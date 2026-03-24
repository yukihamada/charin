import UIKit
import SwiftUI

// MARK: - Template Enum

enum InvoiceTemplate: String, CaseIterable, Identifiable {
    case darkPro = "Dark Pro"
    case classicWhite = "Classic"
    case minimal = "Minimal"
    case neon = "Neon"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .darkPro: return "moon.fill"
        case .classicWhite: return "doc.text.fill"
        case .minimal: return "square.fill"
        case .neon: return "sparkles"
        }
    }

    var previewColors: (Color, Color) {
        switch self {
        case .darkPro: return (Color(hex: "0F0F1A"), Color(hex: "4CC9F0"))
        case .classicWhite: return (.white, Color(hex: "1a1a1a"))
        case .minimal: return (Color(hex: "FAFAFA"), Color(hex: "333333"))
        case .neon: return (Color(hex: "0a0014"), Color(hex: "FF006E"))
        }
    }
}

// MARK: - Invoice Renderer

struct InvoiceRenderer {

    // Brand colors
    private static let cyan = UIColor(red: 0.298, green: 0.788, blue: 0.941, alpha: 1)
    private static let orange = UIColor(red: 0.969, green: 0.498, blue: 0, alpha: 1)
    private static let green = UIColor(red: 0.024, green: 0.839, blue: 0.627, alpha: 1)
    private static let purple = UIColor(red: 0.6, green: 0.271, blue: 1, alpha: 1)
    private static let magenta = UIColor(red: 0.969, green: 0.145, blue: 0.522, alpha: 1)
    private static let neonPink = UIColor(red: 1, green: 0, blue: 0.431, alpha: 1)
    private static let neonBlue = UIColor(red: 0, green: 0.812, blue: 1, alpha: 1)

    // MARK: - Public API

    static func generatePDF(for income: Income, template: InvoiceTemplate = .darkPro) -> Data {
        switch template {
        case .darkPro: return darkProPDF(income)
        case .classicWhite: return classicWhitePDF(income)
        case .minimal: return minimalPDF(income)
        case .neon: return neonPDF(income)
        }
    }

    static func generateImage(for income: Income, template: InvoiceTemplate = .darkPro) -> UIImage? {
        switch template {
        case .darkPro: return darkProImage(income)
        case .classicWhite: return classicWhiteImage(income)
        case .minimal: return minimalImage(income)
        case .neon: return neonImage(income)
        }
    }

