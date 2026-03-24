import SwiftUI
import SwiftData
import WidgetKit

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Income.date, order: .reverse) private var allIncome: [Income]
    @Binding var showAddIncome: Bool

    @AppStorage("reminderDays") private var reminderDays: Int = 7
    @State private var showReminderFor: Income?

    @State private var currentMonth: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        return cal.date(from: comps) ?? .now
    }()

    private var monthIncome: [Income] {
        let cal = Calendar.current
        return allIncome.filter {
            cal.isDate($0.date, equalTo: currentMonth, toGranularity: .month)
        }
    }

    private var monthTotal: Int {
        monthIncome.filter { $0.currency == "JPY" }.reduce(0) { $0 + $1.amount }
    }

    private var unpaidTotal: Int {
        allIncome.filter { $0.currency == "JPY" && $0.paymentStatus != "paid" }.reduce(0) { $0 + $1.amount }
    }

    private var overdueCount: Int {
        allIncome.filter { $0.paymentStatus == "overdue" }.count
    }

    /// Unpaid invoices that have exceeded the reminder threshold
    private var reminderDueInvoices: [Income] {
        let threshold = TimeInterval(reminderDays * 86400)
        return allIncome.filter { inc in
            guard inc.paymentStatus != "paid" else { return false }
            let refDate = inc.nextDueDate ?? inc.date
            return Date().timeIntervalSince(refDate) >= threshold
        }
        .sorted { ($0.nextDueDate ?? $0.date) < ($1.nextDueDate ?? $1.date) }
    }

    private var recurringIncome: [Income] {
        allIncome.filter { $0.isRecurring && $0.nextDueDate != nil }
            .sorted { ($0.nextDueDate ?? .distantFuture) < ($1.nextDueDate ?? .distantFuture) }
    }

    private var sourceBreakdown: [(String, Int)] {
        var dict: [String: Int] = [:]
        for inc in monthIncome where inc.currency == "JPY" {
            dict[inc.source, default: 0] += inc.amount
        }
        return dict.sorted { $0.value > $1.value }
    }

    private var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Month navigator
                    monthNavigator
                        .onAppear { updateWidgetData() }
                        .onChange(of: monthIncome.count) { _, _ in updateWidgetData() }

                    // Stat cards (Pasha-style 3-column)
                    statCards

                    // Unpaid warning
                    if unpaidTotal > 0 {
                        unpaidCard
                    }

                    // Reminder due invoices
                    if !reminderDueInvoices.isEmpty {
                        reminderCard
                    }

                    // Recurring invoices
                    if !recurringIncome.isEmpty {
                        recurringCard
                    }

                    // Source breakdown
                    if !sourceBreakdown.isEmpty {
                        sourceCard
                    }

                    // Recent income list
                    recentCard
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .background(Color.charinBg)
            .navigationTitle("チャリン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddIncome = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.charin)
                    }
                }
            }
            .sheet(item: $showReminderFor) { income in
                PaymentReminderView(income: income)
            }
        }
    }

    // MARK: - Widget Data

    private func updateWidgetData() {
        guard let defaults = UserDefaults(suiteName: "group.com.enablerdao.charin") else { return }
        defaults.set(monthTotal, forKey: "widget_monthly_income")
        let unpaid = allIncome.filter { $0.paymentStatus != "paid" }.count
        defaults.set(unpaid, forKey: "widget_unpaid_count")

        struct IncomeItem: Codable { let client: String; let amount: Int; let status: String }
        let recent = Array(allIncome.prefix(3)).map { IncomeItem(client: $0.source, amount: $0.amount, status: $0.paymentStatus) }
        if let encoded = try? JSONEncoder().encode(recent) {
            defaults.set(encoded, forKey: "widget_recent_income")
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "CharinWidget")
    }

    // MARK: - Month Navigator

    private var monthNavigator: some View {
        HStack {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(monthFormatter.string(from: currentMonth))
                    .font(.system(size: 16, weight: .bold))
                Text("届いた、チャリン。")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .glassCard()
    }

    // MARK: - Stat Cards

    private var statCards: some View {
        HStack(spacing: 10) {
            StatCard(
                label: "月間合計",
                value: "\u{00A5}\(monthTotal.formatted())",
                color: .charinSuccess
            )
            StatCard(
                label: "取引件数",
                value: "\(monthIncome.count)",
                color: .charin
            )
            StatCard(
                label: "ソース数",
                value: "\(Set(monthIncome.map(\.source)).count)",
                color: .charinWarn
            )
        }
    }

    // MARK: - Unpaid Warning Card

    private var unpaidCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.charinWarn.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.charinWarn)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("未入金")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.charinWarn)
                Text("\u{00A5}\(unpaidTotal.formatted())")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.charinWarn)
            }

            Spacer()

            if overdueCount > 0 {
                Text("\(overdueCount)件期限超過")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Color.charinWarn.opacity(0.06))
        .glassCard()
    }

    // MARK: - Reminder Card

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.red)
                Text("催促が必要な請求書")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                Text("\(reminderDueInvoices.count)件")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.red.opacity(0.12))
                    .foregroundStyle(.red)
                    .clipShape(Capsule())
            }

            ForEach(reminderDueInvoices, id: \.id) { income in
                let daysOver: Int = {
                    let ref = income.nextDueDate ?? income.date
                    return max(0, Int(Date().timeIntervalSince(ref) / 86400))
                }()
                Button {
                    showReminderFor = income
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .frame(width: 36, height: 36)
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.red)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(income.source)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("\(daysOver)日超過")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.red)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(income.formattedAmount)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.charinSuccess)
                            Text("催促 →")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.red.opacity(0.04))
        .glassCard()
    }

    // MARK: - Recurring Card

    private var recurringCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundStyle(Color.charinSolana)
                Text("定期請求")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                Text("\(recurringIncome.count)件")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            ForEach(recurringIncome.prefix(5), id: \.id) { income in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(income.source)
                            .font(.system(size: 13, weight: .medium))
                        HStack(spacing: 4) {
                            Text(income.recurringIntervalLabel)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.charinSolana.opacity(0.12))
                                .foregroundStyle(Color.charinSolana)
                                .clipShape(Capsule())
                            if let next = income.nextDueDate {
                                Text("次回: \(next, format: .dateTime.month(.twoDigits).day())")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }

                    Spacer()

                    Text(income.formattedAmount)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.charinSuccess)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Source Breakdown

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ソース別")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            ForEach(sourceBreakdown, id: \.0) { source, amount in
                HStack(spacing: 12) {
                    Text(source)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 90, alignment: .trailing)

                    GeometryReader { geo in
                        let pct = monthTotal > 0 ? CGFloat(amount) / CGFloat(monthTotal) : 0
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                                colors: [Color.charin, Color.charinSuccess],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: max(geo.size.width * pct, 40))
                            .overlay(alignment: .leading) {
                                Text("\u{00A5}\(amount.formatted())")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.leading, 8)
                            }
                    }
                    .frame(height: 28)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Recent Income

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("最近の収入")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                Spacer()
                NavigationLink("すべて") {
                    IncomeListView()
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.charin)
            }

            if monthIncome.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "yensign.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(.quaternary)
                    Text("まだ収入データがありません")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                    Button { showAddIncome = true } label: {
                        Text("最初の収入を登録")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.charinAccent, in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(monthIncome.prefix(10), id: \.id) { income in
                    NavigationLink {
                        IncomeDetailView(income: income)
                    } label: {
                        IncomeRow(income: income)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .glassCard()
    }
}

// MARK: - Stat Card (Pasha-style)

struct StatCard: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCard()
    }
}

