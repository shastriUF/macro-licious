import { afterEach, describe, expect, it } from 'vitest';

import { buildApp } from '../src/app';
import { authStore } from '../src/domain/auth-store';
import { ingredientStore } from '../src/domain/ingredient-store';
import { mealLogStore } from '../src/domain/meal-log-store';

async function createSessionToken(app: ReturnType<typeof buildApp>, email: string): Promise<string> {
  const requestLinkResponse = await app.inject({
    method: 'POST',
    url: '/auth/magic-link/request',
    payload: { email }
  });

  const requestLinkBody = requestLinkResponse.json() as { token: string };

  const verifyResponse = await app.inject({
    method: 'POST',
    url: '/auth/magic-link/verify',
    payload: { token: requestLinkBody.token }
  });

  const verifyBody = verifyResponse.json() as { sessionToken: string };
  return verifyBody.sessionToken;
}

describe('meal log routes', () => {
  afterEach(() => {
    authStore.reset();
    ingredientStore.reset();
    mealLogStore.reset();
  });

  it('creates and lists meal logs with daily totals', async () => {
    const app = buildApp();
    const sessionToken = await createSessionToken(app, 'meal-log@example.com');

    const createResponse = await app.inject({
      method: 'POST',
      url: '/meal-logs',
      headers: {
        authorization: `Bearer ${sessionToken}`
      },
      payload: {
        date: '2026-03-29',
        mealType: 'breakfast',
        notes: 'Post workout meal',
        items: [
          {
            ingredientName: 'Oats',
            quantityValue: 50,
            quantityUnit: 'g',
            consumedGrams: 50,
            nutrition: {
              calories: 194.5,
              carbs: 33.15,
              protein: 8.45,
              fat: 3.45
            }
          },
          {
            ingredientName: 'Milk',
            quantityValue: 120,
            quantityUnit: 'ml',
            consumedGrams: 120,
            nutrition: {
              calories: 73.2,
              carbs: 5.76,
              protein: 3.96,
              fat: 3.96
            }
          }
        ]
      }
    });

    expect(createResponse.statusCode).toBe(201);

    const listResponse = await app.inject({
      method: 'GET',
      url: '/meal-logs?date=2026-03-29',
      headers: {
        authorization: `Bearer ${sessionToken}`
      }
    });

    expect(listResponse.statusCode).toBe(200);
    const listBody = listResponse.json() as {
      mealLogs: Array<{
        mealType: string;
        items: Array<{ ingredientName: string }>;
      }>;
      totals: {
        calories: number;
        carbs: number;
        protein: number;
        fat: number;
      };
    };

    expect(listBody.mealLogs).toHaveLength(1);
    expect(listBody.mealLogs[0]?.mealType).toBe('breakfast');
    expect(listBody.mealLogs[0]?.items).toHaveLength(2);
    expect(listBody.mealLogs[0]?.items[0]?.ingredientName).toBe('Oats');
    expect(listBody.totals.calories).toBeCloseTo(267.7, 2);
    expect(listBody.totals.carbs).toBeCloseTo(38.91, 2);
    expect(listBody.totals.protein).toBeCloseTo(12.41, 2);
    expect(listBody.totals.fat).toBeCloseTo(7.41, 2);

    await app.close();
  });

  it('updates and deletes meal logs', async () => {
    const app = buildApp();
    const sessionToken = await createSessionToken(app, 'meal-log-update@example.com');

    const createResponse = await app.inject({
      method: 'POST',
      url: '/meal-logs',
      headers: {
        authorization: `Bearer ${sessionToken}`
      },
      payload: {
        date: '2026-03-29',
        mealType: 'lunch',
        items: [
          {
            ingredientName: 'Chicken',
            quantityValue: 180,
            quantityUnit: 'g',
            consumedGrams: 180,
            nutrition: {
              calories: 297,
              carbs: 0,
              protein: 55.8,
              fat: 6.48
            }
          }
        ]
      }
    });

    const createdMealLogId = (createResponse.json() as { mealLog: { id: string } }).mealLog.id;

    const updateResponse = await app.inject({
      method: 'PATCH',
      url: `/meal-logs/${createdMealLogId}`,
      headers: {
        authorization: `Bearer ${sessionToken}`
      },
      payload: {
        mealType: 'dinner',
        notes: 'Updated meal notes',
        items: [
          {
            ingredientName: 'Eggs',
            quantityValue: 2,
            quantityUnit: 'oz',
            consumedGrams: 56.7,
            nutrition: {
              calories: 81.7,
              carbs: 0.62,
              protein: 6.99,
              fat: 5.49
            }
          }
        ]
      }
    });

    expect(updateResponse.statusCode).toBe(200);

    const updateBody = updateResponse.json() as {
      mealLog: {
        mealType: string;
        notes: string | null;
        items: Array<{ ingredientName: string }>;
      };
    };

    expect(updateBody.mealLog.mealType).toBe('dinner');
    expect(updateBody.mealLog.notes).toBe('Updated meal notes');
    expect(updateBody.mealLog.items).toHaveLength(1);
    expect(updateBody.mealLog.items[0]?.ingredientName).toBe('Eggs');

    const deleteResponse = await app.inject({
      method: 'DELETE',
      url: `/meal-logs/${createdMealLogId}`,
      headers: {
        authorization: `Bearer ${sessionToken}`
      }
    });

    expect(deleteResponse.statusCode).toBe(204);

    const listResponse = await app.inject({
      method: 'GET',
      url: '/meal-logs?date=2026-03-29',
      headers: {
        authorization: `Bearer ${sessionToken}`
      }
    });

    const listBody = listResponse.json() as { mealLogs: unknown[] };
    expect(listBody.mealLogs).toHaveLength(0);

    await app.close();
  });

  it('enforces authentication and ownership for meal log mutations', async () => {
    const app = buildApp();
    const sessionTokenA = await createSessionToken(app, 'meal-owner-a@example.com');
    const sessionTokenB = await createSessionToken(app, 'meal-owner-b@example.com');

    const createResponse = await app.inject({
      method: 'POST',
      url: '/meal-logs',
      headers: {
        authorization: `Bearer ${sessionTokenA}`
      },
      payload: {
        date: '2026-03-29',
        mealType: 'snack',
        items: [
          {
            ingredientName: 'Almonds',
            quantityValue: 30,
            quantityUnit: 'g',
            consumedGrams: 30,
            nutrition: {
              calories: 173.7,
              carbs: 6.45,
              protein: 6.36,
              fat: 14.97
            }
          }
        ]
      }
    });

    const mealLogId = (createResponse.json() as { mealLog: { id: string } }).mealLog.id;

    const unauthorizedListResponse = await app.inject({
      method: 'GET',
      url: '/meal-logs?date=2026-03-29'
    });

    expect(unauthorizedListResponse.statusCode).toBe(401);

    const wrongOwnerPatchResponse = await app.inject({
      method: 'PATCH',
      url: `/meal-logs/${mealLogId}`,
      headers: {
        authorization: `Bearer ${sessionTokenB}`
      },
      payload: {
        notes: 'Should not update'
      }
    });

    expect(wrongOwnerPatchResponse.statusCode).toBe(404);

    const wrongOwnerDeleteResponse = await app.inject({
      method: 'DELETE',
      url: `/meal-logs/${mealLogId}`,
      headers: {
        authorization: `Bearer ${sessionTokenB}`
      }
    });

    expect(wrongOwnerDeleteResponse.statusCode).toBe(404);

    await app.close();
  });
});
