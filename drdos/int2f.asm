;    File              : $INT2F.ASM$
;
;    Description       :
;
;    Original Author   : 
;
;    Last Edited By    : $Author$
;
;-----------------------------------------------------------------------;
;    Copyright Work of Caldera, Inc. All Rights Reserved.
;      
;    THIS WORK IS A COPYRIGHT WORK AND CONTAINS CONFIDENTIAL,
;    PROPRIETARY AND TRADE SECRET INFORMATION OF CALDERA, INC.
;    ACCESS TO THIS WORK IS RESTRICTED TO (I) CALDERA, INC. EMPLOYEES
;    WHO HAVE A NEED TO KNOW TO PERFORM TASKS WITHIN THE SCOPE OF
;    THEIR ASSIGNMENTS AND (II) ENTITIES OTHER THAN CALDERA, INC. WHO
;    HAVE ACCEPTED THE CALDERA OPENDOS SOURCE LICENSE OR OTHER CALDERA LICENSE
;    AGREEMENTS. EXCEPT UNDER THE EXPRESS TERMS OF THE CALDERA LICENSE
;    AGREEMENT NO PART OF THIS WORK MAY BE USED, PRACTICED, PERFORMED,
;    COPIED, DISTRIBUTED, REVISED, MODIFIED, TRANSLATED, ABRIDGED,
;    CONDENSED, EXPANDED, COLLECTED, COMPILED, LINKED, RECAST,
;    TRANSFORMED OR ADAPTED WITHOUT THE PRIOR WRITTEN CONSENT OF
;    CALDERA, INC. ANY USE OR EXPLOITATION OF THIS WORK WITHOUT
;    AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND
;    CIVIL LIABILITY.
;-----------------------------------------------------------------------;
;
;    *** Current Edit History ***
;    *** End of Current Edit History ***
;
;    $Log$
;    INT2F.A86 1.23 94/11/14 10:34:17
;    Fixed the NWDOS.386 stuff. Still point at startupinfo, but take out the
;    vxdname and the vxdnameseg entries.
;    INT2F.A86 1.22 94/10/07 09:05:11
;    Added patch 005 as source fix. Removed the stuff to load NWDOS.386 as
;    the vxd is no longer needed.
;    INT2F.A86 1.21 94/03/24 18:40:10
;    Support para-aligned HMA allocations (Stacker 4 bug)    
;    INT2F.A86 1.20 93/09/28 19:43:12
;    Extra field to export upper memory root on windows startup
;    INT2F.A86 1.19 93/09/06 15:37:35
;    Startup Broadcast fills entry ES:BX into SwStartupInfo "next" link field
;    INT2F.A86 1.16 93/08/06 16:35:58
;    Change DELWATCH int 2F hook for getnblk to getblk
;    INT2F.A86 1.15 93/07/20 22:47:21
;    Pass on Int 2F/12FF to BIOS - (really to CONFIG)
;    INT2F.A86 1.11 93/06/11 02:10:01
;    GateA20 disabled on EXEC for EXEPACKED apps
;    ENDLOG
;
;   DOS INT 2F Support
;

PCMCODE	GROUP	PCM_CODE
PCMDATA	GROUP	PCMODE_DATA,FDOS_DSEG,GLOBAL_DATA

ASSUME DS:PCMDATA

	.nolist
	include	pcmode.equ
	include msdos.equ
	include	mserror.equ
	include	driver.equ
	include	psp.def
	include	doshndl.def
	include	redir.equ
	.list

PCM_CODE	segment public byte 'CODE'

	extrn	get_dseg:near		; in PCMIF.PCM
	extrn	do_int24:near		; in PCMIF.PCM
	extrn	dos_entry:near
	extrn	strlen:near		; in SUPPORT.PCM
	extrn	toupper:near		; in UTILS.FDO (in BDOS_CODE)
	extrn	ReadTOD:near		; in UTILS.FDO (in BDOS_CODE)
	extrn	share_delay:near	; in UTILS.FDO (in BDOS_CODE)


PointHMA:
;--------
; On Entry:
;	None
; On Exit:
;	DS = DOS data seg
;	BX = bytes available (0 if none)
;	ES:DI -> start of available area (FFFF:FFFF if none)
;	All other regs preserved
;
	call	get_dseg		; DS = DOS data
	mov	di,0FFFFh
	mov	es,di			; ES:DI = FFFF:FFFF
	mov	bx,hmaRoot
	test	bx,bx			; have we an HMA ?
	 jz	PointHMA10
	mov	di,bx			; ES:DI = start of HMA free area
	mov	bx,es:2[bx]		; BX = length
	sub	bx,4			; forget the header
	and	bl,not 15		; make it complete para's
PointHMA10:
	ret	

QueryHMA:
;--------
; On Entry:
;	None
; On Exit:
;	BX = bytes available (0 if none)
;	ES:DI -> start of available area (FFFF:FFFF if none)
;	All other regs preserved
;
	push	ds
	call	PointHMA		; registers ready for return
	jmp	int2F_BIOS		; give CONFIG processing a chance


