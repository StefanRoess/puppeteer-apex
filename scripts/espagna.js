const puppeteer = require('puppeteer');

(async() => {
  try{
    const browser = await puppeteer.launch({
      headless: false
    });

    const page = await browser.newPage();

    await page.goto('http://www.marca.com/futbol/primera-division/clasificacion.html');


    // to read the map function:
    //https://wiki.selfhtml.org/wiki/JavaScript/Objekte/Array/map
    let table = await page.evaluate(() => {
      const equipos =[
        ...document.querySelectorAll('.equipo')
      ].map((nodoEquipo) => nodoEquipo.innerText);

      const puntos =[
        ...document.querySelectorAll('.total_puntos.pt')
      ].map((nodoPunto) => nodoPunto.innerText);

      return equipos.map((equipo, i) => ({equipo: equipo, puntos: puntos[i]}))
    })

    console.log(table)
    await browser.close()

  } catch (e) {

  }
})()