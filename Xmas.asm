#import "VIC.asm"
#import "Precalc.asm"
#import "RasterIrq.asm"
BasicUpstart2(start)

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
- [ ] Create image table
- [ ] Add raster code
- [ ] Add colors
- [ ] Optimize by doing precalc in assembler
Ohttps://codebase64.org/doku.php?id=base:fpp-first-line

} */

// global constants {

.const charsPerLine = 32 // characters per line in the screen
.const nrScreens = 256 / charsPerLine // number of different screens with one line repeated
.const nrCharsets = ($4000 - ($400 * nrScreens)) / $800;
.const firstRasterLine = $31

// }

* = $0810 "Code"

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

  lda #%00011000
  sta $d011

  vicSetupPointers($4000, $0000, $2000)

  lda #$01
  ldx #$00

fillcolor:
  sta $d800,x
  sta $d900,x
  sta $da00,x
  sta $db00,x
  inx
  bne fillcolor

  irqSet(firstRasterLine, mainIrq)

// .break
  lda #$01
  sta $d01a   // Enable raster interrupts and turn interrupts back on
  cli
  jmp *       // Do nothing and let the interrupts do all the work.
// }

mainIrq: // {

  irqStabilize()
  // jsr animate
// .break
  wasteCycles(50)
// .break
.const currentLine = $34

.label lineIndex = * + 1

  ldx #0

// .break

  .for (var y = 0; y < 200; y++) { // unrolled raster code
    // .if (mod(y,2) == 0) {
      // lda #0   // +2 = 2
    // }
    // else {
      // lda #2   // +2 = 2
    // }


    lda #badlineD011(%00011000, currentLine + y) // trigger badline
    sta $d011
    lda sineTableD018 + mod(y, nrLineLengths) * sineLength,x // +4 = 4
    sta $d018 // +4 = 8
    // lda sineTableDD00 + mod(y, nrLineLengths) * sineLength,x // +4 = 12
    // sta $dd00 // +4 = 16
    wasteCycles(6)
    // inc $d011 // +6 = 22

    // wasteCycles(4)
    // .if (!isBadLine(currentLine + y, yScroll)) {
    //   .print ("good: " + (currentLine + y))
    //   bit $ea // 23
    //   wasteCycles(40)
    // } else {
    //   .print ("bad!")
    // }
  }

  inx
  cpx #sineLength
  bne !skip+
  ldx #0
!skip:
  stx lineIndex

// ack and return
  irqSet(firstRasterLine, mainIrq)
  asl $d019
  rti
//

