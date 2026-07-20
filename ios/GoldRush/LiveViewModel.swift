import Foundation
import SwiftUI

@MainActor
final class LiveViewModel: ObservableObject {
    @Published var metal: String = "gold"
    @Published var purity: Int = 999
    @Published var response: PricesResponse?
    @Published var isLive = false
    @Published var loaded = false

    var purities: [Int] {
        metal == "gold" ? ShopTiers.purities : [999]
    }

    var entry: PriceEntry? {
        let dict = metal == "gold" ? response?.gold : response?.silver
        return dict?[String(purity)]
    }

    /// Raw 999 spot (RM/g) used to derive shop tiers.
    var spot999: Double { response?.gold["999"]?.spot ?? entry?.spot ?? 0 }

    /// Loads immediately, then refreshes every 30s until the task is cancelled
    /// (SwiftUI's `.task` cancels this automatically when the view disappears).
    func start() async {
        await load()
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
            if Task.isCancelled { break }
            await load()
        }
    }

    func load() async {
        do {
            let r = try await APIClient.prices()
            response = r
            isLive = r.live
        } catch {
            isLive = false
        }
        loaded = true
    }

    func selectMetal(_ m: String) {
        metal = m
        if !purities.contains(purity) { purity = purities.first ?? 999 }
    }

    func tier(_ t: Tier) -> Double? {
        ShopTiers.value(spot999: spot999, purity: purity, tier: t)
    }
}
