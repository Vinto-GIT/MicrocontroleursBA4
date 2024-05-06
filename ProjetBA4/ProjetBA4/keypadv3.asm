; Keypad 4x4 robust handling for ATmega128 on STK300

.include "m128def.inc"        ; Include device definitions
.include "macros.asm"         ; Include macro definitions
.include "definitions.asm"    ; Include register/constant definitions

.def    wr0 = r16            ; Temporary register for general use
.def    wr1 = r17            ; Temporary register for general use
.def    col = r18            ; Detected column
.def    row = r19            ; Detected row

.equ    KPDD = DDRD          ; Data Direction Register for Keypad
.equ    KPDO = PORTD         ; Data Port Output for Keypad
.equ    KPDI = PIND          ; Data Port Input for Keypad

.equ    KPD_DELAY = 50       ; Debouncing delay in milliseconds

.org 0x00
    rjmp RESET               ; Reset Handler
.org 0x02
    rjmp ISR_INT0            ; External Interrupt 0 Handler
.org 0x04
    rjmp ISR_INT1            ; External Interrupt 1 Handler
.org 0x06
    rjmp ISR_INT2            ; External Interrupt 2 Handler
.org 0x08
    rjmp ISR_INT3            ; External Interrupt 3 Handler

RESET:
    ldi  wr0, low(RAMEND)
    out  SPL, wr0            ; Set Stack Pointer
    ldi  wr0, high(RAMEND)
    out  SPH, wr0

    ; Initialize Keypad Port
    ldi  wr0, 0xFF           ; Configure all PORTD as input initially
    out  KPDD, wr0
    ldi  wr0, 0x00           ; Enable pull-ups on all of PORTD
    out  KPDO, wr0

    sei                      ; Enable global interrupts

MAIN:
    rjmp MAIN                ; Infinite loop

; External Interrupt Service Routines
ISR_INT0:
    ; Handle interrupt for column 1
    call DEBOUNCE
    breq ISR_EXIT            ; Exit if no key is actually pressed
    ldi  col, 1
    rjmp PROCESS_KEY

ISR_INT1:
    ; Handle interrupt for column 2
    call DEBOUNCE
    breq ISR_EXIT            ; Exit if no key is actually pressed
    ldi  col, 2
    rjmp PROCESS_KEY

ISR_INT2:
    ; Handle interrupt for column 3
    call DEBOUNCE
    breq ISR_EXIT            ; Exit if no key is actually pressed
    ldi  col, 3
    rjmp PROCESS_KEY

ISR_INT3:
    ; Handle interrupt for column 4
    call DEBOUNCE
    breq ISR_EXIT            ; Exit if no key is actually pressed
    ldi  col, 4
    rjmp PROCESS_KEY

PROCESS_KEY:
    ; Additional processing here
    ; Example: Determine row and encode the key pressed
    ; You can add lookup table here based on 'row' and 'col' to determine the key
    reti

DEBOUNCE:
    ; Simple software debouncing
    ldi  wr0, KPD_DELAY      ; Load delay time
    call DELAY_MS            ; Wait for the delay
    in   wr1, KPDI           ; Read the keypad input
    cpse wr1, wr0            ; Compare if the key state is stable
    ret
    ldi  wr0, 1              ; Return 1 if stable
    ret

DELAY_MS:
    ; Delay subroutine for debouncing (not precise, just an example)
    dec  wr0
    brne DELAY_MS
    ret

ISR_EXIT:
    reti                     ; Exit the ISR without processing

; Note: Actual implementation of DELAY_MS should use timer for accuracy
