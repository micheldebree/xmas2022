BasicUpstart2(start)

/**

TODO:
- [ ] Map out memory
- [ ] Set up interrupt
- [X] Create screens
- [ ] Create fonts
- [ ] Create $d018 table with ob entry for each line
- [ ] Create $dd00 table with entry for each line
- [ ] Make spinning rectangle (no raster code yet)
- [ ] Create image table
- [ ] Add raster code
- [ ] Add colors
- [ ] Optimize by doing precalc in assembler
 */


.const charsPerLine = 32 // characters per line in the screen
.const nrScreens = 256 / charsPerLine // number of different screens with one line repeated
.const nrCharsets = ($4000 - ($400 * nrScreens)) / $800;


* = $0810 "Code"

start:
  lda #$02
  sta $d020
  sta $d021

  jmp *


* = $1000 "Music"

.fill $1000,0

* = $2000 "Scroll font"

.fill $800,0

.for (var bi = 0; bi <2; bi++) {

* = $4000 + (bi * $4000)

// fill up the screens
.for (var si = 0; si < nrScreens; si++) {

  *=* "Screen"
  .for (var y = 0; y < 25; y++) {
    .fill charsPerLine, i + (si * charsPerLine)
    .fill 40 - charsPerLine, 0
  }
}

// fill up the character sets
.for (var i = 0; i < nrCharsets; i++) {
  * = * "Charset"

  .fill $800, 0
}
}
