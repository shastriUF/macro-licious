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
    let token: String?
    let expiresAt: String?
    let provider: String?
    let note: String?
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

struct Ingredient: Codable, Equatable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let brand: String?
    let barcode: String?
    let caloriesPer100g: Double
    let carbsPer100g: Double
    let proteinPer100g: Double
    let fatPer100g: Double
    let archived: Bool
    let createdAt: String
    let updatedAt: String
}

struct IngredientsResponse: Codable {
    let ingredients: [Ingredient]
}

struct IngredientResponse: Codable {
    let ingredient: Ingredient
}

struct CreateIngredientRequest: Codable {
    let name: String
    let brand: String?
    let barcode: String?
    let caloriesPer100g: Double
    let carbsPer100g: Double
    let proteinPer100g: Double
    let fatPer100g: Double
}

struct UpdateIngredientRequest: Codable {
    let name: String?
    let brand: String?
    let barcode: String?
    let caloriesPer100g: Double?
    let carbsPer100g: Double?
    let proteinPer100g: Double?
    let fatPer100g: Double?
}

struct APIErrorResponse: Codable {
    let error: String
}
