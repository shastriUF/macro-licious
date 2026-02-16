import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var token = ""
    @Published var baseURL: String
    @Published var statusMessage = ""
    @Published var currentUser: UserProfile?
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
            statusMessage = "Signed in as \(response.user.email)."
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
            statusMessage = "Profile refreshed."
        }
    }

    func signOut() {
        sessionStore.clearSession()
        currentUser = nil
        token = ""
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
}