AllocHMA:
;--------
; On Entry:
;	BX = bytes required
; On Exit:
;	ES:DI -> start of available area (FFFF:FFFF if none)
;
	push	ds
	xchg	ax,bx			; AX = bytes required
	add	ax,15
	and	al,not 15		; round up to para's
	call	PointHMA
	xchg	ax,bx
	cmp	ax,bx			; enough room up there ?
	 jae	AllocHMA10
	mov	di,es			; ES:DI = FFFF:FFFF
	jmp	AllocHMA20
AllocHMA10:
	add	hmaRoot,bx		; set new start
	mov	ax,es:2[di]		; get length
	sub	ax,bx			; subtract what we just allocated
	mov	es:2[di+bx],ax		; set new length
	cmp	ax,4			; have we shrunk to zero spare ?
	mov	ax,es:[di]		; move link field to
	mov	es:[di+bx],ax		;  new head
	 ja	AllocHMA20
	mov	hmaRoot,ax		; set new hmaRoot
AllocHMA20:
	mov	ax,4A02h		; "restore" AX
	pop	ds
	iret

;	++++++++++++++++++++++++++++
;	Int 2F - Multiplex Interrupt
;	++++++++++++++++++++++++++++
;
;	This interrupt is used by DBASE III Plus
;
;	On Entry:-   	AH -	Multi-Plex Number
;				01 - 	Print Spooler
;				02 -	Assign Command (Documented)
;				05 -	Critical Error Msg
;				06 -	Assign Command (By Inspection)
;				08 -	DRIVER.SYS Interface for MS-DOS 3.xx
;				10 -	Share Command
;				11 -	Internal DOS - Network Hooks
;				12 -	Internal DOS - Support Services
;				13 -	Original INT 13 ROS ISR Address (BIOS)
;				14 -	NLSFUNC utility
;				AD -	IBM CodePage Screen Driver
;				B7 -	Append Command
;				B8 -	Network Command
;
;			AL -	Function Code
;				00 - 	Get Installed State (All)
;				01 -	Submit File (PRINT)
;				02 -	Cancel File (PRINT)
;				03 -	Cancel All Files (PRINT)	 
;				04 -	Spooler Status (PRINT)
;				05 -	End of Status (PRINT)	
;
;	The Network Test returns the current Network configuration in
;	BX when the Get Installed State is requested.
;
;		BX = 0008h	Redirector	|	Increasing
;		BX = 0080h	Receiver	|	 Network
;		BX = 0004h	Messenger	|      Functionality
;		BX = 0040h	Server		V
;
	Public	int2F_entry

int2F_entry:
	sti
	cld
	cmp ah,012h
	 je i2f_12		; intercept the AH=12 subfunctions
	cmp ah,011h
	 je i2f_11		; intercept the AH=11 subfunctions
	cmp ah,010h
	 je i2f_10		; intercept the AH=10 subfunctions
	cmp ah,005h
	 je i2f_05		; intercept the AH=05 subfunctions
	cmp ax,4A01h
	 je QueryHMA		; intercept Query Free HMA Space
	cmp ax,4A02h
	 je AllocHMA		; intercept Allocate HMA space
	cmp ah,016h
	 jne int2F_exit		; intercept the AH=16 subfucntions
	jmp	WindowsHooks		; go do windows things...
int2F_exit:
	push	ds			; pass onto BIOS now
	call	get_dseg		; trying to remain ROMMABLE
int2F_BIOS:
	jmp	dword ptr ds:int2FNext	;  hence this complication


i2f_05:
;------
; CRITICAL ERROR MSG
; This is the critical error message interceptor.
; On Entry: AL = extended error code.
; On Exit:  if CY clear then ES:DI -> ASCIIZ string to be used in place
;	 of the default error message
	stc				; please use the default message
	retf	2			; IRET, but keep flags


i2f_10:
;------
; SHARE
	cmp	al,i2f_10size		; do we do this one ?
	 jae	int2F_exit		;  no, skip it
	shl	al,1			; we need a word offset
	 jz	int2F_exit		;  exit if share installation check
	cbw				; zero AH
	xchg	ax,bx			; we will index with it
	push	ds
	call	get_dseg		; get PCMode data seg
	push 	ds
	pop 	es
	call	i2f_10tbl[bx]		; execute the function
	pop	ds
	retf	2			;  and return

i2f_11:
;------
; MSNET redirector
	test	al,al			; is it installation check ?
	 jz	i2f_11_10
	mov	ax,1			; no, return ED_FUNCTION error
	stc				; indicate an error
i2f_11_10:
	retf	2			; return

i2f_12:
;------
; DOS Internal
; Support DOS internal functions here
	cmp	al,0FFh			; should we pass it on to the BIOS ?
	 je	int2F_exit		; yes, do so
	cmp	al,i2f_12size		; do we do this one ?
	 jae	i2f_12_bad		;  no, skip it
	push	bp
	xor	ah,ah
	add	ax,ax			; make sub-func a word
	mov	bp,ax			; we need offset in pointer register
	mov	ax,i2f_12tbl[bp]	; get address of service routine
	mov	bp,sp			; BP points to stack frame
	call	ax			; call the service routine
	pop	bp
