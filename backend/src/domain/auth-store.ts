import { randomBytes, randomUUID } from 'node:crypto';

import { env } from '../config/env';
import { getSupabaseAdminClient } from '../integrations/supabase';
import type { MacroTargets, MagicLinkChallenge, User } from './models';

type SessionRecord = {
  sessionToken: string;
  userId: string;
  createdAt: number;
};

const DEFAULT_MACRO_TARGETS: MacroTargets = {
  calories: 2000,
  carbs: 250,
  protein: 120
};

export class AuthStore {
  private readonly usersById = new Map<string, User>();
  private readonly userIdByEmail = new Map<string, string>();
  private readonly challengesByToken = new Map<string, MagicLinkChallenge>();
  private readonly sessionsByToken = new Map<string, SessionRecord>();

  requestMagicLink(email: string, ttlMinutes: number): MagicLinkChallenge {
    const token = this.generateToken();
    const expiresAt = Date.now() + ttlMinutes * 60_000;

    const challenge: MagicLinkChallenge = {
      token,
      email: this.normalizeEmail(email),
      expiresAt,
      used: false
    };

    this.challengesByToken.set(token, challenge);

    return challenge;
  }

  async verifyMagicLink(token: string): Promise<{ sessionToken: string; user: User } | null> {
    const challenge = this.challengesByToken.get(token);
    if (!challenge) {
      return null;
    }

    if (challenge.used || challenge.expiresAt < Date.now()) {
      return null;
    }

    challenge.used = true;
    this.challengesByToken.set(token, challenge);

    return this.createSessionForEmail(challenge.email);
  }

  async createSessionForEmail(email: string): Promise<{ sessionToken: string; user: User }> {
    const user = await this.getOrCreateUser(email);
    const sessionToken = this.generateToken();

    this.sessionsByToken.set(sessionToken, {
      sessionToken,
      userId: user.id,
      createdAt: Date.now()
    });

    return {
      sessionToken,
      user
    };
  }

  async getUserFromSession(sessionToken: string): Promise<User | null> {
    const session = this.sessionsByToken.get(sessionToken);
    if (!session) {
      return null;
    }

    if (env.AUTH_PROVIDER === 'supabase') {
      const supabase = getSupabaseAdminClient();
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', session.userId)
        .single();

      if (error || !data) {
        return null;
      }

      const mappedUser = this.mapDbUserToDomain(data);
      this.usersById.set(mappedUser.id, mappedUser);
      this.userIdByEmail.set(mappedUser.email, mappedUser.id);
      return mappedUser;
    }

    return this.usersById.get(session.userId) ?? null;
  }

  async updateMacroTargets(userId: string, macroTargets: MacroTargets): Promise<User | null> {
    if (env.AUTH_PROVIDER === 'supabase') {
      const supabase = getSupabaseAdminClient();
      const { data, error } = await supabase
        .from('user_profiles')
        .update({
          calories_target: macroTargets.calories,
          carbs_target: macroTargets.carbs,
          protein_target: macroTargets.protein,
          updated_at: new Date().toISOString()
        })
        .eq('id', userId)
        .select('*')
        .single();

      if (error || !data) {
        return null;
      }

      const updatedUser = this.mapDbUserToDomain(data);
      this.usersById.set(updatedUser.id, updatedUser);
      this.userIdByEmail.set(updatedUser.email, updatedUser.id);
      return updatedUser;
    }

    const existingUser = this.usersById.get(userId);
    if (!existingUser) {
      return null;
    }

    const updatedUser: User = {
      ...existingUser,
      macroTargets,
      updatedAt: new Date().toISOString()
    };

    this.usersById.set(userId, updatedUser);

    return updatedUser;
  }

  reset(): void {
    this.usersById.clear();
    this.userIdByEmail.clear();
    this.challengesByToken.clear();
    this.sessionsByToken.clear();
  }

  private async getOrCreateUser(email: string): Promise<User> {
    const normalizedEmail = this.normalizeEmail(email);

    if (env.AUTH_PROVIDER === 'supabase') {
      const supabase = getSupabaseAdminClient();

      const { data: existing, error: existingError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('email', normalizedEmail)
        .maybeSingle();

      if (existingError) {
        throw new Error(`Failed to query user_profiles: ${existingError.message}`);
      }

      if (existing) {
        const existingUser = this.mapDbUserToDomain(existing);
        this.usersById.set(existingUser.id, existingUser);
        this.userIdByEmail.set(existingUser.email, existingUser.id);
        return existingUser;
      }

      const nowIso = new Date().toISOString();
      const { data: inserted, error: insertError } = await supabase
        .from('user_profiles')
        .insert({
          email: normalizedEmail,
          calories_target: DEFAULT_MACRO_TARGETS.calories,
          carbs_target: DEFAULT_MACRO_TARGETS.carbs,
          protein_target: DEFAULT_MACRO_TARGETS.protein,
          created_at: nowIso,
          updated_at: nowIso
        })
        .select('*')
        .single();

      if (insertError || !inserted) {
        throw new Error(`Failed to insert user_profiles row: ${insertError?.message ?? 'Unknown error'}`);
      }

      const createdUser = this.mapDbUserToDomain(inserted);
      this.usersById.set(createdUser.id, createdUser);
      this.userIdByEmail.set(createdUser.email, createdUser.id);
      return createdUser;
    }

    const existingUserId = this.userIdByEmail.get(normalizedEmail);

    if (existingUserId) {
      const existingUser = this.usersById.get(existingUserId);
      if (existingUser) {
        return existingUser;
      }
    }

    const nowIso = new Date().toISOString();
    const user: User = {
      id: randomUUID(),
      email: normalizedEmail,
      macroTargets: DEFAULT_MACRO_TARGETS,
      createdAt: nowIso,
      updatedAt: nowIso
    };

    this.usersById.set(user.id, user);
    this.userIdByEmail.set(normalizedEmail, user.id);

    return user;
  }

  private mapDbUserToDomain(row: {
    id: string;
    email: string;
    calories_target: number;
    carbs_target: number;
    protein_target: number;
    created_at: string;
    updated_at: string;
  }): User {
    return {
      id: row.id,
      email: row.email,
      macroTargets: {
        calories: Number(row.calories_target),
        carbs: Number(row.carbs_target),
        protein: Number(row.protein_target)
      },
      createdAt: row.created_at,
      updatedAt: row.updated_at
    };
  }

  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  private generateToken(): string {
    return randomBytes(24).toString('hex');
  }
}

export const authStore = new AuthStore();
