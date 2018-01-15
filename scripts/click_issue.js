const puppeteer = require('puppeteer');
const devices = require('puppeteer/DeviceDescriptors');
const iPhone = devices['iPhone 5'];

puppeteer.launch({headless: false}).then(async browser => {
  const page = await browser.newPage();
  await page.goto('https://google.com');

  await page.type('[name="q"]', 'hello world');

  const inputElement = await page.$('input[type=submit]');
  await inputElement.click();
  await page.waitFor(2000);

  await page.screenshot({
    path: '../images/snap.png',
  });

  //await browser.close();

});