i2f_12_exit:
	retf	2			; IRET, but returning flags
i2f_12_bad:
	mov	ax,-ED_FUNCTION
	stc
	retf	2


i2f_12tbl	dw	i2f_1200
		dw	i2f_1201
		dw	i2f_1202
		dw	i2f_1203
		dw	i2f_1204
		dw	i2f_1205
		dw	i2f_1206
		dw	i2f_12nyi	; Move disk buffer
		dw	i2f_1208
		dw	i2f_12nyi	; DS:DI -> Disk Buffer ??
		dw	i2f_120A
		dw	i2f_120B
		dw	i2f_120C
		dw	i2f_120D
		dw	share_delay	; delay
		dw	i2f_12nyi	; relink buffer ES:DI ([DI+5].20 <- 0) - Trout
		dw	i2f_1210
		dw	i2f_1211
		dw	i2f_1212
		dw	i2f_1213
		dw	i2f_1214
		dw	i2f_12nyi	; Disk buffer DS:SI ??? (Write - Trout)
		dw	i2f_1216
		dw	i2f_1217
		dw	i2f_1218
		dw	i2f_1219
		dw	i2f_121A
		dw	i2f_121B
		dw	i2f_121C
		dw	i2f_121D
		dw	i2f_121E
		dw	i2f_121F
		dw	i2f_1220
		dw	i2f_1221
		dw	i2f_1222
		dw	i2f_1223
		dw	share_delay
		dw	i2f_1225
		dw	i2f_1226
		dw	i2f_1227
		dw	i2f_1228
		dw	i2f_1229
		dw	i2f_122A
		dw	i2f_122B
		dw	i2f_122C
		dw	i2f_122D
i2f_12size	equ	((offset $) - (offset i2f_12tbl))/2

i2f_12nyi:
; Sets CY the falls through to installation check - so returns ax = 00FF
; Who knows what to do ?
	stc				; indicate problem ?

i2f_1200:
	mov	ax,00FFh
	ret

i2f_1201:
; Close file ??? (at current_dhndl)
	les	di,current_dhndl
	mov	bx,es:DHNDL_WATTR[di]
	test	bh,DHAT_REMOTE/100h
	 jz	i2f_1201_10		; is it networked ?
	mov	ax,I2F_CLOSE
	int	2fh			; then close using int 2f call
i2f_1201_10:				; else do nothing for now
	ret

i2f_1202:
; Get Interrupt Vector pointer
	xor	bx,bx
	mov	es,bx			; point at the vectors
	mov	bl,8[bp]		; pick up which vector
	add	bx,bx
	add	bx,bx			; make it a DWORD offset
	ret

i2f_1203:
; Get DOS Data segment
	jmp	get_dseg		; return DS = DOS data seg

i2f_1204:
; Normalise path character
	mov	ax,8[bp]		; the char is on the stack
tobslash:
	cmp	al,'/'			; if it's a fslash
	 jne	i2f_1204_10
	mov	al,'\'			;  make it a bslash
i2f_1204_10:
	cmp	al,'\'			; set ZF if bslash
	ret

i2f_1205:
; Output Character on the stack
	push	dx
	mov	ah,MS_C_WRITE
	mov	dx,8[bp]		; get char from the stack
	call	dos_entry		;  and output it
	pop	dx
	ret
	
i2f_1206:
; Invoke critical error INT 24
	push	ds
	mov	ax,8[bp]		; action/drive on stack
	mov	es,0[bp]		; seg was in BP
	call	get_dseg		; get the segment right
	call	do_int24		; invoke the critical error handler
	push	ax
    les ax,int24_esbp       
	mov	[bp],ax			; really return new BP
	pop	ax
	pop	ds
	ret

i2f_1208:
; Decrement word at ES:DI, skipping zero
	mov	ax,es:word ptr [di]	; return the word in AX
i2f_1208_10:
	dec	es:word ptr [di]	; dec it
	 jz	i2f_1208_10		;  dec again if it's zero
	ret
	
i2f_120A:
	push	ds
	lds	si,current_ddsc		; point at current driver
	lodsb				; get the drive
	cbw				; pretend dos area read
	pop	ds
	mov	err_drv,al
	mov	rwmode,ah		; set error drive for Int 24h
	mov	ax,3			; return a Fail ?
	stc				; return as error
	ret
	
i2f_120B:
; ES:DI -> system file table entry
	mov	ax,20h			; sharing violation
	stc				; return as error
	ret
	
i2f_120C:
; Open file ??? (at current_dhndl)
	les	di,current_dhndl
; would need to call the device driver, but as we don't support this for
; block devices and as it is generally not supported for remote files (but
; only known to be called from redirectors) we leave this out for later
	test	es:byte ptr DHNDL_MODE+1[di],DHM_FCB/100h
	 jz	i2f_120C_10		; is it an FCB open ?
	mov	ax,current_psp
	mov	es:DHNDL_PSP[di],ax	; update owning PSP field
