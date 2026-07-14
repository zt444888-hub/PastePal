import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<PasteItem> { $0.pinnedAt != nil || $0.isFavorite },
           sort: [SortDescriptor(\PasteItem.createdAt, order: .reverse)])
    private var favoriteItems: [PasteItem]
    
    var body: some View {
        NavigationStack {
            Group {
                if favoriteItems.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "star.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No Favorites Yet")
                            .font(.headline)
                        Text("Go to History, tap the ❤️ on any item, and it appears here. You can also swipe left on an item and tap Favorite.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(favoriteItems) { item in
                            PasteItemRowView(item: item, clipboardManager: ClipboardManager.shared)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        if item.pinnedAt != nil { item.pinnedAt = nil }
                                        item.isFavorite = false
                                        try? modelContext.save()
                                    } label: {
                                        Label("Unfavorite", systemImage: "star.slash")
                                    }
                                    .tint(.orange)
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Favorites")
        }
    }
}
