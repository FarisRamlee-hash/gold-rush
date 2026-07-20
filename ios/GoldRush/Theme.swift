import SwiftUI

/// Brand palette, matching the web app.
enum Theme {
    static let bg = Color(red: 0.03, green: 0.03, blue: 0.08)
    static let card = Color.white.opacity(0.04)
    static let cardStroke = Color.white.opacity(0.07)
    static let gold = Color(red: 1.0, green: 0.843, blue: 0.0)
    static let green = Color(red: 0.0, green: 0.839, blue: 0.561)
    static let red = Color(red: 1.0, green: 0.278, blue: 0.341)
    static let purple = Color(red: 0.753, green: 0.518, blue: 0.988)
    static let pink = Color(red: 1.0, green: 0.561, blue: 0.639)
    static let text2 = Color.white.opacity(0.6)
    static let text3 = Color.white.opacity(0.35)
}

/// RM number formatting with thousands separators, 2 decimals.
func fmtRM(_ v: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.minimumFractionDigits = 2
    f.maximumFractionDigits = 2
    f.groupingSeparator = ","
    return f.string(from: NSNumber(value: v)) ?? String(format: "%.2f", v)
}
