// TODO:: use more accurate math?

#import "VIC.asm"

.const nrCharsPerLine = 32 // width of the animation in characters
// .const maxLineLength = nrCharsPerLine * 8
.const maxLineLength = 20 * 8
.const maxLineSize = nrCharsPerLine * 8 // max width of a line in pixels
.const nrScreensPerBank = 8 // number of different text screens to use
// the number of fonts that fit in a VIC bank after memory for the screens has been used
.const nrFontsPerBank = (vicBankSize - nrScreensPerBank * vicScreenSize) / vicFontSize
.const sineLength = 32 // length of the sineTable

// the number of different line lengths we can display
.const nrLineLengths = (nrScreensPerBank * nrFontsPerBank)

.print ("Number of fonts per bank: " + nrFontsPerBank)
.print ("Number of different line lengths: " + nrLineLengths)

// for line x1 to x2, get the byte representing the segment at charIndex
.function lineSegmentBits(x1, x2, charIndex) {
  .var result = 0
  .var charX = charIndex * 8 // x where character starts
  .var mask = %10000000 // start of mask for bitPos 0

  .if ((x1 <= charX) && (x2 >= charX + 8)) {
    .return $ff
  }
  .for (var i=0; i < 8; i++ ) { // for each bit (left to right)
      .var bitPos = charX + i
      .if ((x1 <= bitPos) && (x2 >= bitPos)) {
        .eval result = result | mask
      }
      .eval mask = mask >> 1
  }
// .print ("line segment " + x1 + " to " + x2 + " for char " + charIndex + " is " + result)
  .return result
}

.macro testScreen() {
  .const charsPerLine = 32
  .const lines = 256 / charsPerLine
  .const emptyChars = 40 - charsPerLine

  .for (var y = 0; y < lines; y++) {
    .for (var x = 0; x < charsPerLine; x++) {
      .byte y * charsPerLine + x
    }
    .for (var x = 0; x < emptyChars; x++) {
      .byte 0
    }

  }
}

.function calcD018(lineNr) {
  .var screen = mod(lineNr, nrScreensPerBank) // 8 screens in one bank
  .var font = 4 + (lineNr / nrScreensPerBank)
  .return vicCalcD018(screen, font)
}

* = $3000 "Sine tables"

// Every one of the 32 possible lines is represented
// by a table of $d018 values for each frame of the 'spin'
sineTableD018:
.for (var i = 0; i < nrLineLengths; i++) {
  .for (var t = 0; t < sineLength; t++) {
    .print "Linenr" + i
    .byte calcD018(i * sin(toRadians(t * 180 / sineLength)))
  }
}

* = $9000 "Image"

// the image is a list of pointers to the sinetables
// 1 sinetable = 1 spinning line
image:

.for (var i = 0; i < 200 - nrLineLengths; i++) {
  .byte 0,0 // reserve space
}

.macro fillScreenWithChars(screenNr) {
  .for (var y = 0; y < screenHeight; y++) {
    .for (var x = 0; x < 20; x++) {
        .byte screenNr * nrCharsPerLine + x
    }
    .for (var x = 0; x < 20; x++) {
        .byte screenNr * nrCharsPerLine + x
    }
  }
}

.const nrCharLines = 256 / nrCharsPerLine
.const screenHeight = 25

.for (var i = 0; i < nrCharLines; i++) {
  * = $4000 + (i * $400) "Screen"
  fillScreenWithChars(i);
}

// bank $4000
// 8 screens
// 4 fonts: line lengtes 0-7, 8-15, 16-23, 24-31
// bank $8000
// 4 fonts: line lengtes 

// nrScreen = 8 for bank 1, 4 for bank 2
.macro createCharset(lineNr) {

  .const lineStep = maxLineLength / (2 * nrLineLengths) // 48 lines in total
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
* = $4000 + $2000 "Charsets bank 1"

  createCharset(0*8)
  createCharset(1*8)
  createCharset(2*8)
  createCharset(3*8)

