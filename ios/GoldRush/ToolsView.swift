import SwiftUI

struct ToolsView: View {
    @EnvironmentObject var st: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                Text(st.t("Tools", "Alat"))
                    .font(.system(size: 21, weight: .heavy)).foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                CalculatorCard()
                ValuatorCard()
                AlertsCard()
                Spacer(minLength: 110)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
        }
    }
}

// MARK: - Weight ⇄ value calculator

struct CalculatorCard: View {
    @EnvironmentObject var st: AppState
    @State private var weight = ""
    @State private var value = ""
    @FocusState private var focus: Field?
    enum Field { case weight, value }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: st.t("Calculator", "Kalkulator"))
            HStack(spacing: 12) {
                field(st.t("Weight", "Berat") + " (\(st.unit.label))", $weight, .weight)
                Image(systemName: "arrow.left.arrow.right").font(.system(size: 15, weight: .bold)).foregroundColor(Theme.gold)
                field(st.t("Value (RM)", "Nilai (RM)"), $value, .value)
            }
        }
        .card()
        .onChange(of: weight) { _ in
            guard focus == .weight else { return }
            let perUnit = (st.entry?.price ?? 0) * st.unitFactor
            value = Double(weight).map { String(format: "%.2f", $0 * perUnit) } ?? ""
        }
        .onChange(of: value) { _ in
            guard focus == .value else { return }
            let perUnit = (st.entry?.price ?? 0) * st.unitFactor
            weight = (Double(value).flatMap { perUnit > 0 ? $0 / perUnit : nil })
                .map { String(format: "%.3f", $0) } ?? ""
        }
    }

    private func field(_ label: String, _ text: Binding<String>, _ f: Field) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text3)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .focused($focus, equals: f)
                .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                .padding(11).background(Color.white.opacity(0.04)).cornerRadius(11)
        }
    }
}

// MARK: - Old gold valuator

struct ValuatorCard: View {
    @EnvironmentObject var st: AppState
    @State private var purity = 916
    @State private var weight = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: st.t("Value My Old Gold", "Nilai Emas Lama"))
            HStack(spacing: 10) {
                Picker(st.t("Purity", "Ketulenan"), selection: $purity) {
                    ForEach(ShopTiers.purities, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.menu).tint(Theme.gold)
                TextField(st.t("Weight", "Berat") + " (\(st.unit.label))", text: $weight)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    .padding(11).background(Color.white.opacity(0.04)).cornerRadius(11)
            }
            result
        }
        .card()
    }

    private var result: some View {
        let w = Double(weight) ?? 0
        let perUnit = st.spot999 * Double(purity) / 1000 * st.unitFactor
        let melt = w * perUnit

        return Group {
            if melt > 0 {
                VStack(spacing: 10) {
                    VStack(spacing: 4) {
                        Text(st.t("Melt value today", "Nilai lebur hari ini").uppercased())
                            .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text3)
                        Text(fmtRM(melt)).font(.system(size: 22, weight: .heavy)).foregroundColor(.white)
                        Text("\(fmtQty(w)) \(st.unit.label) × \(fmtRM(perUnit))/\(st.unit.label) (\(purity))")
                            .font(.system(size: 10)).foregroundColor(Theme.text3)
                    }
                    VStack(spacing: 4) {
                        Text(st.t("Typical dealer buyback", "Anggaran belian balik peniaga").uppercased())
                            .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text3)
                        Text("\(fmtRM(melt * 0.88)) – \(fmtRM(melt * 0.98))")
                            .font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.gold)
                        Text(st.t("Bullion dealers pay near melt; jewellery shops pay less. Guide only — not a quote.",
                                  "Peniaga jongkong bayar hampir nilai lebur; kedai emas bayar kurang. Panduan sahaja — bukan sebut harga."))
                            .font(.system(size: 10)).foregroundColor(Theme.text3)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color.white.opacity(0.02)).cornerRadius(12)
            }
        }
    }
}

// MARK: - Price alerts (checked while the app is open)

struct AlertsCard: View {
    @EnvironmentObject var st: AppState
    @State private var target = ""
    @State private var above = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: st.t("Price Alerts", "Amaran Harga"))

            if st.alerts.isEmpty {
                Text(st.t("No alerts set. Get notified when gold hits your target price.",
                          "Tiada amaran ditetapkan. Dapatkan pemberitahuan apabila emas mencapai harga sasaran anda."))
                    .font(.system(size: 12)).foregroundColor(Theme.text3)
            }

            ForEach(st.alerts) { a in
                HStack {
                    Text("\(a.purity) \(st.t("Gold", "Emas")) \(Image(systemName: a.above ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")) \(fmtRM(a.target))")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    if a.triggered {
                        Text("HIT").font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.green)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Theme.green.opacity(0.1)).clipShape(Capsule())
                    }
                    Spacer()
                    Button {
                        st.alerts.removeAll { $0.id == a.id }
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.red)
                    }
                }
                .padding(11).background(Color.white.opacity(0.03)).cornerRadius(11)
            }

            HStack(spacing: 8) {
                TextField(st.t("Target RM/g", "Sasaran RM/g"), text: $target)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    .padding(10).background(Color.white.opacity(0.04)).cornerRadius(10)
                Picker("", selection: $above) {
                    Text(st.t("Below", "Bawah")).tag(false)
                    Text(st.t("Above", "Atas")).tag(true)
                }
                .pickerStyle(.segmented).frame(width: 130)
                Button {
                    guard let v = Double(target), v > 0 else { return }
                    st.alerts.append(PriceAlert(purity: st.purity, target: v, above: above))
                    target = ""
                } label: {
                    Text("Set").font(.system(size: 12, weight: .heavy)).foregroundColor(.black)
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Theme.gold).cornerRadius(10)
                }
            }

            Text(st.t("Checked every 30s while the app is open.", "Disemak setiap 30s semasa aplikasi dibuka."))
                .font(.system(size: 9)).foregroundColor(Theme.text3)
        }
        .card()
    }
}
