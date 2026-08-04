import SwiftUI
import Combine
import UIKit
import AVFoundation

class SpeechManager: NSObject, ObservableObject {
    static let instance = SpeechManager()
    let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        var cleanedText = text
        cleanedText = cleanedText.replacingOccurrences(of: "*", with: " times ")
        cleanedText = cleanedText.replacingOccurrences(of: " x ", with: " times ")
        cleanedText = cleanedText.replacingOccurrences(of: "+", with: " plus ")
        cleanedText = cleanedText.replacingOccurrences(of: "-", with: " minus ")
        cleanedText = cleanedText.replacingOccurrences(of: "/", with: " divided by ")
        cleanedText = cleanedText.replacingOccurrences(of: "=", with: " equals ")

        let utterance = AVSpeechUtterance(string: cleanedText)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        utterance.voice = voices.first(where: { $0.quality == .enhanced && $0.language == "en-US" }) ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.40
        utterance.pitchMultiplier = 0.90
        synthesizer.speak(utterance)
    }
    func stop() { synthesizer.stopSpeaking(at: .immediate) }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var didRefreshProfile = false

    var body: some View {
        ZStack {
            AxiomPalette.background(dark: appState.isDarkMode).ignoresSafeArea()

            if appState.isLoading {
                LoadingAnimationView()
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
                            withAnimation(.easeInOut(duration: 0.5)) { appState.isLoading = false }
                        }
                    }
            } else if !appState.isUserLoggedIn {
                LoginView().transition(.opacity)
            } else if !appState.hasSelectedGrade {
                GradeSelectionView().transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                MainAppView().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isLoading)
        .animation(.easeInOut(duration: 0.4), value: appState.isUserLoggedIn)
        .animation(.easeInOut(duration: 0.4), value: appState.hasSelectedGrade)
        .task {
            guard !didRefreshProfile, let userId = appState.userId else { return }
            didRefreshProfile = true
            if let profile = try? await APIClient.fetchProfile(userId: userId) {
                appState.applyProfile(profile)
            }
        }
    }
}

struct AxiomBackgroundView: View {
    var isDarkMode: Bool
    let symbols = ["+", "−", "×", "÷", "π", "√", "%"]
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(AxiomPalette.primary.opacity(isDarkMode ? 0.20 : 0.18))
                    .frame(width: 280, height: 280).blur(radius: 70)
                    .position(x: drift ? geo.size.width * 0.12 : geo.size.width * 0.22,
                              y: geo.size.height * 0.10)
                Circle()
                    .fill(AxiomPalette.accent.opacity(isDarkMode ? 0.16 : 0.14))
                    .frame(width: 240, height: 240).blur(radius: 65)
                    .position(x: drift ? geo.size.width * 0.88 : geo.size.width * 0.78,
                              y: geo.size.height * 0.32)
                Circle()
                    .fill(AxiomPalette.primaryLight.opacity(isDarkMode ? 0.12 : 0.10))
                    .frame(width: 260, height: 260).blur(radius: 75)
                    .position(x: geo.size.width * 0.35,
                              y: drift ? geo.size.height * 0.90 : geo.size.height * 0.80)

                ForEach(0..<10, id: \.self) { i in
                    Text(symbols[i % symbols.count])
                        .font(.system(size: CGFloat.random(in: 18...36), weight: .bold, design: .rounded))
                        .foregroundColor(isDarkMode ? Color.white.opacity(0.04) : AxiomPalette.primary.opacity(0.05))
                        .position(x: CGFloat.random(in: 0...geo.size.width), y: drift ? CGFloat.random(in: 0...geo.size.height) : geo.size.height + 40)
                        .animation(.easeInOut(duration: Double.random(in: 6...11)).repeatForever(autoreverses: true).delay(Double(i) * 0.25), value: drift)
                }
            }
        }
        .onAppear { drift = true }
    }
}

