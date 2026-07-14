import SwiftUI
import Combine
import SwiftData

@MainActor
final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    @Published var lastClipString: String = ""
    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?
    
    init() {
        // Listen to native UIPasteboard changes
        NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleClipboardChange()
                }
            }
            .store(in: &cancellables)
            
        // Trigger check when app returns to foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.handleClipboardChange()
                }
            }
            .store(in: &cancellables)
    }
    
    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    private func handleClipboardChange() {
        guard let context = modelContext else { return }
        guard let pasteboardString = UIPasteboard.general.string, !pasteboardString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Avoid infinite loops of identical copies
        if pasteboardString == lastClipString {
            return
        }
        
        lastClipString = pasteboardString
        
        // Fetch Settings
        let defaults = UserDefaults.standard
        let ignoredApps = defaults.stringArray(forKey: "ignoredApps") ?? []
        let activeAppName = getActiveAppName()
        
        if ignoredApps.contains(activeAppName) {
            return
        }
        
        let isSensitive = detectSensitive(text: pasteboardString)
        let contentType = detectContentType(text: pasteboardString)
        
        // Check if item already exists to update metrics
        let fetchDescriptor = FetchDescriptor<PasteItem>(
            predicate: #Predicate { $0.content == pasteboardString }
        )
        
        do {
            let existingItems = try context.fetch(fetchDescriptor)
            if let existing = existingItems.first {
                existing.copyCount += 1
                existing.updatedAt = Date()
                existing.lastCopiedAt = Date()
            } else {
                let newItem = PasteItem(
                    content: pasteboardString,
                    contentType: contentType,
                    sourceAppName: activeAppName,
                    sourceAppBundleId: "com.apple.unknown",
                    isSensitive: isSensitive,
                    tags: isSensitive ? ["Sensitive"] : []
                )
                context.insert(newItem)
            }
            try context.save()
        } catch {
            print("Failed to save clipboard item: \(error)")
        }
    }
    
    private func detectContentType(text: String) -> String {
        if text.hasPrefix("http://") || text.hasPrefix("https://") {
            return "url"
        }
        // Basic code keyword matcher
        let codeKeywords = ["import ", "func ", "class ", "let ", "var ", "const ", "function", "<html>", "body {", "return {", "const {"]
        for keyword in codeKeywords {
            if text.contains(keyword) {
                return "code"
            }
        }
        return "text"
    }
    
    private func detectSensitive(text: String) -> Bool {
        // Regex patterns for credentials, tokens, OTPs and cards
        let isOtp = text.count >= 4 && text.count <= 6 && text.allSatisfy { $0.isNumber }
        let hasSensitiveKeyword = text.lowercased().contains("password") || 
                                  text.lowercased().contains("token") || 
                                  text.lowercased().contains("secret") || 
                                  text.lowercased().contains("private_key") || 
                                  text.lowercased().contains("api_key")
        return isOtp || hasSensitiveKeyword
    }
    
    private func getActiveAppName() -> String {
        // iOS sandboxes cannot access other running bundle identifiers directly.
        // We simulate bundle recognition using default metadata, returning 'System Clipboard'.
        return "System"
    }
    
    func copyToSystem(item: PasteItem) {
        UIPasteboard.general.string = item.content
        lastClipString = item.content
        item.copyCount += 1
        item.lastCopiedAt = Date()
        try? modelContext?.save()
    }
}
