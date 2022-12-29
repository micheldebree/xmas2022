#import "VIC.asm"
#import "Precalc.asm"
#import "RasterIrq.asm"

.var music = LoadSid("ggbond.sid")
.var tree = LoadBinary("tree.png.bin")
.var ball = LoadBinary("ball.png.bin")
.var candle = LoadBinary("candle.png.bin")
.var snowman = LoadBinary("snowman.png.bin")
.var bell = LoadBinary("bell.png.bin")
.var star = LoadBinary("star.png.bin")

BasicUpstart2(start)

* = music.location "Music"
.fill music.size, music.getData(i)

/** { TODO

- [X] Map out memory
- [X] Set up interrupt
- [X] Create screens
- [X] Create fonts
- [X] Create $d018 table with ob entry for each line
- [X] Create $dd00 table with entry for each line
- [X] Make spinning rectangle (no raster code yet)
- [X] Create sinetable for each line
- [X] Create image table
- [X] Add raster code
- [X] Invert font
- [X] Add an outline -> too ugly
- [X] Adjust actual nr of lines from 200
- [X] Switch images
- [X] Add colors
- [X] Optimize by doing precalc in assembler -> nah
- [X] Use 25 column mode without artifacts -> minor artifacts
- [ ] Add scrolltext

https://codebase64.org/doku.php?id=base:fpp-first-line
https://c64os.com/post/6502instructions

} */

// global variables and constants {
.const nrLines = 195
.const charsPerLine = 32 // characters per line in the screen
.const nrScreens = 256 / charsPerLine // number of different screens with one line repeated
.const nrCharsets = ($4000 - ($400 * nrScreens)) / $800;
.const firstRasterY = $33 - 1
// .const d011Value = %00010000 // 24 rows
.const d011Value = %00011111 // 25 rows 
.var imageAddresses = List(nrLines)
.var colorAddresses = List(nrLines)
.var zpWord = $fa

// in the border
.var romFontCopy = $1000
.var spriteData = $2000
.var screenAddressInBorder = $0400


// }

* = romFontCopy "ROM font"

.fill $800,0

* = $7d00 "Code"

nmi:
  rti

start: {
  sei             // Turn off interrupts
  jsr $ff81       // ROM Kernal function to clear the screen
  lda #%00110101
  sta $01         // Turn off Kernal ROM

  lda #$7f
  sta $dc0d      // no timer IRQs
  lda $dc0d      // acknowledge CIA interrupts

  lda #<nmi
  sta $fffa
  lda #>nmi
  sta $fffb      // dummy NMI (Non Maskable Interupt) to avoid crashing due to RESTORE

.const yScroll = 0

  lda #$ff
  sta $d015

  ldy #8
  .for (var i =0; i < 8; i++) {
    lda #24 + 24 * i
    sta $d000 + 2 * i
    sty $d001 + 2 * i
    lda #(spriteData / $40) + i
    sta screenAddressInBorder + $03f8 + i
  }
  lda #0
  sta $d010


  lda #1
  sta $d027

  lda #0
  sta $3fff

  vicCopyRomChar(romFontCopy)
  vicSetupPointers($4000, $0000, $2000)

  jsr copyA
  jsr music.init

  lda #$01
  sta $d020
  sta $d021

fillcolor: {
  sta $d800,x
  sta $d900,x
  sta $da00,x
  sta $db00,x
  inx
  bne fillcolor
}

  jsr replaceImageBell
  // jsr makeBlack

  irqSet(firstRasterY, mainIrq)

  lda #$01
  sta $d01a   // Enable raster interrupts and turn interrupts back on
  cli
  jmp *       // Do nothing and let the interrupts do all the work.
}

