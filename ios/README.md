# Gold Rush — native iOS app

A proper native SwiftUI app (not a PWA/webview). It reuses the **existing Vercel
backend** — the same `/api/*` endpoints the website uses — so there is no backend
to rebuild. Only the UI is native Swift.

## Slice 1 (this commit): Live screen

Native Live tab: Gold/Silver toggle, purity selector (999–375), live price with
change, and the shop-price tiers (New / Used / Trade-in / Buyback), all driven by
`https://gold-rush-tau.vercel.app/api/prices` and auto-refreshing every 30s.

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
