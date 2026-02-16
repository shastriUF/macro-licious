import { afterEach, describe, expect, it } from 'vitest';

import { buildApp } from '../src/app';
import { authStore } from '../src/domain/auth-store';

describe('auth and profile routes', () => {
  afterEach(() => {
    authStore.reset();
  });

  it('supports magic-link sign-in and profile retrieval', async () => {
    const app = buildApp();

    const requestLinkResponse = await app.inject({
      method: 'POST',
      url: '/auth/magic-link/request',
      payload: {
        email: 'aniruddha@example.com'
      }
    });

    expect(requestLinkResponse.statusCode).toBe(200);

    const requestLinkBody = requestLinkResponse.json() as {
      token: string;
      expiresAt: string;
      message: string;
    };

    expect(requestLinkBody.message).toBe('Magic link requested');
    expect(requestLinkBody.token.length).toBeGreaterThan(20);
    expect(new Date(requestLinkBody.expiresAt).toISOString()).toBe(requestLinkBody.expiresAt);

    const verifyResponse = await app.inject({
      method: 'POST',
      url: '/auth/magic-link/verify',
      payload: {
        token: requestLinkBody.token
      }
    });

    expect(verifyResponse.statusCode).toBe(200);

    const verifyBody = verifyResponse.json() as {
      sessionToken: string;
      user: {
        id: string;
        email: string;
        macroTargets: {
          calories: number;
          carbs: number;
          protein: number;
        };
      };
    };

    expect(verifyBody.user.email).toBe('aniruddha@example.com');

    const meResponse = await app.inject({
      method: 'GET',
      url: '/me',
      headers: {
        authorization: `Bearer ${verifyBody.sessionToken}`
      }
    });

    expect(meResponse.statusCode).toBe(200);
    const meBody = meResponse.json() as {
      user: {
        id: string;
      };
    };
    expect(meBody.user.id).toBe(verifyBody.user.id);

    await app.close();
  });

  it('rejects invalid or reused magic-link token', async () => {
    const app = buildApp();

    const invalidResponse = await app.inject({
      method: 'POST',
      url: '/auth/magic-link/verify',
      payload: {
        token: 'invalid-token-value-long-enough-for-validation'
      }
    });

    expect(invalidResponse.statusCode).toBe(401);

    const requestLinkResponse = await app.inject({
      method: 'POST',
      url: '/auth/magic-link/request',
      payload: {
        email: 'aniruddha@example.com'
      }
    });

    const requestLinkBody = requestLinkResponse.json() as { token: string };

    const firstVerifyResponse = await app.inject({
      method: 'POST',
      url: '/auth/magic-link/verify',
      payload: {
        token: requestLinkBody.token
      }
    });

    expect(firstVerifyResponse.statusCode).toBe(200);

    const secondVerifyResponse = await app.inject({
      method: 'POST',
      url: '/auth/magic-link/verify',
      payload: {
        token: requestLinkBody.token
      }
    });

    expect(secondVerifyResponse.statusCode).toBe(401);

    await app.close();
  });

  it('updates macro targets for an authenticated user', async () => {
    const app = buildApp();

    const requestLinkResponse = await app.inject({
      method: 'POST',
      url: '/auth/magic-link/request',
      payload: {
        email: 'aniruddha@example.com'
      }
    });

    const requestLinkBody = requestLinkResponse.json() as { token: string };

    const verifyResponse = await app.inject({
      method: 'POST',
      url: '/auth/magic-link/verify',
      payload: {
        token: requestLinkBody.token
      }
    });

    const verifyBody = verifyResponse.json() as { sessionToken: string };

    const patchResponse = await app.inject({
      method: 'PATCH',
      url: '/me/macro-targets',
      headers: {
        authorization: `Bearer ${verifyBody.sessionToken}`
      },
      payload: {
        calories: 2300,
        carbs: 280,
        protein: 145
      }
    });

    expect(patchResponse.statusCode).toBe(200);

    const patchBody = patchResponse.json() as {
      user: {
        macroTargets: {
          calories: number;
          carbs: number;
          protein: number;
        };
      };
    };

    expect(patchBody.user.macroTargets).toEqual({
      calories: 2300,
      carbs: 280,
      protein: 145
    });

    const unauthorizedResponse = await app.inject({
      method: 'GET',
      url: '/me'
    });

    expect(unauthorizedResponse.statusCode).toBe(401);

    await app.close();
  });
});
