const puppeteer = require('puppeteer')
const devices = require('puppeteer/DeviceDescriptors')

const captureScreenshots = async () => {
  const devicesToEmulate = [
    'iPhone 6',
    'iPhone 6 landscape',
    'iPhone 6 Plus',
    'Nexus 5',
    'Nexus 6',
    'iPad Pro'
  ]

  const browser = await puppeteer.launch()
  const page = await browser.newPage()

  // capture a screenshot of each device we wish to emulate (`devicesToEmulate`)
  for (let device of devicesToEmulate) {
    await page.emulate(devices[device])
    await page.goto('https://stackoverflow.com/')
    await page.screenshot({path: `../images/${device}.png`, fullPage: true})
  }

  await browser.close()
}

captureScreenshots()