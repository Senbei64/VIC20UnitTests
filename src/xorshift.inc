;- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ------------------------

.ifndef XORSHIFT_INC
XORSHIFT_INC = 1

;- GLOBAL ZERO PAGE VARIABLES ------------------------------------------------

.globalzp zXShSeed

;- GLOBAL SUBROUTINES --------------------------------------------------------

;-----------------------------------------------------------------------------
; Generate the next pseudorandom value from the current seed and store it as
; seed for the next call
;
; In:
; - zXShSeed: current seed
;
; Out:
; - A       : pseudorandom value
; - zXShSeed: next seed
;
.global xsh_next

.endif ; XORSHIFT_INC
;-----------------------------------------------------------------------------
