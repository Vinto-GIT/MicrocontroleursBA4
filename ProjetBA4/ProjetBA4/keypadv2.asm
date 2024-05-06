; file	kpd4x4_S.asm   target ATmega128L-4MHz-STK300		
; purpose keypad 4x4 acquisition and print
; uses four external interrupts and ports internal pull-up

; solutions based on the methodology presented in EE208-MICRO210_ESP-2024-v1.0.fm
;>alternate solutions also possible
; standalone solution/file; not meant as a modular solution and thus must be
;>adapted when used in a complex project
; solution based on interrupts detected on each row; not optimal but functional if
;>and external four-input gate is not available

; RAM Allocation
.dseg
current_code: .byte 1
correct_code: .byte 1
.cseg

.include "macros.asm"        ; include macro definitions
.include "definitions.asm"   ; include register/constant definitions

; === definitions ===
.equ    KPDD = DDRD
.equ    KPDO = PORTD
.equ    KPDI = PIND

.equ    KPD_DELAY = 30   ; msec, debouncing keys of keypad

.def    wr0 = r2        ; detected column in hex
.def    wr1 = r1        ; detected row in hex
.def    mask = r14      ; row mask indicating which row has been detected in bin
.def    wr2 = r15       ; semaphore: must enter LCD display routine, unary: 0 or other

; === interrupt vector table ===
.org 0
    jmp reset
    jmp isr_row1    ; external interrupt INT0 = bit 0 du PORTD
    jmp isr_row2    ; external interrupt INT1 = bit 1 du PORTD
    jmp isr_row3    ; external interrupt INT2 = bit 2 du PORTD
    jmp isr_row4    ; external interrupt INT3 = bit 3 du PORTD

; === interrupt service routines ===
isr_row1:
    INVP    PORTB, 0          ; Toggle led 0 for visual feedback
    _LDI    wr1, 0x00       
    _LDI    mask, 0b00000001  ; detected in row 1
    rjmp    column_detect

isr_row2:
    INVP    PORTB, 1		  ; Toggle led 1 for visual feedback
    _LDI    wr1, 0x01
    _LDI    mask, 0b00000010 ; detected in row 2
    rjmp    column_detect

isr_row3:
    INVP    PORTB, 2          ; Toggle led 2 for visual feedback
    _LDI    wr1, 0x02
    _LDI    mask, 0b00000100  ; detected in row 3
    rjmp    column_detect

isr_row4:
    INVP    PORTB, 3          ; Toggle led 3 for visual feedback
    _LDI    wr1, 0x03
    _LDI    mask, 0b00001000  ; detected in row 4
    rjmp    column_detect

.include "lcd.asm"
.include "printf.asm"

; === Column Detection Routines ===
; Detecting the column: each column is pulled up then, one at a time, each column 
; is pulled low and if that forces the previously found row to also be pulled low
; then we have the right column

column_detect:
	OUTI	KPDO,0xFF		  ; bit4-7 (columns) driven high
	WAIT_MS	KPD_DELAY
col1:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0x7F	; setting column 1 low
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w			;check if the line is pulled low
	
	brne	col2
	_LDI	wr0,0x00
	INVP	PORTB,4		;;debug
	OUTI    KPDD,0xf0          ; port D rows=bit0-3 as input
    OUTI    KPDO,0x0f          ; and columns = bits4-7 as output
    OUTI    DDRB,0xff          ; Configure PORTB as output for debug signals
    OUTI    EIMSK,0x0f         ; Enable external interrupts INT0-INT3
    OUTI    EICRB,0x00		   ; Condition d'interrupt au niveau bas pour int4-7 = colonnes
    
	sei
	_LDI wr2, 0xff
	reti
	
col2:
	WAIT_MS KPD_DELAY
	OUTI	KPDO, 0xBF		; setting column 2 low
	WAIT_MS KPD_DELAY
	in		w, KPDI
	and		w, mask
	tst		w				;check if the line is pulled low
	
	brne	col3
	_LDI	wr0, 0x01
	INVP	PORTB, 5		;;debug
	OUTI    KPDD,0xf0          ; port D rows=bit0-3 as input
    OUTI    KPDO,0x0f          ; and columns = bits4-7 as output
    OUTI    DDRB,0xff          ; Configure PORTB as output for debug signals
    OUTI    EIMSK,0x0f         ; Enable external interrupts INT0-INT3
    OUTI    EICRB,0x00		   ; Condition d'interrupt au niveau bas pour int4-7 = colonnes
    
	sei
	_LDI wr2, 0xff
	reti

