import SwiftUI
import SwiftData
import MessageUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Income.date, order: .reverse) private var allIncome: [Income]

    @AppStorage("userName") private var userName = ""
    @AppStorage("invoiceRegistrationNumber") private var registrationNumber = ""
    @AppStorage("csvEmailAddress") private var csvEmail = ""
    @AppStorage("charinApiKey") private var charinApiKey = ""
    @State private var isSettingUp = false
    @State private var copiedWebhook = false
    @State private var pushStatus = "確認中..."

    private var webhookURL: String {
        "https://kacha-server.fly.dev/api/v1/charin/wh/\(charinApiKey)"
    }
    @State private var showExportSheet = false
    @State private var showDeleteAlert = false
    @State private var showEmailSent = false
    @State private var showMailCompose = false
    @State private var showProGate = false
    @StateObject private var sub = SubscriptionManager.shared

    private var totalCount: Int { allIncome.count }
    private var totalJPY: Int { allIncome.filter { $0.currency == "JPY" }.reduce(0) { $0 + $1.amount } }
    private var unpaidCount: Int { allIncome.filter { $0.paymentStatus != "paid" }.count }

    var body: some View {
        NavigationStack {
            List {
                // Invoice Settings
                Section {
                    HStack {
                        Label("名前", systemImage: "person.fill")
                            .foregroundStyle(Color.charin)
                        Spacer()
                        TextField("名前を入力", text: $userName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.primary)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("登録番号", systemImage: "number.circle.fill")
                                .foregroundStyle(Color.charinSolana)
                            Spacer()
                            TextField("T1234567890123", text: $registrationNumber)
                                .multilineTextAlignment(.trailing)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.primary)
                                .autocapitalization(.allCharacters)
                                .onChange(of: registrationNumber) { _, newValue in
                                    let cleaned = newValue.uppercased()
                                    if cleaned.count > 14 {
                                        registrationNumber = String(cleaned.prefix(14))
                                    } else {
                                        registrationNumber = cleaned
                                    }
                                }
                        }
                        Text("適格請求書発行事業者登録番号 (T + 13桁)")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                } header: {
                    Text("インボイス設定")
                }

                // 通知設定
                Section {
                    Button {
                        Task {
                            let center = UNUserNotificationCenter.current()
                            let settings = await center.notificationSettings()
                            if settings.authorizationStatus == .notDetermined {
                                let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
                                if granted == true {
                                    await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
                                    pushStatus = "許可済み"
                                }
                            } else if settings.authorizationStatus == .denied {
                                // 設定アプリに飛ばす
                                await MainActor.run {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            } else {
                                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
                                pushStatus = "許可済み"
                            }
                        }
                    } label: {
                        HStack {
                            Label("プッシュ通知", systemImage: pushStatus == "許可済み" ? "bell.fill" : "bell.badge")
                                .foregroundStyle(pushStatus == "許可済み" ? Color.charinSuccess : Color.charin)
                            Spacer()
                            Text(pushStatus)
                                .font(.system(size: 13))
                                .foregroundStyle(pushStatus == "許可済み" ? Color.charinSuccess : .secondary)
                        }
                    }
                } header: {
                    Text("通知")
                } footer: {
                    Text("売上が入ったときにプッシュ通知でチャリン音が届きます。")
                }

                // Stripe連携
                Section {
                    if charinApiKey.isEmpty {
                        // 未連携 → 連携ボタン
                        Button {
                            Task { await setupStripeLink() }
                        } label: {
                            HStack {
                                Image(systemName: "link.badge.plus")
                                    .foregroundStyle(Color.charin)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Stripeと連携する")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("決済が入るとチャリン音で通知")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if isSettingUp {
                                    ProgressView()
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .disabled(isSettingUp)
                    } else {
                        // 連携済み → Webhook URL表示
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.charinSuccess)
                                Text("Stripe連携済み")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.charinSuccess)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Webhook URL")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                                Text(webhookURL)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Button {
                                UIPasteboard.general.string = webhookURL
                                copiedWebhook = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedWebhook = false }
                            } label: {
                                HStack {
                                    Image(systemName: copiedWebhook ? "checkmark" : "doc.on.doc")
                                    Text(copiedWebhook ? "コピーしました" : "Webhook URLをコピー")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(copiedWebhook ? Color.charinSuccess : Color.charin)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            Button(role: .destructive) {
                                charinApiKey = ""
                            } label: {
                                Text("連携を解除")
                                    .font(.system(size: 12))
                            }
                        }
                    }
                } header: {
                    Text("売上自動連携 (Stripe)")
                } footer: {
                    if charinApiKey.isEmpty {
                        Text("Stripeの売上が入るたびに、チャリン音とともに収入が自動記録されます。")
                    } else {
                        Text("上のWebhook URLをStripe Dashboard → Developers → Webhooks に追加してください。イベントは checkout.session.completed, invoice.paid, payment_intent.succeeded を選択。")
                    }
                }

                // Stats
                Section {
                    HStack {
                        Label("総取引数", systemImage: "number.circle.fill")
                            .foregroundStyle(Color.charin)
                        Spacer()
                        Text("\(totalCount)件").foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("累計収入 (JPY)", systemImage: "yensign.circle.fill")
                            .foregroundStyle(Color.charinSuccess)
                        Spacer()
                        Text("\u{00A5}\(totalJPY.formatted())")
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.charinSuccess)
                    }
                    HStack {
                        Label("未入金", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.charinWarn)
                        Spacer()
                        Text("\(unpaidCount)件").foregroundStyle(Color.charinWarn)
                    }
                } header: { Text("統計") }

                // CSV Export via Email
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(Color.charinAccent)
                            TextField("メールアドレスを入力", text: $csvEmail)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                        }

                        Button {
                            sendCSVByEmail()
                        } label: {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("CSVをメールで送信")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                csvEmail.contains("@") && !allIncome.isEmpty
                                    ? Color.charinAccent
                                    : Color.charinAccent.opacity(0.3)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(!csvEmail.contains("@") || allIncome.isEmpty)
                    }

                    Button {
                        showExportSheet = true
                    } label: {
                        Label("その他の方法でエクスポート", systemImage: "square.and.arrow.up")
                            .font(.system(size: 14))
                    }
                } header: {
                    Text("確定申告CSVエクスポート")
                } footer: {
                    Text("メールアドレスを入力すると、確定申告用CSVファイルをメールで送信します。freee・マネーフォワードにそのまま取り込めます。")
                }

                // Send to Sakutsu
                Section {
                    Button {
                        sendToSakutsu()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color(hex: "3B82F6"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("サクッに送る")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("確定申告アプリにデータを送信")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("姉妹アプリ連携")
                } footer: {
                    Text("チャリンの収入データをサクッ（確定申告）に送って、事業所得として反映できます。")
                }

                // Sister Apps
                Section {
                    sisterRow("パシャ", sub: "レシート撮影・経費管理", icon: "camera.fill", hex: "F72585", url: "https://pasha.run")
                    sisterRow("ポン", sub: "契約書作成・電子署名", icon: "signature", hex: "7B2FBE", url: "https://pasha.run/pon")
                    sisterRow("ポイッ", sub: "不用品の出品・査定サポート", icon: "shippingbox.fill", hex: "06D6A0", url: "https://pasha.run/poi")
                    sisterRow("サクッ", sub: "確定申告・青色申告対応", icon: "checkmark.seal.fill", hex: "3B82F6", url: "https://pasha.run/sakutsu")
                } header: {
                    Text("姉妹アプリ")
                } footer: {
                    Text("フリーランスに必要な機能をアプリで分担。全データはサクッに集めて確定申告できます。")
                }

                // About
                Section {
                    HStack {
                        Text("バージョン"); Spacer()
                        Text("1.0.0").foregroundStyle(.secondary)
                    }
                } header: {
                    Text("チャリンについて")
                } footer: {
                    Text("チャリン - 届いた、チャリン。収入はチャリン、支出はパシャ。")
                }

                // Subscription
                Section {
                    if sub.isPro {
                        HStack {
                            Label("Proプラン", systemImage: "crown.fill").foregroundStyle(Color.charin)
                            Spacer()
                            Text("有効").foregroundStyle(Color.charinSuccess).font(.subheadline.weight(.semibold))
                        }
                        if let exp = sub.expirationDate {
                            HStack {
                                Label("次回更新", systemImage: "arrow.clockwise").foregroundStyle(.secondary)
                                Spacer()
                                Text(exp, style: .date).foregroundStyle(.secondary)
                            }
                        }
                        Button { Task { await sub.restorePurchases() } } label: {
                            Label("購入を復元する", systemImage: "arrow.counterclockwise").foregroundStyle(Color.charin)
                        }
                    } else {
                        Button { showProGate = true } label: {
                            HStack {
                                Image(systemName: "crown.fill").foregroundStyle(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Proにアップグレード").font(.subheadline.weight(.semibold))
                                    Text("無制限請求書・PDFエクスポート・CSV確定申告").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(sub.formattedPrice).font(.subheadline.weight(.bold)).foregroundStyle(Color.charin)
                            }
                        }
                        Button { Task { await sub.restorePurchases() } } label: {
                            Label("購入を復元する", systemImage: "arrow.counterclockwise").foregroundStyle(Color.charin)
                        }
                    }
                } header: { Text("サブスクリプション") }

                // Danger
                Section {
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Label("全データ削除", systemImage: "trash.fill")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.charinBg)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                let s = await UNUserNotificationCenter.current().notificationSettings()
                switch s.authorizationStatus {
                case .authorized, .provisional: pushStatus = "許可済み"
                case .denied: pushStatus = "設定で許可してください"
                case .notDetermined: pushStatus = "タップして許可"
                default: pushStatus = "不明"
                }
            }
            .sheet(isPresented: $showProGate) {
                ProGateView().presentationDetents([.large])
            }
            .sheet(isPresented: $showExportSheet) {
                ActivityView(items: [exportCSV()])
            }
            .sheet(isPresented: $showMailCompose) {
                MailComposeView(
                    subject: "チャリン 確定申告用CSVデータ",
                    recipients: [csvEmail],
                    body: "チャリンから確定申告用CSVデータをお送りします。\n\n添付のCSVファイルをfreee・マネーフォワードにそのまま取り込めます。\n\n件数: \(allIncome.count)件\n合計: \u{00A5}\(totalJPY.formatted())\n\n---\nGenerated by Charin",
                    attachmentData: exportCSV().data(using: .utf8),
                    attachmentMimeType: "text/csv",
                    attachmentFileName: csvFileName
                )
            }
            .alert("全データを削除しますか？", isPresented: $showDeleteAlert) {
                Button("削除する", role: .destructive) {
                    for income in allIncome { context.delete(income) }
                }
                Button("キャンセル", role: .cancel) {}
            } message: { Text("この操作は取り消せません。") }
            .alert("送信完了", isPresented: $showEmailSent) {
                Button("OK") {}
            } message: { Text("\(csvEmail) にCSVを送信しました。") }
        }
    }

    // MARK: - Send to Sakutsu

    private func sendToSakutsu() {
        let incomeBySource = Dictionary(grouping: allIncome, by: \.source)
            .mapValues { items in items.reduce(0) { $0 + $1.amount } }
        let totalIncome = allIncome.filter { $0.currency == "JPY" }.reduce(0) { $0 + $1.amount }

        let data: [String: Any] = [
            "app": "charin",
            "type": "income",
            "totalIncome": totalIncome,
            "bySource": incomeBySource,
            "count": allIncome.count,
            "year": Calendar.current.component(.year, from: .now)
        ]

        if let json = try? JSONSerialization.data(withJSONObject: data),
           let str = String(data: json, encoding: .utf8) {
            UIPasteboard.general.string = "SAKUTSU_IMPORT:" + str
            if let url = URL(string: "sakutsu://import?source=charin") {
                UIApplication.shared.open(url)
            }
        }
    }

    // MARK: - Send CSV

    private func sendCSVByEmail() {
        if MFMailComposeViewController.canSendMail() {
            showMailCompose = true
        } else {
            // Fallback: use share sheet with pre-filled email
            showExportSheet = true
        }
    }

    private var csvFileName: String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return "charin_\(f.string(from: .now)).csv"
    }

    private func exportCSV() -> String {
        var csv = "\u{FEFF}日付,ソース,金額,通貨,カテゴリ,税率,税抜金額,消費税,入金状態,支払方法,メモ,請求書番号,登録番号\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for inc in allIncome {
            csv += "\(formatter.string(from: inc.date)),\(inc.source),\(inc.amount),\(inc.currency),\(inc.category),\(inc.taxRate)%,\(inc.subtotal),\(inc.taxAmount),\(inc.paymentStatus),\(inc.paymentMethod),\(inc.memo),\(inc.invoiceNumber),\(inc.registrationNumber)\n"
        }
        return csv
    }

    @ViewBuilder
    private func sisterRow(_ name: String, sub: String, icon: String, hex: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(Color(hex: hex))
                    .font(.title3)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Stripe Setup

    private func setupStripeLink() async {
        isSettingUp = true
        defer { isSettingUp = false }

        let label = userName.isEmpty ? "チャリンユーザー" : userName
        guard let url = URL(string: "https://kacha-server.fly.dev/api/v1/charin/apikey") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["user_label": label])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 201 else { return }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let key = json["api_key"] as? String {
                await MainActor.run {
                    charinApiKey = key
                    SoundPlayer.shared.play("charin")
                }
            }
        } catch {
            print("[Charin] Setup error: \(error)")
        }
    }
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let recipients: [String]
    let body: String
    let attachmentData: Data?
    let attachmentMimeType: String
    let attachmentFileName: String

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(subject)
        vc.setToRecipients(recipients)
        vc.setMessageBody(body, isHTML: false)
        if let data = attachmentData {
            vc.addAttachmentData(data, mimeType: attachmentMimeType, fileName: attachmentFileName)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        init(_ parent: MailComposeView) { self.parent = parent }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}
