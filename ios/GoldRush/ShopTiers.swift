import Foundation

enum Tier: String, CaseIterable, Identifiable {
    case new, used, tradein, buyback
    var id: String { rawValue }
    var label: String {
        switch self {
        case .new: return "New"
        case .used: return "Used"
        case .tradein: return "Trade-in"
        case .buyback: return "Buyback"
        }
    }
}

/// Shop price tiers (New / Used / Trade-in / Buyback) as factors of the 999.9
/// market reference — reverse-engineered from a real Malaysian shop board.
/// Mirrors GVM_TIERS in the web app so both stay consistent.
enum ShopTiers {
    static let purities = [999, 916, 900, 835, 750, 585, 375]

    static let factors: [Int: [Tier: Double]] = [
        999: [.new: 1.00000, .used: 0.99302, .tradein: 0.97906, .buyback: 0.97209],
        916: [.new: 0.94999, .used: 0.94301, .tradein: 0.90300, .buyback: 0.89604],
        900: [.new: 0.90001, .used: 0.89303, .tradein: 0.85945, .buyback: 0.85249],
        835: [.new: 0.84260, .used: 0.83562, .tradein: 0.79950, .buyback: 0.79254],
        750: [.new: 0.73760, .used: 0.73062, .tradein: 0.70179, .buyback: 0.69482],
        585: [.new: 0.52620, .used: 0.51922, .tradein: 0.50328, .buyback: 0.49632],
        375: [.new: 0.31170, .used: 0.30472, .tradein: 0.30315, .buyback: 0.29618],
    ]

    /// RM per gram for a tier, given the raw 999 spot.
    static func value(spot999: Double, purity: Int, tier: Tier) -> Double? {
        guard spot999 > 0, let f = factors[purity]?[tier] else { return nil }
        return spot999 * f
    }
}
