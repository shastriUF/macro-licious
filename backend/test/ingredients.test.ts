import { afterEach, describe, expect, it } from 'vitest';

import { buildApp } from '../src/app';
import { authStore } from '../src/domain/auth-store';
import { ingredientStore } from '../src/domain/ingredient-store';

async function createSessionToken(app: ReturnType<typeof buildApp>, email = 'aniruddha@example.com'): Promise<string> {
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

describe('ingredient routes', () => {
  afterEach(() => {
    authStore.reset();
    ingredientStore.reset();
  });

  it('creates and lists ingredients for authenticated user', async () => {
    const app = buildApp();
    const sessionToken = await createSessionToken(app);

    const createResponse = await app.inject({
      method: 'POST',
      url: '/ingredients',
      headers: {
        authorization: `Bearer ${sessionToken}`
      },
      payload: {
        name: 'Chicken Breast',
        caloriesPer100g: 165,
        carbsPer100g: 0,
        proteinPer100g: 31,
        fatPer100g: 3.6
      }
    });

    expect(createResponse.statusCode).toBe(201);

    const createBody = createResponse.json() as {
      ingredient: {
        id: string;
        name: string;
      };
    };

    expect(createBody.ingredient.name).toBe('Chicken Breast');

    const listResponse = await app.inject({
      method: 'GET',
      url: '/ingredients',
      headers: {
        authorization: `Bearer ${sessionToken}`
      }
    });

    expect(listResponse.statusCode).toBe(200);

    const listBody = listResponse.json() as {
      ingredients: Array<{ id: string; name: string }>;
    };

    expect(listBody.ingredients).toHaveLength(1);
    expect(listBody.ingredients[0]?.id).toBe(createBody.ingredient.id);

    await app.close();
  });

  it('supports get/update/archive flow', async () => {
    const app = buildApp();
    const sessionToken = await createSessionToken(app);

    const createResponse = await app.inject({
      method: 'POST',
      url: '/ingredients',
      headers: {
        authorization: `Bearer ${sessionToken}`
      },
      payload: {
        name: 'Olive Oil',
        brand: 'Store Brand',
        caloriesPer100g: 884,
        carbsPer100g: 0,
        proteinPer100g: 0,
        fatPer100g: 100
      }
    });

    const ingredientId = (createResponse.json() as { ingredient: { id: string } }).ingredient.id;

    const getResponse = await app.inject({
      method: 'GET',
      url: `/ingredients/${ingredientId}`,
      headers: {
        authorization: `Bearer ${sessionToken}`
      }
    });

    expect(getResponse.statusCode).toBe(200);

    const patchResponse = await app.inject({
      method: 'PATCH',
      url: `/ingredients/${ingredientId}`,
      headers: {
        authorization: `Bearer ${sessionToken}`
      },
      payload: {
        brand: 'Premium Store Brand',
        fatPer100g: 99.5
      }
    });

    expect(patchResponse.statusCode).toBe(200);

    const patchBody = patchResponse.json() as {
      ingredient: {
        brand: string | null;
        fatPer100g: number;
      };
    };

    expect(patchBody.ingredient.brand).toBe('Premium Store Brand');
    expect(patchBody.ingredient.fatPer100g).toBe(99.5);

    const archiveResponse = await app.inject({
      method: 'DELETE',
      url: `/ingredients/${ingredientId}`,
      headers: {
        authorization: `Bearer ${sessionToken}`
      }
    });

    expect(archiveResponse.statusCode).toBe(200);

    const listResponse = await app.inject({
      method: 'GET',
      url: '/ingredients',
      headers: {
        authorization: `Bearer ${sessionToken}`
      }
    });

    const listBody = listResponse.json() as { ingredients: unknown[] };
    expect(listBody.ingredients).toHaveLength(0);

    const listArchivedResponse = await app.inject({
      method: 'GET',
      url: '/ingredients?includeArchived=true',
      headers: {
        authorization: `Bearer ${sessionToken}`
      }
    });

    const listArchivedBody = listArchivedResponse.json() as {
      ingredients: Array<{ archived: boolean }>;
    };

    expect(listArchivedBody.ingredients).toHaveLength(1);
    expect(listArchivedBody.ingredients[0]?.archived).toBe(true);

    await app.close();
  });

  it('enforces authentication and ownership', async () => {
    const app = buildApp();
    const sessionTokenA = await createSessionToken(app, 'a@example.com');
    const sessionTokenB = await createSessionToken(app, 'b@example.com');

    const createResponse = await app.inject({
      method: 'POST',
      url: '/ingredients',
      headers: {
        authorization: `Bearer ${sessionTokenA}`
      },
      payload: {
        name: 'Avocado',
        caloriesPer100g: 160,
        carbsPer100g: 9,
        proteinPer100g: 2,
        fatPer100g: 15
      }
    });

    const ingredientId = (createResponse.json() as { ingredient: { id: string } }).ingredient.id;

    const unauthorizedResponse = await app.inject({
      method: 'GET',
      url: '/ingredients'
    });

    expect(unauthorizedResponse.statusCode).toBe(401);

    const wrongOwnerResponse = await app.inject({
      method: 'GET',
      url: `/ingredients/${ingredientId}`,
      headers: {
        authorization: `Bearer ${sessionTokenB}`
      }
    });

    expect(wrongOwnerResponse.statusCode).toBe(404);

    await app.close();
  });
});
