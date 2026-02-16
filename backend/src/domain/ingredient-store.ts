import { randomUUID } from 'node:crypto';

import type { CreateIngredientInput, Ingredient, UpdateIngredientInput } from './models';

export class IngredientStore {
  private readonly ingredientsById = new Map<string, Ingredient>();

  create(userId: string, input: CreateIngredientInput): Ingredient {
    const nowIso = new Date().toISOString();

    const ingredient: Ingredient = {
      id: randomUUID(),
      userId,
      name: input.name.trim(),
      brand: input.brand?.trim() || null,
      barcode: input.barcode?.trim() || null,
      caloriesPer100g: input.caloriesPer100g,
      carbsPer100g: input.carbsPer100g,
      proteinPer100g: input.proteinPer100g,
      fatPer100g: input.fatPer100g,
      archived: false,
      createdAt: nowIso,
      updatedAt: nowIso
    };

    this.ingredientsById.set(ingredient.id, ingredient);

    return ingredient;
  }

  listByUser(userId: string, includeArchived = false): Ingredient[] {
    return Array.from(this.ingredientsById.values())
      .filter((ingredient) => ingredient.userId === userId)
      .filter((ingredient) => includeArchived || !ingredient.archived)
      .sort((a, b) => a.name.localeCompare(b.name));
  }

  getById(userId: string, ingredientId: string): Ingredient | null {
    const ingredient = this.ingredientsById.get(ingredientId);
    if (!ingredient || ingredient.userId !== userId) {
      return null;
    }

    return ingredient;
  }

  update(userId: string, ingredientId: string, input: UpdateIngredientInput): Ingredient | null {
    const existingIngredient = this.getById(userId, ingredientId);
    if (!existingIngredient) {
      return null;
    }

    const updatedIngredient: Ingredient = {
      ...existingIngredient,
      name: input.name !== undefined ? input.name.trim() : existingIngredient.name,
      brand: input.brand !== undefined ? input.brand.trim() || null : existingIngredient.brand,
      barcode: input.barcode !== undefined ? input.barcode.trim() || null : existingIngredient.barcode,
      caloriesPer100g: input.caloriesPer100g ?? existingIngredient.caloriesPer100g,
      carbsPer100g: input.carbsPer100g ?? existingIngredient.carbsPer100g,
      proteinPer100g: input.proteinPer100g ?? existingIngredient.proteinPer100g,
      fatPer100g: input.fatPer100g ?? existingIngredient.fatPer100g,
      updatedAt: new Date().toISOString()
    };

    this.ingredientsById.set(ingredientId, updatedIngredient);

    return updatedIngredient;
  }

  archive(userId: string, ingredientId: string): Ingredient | null {
    const existingIngredient = this.getById(userId, ingredientId);
    if (!existingIngredient) {
      return null;
    }

    const archivedIngredient: Ingredient = {
      ...existingIngredient,
      archived: true,
      updatedAt: new Date().toISOString()
    };

    this.ingredientsById.set(ingredientId, archivedIngredient);

    return archivedIngredient;
  }

  reset(): void {
    this.ingredientsById.clear();
  }
}

export const ingredientStore = new IngredientStore();
