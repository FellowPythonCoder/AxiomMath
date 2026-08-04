import SwiftUI

extension AxiomPalette {
    static let boardSurface     = Color(hex: 0xFFFDF7)
    static let boardSurfaceDark = Color(hex: 0x14213D)
    static let boardLine        = Color(hex: 0xD8E4F5)
    static let boardLineDark    = Color(hex: 0x27365C)
    static let marker           = primaryDeep
    static let markerDark       = primaryLight
    static let frameWood        = Color(hex: 0xC9A776)
    static let frameWoodDark    = Color(hex: 0x3A2E1F)
}

struct WhiteboardTeachOverlay: View {
    let question: QuizQuestion
    var isDark: Bool
    var themeColor: Color
    var onContinue: () -> Void

    @State private var scrimOpacity: Double = 0
    @State private var boardScale: CGFloat = 0.82
    @State private var boardOpacity: Double = 0
    @State private var boardRotation: Double = -3.5
    @State private var revealedCount: Int = 0
    @State private var answerRevealed = false
    @State private var buddyBounce = false
    @State private var haloPulse: CGFloat = 0.92
    @State private var driftSymbols = false
    @State private var badgeShine: CGFloat = -80

    private var explanation: TeachExplanation { TeachingEngine.explain(for: question) }
    private var boardFill: Color { isDark ? AxiomPalette.boardSurfaceDark : AxiomPalette.boardSurface }
    private var lineColor: Color { isDark ? AxiomPalette.boardLineDark : AxiomPalette.boardLine }
    private var inkColor: Color { isDark ? AxiomPalette.markerDark : AxiomPalette.marker }
    private var inkMuted: Color { inkColor.opacity(isDark ? 0.7 : 0.75) }
    private var frameColor: Color { isDark ? AxiomPalette.frameWoodDark : AxiomPalette.frameWood }

    private let floatingSymbols = ["+", "−", "×", "÷", "="]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                scrim(in: geo.size)

