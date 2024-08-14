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
ESC		EQU		$1E

; address locations
NIB0    EQU     $70
NIB1    EQU     $71
NIB2    EQU     $72
NIB3    EQU     $73
BYTE0   EQU     $74
BYTE1   EQU     $75

MONDATA EQU		$0080
CHAR    EQU     MONDATA + $00
CMDCHR  EQU     MONDATA + $01
CPORT   EQU     MONDATA + $02
COUNTER EQU     MONDATA + $04
CLBUFP  EQU     MONDATA + $06       ; Command line buffer pointer   ; MSB & LSB
CLBUF   EQU     MONDATA + $08       ; Command line buffer start   ; R112 - R127   command line buffer
CLBUFE  EQU     MONDATA + CLBUF + $2C ; (=$B4) command line buffer end
ADDR1   EQU     MONDATA + $B6
ADDR2   EQU     MONDATA + $B8
ADDR3   EQU     MONDATA + $BA
ASCBUF  EQU     MONDATA + $BC
ASCBUFE EQU     MONDATA + $BC + $10 ; 16 chars and a NUL

STACK	EQU		$0200	; and down

        ORG     $8000

; Init serial port     
INIT
    	LDX		#UARTC
    	STX		CPORT   ; Load serial port base address
    	   	
    	LDA		#3      ; 
    	STA		,X      ; 
    	LDA		#$55    ; /16, 8n1, no interrupt
    	STA		,X      ; 
    	
; Init monitor
        CLRA
        STA     ASCBUFE

    	LDY		#STRTMSG
    	LBSR		OUTSTR
    	LDY		#PRMTMSG
    	LBSR		OUTSTR
        
        
; Main loop
LOOP
        LBSR    INCHW
        CMPA    CR
        BNE     _LPNOCR
        LDY     #PRMTMSG
        LBSR    OUTSTR
        BRA     LOOP
        
_LPNOCR        
        STA     CMDCHR
        LBSR    TOUPPER
        BSR     CMDINTP
        
        LDY     #PRMTMSG
        LBSR    OUTSTR

        BRA     LOOP


CMDINTP
		CMPA    #"D"
        BNE     _CINO_D
        LBSR    CMD_DUMP
        BRA     _CIDONE
_CINO_D
		CMPA	#"H"
		BNE		_CINO_H
		LBSR	CMD_HELP
		BRA		_CINO_QWM
_CINO_H
		CMPA	#"?"
		BNE		_CINO_QWM
		LBSR	CMD_HELP
_CINO_QWM
		CMPA    #"T"
        BNE     _CINO_T
        LBSR    CMD_TEST
        
_CINO_T

		BRA		_CIERR

_CIERR
    	LDY		#ERRMSG
    	LBSR		OUTSTR
        RTS

_CIDONE

		RTS

COLLECT
    	LDX     #CLBUF	; Initialize command line
    	STX     CLBUFP	;  buffer pointer
_COLNXT
		LBSR	INCHW
		CMPA	#CR
		BEQ		_COLLDONE
		CMPA	#ESC
		BEQ		_COLLESC
		LBSR	OUTCH
		STA		X+		; increment pointer
		STX		CLBUFP
		LDY		#CLBUFE
		CMPX    *CLBUFP
		BEQ		_COLLERR
		BRA		_COLNXT
		
_COLLERR
		LDY		COLERMSG
		LBSR	OUTSTR		

_COLLESC		
		LDY		ESCMSG
		LBSR	OUTSTR
		ORCC	#$01	; set carrybit
		
_COLLDONE	
		CLRA
		STA		CLBUFP
		RTS
		
COLERMSG
		FCB     CR, LF, "Command line buffer overflow.", CR, LF, NULL
        
STRTMSG	FCB		CR, LF, "MikroKit09 Serial Monitor V", VERMYR, ".", VERMIN, ".", VERPAT, CR, LF, NULL

PRMTMSG	FCB		CR, LF, ">", NULL

ESCMSG	FCB 	CR, LF, "ESC", CR, LF, NULL

ERRMSG	FCB		"Err!", CR, LF, NULL
   
        INCLUDE "MC6850Driver.asm"
		INCLUDE	"MonitorCommands.asm"
		INCLUDE "MonitorCommon.asm"
