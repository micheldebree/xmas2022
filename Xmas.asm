#import "VIC.asm"
#import "Precalc.asm"
#import "RasterIrq.asm"

.const debug = false

.const music = LoadSid("ggbond.sid")
.const tree = LoadBinary("tree.png.bin")
.const ball = LoadBinary("ball.png.bin")
.const candle = LoadBinary("candle.png.bin")
.const snowman = LoadBinary("snowman.png.bin")
.const bell = LoadBinary("bell.png.bin")
.const star = LoadBinary("star.png.bin")
.const soldier = LoadBinary("soldier.png.bin")
.const angel = LoadBinary("angel.png.bin")

BasicUpstart2(start)

* = music.location "Music"
.fill music.size, music.getData(i)

/**  TODO

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

 */

// global variables and constants 

// nr of lines in the big image
.const nrLines = 195

.const firstRasterY = $33 - 1
// .const d011Value = %00010000 // 24 rows
.const d011Value = %00011111 // 25 rows 
.var imageAddresses = List(nrLines)
.var colorAddresses = List(nrLines)

// stuff in the border
.const spriteData = $2000
.const screenAddressInBorder = $0400
.const spritePointers = screenAddressInBorder + $03f8
.const firstPointer = spriteData / $40
.const spriteSineAmp = 32
.const spriteSpacing = (320 + spriteSineAmp * 2) / (8-1)

// load 2x2 charset and convert to sprites, one per character
spritesFrom2x2Char(LoadBinary("marvin-charmar2x2.charset"), spriteData)

* = $7d00 "Code"

nmi:
  rti

start:
  sei

  // clear screen
  jsr $ff81

setupIrq: {{
  // turn off Kernal ROM
  lda #%00110101
  sta $01

  // no timer IRQs
  lda #$7f
  sta $dc0d
  // acknowledge CIA interrupts
  lda $dc0d

  // dummy NMI (Non Maskable Interupt)
  // to avoid crashing due to RESTORE
  lda #<nmi
  sta $fffa
  lda #>nmi
  sta $fffb

  irqSet(firstRasterY, mainIrq)
}}

setupSprites: {{
  lda #$ff
  sta $d015
  ldy #$fa
  .for (var i = 0; i < 8; i++) {
    sty $d001 + 2 * i
    lda #firstPointer + (debug ? 1 : 0)
    sta spritePointers + i
    lda #1
    sta $d027 + i
  }
}}

turnScreenBlack: {{
  lda #debug ? 1 : 0
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
}}

  jsr replaceImageTree
  .if (!debug) {
    jsr makeBlack 
  }
  jsr music.init

  // enable raster interrupts and turn interrupts back on
  lda #$01
  sta $d01a
  cli
  // do nothing and let the interrupts do all the work.
  jmp *

mainIrq:  {{

  irqStabilize()
  wasteCycles(93)
  vicSelectBank($4000)

.const currentRasterY = firstRasterY + 3

.label lineIndex = * + 1
  ldx #16

  // unrolled raster code,
  // each iteration has exact duration of one raster line
  .for (var y = 0; y < nrLines; y++) {{

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
  }}

// we're now at the end of the visible screen


  lda #debug ? 2 : 0
  sta $d021
  wasteCycles(32)
  vicSelectBank(0)
  // use screen at $0400 and font at $3800
  lda #vicCalcD018(1, 7)
  sta $d018

  // open border
  lda #d011Value & %11110111
  sta $d011

  bit animationEnabled
  bvc !else+
    // if animation enabled
    inx

!else:
  cpx #sineLength
  bne !else+
    // if at end of sine period
    jsr replaceImage

!else:
  stx lineIndex

  lda frameCount+1
  cmp #2
  bne !else+
    // if framecount reached
    lda #$ff
    sta animationEnabled

!else:

  // inc $d020
  jsr colorShine
  jsr music.play
  jsr scroll
  jsr advanceFrame

  // // close border
  lda #d011Value | %00001000
  sta $d011

// ack and return
  irqSet(firstRasterY, mainIrq)
  asl $d019
  rti

animationEnabled:
  .byte 0

}}

frameCount:
  .word 0

advanceFrame:
  inc frameCount
  bne !else+
    // if overflowed
    inc frameCount + 1
!else:
  rts

