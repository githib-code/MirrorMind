import SwiftUI

struct CelebrationView: View {
    @State private var particles: [Particle] = []
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
                    .blur(radius: particle.isBlurred ? 2 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: particle.position)
            }
        }
        .drawingGroup()
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        particles = (0..<75).map { _ in
            let angle = Double.random(in: 0..<Double.pi * 2)
            let distance = Double.random(in: 50..<250)
            let size = Double.random(in: 4..<10)
            let delay = Double.random(in: 0..<0.5)
            
            return Particle(
                position: CGPoint(
                    x: UIScreen.main.bounds.midX,
                    y: UIScreen.main.bounds.midY
                ),
                targetPosition: CGPoint(
                    x: UIScreen.main.bounds.midX + CGFloat(cos(angle) * distance),
                    y: UIScreen.main.bounds.midY + CGFloat(sin(angle) * distance)
                ),
                color: colors.randomElement()!,
                size: size,
                opacity: 1,
                scale: 0.1,
                isBlurred: false,
                delay: delay
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                for index in particles.indices {
                    particles[index].position = particles[index].targetPosition
                    particles[index].scale = 1.0
                    particles[index].isBlurred = true
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.5)) {
                for index in particles.indices {
                    particles[index].opacity = 0
                }
            }
        }
    }
}

class Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let targetPosition: CGPoint
    let color: Color
    let size: Double
    var opacity: Double
    var scale: CGFloat
    var isBlurred: Bool
    let delay: Double
    
    init(position: CGPoint, targetPosition: CGPoint, color: Color, size: Double, opacity: Double, scale: CGFloat, isBlurred: Bool, delay: Double) {
        self.position = position
        self.targetPosition = targetPosition
        self.color = color
        self.size = size
        self.opacity = opacity
        self.scale = scale
        self.isBlurred = isBlurred
        self.delay = delay
    }
}