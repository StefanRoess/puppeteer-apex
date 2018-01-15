const puppeteer = require('puppeteer');

async function start() {
  /* start Puppeteer with page */
  const browser = await puppeteer.launch({
                          headless: false,
                          args: ['--no-sandbox'
                               , '--disable-setuid-sandbox'
                               , '--start-maximized']
                  });

  const page = await browser.newPage();

  /* load certain functions */
  //await page.addScriptTag({path: './findElementByText.js'});

  /* Skalierung */
  //await page.setViewport({width: 1366, height: 768});
  // 4k
  await page.setViewport({width: 1920, height: 1280});


  /* Page */
  //await page.goto('https://apex.oracle.com/pls/apex/f?p=121274:LOGIN_DESKTOP::::::', {
  await page.goto('http://localhost:8080/ords/f?p=102', {
     waituntil: "networkidle2"
  });

  /* Login */
  await page.type('#P101_USERNAME', 'test', {delay: 20});
  await page.type('#P101_PASSWORD', 'test_pw', {delay: 20});
  await page.click('#P101_LOGIN');
  //await page.waitForNavigation({waitUntil: 'networkidle2'});


  /* Navigation */
  await page.waitForSelector('li#t_TreeNav_3');
  const inputElement = await page.$('li#t_TreeNav_3');
  await inputElement.click();
  await page.waitForNavigation({waitUntil: 'networkidle2'});
  await page.click('tr > td > a[href^="javascript:apex.navigation.dialog"]')

  /* Modal Window */
  const frame = await page.frames()[1];

  async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async function setSelectVal(sel, val) {
    await sleep(1000);
    frame.evaluate((data) => {
         return document.querySelector(data.sel).value = data.val;
     }, {sel, val})
  }

  /* set values */
  await setSelectVal('#P29_USER_NAME', 'DEMO');
  var today = new Date();
  await setSelectVal('#P29_TAGS', today);

  await frame.waitForSelector('[data-action="selection-add-row"]') 
  const addRow = await frame.$('[data-action="selection-add-row"]');
  await addRow.click();

  await setSelectVal('#PRODUCT_ID', 1);
  await page.keyboard.press("Tab", {delay: 1000});
  await setSelectVal('#UNIT_PRICE', 1);
  await page.keyboard.press("Tab", {delay: 1000});
  await setSelectVal('#QUANTITY', 5);
  await page.keyboard.press("Tab", {delay: 1000});


  const save_button = await frame.$('#SAVE_BUTTON');
  await save_button.click();


  console.log("End of File");
  //browser.close();
}


start();