enum AuthMode { case signUp, logIn }

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var mode: AuthMode = .signUp
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var animateLogo = false
    @State private var animateText = false
    @FocusState private var focusedField: Field?

    enum Field { case name, email, password }

    var body: some View {
        ZStack {
            AxiomBackgroundView(isDarkMode: appState.isDarkMode).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [appState.themeColor.opacity(0.35), .clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)

                        Image("axiom_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(appState.themeColor.opacity(0.4), lineWidth: 2)
                            )
                            .shadow(color: appState.themeColor.opacity(0.4), radius: 16, y: 6)
                    }
                    .frame(height: 150)
                    .scaleEffect(animateLogo ? 1.0 : 0.4)
                    .opacity(animateLogo ? 1 : 0)
                    .onAppear { withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) { animateLogo = true } }

                    VStack(spacing: 6) {
                        Text("Axiom").font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundColor(appState.isDarkMode ? .white : AxiomPalette.navy)
                        Text("Master math, one question at a time").font(.system(size: 15, weight: .medium, design: .rounded)).foregroundColor(.gray)
                    }
                    .opacity(animateText ? 1 : 0).offset(y: animateText ? 0 : 10)
                    .onAppear { withAnimation(.easeOut(duration: 0.6).delay(0.15)) { animateText = true } }

                    modeSwitcher

                    VStack(spacing: 14) {
                        if mode == .signUp {
                            authField(icon: "person.fill", placeholder: "Full name", text: $fullName, field: .name)
                        }
                        authField(icon: "envelope.fill", placeholder: "Email", text: $email, field: .email, keyboard: .emailAddress)
                        authField(icon: "lock.fill", placeholder: "Password", text: $password, field: .password, isSecure: true)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: appState.themeColor.opacity(0.12), radius: 20, y: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(appState.themeColor.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, 26)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AxiomPalette.berry)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .transition(.opacity)
                    }

                    Button {
                        submit()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Text(mode == .signUp ? "Create Account" : "Log In").font(.system(size: 18, weight: .bold, design: .rounded))
                                Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                        .background(LinearGradient(colors: [appState.themeColor, appState.themeColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule()).shadow(color: appState.themeColor.opacity(0.5), radius: 12, y: 6)
                    }
                    .disabled(isSubmitting)
                    .padding(.horizontal, 30)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            mode = mode == .signUp ? .logIn : .signUp
                            errorMessage = nil
                        }
                    } label: {
                        Text(mode == .signUp ? "Already have an account? Log in" : "New here? Create an account")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(appState.isDarkMode ? .white.opacity(0.8) : AxiomPalette.navy.opacity(0.8))
                    }
                    .padding(.bottom, 30)

                    Spacer(minLength: 20)
                }
            }
        }
    }

    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            modeTab(title: "Sign Up", isActive: mode == .signUp) { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { mode = .signUp; errorMessage = nil } }
            modeTab(title: "Log In", isActive: mode == .logIn) { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { mode = .logIn; errorMessage = nil } }
        }
        .padding(4)
        .background(Capsule().fill(.ultraThinMaterial))
        .padding(.horizontal, 60)
    }

    private func modeTab(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(isActive ? .white : (appState.isDarkMode ? .white.opacity(0.7) : AxiomPalette.navy.opacity(0.7)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Capsule().fill(isActive ? appState.themeColor : Color.clear))
        }
    }

    private func authField(icon: String, placeholder: String, text: Binding<String>, field: Field, keyboard: UIKeyboardType = .default, isSecure: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(appState.themeColor).frame(width: 20)
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboard)
                        .autocapitalization(field == .email ? .none : .words)
                        .disableAutocorrection(field == .email)
                }
            }
            .focused($focusedField, equals: field)
            .font(.system(size: 16, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().stroke(focusedField == field ? appState.themeColor : Color.white.opacity(0.2), lineWidth: focusedField == field ? 2 : 1))
    }

    private func submit() {
        focusedField = nil
        errorMessage = nil

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if mode == .signUp && trimmedName.count < 2 {
            errorMessage = "Enter your full name."
            return
        }
        if !trimmedEmail.contains("@") || !trimmedEmail.contains(".") {
            errorMessage = "Enter a valid email address."
            return
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        isSubmitting = true
        Task {
            do {
                let profile: UserProfile
                if mode == .signUp {
                    profile = try await APIClient.signUp(fullName: trimmedName, email: trimmedEmail, password: password)
                } else {
                    profile = try await APIClient.logIn(email: trimmedEmail, password: password)
                }
                await MainActor.run {
                    HapticManager.instance.notify(type: .success)
                    appState.applyProfile(profile)
                    isSubmitting = false
                }
            } catch {
                await MainActor.run {
                    HapticManager.instance.notify(type: .error)
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
}

struct GradeSelectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var isSyncing = false
    @State private var appear = false
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            AxiomBackgroundView(isDarkMode: appState.isDarkMode).ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer(minLength: 30)

                CartoonBuddyView(mood: .thinking, shirtColor: appState.themeColor)
                    .scaleEffect(0.55)
                    .frame(height: 100)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)

                Text("Choose Your Level").font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundColor(appState.isDarkMode ? .white : AxiomPalette.navy)
                Text("You can change this anytime in Settings").font(.subheadline).foregroundColor(.gray)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(gradeCatalog.enumerated()), id: \.element.grade) { index, info in
                            let isSelected = appState.selectedGrade == info.grade
                            VStack(spacing: 10) {
                                Image(systemName: info.icon).font(.system(size: 26)).foregroundColor(isSelected ? .white : appState.themeColor)
                                Text("Grade \(info.grade)").font(.subheadline.bold()).foregroundColor(isSelected ? .white : (appState.isDarkMode ? .white : .black))
                                Text(info.label).font(.caption).foregroundColor(isSelected ? .white.opacity(0.85) : .gray)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 18)
                            .background(RoundedRectangle(cornerRadius: 18).fill(isSelected ? AnyShapeStyle(LinearGradient(colors: [appState.themeColor, appState.themeColor.opacity(0.75)], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(.ultraThinMaterial)))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(appState.themeColor.opacity(isSelected ? 0.9 : 0.25), lineWidth: isSelected ? 2 : 1))
                            .shadow(color: isSelected ? appState.themeColor.opacity(0.5) : .clear, radius: 10, y: 4)
                            .scaleEffect(isSelected ? 1.03 : 1.0)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 16)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.03), value: appear)
                            .onTapGesture {
                                HapticManager.instance.impact(style: .light)
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { appState.selectedGrade = info.grade }
                            }
                        }
                    }.padding(.horizontal, 20).padding(.vertical, 10)
                }

                Button {
                    HapticManager.instance.impact(style: .medium)
                    confirmGrade()
                } label: {
                    HStack {
                        if isSyncing { ProgressView().tint(.white) } else { Text("Start Learning") }
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white).frame(maxWidth: .infinity).padding()
                    .background(LinearGradient(colors: [appState.themeColor, appState.themeColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing)).clipShape(Capsule()).shadow(color: appState.themeColor.opacity(0.5), radius: 10)
                }
                .disabled(isSyncing)
                .padding(.horizontal, 30).padding(.bottom, 20)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.4)) { appear = true } }
    }

    private func confirmGrade() {
        guard let userId = appState.userId else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appState.hasSelectedGrade = true }
            return
        }
        isSyncing = true
        Task {
            let profile = try? await APIClient.updateGrade(userId: userId, grade: appState.selectedGrade)
            await MainActor.run {
                if let profile { appState.applyProfile(profile) }
                isSyncing = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appState.hasSelectedGrade = true }
            }
        }
    }
}

struct MainAppView: View {
    @EnvironmentObject var appState: AppState
    @State private var topBarHeight: CGFloat = 0

    @State private var isTopBarOpen = false
    @State private var isDropdownOpen = false

