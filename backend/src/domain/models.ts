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
  densityGPerMl: number | null;
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
  densityGPerMl?: number;
  caloriesPer100g: number;
  carbsPer100g: number;
  proteinPer100g: number;
  fatPer100g: number;
};

export type UpdateIngredientInput = Partial<CreateIngredientInput>;

export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack';

export type QuantityUnit = 'g' | 'oz' | 'lb' | 'ml' | 'tsp' | 'tbsp' | 'cup';

export type MealLogItemNutrition = {
  calories: number;
  carbs: number;
  protein: number;
  fat: number;
};

export type MealLogItem = {
  id: string;
  mealLogId: string;
  ingredientId: string | null;
  ingredientName: string;
  quantityValue: number;
  quantityUnit: QuantityUnit;
  consumedGrams: number;
  nutrition: MealLogItemNutrition;
  createdAt: string;
  updatedAt: string;
};

export type MealLog = {
  id: string;
  userId: string;
  date: string;
  mealType: MealType;
  notes: string | null;
  items: MealLogItem[];
  createdAt: string;
  updatedAt: string;
};

export type CreateMealLogItemInput = {
  ingredientId?: string;
  ingredientName: string;
  quantityValue: number;
  quantityUnit: QuantityUnit;
  consumedGrams: number;
  nutrition: MealLogItemNutrition;
};

export type CreateMealLogInput = {
  date: string;
  mealType: MealType;
  notes?: string;
  items: CreateMealLogItemInput[];
};

export type UpdateMealLogInput = {
  date?: string;
  mealType?: MealType;
  notes?: string | null;
  items?: CreateMealLogItemInput[];
};
