	    .MODEL large
	    .8086

	    NOR_ATT EQU 00000111b
	    LIT_ATT EQU 00011111b

	    .CODE _PART
	    ORG 	600h
	    ASSUME	DS:_PART, ES:_PART

begin:

part_strt:				; Setup stack and data segment.
	    cli
	    xor		ax, ax
	    ;	push cs
	    ;	pop  ax
	    mov		ss, ax
	    mov		sp, 7c00h
	    mov 	si, sp
	    ;	mov di,sp
	    push	ax
	    pop 	es
	    push	ax
	    pop		ds
	    sti

	    cld				; Move program to 0h:07c00h.
	    mov 	di, 0600h
	    ;	mov si,0600h
	    mov		cx, 0100h
	    rep movsw
	    db		0eah		; jmp far 0000h:red_swh
	    dw		OFFSET red_swh
	    dw		0000h
	    ;	dw SEG red_swh

red_swh:				; Load program to 0h:0800h
	    mov		di, 5
	    mov		cx, 0002h
	    mov		dx, 0080h
swh_1:	    mov		bx, 0800h
	    mov		al, endsec
	    dec		al
	    mov		ah, 02h
	    push	di
	    int 	13h
	    ;	nop
	    ;	nop
	    pop		di
	    jnb		swh_3		; Goto swh_3 if program loaded
	    xor		ax, ax		; correctly.
	    int 	13h
	    ;	nop
	    ;	nop
	    dec		di
	    jnz		swh_1

					; Show error message and shut down.
	    mov		di, OFFSET errradstr
	    mov		cx, OFFSET waitsec - OFFSET errradstr
typ_dta:    mov		ah, 0eh
	    xor		bl, bl
swh_2:	    mov		al, [di]
	    int 	10h
	    inc		di
	    loop	swh_2
dead_lop:   jmp		dead_lop
	    ;	int 3
	    ;	nop

swh_3:					; Chack if program correct, show
	    mov 	ax, chklab	; error message and shut down if
	    cmp 	ax, 55aah	; incorrect.
	    je		swh_wrk
	    mov 	di, OFFSET errprgstr
	    mov 	cx, OFFSET errradstr - OFFSET errprgstr
	    jmp 	typ_dta

swh_wrk:				; Show copyright and system list
	    mov 	ah, 0eh 	; string.
	    xor 	bl, bl
	    mov 	di, OFFSET titlstr
	    mov 	cx, OFFSET chnumstr - OFFSET titlstr
swh_4:	    mov 	al, [di]
	    int 	10h
	    inc 	di
	    loop	swh_4
					; Set total number of choices.
	    mov 	bx, OFFSET nxtdta
	    xor 	ch, ch
	    mov 	cl, totcho

swh_4_1:    push	cx
	    push	bx

	    mov 	ax, 0e20h	; Type ten space.
	    xor 	bl, bl
	    mov 	cx, 000ah
swh_5:	    int 	10h
	    loop	swh_5

	    pop 	bx
	    push	bx

	    mov 	cl, [bx + 4]	; Show OS name strings.
	    add 	bx, 0005h
	    mov 	di, bx
	    xor 	bl, bl
swh_6:	    mov 	al, [di]
	    int 	10h
	    inc 	di
	    loop	swh_6
	    call	typEnter

	    pop 	bx		; Get next offset and loop.
	    mov 	ax, [bx]
	    mov 	bx, ax
	    pop 	cx
	    loop	swh_4_1

	    call	typEnter	; Type two return keys.
	    int 	10h

	    mov 	ah, 0fh 	; Set and startup I/O variables
	    int 	10h		; include screen page, base rol,
	    mov 	scrpag, bh	; now choice and now rol.
	    mov 	ah, 03h
	    int 	10h
	    sub 	dh, totcho
	    sub 	dh, 03h
	    mov 	basrol, dh
	    mov 	al, defcho
	    mov 	nowcho, al
	    add 	al, dh
	    mov 	nowrol, al

	    call	stroshw 	; Show default choice in light.

	    mov 	al, basrol	; Show ask choice string.
	    add 	al, totcho
	    add 	al, 2h
	    mov 	dh, al
	    mov 	ax, 1301h
	    mov 	bh, scrpag
	    mov 	bl, NOR_ATT
	    mov 	cx, OFFSET tmrmnstr - OFFSET chnumstr
	    mov 	dl, 8h
	    mov 	bp, OFFSET chnumstr
	    int 	10h

	    mov 	al, defcho	; Show default choice number.
	    call	bin2unpBCD
	    mov 	ah, 0eh
	    xor 	bl, bl
	    mov 	al, ch
	    or		al, al
	    jnz 	shwdefcho
	    mov 	al, -10h
