import { randomUUID } from 'node:crypto';

import { env } from '../config/env';
import { getSupabaseAdminClient } from '../integrations/supabase';
import type {
  CreateMealLogInput,
  CreateMealLogItemInput,
  MealLog,
  MealLogItem,
  MealType,
  QuantityUnit,
  UpdateMealLogInput
} from './models';

export class MealLogStore {
  private readonly mealLogsById = new Map<string, MealLog>();

  async create(userId: string, input: CreateMealLogInput): Promise<MealLog> {
    if (env.AUTH_PROVIDER === 'supabase') {
      return this.createInSupabase(userId, input);
    }

    const nowIso = new Date().toISOString();
    const mealLogId = randomUUID();

    const mealLog: MealLog = {
      id: mealLogId,
      userId,
      date: input.date,
      mealType: input.mealType,
      notes: this.normalizeNotes(input.notes),
      items: input.items.map((item) => this.mapInputItemToDomain(item, mealLogId, nowIso)),
      createdAt: nowIso,
      updatedAt: nowIso
    };

    this.mealLogsById.set(mealLog.id, mealLog);
    return mealLog;
  }

  async listByUserAndDate(userId: string, date: string): Promise<MealLog[]> {
    if (env.AUTH_PROVIDER === 'supabase') {
      return this.listByUserAndDateInSupabase(userId, date);
    }

    return Array.from(this.mealLogsById.values())
      .filter((mealLog) => mealLog.userId === userId && mealLog.date === date)
      .sort((a, b) => a.createdAt.localeCompare(b.createdAt));
  }

  async update(userId: string, mealLogId: string, input: UpdateMealLogInput): Promise<MealLog | null> {
    if (env.AUTH_PROVIDER === 'supabase') {
      return this.updateInSupabase(userId, mealLogId, input);
    }

    const existing = this.mealLogsById.get(mealLogId);
    if (!existing || existing.userId !== userId) {
      return null;
    }

    const nowIso = new Date().toISOString();
    const updated: MealLog = {
      ...existing,
      date: input.date ?? existing.date,
      mealType: input.mealType ?? existing.mealType,
      notes: input.notes !== undefined ? this.normalizeNotes(input.notes) : existing.notes,
      items:
        input.items !== undefined
          ? input.items.map((item) => this.mapInputItemToDomain(item, mealLogId, nowIso))
          : existing.items,
      updatedAt: nowIso
    };

    this.mealLogsById.set(mealLogId, updated);
    return updated;
  }

  async delete(userId: string, mealLogId: string): Promise<boolean> {
    if (env.AUTH_PROVIDER === 'supabase') {
      const supabase = getSupabaseAdminClient();
      const { data, error } = await supabase
        .from('meal_logs')
        .delete()
        .eq('id', mealLogId)
        .eq('user_id', userId)
        .select('id')
        .maybeSingle();

      if (error) {
        throw new Error(`Failed to delete meal log: ${error.message}`);
      }

      return Boolean(data?.id);
    }

    const existing = this.mealLogsById.get(mealLogId);
    if (!existing || existing.userId !== userId) {
      return false;
    }

    return this.mealLogsById.delete(mealLogId);
  }

  reset(): void {
    this.mealLogsById.clear();
  }

