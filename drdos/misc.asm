;    File              : $MISC.ASM$
;
;    Description       :
;
;    Original Author   : DIGITAL RESEARCH
;
;    Last Edited By    : $CALDERA$
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
;    $Log$
;    MISC.A86 1.29 94/11/30 14:40:17
;    fixed error return for function 6602
;    MISC.A86 1.28 94/07/13 15:31:04 
;    Pass name to share on Int21/5D02 (close file by name)
;    MISC.A86 1.27 93/11/29 14:18:16
;    Fix bug in get extended country info if not current country
;    MISC.A86 1.25 93/11/19 17:00:14
;    If 21/38 get country info fails for current codepage, try any codepage
;    MISC.A86 1.24 93/11/16 15:57:08
;    int 21/5D06 clears CY flag 
;    MISC.A86 1.23 93/10/21 19:31:16
;    Move Int 21/5D03+5D04 support (close all files by machine/psp) into share
;    MISC.A86 1.22 93/10/18 17:41:45
;    fix for >255 open files (PNW Server)
;    MISC.A86 1.21 93/09/03 20:28:57
;    Add intl/dbcs support for int 21/6523 (query yes/no char)
;    MISC.A86 1.20 93/07/26 20:42:13
;    Seperate int21/3306 
;    MISC.A86 1.12 93/03/05 18:12:33
;    Fix DS corruption for NLSFUNC calls
;    ENDLOG
;

PCMDATA group PCMODE_DATA,FDOS_DSEG,GLOBAL_DATA,PCMODE_DSIZE,PCMODE_CODE
PCMCODE group PCM_CODE,PCM_RODATA

ASSUME DS:PCMDATA

VALID_SIG	equ	0EDC1h

	.nolist
	include	pcmode.equ
	include	msdos.equ
	include mserror.equ
	include psp.def
	include	driver.equ
	include	char.def
	include	country.def
	include	doshndl.def
	include	redir.equ
	include	fdos.equ
	include version.inc
	.list

NLSFUNC	equ	TRUE

;
GLOBAL_DATA	segment public word 'DATA'
	extrn	default_country:byte
	extrn	Ucasetbl:word
	extrn	FileUcasetbl:word
	extrn	FileCharstbl:word
	extrn	Collatingtbl:word
	extrn	DBCS_tbl:word
	extrn	NoYesChars:byte
	extrn	info1_len:abs
	extrn	info2_len:abs
	extrn	info4_len:abs
	extrn	info5_len:abs
	extrn	info6_len:abs
	extrn	info7_len:abs
	extrn	true_version:word
	extrn	dos_version:word
	extrn	country_filename:byte
GLOBAL_DATA	ends

PCMODE_CODE	segment public word 'DATA'
	extrn	xlat_xlat:word
PCMODE_CODE	ends

PCM_CODE	segment public byte 'CODE'
	extrn	dbcs_lead:near
	extrn	device_write:near	; Write to a Character Device
	extrn	device_read:near	; Read from a Character Device
	extrn	dos_entry:near
	extrn	error_exit:near
	extrn	error_ret:near
	extrn	func5F_common:near
	extrn	get_dseg:near
	extrn	valid_drive:near
	extrn	ifn2dhndl:near
	extrn	int21_func:near
	extrn	invalid_function:near
	extrn	patch_version:word
	extrn	reload_registers:near
	extrn	reload_ES:near
	extrn	return_AX_CLC:near
	extrn	return_BX:near
	extrn	return_CX:near
	extrn	return_DX:near
	extrn	toupper:near

;
;	*****************************
;	***    DOS Function 34    ***
;	***   Get The Indos Flag  ***
;	*****************************
	Public	func34
func34:
	mov	bx,offset indos_flag
;	jmp	return_DSBX_as_ESBX	; return ES:BX -> indos flag

	Public	return_DSBX_as_ESBX

return_DSBX_as_ESBX:
;-------------------
; On Entry:
;	DS:BX to be returned to caller in ES:BX
; On Exit:
;	ES/DI trashed
;
	les	di,ss:int21regs_ptr
	mov	es:reg_ES[di],ds
	mov	es:reg_BX[di],bx
	ret


;
;	*****************************
;	***    DOS Function 52    ***
;	***   Get Internal Data   ***
;	*****************************
;
;
	Public	func52
func52:
	mov	bx,offset func52_data
	jmp	return_DSBX_as_ESBX	; return ES:BX -> internal data

;
;	*****************************
;	***    DOS Function 5D    ***
;	***    Private DOS Func   ***
;	*****************************
;
;
	Public	func5D
func5D:
	cmp	al,7
	 jae	f5d_05
	mov	si,dx				; ES:SI -> callers structure
	mov	bx,es:word ptr 20[si]
	mov	ss:owning_psp,bx		; update PSP from there
	cmp	WindowsHandleCheck,26h
	 jne	f5D_05				; check if Windows is running
	mov	bx,es:word ptr 18[si]
	mov	ss:machine_id,bx		; no, update machine_id
f5D_05:
	cbw					; zero AH for valid functions
	xchg	ax,bx				; sub function in BX
	
	cmp	bx,func5D_ftl			; Assume Illegal Subfunction
	 jb	f5D_10				; check that it is a valid
	mov	bx,func5D_ftl			;  subfunction
f5D_10:
	shl	bx,1
	push	func5D_ft[bx]			; save function address
	shr	bx,1
	xchg	ax,bx				; restore BX
	ret					; go to function
	
f5D_msnet:
	mov	ax,I2F_REDIR_5D			; magic number to redirect
	jmp	func5F_common			;  calls to extentions
;
;
;	The registers for some of the following sub-functions are passed
;	in the following structure.
;
RDC_AX		equ	es:word ptr 00[di]	; User AX
RDC_BX		equ	es:word ptr 02[di]	; User BX
RDC_CX		equ	es:word ptr 04[di]	; User CX
RDC_DX		equ	es:word ptr 06[di]	; User DX
RDC_SI		equ	es:word ptr 08[di]	; User SI
RDC_DI		equ	es:word ptr 10[di]	; User DI
RDC_DS		equ	es:word ptr 12[di]	; User DS
RDC_ES		equ	es:word ptr 14[di]	; User ES
RDC_RES		equ	es:word ptr 16[di]	; Remote Machine ID (High Word)
RDC_UID		equ	es:word ptr 18[di]	; Remote Machine ID (Low Word)
RDC_PID		equ	es:word ptr 20[di]	; Process ID
;
;	*****************************
;	***   DOS Function 5D00   ***
;	***   Remote DOS Call     ***
;	*****************************
;
;
f5D00:
	mov	remote_call,0ffh	; set remote op flag
	push	es
	les	di,int21regs_ptr	; stack image the copy registers
	pop	ds
	mov	cx,6
	rep	movsw			; Copy AX, BX, CX, DX, SI, DI
	inc 	di
	inc 	di			; Skip BP in the destination
	movsw
	movsw				; finally copy DS and ES
	push 	ss
	pop 	ds			; DS -> PCMDSEG
	call	reload_registers	; load up the new registers
	jmp	int21_func		;  then execute that function

;	*****************************
;	***   DOS Function 5D01   ***
;	***    Commit all files   ***
;	*****************************
;
f5D01:
;-----
; We are being asked to commit all files to disk
; By pretending to be FCB's we force use of IFN's, and we commit all possible
; files in the range 0-255, ignoring errors from unopened handles.
;
	mov	remote_call,DHM_FCB	; pretend to be FCB, forces use of IFN
	xor	bx,bx			; start with handle zero
