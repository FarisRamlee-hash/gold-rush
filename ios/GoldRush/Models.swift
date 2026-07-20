import Foundation

/// Response from https://gold-rush-tau.vercel.app/api/prices
/// Extra JSON keys (e.g. `ts`) are ignored by Codable.
struct PricesResponse: Codable {
    let live: Bool
    let usdMyr: Double
    let gold: [String: PriceEntry]
    let silver: [String: PriceEntry]
}

struct PriceEntry: Codable {
    let price: Double   // purity-adjusted RM per gram
    let close: Double
    let change: Double
    let pct: Double
    let spot: Double    // raw 999 spot RM per gram (same for every gold entry)
}