shwdefcho:  add 	al, 30h
	    int 	10h
	    mov 	al, cl
	    add 	al, 30h
	    int 	10h

	    mov 	al, waitsec	; Chack if time remaining is
	    or		al, al		; enabled.
	    jz		gtkey

	    mov 	al, basrol	; Show time remaining string.
	    add 	al, totcho
	    add 	al, 2h
	    mov 	dh, al
	    mov 	ax, 1301h
	    mov 	bh, scrpag
	    mov 	bl, NOR_ATT
	    mov 	cx, OFFSET askpasstr - OFFSET tmrmnstr
	    mov 	dl, 21h
	    mov 	bp, OFFSET tmrmnstr
	    int 	10h

	    mov 	al, waitsec	; Show time remaining.
	    call	bin2unpBCD
	    mov 	al, ch
	    mov 	ah, 0eh
	    xor 	bl, bl
	    add 	al, 30h
	    int 	10h
	    mov 	al, cl
	    add 	al, 30h
	    int 	10h

	    jmp 	sec_2

	    db		0fh dup(00h)

errprgstr   db		0dh, 0ah, "Incorrect MtSys program."
	    db		0dh, 0ah, "System halted!", 0dh, 0ah, 07h

errradstr   db		0dh, 0ah, "Error loading MtSys program."
	    db		0dh, 0ah, "System halted!", 0dh, 0ah, 07h

waitsec     db		0ah
endsec	    db		0bh
botstrt     db		6h
totcho	    db		6h
lstcho	    db		1h
defcho	    db		1h
partabl     db		40h dup(?)
	    dw		0aa55h

;--From here is the second sector.--------->8--

chklab	    dw		55aah
waitsec2    db		0ah
endsec2	    db		07h
botstrt2    db		05h
totcho2	    db		03h
scrpag	    db		00h
basrol	    db		00h
nowcho	    db		00h
nowrol	    db		00h
nxtcho	    db		00h
nxtrol	    db		00h
endtim	    dw		00h
nowtimr	    db		00h

titlstr	    db		0dh, 0ah, "  MtSys for multi-system swich of PC-AT."
	    db		"   Version 0.7 (C)Copyright 1997.", 0dh, 0ah
	    db		0dh, 0ah, "        System list of the hard disk:"
	    db		0dh, 0ah, 0ah

chnumstr    db		"Enter a choice: "
tmrmnstr    db		"Time remaining: "
askpasstr   db		"Enter the pass word: "
wrngpasstr  db		"Wrong pass word! Choice another system!"
lodsysstr   db		"Loading system...", 0dh, 0ah
parunwrit   db		0dh, 0ah, 0ah, "Can't write back to partition table!"
	    db		0dh, 0ah, "System halted!", 0dh, 0ah, 07h
sysunbot    db		"Can't boot up this system!", 0dh, 0ah
	    db		"Press a key to reboot..."
spacestr    db		"                                         "

sec_2:
	    call	gettim		; Get the time counter number.
	    mov 	bx, ax

	    mov 	al, waitsec	; Compute the end time.
	    mov 	nowtimr, al
	    mov 	ah, 0b6h
	    mul 	ah
	    mov 	cx, 000ah
	    xor 	dx, dx
	    div 	cx
	    add 	ax, bx
	    and 	ax, 3fffh
	    mov 	endtim, ax

sec2_1: 				; If a key in goto delete time
	    mov 	ah, 01h 	; remaining string.
	    int 	16h
	    jnz		deltim

	    call	gettim		; Compute the time remaining
	    mov 	bx, ax		; number. If time up goto choosed.
	    mov 	ax, endtim
	    sub 	ax, bx
	    ja		sec2_2
	    je		choosed
	    add 	ax, 3fffh
	    cmp 	ax, 0400h
	    ja		choosed