col3:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0xDF	; setting column 3 low
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w			;check if the line is pulled low
	brne	col4		
	_LDI	wr0,0x02
	INVP	PORTB, 6		;;debug
	OUTI    KPDD,0xf0          ; port D rows=bit0-3 as input
    OUTI    KPDO,0x0f          ; and columns = bits4-7 as output
    OUTI    DDRB,0xff          ; Configure PORTB as output for debug signals
    OUTI    EIMSK,0x0f         ; Enable external interrupts INT0-INT3
    OUTI    EICRB,0x00		   ; Condition d'interrupt au niveau bas pour int4-7 = colonnes
    
	sei
	_LDI wr2, 0xff
	reti

col4:
	WAIT_MS KPD_DELAY
	OUTI	KPDO, 0xEF		; setting column 4 low
	WAIT_MS KPD_DELAY
	in		w, KPDI
	and		w, mask
	tst		w				;check if the line is pulled low
	brne	PC+11
	_LDI	wr0, 0x03
	;INVP	PORTB, 7		;;debug
	OUTI    KPDD,0xf0          ; port D rows=bit0-3 as input
    OUTI    KPDO,0x0f          ; and columns = bits4-7 as output
    OUTI    DDRB,0xff          ; Configure PORTB as output for debug signals
    OUTI    EIMSK,0x0f         ; Enable external interrupts INT0-INT3
    OUTI    EICRB,0x00		   ; Condition d'interrupt au niveau bas pour int4-7 = colonnes
    
	sei
	_LDI wr2, 0xff
	reti

clear_code:
    rcall   LCD_clear
	PRINTF LCD
	.db	CR, CR, "Code:" 
	.db 0
    ret

; FDEC	decimal number
; FHEX	hexadecimal number
; FBIN	binary number
; FFRAC	fixed fraction number
; FCHAR	single ASCII character
; FSTR	zero-terminated ASCII string

;TODO: Store code as a string in SRAM and change print_code to print the current code

print_code:
	clr		wr2
    cpi     a0, '*'
    breq    clear_code         ; Branch if key == *
	;PRINTF LCD
	;.db CR, CR, "Code:", FCHAR, a, 0
	rcall LCD_putc
    ret

get_char:
	INVP	PORTB, 7
	ldi     b0, 4
    mul     wr1, b0          ; wr1 <-- detected row*4
    add     r0, wr0          ; r0  <-- detected row*4 + detected column
    mov     b0, r0           ; b0  <-- index of key (starts at 0)
    ldi     ZH, high(2*KeySet)
    ldi     ZL, low(2*KeySet)
    add     ZL, b0
	ldi		b3, 0x00
    adc     ZH, b3			   ; Adjust ZH with carry
    lpm     a0, Z
	;rcall LCD_putc
	rcall print_code
	ret


; Initialization and configuration
.org 0x400

reset:
    LDSP    RAMEND
    rcall   LCD_init
    OUTI    KPDD,0xf0          ; port D rows=bit0-3 as input
    OUTI    KPDO,0x0f          ; and columns = bits4-7 as output
    OUTI    DDRB,0xff          ; output for debug
    OUTI    EIMSK,0x0f         ; Enable external interrupts INT0-INT3
    OUTI    EICRB,0x00		   ; Condition d'interrupt au niveau bas pour int4-7 = colonnes

    clr mask
	clr w
	clr wr2
	clr wr1
	clr wr0
	clr a0
	clr b0
	clr b3
	clr r0
	sei
    rcall clear_code
	jmp main


; === main program loop ===
main:
	;Lookup table index = 4*row + col
	tst wr2
	brne go_to_get_char
    rjmp    main

go_to_get_char:
	call get_char
	ret

; Keypad ASCII mapping table
KeySet:
.db '1', '2', '3', 'A'
.db '4', '5', '6', 'B'
.db '7', '8', '9', 'C'
.db '*', '0', '#', 'D'