import SwiftUI
import SwiftData

struct IncomeDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var income: Income
    @State private var showDeleteConfirm = false
    @State private var showShareSheet = false
    @State private var showInvoicePreview = false
    @State private var shareItems: [Any] = []
    @State private var showReminder = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Amount hero
                VStack(spacing: 4) {
                    Text(income.formattedAmount)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.charinSuccess)
                    Text(income.source)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                    // Payment status badge
                    paymentStatusBadge
                        .padding(.top, 4)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .glassCard()

                // Details card
                VStack(spacing: 0) {
                    DetailRow(label: "日付", value: income.date.formatted(date: .long, time: .omitted))
                    DetailRow(label: "ソース", value: income.source)
                    DetailRow(label: "カテゴリ", value: income.categoryLabel, color: Color.categoryColor(for: income.category))
                    DetailRow(label: "通貨", value: income.currency)
                    DetailRow(label: "請求書番号", value: income.invoiceNumber.isEmpty ? "-" : income.invoiceNumber, mono: true)
                    if !income.registrationNumber.isEmpty {
                        DetailRow(label: "登録番号", value: income.registrationNumber, mono: true)
                    }
                    if !income.memo.isEmpty {
                        DetailRow(label: "メモ", value: income.memo)
                    }
                    DetailRow(label: "登録日時", value: income.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
                .glassCard()

                // Tax breakdown card
                VStack(spacing: 0) {
                    DetailRow(label: "税率", value: "\(income.taxRate)%")
                    DetailRow(label: "税抜金額", value: income.formattedSubtotal)
                    DetailRow(label: "消費税", value: income.formattedTax)
                    DetailRow(label: "合計 (税込)", value: income.formattedAmount)
                }
                .glassCard()

                // Payment info card
                VStack(spacing: 0) {
                    HStack {
                        Text("入金状態")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Spacer()
                        paymentStatusBadge
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(.white.opacity(0.04)).frame(height: 0.5)
                    }

                    DetailRow(label: "支払方法", value: income.paymentMethodLabel)

                    if income.paymentStatus == "paid", let paidAt = income.paidAt {
                        DetailRow(label: "入金日", value: paidAt.formatted(date: .long, time: .omitted))
                    }

                    if income.isRecurring {
                        DetailRow(label: "定期請求", value: income.recurringIntervalLabel, color: Color.charinSolana)
                        if let nextDue = income.nextDueDate {
                            DetailRow(label: "次回請求日", value: nextDue.formatted(date: .long, time: .omitted))
                        }
                    }

                    // Payment action buttons
                    HStack(spacing: 8) {
                        if income.paymentStatus != "paid" {
                            Button {
                                income.paymentStatus = "paid"
                                income.paidAt = .now
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("入金済にする")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.charinSuccess, in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        if income.paymentStatus == "paid" {
                            Button {
                                income.paymentStatus = "unpaid"
                                income.paidAt = nil
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text("未入金に戻す")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.charinWarn)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.charinWarn.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(12)
                }
                .glassCard()

                // Send Invoice (Primary action)
                VStack(spacing: 10) {
                    // Preview & Send PDF
                    Button {
                        showInvoicePreview = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("請求書をプレビュー & 送信")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("PDF プレビュー → メール・AirDrop・LINE")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Spacer()
                            Image(systemName: "eye.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [Color.charin, Color.charinAccent],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Quick image share (for LINE)
                    Button {
                        shareImage()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16))
                            Text("画像でLINEに送る")
                                .font(.system(size: 14, weight: .semibold))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(Color.charinSuccess.opacity(0.15))
                        .foregroundStyle(Color.charinSuccess)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.charinSuccess.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .glassCard()

                // Reminder button (only for unpaid)
                if income.paymentStatus != "paid" {
                    Button {
                        showReminder = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bell.badge.fill")
                            Text("入金催促メールを送る")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.red.opacity(0.15)))
                    }
                    .glassCard()
                }

                // Secondary actions
                HStack(spacing: 12) {
                    // Text share
                    ShareLink(
                        item: invoiceText,
                        subject: Text("チャリン 請求書"),
                        message: Text(income.invoiceNumber)
                    ) {
                        Label("テキスト共有", systemImage: "text.bubble")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.charin.opacity(0.12))
                            .foregroundStyle(Color.charin)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Delete
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("削除", systemImage: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.12))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .glassCard()
            }
            .padding()
        }
        .background(Color.charinBg)
        .navigationTitle("収入詳細")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("この収入を削除しますか？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                context.delete(income)
                dismiss()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(items: shareItems)
        }
        .fullScreenCover(isPresented: $showInvoicePreview) {
            InvoicePreviewView(income: income)
        }
        .sheet(isPresented: $showReminder) {
            PaymentReminderView(income: income)
        }
    }

    // MARK: - Payment Status Badge

    private var paymentStatusBadge: some View {
        let (label, color): (String, Color) = {
            switch income.paymentStatus {
            case "paid": return ("入金済", .charinSuccess)
            case "overdue": return ("期限超過", .red)
            default: return ("未入金", .charinWarn)
            }
        }()
        return Text(label)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    // MARK: - Share PDF

    private func sharePDF() {
        let pdfData = InvoiceRenderer.generatePDF(for: income)
        let filename = "\(income.invoiceNumber.isEmpty ? "invoice" : income.invoiceNumber).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? pdfData.write(to: tempURL)
        shareItems = [tempURL]
        showShareSheet = true
    }

    // MARK: - Share Image (for LINE)

    private func shareImage() {
        guard let image = InvoiceRenderer.generateImage(for: income) else { return }
        shareItems = [image]
        showShareSheet = true
    }

    private var invoiceText: String {
        """
        チャリン 請求書
        ─────────────
        番号: \(income.invoiceNumber)
        登録番号: \(income.registrationNumber.isEmpty ? "-" : income.registrationNumber)
        日付: \(income.date.formatted(date: .long, time: .omitted))
        ソース: \(income.source)
        カテゴリ: \(income.categoryLabel)
        ─────────────
        税抜金額: \(income.formattedSubtotal)
        消費税(\(income.taxRate)%): \(income.formattedTax)
        合計: \(income.formattedAmount)
        ─────────────
        入金状態: \(income.paymentStatusLabel)
        支払方法: \(income.paymentMethodLabel)
        支払条件: 翌月末日払い
        メモ: \(income.memo.isEmpty ? "-" : income.memo)
        ─────────────
        Generated by Charin
        """
    }
}

// MARK: - ActivityView (UIKit Share Sheet)

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    var color: Color? = nil
    var mono: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            if let color {
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.12))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            } else if mono {
                Text(value)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.charinSolana)
            } else {
                Text(value)
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.04))
                .frame(height: 0.5)
        }
    }
}
