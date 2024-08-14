
CMD_DUMP
        LDA     CMDCHR
        LBSR    OUTCH
        LBSR     ADDR2BIN       ; temporary key stroke collector

        LBSR    CRLF
        ; display first byte address
        LDA     ADDR1
        LBSR    OUT2HEX
        LDA     ADDR1+1
        LBSR    OUT2HEX
        
        LBSR    SPACE
        LDB     #16
        LDY     #ASCBUF
        LDX     ADDR1
_CDLOOP        
        LDA     ,X+     ; Fetch memory value
        PSHS    A
        LBSR    OUT2HEX
        PULS    A
        LBSR    FILTCHR
        STA     ,Y+
        LBSR    SPACE
        CMPB    #9
        BNE     _CDXSPC
        LBSR    SPACE
_CDXSPC
        DECB
        CMPB    #0
        BNE     _CDLOOP
        
        LBSR    SPACE
        LDY     #ASCBUF
        LBSR    OUTSTR
        CLRA    
        STA     ASCBUFE
        
        BRA     _CDDONE

_CD_ERR
        LDY     #DUMPERRMSG
        LBSR    OUTSTR

_CDDONE
        RTS
        
DUMPERRMSG
        FCB     "D[|+|-|ssss|ssss-eeee]", CR, LF, NULL

CMD_HELP
        LDY	#HELPMSG
        BSR	OUTSTR
        RTS

HELPMSG	FCB		"H - This help text.", CR, LF, NULL

CMD_TEST
        LDA     CMDCHR
        LBSR    OUTCH

        LBSR     COLLECT

        
        RTS
