// TODO:: use more accurate math?
#import "VIC.asm"

.const nrBanks = 2 // number of VIC banks to use
.const nrCharsPerLine = 32 // width of the animation in characters
.const maxLineLength = nrCharsPerLine * 8
.const maxLineSize = nrCharsPerLine * 8 // max width of a line in pixels
.const nrScreensPerBank = 8 // number of different text screens to use
// the number of fonts that fit in a VIC bank after memory for the screens has been used
.const nrFontsPerBank = (vicBankSize - nrScreensPerBank * vicScreenSize) / vicFontSize
.const sineLength = 128 // length of the sineTable

// the number of different line lengths we can display
// the second bank cannot use $9000-$a000, giving us 4 screens instead of 8
.const nrLineLengths = (nrScreensPerBank * nrFontsPerBank) + (nrScreensPerBank / 2 * nrFontsPerBank)

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

.macro indexD018(nrScreens, nrFonts) {
  .for (var fi = 0; fi < nrFonts; fi++) {
    .for (var si = 0; si < nrScreens; si++) {
      .byte vicCalcD018(si, 4 + fi)
    }
  }
}

* = $2000 "d018 and dd00 values"

d018Values:
  indexD018(8, 4)
  indexD018(4, 4) // $9000-$a000 sees Char ROM so are unusable

dd00Values:
  .for (var i = 0; i < 4 * 8; i++) {
    .byte %10 // bank $4000
  }
  .for (var i = 0; i < 4 * 4; i++) {
    .byte %01 // bank $8000
  }

.align $100

* = * "Sine tables"

sineTable:

.for (var i = 0; i < nrLineLengths; i++) {
  .for (var t = 0; t < sineLength; t++) {
    .byte i * sin(toRadians(t * 180/sineLength))
  }
}


// Screen data bank $4000

.macro fillScreenWithChars(screenNr) {
  .for (var y = 0; y < screenHeight; y++) {
    .for (var x =0; x < nrCharsPerLine; x++) {
        .byte screenNr * nrCharsPerLine + x
    }
    .for (var x = 0; x < 40 - nrCharsPerLine; x++) {
      .byte 0
    }
  }

}

.const nrCharLines = 256 / nrCharsPerLine
.const screenHeight = 25

.for (var i = 0; i < nrCharLines; i++) {
  * = $4000 + (i * $400) "Screen bank 1"
  fillScreenWithChars(i);
}

// bank 2 cannot use $9000-$a000 so has twice as few screens
.for (var i = 0; i < nrCharLines  / 2; i++) {
  * = $8000 + (i * $400) "Screen bank 2"
  fillScreenWithChars(i);
}

// * = $4000
  // testScreen()


// fill the screen with 8 different character lines


// bank $4000
// 8 screens
// 4 fonts: line lengtes 0-7, 8-15, 16-23, 24-31
// bank $8000
// 4 fonts: line lengtes 


// nrScreen = 8 for bank 1, 4 for bank 2
.macro createCharset(charsPerLine, lineNr, nrScreens) {

  .const lineStep = maxLineLength / (2 * nrLineLengths) // 48 lines in total

  // 8 lines of characters
  .for (var y =0; y < nrScreens; y++) {

    .const lineLength = (y + lineNr) * lineStep
    .const middle = maxLineLength / 2
    .const x1 = middle - lineLength
    .const x2 = middle + lineLength

    // for all chars on the line
    .for (var x = 0; x < charsPerLine; x++) {
      // each char is 8 pixels high
      .for (var i=0; i < 8; i++) {
        .byte lineSegmentBits(x1, x2, x)
      }
    }
  }
}



// fill the charset
* = $4000 + $2000 "Charsets bank 1"

  createCharset(32, 0, 8)
  createCharset(32, 1*8, 8)
  createCharset(32, 2*8, 8)
  createCharset(32, 3*8, 8)

* = $8000 + $2000 "Charsets bank 2"

  createCharset(32, 4*8, 4)
  .fill $400, 0
  createCharset(32, 36, 4)
  .fill $400, 0
  createCharset(32, 40, 4)
  .fill $400, 0
  createCharset(32, 44, 4)
  .fill $400, 0
