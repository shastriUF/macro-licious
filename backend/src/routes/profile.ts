import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

import { extractBearerToken } from '../auth/session';
import { authStore } from '../domain/auth-store';

const macroTargetsSchema = z.object({
  calories: z.number().positive(),
  carbs: z.number().positive(),
  protein: z.number().positive()
});

export const profileRoute: FastifyPluginAsync = async (app) => {
  app.get('/me', async (request, reply) => {
    const sessionToken = extractBearerToken(request);
    if (!sessionToken) {
      return reply.status(401).send({
        error: 'Missing bearer token'
      });
    }

    const user = await authStore.getUserFromSession(sessionToken);
    if (!user) {
      return reply.status(401).send({
        error: 'Invalid session token'
      });
    }

    return reply.send({ user });
  });

  app.patch('/me/macro-targets', async (request, reply) => {
    const sessionToken = extractBearerToken(request);
    if (!sessionToken) {
      return reply.status(401).send({
        error: 'Missing bearer token'
      });
    }

    const user = await authStore.getUserFromSession(sessionToken);
    if (!user) {
      return reply.status(401).send({
        error: 'Invalid session token'
      });
    }

    const parsedBody = macroTargetsSchema.safeParse(request.body);
    if (!parsedBody.success) {
      return reply.status(400).send({
        error: 'Invalid request payload',
        details: parsedBody.error.flatten()
      });
    }

    const updatedUser = await authStore.updateMacroTargets(user.id, parsedBody.data);
    if (!updatedUser) {
      return reply.status(404).send({
        error: 'User not found'
      });
    }

    return reply.send({ user: updatedUser });
  });
};
