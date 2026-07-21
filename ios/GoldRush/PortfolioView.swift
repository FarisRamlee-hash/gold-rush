import SwiftUI

struct PortfolioView: View {
    @EnvironmentObject var st: AppState
    @State private var showAdd = false
    @State private var expanded: UUID?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                summaryCard

                Text(st.t("Values shown are realistic sell-back today (below melt for jewellery, which loses its workmanship fee). Not retail price.",
                          "Nilai dipaparkan ialah nilai jual balik sebenar hari ini (bawah nilai lebur untuk barang kemas kerana kehilangan upah). Bukan harga runcit."))
                    .font(.system(size: 10)).foregroundColor(Theme.text3)
                    .multilineTextAlignment(.center)

                HStack {
                    SectionTitle(text: st.t("My Gold", "Emas Saya"))
                    Spacer()
                }

                if st.holdings.isEmpty {
                    Text(st.t("No items yet. Add your gold — rings, chains, coins or bars — to track what they are worth to sell today.",
                              "Belum ada barang. Tambah emas anda — cincin, rantai, syiling atau jongkong — untuk jejak nilai jualnya hari ini."))
                        .font(.system(size: 13)).foregroundColor(Theme.text3)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 30)
                } else {
                    ForEach(st.holdings) { h in
                        holdingCard(h)
                    }
                }

                Button { showAdd = true } label: {
                    Text("+ \(st.t("Add Item", "Tambah Barang"))")
                        .font(.system(size: 14, weight: .heavy)).foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 13)
                        .background(Theme.gold).cornerRadius(14)
                }

                Spacer(minLength: 110)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
        }
        .sheet(isPresented: $showAdd) { AddHoldingSheet() }
    }

    // MARK: Summary

    private var summaryCard: some View {
        let sell = st.portfolioSell
        let cost = st.portfolioCost
        let pl = sell - cost
        let up = pl >= 0

        return VStack(spacing: 8) {
            Text(st.t("Est. Sell Value Today", "Anggaran Nilai Jual Hari Ini").uppercased())
                .font(.system(size: 10, weight: .bold)).tracking(1).foregroundColor(Theme.text3)
            Text(fmtRM(sell))
                .font(.system(size: 34, weight: .heavy)).foregroundColor(Theme.gold)
                .contentTransition(.numericText())
            if cost > 0 {
                Text("\(up ? "+" : "")\(fmtRM(pl)) (\(up ? "+" : "")\(String(format: "%.1f", pl / cost * 100))%)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(up ? Theme.green : Theme.red)
            }
            Text("\(String(format: "%.1f", st.portfolioGrams))g · \(st.t("Melt", "Lebur")) \(fmtRM(st.portfolioMelt)) · \(st.t("paid", "dibayar")) \(fmtRM(cost))")
                .font(.system(size: 11)).foregroundColor(Theme.text3)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 20)
    }

    // MARK: Item card

    private func holdingCard(_ h: Holding) -> some View {
        let ti = ItemType.by(h.type)
        let sell = st.holdingValue(h)
        let melt = st.holdingMelt(h)
        let cost = h.grams * h.paidPerG
        let pl = sell - cost
        let up = pl >= 0
        let isOpen = expanded == h.id

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(ti.emoji) \(h.label.isEmpty ? (st.lang == "bm" ? ti.bm : ti.en) : h.label)")
                        .font(.system(size: 14, weight: .heavy)).foregroundColor(.white)
                    Text("\(fmtQty(h.grams))g \(h.purity) · \(st.lang == "bm" ? ti.bm : ti.en) · \(st.t("paid", "dibayar")) \(fmtRM(h.paidPerG))/g")
                        .font(.system(size: 10)).foregroundColor(Theme.text3)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(fmtRM(sell)).font(.system(size: 16, weight: .heavy)).foregroundColor(.white)
                    Text("\(st.t("Melt", "Lebur")) \(fmtRM(melt))")
                        .font(.system(size: 9)).foregroundColor(Theme.text3)
                    if cost > 0 {
                        Text("\(up ? "+" : "")\(fmtRM(pl)) (\(up ? "+" : "")\(String(format: "%.1f", pl / cost * 100))%)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(up ? Theme.green : Theme.red)
                    }
                }
            }

            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.35)) { expanded = isOpen ? nil : h.id }
                } label: {
                    Text("💰 \(st.t("Where to sell", "Di mana nak jual"))")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(Theme.gold)
                        .frame(maxWidth: .infinity).padding(.vertical, 9)
                        .background(Theme.goldSoft)
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.gold.opacity(0.2), lineWidth: 1))
                        .cornerRadius(11)
                }
                Button {
                    withAnimation { st.holdings.removeAll { $0.id == h.id } }
                } label: {
                    Text(st.t("Remove", "Buang"))
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.red)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(Theme.red.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Theme.red.opacity(0.15), lineWidth: 1))
                        .cornerRadius(11)
                }
            }

            if isOpen {
                sellDrawer(h, itemType: ti, sell: sell)
            }
        }
        .card(padding: 14)
    }

    private func sellDrawer(_ h: Holding, itemType ti: ItemType, sell: Double) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            if let bb = st.bestBuyback(purity: h.purity), let sellP = bb.sellP {
                HStack(spacing: 5) {
                    Text("\(st.t("Highest buyback today", "Beli balik tertinggi hari ini")):")
                        .font(.system(size: 11)).foregroundColor(Theme.text2)
                    Text(bb.dealer.name).font(.system(size: 11, weight: .heavy)).foregroundColor(.white)
                    if bb.live {
                        Text("✓ LIVE").font(.system(size: 8, weight: .heavy)).foregroundColor(Theme.green)
                    }
                }
                Text("\(st.t("pays", "bayar")) \(fmtRM(sellP))/g · \(st.t("your item fetches about", "barang anda dapat kira-kira")) \(fmtRM(sell))\(ti.bullion ? "" : " · \(st.t("workmanship (upah) not recovered", "upah tidak dikembalikan"))")")
                    .font(.system(size: 11)).foregroundColor(Theme.text2)
                if let u = bb.dealer.url, let url = URL(string: u) {
                    Link("\(st.t("Sell here", "Jual di sini")) ↗", destination: url)
                        .font(.system(size: 11, weight: .heavy)).foregroundColor(Theme.gold)
                        .padding(.top, 2)
                }
            } else {
                Text(st.t("No live buyback price for this purity yet. Check the Compare tab.",
                          "Belum ada harga beli balik langsung untuk ketulenan ini. Semak tab Banding."))
                    .font(.system(size: 11)).foregroundColor(Theme.text3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.025)).cornerRadius(12)
    }
}