i2f_120C_10:				; else do nothing for now
	ret

i2f_120D:
; Get Date/Time
	push	ds
	push	es
	push	cx
	push	bx
	push	si
	push	di
	push	ss
	pop	ds
	call	ReadTOD
	pop	di
	pop	si
	pop	bx
	pop	cx
	pop	es
	pop	ds
	ret


i2f_1210:
; Find Dirty Buffer Entry DS:SI -> 1st buffer, On exit DS:SI-> 1st dirty buffer
; ZF set if none found
	xor	ax,ax			; never find dirty buffers
	ret
	
i2f_1211:
; Normalise ASCIIZ filename DS:SI -> source buffer, ES:DI -> dest buffer
; make uppercase, fslash becomes bslash
; (Stops at slash - Trout)
	lodsb				; get a character
	call	toupper			; upper case it
	call	tobslash		; convert '/' to '\'
	stosb				; plant it
	test	al,al			; terminating zero ?
	 jnz	i2f_1211
	mov	ax,8[bp]		; AX from stack
	ret
	
i2f_1212:
; Get length of ASCIIZ string ES:DI
	push 	ds
	push 	si
	push 	es
	pop 	ds
	mov	si,di			; make DS:SI -> ASCIIZ
	call	i2f_1225		;  then use our other primitive
	pop 	si
	pop 	ds
	ret

i2f_1213:
; Upperase character on stack
	mov	ax,8[bp]		; get the character
	jmp	toupper			; use BDOS Intl routine
	
i2f_1214:
; Compare far pointers DS:SI with ES:DI
	cmp	di,si
	 jne	i2f_1214_10
	push 	ax
	push 	bx
	mov	ax,ds
	mov	bx,es
	cmp	ax,bx
	pop 	bx
	pop 	ax
i2f_1214_10:
	ret

i2f_1216:
; Get address in ES:DI of DOSHNDL for file BX
	push	ds
	call	get_dseg		; we work with the PCMODE data
	les	di,file_ptr		; get the address of the first entry
	pop	ds
	push	bx			; handle # in BX
i2f_1216_10:
	cmp	bx,es:DCNTRL_COUNT[di]	; handle in this block?
	 jb	i2f_1216_20		; skip if yes
	sub	bx,es:DCNTRL_COUNT[di]	; update the internal file number
	les	di,es:DCNTRL_DSADD[di]	; get the next entry and check
	cmp	di,0FFFFh		;   for the end of the list
	 jnz	i2f_1216_10 
	pop	ax			; handle # back in AX
	stc				; invalid file handle number
	ret

i2f_1216_20:
	push	dx			; save DX and calculate the offset
	mov	ax,DHNDL_LEN		;   of the DOS Handle
	mul	bx
	add	di,ax			; add structure offset (should be 0) 
	add	di,DCNTRL_LEN		;    and then skip the header
	pop	dx
	pop	ax			; handle # back in AX
;	clc
	ret				; valid file handle number
	
i2f_1217:
; Default Drive ???
; On Exit:
; AL = drive we have set to, DS:SI -> LDT structure
	call	get_dseg		; DS -> PCMODE data
	mov	ax,8[bp]		; get the drive
	cmp	al,last_drv		; do we have an LDT for it ?
	 jae	i2f_1217_10		; if not do no more
	cmp	word ptr ldt_ptr+2,0	; valid LDT ?
	 je	i2f_1217_10
	push	ax
	mov	ah,LDT_LEN
	mul	ah
	lds	si,ldt_ptr
	add	si,ax			; DS:SI -> requested LDT, current_LDT
	mov	ss:word ptr current_ldt,si
	mov	ss:word ptr current_ldt+2,ds
	pop	ax
	stc				; indicate NO error (CY inverted)
i2f_1217_10:
	cmc	
	ret				; CY set if invalid


i2f_1218:
; DS:SI -> User register on DOS Call
	call	get_dseg		; we save SS:SP after PUSH$DOS
	lds	si,int21regs_ptr	;  in this location
	ret

i2f_1219:
; Stack = drive (0=default, 1 = A: etc)
	push 	ds
	push 	si
	push 	word ptr 8[bp]
	dec	byte ptr 8[bp]		; make drive zero based
	cmp	byte ptr 8[bp],0ffh	; do we want the default ?
	 jne	i2f_1219_10
	call	get_dseg
	mov	al,current_dsk
	mov	byte ptr 8[bp],al	; use the default drive
i2f_1219_10:
	call	i2f_1217		; set's up current_ldt
	 jc	i2f_1219_20
	test	ds:byte ptr 44h[si],40h	; is it valid LDT ?
	 jnz	i2f_1219_20
	stc				; indicate an error
i2f_1219_20:
	pop 	word ptr 8[bp]
	pop 	si
	pop 	ds
	ret

