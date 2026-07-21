import SwiftUI

struct CompareView: View {
    @EnvironmentObject var st: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                Text(st.t("Dealer Comparison", "Perbandingan Peniaga"))
                    .font(.system(size: 21, weight: .heavy)).foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                spotBanner
                filters
                freshnessLine

                ForEach(st.compareRows) { row in
                    DealerCard(row: row)
                }

                Text(st.t("✓ LIVE prices are confirmed today from official dealer and bank sources. ≈ EST prices are calibrated to published rates and tracked against live spot. Always confirm on the dealer site before transacting.",
                          "Harga ✓ LIVE disahkan hari ini daripada sumber rasmi peniaga dan bank. Harga ≈ EST ditentukur mengikut kadar terbitan dan dijejak mengikut spot semasa. Sentiasa sahkan di laman peniaga sebelum urus niaga."))
                    .font(.system(size: 10)).foregroundColor(Theme.text3)
                    .padding(.top, 4)

                Spacer(minLength: 110)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
        }
    }

    private var spotBanner: some View {
        HStack {
            Text("\(st.t("Spot price", "Harga spot")) · \(st.purity) \(st.t("Gold", "Emas"))")
                .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text2)
            Spacer()
            Text("\(fmtRM(st.spot999 * Double(st.purity) / 1000 * st.unitFactor))/\(st.unit.label)")
                .font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.gold)
        }
        .card(padding: 13)
    }

    private var filters: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                chip(st.t("All", "Semua"), st.dealerType == "all") { st.dealerType = "all" }
                chip(st.t("Physical", "Fizikal"), st.dealerType == "physical") { st.dealerType = "physical" }
                chip("Digital", st.dealerType == "digital") { st.dealerType = "digital" }
                Spacer()
                chip(st.sortByPrice ? st.t("Cheapest", "Termurah") : st.t("Popular", "Popular"), true) {
                    st.sortByPrice.toggle()
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    catChip("all", st.t("All", "Semua"))
                    catChip("dealer", st.t("Dealers", "Peniaga"))
                    catChip("jeweller", st.t("Jewellers", "Pengemas"))
                    catChip("bank", "Bank")
                    catChip("digital", "Digital")
                }
            }
        }
    }

    private func chip(_ label: String, _ active: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.spring(response: 0.3)) { action() } }) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(active ? Theme.gold : Theme.text3)
                .padding(.horizontal, 13).padding(.vertical, 7)
                .background(active ? Theme.goldSoft : Theme.card)
                .overlay(Capsule().stroke(active ? Theme.gold.opacity(0.25) : Theme.cardStroke, lineWidth: 1))
                .clipShape(Capsule())
        }
    }

    private func catChip(_ id: String, _ label: String) -> some View {
        chip(label, st.dealerCat == id) { st.dealerCat = id }
    }

    private var freshnessLine: some View {
        let liveN = st.compareRows.filter(\.live).count
        let mins = st.liveTs.map { max(1, Int(Date().timeIntervalSince($0) / 60)) }
        return Text("\(st.compareRows.count) \(st.t("dealers", "peniaga"))\(liveN > 0 ? " · ✓ \(liveN) \(st.t("live-verified", "disahkan langsung"))\(mins.map { " (\($0)m)" } ?? "")" : "")")
            .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.text3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DealerCard: View {
    @EnvironmentObject var st: AppState
    let row: AppState.DealerRow

    var body: some View {
        let d = row.dealer
        let spotG = st.spot999 * Double(st.purity) / 1000
        let prem = row.buyP - spotG
        let f = st.unitFactor

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Text(d.name).font(.system(size: 14, weight: .heavy)).foregroundColor(.white)
                Text(row.live ? "✓ LIVE" : "≈ EST")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(row.live ? Theme.green : Theme.text3)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background((row.live ? Theme.green : Color.white).opacity(0.08))
                    .overlay(Capsule().stroke((row.live ? Theme.green : Color.white).opacity(0.2), lineWidth: 1))
                    .clipShape(Capsule())
                Spacer()
                Text(d.type == "physical" ? st.t("Physical", "Fizikal") : "Digital")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(d.type == "physical" ? Theme.gold : Color.cyan)
            }

            Text(st.lang == "bm" ? d.bm : d.en)
                .font(.system(size: 11)).foregroundColor(Theme.text3)

            HStack(spacing: 0) {
                priceCol(st.t("Buy", "Beli"), fmtRM(row.buyP * f), .white)
                priceCol(st.t("Sell", "Jual"), row.sellP.map { fmtRM($0 * f) } ?? "—", Theme.text2)
                let spread = row.sellP.map { (row.buyP - $0) / row.buyP * 100 }
                priceCol("Spread", spread.map { String(format: "%.1f%%", $0) } ?? "—",
                         (spread ?? 0) <= 4 ? Theme.green : (spread ?? 0) <= 8 ? Theme.gold : Theme.red)
            }

            HStack {
                Text("+\(fmtRM(prem * f)) (+\(String(format: "%.1f", prem / spotG * 100))%) \(st.t("vs spot", "vs spot"))")
                    .font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text3)
                Spacer()
                if let u = d.url, let url = URL(string: u) {
                    Link(st.t("Visit Site", "Lawati"), destination: url)
                        .font(.system(size: 11, weight: .bold)).foregroundColor(Theme.gold)
                }
            }
        }
        .card(padding: 14)
    }

    private func priceCol(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(label.uppercased()).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text3)
            Text(value).font(.system(size: 13, weight: .heavy)).foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}
