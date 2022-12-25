var Jimp = require('jimp');
var fs = require('fs');

Jimp.read('tree.png', (err, image) => {
  if (err) throw err;
  // image.resize(80, 200);

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

// console.log(`.byte ${Math.floor(nrPixelsInLine / scale)}`)
  console.log(result.length)
  fs.writeFileSync('tree.bin', result)

});
