import Fastify, { type FastifyInstance } from 'fastify';

import { env } from './config/env';
import { authRoute } from './routes/auth';
import { healthRoute } from './routes/health';
import { profileRoute } from './routes/profile';

export function buildApp(): FastifyInstance {
  const app = Fastify({
    logger: env.NODE_ENV !== 'test'
  });

  app.register(healthRoute);
  app.register(authRoute);
  app.register(profileRoute);

  app.get('/', async () => {
    return {
      name: env.APP_NAME,
      status: 'running'
    };
  });

  return app;
}
