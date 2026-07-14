import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PasteItem.createdAt, order: .reverse) private var items: [PasteItem]
    
    private let clipboardManager = ClipboardManager.shared
    
    @State private var searchText = ""
    @State private var activeFilter = "all"
    @State private var selectedItemIds = Set<String>()
    @State private var isEditMode = false
    
    @AppStorage("secureShredMode") private var secureShredMode = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Categories Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterBadge(title: "All", tag: "all", active: activeFilter == "all") { activeFilter = "all" }
                        FilterBadge(title: "Text", tag: "text", active: activeFilter == "text") { activeFilter = "text" }
                        FilterBadge(title: "Links", tag: "url", active: activeFilter == "url") { activeFilter = "url" }
                        FilterBadge(title: "Code", tag: "code", active: activeFilter == "code") { activeFilter = "code" }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                
                // Active Items List
                let filteredItems = filterItems()
                if filteredItems.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(searchText.isEmpty ? "No Copy Clipboard History" : "No Matches Found")
                            .font(.headline)
                        Text(searchText.isEmpty ? "When you copy code or text on your iPhone, PastePal will log them here automatically." : "Refine your query and try searching again.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    List(selection: $selectedItemIds) {
                        // Section 1: Pinned Items
                        let pinned = filteredItems.filter { $0.pinnedAt != nil }
                        if !pinned.isEmpty {
                            Section(header: Text("Pinned Clips 📌")) {
                                ForEach(pinned) { item in
                                    PasteItemRowView(item: item, clipboardManager: clipboardManager)
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                item.isFavorite.toggle()
                                            } label: {
                                                Label("Favorite", systemImage: "heart")
                                            }
                                            .tint(.pink)
                                            Button {
                                                togglePin(item)
                                            } label: {
                                                Label("Unpin", systemImage: "pin.slash.fill")
                                            }
                                            .tint(.orange)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                deleteItem(item)
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                            .tint(.red)
                                        }
                                }
                            }
                        }
                        
                        // Section 2: Favorite Items (not pinned)
                        let favs = filteredItems.filter { $0.isFavorite && $0.pinnedAt == nil }
                        if !favs.isEmpty {
                            Section(header: Text("Favorites ❤️")) {
                                ForEach(favs) { item in
                                    PasteItemRowView(item: item, clipboardManager: clipboardManager)
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                item.isFavorite.toggle()
                                            } label: {
                                                Label("Unfavorite", systemImage: "heart.slash")
                                            }
                                            .tint(.pink)
                                            Button {
                                                togglePin(item)
                                            } label: {
                                                Label("Pin", systemImage: "pin.fill")
                                            }
                                            .tint(.orange)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                deleteItem(item)
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                            .tint(.red)
                                        }
                                }
                            }
                        }
                        
                        // Section 3: Recent Items
                        let recents = filteredItems.filter { !$0.isFavorite && $0.pinnedAt == nil }
                        if !recents.isEmpty {
                            Section(header: Text("Recent History")) {
                                ForEach(recents) { item in
                                    PasteItemRowView(item: item, clipboardManager: clipboardManager)
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                item.isFavorite.toggle()
                                            } label: {
                                                Label("Favorite", systemImage: "heart")
                                            }
                                            .tint(.pink)
                                            Button {
                                                togglePin(item)
                                            } label: {
                                                Label("Pin", systemImage: "pin.fill")
                                            }
                                            .tint(.orange)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                deleteItem(item)
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                            .tint(.red)
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .environment(\.editMode, .constant(isEditMode ? .active : .inactive))
                }
                
                // Multiple Selection Edit Tray
                if isEditMode && !selectedItemIds.isEmpty {
                    HStack {
                        Button {
                            batchDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                                .font(.footnote)
                                .fontWeight(.bold)
                        }
                        .tint(.red)
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()
                        
                        Button {
                            batchMergeAndCopy()
                        } label: {
                            Label("Merge & Copy", systemImage: "doc.on.doc")
                                .font(.footnote)
                                .fontWeight(.bold)
                        }
                        .tint(.blueColor)
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(Color.white.opacity(0.04))
                    .transition(.move(edge: .bottom))
                }
            }
            .searchable(text: $searchText, prompt: "Search clipboard tags, apps or text")
            .navigationTitle("PastePal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditMode ? "Done" : "Select") {
                        withAnimation {
                            isEditMode.toggle()
                            selectedItemIds.removeAll()
                        }
                        triggerHaptic()
                    }
                }
                
            }
        }
        .onAppear {
            clipboardManager.setContext(modelContext)
        }
    }
    
    // Core Methods
    private func filterItems() -> [PasteItem] {
        return items.filter { item in
            let matchesSearch = searchText.isEmpty || 
                item.content.localizedCaseInsensitiveContains(searchText) ||
                item.sourceAppName.localizedCaseInsensitiveContains(searchText) ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            
            let matchesFilter = activeFilter == "all" || item.contentType == activeFilter
            
            return matchesSearch && matchesFilter
        }
    }
    
    private func togglePin(_ item: PasteItem) {
        if item.pinnedAt == nil {
            item.pinnedAt = Date()
        } else {
            item.pinnedAt = nil
        }
        try? modelContext.save()
        triggerHaptic()
    }
    
    private func deleteItem(_ item: PasteItem) {
        if secureShredMode {
            item.content = "[PRIVACY_SHREDDED_\(UUID().uuidString.prefix(6))]"
            item.sourceAppName = "[SHREDDED]"
            try? modelContext.save()
        }
        modelContext.delete(item)
        try? modelContext.save()
        triggerHaptic()
    }
    
    private func batchDelete() {
        let itemsToDelete = items.filter { selectedItemIds.contains($0.id) }
        for item in itemsToDelete {
            deleteItem(item)
        }
        isEditMode = false
        selectedItemIds.removeAll()
        triggerHaptic()
    }
    
    private func batchMergeAndCopy() {
        // Sort items chronologically (oldest first) matching user specification
        let sortedSelection = items
            .filter { selectedItemIds.contains($0.id) }
            .reversed()
        
        let mergedText = sortedSelection.map { $0.content }.joined(separator: "\n\n")
        UIPasteboard.general.string = mergedText
        
        // Feed merged clip back into persistent local storage!
        let isSensitiveMerged = sortedSelection.contains { $0.isSensitive }
        let mergedItem = PasteItem(
            content: mergedText,
            contentType: "text",
            sourceAppName: "PastePal Merge",
            sourceAppBundleId: "com.apple.shortcuts",
            isSensitive: isSensitiveMerged,
            tags: ["Merged"]
        )
        modelContext.insert(mergedItem)
        try? modelContext.save()
        
        isEditMode = false
        selectedItemIds.removeAll()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// SwiftUI custom categories filter badge component
struct FilterBadge: View {
    let title: String
    let tag: String
    let active: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(active ? .white : .gray)
                .padding(.vertical, 6)
                .padding(.horizontal, 14)
                .background(active ? Color.blueColor : Color.white.opacity(0.04))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(active ? Color.clear : Color.white.opacity(0.04), lineWidth: 1)
                )
        }
    }
}
