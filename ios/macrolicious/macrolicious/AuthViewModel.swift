import Foundation

enum AuthCallbackParser {
    static func accessToken(from url: URL) -> String? {
        if let queryToken = parameter(named: "access_token", from: url.query) {
            return queryToken
        }

        if let fragmentToken = parameter(named: "access_token", from: url.fragment) {
            return fragmentToken
        }

        return nil
    }

    private static func parameter(named name: String, from parameterString: String?) -> String? {
        guard let parameterString, !parameterString.isEmpty else {
            return nil
        }

        let pairs = parameterString.split(separator: "&", omittingEmptySubsequences: true)

        for pair in pairs {
            let parts = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else {
                continue
            }

            let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
            if key == name {
                let rawValue = String(parts[1])
                return rawValue.removingPercentEncoding ?? rawValue
            }
        }

        return nil
    }
}

@MainActor
final class AuthViewModel: ObservableObject {
    enum SignInMode {
        case unknown
        case devToken
        case emailLink
    }

    @Published var email = ""
    @Published var token = ""
    @Published var baseURL: String
    @Published var statusMessage = ""
    @Published var currentUser: UserProfile?
    @Published var caloriesInput = ""
    @Published var carbsInput = ""
    @Published var proteinInput = ""
    @Published var ingredients: [Ingredient] = []
    @Published var ingredientNameInput = ""
    @Published var ingredientBrandInput = ""
    @Published var ingredientDensityInput = ""
    @Published var ingredientCaloriesInput = ""
    @Published var ingredientCarbsInput = ""
    @Published var ingredientProteinInput = ""
    @Published var ingredientFatInput = ""
    @Published var diaryDate = Date()
    @Published var mealLogs: [MealLog] = []
    @Published var dailyTotals = MealLogNutrition(calories: 0, carbs: 0, protein: 0, fat: 0)
    @Published var selectedMealType: MealType = .breakfast
    @Published var useIngredientForMealLog = true
    @Published var selectedMealIngredientId = ""
    @Published var mealNotesInput = ""
    @Published var mealIngredientNameInput = ""
    @Published var mealQuantityValueInput = ""
    @Published var mealQuantityUnit: QuantityUnit = .g
    @Published var mealConsumedGramsInput = ""
    @Published var mealCaloriesInput = ""
    @Published var mealCarbsInput = ""
    @Published var mealProteinInput = ""
    @Published var mealFatInput = ""
    @Published var isProduceModeEnabled = true
    @Published var isLoading = false
    @Published private(set) var signInMode: SignInMode = .unknown

    private let apiClient: APIClient
    private let sessionStore: SessionStore

    var selectedMealIngredient: Ingredient? {
        ingredients.first(where: { $0.id == selectedMealIngredientId })
    }

    var mealLogPreview: MealLogComputationPreview? {
        guard useIngredientForMealLog,
              let ingredient = selectedMealIngredient,
              let quantity = Double(mealQuantityValueInput),
              quantity > 0,
              let consumedGrams = UnitConversion.toCanonicalGrams(
                quantity,
                unit: mealQuantityUnit,
                densityGPerMl: ingredient.densityGPerMl
              ),
              let nutrition = UnitConversion.computeNutrition(
                quantity: quantity,
                unit: mealQuantityUnit,
                per100g: UnitConversion.NutritionValues(
                    calories: ingredient.caloriesPer100g,
                    carbs: ingredient.carbsPer100g,
                    protein: ingredient.proteinPer100g,
                    fat: ingredient.fatPer100g
                ),
                densityGPerMl: ingredient.densityGPerMl
              )
        else {
            return nil
        }

        return MealLogComputationPreview(
            consumedGrams: consumedGrams,
            nutrition: MealLogNutrition(
                calories: nutrition.calories,
                carbs: nutrition.carbs,
                protein: nutrition.protein,
                fat: nutrition.fat
            )
        )
    }

