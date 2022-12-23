.macro irqSet(rasterline, address) {
    lda #<address
    sta $fffe
    lda #>address
    sta $ffff
    lda #(rasterline & $ff)
    sta $d012
    .if (rasterline > $ff) {
      lda $d011
      ora %10000000
      sta $d011
   }
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

		.for (var i = 0; i < 19; i++) {
			nop
		}

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