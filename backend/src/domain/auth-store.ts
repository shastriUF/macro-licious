import { randomBytes, randomUUID } from 'node:crypto';

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

  verifyMagicLink(token: string): { sessionToken: string; user: User } | null {
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

  createSessionForEmail(email: string): { sessionToken: string; user: User } {
    const user = this.getOrCreateUser(email);
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

  getUserFromSession(sessionToken: string): User | null {
    const session = this.sessionsByToken.get(sessionToken);
    if (!session) {
      return null;
    }

    return this.usersById.get(session.userId) ?? null;
  }

  updateMacroTargets(userId: string, macroTargets: MacroTargets): User | null {
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

  private getOrCreateUser(email: string): User {
    const normalizedEmail = this.normalizeEmail(email);
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

  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  private generateToken(): string {
    return randomBytes(24).toString('hex');
  }
}

export const authStore = new AuthStore();
