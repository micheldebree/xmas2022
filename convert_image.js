var Jimp = require('jimp');
var fs = require('fs');

const filenameIn = process.argv[2]
const filenameOut = `${filenameIn}.bin`

Jimp.read(filenameIn, (err, image) => {
  if (err) throw err;

  const scale = image.bitmap.width / 32

  var result = new Uint8Array(200);

  for (y = 0; y < image.bitmap.height; y++) {
    let nrPixelsInLine = 0
    for (x = 0; x < image.bitmap.width; x++) {
      const pixel = image.getPixelColor(x,y)
      const alpha = Jimp.intToRGBA(pixel).a
      nrPixelsInLine += alpha > 128 ? 1 : 0
    }
    result[y] = Math.min(Math.round(nrPixelsInLine / scale), 31)
  }

  fs.writeFileSync(filenameOut, result)
  console.log(filenameOut)

});
