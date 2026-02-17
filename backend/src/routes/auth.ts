import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

import { env } from '../config/env';
import { authStore } from '../domain/auth-store';
import { getSupabasePublicClient } from '../integrations/supabase';

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

    if (env.AUTH_PROVIDER === 'dev') {
      const challenge = authStore.requestMagicLink(result.data.email, env.MAGIC_LINK_TTL_MINUTES);

      return reply.send({
        message: 'Magic link requested',
        token: challenge.token,
        expiresAt: new Date(challenge.expiresAt).toISOString(),
        provider: 'dev'
      });
    }

    try {
      const supabase = getSupabasePublicClient();
      const { error } = await supabase.auth.signInWithOtp({
        email: result.data.email,
        options: {
          emailRedirectTo: env.SUPABASE_EMAIL_REDIRECT_URL
        }
      });

      if (error) {
        app.log.error({ error }, 'Supabase magic-link request failed');
        return reply.status(502).send({ error: 'Failed to request magic link from provider' });
      }

      return reply.send({
        message: 'Magic link requested',
        provider: 'supabase',
        note: 'Check your email. In staged mode, verify endpoint expects a Supabase access token in the token field.'
      });
    } catch (error) {
      app.log.error({ error }, 'Supabase configuration error');
      return reply.status(500).send({ error: 'Supabase auth is not configured correctly' });
    }
  });

  app.post('/auth/magic-link/verify', async (request, reply) => {
    const result = magicLinkVerifySchema.safeParse(request.body);

    if (!result.success) {
      return reply.status(400).send({
        error: 'Invalid request payload',
        details: result.error.flatten()
      });
    }

    if (env.AUTH_PROVIDER === 'dev') {
      const verification = await authStore.verifyMagicLink(result.data.token);

      if (!verification) {
        return reply.status(401).send({
          error: 'Invalid or expired magic link token'
        });
      }

      return reply.send({
        sessionToken: verification.sessionToken,
        user: verification.user
      });
    }

    try {
      const supabase = getSupabasePublicClient();
      const { data, error } = await supabase.auth.getUser(result.data.token);

      if (error || !data.user?.email) {
        return reply.status(401).send({
          error: 'Invalid provider access token'
        });
      }

      const verification = await authStore.createSessionForEmail(data.user.email);

      return reply.send({
        sessionToken: verification.sessionToken,
        user: verification.user,
        provider: 'supabase'
      });
    } catch (error) {
      app.log.error({ error }, 'Supabase verification error');
      return reply.status(500).send({ error: 'Supabase auth is not configured correctly' });
    }
  });
};