f5D01_10:
	mov	ah,MS_X_COMMIT
	call	dos_entry		; commit this file
	inc	bx			; onto next candidate
	cmp	bx,0FFh			; runout yet ?
	 jb	f5D01_10		;
	ret


;	*****************************
;	***   DOS Function 5D02   ***
;	***   Close file by name  ***
;	*****************************
;
f5D02:
;-----
; Close file by name. We do a search first to find out about the file.
; As long as it's local we call share with the directory cluster/index
; to close it if it's open.
;
	mov	di,dx			; ES:DI -> register block
	mov	dx,RDC_DX
	mov	es,RDC_DS		; ES:DX -> filename to close
	push	dma_offset
	push	dma_segment
	mov	dma_offset,offset fcb_search_buf
	mov	dma_segment,ds
	mov	cx,DA_RO+DA_SYSTEM+DA_HIDDEN
	mov	ah,MS_X_FIRST		; look for this file
	call	dos_entry		;  to get dir entry info
	pop	dma_segment
	pop	dma_offset
	 jc	f5Dret
	mov	al,fcb_search_buf	; get drive #
	test	al,al			; reject networked drives
	 js	f5Dret
	dec	ax			; make drive zero based
	mov	cx,word ptr fcb_search_buf+0Dh
					; CX = directory count
	mov	dx,word ptr fcb_search_buf+0Eh
					; DX = parent directory cluster
	lea	bx,fcb_search_buf+1	; DS:BX -> name
	mov	di,S_CLOSE_IF_OPEN
;	jmp	f5D_common
f5D_common:	
	call	dword ptr lock_tables	; protect SHARE with a critical section
	call	dword ptr share_stub[di]
	call	dword ptr unlock_tables	; safe again
f5Dret:
	ret

;	*****************************
;	***   DOS Function 5D03   ***
;	*** Close files by machine***
;	*****************************
;
;	*****************************
;	***   DOS Function 5D04   ***
;	*** Close by Machine/PSP  ***
;	*****************************
f5D03:
f5D04:
;-----
; Close all files for given PSP
;
	mov	di,S_CLOSE_FILES
	jmp	f5D_common


;	*****************************
;	***   DOS Function 5D05   ***
;	*****************************
;
f5D05:
; On Entry:
;	RDC.BX = Share File # to look to
;	RDC.CX = Share Record # to look for
; On Exit:
;	AX = DOSHNDL Attribute Word
;	BX = machine ID
;	CX = locked blocks count
;	ES:DI -> buffer containing full pathname
;
;
	call	dword ptr lock_tables	; protect SHARE with a critical section
	call	dword ptr share_stub+S_GET_LIST_ENTRY
	call	dword ptr unlock_tables	; safe again
	 jnc	f5Dret			; just return if it went OK
	jmp	error_ret		;  else return error code in AX


;	*****************************
;	***   DOS Function 5D06   ***
;	***   Get Internal Data   ***
;	*****************************
;
f5D06:
	mov	cx,offset swap_indos		; Calculate Size of Swap
	sub	cx,offset internal_data		; Swap INDOS Array
	call	return_CX			; CX = Swap Indos length
	mov	dx,offset swap_always		; Calculate Size of Swap
	sub	dx,offset internal_data		; Swap ALWAYS Array
	call	return_DX			; DX = Swap Always length
	mov	si,offset internal_data
	call	return_DSSI
	mov	ax,5D06h
	jmp	return_AX_CLC


;
;	*****************************
;	***   DOS Function 5D0A   ***
;	***Set Extended Error Info***
;	*****************************
;
f5D0A:
	mov	si,dx			; ES:SI -> parameter block
	lods	es:word ptr [si]
	mov	error_code,ax		; copy the appropriate fields
	lods	es:word ptr [si]
	mov	error_class,ah
	mov	error_action,al
	lods	es:word ptr [si]
	mov	error_locus,ah
	add	si,2*WORD		; skip to device
	lods	es:word ptr [si]
	mov	error_dev,ax
	lods	es:word ptr [si]
	mov	error_dev+2,ax
	xor	ax,ax			; return AL=0
	ret
;
;	*****************************
;	*** Get switch character  ***
;	*****************************
;
;
	Public	func37
func37:
	cmp 	al,1
	 jb 	f37_getswitch		; Get the current Switch Character
	 je 	f37_setswitch		; Set the Switch Character
	cmp 	al,3
	 je 	f37_s03			; Sub-Func 03 Return Unchanged
	mov 	dl,0ffh
	 jb 	f37_return_DX		; Sub-Func 02 Return DL == 0FFh
	mov	al,0FFh			; else invalid sub-function
f37_s03:
	ret

f37_getswitch:
	mov	dl,switch_char
f37_return_DX:
	jmp	return_DX		; return current setting in DX

f37_setswitch:
	mov	switch_char,dl
	ret

;**************************************************
;**************************************************
;***						***
;***	  Miscellaneous Isolated Functions	***
;***						***
;**************************************************
;**************************************************
;
;	*****************************
;	***    DOS Function 30    ***
;	***   Get Version Number  ***
;	*****************************

	Public	func30
func30:
	mov	cl,al			; save value of AL
	mov	es,current_psp		; version is kept in the PSP
	mov	ax,es:PSP_VERSION
ReturnVersionNumber:
	xor	bx,bx			; zero BX
	cmp	cl,1			; version flag requested?
	 je	f30_10			; yes, then return 0
;	cmp	ax,dos_version		; has the version number been faked?
;	 je	f30_10			; yes, then report OEM code 0 (PC DOS)
	mov	bh,0eeh			; OEM = EEh (DR DOS)
f30_10:
	xor	cx,cx			; zero CX
	call	return_BX
	call	return_CX
	jmp	return_AX_CLC

;
;	*****************************
;	***    DOS Function 33    ***
;	***  Get/Set Cntl-Break   ***
;	*****************************
	Public	func33

; WARNING - called on USER stack

func33:
	cmp	al, 0FFh		; is it function 33FFh ?
	 jne	f33_XX			; no, jump -->
	call	f33_FF			; yes
	db	KERNEL_VER_STR
	db	0

f33_FF:	pop	reg_AX[bp]		; dx:ax - hidden DOS string
	mov	reg_DX[bp], cs
	ret

f33_XX:
	cmp	al,2			; range check subfunction
	 jbe	f33_10
	mov	dl,bootDrv		; assume we want boot drive
	cmp	al,5			; did we ?
	 je	f33_30
	cmp	al,6			; get true version ?
	 je	f33_60
	cmp	al,0fch			; set DOS version?
	 je	f33_fc
	mov	reg_AL[bp],0FFh		; return AL = FF
	ret				; Illegal function request
f33_10:
	and	dl,01h			; force a valid value
	cmp	al,1			; check for get or set
	 jae	f33_20
	mov	dl,break_flag		; it's a get, so use existing setting
f33_20:
	xchg	dl,break_flag		; replace current setting
	 je	f33_40
f33_30:
	mov	reg_DL[bp],dl		; return setting in DL
f33_40:
	ret

f33_60:
	mov	es,current_psp
	mov	ax,es:PSP_VERSION	; reported version for current program
	cmp	ax,dos_version		; has this been faked with SETVER?
	mov	reg_BX[bp],ax
	 jne	f33_61			; yes, then fake the true version, too
	mov	ax,true_version		; if not, then honestly return true version number
	mov	reg_BX[bp],ax
f33_61:
	mov	ax,patch_version
	mov	reg_DX[bp],ax		; return revision+HMA
	ret

