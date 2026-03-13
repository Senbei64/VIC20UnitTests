;- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ------------------------

.include "vic20.inc"
.include "input.inc"
.include "physics.inc"
.include "xorshift.inc"

;- CONSTANTS -----------------------------------------------------------------

PAL_LINES           = 312
PAL_CYCLES_PER_LINE = 71
PAL_TIMER           = PAL_LINES*PAL_CYCLES_PER_LINE - 2
PAL_BORDER_START    = 145

NTSC_LINES           = 261
NTSC_CYCLES_PER_LINE = 65
NTSC_TIMER           = NTSC_LINES*NTSC_CYCLES_PER_LINE - 2
NTSC_BORDER_START    = 130

NUM_COLS = 22+3
NUM_ROWS = 23+6

COLOR_RAM = $9400

MAX_SPEED = 7

;- LOCAL ZERO PAGE VARIABLES -------------------------------------------------
.zeropage

; temp variables shared by many subroutines
zTmpByt:  .res 1
zTmpPtr1: .res 2
zTmpPtr2: .res 2

; position of the star wanderer in pixels, 8.8 fixed point notation
zPosX: .res 2
zPosY: .res 2

; position of the star wanderer in row and column
zPosC: .res 1
zPosR: .res 1

; content of cell overwritten by the star wanderer
zOvwTile:  .res 1
zOvwColor: .res 1

;- LOCAL NOT INITIALIZED VARIABLES -------------------------------------------
.bss

; video matrix
video_ram: .res NUM_ROWS*NUM_COLS

; acceleration vectors for the 4 cardinal directions
acc_x: .res 4
acc_y: .res 4

;- LOCAL READ-ONLY VARIABLES -------------------------------------------------
.rodata

; acceleration vectors for PAL
acc_pal:
	.byte $08, $00, $F8, $00 ; x axis
	.byte $00, $0D, $00, $F3 ; y axis

; acceleration vectors for NTSC
acc_ntsc:
	.byte $07, $00, $F9, $00 ; x axis
	.byte $00, $0B, $00, $F5 ; y axis

; row offsets
row_offs_l:
	.repeat NUM_ROWS, row
	.byte <(row*NUM_COLS)
	.endrepeat
row_offs_h:
	.repeat NUM_ROWS, row
	.byte >(row*NUM_COLS)
	.endrepeat

;- LOCAL MACROS --------------------------------------------------------------

;-----------------------------------------------------------------------------
; 16 bit sum: accumulator += addendum
;
.macro mAddWord accumulator, addendum
	lda accumulator
	clc
	adc addendum
	sta accumulator
	lda accumulator+1
	adc addendum+1
	sta accumulator+1
.endmacro

;-----------------------------------------------------------------------------
; Wrap if coordinate is < 0 or >= threshold
;
.macro mCheckBounds coordinate, threshold
.scope
	lda coordinate
	cmp #threshold
	bcc exit
	cmp #128 + threshold/2
	bcc sub
	adc #threshold-1
	bcs store
sub:
	sbc #threshold-1
store:
	sta coordinate
exit:
.endscope
.endmacro

;-----------------------------------------------------------------------------
; tile = pix << 3
;
.macro mPxToTile px, tile
	lda px
	lsr
	lsr
	lsr
	sta tile
.endmacro

;- LOCAL SUBROUTINES ---------------------------------------------------------
.code

;-----------------------------------------------------------------------------
; Program wrapper and Basic stub
;
.scope
loadaddr:
	.addr basicstub

basicstub:
	.addr nextline ; next basic line
	.word 2026     ; basic line number
    .byte $9E      ; SYS
	.byte <(((starwanderer/1000) .mod 10) + '0')
	.byte <(((starwanderer/ 100) .mod 10) + '0')
	.byte <(((starwanderer/  10) .mod 10) + '0')
	.byte <(((starwanderer/   1) .mod 10) + '0')
    .byte $00      ; end basic line
nextline:
    .addr $0000    ; end basic program
.endscope

;-----------------------------------------------------------------------------
; Entry point, setup screen and interrupt routine
;
.proc starwanderer
	;
	; disable interrupts
	;
.scope
	sei          ; disable maskable irq
	lda #$7F
	sta VIA1_IER ; disable non maskable interrupt sources
	sta VIA1_IFR ; acknowledge
	sta VIA2_IER ; disable maskable interrupt sources
	sta VIA2_IFR ; acknowledge

	ldx #$FF
	txs          ; clear stack
.endscope

	;
	; setup screen
	;
