import SwiftUI

let kOnboardingKey = "pastepal_onboarding_v1"

struct AppTabView: View {
    @AppStorage(kOnboardingKey) private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
            hasCompletedOnboarding = true
        }) {
            OnboardingView(showOnboarding: $showOnboarding)
        }
        .onAppear {
            // Reset so onboarding shows every time during development
            UserDefaults.standard.set(false, forKey: kOnboardingKey)
            let hasSeen = UserDefaults.standard.bool(forKey: kOnboardingKey)
            if !hasSeen {
                showOnboarding = true
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, newValue in
            if !newValue {
                showOnboarding = true
            }
        }
    }
}
