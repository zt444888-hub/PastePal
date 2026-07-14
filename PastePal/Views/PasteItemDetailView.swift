import SwiftUI
import CoreImage.CIFilterBuiltins
import SwiftData

struct PasteItemDetailView: View {
    @Bindable var item: PasteItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showQrCode = false
    @State private var isEditing = false
    @State private var editedContent = ""
    
    // CoreImage filters for QR code generator
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Main Header Info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.sourceAppName)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blueColor)
                        
                        Text("Clipped \(item.createdAt.formatted(.dateTime.hour().minute().second()))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button {
                            withAnimation {
                                if item.pinnedAt == nil {
                                    item.pinnedAt = Date()
                                } else {
                                    item.pinnedAt = nil
                                }
                            }
                            triggerFeedback()
                        } label: {
                            Image(systemName: item.pinnedAt != nil ? "pin.fill" : "pin")
                                .foregroundColor(item.pinnedAt != nil ? .orange : .gray)
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                        
                        Button {
                            withAnimation {
                                item.isFavorite.toggle()
                            }
                            triggerFeedback()
                        } label: {
                            Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(item.isFavorite ? .red : .gray)
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal)
                
                // Content Editor / Viewer
                VStack(alignment: .leading) {
                    if isEditing {
                        TextEditor(text: $editedContent)
                            .font(.system(.body, design: item.contentType == "code" ? .monospaced : .default))
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(item.content)
                                .font(.system(.body, design: item.contentType == "code" ? .monospaced : .default))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                )
                            
                            // JSON visualizer if valid JSON detected
                            if isValidJson(item.content) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Developer Suite: Nested JSON tree")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.gray)
                                        .textCase(.uppercase)
                                    
                                    JsonTreeView(jsonString: item.content)
                                }
                                .padding(.top, 10)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Active Editor Controls (Save/Cancel)
                if isEditing {
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            isEditing = false
                        }
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        
                        Button("Save Changes") {
                            item.content = editedContent
                            item.updatedAt = Date()
                            isEditing = false
                            try? modelContext.save()
                            triggerFeedback(success: true)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                        .background(Color.blueColor)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                } else {
                    // Quick Action Tools
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Formatting & Transformations")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .padding(.leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FormatButton(title: "camelCase", subtitle: "camelCaseStyle") {
                                    transformContent { $0.toCamelCase() }
                                }
                                FormatButton(title: "snake_case", subtitle: "snake_case_style") {
                                    transformContent { $0.toSnakeCase() }
                                }
                                FormatButton(title: "Title Case", subtitle: "Title Case Style") {
                                    transformContent { $0.toTitleCase() }
                                }
                                FormatButton(title: "Strip HTML", subtitle: "Plain Text Only") {
                                    transformContent { $0.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) }
                                }
                                FormatButton(title: "UPPERCASE", subtitle: "ALL CAPS STYLE") {
                                    transformContent { $0.uppercased() }
                                }
                                FormatButton(title: "lowercase", subtitle: "all min style") {
                                    transformContent { $0.lowercased() }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Action Tray
                HStack(spacing: 20) {
                    // Copy Again
                    Button {
                        UIPasteboard.general.string = item.content
                        item.copyCount += 1
                        item.lastCopiedAt = Date()
                        try? modelContext.save()
                        triggerFeedback(success: true)
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc.fill")
                            Text("Copy Content")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blueColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Share Sheet native hook
                    ShareLink(item: item.content) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    // Toggle QR Code Card
                    Button {
                        withAnimation {
                            showQrCode.toggle()
                        }
                        triggerFeedback()
                    } label: {
                        Image(systemName: "qrcode")
                            .font(.title3)
                            .padding()
                            .background(Color.white.opacity(showQrCode ? 0.2 : 0.08))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
                
                // QR Code Panel
                if showQrCode {
                    VStack(spacing: 12) {
                        Text("Dynamic QR Code")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let qrImage = generateQrCode(from: item.content) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .background(Color.white)
                                .cornerRadius(12)
                                .padding()
                        } else {
                            Text("Failed to generate QR Code")
                                .foregroundColor(.red)
                        }
                        
                        Text("Scan to quickly transfer this clip to another device.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Snippet Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if !isEditing {
                        editedContent = item.content
                    }
                    isEditing.toggle()
                    triggerFeedback()
                }
            }
        }
    }
    
    // Helpers
    private func transformContent(transformer: (String) -> String) {
        let transformed = transformer(item.content)
        item.content = transformed
        item.updatedAt = Date()
        UIPasteboard.general.string = transformed
        try? modelContext.save()
        triggerFeedback(success: true)
    }
    
    private func triggerFeedback(success: Bool = false) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(success ? .success : .warning)
    }
    
    private func generateQrCode(from string: String) -> UIImage? {
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
    
    private func isValidJson(_ text: String) -> Bool {
        guard let data = text.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) != nil
    }
}

// Custom format button
struct FormatButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                Text(subtitle)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.03), lineWidth: 1)
            )
        }
    }
}

// String Transformations helper extensions
extension String {
    func toCamelCase() -> String {
        let components = self.components(separatedBy: CharacterSet.alphanumerics.inverted)
        let first = components.first?.lowercased() ?? ""
        let rest = components.dropFirst().map { $0.capitalized }
        return ([first] + rest).joined()
    }
    
    func toSnakeCase() -> String {
        return self.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }
    
    func toTitleCase() -> String {
        return self.capitalized
    }
}
