/**
 * Unit Conversion Engine
 *
 * Canonical storage units:
 *   - mass: grams (g)
 *   - volume: millilitres (ml)
 *
 * Supported input units: g, oz, lb, ml, tsp, tbsp, cup
 *
 * Volume-to-mass conversion requires a density value (g/ml) for the ingredient.
 * If density is not available, volume quantities stay in ml and cannot be
 * converted to grams.
 */

// ─── Mass unit identifiers ───────────────────────────────────────────
export type MassUnit = 'g' | 'oz' | 'lb';

// ─── Volume unit identifiers ─────────────────────────────────────────
export type VolumeUnit = 'ml' | 'tsp' | 'tbsp' | 'cup';

// ─── Union of all supported units ────────────────────────────────────
export type QuantityUnit = MassUnit | VolumeUnit;

// ─── Fixed conversion factors (NIST / USDA standard) ─────────────────
export const MASS_TO_GRAMS: Record<MassUnit, number> = {
  g: 1,
  oz: 28.3495,
  lb: 453.592
};

export const VOLUME_TO_ML: Record<VolumeUnit, number> = {
  ml: 1,
  tsp: 4.92892,
  tbsp: 14.7868,
  cup: 236.588
};

// ─── Helpers ─────────────────────────────────────────────────────────

const ALL_MASS_UNITS = new Set<string>(Object.keys(MASS_TO_GRAMS));
const ALL_VOLUME_UNITS = new Set<string>(Object.keys(VOLUME_TO_ML));

export function isMassUnit(unit: string): unit is MassUnit {
  return ALL_MASS_UNITS.has(unit);
}

export function isVolumeUnit(unit: string): unit is VolumeUnit {
  return ALL_VOLUME_UNITS.has(unit);
}

export function isValidUnit(unit: string): unit is QuantityUnit {
  return isMassUnit(unit) || isVolumeUnit(unit);
}

// ─── Core conversion functions ───────────────────────────────────────

/** Convert any mass unit to canonical grams. */
export function toGrams(value: number, unit: MassUnit): number {
  return value * MASS_TO_GRAMS[unit];
}

/** Convert any volume unit to canonical millilitres. */
export function toMillilitres(value: number, unit: VolumeUnit): number {
  return value * VOLUME_TO_ML[unit];
}

/**
 * Convert a volume quantity to grams using an ingredient's density (g/ml).
 * Returns null if density is not provided.
 */
export function volumeToGrams(
  value: number,
  unit: VolumeUnit,
  densityGPerMl: number | null | undefined
): number | null {
  if (densityGPerMl == null || densityGPerMl <= 0) {
    return null;
  }
  const ml = toMillilitres(value, unit);
  return ml * densityGPerMl;
}

/**
 * Convert any supported unit to grams.
 * - Mass units: direct conversion.
 * - Volume units: requires density; returns null if unavailable.
 */
export function toCanonicalGrams(
  value: number,
  unit: QuantityUnit,
  densityGPerMl?: number | null
): number | null {
  if (isMassUnit(unit)) {
    return toGrams(value, unit);
  }
  return volumeToGrams(value, unit, densityGPerMl);
}

/**
 * Compute nutrition values from a quantity in an arbitrary unit.
 * nutritionPer100g values are multiplied by (grams / 100).
 * Returns null if gram conversion fails (volume without density).
 */
export function computeNutrition(
  quantity: number,
  unit: QuantityUnit,
  nutritionPer100g: { calories: number; carbs: number; protein: number; fat: number },
  densityGPerMl?: number | null
): { calories: number; carbs: number; protein: number; fat: number } | null {
  const grams = toCanonicalGrams(quantity, unit, densityGPerMl);
  if (grams == null) {
    return null;
  }

  const factor = grams / 100;
  return {
    calories: round2(nutritionPer100g.calories * factor),
    carbs: round2(nutritionPer100g.carbs * factor),
    protein: round2(nutritionPer100g.protein * factor),
    fat: round2(nutritionPer100g.fat * factor)
  };
}

/** Round to 2 decimal places for nutrition display. */
function round2(value: number): number {
  return Math.round(value * 100) / 100;
}