// MARK: - Add sheet

struct AddHoldingSheet: View {
    @EnvironmentObject var st: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var type = "ring"
    @State private var purity = 916
    @State private var label = ""
    @State private var grams = ""
    @State private var paid = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Picker(st.t("Item", "Jenis"), selection: $type) {
                    ForEach(ItemType.all) { t in
                        Text("\(t.emoji) \(st.lang == "bm" ? t.bm : t.en)").tag(t.id)
                    }
                }
                Picker(st.t("Purity", "Ketulenan"), selection: $purity) {
                    ForEach(ShopTiers.purities, id: \.self) { Text("\($0)").tag($0) }
                }
                TextField(st.t("Label (e.g. Wife's ring)", "Label (cth. Cincin isteri)"), text: $label)
                TextField(st.t("Weight (g)", "Berat (g)"), text: $grams)
                    .keyboardType(.decimalPad)
                TextField(st.t("Paid price/g (RM)", "Harga dibayar/g (RM)"), text: $paid)
                    .keyboardType(.decimalPad)
                DatePicker(st.t("Purchase date", "Tarikh pembelian"), selection: $date, displayedComponents: .date)
            }
            .navigationTitle(st.t("Add Item", "Tambah Barang"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(st.t("Save", "Simpan")) {
                        let g = Double(grams) ?? 0
                        guard g > 0 else { return }
                        st.holdings.append(Holding(
                            type: type,
                            label: String(label.prefix(40)),
                            purity: purity,
                            grams: g,
                            paidPerG: Double(paid) ?? 0,
                            date: date
                        ))
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(st.t("Cancel", "Batal")) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}
