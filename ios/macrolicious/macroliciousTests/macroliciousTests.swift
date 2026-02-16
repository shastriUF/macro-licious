//
//  macroliciousTests.swift
//  macroliciousTests
//
//  Created by Aniruddha Shastri on 2/15/26.
//

import Testing
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

}
