import Foundation
import SwiftUI

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
    let densityGPerMl: Double?
    let servingSizeGrams: Double?
    let defaultQuantityUnit: QuantityUnit?
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
    let densityGPerMl: Double?
    let servingSizeGrams: Double?
    let defaultQuantityUnit: QuantityUnit?
    let caloriesPer100g: Double
    let carbsPer100g: Double
    let proteinPer100g: Double
    let fatPer100g: Double
}

struct UpdateIngredientRequest: Codable {
    let name: String?
    let brand: String?
    let barcode: String?
    let densityGPerMl: Double?
    let servingSizeGrams: Double?
    let defaultQuantityUnit: QuantityUnit?
    let caloriesPer100g: Double?
    let carbsPer100g: Double?
    let proteinPer100g: Double?
    let fatPer100g: Double?
}

struct APIErrorResponse: Codable {
    let error: String
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var label: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .blue
        case .dinner: return .purple
        case .snack: return .green
        }
    }
}

struct MealLogNutrition: Codable, Equatable {
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
}

struct MealLogItem: Codable, Equatable, Identifiable {
    let id: String
    let mealLogId: String
    let ingredientId: String?
    let ingredientName: String
    let quantityValue: Double
    let quantityUnit: QuantityUnit
    let consumedGrams: Double
    let nutrition: MealLogNutrition
    let createdAt: String
    let updatedAt: String
}

struct MealLog: Codable, Equatable, Identifiable {
    let id: String
    let userId: String
    let date: String
    let mealType: MealType
    let notes: String?
    let items: [MealLogItem]
    let createdAt: String
    let updatedAt: String
}

struct MealLogResponse: Codable {
    let mealLog: MealLog
}

struct MealLogsResponse: Codable {
    let date: String
    let mealLogs: [MealLog]
    let totals: MealLogNutrition
}

struct CreateMealLogItemRequest: Codable {
    let ingredientId: String?
    let ingredientName: String
    let quantityValue: Double
    let quantityUnit: QuantityUnit
    let consumedGrams: Double
    let nutrition: MealLogNutrition
}

struct CreateMealLogRequest: Codable {
    let date: String
    let mealType: MealType
    let notes: String?
    let items: [CreateMealLogItemRequest]
}

struct UpdateMealLogRequest: Codable {
    let date: String?
    let mealType: MealType?
    let notes: String?
    let items: [CreateMealLogItemRequest]?
}
