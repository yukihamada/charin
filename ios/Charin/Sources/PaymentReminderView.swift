import SwiftUI
import MessageUI

// MARK: - Payment Reminder View

struct PaymentReminderView: View {
    @Environment(\.dismiss) private var dismiss
    let income: Income

    @State private var selectedTemplate: ReminderTemplate = .first
    @State private var messageBody: String = ""
    @State private var showMailCompose = false
    @State private var mailResult: MFMailComposeResult?
    @State private var showCopied = false

    enum ReminderTemplate: CaseIterable {
        case first, second, final_notice

        var label: String {
            switch self {
            case .first:        return "1回目催促"
            case .second:       return "2回目催促"
            case .final_notice: return "最終通告"
            }
        }

        var icon: String {
            switch self {
            case .first:        return "envelope.fill"
            case .second:       return "envelope.badge.fill"
            case .final_notice: return "exclamationmark.triangle.fill"
            }
        }

        var color: Color {
            switch self {
            case .first:        return .charinWarn
            case .second:       return .orange
            case .final_notice: return .red
            }
        }

        func message(source: String, amount: String, daysOverdue: Int, dueDate: String) -> String {
            switch self {
            case .first:
                return """
                お世話になっております。

                \(source) のご請求金額 \(amount) につきまして、お振込みのご確認をお願いしたくご連絡いたしました。

                支払期日：\(dueDate)（\(daysOverdue)日経過）

                お振込みの手続きがお済みの場合は、本メールにご返信いただけますと幸いです。ご不明な点がございましたら、お気軽にお問い合わせください。

                引き続き、よろしくお願いいたします。
                """

            case .second:
                return """
                お世話になっております。

                先日、\(source) のご請求金額 \(amount) のお支払いについてご連絡いたしましたが、現在もご入金が確認できておりません。

                支払期日：\(dueDate)（\(daysOverdue)日経過）

                誠に恐れ入りますが、お早めにお振込みのご手続きをお願い申し上げます。

                すでにお手続き済みの場合は、大変失礼いたしました。本メールにてご連絡いただけますと幸いです。

                何卒よろしくお願いいたします。
                """

            case .final_notice:
                let deadline = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                    .map { DateFormatter.mediumJP.string(from: $0) } ?? "7日以内"
                return """
                お世話になっております。

                \(source) のご請求金額 \(amount) について、複数回にわたりご連絡を差し上げましたが、現在もご入金が確認できておりません。

                支払期日：\(dueDate)（\(daysOverdue)日経過）

                誠に遺憾ながら、\(deadline) までにご入金がない場合は、やむを得ず法的手続きを含む措置を取らせていただく場合がございます。

                お支払いにつきましては、至急ご対応いただきますよう最終のご通知を申し上げます。

                なお、本件に関するご不明点やご事情がございましたら、至急ご連絡ください。

                よろしくお願いいたします。
                """
            }
        }
    }

    private var daysOverdue: Int {
        guard let due = income.nextDueDate else {
            return Int(Date().timeIntervalSince(income.date) / 86400)
        }
        return max(0, Int(Date().timeIntervalSince(due) / 86400))
    }

    private var dueDateString: String {
        guard let due = income.nextDueDate else {
            return DateFormatter.mediumJP.string(from: income.date)
        }
        return DateFormatter.mediumJP.string(from: due)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.charinBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Invoice summary
                        summaryCard

                        // Template selector
                        templateSelector

                        // Editable message body
                        messageEditor

                        // Action buttons
                        actionButtons
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("入金催促")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }.foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showMailCompose) {
                ReminderMailComposeView(
                    recipient: income.source,
                    subject: "【ご入金のお願い】\(income.source) \(income.formattedAmount)",
                    body: messageBody
                )
            }
        }
        .onAppear { refreshMessage() }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(income.source)
                    .font(.system(size: 16, weight: .bold))
                HStack(spacing: 8) {
                    Text(income.formattedAmount)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.charinSuccess)
                    Text("未入金")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
                Text("期日: \(dueDateString)（\(daysOverdue)日超過）")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Template Selector

    private var templateSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("テンプレート")
            HStack(spacing: 8) {
                ForEach(ReminderTemplate.allCases, id: \.self) { tmpl in
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            selectedTemplate = tmpl
                            refreshMessage()
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tmpl.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(selectedTemplate == tmpl ? tmpl.color : .secondary)
                            Text(tmpl.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(selectedTemplate == tmpl ? tmpl.color : .secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTemplate == tmpl ? tmpl.color.opacity(0.1) : .white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(selectedTemplate == tmpl ? tmpl.color : .white.opacity(0.06),
                                              lineWidth: selectedTemplate == tmpl ? 1.5 : 0.5)
                        )
                    }
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Message Editor

    private var messageEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("メッセージ本文")
                Spacer()
                Button {
                    refreshMessage()
                } label: {
                    Label("リセット", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            Text("内容は自由に編集できます")
                .font(.system(size: 11)).foregroundStyle(.tertiary)

            TextEditor(text: $messageBody)
                .font(.system(size: 13))
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(Color.charinCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.06)))
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Mail
            if MFMailComposeViewController.canSendMail() {
                Button {
                    showMailCompose = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                        Text("メールで送信")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.charin)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                }
            } else {
                // Fallback: share sheet with mailto
                ShareLink(item: "mailto:?subject=\(mailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(messageBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                        Text("メールで送信")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.charin)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                }
            }

            HStack(spacing: 10) {
                // LINE
                Button {
                    sendViaLine()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                        Text("LINEで送信")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(Color(red: 0.05, green: 0.71, blue: 0.29))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Copy
                Button {
                    UIPasteboard.general.string = messageBody
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation { showCopied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showCopied = false }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                        Text(showCopied ? "コピー済み" : "コピー")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(showCopied ? Color.charinSuccess : Color.charin)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background((showCopied ? Color.charinSuccess : Color.charin).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder((showCopied ? Color.charinSuccess : Color.charin).opacity(0.2)))
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Helpers

    private func refreshMessage() {
        messageBody = selectedTemplate.message(
            source: income.source,
            amount: income.formattedAmount,
            daysOverdue: daysOverdue,
            dueDate: dueDateString
        )
    }

    private func sendViaLine() {
        let encoded = messageBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "line://msg/text/\(encoded)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "https://line.me/R/msg/text/?\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private var mailSubject: String {
        "【ご入金のお願い】\(income.source) \(income.formattedAmount)"
    }

    private func sectionLabel(_ t: String) -> some View {
        Text(t).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            .textCase(.uppercase).tracking(1)
    }
}

// MARK: - Mail Compose (used internally by PaymentReminderView)

private struct ReminderMailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}

// MARK: - DateFormatter helper

extension DateFormatter {
    static let mediumJP: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日"
        return f
    }()
}
