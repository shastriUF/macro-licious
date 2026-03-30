//
//  macroliciousTests.swift
//  macroliciousTests
//
//  Created by Aniruddha Shastri on 2/15/26.
//

import Testing
import Foundation
@testable import macrolicious

struct macroliciousTests {

        @Test func decodesProfileResponse() async throws {
                let json = """
                {
                    "user": {
                        "id": "user_123",
                        "email": "aniruddha@example.com",
                        "macroTargets": {
                            "calories": 2200,
                            "carbs": 275,
                            "protein": 140
                        },
                        "createdAt": "2026-02-15T18:00:00Z",
                        "updatedAt": "2026-02-15T18:00:00Z"
                    }
                }
                """

                let data = try #require(json.data(using: .utf8))
                let decoded = try JSONDecoder().decode(MeResponse.self, from: data)

                #expect(decoded.user.email == "aniruddha@example.com")
                #expect(decoded.user.macroTargets.calories == 2200)
                #expect(decoded.user.macroTargets.carbs == 275)
                #expect(decoded.user.macroTargets.protein == 140)
    }

    @Test func decodesSupabaseMagicLinkRequestWithoutDevTokenFields() async throws {
        let json = """
        {
            "message": "Magic link requested",
            "provider": "supabase",
            "note": "Check your email."
        }
        """

        let data = try #require(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(MagicLinkRequestResponse.self, from: data)

        #expect(decoded.message == "Magic link requested")
        #expect(decoded.provider == "supabase")
        #expect(decoded.token == nil)
        #expect(decoded.expiresAt == nil)
    }

    @Test func extractsAccessTokenFromQueryOrFragmentCallback() async throws {
        let queryURL = try #require(URL(string: "macrolicious://auth/callback?access_token=query-token-123&type=magiclink"))
        let fragmentURL = try #require(URL(string: "macrolicious://auth/callback#access_token=fragment-token-456&type=magiclink"))
        let missingTokenURL = try #require(URL(string: "macrolicious://auth/callback?type=magiclink"))

        #expect(AuthCallbackParser.accessToken(from: queryURL) == "query-token-123")
        #expect(AuthCallbackParser.accessToken(from: fragmentURL) == "fragment-token-456")
        #expect(AuthCallbackParser.accessToken(from: missingTokenURL) == nil)
    }

    @Test func decodesMealLogsResponse() async throws {
        let json = """
        {
            "date": "2026-03-29",
            "mealLogs": [
                {
                    "id": "meal_123",
                    "userId": "user_123",
                    "date": "2026-03-29",
                    "mealType": "breakfast",
                    "notes": "Morning log",
                    "items": [
                        {
                            "id": "item_123",
                            "mealLogId": "meal_123",
                            "ingredientId": null,
                            "ingredientName": "Oats",
                            "quantityValue": 50,
                            "quantityUnit": "g",
                            "consumedGrams": 50,
                            "nutrition": {
                                "calories": 194.5,
                                "carbs": 33.15,
                                "protein": 8.45,
                                "fat": 3.45
                            },
                            "createdAt": "2026-03-29T12:00:00Z",
                            "updatedAt": "2026-03-29T12:00:00Z"
                        }
                    ],
                    "createdAt": "2026-03-29T12:00:00Z",
                    "updatedAt": "2026-03-29T12:00:00Z"
                }
            ],
            "totals": {
                "calories": 194.5,
                "carbs": 33.15,
                "protein": 8.45,
                "fat": 3.45
            }
        }
        """

        let data = try #require(json.data(using: .utf8))
        let decoded = try JSONDecoder().decode(MealLogsResponse.self, from: data)

        #expect(decoded.date == "2026-03-29")
        #expect(decoded.mealLogs.count == 1)
        #expect(decoded.mealLogs.first?.mealType == .breakfast)
        #expect(decoded.mealLogs.first?.items.first?.quantityUnit == .g)
        #expect(decoded.totals.calories == 194.5)
    }

    // MARK: - Unit Conversion Tests

    @Test func convertsGramsIdentity() {
        #expect(UnitConversion.toGrams(100, unit: .g) == 100)
    }

    @Test func convertsOuncesToGrams() {
        let result = UnitConversion.toGrams(1, unit: .oz)
        #expect(abs(result - 28.3495) < 0.001)
    }

