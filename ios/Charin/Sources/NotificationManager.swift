import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() async {
        try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
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
