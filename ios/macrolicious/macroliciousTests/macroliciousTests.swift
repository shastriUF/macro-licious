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

}
