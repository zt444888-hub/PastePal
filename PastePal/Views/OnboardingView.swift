import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages: [(icon: String, title: String, subtitle: String, color: Color)] = [
        (
            icon: "clock.arrow.circlepath",
            title: "Clipboard History, Auto-Saved",
            subtitle: "PastePal automatically saves everything you copy. Never lose an important snippet again — it's all right here.",
            color: .blueColor
        ),
        (
            icon: "lock.shield.fill",
            title: "Your Data Stays on Your Device",
            subtitle: "All clipboard data is stored locally on your device and synced only through your private iCloud. We never upload your data. Period.",
            color: .emeraldColor
        ),
        (
            icon: "doc.on.doc.fill",
            title: "Tap Any Item to Copy Back",
            subtitle: "Search through your history, pin favorites, or copy with one tap. Open the Settings tab to customize privacy and more.",
            color: .orange
        ),
    ]
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 24) {
                            Image(systemName: pages[index].icon)
                                .font(.system(size: 72))
                                .foregroundColor(pages[index].color)
                                .padding(.bottom, 8)
                            
                            Text(pages[index].title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(pages[index].subtitle)
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .tag(index)
                        .padding(.bottom, 60)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                
                Spacer()
                
                Button {
                    withAnimation {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            showOnboarding = false
                        }
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(pages[currentPage].color)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 12)
                
                if currentPage < pages.count - 1 {
                    Button {
                        withAnimation {
                            showOnboarding = false
                        }
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 32)
                } else {
                    Text("")
                        .padding(.bottom, 32)
                }
            }
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
