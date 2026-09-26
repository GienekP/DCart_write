;***********************************************************************
;
; DCart starter - Write Procedures
; Exmaple for first 5 banks
; (c)2026 GienekP
;
;***********************************************************************
DEFAULT_BANK_OFF = 0
;-----------------------------------------------------------------------
MAIN	= $0600
;----------------
PTR		= $A0
STCKPRC = $0100
;----------------
CRITIC  = $42
GINTLK  = $03FA
TRIG3   = $D013
CONSOL  = $D01F
WSYNC	= $D40A
VCOUNT  = $D40B
RESETCD = $E477
;-----------------------------------------------------------------------
; ... I love MADS
.MACRO PROC
	.IF .NOT .DEF %%1
        .DEF :%%1 = *
	.ENDIF
.ENDM
;-----------------------------------------------------------------------
; DCart Procedures
.MACRO DCART_PROCEDURES
;-------------------------------
;	$B5XX - special Page for DCart
		ORG $B500
;-------------------------------
; This proc see as $D5XX
.LOCAL D5DCART,$D500
;-------------------------------
; Just RTS
		PROC RTSDCRT
;----------------
		rts
;-------------------------------
; Reset DCart and REBOOT
		PROC RESETDC
;----------------
		jsr WAITFSL
		sta $D500
		jmp RESETCD
;-------------------------------
; Safe turn on X bank of DCart
		PROC DCARTON
;----------------	
		jsr WAITFSF
		sta $D500,x
		jmp CPYT32G
;-------------------------------
; Safe turn off bank of DCart
		PROC DCARTOFF
;----------------
		jsr WAITFSF
		sta $D580+DEFAULT_BANK_OFF
		jmp CPYT32G
;-------------------------------
; Wait for Safe Line
		PROC WAITFSL
;----------------
		lda #$7A
@		cmp VCOUNT
		bne @-
		rts
;-------------------------------
; Wait for Safe Field
		PROC WAITFSF
;----------------
		lda #$7B
@		cmp VCOUNT
		bcc @-
		rts
;-------------------------------
; COPY TRIG3 to GINTLK - when switching banks
		PROC CPYT32G
;----------------
		lda TRIG3
		sta GINTLK
		rts
;-------------------------------
; CRITIC ON
		PROC CRITICON
;----------------
		lda #$01
		sta CRITIC
		rts
;-------------------------------
; CRITIC OFF
		PROC CRITICOFF
;----------------
		lda #$00
		sta CRITIC
		rts
;-------------------------------
; Read form $YYXX
		PROC READDC
;----------------
		jsr WAITFSF
		sta $D500
		lda WRBUFAD,x
		sta $D580+DEFAULT_BANK_OFF
		rts
;-------------------------------
; Write A to $YYXX
		PROC WRITEDC
;----------------
		pha
		txa
		pha
		jsr CRITICON
		ldx #$00
		jsr DCARTON
		jsr WRITERT
		pla
		tax
		pla
		sta $D500
		sta WRBUFAD,x		
		jsr DCARTOFF
		jsr CRITICOFF
		sta WSYNC	; 4 x 6.24us
		sta WSYNC
		sta WSYNC
		sta WSYNC
		rts
;-------------------------------
; Erase Sector
		PROC ERASEDC
;----------------
		jsr CRITICON
		txa
		pha
		ldx #$00
		jsr DCARTON
		jsr ERASERT
		jsr DCARTOFF
		jsr CRITICOFF
		LDX #$C8	; 25ms
@		sta WSYNC
		sta WSYNC
		dex
		bne @-
		pla
		tax
		rts
;-------------------------------
.ENDL
;-----------------------------------------------------------------------
; DCart Procedures in bank
		ORG $B600
;-------------------------------
FLASHST lda #$AA
		sta $D502
		sta $B555	; 1st AA->5555
		lda #$55
		sta $D501
		sta $AAAA	; 2nd 55->2AAA
		rts
;-------------------------------
WRITERT	jsr FLASHST
		lda #$A0	; A0 command
		sta $D502
		sta $B555	; 3rd A0->5555
		rts
;-------------------------------
ERASERT jsr FLASHST
		lda #$80	; 80 command
		sta $D502
		sta $B555	; 3rd 80->5555
		lda #$AA
		sta $D502
		sta $B555	; 4th AA->5555
		lda #$55
		sta $D501
		sta $AAAA	; 5tg 55->2AAA
		lda #$30	; SST39SF040
		sta $D500	; sector 0
		sta $A000	; 6th 30->SA
		rts
;-----------------------------------------------------------------------
.ENDM
;-----------------------------------------------------------------------
; Cartridge Header
.MACRO DCART_HEADER
;-------------------------------
; BACKCART ROUTINE
		ORG $BFF3
