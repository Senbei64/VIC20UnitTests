;- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ------------------------

.include "input.inc"
.include "vic20.inc"

;- GLOBAL ZERO PAGE VARIABLES ------------------------------------------------
.zeropage

zInputJyst: .res 1
zInputKbd1: .res 1
zInputKbd2: .res 1
zInputKbd4: .res 1
zInputKbd5: .res 1

;- GLOBAL SUBROUTINES --------------------------------------------------------
.code

;-----------------------------------------------------------------------------
; Initialize zeropage variables and VIAs for joystick and keyboard scan
;
.proc input_init
	ldx #$00
	stx VIA1_DDRA  ; set all VIA1 port A lines to input, joystick
	stx VIA2_DDRA  ; set all VIA2 port A lines to input, keyboard rows
	dex            ; all ones 
	stx zInputJyst ; no joystick inputs active
	stx zInputKbd1 ; no keys pressed
	stx zInputKbd2 ; no keys pressed
	stx zInputKbd4 ; no keys pressed
	stx zInputKbd5 ; no keys pressed
	stx VIA2_DDRB  ; set all VIA2 port B lines to output, keyboard columns
	stx VIA2_PB    ; set all VIA2 port B latches to ones, no columns selected
	rts
.endproc

;-----------------------------------------------------------------------------
; Scan joystick and keyboard, set zeropage variables
;
.proc input_scan

	; set VIA2 port B line 7 to input, joystick right
	lsr VIA2_DDRB  ; shify 0 in PB7, shift PB0 (1) into carry
	
	; read joystick
	lda VIA1_PA1   ; read 4 joystick lines from VIA1 port B
	ora #%11000011 ; mask the non joystick inputs
	and VIA2_PB    ; read joystick right in bit 7, all other latches are ones
	sta zInputJyst

	; set all VIA2 port B lines to output, keyboard columns
	ldx #$FF
	stx VIA2_DDRB
	
	; read keyboard
	lda #%11111101
	sta VIA2_PB    ; activate column 1
	lda VIA2_PA1   ; read rows of column 1
	sta zInputKbd1
	rol VIA2_PB    ; activate column 2, carry (1) to PB0, pB7 (1) to carry
	lda VIA2_PA1   ; read rows of column 2
	sta zInputKbd2
	lda #%11101111
	sta VIA2_PB    ; activate column 4
	lda VIA2_PA1   ; read rows of column 4
	sta zInputKbd4
	rol VIA2_PB    ; activate column 5, carry (1) to PB0, pB7 (1) to carry
	lda VIA2_PA1   ; read rows of column 5
	sta zInputKbd5
	stx VIA2_PB    ; deactivate all columns
	
	rts
.endproc

;-----------------------------------------------------------------------------
