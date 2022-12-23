#importonce
// .filenamespace vic
// .namespace vic {

	.const vicBankSize = $4000
	.const vicScreenSize = $400
	.const vicFontSize = $800

	// Set the vic bank to start at
	.macro vicSelectBank(startAddress) {
		.errorif mod(startAddress, vicBankSize) != 0, "startAddess must be a multiple of $4000"
		lda $dd00
		and #%11111100
		ora #%11 - startAddress / vicBankSize
		sta $dd00
	}

	.function vicCalcD018(screenNr, fontNr) {
		.errorif (screenNr >= 16), "screenNr should be below 16"
		.errorif(fontNr >= 8), "fontNr should be below 8"
		.return screenNr << 4 | fontNr << 1
	}

	.macro vicSetupPointers(baseAddress, screenOffset, fontOffset) {
		.errorif mod(screenOffset, vicScreenSize) != 0, "screenOffset must be a multiple op $400"
		.errorif mod(fontOffset, vicFontSize) != 0, "fontOffset must be a multiple op $800"
		.errorif screenOffset > vicBankSize, "screenOffset must be below $4000"
		.errorif fontOffset > vicBankSize, "fontOffset must be below $4000"

		vicSelectBank(baseAddress)
		lda vicCalcD018(fontOffset / vicFontSize, screenOffset / vicScreenSize)
		sta $d018
	}

// }