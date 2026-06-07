import StoreKit
import SwiftUI

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    static let proProductID = "com.enablerdao.charin.pro"

    @Published var isPro = false
    @Published var isPurchasing = false
    @Published var isLoadingProduct = false
    @Published var purchaseError: String?
    @Published var proProduct: Product?
    @Published var expirationDate: Date?

    private var transactionListener: Task<Void, Never>?

    /// タイムアウト秒数
    private let fetchTimeoutSeconds: Double = 15
    /// 最大リトライ回数
    private let maxRetryCount = 3
    /// 指数バックオフの基準秒数（1s, 2s, 4s）
    private let retryBaseDelay: Double = 1.0

    var formattedPrice: String { proProduct?.displayPrice ?? "¥480/月" }

    init() {
        transactionListener = listenForTransactions()
        Task {
            await fetchProduct()
            await updateSubscriptionStatus()
        }
    }

    deinit { transactionListener?.cancel() }

    /// 商品情報を取得する（15秒タイムアウト・最大3回リトライ・指数バックオフ）
    func fetchProduct() async {
        guard !isLoadingProduct else { return }
        isLoadingProduct = true
        defer { isLoadingProduct = false }

        for attempt in 0..<maxRetryCount {
            // 2回目以降は指数バックオフ待機
            if attempt > 0 {
                let delay = retryBaseDelay * pow(2.0, Double(attempt - 1)) // 1s, 2s, 4s
                print("[SubscriptionManager] リトライ \(attempt)/\(maxRetryCount - 1)（\(Int(delay))秒後）")
                try? await Task.sleep(for: .seconds(delay))
            }

            do {
                // タイムアウト付きで商品情報を取得
                let products = try await withTimeout(seconds: fetchTimeoutSeconds) {
                    try await Product.products(for: [Self.proProductID])
                }
                proProduct = products.first
                // 成功したらエラーをクリアしてループ終了
                if proProduct != nil {
                    purchaseError = nil
                }
                return
            } catch is TimeoutError {
                print("[SubscriptionManager] fetchProduct タイムアウト (attempt \(attempt + 1))")
                if attempt == maxRetryCount - 1 {
                    purchaseError = "商品情報の取得がタイムアウトしました。ネットワーク環境を確認して再試行してください。"
                }
            } catch {
                print("[SubscriptionManager] fetchProduct error (attempt \(attempt + 1)): \(error)")
                if attempt == maxRetryCount - 1 {
                    purchaseError = "商品情報を取得できませんでした。ネットワーク環境を確認して再試行してください。"
                }
            }
        }
    }

    /// タイムアウト付き非同期実行ヘルパー
    private func withTimeout<T: Sendable>(seconds: Double, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw TimeoutError()
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    func updateSubscriptionStatus() async {
        var foundPro = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.productID == Self.proProductID && tx.revocationDate == nil {
                foundPro = true
                expirationDate = tx.expirationDate
                break
            }
        }
        // Also check Enabler Fan Club via API
        if !foundPro {
            foundPro = await checkFanClubPro()
        }
        isPro = foundPro
        if !foundPro { expirationDate = nil }
    }

    /// Enabler ファンクラブのPro判定
    private func checkFanClubPro() async -> Bool {
        let email = UserDefaults.standard.string(forKey: "fanClubEmail") ?? ""
        guard !email.isEmpty else { return false }
        guard let url = URL(string: "https://yukihamada.jp/api/fanclub/verify") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["email": email])
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let pro = json["pro"] as? Bool {
                return pro
            }
        } catch {}
        return false
    }

    func purchasePro() async {
        guard let product = proProduct else {
            purchaseError = "商品情報を取得できません"
            return
        }
        isPurchasing = true
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let tx) = verification else {
                    purchaseError = "トランザクションの検証に失敗しました"
                    isPurchasing = false
                    return
                }
                await tx.finish()
                await updateSubscriptionStatus()
            case .userCancelled:
                break
            case .pending:
                purchaseError = "購入が保留中です。承認後に反映されます。"
            @unknown default:
                purchaseError = "不明なエラーが発生しました"
            }
        } catch {
            purchaseError = "購入に失敗しました: \(error.localizedDescription)"
        }
        isPurchasing = false
    }

    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            if !isPro { purchaseError = "復元可能なサブスクリプションが見つかりません" }
        } catch {
            purchaseError = "復元に失敗しました: \(error.localizedDescription)"
        }
        isPurchasing = false
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let tx) = result else { continue }
                await tx.finish()
                await self?.updateSubscriptionStatus()
            }
        }
    }
}

// MARK: - TimeoutError

private struct TimeoutError: Error {}
