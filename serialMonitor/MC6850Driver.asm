* Derived from the Sbug receive and transmit routines.
* fjkraan@electrickery.nl, 2024-08-09

* MC6850 registers
* Control Register (0. Wr)
* CR1 CR0 
*  0   0   /1
*  0   1   /16
*  1   0   /64
*  1   1   Master Reset

* CR4 CR3 CR2
*  1   0   1  8 Bits, 1 stop bit

* CR6 CR5
*  0   0   RTS = low, interrupt disabled
*  0   1   RTS = low, interrupt enabled
*  1   0   RTS = high, interrupt disabled
*  1   1   RTS = low, send BREAK, interrupt disabled

* CR7
*  0  Receive interrupt disable
*  1  Receive interrupt enable


* CPORT (0, Rd)
* Status register bits (valid when 1)
* SR0 - Receive data register full
* SR1 - Transmit data register empty
* SR2 - Data Carrier detect
* SR3 - Clear to Send
* SR4 - Framing Error
* SR5 - Receiver overrun
* SR6 - Parity Error
* SR7 - Interrupt Request

UARTC   EQU $A400
UARTS   EQU UARTC
UARTD   EQU UARTC+1

*               CR 7 65 432 10
*               0b 0 10 101 01 
UARTINI EQU     0b01010101 ;* /16, 8n1, no interrupt


; From SBUG source    
; Output Character from A; original name OUTCH
OUTCH	PSHS	A,X     ; push X first, then A
        LDX		CPORT   ; Load serial port base address
_OUTCW	LDA		,X      ; Load serial port status byte
        BITA	#2      ; Check Tx register
        BEQ		_OUTCW  ; Loop when not empty
        PULS	A       ; Get char back
        STA		1,X     ; Send char
        PULS	X       ; 
        RTS

; Input Character (wait for it, blocking) ; original name 
INCHW   PSHS   X          ; SAVE IX
        LDX     CPORT      ; POINT TO TERMINAL PORT
_INCW   LDA    ,X         ; FETCH PORT STATUS
        BITA    #1 TEST    ; READY BIT, RDRF ?
        BEQ     _INCW     ; IF NOT RDY, THEN TRY AGAIN
        LDA     1,X        ; FETCH CHAR
        PULS    X          ; RESTORE IX
        RTS

; Check Rx buffer
CHKRX   PSHS    X          ; SAVE IX
        LDX     CPORT      ; POINT TO TERMINAL PORT
        LDA     ,X         ; FETCH PORT STATUS
        BITA    #1 TEST    ; READY BIT, RDRF ?
        RTS

; Get Rx character in A and set or Z flag cleared if no char
INCHC   BSR     CHKRX
        BEQ     _ICNOCH
        LDA     UARTD
        RTS
_ICNOCH
RTS

;Push Order last to first!
;    Condition Code Register 
;    Accumulator A 
;    Accumulator B 
;    Direct Page Register 
;    Index Register X (HI)  
;    Index Register X (LO) 
;    Index Register Y (HI) 
;    Index Register Y (LO) 
;    User Stack Pointer/Hardware Stack Pointer (HI) 
;    User Stack Pointer/Hardware Stack Pointer (LO) 
;    Program Counter (HI) 
;    Program Counter (LO)
