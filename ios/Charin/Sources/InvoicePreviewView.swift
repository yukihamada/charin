import SwiftUI
import PDFKit
import UIKit

struct InvoicePreviewView: View {
    let income: Income
    @State private var selectedTemplate: InvoiceTemplate = .darkPro
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.charinBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Template selector
                    templatePicker
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // PDF Preview
                    PDFPreviewRepresentable(
                        data: InvoiceRenderer.generatePDF(for: income, template: selectedTemplate)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .id(selectedTemplate.id) // force refresh on change

                    // Action buttons
                    actionButtons
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
            .navigationTitle("請求書プレビュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityView(items: shareItems)
            }
        }
    }

    // MARK: - Template Picker

    private var templatePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InvoiceTemplate.allCases) { tmpl in
                    templateCard(tmpl)
                }
            }
        }
    }

    private func templateCard(_ tmpl: InvoiceTemplate) -> some View {
        let isSelected = selectedTemplate == tmpl
        let colors = tmpl.previewColors
        return Button {
            withAnimation(.spring(duration: 0.3)) {
                selectedTemplate = tmpl
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 6) {
                // Mini preview swatch
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colors.0)
                        .frame(width: 56, height: 72)
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colors.1)
                            .frame(width: 30, height: 2)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(colors.1.opacity(0.4))
                            .frame(width: 24, height: 1.5)
                        Spacer().frame(height: 4)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(colors.1.opacity(0.3))
                            .frame(width: 36, height: 1.5)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(colors.1.opacity(0.3))
                            .frame(width: 36, height: 1.5)
                        Spacer().frame(height: 6)
                        Text(chr(0xa5))
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(colors.1)
                    }
                    .padding(8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isSelected ? Color.charin : .white.opacity(0.06),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                )

                // Label
                Text(tmpl.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.charin : Color.secondary)
            }
        }
    }

    private func chr(_ v: UInt32) -> String { String(UnicodeScalar(v)!) }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { sharePDF() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                    Text("メール")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [Color.charin, Color.charinAccent],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button { shareImage() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text("LINE")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [Color.charinSuccess, Color.charin],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button { sharePDF() } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.charin)
                    .frame(width: 50, height: 50)
                    .background(Color.charin.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Share

    private func sharePDF() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let data = InvoiceRenderer.generatePDF(for: income, template: selectedTemplate)
        let filename = "\(income.invoiceNumber.isEmpty ? "invoice" : income.invoiceNumber).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        shareItems = [url]
        showShareSheet = true
    }

    private func shareImage() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        guard let image = InvoiceRenderer.generateImage(for: income, template: selectedTemplate) else { return }
        shareItems = [image]
        showShareSheet = true
    }
}

// MARK: - PDFKit Preview

struct PDFPreviewRepresentable: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.backgroundColor = UIColor(red: 0.059, green: 0.059, blue: 0.102, alpha: 1)
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}
