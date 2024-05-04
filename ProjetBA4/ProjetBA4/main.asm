;
; ProjetBA4.asm
;
; Created: 27/04/2024 11:15:23
; Author : Arno Laurie
;


.include "macros.asm"
.include "definitions.asm"


reset: 
	LDSP ramend
	ldi r16, 0x00
	ldi r17, 0x00
	rjmp main

.include "test_routine.asm"
;.include "kpd4x4.asm"

main:
	rcall test_routine
	;rcall kpd_main
	rjmp main