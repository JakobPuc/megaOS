.INCLUDE "m328pdef.inc"
.INCLUDE "interrupt.asm"

.CSEG
.EQU CPU_FREQ = 16000000
.EQU BAUD = 9600 
.EQU BPS = (CPU_FREQ / 16 / BAUD) - 1

.EQU RX_BUFFER_SIZE = 64 ; More bit potenca dvojke!!!!!
.EQU BUFFER2_SIZE = 64 

START:
	CLI

	LDI R16, LOW(RAMEND)
	OUT SPL, R16
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16

	LDI XL, LOW(BUFFER2)
	LDI XH, HIGH(BUFFER2)
	LDI R16, 0 
	LDI R17, BUFFER2_SIZE
	CALL MEMSET

	LDI XL, LOW(UKAZ)
	LDI XH, HIGH(UKAZ)
	LDI R16, 0 
	LDI R17, 8
	CALL MEMSET

	LDI XL, LOW(PARAMETER)
	LDI XH, HIGH(PARAMETER)
	LDI R16, 0 
	LDI R17, BUFFER2_SIZE - 8
	CALL MEMSET

	LDI R16, LOW(BPS)
	LDI R17, HIGH(BPS)
	STS UBRR0L, R16
	STS UBRR0H, R17

	LDI R16, (1 << RXEN0) | (1 << TXEN0) | (1 << RXCIE0) | (1 << TXCIE0) | (1 << UDRIE0)
	STS UCSR0B, R16

	CLR R16
	STS TX_BUSY, R16
	STS WRITE_HEAD_L, R16
	STS READ_HEAD_L, R16

	SEI

	LDI ZL, LOW(POZDRAV * 2)
	LDI ZH, HIGH(POZDRAV * 2)
	CALL FPRINTS

LOOP:
	LDI XL, LOW(BUFFER2)
	LDI XH, HIGH(BUFFER2)
	LDI R16, 0x00
	LDI R17, BUFFER2_SIZE
	CALL MEMSET

	LDI XL, LOW(UKAZ)
	LDI XH, HIGH(UKAZ)
	LDI R16, 0x00
	LDI R17, 8
	CALL MEMSET

	LDI XL, LOW(PARAMETER)
	LDI XH, HIGH(PARAMETER)
	LDI R16, 0x00
	LDI R17, BUFFER2_SIZE - 8
	CALL MEMSET

	LDI XL, LOW(BUFFER2)
	LDI XH, HIGH(BUFFER2)

	LDI R16, '>'
	CALL PUTCHAR

WAIT_FOR_CHARACTER:
	CALL GETCHAR
	BREQ WAIT_FOR_CHARACTER

	CPI R16, 0x7F ; DEL 
	BRNE SAVE_TO_BUFFER

	CPI XL, LOW(BUFFER2) ; Za bufferje manjše od 256 byte-ov bo ta goljufija delala.
	BREQ WAIT_FOR_CHARACTER

	CALL PUTCHAR
	CLR R16
	ST -X, R16
	RJMP WAIT_FOR_CHARACTER

SAVE_TO_BUFFER:	
	CALL PUTCHAR
	ST X+, R16
	
	CPI R16, 0x0D
	BRNE WAIT_FOR_CHARACTER	

	CALL LOCI_UKAZ

	LDI R16, 0x0A
	CALL PUTCHAR
	LDI R16, 0x0D
	CALL PUTCHAR

	LDI XL, LOW(UKAZ)
	LDI XH, HIGH(UKAZ)
	CALL MPRINTS

	LDI XL, LOW(PARAMETER)
	LDI XH, HIGH(PARAMETER)
	CALL MPRINTS

	CLR R18

	LDI YL, LOW(UKAZ)
	LDI YH, HIGH(UKAZ)

	LDI ZL, LOW(COMMAND_START * 2)
	LDI ZH, HIGH(COMMAND_START * 2)

COMMAND_SEEK_LOOP:
	CALL STRMFCMP
	BREQ FOUND

	INC R18

	CALL STRFLEN
	ADD ZL, R16
	ADC ZH, R17

	LPM R16, Z
	CPI R16, 0x03
	BREQ NOT_FOUND

	RJMP COMMAND_SEEK_LOOP

FOUND:
	LDI ZL, LOW(COMMAND_JUMP_TABLE_START)
	LDI ZH, HIGH(COMMAND_JUMP_TABLE_START)

	CLR R19
	LSL R18
	
	ADD ZL, R18
	ADC ZH, R19	
	
	IJMP

NOT_FOUND:
	LDI ZL, LOW(NOT_FOUND_MSG * 2)
	LDI ZH, HIGH(NOT_FOUND_MSG * 2)
	CALL FPRINTS

	JMP LOOP

HANG:
	RJMP HANG

POZDRAV: .DB "megaOS (ver 69.420)", 0x0A, 0x0D, 0x00
FOUND_MSG: .DB "Command found!", 0x0A, 0x0D, 0x00
NOT_FOUND_MSG: .DB "Command not found.", 0x0A, 0x0D, 0x00
LEN_PROGRAMER: .DB "Ni implementirano ker je bil programer len.", 0x0A, 0x0D, "Lp programer", 0x0D, 0x0A, 0x00

