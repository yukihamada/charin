import Foundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        print("[Push] Current status: \(settings.authorizationStatus.rawValue)")

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print("[Push] Permission granted: \(granted)")
        } catch {
            print("[Push] Permission error: \(error)")
        }

        await MainActor.run {
            print("[Push] Registering for remote notifications...")
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    /// APNsトークンをKAGIサーバーに登録
    func registerPushToken(_ token: Data) {
        let tokenStr = token.map { String(format: "%02.2hhx", $0) }.joined()
        let userId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        print("[Charin] APNs token: \(tokenStr.prefix(16))...")

        let url = URL(string: "https://kacha-server.fly.dev/api/v1/charin/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["user_id": userId, "push_token": tokenStr]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }

    // MARK: - Handle incoming push (チャリン音)

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        if userInfo["type"] as? String == "revenue" {
            // チャリン音を鳴らす
            SoundPlayer.shared.play("charin")
        }
        completionHandler([.banner, .sound, .badge])
    }

    /// リモートプッシュから収入を自動記録
    static func handleRevenuePush(userInfo: [AnyHashable: Any]) -> Income? {
        guard let type = userInfo["type"] as? String, type == "revenue" else { return nil }
        let source = userInfo["source"] as? String ?? "KAGI"
        let amount = userInfo["amount"] as? Int ?? 0
        let currency = userInfo["currency"] as? String ?? "JPY"

        // チャリン音
        SoundPlayer.shared.play("charin")

        return Income(
            date: .now,
            source: source,
            amount: amount,
            currency: currency.uppercased(),
            category: "one-time",
            memo: "Enabler自動連携",
            paymentStatus: "paid",
            paidAt: .now,
            paymentMethod: "stripe"
        )
    }

    // MARK: - Overdue payment reminder (+7 days after due date if unpaid)

    func scheduleOverdueReminder(income: Income) {
        // Only schedule for unpaid income
        guard income.paymentStatus == "unpaid" else { return }

        let referenceDate = income.nextDueDate ?? income.date
        guard let triggerDate = Calendar.current.date(byAdding: .day, value: 7, to: referenceDate),
              triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "未払い請求書があります"
        content.body = "\(income.source)様 \(income.formattedAmount) が未払いです。確認してください。"
        content.sound = .default
        content.userInfo = ["incomeId": income.id, "type": "overdue"]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "overdue-\(income.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel reminder for an income

    func cancelReminder(incomeId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "overdue-\(incomeId)"
        ])
    }
}
