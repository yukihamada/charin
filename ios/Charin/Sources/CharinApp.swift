import SwiftUI
import SwiftData
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var container: ModelContainer?

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationManager.shared.registerPushToken(deviceToken)
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let income = NotificationManager.handleRevenuePush(userInfo: userInfo),
           let ctx = container?.mainContext {
            ctx.insert(income)
            try? ctx.save()
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
}

@main
struct CharinApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
                    appDelegate.container = container
                    SeedData.insertIfEmpty(context: container.mainContext)
                    ClientManager.seedIfEmpty(context: container.mainContext)
                    Task {
                        // Always request push permission + register
                        await NotificationManager.shared.requestPermission()
                        // Fetch pending income from server
                        await PendingIncomeSync.fetch(context: container.mainContext)
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
