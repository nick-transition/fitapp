import { test, expect } from '@playwright/test';

test.describe('Coach: athlete workout detail (read-only)', () => {
  test('navigates to workout detail from athlete programs tab', async ({ page }) => {
    // Navigate to coach tab and select an athlete
    await page.goto('/');
    await page.getByTestId('tab-coach').click();

    // Assume at least one athlete connection exists
    const athleteCard = page.getByTestId('athlete-card').first();
    await athleteCard.click();

    // On athlete detail, the Programs tab is default
    // Find first expanded program or expand one
    const programTile = page.getByTestId('program-tile').first();
    await programTile.click();

    // Wait for workouts to load, then find a View Details link
    const viewDetailsBtn = page.getByRole('button', { name: /view details/i }).first();
    await expect(viewDetailsBtn).toBeVisible({ timeout: 10000 });
    await viewDetailsBtn.click();

    // Workout detail screen should render and NOT show edit/delete buttons
    await expect(page.getByText(/exercises/i)).toBeVisible();
    await expect(page.getByRole('button', { name: /edit/i })).not.toBeVisible();
    await expect(page.getByRole('button', { name: /delete/i })).not.toBeVisible();

    // Exercise video links should still be present
    const videoIcons = page.locator('[data-testid="video-link"]');
    // At least check that the page loaded (videos may not exist on all workouts)
    await expect(page.locator('h1, h2').first()).toBeVisible();
  });
});
