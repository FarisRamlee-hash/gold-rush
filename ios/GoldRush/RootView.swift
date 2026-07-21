import SwiftUI

enum Tab: String, CaseIterable {
    case live, compare, portfolio, zakat, tools

    var icon: String {
        switch self {
        case .live: return "chart.line.uptrend.xyaxis"
        case .compare: return "slider.horizontal.3"
        case .portfolio: return "lock.shield"
        case .zakat: return "moon.stars"
        case .tools: return "wrench.and.screwdriver"
        }
    }

    @MainActor func label(_ st: AppState) -> String {
        switch self {
        case .live: return "Live"
        case .compare: return st.t("Compare", "Banding")
        case .portfolio: return "Portfolio"
        case .zakat: return "Zakat"
        case .tools: return st.t("Tools", "Alat")
        }
    }
}

struct RootView: View {
    @StateObject private var st = AppState()
    @State private var tab: Tab = .live
    @Namespace private var tabNS

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            Group {
                switch tab {
                case .live: LiveView()
                case .compare: CompareView()
                case .portfolio: PortfolioView()
                case .zakat: ZakatView()
                case .tools: ToolsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)

            tabBar
        }
        .environmentObject(st)
        .preferredColorScheme(.dark)
        .task { await st.start() }
    }

    /// Floating minimalist pill — icon-only inactive, active expands with label.
    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(Tab.allCases, id: \.self) { t in
                let active = tab == t
                HStack(spacing: 7) {
                    Image(systemName: t.icon)
                        .font(.system(size: 17, weight: .semibold))
                    if active {
                        Text(t.label(st))
                            .font(.system(size: 12, weight: .heavy))
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .foregroundColor(active ? Theme.gold : Theme.text3)
                .padding(.horizontal, active ? 17 : 13)
                .padding(.vertical, 12)
                .background {
                    if active {
                        Capsule()
                            .fill(Theme.goldSoft)
                            .overlay(Capsule().stroke(Theme.gold.opacity(0.18), lineWidth: 1))
                            .matchedGeometryEffect(id: "tabpill", in: tabNS)
                    }
                }
                .onTapGesture {
                    if tab != t { Haptics.select() }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { tab = t }
                }
            }
        }
        .padding(6)
        .background(.ultraThinMaterial.opacity(0.9), in: Capsule())
        .background(Theme.bg.opacity(0.6), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 18, y: 10)
        .padding(.bottom, 8)
    }
}