i2f_121A:
; Get files drive DS:SI -> drives, AL = drive
	xor	ax,ax			; assume default drive
	cmp	ds:byte ptr 1[si],':'
	 jne	i2f_121A_10		; if no drive letter, then default
	mov	al,ds:byte ptr [si]
	test	al,al			; null string ?
	 jz	i2f_121A_10		;  then it's the default drive
	call	toupper
	sub	al,'A'-1		; make one based
	 jbe	i2f_121A_20		; it's invalid..
	push	ds
	call	get_dseg
	cmp	al,last_drv		; is it a valid drive ?
	pop	ds
	 ja	i2f_121A_20		; yes, return it
i2f_121A_10:
	clc
	ret
i2f_121A_20:
	mov	al,0FFh			; invalid drive
	stc
	ret

i2f_121B:
; On Entry CX = year-1980
; On Exit AL = days in February
	push	bx
	mov	bx,offset days_in_month+1
	mov	ds:byte ptr [bx],28	; assume 28 days in Feb
	test	cl,3			; is it a leap year ?
	 jnz	i2f_121B_10
	inc	ds:byte ptr [bx]	; yes, we have 29
i2f_121B_10:
	mov	yearsSince1980,cl	; save the year
	mov	al,ds:byte ptr [bx]	; return the days in Feb
	pop	bx
	ret

i2f_121C:
; Checksum Memory CX bytes at DS:SI, DX = initial checksum
; DX = final checksum
; I've seen this used to total days in N months.
; On Entry:
;	CX = current month
;	DX = total days in prior years
;	DS:SI -> days-per-month table
; On Exit:
;	DX = Total days to start of current month
;
	xor	ax,ax			; clear AX
	jcxz	i2f_121C_20		; check for zero bytes
i2f_121C_10:
	lodsb				; get a byte
	add	dx,ax			; add to the checksum
	loop	i2f_121C_10		; until we run out
i2f_121C_20:
	ret

i2f_121D:
; Calculate Date
; On Entry:
;	CX = 0
;	DX = total day count this year
;	DS:SI -> days-per-month table
; On Exit:
;	CX = Month
;	DX = Day
;
	xor	ax,ax
i2f_121D_10:
	lodsb
	inc	cx
	sub	dx,ax
	 jnb	i2f_121D_10
	dec	cx			; undo the last count
	add	dx,ax			; undo the sub
	cmp	dx,ax			; get the flags right
	ret

i2f_121E:
; Compare Filenames at DS:SI and ES:DI
	push 	si
	push 	di
	push 	cx
	call	i2f_1225		; find length of DS:SI filename
	push	cx
	call	i2f_1212		; find length of ES:DI filename
	pop	ax
	cmp	ax,cx			; if lengths not the same
	 jne	i2f_121E_20		;  don't even bother
i2f_121E_10:
	push	cx
	lodsb
	call	toupper
	call	tobslash		; normalise slash characters
	push	ax			; save it
	mov	al,es:byte ptr [di]
	inc	di
	call	toupper
	call	tobslash		; normalise slash again
	pop	cx			; recover the character
	cmp	al,cl			; are they the same?
	pop	cx
	loope	i2f_121E_10		; yes, try again if we have any left
i2f_121E_20:
	pop 	cx
	pop 	di
	pop 	si
	mov	ax,8[bp]		; return stack value in AX
	ret

i2f_121F:
; Build drive info into block
; Stack = Drive (1=A: etc)
	push 	ds
	push 	si
	push 	dx
	call	get_dseg
	les	di,current_ldt
	push	di
	mov	ax,8[bp]		; get the drive we want to do
	stosb				; plant the ASCII
	xchg	ax,dx			; save drive in DX
	mov	ax,'\:'
	stosw				; we have d:\
	xor	ax,ax
	mov	cx,LDT_FLAGS-3
	rep	stosb			; zero rest of name and flags
;	lea	di,LDT_FLAGS
	and	dl,1fh			; convert from ASCII
	dec	dx			; into zero based drive number
	cmp	dl,phys_drv		; valid physical drive ?
	 jae	i2f_121F_10		; mark it as such
	mov	ax,LFLG_PHYSICAL
i2f_121F_10:
	stosw				; set flags
;	lea	di,LDT_PDT
	lea	si,ddsc_ptr-18h
i2f_121F_20:
	lds	si,18h[si]
	cmp	si,-1
	 je	i2f_121F_30
	cmp	dl,[si]			; is this the DDSC for the drive
	 jne	i2f_121F_20		; if so save it away
i2f_121F_30:
	xchg	ax,si			; AX = DDSC offset
	stosw
	mov	ax,ds			; AX = DDSC seg
	stosw
	mov	ax,0FFFFh		; AX = FFFF
	stosw
	stosw
	stosw		; fill in block info
;	stosw ! stosw
;	lea	di,LDT_ROOTLEN
	mov	ax,2
	stosw				; set root length
;	lea	di,LDT_BLKH
	stosw
;	lea	di,LDT_ROOTH
	stosw
	pop	di
	pop 	dx
	pop 	si
	pop 	ds
	ret

i2f_1220:
; Get pointer to system file table number for handle BX into ES:DI
	push	ds
	call	get_dseg
	mov	es,current_psp
	mov	ax,6			; assume illegal
	cmp	bx,es:PSP_XFNMAX	; is it a legal handle
	cmc				; invert CY for error return
	 jc	i2f_1220_10		;  no, forget it
	les	di,es:PSP_XFTPTR	; get XFT from PSP
	add	di,bx			; add in the offset
