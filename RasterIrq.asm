.const DUMMY_WRITE_ADDR = $d02f

.macro irqSet(rasterline, address) {
    lda #<address
    sta $fffe
    lda #>address
    sta $ffff
    lda #(rasterline & $ff)
    sta $d012
    lda $d011
    .if (rasterline > $ff) {
      ora #%10000000
    }
    else {
      and #%01111111
    }
    sta $d011
}

.macro wasteCycles(nrCycles) {
  .var left = nrCycles
  .var nrInc = floor(nrCycles / 6)
  .if (mod(nrCycles, 6) == 1) { .eval nrInc = nrInc - 1 }
  .for (var i = 0; i < nrInc; i++) { inc DUMMY_WRITE_ADDR }
  .eval left = left - nrInc * 6

  .var nrBit = floor(left / 3)
  .if (mod(left, 3) == 1) { .eval nrBit = nrBit - 1 }
  .for (var i = 0; i < nrBit; i++) { bit $ea }
  .eval left = left - nrBit * 3

  .var nrNop = floor(left / 2)
  .for (var i = 0; i < nrNop; i++) { nop }
}

.macro irqStabilize() {
    lda #<stabilizerIrq
    sta $fffe
    lda #>stabilizerIrq
    sta $ffff
    inc $d012 // next irq on next line
    asl $d019 // ack interrupt
    tsx // save stack pointer (return address for this irq)
    cli // enable interrupts so stabelizerIrq can occur
    // somewhere along these nops, the stabilizerIrq will
    // take over, leaving 1 cycle jitter

    .for (var i = 0; i < 25; i++) { nop }

  stabilizerIrq:
    txs // restore stack pointer
    ldx #8
  waste:
    dex
    bne waste
    nop
    bit $ea // waste 3 cycles
    lda $d012
    cmp $d012
    beq done // waste one more cycle if no raster change yet
done:
}