  private async createInSupabase(userId: string, input: CreateMealLogInput): Promise<MealLog> {
    const nowIso = new Date().toISOString();
    const supabase = getSupabaseAdminClient();

    const { data: mealLogRow, error: mealLogError } = await supabase
      .from('meal_logs')
      .insert({
        user_id: userId,
        log_date: input.date,
        meal_type: input.mealType,
        notes: this.normalizeNotes(input.notes),
        created_at: nowIso,
        updated_at: nowIso
      })
      .select('*')
      .single();

    if (mealLogError || !mealLogRow) {
      throw new Error(`Failed to create meal log: ${mealLogError?.message ?? 'Unknown error'}`);
    }

    if (input.items.length > 0) {
      const itemRows = input.items.map((item) => this.mapInputItemToDb(item, mealLogRow.id, nowIso));
      const { error: itemInsertError } = await supabase.from('meal_log_items').insert(itemRows);

      if (itemInsertError) {
        throw new Error(`Failed to create meal log items: ${itemInsertError.message}`);
      }
    }

    const { data: items, error: itemFetchError } = await supabase
      .from('meal_log_items')
      .select('*')
      .eq('meal_log_id', mealLogRow.id)
      .order('created_at', { ascending: true });

    if (itemFetchError || !items) {
      throw new Error(`Failed to fetch meal log items: ${itemFetchError?.message ?? 'Unknown error'}`);
    }

    return this.mapDbMealLogToDomain(mealLogRow, items);
  }

  private async listByUserAndDateInSupabase(userId: string, date: string): Promise<MealLog[]> {
    const supabase = getSupabaseAdminClient();
    const { data: mealLogRows, error: mealLogError } = await supabase
      .from('meal_logs')
      .select('*')
      .eq('user_id', userId)
      .eq('log_date', date)
      .order('created_at', { ascending: true });

    if (mealLogError || !mealLogRows) {
      throw new Error(`Failed to list meal logs: ${mealLogError?.message ?? 'Unknown error'}`);
    }

    if (mealLogRows.length === 0) {
      return [];
    }

    const mealLogIds = mealLogRows.map((row) => row.id);

    const { data: itemRows, error: itemError } = await supabase
      .from('meal_log_items')
      .select('*')
      .in('meal_log_id', mealLogIds)
      .order('created_at', { ascending: true });

    if (itemError || !itemRows) {
      throw new Error(`Failed to list meal log items: ${itemError?.message ?? 'Unknown error'}`);
    }

    const itemsByMealLogId = new Map<string, Array<DbMealLogItemRow>>();
    for (const item of itemRows) {
      const existingItems = itemsByMealLogId.get(item.meal_log_id) ?? [];
      existingItems.push(item);
      itemsByMealLogId.set(item.meal_log_id, existingItems);
    }

    return mealLogRows.map((row) => this.mapDbMealLogToDomain(row, itemsByMealLogId.get(row.id) ?? []));
  }

  private async updateInSupabase(userId: string, mealLogId: string, input: UpdateMealLogInput): Promise<MealLog | null> {
    const updatePayload: Record<string, string | null> = {
      updated_at: new Date().toISOString()
    };

    if (input.date !== undefined) updatePayload.log_date = input.date;
    if (input.mealType !== undefined) updatePayload.meal_type = input.mealType;
    if (input.notes !== undefined) updatePayload.notes = this.normalizeNotes(input.notes);

    const supabase = getSupabaseAdminClient();
    const { data: mealLogRow, error: updateError } = await supabase
      .from('meal_logs')
      .update(updatePayload)
      .eq('id', mealLogId)
      .eq('user_id', userId)
      .select('*')
      .maybeSingle();

    if (updateError) {
      throw new Error(`Failed to update meal log: ${updateError.message}`);
    }

    if (!mealLogRow) {
      return null;
    }

    if (input.items !== undefined) {
      const { error: deleteItemsError } = await supabase.from('meal_log_items').delete().eq('meal_log_id', mealLogId);

      if (deleteItemsError) {
        throw new Error(`Failed to reset meal log items: ${deleteItemsError.message}`);
      }

      if (input.items.length > 0) {
        const nowIso = new Date().toISOString();
        const itemRows = input.items.map((item) => this.mapInputItemToDb(item, mealLogId, nowIso));
        const { error: insertItemsError } = await supabase.from('meal_log_items').insert(itemRows);

        if (insertItemsError) {
          throw new Error(`Failed to update meal log items: ${insertItemsError.message}`);
        }
      }
    }

    const { data: itemRows, error: itemError } = await supabase
      .from('meal_log_items')
      .select('*')
      .eq('meal_log_id', mealLogId)
      .order('created_at', { ascending: true });

    if (itemError || !itemRows) {
      throw new Error(`Failed to fetch meal log items: ${itemError?.message ?? 'Unknown error'}`);
    }

    return this.mapDbMealLogToDomain(mealLogRow, itemRows);
  }

