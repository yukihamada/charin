import SwiftUI
import SwiftData
import Charts

struct ReportView: View {
    @Query(sort: \Income.date, order: .reverse) private var allIncome: [Income]

    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)

    private var yearIncome: [Income] {
        allIncome.filter { Calendar.current.component(.year, from: $0.date) == selectedYear && $0.currency == "JPY" }
    }

    private var yearTotal: Int {
        yearIncome.reduce(0) { $0 + $1.amount }
    }

    private var monthlyData: [(month: Int, total: Int)] {
        var dict: [Int: Int] = [:]
        for inc in yearIncome {
            let m = Calendar.current.component(.month, from: inc.date)
            dict[m, default: 0] += inc.amount
        }
        return (1...12).map { (month: $0, total: dict[$0] ?? 0) }
    }

    private var categoryData: [(category: String, total: Int)] {
        var dict: [String: Int] = [:]
        for inc in yearIncome {
            dict[inc.category, default: 0] += inc.amount
        }
        return dict.sorted { $0.value > $1.value }.map { (category: $0.key, total: $0.value) }
    }

    private var sourceData: [(source: String, total: Int)] {
        var dict: [String: Int] = [:]
        for inc in yearIncome {
            dict[inc.source, default: 0] += inc.amount
        }
        return dict.sorted { $0.value > $1.value }.map { (source: $0.key, total: $0.value) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Year selector
                    yearSelector

                    // Year total
                    VStack(spacing: 4) {
                        Text("年間合計")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)
                        Text("\u{00A5}\(yearTotal.formatted())")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.charinSuccess)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .glassCard()

                    // Monthly bar chart
                    monthlyChart

                    // Category breakdown
                    if !categoryData.isEmpty {
                        categoryChart
                    }

                    // Top sources
                    if !sourceData.isEmpty {
                        topSources
                    }
                }
                .padding()
                .padding(.bottom, 100)
            }
            .background(Color.charinBg)
            .navigationTitle("レポート")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Year Selector

    private var yearSelector: some View {
        HStack {
            Button { selectedYear -= 1 } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(String(selectedYear))年")
                .font(.system(size: 16, weight: .bold))
            Spacer()
            Button { selectedYear += 1 } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard()
    }

    // MARK: - Monthly Chart

    private var monthlyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月別推移")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            Chart(monthlyData, id: \.month) { item in
                BarMark(
                    x: .value("月", "\(item.month)月"),
                    y: .value("金額", item.total)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.charin, .charinSuccess],
                        startPoint: .bottom, endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text(shortAmount(v))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 200)
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Category Chart

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ別")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            ForEach(categoryData, id: \.category) { item in
                let label: String = {
                    switch item.category {
                    case "subscription": return "定期"
                    case "one-time": return "単発"
                    case "token sale": return "トークン"
                    case "consulting": return "コンサル"
                    default: return item.category
                    }
                }()
                let color = Color.categoryColor(for: item.category)

                HStack(spacing: 10) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 70, alignment: .leading)
                    GeometryReader { geo in
                        let pct = yearTotal > 0 ? CGFloat(item.total) / CGFloat(yearTotal) : 0
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.3))
                            .frame(width: max(geo.size.width * pct, 30))
                    }
                    .frame(height: 20)
                    Spacer()
                    Text("\u{00A5}\(item.total.formatted())")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Top Sources

    private var topSources: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("トップソース")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(1)

            ForEach(Array(sourceData.prefix(5).enumerated()), id: \.offset) { index, item in
                HStack {
                    Text("#\(index + 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.charinWarn)
                        .frame(width: 28)
                    Text(item.source)
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text("\u{00A5}\(item.total.formatted())")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.charinSuccess)
                }
                .padding(.vertical, 4)
                if index < sourceData.prefix(5).count - 1 {
                    Divider().overlay(Color.white.opacity(0.04))
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    private func shortAmount(_ v: Int) -> String {
        if v >= 1_000_000 { return "\(v / 1_000_000)M" }
        if v >= 1_000 { return "\(v / 1_000)K" }
        return "\(v)"
    }
}
