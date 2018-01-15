const puppeteer = require('puppeteer');

try {
  (async () => {
   const browser = await puppeteer.launch({
                            headless: false
                          // ,slowMo: 20
                          // ,args: ['--start-maximized']
                   });
   const page = await browser.newPage();
  
   // sollten Buttons nicht erscheinen, so ist das ein Skalierungsproblem
   // das man über width, height einstellen kann.

    /* Skalierung */
    page.setViewport({
      width: 1680,
      height: 1050
    });

    /* Page */
    await page.goto('https://apex.oracle.com/pls/apex/f?p=121274:LOGIN_DESKTOP::::::', {
       waituntil: "networkidle2"
    });

    /* Login */
    await page.type('#P101_USERNAME', 'test', {delay: 20}); // Types slower, like a user
    await page.type('#P101_PASSWORD', 'test_pw', {delay: 20}); // Types slower, like a user
    await page.click('#P101_LOGIN');
    await page.waitForNavigation({waitUntil: 'networkidle2'});

    /* Navigation */
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
    await setSelectVal('#P7_CUST_STREET_ADDRESS1', '0815 MyBeautifulStreet');
    await setSelectVal('#P7_CUST_CITY', 'Worms');
    await setSelectVal('#P7_CREDIT_LIMIT', '3999');
    await setSelectVal('#P7_CUST_STATE', 'AL');

    const update_button = await frame.$('#UPDATE_BUTTON');
    await update_button.click();

    console.log("End of File");
    //browser.close();

  })();
} catch (err) {
    console.log(err);
}