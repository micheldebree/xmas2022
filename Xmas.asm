#import "VIC.asm"
#import "Precalc.asm"
#import "RasterIrq.asm"
BasicUpstart2(start)

/**
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
 */

.const charsPerLine = 32 // characters per line in the screen
.const nrScreens = 256 / charsPerLine // number of different screens with one line repeated
.const nrCharsets = ($4000 - ($400 * nrScreens)) / $800;

  .const firstRasterLine = $31

* = $0810

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

  lda #$01
  sta $d01a   // Enable raster interrupts and turn interrupts back on
  cli
  jmp *       // Do nothing and let the interrupts do all the work.

* = $1000 "Music"

.fill $1000,0

* = $e000 "IRQ"

mainIrq:

// .break

  irqStabilize()
  // jsr animate
// .break
  wasteCycles(50)
// .break
    .const currentLine = $34
    ldx #0
  .for (var y = 0; y < 200; y++) {
    .if (mod(y,2) == 0) {
      lda #0   // 2
    }
    else {
      lda #2   // 2
    }
    sta $d021 // 6



    wasteCycles(14)
      // nop // 12
      // nop // 14
      // nop // 16
      // nop // 18
      // nop // 20
    .if (!isBadLine(currentLine + y, yScroll)) {
      .print ("good: " + (currentLine + y))
      bit $ea // 23
      wasteCycles(40)
      // nop // 25
      // nop // 27
      // nop // 29
      // nop // 31
      // nop // 33
      // nop // 35
      // nop // 37
      // nop // 39
      // nop // 41
      // nop // 43
      // nop // 45
      // nop // 47
      // nop // 49
      // nop // 51
      // nop // 53
      // nop // 55
      // nop // 57
      // nop // 59
      // nop // 61
      // nop // 63
    } else {
      .print ("bad!")
    }
  }
// ack and return
jsr animate
  irqSet(firstRasterLine, mainIrq)
  asl $d019
  rti

animate:
li:
  ldx #00

  ldy (sineTable + 47 * sineLength),x

  lda d018Values,y
  sta $d018
  lda dd00Values,y
  sta $dd00
  inx
  cpx #sineLength
  bcc skip
  ldx #0
skip:
  stx li+1
  rts



