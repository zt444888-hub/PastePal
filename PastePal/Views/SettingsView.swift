import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var history: [PasteItem]
    @ObservedObject private var iapManager = IAPManager.shared
    
    @AppStorage("secureShredMode") private var secureShredMode = false
    @AppStorage("sensitiveDetection") private var sensitiveDetection = true
    @State private var ignoredApps: [String] = ["Keychain", "Password Safe"]
    
    @State private var showWipeConfirm = false
    @State private var showTipJar = false
    @State private var showAddAppAlert = false
    @State private var newAppName = ""
    
    var body: some View {
        NavigationStack {
            List {
            Section(header: Text("Security & Masking")) {
                Toggle(isOn: $sensitiveDetection) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sensitive Masking")
                                .font(.body)
                            Text("Scramble credit cards, PINs, and tokens.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    } icon: {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(.blueColor)
                    }
                }
                
                Toggle(isOn: $secureShredMode) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Privacy Shredder")
                                .font(.body)
                            Text("Securely overwrite binary segments on deletion.")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    } icon: {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            
            Section(header: Text("Ignored Applications")) {
                ForEach(ignoredApps, id: \.self) { app in
                    HStack {
                        Image(systemName: "slash.circle.fill")
                            .foregroundColor(.gray)
                        Text(app)
                        Spacer()
                    }
                }
                .onDelete(perform: removeIgnoredApp)
                
                Button {
                    showAddAppAlert = true
                } label: {
                    Label("Ignore New App...", systemImage: "plus")
                        .foregroundColor(.blueColor)
                }
            }
            
            Section(header: Text("Appearance & Customization")) {
                NavigationLink {
                    AnalyticsView()
                } label: {
                    Label("Developer Analytics", systemImage: "chart.bar.xaxis")
                        .foregroundColor(.orange)
                }
                
                Button {
                    showTipJar = true
                } label: {
                    Label("Tip Jar — Support Development", systemImage: "heart.fill")
                        .foregroundColor(.pink)
                }
                
                Button {
                    UserDefaults.standard.set(false, forKey: "pastepal_onboarding_v1")
                } label: {
                    Label("Show Onboarding Again", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blueColor)
                }
            }
            
            Section(header: Text("Storage Maintenance")) {
                HStack {
                    Text("Total Cached Clips")
                    Spacer()
                    Text("\(history.count) items")
                        .foregroundColor(.gray)
                }
                
                Button(role: .destructive) {
                    showWipeConfirm = true
                } label: {
                    Label("Wipe Entire Clipboard Cache", systemImage: "trash.slash")
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Ignore Application", isPresented: $showAddAppAlert) {
            TextField("Application Name", text: $newAppName)
            Button("Cancel", role: .cancel) { newAppName = "" }
            Button("Add") {
                if !newAppName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ignoredApps.append(newAppName)
                    UserDefaults.standard.set(ignoredApps, forKey: "ignoredApps")
                    newAppName = ""
                }
            }
        } message: {
            Text("PastePal will skip recording copying operations executed inside this specified app.")
        }
        .confirmationDialog("Wipe database?", isPresented: $showWipeConfirm, titleVisibility: .visible) {
            Button("Wipe Everything", role: .destructive) { wipeHistory() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action is irreversible. All cached snippets will be permanently purged.")
        }
        .sheet(isPresented: $showTipJar) {
            TipJarView()
                .environmentObject(iapManager)
        }
        .onAppear {
            if let saved = UserDefaults.standard.stringArray(forKey: "ignoredApps") {
                ignoredApps = saved
            }
        }
        .task {
            guard !iapManager.hasLoaded else { return }
            await iapManager.loadProducts()
    }

        }
    }



    private func removeIgnoredApp(at offsets: IndexSet) {
        ignoredApps.remove(atOffsets: offsets)
        UserDefaults.standard.set(ignoredApps, forKey: "ignoredApps")
    }
    
    private func wipeHistory() {
        for item in history {
            modelContext.delete(item)
        }
        try? modelContext.save()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct TipJarView: View {
    @EnvironmentObject private var iapManager: IAPManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var purchaseSuccess = false
    @State private var purchaseFailed = false
    @State private var storeNotConfigured = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                    .padding(.top)
                
                Text("Support PastePal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your support fuels the continuous development of clipboard developer features like JSON explorers, regex triggers and secure privacy shredding.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if !iapManager.hasLoaded {
                ProgressView("Loading...")
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(iapManager.tipOptions) { option in
                        Button {
                            Task {
                                let success = await iapManager.purchase(option)
                                if !iapManager.storeAvailable {
                                    storeNotConfigured = true
                                } else if success {
                                    purchaseSuccess = true
                                } else {
                                    purchaseFailed = true
                                }
                            }
                        } label: {
                            HStack {
                                Text(option.displayName)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(option.displayPrice)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blueColor)
                            }
                            .padding()
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1.5)
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(iapManager.isPurchasing)
                    }
                }
                .padding(.horizontal)
                
                if !iapManager.storeAvailable {
                    Text("💡 Set up StoreKit Config in Xcode Scheme → Run → Options → StoreKit Configuration to test purchases")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
            }
            
            if iapManager.isPurchasing {
                ProgressView()
                    .padding()
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blueColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .background(Color(red: 0.1, green: 0.1, blue: 0.12).edgesIgnoringSafeArea(.all))
        .alert("Thank You! 🎉", isPresented: $purchaseSuccess) {
            Button("You're welcome!", role: .cancel) { dismiss() }
        } message: {
            Text("Your support means the world. PastePal will keep getting better because of you.")
        }
        .alert("Purchase Failed", isPresented: $purchaseFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The transaction didn't go through. Please try again.")
        }
        .alert("StoreKit Not Configured", isPresented: $storeNotConfigured) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("To test in-app purchases, configure StoreKit in Xcode: Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration, then select StoreKitConfig.storekit.")
        }
    }
}
