import Foundation

/// Canonical storage units: mass → grams, volume → millilitres.
/// Supported input: g, oz, lb, ml, tsp, tbsp, cup.

// MARK: - Unit types

enum MassUnit: String, CaseIterable, Codable {
    case g, oz, lb
}

enum VolumeUnit: String, CaseIterable, Codable {
    case ml, tsp, tbsp, cup
}

enum QuantityUnit: String, CaseIterable, Codable {
    case g, oz, lb, ml, tsp, tbsp, cup

    var isMass: Bool {
        switch self {
        case .g, .oz, .lb: return true
        default: return false
        }
    }

    var isVolume: Bool { !isMass }

    var massUnit: MassUnit? {
        MassUnit(rawValue: rawValue)
    }

    var volumeUnit: VolumeUnit? {
        VolumeUnit(rawValue: rawValue)
    }

    /// Human-readable label for picker UI.
    var label: String {
        switch self {
        case .g:    return "g"
        case .oz:   return "oz"
        case .lb:   return "lb"
        case .ml:   return "ml"
        case .tsp:  return "tsp"
        case .tbsp: return "tbsp"
        case .cup:  return "cup"
        }
    }
}

// MARK: - Conversion factors (NIST / USDA)

enum UnitConversion {
    static let massToGrams: [MassUnit: Double] = [
        .g:  1,
        .oz: 28.3495,
        .lb: 453.592
    ]

    static let volumeToMl: [VolumeUnit: Double] = [
        .ml:   1,
        .tsp:  4.92892,
        .tbsp: 14.7868,
        .cup:  236.588
    ]

    // MARK: - Core conversions

    static func toGrams(_ value: Double, unit: MassUnit) -> Double {
        value * (massToGrams[unit] ?? 1)
    }

    static func toMillilitres(_ value: Double, unit: VolumeUnit) -> Double {
        value * (volumeToMl[unit] ?? 1)
    }

    /// Convert a volume quantity to grams using density (g/ml).
    /// Returns nil if density is not available.
    static func volumeToGrams(_ value: Double, unit: VolumeUnit, densityGPerMl: Double?) -> Double? {
        guard let density = densityGPerMl, density > 0 else { return nil }
        return toMillilitres(value, unit: unit) * density
    }

    /// Convert any supported unit to canonical grams.
    /// Mass units convert directly; volume units require density.
    static func toCanonicalGrams(_ value: Double, unit: QuantityUnit, densityGPerMl: Double? = nil) -> Double? {
        if let mass = unit.massUnit {
            return toGrams(value, unit: mass)
        }
        if let vol = unit.volumeUnit {
            return volumeToGrams(value, unit: vol, densityGPerMl: densityGPerMl)
        }
        return nil
    }

    // MARK: - Nutrition computation

    struct NutritionValues: Equatable {
        let calories: Double
        let carbs: Double
        let protein: Double
        let fat: Double
    }

    /// Compute nutrition from a quantity in any supported unit.
    /// Returns nil if gram conversion fails (volume without density).
    static func computeNutrition(
        quantity: Double,
        unit: QuantityUnit,
        per100g: NutritionValues,
        densityGPerMl: Double? = nil
    ) -> NutritionValues? {
        guard let grams = toCanonicalGrams(quantity, unit: unit, densityGPerMl: densityGPerMl) else {
            return nil
        }

        let factor = grams / 100.0
        return NutritionValues(
            calories: round2(per100g.calories * factor),
            carbs: round2(per100g.carbs * factor),
            protein: round2(per100g.protein * factor),
            fat: round2(per100g.fat * factor)
        )
    }

    /// Round to 2 decimal places.
    static func round2(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
