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
  sessionCard,
  tab,
  text,
  goBack,
} from './helpers';

test('athlete can browse programs, calendar, and session history', async ({ page }) => {
  await gotoApp(page);
  await signIn(page, ATHLETE);

  // Programs tab (default) lists the seeded program; open its detail.
  await text(page, PROGRAM_NAME).click();
  await expect(text(page, 'Workouts')).toBeVisible();

  // Expand the plan card to reveal its day headers and exercises.
  await text(page, /4 days/).click();
  await expect(text(page, 'Lower Body')).toBeVisible();
  await expect(text(page, 'Back Squat')).toBeVisible();
  await goBack(page);

  // Calendar tab shows the current month.
  await tab(page, 'Calendar').click();
  const now = new Date();
  const monthName = now.toLocaleString('en-US', { month: 'long' });
  await expect(text(page, `${monthName} ${now.getFullYear()}`)).toBeVisible();

  // Sessions tab lists the completed session from the seed.
  await tab(page, 'Sessions').click();
  await expect(sessionCard(page, PROGRAM_NAME)).toBeVisible();

  await signOut(page);
});

test('coach can browse an athlete\'s programs and sessions', async ({ page }) => {
  await gotoApp(page);
  await signIn(page, COACH);

  await openAthleteDetail(page);

  // Programs tab (default): expand the program to reveal its workouts.
  await text(page, PROGRAM_NAME).click();
  await expect(text(page, WORKOUT_NAME)).toBeVisible();

  // Expand the workout card to reveal its exercises.
  await text(page, WORKOUT_NAME).click();
  await expect(text(page, 'Bench Press')).toBeVisible();

  // Sessions tab lists the athlete's completed session.
  await tab(page, 'Sessions').click();
  await expect(sessionCard(page, PROGRAM_NAME)).toBeVisible();

  // Back out to home (athlete detail → coach screen → home), then sign out.
  await goBack(page);
  await goBack(page);
  await signOut(page);
});