COMMAND_START:
.DB "echo", 0x00, "sus", 0x00, 0x03
COMMAND_END:

COMMAND_JUMP_TABLE_START:
JUMP_ECHO: JMP ECHO 
JUMP_SUS: JMP SUS
COMMAND_JUMP_TABLE_END:

JERMA_SUS:
.DB "                     .,..,,*,,..,,,,,,,**", 0x0D, 0x0A, "                 .*,,...................,*/", 0x0D, 0x0A, "               ,,...../..,.,,,***/******,,*,*//", 0x0D, 0x0a, "             ,,.  ..,,,,,//((##%%%%%%####(/,,..,*", 0x0D, 0x0a, "           .,*.  ,,****,/((#####%%%&%%#####(/*....", 0x0D, 0x0a, "           *.. .**//***/((((###%%%%&%%####(#(/,....", 0x0D, 0x0a, "          ,,...*****/*/(((#######%%%%%%#####(/*....", 0x0D, 0x0a, "          ., .,****/((((((((((######%%%#####((*....", 0x0D, 0x0a, "           ...***,,,,*///(((((((((((/****//(##/,..,", 0x0D, 0x0a, "           ...,,**,....,,,**/((//**...,,..,*/##,...", 0x0D, 0x0a, "            ,.***.,**   ,.,,(#%#*.,**,.,(/(*/#%*.//", 0x0D, 0x0a, "           /../*,,,*/,,,,,,*(###((/*,,,,/(##//(/,*(", 0x0D, 0x0a, "           .,,***/(((((//***/##(((((////(((###///(%", 0x0D, 0x0a, "           , ,**//(((/****,/((#(((((/***/(((((((#%%", 0x0D, 0x0a, "            .******.,*,****/(((((//(((//**,*(#*(#(.", 0x0D, 0x0a, "              ****,,,**,,,,,****//(((/**,,..,/**", 0x0D, 0x0a, "              **/,/*,.,,,,,*,*/*****#//../*./(/", 0x0D, 0x0a, "               ****/*,,#%#&(%%#&&&@@&&.*(/,(*/", 0x0D, 0x0a, "                ,**//**,.*%#%%%&&##*#**((((//", 0x0D, 0x0a, "                  .*//**,*,(((*(#(%%(/((#(*", 0x0D, 0x0a, "              .,***,,/***//***/*///((((#((/(#/##", 0x0D, 0x0a, "        .,****.*/* *,,,****///////((((#(*/(((*/##(##%%", 0x0D, 0x0a, "((///***,,****.**.**,,,,,///(((((((#(((*//,/#/(#########(#%", 0x0D, 0x0a, "/*,,,,**,,**/*,/*,,,,***,,*//(((((((/,*//((*,/###########%%#", 0x0D, 0x0a, 0x00

ECHO:
	LDI ZL, LOW(LEN_PROGRAMER * 2)
	LDI ZH, HIGH(LEN_PROGRAMER * 2)
	CALL FPRINTS

	JMP LOOP

SUS:
	LDI ZL, LOW(JERMA_SUS * 2)
	LDI ZH, HIGH(JERMA_SUS * 2)
	CALL FPRINTS

	JMP LOOP

; Pošlje znak v registru R16 po UART-u.
;
; R16 -> Znak, ki ga želimo poslati.
PUTCHAR:
	PUSH R17

PUTCHAR_WAIT:
	LDS R17, TX_BUSY
	CPI R17, 0 
	BRNE PUTCHAR_WAIT

	STS UDR0, R16

	LDI R17, 1 
	STS TX_BUSY, R17

	POP R17
	RET

; Dobi znak iz RX buffer-ja in ga da v R16.
; Če je zero flag postavljen pomeni, da ni več ničesar v RX buffer-ju. 
;
; R16 <- Znak, prebran iz RX buffer-ja. 
GETCHAR:
	PUSH R17
	PUSH XL
	PUSH XH

	LDS XL, READ_HEAD_L
	LDI XH, 0x01 

	LDS R17, WRITE_HEAD_L
	CP XL, R17
	BREQ GETCHAR_OUT

	LD R16, X+
	ANDI XL, RX_BUFFER_SIZE - 1
	STS READ_HEAD_L, XL
	CLZ

GETCHAR_OUT:
	POP XH
	POP XL
	POP R17
	RET	

BUFFER2_SETUP:
	PUSH XL
	PUSH XH
	PUSH R16
	PUSH R17
	LDI XL, LOW(BUFFER2)
	LDI XH, HIGH(BUFFER2)
	LDI R17, 0x00
	LDI R16, BUFFER2_SIZE
	BUFFER2_CLEAR:
	ST X+, R17
	DEC R16
	BRNE BUFFER2_CLEAR
	POP R17
	POP R16
	POP XH
	POP XL
	RET

; Nastavi buffer na dano vrednost.
;
; X -> Lokacija bufferja.
; R16 -> Vrednost na katero hočemo nastavit buffer.
; R17 -> Velikost bufferja.
MEMSET:
	PUSH R17
	PUSH XL
	PUSH XH