    private var isBarActive: Bool { isTopBarOpen || isDropdownOpen }

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch appState.selectedTab {
                case "Home": HomeFeedView(topInset: topBarHeight, isTopBarOpen: $isTopBarOpen, isDropdownOpen: $isDropdownOpen)
                case "Shop": ShopView()
                case "Challenge": ChallengeView()
                case "Profile": ProfileView()
                case "Settings": SettingsView()
                default: HomeFeedView(topInset: topBarHeight, isTopBarOpen: $isTopBarOpen, isDropdownOpen: $isDropdownOpen)
                }
            }
            .id(appState.selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, appState.selectedTab == "Home" ? 0 : topBarHeight)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))

            if isBarActive {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isTopBarOpen = false
                            isDropdownOpen = false
                        }
                    }
                    .zIndex(1)
            }

            ExpandableTopBar(isOpen: $isTopBarOpen, isDropdownOpen: $isDropdownOpen)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: TopBarHeightKey.self, value: geo.size.height)
                    }
                )
                .onPreferenceChange(TopBarHeightKey.self) { newHeight in
                    guard newHeight > 0, abs(newHeight - topBarHeight) > 0.5 else { return }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { topBarHeight = newHeight }
                }
                .zIndex(2)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appState.selectedTab)
        .task { await appState.refreshFromServer() }
    }
}

struct TopBarHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ExpandableTopBar: View {
    @EnvironmentObject var appState: AppState
    @Binding var isOpen: Bool
    @Binding var isDropdownOpen: Bool
    @State private var chevronPressed = false
    @State private var appear = false
    @State private var ringRotation: Double = 0
    @State private var shimmerX: CGFloat = -220
    @State private var glowPulse: CGFloat = 0.85
    @State private var logoOrbit: Double = 0

    private var textColor: Color { appState.isDarkMode ? .white : AxiomPalette.navy }

    private let tabItems: [(id: String, icon: String, label: String, tint: Color)] = [
        ("Home", "house.fill", "Home", AxiomPalette.primary),
        ("Challenge", "bolt.fill", "Challenge", AxiomPalette.electric),
        ("Shop", "bag.fill", "Shop", AxiomPalette.primaryDeep),
        ("Profile", "person.fill", "Profile", AxiomPalette.accent),
        ("Settings", "gearshape.fill", "Settings", AxiomPalette.primaryLight)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                logoBadge

                if isOpen {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(greeting)
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(textColor.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(0.4)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Text(appState.userName)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }

                    .layoutPriority(2)
                    .transition(.opacity.combined(with: .move(edge: .leading)))

                    Spacer(minLength: 6)

                    HStack(spacing: 8) {
                        statPill(icon: "flame.fill", value: "\(appState.challengeStreak)", tint: AxiomPalette.sunset)
                        statPill(icon: "star.fill", value: "\(appState.userXP)", tint: AxiomPalette.accent)
                        statPill(icon: "dollarsign.circle.fill", value: "\(appState.coins)", tint: AxiomPalette.primaryLight)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .trailing)))