f33_fc:
	mov	ax,reg_BX[bp]
	mov	dos_version,ax
	ret

;
;	*****************************
;	***    DOS Function 25    ***
;	***  Set Interrupt Vector ***
;	*****************************
;

; WARNING - use no stack as device drivers have called us re-entrantly

	Public	func25
func25:
	mov	bx,es			; is really dos_DS - save for later
	xor	di,di			; replace with the values in dos_DS:DX
	mov	es,di			; es -> zero segment
	xor	ah,ah			; the interrupt number
	mov	di,ax			; 0:di -> vector
	shl 	di,1
	shl 	di,1			; 4 bytes per vector

	cli
	xchg	ax,dx			; Get New Offset
	stosw				; and Save
	xchg	ax,bx			; Get New Segment
	stosw				; and Save
	sti
	xchg	ax,dx			; recover entry AL to (preserve it)
	ret

;	*****************************
;	***    DOS Function 35    ***
;	***  Get Interrupt Vector ***
;	*****************************

; WARNING - use no stack as device drivers have called us re-entrantly

	Public	func35
func35:
	xor	bx,bx
	mov	ds,bx			; DS:0 -> vector table
	mov	bl,al			; BX = the interrupt number
	shl 	bx,1
	shl 	bx,1			; 4 bytes per vector
	lds	bx,ds:dword ptr [bx]	; DS:BX -> vector
	les	di,ss:int21regs_ptr
	mov	es:reg_BX[di],bx
	mov	es:reg_ES[di],ds
	jmp	get_dseg		; restore DS for return

;PC-DOS	Verify and Break Flags Support
;
;	*****************************
;	***    DOS Function 2E    ***
;	***    Set/Reset Verify   ***
;	*****************************
	Public	func2E
func2E:
	and	al,1			; only use bottom bit
	mov	verify_flag,al		; store for use later
	ret

;	*****************************
;	***    DOS Function 54    ***
;	***  Get Verify Setting   ***
;	*****************************
	Public	func54
func54:
	mov	al,verify_flag		; return verify flag
	ret

;	*****************************
;	***    DOS Function 63    ***
;	***  Get Lead Byte Table  ***
;	*****************************
;


	Public	func63
func63:
	cmp	al, 1			; subfunction #?
	 jb	f63_get_tbl		; subfunction 0
	 je	f63_set_flg		; subfunction 1
	cmp	al, 2			; subfunction 2?
	 je	f63_get_flg		;  yes

	mov	ax, ED_FUNCTION		; invalid subfunction number
	jmp	error_exit		; so quit


f63_get_flg:
; Get the current state of the DOS interim character console flag.
; If this flag is set int 21h functions 07h, 08h, 0Bh, 0Ch are supposed
; to return "interim character information" which I assume is incomplete
; characters. (In languages like Korean a given double byte character
; may be built by the user entering several keystrokes which form
; incomplete characters.)
	mov	es, current_psp
	mov	dl, es:PSP_RIC		; Return Interim Character flag
	jmp	return_DX		; flag returned in dl


f63_set_flg:
; Set the current state of the DOS interim character console flag.
; dos_DL = 0 - clear flag, dos_DL = 1 - set flag
	mov	es, current_psp
	mov	es:PSP_RIC, dl		; record flag
	ret


f63_get_tbl:
; Get the current DBCS table address.
	mov	si,offset DBCS_tbl+2; skip the table size entry
;	jmp	return_DSSI

return_DSSI:
;-----------
; On Entry:
;	DS:SI to be returned to caller
; On Exit:
;	AX preserved
;
	les	di,ss:int21regs_ptr
	mov	es:reg_DS[di],ds
	mov	es:reg_SI[di],si
	ret

;
;	*****************************
;	***    DOS Function 29    ***
;	***     Parse String      ***
;	*****************************
	Public	func29
func29:
;
; Entry:
;    DS:SI  ->	line to parse
;    ES:DI  ->	resulting fcb
; Exit:
;    DS:SI  ->	terminating delimeter past parsed filename
;    ES:DI  ->	filled in fcb (Affects 16 bytes:  DnnnnnnnnTTT0000)
;
	push	ds
	push	es
	call	reload_ES
	pop	ds
	call	parse
	call	return_DSSI		; return result of parse
	pop	ds
	mov	al,dh			; return result in AL
	ret

;-----
parse:	; parse DOS filename delimited by TAB,SPACE,or .,+:;=|"/\[]<> or ctrl
;-----
; Entry:
;    DS:SI  ->	line to parse
;    ES:DI  ->	fcb to parse into
;	AL  ==	bit options:
;		Bit 0 == 1:  scan off leading delimiters
;		Bit 1 == 1:  change drive only if specified
;		Bit 2 == 1:  change name   "	"     "
;		Bit 3 == 1:  change type   "	"     "
; Exit:
;    DS:SI  ->	terminating delimeter past parsed filename
;    ES:DI  ->	filled in fcb (Affects 16 bytes:  DnnnnnnnnTTT0000)
;	DH  ==	1 if wild, 0FFh if the drive is invalid, 0 otherwise
;
	push	di			; (<--keep DI last on stack)

	cld				; ChSh
	xor	dx,dx			; DH = default return value (0)
	xchg	al,dl			; put flags into DL, AL = 0

	mov	cx,1
	test	dl,0010b		; should we initialize drive?
	call	nz_store_al		; do conditional store

	mov	al,' '			; use spaces for filename & typ

	mov	cl,8
	test	dl,0100b		; should we initialize the name?
	call	nz_store_al

	mov	cl,3
	test	dl,1000b		; should we initialize the typ?
	call	nz_store_al

	xor	ax,ax			; zero-out the 4 post-typ bytes
	stosw
	stosw

	pop 	di
	push 	di			; restore DI to start of FCB

deblank_loop:
	lodsb				; grab char
	cmp	al,' '			; is it a blank?
	 je	deblank_loop		;  Y: keep looping
	cmp	al,'I'-'@'		; is it a tab?
	 je	deblank_loop		;  Y: keep looping

	test	dl,0001b		; skip-delimiter-bit set?
	 jz	parse_drive		;  N: go start parsing

skip_delim_loop:
	call	check_delimiters	; check AL for delimiterness
	 jb	parse_dec_ret		; found terminator, dec SI & leave
	mov	dl,dh			; flag no-more-delimiter-skip (DL = 0)
	 je 	deblank_loop		; found separator, go deblank after it

parse_drive:
	dec	si
	cmp	byte ptr 1[si],':'	; is the drive specified?
	 jne	parse_name
	lodsw				; get drive, junk colon
	and	al,01011111b		; upper case it
	sub	al,'@'			; AL = 1-relative drive #
	push 	ax
	push 	ds			; Save the drive code and call
	call	get_dseg		; Restore our Data Segment
	call	valid_drive		; routine to validate drive ZR == OK
	pop 	ds
	pop 	ax			; Restore drive code and User DS
	 jz	parse_d10
	dec	dh			; flag drive error (0FFh)
parse_d10:
	mov	es:[di],al		; insert drive in fcb

parse_name:
	inc	di			; DI -> fname
	mov	cx,8
	call	parse_item		; parse an up-to 8 char filename
	cmp	dl,'.'			; was the delimeter a '.'?
	 jne	parse_dec_ret		;  N:  the parse is complete

	mov	cl,3
	call	parse_item		; parse an up-to 3 char filetype
parse_dec_ret:
	dec	si			; bump SI back to point to delimeter

parse_ret:
	pop	di
	ret


