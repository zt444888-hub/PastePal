import SwiftUI

struct PasteItemRowView: View {
    @Bindable var item: PasteItem
    @ObservedObject var clipboardManager: ClipboardManager
    @State private var showSensitiveReveal = false
    
    var body: some View {
        NavigationLink {
            PasteItemDetailView(item: item)
        } label: {
            HStack(spacing: 12) {
                // Left Content Type Icon Indicator
                VStack {
                    Image(systemName: getIconName())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(getIconColor())
                        .frame(width: 32, height: 32)
                        .background(getIconColor().opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Text details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.sourceAppName)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                            .textCase(.uppercase)
                        
                        if item.pinnedAt != nil {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.orange)
                        }
                        
                        Button {
                            item.isFavorite.toggle()
                        } label: {
                            Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 9))
                                .foregroundColor(item.isFavorite ? .red : .gray.opacity(0.3))
                        }
                    }
                    
                    // Main body content (with sensitive masking option)
                    if item.isSensitive && !showSensitiveReveal {
                        HStack(spacing: 6) {
                            Text("••••••••••••••••")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Button {
                                withAnimation {
                                    showSensitiveReveal = true
                                }
                            } label: {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.blueColor)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Text(item.content.replacingOccurrences(of: "\n", with: " "))
                            .font(.system(.subheadline, design: item.contentType == "code" ? .monospaced : .default))
                            .foregroundColor(.white.opacity(0.95))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                
                Spacer()
                
                // Copy quick counter or timestamp
                Text(item.createdAt.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
    }
    
    private func getIconName() -> String {
        switch item.contentType {
        case "url": return "link"
        case "code": return "chevron.left.forwardslash.chevron.right"
        default: return "doc.text.fill"
        }
    }
    
    private func getIconColor() -> Color {
        switch item.contentType {
        case "url": return .green
        case "code": return .orange
        default: return .blueColor
        }
    }
}
