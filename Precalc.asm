#import "VIC.asm"
/*

Calculate fonts and screens to give 32 possible line lengths
at any y-position.

Calculate 32 sinetables of $d018 values representing all the
phases of one 'spin' for each line length

*/

.var font = LoadBinary("marvin-charmar2x2.charset")
.const nrCharsPerLine = 20 // width of the animation in characters
.const nrCharLines = 8
.const maxLineLength = 20 * 8
.const maxLineSize = nrCharsPerLine * 8 // max width of a line in pixels
.const nrScreensPerBank = 8 // number of different text screens to use
// the number of fonts that fit in a VIC bank after memory for the screens has been used
.const nrFontsPerBank = (vicBankSize - nrScreensPerBank * vicScreenSize) / vicFontSize
.const sineLength = 32 // length of the sineTable

// the number of different line lengths we can display
.const nrLineLengths = (nrScreensPerBank * nrFontsPerBank)
.const invertFont = true // use inverted fonts so we can switch color with $d021

// for line x1 to x2, get the byte representing the segment at charIndex
.function lineSegmentBits(x1, x2, charIndex) {
  .var result = 0
  .var charX = charIndex * 8 // x where character starts
  .var mask = %10000000 // start of mask for bitPos 0

  // shortcut: if line overlaps char completely, all bits are set
  .if ((x1 <= charX) && (x2 >= charX + 8)) {
    .return invertFont ? 0 : $ff
  }

  .for (var i=0; i < 8; i++ ) { // for each bit (left to right)
      .var bitPos = charX + i
      .if ((x1 <= bitPos) && (x2 >= bitPos)) {
        .eval result = result | mask
      }
      .eval mask = mask >> 1
  }
  .if (invertFont) {
    .eval result = result ^ %11111111
  }
  .return result
}

.function calcD018(lineNr) {
  .var screen = mod(lineNr, nrScreensPerBank) // 8 screens in one bank
  .var font = 4 + (lineNr / nrScreensPerBank)
  .return vicCalcD018(screen, font)
}

* = $0900 "Sine tables"

// Every one of the 32 possible lines is represented
// by a table of $d018 values for each frame (of 32) of the 'spin'
// one 'spin' is actually a bounce, so 180 degrees instead of 360
sineTableD018:
.for (var i = 0; i < nrLineLengths; i++) {
  .for (var t = 0; t < sineLength; t++) {
    .byte calcD018(i * sin(toRadians(t * 180 / sineLength)))
  }
}

.macro fillScreenWithChars(screenNr) {
  // for some reason we only need the first line to be filled
  // not sure why
  .for (var x = 0; x < 20; x++) {
      .byte screenNr * nrCharsPerLine + x
  }
  .for (var x = 0; x < 20; x++) {
      .byte screenNr * nrCharsPerLine + x
  }
}

.for (var i = 0; i < nrCharLines; i++) {
  * = $4000 + (i * $400) "Screen"
  fillScreenWithChars(i);
}

.macro createCharset(lineNr) {

  .const lineStep = maxLineLength / (2 * nrLineLengths)
  .const middle = maxLineLength / 2

  // 8 lines of characters
  .for (var y =0; y < nrScreensPerBank; y++) {

    .const lineLength = (y + lineNr) * lineStep
    .const x1 = middle - lineLength
    .const x2 = middle + lineLength

    // for all chars on the line
    .for (var x = 0; x < nrCharsPerLine; x++) {
      // each char is 8 pixels high
      .for (var i = 0; i < 8; i++) {
        .byte lineSegmentBits(x1, x2, x)
      }
    }
  }
}

// fill the charset
* = $4000 + $2000

* = * "Font"
.align $800
  createCharset(0*8)
* = * "Font"
.align $800
  createCharset(1*8)
* = * "Font"
.align $800
  createCharset(2*8)
* = * "Font"
.align $800
  createCharset(3*8)

