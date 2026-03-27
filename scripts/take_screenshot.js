const puppeteer = require('puppeteer');

(async () => {
  console.log('Launching browser...');
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  
  page.on('console', msg => console.log('PAGE LOG:', msg.text()));
  page.on('pageerror', err => console.log('PAGE ERROR:', err.toString()));
  
  // Set viewport to a typical mobile device size
  await page.setViewport({ width: 412, height: 915 });
  
  console.log('Navigating to https://fitapp-ns.web.app...');
  await page.goto('https://fitapp-ns.web.app', { waitUntil: 'networkidle0', timeout: 60000 });
  
  console.log('Waiting for Flutter app to render (15s)...');
  await new Promise(resolve => setTimeout(resolve, 15000));
  
  console.log('Taking screenshot...');
  await page.screenshot({ path: 'debug_screenshot.png' });
  
  console.log('Screenshot saved to debug_screenshot.png');
  await browser.close();
})();
