import Foundation
import SwiftData

@Model
final class Income {
    var id: String
    var date: Date
    var source: String
    var amount: Int               // Smallest unit (yen or cents)
    var currency: String          // "JPY" or "USD"
    var category: String          // subscription, one-time, token sale, consulting
    var memo: String
    var invoiceNumber: String     // CHR-YYYYMM-NNN
    var createdAt: Date

    // Invoice system (インボイス制度)
    var registrationNumber: String  // 適格請求書発行事業者登録番号 T + 13 digits
    var taxRate: Int                // 10 or 8 (reduced rate)
    var taxAmount: Int              // Calculated tax
    var subtotal: Int               // Before tax

    // Recurring invoice support
    var isRecurring: Bool
    var recurringInterval: String   // monthly, quarterly, yearly
    var nextDueDate: Date?

    // Payment tracking
    var paymentStatus: String       // unpaid, paid, overdue
    var paidAt: Date?
    var paymentMethod: String       // bank, stripe, paypal, cash, crypto

    init(
        date: Date = .now,
        source: String,
        amount: Int,
        currency: String = "JPY",
        category: String = "subscription",
        memo: String = "",
        invoiceNumber: String = "",
        registrationNumber: String = "",
        taxRate: Int = 10,
        taxAmount: Int = 0,
        subtotal: Int = 0,
        isRecurring: Bool = false,
        recurringInterval: String = "monthly",
        nextDueDate: Date? = nil,
        paymentStatus: String = "unpaid",
        paidAt: Date? = nil,
        paymentMethod: String = "bank"
    ) {
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        let uuid = UUID().uuidString.prefix(6)
        self.id = "chr_\(ts)_\(uuid)"
        self.date = date
        self.source = source
        self.amount = amount
        self.currency = currency
        self.category = category
        self.memo = memo
        self.invoiceNumber = invoiceNumber
        self.createdAt = .now
        self.registrationNumber = registrationNumber
        self.taxRate = taxRate
        // Auto-calculate tax if not provided
        if subtotal == 0 && taxAmount == 0 {
            // amount is tax-inclusive, calculate backwards
            let calcSubtotal = amount * 100 / (100 + taxRate)
            self.subtotal = calcSubtotal
            self.taxAmount = amount - calcSubtotal
        } else {
            self.taxAmount = taxAmount
            self.subtotal = subtotal
        }
        self.isRecurring = isRecurring
        self.recurringInterval = recurringInterval
        self.nextDueDate = nextDueDate
        self.paymentStatus = paymentStatus
        self.paidAt = paidAt
        self.paymentMethod = paymentMethod
    }

    // MARK: - Display helpers

    var currencySymbol: String {
        switch currency {
        case "USD": return "$"
        case "EUR": return "\u{20AC}"
        default: return "\u{00A5}"
        }
    }

    var formattedAmount: String {
        if currency == "USD" {
            let dollars = amount / 100
            let cents = amount % 100
            return "$\(dollars.formatted()).\(String(format: "%02d", cents))"
        }
        return "\(currencySymbol)\(amount.formatted())"
    }

    var formattedSubtotal: String {
        if currency == "USD" {
            let dollars = subtotal / 100
            let cents = subtotal % 100
            return "$\(dollars.formatted()).\(String(format: "%02d", cents))"
        }
        return "\(currencySymbol)\(subtotal.formatted())"
    }

    var formattedTax: String {
        if currency == "USD" {
            let dollars = taxAmount / 100
            let cents = taxAmount % 100
            return "$\(dollars.formatted()).\(String(format: "%02d", cents))"
        }
        return "\(currencySymbol)\(taxAmount.formatted())"
    }

    var categoryLabel: String {
        switch category {
        case "subscription": return "定期"
        case "one-time": return "単発"
        case "token sale": return "トークン"
        case "consulting": return "コンサル"
        default: return category
        }
    }

    var paymentStatusLabel: String {
        switch paymentStatus {
        case "paid": return "入金済"
        case "overdue": return "期限超過"
        case "unpaid": return "未入金"
        default: return paymentStatus
        }
    }

    var paymentMethodLabel: String {
        switch paymentMethod {
        case "bank": return "銀行振込"
        case "stripe": return "Stripe"
        case "paypal": return "PayPal"
        case "cash": return "現金"
        case "crypto": return "暗号資産"
        default: return paymentMethod
        }
    }

    var recurringIntervalLabel: String {
        switch recurringInterval {
        case "monthly": return "毎月"
        case "quarterly": return "四半期"
        case "yearly": return "毎年"
        default: return recurringInterval
        }
    }

    // MARK: - Invoice number generation

    static func generateInvoiceNumber(date: Date, existingCount: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMM"
        let prefix = formatter.string(from: date)
        return "CHR-\(prefix)-\(String(format: "%03d", existingCount + 1))"
    }

    // MARK: - Default sources

    static let defaultSources: [(name: String, category: String)] = [
        ("chatweb.ai", "subscription"),
        ("StayFlow", "subscription"),
        ("JiuFlow", "subscription"),
        ("Elio", "subscription"),
        ("Pasha", "subscription"),
        ("ENAI", "token sale"),
        ("Consulting", "consulting"),
        ("Other", "one-time"),
    ]
}