sec2_2: 				; If time remaining number is
	    mov 	bx, ax		; changed, reshow it.
	    mov 	cx, 000ah
	    mul 	cx
	    mov 	cx, 00b6h
	    div 	cx

	    cmp 	al, nowtimr
	    jz		sec2_1		; Rescan key if second not changed.
	    mov 	nowtimr, al

	    mov 	al, basrol	; Move cursor.
	    add 	al, totcho
	    add 	al, 2h
	    mov 	dh, al
	    mov 	ah, 02h
	    mov 	dl, 31h
	    mov 	bh, scrpag
	    int 	10h

	    mov 	al, nowtimr	; Show time remaining.
	    call	bin2unpBCD
	    mov 	al, ch
	    mov 	ah, 0eh
	    xor 	bl, bl
	    add 	al, 30h
	    int 	10h
	    mov 	al, cl
	    add 	al, 30h
	    int 	10h

	    jmp 	sec2_1		; Rescan key.

deltim: 				; Delete time remaining string.
	    mov 	al, basrol
	    add 	al, totcho
	    add 	al, 2h
	    mov 	dh, al
	    mov 	ax, 1301h
	    mov 	bh, scrpag
	    mov 	bl, NOR_ATT
	    mov 	cx, OFFSET askpasstr - OFFSET tmrmnstr + 2
	    mov 	dl, 21h
	    mov 	bp, OFFSET spacestr
	    int 	10h

	    mov 	al, basrol	; Move cursor to the end of choose
	    add 	al, totcho	; number.
	    add 	al, 02h
	    mov 	dh, al
	    mov 	ah, 02h
	    mov 	dl, 1ah
	    mov 	bh, scrpag
	    int 	10h


gtkey:					; Get key and chack what it is.
	    xor 	ah, ah
	    int 	16h
	    or		al, al
	    jz		kyscncod	; Chack scan code if not ascii key.
	    cmp 	al, 0dh
	    je		lokpas		; Enter (Return) key.
	    cmp 	al, 31h
	    jb		gtkey
	    mov 	bl, totcho
	    add 	bl, 30h
	    cmp 	al, bl
	    ja		gtkey
	    sub 	al, 30h
	    mov 	nxtcho, al
	    add 	al, basrol
	    mov 	nxtrol, al
	    jmp 	chgcho		; Number keys, change choose.

kyscncod:
	    cmp 	ah, 48h
	    je		keyup		; Up arrow key.
	    cmp 	ah, 50h
	    jne 	gtkey		; Rescan key if not down arrow key.

	    mov 	al, nowcho	; Change to next choice if not at
	    cmp 	al, totcho	; the last one.
	    je		gtkey
	    inc 	al
	    mov 	nxtcho, al
	    mov 	al, nowrol
	    inc 	al
	    mov 	nxtrol, al
	    jmp 	chgcho

keyup:	    mov 	al, nowcho	; Change to previous choice if not
	    cmp 	al, 01h 	; at the first one.
	    je		gtkey
	    dec 	al
	    mov 	nxtcho, al
	    mov 	al, nowrol
	    dec 	al
	    mov 	nxtrol, al

chgcho: 				; Keep now rol and now choose, show
	    mov 	ah, nowrol	; next choice string in light
	    push	ax		; character attribute.
	    mov 	al, nowcho
	    xor 	ah, ah
	    push	ax
	    mov 	al, nxtcho
	    mov 	nowcho, al
	    mov 	al, nxtrol
	    mov 	nowrol, al
	    call	stroshw

	    pop 	cx		; Get offset of now choice data.
	    mov 	bx, OFFSET nxtdta
	    jmp 	norshw_2
norshw_1:   mov		ax, [bx]
	    mov 	bx, ax
