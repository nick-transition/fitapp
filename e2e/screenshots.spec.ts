import { test, Page } from '@playwright/test';

async function signIn(page: Page, email: string, password: string) {
  await page.evaluate(
    async ({ email, password }) => {
      const w = window as any;
      const auth = w.firebase_auth.getAuth();
      await w.firebase_auth.signInWithEmailAndPassword(auth, email, password);
    },
    { email, password },
  );
  await page.waitForTimeout(3000);
}

async function signOut(page: Page) {
  await page.evaluate(async () => {
    const w = window as any;
    await w.firebase_auth.signOut(w.firebase_auth.getAuth());
  });
  await page.waitForTimeout(2000);
}

async function clickAt(page: Page, x: number, y: number) {
  await page.mouse.click(x, y);
  await page.waitForTimeout(2000);
}

test('Capture README screenshots', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 720 });
  await page.goto('/');
  await page.waitForTimeout(5000);

  // 1. Marketing / landing screen
  await page.screenshot({ path: 'screenshots/01_landing.png' });

  // 2. Sign in as athlete
  await signIn(page, 'testuser@gmail.com', 'testpass123');
  await page.waitForTimeout(2000);

  // 3. Programs tab (home)
  await page.screenshot({ path: 'screenshots/02_programs.png' });

  // 4. Workouts tab
  await clickAt(page, 192, 90);
  await page.waitForTimeout(3000);
  await page.screenshot({ path: 'screenshots/03_workouts.png' });

  // 5. Expand Push Day to show exercises + video
  await clickAt(page, 400, 175);
  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'screenshots/04_workout_expanded.png' });

  // 6. View Details → workout detail with inline YouTube
  await clickAt(page, 1093, 412);
  await page.waitForTimeout(8000);
  await page.screenshot({ path: 'screenshots/05_workout_detail.png' });

  // 7. Back
  await clickAt(page, 30, 28);
  await page.waitForTimeout(2000);

  // 8. Calendar tab
  await clickAt(page, 283, 90);
  await page.waitForTimeout(3000);
  await page.screenshot({ path: 'screenshots/06_calendar.png' });

  // 9. Sessions tab
  await clickAt(page, 371, 90);
  await page.waitForTimeout(3000);
  await page.screenshot({ path: 'screenshots/07_sessions.png' });

  await signOut(page);

  // 10. Sign in as coach
  await signIn(page, 'coach@gmail.com', 'coachpass123');
  await page.waitForTimeout(2000);

  // 11. Coach Sharing
  await clickAt(page, 1139, 28);
  await page.waitForTimeout(3000);

  // My Athletes tab
  await clickAt(page, 957, 90);
  await page.waitForTimeout(3000);
  await page.screenshot({ path: 'screenshots/08_coach_athletes.png' });

  // 12. Tap athlete → detail
  await clickAt(page, 400, 390);
  await page.waitForTimeout(3000);

  // Expand program
  await clickAt(page, 400, 178);
  await page.waitForTimeout(3000);
  await page.screenshot({ path: 'screenshots/09_athlete_detail.png' });

  await signOut(page);
});
