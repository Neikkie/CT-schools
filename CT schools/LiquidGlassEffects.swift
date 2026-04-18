import SwiftUI

// MARK: - Liquid Glass Material Effects

/// Liquid glass material modifier with depth and luminosity
struct LiquidGlassMaterial: ViewModifier {
    var intensity: Double = 1.0
    var tint: Color = .white
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base glass layer
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.9)

                    // Luminous overlay
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(0.3 * intensity),
                                    tint.opacity(0.1 * intensity),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Border shimmer - adaptive for dark mode
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: colorScheme == .dark ? [
                                    Color.white.opacity(0.3 * intensity),
                                    Color.white.opacity(0.1 * intensity),
                                    .clear
                                ] : [
                                    Color.white.opacity(0.5 * intensity),
                                    Color.white.opacity(0.2 * intensity),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
            .shadow(color: tint.opacity(0.2 * intensity), radius: 20, x: 0, y: 10)
            .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? [
                Color(red: 0.05, green: 0.05, blue: 0.1),
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color.black
            ] : [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color(red: 0.92, green: 0.95, blue: 0.98),
                Color.white
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    var duration: Double = 1.5
    var bounce: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.3),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(45))
                        .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                }
            }
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: bounce)
                ) {
                    phase = 1
                }
            }
    }
}

// MARK: - Breathing Animation

struct BreathingScale: ViewModifier {
    @State private var isBreathing = false
    var minScale: CGFloat = 0.98
    var maxScale: CGFloat = 1.02

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? maxScale : minScale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    isBreathing.toggle()
                }
            }
    }
}

// MARK: - Floating Animation

struct FloatingAnimation: ViewModifier {
    @State private var isFloating = false
    var distance: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -distance : distance)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    isFloating.toggle()
                }
            }
    }
}

// MARK: - Parallax Scroll Effect

struct ParallaxHeader<Content: View>: View {
    let content: Content
    let coordinateSpace: String = "scroll"

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .named(coordinateSpace)).minY
            let height = geometry.size.height

            content
                .frame(width: geometry.size.width, height: height + max(0, offset))
                .offset(y: -max(0, offset))
        }
    }
}

// MARK: - Morphing Card

struct MorphingCard: ViewModifier {
    @State private var isMorphing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isMorphing ? 1.05 : 1.0)
            .rotation3DEffect(
                .degrees(isMorphing ? 2 : 0),
                axis: (x: 1, y: 1, z: 0),
                perspective: 0.5
            )
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isMorphing)
            .onTapGesture {
                isMorphing.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isMorphing.toggle()
                }
            }
    }
}

// MARK: - Glow Effect

struct GlowEffect: ViewModifier {
    var color: Color
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: radius / 2, x: 0, y: 0)
            .shadow(color: color.opacity(0.2), radius: radius / 4, x: 0, y: 0)
    }
}

// MARK: - Bounce Animation

struct BounceAnimation: ViewModifier {
    @State private var bouncing = false
    var trigger: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(bouncing ? 1.2 : 1.0)
            .onChange(of: trigger) { _, _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bouncing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        bouncing = false
                    }
                }
            }
    }
}

// MARK: - Particle Effect

struct ParticleEffect: View {
    @State private var particles: [Particle] = []
    let particleCount = 20

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            generateParticles()
            animateParticles()
        }
    }

    private func generateParticles() {
        particles = (0..<particleCount).map { _ in
            Particle(
                x: CGFloat.random(in: -150...150),
                y: CGFloat.random(in: -150...150),
                size: CGFloat.random(in: 2...8),
                color: Color.blue.opacity(0.3),
                opacity: Double.random(in: 0.2...0.8)
            )
        }
    }

    private func animateParticles() {
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            particles = particles.map { particle in
                var newParticle = particle
                newParticle.x += CGFloat.random(in: -50...50)
                newParticle.y += CGFloat.random(in: -50...50)
                return newParticle
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}

// MARK: - View Extensions

extension View {
    func liquidGlass(intensity: Double = 1.0, tint: Color = .white) -> some View {
        modifier(LiquidGlassMaterial(intensity: intensity, tint: tint))
    }

    func shimmer(duration: Double = 1.5, bounce: Bool = false) -> some View {
        modifier(ShimmerEffect(duration: duration, bounce: bounce))
    }

    func breathing(minScale: CGFloat = 0.98, maxScale: CGFloat = 1.02) -> some View {
        modifier(BreathingScale(minScale: minScale, maxScale: maxScale))
    }

    func floating(distance: CGFloat = 10) -> some View {
        modifier(FloatingAnimation(distance: distance))
    }

    func morphingCard() -> some View {
        modifier(MorphingCard())
    }

    func glow(color: Color, radius: CGFloat) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }

    func bounceOnTap(trigger: Bool) -> some View {
        modifier(BounceAnimation(trigger: trigger))
    }
}

// MARK: - Animated Success Checkmark

struct AnimatedCheckmark: View {
    @State private var trimEnd: CGFloat = 0
    @State private var scale: CGFloat = 0
    var color: Color = .green

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
                .frame(width: 60, height: 60)

            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 60, height: 60)
                .scaleEffect(scale)

            Path { path in
                path.move(to: CGPoint(x: 20, y: 30))
                path.addLine(to: CGPoint(x: 28, y: 38))
                path.addLine(to: CGPoint(x: 42, y: 22))
            }
            .trim(from: 0, to: trimEnd)
            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .frame(width: 60, height: 60)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                trimEnd = 1.0
            }
        }
    }
}

// MARK: - Loading Dots Animation

struct LoadingDots: View {
    @State private var animating = false
    var color: Color = .blue

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}
