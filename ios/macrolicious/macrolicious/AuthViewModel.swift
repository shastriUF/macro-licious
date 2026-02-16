import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var token = ""
    @Published var baseURL: String
    @Published var statusMessage = ""
    @Published var currentUser: UserProfile?
    @Published var caloriesInput = ""
    @Published var carbsInput = ""
    @Published var proteinInput = ""
    @Published var isLoading = false

    private let apiClient: APIClient
    private let sessionStore: SessionStore

    init(apiClient: APIClient = APIClient(), sessionStore: SessionStore = SessionStore()) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
        self.baseURL = sessionStore.baseURL
    }

    func requestMagicLink() async {
        await perform {
            let response = try await apiClient.requestMagicLink(email: email, baseURL: normalizedBaseURL)
            token = response.token
            statusMessage = "Magic link requested. Dev token auto-filled for testing."
        }
    }

    func verifyMagicLink() async {
        await perform {
            let response = try await apiClient.verifyMagicLink(token: token, baseURL: normalizedBaseURL)
            sessionStore.sessionToken = response.sessionToken
            currentUser = response.user
            syncMacroInput(with: response.user)
            token = ""
            statusMessage = "Signed in as \(response.user.email). Token consumed; request a new one if needed."
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

    func signOut() {
        sessionStore.clearSession()
        currentUser = nil
        token = ""
        caloriesInput = ""
        carbsInput = ""
        proteinInput = ""
        statusMessage = "Signed out."
    }

    func saveBaseURL() {
        sessionStore.baseURL = normalizedBaseURL
        baseURL = normalizedBaseURL
    }

    private var normalizedBaseURL: String {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
    }

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
}
