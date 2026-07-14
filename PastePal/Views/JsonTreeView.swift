import SwiftUI

struct JsonTreeView: View {
    let jsonString: String
    @State private var parsedObject: Any?
    @State private var parseError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let error = parseError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Invalid JSON Format: \(error)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            } else if let object = parsedObject {
                ScrollView(.horizontal, showsIndicators: true) {
                    ScrollView(.vertical, showsIndicators: true) {
                        JsonNodeView(label: "root", value: object, isLast: true, depth: 0)
                            .padding(.vertical, 8)
                    }
                }
                .background(Color(red: 0.1, green: 0.1, blue: 0.12))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            } else {
                Text("Empty JSON Content")
                    .foregroundColor(.gray)
                    .font(.footnote)
            }
        }
        .onAppear {
            parseJson()
        }
    }

    private func parseJson() {
        guard let data = jsonString.data(using: .utf8) else {
            parseError = "Could not convert text to UTF-8 data."
            return
        }
        do {
            parsedObject = try JSONSerialization.jsonObject(with: data, options: [])
            parseError = nil
        } catch {
            parseError = error.localizedDescription
        }
    }
}

struct JsonNodeView: View {
    let label: String
    let value: Any
    let isLast: Bool
    let depth: Int

    @State private var isExpanded = true

    var body: some View {
        let indent = CGFloat(depth * 14)
        
        VStack(alignment: .leading, spacing: 4) {
            if let dict = value as? [String: Any] {
                // Dictionary Node
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isExpanded.toggle()
                            }
                        }
                    
                    Text(label)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.purple)
                    
                    Text(":")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Text("{")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    
                    if !isExpanded {
                        Text("\(dict.count) items")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(4)
                            .foregroundColor(.gray)
                        
                        Text("}")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        if !isLast {
                            Text(",")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        if let jsonString = dict.toJsonString() {
                            UIPasteboard.general.string = jsonString
                        }
                    } label: {
                        Text("Copy")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    }
                    .padding(.horizontal, 6)
                }
                .padding(.leading, indent + 4)
                
                if isExpanded {
                    let keys = dict.keys.sorted()
                    ForEach(Array(keys.enumerated()), id: \.element) { index, key in
                        JsonNodeView(
                            label: "\"\(key)\"",
                            value: dict[key] ?? NSNull(),
                            isLast: index == keys.count - 1,
                            depth: depth + 1
                        )
                    }
                    
                    Text("}")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.leading, indent + 18)
                }
                
            } else if let array = value as? [Any] {
                // Array Node
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isExpanded.toggle()
                            }
                        }
                    
                    Text(label)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.purple)
                    
                    Text(":")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Text("[")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    
                    if !isExpanded {
                        Text("\(array.count) items")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(4)
                            .foregroundColor(.gray)
                        
                        Text("]")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        
                        if !isLast {
                            Text(",")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        if let jsonString = array.toJsonString() {
                            UIPasteboard.general.string = jsonString
                        }
                    } label: {
                        Text("Copy")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    }
                    .padding(.horizontal, 6)
                }
                .padding(.leading, indent + 4)
                
                if isExpanded {
                    ForEach(Array(array.enumerated()), id: \.offset) { index, item in
                        JsonNodeView(
                            label: "",
                            value: item,
                            isLast: index == array.count - 1,
                            depth: depth + 1
                        )
                    }
                    
                    Text("]")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.leading, indent + 18)
                }
                
            } else {
                // Primitive Leaf Nodes
                HStack(spacing: 4) {
                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.purple)
                        Text(":")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    renderPrimitiveValue()
                    
                    if !isLast {
                        Text(",")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = String(describing: value)
                    } label: {
                        Text("Copy")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    }
                    .padding(.horizontal, 6)
                }
                .padding(.leading, indent + 18)
            }
        }
    }

    @ViewBuilder
    private func renderPrimitiveValue() -> some View {
        if value is NSNull {
            Text("null")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.zincColor)
        } else if let str = value as? String {
            Text("\"\(str)\"")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.emeraldColor)
        } else if let num = value as? NSNumber {
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                Text(num.boolValue ? "true" : "false")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.blueColor)
            } else {
                Text(num.stringValue)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.amberColor)
            }
        } else {
            Text(String(describing: value))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}


// Color extension moved to ColorExtensions.swift
