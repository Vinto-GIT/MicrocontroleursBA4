; file	kpd4x4_S.asm   target ATmega128L-4MHz-STK300		
; purpose keypad 4x4 acquisition and print
;  uses four external interrupts and ports internal pull-up

; solutions based on the methodology presented in EE208-MICRO210_ESP-2024-v1.0.fm
;>alternate solutions also possible
; standalone solution/file; not meant as a modular solution and thus must be
;>adapted when used in a complex project
; solution based on interrupts detected on each row; not optimal but functional if
;>and external four-input gate is not available

.include "macros.asm"		; include macro definitions
.include "definitions.asm"	; include register/constant definitions
	


	; === definitions ===
.equ	KPDD = DDRD
.equ	KPDO = PORTD
.equ	KPDI = PIND

.equ	KPD_DELAY = 50	; msec, debouncing keys of keypad

.def	wr0 = r2		; detected column in hex
.def	wr1 = r1		; detected row in hex
.def	mask = r14		; row mask indicating which row has been detected in bin
.def	wr2 = r15		; semaphore: must enter LCD display routine, unary: 0 or other


	; === interrupt vector table ===
.org 0
	jmp reset
	jmp	isr_ext_int0	; external interrupt INT0
	jmp	isr_ext_int1	; external interrupt INT1
	jmp isr_ext_int2	; external interrupt INT2
	jmp isr_ext_int3	; external interrupt INT3


	; === interrupt service routines ===
isr_ext_int0:
	INVP	PORTB,0			  ; Toggle PORTB, pin 0 for visual feedback
	_LDI	wr1, 0x00		
	_LDI	mask, 0b00000001  ; detected in row 1
	rjmp	column_detect
	; no reti (grouped in isr_return)

isr_ext_int1:
	INVP	PORTB, 1
	_LDI	wr1, 0x01
	_LDI	mask, 0b00000010 ; detected in row2
	rjmp	column_detect

isr_ext_int2:
    INVP	PORTB, 2          ; Toggle PORTB, pin 0 for visual feedback
    _LDI	wr1, 0x02
    _LDI	mask, 0b00000100  ; detected in row 3
    rjmp	column_detect

isr_ext_int3:
    INVP	PORTB, 3          ; Toggle PORTB, pin 0 for visual feedback
    _LDI	wr1, 0x03
    _LDI	mask, 0b00001000  ; detected in row 4
    rjmp	column_detect

;Detecting the column: each column is pulled up then, one at a time, each column 
; is pulled low and if that forces the previously found row to als be pulled low
; then we have the right column


column_detect:
	OUTI	KPDO,0xff	; bit4-7 (columns) driven high
col1:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0x7f	; setting column 1 low: 0b01111111
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w			;check if the line is pulled low
	brne	col2
	_LDI	wr0,0x00
	INVP	PORTB,4		;;debug
	rjmp	isr_return
	
col2:
	WAIT_MS KPD_DELAY
	OUTI	KPDO, 0xBF		; setting column 2 low: 0b10111111
	WAIT_MS KPD_DELAY
	in		w, KPDI
	and		w, mask
	tst		w				;check if the line is pulled low
	brne	col3
	_LDI	wr0, 0x01
	INVP	PORTB, 5		;;debug
	rjmp	isr_return

col3:
	WAIT_MS	KPD_DELAY
	OUTI	KPDO,0xDF	; setting column 3 low: 0b11011111
	WAIT_MS	KPD_DELAY
	in		w,KPDI
	and		w,mask
	tst		w			;check if the line is pulled low
	brne	col4		
	_LDI	wr0,0x02
	INVP	PORTB, 6		;;debug
	rjmp	isr_return

col4:
	WAIT_MS KPD_DELAY
	OUTI	KPDO, 0xEF		; setting column 4 low: 0b11101111
	WAIT_MS KPD_DELAY
	in		w, KPDI
	and		w, mask
	tst		w				;check if the line is pulled low
	brne	isr_return
	_LDI	wr0, 0x03
	INVP	PORTB, 7		;;debug
	rjmp	isr_return


	
isr_return:
    ; Calculate index of corresponding key : index = row*4 + column
    ldi b0, 4
    mul wr1, b0 ; wr1 = detected row, row*4 is stored in r0
    add r0, wr0 ; + wr0 = detected column
    mov b0, r0  ; r18 stores the index of the pressed key (first index is 0)
    
	rcall print_key
	;call LCD_clear
	ldi _w, 10 ; sound feedback of pressed acknowledge
    sei ; Re-enable interrupts
    reti ; Return from interrupt

	beep01:
	;to be completed
	_LDI wr2, 0xff
	reti

.include "lcd.asm"			; include UART routines
.include "printf.asm"		; include formatted printing routines

print_key:
	ldi ZH, high(2*KeySet) ;zh=r31
	ldi ZL, low(2*KeySet)  ;zl=r30
	add ZL, b0 ; add index to address of first value in lookup table
	ldi b3, 0
	adc ZH, b3
	lpm a0, Z
	cpi a0, '*'
	breq clear_code
	rcall LCD_putc  ;expects char in r18 == a0
	ret
clear_code:
	rcall LCD_clear
	PRINTF LCD
	.db	CR,CR,"Code:"
	ret

; === initialization and configuration ===

.org 0x400

reset:	
	LDSP	RAMEND			; Load Stack Pointer (SP)
	rcall	LCD_init		; initialize UART

	OUTI	KPDD,0xf0		; bit0-3 pull-up and bits4-7 driven low
	OUTI	KPDO,0x0f		;>(needs the two lines)
	OUTI	DDRB,0xff		; turn on LEDs
	OUTI	EIMSK,0x0f		; enable INT0-INT3
	OUTI	EICRB,0b0		;>at low level
	sbi		DDRE,SPEAKER	; enable sound
	sei
	PRINTF LCD
	.db	CR,CR,"Code:"
	clr		wr0
	clr		wr1
	clr		wr2

	clr		a1				
	clr		a2
	clr		a3
	clr		b1
	clr		b2
	clr		b3
	rjmp	main

	; === main program ===
main:
	tst		wr2				; check flag/semaphore = check if key was pressed
	breq	main			; loop back because no key was detected
	clr		wr2
    ; Optionally, clear LCD or handle additional display logic here
    rjmp    main            ; Loop back to start of main
	
	
PRINTF LCD
.db	CR,LF,"KPD=",FHEX,a," ascii=",FHEX,b
.db	0
	rjmp	main
	
; code conversion table, character set #1 key to ASCII	
KeySet:
.db '1', '2', '3', 'A'
.db '4', '5', '6', 'B'
.db '7', '8', '9', 'C'
.db '*', '0', '#', 'D'
