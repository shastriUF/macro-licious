export type MacroTargets = {
  calories: number;
  carbs: number;
  protein: number;
};

export type User = {
  id: string;
  email: string;
  macroTargets: MacroTargets;
  createdAt: string;
  updatedAt: string;
};

export type MagicLinkChallenge = {
  token: string;
  email: string;
  expiresAt: number;
  used: boolean;
};
