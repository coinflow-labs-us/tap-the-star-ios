import SwiftData
import SwiftUI

@main
struct test_checkout_iosApp: App {
    @StateObject var gameState = GameState()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameState)
                .onOpenURL { url in
                    // Handle the deep link here
                    if url.scheme == "testcheckout" && url.host == "checkout-complete" {
                        gameState.credits += 500
                        gameState.toastMessage = "+500 credits added!"
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
