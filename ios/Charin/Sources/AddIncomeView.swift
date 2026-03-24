import SwiftUI
import SwiftData
import UIKit

struct AddIncomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Income.date, order: .reverse) private var allIncome: [Income]
    @AppStorage("invoiceRegistrationNumber") private var savedRegistrationNumber = ""

    @State private var date = Date.now
    @State private var source = "chatweb.ai"
    @State private var amount = ""
    @State private var currency = "JPY"
    @State private var category = "subscription"
    @State private var memo = ""
    @State private var taxRate = 10
    @State private var isRecurring = false
    @State private var recurringInterval = "monthly"
    @State private var paymentStatus = "unpaid"
    @State private var paymentMethod = "bank"
    @State private var showCelebration = false

    private let sources = Income.defaultSources
    private static let amountMax = 999_999_999
    private static let memoMaxLength = 200

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Amount (hero input)
                    amountSection

                    // Source pills
                    sourceSection

                    // Category pills
                    categorySection

                    // Tax rate
                    taxSection

                    // Payment section
                    paymentSection

                    // Recurring section
                    recurringSection

                    // Date + Currency
                    detailsSection

                    // Memo
                    memoSection
                }
                .padding()
            }
            .background(Color.charinBg)
            .navigationTitle("収入を登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("登録") { save() }
                        .font(.headline)
                        .foregroundStyle(Color.charinSuccess)
                        .disabled(amount.isEmpty)
                }
            }
        }
        .overlay {
            if showCelebration {
                ZStack {
                    CoinRainView()
                    SuccessCheckmark(color: .charinSuccess)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showCelebration)
        .presentationDetents([.large])
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(spacing: 8) {
            Text(currency == "JPY" ? "\u{00A5}" : "$")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
            TextField("0", text: $amount)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(Color.charinSuccess)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .onChange(of: amount) { _, newValue in
                    let cleaned = newValue.replacingOccurrences(of: ",", with: "")
                    if let val = Int(cleaned), val > Self.amountMax {
                        amount = String(Self.amountMax)
                    }
                }
        }
        .padding(.vertical, 20)
        .glassCard()
    }

    // MARK: - Source Section

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ソース")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            FlowLayout(spacing: 8) {
                ForEach(sources, id: \.name) { s in
                    sourcePill(s)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private func sourcePill(_ s: (name: String, category: String)) -> some View {
        let isSelected = source == s.name
        let bg: Color = isSelected ? Color.charin.opacity(0.15) : Color.white.opacity(0.03)
        let fg: Color = isSelected ? Color.charin : Color.secondary
        let border: Color = isSelected ? Color.charin : Color.white.opacity(0.06)
        return Button {
            source = s.name
            category = s.category
        } label: {
            Text(s.name)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(bg)
                .foregroundStyle(fg)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(border, lineWidth: 1))
        }
    }

    private func categoryPill(_ cat: String) -> some View {
        let color = Color.categoryColor(for: cat)
        let isSelected = category == cat
        let label: String = switch cat {
        case "subscription": "定期"
        case "one-time": "単発"
        case "token sale": "トークン"
        case "consulting": "コンサル"
        default: cat
        }
        let bg: Color = isSelected ? color.opacity(0.15) : Color.white.opacity(0.03)
        let fg: Color = isSelected ? color : Color.secondary
        let border: Color = isSelected ? color : Color.white.opacity(0.06)
        return Button {
            category = cat
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(bg)
                .foregroundStyle(fg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(border, lineWidth: 1))
        }
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カテゴリ")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 8) {
                ForEach(["subscription", "one-time", "token sale", "consulting"], id: \.self) { cat in
                    categoryPill(cat)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Tax Section

    private var taxSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("税率")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 8) {
                taxRatePill(10, label: "10% (標準)")
                taxRatePill(8, label: "8% (軽減)")
            }

            if let amountInt = Int(amount.replacingOccurrences(of: ",", with: "")), amountInt > 0 {
                let sub = amountInt * 100 / (100 + taxRate)
                let tax = amountInt - sub
                HStack {
                    Text("税抜: \u{00A5}\(sub.formatted())")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("消費税: \u{00A5}\(tax.formatted())")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private func taxRatePill(_ rate: Int, label: String) -> some View {
        let isSelected = taxRate == rate
        return Button { taxRate = rate } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.charin.opacity(0.15) : Color.white.opacity(0.03))
                .foregroundStyle(isSelected ? Color.charin : Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? Color.charin : Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }

    // MARK: - Payment Section

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("入金状態")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 8) {
                paymentStatusPill("unpaid", label: "未入金", color: .charinWarn)
                paymentStatusPill("paid", label: "入金済", color: .charinSuccess)
                paymentStatusPill("overdue", label: "期限超過", color: .red)
            }

            HStack(spacing: 8) {
                Text("支払方法")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $paymentMethod) {
                    Text("銀行振込").tag("bank")
                    Text("Stripe").tag("stripe")
                    Text("PayPal").tag("paypal")
                    Text("現金").tag("cash")
                    Text("暗号資産").tag("crypto")
                }
                .pickerStyle(.menu)
                .tint(.charin)
            }
        }
        .padding(16)
        .glassCard()
    }

    private func paymentStatusPill(_ status: String, label: String, color: Color) -> some View {
        let isSelected = paymentStatus == status
        return Button { paymentStatus = status } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? color.opacity(0.15) : Color.white.opacity(0.03))
                .foregroundStyle(isSelected ? color : Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? color : Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }

    // MARK: - Recurring Section

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $isRecurring) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundStyle(Color.charinSolana)
                    Text("定期請求")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .tint(Color.charinSolana)

            if isRecurring {
                HStack(spacing: 8) {
                    intervalPill("monthly", label: "毎月")
                    intervalPill("quarterly", label: "四半期")
                    intervalPill("yearly", label: "毎年")
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private func intervalPill(_ interval: String, label: String) -> some View {
        let isSelected = recurringInterval == interval
        return Button { recurringInterval = interval } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.charinSolana.opacity(0.15) : Color.white.opacity(0.03))
                .foregroundStyle(isSelected ? Color.charinSolana : Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(isSelected ? Color.charinSolana : Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("日付")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .tint(.charin)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("通貨")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Picker("", selection: $currency) {
                    Text("JPY").tag("JPY")
                    Text("USD").tag("USD")
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Memo Section

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)
            TextField("月額サブスクリプション", text: $memo)
                .font(.system(size: 14))
                .padding(12)
                .background(Color.charinCard)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                )
                .onChange(of: memo) { _, newValue in
                    if newValue.count > Self.memoMaxLength {
                        memo = String(newValue.prefix(Self.memoMaxLength))
                    }
                }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Save

    private func save() {
        guard let amountInt = Int(amount.replacingOccurrences(of: ",", with: "")),
              amountInt > 0, amountInt <= Self.amountMax,
              !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Count existing invoices for this month
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: date))!
        let monthEnd = cal.date(byAdding: .month, value: 1, to: monthStart)!
        let existingCount = allIncome.filter { $0.date >= monthStart && $0.date < monthEnd }.count

        // Calculate next due date for recurring
        var nextDue: Date? = nil
        if isRecurring {
            switch recurringInterval {
            case "monthly":
                nextDue = cal.date(byAdding: .month, value: 1, to: date)
            case "quarterly":
                nextDue = cal.date(byAdding: .month, value: 3, to: date)
            case "yearly":
                nextDue = cal.date(byAdding: .year, value: 1, to: date)
            default:
                nextDue = cal.date(byAdding: .month, value: 1, to: date)
            }
        }

        let income = Income(
            date: date,
            source: source,
            amount: amountInt,
            currency: currency,
            category: category,
            memo: String(memo.prefix(Self.memoMaxLength)),
            invoiceNumber: Income.generateInvoiceNumber(date: date, existingCount: existingCount),
            registrationNumber: savedRegistrationNumber,
            taxRate: taxRate,
            isRecurring: isRecurring,
            recurringInterval: recurringInterval,
            nextDueDate: nextDue,
            paymentStatus: paymentStatus,
            paymentMethod: paymentMethod
        )

        context.insert(income)

        // Schedule overdue reminder for unpaid income (+7 days)
        if paymentStatus == "unpaid" {
            NotificationManager.shared.scheduleOverdueReminder(income: income)
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        SoundPlayer.shared.play("charin")
        showCelebration = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }
}

// MARK: - FlowLayout (for source pills)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: y + lineHeight), positions)
    }
}
