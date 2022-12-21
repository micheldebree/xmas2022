BasicUpstart2(preview)

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
.macro vicSetGraphicsPointers(screenAddress, charSetAddress) {
	.assert "screenAddress must be a multiple op $400", mod(screenAddress, $400), 0
	.assert "charsetAddress must be a multiple op $800", mod(screenAddress, $800), 0
	.assert "screenAddress must be below $4000", screenAddress < $4000, true
	.assert "charsetAddress must be below $4000", charSetAddress < $4000, true

	.const bitsCharset = charSetAddress / $800
	.const bitsScreen = screenAddress / $400

	// lda #bitsScreen << 4 | bitsCharset << 1
	lda #calcD018(bitsScreen, bitsCharset)
	sta $d018
}

* = $0810

preview:
	sei
	vicSelectBank($4000)
	vicSetGraphicsPointers($0000, $2000)

loop:
	lda #$fa
wait:
	cmp $d012
	bne wait

li:
	ldx #00
	lda d018Values,x
	sta $d018
	lda dd00Values,x
	sta $dd00
	inx
	cpx #48
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

.macro indexD018(nrScreens) {
	.const nrCharSets = 4
	.for (var fi = 0; fi < nrCharSets; fi++) {
		.for (var si = 0; si < nrScreens; si++) {
			.byte calcD018(si, 4 + fi)
		}
	}
}

* = $3000 "d018 and dd00 values"
d018Values:
	indexD018(8); // repeated per bank
	indexD018(4); // $9000-$a000 sees Char ROM so are unusable

dd00Values:
	.for (var i = 0; i < 32; i++) {
		.byte %10 // bank $4000
	}
	.for (var i = 0; i < 32; i++) {
		.byte %01 // bank $8000
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


// fill the screen with 8 different character lines


// bank $4000
// 8 screens
// 4 fonts: line lengtes 0-7, 8-15, 16-23, 24-31
// bank $8000
// 4 fonts: line lengtes 




.macro createCharset(charsPerLine, lineNr) {

	.const maxLineLength = charsPerLine * 8
	.const lineStep = maxLineLength / (2*48) // 48 lines in total

  // 8 lines of characters
	.for (var y =0; y < 8; y++) {

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

	createCharset(32, 0)
	createCharset(32, 1*8)
	createCharset(32, 2*8)
	createCharset(32, 3*8)

* = $8000+$2000 "Charsets bank 2"

	createCharset(32, 4*8)
	createCharset(32, 5*8)
	createCharset(32, 6*8)
	createCharset(32, 7*8)