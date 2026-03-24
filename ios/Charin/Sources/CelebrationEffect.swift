import SwiftUI

// MARK: - Confetti Effect

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    let colors: [Color]

    init(colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]) {
        self.colors = colors
    }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .position(p.position)
                    .opacity(p.opacity)
                    .rotationEffect(.degrees(p.rotation))
            }
        }
        .onAppear { startConfetti() }
        .allowsHitTesting(false)
    }

    private func startConfetti() {
        for i in 0..<40 {
            let p = ConfettiParticle(
                id: i,
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: CGFloat.random(in: 0...400), y: -20),
                opacity: 1,
                rotation: Double.random(in: 0...360)
            )
            particles.append(p)
        }

        withAnimation(.easeIn(duration: 2.0)) {
            for i in particles.indices {
                particles[i].position.y += CGFloat.random(in: 600...900)
                particles[i].position.x += CGFloat.random(in: -100...100)
                particles[i].opacity = 0
                particles[i].rotation += Double.random(in: 180...720)
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
    var rotation: Double
}

// MARK: - Success Checkmark Animation

struct SuccessCheckmark: View {
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 80, height: 80)

            Circle()
                .fill(color)
                .frame(width: 64, height: 64)

            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                scale = 1
                opacity = 1
            }
        }
    }
}

// MARK: - Coin Rain (for Charin)

struct CoinRainView: View {
    @State private var coins: [CoinParticle] = []

    var body: some View {
        ZStack {
            ForEach(coins) { coin in
                Text("\u{00A5}")
                    .font(.system(size: coin.size, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow.opacity(coin.opacity))
                    .position(coin.position)
                    .rotationEffect(.degrees(coin.rotation))
            }
        }
        .onAppear { startRain() }
        .allowsHitTesting(false)
    }

    private func startRain() {
        for i in 0..<20 {
            let coin = CoinParticle(
                id: i,
                size: CGFloat.random(in: 14...28),
                position: CGPoint(x: CGFloat.random(in: 30...350), y: CGFloat.random(in: -50...(-10))),
                opacity: 0.8,
                rotation: Double.random(in: -30...30)
            )
            coins.append(coin)
        }
        withAnimation(.easeIn(duration: 1.5)) {
            for i in coins.indices {
                coins[i].position.y += CGFloat.random(in: 500...800)
                coins[i].opacity = 0
                coins[i].rotation += Double.random(in: -180...180)
            }
        }
    }
}

struct CoinParticle: Identifiable {
    let id: Int
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
    var rotation: Double
}