colorShine: {{

.label shineIndex = * + 1

    ldy shineSine + $20
    ldx #40

!while: // x >= 0
      lda shineColors,y
      sta $d800-1,x
      iny
      dex
      bne !while-

    bit shineEnabled
    bvc !else+
      // if effect is enabled
      inc shineIndex
      lda shineIndex
      and #%01111111
      sta shineIndex
      cmp #$20
      bne !else+
        jmp flipShineEnabled

  !else:
    dec shineDelay
    bne !else+
      // if delay reached zero
flipShineEnabled:
      lda shineEnabled
      eor #$ff
      sta shineEnabled

  !else:
    rts

shineDelay:
  .byte $40

shineEnabled:
  .byte 0

.align $100

shineColors:
  .fill 32+12,0
  // .byte 9,11,8,12,15,7,1,7,15,12,8,11,9,0,0,0
  .byte 9,2,8,10,15,7,1,7,15,10,8,2,9,0,0,0
  .fill 32,0

.align $100

shineSine:
  .fill 128, 32 + 32 * sin(toRadians(i * 360 / 128)) 

}}

scroll: {{

  ldx #0
  stx spriteMSBs

   .for (var i = 0; i < 8; i++) {
      lda spriteCalcXLo + i
      sta $d000 + 2 * i
      lda spriteCalcXHi + i
      clc
      adc #$ff
      ror spriteMSBs

      lda spritePosXLo + i
      sec
      sbc #3
      sta spritePosXLo + i
      lda spritePosXHi + i
      sbc #0
      and #1
      sta spritePosXHi + i
      bcs !else+
      // sprite is 'dirty', meaning it should be replaced soon
      lda #$ff
      sta spriteDirty + i

!else:
      bit spriteDirty + i
      bvc !else+

       lda spritePosXHi + i
       cmp #1
       bcc !else+ 
       lda spritePosXLo + i
        cmp #0 - spriteSineAmp * 2
        bcs !else+
        // reset sprite x to far right
        // and get next char
        lda #24 + spriteSpacing * 8 - spriteSineAmp * 2 
        sta spritePosXLo + i
         jsr getNextChar
         sta spritePointers + i
         lda #0
         sta spriteDirty + i
!else:

  }

.label spriteMSBs = * + 1
  lda #0
  sta $d010

.label spriteSineIndex = * + 1
  ldx #0
  .for (var i = 0; i < 8; i++) {
    lda spritePosXLo + i
    clc
    adc spriteSine + 16 * i,x
    sta spriteCalcXLo + i
    lda spritePosXHi + i
    adc #0
    and #1
    sta spriteCalcXHi + i

!else:

  }
   inc spriteSineIndex 
   lda spriteSineIndex
   and #%01111111
   sta spriteSineIndex
  .label spriteColorIndex = * + 1
        ldx #0
        lda spriteColors,x
        .for (var i = 0; i < 8; i++) {
          sta $d027 + i
        }
        inc spriteColorIndex
        lda spriteColorIndex
        and #%00011111
        sta spriteColorIndex
  rts

getNextChar: {
.label scrollTextIndex = * + 1

        lda scrollText
        cmp #0
        bne !else+

          // if end of scroll reached
          lda #<scrollText
          sta scrollTextIndex
          lda #>scrollText
          sta scrollTextIndex+1
          jmp getNextChar
  !else:
        clc
        adc #firstPointer
        inc scrollTextIndex
        bne !skip+
        inc scrollTextIndex + 1

  !skip:


        rts
}

spritePosXLo:
  .fill 8, 24 + spriteSpacing * i

spriteCalcXLo:
  .fill 8, 0

spritePosXHi:
  .fill 8, (24 + spriteSpacing * i) / $100

spriteCalcXHi:
  .fill 8, 0

spriteDirty:
  .fill 8, 0

spriteColors:
  .byte 9,2,8,10,15,7,1,1,1,1,1,1,1,1,1,1
  .byte 1,1,1,1,1,1,1,1,1,7,15,10,8,2,9,0

.align $100
spriteSine:
.fill 128, spriteSineAmp + spriteSineAmp * sin(toRadians(i * 360 / 128))
.fill 128, spriteSineAmp + spriteSineAmp * sin(toRadians(i * 360 / 128))

scrollText:
  .encoding "screencode_mixed"
  .text "         i wish you all a sparkling and healthy 2023!   a special warm and sloppy brohug to:  yavin  laxity  jch  smc genius  honcho magic  jack-paw-judi  sander  drax reyn vincenzo  stinsen  statler  waldorf  animal  hires  moren  it was fun working and chatting with you guys, thanks for keeping the scene alive!     and a special thanks to jez for setting up the c64.chat mastodon server!      "
  .byte 0

}}

