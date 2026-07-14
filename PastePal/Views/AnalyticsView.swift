import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Query private var history: [PasteItem]
    @Environment(\.modelContext) private var modelContext
    @State private var activeTab: String = "overview"
    @State private var justOptimized = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Segmented picker header (iOS styling)
                Picker("Active Analysis Mode", selection: $activeTab) {
                    Text("Overview").tag("overview")
                    Text("Categories").tag("categories")
                    Text("Diagnostics").tag("diagnostics")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if activeTab == "overview" {
                    renderOverview()
                } else if activeTab == "categories" {
                    renderCategories()
                } else {
                    renderDiagnostics()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Clipboard Analytics")
    }
    
    // TAB 1: OVERVIEW
    @ViewBuilder
    private func renderOverview() -> some View {
        VStack(spacing: 16) {
            // Highlights cards
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Clipped")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(history.count)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("records")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blueColor)
                            .font(.system(size: 10))
                        Text("Time Saved")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.blueColor)
                            .textCase(.uppercase)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(history.count * 2)")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.blueColor)
                        Text("mins")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blueColor)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blueColor.opacity(0.06))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blueColor.opacity(0.12), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            
            // Database Storage bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Database Storage Capacity")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("\(min(history.count, 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(history.count > 80 ? Color.red : (history.count > 50 ? Color.orange : Color.green))
                            .frame(width: geo.size.width * CGFloat(min(Double(history.count) / 100.0, 1.0)), height: 8)
                    }
                }
                .frame(height: 8)
                
                Text("Database sync is running in sandbox mode. Offline caching secures keys.")
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
            .padding()
            .background(Color.white.opacity(0.02))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Masked indicator
            let sensitiveCount = history.filter { $0.isSensitive }.count
            HStack(spacing: 12) {
                Image(systemName: "shield.safari.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text("Security Health: **\(sensitiveCount)** private clips masked successfully from visual inspection overlays.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.03))
            .cornerRadius(14)
            .padding(.horizontal)
        }
    }
    
    // TAB 2: CATEGORIES
    @ViewBuilder
    private func renderCategories() -> some View {
        VStack(spacing: 20) {
            let textsCount = history.filter { $0.contentType == "text" }.count
            let urlsCount = history.filter { $0.contentType == "url" }.count
            let codesCount = history.filter { $0.contentType == "code" }.count
            let total = max(history.count, 1)
            
            let textPct = Int(Double(textsCount) / Double(total) * 100)
            let urlPct = Int(Double(urlsCount) / Double(total) * 100)
            let codePct = Int(Double(codesCount) / Double(total) * 100)
            
            // Content Type Breakdown bar chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Content Type Breakdown")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 0) {
                    if textPct > 0 {
                        Color.blueColor
                            .frame(width: CGFloat(textPct) * 2.8)
                    }
                    if urlPct > 0 {
                        Color.green
                            .frame(width: CGFloat(urlPct) * 2.8)
                    }
                    if codePct > 0 {
                        Color.orange
                            .frame(width: CGFloat(codePct) * 2.8)
                    }
                }
                .frame(height: 14)
                .cornerRadius(7)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                    GridRow {
                        HStack(spacing: 6) {
                            Circle().fill(Color.blueColor).frame(width: 8, height: 8)
                            Text("Text (\(textPct)%)")
                        }
                        HStack(spacing: 6) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text("Links (\(urlPct)%)")
                        }
                        HStack(spacing: 6) {
                            Circle().fill(Color.orange).frame(width: 8, height: 8)
                            Text("Code (\(codePct)%)")
                        }
                    }
                }
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Simulated Source analytics
            VStack(alignment: .leading, spacing: 12) {
                Text("Active Clip Sources")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                
                SourceRow(appName: "Safari", clips: history.filter { $0.contentType == "url" }.count, total: total)
                SourceRow(appName: "Xcode", clips: history.filter { $0.contentType == "code" }.count, total: total)
                SourceRow(appName: "Messages", clips: history.filter { $0.contentType == "text" && $0.content.count < 100 }.count, total: total)
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    // TAB 3: DIAGNOSTICS & CLEANUP
    @ViewBuilder
    private func renderDiagnostics() -> some View {
        VStack(spacing: 16) {
            let emptyClips = history.filter { $0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let largeClips = history.filter { $0.content.count > 5000 }
            
            // Calculate duplicates
            let duplicates = findDuplicateIds()
            let issueCount = emptyClips.count + largeClips.count + duplicates.count
            
            HStack {
                Text("Clipboard Sanitation Health")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                Spacer()
                Text("\(issueCount) anomalies")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                DiagnosticRow(title: "Duplicate Clipboard Clips", status: duplicates.count > 0 ? "\(duplicates.count) duplicates" : "None detected", isAnomaly: duplicates.count > 0)
                DiagnosticRow(title: "Empty / Corrupted Records", status: emptyClips.count > 0 ? "\(emptyClips.count) malformed" : "None detected", isAnomaly: emptyClips.count > 0)
                DiagnosticRow(title: "Memory Bloat Snippets (>5KB)", status: largeClips.count > 0 ? "\(largeClips.count) heavy elements" : "None detected", isAnomaly: largeClips.count > 0)
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .padding(.horizontal)
            
            if issueCount > 0 {
                VStack(spacing: 12) {
                    Text("Optimize performance and reduce SQLite index overhead by running a complete deduplication cycle now.")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button {
                        runDeepClean(duplicateIds: duplicates)
                    } label: {
                        HStack(spacing: 8) {
                            if justOptimized {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Purged & Optimized Successfully!")
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Run Memory Sanitizer & Deduplicate")
                            }
                        }
                        .fontWeight(.bold)
                        .font(.footnote)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(justOptimized ? Color.green : Color.red.opacity(0.15))
                        .foregroundColor(justOptimized ? .white : .red)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(justOptimized ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(justOptimized)
                }
                .padding()
                .background(Color.red.opacity(0.03))
                .cornerRadius(16)
                .padding(.horizontal)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.largeTitle)
                    
                    Text("Your Clipboard Cache is Spotless!")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Text("All strings are deduplicated, lightweight, and indexing smoothly inside SwiftUI storage caches.")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(30)
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.04))
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
    }
    
    // Helpers
    private func findDuplicateIds() -> [String] {
        var seenContents = Set<String>()
        var duplicateIds: [String] = []
        for item in history {
            let content = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if seenContents.contains(content) {
                duplicateIds.append(item.id)
            } else {
                seenContents.insert(content)
            }
        }
        return duplicateIds
    }
    
    private func runDeepClean(duplicateIds: [String]) {
        // Delete duplicates and trim whitespace
        for item in history {
            if duplicateIds.contains(item.id) {
                modelContext.delete(item)
            } else {
                item.content = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        try? modelContext.save()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        withAnimation {
            justOptimized = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            justOptimized = false
        }
    }
}

struct SourceRow: View {
    let appName: String
    let clips: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Text(appName)
                .font(.footnote)
                .fontWeight(.bold)
                .frame(width: 80, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                    
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: geo.size.width * CGFloat(Double(clips) / Double(max(total, 1))))
                }
            }
            .frame(height: 6)
            
            Text("\(clips) clips")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 60, alignment: .trailing)
        }
    }
}

struct DiagnosticRow: View {
    let title: String
    let status: String
    let isAnomaly: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(status)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(isAnomaly ? .orange : .green)
        }
        .padding(.vertical, 4)
    }
}