;	clc
i2f_1220_10:
	pop	ds
	ret

i2f_1221:
	mov	ah,MS_X_EXPAND		; let the FDOS do the walking...
	call	DOS			;  and call our internal entry point
	 jnc	i2f_1221_10
	neg	ax			; get error code correct
	stc				;  before returning error
i2f_1221_10:
	ret

i2f_1222:
; Store error class, locus, action from DS:SI
i2f_1222_10:
	lodsw
	cmp	al,byte ptr error_code	; have we found the error ?
	 je	i2f_1222_20
	inc	al			; or hit the end of the list ?
	 jz	i2f_1222_20
	lodsw				; skip this one
	jmp	i2f_1222_10		; and try the next
i2f_1222_20:
	cmp	ah,0ffh			; valid error class ?
	 je	i2f_1222_30
	mov	error_class,ah
i2f_1222_30:
	lodsw
	cmp	al,0ffh
	 je	i2f_1222_40
	mov	error_action,al
i2f_1222_40:
	cmp	ah,0ffh
	 je	i2f_1222_50
	mov	error_locus,ah	
i2f_1222_50:
	ret

i2f_1223:
; On Entry buffer at 4E6 filled with Device name - eg. "NAME1   "
; Preserve word ptr [4E6]
; if byte ptr [4E6] = 5 then byte ptr [4E6] = E5
; if byte ptr [506] & 8 then exit now with STC
; otherwise work down device chain
; Find device driver for device NAME1
; Check if character device
	push	ds
	call	get_dseg
if FALSE
	push	word ptr name_buf	; save 1st char of name
	test	magic_byte,8		; magic location and number ??
	 jnz	i2f_1223_40		; can we do the check ?
	cmp	name_buf,5
	 jne	i2f_1223_10		; if 1st char is 5, make it
	mov	name_buf,0e5h		;  an E5
i2f_1223_10:
endif
	mov	si,offset nul_device	; start from NUL
i2f_1223_20:
	test	ds:DEVHDR.ATTRIB[si],DA_CHARDEV
	 jz	i2f_1223_30		; skip unless character device
	mov	cx,8
	lea	di,name_buf		; point at name we are looking for
	push	si
	lea	si,ds:DEVHDR.NAM[si]	; point a device name
	repe	cmpsb			; compare the names
	pop	si
	 jne	i2f_1223_30		; if we found it, save info
	mov	es:word ptr current_device,si
	mov	es:word ptr current_device+2,ds
	mov	bh,ds:byte ptr DEVHDR.ATTRIB[si]
	or	bh,0e0h
	xor	bh,20h			; clear this bit
	clc				; we found it
	jmp	i2f_1223_50
i2f_1223_30:
	lds	si,ds:DEVHDR.NEXT[si]
	cmp	si,0ffffh		; any more entries ?
	 jne	i2f_1223_20		; yes, do them
i2f_1223_40:
	stc
i2f_1223_50:
if FALSE
	pushf
	call	get_dseg		; we may have scambled DS
	popf
	pop	word ptr name_buf	; restore 1st character
endif
	pop	ds
	ret


i2f_1225:
; Get length of ASCIIZ string DS:SI
	call	strlen
	inc	cx			; include the terminating zero
	mov	ax,8[bp]		; restore AX from stack
	ret

; The following are NOT required for MSNET - they are used by NLSFUNC

i2f_1226:
; Open the file at DS:DX
	mov	al,cl			; open mode in CL on entry
	mov	ah,MS_X_OPEN		; open the file
DOS:
	push 	ds
	push 	es
	pop 	ds
	pop 	es
	call	dos_entry		; reverse DS/ES before for dos_entry
	push 	ds
	push 	es
	pop 	ds
	pop 	es
	ret

i2f_1227:
; Close file BX
	mov	ah,MS_X_CLOSE		; close the file
	jmp	DOS

i2f_1228:
; LSEEK on file BX
	mov	ax,[bp]			; seek mode in BP on entry
	mov	ah,MS_X_LSEEK		; do the seek
	jmp	DOS
	
i2f_1229:
; Read from file BX
	mov	ah,MS_X_READ
	jmp	DOS

i2f_122A:
; Set fastopen entry point to DS:SI
; SI = FFFF, sdont't set - just check if installed
	mov	ax,si			; AX = offset
	inc	ax			; AX = 0 if it's an installation check
	stc				; assume it is, and say not installed
	 jne	i2f_122A_10
	clc				; fail new installation
i2f_122A_10:
	ret

i2f_122B:
; IOCTL
	mov	al,[bp]			; get IOCTL minor
	mov	ah,MS_X_IOCTL
	jmp	DOS

i2f_122C:
; Get 2nd device driver header address
	push	ds
	call	get_dseg
	lds	ax,ds:dword ptr nul_device
	mov	bx,ds			; BX:AX -> 2nd device header
	pop	ds
	ret

