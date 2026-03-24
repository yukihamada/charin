import SwiftUI
import SwiftData

struct IncomeListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Income.date, order: .reverse) private var allIncome: [Income]
    @State private var searchText = ""
    @State private var filterSource = ""

    private var filtered: [Income] {
        var result = allIncome
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.source.lowercased().contains(q) ||
                $0.memo.lowercased().contains(q) ||
                $0.invoiceNumber.lowercased().contains(q)
            }
        }
        if !filterSource.isEmpty {
            result = result.filter { $0.source == filterSource }
        }
        return result
    }

    private var allSources: [String] {
        Array(Set(allIncome.map(\.source))).sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("検索...", text: $searchText)
                            .font(.system(size: 14))
                    }
                    .padding(12)
                    .background(Color.charinCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                    )

                    // Source filter pills
                    if !allSources.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                FilterPill(label: "すべて", isSelected: filterSource.isEmpty) {
                                    filterSource = ""
                                }
                                ForEach(allSources, id: \.self) { src in
                                    FilterPill(label: src, isSelected: filterSource == src) {
                                        filterSource = filterSource == src ? "" : src
                                    }
                                }
                            }
                        }
                    }

                    // Income entries
                    if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 36))
                                .foregroundStyle(.quaternary)
                            Text("データがありません")
                                .font(.system(size: 14))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(filtered, id: \.id) { income in
                            NavigationLink {
                                IncomeDetailView(income: income)
                            } label: {
                                IncomeRow(income: income)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .background(Color.charinBg)
            .navigationTitle("収入一覧")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: exportCSV()) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Color.charin)
                    }
                }
            }
        }
    }

    private func exportCSV() -> String {
        var csv = "\u{FEFF}日付,ソース,金額,通貨,カテゴリ,税率,税抜金額,消費税,入金状態,支払方法,メモ,請求書番号,登録番号\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for inc in filtered {
            csv += "\(formatter.string(from: inc.date)),\(inc.source),\(inc.amount),\(inc.currency),\(inc.category),\(inc.taxRate)%,\(inc.subtotal),\(inc.taxAmount),\(inc.paymentStatus),\(inc.paymentMethod),\(inc.memo),\(inc.invoiceNumber),\(inc.registrationNumber)\n"
        }
        return csv
    }
}

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.charin.opacity(0.15) : .white.opacity(0.03))
                .foregroundStyle(isSelected ? Color.charin : Color.secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.charin : .white.opacity(0.06), lineWidth: 1)
                )
        }
    }
}
