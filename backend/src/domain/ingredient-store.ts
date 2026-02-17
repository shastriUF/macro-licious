import { randomUUID } from 'node:crypto';

import { env } from '../config/env';
import { getSupabaseAdminClient } from '../integrations/supabase';
import type { CreateIngredientInput, Ingredient, UpdateIngredientInput } from './models';

export class IngredientStore {
  private readonly ingredientsById = new Map<string, Ingredient>();

  async create(userId: string, input: CreateIngredientInput): Promise<Ingredient> {
    if (env.AUTH_PROVIDER === 'supabase') {
      const nowIso = new Date().toISOString();
      const supabase = getSupabaseAdminClient();
      const { data, error } = await supabase
        .from('ingredients')
        .insert({
          user_id: userId,
          name: input.name.trim(),
          brand: input.brand?.trim() || null,
          barcode: input.barcode?.trim() || null,
          calories_per_100g: input.caloriesPer100g,
          carbs_per_100g: input.carbsPer100g,
          protein_per_100g: input.proteinPer100g,
          fat_per_100g: input.fatPer100g,
          archived: false,
          created_at: nowIso,
          updated_at: nowIso
        })
        .select('*')
        .single();

      if (error || !data) {
        throw new Error(`Failed to create ingredient: ${error?.message ?? 'Unknown error'}`);
      }

      return this.mapDbIngredientToDomain(data);
    }

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

  async listByUser(userId: string, includeArchived = false): Promise<Ingredient[]> {
    if (env.AUTH_PROVIDER === 'supabase') {
      const supabase = getSupabaseAdminClient();
      let query = supabase.from('ingredients').select('*').eq('user_id', userId).order('name', { ascending: true });

      if (!includeArchived) {
        query = query.eq('archived', false);
      }

      const { data, error } = await query;
      if (error || !data) {
        throw new Error(`Failed to list ingredients: ${error?.message ?? 'Unknown error'}`);
      }

      return data.map((row) => this.mapDbIngredientToDomain(row));
    }

    return Array.from(this.ingredientsById.values())
      .filter((ingredient) => ingredient.userId === userId)
      .filter((ingredient) => includeArchived || !ingredient.archived)
      .sort((a, b) => a.name.localeCompare(b.name));
  }

  async getById(userId: string, ingredientId: string): Promise<Ingredient | null> {
    if (env.AUTH_PROVIDER === 'supabase') {
      const supabase = getSupabaseAdminClient();
      const { data, error } = await supabase
        .from('ingredients')
        .select('*')
        .eq('id', ingredientId)
        .eq('user_id', userId)
        .maybeSingle();

      if (error) {
        throw new Error(`Failed to get ingredient: ${error.message}`);
      }

      if (!data) {
        return null;
      }

      return this.mapDbIngredientToDomain(data);
    }

    const ingredient = this.ingredientsById.get(ingredientId);
    if (!ingredient || ingredient.userId !== userId) {
      return null;
    }

    return ingredient;
  }

  async update(userId: string, ingredientId: string, input: UpdateIngredientInput): Promise<Ingredient | null> {
    if (env.AUTH_PROVIDER === 'supabase') {
      const updatePayload: Record<string, string | number | boolean | null> = {
        updated_at: new Date().toISOString()
      };

      if (input.name !== undefined) updatePayload.name = input.name.trim();
      if (input.brand !== undefined) updatePayload.brand = input.brand.trim() || null;
      if (input.barcode !== undefined) updatePayload.barcode = input.barcode.trim() || null;
      if (input.caloriesPer100g !== undefined) updatePayload.calories_per_100g = input.caloriesPer100g;
      if (input.carbsPer100g !== undefined) updatePayload.carbs_per_100g = input.carbsPer100g;
      if (input.proteinPer100g !== undefined) updatePayload.protein_per_100g = input.proteinPer100g;
      if (input.fatPer100g !== undefined) updatePayload.fat_per_100g = input.fatPer100g;

      const supabase = getSupabaseAdminClient();
      const { data, error } = await supabase
        .from('ingredients')
        .update(updatePayload)
        .eq('id', ingredientId)
        .eq('user_id', userId)
        .select('*')
        .maybeSingle();

      if (error) {
        throw new Error(`Failed to update ingredient: ${error.message}`);
      }

      if (!data) {
        return null;
      }

      return this.mapDbIngredientToDomain(data);
    }

    const existingIngredient = await this.getById(userId, ingredientId);
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

  async archive(userId: string, ingredientId: string): Promise<Ingredient | null> {
    if (env.AUTH_PROVIDER === 'supabase') {
      const supabase = getSupabaseAdminClient();
      const { data, error } = await supabase
        .from('ingredients')
        .update({
          archived: true,
          updated_at: new Date().toISOString()
        })
        .eq('id', ingredientId)
        .eq('user_id', userId)
        .select('*')
        .maybeSingle();

      if (error) {
        throw new Error(`Failed to archive ingredient: ${error.message}`);
      }

      if (!data) {
        return null;
      }

      return this.mapDbIngredientToDomain(data);
    }

    const existingIngredient = await this.getById(userId, ingredientId);
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

  private mapDbIngredientToDomain(row: {
    id: string;
    user_id: string;
    name: string;
    brand: string | null;
    barcode: string | null;
    calories_per_100g: number;
    carbs_per_100g: number;
    protein_per_100g: number;
    fat_per_100g: number;
    archived: boolean;
    created_at: string;
    updated_at: string;
  }): Ingredient {
    return {
      id: row.id,
      userId: row.user_id,
      name: row.name,
      brand: row.brand,
      barcode: row.barcode,
      caloriesPer100g: Number(row.calories_per_100g),
      carbsPer100g: Number(row.carbs_per_100g),
      proteinPer100g: Number(row.protein_per_100g),
      fatPer100g: Number(row.fat_per_100g),
      archived: row.archived,
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }
}

export const ingredientStore = new IngredientStore();