                    dropdownButton
                        .transition(.opacity.combined(with: .scale(scale: 0.7, anchor: .trailing)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())

            .onTapGesture { collapseStep() }

            if isOpen && isDropdownOpen {
                VStack(spacing: 14) {
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [.clear, textColor.opacity(0.14), .clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(height: 1)
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("Navigate")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(tabItems.enumerated()), id: \.element.id) { index, tab in
                                    topBarIcon(
                                        icon: tab.icon,
                                        label: tab.label,
                                        tint: tab.tint,
                                        isActive: appState.selectedTab == tab.id
                                    ) {
                                        appState.selectedTab = tab.id
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            isDropdownOpen = false
                                            isOpen = false
                                        }
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("Preferences")
                        HStack(spacing: 12) {
                            topBarIcon(
                                icon: appState.voiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                                label: "Voice",
                                tint: AxiomPalette.primaryLight,
                                isActive: appState.voiceEnabled
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { appState.voiceEnabled.toggle() }
                            }
                            topBarIcon(
                                icon: appState.isDarkMode ? "moon.fill" : "sun.max.fill",
                                label: "Theme",
                                tint: AxiomPalette.warning,
                                isActive: appState.isDarkMode
                            ) {
                                withAnimation { appState.isDarkMode.toggle() }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("Grade Level")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(gradeCatalog, id: \.grade) { grade in
                                    topBarIcon(
                                        icon: grade.icon,
                                        label: grade.label,
                                        tint: appState.themeColor,
                                        isActive: appState.selectedGrade == grade.grade
                                    ) {
                                        let newGrade = grade.grade
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { appState.selectedGrade = newGrade }
                                        if let userId = appState.userId {
                                            Task { _ = try? await APIClient.updateGrade(userId: userId, grade: newGrade) }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.bottom, 14)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: appState.isDarkMode
                                    ? [AxiomPalette.primary.opacity(0.26), .clear, AxiomPalette.electric.opacity(0.10)]
                                    : [AxiomPalette.primaryLight.opacity(0.22), .clear, AxiomPalette.accent.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .trim(from: 0.0, to: 0.5)
                        .stroke(Color.white.opacity(appState.isDarkMode ? 0.18 : 0.55), lineWidth: 1)
                        .blur(radius: 0.5)
                )
                .overlay(

                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.white.opacity(appState.isDarkMode ? 0.12 : 0.30), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(18))
                        .frame(width: 70)
                        .offset(x: shimmerX)
                        .mask(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .allowsHitTesting(false)
                )
                .shadow(color: appState.themeColor.opacity(0.28), radius: 22, y: 10)
                .shadow(color: .black.opacity(appState.isDarkMode ? 0.35 : 0.08), radius: 10, y: 4)
        )
        .background(ambientGlow)
        .overlay(

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    AngularGradient(
                        colors: [
                            appState.themeColor.opacity(0.18),
                            .white.opacity(appState.isDarkMode ? 0.5 : 0.75),
                            appState.themeColor.opacity(0.18),
                            AxiomPalette.electric.opacity(0.45),
                            appState.themeColor.opacity(0.18)
                        ],
                        center: .center,
                        angle: .degrees(ringRotation)
                    ),
                    lineWidth: 1.3
                )
        )
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isOpen)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isDropdownOpen)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { appear = true }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) { ringRotation = 360 }
            withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false).delay(1.0)) { shimmerX = 420 }
        }
    }

    private var ambientGlow: some View {
        ZStack {
            Circle()
                .fill(appState.themeColor.opacity(appState.isDarkMode ? 0.35 : 0.28))
                .frame(width: 120, height: 90)
                .blur(radius: 40)
                .offset(x: -110, y: -6)
                .scaleEffect(glowPulse)
            Circle()
                .fill(AxiomPalette.electric.opacity(appState.isDarkMode ? 0.28 : 0.20))
                .frame(width: 100, height: 80)
                .blur(radius: 38)
                .offset(x: 120, y: 8)
                .scaleEffect(glowPulse)
        }
        .allowsHitTesting(false)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Hi"
        case 12..<17: return "How Are You ?"
        default: return "Hello"
        }
    }

    private var logoBadge: some View {
        ZStack {

            Circle()
                .fill(
                    RadialGradient(colors: [appState.themeColor.opacity(0.45), .clear], center: .center, startRadius: 2, endRadius: 28)
                )
                .frame(width: 50, height: 50)
                .scaleEffect(glowPulse)

            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [appState.themeColor, AxiomPalette.electric, .clear, appState.themeColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.4, dash: [1, 5], dashPhase: 0)
                )
                .frame(width: 46, height: 46)
                .rotationEffect(.degrees(logoOrbit))
                .opacity(0.8)

            Image("axiom_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.7), appState.themeColor.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: appState.themeColor.opacity(0.4), radius: 7, y: 2)
        }
        .scaleEffect(appear ? 1 : 0.6)
        .opacity(appear ? 1 : 0)
        .onAppear {
            withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) { logoOrbit = 360 }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { glowPulse = 1.12 }
        }
    }

    private func collapseStep() {
        HapticManager.instance.impact(style: .light)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            if !isOpen {
                isOpen = true
            } else if isDropdownOpen {
                isDropdownOpen = false
            } else {
                isOpen = false
            }
        }
    }

    private func toggleDropdown() {
        HapticManager.instance.impact(style: .light)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
            isDropdownOpen.toggle()
        }
    }

    private var dropdownButton: some View {
        Button {
            toggleDropdown()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [appState.themeColor, appState.themeColor.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 34, height: 34)
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isDropdownOpen ? 180 : 0))
            }
            .shadow(color: appState.themeColor.opacity(0.5), radius: 8, y: 3)
            .scaleEffect(chevronPressed ? 0.88 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.12)) { chevronPressed = true } }
                .onEnded { _ in withAnimation(.easeOut(duration: 0.12)) { chevronPressed = false } }
        )
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundColor(textColor.opacity(0.4))
            .textCase(.uppercase)
            .tracking(0.6)
            .padding(.horizontal, 16)
    }

    private func statPill(icon: String, value: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(tint)
                .shadow(color: tint.opacity(0.6), radius: 3)
            Text(value).font(.system(size: 12.5, weight: .bold, design: .rounded)).foregroundColor(textColor)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(
                LinearGradient(
                    colors: appState.isDarkMode
                        ? [tint.opacity(0.32), tint.opacity(0.12)]
                        : [tint.opacity(0.22), tint.opacity(0.08)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
        )
        .overlay(Capsule().stroke(tint.opacity(0.4), lineWidth: 1))
        .shadow(color: tint.opacity(appState.isDarkMode ? 0.25 : 0.15), radius: 4, y: 2)
        .layoutPriority(1)
        .fixedSize()
    }

    private func topBarIcon(icon: String, label: String, tint: Color, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.instance.impact(style: .light)
            action()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isActive ? AnyShapeStyle(LinearGradient(colors: [tint, tint.opacity(0.7)], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(tint.opacity(0.14)))
                        .frame(width: 46, height: 46)
                        .shadow(color: isActive ? tint.opacity(0.45) : .clear, radius: 8, y: 3)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isActive ? .white : tint)
                        .symbolEffect(.bounce, value: isActive)
                }
                Text(label)
                    .font(.system(size: 11, weight: isActive ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isActive ? tint : textColor.opacity(0.65))
                    .lineLimit(1)
            }
            .frame(width: 62)
        }
        .buttonStyle(.plain)
    }
}

struct HomeFeedView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var speechManager = ElevenLabsManager.shared
    var topInset: CGFloat = 0
    @Binding var isTopBarOpen: Bool
    @Binding var isDropdownOpen: Bool
    @State private var questions: [QuizQuestion] = []
    @State private var selectedOptions: [Int: String] = [:]
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var currentIndex: Int = 0
    @State private var isFetchingMore = false

    var body: some View {
        ZStack(alignment: .top) {
            AxiomBackgroundView(isDarkMode: appState.isDarkMode).ignoresSafeArea()

            if isLoading {
                VStack(spacing: 16) {
                    CartoonBuddyView(mood: .thinking, shirtColor: appState.themeColor).scaleEffect(0.6).frame(height: 130)
                    Text("Generating questions").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(.gray)
                }
            } else if loadFailed {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundColor(.gray)
                    Text("Couldn't reach the server").foregroundColor(.gray)
                    Button("Try Again") { fetchQuestions() }.foregroundColor(appState.themeColor).font(.headline)
                }
            } else {

                VerticalPager(index: $currentIndex, count: questions.count) { i in
                    let question = questions[i]
                    VideoQuizCard(
                        question: question,
                        userInput: Binding(get: { selectedOptions[question.id] ?? "" }, set: { newValue in selectedOptions[question.id] = newValue }),
                        questionNumber: i + 1,
                        topInset: topInset,
                        onNext: {
                            guard i < questions.count - 1 else { return }
                            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.86)) {
                                currentIndex = i + 1
                            }
                        }
                    )
                }
                .ignoresSafeArea()

                .ignoresSafeArea(.keyboard, edges: .bottom)
                .onChange(of: currentIndex) { _, newIndex in
                    if isTopBarOpen || isDropdownOpen {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isTopBarOpen = false
                            isDropdownOpen = false
                        }
                    }
                    guard questions.indices.contains(newIndex) else { return }
                    if appState.voiceEnabled {
                        speechManager.speak(VoicePhrases.randomIntro(question: questions[newIndex].question))
                    }
                    if newIndex >= questions.count - 3 {
                        fetchMoreQuestions()
                    }
                }
            }
        }.onAppear { if questions.isEmpty { fetchQuestions() } }
    }

    private func fetchQuestions() {
        isLoading = true
        loadFailed = false
        Task {
            do {
                let decoded = try await APIClient.fetchLessons(grade: appState.selectedGrade)
                await MainActor.run {
                    questions = decoded
                    isLoading = false
                    currentIndex = 0
                    if let firstQ = decoded.first, appState.voiceEnabled {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            speechManager.speak(VoicePhrases.randomIntro(question: firstQ.question))
                        }
                    }
                }
            } catch {
                await MainActor.run { isLoading = false; loadFailed = true }
            }
        }
    }

    private func fetchMoreQuestions() {
        guard !isFetchingMore else { return }
        isFetchingMore = true
        Task {
            defer { Task { @MainActor in isFetchingMore = false } }
            guard let decoded = try? await APIClient.fetchLessons(grade: appState.selectedGrade) else { return }
            await MainActor.run {
                let startID = (self.questions.map(\.id).max() ?? -1) + 1
                let newQuestions = decoded.enumerated().map { (i, q) in
                    QuizQuestion(id: startID + i, title: q.title, question: q.question, options: q.options, correct_answer: q.correct_answer)
                }
                self.questions.append(contentsOf: newQuestions)
            }
        }
    }
}

