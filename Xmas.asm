#import "VIC.asm"
#import "Precalc.asm"
#import "RasterIrq.asm"
BasicUpstart2(start)

.var tree = LoadBinary("tree.bin")

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
.const firstRasterY = $33 -1 
.const d011Value = %00010000 // 24 rows
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

  lda #d011Value
  sta $d011

  vicSetupPointers($4000, $0000, $2000)



  lda #$05
  ldx #$00
  stx $d020
  stx $d021

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

mainIrq: // {

  irqStabilize()
  // jsr animate
// .break
  wasteCycles(50)
// .break
.const currentRasterY = firstRasterY + 3

.label lineIndex = * + 1

  ldx #0

// .break

  .for (var y = 0; y < 200; y++) { // unrolled raster code
    lda #badlineD011(d011Value, currentRasterY + y) // trigger badline
    sta $d011
    // lda sine TableD018 + mod(y, nrLineLengths) * sineLength,x // +4 = 4
    lda sineTableD018 + tree.get(y) * sineLength,x
    sta $d018 // +4 = 8
    wasteCycles(6)
    .if (y == 198) {
      // .break
    }
  }

  inx
  cpx #sineLength
  bne !skip+
  ldx #0
!skip:
  stx lineIndex

// ack and return
  irqSet(firstRasterY, mainIrq)
  asl $d019
  rti
//

