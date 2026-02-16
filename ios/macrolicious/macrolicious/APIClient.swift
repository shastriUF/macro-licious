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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
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

        return try JSONDecoder().decode(ResponseBody.self, from: data)
    }
}
