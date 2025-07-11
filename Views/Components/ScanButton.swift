import SwiftUI

struct ScanButton: View {
    var action: () -> Void
    @State private var isPulsing = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulsing background glow
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 90, height: 90)
                    .scaleEffect(isPulsing ? 1.2 : 1)
                    .opacity(isPulsing ? 0 : 0.7)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                        value: isPulsing
                    )
                
                // Main button
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.8), .clear]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 2)
                            .padding(2)
                    )
                    .overlay(
                        Image(systemName: "camera")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    )
                    .scaleEffect(isPressed ? 0.92 : 1)
                    .premiumShadow(.medium)
            }
        }
        .buttonStyle(NoHighlightButtonStyle())
        .onAppear {
            isPulsing = true
        }
    }
}

private struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.5), value: configuration.isPressed)
    }
}