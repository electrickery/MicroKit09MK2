; Monitor program for the MicroKit09 serial extension
;  Common routines
; fjkraan@electrickery.nl, 2024-08-09


;;**********************************************************************
; TOUPPER
; converts character in A in range a-z to A-Z
;;**********************************************************************  
TOUPPER
        CMPA    #"a"
        BMI     _TNOLC
        CMPA    #"z"
        BPL     _TNOLC
        SUBA    #$20
_TNOLC
        RTS

;;**********************************************************************
;; OUTNIBH
;; OUTPUT High 4 bits of A as 1 HEX Digit
;; OUTNIBL
;; OUTPUT Low 4 bits of A as 1 HEX Digit
;;**********************************************************************
OUTNIBH 
        LSRA                ; OUT HEX LEFT HEX DIGIT
        LSRA
        LSRA
        LSRA

OUTNIBL 
        ANDA    #0b00001111     ; OUT HEX RIGHT HEX DIGIT
        ORA     #"0"            ; Patch upper nibble
        CMPA    #":"            ; check for > 9
        BCS     _OUTNIBX
        ADDA    #7
_OUTNIBX 
        LBSR    OUTCH
        RTS 

;;**********************************************************************
;; OUT2HEX
;; Output A as 2 HEX digits
;;**********************************************************************
OUT2HEX PSHS    A
        BSR     OUTNIBH     ; 
        PULS    A
        BSR     OUTNIBL     ;
        RTS

;;**********************************************************************
;; CRLF
;; Output CR & LF
;;**********************************************************************
CRLF    LDA     #CR
        LBSR    OUTCH
        LDA     #LF
        LBSR    OUTCH
        RTS

;;**********************************************************************
;; SPACE
;;**********************************************************************
SPACE   LDA     #" "
        LBSR    OUTCH
        RTS

;;**********************************************************************
;; OUTSTR
;; Output string at (Y). ) terminated
;;**********************************************************************

OUTSTR	
        LDA     ,Y+
        BEQ     _OUTSDONE
        LBSR    OUTCH
        BRA     OUTSTR

_OUTSDONE
        RTS

;;**********************************************************************
;; FILTCHR
;;**********************************************************************
FILTCHR
        CMPA    #" "
        BCS     _FCDOT
        CMPA    #$7F
        BCC     _FCDOT
        BRA     _FCDONE
_FCDOT
        LDA     #"."
_FCDONE
        RTS        

;;**********************************************************************
;;
;;**********************************************************************
CHR2NIB
        BSR     TOUPPER
        SUBA    #"0"
        CMPA    #10
        BCS     _C2NNUM
        SUBA    #7
_C2NNUM        
        RTS


ADDR2BIN        ; temporary key stroke collector
        LBSR    INCHW
        LBSR    OUTCH
        BSR     CHR2NIB
        LSLA
        LSLA
        LSLA
        LSLA
        STA     NIB0
        STA     ADDR1
        LDB     A
        LBSR    INCHW
        LBSR    OUTCH
        BSR     CHR2NIB
        STA     NIB1
        ADDA    ADDR1
        STA     BYTE0
        STA     ADDR1
        LBSR    INCHW
        LBSR    OUTCH
        BSR     CHR2NIB
        LSLA
        LSLA
        LSLA
        LSLA
        STA     NIB2
        STA     ADDR1+1
        LDB     A
        LBSR     INCHW
        LBSR    OUTCH
        BSR     CHR2NIB
        STA     NIB3
        ADDA    ADDR1+1
        STA     BYTE1
        STA     ADDR1+1
        RTS
