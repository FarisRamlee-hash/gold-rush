import SwiftUI
import Charts

struct LiveView: View {
    @EnvironmentObject var st: AppState
    @State private var showUnitInfo = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header
                metalPicker
                purityPicker
                priceBlock
                chartCard
                if st.metal == "gold" { tierGrid }
                quickPrices
                signalCard
                Spacer(minLength: 110)
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
        }
        .sheet(isPresented: $showUnitInfo) { UnitInfoSheet() }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Text("Au")
                    .font(.system(size: 17, weight: .bold)).foregroundColor(.black)
                    .frame(width: 38, height: 38)
                    .background(Theme.gold).cornerRadius(10)
                Text("Gold Rush")
                    .font(.system(size: 21, weight: .heavy)).foregroundColor(.white)
            }
            Spacer()
            Button {
                st.lang = st.lang == "en" ? "bm" : "en"
            } label: {
                Text(st.lang == "en" ? "BM" : "EN")
                    .font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text2)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Theme.card).clipShape(Capsule())
            }
            HStack(spacing: 6) {
                Circle().fill(st.isLive ? Theme.green : Theme.gold).frame(width: 7, height: 7)
                Text(st.isLive ? "LIVE" : "…")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(st.isLive ? Theme.green : Theme.text3)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Theme.card).clipShape(Capsule())
        }
    }

    // MARK: Metal + purity

    private var metalPicker: some View {
        HStack(spacing: 0) {
            ForEach(["gold", "silver"], id: \.self) { m in
                let active = st.metal == m
                Text(m == "gold" ? st.t("Gold", "Emas") : st.t("Silver", "Perak"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(active ? .black : Theme.text2)
                    .frame(maxWidth: .infinity).padding(.vertical, 11)
                    .background(active ? (m == "silver" ? Theme.silver : Theme.gold) : .clear)
                    .clipShape(Capsule())
                    .onTapGesture { withAnimation(.spring(response: 0.35)) { st.selectMetal(m) } }
            }
        }
        .padding(5).background(Theme.card).clipShape(Capsule())
    }

    private var purityPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(st.purities, id: \.self) { p in
                        let active = st.purity == p
                        Text("\(p)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(active ? Theme.gold : Theme.text3)
                            .opacity(active ? 1 : 0.5)
                            .scaleEffect(active ? 1.18 : 1)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(active ? Theme.goldSoft : .clear)
                            .overlay(Capsule().stroke(active ? Theme.gold.opacity(0.25) : .clear, lineWidth: 1))
                            .clipShape(Capsule())
                            .id(p)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4)) {
                                    st.purity = p
                                    proxy.scrollTo(p, anchor: .center)
                                }
                            }
                    }
                }
                .padding(.horizontal, 6)
            }
        }
    }

    // MARK: Price

    private var priceBlock: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text("RM").font(.system(size: 20, weight: .medium)).foregroundColor(Theme.text2)
                Text(st.entry.map { fmtNum($0.price * st.unitFactor) } ?? "—")
                    .font(.system(size: st.unit == .tahil ? 42 : 52, weight: .heavy))
                    .foregroundColor(st.metal == "silver" ? Theme.silver : Theme.gold)
                    .contentTransition(.numericText())
                Button {
                    withAnimation(.spring(response: 0.35)) { st.cycleUnit() }
                } label: {
                    Text("/\(st.unit.label) ⇄")
                        .font(.system(size: 13, weight: .bold)).foregroundColor(Theme.gold)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.goldSoft)
                        .overlay(Capsule().stroke(Theme.gold.opacity(0.2), lineWidth: 1))
                        .clipShape(Capsule())
                }
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in showUnitInfo = true })
            }
            .animation(.spring(response: 0.4), value: st.entry?.price)
            .animation(.spring(response: 0.4), value: st.unit)

            if let e = st.entry {
                let up = e.change >= 0
                Text("\(up ? "▲" : "▼") RM \(fmtNum(abs(e.change) * st.unitFactor))  (\(up ? "+" : "")\(String(format: "%.2f", e.pct))%)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(up ? Theme.green : Theme.red)
                    .padding(.horizontal, 15).padding(.vertical, 7)
                    .background((up ? Theme.green : Theme.red).opacity(0.1))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: Chart

    private var chartCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(["1D", "7D", "1M", "3M", "6M", "1Y"], id: \.self) { f in
                    let active = st.tf == f
                    Text(f == "1D" ? "24H" : f)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(active ? .black : Theme.text3)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(active ? Theme.gold : .clear)
                        .clipShape(Capsule())
                        .onTapGesture { withAnimation { st.selectTF(f) } }
                }
            }
            PriceChart(points: st.displayHistory, tint: st.metal == "silver" ? Theme.silver : Theme.gold)
                .frame(height: 210)
                .animation(.spring(response: 0.6), value: st.purity)
                .animation(.spring(response: 0.6), value: st.displayHistory.last?.y)
        }
        .card()
    }

    // MARK: Shop tiers

    private var tierGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(text: st.t("Shop Price", "Harga Kedai"))
                Spacer()
                Text("\(st.purity) · RM/\(st.unit.label)")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(Theme.gold)
                    .padding(.horizontal, 11).padding(.vertical, 4)
                    .background(Theme.goldSoft).clipShape(Capsule())
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                tierCell(.new, st.t("NEW", "BARU"), .white)
                tierCell(.used, st.t("USED", "TERPAKAI"), .white.opacity(0.82))
                tierCell(.tradein, "TRADE-IN", Theme.purple)
                tierCell(.buyback, st.t("BUYBACK", "BELI BALIK"), Theme.pink)
            }
            Text(st.t("New = buy new · Buyback = shop buys your gold. Prices move with the market and vary by shop.",
                      "Baru = beli baharu · Beli Balik = kedai beli emas anda. Harga berubah ikut pasaran & berbeza setiap kedai."))
                .font(.system(size: 10)).foregroundColor(Theme.text3)
        }
    }

    private func tierCell(_ t: Tier, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 5) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text3)
            Text(st.tier(t).map { fmtNum($0 * st.unitFactor) } ?? "—")
                .font(.system(size: 17, weight: .heavy)).foregroundColor(color)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardStroke, lineWidth: 1))
        .cornerRadius(16)
        .animation(.spring(response: 0.4), value: st.spot999)
        .animation(.spring(response: 0.4), value: st.purity)
    }

    // MARK: Quick prices

    private var quickWeights: [Double] {
        switch st.unit {
        case .g: return [1, 3.71, 5, 10, 20, 50, 100, 1000]
        case .tahil: return [0.25, 0.5, 1, 2, 3, 5, 10, 20]
        default: return [1, 2, 3, 5, 8, 10, 16, 20]
        }
    }

    private var quickPrices: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: st.t("Quick Prices", "Harga Pantas"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickWeights, id: \.self) { w in
                        VStack(spacing: 4) {
                            Text(quickLabel(w))
                                .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.text3)
                            Text(fmtRM((st.entry?.price ?? 0) * st.unitFactor * w))
                                .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Theme.card)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.cardStroke, lineWidth: 1))
                        .cornerRadius(14)
                    }
                }
            }
        }
    }

    private func quickLabel(_ w: Double) -> String {
        if st.unit == .g {
            if w == 3.71 { return "1 mayam" }
            if w == 1000 { return "1kg" }
            return "\(fmtQty(w))g"
        }
        if w == 0.25 { return "¼ \(st.unit.label)" }
        if w == 0.5 { return "½ \(st.unit.label)" }
        return "\(fmtQty(w)) \(st.unit.label)"
    }

    // MARK: Signal

    private var signalCard: some View {
        let sig = st.signal
        return HStack {
            SectionTitle(text: st.t("Signal", "Isyarat"))
            Spacer()
            Text(sig.label)
                .font(.system(size: 15, weight: .heavy)).foregroundColor(sig.color)
                .padding(.horizontal, 16).padding(.vertical, 7)
                .background(sig.color.opacity(0.1))
                .overlay(Capsule().stroke(sig.color.opacity(0.25), lineWidth: 1))
                .clipShape(Capsule())
        }
        .card()
    }
}