;-----------
nz_store_al:
;-----------
; Entry:
;	DI  ->	destination to conditionally initialize
;	CX  ==	length of destination
;	AL  ==	byte to initialize with
;	ZF set: do not initialize destination
; Exit:
;	DI  ->	past destination (initial DI+CX)
; Changed:
;	CX,DI
;
	 jnz	skip_store		; should we initialize?
	rep	stosb			;  Y: store them bytes
skip_store:
	add	di,cx			; bump DI to post-dest position
	ret


;==========
parse_item:		; Parses item into fcb if item is specified
;==========
;
; Entry:
;	SI  ->	item to parse (name or type)
;	DI  ->	fcb area to parse it into
;	CX  ==	length of item
;	DH  ==	parse_return
; Exit:
;	SI  ->	past ending delimeter
;	DI  ->	past fcb area (initial DI + CX)
;	CH  ==	If zero on enter zero on exit else 0-255
;	DH  ==	updated parse_return w/possible wild bit set
;	DL  ==	character delimiter @(SI-1)
; Changed:
;	AX,CX,DX,SI,DI
;

	mov	ah,FALSE		; specified item flag
parse_item_loop:
	lodsb				; get char
	call	check_delimiters	; is it a delimiter?
	jbe	pi_pad_ret		;  Y:  the parse is complete
	jcxz	parse_item_loop		; if the name is full, skip the char
	mov	ah,al			; flag name as present
	cmp	al,'?'			; is it a single wild char?
	je	pi_set_wild		;  Y: set wild flag
	cmp	al,'*'			; is it a multi-char wild card?
	jne	pi_store		;  N: store it
	mov	al,'?'			;  Y: fill with '?' to end of name
	rep	stosb
pi_set_wild:
	or	dh,1			; set wild flag
	jcxz	parse_item_loop		; skip store if name is now filled
pi_store:
	dec	cx			; another char done
	call	dbcs_lead		; is it the 1st byte of kanji ?
	 jne	pi_store10
	inc	si			; skip 2nd byte
	 jcxz	parse_item_loop		; can I copy both ?
	dec	cx			; yes, do so
	stosb
	dec	si			; point at second byte
	lodsb				;  so we can copy it too..
pi_store10:
	stosb				; put the char in the fcb
	jmp	parse_item_loop
pi_pad_ret:
	mov	dl,al			; DL = ending delimeter
	or	ah,ah			; the the item specified?
	 jz	pi_ret			;  N: skip padding
	mov	al,' '			;  Y: pad to end with spaces
	rep	stosb
pi_ret:
	add	di,cx			; bump DI out to end
	ret


;----------------
check_delimiters:
;----------------
;
; Entry:
;	AL  ==	char to check in list of delimiters
; Exit:
;	AL  ==	char changed to uppercase
;	CF set if it is one of the terminators:  |"/\[]<>  & ctrl chars != TAB
;	ZF set if it is one of the separators:   .,+:;=    SPACE & TAB
;	       OR one of the non-ctrl terminators
;

	cmp	al,'a'			; check for lower case
	jb	not_lower
	cmp	al,'z'
	ja	not_lower
	and	al,01011111b		; uppercase it, CF clear, ZF clear
	ret
not_lower:
	push	cx
	push 	di
	push 	es
	push	cs
	pop  	es			; ES = Code segment
	mov	di,offset parse_separators
	mov	cx,lengthof parse_separators
	repne	scasb			; is AL a separator?
	je	cpd_pop_ret		;  Y: return ZF set
	mov	cl,lengthof parse_terminators
	repne	scasb			; is AL a terminator?
	 stc				;  (set CF if true)
	je	cpd_pop_ret		;  Y: return CF & ZF set
	cmp	al,' '			; (AL == ' ') ZF set, (AL < ' ') CF set
cpd_pop_ret:
	pop	es
	pop  	di
	pop  	cx
	ret

;
;	*****************************
;	***    DOS Function 2A    ***
;	***  Get Current Date     ***
;	*****************************
	Public	func2A
func2A:
;
;	entry:	None
;
;	exit:	cx = year (1980-2099)
;		dh = month (1-12)
;		dl = day (1-31)
;		al = DOS returns day of week here
;
	call	ReadTimeAndDate		; Get the current Time and Date
	mov	cx,1980
	add	cx,yearsSince1980
;	mov	dl,dayOfMonth
;	mov	ah,month
	mov	dx,word ptr dayOfMonth
	mov	al,dayOfWeek
	jmp	f2C_10			; exit via common routine

;	*****************************
;	***    DOS Function 2C    ***
;	***  Get Current Time     ***
;	*****************************
	Public	func2C
func2C:
;
;	entry:	None
;
;	exit:	ch = hours (0-23)
;		cl = minutes (0-59)
;		dh = seconds (0-59)
;		dl = Hunredths seconds (0-99)
;		al = 0
;
	call	ReadTimeAndDate		; Get the current Time and Date
	mov	cx,biosDate+2		; Get the Hour and Minute
	mov	dx,biosDate+4		; Get the Seconds and Hundredths
	xor	ax,ax			; return AL = 0
f2C_10:
	call	return_CX		; and return to caller
	jmp	return_DX



;	*****************************
;	***    DOS Function 2B    ***
;	***  Set Current Date     ***
;	*****************************
	Public	func2B
func2B:
;
;	entry:	cx = year (1980-2099)
;		dh = month (1-12)
;		dl = day (1-31)
;
;	exit:	al = 00H success
;		   = FFH failure
;
	call	ConvertDate		; Convert to BIOS date
	 jc	f2B_20			; Abort on Error
	push	cx			; save the converted date
	call	ReadTimeAndDate		; Get the current Time and Date
	pop	biosDate		; new date, existing time
f2B_10:					; Set the current Time and Date
	call	rw_clock_common		; make sure clock is there/setup regs
	call	device_write		; Update the Date and Time
	xor	ax,ax
	ret

f2B_20:
	mov	al,0FFh			; return FAILURE
	ret

;	*****************************
;	***    DOS Function 2D    ***
;	***  Set Current Time     ***
;	*****************************
	Public	func2D
func2D:
;
;	entry:	ch = hours (0-23)
;		cl = minutes (0-59)
;		dh = seconds (0-59)
;		dl = hundredth seconds (0-99)
;
;	exit:	al = 00H success
;		   = FFH failure
;
	cmp	ch,23			; Range check hours
	 ja	f2B_20
	cmp	cl,59			; Range check minutes
	 ja	f2B_20
	cmp	dh,59			; Range check seconds
	 ja	f2B_20
	cmp	dl,99			; Range check hundredths
	 ja	f2B_20
	push	cx			; save hours/mins
	push	dx			; save secs/hundredths
	call	ReadTimeAndDate		; Get the current Time and Date
	pop	biosDate+4		; leave the date alone
	pop	biosDate+2		;  but update the time
	jmp	f2B_10			; Update the Date and Time	


	Public	ReadTimeAndDate
	
ReadTimeAndDate:			; Get the current Time and Date
	call	rw_clock_common		; make sure clock is there/setup regs
	call	device_read		; read the Date and Time
	mov	ax,biosDate		; get the BIOS date and convert
	cmp	ax,daysSince1980	; (but only if necessary)
	 jne	NewDate
	ret

