import Foundation

struct MacroTargets: Codable, Equatable {
    let calories: Double
    let carbs: Double
    let protein: Double
}

struct UserProfile: Codable, Equatable {
    let id: String
    let email: String
    let macroTargets: MacroTargets
    let createdAt: String
    let updatedAt: String
}

struct MagicLinkRequestResponse: Codable {
    let message: String
    let token: String
    let expiresAt: String
}

struct MagicLinkVerifyResponse: Codable {
    let sessionToken: String
    let user: UserProfile
}

struct MeResponse: Codable {
    let user: UserProfile
}

struct UpdateMacroTargetsRequest: Codable {
    let calories: Double
    let carbs: Double
    let protein: Double
}

struct APIErrorResponse: Codable {
    let error: String
}