norshw_2:   loop	norshw_1
	    mov 	cl, [bx + 4]	; Get string length in CX and
	    add 	bx, 0005h	; string offset in BP.
	    mov 	bp, bx

	    mov 	ax, 1300h ;1301h; Show now choice string in
	    mov 	bh, scrpag	; normal character attribute.
	    mov 	bl, NOR_ATT
	    pop 	dx
	    mov 	dl, 0ah
	    int 	10h

	    mov 	al, basrol	; Move cursor to the end of choose
	    add 	al, totcho	; string.
	    add 	al, 02h
	    mov 	dh, al
	    mov 	ah, 02h
	    mov 	dl, 18h
	    mov 	bh, scrpag
	    int 	10h

	    mov 	al, nowcho	; Show choice number.
	    call	bin2unpBCD
	    mov 	ah, 0eh
	    xor 	bl, bl
	    mov 	al, ch
	    or		al, al
	    jnz 	shwchonm
	    mov 	al, -10h
shwchonm:   add 	al, 30h
	    int 	10h
	    mov 	al, cl
	    add 	al, 30h
	    int 	10h
	    jmp 	gtkey

lokpas: 				; Chack if the choosed system need
	    call	offnowcho	; a password.
	    mov 	bx, [bx + 2]
	    or		bx, bx
	    jz		choosed 	; No password, system choosed.

	    mov 	al, basrol	; Show ask pass string.
	    add 	al, totcho
	    add 	al, 03h
	    mov 	dh, al
	    mov 	ax, 1301h
	    mov 	bh, scrpag
	    mov 	bl, NOR_ATT
	    mov 	cx, OFFSET wrngpasstr - OFFSET askpasstr
	    mov 	dl, 08h
	    mov 	bp, OFFSET askpasstr
	    int 	10h

	    xor 	al, al		; Get keys for type in password, use
	    mov 	spacestr, al	; the memory of space string as a
passin_1:   xor 	ah, ah		; buffer.
	    int 	16h
	    or		al, al
	    jz		passin_1	; Not ascii keys.
	    cmp 	al, 0dh
	    je		chkpass 	; Enter (Return) key.
	    cmp 	al, 08h
	    je		bckspcky	; Backspace key.

	    mov 	cl, spacestr	; If password string doesn't have
	    cmp 	cl, 14h 	; 20 character, add this key in and
	    je		passin_1	; show a star.
	    inc 	cl
	    mov 	spacestr, cl
	    xor 	ch, ch
	    mov 	bx, OFFSET spacestr
	    add 	bx, cx
	    mov 	[bx], al
	    mov 	ax, 0e2ah
	    xor 	bl, bl
	    int 	10h
	    jmp 	passin_1

bckspcky:				; If password string has characters,
	    mov 	cl, spacestr	; remove the last one and remove a
	    or		cl, cl		; star on screen.
	    jz		passin_1
	    xor 	ch, ch
	    mov 	bx, OFFSET spacestr
	    add 	bx, cx
	    mov 	al, 20h
	    mov 	[bx], al
	    dec 	cl
	    mov 	spacestr, cl
	    mov 	ax, 0e08h
	    xor 	bl, bl
	    int 	10h
	    mov 	al, 20h
	    int 	10h
	    mov 	al, 08h
	    int 	10h
	    jmp 	passin_1

chkpass:				; Chack if the password correct.
	    call	offnowcho
	    mov 	bx, [bx + 2]
	    mov 	al, [bx]	; Get offset of password data.
	    mov 	cl, spacestr
	    cmp 	al, cl
	    jne 	wrngpas 	; Wrong if length are different.

	    xor 	ch, ch
	    inc 	bx
	    mov 	si, bx
	    mov 	di, OFFSET spacestr
	    inc 	di
	    repe cmpsb
	    jnz 	wrngpas 	; Wrong if any character different.

	    mov 	cl, spacestr	; Erase the buffer.
	    inc 	cl
	    xor 	ch, ch
	    mov 	di, OFFSET spacestr
	    mov 	al, 20h
	    rep stosb
	    jmp 	choosed 	; System choosed.

