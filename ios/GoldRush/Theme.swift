import SwiftUI

/// Brand palette + shared styling, matching the web app's dark-luxe look.
enum Theme {
    static let bg = Color(red: 0.027, green: 0.027, blue: 0.071)
    static let card = Color.white.opacity(0.045)
    static let cardStroke = Color.white.opacity(0.07)
    static let gold = Color(red: 1.0, green: 0.843, blue: 0.0)
    static let goldSoft = Color(red: 1.0, green: 0.843, blue: 0.0).opacity(0.09)
    static let green = Color(red: 0.0, green: 0.839, blue: 0.561)
    static let red = Color(red: 1.0, green: 0.278, blue: 0.341)
    static let purple = Color(red: 0.753, green: 0.518, blue: 0.988)
    static let pink = Color(red: 1.0, green: 0.561, blue: 0.639)
    static let silver = Color(red: 0.75, green: 0.75, blue: 0.78)
    static let text2 = Color.white.opacity(0.62)
    static let text3 = Color.white.opacity(0.38)
}

/// "12,345.67" — amounts with thousands separators.
func fmtNum(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.minimumFractionDigits = 2
    f.maximumFractionDigits = 2
    f.groupingSeparator = ","
    return f.string(from: NSNumber(value: v)) ?? String(format: "%.2f", v)
}

func fmtRM(_ v: Double) -> String { "RM " + fmtNum(v) }

/// Compact quantity labels: 1, 3.71, 0.25 …
func fmtQty(_ v: Double) -> String {
    v == v.rounded() ? String(Int(v)) : String(v)
}

// MARK: - Reusable styling

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.cardStroke, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View { modifier(CardStyle(padding: padding)) }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .tracking(1.2)
            .foregroundColor(Theme.text3)
    }
}
