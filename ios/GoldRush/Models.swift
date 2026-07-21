import Foundation

// MARK: - /api/prices

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

// MARK: - /api/history

struct HistoryResponse: Codable {
    let live: Bool
    let points: [HistoryPoint]
}

struct HistoryPoint: Codable, Identifiable {
    let t: Double   // ms since epoch
    let y: Double   // RM per gram (999 gold)
    var id: Double { t }
    var date: Date { Date(timeIntervalSince1970: t / 1000) }
}

// MARK: - /api/content (dealers)

struct ContentResponse: Codable {
    let dealers: [Dealer]
}

struct Dealer: Codable, Identifiable {
    let id: String
    let name: String
    let cat: String        // dealer | jeweller | bank | digital
    let type: String       // physical | digital
    let pop: Int
    let en: String
    let bm: String
    let url: String?
    let buy: [String: Double]      // purity → multiplier over purity-adjusted spot
    let sell: [String: Double]?
}

// MARK: - /api/live-dealers (crosscheck overrides)

struct LiveDealersResponse: Codable {
    let ts: Double
    let live: [String: LiveDealerEntry]
}

struct LiveDealerEntry: Codable {
    let buy: [String: Double]?     // purity → absolute RM/gram, published today
    let sell: [String: Double]?
    let std: Bool?                 // standard trade retail (≈, not ✓ LIVE)
}

// MARK: - Weight units

enum WeightUnit: String, CaseIterable, Codable {
    case g, mayam, serial, tahil

    /// grams per unit — mayam & serial are Kelantanese trade units,
    /// tahil is the goldsmith/bullion unit.
    var grams: Double {
        switch self {
        case .g: return 1
        case .mayam: return 3.71
        case .serial: return 2.72
        case .tahil: return 37.8
        }
    }

    var label: String { rawValue }

    var next: WeightUnit {
        let all = WeightUnit.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}

// MARK: - Portfolio

struct Holding: Codable, Identifiable {
    var id = UUID()
    var type: String       // ItemType.id
    var label: String
    var purity: Int
    var grams: Double
    var paidPerG: Double
    var date: Date
}

struct ItemType: Identifiable {
    let id: String         // also the ItemIcon key
    let bullion: Bool      // bullion buys back near melt; jewellery loses upah
    let en: String
    let bm: String

    static let all: [ItemType] = [
        ItemType(id: "ring", bullion: false, en: "Ring", bm: "Cincin"),
        ItemType(id: "necklace", bullion: false, en: "Necklace", bm: "Rantai leher"),
        ItemType(id: "bracelet", bullion: false, en: "Bracelet / Bangle", bm: "Gelang"),
        ItemType(id: "pendant", bullion: false, en: "Pendant / Other", bm: "Loket / Lain"),
        ItemType(id: "coin", bullion: true, en: "Coin", bm: "Syiling"),
        ItemType(id: "bar", bullion: true, en: "Bar / Wafer", bm: "Jongkong / Wafer"),
    ]

    static func by(_ id: String) -> ItemType { all.first { $0.id == id } ?? all[5] }
}

// MARK: - Price alerts

struct PriceAlert: Codable, Identifiable {
    var id = UUID()
    var purity: Int
    var target: Double     // RM per gram
    var above: Bool        // true = notify when price rises above target
    var triggered = false
}

// MARK: - Zakat state directory (official bodies, URLs verified Jul 2026)

struct ZakatBody: Identifiable {
    let state: String
    let name: String
    let url: String
    var id: String { state }

    static let all: [ZakatBody] = [
        ZakatBody(state: "Wilayah Persekutuan", name: "PPZ-MAIWP", url: "https://www.zakat.com.my"),
        ZakatBody(state: "Selangor", name: "Lembaga Zakat Selangor", url: "https://www.zakatselangor.com.my"),
        ZakatBody(state: "Johor", name: "MAIJ", url: "https://www.maij.gov.my"),
        ZakatBody(state: "Kedah", name: "Lembaga Zakat Negeri Kedah", url: "https://www.zakatkedah.com.my"),
        ZakatBody(state: "Kelantan", name: "MAIK", url: "https://www.e-maik.my"),
        ZakatBody(state: "Melaka", name: "MAIM", url: "https://www.maim.gov.my"),
        ZakatBody(state: "Negeri Sembilan", name: "MAINS", url: "https://www.mains.gov.my"),
        ZakatBody(state: "Pahang", name: "Pusat Kutipan Zakat Pahang", url: "https://www.zakatpahang.my"),
        ZakatBody(state: "Pulau Pinang", name: "Zakat Pulau Pinang", url: "https://www.zakatpenang.com"),
        ZakatBody(state: "Perak", name: "MAIPk", url: "https://www.maiamp.gov.my"),
        ZakatBody(state: "Perlis", name: "MAIPs", url: "https://www.maips.gov.my"),
        ZakatBody(state: "Sabah", name: "Zakat MUIS Sabah", url: "https://www.zakat.sabah.gov.my"),
        ZakatBody(state: "Sarawak", name: "Tabung Baitulmal Sarawak", url: "https://www.tbs.org.my"),
        ZakatBody(state: "Terengganu", name: "MAIDAM", url: "https://www.maidam.gov.my"),
    ]
}