NewDate:
	mov	daysSince1980,ax	; so we won't have to convert next time
	inc	ax			; Day number starting 1 Jan 1980
	mov	cx,ax			; save day count
	inc	ax			; convert to a sunday as 1/1/80 is tues
	xor	dx,dx
	mov	bx,7
	div	bx
	mov	dayOfWeek,dl		; save day of week

	xor	dx,dx
	mov	ax,cx			; recover day count

	xor	di,di			; assume zero leap days
	sub	ax,60			; less than 60 days
	 jc	no_leap_days		; means no leap days to subtract
	mov	bx,1461			; 1461 = days in four years
	div	bx			; get number of leap years since 1980
	inc	ax			; include 1980
	sub	cx,ax			; normalize years to 365 days
	mov	di,ax			; save proper leap day count
no_leap_days:

	xor	dx,dx
	xchg	ax,cx			; DX:AX = years since 1980 * 365
	mov	bx,365
	div	bx			; get number of years since 1980
	or	dx,dx			; check for zero days left
	 jnz	days_left
	dec	ax			; dec year count
	mov	dx,365			; set day count to last day of last year
days_left:

	mov	yearsSince1980,ax	; save the year
	xchg	ax,si			; save in SI

	xor	bx,bx
	mov	cx,12
get_month:				; find the appropriate month
	cmp	dx,totaldays[bx]
	 jbe	got_month
	inc 	bx
	inc 	bx
	loop	get_month
got_month:
	shr	bx,1			; BX = month
	mov	month,bl
	
	dec	bx
	shl	bx,1			; BX = index to previous months
	sub	dx,totaldays[bx]	; get days into this month

	cmp	bx,2			; if it's FEB 29th we've lost a day
	 jne	not_leap_yr		; check it's FEB
	test	si,3
	 jnz	not_leap_yr		; but is it a leap year ?
	shr 	si,1
	shr 	si,1			; divide years by 4
	inc	si			; include this year
	cmp	si,di			; compare against leap day adjustment
	 jne	not_leap_yr
	inc	dx			; put 29th feb back again
not_leap_yr:
	mov	dayOfMonth,dl		; save the day of the month
	ret


ConvertDate:
    sub cx,1980         ; Base year is 1980
	jc	xset_date_error
	cmp	cx,2100-1980		; Year in valid range ?
	jnc	xset_date_error
	mov	bl,dh			; Month to BL
	xor	bh,bh
	dec	bx			; Adjust month to 0-11
	cmp	bl,12			; Month in valid range ?
	jnc	xset_date_error
	mov	al,dl			; Day of month
	cbw
	test	cl,3			; Leap year ?
	jnz	not_leap_year		; Jump if not
	cmp	dh,3			; After February ?
	cmc
	adc	al,ah			; Increment days in current year if so
	cmp	dl,29			; Day of month 29 ?
	jz	day_valid		; Valid if so

not_leap_year:
	dec	dx
	cmp	dl,monthdays[bx]	; Day of month within range for non-leap
					; year ?
	jnc	xset_date_error

day_valid:
	shl	bx,1
	add	ax,totaldays[bx]	; Get total days in current year

	push	ax

	mov	ax,365
	mul	cx			; Convert year to days since 1-1-1980
	mov	cx,ax

;	if total (ax) >= 60 (Feb 29 1980) then
;	  leap$days = (total - 60) / (365 * 4) + 1

	sub	ax,60			; Before first leap year date
	jc	noleap			; Jump if so
	mov	bx,365*4		; 4 years worth of days (365 * 4)
	sub	dx,dx
	div	bx			; Get number of leap years - 1
	inc	ax
	add	cx,ax			; CX now has total days including leap
					; days

noleap:
	dec	cx

	pop	ax

	add	cx,ax			; Get total days since 1-1-1980
	clc
	ret

xset_date_error:
	stc
	ret

rw_clock_common:
	mov	cx,6			; read/write 6 characters
	mov	dx,offset biosDate	; DX -> 6 byte buffer
	les	si,clk_device		; Get the address of the Clock Device
	cmp	si,-1			; Has a valid device been selected
	 jne	rw_clock_common10
	add	sp,WORD			; discard near return address
rw_clock_common10:
	ret


;	*****************************
;	***    DOS Function 38    ***
;	*** Get/Set Country Data  ***
;	*****************************
	Public	func38
func38:
	xor	ah,ah			; Generate 16 Bit country
	cmp	al,0FFh			; FF means country code in BX
	 jne	f38_10
	xchg	ax,bx			; AX = real country code
f38_10:
	xchg	ax,dx			; DX = country
	test	dx,dx			; dos_AL = 0 get the current country
     jz f38_get         
	inc	ax			; now check for dos_DX = FFFF
	 jz	f38_set			;  which means set country code
	dec	ax			; no, return buffer to normal
f38_get:
	test	dx,dx			; Get current?
	 jnz	f38_g10			; Yes
	mov	dx,cur_country		; use current country
f38_g10:
; look for (and if neccessary load) type 1 info into buffer
	xchg	ax,di			; ES:DI -> buffer
	mov	bx,cur_cp		; bx=codepage
	call	f38_get_info		; get info in current codepage
	 jnc	f38_g20
	push 	ss
	pop 	ds
	xor	bx,bx			; now try any codepage
	call	f38_get_info		; if none for current codepage
	 jc	f38_error		; No Match Found
f38_g20:
	lea	si,EXCI_CI_DATAOFF[si]	; point at CI_, not EXCI_ data
	mov	bx,[si+CI_CODE]		; Return the selected country code
	mov	cx,CI_STATICLEN/2
	rep	movsw
	
if NLSFUNC
	push	ss
	pop	ds
;	call	get_dseg		; DS back to PCMODE
endif
	call	return_BX		; return country code in BX
	xchg	ax,bx
	jmp	return_AX_CLC		; and in AX

f38_get_info:
	push 	es
	push 	di
	push 	dx			; save pointer to buffer
	mov	al,1			; Get data list seperators etc...
	call	f65_get_info		; DS:SI -> extended country info buffer
	pop 	dx
	pop 	di
	pop 	es			; ES:DI -> users buffer
	ret

f38_set:
	mov	bx,cur_cp		; bx=codepage
	and	bx,f38_flag		; force CP to zero if 1st time here
	call	f38_set_country		; Update the Internal Data Structures
	 jc	f38_error
f38_s20:
	mov	f38_flag,0FFFFh		; Country Code Set Successfully
	mov	ax,cur_country		; and return the current country
	jmp	return_AX_CLC		;  to the user


f38_error:

if NLSFUNC
	push	ss
	pop	ds
;	call	get_dseg		; DS back to PCMODE
endif
	mov	ax,ED_FILE		; This is the Error to return 
    jmp error_exit      


f38_set_country:
; On Entry:
;	BX = codepage
;	DX = country
; On Exit:
;	AX = error code
; preserve codepage/country info if there is an error (ie do type 1 last!)
;
	mov	al,2			; Get uppercase & filename table
	mov	di,offset Ucasetbl
	mov	cx,info2_len
	call	f38_update
	 jc	f38_seterr
	mov	al,4			; Get uppercase & filename table
	mov	di,offset FileUcasetbl
	mov	cx,info4_len
	call	f38_update
	 jc	f38_seterr
	mov	al,5			; Get Legal file characters
	mov	di,offset FileCharstbl
	mov	cx,info5_len
	call	f38_update
	 jc	f38_seterr
	mov	al,6			; Get Collating table
	mov	di,offset Collatingtbl
	mov	cx,info6_len
	call	f38_update
	 jc	f38_seterr
	mov	al,7			; Get double byte character set table
	mov	di,offset DBCS_tbl
	mov	cx,info7_len
	call	f38_update
	 jc	f38_seterr
	mov	al,1			; Get data list seperators etc...
	mov	di,offset country_data	; do last since this updates
	mov	cx,info1_len		; cur_country/cur_cp
	call	f38_update
