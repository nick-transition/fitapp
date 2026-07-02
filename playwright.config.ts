import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 120_000,
  retries: process.env.CI ? 2 : 0,
  // Clears the Firebase emulators and reseeds before every run.
  globalSetup: './e2e/global-setup.ts',
  use: {
    baseURL: 'http://localhost:8080',
    viewport: { width: 1280, height: 720 },
    video: 'retain-on-failure',
    screenshot: 'only-on-failure',
    trace: 'on-first-retry',
  },
  projects: [
    // Regression suite — what CI runs.
    { name: 'e2e', testIgnore: /screenshots\.spec\.ts/ },
    // README screenshot generator — run on demand via `npm run e2e:screenshots`.
    {
      name: 'screenshots',
      testMatch: /screenshots\.spec\.ts/,
      use: { video: 'off', screenshot: 'off' },
    },
  ],
  // Serve the built Flutter web app
  webServer: {
    command: 'npx serve build/web -l 8080 -s',
    port: 8080,
    reuseExistingServer: true,
  },
  reporter: process.env.CI
    ? [['list'], ['html', { open: 'never' }]]
    : [['list']],
});
