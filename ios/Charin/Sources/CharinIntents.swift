import AppIntents

// MARK: - Add Income Intent

struct AddIncomeIntent: AppIntent {
    static var title: LocalizedStringResource = "収入を記録"
    static var description = IntentDescription("チャリンに収入を記録します")
    static var openAppWhenRun = true

    @Parameter(title: "金額")
    var amount: Int

    @Parameter(title: "クライアント名")
    var clientName: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let formatted = amount.formatted()
        return .result(dialog: "\(clientName)から¥\(formatted)を記録しました")
    }
}

// MARK: - Check Unpaid Intent

struct CheckUnpaidIntent: AppIntent {
    static var title: LocalizedStringResource = "未払い確認"
    static var description = IntentDescription("未払いの請求書を確認します")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "チャリンで未払い請求書を確認します")
    }
}

// MARK: - App Shortcuts

struct CharinShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddIncomeIntent(),
            phrases: [
                "チャリンで収入を記録",
                "収入を追加",
                "Record income with \(.applicationName)"
            ],
            shortTitle: "収入を記録",
            systemImageName: "yensign.circle.fill"
        )
        AppShortcut(
            intent: CheckUnpaidIntent(),
            phrases: [
                "未払い請求書を確認",
                "チャリンで未払い確認",
                "Check unpaid invoices with \(.applicationName)"
            ],
            shortTitle: "未払い確認",
            systemImageName: "exclamationmark.circle.fill"
        )
    }
}