  private mapInputItemToDomain(input: CreateMealLogItemInput, mealLogId: string, nowIso: string): MealLogItem {
    return {
      id: randomUUID(),
      mealLogId,
      ingredientId: input.ingredientId ?? null,
      ingredientName: input.ingredientName.trim(),
      quantityValue: input.quantityValue,
      quantityUnit: input.quantityUnit,
      consumedGrams: input.consumedGrams,
      nutrition: {
        calories: input.nutrition.calories,
        carbs: input.nutrition.carbs,
        protein: input.nutrition.protein,
        fat: input.nutrition.fat
      },
      createdAt: nowIso,
      updatedAt: nowIso
    };
  }

  private mapInputItemToDb(input: CreateMealLogItemInput, mealLogId: string, nowIso: string): DbMealLogItemInsert {
    return {
      meal_log_id: mealLogId,
      ingredient_id: input.ingredientId?.trim() || null,
      ingredient_name: input.ingredientName.trim(),
      quantity_value: input.quantityValue,
      quantity_unit: input.quantityUnit,
      consumed_grams: input.consumedGrams,
      calories: input.nutrition.calories,
      carbs: input.nutrition.carbs,
      protein: input.nutrition.protein,
      fat: input.nutrition.fat,
      created_at: nowIso,
      updated_at: nowIso
    };
  }

  private mapDbMealLogToDomain(mealLogRow: DbMealLogRow, itemRows: Array<DbMealLogItemRow>): MealLog {
    return {
      id: mealLogRow.id,
      userId: mealLogRow.user_id,
      date: mealLogRow.log_date,
      mealType: mealLogRow.meal_type,
      notes: mealLogRow.notes,
      items: itemRows.map((row) => ({
        id: row.id,
        mealLogId: row.meal_log_id,
        ingredientId: row.ingredient_id,
        ingredientName: row.ingredient_name,
        quantityValue: Number(row.quantity_value),
        quantityUnit: row.quantity_unit,
        consumedGrams: Number(row.consumed_grams),
        nutrition: {
          calories: Number(row.calories),
          carbs: Number(row.carbs),
          protein: Number(row.protein),
          fat: Number(row.fat)
        },
        createdAt: row.created_at,
        updatedAt: row.updated_at
      })),
      createdAt: mealLogRow.created_at,
      updatedAt: mealLogRow.updated_at
    };
  }

  private normalizeNotes(notes: string | null | undefined): string | null {
    if (notes == null) {
      return null;
    }

    const trimmed = notes.trim();
    return trimmed.length > 0 ? trimmed : null;
  }
}

type DbMealLogRow = {
  id: string;
  user_id: string;
  log_date: string;
  meal_type: MealType;
  notes: string | null;
  created_at: string;
  updated_at: string;
};

type DbMealLogItemRow = {
  id: string;
  meal_log_id: string;
  ingredient_id: string | null;
  ingredient_name: string;
  quantity_value: number;
  quantity_unit: QuantityUnit;
  consumed_grams: number;
  calories: number;
  carbs: number;
  protein: number;
  fat: number;
  created_at: string;
  updated_at: string;
};

type DbMealLogItemInsert = {
  meal_log_id: string;
  ingredient_id: string | null;
  ingredient_name: string;
  quantity_value: number;
  quantity_unit: QuantityUnit;
  consumed_grams: number;
  calories: number;
  carbs: number;
  protein: number;
  fat: number;
  created_at: string;
  updated_at: string;
};

export const mealLogStore = new MealLogStore();