mainIrq:  {

  irqStabilize()
  wasteCycles(93)
  vicSelectBank($4000)

.const currentRasterY = firstRasterY + 3

.label lineIndex = * + 1
  ldx #16

  // unrolled raster code,
  // each iteration has exact duration of one raster line
  .for (var y = 0; y < nrLines; y++) {

    // trigger badline
    lda #badlineD011(d011Value, currentRasterY + y)
    sta $d011

    // save the address so we can modify the code
    .eval imageAddresses.set(y, * + 1)
    lda sineTableD018 + tree.get(y) * sineLength,x
    sta $d018

    // save the address so we can modify the code
    .eval colorAddresses.set(y, * + 1)
    lda #0
    sta $d021
  }

// we're now at the end of the visible screen

// .break
  lda #0
  sta $d021
  vicSelectBank(0)
  // use screen at $0400 and font at $3000
  lda #vicCalcD018(1, 5)
  sta $d018

  // open border
  lda #d011Value & %11110111
  sta $d011
  // .break

  inx
  cpx #sineLength
  bne !if+ // not end of sine period
    jsr replaceImage

!if:
  stx lineIndex

  // inc $d020
  jsr colorShine
  jsr music.play
  jsr scroll

  // // close border
  lda #d011Value | %00001000
  sta $d011

// ack and return
  irqSet(firstRasterY, mainIrq)

  asl $d019
  rti
}

colorShine: {

.label shineIndex = * + 1
    ldy shineSine
    ldx #40
!while: // x >= 0
      lda shineColors,y
      sta $d800-1,x
      iny
      dex
      bne !while-
    inc shineIndex
    lda shineIndex
    and #%01111111
    sta shineIndex
    rts

.align $100

shineColors:
.fill 32+12,0
.byte 9,11,8,12,15,7,1,7,15,12,8,11,9,0,0,0
.fill 32,0

.align $100

shineSine:

.fill 128, 32 + 32 * sin(toRadians(i*360/128)) 
}


copyA:
.for (var i = 0; i < 8; i++) {
  ldx #0
  ldy #0
!while: // x < 8
    lda romFontCopy + 8,x
    sta spriteData + (i * $40),y
    inx
    iny
    iny
    iny
    cpx #8
    bne !while-
}
rts




// .label spriteSineIndex = * + 1
  

scroll:

  ldx #0
  stx spriteMSBs
  // lda #0
  // sta zpWord
  // sta zpWord + 1

   .for (var i = 0; i < 8; i++) {
      lda spritePosXLo + i
      sta $d000 + 2 * i
      lda spritePosXHi + i
      clc
      adc #$ff
      ror spriteMSBs

      .if (i == 0) { 
// .break      
        }
      lda spritePosXLo + i
      sec
      sbc #1
      sta spritePosXLo + i
      lda spritePosXHi + i
      sbc #0
      and #1
      sta spritePosXHi + i
      bcs !if+
      lda #24+320
      sta spritePosXLo + i
      lda #1
      sta spritePosXHi + i

!if:
  }



.label spriteMSBs = * + 1
  lda #0
  sta $d010

  // inx
  // stx spriteSineIndex
  // inc spriteScrollOffset
  rts

spritePosXLo:
  .fill 8, (24 + 40 * i) & $ff

spritePosXHi:
  .fill 8, (24 + 40 * i) / $100
  

spriteScrollOffset:
  .word $0000

spriteSine:
.fill 256, 32 + 32 * sin(toRadians(i*360/256)) 

replaceImage:

.label imageIndex = * + 1
  lda #0
  cmp #5 // if max image nr reached
  bcc !else+ 
    lda #0
    sta imageIndex

!else:
  tax
  lda imageCodeLo,x
  sta imageJsr
  lda imageCodeHi,x
  sta imageJsr + 1

.label imageJsr = * + 1
  jsr replaceImageTree
  inc imageIndex
  ldx #0
  rts

imageCodeLo:
    .byte <replaceImageTree
    .byte <replaceImageBall
    // .byte <replaceImageCandle
    .byte <replaceImageBell
    .byte <replaceImageSnowman
    .byte <replaceImageStar

imageCodeHi:
    .byte >replaceImageTree
    .byte >replaceImageBall
    .byte >replaceImageBell
    .byte >replaceImageSnowman
    .byte >replaceImageStar

// image: list of linelengths (0-31), one for each image line
// colors: list of colors, one for each image line

.macro addToHashTable(table, value, address) {
  .eval table.get(value).add(address)
}

