; Monitor program for the MicroKit09 serial extension
; fjkraan@electrickery.nl, 2024-08-09

CMD_HELP
		LDY		#HELPMSG
    	LBSR	OUTSTR
		RTS

HELPMSG	FCB		"H - This help text.", CR, LF, NULL