struct VerticalPager<Content: View>: View {
    @Binding var index: Int
    let count: Int
    @ViewBuilder let content: (Int) -> Content

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            VStack(spacing: 0) {
                ForEach(0..<max(count, 1), id: \.self) { i in
                    Group {
                        if i < count {
                            content(i)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: geo.size.width, height: height)
                }
            }
            .offset(y: -CGFloat(index) * height + dragOffset)
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in

                        let atTop = index == 0 && value.translation.height > 0
                        let atBottom = index == count - 1 && value.translation.height < 0
                        dragOffset = (atTop || atBottom) ? value.translation.height * 0.35 : value.translation.height
                    }
                    .onEnded { value in
                        let threshold = height * 0.22
                        var newIndex = index
                        if value.translation.height < -threshold, index < count - 1 {
                            newIndex += 1
                        } else if value.translation.height > threshold, index > 0 {
                            newIndex -= 1
                        }
                        withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.86)) {
                            index = newIndex
                            dragOffset = 0
                        }
                    }
            )
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.86), value: index)
        }
        .clipped()
    }
}

struct VideoQuizCard: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var speechManager = ElevenLabsManager.shared
    var question: QuizQuestion
    @Binding var userInput: String
    var questionNumber: Int
    var topInset: CGFloat = 0
    var onNext: (() -> Void)? = nil
    @State private var animateIn = false
    @State private var showCorrectBurst = false
    @State private var showWrongShake = false
    @State private var showTeachOverlay = false
    @State private var manFloat = false
    @FocusState private var isFocused: Bool

    private var isDark: Bool { appState.isDarkMode }
    private var textColor: Color { AxiomPalette.cardText(dark: isDark) }

    var body: some View {
        ZStack {
            AxiomPalette.cardGradient(dark: isDark).ignoresSafeArea()

            VStack {
                HStack(spacing: 5) { ForEach(1...5, id: \.self) { i in Capsule().fill(i <= questionNumber ? appState.themeColor : textColor.opacity(0.18)).frame(height: 3) } }
                    .padding(.horizontal, 30)
                    .padding(.top, topInset + 14)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: topInset)
                Spacer()
                VStack(spacing: 20) {
                    CartoonBuddyView(mood: showWrongShake ? .oops : (showCorrectBurst ? .happy : .idle), shirtColor: appState.themeColor)
                        .scaleEffect(0.75)
                        .scaleEffect(animateIn ? 1.0 : 0.5)
                        .opacity(animateIn ? 1.0 : 0)
                        .offset(x: manFloat ? 12 : -12, y: manFloat ? -8 : 8)
                        .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: manFloat)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Axiom Math").font(.subheadline.bold()).foregroundColor(appState.themeColor)
                        Text("Quick! What is \(question.question)?").font(.system(size: 28, weight: .heavy, design: .rounded)).foregroundColor(textColor).multilineTextAlignment(.leading)
                    }.padding().background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)).overlay(RoundedRectangle(cornerRadius: 20).stroke(textColor.opacity(0.15), lineWidth: 1)).padding(.horizontal)
                }.offset(y: showWrongShake ? -10 : 0).animation(.interpolatingSpring(stiffness: 3000, damping: 10).repeatCount(3), value: showWrongShake)
                Spacer()
                HStack(spacing: 15) {
                    TextField("Type your answer", text: $userInput)
                        .focused($isFocused)
                        .keyboardType(.default)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                        .padding(.horizontal, 20).padding(.vertical, 18)
                        .background(Capsule().fill(isDark ? Color.white.opacity(0.16) : Color.white.opacity(0.75)))
                        .overlay(Capsule().stroke(textColor.opacity(0.25), lineWidth: 1))
                    Button(action: { checkAnswer(userInput) }) {
                        ZStack {
                            Circle().fill(LinearGradient(colors: [appState.themeColor, appState.themeColor.opacity(0.8)], startPoint: .top, endPoint: .bottom)).frame(width: 60, height: 60)
                            Image(systemName: "paperplane.fill").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                        }
                    }
                }.padding(.horizontal).padding(.bottom, 20)
            }
            if showCorrectBurst { CorrectAnswerOverlay().zIndex(10) }

            if showTeachOverlay {
                WhiteboardTeachOverlay(
                    question: question,
                    isDark: isDark,
                    themeColor: appState.themeColor,
                    onContinue: {
                        showTeachOverlay = false
                        userInput = ""
                        showWrongShake = false
                        onNext?()
                    }
                )
                .zIndex(20)
                .transition(.opacity)
            }
        }.onAppear { withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) { animateIn = true }; manFloat.toggle() }
    }

    private func checkAnswer(_ input: String) {
        if showCorrectBurst || showTeachOverlay { return }
        let cleanedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedCorrect = question.correct_answer.trimmingCharacters(in: .whitespacesAndNewlines)
        var isCorrect = false
        if let inputInt = Int(cleanedInput), let correctInt = Int(cleanedCorrect) { isCorrect = inputInt == correctInt } else { isCorrect = cleanedInput.caseInsensitiveCompare(cleanedCorrect) == .orderedSame }
        isFocused = false

        if let userId = appState.userId {
            Task {
                if let profile = try? await APIClient.submitAnswer(userId: userId, correct: isCorrect) {
                    await MainActor.run { appState.applyProfile(profile) }
                }
            }
        }

        if isCorrect {
            HapticManager.instance.notify(type: .success)
            if appState.voiceEnabled { speechManager.speak("That is correct! The answer is \(question.correct_answer).") }
            withAnimation(.spring()) { appState.points += 1; appState.coins += 10; appState.userXP += 5 }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { showCorrectBurst = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation(.easeOut(duration: 0.3)) { showCorrectBurst = false } }
        } else {
            HapticManager.instance.notify(type: .error)
            if appState.voiceEnabled { speechManager.speak("Oops, not quite. Let's break it down together.") }
            showWrongShake.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeInOut(duration: 0.3)) { showTeachOverlay = true }
            }
        }
    }
}

