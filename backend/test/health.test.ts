import { describe, expect, it } from 'vitest';

import { buildApp } from '../src/app';

describe('health route', () => {
  it('returns service status', async () => {
    const app = buildApp();

    const response = await app.inject({
      method: 'GET',
      url: '/health'
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({
      ok: true,
      service: 'macrolicious-backend'
    });

    await app.close();
  });
});