    // MARK: - Registration number helper
    private static func regNum(_ i: Income) -> String {
        let r = i.registrationNumber
        if r.isEmpty {
            let stored = UserDefaults.standard.string(forKey: "invoiceRegistrationNumber") ?? ""
            return stored.isEmpty ? "" : stored
        }
        return r
    }

    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: 1) DARK PRO
    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static func darkProPDF(_ inc: Income) -> Data {
        let pw: CGFloat = 595; let ph: CGFloat = 842; let m: CGFloat = 50
        let cw = pw - m * 2
        let bg = UIColor(red: 0.059, green: 0.059, blue: 0.102, alpha: 1)
        let card = UIColor(red: 0.086, green: 0.129, blue: 0.243, alpha: 1)
        let dim = UIColor(white: 1, alpha: 0.4)
        let faint = UIColor(white: 1, alpha: 0.06)

        return pdfRender(pw, ph) { g, ctx in
            var y: CGFloat = 0
            bg.setFill(); g.fill(CGRect(x: 0, y: 0, width: pw, height: ph))
            drawGrad(g, CGRect(x: 0, y: 0, width: pw, height: 5), cyan, orange)
            y = m

            // Header card
            card.setFill()
            let hr = CGRect(x: m-16, y: y-10, width: cw+32, height: 110)
            UIBezierPath(roundedRect: hr, cornerRadius: 12).fill()
            faint.setStroke(); UIBezierPath(roundedRect: hr, cornerRadius: 12).lineWidth = 0.5
            UIBezierPath(roundedRect: hr, cornerRadius: 12).stroke()

            txt("CHARIN", m, y, .systemFont(ofSize: 10, weight: .black), dim)
            txt("請求書", m, y+18, .systemFont(ofSize: 34, weight: .bold), .white)
            txt("INVOICE", m+108, y+34, .systemFont(ofSize: 12, weight: .medium), dim)
            txtR(invNum(inc), pw-m, y+4, .monospacedSystemFont(ofSize: 12, weight: .semibold), purple)
            txtR("発行日: "+dateLong(inc.date), pw-m, y+24, .systemFont(ofSize: 10, weight: .medium), dim)
            // Registration number
            let rn = regNum(inc)
            if !rn.isEmpty {
                txtR("登録番号: \(rn)", pw-m, y+40, .monospacedSystemFont(ofSize: 9, weight: .medium), purple)
            }
            badge(inc, m, y+70)
            y += 126

            fromTo(inc, m, y, cw, dim, .white)
            y += 60; line(g, y, m, cw, faint); y += 16
            tableRowWithTax(g, inc, m, pw, y, cw, card, dim, faint, .white, green)
            y += 130; line(g, y, m, cw, faint); y += 24
            totalBlock(inc, pw, m, y, dim, green)
            y += 70; drawGrad(g, CGRect(x: pw-m-200, y: y, width: 200, height: 2), cyan, orange)
            y += 24; infoBox(g, inc, m, y, cw, card, faint, dim, .white, purple, green)
            y += 80
            // Payment terms
            paymentTerms(m, y, dim)
            y += 30
            footer(g, inc, m, y, pw, ph, cw, faint, cyan, orange)
        }
    }

    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: 2) CLASSIC WHITE
    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static func classicWhitePDF(_ inc: Income) -> Data {
        let pw: CGFloat = 595; let ph: CGFloat = 842; let m: CGFloat = 50
        let cw = pw - m * 2
        let dark = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        let mid = UIColor(white: 0.45, alpha: 1)
        let lightBg = UIColor(white: 0.97, alpha: 1)
        let borderC = UIColor(white: 0.88, alpha: 1)
        let accent = UIColor(red: 0.298, green: 0.788, blue: 0.941, alpha: 1)

        return pdfRender(pw, ph) { g, ctx in
            var y: CGFloat = 0
            UIColor.white.setFill(); g.fill(CGRect(x: 0, y: 0, width: pw, height: ph))

            // Top color bar
            accent.setFill(); g.fill(CGRect(x: 0, y: 0, width: pw, height: 4))
            y = m

            txt("CHARIN", m, y, .systemFont(ofSize: 9, weight: .heavy), mid)
            txt("請求書", m, y+16, .systemFont(ofSize: 30, weight: .bold), dark)
            txt("INVOICE", m+96, y+30, .systemFont(ofSize: 11, weight: .medium), mid)
            txtR(invNum(inc), pw-m, y+4, .monospacedSystemFont(ofSize: 11, weight: .semibold), accent)
            txtR("発行日: "+dateLong(inc.date), pw-m, y+22, .systemFont(ofSize: 10, weight: .medium), mid)
            let rn = regNum(inc)
            if !rn.isEmpty {
                txtR("登録番号: \(rn)", pw-m, y+38, .monospacedSystemFont(ofSize: 9, weight: .medium), accent)
            }
            y += 64

            line(g, y, m, cw, borderC); y += 20
            fromTo(inc, m, y, cw, mid, dark)
            y += 60; line(g, y, m, cw, borderC); y += 16

            // Table header
            lightBg.setFill(); g.fill(CGRect(x: m, y: y, width: cw, height: 32))
            borderC.setFill(); g.fill(CGRect(x: m, y: y+31.5, width: cw, height: 0.5))
            let th = UIFont.systemFont(ofSize: 8, weight: .bold)
            txt("項目", m+12, y+11, th, mid); txt("説明", m+200, y+11, th, mid)
            txtR("金額", pw-m-12, y+11, th, mid)
            y += 32

            // Item row
            txt("\(inc.source) — \(inc.categoryLabel)", m+12, y+10, .systemFont(ofSize: 12, weight: .medium), dark)
            let memo = inc.memo.isEmpty ? "-" : inc.memo
            txt(memo, m+200, y+11, .systemFont(ofSize: 10), mid)
            txtR(inc.formattedSubtotal, pw-m-12, y+9, .systemFont(ofSize: 13, weight: .bold), dark)
            y += 36

            // Tax row
            borderC.setFill(); g.fill(CGRect(x: m, y: y, width: cw, height: 0.5))
            y += 8
            txt("消費税 (\(inc.taxRate)%)", m+12, y+4, .systemFont(ofSize: 11, weight: .medium), mid)
            txtR(inc.formattedTax, pw-m-12, y+3, .systemFont(ofSize: 12, weight: .semibold), mid)
            y += 28

            line(g, y, m, cw, borderC); y += 24

            txtR("合計 / TOTAL", pw-m, y, .systemFont(ofSize: 9, weight: .bold), mid)
            y += 14
            txtR(inc.formattedAmount, pw-m, y, .systemFont(ofSize: 34, weight: .heavy), dark)
            y += 50; accent.setFill(); g.fill(CGRect(x: pw-m-160, y: y, width: 160, height: 2))
            y += 30

            // Payment terms
            paymentTerms(m, y, mid)
            y += 30

            // Footer
            line(g, y, m, cw, borderC); y += 14
            let fc = UIColor(white: 0.6, alpha: 1)
            let ff = UIFont.systemFont(ofSize: 9)
            txt("請求書番号: \(invNum(inc))", m, y, ff, fc); y += 13
            let regStr = rn.isEmpty ? "" : " | 登録番号: \(rn)"
            txt("通貨: \(inc.currency) | ステータス: \(inc.paymentStatusLabel)\(regStr)", m, y, ff, fc); y += 18
            txt("Generated by Charin", m, y, .systemFont(ofSize: 8, weight: .medium), UIColor(white: 0.8, alpha: 1))
            accent.setFill(); g.fill(CGRect(x: 0, y: ph-4, width: pw, height: 4))
        }
    }

    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: 3) MINIMAL
    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static func minimalPDF(_ inc: Income) -> Data {
        let pw: CGFloat = 595; let ph: CGFloat = 842; let m: CGFloat = 60
        let cw = pw - m * 2
        let dark = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
        let mid = UIColor(white: 0.5, alpha: 1)
        let bg = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
        let faintLine = UIColor(white: 0.9, alpha: 1)

        return pdfRender(pw, ph) { g, ctx in
            var y: CGFloat = 0
            bg.setFill(); g.fill(CGRect(x: 0, y: 0, width: pw, height: ph))
            y = m + 20

            // Ultra minimal - just text
            txt("請求書", m, y, .systemFont(ofSize: 28, weight: .light), dark)
            txtR(invNum(inc), pw-m, y+6, .monospacedSystemFont(ofSize: 10, weight: .regular), mid)
            y += 40

            // Registration number
            let rn = regNum(inc)
            if !rn.isEmpty {
                txt("登録番号: \(rn)", m, y, .monospacedSystemFont(ofSize: 9, weight: .regular), mid)
                y += 16
            }

            // Thin line
            faintLine.setFill(); g.fill(CGRect(x: m, y: y, width: cw, height: 0.5))
            y += 24

            txt("発行者", m, y, .systemFont(ofSize: 8, weight: .medium), mid)
            txt("Yuki Hamada", m, y+14, .systemFont(ofSize: 13, weight: .regular), dark)
            txtR("発行日", pw-m, y, .systemFont(ofSize: 8, weight: .medium), mid)
            txtR(dateLong(inc.date), pw-m, y+14, .systemFont(ofSize: 13, weight: .regular), dark)
            y += 40

            txt("ソース", m, y, .systemFont(ofSize: 8, weight: .medium), mid)
            txt(inc.source, m, y+14, .systemFont(ofSize: 13, weight: .regular), dark)
            txtR("カテゴリ", pw-m, y, .systemFont(ofSize: 8, weight: .medium), mid)
            txtR(inc.categoryLabel, pw-m, y+14, .systemFont(ofSize: 13, weight: .regular), dark)
            y += 44

            faintLine.setFill(); g.fill(CGRect(x: m, y: y, width: cw, height: 0.5))
            y += 30

            if !inc.memo.isEmpty {
                txt("メモ", m, y, .systemFont(ofSize: 8, weight: .medium), mid)
                txt(inc.memo, m, y+14, .systemFont(ofSize: 11, weight: .regular), dark)
                y += 40
            }

            // Tax breakdown
            txt("税抜金額", m, y, .systemFont(ofSize: 8, weight: .medium), mid)
            txtR(inc.formattedSubtotal, pw-m, y, .systemFont(ofSize: 13, weight: .regular), dark)
            y += 20
            txt("消費税 (\(inc.taxRate)%)", m, y, .systemFont(ofSize: 8, weight: .medium), mid)
            txtR(inc.formattedTax, pw-m, y, .systemFont(ofSize: 13, weight: .regular), mid)
            y += 24

            faintLine.setFill(); g.fill(CGRect(x: m, y: y, width: cw, height: 0.5))
            y += 20

            // Amount - centered, large
            let amtFont = UIFont.systemFont(ofSize: 52, weight: .ultraLight)
            let amtStr = inc.formattedAmount
            let amtW = amtStr.size(withAttributes: [.font: amtFont]).width
            txt(amtStr, (pw - amtW) / 2, y, amtFont, dark)
            y += 70

            txt("合計金額 (税込)", (pw - "合計金額 (税込)".size(withAttributes: [.font: UIFont.systemFont(ofSize: 9)]).width) / 2, y, .systemFont(ofSize: 9, weight: .medium), mid)
            y += 24

            // Payment terms
            let ptText = "支払条件: 翌月末日払い"
            let ptW = ptText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 9)]).width
            txt(ptText, (pw - ptW) / 2, y, .systemFont(ofSize: 9, weight: .medium), mid)
            y += 24

            faintLine.setFill(); g.fill(CGRect(x: m, y: y, width: cw, height: 0.5))
            y += 20

            let fc = UIFont.systemFont(ofSize: 8)
            let regStr = rn.isEmpty ? "" : "  •  \(rn)"
            txt("\(invNum(inc))  •  \(inc.currency)  •  \(inc.paymentStatusLabel)\(regStr)", m, y, fc, mid)
            y += 16
            txt("Charin", m, y, .systemFont(ofSize: 7, weight: .medium), UIColor(white: 0.82, alpha: 1))
        }
    }

    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: 4) NEON
    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static func neonPDF(_ inc: Income) -> Data {
        let pw: CGFloat = 595; let ph: CGFloat = 842; let m: CGFloat = 50
        let cw = pw - m * 2
        let bg = UIColor(red: 0.039, green: 0, blue: 0.078, alpha: 1)
        let card = UIColor(red: 0.078, green: 0.02, blue: 0.14, alpha: 1)
        let dim = UIColor(white: 1, alpha: 0.35)
        let faint = UIColor(red: 1, green: 0, blue: 0.431, alpha: 0.1)

        return pdfRender(pw, ph) { g, ctx in
            var y: CGFloat = 0
            bg.setFill(); g.fill(CGRect(x: 0, y: 0, width: pw, height: ph))
            drawGrad(g, CGRect(x: 0, y: 0, width: pw, height: 3), neonPink, neonBlue)
            y = m

            txt("CHARIN", m, y, .systemFont(ofSize: 10, weight: .black), neonPink.withAlphaComponent(0.6))
            txt("請求書", m, y+18, .systemFont(ofSize: 34, weight: .bold), .white)

            // Neon glow invoice number
            txtR(invNum(inc), pw-m, y+4, .monospacedSystemFont(ofSize: 12, weight: .bold), neonBlue)
            txtR(dateLong(inc.date), pw-m, y+24, .systemFont(ofSize: 10, weight: .medium), dim)
            let rn = regNum(inc)
            if !rn.isEmpty {
                txtR("登録番号: \(rn)", pw-m, y+40, .monospacedSystemFont(ofSize: 9, weight: .medium), neonBlue)
            }
            y += 60

            drawGrad(g, CGRect(x: m, y: y, width: cw, height: 1), neonPink, neonBlue)
            y += 20

            fromTo(inc, m, y, cw, dim, .white)
            y += 60
            drawGrad(g, CGRect(x: m, y: y, width: cw, height: 1), neonPink, neonBlue)
            y += 16

            // Table with neon style
            card.setFill(); g.fill(CGRect(x: m, y: y, width: cw, height: 32))
            faint.setFill(); g.fill(CGRect(x: m, y: y+31.5, width: cw, height: 0.5))
            let th = UIFont.systemFont(ofSize: 8, weight: .bold)
            txt("項目", m+12, y+11, th, dim); txt("説明", m+200, y+11, th, dim)
            txtR("金額", pw-m-12, y+11, th, dim)
            y += 32

            txt("\(inc.source) — \(inc.categoryLabel)", m+12, y+10, .systemFont(ofSize: 12, weight: .medium), .white)
            let memo = inc.memo.isEmpty ? "-" : inc.memo
            txt(memo, m+200, y+11, .systemFont(ofSize: 10), dim)
            txtR(inc.formattedSubtotal, pw-m-12, y+9, .systemFont(ofSize: 13, weight: .bold), neonBlue)
            y += 36

            // Tax row
            txt("消費税 (\(inc.taxRate)%)", m+12, y+4, .systemFont(ofSize: 11, weight: .medium), dim)
            txtR(inc.formattedTax, pw-m-12, y+3, .systemFont(ofSize: 12, weight: .semibold), dim)
            y += 28

            drawGrad(g, CGRect(x: m, y: y, width: cw, height: 1), neonPink, neonBlue)
            y += 24

            txtR("TOTAL", pw-m, y, .systemFont(ofSize: 9, weight: .black), neonPink.withAlphaComponent(0.5))
            y += 14
            txtR(inc.formattedAmount, pw-m, y, .systemFont(ofSize: 38, weight: .heavy), neonPink)
            y += 54
            drawGrad(g, CGRect(x: pw-m-200, y: y, width: 200, height: 2), neonPink, neonBlue)
            y += 30

            // Neon info box
            let bx = CGRect(x: m, y: y, width: cw, height: 46)
            card.setFill(); UIBezierPath(roundedRect: bx, cornerRadius: 8).fill()
            neonPink.withAlphaComponent(0.15).setStroke()
            UIBezierPath(roundedRect: bx, cornerRadius: 8).lineWidth = 0.5
            UIBezierPath(roundedRect: bx, cornerRadius: 8).stroke()
            let sf = UIFont.systemFont(ofSize: 8, weight: .bold)
            txt("通貨", m+14, y+8, sf, dim); txt(inc.currency, m+14, y+22, .systemFont(ofSize: 12, weight: .bold), .white)
            txt("番号", m+120, y+8, sf, dim); txt(invNum(inc), m+120, y+22, .monospacedSystemFont(ofSize: 10, weight: .medium), neonBlue)
            txt("STATUS", m+300, y+8, sf, dim); txt(inc.paymentStatusLabel, m+300, y+22, .systemFont(ofSize: 10, weight: .bold), neonPink)

            y += 66
            // Payment terms
            paymentTerms(m, y, dim)
            y += 24

            drawGrad(g, CGRect(x: m, y: y, width: cw, height: 0.5), neonPink, neonBlue)
            y += 14
            let fc = UIColor(white: 1, alpha: 0.2)
            txt("請求書番号: \(invNum(inc))", m, y, .systemFont(ofSize: 9), fc); y += 18
            txt("Charin // Neon Edition", m, y, .systemFont(ofSize: 7, weight: .bold), neonPink.withAlphaComponent(0.3))

            drawGrad(g, CGRect(x: 0, y: ph-3, width: pw, height: 3), neonPink, neonBlue)
        }
    }

    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: Image generators (1080x1920 for LINE)
    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    private static func darkProImage(_ inc: Income) -> UIImage? {
        imgRender { g, w, h, m in
            let bg = UIColor(red: 0.059, green: 0.059, blue: 0.102, alpha: 1)
            let card = UIColor(red: 0.086, green: 0.129, blue: 0.243, alpha: 1)
            let dim = UIColor(white: 1, alpha: 0.4)
            bg.setFill(); g.fill(CGRect(x: 0, y: 0, width: w, height: h))
            drawGrad(g, CGRect(x: 0, y: 0, width: w, height: 6), cyan, orange)
            imgContent(g, inc, w, h, m, .white, dim, green, purple, card, cyan, orange)
            drawGrad(g, CGRect(x: 0, y: h-6, width: w, height: 6), cyan, orange)
            imgFooter(g, w, h, "Charin — Dark Pro", UIColor(white: 1, alpha: 0.15))
        }
    }

    private static func classicWhiteImage(_ inc: Income) -> UIImage? {
        imgRender { g, w, h, m in
            UIColor.white.setFill(); g.fill(CGRect(x: 0, y: 0, width: w, height: h))
            cyan.setFill(); g.fill(CGRect(x: 0, y: 0, width: w, height: 6))
            let dark = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            let mid = UIColor(white: 0.45, alpha: 1)
            imgContent(g, inc, w, h, m, dark, mid, dark, cyan, UIColor(white: 0.97, alpha: 1), cyan, cyan)
            cyan.setFill(); g.fill(CGRect(x: 0, y: h-6, width: w, height: 6))
            imgFooter(g, w, h, "Charin — Classic", UIColor(white: 0.75, alpha: 1))
        }
    }

    private static func minimalImage(_ inc: Income) -> UIImage? {
        imgRender { g, w, h, m in
            UIColor(white: 0.98, alpha: 1).setFill(); g.fill(CGRect(x: 0, y: 0, width: w, height: h))
            let dark = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
            let mid = UIColor(white: 0.5, alpha: 1)
            imgContent(g, inc, w, h, m, dark, mid, dark, mid, UIColor(white: 0.94, alpha: 1), mid, mid)
            imgFooter(g, w, h, "Charin", UIColor(white: 0.82, alpha: 1))
        }
    }

    private static func neonImage(_ inc: Income) -> UIImage? {
        imgRender { g, w, h, m in
            UIColor(red: 0.039, green: 0, blue: 0.078, alpha: 1).setFill()
            g.fill(CGRect(x: 0, y: 0, width: w, height: h))
            drawGrad(g, CGRect(x: 0, y: 0, width: w, height: 6), neonPink, neonBlue)
            let card = UIColor(red: 0.078, green: 0.02, blue: 0.14, alpha: 1)
            imgContent(g, inc, w, h, m, .white, UIColor(white: 1, alpha: 0.35), neonPink, neonBlue, card, neonPink, neonBlue)
            drawGrad(g, CGRect(x: 0, y: h-6, width: w, height: 6), neonPink, neonBlue)
            imgFooter(g, w, h, "Charin // Neon", neonPink.withAlphaComponent(0.3))
        }
    }

    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: Shared Drawing Helpers
    // MARK: ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // Text
    private static func txt(_ s: String, _ x: CGFloat, _ y: CGFloat, _ f: UIFont, _ c: UIColor) {
        s.draw(at: CGPoint(x: x, y: y), withAttributes: [.font: f, .foregroundColor: c])
    }
    private static func txtR(_ s: String, _ rx: CGFloat, _ y: CGFloat, _ f: UIFont, _ c: UIColor) {
        let a: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: c]
        s.draw(at: CGPoint(x: rx - s.size(withAttributes: a).width, y: y), withAttributes: a)
    }

    // Line
    private static func line(_ g: CGContext, _ y: CGFloat, _ x: CGFloat, _ w: CGFloat, _ c: UIColor) {
        g.setStrokeColor(c.cgColor); g.setLineWidth(0.5)
        g.move(to: CGPoint(x: x, y: y)); g.addLine(to: CGPoint(x: x+w, y: y)); g.strokePath()
    }

    // Gradient bar
    private static func drawGrad(_ g: CGContext, _ r: CGRect, _ c1: UIColor, _ c2: UIColor) {
        guard let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: [c1.cgColor, c2.cgColor] as CFArray, locations: nil) else { return }
        g.saveGState(); g.addRect(r); g.clip()
        g.drawLinearGradient(grad, start: CGPoint(x: r.minX, y: 0), end: CGPoint(x: r.maxX, y: 0), options: [])
        g.restoreGState()
    }

    // Date
    private static func dateLong(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "ja_JP"); f.dateStyle = .long; return f.string(from: d)
    }
    private static func invNum(_ i: Income) -> String { i.invoiceNumber.isEmpty ? "-" : i.invoiceNumber }

    // Badge
    private static func badge(_ i: Income, _ x: CGFloat, _ y: CGFloat) {
        let f = UIFont.systemFont(ofSize: 9, weight: .bold)
        let c = categoryUIColor(i.category)
        let s = i.categoryLabel.size(withAttributes: [.font: f])
        c.withAlphaComponent(0.15).setFill()
        UIBezierPath(roundedRect: CGRect(x: x, y: y, width: s.width+16, height: 20), cornerRadius: 10).fill()
        txt(i.categoryLabel, x+8, y+3, f, c)
    }

    // From/To
    private static func fromTo(_ i: Income, _ m: CGFloat, _ y: CGFloat, _ cw: CGFloat, _ dim: UIColor, _ main: UIColor) {
        let sf = UIFont.systemFont(ofSize: 8, weight: .bold)
        let nf = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let sub = UIFont.systemFont(ofSize: 10)
        let userName = UserDefaults.standard.string(forKey: "userName") ?? "Yuki Hamada"
        txt("発行者 / FROM", m, y, sf, dim)
        txt(userName.isEmpty ? "Yuki Hamada" : userName, m, y+16, nf, main)
        txt("mail@yukihamada.jp", m, y+34, sub, dim)
        let rx = m + cw/2
        txt("宛先 / TO", rx, y, sf, dim)
        txt(i.source, rx, y+16, nf, main)
    }

    // Table row with tax breakdown
    private static func tableRowWithTax(_ g: CGContext, _ i: Income, _ m: CGFloat, _ pw: CGFloat, _ y: CGFloat, _ cw: CGFloat, _ card: UIColor, _ dim: UIColor, _ faint: UIColor, _ main: UIColor, _ amt: UIColor) {
        var y = y
        card.setFill(); g.fill(CGRect(x: m, y: y, width: cw, height: 32))
        faint.setFill(); g.fill(CGRect(x: m, y: y+31.5, width: cw, height: 0.5))
        let th = UIFont.systemFont(ofSize: 8, weight: .bold)
        txt("項目", m+12, y+11, th, dim); txt("説明", m+200, y+11, th, dim)
        txtR("金額", pw-m-12, y+11, th, dim); y += 32

        // Item row (subtotal)
        txt("\(i.source) — \(i.categoryLabel)", m+12, y+10, .systemFont(ofSize: 12, weight: .medium), main)
        txt(i.memo.isEmpty ? "-" : i.memo, m+200, y+11, .systemFont(ofSize: 10), dim)
        txtR(i.formattedSubtotal, pw-m-12, y+9, .systemFont(ofSize: 13, weight: .bold), amt)
        y += 36

        // Separator
        faint.setFill(); g.fill(CGRect(x: m, y: y, width: cw, height: 0.5))
        y += 10

        // Tax row
        txt("消費税 (\(i.taxRate)%)", m+12, y+4, .systemFont(ofSize: 11, weight: .medium), dim)
        txtR(i.formattedTax, pw-m-12, y+3, .systemFont(ofSize: 12, weight: .semibold), dim)
        y += 28

        // Total separator
        faint.setFill(); g.fill(CGRect(x: m, y: y, width: cw, height: 0.5))
    }

    // Total
    private static func totalBlock(_ i: Income, _ pw: CGFloat, _ m: CGFloat, _ y: CGFloat, _ dim: UIColor, _ amt: UIColor) {
        txtR("合計 / TOTAL (税込)", pw-m, y, .systemFont(ofSize: 9, weight: .bold), dim)
        txtR(i.formattedAmount, pw-m, y+16, .systemFont(ofSize: 38, weight: .heavy), amt)
    }

    // Info box
    private static func infoBox(_ g: CGContext, _ i: Income, _ m: CGFloat, _ y: CGFloat, _ cw: CGFloat, _ card: UIColor, _ faint: UIColor, _ dim: UIColor, _ main: UIColor, _ numC: UIColor, _ statC: UIColor) {
        let r = CGRect(x: m, y: y, width: cw, height: 46)
        card.setFill(); UIBezierPath(roundedRect: r, cornerRadius: 8).fill()
        faint.setStroke(); UIBezierPath(roundedRect: r, cornerRadius: 8).lineWidth = 0.5; UIBezierPath(roundedRect: r, cornerRadius: 8).stroke()
        let sf = UIFont.systemFont(ofSize: 8, weight: .bold)
        txt("通貨", m+14, y+8, sf, dim); txt(i.currency, m+14, y+22, .systemFont(ofSize: 12, weight: .bold), main)
        txt("請求書番号", m+120, y+8, sf, dim); txt(invNum(i), m+120, y+22, .monospacedSystemFont(ofSize: 10, weight: .medium), numC)
        txt("ステータス", m+300, y+8, sf, dim); txt(i.paymentStatusLabel, m+300, y+22, .systemFont(ofSize: 10, weight: .semibold), statC)
    }

    // Payment terms
    private static func paymentTerms(_ m: CGFloat, _ y: CGFloat, _ dim: UIColor) {
        txt("支払条件: 翌月末日払い", m, y, .systemFont(ofSize: 9, weight: .medium), dim)
    }

    // Footer
    private static func footer(_ g: CGContext, _ i: Income, _ m: CGFloat, _ y: CGFloat, _ pw: CGFloat, _ ph: CGFloat, _ cw: CGFloat, _ faint: UIColor, _ c1: UIColor, _ c2: UIColor) {
        var y = y; line(g, y, m, cw, faint); y += 14
        let fc = UIColor(white: 1, alpha: 0.25); let ff = UIFont.systemFont(ofSize: 9)
        txt("請求書番号: \(invNum(i))", m, y, ff, fc); y += 14
        let rn = regNum(i)
        if !rn.isEmpty {
            txt("登録番号: \(rn)", m, y, ff, fc); y += 14
        }
        txt("作成日時: \(i.createdAt.formatted(date: .abbreviated, time: .shortened))", m, y, ff, fc); y += 18
        txt("Generated by Charin", m, y, .systemFont(ofSize: 8, weight: .medium), UIColor(white: 1, alpha: 0.15))
        drawGrad(g, CGRect(x: 0, y: ph-5, width: pw, height: 5), c1, c2)
    }

    // Category color
    private static func categoryUIColor(_ c: String) -> UIColor {
        switch c {
        case "subscription": return cyan
        case "one-time": return orange
        case "token sale": return purple
        case "consulting": return magenta
        default: return .gray
        }
    }

    // PDF render helper
    private static func pdfRender(_ w: CGFloat, _ h: CGFloat, _ draw: (CGContext, UIGraphicsPDFRendererContext) -> Void) -> Data {
        UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: w, height: h)).pdfData { ctx in
            ctx.beginPage(); draw(ctx.cgContext, ctx)
        }
    }

    // Image render helper
    private static func imgRender(_ draw: @escaping (CGContext, CGFloat, CGFloat, CGFloat) -> Void) -> UIImage? {
        let w: CGFloat = 1080; let h: CGFloat = 1920; let m: CGFloat = 80
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: fmt).image { ctx in
            draw(ctx.cgContext, w, h, m)
        }
    }

    // Shared image content
    private static func imgContent(_ g: CGContext, _ i: Income, _ w: CGFloat, _ h: CGFloat, _ m: CGFloat,
                                    _ main: UIColor, _ dim: UIColor, _ amt: UIColor, _ num: UIColor,
                                    _ card: UIColor, _ g1: UIColor, _ g2: UIColor) {
        var y: CGFloat = 100
        txt("CHARIN", m, y, .systemFont(ofSize: 18, weight: .black), dim); y += 40
        txt("請求書", m, y, .systemFont(ofSize: 60, weight: .bold), main)
        txtR(invNum(i), w-m, y+16, .monospacedSystemFont(ofSize: 22, weight: .semibold), num)
        y += 80

        // Registration number
        let rn = regNum(i)
        if !rn.isEmpty {
            txt("登録番号: \(rn)", m, y, .monospacedSystemFont(ofSize: 16, weight: .medium), num)
            y += 30
        }

        drawGrad(g, CGRect(x: m, y: y, width: w-m*2, height: 2), g1, g2); y += 40

        let userName = UserDefaults.standard.string(forKey: "userName") ?? "Yuki Hamada"
        txt("発行者", m, y, .systemFont(ofSize: 14, weight: .bold), dim)
        txt(userName.isEmpty ? "Yuki Hamada" : userName, m, y+26, .systemFont(ofSize: 24, weight: .semibold), main)
        let rx = m + (w-m*2)/2
        txt("宛先", rx, y, .systemFont(ofSize: 14, weight: .bold), dim)
        txt(i.source, rx, y+26, .systemFont(ofSize: 24, weight: .semibold), main)
        y += 80

        txt(dateLong(i.date), m, y, .systemFont(ofSize: 20, weight: .medium), dim)
        y += 50

        // Tax breakdown
        txt("税抜: \(i.formattedSubtotal)  |  消費税(\(i.taxRate)%): \(i.formattedTax)", m, y, .systemFont(ofSize: 16, weight: .medium), dim)
        y += 40

        // Amount card
        let ch: CGFloat = 260
        let cr = CGRect(x: m-20, y: y, width: w-m*2+40, height: ch)
        card.setFill(); UIBezierPath(roundedRect: cr, cornerRadius: 24).fill()
        txt("合計金額 (税込)", m+20, y+30, .systemFont(ofSize: 16, weight: .bold), dim)
        txt(i.formattedAmount, m+20, y+70, .systemFont(ofSize: 72, weight: .heavy), amt)

        // Payment terms in image
        txt("支払条件: 翌月末日払い", m+20, y+160, .systemFont(ofSize: 14, weight: .medium), dim)
        txt("入金状態: \(i.paymentStatusLabel)", m+20, y+184, .systemFont(ofSize: 14, weight: .medium), dim)

        drawGrad(g, CGRect(x: m, y: y+ch-40, width: w-m*2, height: 3), g1, g2)
    }

    private static func imgFooter(_ g: CGContext, _ w: CGFloat, _ h: CGFloat, _ text: String, _ c: UIColor) {
        let s = text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
        txt(text, (w-s.width)/2, h-50, .systemFont(ofSize: 14, weight: .medium), c)
    }
}
