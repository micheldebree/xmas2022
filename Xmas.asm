#import "VIC.asm"
#import "Precalc.asm"
#import "RasterIrq.asm"

.var music = LoadSid("ggbond.sid")
.var tree = LoadBinary("tree.png.bin")
.var ball = LoadBinary("ball.png.bin")
.var candle = LoadBinary("candle.png.bin")
.var snowman = LoadBinary("snowman.png.bin")

.const nrLines = 196

BasicUpstart2(start)

* = music.location "Music"
.fill music.size, music.getData(i)

/** {

TODO:
- [X] Map out memory
- [ ] Set up interrupt
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
- [ ] Adjust actual nr of lines from 200
- [ ] Switch images
- [ ] Add colors
- [ ] Optimize by doing precalc in assembler
Ohttps://codebase64.org/doku.php?id=base:fpp-first-line

} */

// global variables and constants {
.const charsPerLine = 32 // characters per line in the screen
.const nrScreens = 256 / charsPerLine // number of different screens with one line repeated
.const nrCharsets = ($4000 - ($400 * nrScreens)) / $800;
.const firstRasterY = $33 - 1
.const d011Value = %00010000 
.var imageAddresses = List(nrLines)
.var colorAddresses = List(nrLines)

// }

* = $8000 "Code"

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

  lda #d011Value
  sta $d011

  vicSetupPointers($4000, $0000, $2000)
  jsr music.init

  lda #$00
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

  jsr replaceImageSnowman

  irqSet(firstRasterY, mainIrq)

// .break
// .break
  lda #$01
  sta $d01a   // Enable raster interrupts and turn interrupts back on
  cli
  jmp *       // Do nothing and let the interrupts do all the work.
}

mainIrq:  {

  irqStabilize()
  wasteCycles(52)

.const currentRasterY = firstRasterY + 3

.label lineIndex = * + 1

  ldx #0

// TODO: count cycles
  .for (var y = 0; y < nrLines; y++) { // unrolled raster code
    lda #badlineD011(d011Value, currentRasterY + y) // trigger badline
    sta $d011
    .eval imageAddresses.set(y, * + 1)
    lda sineTableD018 + tree.get(y) * sineLength,x
    sta $d018 // +4 = 8
    .eval colorAddresses.set(y, * + 1)
    lda #0
    sta $d021
  }
  lda #0
  sta $d021
 wasteCycles(5)

  // open border
  // lda #d011Value & %11110111
  // sta $d011

  inx
  cpx #sineLength
  bne !if+
  jsr replaceImage
!if: // not end of sine
  stx lineIndex

  // inc $d020
  jsr colorShine

  jsr music.play
  // // close border
  // lda #d011Value | %00001000
  // sta $d011

// ack and return
  irqSet(firstRasterY, mainIrq)

  asl $d019
  rti
}

colorShine: {

.label shineIndex = * + 1
    ldy rasterSine
    ldx #40
!while: // x >= 0
    lda shineD800,y
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
shineD800:
.fill 32+12,0
.byte 9,11,8,12,15,7,1,7,15,12,8,11,9,0,0,0
.fill 32,0

}

.align $100
rasterSine:
.fill 128, 32 + 32 * sin(toRadians(i*360/128)) // Generates a sine curve


replaceImage:
.label imageIndex = * + 1
  lda #0
  cmp #3 // nr of images
  bcc !skip+
  lda #0
  sta imageIndex

!skip:
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
    .byte <replaceImageSnowman

imageCodeHi:
    .byte >replaceImageTree
    .byte >replaceImageBall
    // .byte >replaceImageCandle
    .byte >replaceImageSnowman

// image: list of linelengths (0-31), one for each image line
// colors: list of colors, one for each image line

.macro addToHashTable(table, value, address) {
  .eval table.get(value).add(address)
}

.macro replaceImage(image, colors) {

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

* = * "Tree image code"

@replaceImageTree:

  .var treeColors = List(nrLines)
  putColor(treeColors, 0, 5)
  putColor(treeColors, 74, 8)
  putColor(treeColors, 75, 12)
  putColor(treeColors, 76, 5)
  putColor(treeColors, 124, 8)
  putColor(treeColors, 125, 12)
  putColor(treeColors, 126, 5)
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

* = * "Snowman image code"

@replaceImageSnowman:

  .var snowmanColors = List(nrLines)
  putColor(snowmanColors, 0, 11)
  putColor(snowmanColors, 31, 12)
  putColor(snowmanColors, 32, 15)
  putColor(snowmanColors, 33, 1)

  putColor(snowmanColors, 65, 15)
  putColor(snowmanColors, 66, 12)
  putColor(snowmanColors, 67, 15)
  putColor(snowmanColors, 68, 1)

  putColor(snowmanColors, 112, 15)
  putColor(snowmanColors, 113, 12)
  putColor(snowmanColors, 114, 15)
  putColor(snowmanColors, 115, 1)
  putColor(snowmanColors, 190, 15)
  putColor(snowmanColors, 191, 12)
  putColor(snowmanColors, 192, 11)
  replaceImage(snowman, snowmanColors)