.scope
	bit $E475
	bmi pal
	lda #$05 - (NUM_COLS-22)     - 1 ; centered in VICE with normal borders
	ldx #$19 - (NUM_ROWS-23) * 2 + 2 ; centered in VICE with normal borders
	jmp store
pal:
	lda #$0C - (NUM_COLS-22)
	ldx #$26 - (NUM_ROWS-23) * 2
store:
	sta VIC_CR0 ; X
	stx VIC_CR1 ; Y
	
	lda #NUM_COLS
	sta VIC_CR2 ; columns
	lda #NUM_ROWS*2
	sta VIC_CR3 ; rows, short tiles
	lda #$F0
	sta VIC_CR5 ; screen, chars
.ifdef DEBUG
    lda #$0A    ; black, red
.else
    lda #$08    ; black, black
.endif
	sta VIC_CRF ; screen, border
	
	; draw the ster field
	jsr fill_matrix_stars
.endscope

	;
	; initialize modules
	;
.scope
	; initialize input module
	jsr input_init

	; initialize physiscs variables
	lda #0
	sta zPhyVelX
	sta zPhyVelX+1
	sta zPhyVelY
	sta zPhyVelY+1
.endscope

	;
	; initialize variables
	;
.scope
	; initial position in screen center
	lda #(NUM_COLS*8 - 1)/2
	sta zPosX+1
	lda #(NUM_ROWS*8 - 1)/2
	sta zPosY+1
	; both fractional parts set to 0.5
	lda #$7F
	sta zPosX
	sta zPosY
	; position in matrix
	lda #(NUM_COLS*8 - 1)/2/8
	sta zPosC
	lda #(NUM_ROWS*8 - 1)/2/8
	sta zPosR
	
	; Earth in the middle
	lda #$51 ; sphere
	sta zOvwTile
	lda #6   ; blue
	sta zOvwColor
	
	; copy acceleration vectors table
	ldy #(acc_y - acc_x)*2 - 1
loop:
	bit $E475
	bmi pal
	lda acc_ntsc,y
	jmp store
pal:
	lda acc_pal,y
store:
	sta acc_x,y
	dey
	bpl loop
.endscope

	;
	; synch and enable vertical blanking timer
	;
.scope
	; install IRQ handler
	lda #<irq_handler
	sta IRQVec
	lda #>irq_handler
	sta IRQVec+1

	; enable timer A free run
	lda #$40 
	sta VIA2_ACR
	
	; wait vertical blanking
	bit $E475
	bmi @pal
	lda #NTSC_BORDER_START
	jmp waitvb
@pal:	
	lda #PAL_BORDER_START
waitvb:
	cmp VIC_CR4	
	bne waitvb
wait2:
	cmp VIC_CR4
	beq wait2

	bit $E475
	bmi @pal
	lda #<NTSC_TIMER
	ldx #>NTSC_TIMER
	jmp store
@pal:
	lda #<PAL_TIMER
	ldx #>PAL_TIMER
store:
	sta VIA2_T1LL ; load the timer low byte latch
	stx VIA2_T1CH ; start the IRQ timer A

    lda #$C0
	sta VIA2_IER ; enable timer A underflow interrupts

	cli ; enable interrupts from now on, everything is in place
.endscope

endless:
	bne endless
	
.endproc

;-----------------------------------------------------------------------------
; Interrupt Routine
;
.proc irq_handler
	lda #$7F
	sta VIA2_IFR ; acknowledge interrupt request
.ifdef DEBUG
	inc VIC_CRF
.endif
	
	;
	; handle keyboard and joystick input
	;
.scope
	jsr input_scan
	lda #%00000010
	bit zInputKbd1
	beq up
	bit zInputKbd2
	beq left
	bit zInputKbd5
	beq down
	asl
	bit zInputKbd2
	beq right
	bit zInputJyst
	bpl right
	beq up
	asl
	bit zInputKbd4
	beq break
	bit zInputJyst
	beq down
	asl
	bit zInputJyst
	beq left
	asl
	bit zInputJyst
	bne input_end
break:
	; set speed to zero
	lda #0
	sta zPhyVelX
	sta zPhyVelX+1
	sta zPhyVelY
	sta zPhyVelY+1
	beq input_end
right:
	ldy #0
	beq input_accelerate
down:
	ldy #1
	bne input_accelerate
left:
	ldy #2
	bne input_accelerate
up:
	ldy #3
input_accelerate:
	ldx acc_x,y
	lda acc_y,y
	jsr phy_add_acc

	; clamp to maximum speed (only integer part)
	lda zPhyVelX+1
	jsr clamp_velocity
	sta zPhyVelX+1
	lda zPhyVelY+1
	jsr clamp_velocity
	sta zPhyVelY+1