BCKFUNB	sta $D500	; Don't touch
		jmp RESETCD
;-------------------------------
		ORG $BFF9
		dta b(=*)	; Bank number
;-------------------------------
; CARTRIDGE HEADER
		ORG $BFFA
		dta <BCKFUNB, >BCKFUNB, $00, $04, <BCKFUNB, >BCKFUNB
;-------------------------------
.ENDM
;=======================================================================
; DCart BANK 0
; Initial Procedures
;-----------------------------------------------------------------------
		OPT b-h-f+l+
		ORG $A000
		RMB
.PAGES $20
;-----------------------------------------------------------------------
; WRITABLE SPACE 
WRBUFAD	:+256 dta $00
;-----------------------------------------------------------------------
; Copy MAIN to RAM
		ORG $B000
BEGIN	lda #>RESETCD
		pha
		lda #<RESETCD-1
		pha
		ldx #(ENDMAIN-STRMAIN-1)
@		lda STRMAIN,X
		sta MAIN,x
		dex
		bpl @-
		jmp MAIN
;-----------------------------------------------------------------------
; Example MAIN program
; always run from RAM
STRMAIN
.LOCAL MAINDTA,MAIN
;----------------
		jsr DCARTOFF
		
		; stop for debug
		sec
@		bcs @-

		; read $F0 byte
		ldx #$F0
		jsr READDC
		
		; erase sector
		jsr ERASEDC

		; read $F0 byte
		ldx #$F0
		jsr READDC
		
		; write 55 to $F0 byte
		lda #$55
		ldx #$F0
		jsr WRITEDC

		; read $F0 byte
		ldx #$F0
		jsr READDC

		jsr WAITFSL
		jsr WAITFSF

		jmp RTSDCRT
;----------------
.ENDL
ENDMAIN
;-----------------------------------------------------------------------				
		DCART_PROCEDURES
;-----------------------------------------------------------------------		
; INITCART ROUTINE
		ORG $BFD0
INIT	lda CONSOL
		and #$02
		bne CONTIN
		ldx #(CONTIN-STANDR-1)
@		lda STANDR,X
		sta STCKPRC,x
		dex
		bpl @-
		jmp STCKPRC
STANDR  sta $D5FF
		jmp RESETCD
CONTIN	sta $D500
		rts
;-----------------------------------------------------------------------		
		ORG $BFF3
		sta $D500	; Don't touch
		jmp RESETCD
;-----------------------------------------------------------------------
		ORG $BFF9
		dta $00		; Bank number 0
;-----------------------------------------------------------------------
; CARTRIDGE HEADER
		ORG $BFFA
		dta <BEGIN, >BEGIN, $00, $04, <INIT, >INIT
;-----------------------------------------------------------------------
.ENDPG
;=======================================================================
; DCart BANK 1
; Write Procedures
;-----------------------------------------------------------------------
		OPT f-
		ORG $A000
		OPT f+
		NMB
.PAGES $20
;-----------------------------------------------------------------------
; EMPTY
		dta $FF
;-----------------------------------------------------------------------				
		; ...
		; empty
		; ...
		DCART_PROCEDURES
		; ...
		; empty
		; ...
		DCART_HEADER
;-----------------------------------------------------------------------
.ENDPG
;=======================================================================
; DCart BANK 2
; Custom Bank
;-----------------------------------------------------------------------
		OPT f-
		ORG $A000
		OPT f+
		NMB
.PAGES $20
;-----------------------------------------------------------------------		
; EMPTY
		dta $FF
;-----------------------------------------------------------------------		
		; ...
		; empty
		; ...
		DCART_PROCEDURES
		; ...
		; empty
		; ...
		DCART_HEADER
;-----------------------------------------------------------------------
.ENDPG
;=======================================================================
; DCart BANK X
; Custom Bank
;-----------------------------------------------------------------------
		OPT f-
		ORG $A000
		OPT f+
		NMB
.PAGES $20
;-----------------------------------------------------------------------		
; EMPTY
		dta $FF
;-----------------------------------------------------------------------
		; ...
		; empty
		; ...
		DCART_HEADER
;-----------------------------------------------------------------------
.ENDPG
;=======================================================================
; DCart BANK Y
; Custom Bank
;-----------------------------------------------------------------------
		OPT f-
		ORG $A000
		OPT f+
		NMB
.PAGES $20
;-----------------------------------------------------------------------		
; EMPTY
		dta $FF
;-----------------------------------------------------------------------
		; ...
		; full empty
		; ...
;-----------------------------------------------------------------------
.ENDPG
;=======================================================================
