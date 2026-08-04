import SwiftUI

struct LoadingAnimationView: View {
    @State private var logoScale: CGFloat = 0.2
    @State private var logoOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringPulse: CGFloat = 0.85
    @State private var progress: CGFloat = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var orbitAngle: Double = 0
    @State private var tipIndex = 0
    @State private var glowIntensity: Double = 0.3

    let tips = [
        "Sharpening pencils",
        "Warming up the math engine",
        "Syncing the leaderboard",
        "Feeding the pets",
        "Solving for x"
    ]

    let orbitSymbols = ["+", "−", "×", "÷", "π", "√"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AxiomPalette.navyDeep,
                    Color(hex: 0x1E3A8A),
                    AxiomPalette.primaryDeep
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(AxiomPalette.primaryLight.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)

            Circle()
                .fill(AxiomPalette.accent.opacity(0.12))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 120, y: 250)

            ForEach(0..<6, id: \.self) { i in
                let angle = (orbitAngle + Double(i) * 60) * .pi / 180
                Text(orbitSymbols[i])
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.25))
                    .offset(x: cos(angle) * 130, y: sin(angle) * 130)
            }

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                AxiomPalette.glow.opacity(0.25 - Double(i) * 0.06),
                                lineWidth: 1.5
                            )
                            .frame(
                                width: 130 + CGFloat(i * 45),
                                height: 130 + CGFloat(i * 45)
                            )
                            .scaleEffect(ringPulse)
                            .rotationEffect(.degrees(ringRotation + Double(i * 30)))
                    }

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AxiomPalette.primaryLight.opacity(glowIntensity),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 90
                            )
                        )
                        .frame(width: 180, height: 180)
                        .blur(radius: 15)

                    Image("axiom_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.6), AxiomPalette.glow.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: AxiomPalette.primaryLight.opacity(0.5), radius: 25, y: 8)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                .frame(height: 220)

                VStack(spacing: 6) {
                    Text("Axiom")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, AxiomPalette.glow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Math, mastered.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(logoOpacity)

                VStack(spacing: 14) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 6)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AxiomPalette.primaryLight, AxiomPalette.glow, .white],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(6, geo.size.width * progress), height: 6)
                                .shadow(color: AxiomPalette.glow.opacity(0.8), radius: 6)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.5), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60, height: 6)
                                .offset(x: shimmerOffset)
                                .mask(
                                    Capsule()
                                        .frame(width: max(6, geo.size.width * progress), height: 6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                )
                        }
                    }
                    .frame(height: 6)
                    .frame(width: 240)

                    Text(tips[tipIndex])
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                        .id(tipIndex)
                }
                .opacity(logoOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                ringPulse = 1.05
                glowIntensity = 0.55
            }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                orbitAngle = 360
            }
            withAnimation(.easeInOut(duration: 3.2)) {
                progress = 1.0
            }
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 300
            }

            Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.35)) {
                    tipIndex = (tipIndex + 1) % tips.count
                }
                if progress >= 1.0 { timer.invalidate() }
            }
        }
    }
}
