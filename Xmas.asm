#import "VIC.asm"
#import "Precalc.asm"
#import "RasterIrq.asm"

.var music = LoadSid("ggbond.sid")
.var tree = LoadBinary("tree.png.bin")
.var ball = LoadBinary("ball.png.bin")

.const nrLines = 194

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
.const d011Value = %00010000 // 24 rows
.var ImageAddresses = List(nrLines)
.var colorList = List(nrLines)
.var treeColors = List(nrLines)
.var ballColors = List(nrLines)
// }


* = $8000 "Code"

// setup irq {
nmi:
  rti
start:
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

  lda #$05
  sta $d021
  ldx #$00
  stx $d020
  txa
fillcolor:
  sta $d800,x
  sta $d900,x
  sta $da00,x
  sta $db00,x
  inx
  bne fillcolor

  irqSet(firstRasterY, mainIrq)

// .break
  lda #$01
  sta $d01a   // Enable raster interrupts and turn interrupts back on
  cli
  jmp *       // Do nothing and let the interrupts do all the work.
// }

mainIrq:  {

  irqStabilize()
  // jsr animate
// .break
  wasteCycles(52)
// .break
.const currentRasterY = firstRasterY + 3
// .break

.label lineIndex = * + 1

  ldx #0

// .break

// TODO: count cycles
  .for (var y = 0; y < nrLines; y++) { // unrolled raster code
    lda #badlineD011(d011Value, currentRasterY + y) // trigger badline
    sta $d011
    .eval ImageAddresses.set(y, * + 1)
    // lda sineTableD018 + tree.get(y) * sineLength,x
    lda $8000,x
    sta $d018 // +4 = 8
    .eval colorList.set(y, * + 1)
    lda #5
    sta $d021

    // wasteCycles(6)
    // .if (y == 198) {
      // .break
    // }
  }

  inx
  cpx #sineLength
  bne !skip+

.label imageIndex = * + 1
  lda #0
  and #1
  bne !next+
  jsr replaceImageTree
  jmp !end+
!next:
  jsr replaceImageBall
!end:
  inc imageIndex
  ldx #0
!skip:
  stx lineIndex


  inc $d020
  jsr music.play
  dec $d020

// ack and return
  irqSet(firstRasterY, mainIrq)
  asl $d019
  rti
}


// image: list of linelengths (0-31), one for each image line
// colors: list of colors, one for each image line
.macro replaceImage(image, colors) {
  .for (var y = 0; y < nrLines; y++) {
    .const sineStart = sineTableD018 + image.get(y) * sineLength
    lda #<sineStart
    sta ImageAddresses.get(y)
    lda #>sineStart
    sta ImageAddresses.get(y) + 1
    lda #colors.get(y)
    sta colorList.get(y)
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

  putColor(treeColors, 0, 5)
  putColor(treeColors, 178,11)
  putColor(treeColors, 179, 9)
  putColor(treeColors, 181, 8)
  replaceImage(tree, treeColors)

* = * "Ball image code"

@replaceImageBall:

  putColor(ballColors, 0, 2)
  replaceImage(ball, ballColors)