;	 jc	f38_seterr
;	clc
	ret
f38_seterr:
	mov	ax,ED_FILE		; return file not found error
	ret

f38_update:
	push	ds			; save important registers
	push	bx			; codepage
	push	cx			; count for move
	push	dx			; country
	push	di			; destination offset for move
	push	ds			; destination segment
	call	f65_get_info		; DS:SI -> buffer with country info
	pop	es			; destination seg in ES
	pop	di			; ES:DI -> destination of move
	pop	dx			; country
	pop	cx			; bytes to move
	pop	bx			; codepage back again
	 jc	f38_update10		; any problems ?
	rep	movsb			; no, copy the data
f38_update10:
	pop	ds			; DS back to PCMDSEG
	ret

;	*****************************
;	***    DOS Function 65    ***
;	*** Extended Country Data ***
;	*****************************
;
;CODEPAGE	equ	437			; Return Standard Code Page
;
;	Get Extended Country Code Sub-Functions
;
func65_dt	dw	0FFFFh			; 00 Illegal Sub-Function
		dw	offset country_data	; 01 Extended Country Info
		dw	offset Ucasetbl		; 02 UpperCase Table
		dw	0FFFFh			; 03 Invalid Subfunction
		dw	offset FileUcasetbl	; 04 FileName Upper Case Table
		dw	offset FileCharstbl	; 05 Valid Filename Characters
		dw	offset Collatingtbl	; 06 Collating Sequence
		dw	offset DBCS_tbl		; 07 DBCS Environment Vector 
func65_dtl	equ	(offset $ - offset func65_dt)/2

	Public	func65
func65:
	cmp	al,func65_dtl		; is sub-function 0-7 ?
	 jb	func65_read_table
	sub	al,20h			; now check for 20-22
	 jb	f65_invalid
	 je	func6520		; it's upper case character
	sub	al,2
	 je	func6522
	 jb	func6521
	sub	al,1			; how about 6523 ?
	 jnz	f65_invalid
;	jmp	func6523

func6523:
;--------
; On Entry:
;	DX = character to check
; On Exit:
;	AX = 0, No
;	AX = 1, Yes
;	AX = 2, neither
;
	push	ds
	pop	es
	mov	di,offset NoYesChars	; 'NnYy'
	cbw				; assume No (AX=0)	
	xchg	ax,dx			; AX = char, DX = answer
	call	dbcs_lead		; is it 1st of a DBCS pair
	 jne	func6523_10
	scasw				; check 'N'
	 je	func6523_30
	inc	dx			; assume Yes (DX=1)
	scasw				; check 'Y'
	jmp	func6523_20
func6523_10:
	scasb				; check 'N'
	 je	func6523_30
	scasb				; check 'n'
	 je	func6523_30
	inc	dx			; assume Yes (DX=1)
	scasb				; check 'Y'
	 je	func6523_30
	scasb				; check 'y'
func6523_20:
	 je	func6523_30
	inc	dx			; it's neither (DX=2)
func6523_30:
	xchg	ax,dx			; return result in AX
	jmp	return_AX_CLC		; Return the Code Page

func6522:
;--------
; Upper case ASCIIZ string at ES:DX
	mov	cx,0FFFFh		; calculate the length
	mov	di,dx			;  of the string
;	mov	al,0
	repne	scasb
	not	cx			; CX = length, including 0
;	jmp	func6521		; now use upper case CX bytes

func6521:
;--------
; Upper case string of CX bytes at ES:DX
	jcxz	f6521_30		; nothing to do?
	mov	si,dx
	mov	di,dx			; point SI & DI at string
f6521_10:
	lodsb	es:0			; read a character
	call	dbcs_lead		; is it 1st of a DBCS pair
	 jne	f6521_20
	stosb				; store 1st byte of this pair
	movs	es:byte ptr [di],es:byte ptr [si]
					; copy 2nd byte
	dec	cx			; 1st byte of pair
	loopnz	f6521_10		; go around for another one
	ret				; time to go...
f6521_20:
	call	toupper			; upper case the character
	stosb				; 
	loop	f6521_10		; go and do another one
f6521_30:
	ret

func6520:
;--------
; Upper case character DL
	xchg	ax,dx			; character in AX
	call	toupper			; upper case it
	mov	dl,al			; return in AL and DL
	jmp	return_DX		; set return code

f65_invalid:
;-----------
; short jump to invalid function
	jmp	invalid_function


func65_read_table:
;-----------------
	cmp	cx,5			; Check for valid buffer size
	 jb	f65_invalid
	cbw				; Get the request sub-function
	mov	si,ax			; into SI
	shl	si,1
	mov	si,func65_dt[si]
	inc	si			; is SI = 0FFFFh
	 jz	f65_invalid		; if so it's an invalid function
	dec	si

	cmp	dx,0ffffh
	 jne	f65_21			; FFFF means
	mov	dx,cur_country		;  use default country
f65_21:
	cmp	bx,0ffffh
	 jne	f65_22			; FFFF means
	mov	bx,cur_cp		;  use default codepage
f65_22:
	call	f65_get_info		; DS:SI -> extended info for this pair
	mov	ax,ED_FILE		; On Error return File Not Found
	 jnc	f65_23			; for any error
	push 	ss
	pop 	ds
	jmp	error_exit		; so Quit
f65_23:
	les	bx,ss:int21regs_ptr	; point to callers registers
	mov	ax,es:reg_AX[bx]	; get the subfunction number
	mov	cx,es:reg_CX[bx]	; this much data is requested
	mov	di,es:reg_DI[bx]	; Get the Parameter Block Offset
	mov	es,es:reg_ES[bx]	; and Segment
	stosb				; fill in Info ID
	cmp	al,1			; 1 is special - the rest
	 jne	f65_30			;  want a DWORD ptr
	cmp	cx,EXCI_MAXLEN		; Check CX against the sub-function 1
	 jbe	f65_25			; maximum and force CX to this value
	mov	cx,EXCI_MAXLEN		; if it is greater
f65_25:
	call	return_CX		; Return the number of bytes transfered
	sub	cx,EXI_DATA_LEN		; Adjust count for 3 byte header 
	mov 	ax,cx
	stosw				; fill in EXCI_LENGTH
	push	cx			; Save the count and copy as much
	cmp	cx,EXCI_STATLEN		; valid data a possible. IE at most
	 jbe f65_27			; EXCI_STATLEN bytes	
	mov	cx,EXCI_STATLEN
f65_27:
	rep	movsb			; just copy the data
	pop	cx			; Zero the rest of the data
	sub	cx,EXCI_STATLEN		; Skip if no space left in users
	 jbe	f65_40			; buffer otherwise STOSB
	xor 	al,al
	rep 	stosb
	jmp	f65_40

;
;	All function 65 sub-functions apart from 01 (Extended Country Info.)
;	pass use this code to update the users parameter block.
;
f65_30:
    mov cx,5            
	call	return_CX
	mov 	ax,si
	stosw				; fill in the DWORD ptr to the data
	mov 	ax,ds
	stosw
f65_40:
	push	ss
	pop	ds
;	call	get_dseg		; back to PCMDSEG
	mov	ax,cur_cp		; ##jc## Is the Requested or Current
	jmp	return_AX_CLC		; Return the Code Page

;	*****************************
;	***    DOS Function 66    ***
;	***Get/Set Global CodePage***
;	*****************************
;
	Public	func66
func66:
	cbw
	dec 	ax
	 jz 	f66_10			; AL = 1, Get the Current CodePage
	dec 	ax
	 jz 	f66_20			; AL = 2, Set the Current CodePage
	jmp	invalid_function	; Illegal Sub-Function return an Error

