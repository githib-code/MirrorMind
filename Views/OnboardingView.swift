import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            title: "Discover Your Unique Beauty",
            subtitle: "See your face through the lens of golden ratios",
            image: "sparkles",
            color: .purple
        ),
        OnboardingPage(
            title: "Personalized Improvements",
            subtitle: "Get natural and cosmetic enhancement suggestions",
            image: "heart.text.square",
            color: .pink
        ),
        OnboardingPage(
            title: "Track Your Progress",
            subtitle: "See how small changes make big differences",
            image: "chart.line.uptrend.xyaxis",
            color: .blue
        )
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            Button(action: {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    isOnboardingComplete = true
                }
            }) {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pages[currentPage].color)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(.horizontal, 50)
            }
            .buttonStyle(.plain)
            
            if currentPage < pages.count - 1 {
                Button("Skip") {
                    isOnboardingComplete = true
                }
                .foregroundColor(.gray)
                .padding()
            }
        }
        .background(Color.darkBackground.ignoresSafeArea())
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: page.image)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(page.color)
                .padding()
                .background(page.color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(spacing: 15) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .padding()
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let image: String
    let color: Color
}