i2f_122D:
; Get extended error code
	mov	ax,error_code
	ret


;
; Our FDOS extentions live here
;
ifdef DELWATCH
	extrn	locate_buffer:near
	extrn	flush_drive:near
	extrn	delfat:near
	extrn	allocate_cluster:near
	extrn	getblk:near
	extrn	change_fat_entry:near
	extrn	fixup_hashing:near
	
; for speed/code size we just call directly in BLACK.A86
endif

i2f_10tbl	dw	i2f_10nyi	; never gets here...
		dw	i2f_1001	; install fdos hook
ifdef DELWATCH
if FALSE
		dw	i2f_1002	; read buffer
		dw	i2f_1003	; flush buffers
		dw	i2f_1004	; free fat chain
		dw	i2f_1005	; allocate cluster
		dw	i2f_1006	; next cluster
		dw	i2f_1007	; update fat entry
		dw	i2f_1008	; fixup checksums
else
		dw	locate_buffer	; ask BLACK to find that buffer
		dw	flush_drive	; ask BLACK to flush buffers
		dw	delfat		; ask BLACK to release FAT chain
		dw	allocate_cluster; ask DEBLOCK to allocate space
		dw	getblk		; ask DEBLOCK to return next block
		dw	change_fat_entry; ask DEBLOCK to update fat entry
		dw	fixup_hashing	; ask BLACK to fixup hashing/checksums
endif
		dw	i2f_1009	; directory buffer info
endif
i2f_10size	equ	(offset $ - offset i2f_10tbl)/2

i2f_1001:
;--------
; install fdos stub
;
; On Entry:
;	DX:AX -> new fdos_stub entry address
; On Exit:
;	None
;
	call	get_dseg		; get PCMode data seg
	mov	word ptr fdos_stub,ax	; fixup our share stubs
	mov	word ptr fdos_stub+WORD,dx
i2f_10nyi:
	ret

ifdef DELWATCH
if FALSE

i2f_1002:
;--------
; read buffer
; On Entry:
;	CH = 0FFh (pre-read required)
;	CL = BF_ISFAT/BF_ISDIR/BF_ISDATA
;	AH:DX = 24 bit sector number
; On Exit:
;	ES:SI -> Buffer control block
;
	mov	al,ah
	xor	ah,ah
    jmp locate_buffer

i2f_1003:
;--------
; flush buffers
; On Entry:
;	AL = drive
;	AH = buffer type to flush (BF_ISFAT+BF_ISDIR+BF_ISDATA)
; On Exit:
;	None
;
    jmp flush_drive     

i2f_1004:
;--------
; free fat chain
; On Entry:
;	AX = 1st block to release on current drive
; On Exit:
;	None
	xor	dx,dx
    jmp delfat          

i2f_1005:
;--------
; allocate cluster
; On Entry:
;	AX = block to start search from (eg. current end of file)
;	     0000 = start of disk
; On Exit:
;	AX = 0000 if none available
;	     else allocated block (marked as End Of Chain)
;
	xor	dx,dx
	jmp	allocate_cluster	; ask DEBLOCK.A86 to allocate some space

i2f_1006:
;--------
; get next cluster
; On Entry:
;	AX = current block
; On Exit:
;	AX = next block in chain
;
	xor	dx,dx
	jmp	getblk			; ask DEBLOCK.A86 to return next block

i2f_1007:
;--------
; change fat entry
; On Entry:
;	AX = fat entry to change
;	DX = new value
; On Exit:
;	None
;
	mov	bx,dx
	xor	dx,dx
	xor	cx,cx
	jmp	change_fat_entry	; ask DEBLOCK.A86 to modify FAT entry

i2f_1008:
;--------
; update hash code for directory entry on current drive
; On Entry:
;	AX =	segment of dir buffer
;	CX =	cluster to fixup (0 = root)
;	DI =	directory entry index(clipped to cluster if subdir)
;	AX:SI->	dir entry (single entry for hashing)
; On Exit:
;	None
;
	xchg	cx,ax
	xor	dx,dx
	jmp	fixup_hashing

endif

i2f_1009:
;--------
; return dirbuf info
; On Entry:
;	None
; On Exit:
;	ES:DI -> 128 byte directory record buffer
;	ES:SI -> dir bcb structure
;		0[si] = drive (FF = invalid)
;		1[si] = low byte of record number
;		2[si] = mid byte of record number
;		3[si] =  hi byte of record number
;
	push 	cs
	pop 	es
	mov	si,offset invalid_dir_bcb
	ret

invalid_dir_bcb	db	0ffh		; drive is invalid
;		db	?,?,?		; don't bother about record number

endif	;DELWATCH


WindowsHooks:
;------------
; On Entry:
;	AH = 16h, it's a windows broadcast
;	AL = subfunction, other regs as appropriate
; On Exit:
;	Various
;
	cmp	al,07h			; 1607: Virtual device init
	 je	WindowsDOSMGR
	test	dx,1			; is it a DOSX broadcast ?
	 jnz	WindowsExit
	cmp	al,05h			; 1605: Windows enhanced mode init
	 je	WindowsStartup
	cmp	al,06h			; 1606: Windows enhanced mode exit
	 je	WindowsShutdown
