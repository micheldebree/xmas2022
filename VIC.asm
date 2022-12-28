#importonce
// .filenamespace vic
// .namespace vic {

  // 63 cycles in one line
  // 23 cycles on bad line

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
    .errorif (screenNr >= 16), "screenNr should be below 16 but is " + screenNr
    .errorif(fontNr >= 8), "fontNr should be below 8 but is " + fontNr
    .return screenNr << 4 | fontNr << 1
  }

//  A Bad Line Condition is given at any arbitrary clock cycle, if at the
//  negative edge of �0 at the beginning of the cycle RASTER >= $30 and RASTER
//  <= $f7 and the lower three bits of RASTER are equal to YSCROLL and if the
//  DEN bit was set during an arbitrary cycle of raster line $30.
  .function isBadLine(rasterY, yscroll) {
    .const rasterBits = rasterY & %111
    .const yscrollBits = yscroll & %111
    .const result = (rasterY >= $30 && rasterY <= $f7) && rasterBits == yscrollBits
    .return result
  }

  // calculate the new value for D011 that triggers a bad line on rasterY
  .function badlineD011(currentD011, rasterY) {
    .return (currentD011 & %11111000) | (rasterY & %111)
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
  
.macro vicCopyRomChar(toAddress) {

        lda $01
        pha
        // make rom characters visible
        lda #%00110011
        sta $01
        ldx #0
!while: // x < 256
          .for(var i = 0; i < 8; i++) {
            lda $d000 + (i * $100),x
            sta toAddress + (i * $100),x
          }
          inx
          bne !while-
        pla
        sta $01
}

// }
