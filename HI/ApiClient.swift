

import Foundation


let SERVER_BASE_URL = "http://10.0.0.54:5000"

enum APIClientError: LocalizedError {
    case badURL
    case server(String)
    case decoding
    case network

    var errorDescription: String? {
        switch self {
        case .badURL: return "Could not reach the server."
        case .server(let message): return message
        case .decoding: return "The server sent back something unexpected."
        case .network: return "Check your connection and try again."
        }
    }
}

enum APIClient {
    private static func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIClientError.network
        }
        guard let http = response as? HTTPURLResponse else { throw APIClientError.network }
        if http.statusCode >= 400 {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                throw APIClientError.server(apiError.error)
            }
            throw APIClientError.server("Something went wrong. Please try again.")
        }
        guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            throw APIClientError.decoding
        }
        return decoded
    }

    private static func jsonRequest(path: String, method: String, body: [String: Any]) throws -> URLRequest {
        guard let url = URL(string: "\(SERVER_BASE_URL)\(path)") else { throw APIClientError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 12
        return request
    }

    static func signUp(fullName: String, email: String, password: String) async throws -> UserProfile {
        let request = try jsonRequest(path: "/signup", method: "POST", body: [
            "full_name": fullName, "email": email, "password": password
        ])
        return try await send(request, as: UserProfile.self)
    }

    static func logIn(email: String, password: String) async throws -> UserProfile {
        let request = try jsonRequest(path: "/login", method: "POST", body: [
            "email": email, "password": password
        ])
        return try await send(request, as: UserProfile.self)
    }

    static func fetchProfile(userId: Int) async throws -> UserProfile {
        guard let url = URL(string: "\(SERVER_BASE_URL)/get_profile/\(userId)") else { throw APIClientError.badURL }
        return try await send(URLRequest(url: url), as: UserProfile.self)
    }

    static func updateGrade(userId: Int, grade: Int) async throws -> UserProfile {
        let request = try jsonRequest(path: "/update_grade", method: "POST", body: [
            "user_id": userId, "grade": grade
        ])
        return try await send(request, as: UserProfile.self)
    }

    static func submitAnswer(userId: Int, correct: Bool) async throws -> UserProfile {
        let request = try jsonRequest(path: "/submit_answer", method: "POST", body: [
            "user_id": userId, "correct": correct
        ])
        return try await send(request, as: UserProfile.self)
    }

    static func purchaseItem(userId: Int, itemId: String, price: Int) async throws -> UserProfile {
        let request = try jsonRequest(path: "/purchase_item", method: "POST", body: [
            "user_id": userId, "item_id": itemId, "price": price
        ])
        return try await send(request, as: UserProfile.self)
    }

    static func fetchLessons(grade: Int) async throws -> [QuizQuestion] {
        guard let url = URL(string: "\(SERVER_BASE_URL)/get_lessons/\(grade)") else { throw APIClientError.badURL }
        return try await send(URLRequest(url: url), as: [QuizQuestion].self)
    }

    static func fetchDailyChallenge(grade: Int) async throws -> DailyChallengeResponse {
        guard let url = URL(string: "\(SERVER_BASE_URL)/get_daily_challenge/\(grade)") else { throw APIClientError.badURL }
        return try await send(URLRequest(url: url), as: DailyChallengeResponse.self)
    }

    static func submitChallengeResult(userId: Int, correctCount: Int) async throws -> [String: Int] {
        let request = try jsonRequest(path: "/submit_challenge_result", method: "POST", body: [
            "user_id": userId, "correct_count": correctCount
        ])
        return try await send(request, as: [String: Int].self)
    }

    static func fetchLeaderboard() async throws -> [LeaderboardUser] {
        guard let url = URL(string: "\(SERVER_BASE_URL)/get_leaderboard") else { throw APIClientError.badURL }
        return try await send(URLRequest(url: url), as: [LeaderboardUser].self)
    }

    static func fetchOwnedItems(userId: Int) async throws -> [String] {
        guard let url = URL(string: "\(SERVER_BASE_URL)/get_owned_items/\(userId)") else { throw APIClientError.badURL }
        let response = try await send(URLRequest(url: url), as: OwnedItemsResponse.self)
        return response.owned_items
    }
}

struct OwnedItemsResponse: Decodable {
    let owned_items: [String]
}
