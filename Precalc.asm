// TODO:: use more accurate math?

BasicUpstart2(preview)

.const vicBankSize = $4000 // size of one VIC bank
.const screenSize = $400 // size of one text screen
.const fontSize = $800 // size of one font
.const nrBanks = 2 // number of VIC banks to use
.const nrCharsPerLine = 32 // width of the animation in characters
.const maxLineSize = nrCharsPerLine * 8 // max width of a line in pixels
.const nrScreensPerBank = 8 // number of different text screens to use
// the number of fonts that fit in a VIC bank after memory for the screens has been used
.const nrFontsPerBank = (vicBankSize - nrScreensPerBank * screenSize) / fontSize
.const sineLength = 128 // length of the sineTable

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

// Set the vic bank to start at
.macro vicSelectBank(startAddress) {
	.assert "startAddess must be a multiple of $4000", mod(startAddress, $4000), 0
	lda $dd00
	and #%11111100
	ora #%11 - startAddress / $4000
	sta $dd00
}

.function calcD018(screenNr, charSetNr) {
	.return screenNr << 4 | charSetNr << 1
}

// relative to the bank
.macro vicSetGraphicsPointers(baseAddress, screenOffset, fontOffset) {
	.errorif mod(screenOffset,$400) != 0, "screenOffset must be a multiple op $400"
	.errorif mod(fontOffset, $800) != 0, "fontOffset must be a multiple op $800"
	.errorif screenOffset > $4000, "screenOffset must be below $4000"
	.errorif fontOffset > $4000, "fontOffset must be below $4000"

	vicSelectBank(baseAddress)
	lda #calcD018(fontOffset / $800, screenOffset / $400)
	sta $d018
}

* = $0810

preview:
	sei
	vicSetGraphicsPointers($4000, $0000, $2000)

	lda #$01
	ldx #$00
fillcolor:
	sta $d800,x
	sta $d900,x
	sta $da00,x
	sta $db00,x
	inx
	bne fillcolor


loop:
	lda #$ff
wait:
	cmp $d012
	bne wait

li:
	ldx #00

  ldy sineTable,x

	lda d018Values,y
	sta $d018
	lda dd00Values,y
	sta $dd00
	inx
	cpx #sineLength
	bcc skip
	ldx #0
skip:
	stx li+1
	jmp loop


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
			.byte calcD018(si, 4 + fi)
		}
	}
}

* = $3000 "d018 and dd00 values"

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
* = * "Sine table"

sineTable:

.for (var t = 0; t < sineLength; t++) {
	.byte 48 * sin(toRadians(t * 180/sineLength))
}


// Screen data bank $4000

.macro fillScreenWithChars(screenNr) {
	.for (var y = 0; y < screenHeight; y++) {
		.for (var x =0; x < charsPerLine; x++) {
				.byte screenNr * charsPerLine + x
		}
		.for (var x = 0; x < 40-charsPerLine; x++) {
			.byte 0
		}
	}

}

.const charsPerLine = 32
.const nrLines = 256 / charsPerLine
.const screenHeight = 25

.for (var i = 0; i < nrLines; i++) {

	* = $4000 + (i * $400) "Screen bank 1"
	fillScreenWithChars(i);
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

	.const maxLineLength = charsPerLine * 8
	.const lineStep = maxLineLength / (2*48) // 48 lines in total

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
* = $4000+$2000 "Charsets bank 1"

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