struct CorrectAnswerOverlay: View {
    @State private var animateCard = false
    var body: some View {
        ZStack {
            AxiomPalette.success.opacity(0.2).ignoresSafeArea().transition(.opacity)
            VStack(spacing: 15) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AxiomPalette.success)
                    .shadow(color: AxiomPalette.success, radius: 15)
                    .scaleEffect(animateCard ? 1.0 : 0.1)
                Text("Correct!")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: 30).fill(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.white.opacity(0.4), lineWidth: 2))
            .shadow(color: AxiomPalette.success.opacity(0.5), radius: 20)
            .scaleEffect(animateCard ? 1.0 : 0.5)
            .transition(.scale.combined(with: .opacity))
        }.onAppear { withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { animateCard = true } }
    }
}

struct ShopView: View {
    @EnvironmentObject var appState: AppState
    @State private var justPurchased: ShopItem?
    @State private var purchaseError: String?
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            AxiomBackgroundView(isDarkMode: appState.isDarkMode).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Text("Shop").font(.title.bold()).foregroundColor(appState.isDarkMode ? .white : AxiomPalette.navy)
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "dollarsign.circle.fill").foregroundColor(AxiomPalette.gold)
                            Text("\(appState.coins)").font(.headline.bold()).foregroundColor(appState.isDarkMode ? .white : .black)
                        }.padding(.horizontal, 14).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial))
                    }.padding(.horizontal).padding(.top, 12)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(shopCatalog) { item in
                            ShopItemCard(item: item, owned: appState.ownedItemIDs.contains(item.id)) {
                                purchase(item)
                            }
                        }
                    }.padding(.horizontal)
                    Spacer(minLength: 40)
                }
            }
            .overlay {
                if let item = justPurchased {
                    VStack(spacing: 12) {
                        Image(systemName: item.icon).font(.system(size: 50)).foregroundColor(item.color)
                        Text("Purchased \(item.name)!").font(.headline).foregroundColor(.white)
                    }
                    .padding(30)
                    .background(RoundedRectangle(cornerRadius: 24).fill(.ultraThinMaterial))
                    .transition(.scale.combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { withAnimation { justPurchased = nil } }
                    }
                } else if let purchaseError {
                    Text(purchaseError)
                        .font(.subheadline.bold()).foregroundColor(.white).padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AxiomPalette.berry))
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { withAnimation { self.purchaseError = nil } }
                        }
                }
            }
        }
    }

    private func purchase(_ item: ShopItem) {
        guard !appState.ownedItemIDs.contains(item.id), appState.coins >= item.price, let userId = appState.userId else {
            HapticManager.instance.notify(type: .error)
            return
        }
        Task {
            do {
                let profile = try await APIClient.purchaseItem(userId: userId, itemId: item.id, price: item.price)
                await MainActor.run {
                    HapticManager.instance.notify(type: .success)
                    appState.applyProfile(profile)
                    appState.ownedItemIDs.insert(item.id)
                    if let pet = petTemplate(for: item.id) { appState.ownedPets.append(pet) }
                    withAnimation(.spring()) { justPurchased = item }
                }
            } catch {
                await MainActor.run {
                    HapticManager.instance.notify(type: .error)
                    withAnimation { purchaseError = error.localizedDescription }
                }
            }
        }
    }
}

struct ShopItemCard: View {
    @EnvironmentObject var appState: AppState
    let item: ShopItem
    let owned: Bool
    let onBuy: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(item.color.opacity(0.2)).frame(width: 60, height: 60)
                Image(systemName: item.icon).font(.system(size: 26)).foregroundColor(item.color)
            }
            Text(item.name).font(.subheadline.bold()).foregroundColor(appState.isDarkMode ? .white : .black).multilineTextAlignment(.center)
            Text(item.rarity).font(.caption2.bold()).foregroundColor(item.color)

            Button(action: onBuy) {
                if owned {
                    Text("Owned").font(.caption.bold()).foregroundColor(.gray).frame(maxWidth: .infinity).padding(8)
                        .background(Capsule().fill(Color.gray.opacity(0.2)))
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                        Text("\(item.price)")
                    }.font(.caption.bold()).foregroundColor(.white).frame(maxWidth: .infinity).padding(8)
                        .background(Capsule().fill(appState.coins >= item.price ? item.color : Color.gray))
                }
            }.disabled(owned)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(item.color.opacity(0.4), lineWidth: 1.5))
    }
}

enum ChallengeStage { case intro, loading, playing, finished, error }

struct ChallengeView: View {
    @EnvironmentObject var appState: AppState
    @State private var stage: ChallengeStage = .intro
    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var correctCount = 0
    @State private var secondsLeft = 30
    @State private var timer: Timer?
    @State private var earnedCoins = 0
    @State private var earnedXP = 0

