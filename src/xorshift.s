;- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ------------------------

.include "xorshift.inc"

;- GLOBAL ZERO PAGE VARIABLES ------------------------------------------------
.zeropage

; velocity vector
zXShSeed: .res 1

;- GLOBAL SUBROUTINES --------------------------------------------------------
.code

;-----------------------------------------------------------------------------
.proc xsh_next
	lda zXShSeed
	asl
	asl
	asl
	eor zXShSeed
	sta zXShSeed
	lsr
	lsr
	lsr
	lsr
	lsr
	eor zXShSeed
	sta zXShSeed
	asl
	asl
	asl
	asl
	eor zXShSeed
	sta zXShSeed
	rts
.endproc

;- UNIT TESTS ----------------------------------------------------------------
.ifdef UNIT_TESTS

_zXShSeed = zXShSeed
.exportzp _zXShSeed

_xsh_next = xsh_next
.export _xsh_next

.endif ; UNIT_TESTS

;-----------------------------------------------------------------------------