                VStack(spacing: 0) {
                    header
                    board
                    continueButton
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .scaleEffect(boardScale)
                .rotation3DEffect(.degrees(boardRotation), axis: (x: 0, y: 1, z: 0.15), perspective: 0.4)
                .opacity(boardOpacity)
            }
        }
        .onAppear { runSequence() }
    }

    private func scrim(in size: CGSize) -> some View {
        ZStack {
            Color.black.opacity(scrimOpacity)
                .ignoresSafeArea()
                .onTapGesture {  }

            RadialGradient(
                colors: [themeColor.opacity(scrimOpacity * 0.28), .clear],
                center: .center,
                startRadius: 10,
                endRadius: size.width * 0.75
            )
            .scaleEffect(haloPulse)
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ForEach(Array(floatingSymbols.enumerated()), id: \.offset) { i, symbol in
                Text(symbol)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.05))
                    .position(
                        x: size.width * [0.14, 0.86, 0.2, 0.82, 0.5][i % 5],
                        y: driftSymbols
                            ? size.height * [0.14, 0.18, 0.85, 0.82, 0.06][i % 5]
                            : size.height * [0.20, 0.24, 0.78, 0.76, 0.12][i % 5]
                    )
                    .opacity(boardOpacity)
                    .allowsHitTesting(false)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom, spacing: 10) {
            CartoonBuddyView(mood: .thinking, shirtColor: themeColor)
                .scaleEffect(0.34)
                .frame(width: 70, height: 90)
                .offset(y: buddyBounce ? -4 : 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(explanation.heading)
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                Text("Not quite — here's how to get there")
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
            }
            Spacer()
        }
        .padding(.bottom, 12)
    }

    private var board: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(themeColor)
                Text(explanation.restatedQuestion)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(inkColor)
                Spacer()
            }
            .padding(.bottom, 14)

            LinearGradient(colors: [.clear, lineColor, lineColor, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(height: 1.5)
                .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(explanation.steps.enumerated()), id: \.element.id) { index, step in
                    if index < revealedCount {
                        stepRow(step, index: index)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .opacity
                                )
                            )
                    }
                }
            }

            Spacer(minLength: 18)

            if answerRevealed {
                finalAnswerBadge
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(boardFill)
                gridPattern
                RadialGradient(
                    colors: [.clear, .clear, Color.black.opacity(isDark ? 0.28 : 0.05)],
                    center: .center, startRadius: 140, endRadius: 320
                )
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(frameColor.opacity(0.55), lineWidth: 5)
                .padding(2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(
                    LinearGradient(colors: [themeColor.opacity(0.6), themeColor.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 2
                )
        )
        .shadow(color: themeColor.opacity(0.35), radius: 30, y: 16)
        .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
        .frame(minHeight: 260)
        .overlay(alignment: .topLeading) { mountPin.offset(x: 14, y: -10) }
        .overlay(alignment: .topTrailing) { mountPin.offset(x: -14, y: -10) }
    }

    private var mountPin: some View {
        ZStack {
            Circle().fill(themeColor).frame(width: 14, height: 14)
            Circle().fill(Color.white.opacity(0.5)).frame(width: 5, height: 5).offset(x: -2, y: -2)
        }
        .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
    }

    private var gridPattern: some View {
        GeometryReader { geo in
            Path { path in
                let spacing: CGFloat = 22
                var x: CGFloat = 0
                while x < geo.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    x += spacing
                }
                var y: CGFloat = 0
                while y < geo.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    y += spacing
                }
            }
            .stroke(lineColor.opacity(0.5), lineWidth: 0.6)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    private func stepRow(_ step: TeachStep, index: Int) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(
                    LinearGradient(colors: [themeColor.opacity(0.22), themeColor.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                ).frame(width: 22, height: 22)
                Circle().stroke(themeColor.opacity(0.35), lineWidth: 1).frame(width: 22, height: 22)
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(themeColor)
            }
            .padding(.top, 1)

            highlightedText(step)
                .font(.system(size: 15.5, weight: .semibold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func highlightedText(_ step: TeachStep) -> Text {
        guard let highlight = step.highlight, let range = step.text.range(of: highlight) else {
            return Text(step.text).foregroundColor(inkMuted)
        }
        let before = String(step.text[step.text.startIndex..<range.lowerBound])
        let middle = String(step.text[range])
        let after = String(step.text[range.upperBound...])

        return Text(before).foregroundColor(inkMuted)
            + Text(middle).foregroundColor(AxiomPalette.portalDeep).bold()
            + Text(after).foregroundColor(inkMuted)
    }

    private var finalAnswerBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
            Text(explanation.finalLine)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            Capsule().fill(
                LinearGradient(colors: [AxiomPalette.portal, AxiomPalette.portalDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        )
        .overlay(
            Capsule()
                .fill(LinearGradient(colors: [.clear, .white.opacity(0.55), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: 50)
                .offset(x: badgeShine)
                .mask(Capsule())
        )
        .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
        .shadow(color: AxiomPalette.portalDeep.opacity(0.5), radius: 16, y: 8)
    }

    private var continueButton: some View {
        Button {
            HapticManager.instance.impact(style: .light)
            withAnimation(.easeInOut(duration: 0.25)) {
                scrimOpacity = 0
                boardOpacity = 0
                boardScale = 0.9
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onContinue() }
        } label: {
            HStack(spacing: 8) {
                Text("Got it, next question")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule().fill(LinearGradient(colors: [themeColor, themeColor.opacity(0.8)], startPoint: .top, endPoint: .bottom))
            )
            .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 1))
            .shadow(color: themeColor.opacity(0.55), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .opacity(answerRevealed ? 1 : 0)
        .scaleEffect(answerRevealed ? 1 : 0.92)
        .disabled(!answerRevealed)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    private func runSequence() {
        withAnimation(.easeOut(duration: 0.25)) { scrimOpacity = 0.6 }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) {
            boardScale = 1.0
            boardOpacity = 1.0
            boardRotation = 0
        }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            buddyBounce = true
        }
        withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
            haloPulse = 1.15
        }
        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
            driftSymbols = true
        }

        let stepCount = explanation.steps.count
        for i in 0..<stepCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.55) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    revealedCount = i + 1
                }
                HapticManager.instance.impact(style: .light)
            }
        }
        let answerDelay = 0.5 + Double(stepCount) * 0.55 + 0.25
        DispatchQueue.main.asyncAfter(deadline: .now() + answerDelay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                answerRevealed = true
            }
            HapticManager.instance.notify(type: .success)
            badgeShine = -80
            withAnimation(.linear(duration: 0.9).delay(0.15)) {
                badgeShine = 200
            }
        }
    }
}