    var body: some View {
        ZStack {
            AxiomBackgroundView(isDarkMode: appState.isDarkMode).ignoresSafeArea()
            switch stage {
            case .intro: introView
            case .loading:
                VStack(spacing: 16) {
                    CartoonBuddyView(mood: .thinking, shirtColor: appState.themeColor).scaleEffect(0.6).frame(height: 130)
                    Text("Loading challenge").foregroundColor(.gray).font(.subheadline.bold())
                }
            case .playing: playingView
            case .finished: finishedView
            case .error: errorView
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    private var introView: some View {
        VStack(spacing: 26) {
            Spacer()
            CartoonBuddyView(mood: .happy, shirtColor: appState.themeColor).scaleEffect(0.8).frame(height: 170)
            Text("Daily Challenge").font(.title.bold()).foregroundColor(appState.isDarkMode ? .white : AxiomPalette.navy)
            Text("Complete 5 questions of increasing difficulty before the timer runs out!").font(.headline).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal)
            HStack(spacing: 30) {
                VStack { Text("0:30").font(.title.monospacedDigit()).foregroundColor(appState.isDarkMode ? .white : .black); Text("Time Per Q").font(.caption).foregroundColor(.gray) }
                VStack { Text("+500").font(.title.bold()).foregroundColor(AxiomPalette.gold); Text("Coin Reward").font(.caption).foregroundColor(.gray) }
            }
            if appState.hasCompletedChallengeToday {
                Text("Already completed today — come back tomorrow!").foregroundColor(AxiomPalette.mint).font(.subheadline.bold())
            }
            if appState.challengeStreak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundColor(AxiomPalette.electric)
                    Text("\(appState.challengeStreak) day streak").foregroundColor(AxiomPalette.electric).font(.subheadline.bold())
                }
            }
            Button {
                HapticManager.instance.impact(style: .medium)
                startChallenge()
            } label: {
                Text(appState.hasCompletedChallengeToday ? "Play Again" : "Start Challenge").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(appState.themeColor).cornerRadius(15)
            }.padding(.horizontal, 40)
            Spacer()
        }
    }

    private var playingView: some View {
        VStack(spacing: 25) {
            HStack {
                Text("Question \(currentIndex + 1)/5").font(.subheadline.bold()).foregroundColor(.gray)
                Spacer()
                Text("\(secondsLeft)s").font(.subheadline.bold()).foregroundColor(secondsLeft <= 10 ? AxiomPalette.berry : appState.themeColor)
            }.padding(.horizontal, 30).padding(.top, 12)

            ProgressView(value: Double(currentIndex), total: 5).tint(appState.themeColor).padding(.horizontal, 30)

            Spacer()
            if let q = questions[safe: currentIndex] {
                Text(q.question).font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundColor(appState.isDarkMode ? .white : .black).multilineTextAlignment(.center).padding()

                VStack(spacing: 12) {
                    ForEach(q.options, id: \.self) { option in
                        Button {
                            answer(option, correct: q.correct_answer)
                        } label: {
                            Text(option).font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding()
                                .background(appState.themeColor.opacity(0.85)).cornerRadius(14)
                        }
                    }
                }.padding(.horizontal, 30)
            }
            Spacer()
        }
    }

    private var finishedView: some View {
        VStack(spacing: 20) {
            Spacer()
            CartoonBuddyView(mood: correctCount >= 3 ? .happy : .idle, shirtColor: appState.themeColor).scaleEffect(0.75).frame(height: 160)
            Text("Challenge Complete!").font(.title.bold()).foregroundColor(appState.isDarkMode ? .white : AxiomPalette.navy)
            Text("\(correctCount)/5 correct").font(.title2.bold()).foregroundColor(.gray)
            HStack(spacing: 30) {
                VStack { Text("+\(earnedCoins)").font(.title2.bold()).foregroundColor(AxiomPalette.gold); Text("Coins").font(.caption).foregroundColor(.gray) }
                VStack { Text("+\(earnedXP)").font(.title2.bold()).foregroundColor(AxiomPalette.mint); Text("XP").font(.caption).foregroundColor(.gray) }
            }
            Button {
                stage = .intro
            } label: {
                Text("Done").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(appState.themeColor).cornerRadius(15)
            }.padding(.horizontal, 40)
            Spacer()
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.slash").font(.system(size: 50)).foregroundColor(.gray)
            Text("Couldn't reach the server.").foregroundColor(.gray)
            Button("Try Again") { startChallenge() }.foregroundColor(appState.themeColor)
            Spacer()
        }
    }

