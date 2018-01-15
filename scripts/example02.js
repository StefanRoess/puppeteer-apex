const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({
      headless: false
  });
  let page = await browser.newPage();

  await page.goto('https://developer.mozilla.org/en-US/', { waitUntil: 'load' });
  await page.click('#language', { delay: 1000 });
  await page.screenshot({ path: '../images/screenshot1.jpg', type: 'jpeg', quality:50 });
  await browser.close();
})();
