import SwiftUI

struct ZakatView: View {
    @EnvironmentObject var st: AppState
    @State private var grams = ""
    @State private var worn = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                heroCard
                calculatorCard
                payCard
                Spacer(minLength: 110)
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
        }
    }

    // MARK: Hero — nisab progress + haul

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(st.t("Gold Zakat", "Zakat Emas"))
                    .font(.system(size: 19, weight: .heavy)).foregroundColor(.white)
                Spacer()
                if let hy = st.hijriYear {
                    Text("\(hy)H")
                        .font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.gold)
                        .padding(.horizontal, 11).padding(.vertical, 4)
                        .background(Theme.goldSoft)
                        .overlay(Capsule().stroke(Theme.gold.opacity(0.25), lineWidth: 1))
                        .clipShape(Capsule())
                }
            }

            if st.holdings.isEmpty {
                Text(st.t("Add your gold in the Portfolio tab to track nisab progress, haul and zakat automatically.",
                          "Tambah emas anda dalam tab Portfolio untuk menjejak nisab, haul dan zakat secara automatik."))
                    .font(.system(size: 12)).foregroundColor(Theme.text3)
            } else {
                let pure = st.pureGoldGrams
                let pct = min(1, pure / AppState.nisabGrams)
                let over = pure >= AppState.nisabGrams

                HStack {
                    Text("\(String(format: "%.1f", pure))g / \(Int(AppState.nisabGrams))g nisab")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text2)
                    Spacer()
                    Text("\(Int(pct * 100))%")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(Theme.gold)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.06)).frame(height: 10)
                        Capsule()
                            .fill(LinearGradient(colors: [Theme.gold.opacity(0.5), Theme.gold],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * pct, height: 10)
                    }
                }
                .frame(height: 10)
                .animation(.spring(response: 0.6), value: pct)

                if over {
                    let due = st.portfolioMelt * AppState.zakatRate
                    Text("\(Image(systemName: "checkmark.circle.fill")) \(st.t("Above nisab — zakat applies", "Melebihi nisab — zakat dikenakan")) · \(st.t("estimated zakat", "anggaran zakat")): ").font(.system(size: 12)).foregroundColor(Theme.green)
                    + Text(fmtRM(due)).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.gold)
                } else {
                    Text("\(st.t("Below nisab — no zakat yet", "Bawah nisab — belum wajib zakat")) (nisab ≈ \(fmtRM(st.nisabRM)))")
                        .font(.system(size: 12)).foregroundColor(Theme.text3)
                }

                if let end = st.haulEnd {
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
                    HStack(alignment: .top, spacing: 7) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 12)).foregroundColor(Theme.gold)
                        Text(days > 0
                             ? st.t("Haul complete in \(days) days — zakat falls due if you stay above nisab.", "Haul genap dalam \(days) hari — zakat wajib jika kekal melebihi nisab.")
                             : st.t("Haul complete — zakat is due this year", "Haul genap — zakat wajib tahun ini"))
                            .font(.system(size: 11)).foregroundColor(days > 0 ? Theme.text2 : Theme.gold)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.03)).cornerRadius(12)
                }
            }
        }
        .card()
    }

    // MARK: Calculator

    private var calculatorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: st.t("Zakat Calculator", "Kalkulator Zakat"))

            if st.portfolioGrams > 0 {
                Button {
                    grams = String(format: "%.1f", st.portfolioGrams)
                } label: {
                    Text("\(st.t("Use my portfolio", "Guna portfolio saya")) (\(String(format: "%.1f", st.portfolioGrams))g)")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(Theme.gold)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(Theme.goldSoft)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.gold.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4])))
                        .cornerRadius(12)
                }
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(st.t("Gold held (g)", "Emas dimiliki (g)"))
                        .font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text3)
                    TextField("100", text: $grams)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        .padding(11).background(Color.white.opacity(0.04)).cornerRadius(11)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(st.t("Type", "Jenis"))
                        .font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.text3)
                    Picker("", selection: $worn) {
                        Text(st.t("Kept", "Simpanan")).tag(false)
                        Text(st.t("Worn", "Dipakai")).tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 5)
                }
            }

            resultRow
        }
        .card()
    }

    private var resultRow: some View {
        let g = Double(grams) ?? 0
        let p999 = st.goldPerGram(purity: 999)
        var due: Double? = nil
        var note = ""

        if g > 0, p999 > 0 {
            if worn {
                if g <= AppState.urufGrams {
                    note = st.t("Exempt — within uruf (\(Int(AppState.urufGrams))g)", "Dikecualikan — dalam uruf (\(Int(AppState.urufGrams))g)")
                } else {
                    due = (g - AppState.urufGrams) * p999 * AppState.zakatRate
                }
            } else if g * p999 < st.nisabRM {
                note = st.t("Exempt — below nisab", "Dikecualikan — bawah nisab")
            } else {
                due = g * p999 * AppState.zakatRate
            }
        }

        return VStack(spacing: 5) {
            Text(st.t("Zakat due", "Zakat perlu dibayar").uppercased())
                .font(.system(size: 9, weight: .bold)).foregroundColor(Theme.text3)
            Text(due.map(fmtRM) ?? (note.isEmpty ? "—" : note))
                .font(.system(size: due != nil ? 22 : 13, weight: .heavy))
                .foregroundColor(due != nil ? Theme.gold : Theme.text3)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Color.white.opacity(0.02)).cornerRadius(12)
    }

    // MARK: Pay online

    private var payCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: st.t("Pay Zakat Online", "Bayar Zakat Dalam Talian"))
            Picker(st.t("Your state", "Negeri anda"), selection: $st.zakatStateIdx) {
                ForEach(Array(ZakatBody.all.enumerated()), id: \.offset) { i, b in
                    Text(b.state).tag(i)
                }
            }
            .pickerStyle(.menu).tint(Theme.gold)

            let body = ZakatBody.all[st.zakatStateIdx]
            if let url = URL(string: body.url) {
                Link(destination: url) {
                    HStack(spacing: 6) {
                        Text("\(st.t("Pay via", "Bayar melalui")) \(body.name)")
                        Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .heavy)).foregroundColor(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(Theme.gold).cornerRadius(13)
                }
            }
            Text(st.t("Official zakat body for your state. Uruf varies by state — check with your zakat body. Estimates, not a fatwa.",
                      "Badan zakat rasmi negeri anda. Uruf berbeza mengikut negeri — semak dengan badan zakat anda. Anggaran, bukan fatwa."))
                .font(.system(size: 10)).foregroundColor(Theme.text3)
        }
        .card()
    }
}
