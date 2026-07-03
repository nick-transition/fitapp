import { Page, expect } from '@playwright/test';

export const ATHLETE = { email: 'testuser@gmail.com', password: 'testpass123' };
export const COACH = { email: 'coach@gmail.com', password: 'coachpass123' };

// Names created by scripts/seed_emulator.js
export const PROGRAM_NAME = '4-Day Strength & Conditioning';
export const ATHLETE_NAME = 'Test User';
export const WORKOUT_NAME = 'Push Day';

// ── Selectors ────────────────────────────────────────────────────────────────
// The app is built with --dart-define=ENABLE_SEMANTICS=true (see
// scripts/run_e2e.sh), which makes Flutter web emit its accessibility tree as
// DOM nodes. That lets us target widgets by accessible role/name instead of
// screen coordinates.

// Flutter emits most text as the accessible name (aria-label) of a semantics
// node rather than as DOM text, so match either.
export function text(page: Page, value: string | RegExp) {
  return page.getByLabel(value).or(page.getByText(value)).first();
}

export function button(page: Page, name: string | RegExp) {
  return page.getByRole('button', { name }).first();
}

export function tab(page: Page, name: string) {
  return page.getByRole('tab', { name: new RegExp(name) }).first();
}

export async function goBack(page: Page) {
  await button(page, 'Back').click();
}

// ── App lifecycle ────────────────────────────────────────────────────────────

export async function gotoApp(page: Page) {
  await page.goto('/');
  // Marketing screen is the signed-out landing page. First paint includes
  // engine startup, so allow a generous timeout.
  await expect(button(page, 'Get Started')).toBeVisible({ timeout: 60_000 });
}

// Flutter web exposes firebase_auth as a JS global (see web/index.html).
// Signing in via JS fires the Dart AuthWrapper stream — no UI login needed.
export async function signIn(page: Page, user: { email: string; password: string }) {
  await page.evaluate(async ({ email, password }) => {
    const w = window as any;
    const auth = w.firebase_auth.getAuth();
    await w.firebase_auth.signInWithEmailAndPassword(auth, email, password);
  }, user);
  // Signed-in home always shows the tab bar.
  await expect(tab(page, 'Programs')).toBeVisible({ timeout: 30_000 });
}

// Signs out through the UI. Only valid from the home screen (where the
// Sign Out action lives) — navigate back there first if in a pushed route.
export async function signOut(page: Page) {
  await button(page, 'Sign Out').click();
  await expect(button(page, 'Get Started')).toBeVisible({ timeout: 30_000 });
}

// A SessionCard exposes button semantics whose accessible name starts with
// the plan name followed by the session date (which disambiguates it from
// the program tile of the same name).
export function sessionCard(page: Page, planName: string) {
  return page.getByRole('button', { name: new RegExp(`${planName}[\\s\\S]*\\b20\\d\\d\\b`) }).first();
}

// Coach Sharing screen → My Athletes → open the seeded athlete.
export async function openAthleteDetail(page: Page) {
  await button(page, 'Coach Sharing').click();
  await tab(page, 'My Athletes').click();
  await text(page, ATHLETE_NAME).click();
  await expect(tab(page, 'Plans')).toBeVisible();
}
