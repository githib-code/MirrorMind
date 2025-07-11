import SwiftUI

extension View {
    // MARK: - Original Features (Enhanced)
    func bounceOnAppear(delay: Double = 0.2) -> some View {
        modifier(BounceOnAppear(delay: delay))
    }
    
    func hapticOnTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        modifier(HapticOnTap(style: style))
    }
    
    func glow(color: Color = .blue, radius: CGFloat = 20) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
    
    // MARK: - New Premium Additions
    func smoothCornerRadius(_ radius: CGFloat, edges: UIRectCorner = .allCorners) -> some View {
        modifier(SmoothCornerModifier(radius: radius, edges: edges))
    }
    
    func pressAnimation(minScale: CGFloat = 0.96, intensity: UIImpactFeedbackGenerator.FeedbackStyle = .soft) -> some View {
        modifier(PressAnimationModifier(minScale: minScale, intensity: intensity))
    }
    
    func shimmer(config: ShimmerConfig = .premium) -> some View {
        modifier(ShimmerModifier(config: config))
    }
    
    func fadeSlideTransition(_ edge: Edge = .bottom) -> some View {
        modifier(FadeSlideModifier(edge: edge))
    }
    
    func microInteraction(_ isActive: Bool) -> some View {
        modifier(MicroInteractionModifier(isActive: isActive))
    }
    
    func premiumShadow(_ intensity: ShadowIntensity = .medium) -> some View {
        modifier(PremiumShadowModifier(intensity: intensity))
    }
    
    func parallaxEffect(amount: CGFloat = 10) -> some View {
        modifier(ParallaxModifier(amount: amount))
    }
}

// MARK: - Enhanced Modifiers
private struct BounceOnAppear: ViewModifier {
    let delay: Double
    @State private var isScaled = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isScaled ? 1.05 : 1)
            .animation(
                .interpolatingSpring(mass: 0.5, stiffness: 200, damping: 10, initialVelocity: 0)
                .delay(delay),
                value: isScaled
            )
            .onAppear { isScaled = true }
            .onDisappear { isScaled = false }
    }
}

private struct HapticOnTap: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    private let feedback = UIImpactFeedbackGenerator(style: .light)
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded {
                    feedback.impactOccurred(intensity: 0.8)
                }
            )
    }
}

private struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.4), radius: radius / 3)
            .shadow(color: color.opacity(0.3), radius: radius / 2)
            .shadow(color: color.opacity(0.2), radius: radius)
    }
}

// MARK: - Premium Modifiers
private struct PressAnimationModifier: ViewModifier {
    @State private var isPressed = false
    let minScale: CGFloat
    let intensity: UIImpactFeedbackGenerator.FeedbackStyle
    private let feedback = UIImpactFeedbackGenerator(style: .rigid)
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? minScale : 1)
            .brightness(isPressed ? -0.03 : 0)
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.5), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            feedback.impactOccurred(intensity: 0.7)
                        }
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

private struct ShimmerModifier: ViewModifier {
    struct ShimmerConfig {
        var gradient: Gradient
        var startPoint: UnitPoint
        var endPoint: UnitPoint
        var duration: Double
        var fadeWidth: CGFloat
        
        static let premium = ShimmerConfig(
            gradient: Gradient(colors: [
                .clear,
                .white.opacity(0.3),
                .white.opacity(0.5),
                .white.opacity(0.3),
                .clear
            ]),
            startPoint: .leading,
            endPoint: .trailing,
            duration: 2.0,
            fadeWidth: 0.3
        )
    }
    
    @State private var phase: CGFloat = 0
    let config: ShimmerConfig
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: config.gradient,
                    startPoint: config.startPoint,
                    endPoint: config.endPoint
                )
                .mask(content)
                .modifier(ShimmerAnimation(phase: phase, fadeWidth: config.fadeWidth))
            )
            .onAppear {
                withAnimation(Animation.linear(duration: config.duration).repeatForever(autoreverses: false)) {
                    phase = 1 + config.fadeWidth
                }
            }
    }
}

private struct ShimmerAnimation: AnimatableModifier {
    var phase: CGFloat
    var fadeWidth: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: phase - fadeWidth),
                                .init(color: .white, location: phase),
                                .init(color: .clear, location: phase + fadeWidth)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
    }
}

private struct PremiumShadowModifier: ViewModifier {
    enum ShadowIntensity {
        case subtle, medium, strong
    }
    
    let intensity: ShadowIntensity
    
    func body(content: Content) -> some View {
        switch intensity {
        case .subtle:
            return content
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        case .medium:
            return content
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        case .strong:
            return content
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
}

private struct ParallaxModifier: ViewModifier {
    @State private var position: CGSize = .zero
    let amount: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(x: position.width, y: position.height)
            .onAppear {
                withAnimation(.easeInOut(duration: 10).repeatForever()) {
                    position = CGSize(width: amount, height: amount)
                }
            }
    }
}