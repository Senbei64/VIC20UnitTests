;- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ------------------------

.include "physics.inc"

;- LOCAL MACROS --------------------------------------------------------------

;-----------------------------------------------------------------------------
; Add passed acceleration component to internally stored velocity
;
; In:
; - A: component of the acceleration, packed form
;
.macro mAddAcc zVel
.scope
	; packed fractional acceleration in A
	asl      ; sign into carry, 7 fractional bits properly left aligned
	bcs negative_acc
	; carry clear, positive acceleration
	adc zVel
	sta zVel
	lda #$00 ; implicit leading zeros
	beq add_high
negative_acc:
	; carry set, negative acceleration
	clc
	adc zVel
	sta zVel
	lda #$FF ; implicit leading ones

add_high:
	adc zVel+1
	sta zVel+1
.endscope
.endmacro

;- GLOBAL ZERO PAGE VARIABLES ------------------------------------------------
.zeropage

; velocity vector
zPhyVelX: .res 2
zPhyVelY: .res 2   

;- GLOBAL SUBROUTINES --------------------------------------------------------
.code

;-----------------------------------------------------------------------------
.proc phy_add_acc
	mAddAcc zPhyVelY
	txa
	mAddAcc zPhyVelX
	rts
.endproc

;- UNIT TESTS ----------------------------------------------------------------
.ifdef UNIT_TESTS

_zPhyVelX = zPhyVelX
_zPhyVelY = zPhyVelY
.exportzp _zPhyVelX, _zPhyVelY

_phy_add_acc = phy_add_acc
.export _phy_add_acc

.endif ; UNIT_TESTS

;-----------------------------------------------------------------------------
