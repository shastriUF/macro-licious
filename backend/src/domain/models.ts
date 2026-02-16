export type MacroTargets = {
  calories: number;
  carbs: number;
  protein: number;
};

export type User = {
  id: string;
  email: string;
  macroTargets: MacroTargets;
  createdAt: string;
  updatedAt: string;
};

export type MagicLinkChallenge = {
  token: string;
  email: string;
  expiresAt: number;
  used: boolean;
};

export type Ingredient = {
  id: string;
  userId: string;
  name: string;
  brand: string | null;
  barcode: string | null;
  caloriesPer100g: number;
  carbsPer100g: number;
  proteinPer100g: number;
  fatPer100g: number;
  archived: boolean;
  createdAt: string;
  updatedAt: string;
};

export type CreateIngredientInput = {
  name: string;
  brand?: string;
  barcode?: string;
  caloriesPer100g: number;
  carbsPer100g: number;
  proteinPer100g: number;
  fatPer100g: number;
};

export type UpdateIngredientInput = Partial<CreateIngredientInput>;
