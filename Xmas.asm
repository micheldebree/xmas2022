#import "VIC.asm"
#import "Precalc.asm"
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

start:
	sei

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


loop:
	lda #$ff
wait:
	cmp $d012
	bne wait

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
	jmp loop


* = $1000 "Music"

.fill $1000,0

