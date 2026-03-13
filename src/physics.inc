;- VIC-20 Unit Tests - Copyright 2026 Fabio Carignano ------------------------
;
; Components of accelerations, velocities, and positions are handled as fixed-
; point variables with 8 bits for the signed integer part and 8 bits for the 
; fractional part, denoted as 8.8.
; Acceleration components are measured as pixels per tick squared and are
; always less than 1.0 in magnitude.
; Acceleration components are stored in a packed 8-bit form containing the
; sign in the MSB and a 7-bit fractional part, which is promoted to 8.8 bits
; by sign-extending to the whole integer part, aligning the 7 fractional
; bits to the left, leaving the LSB of the reconstructed 8.8 bits to zero:
; SFFFFFFF -> SSSSSSSS.FFFFFFF0

.ifndef PHYSICS_INC
PHYSICS_INC = 1

;- GLOBAL ZERO PAGE VARIABLES ------------------------------------------------

; velocity vector
.globalzp zPhyVelX, zPhyVelY

;- GLOBAL SUBROUTINES --------------------------------------------------------

;-----------------------------------------------------------------------------
; Add passed acceleration vector to velocity
;
; In:
; - A: Y component of the acceleration, packed form
; - X: X component of the acceleration, packed form
;
.global phy_add_acc

.endif ; PHYSICS_INC
;-----------------------------------------------------------------------------