    private func startChallenge() {
        stage = .loading
        Task {
            do {
                let decoded = try await APIClient.fetchDailyChallenge(grade: appState.selectedGrade)
                await MainActor.run {
                    questions = decoded.questions
                    currentIndex = 0
                    correctCount = 0
                    secondsLeft = decoded.time_per_question
                    stage = .playing
                    startTimer()
                }
            } catch {
                await MainActor.run { stage = .error }
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if secondsLeft > 0 {
                secondsLeft -= 1
            } else {
                answer(nil, correct: questions[safe: currentIndex]?.correct_answer ?? "")
            }
        }
    }

    private func answer(_ chosen: String?, correct: String) {
        timer?.invalidate()
        if chosen == correct { correctCount += 1; HapticManager.instance.notify(type: .success) } else { HapticManager.instance.notify(type: .error) }
        if currentIndex >= questions.count - 1 {
            finishChallenge()
        } else {
            currentIndex += 1
            secondsLeft = 30
            startTimer()
        }
    }

    private func finishChallenge() {
        let wasCompletedToday = appState.hasCompletedChallengeToday
        guard let userId = appState.userId else { stage = .finished; return }
        Task {
            let result = try? await APIClient.submitChallengeResult(userId: userId, correctCount: correctCount)
            await MainActor.run {
                earnedCoins = result?["coins_earned"] ?? correctCount * 100
                earnedXP = result?["xp_earned"] ?? correctCount * 50
                appState.coins = result?["total_coins"] ?? (appState.coins + earnedCoins)
                appState.userXP = result?["total_xp"] ?? (appState.userXP + earnedXP)
                appState.points += earnedXP
                if !wasCompletedToday { appState.challengeStreak += 1 }
                appState.markChallengeCompletedToday()
                stage = .finished
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var leaderboard: [LeaderboardUser] = []
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            AxiomBackgroundView(isDarkMode: appState.isDarkMode).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        CartoonBuddyView(mood: .happy, shirtColor: appState.themeColor).scaleEffect(0.6).frame(height: 130)
                        Text(appState.userName).font(.title2.bold()).foregroundColor(appState.isDarkMode ? .white : .black)
                        Text("Grade \(appState.selectedGrade)").font(.subheadline).foregroundColor(.gray)
                    }.padding(.top, 8)

                    HStack(spacing: 12) {
                        ProfileStatCard(icon: "star.fill", value: "\(appState.points)", label: "Points", color: appState.themeColor)
                        ProfileStatCard(icon: "dollarsign.circle.fill", value: "\(appState.coins)", label: "Coins", color: AxiomPalette.gold)
                        ProfileStatCard(icon: "bolt.fill", value: "\(appState.userXP)", label: "XP", color: AxiomPalette.mint)
                    }.padding(.horizontal)

                    if appState.challengeStreak > 0 {
                        HStack {
                            Image(systemName: "flame.fill").foregroundColor(AxiomPalette.electric)
                            Text("\(appState.challengeStreak) day challenge streak").font(.subheadline.bold()).foregroundColor(AxiomPalette.electric)
                            Spacer()
                        }.padding().background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)).padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Pets (\(appState.ownedPets.count))").font(.headline).foregroundColor(appState.isDarkMode ? .white : .black).padding(.horizontal)
                        if appState.ownedPets.isEmpty {
                            Text("No pets yet — visit the Shop!").foregroundColor(.gray).padding(.horizontal)
                        } else {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(appState.ownedPets) { pet in
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle().fill(pet.color.opacity(0.2)).frame(width: 55, height: 55)
                                            Image(systemName: pet.icon).font(.system(size: 22)).foregroundColor(pet.color)
                                        }
                                        Text(pet.name).font(.caption.bold()).foregroundColor(appState.isDarkMode ? .white : .black).lineLimit(1)
                                    }
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(appState.equippedPet?.id == pet.id ? appState.themeColor.opacity(0.25) : Color.clear))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(appState.equippedPet?.id == pet.id ? appState.themeColor : Color.clear, lineWidth: 2))
                                    .onTapGesture {
                                        HapticManager.instance.impact(style: .light)
                                        appState.equippedPet = pet
                                    }
                                }
                            }.padding(.horizontal)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Leaderboard").font(.headline).foregroundColor(appState.isDarkMode ? .white : .black).padding(.horizontal)
                        if leaderboard.isEmpty {
                            Text("Leaderboard will appear once players start earning XP.").foregroundColor(.gray).padding(.horizontal)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(leaderboard) { entry in
                                    HStack {
                                        Text("#\(entry.rank)").font(.subheadline.bold()).foregroundColor(appState.themeColor).frame(width: 30, alignment: .leading)
                                        Text(entry.name).font(.subheadline.bold()).foregroundColor(appState.isDarkMode ? .white : .black)
                                        Spacer()
                                        Text("\(entry.xp) XP").font(.subheadline.bold()).foregroundColor(.gray)
                                    }.padding(.horizontal, 14).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
                                }
                            }.padding(.horizontal)
                        }
                    }
                    Spacer(minLength: 40)
                }
            }
        }
        .task { leaderboard = (try? await APIClient.fetchLeaderboard()) ?? [] }
    }
}

struct ProfileStatCard: View {
    let icon: String; let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 20))
            Text(value).font(.headline.bold())
            Text(label).font(.caption2).foregroundColor(.gray)
        }.frame(maxWidth: .infinity).padding(.vertical, 14).background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogOutConfirm = false
    let themeOptions: [Color] = [
        AxiomPalette.primary,
        AxiomPalette.primaryDeep,
        AxiomPalette.primaryLight,
        AxiomPalette.accent,
        AxiomPalette.electric,
        AxiomPalette.navy
    ]

    var body: some View {
        ZStack {
            AxiomBackgroundView(isDarkMode: appState.isDarkMode).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Settings").font(.largeTitle.bold()).foregroundColor(appState.isDarkMode ? .white : AxiomPalette.navy).padding(.top, 12).padding(.horizontal)

                    SettingsSection(title: "Appearance") {
                        Toggle("Dark Mode", isOn: $appState.isDarkMode).tint(appState.themeColor)
                        HStack {
                            Text("Theme Color")
                            Spacer()
                            HStack(spacing: 10) {
                                ForEach(themeOptions, id: \.self) { color in
                                    Circle().fill(color).frame(width: 26, height: 26)
                                        .overlay(Circle().stroke(Color.primary, lineWidth: appState.themeColor == color ? 2 : 0))
                                        .onTapGesture { HapticManager.instance.impact(style: .light); appState.themeColor = color }
                                }
                            }
                        }
                    }

                    SettingsSection(title: "Audio") {
                        Toggle("Voice Narration", isOn: $appState.voiceEnabled).tint(appState.themeColor)
                        Toggle("Sound Effects", isOn: $appState.soundEffectsEnabled).tint(appState.themeColor)
                    }

                    SettingsSection(title: "Notifications") {
                        Toggle("Daily Challenge Reminders", isOn: $appState.notificationsEnabled).tint(appState.themeColor)
                    }

                    SettingsSection(title: "Account") {
                        HStack { Text("Name"); Spacer(); Text(appState.userName).foregroundColor(.gray) }
                        HStack { Text("Email"); Spacer(); Text(appState.userEmail).foregroundColor(.gray) }
                        HStack { Text("Grade Level"); Spacer(); Text("\(appState.selectedGrade)").foregroundColor(.gray) }
                        Button(role: .destructive) { showLogOutConfirm = true } label: {
                            Text("Log Out").foregroundColor(AxiomPalette.berry)
                        }
                    }
                    Spacer(minLength: 40)
                }
            }
        }
        .confirmationDialog("Log out of Axiom?", isPresented: $showLogOutConfirm, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { appState.logOut() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct SettingsSection<Content: View>: View {
    @EnvironmentObject var appState: AppState
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.caption.bold()).foregroundColor(.gray).padding(.horizontal, 20)
            VStack(spacing: 14) { content }
                .padding().background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial)).padding(.horizontal)
        }
    }
}
