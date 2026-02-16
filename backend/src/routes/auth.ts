import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

import { env } from '../config/env';
import { authStore } from '../domain/auth-store';

const magicLinkRequestSchema = z.object({
  email: z.string().email()
});

const magicLinkVerifySchema = z.object({
  token: z.string().min(20)
});

export const authRoute: FastifyPluginAsync = async (app) => {
  app.post('/auth/magic-link/request', async (request, reply) => {
    const result = magicLinkRequestSchema.safeParse(request.body);

    if (!result.success) {
      return reply.status(400).send({
        error: 'Invalid request payload',
        details: result.error.flatten()
      });
    }

    const challenge = authStore.requestMagicLink(result.data.email, env.MAGIC_LINK_TTL_MINUTES);

    return reply.send({
      message: 'Magic link requested',
      token: challenge.token,
      expiresAt: new Date(challenge.expiresAt).toISOString()
    });
  });

  app.post('/auth/magic-link/verify', async (request, reply) => {
    const result = magicLinkVerifySchema.safeParse(request.body);

    if (!result.success) {
      return reply.status(400).send({
        error: 'Invalid request payload',
        details: result.error.flatten()
      });
    }

    const verification = authStore.verifyMagicLink(result.data.token);

    if (!verification) {
      return reply.status(401).send({
        error: 'Invalid or expired magic link token'
      });
    }

    return reply.send({
      sessionToken: verification.sessionToken,
      user: verification.user
    });
  });
};
