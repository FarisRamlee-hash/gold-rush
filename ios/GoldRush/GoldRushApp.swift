import SwiftUI

@main
struct GoldRushApp: App {
    var body: some Scene {
        WindowGroup {
            LiveView()
                .preferredColorScheme(.dark)
        }
    }
}
