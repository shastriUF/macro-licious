import Fastify, { type FastifyInstance } from 'fastify';

import { env } from './config/env';
import { healthRoute } from './routes/health';

export function buildApp(): FastifyInstance {
  const app = Fastify({
    logger: env.NODE_ENV !== 'test'
  });

  app.register(healthRoute);

  app.get('/', async () => {
    return {
      name: env.APP_NAME,
      status: 'running'
    };
  });

  return app;
}
