import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {

    // MARK: Selection
    @Published var metal = "gold"
    @Published var purity = 999
    @Published var tf = "7D"
    @Published var unit: WeightUnit { didSet { save(unit.rawValue, "unit") } }
    @Published var lang: String { didSet { save(lang, "lang") } }

    // MARK: Data
    @Published var prices: PricesResponse?
    @Published var isLive = false
    @Published var history: [HistoryPoint] = []      // raw 999-gold RM/g series for current tf
    @Published var historyLoading = false
    @Published var yearHistory: [HistoryPoint] = []  // 1Y series for the signal
    @Published var dealers: [Dealer] = []
    @Published var liveMap: [String: LiveDealerEntry] = [:]
    @Published var liveTs: Date?

    // MARK: Compare filters
    @Published var dealerType = "all"   // all | physical | digital
    @Published var dealerCat = "all"    // all | dealer | jeweller | bank | digital
    @Published var sortByPrice = false

    // MARK: Portfolio & alerts (persisted)
    @Published var holdings: [Holding] { didSet { saveJSON(holdings, "holdings") } }
    @Published var alerts: [PriceAlert] { didSet { saveJSON(alerts, "alerts") } }
    @Published var zakatPaidYear: Int? { didSet { save(zakatPaidYear.map(String.init) ?? "", "zakatPaid") } }
    @Published var zakatStateIdx: Int { didSet { save(String(zakatStateIdx), "zakatState") } }

    init() {
        let d = UserDefaults.standard
        unit = WeightUnit(rawValue: d.string(forKey: "gr_unit") ?? "g") ?? .g
        lang = d.string(forKey: "gr_lang") ?? "en"
        holdings = Self.loadJSON([Holding].self, "holdings") ?? []
        alerts = Self.loadJSON([PriceAlert].self, "alerts") ?? []
        zakatPaidYear = Int(d.string(forKey: "gr_zakatPaid") ?? "")
        zakatStateIdx = Int(d.string(forKey: "gr_zakatState") ?? "") ?? 0
    }

    // MARK: - i18n

    func t(_ en: String, _ bm: String) -> String { lang == "bm" ? bm : en }

    // MARK: - Derived pricing

    var purities: [Int] { metal == "gold" ? ShopTiers.purities : [999] }

    var entry: PriceEntry? {
        (metal == "gold" ? prices?.gold : prices?.silver)?[String(purity)]
    }

    /// Raw 999 spot RM/g — the market reference everything derives from.
    var spot999: Double { prices?.gold["999"]?.spot ?? 0 }

    var unitFactor: Double { unit.grams }

    func tier(_ t: Tier, purity p: Int? = nil) -> Double? {
        ShopTiers.value(spot999: spot999, purity: p ?? purity, tier: t)
    }

    func goldPerGram(purity p: Int) -> Double {
        prices?.gold[String(p)]?.price ?? 0
    }

    /// History scaled to the selected purity/metal price (matches the web chart).
    var displayHistory: [HistoryPoint] {
        guard let last = history.last?.y, last > 0, let price = entry?.price else { return history }
        let f = price / last
        return history.map { HistoryPoint(t: $0.t, y: ($0.y * f * 100).rounded() / 100) }
    }

    // MARK: - Dealers (live crosscheck, ported from the web)

    struct DealerRow: Identifiable {
        let dealer: Dealer
        let buyP: Double
        let sellP: Double?
        let live: Bool          // ✓ LIVE (published today) vs ≈ EST (calibrated)
        var id: String { dealer.id }
    }

    func dealerRow(_ d: Dealer, purity p: Int) -> DealerRow? {
        guard let mult = d.buy[String(p)], spot999 > 0 else { return nil }
        let spotG = spot999 * Double(p) / 1000
        let lv = liveMap[d.id]
        let lvBuy = lv?.buy?[String(p)]
        let lvSell = lv?.sell?[String(p)]
        let buyP = lvBuy ?? spotG * mult
        let sellP = lvSell ?? d.sell?[String(p)].map { spotG * $0 }
        let live = lvBuy != nil && !(lv?.std ?? false)
        return DealerRow(dealer: d, buyP: buyP, sellP: sellP, live: live)
    }

    var compareRows: [DealerRow] {
        var rows = dealers.compactMap { dealerRow($0, purity: purity) }
        if dealerType != "all" { rows = rows.filter { $0.dealer.type == dealerType } }
        if dealerCat != "all" { rows = rows.filter { $0.dealer.cat == dealerCat } }
        return sortByPrice ? rows.sorted { $0.buyP < $1.buyP } : rows.sorted { $0.dealer.pop < $1.dealer.pop }
    }

    /// Highest-paying buyback dealer today for a purity.
    func bestBuyback(purity p: Int) -> DealerRow? {
        dealers.compactMap { dealerRow($0, purity: p) }
            .filter { $0.sellP != nil }
            .max { ($0.sellP ?? 0) < ($1.sellP ?? 0) }
    }

    // MARK: - Portfolio valuation (honest sell-back, not paper melt)

    func sellPerGram(_ h: Holding) -> Double {
        if let bb = bestBuyback(purity: h.purity)?.sellP { return bb }
        let melt = goldPerGram(purity: h.purity)
        return melt * (ItemType.by(h.type).bullion ? 0.98 : 0.90)
    }

    func holdingValue(_ h: Holding) -> Double { h.grams * sellPerGram(h) }
    func holdingMelt(_ h: Holding) -> Double { h.grams * goldPerGram(purity: h.purity) }

    var portfolioSell: Double { holdings.reduce(0) { $0 + holdingValue($1) } }
    var portfolioMelt: Double { holdings.reduce(0) { $0 + holdingMelt($1) } }
    var portfolioCost: Double { holdings.reduce(0) { $0 + $1.grams * $1.paidPerG } }
    var portfolioGrams: Double { holdings.reduce(0) { $0 + $1.grams } }

    /// Pure-gold grams (for nisab): Σ grams × purity/1000.
    var pureGoldGrams: Double { holdings.reduce(0) { $0 + $1.grams * Double($1.purity) / 1000 } }

    // MARK: - Zakat

    static let nisabGrams = 85.0
    static let urufGrams = 850.0
    static let zakatRate = 0.025

    var hijriYear: Int? {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.locale = Locale(identifier: "en_US_POSIX")
        return cal.dateComponents([.year], from: Date()).year
    }

    var nisabRM: Double { Self.nisabGrams * goldPerGram(purity: 999) }

    /// Haul (354-day lunar year) end date from the earliest holding purchase.
    var haulEnd: Date? {
        guard pureGoldGrams >= Self.nisabGrams,
              let earliest = holdings.map(\.date).min() else { return nil }
        return earliest.addingTimeInterval(354 * 86400)
    }

    // MARK: - Signal (RSI-14 + trend, from 1Y history)

    struct Signal { let label: String; let color: Color }

    var signal: Signal {
        let closes = yearHistory.map(\.y)
        guard closes.count > 60, let price = closes.last else {
            return Signal(label: t("HOLD", "TAHAN"), color: Theme.gold)
        }
        // Wilder's RSI-14
        var gain = 0.0, loss = 0.0
        for i in 1...14 {
            let d = closes[i] - closes[i - 1]
            if d > 0 { gain += d } else { loss -= d }
        }
        gain /= 14; loss /= 14
        for i in 15..<closes.count {
            let d = closes[i] - closes[i - 1]
            gain = (gain * 13 + max(d, 0)) / 14
            loss = (loss * 13 + max(-d, 0)) / 14
        }
        let rsi = loss == 0 ? 100 : 100 - 100 / (1 + gain / loss)
        let ma50 = closes.suffix(50).reduce(0, +) / Double(min(50, closes.count))

        if rsi < 30 { return Signal(label: t("STRONG BUY", "BELI KUKUH"), color: Theme.green) }
        if rsi < 42 && price < ma50 { return Signal(label: t("BUY", "BELI"), color: Theme.green) }
        if rsi > 70 { return Signal(label: t("STRONG SELL", "JUAL KUKUH"), color: Theme.red) }
        if rsi > 60 && price > ma50 { return Signal(label: t("SELL", "JUAL"), color: Theme.red) }
        return Signal(label: t("HOLD", "TAHAN"), color: Theme.gold)
    }

    // MARK: - Loading

    /// Immediate load + 30s refresh, cancelled automatically by SwiftUI's .task.
    func start() async {
        async let a: Void = loadPrices()
        async let b: Void = loadHistory()
        async let c: Void = loadDealers()
        async let d: Void = loadYearHistory()
        _ = await (a, b, c, d)
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
            if Task.isCancelled { break }
            await loadPrices()
            checkAlerts()
        }
    }

    func loadPrices() async {
        do {
            let r = try await APIClient.prices()
            prices = r
            isLive = r.live
        } catch { isLive = false }
    }

    func loadHistory() async {
        historyLoading = true
        if let pts = (try? await APIClient.history(tf: tf, metal: metal))?.points {
            withAnimation(.easeInOut(duration: 0.55)) { history = pts }
        }
        historyLoading = false
    }

    /// Stable identity for the current chart series — the crossfade transition
    /// keys on this, so it fires when new data lands (not while fetching).
    var chartKey: String { "\(tf)|\(metal)|\(history.first?.t ?? 0)|\(history.count)" }

    func loadYearHistory() async {
        yearHistory = (try? await APIClient.history(tf: "1Y", metal: "gold"))?.points ?? yearHistory
    }

    func loadDealers() async {
        if let c = try? await APIClient.content() { dealers = c.dealers }
        if let l = try? await APIClient.liveDealers() {
            liveMap = l.live
            liveTs = Date(timeIntervalSince1970: l.ts / 1000)
        }
    }

    func selectMetal(_ m: String) {
        metal = m
        if !purities.contains(purity) { purity = purities.first ?? 999 }
        Task { await loadHistory() }
    }

    func selectTF(_ newTF: String) {
        tf = newTF
        Task { await loadHistory() }
    }

    func cycleUnit() { unit = unit.next }

    func checkAlerts() {
        guard metal == "gold" else { return }
        for i in alerts.indices where !alerts[i].triggered {
            let p = goldPerGram(purity: alerts[i].purity)
            guard p > 0 else { continue }
            if alerts[i].above ? p >= alerts[i].target : p <= alerts[i].target {
                alerts[i].triggered = true
            }
        }
    }

    // MARK: - Persistence helpers

    private func save(_ v: String, _ key: String) { UserDefaults.standard.set(v, forKey: "gr_\(key)") }

    private func saveJSON<T: Encodable>(_ v: T, _ key: String) {
        if let d = try? JSONEncoder().encode(v) { UserDefaults.standard.set(d, forKey: "gr_\(key)") }
    }

    private static func loadJSON<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        UserDefaults.standard.data(forKey: "gr_\(key)").flatMap { try? JSONDecoder().decode(type, from: $0) }
    }
}
