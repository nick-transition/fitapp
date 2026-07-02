import { test, expect } from '@playwright/test';
import {
  COACH,
  PROGRAM_NAME,
  WORKOUT_NAME,
  gotoApp,
  signIn,
  openAthleteDetail,
  sessionCard,
  tab,
  text,
  button,
} from './helpers';

test.describe('Coach views of athlete data are read-only', () => {
  test.beforeEach(async ({ page }) => {
    await gotoApp(page);
    await signIn(page, COACH);
    await openAthleteDetail(page);
  });

  test('workout detail hides edit and start-session actions', async ({ page }) => {
    // Expand the program, then the workout card, then open its detail screen.
    await text(page, PROGRAM_NAME).click();
    await text(page, WORKOUT_NAME).click();
    await button(page, 'View Details').click();

    // The detail screen rendered with the workout's content…
    await expect(text(page, 'Bench Press')).toBeVisible();

    // …and none of the owner-only actions (WorkoutDetailScreen readOnly=true).
    await expect(page.getByRole('button', { name: 'Edit workout' })).toHaveCount(0);
    await expect(page.getByRole('button', { name: 'Start Session' })).toHaveCount(0);
  });

  test('session detail is labeled Coach View and hides delete', async ({ page }) => {
    await tab(page, 'Sessions').click();
    await sessionCard(page, PROGRAM_NAME).click();

    // Session content rendered…
    await expect(text(page, 'Back Squat')).toBeVisible();

    // …with the read-only marker and no owner-only delete action.
    await expect(text(page, 'Coach View')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Delete Session' })).toHaveCount(0);
  });
});
