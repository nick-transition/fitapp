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

test('Athlete e2e walkthrough', async ({ page }) => {
  // Use a consistent viewport
  await page.setViewportSize({ width: 1280, height: 720 });

  // 1. Marketing screen
  await page.goto('/');
  await page.waitForTimeout(5000);

  // 2. Sign in as athlete
  await signIn(page, 'testuser@gmail.com', 'testpass123');
  // Now on HomeScreen, Programs tab with "4-Day Strength & Conditioning"
  await page.waitForTimeout(2000);

  // 3. Click the program card (roughly center of the card area)
  await clickAt(page, 640, 178);
  await page.waitForTimeout(2000);

  // 4. Back button (top-left area)
  await clickAt(page, 30, 28);
  await page.waitForTimeout(2000);

  // 5. Click "Workouts" tab (second tab)
  await clickAt(page, 192, 90);
  await page.waitForTimeout(3000);

  // 6. Click "Push Day" workout to expand
  await clickAt(page, 400, 175);
  await page.waitForTimeout(2000);

  // 7. Click "Calendar" tab (third tab)
  await clickAt(page, 283, 90);
  await page.waitForTimeout(3000);

  // 8. Click "Sessions" tab (fourth tab)
  await clickAt(page, 371, 90);
  await page.waitForTimeout(3000);

  await signOut(page);
});

test('Coach e2e walkthrough', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 720 });

  await page.goto('/');
  await page.waitForTimeout(5000);

  // Sign in as coach
  await signIn(page, 'coach@gmail.com', 'coachpass123');
  await page.waitForTimeout(2000);

  // Coach Sharing icon (people icon, top-right area)
  await clickAt(page, 1139, 28);
  await page.waitForTimeout(3000);

  // My Athletes tab (second tab)
  await clickAt(page, 350, 90);
  await page.waitForTimeout(3000);

  // Click "Test User" athlete card
  await clickAt(page, 400, 250);
  await page.waitForTimeout(3000);

  // Sessions tab on athlete detail
  await clickAt(page, 340, 90);
  await page.waitForTimeout(3000);

  await signOut(page);
});
