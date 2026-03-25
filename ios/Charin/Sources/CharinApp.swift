import SwiftUI
import SwiftData

@main
struct CharinApp: App {
    let container: ModelContainer
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    init() {
        let schema = Schema([Income.self, Client.self])
        let config = ModelConfiguration(
            "CharinStore",
            schema: schema,
            cloudKitDatabase: .none
        )
        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            // Fallback to in-memory
            let fallback = ModelConfiguration(
                "CharinStore",
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            container = try! ModelContainer(for: schema, configurations: fallback)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(subscriptionManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    SeedData.insertIfEmpty(context: container.mainContext)
                    ClientManager.seedIfEmpty(context: container.mainContext)
                    Task {
                        #if !targetEnvironment(simulator)
                        await NotificationManager.shared.requestPermission()
                        #endif
                    }
                }
        }
        .modelContainer(container)
    }
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            ContentView()
        } else {
            OnboardingView()
        }
    }
}