WindowsExit:
	iret



WindowsStartup:
;--------------
	push	ds
	call	get_dseg		; DS -> our data
	inc	criticalSectionEnable	; enable Int 2Ah for Windows
	inc	WindowsHandleCheck

;;if 0		Put this back in, as instance data still required
;;		Removed pointer to vxd in HEADER.A86   BAP

	mov	SwStartupInfo+2,bx	; Commented out, as NWDOS.386
	mov	SwStartupInfo+4,es	; no longer needed.
	push	ds
	pop	es			; ES -> pcmode data
	mov	bx,offset SwStartupInfo
;;endif
	jmp	int2F_BIOS		; pass on to the BIOS


WindowsShutdown:
;---------------
	push	ds
	call	get_dseg		; DS -> our data
	dec	criticalSectionEnable	; enable Int 2Ah for Windows
	dec	WindowsHandleCheck
	pop	ds
	sub	dx,dx			; return success
	iret


WindowsDOSMGR:
;-------------
	cmp	bx,15h			; is it DOS manager?
	 jne	WindowsExit		; forget the others
;	cmp	cx,0
	 jcxz	WindowsCX0
	dec	cx
	 jcxz	WindowsCX1
	dec	cx
	dec 	cx
	dec 	cx
	 jcxz	WindowsCX4
	dec	cx
	 jcxz	WindowsCX5
	iret


WindowsCX0:
;----------
	push	ds
	call	get_dseg
	push	ds
	pop	es			; ES = DOS data segment
	pop	ds
	lea	bx,windowsData		; ES:BX -> secret variables
	inc	cx			; tell them we've responded
	iret

WindowsCX1:
;----------
	mov	bx,dx			; entry DX=1Fh, exit BX=1Fh
	mov	ax,0B97Ch		; AX, DX are magic values
    mov dx,0A2ABh       
;	xor	cx,cx			; CX = 0
	iret

WindowsCX4:
;----------
	xor	dx,dx
;	xor	cx,cx			; CX = 0
	iret

WindowsCX5:
;----------
;	entry:	ES:DI -> device driver
;		determine device driver size in bytes

	push	ds
	test	di,di			; not primary DEVICE= driver?
	 jnz	WindowsCX5NoDev		; can't have DMD preceeding it
	mov	ax,es			; get device segment
	dec	ax			; DMD is one paragraph lower down
	mov	ds,ax			; DS:DI -> device DMD
	inc	ax			; AX = device driver segment
	cmp	ds:byte ptr 0[di],'D'	; see if 'D'device=
	 jne	WindowsCX5NoDev		; skip if not
	cmp	ax,ds:word ptr 1[di]	; owned by the driver ?
	 jne	WindowsCX5NoDev		; skip if not

	mov	ax,10h			; bytes per paragraph
	mul	ds:word ptr 3[di]	; bytes in device driver
	pop	ds
	mov	bx,dx			; BX = high word
	xchg	ax,cx			; CX = low word
	mov	ax,0B97Ch		; AX, DX are magic values
    mov dx,0A2ABh       
	iret

WindowsCX5NoDev:
; ES:DI -> not an external device 
	pop	ds
	xor	ax,ax
	xor	dx,dx
;	xor	cx,cx			; CX = 0
	iret

PCM_CODE	ends

PCMODE_DATA	segment public word 'DATA'
	extrn	hmaRoot:word
	extrn	last_drv:byte
	extrn	phys_drv:byte
	extrn	ddsc_ptr:dword
	extrn	current_psp:word
	extrn	current_dsk:byte
	extrn	net_delay:word
	extrn	nul_device:byte
	extrn	error_code:word
	extrn	error_class:byte
	extrn	error_action:byte
	extrn	error_locus:byte
	extrn	file_ptr:dword
	extrn	ldt_ptr:dword
	extrn	current_device:dword
	extrn	current_ldt:dword
	extrn	current_dhndl:dword
	extrn	current_ddsc:dword
	extrn	yearsSince1980:byte
	extrn	days_in_month:byte
	extrn	name_buf:byte
	extrn	int21regs_ptr:dword
	extrn	int24_esbp:dword
	extrn	int2FNext:dword
	extrn	fdos_stub:dword
	extrn	SwStartupInfo:word
	extrn	err_drv:byte
	extrn	rwmode:byte

	extrn	indos_flag:byte, machine_id:byte, internal_data:byte, dmd_upper_root:word

	extrn	criticalSectionEnable:byte
	extrn	WindowsHandleCheck:byte

PCMODE_DATA	ends

GLOBAL_DATA	segment public word 'DATA'
	
windowsData	dw	5		; version number ?
		dw	$-offset windowsData	; dummy
		dw	$-offset windowsData	; dummy
		dw	offset indos_flag
		dw	offset machine_id
		dw	offset internal_data-10
		dw	offset dmd_upper_root

GLOBAL_DATA	ends

	end
