const puppeteer = require('puppeteer');

(async () => {
  console.log('--- Starting Automation Flow (Robust) ---');
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  const page = await browser.newPage();
  await page.setViewport({ width: 1200, height: 1000 });

  try {
    console.log('Navigating to http://localhost:8181...');
    await page.goto('http://localhost:8181', { waitUntil: 'networkidle0', timeout: 60000 });
    await new Promise(r => setTimeout(r, 15000));

    console.log('Clicking "Get Started"...');
    // Try click by coordinate if selector fails
    await page.mouse.click(600, 500); 
    await new Promise(r => setTimeout(r, 3000));

    console.log('Clicking "Sign in with Google"...');
    const newTargetPromise = new Promise(x => browser.once('targetcreated', x));
    await page.mouse.click(600, 150); // Click top right area for "Sign In"
    
    console.log('Waiting for potential popup...');
    const target = await Promise.race([
      newTargetPromise,
      new Promise((_, reject) => setTimeout(() => reject(new Error('Popup timeout')), 10000))
    ]).catch(e => null);

    if (target) {
      console.log('Popup detected!');
      const popupPage = await target.page();
      await new Promise(r => setTimeout(r, 5000));
      await popupPage.evaluate(() => {
        const btns = Array.from(document.querySelectorAll('button'));
        const target = btns.find(b => b.textContent.includes('testuser@gmail.com'));
        if (target) target.click();
      });
      await new Promise(r => setTimeout(r, 10000));
    } else {
      console.log('No popup, might be auto-logged in or failed.');
    }

    await page.screenshot({ path: 'screenshots/automated_final.png' });
    console.log('Captured screenshots/automated_final.png');

  } catch (err) {
    console.error('ERROR:', err);
  } finally {
    await browser.close();
    process.exit(0);
  }
})();