f66_10:					; Get the Current Code Page Info
	mov	bx,cur_cp		; Current CodePage
	call	return_BX
	mov	dx,SYS_CP		; System CodePage
	call	return_DX
	xor	ax,ax
	jmp	return_AX_CLC

f66_20:					; Set the Current CodePage
	mov	dx,cur_country		; The Codepage has changed, so update
	call	f38_set_country		; Country Info and tables
	 jnc	f66_30			; Reset the Current CodePage if
	mov	ax,ED_FILE		; and return the error
	jmp	error_exit
f66_30:
	mov	bx,cur_cp		; select the new codepage
	call	f66_select_cp		; Prepare CodePage Devices
	 jnc	f66_40			; No Errors Skip Error Handler
	mov	ax,-65			; Update Error Status do not generate
	call	error_ret		;  a critical error but return
					;  "access denied" to the application
f66_40:
	ret


f65_get_info:
; On Entry:
;	AL = info type
;	BX = codepage (zero means any)
;	DX = country
; On Exit:
;	CY set if error
;	DS:SI -> buffer with info in it
;
; NB. Remember to to Xlat fixups !
;
	cmp	dx,cur_country		; is it default country ?
	 jne	f65_p30			; have we already got correct country ?
	test	bx,bx			; CP zero special case and we will
	 jz	f65_p20			;  accept anything for this country
	cmp	bx,cur_cp		; otherwise is the codepage
	 jne	f65_p30			;  in the default system ?
f65_p20:
	cbw				; make info type a word
	mov	si,ax			;  into index register
	shl	si,1			; now a word offset
	mov	si,func65_dt[si]	; pick up offset of correct table
	jmp	f65_p90
f65_p30:
	push	ax
	call	f65_locate_and_read	; get info into a buffer at DS:SI
	pop	ax
	 jc	f65_p_exit
f65_p90:
	cmp	al,1			; was it country info ?
	 jne	f65_p95			; no, skip the fixup
	mov	CI_CASEOFF+EXCI_CI_DATAOFF[si],offset xlat_xlat
	mov	CI_CASESEG+EXCI_CI_DATAOFF[si],ss
f65_p95:
	clc
f65_p_exit:
	ret


;
;	**********************************************************************
;	***  Function 65 support - routines for seeking a country/codepage ***
;	***  and loading the required information into the temp data area  ***
;	**********************************************************************
;
;	**************************************************
;	***   Open country.sys and search for the      ***
;	***   table of offsets for the given country/  ***
;	***   codepage, read it in and exit.           ***
;	**************************************************

f65_locate_and_read:
;	Locate and Read info AL for Country DX Codepage BX
if NLSFUNC
	mov	di,offset country_filename
					; point at pathname to country.sys 
	xchg	ax,cx			; get info into CL
	mov	ax,14feh		; then call magic backdoor
nlsfunc_int2f:
	stc				; assume an error
	int	2fh			; to do the hard work
	ret
else
	push	ax
	call	f65x_find_info		; Will need to load up the info 
	pop	ax
	 jc	f65_lr_exit		; so do it if we can.

	mov	dx,offset f65xx_temp_area
	mov	cx,256			; read 256 bytes into local buffer
	push	ax
	call	f65x_load_info		; Load required info
	pop	ax
	 jc	f65_lr_exit
	mov	ah,MS_X_CLOSE		; All done so 
	mov	bx,c_handle 		; Close the file first
	call	dos_entry		; before leaving
;	 jc	f65_lr_exit
	mov	si,offset f65xx_temp_area ; Tell subroutines where info is
f65_lr_exit:
	ret
;
; Entry:  dx=country code, bx=codepage
; Exit :  carry set, and country.sys closed if failure
;         country.sys open ready for more reads if success
;
f65x_find_info:
	push	es			; Save es
	push	ds
	pop	es			; Make es=ds
	mov	f65xx_country,dx
	mov	f65xx_codepage,bx
	mov	dx,offset country_filename
	mov	ax,(MS_X_OPEN*256)+0	; Attempt to open country.sys 
	test	dx,dx
	stc
	 jz	f65x_40 
	call	dos_entry		; Handle should come back in ax
	 jc	f65x_40
f65x_10:
	mov	c_handle,ax		; Save handle
	mov	dx,f65xx_country
	cmp	f65xx_code,dx		; do we already have the information?
	 jne	f65x_30			; No - get it from country.sys
f65x_20:
	cmp	f65xx_cp,bx		; Does codepage agree too?
	 je	f65x_35			; Yes so exit with no more ado
f65x_30:
	mov	dx,007Eh	
	xor	cx,cx			; Seek within country.sys
	mov	bx,c_handle
	mov	ax,(MS_X_LSEEK*256)+0	; seek from begining
	call	dos_entry
	 jc	f65x_err
	mov	ah,MS_X_READ		; Now read the signature bytes and
	mov	bx,c_handle		; check them
	mov 	cx,2
	mov 	dx,offset f65xx_sig
	call	dos_entry
	 jc	f65x_err
	cmp	f65xx_sig,VALID_SIG
	 jne	f65x_err		; If signature bad exit
f65x_32:
	mov	ah,MS_X_READ		; Read from country.sys header until
	mov	bx,c_handle		; Country/codepage found or NULL
	mov	cx,f65xx_ptable_len
	mov	dx,offset f65xx_code
	call	dos_entry
	 jc	f65x_err	
	cmp	f65xx_code,0		; Found NULL so reqd combination
	 je	f65x_err		; was not found
	mov	dx,f65xx_code		; Get the country/codepage values
	mov	bx,f65xx_cp		; read from Country.SYS
	cmp	dx,f65xx_country	; Check against the requested
	 jne	f65x_32			; Country. 
	cmp	f65xx_codepage,0	; If a codepage match is not
	 jz	f65x_35			; then return success
	cmp	bx,f65xx_codepage	; Check against the requested
	 jne	f65x_32			; Codepage
f65x_35:
	mov	f65xx_country,dx	; Force the Search Country and
	mov	f65xx_codepage,bx	; CodePage to be Updated
f65x_40:
	pop	es			; combination found so exit
	ret
	
f65x_err:
	pop	es
	mov	ah,MS_X_CLOSE		; On error close country.sys
	mov	bx,c_handle 		; and set the carry flag before
	call	dos_entry		; leaving
	stc
	ret
;
;	**************************************************
;	***   Load the type of information requested   ***
;	***   For the country currently active in the  ***
;	***   offset table			       ***
;	**************************************************
;
; Entry:  al=type of info, dx=offset of buffer to read info into cx=no of bytes
; Exit :  carry set, and country.sys closed if failure
;
f65x_load_info:
	push	es
	push	cx
	push	dx
	push	ds			; Make es=ds
	pop	es
	dec	al			; 1=Data , 2=uppercase, 4=fuppercase
	sub	bh,bh			; 5=filechars, 6=Collating table
	mov	bl,al			; 7=DBCS table
	shl	bx,1			; Retrieve relevant offset
	mov	dx,f65xx_data[bx]	
	xor	cx,cx			; Seek within country.sys
	mov	bx,c_handle
	mov	ax,(MS_X_LSEEK*256)+0	; seek from begining
	call	dos_entry
	pop	dx			; Get buffer address back
	pop	cx			; and number of bytes to read
	 jc	f65x_err
	test	ax,ax			; zero offset is a problem
	 jz	f65x_err		; (probably DBCS with old COUNTRY.SYS)
	mov	ah,MS_X_READ		; Now read that info into our data area
	mov	bx,c_handle
	call	dos_entry		; Return when read is done
	 jc	f65x_err
	pop	es
	ret
