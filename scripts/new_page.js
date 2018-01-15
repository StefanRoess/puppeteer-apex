const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({headless: false})
  let max_val = 4

  for (let i = 0; i < max_val; ++i) {
    let page = await browser.newPage(i)
    await page.goto('https://developer.mozilla.org/en-US/')
  }
  await browser.close()
})()