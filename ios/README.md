# Gold Rush — native iOS app

A proper native SwiftUI app (not a PWA/webview). It reuses the **existing Vercel
backend** — the same `/api/*` endpoints the website uses — so there is no backend
to rebuild. Only the UI is native Swift.

## Slice 2 (current): full app — web feature parity

Five native screens behind a floating pill tab bar (matchedGeometryEffect):

- **Live** — Gold/Silver, purity slider (999–375), live price with numericText
  transitions, Swift Charts history (24H–1Y) with smooth purity morph, shop
  tiers (New/Used/Trade-in/Buyback), unit-aware quick prices, RSI-based signal.
  Tap the `/g ⇄` pill to cycle g → mayam → serial → tahil; long-press for the
  unit info sheet.
- **Compare** — all dealers from `/api/content` with the `/api/live-dealers`
  crosscheck (✓ LIVE vs ≈ EST badges), physical/digital + category filters,
  popular/cheapest sort, premium vs spot, visit-site links, freshness line.
- **Portfolio** — jewellery item types, honest sell-back valuation (live best
  buyback, upah excluded), melt shown transparently, per-item "where to sell"
  drawer, add sheet.
- **Zakat** — Hijri year, nisab progress bar from portfolio, 354-day haul
  countdown, calculator (kept/worn + uruf), 14-state official payment directory.
- **Tools** — weight⇄value calculator, old-gold valuator, price alerts
  (checked every 30s while open).

Fully bilingual EN/BM (header toggle). Everything is driven by the production
Vercel APIs and refreshes every 30s. The whole source passes
`xcrun -sdk iphonesimulator swiftc -typecheck` clean.

## Set up in Xcode (one-time)

1. **Xcode → File → New → Project → iOS → App.**
   - Product Name: `GoldRush`
   - Interface: **SwiftUI**, Language: **Swift**
   - Minimum Deployments: **iOS 16.0** (needed for `.contentTransition`; iOS 17 also fine)
2. Xcode creates a `GoldRushApp.swift` and `ContentView.swift` — **delete both**
   from the project (move to trash).
3. Drag every `.swift` file from `ios/GoldRush/` into the Xcode project navigator
   (tick "Copy items if needed" is optional since they're already in the folder;
   easiest is to add the folder as a group).
4. **Build & run** (⌘R) on a simulator or your iPhone.

No `Info.plist` changes needed — the API is HTTPS, so App Transport Security is
satisfied out of the box.

## Files

| File | Purpose |
|------|---------|
| `GoldRushApp.swift` | App entry point |
| `Models.swift` | Codable structs for `/api/prices` |
| `APIClient.swift` | async URLSession client for the Vercel backend |
| `ShopTiers.swift` | GVM-derived New/Used/Trade-in/Buyback factor table |
| `Theme.swift` | brand colours + RM formatting |
| `LiveViewModel.swift` | state + 30s refresh |
| `LiveView.swift` | the Live screen UI |

## Roadmap (next slices)

- [ ] Swift Charts price history (`/api/history`) with the smooth purity morph
- [ ] Weight unit toggle (g / mayam / serial / tahil)
- [ ] Compare tab — dealers with ✓ LIVE / ≈ EST badges (`/api/live-dealers`)
- [ ] Zakat tab — nisab, haul, state directory
- [ ] Portfolio tab — jewellery items, honest sell-back
- [ ] Bottom tab bar + navigation
- [ ] Bahasa Melayu localization
- [ ] **Push notifications (APNs)** — price alerts, zakat haul, buy/sell signals
      (the feature that makes it a real app, not a website in a box)
- [ ] App icon + launch screen, App Store listing

## What only you can do

- Apple Developer account ($99/yr)
- Xcode builds / running on device / App Store submission
