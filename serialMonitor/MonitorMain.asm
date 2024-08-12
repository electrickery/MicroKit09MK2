* Monitor program for MicroKit09 MK2 serial extension.
* 
* fjkraan@electrickery.nl, 2024-08-09

; version information
VERMYR	EQU		"0"
VERMIN	EQU		"1"
VERPAT	EQU		"0"

; constants
NULL	EQU		$00
LF		EQU		$0A
CR		EQU		$0D

; address locations
CHAR    EQU     $0080
CPORT   EQU     $0082
COUNTER EQU     $0084

STACK	EQU		$0100

        ORG     $8000

; Init serial port     
INIT
    	LDX		#UARTC
    	STX		CPORT   ; Load serial port base address
    	   	
    	LDA		#3      ; 
    	STA		,X      ; 
    	LDA		#$55    ; /16, 8n1, no interrupt
    	STA		,X      ; 
    	
    	LDY		#STRTMSG
    	BSR		OUTSTR
    	LDY		#PRMTMSG
    	BSR		OUTSTR
    	
; Main loop
LOOP
        BSR     INCHW
        BSR		TOUPPER
        BSR		CMDINTP
        
    	LDY		#PRMTMSG
    	BSR		OUTSTR
		
        BRA		LOOP

OUTSTR	
		LDA		,Y+
		BEQ		_OUTSDONE
		BSR		OUTCH
		BRA		OUTSTR
		
_OUTSDONE
		RTS
		
; Converts lower case to upper case. Input and output char in A
TOUPPER
		CMPA	#"a"
		BMI		_TNOLC
		CMPA	#"z"
		BPL		_TNOLC
		SUBA	#$20
_TNOLC
		RTS
		
CMDINTP
		CMPA	#"H"
		BNE		_CINO_H
		BSR		CMD_HELP
		BRA		_CINO_QWM
_CINO_H
		CMPA	#"?"
		BNE		_CINO_QWM
		BSR		CMD_HELP
_CINO_QWM
		BRA		_CIDONE
		
		
_CIERR
    	LDY		#ERRMSG
    	BSR		OUTSTR
		

_CIDONE
		RTS
		

        
STRTMSG	FCB	CR, LF, "MikroKit09 Serial Monitor V", VERMYR, ".", VERMIN, ".", VERPAT, CR, LF, NULL

PRMTMSG	FCB	CR, LF, ">", NULL

ERRMSG	FCB	"Err!", CR, LF, NULL
   
        INCLUDE "MC6850Driver.asm"
		INCLUDE	"MonitorCommands.asm"

