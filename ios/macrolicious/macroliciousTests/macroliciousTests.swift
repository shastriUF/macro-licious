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

}
