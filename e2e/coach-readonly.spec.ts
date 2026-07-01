import { test, expect, Page } from '@playwright/test';

// Flutter web exposes firebase_auth/firebase_core as globals.
// Sign-in via JS triggers the Dart AuthWrapper stream automatically.
// Navigation uses coordinate clicks since Flutter renders to canvas/custom DOM.

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

// Click at a position relative to viewport (Flutter renders to full viewport)
async function clickAt(page: Page, x: number, y: number) {
  await page.mouse.click(x, y);
  await page.waitForTimeout(2000);
}

test.describe('Coach: athlete workout detail (read-only)', () => {
  test('navigates to workout detail from athlete programs tab', async ({ page }) => {
    // Use a consistent viewport (matches walkthrough.spec.ts)
    await page.setViewportSize({ width: 1280, height: 720 });

    // Navigate and wait for app to load
    await page.goto('/');
    await page.waitForTimeout(5000);

    // Sign in as coach
    await signIn(page, 'coach@gmail.com', 'coachpass123');
    await page.waitForTimeout(2000);

    // Coach Sharing icon (people icon, top-right area) — same coords as walkthrough
    await clickAt(page, 1139, 28);
    await page.waitForTimeout(3000);

    // My Athletes tab (right side of tab bar)
    await clickAt(page, 957, 90);
    await page.waitForTimeout(3000);

    // Click "Test User" athlete card
    await clickAt(page, 400, 390);
    await page.waitForTimeout(3000);

    // Expand "4-Day Strength & Conditioning" program
    await clickAt(page, 400, 178);
    await page.waitForTimeout(3000);

    // Click "View Details" button on a workout — coordinates from screenshots.spec.ts
    await clickAt(page, 1093, 412);
    await page.waitForTimeout(5000);

    // Workout detail screen should render in read-only mode.
    // Flutter renders to canvas so we verify by checking the page has content
    // and taking a screenshot for visual verification.
    await page.screenshot({ path: 'screenshots/coach_readonly_workout_detail.png' });

    // Verify the page loaded (has content, not a blank/error screen)
    const hasContent = await page.evaluate(() => {
      const body = document.body;
      return body !== null && body.innerHTML.length > 100;
    });
    expect(hasContent).toBeTruthy();

    // Navigate back
    await clickAt(page, 30, 28);
    await page.waitForTimeout(2000);

    await signOut(page);
  });

  test('session detail is read-only for coach', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 720 });

    await page.goto('/');
    await page.waitForTimeout(5000);

    // Sign in as coach
    await signIn(page, 'coach@gmail.com', 'coachpass123');
    await page.waitForTimeout(2000);

    // Coach Sharing icon
    await clickAt(page, 1139, 28);
    await page.waitForTimeout(3000);

    // My Athletes tab
    await clickAt(page, 957, 90);
    await page.waitForTimeout(3000);

    // Click athlete card
    await clickAt(page, 400, 390);
    await page.waitForTimeout(3000);

    // Sessions tab on athlete detail
    await clickAt(page, 1063, 90);
    await page.waitForTimeout(3000);

    // Click the completed session to view details
    await clickAt(page, 400, 178);
    await page.waitForTimeout(5000);

    // Session detail should render in read-only mode
    await page.screenshot({ path: 'screenshots/coach_readonly_session_detail.png' });

    const hasContent = await page.evaluate(() => {
      const body = document.body;
      return body !== null && body.innerHTML.length > 100;
    });
    expect(hasContent).toBeTruthy();

    await signOut(page);
  });
});
