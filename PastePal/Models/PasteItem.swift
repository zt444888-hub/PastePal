import Foundation
import SwiftData

@Model
final class PasteItem {
    @Attribute(.unique) var id: String
    var content: String
    var contentType: String // "text", "url", "code"
    var createdAt: Date
    var updatedAt: Date
    var pinnedAt: Date?
    var lastCopiedAt: Date?
    var copyCount: Int
    var sourceAppName: String
    var sourceAppBundleId: String
    var isSensitive: Bool
    var isTrashed: Bool
    var isFavorite: Bool
    var tags: [String]
    
    init(
        id: String = UUID().uuidString,
        content: String,
        contentType: String = "text",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        pinnedAt: Date? = nil,
        lastCopiedAt: Date? = nil,
        copyCount: Int = 0,
        sourceAppName: String = "System",
        sourceAppBundleId: String = "com.apple.system",
        isSensitive: Bool = false,
        isTrashed: Bool = false,
        isFavorite: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.content = content
        self.contentType = contentType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.pinnedAt = pinnedAt
        self.lastCopiedAt = lastCopiedAt
        self.copyCount = copyCount
        self.sourceAppName = sourceAppName
        self.sourceAppBundleId = sourceAppBundleId
        self.isSensitive = isSensitive
        self.isTrashed = isTrashed
        self.isFavorite = isFavorite
        self.tags = tags
    }
}
