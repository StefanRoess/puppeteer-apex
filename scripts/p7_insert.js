const puppeteer = require('puppeteer');

puppeteer.launch({headless: false})
   .then(async browser => {

    const page = await browser.newPage();
    // sollten Buttons nicht erscheinen, so ist das ein Skalierungsproblem
    // das man über width, height einstellen kann.

    /* Skalierung */
    page.setViewport({
      width: 1920,
      height: 1080
    });

    /* Page */
    await page.goto('https://apex.oracle.com/pls/apex/f?p=121274:LOGIN_DESKTOP::::::', {
       waituntil: "load"
    });

    /* Login */
    await page.type('#P101_USERNAME', 'test', {delay: 20}); // Types slower, like a user
    await page.type('#P101_PASSWORD', 'test_pw', {delay: 0}); // Types slower, like a user
    await page.click('button#P101_LOGIN', { delay: 20 });
    await page.waitForNavigation({waitUntil: 'networkidle2'});

    /* Navigation */
    //page.on('load', () => console.log("Loaded: " + page.url()));
    const inputElement = await page.$('li#t_TreeNav_1');
    await page.waitFor('li#t_TreeNav_1');
    await inputElement.click();
    await page.waitForNavigation({waitUntil: 'networkidle2'});
    await page.click('#NEW_CUSTOMER');

    /* Modal Window */
    const frame = await page.frames()[1];

    /* an old man is not a D-Train */
    function sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
    }

    async function setSelectVal(sel, val) {
      await sleep(1000);
      frame.evaluate((data) => {
           return document.querySelector(data.sel).value = data.val;
       }, {sel, val})
    }

    /* set values */
    await setSelectVal('#P7_CUST_EMAIL', 'testusermail.@email.com');
    await setSelectVal('#P7_CREDIT_LIMIT', '1000');
    await setSelectVal('#P7_CUST_FIRST_NAME', 'Hans1');
    await setSelectVal('#P7_CUST_LAST_NAME', 'Ceylan');
    await setSelectVal('#P7_CUST_STREET_ADDRESS1', 'MyHomeAdress 1');
    await setSelectVal('#P7_CUST_CITY', 'Mannheim');
    await setSelectVal('#P7_CUST_POSTAL_CODE', '20166');
    await setSelectVal('#P7_CUST_STATE', 'DE');

    const create_button = await frame.$('#CREATE_BUTTON');
    await create_button.click();

    console.log("End of File");

    //browser.close();

});
