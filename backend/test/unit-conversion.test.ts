import { describe, expect, it } from 'vitest';

import {
  computeNutrition,
  isMassUnit,
  isValidUnit,
  isVolumeUnit,
  toCanonicalGrams,
  toGrams,
  toMillilitres,
  volumeToGrams
} from '../src/domain/unit-conversion';

describe('unit-conversion', () => {
  describe('type guards', () => {
    it('identifies mass units', () => {
      expect(isMassUnit('g')).toBe(true);
      expect(isMassUnit('oz')).toBe(true);
      expect(isMassUnit('lb')).toBe(true);
      expect(isMassUnit('ml')).toBe(false);
      expect(isMassUnit('cup')).toBe(false);
      expect(isMassUnit('bogus')).toBe(false);
    });

    it('identifies volume units', () => {
      expect(isVolumeUnit('ml')).toBe(true);
      expect(isVolumeUnit('tsp')).toBe(true);
      expect(isVolumeUnit('tbsp')).toBe(true);
      expect(isVolumeUnit('cup')).toBe(true);
      expect(isVolumeUnit('g')).toBe(false);
      expect(isVolumeUnit('bogus')).toBe(false);
    });

    it('validates any supported unit', () => {
      expect(isValidUnit('g')).toBe(true);
      expect(isValidUnit('cup')).toBe(true);
      expect(isValidUnit('litre')).toBe(false);
    });
  });

  describe('toGrams', () => {
    it('converts grams to grams (identity)', () => {
      expect(toGrams(100, 'g')).toBe(100);
    });

    it('converts ounces to grams', () => {
      expect(toGrams(1, 'oz')).toBeCloseTo(28.3495, 3);
      expect(toGrams(4, 'oz')).toBeCloseTo(113.398, 2);
    });

    it('converts pounds to grams', () => {
      expect(toGrams(1, 'lb')).toBeCloseTo(453.592, 2);
      expect(toGrams(0.5, 'lb')).toBeCloseTo(226.796, 2);
    });
  });

  describe('toMillilitres', () => {
    it('converts ml to ml (identity)', () => {
      expect(toMillilitres(250, 'ml')).toBe(250);
    });

    it('converts teaspoons to ml', () => {
      expect(toMillilitres(1, 'tsp')).toBeCloseTo(4.929, 2);
    });

    it('converts tablespoons to ml', () => {
      expect(toMillilitres(1, 'tbsp')).toBeCloseTo(14.787, 2);
      // 1 tbsp ≈ 3 tsp
      expect(toMillilitres(1, 'tbsp')).toBeCloseTo(toMillilitres(3, 'tsp'), 0);
    });

    it('converts cups to ml', () => {
      expect(toMillilitres(1, 'cup')).toBeCloseTo(236.588, 2);
    });
  });

  describe('volumeToGrams', () => {
    it('converts volume to grams with density', () => {
      // Water: density ~1 g/ml → 1 cup ≈ 236.6 g
      expect(volumeToGrams(1, 'cup', 1.0)).toBeCloseTo(236.588, 2);
    });

    it('converts oil volume to grams (density ~0.92)', () => {
      // 1 tbsp oil at 0.92 g/ml → 14.787 * 0.92 ≈ 13.6 g
      expect(volumeToGrams(1, 'tbsp', 0.92)).toBeCloseTo(13.604, 1);
    });

    it('returns null when density is null', () => {
      expect(volumeToGrams(1, 'cup', null)).toBeNull();
    });

    it('returns null when density is undefined', () => {
      expect(volumeToGrams(1, 'cup', undefined)).toBeNull();
    });

    it('returns null when density is zero or negative', () => {
      expect(volumeToGrams(1, 'cup', 0)).toBeNull();
      expect(volumeToGrams(1, 'cup', -1)).toBeNull();
    });
  });

  describe('toCanonicalGrams', () => {
    it('converts mass units without density', () => {
      expect(toCanonicalGrams(100, 'g')).toBe(100);
      expect(toCanonicalGrams(1, 'oz')).toBeCloseTo(28.3495, 3);
    });

    it('converts volume with density', () => {
      expect(toCanonicalGrams(1, 'cup', 0.9)).toBeCloseTo(212.929, 1);
    });

    it('returns null for volume without density', () => {
      expect(toCanonicalGrams(1, 'cup')).toBeNull();
      expect(toCanonicalGrams(1, 'tsp', null)).toBeNull();
    });
  });

  describe('computeNutrition', () => {
    const chickenPer100g = { calories: 165, carbs: 0, protein: 31, fat: 3.6 };

    it('computes nutrition for a gram quantity', () => {
      const result = computeNutrition(200, 'g', chickenPer100g);
      expect(result).toEqual({
        calories: 330,
        carbs: 0,
        protein: 62,
        fat: 7.2
      });
    });

    it('computes nutrition for an oz quantity', () => {
      // 6 oz ≈ 170.097 g → factor 1.70097
      const result = computeNutrition(6, 'oz', chickenPer100g);
      expect(result).not.toBeNull();
      expect(result!.calories).toBeCloseTo(280.66, 1);
      expect(result!.protein).toBeCloseTo(52.73, 1);
    });

    it('computes nutrition for volume with density', () => {
      const oilPer100g = { calories: 884, carbs: 0, protein: 0, fat: 100 };
      // 1 tbsp olive oil at density 0.92 → ~13.6 g → factor 0.136
      const result = computeNutrition(1, 'tbsp', oilPer100g, 0.92);
      expect(result).not.toBeNull();
      expect(result!.calories).toBeCloseTo(120.26, 0);
      expect(result!.fat).toBeCloseTo(13.6, 0);
    });

    it('returns null for volume without density', () => {
      const result = computeNutrition(1, 'cup', chickenPer100g);
      expect(result).toBeNull();
    });

    it('rounds to 2 decimal places', () => {
      // 1 oz of chicken = 28.3495 g → factor 0.283495
      const result = computeNutrition(1, 'oz', chickenPer100g);
      expect(result).not.toBeNull();
      // Check that all values have at most 2 decimal places
      for (const val of Object.values(result!)) {
        const decimalPart = val.toString().split('.')[1];
        expect((decimalPart?.length ?? 0) <= 2).toBe(true);
      }
    });
  });
});
