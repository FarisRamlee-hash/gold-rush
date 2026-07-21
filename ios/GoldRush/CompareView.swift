import SwiftUI

/// Airy dealer comparison: collapsed cards show only name + the two numbers
/// that matter (buy / buyback); tap a card for details and the visit link.
struct CompareView: View {
    @EnvironmentObject var st: AppState
    @State private var expanded: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                spotRow
                filterRow
                freshnessLine

                VStack(spacing: 12) {
                    ForEach(st.compareRows) { row in
                        DealerCard(row: row, expanded: expanded == row.id) {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                                expanded = expanded == row.id ? nil : row.id
                            }
                        }
                    }
                }

                Text(st.t("✓ LIVE = confirmed today from official sources · ≈ EST = calibrated estimate. Always confirm on the dealer site.",
                          "✓ LIVE = disahkan hari ini dari sumber rasmi · ≈ EST = anggaran ditentukur. Sentiasa sahkan di laman peniaga."))
                    .font(.system(size: 10)).foregroundColor(Theme.text3)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)

                Spacer(minLength: 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }

    private var header: some View {
        HStack {
            Text(st.t("Compare", "Banding"))
                .font(.system(size: 22, weight: .heavy)).foregroundColor(.white)
            Spacer()
            Button {
                withAnimation(.spring(response: 0.35)) { st.sortByPrice.toggle() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: st.sortByPrice ? "arrow.down.circle.fill" : "star.circle.fill")
                        .font(.system(size: 13))
                    Text(st.sortByPrice ? st.t("Cheapest", "Termurah") : "Popular")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Theme.gold)
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(Theme.goldSoft).clipShape(Capsule())
            }
        }
    }

    private var spotRow: some View {
        HStack {
            Text("\(st.t("Spot", "Spot")) · \(st.purity)")
                .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text3)
            Spacer()
            Text("\(fmtRM(st.spot999 * Double(st.purity) / 1000 * st.unitFactor))/\(st.unit.label)")
                .font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.gold)
        }
        .padding(.horizontal, 4)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                typeChip("all", st.t("All", "Semua"))
                typeChip("physical", st.t("Physical", "Fizikal"))
                typeChip("digital", "Digital")

                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1, height: 18)

                Menu {
                    Picker("", selection: $st.dealerCat) {
                        Text(st.t("All categories", "Semua kategori")).tag("all")
                        Text(st.t("Dealers", "Peniaga")).tag("dealer")
                        Text(st.t("Jewellers", "Pengemas")).tag("jeweller")
                        Text("Bank").tag("bank")
                        Text("Digital").tag("digital")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(catLabel).font(.system(size: 12, weight: .bold))
                        Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(st.dealerCat == "all" ? Theme.text3 : Theme.gold)
                    .padding(.horizontal, 13).padding(.vertical, 8)
                    .background(st.dealerCat == "all" ? Theme.card : Theme.goldSoft)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var catLabel: String {
        switch st.dealerCat {
        case "dealer": return st.t("Dealers", "Peniaga")
        case "jeweller": return st.t("Jewellers", "Pengemas")
        case "bank": return "Bank"
        case "digital": return "Digital"
        default: return st.t("Category", "Kategori")
        }
    }

    private func typeChip(_ id: String, _ label: String) -> some View {
        let active = st.dealerType == id
        return Button {
            withAnimation(.spring(response: 0.3)) { st.dealerType = id }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(active ? Theme.gold : Theme.text3)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(active ? Theme.goldSoft : Theme.card)
                .clipShape(Capsule())
        }
    }

    private var freshnessLine: some View {
        let liveN = st.compareRows.filter(\.live).count
        return Text("\(st.compareRows.count) \(st.t("dealers", "peniaga"))\(liveN > 0 ? "  ·  ✓ \(liveN) \(st.t("live-verified", "disahkan langsung"))" : "")")
            .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.text3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

// MARK: - Card

struct DealerCard: View {
    @EnvironmentObject var st: AppState
    let row: AppState.DealerRow
    let expanded: Bool
    let onTap: () -> Void

    var body: some View {
        let d = row.dealer
        let f = st.unitFactor

        VStack(alignment: .leading, spacing: 0) {
            // Collapsed: just the essentials.
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 7) {
                        Text(d.name)
                            .font(.system(size: 15, weight: .heavy)).foregroundColor(.white)
                            .lineLimit(1)
                        if row.live {
                            Text("✓ LIVE")
                                .font(.system(size: 8, weight: .heavy)).foregroundColor(Theme.green)
                                .padding(.horizontal, 6).padding(.vertical, 3)
                                .background(Theme.green.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                    HStack(spacing: 5) {
                        Circle()
                            .fill(d.type == "physical" ? Theme.gold : Color.cyan)
                            .frame(width: 5, height: 5)
                        Text(d.type == "physical" ? st.t("Physical", "Fizikal") : "Digital")
                            .font(.system(size: 10)).foregroundColor(Theme.text3)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(fmtRM(row.buyP * f))
                        .font(.system(size: 17, weight: .heavy)).foregroundColor(.white)
                    Text(row.sellP.map { "↩ \(fmtRM($0 * f))" } ?? "↩ —")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.text2)
                }

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text3)
                    .rotationEffect(.degrees(expanded ? 180 : 0))
            }
            .padding(18)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            // Expanded details
            if expanded {
                VStack(alignment: .leading, spacing: 12) {
                    Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1)

                    Text(st.lang == "bm" ? d.bm : d.en)
                        .font(.system(size: 12)).foregroundColor(Theme.text2)

                    let spotG = st.spot999 * Double(st.purity) / 1000
                    let prem = row.buyP - spotG
                    let spread = row.sellP.map { (row.buyP - $0) / row.buyP * 100 }

                    HStack(spacing: 18) {
                        detail(st.t("vs spot", "vs spot"),
                               "+\(fmtNum(prem * f)) (+\(String(format: "%.1f", prem / spotG * 100))%)",
                               Theme.text2)
                        detail("Spread",
                               spread.map { String(format: "%.1f%%", $0) } ?? "—",
                               (spread ?? 0) <= 4 ? Theme.green : (spread ?? 0) <= 8 ? Theme.gold : Theme.red)
                        Spacer()
                    }

                    if let u = d.url, let url = URL(string: u) {
                        Link(destination: url) {
                            Text("\(st.t("Visit Site", "Lawati")) ↗")
                                .font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.gold)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(Theme.goldSoft)
                                .overlay(RoundedRectangle(cornerRadius: 11)
                                    .stroke(Theme.gold.opacity(0.2), lineWidth: 1))
                                .cornerRadius(11)
                        }
                    }
                }
                .padding([.horizontal, .bottom], 18)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 18)
            .stroke(expanded ? Theme.gold.opacity(0.2) : Theme.cardStroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func detail(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased()).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.text3)
            Text(value).font(.system(size: 12, weight: .heavy)).foregroundColor(color)
        }
    }
}