input_end:
.endscope

	;
	; move star wanderer
	;
.scope
	; delete star wanderer from previous position
	lda zOvwTile
	ldy zOvwColor
	jsr draw_tile

	; add velocity vector to position
	mAddWord zPosX, zPhyVelX
	mAddWord zPosY, zPhyVelY
		
	; check bounds (only integer part)
	mCheckBounds zPosX+1, NUM_COLS*8
	mCheckBounds zPosY+1, NUM_ROWS*8

	; convert fixed point pixel position to video matrix
	mPxToTile zPosX+1, zPosC
	mPxToTile zPosY+1, zPosR
	
	; draw star wanderer in new position
	lda #$5A ; diamond
	ldy #3   ; cyan
	jsr draw_tile
.endscope

.ifdef DEBUG
	lda zPosX
	sta video_ram
	lda zPosX+1
	sta video_ram+1
	lda zPosY
	sta video_ram+3
	lda zPosY+1
	sta video_ram+4
	lda zPhyVelX
	sta video_ram+6
	lda zPhyVelX+1
	sta video_ram+7
	lda zPhyVelY
	sta video_ram+9
	lda zPhyVelY+1
	sta video_ram+10
.endif

.ifdef DEBUG
	dec VIC_CRF
.endif
	jmp $EB18 ; standard return from interrupt, pull registers and rti
.endproc


;-----------------------------------------------------------------------------
; Clamp to maximum absolute velocity
;
; In:
; - A: velocity to clamp
;
; Out:
; - A: clamped velocity
;
.proc clamp_velocity
	bmi vel_negative
	cmp #MAX_SPEED
	bcc return
	lda #MAX_SPEED
	rts
vel_negative:
	cmp #<-MAX_SPEED
	bcs return
	lda #<-MAX_SPEED
return:
	rts
.endproc

;-----------------------------------------------------------------------------
; Place one tile in the video matrix
;
; In:
; - A:     new tile
; - Y:     new color
; - zPosC: column
; - zPosR: row
;
; Out:
; - zOvwTile:  overwritten tile
; - zOvwColor: overwritten color
.proc draw_tile
	; save new cell content for later
	pha
	sty zTmpByt

	; compute pointers to video and color ram rows
	ldx zPosR
	lda row_offs_l,x
	sta zTmpPtr1
	sta zTmpPtr2
	lda row_offs_h,x
	sta zTmpPtr2+1
	clc
	adc #>video_ram
	sta zTmpPtr1+1
	lda zTmpPtr2+1
	clc
	adc #>COLOR_RAM
	sta zTmpPtr2+1
	
	; save content of overwritten cell
	ldy zPosC
	lda (zTmpPtr1),y
	sta zOvwTile
	lda (zTmpPtr2),y
	sta zOvwColor
	
	; overwrite cell with new content
	pla         ; pick saved new tile from stack
	sta (zTmpPtr1),y
	lda zTmpByt ; pick saved new color
	sta (zTmpPtr2),y
	rts
.endproc

;-----------------------------------------------------------------------------
; Fill video and color matrix with a star field
;
.proc fill_matrix_stars
	lda #$15
	sta zXShSeed

	ldx #NUM_ROWS-1
loop_row:
	lda row_offs_l,x
	sta zTmpPtr1
	sta zTmpPtr2
	lda row_offs_h,x
	clc
	adc #>video_ram
	sta zTmpPtr1+1
	lda row_offs_h,x
	clc
	adc #>COLOR_RAM
	sta zTmpPtr2+1
		
	ldy #NUM_COLS-1
loop_col:
.scope
	jsr xsh_next
	txa
	eor zXShSeed
	cmp #250
	bcc space
	lda #'.'
	bne storeshape
space:
	lda #' '
storeshape:
	sta (zTmpPtr1),y

	txa
	eor zXShSeed
	cmp #253
	beq red
	bcc white
	lda #7 ; yellow
	bne storecolor
red:
	lda #2 ; red
	bne storecolor
white:
	lda #1 ; white
storecolor:
	sta (zTmpPtr2),y

	dey
.endscope
	bpl loop_col

	dex
	bmi return
	lda zTmpPtr1
	clc
	adc #NUM_COLS
	sta zTmpPtr1
	bcc loop_row
	inc zTmpPtr1+1
	bcs loop_row

return:
	rts
.endproc

;-----------------------------------------------------------------------------
