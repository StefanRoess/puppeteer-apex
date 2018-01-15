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
  
  /* Skalierung */
  await page.setViewport({width: 1366, height: 768});

  /* Page */
  await page.goto('https://apex.oracle.com/pls/apex/f?p=121274:LOGIN_DESKTOP::::::', {
     waituntil: "networkidle2"
  });

  /* Login */
  await page.type('#P101_USERNAME', 'test', {delay: 20}); // Types slower, like a user
  await page.type('#P101_PASSWORD', 'test_pw', {delay: 20}); // Types slower, like a user
  await page.click('#P101_LOGIN');
  //await page.waitForNavigation({waitUntil: 'networkidle2'});

  /* Navigation */
  await page.waitForSelector('li#t_TreeNav_1');
  const inputElement = await page.$('li#t_TreeNav_1');
  await inputElement.click();
  await page.waitForNavigation({waitUntil: 'networkidle2'});
  await page.click('tr:last-child > td > a[href^="javascript:apex.navigation.dialog"]');

  const frame = await page.frames()[1];

  /* an old man is not a D-Train */
  function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async function setSelectVal(sel, val) {
    await sleep(1000);
    frame.evaluate((data) => {
         return document.querySelector(data.sel).value = data.val
     }, {sel, val})
  }

  /* set values */
  // this is necessary to reach DELETE_BUTTON
  await setSelectVal('#P7_CUST_STREET_ADDRESS1', '0815 MyBeautifulStreet');

  const delete_button = await frame.$('#DELETE_BUTTON');
  await delete_button.click();

  await sleep(1000);
  // hier liegt der Hase im Pfeffer.
  const ok_button = await page.$('#apexConfirmBtn');
  await ok_button.click();

  console.log("End of File");
    //browser.close();
}


start();