    NAM MICROMON09
* REV 1.10
*
*PROGRAMME MONITEUR POUR MC 6809
*
*ASSEMBLE SUR EUROMAK LE 20 JUILLET 1982


*****************************************
*PROGRAMME REALISE PAR CLAUDE VICIDOMINI*
*****************************************
*SAISI LE 21 JANVIER 2013 PAR F LE DUIGOU
*FIN DE VERIFICATION LE 26 JANVIER 2013
*Reformatted for explicit comments and assembly on April 28th, 2021 by F.J. Kraan
*with asm6809 (https://www.6809.org.uk/asm6809) to identical binary
*again for the Flex assembler format a09 (https://github.com/electrickery/A09)


*DEFINITION DES FONCTIONS:
***P - PUNCH CHARGE UNE ZONE MEMOIRE EN CASSETTE
***L - LOAD CHARGE LE CONTENU D'UNE CASSETTE EN MEMOIRE
***M - MEMORY EXAMINE ET CHANGE LE CONTENU D'UNE MEMOIRE
***AB- ABORT MET SOUS CONTROLE MONITEUR SANS INITIALISATION
***R - REGISTER DISPLAY
*      ORDRE DE VISUALISATION des REGISTRES:CC,A,B,DP,X,Y,U,PC,SP
*      LE CONTENU DES REGISTRES PEUT ETRE CHANGE A LA DEMANDE
***I - INCREMENT
*      INCREMENTE D'UN PAS LORS D'UNE FONCTION MEMOIRE
*      VISUALISE UN REGISTRE APRES L'AUTRE LORS D'UNE INTERRUPTION.
*      STOCKE EN MEMOIRE LA DONNEE RENTREE
***G - GO DEMARRE UN PROGRAMME APRES AVOIR PRECISE SON ADRESSE
*      PERMET D'EFFECTUER UN CALCUL D'OFFSET POUR UN ADRESSAGE
*      INDEXE OU POUR UN BRANCHEMENT RELATIF
***CN- CONTINUE PERMET DE CONTINUER LE DEROULEMENT D'UN PROGRAMME
*      APRES UN "ABORT".
***DN- DECREMENTATION: PERMET DE DECREMENTER D'UN PAS LORS D'UNE
*      FONCTION MEMOIRE OU DE VISUALISER LES REGISTRES DANS L'AUTRE
*      SENS.
***OF- OFFSET: CALCULE L'OFFSET LONG OU COURT LORS D'UNE
*      FONCTION MEMOIRE ET LE PLACE AUTOMATIQUEMENT DANS LA
*      MEMOIRE DE PROGRAMME, PUIS RETOURNE DANS LA FONCTION
*      MEMOIRE.
*X-OF- POST OCTET: PERMET DE CALCULER L'OFFSET EN DECIMAL QU'IL FAUT
*      DONNER AU POST OCTET; LE PROGRAMME LE CALCULE EN HEXA ET LE
*      PLACE EN MEMOIRE.
***BP- BREAKPOINT: INSERE UN SWI2 A UNE ADRESSE SPECIFIEE, VISUALISE
*      LE CONTENU DES REGISTRES DU MPU, PUIS PLACE L'INSTRUCTION EN MEM
*      A LA PLACE DU SWI2
*
*
*
*
********************************************************************
**LA PILE EST LOCALISEE A1 PARTIR DE L'ADRESSE $0780 "JUSQU'A $07CC"
**LA RAM PART DE L'ADRESSE $0000 JUSQU'A $07AF
**LE MONITEUR EST LOCALISE ENTRE $E000 ET $E7FF
**LE PIA EST LOCALISE ENTRE $A004 ET $A007
******************************************************************** 
********************************************************************
*  LE RESET EST SITUE A L'ADRESSE $E219.
*  LA ROUTINE DE NMI EST A L'ADRESSE $E27C.
*  LE SWI EST A L'ADRESSE $E2A7.
*  LE SWI2 EST A L'ADRESSE $E27C.
*  LES AUTRES INTERRUPS SONT DEFINIES DS "EMPLACEMENT DES REGISTRES"
********************************************************************
        ORG $E000
*
* SCRUTATION DU CLAVIER *
*
*              0   1   2   3
KEYTBL  FCB $06,$05,$04,$03
*
*              4   5   6   7
        FCB $02,$01,$15,$14
* 
*              8   9   A   B
        FCB $13,$12,$11,$25
*
*              C   D   E   F
        FCB $24,$23,$22,$21

* CODAGE DES SEGMENTS *
*
*              0   1   2   3
DIGTBL  FCB $7E,$06,$5B,$1F
*
*              4   5   6   7
        FCB $27,$3D,$7D,$0E
*
*              8   9   A   B
        FCB $7F,$3F,$6F,$75
*
*              C   D   E   F
        FCB $78,$57,$79,$69


**************  GETKEY ROUTINE  **************
*SCRUTE LES LIGNES ET LES COLONNES DU CLAVIER*
************ ALLUME LES AFFICHEURS ***********

GETKEY  PSHS Y,DP,B
        SETDP $A0
        LDA #$A0
        TFR A,DP
FINCLA  BSR DISPRE      ; ALLUMER LES AFFICHEURS
        CLRA            ; 
        STA <SCNREG     ; PIA Control Register A 2=0: DDR
        STA <SCNCNT     ; ACCES A DDRB  PIA DDR B
        STA <DISREG     ; PA EN ENTREE
        LDA #$0F        ; lower nibble output, upper nibble input
        STA <DISCNT     ; PB EN SORTIE  
        LDA #$04
        STA <SCNREG     ; ACCES A ORA-DISREG
        STA <SCNCNT     ; ACCES A DRB-DISCNT
        LDB #$FF
LIGSUI  INCB
        CMPB #$04       ; FIN SCRUT. CLAVIER?
        BEQ FINCLA      ; OUI, SCRUTER AFFICHEURS
        STB <DISCNT     ; NON, SCRUTER LIGNE PAR LIGNE
        LDA <DISREG
        COMA            ; PAS DE TOUCHE ENFONCEES?
        BEQ LIGSUI      ; OUI, SCRUTER LIGNE SUIV;
        STB SAVCNT     
        STA SAVREG      ; NON, TOUCHE ENFONCEE
        CLRA
        LDB #$01
COLSUI  CMPB SAVREG     ; TOUCHE DETECTEE?
        BEQ DECKEY      ; OUI, RECONNAITRE LA TOUCHE
        INCA            ; NON, PASSER A LA COLONNE SUIVANTE
        ASLB            ; TOUTES COLONNES TESTEES?
        BEQ LIGSUI      ; OUI, LIGNE SUIVANTE
        BRA COLSUI      ; NON,COLONNE SUIVANTE


************ RECONNAISSANCE DE LA TOUCHE ***********
*FABRIQUE LE CODE DE RECONNAISSANCE DE LA TOUCHE SI*
** ELLE EST APPUYEE     ; SUPPRIME LES REBONDISSEMENTS**

DECKEY  LDB SAVCNT      ; NUMERO DE LIGNE
        ASLB
        ASLB
        ASLB
        ASLB
        PSHS B          ; REPERE LIGNE
        ADDA ,S+
        PSHS A          ; SAUVEGARDE CODE TOUCHE
        LDY #$0008
NOREB   CLRB
DLY2    LDA <DISREG
        COMA            ; REBONDISSEMENT ?
        BNE NOREB       ; OUI, ATTENDRE DISPARITION
        DECB            ; NON, TEMPO=30MS
        BNE DLY2
        LEAY -1,Y
        BNE DLY2
        PULS PC,Y,DP,B,A    ; RETOUR RESET ROUTINE ; RTS


****** ALLUMAGE DES AFFICHEURS ******


DISPRE  PSHS X,B,A
        LDX #DISREG
        CLRA
        STA 2,X             ; ACCES A DDRA
        STA 3,X             ; ACCES A DDRB
        LDA #$FF            ; Set all port lines to output, decimal point too
        STA ,X              ; PA EN SORTIE
        LDA #$0F
        STA 1,X             ; PB0-3 EN SORTIE
        LDA #$04
        STA 2,X             ; ACCES A PA-DISREG
        STA 3,X             ; ACCES A PB-DISCNT
        LDX #DISBUF
        LDB #$03
RECOM   INCB
        CMPB #$0A           ; TOUS LES AFFICHEURS SCRUTES?
        BNE SCRUTA          ; NON, CONTINUER
        PULS PC,X,B,A       ; OUI, RETOUR SOUS GETKEY ; RTS


****** ALLUMER UN AFFICHEUR APRES L'AUTRE *******


SCRUTA  STB >DISCNT         ; CHOISIR L'AFFICHEUR
        LDA ,X+             ; PRENDRE CARACTERE DS DISBUF
        ORA MABS            ; Set the dp-segment for absent memory
        COMA
        STA DISREG          ; ALLUMER SEGMENTS
        LDA #$A0
DLY1    DECA
        BNE DLY1            ; DUREE #1MS
    
    
        LDA #$FF            ; Clear all segments
        STA DISREG          ;  before next display
    
    
        BRA RECOM           ; ALLUMER TOUS LES AFFICHEURS

*** CHARGEMENT DE L'ADRESSE DANS X ***


FADDRX  EXG A,B
        TFR D,X             ; D=X=ADRESSE PROGRAMME
        PULS PC,B,A         ; RTS


****** FABRICATION DES ADRESSES ******


BADDR   PSHS B,A
        CLRA
        CLRB
        STD DISBUF
        STD DISBUF+2        ; 4 PREMIERS DIGITS=0
        LDX #DISBUF         ; POINTER SUR DISBUF
        BSR HEXIN7          ; AFFICHE 2 PREMIERS CHIFFRES
        PSHS A
        BSR HEXIN7          ; AFFICHE 3e ET 4e CHIFFRE
        PULS B
        BRA FADDRX          ; FABRIQUE ADRESSE
HEXIN7  BSR KEYHEX          ; FABRIQUE VAL TOUCHE
        ASLA
        ASLA
        ASLA
        ASLA                ; TRANSFERT LSB,MSB
        PSHS A              ; SAUVE VAL TOUCHE
        BSR L7SEG           ; FABRIQUE VAL CONVERSION TOUCHE
        STA ,X+             ; VAL CONV DANS DISBUF
        BSR KEYHEX          ; CONTINUER CHIFFRES SUIVANTS
        ADDA ,S+
        PSHS A
        BSR R7SEG
        STA ,X+             ; TOUCHE SUIVANTE
        PULS PC,A           ; RTS


**FABRICATION DE LA VALEUR HEXA DE LA TOUCHE**


KEYHEX  LBSR GETKEY         ; SCRUTER LIGNES ET COLONNES
HEXCON  PSHS X,B            ; ALLUMER CHIFFRE ET G
        LDX #KEYTBL         ; POINTER SUR LE TABLEAU
        LDB #$FF            ; DES CHIFFRES
SCRUTC  INCB
        CMPX #DIGTBL        ; VALEUR DIFF CHIFFRE?
        BEQ FONCTI          ; OUI, C'EST UNE FONCTION
        CMPA ,X+            ; NON, CHIFFRE TROUVE?
        BNE SCRUTC          ; NON, CONTINUER A SCRUTER
        TFR B,A
        PULS PC,X,B         ; RTS


*** CONVERSION HEXA-7 SEGMENTS ***
********** TOUCHES VALEURS *******


L7SEG   ASRA
        ASRA
        ASRA
        ASRA            ; VAL TOUCHE DS A, LSB
R7SEG   PSHS X
        LDX #DIGTBL     ; POINTER SUR TABLEAU
        ANDA #$0F       ; PREMIERE TOUCHE?
NDVALH  BEQ VALHEX      ; OUI, VAL HEX DS A
        LEAX 1,X        ; NON, POINTER SUR VAL SUIVANTE
        DECA
        BRA NDVALH      ; RECOMMENCER SI VAL NON TROUVEE
VALHEX  LDA ,X          ; CONVERSION HEXA-7SEGMENTS
        PULS PC,X       ; DANS A TROUVE ; RTS


**** CONVERSION DU CODE TOUCHE EN UNE VAL HEXA ****


CONHEX  PSHS X,B
        LDX #DIGTBL
        TFR A,B         ; B=DISBUF+4 OU DISBUF+5
        CLRA
NONFIN  CMPB ,X+        ; CHERCHE VAL DONNEE
        BEQ DONEA       ; A=VAL HEXA DONNEE
FONCTI  LBEQ RPOINT     ; OUI, FONCTION, RETOURNER SCRUTER
        INCA
        BRA NONFIN
DONEA   PULS PC,X,B     ; RTS


****** EXECUTION DE LA FONCTION MEMOIRE ******


EXMEMO  CLRA
        SETDP $07
        STA <DISBUF+4   ; ETEINDRE 5e DIGIT
        LDA #$6E
        STA <DISBUF+5   ; M DANS 6e DIGIT
        BSR BADDR       ; FABRIQUER ADRESSE DANS X
REMEMO  CLR <COMDEC
        LDA ,X          ; METTRE A DANS LE CONTENU
        PSHS A          ; DE LA CASE MEMOIRE
        BSR L7SEG       ; FABRIQUER LE CODE A METTRE
        STA <DISBUF+4   ; DANS LE 5e DIGIT
        PULS A
        BSR R7SEG       ; FABRIQUER LE CODE A METTRE
        STA <DISBUF+5   ; DANS LE 6e DIGIT
ENCDON  LBSR GETKEY     ; ALLUMER LES DIGITS
        CMPA #$36       ; TOUCHE X?
        BEQ EXPOCT      ; OUI, SCRUTER LA TOUCHE OFFSET
        CMPA #$00       ; INCREMENTE CASE MEMOIRE?
        BEQ EXINC       ; OUI, EXECUTER LA FONCTION
        CMPA #$10       ; NON, DECREMENTE CASE MEMOIRE?
        BEQ EXDEC       ; OUI, EXECUTE LA FONCTION
        CMPA #$33       ; TOUCHE OFFSET?
        LBEQ EXOFST     ; OUI, EXECUTE LA FONCTION
        BSR HEXCON      ; NON, FABRIQUER CODE HEXA TOUCHE
        LDB <DISBUF+5   ; SHIFTER DISBUF
        STB <DISBUF+4
        BSR R7SEG
        STA <DISBUF+5
        BSR INCREM      ; STOCKER DONNEE
        BRA ENCDON      ; RECOM SI AUTRE DONNEE


******* EXECUTION DE LA FONCTION INCREMENTATION *******
*********** ET DE LA FONCTION DECREMENTATION **********


        SETDP $07
INCREM  LDA <DISBUF+4 PLACE DONNEE EN MEM.
        BSR CONHEX      ; CONVERTIR VAL CONVERSION
        ASLA
        ASLA
        ASLA
        ASLA            ; VAL HEXA DANS MSB
        PSHS A
        LDA <DISBUF+5
        BSR CONHEX
        ADDA ,S+        ; A=DONNEE DISBUF+4 ET +5
        TFR A,B
        STA ,X          ; DONNEE DANS CASE X
        RTS
        
EXDEC   DEC <COMDEC
EXINC   BSR INCREM
        LDA <COMDEC     ; INCREMENTE OU DECREMENTE?
        BNE DECRE       ; COMDEC<>0, DECREMENTE
        LDA ,X+         ; PRENDRE DONNEE DS X ET X+1
PREXIN  PSHS B          ; SAUVE AVANT STOCKAGE
        CMPA ,S+        ; MEMOIRE ABSENTE OU MEMOIRE MORTE?
;        LBNE RPOINT     ; OUI, ALLUMER PROMPT ET SCRUTER
        LBSR SETMBS     ; Set or reset 
        TFR X,D         ; NON, AFFICHE CASE MEMOIRE
        LBSR L7SEG      ; SUIVANTE OU PRECEDENTE
        STA <DISBUF
        TFR X,D
        LBSR R7SEG
        STA <DISBUF+1
        TFR B,A
        LBSR L7SEG
        STA <DISBUF+2
        TFR B,A
        LBSR R7SEG
        STA <DISBUF+3
        BRA REMEMO      ; RECOMMENCER EXECUTION MEMOIRE
DECRE   LDA ,X
        LEAX -1,X
        BRA PREXIN      ; DECREMENTATION EXECUTEE


****** EXECUTION POST OCTET: DEFINI S'IL EST >0 OU <0 ******


EXPOCT  BSR INCREM      ; POST OCTET EN MEM
        STA <SAVPOC     ; SAUVE POST OCTET
        LDA #$01        ; ALLUME PROMPT
        PSHS X
        LBSR PROMPT
        LBSR GETKEY
        CMPA #$33       ; TOUCHE OFFSET?
        BEQ OFFSET
        LBRA REMEMO     ; NON, RETOUR FCT MEM
OFFSET  LDA <SAVPOC     ; REPRENDRE POST OCTET
        PULS X
        LEAX -1,X
        TFR A,B
        ANDB #$8E 
        CMPB #$8C       ; LEA N,PCR?
        BNE CALPOT      ; NON, AFFICHE SIGNE
        TFR A,B 
        ANDB #$0D
        CMPB #$0C       ; BRANCH COURT
        LBEQ OFPOCT
        CMPB #$0D       ; BRANCH LONG
        LBEQ EXLBCL 
CALPOT  LBSR GETKEY
        LBSR CLRDIS
        CMPA #$00       ; TOUCHE INCREM?
        BEQ PLUS        ; POSTOCTET>0
        CMPA #$10       ; TOUCHE DECREM?
        BEQ MOINS       ; POSTOCTET<0
        LEAX 1,X
        LBRA REMEMO     ; SINON RETOUR MEM
PLUS    LDA #$6B
        STA <DISBUF+5   ; AFFICHE PLUS
        CLRA
        BRA CONTI
        
MOINS   LDA #$6E
        STA <DISBUF+5   ; AFFICHE MOINS
        LDA #$80
CONTI   STA <PLUSMS
        LBRA AFIVAL


****** PLACE UN POINT D'ARRET EN MEMOIRE ET SAUVE L'INSTRUCTION ******


BPOINT  LDD #$756B
        STD <DISBUF+4   ; ALLUMER BP
        LBSR BADDR      ; AFFICHE ADRESSE
        LDD ,X
        STD <SASWI2     ; SAUVE INSTRUCTION
        LDD #$103F
        STD ,X          ; PLACE POINT D'ARRET
        BRA RPOINT      ; RETOUR SCRUT

SETMBS
        PSHS A, CC
        BNE SM1
        CLRA
        BRA SM2
SM1     LDA #$80
SM2     STA <MABS
        PULS A,CC
        RTS

***********************************************************************
******************** PROGRAMME DE RESET *******************************
****** INITIALISATION ET DECODAGE DES FONCTIONS :M, R,CN,G,BP,L,P *****
***********************************************************************


RESTAR  LDS #PILE       ; INIT PILE
        STS >SAVPIL     ; ET POINTEUR X
        LDX #ROUNMI
        STX >SAVNMI
RPOINT  LDS #PILMON
        SETDP $07
        LDA #$07        ; INIT DP
        TFR A,DP
        BSR CLRDIS      ; DISBUF=0
        LDA #$01
        STA <DISBUF     ; CHARGEMENT PROMPT
        LBSR GETKEY     ; ALLUME PROMPT
        CMPA #$26       ; TOUCHE BP ?
        BEQ BPOINT      ; OUI, PLACER POINT D'ARRET
        CMPA #$30       ; TOUCHE REGISTRE?
        LBEQ FONREG     ; OUI, EXECUTE FONCTION DE CHGT REG
        CMPA #$20       ; TOUCHE=MEMORY?
        LBEQ EXMEMO     ; OUI, EXECUTE ROUTINE
        CMPA #$32       ; NON, TOUCHE=CONTINUE?
        BEQ EXCN        ; OUI, EXECUTE ROUTINE
        CMPA #$34       ; NOU, TOUCHE=LOAD?
        LBEQ EXLOAD     ; OUI, EXECUTE ROUTINE
        CMPA #$35       ; NON, TOUCHE=PUNCH?
        LBEQ EXPUNC     ; OUI, EXECUTE ROUTINE
        CMPA #$31       ; NON, TOUCHE=GO?
        BNE RPOINT      ; NON, RETOUR SCRUTATION
        LDA #$7C        ; OUI, CHARGE G DS DERNIER DIGIT
        STA <DISBUF+5
        LBSR BADDR      ; FABRIQUE ADRESSE DEPART
        LDY <SAVPIL     ; DU PROGRAMME
        STX 10,Y        ; ADRESSE PROG DANS PC
        LDA #$80
        ORA ,Y          ; POSITIONNER PLAG E=1
        STA ,Y          ; POUR PRENDRE EN COMPTE
EXCN    LDS <SAVPIL     ; TOUS LES REGISTRES
        RTI             ; DEPART PROG UTILISATEUR


****** INITIALISATION DE LA FONCTION NMI ******


ROUNMI  LDA 10,S
        ANDA #$F0
        CMPA #$E0
        BEQ RPOINT
        BRA RSWI


****** INITIALISATION DE LA FONCTION SWI2 ******


RSWI2   DEC 11,S
        DEC 11,S        ; POINTER PCR SUR INSTRUC.
        LDD >SASWI2
        STD [10,S]      ; REMETRE INSTRUCTION EN MEM.
        BRA RSWI        ; SCRUTER LES REGISTRES


************** REMISE A ZERO DE TOUT DISBUF **************


CLRDIS  PSHS U,X,B,A
        LEAU INTER2,PCR
        PSHS U
        CLRA            ; TOUT DISBUF=0
        STA MABS        ; clear decimal point flag
PROMPT  LDB #$06
        LDX #DISBUF
ENCORE  STA ,X+
        DECB
        BNE ENCORE
        RTS
        
INTER2  PULS PC,U,X,B,A


* CODAGE DES REGISTRES DU MPU *
*
*              C   A   B   D
REGTBL  FCB $78,$6F,$75,$57
*
*              X   Y   U   P
        FCB $67,$37,$76,$6B
*
*             S
        FCB $3D


*************** SOFTWARE INTERRUPT ROUTINE *****************************
***** PERMET DE VISUALISER LE CONTENU DES REGISTRES DU MPU *************
******* ET DE CHANGER EVENTUELLEMENT LE CONTENU D'UN REGISTRE QCQ ******
************************************************************************


        SETDP $07
RSWI    LDA #$07
        TFR A,DP
        STS <SAVPIL
        LDS #PILMON
        BSR CLRDIS      ; TOUT DISBUF=00
        LDB #$02        ; COMPTEUR REGISTRES
        LDX <SAVPIL     ; INDEX DE CHARGEMENT DES REGISTRES
        LEAY REGTBL,PCR ; Y=REGTBL
TOUREG  LEAU >INTER,PCR
        PSHS U          ; PC SAUVE EN PILE
        LDA ,Y+         ; A=VAL REGISTRE
        STA <DISBUF+5   ; REGISTRE DS DERNIER DIGIT
        CMPY #RSWI      ; FIN TABLEAU?
        BNE SUITER      ; NON
        LDX #SAVPIL     ; OUI, X POINTE SAVPIL
SUITER  CMPY #REGTBL+4  ; 1iere MOITIER TEBLEAU?
        BLS AF2DIG      ; OUI, 1iere MOITIER
        LDA ,X          ; NON, 2ieme MOITIER
        LBSR L7SEG      ; AFFICHE CONTENU
        STA <DISBUF     ; SUR 4 DIGITS
        LDA ,X+ 
        LBSR R7SEG
        STA <DISBUF+1
AF2DIG  LDA ,X          ; 1iere MOITIER
        LBSR L7SEG      ; AFFICHE COTENU SUR
        STA <DISBUF+2   ; 2 DIGITS
        LDA ,X+ 
        LBSR R7SEG
        STA <DISBUF+3
        LBSR GETKEY     ; ALLUMER AFFICHEURS
        RTS             ; RETOUR A CHANGEMENT DE REG
        
INTER   DECB 
        BLE SCRUDE      ; DECREMENTE OU INCREMENTE ? 
        CMPB #$01       ; 1er REGISTRE =CCR?
        BEQ TSTDEC      ; OUI, SCUTER r
REGSUI  CMPA #$00       ; REGISTRE SUIVANT?
        LBNE RPOINT     ; NON, RETOUR PROMPT
        CMPY #RSWI      ; OUI, FIN TABLEAU?
        BNE TOUREG      ; NON, CONTINUER REGISTRES
FONREG  LBSR CLRDIS
        LDA #$41        ; AFFICHER r
        STA <DISBUF+4
        BRA EXREGI      ; SCRUTER REGISTRES
        
TSTDEC  CMPA #$10
        BEQ FONREG
        BRA REGSUI 
        
SCRUDE  CMPA #$10       ; DECREMENTATION DEMANDEE?
        BEQ REGPRE      ; OUI, PASSER AU REGISTRE PRECEDENT
        BRA REGSUI      ; NON, PASSER AU REGISTRE SUIVANT
        
REGPRE  LEAY -2,Y       ; REGTBL POINTE VERS REGISTRE PRECEDENT
        LBSR CLRDIS     ; ETEINDRE AFFICHAGE
        CMPY #REGTBL-1  ; DEBUT TABLEAU DES REGISTRES?
        BEQ FONREG      ; OUI, RETOUR FONCTION REGISTRE
        CMPY #REGTBL+7  ; POINTE SUR PC?
        BEQ REGPC       ; OUI, ALLUMER LE CONTENU
        CMPY REGTBL+3   ; REGISTRES 8 BITS?
        BEQ RE8BIT
        CMPY REGTBL+2
        BLS REBIT8
        LEAX -4,X       ; REGISTRE 16 BITS X,Y,U,P,S
        LBRA TOUREG     ; VISUALISER CONTENU
RE8BIT  LEAX -3,X       ; REGISTRES 8 BITS D,B,A,C
        LBRA TOUREG     ; VISUALISE CONTENU
REBIT8  LEAX -2,X       ; REGISTRES 8 BITS B,A,C
        LBRA TOUREG     ; VISUALISER CONTENU
REGPC   LDX <SAVPIL
        LEAX 10,X       ; X POINTE SUR PC
        LBRA TOUREG


****** PERMET DE CHANGER LE CONTENU D'UN REG LORS D'UN NMI ou SWI ******


EXREGI  LEAY REGTBL,PCR
        LDX <SAVPIL
        LBSR GETKEY     ; ALLUMER REG
        CMPA #$30       ; REG DEMANDE?
        LBEQ RPOINT     ; OUI, CRUTER TOUCHES
        CMPA #$06       ; CCR?
        BEQ R8BREG      ; OUI
        LEAX 1,X
        LEAY 1,Y        ; REG SUIVANT
        CMPA #$05       ; ACCA?
        BEQ R8BREG      ; OUI
        LEAX 1,X
        LEAY 1,Y
        CMPA #$04       ; ACCB?
        BEQ R8BREG      ; OUI
        LEAX 1,X
        LEAY 1,Y
        CMPA #$03       ; DPR?
        BEQ R8BREG      ; OUI
        LEAX 1,X
        LEAY 1,Y
        CMPA #$02       ; REG X?
        BEQ REG16B      ; OUI
        LEAX 2,X
        LEAY 1,Y
        CMPA #$01       ; REG Y?
        BEQ REG16B      ; OUI
        LEAX 2,X
        LEAY 1,Y 
        CMPA #$15       ; REG U?
        BEQ REG16B      ; OUI
        LEAX 2,X
        LEAY 1,Y
        CMPA #$14       ; REG PCR?
        BEQ REG16B      ; OUI
        LBRA RPOINT
R8BREG  LDA ,Y
        STA <DISBUF+5   ; AFFICHE TYPE DE REG
        LBSR AF2DIG     ; AFFICHE LE CONTENU DU REG 8BITS
        LEAX -1,X
        BRA CHANG8      ; CHANGER LE CONTENU
REG16B  LDA ,Y
        STA <DISBUF+5   ; AFFICHE TYPE DE REG
        LBSR SUITER+6   ; AFFICHE LE CONTENU DU REGISTRE 16BITS
        LEAX -2,X
        BRA CHAN16      ; CHANGER SON CONTENU
CHANG8  PSHS Y,X        ; SAUVEGARDE DES POINTEURS
        LDX #DISBUF+2
        LDY #$02
        LBSR CHTDON     ; SOUS PROG DE CHGT DES DONNEES
        PULS Y,X
        LDA <PRESEH 
        STA ,X          ; NELLE DONNEE EN PILE
        LBRA FONREG     ; SCRUTER LES REGISTRES


CHAN16  PSHS Y,X
        LDX #DISBUF
        LDY #$06
        LBSR CHTDON
        PULS Y,X
        LDD <PRESEH
        STD ,X
        LBRA FONREG


****** AFFICHE VAL DU POST OCTET,EFFECTUE LA CONVERSION ******
****** DECIMALE-HEXADECIMALE ET PLACE LE RESLT EN MEMRE ******


AFIVAL  LEAX 1,X
        PSHS X
        LBSR GETKEY
        LDX #DISBUF
        LDY #$06
        LBSR CHTDON
        LBSR GETKEY
        LBSR MSBDON
        CLR <PRELOW
        STB <PRELOW+1
        PULS X
        LBSR GETKEY
        CMPA #$31
        BEQ CALCON
        LBRA REMEMO
        
CALCON  LBSR CLRDIS
        LBSR DECHEX     ; CONVERSION DEC-HEXA
        LDD <PRELOW
        TSTA            ; A-0?
        BNE TESTST      ; NON, VAL 16BITS?
        ASLB
        BCS TSTSUI      ; VAL 16BITS?
        ASLB
        BCS INTR08      ; VAL 16BITS?
        ASLB
        BCS INTR08      ; VAL 8BITS?
        BRA INTR05      ; VAL 5BITS?
        
TESTST  CMPA #$80       ; A>80?
        BHI ERREUR      ; OUI, AFFICHE ERREUR
        BEQ COMPAB
        BRA INTR16      ; NON, VAL 16 BITS
        
COMPAB  CMPB #$00
        BEQ INTR16
ERREUR  LEAX -1,X
EREURE  TFR X,Y
        LBRA CLIGNO
        
TSTSUI  RORB
        CMPB #$80       ; B>80?
        BHI INTR16      ; OUI, VAL 16BITS
        BRA INTR08      ; NON, VAL 8BITS
INTR05  ASLB
        BCC POSITIF
        LDD <PRELOW
        LDA ,X          ; POST DS A, VAL DS B
        CMPB #$10       ; B>10?
        BHI TSTPOC      ; OUI, TESTER POST OCTET
        ASLA
        BCC POCPOS
        BRA INTR08
        
TSTPOC  ASLA
        BCC EREURE      ; POST INCORRECT
        BRA INTR08      ; VAL 8BITS POSSIBLE
        
POCPOS  ASL <PLUSMS     ; POSITIF?
        BCC INTR08      ; VAL 8BITS
CHPOST  LDA ,X
        PSHS B
        ADDA ,S+
        STA ,X
        BRA STODN1
        
POSITIF LDD <PRELOW
        LDA ,X
        ASLA
        BCS EREURE
        ASL <PLUSMS
        BCC CHPOST      ; SI POSITIF , CHARGER
        NEGB
        ANDB #$1F
        BRA CHPOST      ; SI NEG, CHARGER
        
INTR08  LDD <PRELOW
        LDA ,X+
        ROLA
        BCC ERREUR      ; SI DIFFERENT 8BITS ERREUR
        RORA
        ANDA #$0F
        CMPA #$08       ; POST OCTET 8BITS
        BNE ERREUR
        ASL <PLUSMS     ; OUI, POSITIF?
        BCC STADON      ; OUI STOCKER DONNEE
        NEGB
STODON  STB ,X
STODN1  LBSR AFFIAD+2
        LBRA REMEMO
STADON  CMPB #$80
RCR     BEQ ERREUR
        BRA STODON
        
INTR16  LDA ,X+
        ROLA
        BCC ERREUR      ; DIFF 16BITS
        RORA
        ANDA #$0F
        CMPA #$09       ; 16BITS?
        BNE ERREUR
        LDD <PRELOW
        ASL <PLUSMS     ; POSITIF?
        BCC COMPAR      ; OUI
        COMA
        COMB
        ADDD #$01
CHAR16  STD ,X
        BRA STODN1
COMPAR  CMPD #$8000
        BEQ RCR
        BRA CHAR16


****** CHANGEMENT DE CONTENU DES REGISTRES PRESERVES EN PILE ******


CHTCHI  LBSR GETKEY     ; SCRUTER CHIFFRES
CHTDON  LEAU >INTVAL,PCR
        PSHS U
MSBDON  LBSR HEXCON     ; CONVERTI CHIFFRE EN HEXA
        TFR A,B
        LBSR R7SEG
        STA ,X+         ; ENVOI CHIFFRE SUR AFFICHEUR
        RTS
        
INTVAL  PSHS B
        LEAY -1,Y
        TFR Y,D         ; 1 OU 5 OU 3
        LSRB 
        BCS DEPLAC
SUITEP  CMPY #$02       ; DISBUF+0
        BEQ CAL16       ; REGISTRE 16BITS
        TFR Y,D         ; 0 OU 4
        LSRB
        BCC CALCU8      ; REGISTRE 8BITS
SUI     CMPY #$00
        BGT CHTCHI      ; CHIFFRE SUIVANT
        BEQ RETOUR
CAL16   PULS A
        ADDA ,S+
        STA <PRESEL
RETOUR  RTS

DEPLAC  PULS A
        ASLA
        ASLA
        ASLA
        ASLA
        PSHS A
        BRA SUITEP
        
CALCU8  PULS A
        ADDA ,S+
        STA <PRESEH
        BRA SUI


****** SOUS-PROG DE CONVERSION DECIMALE-HEXA, RETOUR EN FCT MEM ******


DECHEX  PSHS Y,X,DP
        LDA #$0A
        TFR A,DP        ; 10 DS DP
        LDX #PRESEL
        LDY #$00
CALCUL  LDA ,X
        LEAY 1,Y
        CMPY #$01
        BNE COMPR2
        BSR LSBDSA      ; LSB DANS ACCA
MULPAR  MUL
        ADDD >PRELOW    ; D+PRELOW DS D
        STD >PRELOW
        BRA CALCUL
        
COMPR2  CMPY #$02
        BNE COMPR3
        BSR MUL100      ; MUL DES CENTAINES
        BSR MSBLSB
        BRA MULPAR
        
COMPR3  CMPY #$03
        BNE COMPR4
        BSR MUL100      ; MUL DES MILLIERS
        LDA ,X
        BSR LSBDSA
MULFIN  MUL
        LDA >PRESER
        BRA MULPAR
        
COMPR4  CMPY #$04
        BNE COMPR5
        LDA #$02
        STA >SAUVER
RECMCE  BSR MUP100      ; MUL DES DIZAINES DE MILLIERS
        DEC >SAUVER
        BEQ M10000
        STB >PRESER
        BRA RECMCE
        
M10000  BSR MSBLSB
SECPAR  CMPA #$03
        BHS TESTER
        LDY #$05
        BRA MULFIN
TESTER  BHI AFEROR
        LDA #$02
        BRA MULFIN
        
COMPR5  CMPY #$05
        BNE FINCAL
        LDA #$01
        LDB >PRESER
        BRA SECPAR
    
AFEROR  PULS DP,X,Y,U
        TFR X,Y
        LBRA CLIGNO
        
FINCAL  PULS PC,X,Y,DP      ; RTS

LSBDSA  LDB #$08
DECENC  LSLA
        DECB
        CMPB #$04
        BNE DECENC
DECTJS  LSRA
        DECB
        BNE DECTJS
        TFR DP,B
        RTS

MSBLSB  LDA ,X
        LSRA
        LSRA
        LSRA
        LSRA
        LEAX -1,X
        RTS

MUL100  LEAU >INTER3,PCR
        PSHS U
MUP100  TFR DP,B
        TFR B,A
        MUL
        RTS
        
INTER3  STB >PRESER
        RTS


****** RECONNAISSANCE DU BIT DU CARACTERE TRANSMIS ******
*
*
*
RECBIT  PSHS B,A
NOUDLY  LDB #$06
SCARRY  LDA DISCNT      ; CHARGER PB7 PIA
        LSLA            ; PB7=1
        BCC SCARRY      ; NON, ATTENDRE UN 1 DEBUT CARAC.
DLY30U  DECB            ; OUI, DELAI # 30MICROSEC
        BNE DLY30U
        LDA DISCNT      ; CHARGER DE NOUVEAU PB7
        LSLA            ; 1 TOUJOURS PRESENT?
        BCC NOUDLY      ; NON, NOUVELLE ATTENTE D'UN CARAC.
        LDB #$24        ; OUI, DELAI 430MICROSEC MINI
CARRY1  DECB
        LDA DISCNT
        LSLA            ; TOUJOURS 1?
        BCS CARRY1      ; OUI, DECOMPTER
        LDA #$EF        ; NON, DECOMPTE>720MICROSEC.
        TSTB            ; BIT CARAC.=0?
        BMI AFSIGN      ; OUI, AFFICHER SIGNE POUR 0
        ASRA            ; NON, AFFICHER SIGNE POUR 1
AFSIGN  STA DISREG
        TSTB
        PULS PC,B,A     ; RTS


******** POSITIONNEMENT DU BIT DU CARACTERE ********
***** TRANSMIS DANS LE LSB DE L'ACCUMULATEUR B *****
*
*
*
BITLSB  PSHS A
BITCA1  BSR RECBIT      ; RECONNAISSANCE BIT TRANSMIS
        BPL BITCA1      ; BIT CARAC. = 1
        LDA #$08        ; RECONNAISSANCE BIT SUIVANTS
CONROT  BSR RECBIT      ; BIT CARAC=0 RECON BITS SUIVANTS
        ANDCC #$FE      ; CARRY=0
        BMI BITCA0      ; BIT CARACTERE = 0 ?
        ORCC #$01       ; NON, METRE CARRY A 1
BITCA0  RORB            ; OUI, DEPLACER LA CARRY
        DECA            ; PAR ROTATIONS SUCCESSIVES
        BNE CONROT      ; CARRY DANS LSB DE ACCB
        PULS PC,A       ; RTS


****** CHARGEMENT D'UN PROGRAMMA PROVENANT D'UNE CASSETTE ******
****************************************************************


EXLOAD  LDD #$0000
        STD SCNREG      ; ACCES A DDRAB
        LDD #$FF7F
        STD DISREG      ; PA ET PB EN SORTIE
        LDD #$0404      ; PB7 EN ENTREE
        STD SCNREG      ; ACCES DRAB
        LDD #$FF04      ; ETEINDRE LES AFFICHEURS
        STD DISREG      ; ET SELECTIONNER LE 1er DIGIT
DETECS  BSR BITLSB      ; DETECTE CARACTERE DEBUT CHARGEMENT
        CMPB #$53       ; CARACTERE S TRANSMIS ?
        BNE DETECS      ; NON, CONTINUER A CHERCHER CARACTERE
        BSR BITLSB      ; OUI, CARACTERES SUIVANTS 
        CMPB #$31       ; CARACTERE 1 TRANSMIS ?
        BEQ CARSUI      ; OUI, CARACTERES SUIVANTS
        CMPB #$4A       ; NON, CARACTERE FIN = J ?
        BNE DETECS      ; NON, DETECTER CARACTERE DE FIN
AFICHA  LDA #$69        ; LDA #$69 OUI, AFFICHER FIN DU CHARGEMENT
        BRA DISFIN


****** MISE EN MEMOIRE, POINTEE PAR X DES CARAC TRANSMIS ******
***************************************************************

CARSUI  BSR BITLSB      ; CONVERSION INTERVALE
        STB <SAVCNT
        LDA <SAVCNT
        BSR BITLSB
        STB <SAVB1
        PSHS B
        ADDA ,S+        ; A + B DANS ACCA
        DEC <SAVCNT 
        BSR BITLSB 
        STB <SAVB2
        PSHS B
        ADDA ,S+        ; A + B DANS ACCA
        LDX <SAVB1      ; X CONTIENT ADRESSE DE CHARGEMENT
SUICHA  DEC <SAVCNT
        BEQ DERADD      ; DERNIERE ADRESSE ?
        BSR BITLSB      ; NON, CONTINUER A CHARGER
        STB ,X+         ; ET A METTRE EN MEMOIRE
        PSHS B
        ADDA ,S+        ; A + B DANS ACCA
        BRA SUICHA 
        
DERADD  BSR BITLSB      ; OUI, DERNIERE ADRESSE
        PSHS B
        ADDA ,S+        ; ERREUR DANS LA TRANSMISSION
        BEQ DETECS 
        LDA #$78        ; OUI, AFFICHER L'ERREUR
DISFIN  LBSR CLRDIS 
        STA <DISBUF
BOUFIN  LBSR DISPRE
        BRA BOUFIN


****** CHARGEMENT D'UN PROGRAMME D'UNE ZONE MEMOIRE ******
*******************VERS UN MAGNETOCASSETTE ***************
**********************************************************


EXPUNC  LDX #$003D 
        STX <DISBUF+4   ; AFFICHER S POUR START
        LBSR BADDR      ; FABRIQUER ADRESSE DE DEBUT
        STX <SADDR1     ; SAUVE DEBUT ADRESSE
        LDA #$69        ; AFFICHER F POUR FIN
        STA <DISBUF+5
        LBSR BADDR      ; FABRIQUER ADRESSE DE FIN
        STX <SADDR2     ; SAUVE FIN ADRESSE
        CLRA            ; ACCES A DDRB
        STA SCNCNT
        DECA            ; PB EN SORTIE
        STA DISCNT 
        LDA #$04        ; ACCES A ORB DU PIA
        STA SCNCNT
        CLRA            ; LIGNE No 0 A 0 ET PB6 = 0
        STA DISCNT
        LDA #$FF 
        BSR DLY5MS      ; FABRICATION D'UNE SERIE
        BSR DLY5MS      ; DE 10 PERIODES DE 1400 ET 5600HZ
RECYCL  BSR DEBCHA      ; CHARGER CARACTERE DE DEBUT
        LDA #$FF
        LDB <SADDR1+1   ; POIDS FAIBLE ADRESSE DEBUT
        PSHS B
        SUBA ,S+        ; A + B DANS ACCA
CODFIN  ANDA #$0F 
        ADDA #$03       ; TRANSMISSION D'UN CARACTERE
        BSR DLY5MS      ; INTERVALE
        STA <SAVREG
        LDX #SADDR1     ; DEBUT ADRESSE
        BSR TRANSM      ; TRANSMISSION MSB ADRESSE DEBUT
        ADDA <SAVREG
        STA <SAVREG
        LEAX 1,X
        BSR TRANSM      ; TRANSMISSION LSB ADRESSE DEBUT
        ADDA <SAVREG
        STA <SAVREG
        LDX <SADDR1     ; X POINTE SUR PROGRAMME A ENREGISTRER
TJTRAN  BSR TRANSM      ; TRANSMISSION DES DONNEES
        ADDA <SAVREG
        STA <SAVREG 
        CMPX <SADDR2    ; FIN D'ENREGISTREMENT ?
        BEQ FINENR      ; OUI, TRANSMETTRE FIN
        LEAX 1,X        ; NON, DONNEE SUIVANTE A TRANSMETTRE
        STX <SADDR1     ; SAUVE POINTEUR
        LDA <SADDR1+1
        BITA #$0F       ; 16 CARACTERES TRANSMIS ?
        BNE TJTRAN      ; NON, CONTINUER TRANSMISSION
FINENR  LDA <SAVREG     ; OUI, 16 CARACTERES TRANSMIS
        NEGA
        BSR DLY5MS      ; TRANSMISSION CODE POUR 16CARAC TRANSMIS
        CMPX <SADDR2    ; FIN PROGRAMME ?
        BEQ FINCHA      ; OUI, TRANSMETTRE FIN CHARGEMENT
        LDA <SADDR1     ; NON, MSB DEBUT ADRESSE
        CMPA <SADDR2    ; < MSB FIN ADRESSE ?
        BMI RECYCL      ; OUI, RECOMMENCER CYCLE
        LDB <SADDR1+1   ; NON, LSB DEBUT ADRESSE
        LDA <SADDR2+1   ; -LSB FIN ADRESSE <>0 ?
        ANDA #$F0
        PSHS B
        CMPA ,S+        ; COMPARE B A ACCA
        BNE RECYCL      ; OUI, RECOMMENCER UN CYCLE
        BSR DEBCHA      ; NON, TRANSMETTRE DEBUT CHARGEMENT
        LDA <SADDR2+1   ; DU CODE DE FIN
        BRA CODFIN      ; CHARGEMENT PUIS FIN


****** FABRICATION DU SIGNAL DE FIN DE CHARGEMENT ******
*
*
FINCHA  LDA #$53
        BSR DLY5MS
        LDA #$4A
        BSR DLY5MS
        LBRA AFICHA     ; AFFICHAGE FIN DE CHARGEMENT


****** FABRICATION DU SIGNAL DE DEBUT DE CHARGEMENT ******
*
*
DEBCHA  LDA #$53
        BSR DLY5MS      ; TRANSMISSION CARACTERE S
        LDA #$31
        BRA DLY5MS      ; TRANSMISSION DU CARACTERE 1


****** FABRICATION DU SIGNAL SERIALISE ******
*********** DE 10 PERIODES PAR DONNEES **********
*
*
TRANSM  LDA ,X
DLY5MS  PSHS B,A
        LDB #$0A
        STB <SAVRES
        ANDCC #$FE      ; METTRE CARRY A 0
BOUCL3 LDB #$90         ; DELAI = 720MICROSEC
        BCC SAUT
        LDB #$24        ; DELAI = 180MICROSEC
SAUT    PSHS B
        LDB #$40
        STB DISCNT      ; PB6=1
        LDB ,S
BOUCL1  DECB            ; DELAY 180 OU 720MICROSEC
        BNE BOUCL1
        STB DISCNT      ; PB6=0
        PULS B
BOUCL2  DECB            ; NOUVEAU DELAY DE 180 OU 720MICROSEC
        BNE BOUCL2
        ORCC #$01       ; METTRE CARRY A 1
        RORA
        DEC <SAVRES
        BNE BOUCL3      ; TERMINER DELAY DE 5MS
        PULS PC,B,A     ; RTS


***** EXECUTION DE LA FONCTION OFFSET *****
*
*
*
EXOFST  LBSR INCREM
        LDA ,X
        CMPA #$16       ; LBRA?
        BEQ EXLBIL      ; OUI, BRANCHEMENT LONG INCONDITIONNEL
        CMPA #$17       ; LBSR/
        BEQ EXLBIL      ; OUI, //////////////////////////////
        LDA ,-X         ; POINTER SUR INSTRUCTION PRECEDENTE
        CMPA #$10       ; BRANCHEMENT CONDITIONNEL LONG?
        BEQ EXLBCL      ; OUI
OFPOCT  LEAX 3,X        ; X CONTIENT ADRESSE DU BRANCHEMENT COURT
        BSR CALOFS      ; CALCULER OFFSET
        BVS RETOU1      ; SI DEPASSEMENT DE CAPACITE, ERREUR
        BITA <NEGPOS
        BEQ BRANPO      ; TOUT MSB A 0 = BRANCH POS
        BMI BRANNE      ; MSBIT=1 BRANCH NEG
        BRA RETOU1      ; BRANCH SUR 16 BITS
        
BRANPO  TSTB
        BEQ RETOU1      ; BRANCH NUL IMPOSSIBLE 
        BMI RETOU1      ; N=1, ERREUR BRANCH=16BITS
        BRA CHARGE      ; N=0, CHARGE OFFSET DS MEM PROG
        
BRANNE  CMPA <NEGPOS    ; A=FF?
        BNE RETOU1      ; NON, ERREUR BRANCH SUR 16 BITS
        TSTB            ; POSITIONNER N
        BPL RETOU1      ; N=0, BRANCH SUR 16BITS
        CMPB #$FF
        BEQ RETOU1
CHARGE  STB ,-Y         ; STOCKE OFFSET DS MEM PROG
        LBSR AFFIAD     ; AFFICHE ADRESSE DE STOCKAGE
        LBRA REMEMO     ; RETOUR DS FCT MEMOIRE
        
EXLBCL  LEAX 1,X 
EXLBIL  LEAX 3,X        ; BRANCH LONG, X=ADRESSE DE DEPART
        BSR CALOFS      ; CALCULE OFFSET
        BVS RETOU2      ; SI DEPASSE CAPACITE, ERREUR
        CMPA #$FF
        BEQ PLUCOU      ; BRANCH COURT PEUT ETRE POSSIBLE
        CMPA #$00 
        BEQ BCOURT      ; BRANCH>0 COURT POSSIBLE
SUITEB  STD ,--Y        ; STOCKE OFFSET DS MEM PROG
        BSR AFFIAD      ; AFFICHE ADRESSE
        LBRA REMEMO     ; RETOUR DS FCT MEMOIRE


****** CALCULE L'OFFSET SUR 16 BITS ******
**** D CONTIENT L'OFFSET,Y=ADRESSE DEP ***
*
*
*
CALOFS  TFR X,Y         ; Y=ADRESSE DE DEPART
        STY <ADDDEP
        BSR AFFIAR      ; AFFICHAGE ADRESSE ARRIVEE
        TFR X,D         ; D=ADRESSE DEPART
        SUBD <ADDDEP    ; D=ARRIVEE-DEPART=OFFSET
        RTS


** DETERMINE SI LE BRANCH SUR 16BITS PEUT SE FAIRE SUR 8BITS **
*
*
*
PLUCOU  ROLB
        BCS RETOU2      ; BRANCH COURT POSSIBLE
        RORB
        BRA SUITEB      ; CONTINUE CALCUL
        
BCOURT  ROLB
        BCC RETOU2
        RORB
        BRA SUITEB
    
RETOU1  LEAY -2,Y
        BRA CLIGNO      ; AFFICHE ERREUR, PUIS RETOUR MEMORY
        
RETOU2  LEAY -4,Y
        LDA ,Y+
        CMPA #$10
        BEQ CLIGNE
        LDA ,Y
        CMPA #$16
        BEQ CLIGNO
        CMPA #$17
        BEQ CLIGNO
        ANDA #$8F
        CMPA #$8D
        BEQ CLIGNO
        LBRA RPOINT     ; SI PAS BRANCH, RETOUR RESET
        
CLIGNE  LEAY -1,Y
CLIGNO  BSR AFFIAD      ; AFFICHE ADRESSE OU EST L'ERREUR
        BSR ERROR       ; PLACE ERREUR DS DISBUF
        LDY #$02FF
AFCLIG  LBSR DISPRE     ; AFFICHE L'ERREUR
        BRA TEMPO       ; TEMPORAIREMENT
        
ERROR   LDD #$7941      ; PLACE ER DANS LES 2
        STD <DISBUF+4   ; DERNIERS DIGITS
        RTS
        
TEMPO   LEAY -1,Y
        BNE AFCLIG
        LBRA REMEMO     ; RETOUR DANS FCT MEMORY


****** AFFICHAGE DE L'ADRESSE D'ARRIVEE ******
** STOCKE DS NEGPOS LE SENS DE L'OFFSET<>0 ***
*
*
*
AFFIAR  LDD #$6F41      ; AFFICHE AR DS DISBUF
        STD <DISBUF+4
        LBSR BADDR      ; AFFICHE ADRESSE ARRIVEE
        STX <ADDARR
        LBSR GETKEY
        CMPA #$31       ; TOUCHE GO?
        BEQ SUIVT       ; OUI, CHARGE ADRESSE
        LBRA RPOINT 
        
SUIVT   LBSR CLRDIS     ; ETEINDRE AFFICHAGE
        LDA #$FF
        CMPX <ADDDEP    ; ARRIVEE<DEPART ?
        BLO STOCKA      ; OUI, STOCKE DS NEGPOS
        INCA
STOCKA  STA <NEGPOS     ; NEGPOS=0>0 NEGPOS=FF<0
        RTS


****** AFFICHE L'ADRESSE DE CHARGEMENT ******
** DE L'OFFSET DANS LES 4 PREMIERS DIGITS ***
*
*
*
AFFIAD  TFR Y,X
        TFR X,D         ; NLLE ADRESSE DE DEP APRES INSTRUC
        LBSR R7SEG 
        STA <DISBUF+1
        TFR X,D
        LBSR L7SEG
        STA <DISBUF
        TFR B,A
        LBSR R7SEG
        STA <DISBUF+3
        TFR B,A
        LBSR L7SEG
        STA <DISBUF+2
        RTS


*************************
****** NMI ROUTINE ******
*************************


RNMI    LDX >SAVNMI
        JMP ,X          ; EXECUTE ROUTINE NMI



*******************************        
* Routines from documentation *
*******************************

* Displays: 6809 uP  or 6309 uP
* Etudes atour du 6809, p55
* Added 6309 check from bertmon53
                      
D6809uP
        JSR     DT6863
        BNE     D63
D68
        LDD     #$7D7F      ; 68
        BRA     D09uP
D63
        LDD     #$7D1F      ; 63
D09uP
        STD     DISBUF
        LDD     #$7E3F      ; 09
        STD     DISBUF+2
        LDD     #$636B      ; uP
        STD     DISBUF+4
DPLOOP  JSR     >DISPRE
        BRA     DPLOOP

DT6863  ; 6809/6309 test
        PSHS    D
        FDB     $1043           ; 6309 COMD, 6809 COMA
        CMPB    1,S             ; 6309 NE,   6809 EQ
        CLRA    ;$              ; TEST 6309
        INCA    ;$
        PULS    D,PC 

* Displays: 'tst-kk'
* Key value as reported by GETKEY

KBTEST
        LDD     #$713D
        STD     DISBUF
        LDD     #$7101
        STD     DISBUF+2
        CLRA
        CLRB
        STD     DISBUF+4
KBLOOP  
        LBSR    >GETKEY
        PSHS    A
        LBSR    >L7SEG
        STA     DISBUF+4
        PULS    A
        LBSR    >R7SEG
        STA     DISBUF+5
        LBSR    >DISPRE 
        BRA     KBLOOP

* segments:
*     _3_
*  5 |   | 1
*    |_0_| 
*  6 |   | 2
*    |_4_|
* segments:

*   U1: |_|   U2: |_|   U3:  _|  U4:    _|   U5:   |
*        _|         |        _|          |        _|
*     
*    X: | |  Bpt: | |   P:   |_    L:   |   Ofs: |_|
*   $36  _|   $26   |  $35    _|  $34    _|  $33  _
*
*  Cnt: | |  Go:  |_   Reg:  |   Mem:   |   Dec:      Inc:
*   $32  _   $31   _    $30   _   $20        $10  _    $00
*
*          B:    C:    D:    E:    F:
*          $25   $24   $23   $22   $21
*          6:    7:    8:    9:     A:
*          $15   $14   $13   $12   $11
*    0:    1:    2:    3:    4:     5:  
*    $06   $05   $04   $03   $02    $01


*************************************
****** VECTEURS D'INTERRUPTION ******
*************************************


        ORG $EFF2

        FDB RSWI3       ; INTERRUPTION SOFT No 3
        FDB RSWI2       ; INTERRUPTION SOFT No 2
        FDB RFIRQ       ; INTERRUPTION RAPIDE HARD
        FDB RIRQ        ; INTERRUPTION NORMALE HARD
        FDB RSWI        ; INTERRUPTION SOFT No 1
        FDB RNMI        ; INTERRUPTION NON MASQUABLE HARD
        FDB RESTAR      ; RESET GENERAL


***************************************
****** EMPLACEMENT DES REGISTRES ******
***************************************


PILE    EQU $07C0       ; PILE SYSTEME
PILMON  EQU $07A0       ; INITIALISATION PILE MONITEUR
RSWI3   EQU $077A
RFIRQ   EQU $0775
RIRQ    EQU $0770
MABS    EQU $0760       ; P-segment for DISBUF+4 & DISBUF+5

*       A2 A1 A0  CRA-2 CRB-2 
*  0-3  0  x  x    x     x   not selected
*  4    1  0  0    0     x   Data Direction Register A
*  4    1  0  0    1     x   Peripheral Register A
*  5    1  0  1    x     0   Data Direction Register B
*  6    1  1  0    x     x   Control Register A
*  7    1  0  1    x     1   Peripheral Register B
*  7    1  1  1    x     x   Control Register B
* 
* Control Register
* b7  b6  b5  b4  b3  b2  b1  b0
*  |   |   |   |   |   |   |   |
*  |   |   |   |   |   |   |   +--- Interrupt Request Enable: b0=1  / Disable b0=1
*  |   |   |   |   |   |   +------- Cx1 Active transition: b1=high-to-low / b1=low-to-high
*  |   |   |   |   |   +----------- DDR/Output Register selected: b2=0 DDR / b2=1 Output Register
*  |   |   +---+---+--------------- Cx2 Mode
*  |   +--------------------------- Interrupt Flag Cx2: b7=1 Interrupt occurred
*  +------------------------------- Interrupt Flag Cx1: b7=1 Interrupt occurred
*
* Data Direction Register
* 1=output, 0=input

DISREG  EQU $A004       ; DRA-ACCES CLAVIER ET SEGMENTS      PIA DDR/PR A
DISCNT  EQU $A005       ; ORB-COMMANDE CLAVIER ET AFFICHEUR  PIA DDR/PR B
SCNREG  EQU $A006       ; PIACRA
SCNCNT  EQU $A007       ; PIACRB


************************************************
****** PARAMETRES VARIABLES SITUES EN RAM ******
************************************************

        ORG $07DD

SAVNMI  RMB 2
SASWI2  RMB 2
PRESER  RMB 1
SAUVER  RMB 1
PLUSMS  RMB 1
SAVPOC  RMB 1
PRESEH  RMB 1
PRESEL  RMB 1
PRELOW  RMB 2
NEGPOS  RMB 1
ADDDEP  RMB 2
ADDARR  RMB 2
COMDEC  RMB 1
SAVRES  RMB 1
SAVCNT  RMB 1
SAVREG  RMB 1
SADDR1  RMB 2
SADDR2  RMB 2
SAVB1   RMB 1
SAVB2   RMB 1
SAVPIL  RMB 2
DISBUF  RMB 6

        END 