    @Test func convertsPoundsToGrams() {
        let result = UnitConversion.toGrams(1, unit: .lb)
        #expect(abs(result - 453.592) < 0.01)
    }

    @Test func convertsCupToMl() {
        let result = UnitConversion.toMillilitres(1, unit: .cup)
        #expect(abs(result - 236.588) < 0.01)
    }

    @Test func convertsVolumeToGramsWithDensity() {
        // 1 cup water (density 1.0) ≈ 236.6 g
        let result = UnitConversion.volumeToGrams(1, unit: .cup, densityGPerMl: 1.0)
        #expect(result != nil)
        #expect(abs(result! - 236.588) < 0.01)
    }

    @Test func volumeToGramsReturnsNilWithoutDensity() {
        #expect(UnitConversion.volumeToGrams(1, unit: .cup, densityGPerMl: nil) == nil)
    }

    @Test func canonicalGramsForMassDoesNotRequireDensity() {
        let result = UnitConversion.toCanonicalGrams(4, unit: .oz)
        #expect(result != nil)
        #expect(abs(result! - 113.398) < 0.1)
    }

    @Test func canonicalGramsForVolumeRequiresDensity() {
        #expect(UnitConversion.toCanonicalGrams(1, unit: .cup) == nil)
        #expect(UnitConversion.toCanonicalGrams(1, unit: .cup, densityGPerMl: 0.9) != nil)
    }

    @Test func computesNutritionForGrams() {
        let chicken = UnitConversion.NutritionValues(calories: 165, carbs: 0, protein: 31, fat: 3.6)
        let result = UnitConversion.computeNutrition(quantity: 200, unit: .g, per100g: chicken)
        #expect(result != nil)
        #expect(result!.calories == 330)
        #expect(result!.protein == 62)
        #expect(result!.fat == 7.2)
    }

    @Test func computeNutritionReturnsNilForVolumeWithoutDensity() {
        let chicken = UnitConversion.NutritionValues(calories: 165, carbs: 0, protein: 31, fat: 3.6)
        #expect(UnitConversion.computeNutrition(quantity: 1, unit: .cup, per100g: chicken) == nil)
    }

    @Test func quantityUnitClassification() {
        #expect(QuantityUnit.g.isMass == true)
        #expect(QuantityUnit.oz.isMass == true)
        #expect(QuantityUnit.cup.isVolume == true)
        #expect(QuantityUnit.tsp.isVolume == true)
        #expect(QuantityUnit.g.isVolume == false)
        #expect(QuantityUnit.cup.isMass == false)
    }

    @MainActor
    @Test func quickPresetsLoadAfterVerifyAndFilterUnavailableIngredients() async throws {
        let userId = "user_\(UUID().uuidString)"
        let availableIngredient = testIngredient(id: "ingredient_available")

        let sessionStore = MockSessionStore()
        sessionStore.storedPresets = [
            StoredMealQuickPreset(
                userId: userId,
                mealTypeRawValue: MealType.breakfast.rawValue,
                ingredientId: availableIngredient.id,
                ingredientName: availableIngredient.name,
                quantityValue: 80,
                quantityUnitRawValue: QuantityUnit.g.rawValue,
                updatedAt: Date()
            ),
            StoredMealQuickPreset(
                userId: userId,
                mealTypeRawValue: MealType.lunch.rawValue,
                ingredientId: "ingredient_missing",
                ingredientName: "Missing Ingredient",
                quantityValue: 1,
                quantityUnitRawValue: QuantityUnit.cup.rawValue,
                updatedAt: Date().addingTimeInterval(-60)
            )
        ]

        let apiClient = MockAPIClient()
        apiClient.verifyResponse = MagicLinkVerifyResponse(
            sessionToken: "session_test",
            user: testUserProfile(id: userId)
        )
        apiClient.ingredientsResponse = IngredientsResponse(ingredients: [availableIngredient])
        apiClient.mealLogsResponse = emptyMealLogsResponse()

        let viewModel = AuthViewModel(apiClient: apiClient, sessionStore: sessionStore)
        viewModel.token = "token_from_magic_link"

        await viewModel.verifyMagicLink()

        #expect(viewModel.mealQuickPresets.count == 1)
        #expect(viewModel.mealQuickPresets.first?.ingredientId == availableIngredient.id)
    }

