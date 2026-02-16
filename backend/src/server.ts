import { buildApp } from './app';
import { env } from './config/env';

async function startServer() {
  const app = buildApp();

  try {
    await app.listen({
      host: '0.0.0.0',
      port: env.PORT
    });
  } catch (error) {
    app.log.error(error);
    process.exit(1);
  }
}

void startServer();