endif

;
;	This function scans the complete device list and prepares
;	all devices which support codepage.
;
; On Entry:
;	BX = codepage
; On Exit:
;	AX = error code

DA_CODEPAGE	equ	DA_CHARDEV+DA_IOCTL+DA_GETSET

f66_select_cp:
if NLSFUNC
	mov	ax,14ffh		; then call magic backdoor
	jmp	nlsfunc_int2f		;  to do the hard work
else	
	push	ds
	mov	f66_cp,bx		; Save requested CodePage
	mov	preperr,0000		; Initialize Prepare Error
	push 	ds
	pop 	es
	mov	bx,offset dev_root	; Get the Root of the Device List
f66_p10:				; Skip the NUL Device and check
	lds	bx,ds:DH_NEXT[bx]	; each character device for CodePage
	cmp 	bx,0FFFFh
	 jz 	f66_p50			; Support.
	mov	ax,ds:DH_ATTRIB[bx]
	and	ax,DA_CODEPAGE		; Check for a Character Device which
	cmp	ax,DA_CODEPAGE		; supports IOCTL strings and GETSET
	 jne	f66_p10			; otherwise skip the device

	push	bx
	lea	si,DH_NAME[bx]		; Found a matching device so
	mov	di,offset prepname	; open the device and select the 
	mov	cx,8			; requested codepage

f66_p20:
	lodsb
	cmp 	al,' '
	 jz 	f66_p30
	stosb
	loop	f66_p20

f66_p30:
	xor 	al,al
	stosb	
	mov	ax,(MS_X_OPEN*256)+1	; Open the device name for
	mov	dx,offset prepname	; Write Access
	call	dos_entry
	 jc	f66_perr
	mov	bx,ax			; Save Device Handle in BX

	mov	si,es:f66_cp		; Get Requested CodePage in SI
	mov	dx,offset cp_packet	; Offset of CodePage Struct
	mov	cx,006Ah		; Get Unknown CodePage
	mov	ax,(MS_X_IOCTL*256)+0Ch	; Generic IOCTL function
	call	dos_entry		; Make function Call
	 jc	f66_p32			; Error so Select requested Code Page

	cmp 	si,es:cp_cpid
	jz 	f66_p35			; If this the currently selected
f66_p32:				; skip the select CodePage
	mov	es:cp_cpid,si
	mov	dx,offset cp_packet	; Offset of CodePage Struct
	mov	cx,004Ah		; Select Unkown CodePage
	mov	ax,(MS_X_IOCTL*256)+0Ch	; Generic IOCTL function
	call	dos_entry		; Make function Call
	 jnc	f66_p35			; No Error so skip the error
f66_p33:
 	mov	es:preperr,ax		; save

f66_p35:	
	mov	ah,MS_X_CLOSE		; Close the device and check
	call	dos_entry		; for more devices to be prepared
	jmp	f66_p40	

f66_perr:
	mov	es:preperr,ax		; Save the error code and try the
f66_p40:				; next device in the chain
	pop	bx			; Restore the Device offset
	jmp	f66_p10			; and continue

f66_p50:				; All device have been prepared
	pop	ds			; now return the last error code
	mov	ax,preperr		; in AX
	or	ax,ax
	ret
endif

PCM_CODE	ends

PCMODE_DSIZE	segment public para 'DATA'
	extrn	swap_indos:word
PCMODE_DSIZE	ends

PCM_RODATA	segment public word 'CODE'
;
;	Get Internal Data DOS function 5Dh
;
func5D_ft   dw  f5D00       
		dw	f5D01		; Commit All
		dw	f5D02		; Close File By Name
		dw	f5D03		; Close All Host Files
		dw	f5D04		; Close Process Host Files
		dw	f5D05 		; Get Open File List
		dw	f5D06		; Get DOS Data Area
		dw	f5D_msnet	; f5D07 ; Get Truncate Flag used
						; with Redirected Dev I/O
		dw	f5D_msnet	; f5D08 ; Set Truncate Flag with
						; with Redirected Dev I/O
		dw	f5D_msnet	; f5D09 ; Close All Spool Streams
		dw	f5D0A		; Set Extended Error Info
func5D_ftl	equ	(offset $ - offset func5D_ft)/2
		dw	invalid_function

;
;	Data used by the Binary format Time and Date routines
;
totaldays	dw	0,31,59,90,120,151,181,212,243,273,304,334,0ffffh
monthdays	db	31,28,31,30,31,30,31,31,30,31,30,31

parse_separators	db	TAB,'.,+:;='
parse_terminators	db	'|"/\[]<>'

PCM_RODATA	ends

PCMODE_DATA	segment public word 'DATA'
	extrn	internal_data:word
	extrn	error_code:word
	extrn	error_class:byte
	extrn	error_action:byte
	extrn	error_locus:byte
	extrn	error_dev:word

	extrn	indos_flag:word
	extrn	bootDrv:byte
	extrn	current_psp:word
	extrn	break_flag:byte
	extrn	dma_offset:word
	extrn	dma_segment:word
	extrn	fcb_search_buf:byte
	extrn	func52_data:byte	; Internal Data Table Area
	extrn	int21regs_ptr:dword
	extrn	lock_tables:dword
	extrn	unlock_tables:dword
	extrn	share_stub:dword
	extrn	remote_call:word	; set to FF if remote machine operation
	extrn	swap_always:word
	extrn	switch_char:byte
	extrn	owning_psp:word
	extrn	machine_id:word
	extrn	country_data:byte
	extrn	cur_country:word
	extrn	cur_cp:word
	extrn	verify_flag:byte

	extrn	clk_device:dword	; Clock Device Driver Address
	extrn	biosDate:word
	extrn	daysSince1980:word
	extrn	yearsSince1980:word
	extrn	month:byte
	extrn	dayOfWeek:byte
	extrn	dayOfMonth:byte
	extrn	hour:byte
	extrn	minute:byte
	extrn	second:byte
	extrn	hundredth:byte
	extrn	WindowsHandleCheck:byte

SYS_CP		equ	437		; System CodePage
PCMODE_DATA	ends

GLOBAL_DATA	segment public word 'DATA'

f38_flag	dw	0		; Country Code Selected Successfully

if NLSFUNC ne TRUE
	extrn	dev_root:dword

f66_cp		dw	0		; INT21/66 Local Variable
cp_packet	dw	2		; Packet Size
cp_cpid		dw	0		; Request CodePage
		db	0,0		; Packet Terminators

preperr		dw	0		; Prepare function Error Code
prepname	db	9 dup (0)	; Reserved for ASCIIZ Device Name

;
; Area for country.sys current pointer table 
; (these are all offsets into country.sys)
;
f65xx_code	dw	0	; Country code
f65xx_cp	dw	0	; Code page
		dw	0	; +1 reserved
f65xx_data	dw	0	; Data area
		dw	0	; Upper case table
		dw	0	; +1 reserved		
		dw	0	; Filename upper case table
		dw	0	; Legal file characters
		dw	0	; Collating table
		dw	0	; Double byte character set lead byte table
f65xx_ptable_len	equ	offset $ - offset f65xx_code

f65xx_temp_area	db	256 dup (0)	; Data area for extended country info
f65xx_codepage	dw	0
f65xx_country	dw	0
f65xx_sig	dw	0	; Signature
c_handle	dw	0

endif	;not NLSFUNC

GLOBAL_DATA	ends

	end
