import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("userName") private var userName = ""
    @AppStorage("invoiceRegistrationNumber") private var registrationNumber = ""
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.charinBg.ignoresSafeArea()

            TabView(selection: $currentPage) {
                // Screen 1: Welcome
                welcomePage
                    .tag(0)

                // Screen 2: Setup
                setupPage
                    .tag(1)

                // Screen 3: Start
                startPage
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.charinSuccess, .charin],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                Image(systemName: "yensign.circle.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: .charinSuccess.opacity(0.35), radius: 24, y: 8)

            VStack(spacing: 8) {
                Text("届いた、チャリン。")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)

                Text("フリーランス・個人事業主のための\n収入管理 & インボイス発行アプリ")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "doc.richtext", color: .charin, text: "美しい請求書をワンタップで作成")
                featureRow(icon: "chart.bar.fill", color: .charinSuccess, text: "収入をリアルタイムで可視化")
                featureRow(icon: "building.2.fill", color: .charinAccent, text: "インボイス制度に完全対応")
                featureRow(icon: "arrow.clockwise", color: .charinSolana, text: "定期請求を自動管理")
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("次へ")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.charin, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Setup Page

    private var setupPage: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.charin)

                Text("あなたの情報")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text("請求書に表示される情報です")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("名前")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("Yuki Hamada", text: $userName)
                        .font(.system(size: 16))
                        .padding(14)
                        .background(Color.charinCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("適格請求書発行事業者登録番号")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("T1234567890123", text: $registrationNumber)
                        .font(.system(size: 16, design: .monospaced))
                        .padding(14)
                        .background(Color.charinCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                        .autocapitalization(.allCharacters)
                        .onChange(of: registrationNumber) { _, newValue in
                            // Validate: T + 13 digits
                            let cleaned = newValue.uppercased()
                            if cleaned.count > 14 {
                                registrationNumber = String(cleaned.prefix(14))
                            } else {
                                registrationNumber = cleaned
                            }
                        }

                    Text("T + 13桁の数字 (例: T1234567890123)")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                withAnimation { currentPage = 2 }
            } label: {
                Text("次へ")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.charin, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Start Page

    private var startPage: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.charinSuccess, .charin],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text("準備完了!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("収入が届くたびに、チャリン。")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                SoundPlayer.shared.play("charin")
                withAnimation {
                    hasCompletedOnboarding = true
                }
            } label: {
                Text("始めましょう")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.charinSuccess, .charin],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}
