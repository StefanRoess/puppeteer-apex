const puppeteer = require('puppeteer');

(async () => {
  async function dumpFrameTree(page, frame, indent) {
      console.log(indent + frame.url());
      const result = await frame.evaluate(() => {
          let retVal = '';
          if (document.doctype) {
              retVal = new XMLSerializer().serializeToString(document.doctype);
          }
          if (document.documentElement) {
              retVal += document.documentElement.outerHTML;
          }
          return retVal;
      });
      console.log(indent + "  " + result.slice(0, 20));
      for (let child of frame.childFrames()) {
          await dumpFrameTree(page, child, indent + '  ');
      }
  }

  const browser = await puppeteer.launch({headless: false});
  const page = await browser.newPage();
  const url = 'http://diy-cellars.space/woodworking-plans-glider/?DIYCellar=301248662559422964';
  await page.goto(url, {waitUntil: 'load'});
  await dumpFrameTree(page, page.mainFrame(), '');
  await browser.close();
})();