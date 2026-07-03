import { test, expect } from '@playwright/test';
import {
  ATHLETE,
  COACH,
  PROGRAM_NAME,
  WORKOUT_NAME,
  gotoApp,
  signIn,
  signOut,
  openAthleteDetail,
  tab,
  text,
  goBack,
} from './helpers';

// Generates the screenshots embedded in README.md. Not a regression test —
// runs only via the "screenshots" Playwright project (npm run e2e:screenshots).

test('Capture README screenshots', async ({ page }) => {
  await gotoApp(page);
  await page.screenshot({ path: 'screenshots/01_landing.png' });

  // ── Athlete ────────────────────────────────────────────────────────────────
  await signIn(page, ATHLETE);
  await page.screenshot({ path: 'screenshots/02_programs.png' });

  // Program detail with the plan card
  await text(page, PROGRAM_NAME).click();
  await expect(text(page, 'Workouts')).toBeVisible();
  await page.screenshot({ path: 'screenshots/03_workouts.png' });

  // Expanded plan showing day headers and exercises
  await text(page, /4 days/).click();
  await expect(text(page, 'Back Squat')).toBeVisible();
  await page.screenshot({ path: 'screenshots/04_workout_expanded.png' });
  await goBack(page);

  await tab(page, 'Calendar').click();
  await page.screenshot({ path: 'screenshots/06_calendar.png' });

  await tab(page, 'Sessions').click();
  await expect(text(page, PROGRAM_NAME)).toBeVisible();
  await page.screenshot({ path: 'screenshots/07_sessions.png' });

  await signOut(page);

  // ── Coach ──────────────────────────────────────────────────────────────────
  await signIn(page, COACH);
  await openAthleteDetail(page);
  await page.screenshot({ path: 'screenshots/08_coach_athletes.png' });

  await text(page, PROGRAM_NAME).click();
  await expect(text(page, WORKOUT_NAME)).toBeVisible();
  await page.screenshot({ path: 'screenshots/09_athlete_detail.png' });

  // Read-only workout detail (has the inline exercise video tile)
  await text(page, WORKOUT_NAME).click();
  await page.getByRole('button', { name: 'View Details' }).first().click();
  await expect(text(page, 'Bench Press')).toBeVisible();
  await page.screenshot({ path: 'screenshots/05_workout_detail.png' });
});