    @MainActor
    @Test func applyQuickPresetPopulatesMealComposerFields() {
        let apiClient = MockAPIClient()
        let sessionStore = MockSessionStore()
        let ingredient = testIngredient(id: "ingredient_42", name: "Greek Yogurt")
        let viewModel = AuthViewModel(apiClient: apiClient, sessionStore: sessionStore)
        viewModel.ingredients = [ingredient]

        let preset = MealQuickPreset(
            mealType: .snack,
            ingredientId: ingredient.id,
            ingredientName: ingredient.name,
            quantityValue: 150,
            quantityUnit: .g,
            updatedAt: Date()
        )

        viewModel.applyMealQuickPreset(preset)

        #expect(viewModel.selectedMealType == .snack)
        #expect(viewModel.useIngredientForMealLog == true)
        #expect(viewModel.selectedMealIngredientId == ingredient.id)
        #expect(viewModel.mealQuantityValueInput == "150")
        #expect(viewModel.mealQuantityUnit == .g)
    }

    @MainActor
    @Test func createMealLogPersistsQuickPresetInIngredientMode() async {
        let userId = "user_\(UUID().uuidString)"
        let ingredient = testIngredient(id: "ingredient_abc", name: "Oats")
        let apiClient = MockAPIClient()
        let sessionStore = MockSessionStore()
        sessionStore.sessionToken = "session_token_123"

        apiClient.mealLogsResponse = emptyMealLogsResponse()

        let viewModel = AuthViewModel(apiClient: apiClient, sessionStore: sessionStore)
        viewModel.currentUser = testUserProfile(id: userId)
        viewModel.ingredients = [ingredient]
        viewModel.selectedMealIngredientId = ingredient.id
        viewModel.selectedMealType = .lunch
        viewModel.mealQuantityValueInput = "125"
        viewModel.mealQuantityUnit = .g

        await viewModel.createMealLog()

        #expect(sessionStore.upsertedPresets.count == 1)
        #expect(sessionStore.upsertedPresets.first?.userId == userId)
        #expect(sessionStore.upsertedPresets.first?.ingredientId == ingredient.id)
        #expect(sessionStore.upsertedPresets.first?.mealTypeRawValue == MealType.lunch.rawValue)
        #expect(viewModel.mealQuickPresets.count == 1)
        #expect(viewModel.mealQuickPresets.first?.ingredientId == ingredient.id)
    }

    @MainActor
    @Test func createMealLogDoesNotPersistPresetInManualMode() async {
        let userId = "user_\(UUID().uuidString)"
        let apiClient = MockAPIClient()
        let sessionStore = MockSessionStore()
        sessionStore.sessionToken = "session_token_123"

        apiClient.mealLogsResponse = emptyMealLogsResponse()

        let viewModel = AuthViewModel(apiClient: apiClient, sessionStore: sessionStore)
        viewModel.currentUser = testUserProfile(id: userId)
        viewModel.useIngredientForMealLog = false
        viewModel.mealIngredientNameInput = "Manual Ingredient"
        viewModel.mealQuantityValueInput = "1"
        viewModel.mealQuantityUnit = .cup
        viewModel.mealConsumedGramsInput = "240"
        viewModel.mealCaloriesInput = "100"
        viewModel.mealCarbsInput = "10"
        viewModel.mealProteinInput = "5"
        viewModel.mealFatInput = "2"

        await viewModel.createMealLog()

        #expect(sessionStore.upsertedPresets.isEmpty)
        #expect(viewModel.mealQuickPresets.isEmpty)
    }

}

private func testUserProfile(id: String) -> UserProfile {
    UserProfile(
        id: id,
        email: "test@example.com",
        macroTargets: MacroTargets(calories: 2200, carbs: 250, protein: 150),
        createdAt: "2026-03-29T00:00:00Z",
        updatedAt: "2026-03-29T00:00:00Z"
    )
}

private func testIngredient(id: String, name: String = "Ingredient") -> Ingredient {
    Ingredient(
        id: id,
        userId: "user_test",
        name: name,
        brand: nil,
        barcode: nil,
        densityGPerMl: 1.0,
        caloriesPer100g: 200,
        carbsPer100g: 20,
        proteinPer100g: 10,
        fatPer100g: 5,
        archived: false,
        createdAt: "2026-03-29T00:00:00Z",
        updatedAt: "2026-03-29T00:00:00Z"
    )
}

