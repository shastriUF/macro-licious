import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

import { extractBearerToken } from '../auth/session';
import { authStore } from '../domain/auth-store';
import { ingredientStore } from '../domain/ingredient-store';

const createIngredientSchema = z.object({
  name: z.string().min(1),
  brand: z.string().optional(),
  barcode: z.string().optional(),
  caloriesPer100g: z.number().nonnegative(),
  carbsPer100g: z.number().nonnegative(),
  proteinPer100g: z.number().nonnegative(),
  fatPer100g: z.number().nonnegative()
});

const updateIngredientSchema = createIngredientSchema.partial();

export const ingredientRoute: FastifyPluginAsync = async (app) => {
  app.post('/ingredients', async (request, reply) => {
    const sessionToken = extractBearerToken(request);
    if (!sessionToken) {
      return reply.status(401).send({ error: 'Missing bearer token' });
    }

    const user = authStore.getUserFromSession(sessionToken);
    if (!user) {
      return reply.status(401).send({ error: 'Invalid session token' });
    }

    const parsedBody = createIngredientSchema.safeParse(request.body);
    if (!parsedBody.success) {
      return reply.status(400).send({
        error: 'Invalid request payload',
        details: parsedBody.error.flatten()
      });
    }

    const ingredient = ingredientStore.create(user.id, parsedBody.data);
    return reply.status(201).send({ ingredient });
  });

  app.get('/ingredients', async (request, reply) => {
    const sessionToken = extractBearerToken(request);
    if (!sessionToken) {
      return reply.status(401).send({ error: 'Missing bearer token' });
    }

    const user = authStore.getUserFromSession(sessionToken);
    if (!user) {
      return reply.status(401).send({ error: 'Invalid session token' });
    }

    const query = z
      .object({
        includeArchived: z.coerce.boolean().optional().default(false)
      })
      .parse(request.query ?? {});

    const ingredients = ingredientStore.listByUser(user.id, query.includeArchived);
    return reply.send({ ingredients });
  });

  app.get('/ingredients/:ingredientId', async (request, reply) => {
    const sessionToken = extractBearerToken(request);
    if (!sessionToken) {
      return reply.status(401).send({ error: 'Missing bearer token' });
    }

    const user = authStore.getUserFromSession(sessionToken);
    if (!user) {
      return reply.status(401).send({ error: 'Invalid session token' });
    }

    const params = z.object({ ingredientId: z.string().min(1) }).parse(request.params);
    const ingredient = ingredientStore.getById(user.id, params.ingredientId);

    if (!ingredient) {
      return reply.status(404).send({ error: 'Ingredient not found' });
    }

    return reply.send({ ingredient });
  });

  app.patch('/ingredients/:ingredientId', async (request, reply) => {
    const sessionToken = extractBearerToken(request);
    if (!sessionToken) {
      return reply.status(401).send({ error: 'Missing bearer token' });
    }

    const user = authStore.getUserFromSession(sessionToken);
    if (!user) {
      return reply.status(401).send({ error: 'Invalid session token' });
    }

    const params = z.object({ ingredientId: z.string().min(1) }).parse(request.params);

    const parsedBody = updateIngredientSchema.safeParse(request.body);
    if (!parsedBody.success) {
      return reply.status(400).send({
        error: 'Invalid request payload',
        details: parsedBody.error.flatten()
      });
    }

    if (Object.keys(parsedBody.data).length === 0) {
      return reply.status(400).send({ error: 'No update fields provided' });
    }

    const ingredient = ingredientStore.update(user.id, params.ingredientId, parsedBody.data);
    if (!ingredient) {
      return reply.status(404).send({ error: 'Ingredient not found' });
    }

    return reply.send({ ingredient });
  });

  app.delete('/ingredients/:ingredientId', async (request, reply) => {
    const sessionToken = extractBearerToken(request);
    if (!sessionToken) {
      return reply.status(401).send({ error: 'Missing bearer token' });
    }

    const user = authStore.getUserFromSession(sessionToken);
    if (!user) {
      return reply.status(401).send({ error: 'Invalid session token' });
    }

    const params = z.object({ ingredientId: z.string().min(1) }).parse(request.params);
    const ingredient = ingredientStore.archive(user.id, params.ingredientId);

    if (!ingredient) {
      return reply.status(404).send({ error: 'Ingredient not found' });
    }

    return reply.send({ ingredient });
  });
};