    init(apiClient: APIClient = APIClient(), sessionStore: SessionStore = SessionStore()) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
        self.baseURL = sessionStore.baseURL
    }

    func requestMagicLink() async {
        await perform {
            let response = try await apiClient.requestMagicLink(email: email, baseURL: normalizedBaseURL)

            if let issuedToken = response.token {
                signInMode = .devToken
                token = issuedToken
                statusMessage = "Magic link requested. Dev token auto-filled for testing."
            } else {
                signInMode = .emailLink
                statusMessage = response.note ?? "Magic link requested. Check your email to continue sign-in."
            }
        }
    }

    func verifyMagicLink() async {
        await perform {
            let response = try await apiClient.verifyMagicLink(token: token, baseURL: normalizedBaseURL)
            sessionStore.sessionToken = response.sessionToken
            currentUser = response.user
            syncMacroInput(with: response.user)

            let ingredientResponse = try await apiClient.listIngredients(
                sessionToken: response.sessionToken,
                baseURL: normalizedBaseURL
            )
            ingredients = ingredientResponse.ingredients
            syncMealIngredientSelection()

            let mealLogResponse = try await apiClient.listMealLogs(
                sessionToken: response.sessionToken,
                baseURL: normalizedBaseURL,
                date: currentDiaryDateString
            )
            applyDiaryResponse(mealLogResponse)

            token = ""
            signInMode = .unknown
            statusMessage = "Signed in as \(response.user.email). Loaded \(ingredients.count) ingredients and \(mealLogs.count) meal logs."
        }
    }

    func refreshProfile() async {
        guard let sessionToken = sessionStore.sessionToken else {
            statusMessage = "No session token saved."
            return
        }

        await perform {
            let response = try await apiClient.fetchProfile(sessionToken: sessionToken, baseURL: normalizedBaseURL)
            currentUser = response.user
            syncMacroInput(with: response.user)
            statusMessage = "Profile refreshed."
        }
    }

    func refreshIngredients() async {
        guard let sessionToken = sessionStore.sessionToken else {
            statusMessage = "No session token saved."
            return
        }

        await perform {
            let response = try await apiClient.listIngredients(sessionToken: sessionToken, baseURL: normalizedBaseURL)
            ingredients = response.ingredients
            syncMealIngredientSelection()
            statusMessage = "Ingredients refreshed."
        }
    }

    func createIngredient() async {
        guard let sessionToken = sessionStore.sessionToken else {
            statusMessage = "No session token saved."
            return
        }

        guard
            !ingredientNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let calories = Double(ingredientCaloriesInput),
            let carbs = Double(ingredientCarbsInput),
            let protein = Double(ingredientProteinInput),
            let fat = Double(ingredientFatInput),
            calories >= 0,
            carbs >= 0,
            protein >= 0,
            fat >= 0
        else {
            statusMessage = "Enter ingredient name and valid macro numbers."
            return
        }

        let density = ingredientDensityInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : Double(ingredientDensityInput)
        if let density, density <= 0 {
            statusMessage = "Density must be greater than 0 when provided."
            return
        }

        let normalizedBrand = ingredientBrandInput.trimmingCharacters(in: .whitespacesAndNewlines)

        await perform {
            let request = CreateIngredientRequest(
                name: ingredientNameInput,
                brand: normalizedBrand.isEmpty ? nil : normalizedBrand,
                barcode: nil,
                densityGPerMl: density,
                caloriesPer100g: calories,
                carbsPer100g: carbs,
                proteinPer100g: protein,
                fatPer100g: fat
            )

            let response = try await apiClient.createIngredient(
                sessionToken: sessionToken,
                baseURL: normalizedBaseURL,
                request: request
            )

            ingredients.append(response.ingredient)
            ingredients.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            syncMealIngredientSelection()
            resetIngredientInput()
            statusMessage = "Ingredient created."
        }
    }

    func refreshMealLogs() async {
        guard let sessionToken = sessionStore.sessionToken else {
            statusMessage = "No session token saved."
            return
        }

        await perform {
            let response = try await apiClient.listMealLogs(
                sessionToken: sessionToken,
                baseURL: normalizedBaseURL,
                date: currentDiaryDateString
            )
            applyDiaryResponse(response)
            statusMessage = "Diary refreshed."
        }
    }

    func createMealLog() async {
        guard let sessionToken = sessionStore.sessionToken else {
            statusMessage = "No session token saved."
            return
        }

        let createItem: CreateMealLogItemRequest

        if useIngredientForMealLog {
            guard let ingredient = selectedMealIngredient else {
                statusMessage = "Select an ingredient before adding a meal log."
                return
            }

            guard let quantityValue = Double(mealQuantityValueInput), quantityValue > 0 else {
                statusMessage = "Enter a valid quantity before adding a meal log."
                return
            }

            guard let preview = mealLogPreview else {
                statusMessage = "Cannot compute nutrition for the selected unit. Use a mass unit or provide ingredient density."
                return
            }

            createItem = CreateMealLogItemRequest(
                ingredientId: ingredient.id,
                ingredientName: ingredient.name,
                quantityValue: quantityValue,
                quantityUnit: mealQuantityUnit,
                consumedGrams: preview.consumedGrams,
                nutrition: preview.nutrition
            )
        } else {
            guard
                !mealIngredientNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                let quantityValue = Double(mealQuantityValueInput),
                let consumedGrams = Double(mealConsumedGramsInput),
                let calories = Double(mealCaloriesInput),
                let carbs = Double(mealCarbsInput),
                let protein = Double(mealProteinInput),
                let fat = Double(mealFatInput),
                quantityValue > 0,
                consumedGrams > 0,
                calories >= 0,
                carbs >= 0,
                protein >= 0,
                fat >= 0
            else {
                statusMessage = "Enter valid manual meal-log values before adding an entry."
                return
            }

            createItem = CreateMealLogItemRequest(
                ingredientId: nil,
                ingredientName: mealIngredientNameInput,
                quantityValue: quantityValue,
                quantityUnit: mealQuantityUnit,
                consumedGrams: consumedGrams,
                nutrition: MealLogNutrition(
                    calories: calories,
                    carbs: carbs,
                    protein: protein,
                    fat: fat
                )
            )
        }

        await perform {
            let createRequest = CreateMealLogRequest(
                date: currentDiaryDateString,
                mealType: selectedMealType,
                notes: mealNotesInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : mealNotesInput,
                items: [createItem]
            )

            _ = try await apiClient.createMealLog(
                sessionToken: sessionToken,
                baseURL: normalizedBaseURL,
                request: createRequest
            )

            let response = try await apiClient.listMealLogs(
                sessionToken: sessionToken,
                baseURL: normalizedBaseURL,
                date: currentDiaryDateString
            )

            applyDiaryResponse(response)
            resetMealLogInput()
            statusMessage = "Meal log entry created."
        }
    }

    func updateMealLog(mealLogId: String, mealType: MealType, notes: String?) async {
        guard let sessionToken = sessionStore.sessionToken else {
            statusMessage = "No session token saved."
            return
        }

        await perform {
            let request = UpdateMealLogRequest(
                date: nil,
                mealType: mealType,
                notes: notes,
                items: nil
            )

            _ = try await apiClient.updateMealLog(
                sessionToken: sessionToken,
                baseURL: normalizedBaseURL,
                mealLogId: mealLogId,
                request: request
            )

            let response = try await apiClient.listMealLogs(
                sessionToken: sessionToken,
                baseURL: normalizedBaseURL,
                date: currentDiaryDateString
            )

            applyDiaryResponse(response)
            statusMessage = "Meal log updated."
        }
    }

    func deleteMealLog(_ mealLogId: String) async {
        guard let sessionToken = sessionStore.sessionToken else {
            statusMessage = "No session token saved."
            return
        }

        await perform {
            try await apiClient.deleteMealLog(
                sessionToken: sessionToken,
                baseURL: normalizedBaseURL,
                mealLogId: mealLogId
            )

            let response = try await apiClient.listMealLogs(
                sessionToken: sessionToken,
                baseURL: normalizedBaseURL,
                date: currentDiaryDateString
            )

            applyDiaryResponse(response)
            statusMessage = "Meal log deleted."
        }
    }

    func updateIngredient(_ ingredient: Ingredient) async {
        guard let sessionToken = sessionStore.sessionToken else {
            statusMessage = "No session token saved."
            return
        }

        await perform {
            let request = UpdateIngredientRequest(
                name: ingredient.name,
                brand: ingredient.brand,
                barcode: ingredient.barcode,
                densityGPerMl: ingredient.densityGPerMl,
                caloriesPer100g: ingredient.caloriesPer100g,
                carbsPer100g: ingredient.carbsPer100g,
                proteinPer100g: ingredient.proteinPer100g,
                fatPer100g: ingredient.fatPer100g
            )

            let response = try await apiClient.updateIngredient(
                sessionToken: sessionToken,
                baseURL: normalizedBaseURL,
                ingredientId: ingredient.id,
                request: request
            )

            if let index = ingredients.firstIndex(where: { $0.id == response.ingredient.id }) {
                ingredients[index] = response.ingredient
            }

            statusMessage = "Ingredient updated."
        }
    }

    func archiveIngredient(_ ingredientId: String) async {
        guard let sessionToken = sessionStore.sessionToken else {
            statusMessage = "No session token saved."
            return
        }

        await perform {
            _ = try await apiClient.archiveIngredient(
                sessionToken: sessionToken,
                baseURL: normalizedBaseURL,
                ingredientId: ingredientId
            )

            ingredients.removeAll { $0.id == ingredientId }
            syncMealIngredientSelection()
            statusMessage = "Ingredient archived."
        }
    }

    func saveMacroTargets() async {
        guard let sessionToken = sessionStore.sessionToken else {
            statusMessage = "No session token saved."
            return
        }

        guard
            let calories = Double(caloriesInput),
            let carbs = Double(carbsInput),
            let protein = Double(proteinInput),
            calories > 0,
            carbs > 0,
            protein > 0
        else {
            statusMessage = "Enter positive numeric values for calories, carbs, and protein."
            return
        }

        await perform {
            let request = UpdateMacroTargetsRequest(
                calories: calories,
                carbs: carbs,
                protein: protein
            )

            let response = try await apiClient.updateMacroTargets(
                sessionToken: sessionToken,
                baseURL: normalizedBaseURL,
                request: request
            )

            currentUser = response.user
            syncMacroInput(with: response.user)
            statusMessage = "Macro targets updated."
        }
    }

    func signOut() async {
        let sessionToken = sessionStore.sessionToken

        await perform {
            if let sessionToken {
                _ = try? await apiClient.signOut(sessionToken: sessionToken, baseURL: normalizedBaseURL)
            }

            sessionStore.clearSession()
            currentUser = nil
            ingredients = []
            mealLogs = []
            dailyTotals = MealLogNutrition(calories: 0, carbs: 0, protein: 0, fat: 0)
            selectedMealIngredientId = ""
            token = ""
            signInMode = .unknown
            caloriesInput = ""
            carbsInput = ""
            proteinInput = ""
            resetIngredientInput()
            resetMealLogInput()
            statusMessage = "Signed out."
        }
    }

    func handleAuthCallback(url: URL) async {
        guard url.scheme?.lowercased() == "macrolicious" else {
            return
        }

        guard url.host?.lowercased() == "auth", url.path == "/callback" else {
            return
        }

        guard let accessToken = AuthCallbackParser.accessToken(from: url) else {
            statusMessage = "Auth callback received, but access token was missing."
            return
        }

        signInMode = .emailLink
        token = accessToken
        await verifyMagicLink()
    }

    var showsManualTokenEntry: Bool {
        signInMode == .devToken || signInMode == .unknown
    }

    func saveBaseURL() {
        sessionStore.baseURL = normalizedBaseURL
        baseURL = normalizedBaseURL
    }

    private var normalizedBaseURL: String {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
    }

    private var currentDiaryDateString: String {
        Self.diaryDateFormatter.string(from: diaryDate)
    }

    private static let diaryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private func perform(_ operation: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await operation()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func syncMacroInput(with user: UserProfile) {
        caloriesInput = String(Int(user.macroTargets.calories))
        carbsInput = String(Int(user.macroTargets.carbs))
        proteinInput = String(Int(user.macroTargets.protein))
    }

    private func resetIngredientInput() {
        ingredientNameInput = ""
        ingredientBrandInput = ""
        ingredientDensityInput = ""
        ingredientCaloriesInput = ""
        ingredientCarbsInput = ""
        ingredientProteinInput = ""
        ingredientFatInput = ""
    }

    private func resetMealLogInput() {
        mealNotesInput = ""
        mealIngredientNameInput = ""
        mealQuantityValueInput = ""
        mealQuantityUnit = .g
        mealConsumedGramsInput = ""
        mealCaloriesInput = ""
        mealCarbsInput = ""
        mealProteinInput = ""
        mealFatInput = ""
    }

    private func syncMealIngredientSelection() {
        guard !ingredients.isEmpty else {
            selectedMealIngredientId = ""
            return
        }

        if ingredients.contains(where: { $0.id == selectedMealIngredientId }) {
            return
        }

        selectedMealIngredientId = ingredients[0].id
    }

    private func applyDiaryResponse(_ response: MealLogsResponse) {
        mealLogs = response.mealLogs.sorted { lhs, rhs in
            if mealTypeSortKey(lhs.mealType) == mealTypeSortKey(rhs.mealType) {
                return lhs.createdAt < rhs.createdAt
            }

            return mealTypeSortKey(lhs.mealType) < mealTypeSortKey(rhs.mealType)
        }
        dailyTotals = response.totals
    }

    private func mealTypeSortKey(_ mealType: MealType) -> Int {
        switch mealType {
        case .breakfast: return 0
        case .lunch: return 1
        case .dinner: return 2
        case .snack: return 3
        }
    }
}

struct MealLogComputationPreview {
    let consumedGrams: Double
    let nutrition: MealLogNutrition
}
