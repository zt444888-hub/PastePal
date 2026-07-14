import SwiftUI
import SwiftData

let kSeedDataKey = "pastepal_seed_v1"

@main
struct PastePalApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([PasteItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .preferredColorScheme(.dark)
                .onAppear {
                    seedIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func seedIfNeeded() {
        let seeded = UserDefaults.standard.bool(forKey: kSeedDataKey)
        guard !seeded else { return }
        UserDefaults.standard.set(true, forKey: kSeedDataKey)
        
        let ctx = sharedModelContainer.mainContext
        let demoItems = [
            PasteItem(
                content: "https://developer.apple.com/documentation/swiftdata",
                contentType: "url",
                createdAt: Date().addingTimeInterval(-3600),
                pinnedAt: Date().addingTimeInterval(-3600),
                sourceAppName: "Safari",
                sourceAppBundleId: "com.apple.mobilesafari",
                isFavorite: true
            ),
            PasteItem(
                content: "Weekly grocery list:\n- Milk\n- Eggs\n- Bread\n- Avocados\n- Coffee beans",
                contentType: "text",
                createdAt: Date().addingTimeInterval(-7200),
                sourceAppName: "Notes",
                sourceAppBundleId: "com.apple.mobilenotes"
            ),
            PasteItem(
                content: """
                struct PasteItem: Identifiable {
                    let id: UUID
                    var content: String
                    var createdAt: Date
                }
                """,
                contentType: "code",
                createdAt: Date().addingTimeInterval(-10800),
                sourceAppName: "Xcode",
                sourceAppBundleId: "com.apple.dt.Xcode",
                tags: ["Swift", "Code"]
            ),
            PasteItem(
                content: "Design review meeting @ 3PM in Conference Room B",
                contentType: "text",
                createdAt: Date().addingTimeInterval(-14400),
                sourceAppName: "Slack",
                sourceAppBundleId: "com.tinyspeck.slack"
            ),
            PasteItem(
                content: "sk-proj-apiKeysAndSecretsJWT12345XYZabc123",
                contentType: "text",
                createdAt: Date().addingTimeInterval(-18000),
                sourceAppName: "1Password",
                sourceAppBundleId: "com.agilebits.onepassword",
                isSensitive: true
            ),
        ]
        for item in demoItems {
            ctx.insert(item)
        }
        try? ctx.save()
    }
}