.macro replaceImage(image, colors) {

  // first line is always black to hide stupid artefact
  .eval colors.set(0,0)

  // optimize code by only doing lda #$xx once for every unique value
  // and storing it in one or more addresses
  .const hash = Hashtable()
  .for (var i = 0; i < 256; i++) {
    .eval hash.put(i, List())
  }

  .for (var y = 0; y < nrLines; y++) {
    .const sineStart = sineTableD018 + image.get(y) * sineLength
    .const imgAddress = imageAddresses.get(y)
    .const colorAddress = colorAddresses.get(y)
    addToHashTable(hash, <sineStart, imgAddress)
    addToHashTable(hash, >sineStart, imgAddress + 1)
    addToHashTable(hash, colors.get(y), colorAddress)
  }

  .var lastI = 0;
  .for (var i = 0; i < 256; i++) {
    .const addresses = hash.get(i)
    .if (addresses.size() > 0) {
      .if (i == lastI + 1) {
        inx
      }
      else {
        ldx #i
      }
      .for (var ii = 0; ii < addresses.size(); ii++) {
        stx addresses.get(ii)
      }
      .eval lastI = i
    }
  }

  rts
}

.macro putColor(colorList, startLine, color) {
  .for (var i = startLine; i < colorList.size(); i++) {
    .eval colorList.set(i, color)
   }
}

@makeBlack:

lda #0
.for (var y = 0; y < nrLines; y++) {
  sta colorAddresses.get(y)
}
rts

* = * "Tree image code"

@replaceImageTree:

  .var treeColors = List(nrLines)
  putColor(treeColors, 0, 5)
  putColor(treeColors, 74, 8)
  putColor(treeColors, 75, 5)
  putColor(treeColors, 124, 8)
  putColor(treeColors, 125, 5)
  putColor(treeColors, 178,11)
  putColor(treeColors, 179, 9)
  putColor(treeColors, 181, 8)
  replaceImage(tree, treeColors)

* = * "Ball image code"

@replaceImageBall:

  .var ballColors = List(nrLines)
  putColor(ballColors, 0, 11)
  putColor(ballColors, 1, 12)
  putColor(ballColors, 2, 15)
  putColor(ballColors, 25, 1)
  putColor(ballColors, 26, 15)

  putColor(ballColors, 50, 7)
  putColor(ballColors, 51, 13)
  putColor(ballColors, 52, 3)

  putColor(ballColors, 190, 15)
  putColor(ballColors, 191, 14)
  putColor(ballColors, 192, 6)
  replaceImage(ball, ballColors)

* = * "Candle image code"

@replaceImageCandle:

  .var candleColors = List(nrLines)
  putColor(candleColors, 0, 1)
  replaceImage(candle, candleColors)

* = * "Star image code"

@replaceImageStar:

  .var starColors = List(nrLines)
  putColor(starColors, 0, 7)
  replaceImage(star, starColors)

* = * "Bell image code"

@replaceImageBell:

  .var bellColors = List(nrLines)
  putColor(bellColors, 0, 1)
  putColor(bellColors, 2, 7)
  putColor(bellColors, 9, 1)
  putColor(bellColors, 10, 7)
  putColor(bellColors, 160, 11)
  putColor(bellColors, 161, 12)
  putColor(bellColors, 162, 15)
  putColor(bellColors, 191, 12)
  putColor(bellColors, 192, 11)
  replaceImage(bell, bellColors)

* = * "Snowman image code"

@replaceImageSnowman:

  .var snowmanColors = List(nrLines)
  putColor(snowmanColors, 0, 11)
  putColor(snowmanColors, 31, 12)
  putColor(snowmanColors, 32, 15)
  putColor(snowmanColors, 33, 1)

  putColor(snowmanColors, 66, 15)
  putColor(snowmanColors, 67, 1)

  putColor(snowmanColors, 113, 15)
  putColor(snowmanColors, 114, 1)
  putColor(snowmanColors, 190, 15)
  putColor(snowmanColors, 191, 12)
  putColor(snowmanColors, 192, 11)
  replaceImage(snowman, snowmanColors)