// MARK: - Chart

struct PriceChart: View {
    let points: [HistoryPoint]
    let tint: Color

    var body: some View {
        if points.count < 2 {
            HStack { Spacer(); ProgressView().tint(tint); Spacer() }
        } else {
            let lo = points.map(\.y).min() ?? 0
            let hi = points.map(\.y).max() ?? 1
            let pad = max((hi - lo) * 0.08, 0.5)
            Chart(points) { p in
                AreaMark(x: .value("t", p.date), y: .value("RM", p.y))
                    .foregroundStyle(LinearGradient(colors: [tint.opacity(0.25), .clear],
                                                    startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("t", p.date), y: .value("RM", p.y))
                    .foregroundStyle(tint)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)
            }
            .chartYScale(domain: (lo - pad)...(hi + pad))
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
                    AxisValueLabel().foregroundStyle(Theme.text3).font(.system(size: 10))
                }
            }
        }
    }
}

// MARK: - Unit info sheet (long-press the unit pill)

struct UnitInfoSheet: View {
    @EnvironmentObject var st: AppState
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(st.t("Traditional gold units", "Unit emas tradisional"))
                .font(.system(size: 15, weight: .heavy)).foregroundColor(Theme.gold)
            row("1 mayam = 3.71 g", "Kelantan / Terengganu")
            row("1 serial = 2.72 g", st.t("old Kelantan measure", "ukuran lama Kelantan"))
            row("1 tahil = 37.8 g", st.t("goldsmiths / bullion", "tukang emas / jongkong"))
            Text(st.t("Tap the pill beside the price to switch the whole app between g, mayam, serial and tahil.",
                      "Tekan pil di sebelah harga untuk menukar seluruh aplikasi antara g, mayam, serial dan tahil."))
                .font(.system(size: 12)).foregroundColor(Theme.text3)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bg)
        .presentationDetents([.height(280)])
    }

    private func row(_ l: String, _ r: String) -> some View {
        HStack {
            Text(l).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            Spacer()
            Text(r).font(.system(size: 12)).foregroundColor(Theme.text2)
        }
    }
}
