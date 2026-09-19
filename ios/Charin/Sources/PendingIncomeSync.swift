import Foundation
import SwiftData

/// Fetch income recorded by the optional Stripe integration.
enum PendingIncomeSync {
    private struct PendingResponse: Decodable {
        let count: Int
        let income: [PendingIncome]
    }

    private struct PendingIncome: Decodable {
        let id: Int
        let source: String
        let amount: Int
        let currency: String
        let category: String
        let memo: String
        let email: String
        let created_at: String
    }

    @MainActor
    static func fetch(context: ModelContext) async {
        let apiKey = UserDefaults.standard.string(forKey: "charinApiKey") ?? ""
        guard !apiKey.isEmpty else { return }
        var components = URLComponents(string: "https://kacha-server.fly.dev/api/v1/charin/income/pending")!
        components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        guard let url = components.url else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let decoded = try JSONDecoder().decode(PendingResponse.self, from: data)
            for item in decoded.income {
                let income = Income(
                    date: ISO8601DateFormatter().date(from: item.created_at) ?? .now,
                    source: item.source, amount: item.amount,
                    currency: item.currency.uppercased(), category: item.category,
                    memo: item.memo.isEmpty ? "Stripe自動連携" : item.memo,
                    paymentStatus: "paid", paidAt: .now, paymentMethod: "stripe"
                )
                context.insert(income)
            }
            try context.save()
            if !decoded.income.isEmpty { SoundPlayer.shared.play("charin") }
        } catch {
            print("[Charin] Income sync failed: \(error.localizedDescription)")
        }
    }
}
