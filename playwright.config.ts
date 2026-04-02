import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 120_000,
  use: {
    baseURL: 'http://localhost:8080',
    // Record video of each test
    video: 'on',
    screenshot: 'on',
    // Slow down for visibility
    launchOptions: {
      slowMo: 500,
    },
  },
  // Serve the built Flutter web app
  webServer: {
    command: 'npx serve build/web -l 8080 -s',
    port: 8080,
    reuseExistingServer: true,
  },
  reporter: [['html', { open: 'never' }]],
});
