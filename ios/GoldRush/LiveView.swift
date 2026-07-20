import SwiftUI

struct LiveView: View {
    @StateObject private var vm = LiveViewModel()

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    metalPicker
                    purityPicker
                    priceBlock
                    if vm.metal == "gold" { tierGrid }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .task { await vm.start() }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Text("Au")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 38, height: 38)
                    .background(Theme.gold)
                    .cornerRadius(10)
                Text("Gold Rush")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(vm.isLive ? Theme.green : Theme.gold)
                    .frame(width: 7, height: 7)
                Text(vm.isLive ? "LIVE" : "…")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(vm.isLive ? Theme.green : Theme.text3)
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Theme.card)
            .clipShape(Capsule())
        }
    }

    // MARK: Metal picker

    private var metalPicker: some View {
        HStack(spacing: 0) {
            ForEach(["gold", "silver"], id: \.self) { m in
                let active = vm.metal == m
                Text(m == "gold" ? "Gold" : "Silver")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(active ? .black : Theme.text2)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(active ? Theme.gold : Color.clear)
                    .clipShape(Capsule())
                    .onTapGesture { withAnimation(.spring(response: 0.3)) { vm.selectMetal(m) } }
            }
        }
        .padding(5)
        .background(Theme.card)
        .clipShape(Capsule())
    }

    // MARK: Purity picker

    private var purityPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(vm.purities, id: \.self) { p in
                    let active = vm.purity == p
                    Text("\(p)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(active ? Theme.gold : Theme.text3)
                        .opacity(active ? 1 : 0.5)
                        .scaleEffect(active ? 1.15 : 1)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(active ? Theme.gold.opacity(0.09) : Color.clear)
                        .overlay(Capsule().stroke(active ? Theme.gold.opacity(0.25) : .clear, lineWidth: 1))
                        .clipShape(Capsule())
                        .onTapGesture { withAnimation(.spring(response: 0.35)) { vm.purity = p } }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: Price

    private var priceBlock: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("RM").font(.system(size: 22, weight: .medium)).foregroundColor(Theme.text2)
                Text(vm.entry.map { fmtRM($0.price) } ?? "—")
                    .font(.system(size: 54, weight: .heavy))
                    .foregroundColor(Theme.gold)
                    .contentTransition(.numericText())
                Text("/g").font(.system(size: 16)).foregroundColor(Theme.text3)
            }
            .animation(.spring(response: 0.4), value: vm.entry?.price)

            if let e = vm.entry {
                let up = e.change >= 0
                Text("\(up ? "▲" : "▼") RM \(fmtRM(abs(e.change)))  (\(up ? "+" : "")\(String(format: "%.2f", e.pct))%)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(up ? Theme.green : Theme.red)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background((up ? Theme.green : Theme.red).opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: Shop tiers

    private var tierGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Shop Price").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                Spacer()
                Text("\(vm.purity) · RM/g")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(Theme.gold)
                    .padding(.horizontal, 11).padding(.vertical, 3)
                    .background(Theme.gold.opacity(0.07)).clipShape(Capsule())
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                ForEach(Tier.allCases) { t in
                    tierCell(t)
                }
            }
            Text("New = buy new · Buyback = shop buys your gold. Prices move with the market and vary by shop.")
                .font(.system(size: 10)).foregroundColor(Theme.text3)
                .padding(.top, 2)
        }
    }

    private func tierCell(_ t: Tier) -> some View {
        let color: Color = t == .tradein ? Theme.purple : (t == .buyback ? Theme.pink : .white)
        return VStack(spacing: 5) {
            Text(t.label.uppercased())
                .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text3)
            Text(vm.tier(t).map { fmtRM($0) } ?? "—")
                .font(.system(size: 17, weight: .heavy)).foregroundColor(color)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardStroke, lineWidth: 1))
        .cornerRadius(16)
        .animation(.spring(response: 0.4), value: vm.spot999)
    }
}

struct LiveView_Previews: PreviewProvider {
    static var previews: some View {
        LiveView().preferredColorScheme(.dark)
    }
}
