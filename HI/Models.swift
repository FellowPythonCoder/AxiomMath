//
//  Models.swift
//  Axiom
//
//  Created by azad pelia on 8/2/26.
//
import SwiftUI

struct QuizQuestion: Identifiable, Decodable {
    var id: Int
    let title: String
    let question: String
    let options: [String]
    let correct_answer: String
}

struct DailyChallengeResponse: Decodable {
    let questions: [QuizQuestion]
    let time_per_question: Int
    let coin_reward: Int
}

struct UserProfile: Decodable {
    let user_id: Int
    let full_name: String
    let email: String
    let grade: Int
    let has_selected_grade: Bool
    let xp: Int
    let coins: Int
    let points: Int
    let challenge_streak: Int
    let last_challenge_date: String?
}

struct APIError: Decodable {
    let error: String
}

struct LeaderboardUser: Identifiable, Decodable {
    var id: String { name + String(rank) }
    let name: String
    let xp: Int
    let rank: Int
}

struct Pet: Identifiable {
    let id = UUID()
    let name: String
    let rarity: String
    let icon: String
    let color: Color
}

struct GradeInfo {
    let grade: Int
    let label: String
    let icon: String
}

let gradeCatalog: [GradeInfo] = [
    GradeInfo(grade: 1, label: "Counting", icon: "1.circle.fill"),
    GradeInfo(grade: 2, label: "Addition", icon: "plus.circle.fill"),
    GradeInfo(grade: 3, label: "Subtraction", icon: "minus.circle.fill"),
    GradeInfo(grade: 4, label: "Multiplication", icon: "multiply.circle.fill"),
    GradeInfo(grade: 5, label: "Division", icon: "divide.circle.fill"),
    GradeInfo(grade: 6, label: "Fractions", icon: "chart.pie.fill"),
    GradeInfo(grade: 7, label: "Pre-Algebra", icon: "x.circle.fill"),
    GradeInfo(grade: 8, label: "Algebra I", icon: "function"),
    GradeInfo(grade: 9, label: "Algebra II", icon: "square.and.pencil"),
    GradeInfo(grade: 10, label: "Quadratics", icon: "waveform.path.ecg"),
]

struct ShopItem: Identifiable {
    let id: String
    let name: String
    let icon: String
    let rarity: String
    let color: Color
    let price: Int
}

let shopCatalog: [ShopItem] = [
    ShopItem(id: "pet_fox", name: "Fennec Fox", icon: "hare.fill", rarity: "Common", color: AxiomPalette.primaryLight, price: 150),
    ShopItem(id: "pet_owl", name: "Wise Owl", icon: "bird.fill", rarity: "Common", color: AxiomPalette.accent, price: 150),
    ShopItem(id: "pet_dragon", name: "Baby Dragon", icon: "flame.fill", rarity: "Rare", color: AxiomPalette.primaryDeep, price: 400),
    ShopItem(id: "pet_unicorn", name: "Unicorn", icon: "sparkles", rarity: "Rare", color: AxiomPalette.electric, price: 400),
    ShopItem(id: "pet_phoenix", name: "Phoenix", icon: "sun.max.fill", rarity: "Legendary", color: AxiomPalette.glow, price: 900),
    ShopItem(id: "theme_ocean", name: "Ocean Theme", icon: "paintpalette.fill", rarity: "Cosmetic", color: AxiomPalette.primary, price: 250),
    ShopItem(id: "theme_sky", name: "Sky Theme", icon: "cloud.fill", rarity: "Cosmetic", color: AxiomPalette.accent, price: 250),
    ShopItem(id: "streak_freeze", name: "Streak Freeze", icon: "snowflake", rarity: "Booster", color: AxiomPalette.sky, price: 100),
]

func petTemplate(for itemID: String) -> Pet? {
    guard let item = shopCatalog.first(where: { $0.id == itemID }), itemID.hasPrefix("pet_") else { return nil }
    return Pet(name: item.name, rarity: item.rarity, icon: item.icon, color: item.color)
}
