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

  irqSet($10, mainIrq)

  lda #$01
  sta $d01a   // Enable raster interrupts and turn interrupts back on
  cli
  jmp *       // Do nothing and let the interrupts do all the work.

* = $1000 "Music"

.fill $1000,0

* = $c000 "IRQ"

mainIrq:

// .break

irqStabilize()

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

// ack and return
  irqSet($10, mainIrq)
  asl $d019
  rti



