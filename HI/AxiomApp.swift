import SwiftUI
import Combine

@main
struct AxiomApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        }
    }
}

final class AppState: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var isLoading: Bool = true
    @Published var isUserLoggedIn: Bool = false
    @Published var hasSelectedGrade: Bool = false
    @Published var selectedGrade: Int = 1
    @Published var points: Int = 0
    @Published var selectedTab: String = "Home"
    @Published var isMenuExpanded: Bool = false
    @Published var coins: Int = 0
    @Published var themeColor: Color = AxiomPalette.primary
    @Published var userId: Int? = nil
    @Published var fullName: String = ""
    @Published var userEmail: String = ""
    @Published var userXP: Int = 0
    @Published var ownedPets: [Pet] = []
    @Published var equippedPet: Pet? = nil
    @Published var showPetPopup: Pet? = nil
    @Published var leaderboard: [LeaderboardUser] = []

    @Published var voiceEnabled: Bool = true
    @Published var soundEffectsEnabled: Bool = true
    @Published var notificationsEnabled: Bool = true

    @Published var lastChallengeCompletedDate: Date? = nil
    @Published var challengeStreak: Int = 0
    @Published var ownedItemIDs: Set<String> = []

    var userName: String { fullName.isEmpty ? "Guest" : fullName }

    var hasCompletedChallengeToday: Bool {
        guard let last = lastChallengeCompletedDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private let defaults = UserDefaults.standard

    init() {
        let savedId = defaults.integer(forKey: "axiom_user_id")
        if savedId > 0 {
            userId = savedId
            fullName = defaults.string(forKey: "axiom_full_name") ?? ""
            userEmail = defaults.string(forKey: "axiom_email") ?? ""
            isUserLoggedIn = true
        }
        if let savedDate = defaults.object(forKey: "axiom_last_challenge_date") as? Date {
            lastChallengeCompletedDate = savedDate
        }
        challengeStreak = defaults.integer(forKey: "axiom_challenge_streak")
    }

    func applyProfile(_ profile: UserProfile) {
        userId = profile.user_id
        fullName = profile.full_name
        userEmail = profile.email
        selectedGrade = profile.grade
        hasSelectedGrade = profile.has_selected_grade
        userXP = profile.xp
        coins = profile.coins
        points = profile.points
        challengeStreak = profile.challenge_streak
        isUserLoggedIn = true

        defaults.set(profile.user_id, forKey: "axiom_user_id")
        defaults.set(profile.full_name, forKey: "axiom_full_name")
        defaults.set(profile.email, forKey: "axiom_email")
        defaults.set(profile.challenge_streak, forKey: "axiom_challenge_streak")
    }

    func markChallengeCompletedToday() {
        let now = Date()
        lastChallengeCompletedDate = now
        defaults.set(now, forKey: "axiom_last_challenge_date")
        defaults.set(challengeStreak, forKey: "axiom_challenge_streak")
    }

    func logOut() {
        defaults.removeObject(forKey: "axiom_user_id")
        defaults.removeObject(forKey: "axiom_full_name")
        defaults.removeObject(forKey: "axiom_email")
        defaults.removeObject(forKey: "axiom_last_challenge_date")
        defaults.removeObject(forKey: "axiom_challenge_streak")

        userId = nil
        fullName = ""
        userEmail = ""
        isUserLoggedIn = false
        hasSelectedGrade = false
        coins = 0
        userXP = 0
        points = 0
        challengeStreak = 0
        lastChallengeCompletedDate = nil
        ownedPets = []
        equippedPet = nil
        ownedItemIDs = []
        selectedTab = "Home"
    }

    func syncOwnedItems(from ids: [String]) {
        ownedItemIDs = Set(ids)
        ownedPets = ids.compactMap { petTemplate(for: $0) }
        if let equipped = equippedPet, !ownedPets.contains(where: { $0.id == equipped.id }) {
            equippedPet = ownedPets.first
        }
    }

    func refreshFromServer() async {
        guard let userId else { return }
        if let profile = try? await APIClient.fetchProfile(userId: userId) {
            await MainActor.run { applyProfile(profile) }
        }
        if let owned = try? await APIClient.fetchOwnedItems(userId: userId) {
            await MainActor.run { syncOwnedItems(from: owned) }
        }
    }
}