MEMSET_LOOP:
	ST X+, R16
	DEC R17
	BRNE MEMSET_LOOP

	POP XH
	POP XL
	POP R17
	RET

; Kopira en buffer v drugega.
;
; X -> Buffer v katerega bodo šle kopirane vrednosti.
; Y -> Buffer iz katerega kopiramo.
; R16 -> Velikost bufferja.
MEMCPY:
	PUSH R16
	PUSH R17
	PUSH XL
	PUSH XH
	PUSH YL
	PUSH YH

MEMCPY_LOOP:
	LD R17, Y+
	ST X+, R17
	DEC R16
	BRNE MEMCPY_LOOP

	POP YH
	POP YL
	POP XH
	POP XL
	POP R17
	POP R16
	RET

; Pošlje besedilo v flash-u po UART-u.
;
; Z -> Lokacija besedila v flash-u.
FPRINTS:
	PUSH R16
	PUSH ZL
	PUSH ZH

FPRINTS_LOOP:
	LPM R16, Z+
	OR R16, R16
	BREQ FPRINTS_OUT
	CALL PUTCHAR
	RJMP FPRINTS_LOOP

FPRINTS_OUT:
	POP ZH
	POP ZL
	POP R16
	RET

; Pošlje besedilo v RAM-u po UART-u.
;
; X -> Lokacija besedila v RAM-u.
MPRINTS:
	PUSH R16
	PUSH XL
	PUSH XH

MPRINTS_LOOP:
	LD R16, X+
	OR R16, R16
	BREQ MPRINTS_OUT
	CALL PUTCHAR
	RJMP MPRINTS_LOOP

MPRINTS_OUT:
	LDI R16, 0x0A
	CALL PUTCHAR
	LDI R16, 0x0D
	CALL PUTCHAR

	POP XH
	POP XL
	POP R16
	RET

; Primerja string v RAM-u in string v flash-u. Zastavica zero je postavljena če sta stringa enaka.
;
; Y -> String v RAM-u.
; Z -> String v flash-u.
STRMFCMP:
	PUSH R16
	PUSH R17
	PUSH YL
	PUSH YH
	PUSH ZL
	PUSH ZH

STRMFCMP_LOOP:
	LD R16, Y+
	LPM R17, Z+

	CP R16, R17
	BRNE STRMFCMP_OUT

	CPI R16, 0
	BRNE STRMFCMP_LOOP

STRMFCMP_OUT:
	POP ZH
	POP ZL
	POP YH
	POP YL
	POP R17
	POP R16
	RET

; Vrne dolžino stringa v flash-u v R16:R17.
;
; Z -> Naslov buffer-ja.
STRFLEN:
	PUSH ZL
	PUSH ZH

STRFLEN_LOOP:
	LPM R16, Z+
	OR R16, R16
	BRNE STRFLEN_LOOP

STRFLEN_OUT:
	POP R17 ; ZH
	SUB ZH, R17

	PUSH R17
	MOV R17, ZH
	POP ZH

	POP R16 ; ZL
	SUB ZL, R16

	PUSH R16
	MOV R16, ZL 
	POP R16

	RET


; Loci ukaz na parameter in ukaz.
LOCI_UKAZ:
	PUSH XL
	PUSH XH
	PUSH YL
	PUSH YH
	PUSH R17
	PUSH R18

	LDI R18, 8
	LDI XL, LOW(BUFFER2)
	LDI XH, HIGH(BUFFER2)
	LDI YL, LOW(UKAZ)
	LDI YH, HIGH(UKAZ)

LOCI_1:
	LD R17, X+
	CPI R17, 0x20
	BREQ NAPREJ2
	CPI R17, 0x00
	BREQ KONEC
	DEC R18 
	BREQ KONEC
	ST Y+, R17
	RJMP LOCI_1

NAPREJ2:
	LDI R17, 0x00
	ST Y , R17
	LDI R18, BUFFER2_SIZE - 8
	LDI YL, LOW(PARAMETER)
	LDI YH, HIGH(PARAMETER)

LOCI_PARAMETER2:
	DEC R18
	BREQ KONEC
	LD R17, X+
	ST Y+, R17
	CPI R17, 0x0D
	BRNE LOCI_PARAMETER2 
	LDI R17, 0x00
	ST Y, R17

KONEC:
	CALL BUFFER2_SETUP
	POP R18
	POP R17
	POP YH
	POP YL
	POP XH
	POP XL
	RET

.DSEG
.ORG 0x0100
; Pred RX_BUFFER-jem mi ne vrivi nč.
RX_BUFFER: .BYTE RX_BUFFER_SIZE
; Tle naprej se lohk dela nove bufferje.
WRITE_HEAD_L: .BYTE 1
READ_HEAD_L: .BYTE 1
TX_BUSY: .BYTE 1

PARAMETER: .BYTE BUFFER2_SIZE - 8
UKAZ: .BYTE 8  ; MAKS DOLZINA UKAZA JE 5 KER PAC
BUFFER2: .BYTE BUFFER2_SIZE
