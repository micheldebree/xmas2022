// 
// Convert an image of height y to a list of size y with the number of
// non-transparent pixels on each horizontal line

var Jimp = require('jimp');
var fs = require('fs');

const filenameIn = process.argv[2]
const filenameOut = `${filenameIn}.bin`

Jimp.read(filenameIn, (err, image) => {
  if (err) throw err;

  const scale = image.bitmap.width / 31

  var result = new Uint8Array(image.bitmap.height);

  for (y = 0; y < image.bitmap.height; y++) {
    let nrPixelsInLine = 0
    for (x = 0; x < image.bitmap.width; x++) {
      const alpha = Jimp.intToRGBA(image.getPixelColor(x,y)).a
      nrPixelsInLine += alpha > 128 ? 1 : 0
    }
    result[y] = nrPixelsInLine / scale
  }

  fs.writeFileSync(filenameOut, result)
  console.log(filenameOut)
});
