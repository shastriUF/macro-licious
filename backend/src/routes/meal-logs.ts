import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

import { extractBearerToken } from '../auth/session';
import { authStore } from '../domain/auth-store';
import { mealLogStore } from '../domain/meal-log-store';
import type { MealLog } from '../domain/models';

const datePattern = /^\d{4}-\d{2}-\d{2}$/;

const mealTypeSchema = z.enum(['breakfast', 'lunch', 'dinner', 'snack']);
const quantityUnitSchema = z.enum(['g', 'oz', 'lb', 'ml', 'tsp', 'tbsp', 'cup', 'count']);

const mealLogItemSchema = z.object({
  ingredientId: z.string().min(1).optional(),
  ingredientName: z.string().min(1),
  quantityValue: z.number().positive(),
  quantityUnit: quantityUnitSchema,
  consumedGrams: z.number().positive(),
  nutrition: z.object({
    calories: z.number().nonnegative(),
    carbs: z.number().nonnegative(),
    protein: z.number().nonnegative(),
    fat: z.number().nonnegative()
  })
});

const createMealLogSchema = z.object({
  date: z.string().regex(datePattern, 'Date must use YYYY-MM-DD format'),
  mealType: mealTypeSchema,
  notes: z.string().optional(),
  items: z.array(mealLogItemSchema).min(1)
});

const updateMealLogSchema = z
  .object({
    date: z.string().regex(datePattern, 'Date must use YYYY-MM-DD format').optional(),
    mealType: mealTypeSchema.optional(),
    notes: z.string().nullable().optional(),
    items: z.array(mealLogItemSchema).optional()
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: 'No update fields provided'
  });

export const mealLogRoute: FastifyPluginAsync = async (app) => {
  app.post('/meal-logs', async (request, reply) => {
    const sessionToken = extractBearerToken(request);
    if (!sessionToken) {
      return reply.status(401).send({ error: 'Missing bearer token' });
    }

    const user = await authStore.getUserFromSession(sessionToken);
    if (!user) {
      return reply.status(401).send({ error: 'Invalid session token' });
    }

    const parsedBody = createMealLogSchema.safeParse(request.body);
    if (!parsedBody.success) {
      return reply.status(400).send({
        error: 'Invalid request payload',
        details: parsedBody.error.flatten()
      });
    }

    try {
      const mealLog = await mealLogStore.create(user.id, parsedBody.data);
      return reply.status(201).send({ mealLog });
    } catch (error) {
      app.log.error({ error }, 'Failed to create meal log');
      return reply.status(500).send({ error: 'Failed to create meal log' });
    }
  });

  app.get('/meal-logs', async (request, reply) => {
    const sessionToken = extractBearerToken(request);
    if (!sessionToken) {
      return reply.status(401).send({ error: 'Missing bearer token' });
    }

    const user = await authStore.getUserFromSession(sessionToken);
    if (!user) {
      return reply.status(401).send({ error: 'Invalid session token' });
    }

    const queryParse = z
      .object({
        date: z.string().regex(datePattern, 'Date must use YYYY-MM-DD format')
      })
      .safeParse(request.query ?? {});

    if (!queryParse.success) {
      return reply.status(400).send({
        error: 'Invalid request payload',
        details: queryParse.error.flatten()
      });
    }

    try {
      const mealLogs = await mealLogStore.listByUserAndDate(user.id, queryParse.data.date);
      const totals = computeDailyTotals(mealLogs);
      return reply.send({
        date: queryParse.data.date,
        mealLogs,
        totals
      });
    } catch (error) {
      app.log.error({ error }, 'Failed to list meal logs');
      return reply.status(500).send({ error: 'Failed to list meal logs' });
    }
  });

  app.patch('/meal-logs/:mealLogId', async (request, reply) => {
    const sessionToken = extractBearerToken(request);
    if (!sessionToken) {
      return reply.status(401).send({ error: 'Missing bearer token' });
    }

    const user = await authStore.getUserFromSession(sessionToken);
    if (!user) {
      return reply.status(401).send({ error: 'Invalid session token' });
    }

    const params = z.object({ mealLogId: z.string().min(1) }).parse(request.params);

    const parsedBody = updateMealLogSchema.safeParse(request.body);
    if (!parsedBody.success) {
      return reply.status(400).send({
        error: 'Invalid request payload',
        details: parsedBody.error.flatten()
      });
    }

    try {
      const mealLog = await mealLogStore.update(user.id, params.mealLogId, parsedBody.data);
      if (!mealLog) {
        return reply.status(404).send({ error: 'Meal log not found' });
      }

      return reply.send({ mealLog });
    } catch (error) {
      app.log.error({ error }, 'Failed to update meal log');
      return reply.status(500).send({ error: 'Failed to update meal log' });
    }
  });

  app.delete('/meal-logs/:mealLogId', async (request, reply) => {
    const sessionToken = extractBearerToken(request);
    if (!sessionToken) {
      return reply.status(401).send({ error: 'Missing bearer token' });
    }

    const user = await authStore.getUserFromSession(sessionToken);
    if (!user) {
      return reply.status(401).send({ error: 'Invalid session token' });
    }

    const params = z.object({ mealLogId: z.string().min(1) }).parse(request.params);

    try {
      const deleted = await mealLogStore.delete(user.id, params.mealLogId);
      if (!deleted) {
        return reply.status(404).send({ error: 'Meal log not found' });
      }

      return reply.status(204).send();
    } catch (error) {
      app.log.error({ error }, 'Failed to delete meal log');
      return reply.status(500).send({ error: 'Failed to delete meal log' });
    }
  });
};

function computeDailyTotals(mealLogs: MealLog[]): {
  calories: number;
  carbs: number;
  protein: number;
  fat: number;
} {
  let calories = 0;
  let carbs = 0;
  let protein = 0;
  let fat = 0;

  for (const mealLog of mealLogs) {
    for (const item of mealLog.items) {
      calories += item.nutrition.calories;
      carbs += item.nutrition.carbs;
      protein += item.nutrition.protein;
      fat += item.nutrition.fat;
    }
  }

  return {
    calories: round2(calories),
    carbs: round2(carbs),
    protein: round2(protein),
    fat: round2(fat)
  };
}

function round2(value: number): number {
  return Math.round(value * 100) / 100;
}