replaceImage:

.label imageIndex = * + 1
  lda #0
  cmp #8 // if max image nr reached
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
    .byte <replaceImageCandle
    .byte <replaceImageBell
    .byte <replaceImageSnowman
    .byte <replaceImageStar
    .byte <replaceImageSoldier
    .byte <replaceImageAngel

imageCodeHi:
    .byte >replaceImageTree
    .byte >replaceImageBall
    .byte >replaceImageCandle
    .byte >replaceImageBell
    .byte >replaceImageSnowman
    .byte >replaceImageStar
    .byte >replaceImageSoldier
    .byte >replaceImageAngel

// image: list of linelengths (0-31), one for each image line
// colors: list of colors, one for each image line

.macro addToHashTable(table, value, address) {
  .eval table.get(value).add(address)
}

.macro replaceImage(image, colors) {

  // first line is always black to hide stupid artifact
  .if (!debug) {
    .eval colors.set(0,0)
  }

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
      // save one byte if we can do inx
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

makeBlack:

lda #0

.for (var y = 0; y < nrLines; y++) {
  sta colorAddresses.get(y)
}
rts

* = * "Tree image code"

replaceImageTree:

  .var treeColors = List(nrLines)
  putColor(treeColors, 0, 5)
  putColor(treeColors, 178,11)
  putColor(treeColors, 179, 9)
  putColor(treeColors, 181, 8)
  replaceImage(tree, treeColors)

* = * "Ball image code"

replaceImageBall:

  .var ballColors = List(nrLines)
  putColor(ballColors, 0, 15)
  putColor(ballColors, 25, 1)
  putColor(ballColors, 26, 15)
  putColor(ballColors, 50, 7)
  putColor(ballColors, 51, 13)
  putColor(ballColors, 52, 3)

  replaceImage(ball, ballColors)

* = * "Candle image code"

replaceImageCandle:

  .var candleColors = List(nrLines)
  putColor(candleColors, 0, 7)
  putColor(candleColors, 60, 11)
  putColor(candleColors, 68, 1)
  putColor(candleColors, 173, 8)
  replaceImage(candle, candleColors)

* = * "Star image code"

replaceImageStar:

  .var starColors = List(nrLines)
  putColor(starColors, 0, 7)
  replaceImage(star, starColors)

* = * "Bell image code"

replaceImageBell:

  .var bellColors = List(nrLines)
  putColor(bellColors, 0, 8)
  putColor(bellColors, 10, 2)
  putColor(bellColors, 160, 11)
  putColor(bellColors, 161, 12)
  putColor(bellColors, 162, 15)
  replaceImage(bell, bellColors)

* = * "Snowman image code"

replaceImageSnowman:

  .var snowmanColors = List(nrLines)
  putColor(snowmanColors, 0, 11)
  putColor(snowmanColors, 32, 12)
  putColor(snowmanColors, 33, 15)
  putColor(snowmanColors, 34, 1)
  putColor(snowmanColors, 66, 15)
  putColor(snowmanColors, 67, 1)
  putColor(snowmanColors, 113, 15)
  putColor(snowmanColors, 114, 1)
  replaceImage(snowman, snowmanColors)

* = * "Soldier image code"

replaceImageSoldier:

  .var soldierColors = List(nrLines)
  putColor(soldierColors, 0, 2)
  putColor(soldierColors, 40, 11)
  putColor(soldierColors, 49, 2)
  putColor(soldierColors, 50, 10)
  putColor(soldierColors, 67, 15)
  putColor(soldierColors, 72, 2)
  putColor(soldierColors, 144, 9)
  putColor(soldierColors, 145, 8)
  putColor(soldierColors, 166, 9)
  putColor(soldierColors, 174, 0)
  putColor(soldierColors, 175, 11)
  replaceImage(soldier, soldierColors)

* = * "Soldier image code"

replaceImageAngel:

  .var angelColors = List(nrLines)
  putColor(angelColors, 0, 10)
  putColor(angelColors, 40, 1)
  replaceImage(angel, angelColors)