wrngpas:
	    mov 	cl, spacestr
	    xor 	ch, ch
	    push	cx

	    inc 	cx		; Erase the buffer.
	    mov 	di, OFFSET spacestr
	    mov 	al, 20h
	    rep stosb

	    pop 	cx		; Remove the ask pass string.
	    add 	cx, OFFSET wrngpasstr - OFFSET askpasstr
	    mov 	al, basrol
	    add 	al, totcho
	    add 	al, 03h
	    mov 	dh, al
	    mov 	ax, 1301h
	    mov 	bh, scrpag
	    mov 	bl, NOR_ATT
	    mov 	dl, 08h
	    mov 	bp, OFFSET spacestr
	    push	ax
	    push	bx		; Keep string output format data.
	    push	dx
	    int 	10h

					; Show wrong password string and
					; beep.
	    mov 	bp, OFFSET wrngpasstr
	    mov 	cx, OFFSET lodsysstr - OFFSET wrngpasstr
	    int 	10h
	    mov 	ax, 0e07h
	    xor 	bl, bl
	    int 	10h

	    mov 	ah, 02h 	; Wait 2 or 3 seconds.
	    int 	1ah
	    mov 	cx, 0002h
	    mov 	bh, dh
wait1s:     push	cx
	    mov 	ah, 02h
	    int 	1ah
	    pop 	cx
	    jb		wait1s
	    cmp 	dh, bh
	    je		wait1s
	    mov 	bh, dh
	    loop	wait1s

delwrng:				; Remove wrong password string.
	    pop 	dx
	    pop 	bx		; Restore string output format data.
	    pop 	ax
	    mov 	bp, OFFSET spacestr
	    mov 	cx, OFFSET lodsysstr - OFFSET wrngpasstr
	    int 	10h

	    mov 	al, basrol	; Move cursor to the end of choose
	    add 	al, totcho	; number.
	    add 	al, 02h
	    mov 	dh, al
	    mov 	ah, 02h
	    mov 	dl, 19h
	    mov 	bh, scrpag
	    int 	10h
	    jmp 	gtkey		; Rescan key.

choosed:
	    mov 	al, nowcho	; If the choice the same with last
	    cmp 	al, lstcho	; time, dont change partition table.
	    je		chksystm
	    mov 	lstcho, al	; Change last choice.
	    call	offnowcho
	    mov 	ax, [bx + 2]
	    or		ax, ax
	    jnz 	mvpartabl
	    mov 	al, nowcho	; IF no password, change default
	    mov 	defcho, al	; choice.

mvpartabl:				; Move partition teble of now choice
	    mov 	al, nowcho	; to boot sector of MtSys.
	    add 	al, botstrt
	    mov 	ah, 02h
	    mul 	ah
	    xchg	ah, al
	    add 	ax, 03beh
	    mov 	si, ax
	    mov 	di, 07beh
	    mov 	cx, 0020h
	    cld
	    rep movsw

	    mov		di, 5		; Write partition table back.
	    mov		cx, 0001h
	    mov		dx, 0080h
writ:	    mov		bx, 0600h
	    mov		ax, 0301h
	    push	di
	    int 	13h
	    ;	nop
	    ;	nop
	    pop		di
	    jnb 	chksystm
	    xor		ax, ax
	    int 	13h
	    ;	nop
	    ;	nop
	    dec		di
	    jnz 	writ

					; Show error in writing string and
					; shut down.
	    call	scroll2
	    mov 	di, OFFSET parunwrit
	    mov 	cx, OFFSET sysunbot - OFFSET parunwrit
	    jmp 	typ_dta

chksystm:				; Chack if choosed system can be
	    mov 	al, nowcho	; boot up.
	    add 	al, botstrt
	    mov 	ah, 02h
	    mul 	ah
	    xchg	ah, al
	    add 	ax, 0200h
	    mov 	bx, ax
	    mov 	ax, [bx + 01feh]
	    cmp 	ax, 0aa55h
	    je		mvbotprg	; System can be boot up, start it.

	    call	scroll2 	; Show system can't boot string.
	    mov		di, OFFSET sysunbot
	    mov		cx, OFFSET spacestr - OFFSET sysunbot
	    mov 	ah, 0eh
	    xor		bl, bl
chksys_1:   mov 	al, [di]
	    int 	10h
	    inc		di
	    loop	chksys_1

	    xor 	ah, ah		; Wait a key and then reboot.
	    int 	16h
	    int 	19h
	    ;	int 3
	    ;	nop

mvbotprg:
	    call	scroll2 	; Show loading system string.
	    mov		di, OFFSET lodsysstr
	    mov		cx, OFFSET parunwrit - OFFSET lodsysstr
	    mov 	ah, 0eh
	    xor		bl, bl
