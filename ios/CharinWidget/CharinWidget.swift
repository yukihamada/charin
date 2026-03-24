import WidgetKit
import SwiftUI

// MARK: - Data Model

struct CharinWidgetEntry: TimelineEntry {
    let date: Date
    let monthlyIncome: Int
    let unpaidCount: Int
    let recentItems: [(String, Int, String)]  // (client, amount, status)
}

// MARK: - Provider

struct CharinProvider: TimelineProvider {
    private let suiteName = "group.com.enablerdao.charin"

    func placeholder(in context: Context) -> CharinWidgetEntry {
        CharinWidgetEntry(
            date: Date(),
            monthlyIncome: 850000,
            unpaidCount: 3,
            recentItems: [
                ("株式会社ABC", 200000, "unpaid"),
                ("田中デザイン事務所", 150000, "paid"),
                ("フリーランス案件", 80000, "overdue")
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CharinWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CharinWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> CharinWidgetEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        let income = defaults?.integer(forKey: "widget_monthly_income") ?? 0
        let unpaid = defaults?.integer(forKey: "widget_unpaid_count") ?? 0

        var recentItems: [(String, Int, String)] = []
        if let data = defaults?.data(forKey: "widget_recent_income"),
           let decoded = try? JSONDecoder().decode([IncomeItem].self, from: data) {
            recentItems = decoded.map { ($0.client, $0.amount, $0.status) }
        }

        return CharinWidgetEntry(
            date: Date(),
            monthlyIncome: income,
            unpaidCount: unpaid,
            recentItems: recentItems
        )
    }
}

private struct IncomeItem: Codable {
    let client: String
    let amount: Int
    let status: String
}

// MARK: - Views

private let goldAccent = Color(red: 1.0, green: 0.75, blue: 0.2)
private let darkBg = Color(red: 0.06, green: 0.06, blue: 0.09)

struct CharinSmallView: View {
    let entry: CharinWidgetEntry

    var body: some View {
        ZStack {
            darkBg
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "yensign.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(goldAccent)
                    Text("チャリン")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Text(formatYen(entry.monthlyIncome))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)

                Text("\(monthLabel())の収入")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))

                if entry.unpaidCount > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("未払い \(entry.unpaidCount)件")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.orange)
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(goldAccent)
                            .frame(width: 6, height: 6)
                        Text("未払いなし")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(14)
        }
    }
}

struct CharinMediumView: View {
    let entry: CharinWidgetEntry

    var body: some View {
        ZStack {
            darkBg
            HStack(spacing: 0) {
                // Left column: totals
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "yensign.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(goldAccent)
                        Text("チャリン")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Text(formatYen(entry.monthlyIncome))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)

                    Text("\(monthLabel())の収入")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))

                    HStack(spacing: 4) {
                        if entry.unpaidCount > 0 {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.orange)
                            Text("未払い \(entry.unpaidCount)件")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.orange)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(goldAccent)
                            Text("全件回収済み")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(14)

                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 1)

                // Right column: recent items
                VStack(alignment: .leading, spacing: 0) {
                    Text("直近")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.bottom, 6)

                    if entry.recentItems.isEmpty {
                        Text("データなし")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.3))
                    } else {
                        ForEach(Array(entry.recentItems.prefix(3).enumerated()), id: \.offset) { _, item in
                            HStack {
                                statusDot(item.2)
                                Text(item.0)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .lineLimit(1)
                                Spacer()
                                Text(formatYen(item.1))
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.white)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(14)
            }
        }
    }

    @ViewBuilder
    private func statusDot(_ status: String) -> some View {
        let color: Color = status == "paid" ? goldAccent : (status == "overdue" ? .red : .orange)
        Circle()
            .fill(color)
            .frame(width: 5, height: 5)
    }
}

// MARK: - Widget

@main
struct CharinWidget: Widget {
    let kind = "CharinWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CharinProvider()) { entry in
            CharinWidgetEntryView(entry: entry)
                .containerBackground(darkBg, for: .widget)
        }
        .configurationDisplayName("チャリン")
        .description("今月の収入を確認")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CharinWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: CharinWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            CharinSmallView(entry: entry)
        case .systemMedium:
            CharinMediumView(entry: entry)
        default:
            CharinSmallView(entry: entry)
        }
    }
}

// MARK: - Helpers

private func formatYen(_ amount: Int) -> String {
    if amount >= 10000 {
        let man = Double(amount) / 10000.0
        if man == Double(Int(man)) {
            return "¥\(Int(man))万"
        } else {
            return String(format: "¥%.1f万", man)
        }
    }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return "¥\(formatter.string(from: NSNumber(value: amount)) ?? "\(amount)")"
}

private func monthLabel() -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ja_JP")
    f.dateFormat = "M月"
    return f.string(from: Date())
}
