const puppeteer = require('puppeteer');

(async() => {
    const browser = await puppeteer.launch({
        headless: false,
        timeout: 10000,
        devtools: true
    });

    browser.on('targetcreated', async (target) => {
        console.log(`Created target type ${target.type()} url ${target.url()}`);
        if (target.type() !== 'page') {
            return;
        } else {
            var page = await target.page();
        }
        await page.evaluateOnNewDocument(() => {
            console.log('evaluateOnNewDocument');
        });
    });

    const page = await browser.newPage();

    await page.goto('https://example.com/');

    await page.evaluate(() => {
        var a = document.createElement('a');
        a.href = 'https://example.com/?404';
        a.target = '_blank';
        //a.innerHTML = 'Click me';
        a.innerText = 'Click me';
        a.id = 'click';
        document.body.appendChild(a);
    });

    await page.waitFor(1000);

    await page.click('#click');
    console.log('end of file');
})();
