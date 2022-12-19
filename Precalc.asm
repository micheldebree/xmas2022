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
	// .print("line segment " + x1 + " to " + x2 + " for char " + charIndex + " is " + result)
	.return result
}

.macro calcCharset(nrLines, maxWidth) {

	.const middle = maxWidth / 2
	.const step = middle / nrLines

	.for (var i = 0; i < nrLines; i++)	{

		.const length = i * step;
		.const x1 = middle - length
		.const x2 = middle + length




	}

}


// Set the vic bank to start at
.macro vicSelectBank(startAddress) {
	.assert "startAddess must be a multiple of $4000", mod(startAddress, $4000), 0
	lda $dd00
	and #%11111100
	ora #%11 - startAddress / $4000
	sta $dd00
}

// relative to the bank
.macro vicSetGraphicsPointers(screenAddress, charSetAddress) {
	.assert "screenAddress must be a multiple op $400", mod(screenAddress, $400), 0
	.assert "charsetAddress must be a multiple op $800", mod(screenAddress, $800), 0
	.assert "screenAddress must be below $4000", screenAddress < $4000, true
	.assert "charsetAddress must be below $4000", charSetAddress < $4000, true

	.const bitsCharset = charSetAddress / $800
	.const bitsScreen = screenAddress / $400

	lda #bitsScreen << 4 | bitsCharset << 1
	sta $d018
}

* = $0810

preview:
	sei

	// select VIC bank
	// lda $dd00
	// and #%11111100
	// ora #%10 // 11 = $0000, 10 = $4000, 01 = $8000, 00 = $c000
	// sta $dd00

	vicSelectBank($4000)

	// screen at $0000, chars at 4 * $0800 = $2000
	// lda (%0000 << 3) | ($2000 / 4)
	// sta $d018
	vicSetGraphicsPointers($0000, $2000)

	// lda #%00000100
	// sta $d018
	jmp *

* = $4000

// fill the screen with 8 different character lines
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


// fill the charset
* = $6000

	.const maxLineLength = charsPerLine * 8
	.const lineStep = maxLineLength / 128 // 64 lines in total


  // 8 lines of characters
	.for (var y =0; y < 8; y++) {

		.const lineLength = y * lineStep 
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