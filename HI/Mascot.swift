//
//  Mascot.swift
//  Axiom
//
import SwiftUI

enum BuddyMood {
    case idle
    case happy
    case oops
    case thinking
}

struct CartoonBuddyView: View {
    var mood: BuddyMood = .idle
    var shirtColor: Color = AxiomPalette.primary

    @State private var blink = false
    @State private var bounce = false
    @State private var wave = false
    @State private var breathe = false

    private let skin = Color(hex: 0xFFCC9A)
    private let skinShadow = Color(hex: 0xE8A86A)
    private let skinHighlight = Color(hex: 0xFFE4C4)
    private let hair = Color(hex: 0x2C1810)
    private let hairHighlight = Color(hex: 0x4A3020)

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.22))
                .frame(width: 100, height: 20)
                .blur(radius: 6)
                .offset(y: 128)
                .scaleEffect(breathe ? 1.05 : 0.95)

            legs
            arms
            torso
            neck
            head
            sparkles
        }
        .frame(width: 200, height: 260)
        .scaleEffect(bounce ? 1.02 : 1.0)
        .offset(y: bounce ? -2 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { bounce = true }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { breathe = true }
            if mood == .happy {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { wave = true }
            }
            startBlinking()
        }
        .onChange(of: mood) { _, newMood in
            if newMood == .happy {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { wave = true }
            } else {
                wave = false
            }
        }
    }

    private var legs: some View {
        HStack(spacing: 16) {
            legSide
            legSide
        }
        .offset(y: 92)
    }

    private var legSide: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(LinearGradient(colors: [Color(hex: 0x3D4F6F), Color(hex: 0x2E3A59)], startPoint: .top, endPoint: .bottom))
                .frame(width: 22, height: 44)
            Ellipse()
                .fill(Color(hex: 0x1A2235))
                .frame(width: 32, height: 14)
                .overlay(Ellipse().stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
    }

    private var arms: some View {
        ZStack {
            arm(side: -1)
            arm(side: 1)
        }
    }

    private func arm(side: CGFloat) -> some View {
        let isLeft = side < 0
        let happyWave = mood == .happy && isLeft
        return ZStack {
            Capsule()
                .fill(LinearGradient(colors: [skinHighlight, skin, skinShadow], startPoint: .top, endPoint: .bottom))
                .frame(width: 18, height: 54)
            Capsule()
                .fill(skinShadow.opacity(0.3))
                .frame(width: 14, height: 16)
                .offset(y: 20)
        }
        .offset(x: side * 50, y: happyWave ? -8 : 28)
        .rotationEffect(.degrees(happyWave ? (wave ? -55 : -25) : (isLeft ? -8 : 8)), anchor: .top)
        .rotationEffect(.degrees(mood == .oops && !isLeft ? 35 : 0), anchor: .top)
    }

    private var torso: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(LinearGradient(colors: [shirtColor, shirtColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 96, height: 88)
                .shadow(color: shirtColor.opacity(0.45), radius: 12, y: 8)

            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 2
                )
                .frame(width: 96, height: 88)

            // Collar
            Ellipse()
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 14)
                .offset(y: -32)

            // Pocket
            RoundedRectangle(cornerRadius: 6)
                .fill(shirtColor.opacity(0.5))
                .frame(width: 24, height: 20)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .offset(x: -22, y: 8)
        }
        .offset(y: 36)
    }

    private var neck: some View {
        Capsule()
            .fill(LinearGradient(colors: [skinShadow, skin], startPoint: .top, endPoint: .bottom))
            .frame(width: 28, height: 18)
            .offset(y: -8)
    }

    private var head: some View {
        ZStack {
            // Ears
            ear(offsetX: -42)
            ear(offsetX: 42)

            // Head base
            Circle()
                .fill(LinearGradient(colors: [skinHighlight, skin, skinShadow], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 100, height: 100)
                .shadow(color: skinShadow.opacity(0.4), radius: 10, y: 5)

            // Cheek blush
            HStack(spacing: 62) {
                Circle().fill(Color.pink.opacity(0.28)).frame(width: 18, height: 14).blur(radius: 3)
                Circle().fill(Color.pink.opacity(0.28)).frame(width: 18, height: 14).blur(radius: 3)
            }
            .offset(y: 12)

            eyes.offset(y: -2)
            nose.offset(y: 10)
            eyebrows.offset(y: -22)
            mouth.offset(y: 28)
            hairShape
        }
        .offset(y: -48)
    }

    private func ear(offsetX: CGFloat) -> some View {
        Ellipse()
            .fill(LinearGradient(colors: [skin, skinShadow], startPoint: .top, endPoint: .bottom))
            .frame(width: 16, height: 22)
            .overlay(
                Ellipse()
                    .fill(Color.pink.opacity(0.25))
                    .frame(width: 8, height: 12)
            )
            .offset(x: offsetX, y: 4)
    }

    private var hairShape: some View {
        ZStack {
            // Main hair mass
            Ellipse()
                .fill(LinearGradient(colors: [hairHighlight, hair], startPoint: .top, endPoint: .bottom))
                .frame(width: 108, height: 58)
                .offset(y: -38)

            // Side tufts
            Capsule().fill(hair).frame(width: 22, height: 16).rotationEffect(.degrees(-20)).offset(x: -48, y: -28)
            Capsule().fill(hair).frame(width: 22, height: 16).rotationEffect(.degrees(20)).offset(x: 48, y: -28)

            // Front bangs
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(hair)
                    .frame(width: 18, height: 24)
                    .rotationEffect(.degrees(Double(i - 1) * 12))
                    .offset(x: CGFloat(i - 1) * 20, y: -46)
            }
        }
    }

    private var eyes: some View {
        HStack(spacing: 28) {
            realisticEye
            realisticEye
        }
    }

    private var realisticEye: some View {
        ZStack {
            // Eye white
            Ellipse()
                .fill(Color.white)
                .frame(width: 26, height: blink ? 3 : 26)
                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)

            if !blink {
                // Iris
                Circle()
                    .fill(
                        RadialGradient(
                            colors: mood == .oops
                                ? [Color(hex: 0xE85050), Color(hex: 0x8B2020)]
                                : [Color(hex: 0x4A6741), Color(hex: 0x2C4028)],
                            center: .center,
                            startRadius: 2,
                            endRadius: 8
                        )
                    )
                    .frame(width: 14, height: 14)

                // Pupil
                Circle().fill(Color(hex: 0x1A1A1A)).frame(width: 7, height: 7)

                // Highlight
                Circle().fill(Color.white).frame(width: 4, height: 4).offset(x: -2, y: -2)
                Circle().fill(Color.white.opacity(0.6)).frame(width: 2, height: 2).offset(x: 2, y: 2)
            }
        }
    }

    private var nose: some View {
        Ellipse()
            .fill(LinearGradient(colors: [skinShadow.opacity(0.6), skinShadow], startPoint: .top, endPoint: .bottom))
            .frame(width: 12, height: 10)
            .shadow(color: skinShadow.opacity(0.3), radius: 1, y: 1)
    }

    private var eyebrows: some View {
        HStack(spacing: 26) {
            eyebrow(rotation: mood == .thinking ? -18 : (mood == .oops ? 12 : -8))
            eyebrow(rotation: mood == .thinking ? 18 : (mood == .oops ? -12 : 8))
        }
    }

    private func eyebrow(rotation: Double) -> some View {
        Capsule()
            .fill(hair)
            .frame(width: 22, height: 5)
            .rotationEffect(.degrees(rotation))
    }

    private var mouth: some View {
        Group {
            switch mood {
            case .happy:
                ZStack {
                    Capsule()
                        .fill(Color(hex: 0xC0392B))
                        .frame(width: 32, height: 16)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 26, height: 7)
                        .offset(y: -3)
                }
            case .oops:
                Circle()
                    .fill(Color(hex: 0xC0392B))
                    .frame(width: 14, height: 14)
            case .thinking:
                Circle()
                    .fill(Color(hex: 0xC0392B))
                    .frame(width: 8, height: 8)
                    .offset(x: 8, y: 2)
            case .idle:
                Capsule()
                    .fill(Color(hex: 0xC0392B))
                    .frame(width: 24, height: 5)
            }
        }
    }

    private var sparkles: some View {
        Group {
            if mood == .happy {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AxiomPalette.glow)
                        .offset(x: CGFloat([-70, 0, 70][i]), y: CGFloat([-110, -128, -110][i]))
                        .opacity(bounce ? 1 : 0.3)
                        .scaleEffect(bounce ? 1.1 : 0.8)
                }
            }
        }
    }

    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 2.8...4.8), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) { blink = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) { blink = false }
            }
        }
    }
}