movbot_1:   mov 	al, [di]
	    int 	10h
	    inc		di
	    loop	movbot_1

	    mov 	al, nowcho	; Move choosed boot program to
	    add 	al, botstrt	; 0h:07c00h.
	    mov 	ah, 02h
	    mul 	ah
	    xchg	ah, al
	    add 	ax, 0200h
	    cld
	    mov 	si, ax
	    mov		di, 7c00h
	    mov		cx, 0100h
	    rep movsw

	    db		0eah		; jmp far 0000h:7c00h
	    dw		7c00h
	    dw		0000h
	    ;	mov ah,4ch
	    ;	int 21h
	    ;	nop

;****************************

stroshw:
	    call	offnowcho	; Get offset of now choice data.

	    mov 	cl, [bx + 4]	; Get string length in CX and
	    add 	bx, 0005h	; string offset in BP.
	    mov 	bp, bx

	    mov 	ax, 1300h	; Show now choice string in
	    mov 	bh, scrpag	; strong character attribute.
	    mov 	bl, LIT_ATT
	    mov 	dh, nowrol
	    mov 	dl, 0ah
	    int 	10h
	    retn

gettim:
	    ;	xor ax, ax
	    ;	mov ds, ax
	    db		0a1h, 06ch, 04h
	    ;	push es
	    ;	pop  ds
	    and 	ax, 3fffh
	    retn

bin2unpBCD:
	    xor 	ah, ah
	    mov 	bl, 0ah
	    div 	bl
	    xchg	ah, al
	    mov 	cx, ax
	    retn

offnowcho:
	    mov 	cl, nowcho	; Get offset of now choice data.
	    xor 	ch, ch
	    mov 	bx, OFFSET nxtdta
	    jmp 	offcho_2
offcho_1:   mov		ax, [bx]
	    mov 	bx, ax
offcho_2:   loop	offcho_1
	    retn

typEnter:				; Type a Enter key.
	    mov 	ax, 0e0dh
	    xor 	bl, bl
	    int 	10h
	    mov 	al, 0ah
	    int 	10h
	    retn

scroll2:
	    mov 	al, basrol	; Move cursor to the lowest used rol.
	    add 	al, totcho
	    add 	al, 3h
	    mov 	dh, al
	    mov 	ah, 02h
	    mov 	dl, 00h
	    mov 	bh, scrpag
	    int 	10h

	    call	typEnter	; Type two Enter keys.
	    int 	10h
	    retn


nxtdta	    dw		OFFSET nxtdta2
passoff     dw		0000h
	    db		1eh, "1. MS-DOS system version 6.22."

nxtdta2     dw		OFFSET nxtdta3
	    dw		0000h
	    db		20h, "2. PC-DOS system version T6.3/V."

nxtdta3     dw		OFFSET nxtdta4
	    dw		0000h
	    db		14h, "3. Windows95 system."

nxtdta4     dw		OFFSET nxtdta5
	    dw		0000h
	    db		1ch, "4. OS/2 system version T2.1."

nxtdta5     dw		OFFSET nxtdta6
	    dw		0000h
	    db		10h, "5. LINUX system."

nxtdta6     dw		0000h
	    dw		OFFSET pasdta6
	    db		1ch, "6. Robert's personal system."
pasdta6     db		06h, "nonakp"

	    ORG 	11beh
	    db		"First partition"
	    ORG 	11fch
	    db		"Y!"
	    dw		0aa55h
	    ORG 	13beh
	    db		"Second partition"
	    ORG 	13fch
	    db		"Y!"
	    dw		0aa55h
	    ORG 	15beh
	    db		"Third partition"
	    ORG 	15fch
	    db		"Y!"
	    dw		0aa55h
	    ORG 	17beh
	    db		"Forth partition"
	    ORG 	17fch
	    db		"Y!"
	    dw		0aa55h
	    ORG 	19beh
	    db		"Fifth partition"
	    ORG 	19fch
	    db		"Y!"
	    dw		0aa55h
	    ORG 	1bbeh
	    db		"Sixth partition"
	    ORG 	1bfch
	    db		"Y!"
	    dw		0aa55h

	    END 	begin
