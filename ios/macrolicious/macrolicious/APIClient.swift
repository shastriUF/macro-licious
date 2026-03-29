import Foundation

enum APIClientError: Error, LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Invalid backend URL."
        case .invalidResponse:
            return "Invalid server response."
        case .httpError(let status, let message):
            return "HTTP \(status): \(message)"
        }
    }
}

final class APIClient {
    func requestMagicLink(email: String, baseURL: String) async throws -> MagicLinkRequestResponse {
        let payload = ["email": email]
        return try await send(
            path: "/auth/magic-link/request",
            method: "POST",
            baseURL: baseURL,
            body: payload,
            authToken: nil,
            decodeAs: MagicLinkRequestResponse.self
        )
    }

    func verifyMagicLink(token: String, baseURL: String) async throws -> MagicLinkVerifyResponse {
        let payload = ["token": token]
        return try await send(
            path: "/auth/magic-link/verify",
            method: "POST",
            baseURL: baseURL,
            body: payload,
            authToken: nil,
            decodeAs: MagicLinkVerifyResponse.self
        )
    }

    func fetchProfile(sessionToken: String, baseURL: String) async throws -> MeResponse {
        try await send(
            path: "/me",
            method: "GET",
            baseURL: baseURL,
            body: Optional<Int>.none,
            authToken: sessionToken,
            decodeAs: MeResponse.self
        )
    }

    func updateMacroTargets(
        sessionToken: String,
        baseURL: String,
        request: UpdateMacroTargetsRequest
    ) async throws -> MeResponse {
        try await send(
            path: "/me/macro-targets",
            method: "PATCH",
            baseURL: baseURL,
            body: request,
            authToken: sessionToken,
            decodeAs: MeResponse.self
        )
    }

    func listIngredients(sessionToken: String, baseURL: String) async throws -> IngredientsResponse {
        try await send(
            path: "/ingredients",
            method: "GET",
            baseURL: baseURL,
            body: Optional<Int>.none,
            authToken: sessionToken,
            decodeAs: IngredientsResponse.self
        )
    }

    func createIngredient(
        sessionToken: String,
        baseURL: String,
        request: CreateIngredientRequest
    ) async throws -> IngredientResponse {
        try await send(
            path: "/ingredients",
            method: "POST",
            baseURL: baseURL,
            body: request,
            authToken: sessionToken,
            decodeAs: IngredientResponse.self
        )
    }

    func updateIngredient(
        sessionToken: String,
        baseURL: String,
        ingredientId: String,
        request: UpdateIngredientRequest
    ) async throws -> IngredientResponse {
        try await send(
            path: "/ingredients/\(ingredientId)",
            method: "PATCH",
            baseURL: baseURL,
            body: request,
            authToken: sessionToken,
            decodeAs: IngredientResponse.self
        )
    }

    func archiveIngredient(
        sessionToken: String,
        baseURL: String,
        ingredientId: String
    ) async throws -> IngredientResponse {
        try await send(
            path: "/ingredients/\(ingredientId)",
            method: "DELETE",
            baseURL: baseURL,
            body: Optional<Int>.none,
            authToken: sessionToken,
            decodeAs: IngredientResponse.self
        )
    }

    func signOut(sessionToken: String, baseURL: String) async throws {
        _ = try await send(
            path: "/auth/sign-out",
            method: "POST",
            baseURL: baseURL,
            body: Optional<Int>.none,
            authToken: sessionToken,
            decodeAs: SignOutResponse.self
        )
    }

    func listMealLogs(
        sessionToken: String,
        baseURL: String,
        date: String
    ) async throws -> MealLogsResponse {
        try await send(
            path: "/meal-logs?date=\(date)",
            method: "GET",
            baseURL: baseURL,
            body: Optional<Int>.none,
            authToken: sessionToken,
            decodeAs: MealLogsResponse.self
        )
    }

    func createMealLog(
        sessionToken: String,
        baseURL: String,
        request: CreateMealLogRequest
    ) async throws -> MealLogResponse {
        try await send(
            path: "/meal-logs",
            method: "POST",
            baseURL: baseURL,
            body: request,
            authToken: sessionToken,
            decodeAs: MealLogResponse.self
        )
    }

    func updateMealLog(
        sessionToken: String,
        baseURL: String,
        mealLogId: String,
        request: UpdateMealLogRequest
    ) async throws -> MealLogResponse {
        try await send(
            path: "/meal-logs/\(mealLogId)",
            method: "PATCH",
            baseURL: baseURL,
            body: request,
            authToken: sessionToken,
            decodeAs: MealLogResponse.self
        )
    }

    func deleteMealLog(
        sessionToken: String,
        baseURL: String,
        mealLogId: String
    ) async throws {
        _ = try await send(
            path: "/meal-logs/\(mealLogId)",
            method: "DELETE",
            baseURL: baseURL,
            body: Optional<Int>.none,
            authToken: sessionToken,
            decodeAs: EmptyResponse.self
        )
    }

    private func send<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        method: String,
        baseURL: String,
        body: RequestBody?,
        authToken: String?,
        decodeAs: ResponseBody.Type
    ) async throws -> ResponseBody {
        guard let url = URL(string: baseURL + path) else {
            throw APIClientError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let apiMessage = (try? JSONDecoder().decode(APIErrorResponse.self, from: data).error) ?? "Request failed"
            throw APIClientError.httpError(httpResponse.statusCode, apiMessage)
        }

        if data.isEmpty, ResponseBody.self == EmptyResponse.self {
            return EmptyResponse() as! ResponseBody
        }

        return try JSONDecoder().decode(ResponseBody.self, from: data)
    }
}

private struct SignOutResponse: Codable {
    let message: String
}

private struct EmptyResponse: Codable {}
