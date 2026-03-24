import SwiftUI

// MARK: - Color Extensions (Pasha sister palette)

extension Color {
    /// Primary cyan: #4CC9F0
    static let charin = Color(hex: "4CC9F0")
    /// Accent orange: #F77F00
    static let charinAccent = Color(hex: "F77F00")
    /// Magenta: #F72585
    static let charinMagenta = Color(hex: "F72585")
    /// Success green: #06D6A0
    static let charinSuccess = Color(hex: "06D6A0")
    /// Warning yellow: #FFD60A
    static let charinWarn = Color(hex: "FFD60A")
    /// Solana purple: #9945FF
    static let charinSolana = Color(hex: "9945FF")
    /// Card background: #16213E
    static let charinCard = Color(hex: "16213E")
    /// Page background: #0F0F1A
    static let charinBg = Color(hex: "0F0F1A")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255,
                  blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Category color

extension Color {
    static func categoryColor(for cat: String) -> Color {
        switch cat {
        case "subscription": return .charin
        case "one-time": return .charinAccent
        case "token sale": return .charinSolana
        case "consulting": return .charinMagenta
        default: return .gray
        }
    }
}

// MARK: - Glass Card Modifier (matches Pasha)

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}

// MARK: - Tab Navigation

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showAddIncome = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(showAddIncome: $showAddIncome)
                    .tag(0)
                    .tabItem { Label("ホーム", systemImage: "house.fill") }

                IncomeListView()
                    .tag(1)
                    .tabItem { Label("一覧", systemImage: "list.bullet") }

                ReportView()
                    .tag(2)
                    .tabItem { Label("レポート", systemImage: "chart.bar.fill") }

                SettingsView()
                    .tag(3)
                    .tabItem { Label("設定", systemImage: "gearshape.fill") }
            }
            .tint(.charin)

            // Floating add button (Pasha-style coin button)
            Button { showAddIncome = true } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 68, height: 68)
                    Circle()
                        .fill(LinearGradient(
                            colors: [.charinSuccess, .charin],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                    Image(systemName: "yensign.circle.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: .charinSuccess.opacity(0.35), radius: 16, y: 6)
            }
            .offset(y: -4)
        }
        .sheet(isPresented: $showAddIncome) {
            AddIncomeView()
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .modelContainer(for: [Income.self, Client.self], inMemory: true)
}
