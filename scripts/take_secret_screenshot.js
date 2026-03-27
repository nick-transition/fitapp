const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  const page = await browser.newPage();
  
  // Mobile size viewport
  await page.setViewport({ width: 412, height: 915 });
  
  console.log('Navigating to http://localhost:8282...');
  await page.goto('http://localhost:8282', { waitUntil: 'networkidle0', timeout: 60000 });
  
  // Wait a bit extra to ensure flutter web app initializes completely and font loads
  await new Promise(resolve => setTimeout(resolve, 5000));
  
  console.log('Taking screenshot...');
  await page.screenshot({ path: 'secret_generation_screenshot.png' });
  
  console.log('Screenshot saved to secret_generation_screenshot.png');
  await browser.close();
})();