private func emptyMealLogsResponse() -> MealLogsResponse {
    MealLogsResponse(
        date: "2026-03-29",
        mealLogs: [],
        totals: MealLogNutrition(calories: 0, carbs: 0, protein: 0, fat: 0)
    )
}

private final class MockSessionStore: SessionStoreProtocol {
    var sessionToken: String?
    var baseURL: String = "http://127.0.0.1:4000"
    var storedPresets: [StoredMealQuickPreset] = []
    var upsertedPresets: [StoredMealQuickPreset] = []

    func clearSession() {
        sessionToken = nil
    }

    func loadMealQuickPresets(for userId: String) -> [StoredMealQuickPreset] {
        storedPresets
            .filter { $0.userId == userId }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func upsertMealQuickPreset(_ preset: StoredMealQuickPreset, maxPerUser: Int) {
        upsertedPresets.append(preset)

        storedPresets.removeAll {
            $0.userId == preset.userId &&
            $0.mealTypeRawValue == preset.mealTypeRawValue &&
            $0.ingredientId == preset.ingredientId
        }
        storedPresets.append(preset)

        let userPresets = storedPresets
            .filter { $0.userId == preset.userId }
            .sorted { $0.updatedAt > $1.updatedAt }

        if userPresets.count > maxPerUser {
            let allowedIds = Set(userPresets.prefix(maxPerUser).map { "\($0.mealTypeRawValue)-\($0.ingredientId)" })
            storedPresets.removeAll {
                $0.userId == preset.userId && !allowedIds.contains("\($0.mealTypeRawValue)-\($0.ingredientId)")
            }
        }
    }
}

private final class MockAPIClient: APIClientProtocol {
    var verifyResponse = MagicLinkVerifyResponse(
        sessionToken: "mock_session",
        user: testUserProfile(id: "mock_user")
    )
    var ingredientsResponse = IngredientsResponse(ingredients: [])
    var mealLogsResponse = emptyMealLogsResponse()

    private var dummyMealLog: MealLog {
        MealLog(
            id: "meal_dummy",
            userId: "mock_user",
            date: "2026-03-29",
            mealType: .breakfast,
            notes: nil,
            items: [],
            createdAt: "2026-03-29T00:00:00Z",
            updatedAt: "2026-03-29T00:00:00Z"
        )
    }

    func requestMagicLink(email: String, baseURL: String) async throws -> MagicLinkRequestResponse {
        MagicLinkRequestResponse(message: "ok", token: nil, expiresAt: nil, provider: "mock", note: nil)
    }

    func verifyMagicLink(token: String, baseURL: String) async throws -> MagicLinkVerifyResponse {
        verifyResponse
    }

    func fetchProfile(sessionToken: String, baseURL: String) async throws -> MeResponse {
        MeResponse(user: verifyResponse.user)
    }

    func updateMacroTargets(sessionToken: String, baseURL: String, request: UpdateMacroTargetsRequest) async throws -> MeResponse {
        MeResponse(user: verifyResponse.user)
    }

    func listIngredients(sessionToken: String, baseURL: String) async throws -> IngredientsResponse {
        ingredientsResponse
    }

    func createIngredient(sessionToken: String, baseURL: String, request: CreateIngredientRequest) async throws -> IngredientResponse {
        throw APIClientError.invalidResponse
    }

    func updateIngredient(sessionToken: String, baseURL: String, ingredientId: String, request: UpdateIngredientRequest) async throws -> IngredientResponse {
        throw APIClientError.invalidResponse
    }

    func archiveIngredient(sessionToken: String, baseURL: String, ingredientId: String) async throws -> IngredientResponse {
        throw APIClientError.invalidResponse
    }

    func signOut(sessionToken: String, baseURL: String) async throws {}

    func listMealLogs(sessionToken: String, baseURL: String, date: String) async throws -> MealLogsResponse {
        mealLogsResponse
    }

    func createMealLog(sessionToken: String, baseURL: String, request: CreateMealLogRequest) async throws -> MealLogResponse {
        MealLogResponse(mealLog: dummyMealLog)
    }

    func updateMealLog(sessionToken: String, baseURL: String, mealLogId: String, request: UpdateMealLogRequest) async throws -> MealLogResponse {
        MealLogResponse(mealLog: dummyMealLog)
    }

    func deleteMealLog(sessionToken: String, baseURL: String, mealLogId: String) async throws {}
}
