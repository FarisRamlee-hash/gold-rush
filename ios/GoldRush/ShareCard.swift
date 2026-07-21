import SwiftUI
import UIKit

/// Spotify-style story card (1080×1920 @3x) rendered natively and pushed to
/// the iOS share sheet — WhatsApp/IG-ready, mirrors the web PWA share cards.
struct ShareCardView: View {
    @EnvironmentObject var st: AppState

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.14), Theme.bg],
                           startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(Theme.gold.opacity(0.10))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(y: -190)

            VStack(spacing: 0) {
                // Header
                Text("Au")
                    .font(.system(size: 22, weight: .bold)).foregroundColor(.black)
                    .frame(width: 46, height: 46)
                    .background(Theme.gold).cornerRadius(12)
                Text("Gold Rush")
                    .font(.system(size: 24, weight: .heavy)).foregroundColor(.white)
                    .padding(.top, 10)
                Text(st.t("LIVE GOLD PRICE", "HARGA EMAS LANGSUNG"))
                    .font(.system(size: 10, weight: .bold)).tracking(2)
                    .foregroundColor(Theme.gold.opacity(0.6))
                    .padding(.top, 4)
                Text(Date().formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11)).foregroundColor(Theme.text3)
                    .padding(.top, 6)

                // Purity pill
                Text("\(st.purity) \(st.t("GOLD", "EMAS"))")
                    .font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.gold)
                    .padding(.horizontal, 16).padding(.vertical, 7)
                    .background(Theme.goldSoft)
                    .overlay(Capsule().stroke(Theme.gold.opacity(0.3), lineWidth: 1))
                    .clipShape(Capsule())
                    .padding(.top, 26)

                // Price
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("RM").font(.system(size: 17, weight: .medium)).foregroundColor(Theme.text2)
                    Text(st.entry.map { fmtNum($0.price * st.unitFactor) } ?? "—")
                        .font(.system(size: 46, weight: .heavy)).foregroundColor(.white)
                    Text("/\(st.unit.label)").font(.system(size: 14)).foregroundColor(Theme.text3)
                }
                .padding(.top, 18)

                if let e = st.entry {
                    let up = e.change >= 0
                    HStack(spacing: 4) {
                        Image(systemName: up ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("RM \(fmtNum(abs(e.change) * st.unitFactor)) (\(up ? "+" : "")\(String(format: "%.2f", e.pct))%)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(up ? Theme.green : Theme.red)
                    .padding(.horizontal, 13).padding(.vertical, 6)
                    .background((up ? Theme.green : Theme.red).opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.top, 10)
                }

                // Shop tiers 2×2
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 9) {
                    tile(st.t("NEW", "BARU"), .new, .white)
                    tile(st.t("USED", "TERPAKAI"), .used, .white.opacity(0.8))
                    tile("TRADE-IN", .tradein, Theme.purple)
                    tile(st.t("BUYBACK", "BELI BALIK"), .buyback, Theme.pink)
                }
                .padding(.top, 26)

                Spacer(minLength: 0)

                // Footer
                Text("gold-rush-tau.vercel.app")
                    .font(.system(size: 13, weight: .heavy)).foregroundColor(Theme.gold.opacity(0.7))
                Text(st.t("Prices move with the market and vary by shop",
                          "Harga berubah ikut pasaran & berbeza setiap kedai"))
                    .font(.system(size: 8)).foregroundColor(Theme.text3)
                    .padding(.top, 4)
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 26)
        }
        .frame(width: 360, height: 640)
    }

    private func tile(_ label: String, _ t: Tier, _ color: Color) -> some View {
        VStack(spacing: 5) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.gold.opacity(0.5))
            Text(st.tier(t).map { fmtNum($0 * st.unitFactor) } ?? "—")
                .font(.system(size: 19, weight: .heavy)).foregroundColor(color)
            Text("RM/\(st.unit.label)").font(.system(size: 8)).foregroundColor(Theme.text3)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 15)
        .background(Color.white.opacity(0.03))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .cornerRadius(15)
    }
}

/// Preview + share sheet: shows the card, renders it @3x, hands it to iOS share.
struct ShareSheetView: View {
    @EnvironmentObject var st: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var rendered: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(Color.white.opacity(0.15)).frame(width: 36, height: 4).padding(.top, 12)

            ShareCardView()
                .environmentObject(st)
                .scaleEffect(0.58)
                .frame(width: 360 * 0.58, height: 640 * 0.58)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.5), radius: 24, y: 12)

            if let img = rendered {
                ShareLink(
                    item: Image(uiImage: img),
                    preview: SharePreview("Gold Rush — \(st.t("Gold Price", "Harga Emas"))",
                                          image: Image(uiImage: img))
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text(st.t("Share", "Kongsi"))
                    }
                    .font(.system(size: 15, weight: .heavy)).foregroundColor(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Theme.gold).cornerRadius(15)
                }
                .padding(.horizontal, 24)
            } else {
                ProgressView().tint(Theme.gold).padding(.vertical, 14)
            }

            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .presentationDetents([.height(560)])
        .task {
            // Render at 3x for a crisp 1080×1920 story image.
            let renderer = ImageRenderer(content: ShareCardView().environmentObject(st))
            renderer.scale = 3
            rendered = renderer.uiImage
        }
    }
}
