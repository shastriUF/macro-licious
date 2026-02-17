import { env } from '../src/config/env';
import { authStore } from '../src/domain/auth-store';
import { ingredientStore } from '../src/domain/ingredient-store';

async function run(): Promise<void> {
  if (env.AUTH_PROVIDER !== 'supabase') {
    throw new Error('AUTH_PROVIDER must be set to supabase for this smoke test.');
  }

  const email = `smoke+${Date.now()}@macrolicious.local`;

  console.log('Running Supabase smoke test...');
  console.log(`Using test user: ${email}`);

  const firstSession = await authStore.createSessionForEmail(email);

  const createdIngredient = await ingredientStore.create(firstSession.user.id, {
    name: 'Smoke Test Oats',
    brand: 'MacroLicious Smoke',
    barcode: undefined,
    caloriesPer100g: 389,
    carbsPer100g: 66.3,
    proteinPer100g: 16.9,
    fatPer100g: 6.9
  });

  authStore.reset();
  ingredientStore.reset();

  const secondSession = await authStore.createSessionForEmail(email);
  const ingredientsAfterReset = await ingredientStore.listByUser(secondSession.user.id, true);

  const persistedIngredient = ingredientsAfterReset.find((ingredient) => ingredient.id === createdIngredient.id);

  if (!persistedIngredient) {
    throw new Error('Persistence check failed: ingredient not found after reset.');
  }

  if (secondSession.user.email !== firstSession.user.email) {
    throw new Error('Persistence check failed: user email mismatch after reset.');
  }

  console.log('Supabase smoke test passed.');
  console.log(`Persisted ingredient id: ${persistedIngredient.id}`);
}

run().catch((error) => {
  console.error('Supabase smoke test failed.');
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
