import Foundation
import SwiftData

enum SeedData {
    @MainActor
    static func insertIfEmpty(context: ModelContext) {
        let descriptor = FetchDescriptor<Income>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let entries: [(source: String, amount: Int, category: String, date: String, memo: String, isRecurring: Bool, recurringInterval: String, paymentStatus: String, paymentMethod: String)] = [
            ("chatweb.ai", 29_800, "subscription", "2026-03-01", "月額プラン収入", true, "monthly", "paid", "stripe"),
            ("StayFlow", 79_000, "subscription", "2026-03-05", "Proプラン x 10施設", true, "monthly", "paid", "bank"),
            ("Consulting", 150_000, "consulting", "2026-03-10", "UI/UXレビュー", false, "monthly", "unpaid", "bank"),
            ("ENAI", 45_000, "token sale", "2026-03-12", "トークン売却 450 ENAI", false, "monthly", "paid", "crypto"),
            ("JiuFlow", 9_800, "subscription", "2026-03-15", "月額プラン", true, "monthly", "unpaid", "stripe"),
            ("Elio", 4_900, "subscription", "2026-03-18", "Proアップグレード", true, "monthly", "unpaid", "stripe"),
            ("Consulting", 200_000, "consulting", "2026-02-15", "アーキテクチャ設計", false, "monthly", "paid", "bank"),
            ("chatweb.ai", 29_800, "subscription", "2026-02-01", "月額プラン収入", true, "monthly", "paid", "stripe"),
        ]

        let cal = Calendar.current

        for (index, e) in entries.enumerated() {
            let date = dateFormatter.date(from: e.date) ?? .now
            var nextDue: Date? = nil
            if e.isRecurring {
                nextDue = cal.date(byAdding: .month, value: 1, to: date)
            }
            let income = Income(
                date: date,
                source: e.source,
                amount: e.amount,
                currency: "JPY",
                category: e.category,
                memo: e.memo,
                invoiceNumber: Income.generateInvoiceNumber(date: date, existingCount: index),
                taxRate: 10,
                isRecurring: e.isRecurring,
                recurringInterval: e.recurringInterval,
                nextDueDate: nextDue,
                paymentStatus: e.paymentStatus,
                paidAt: e.paymentStatus == "paid" ? date : nil,
                paymentMethod: e.paymentMethod
            )
            context.insert(income)
        }
    }
}