// MARK: - Income Row (Pasha ReceiptRow-style)

struct IncomeRow: View {
    let income: Income

    var body: some View {
        HStack(spacing: 14) {
            // Source icon circle
            ZStack {
                Circle()
                    .fill(Color.categoryColor(for: income.category).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: sourceIcon(income.source))
                    .font(.system(size: 18))
                    .foregroundStyle(Color.categoryColor(for: income.category))
            }

            // Source + date + category badge + payment status
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(income.source)
                        .font(.subheadline.weight(.medium))
                    // Payment status badge
                    paymentBadge
                }
                HStack(spacing: 6) {
                    Text(income.date, format: .dateTime.month(.twoDigits).day())
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(income.categoryLabel)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.categoryColor(for: income.category).opacity(0.12))
                        .foregroundStyle(Color.categoryColor(for: income.category))
                        .clipShape(Capsule())
                    if !income.invoiceNumber.isEmpty {
                        Text(income.invoiceNumber)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.charinSolana)
                    }
                    if income.isRecurring {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.charinSolana)
                    }
                }
            }

            Spacer(minLength: 4)

            // Amount
            Text(income.formattedAmount)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.charinSuccess)
        }
        .padding(12)
        .glassCard()
    }

    private var paymentBadge: some View {
        let (label, color): (String, Color) = {
            switch income.paymentStatus {
            case "paid": return ("入金済", .charinSuccess)
            case "overdue": return ("期限超過", .red)
            default: return ("未入金", .charinWarn)
            }
        }()
        return Text(label)
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func sourceIcon(_ source: String) -> String {
        switch source.lowercased() {
        case "chatweb.ai", "elio": return "bubble.left.and.bubble.right.fill"
        case "stayflow": return "building.2.fill"
        case "jiuflow": return "figure.martial.arts"
        case "pasha": return "camera.fill"
        case "enai": return "bitcoinsign.circle.fill"
        case "consulting": return "person.2.fill"
        default: return "banknote.fill"
        }
    }
}
