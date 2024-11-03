title 'REDIR - DOS file system network redirector interace support'
;    File              : $REDIR.ASM$
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
;    $Log: $
;    REDIR.A86 1.30 94/12/01 10:05:21 
;    added attribute support for open/move/unlink  
;    REDIR.A86 1.29 94/11/11 15:10:03
;    Code at redir_lseek30 changed to ensure that the file offset is 
;    updated. Previously, this did not happen when INT 21/4202 (seek from
;    end of file) was called, and consequently the game MYST could not 
;    be installed under NWDOS7.    
;    REDIR.A86 1.28 94/10/03 15:41:12
;    fix problem where VLM network mapping gets deleted if you try to access
;    a path greater than 66 characters long on a network drive.
;    REDIR.A86 1.27 94/02/22 18:05:09
;    fix problem with "d:\\filename.ext" (Netware 4 LOGIN)
;    REDIR.A86 1.26 94/01/10 16:42:16
;    File delete uses file attributes of 06, not 16 (no directory bit)
;    REDIR.A86 1.25 93/12/10 00:03:09
;    Move non-inherited bit to correct place in file handle
;    REDIR.A86 1.22 93/11/19 23:59:00
;    If a read/write returns ED_LOCKFAIL turn into ED_ACCESS on shared files
;    REDIR.A86 1.21 93/09/24 19:50:50
;    Tidy up code on rename
;    REDIR.A86 1.15 93/06/16 16:22:21
;    Always initialise file search attributes to 16h (ie. sys+hidden+dir)
;    REDIR.A86 1.14 93/06/11 15:08:09
;    Return 0 from search first/next
;    REDIR.A86 1.13 93/06/11 02:06:53
;    zero space adjust on getddsc
;    ENDLOG

PCMCODE	GROUP	BDOS_CODE
PCMDATA	GROUP	PCMODE_DATA,PCMODE_CODE

ASSUME DS:PCMDATA

	.nolist
	include psp.def
	include fdos.equ
	include msdos.equ
	include mserror.equ
	include doshndl.def	; DOS Handle Structures
	include f52data.def	; DRDOS Structures
	include redir.equ
	.list

FD_EXPAND	equ	55h


PCMODE_DATA	segment public word 'DATA'

	extrn	current_dsk:byte
	extrn	current_ddsc:dword
	extrn	current_dhndl:dword
	extrn	current_filepos:dword
	extrn	current_ldt:dword
	extrn	dma_offset:word
	extrn	dma_segment:word
	extrn	err_drv:byte
	extrn	file_attrib:word
	extrn	ldt_ptr:dword
	extrn	last_drv:byte
	extrn	phys_drv:byte
	extrn	pri_pathname:byte
	extrn	remote_call:word
	extrn	sec_pathname:byte
	extrn	srch_buf:byte
	
; Data for some int2f commands

	extrn	int2f_cmd:word
	extrn	int2f_stack:word
	extrn	file_mode:word

PCMODE_DATA	ends

PCMODE_CODE	segment public word 'DATA'
	extrn lfn_search_redir:byte
PCMODE_CODE	ends

BDOS_CODE	segment public byte 'CODE'

	Public	islocal
	Public	redir_asciiz_dev_offer
	Public	redir_asciiz_offer
	Public	redir_asciiz_file_offer

	Public	redir_drv_offer
	Public	redir_dhndl_offer
	Public	redir_move_offer
	Public	redir_snext_offer

	extrn	toupper:near
	extrn	check_delim:near
	extrn	check_slash:near
	extrn	check_dslash:near
	extrn	copy_asciiz:near
	extrn	unparse:near
	extrn	find_xfn:near
	extrn	find_dhndl:near
	extrn	ifn2dhndl:near
	extrn	get_xftptr:near
	extrn	output_hex:near
ifdef KANJI
	extrn	dbcs_lead:near
endif


redir_dhndl_offer:
;================
; The FDOS has called this hook to see if we are operating on an MSNET drive.
; We return if we are not, or stay and process function here if we are
	test	es:byte ptr DHNDL_WATTR+1[bx],DHAT_REMOTE/100h
	 jnz	redir_dhndl_accept
	ret
redir_dhndl_accept:
; copy some info from DHNDL_ to local variables
	push	ds
	push 	ss
	pop 	ds
	mov	ax,es:DHNDL_DEVOFF[bx]
	mov	word ptr current_ddsc,ax
	mov	ax,es:word ptr DHNDL_DEVSEG[bx]
	mov	word ptr current_ddsc+WORD,ax
	mov	ax,es:word ptr DHNDL_POS[bx]
	mov	word ptr current_filepos,ax
	mov	ax,es:word ptr DHNDL_POS+2[bx]
	mov	word ptr current_filepos+2,ax
	mov	ax,es:word ptr DHNDL_POSX[bx]
	mov	word ptr current_filepos+4,ax
	mov	ax,es:word ptr DHNDL_POSX+2[bx]
	mov	word ptr current_filepos+6,ax
	pop	ds
	jmp	redir_accept		; now we can process the call


redir_asciiz_dev_offer:
;======================
; The FDOS has called this hook to see if we are opening a redirected device.
; We return if we are not, or stay and process function here if we are

; Before we build it all ourselves do the appropriate INT 2F to allow
; other people to process the path themselves

	call	redir_dev_check		; is it a device ?
	 jnc	redir_accept		; it's been recognised
	ret

redir_move_offer:
;================
; The FDOS has called this hook to see if the rename operation is on a
; redirected drive. Lantastic relies on the path check broadcast's being
; done in the order new_name, old_name.

	mov	word ptr current_ldt,0ffffh
	mov	err_drv,DHAT_DRVMSK
	push	ds
	mov	si,2[bp]		; SI -> parameter block
	lds	si,10[si]		; DS:SI -> user supplied name
	push 	ss
	pop 	es
	mov	di,offset sec_pathname	; DI -> where to build pathname
	push 	ds
	push 	si
	push 	di
	push 	bp
	mov	ax,I2F_PPATH
	int	2fh			; offer path build to someone else
	pop 	bp
	pop 	di
	pop 	si
	pop 	ds
	mov	cx,0			; if accepted then it's a remote drive
	 jnc	redir_move_offer10
	call	build_remote_path	; build path if it a remote drive
redir_move_offer10:
	pop	ds
	 jc	redir_asciiz_error	; return error's if we have any
	 jcxz	redir_asciiz_offer	; it's a valid remote path
	ret				; it's not a remote path

redir_asciiz_offer:
;==================
; The FDOS has called this hook to see if we are operating on an redirected
; drive. We return if we are not, or stay and process function here if we are.
	call	redir_dev_check		; is it a device ?
	 jnc	redir_accept		; it's been recognised
;	jmp	redir_asciiz_file_offer	; now try offering as a file

redir_asciiz_file_offer:
;=======================
;	entry:	SS:BP -> function #, parameter address
;		1st level call (MXdisk not owned)
;	exit:	ZF = 1 if not networked
;
; This function is only called after an Int 2F/I2F_PPATH callout has been
; made and failed. On some functions (Open/Create) we do a check for devices
; between the redir_dev_offer and redir_asciiz_file offer

; We look for a "\\" as the start of "\\server\dir\file" form

	push	ds			; save DS
	mov	si,2[bp]		; SI -> parameter block
	lds	si,2[si]		; get ASCIIZ # from parameter block
	mov	di,offset pri_pathname	; SS:DI -> path buffer
	call	build_remote_path	; build path if it a remote drive
	pop	ds			; restore DS
	 jc	redir_asciiz_error	; return error's if we have any
	 jcxz	redir_accept		; it's a valid remote path
	ret				; it's not a remote path

redir_asciiz_error:
; On Entry:
;	BX = error code
;	DS on stack
; On Exit:
;	DS restored, BX preserved
;	near return on stack discarded, and error returned to fdos_entry
;
	pop	ax			; discard "offer" near ret
	ret				; drop straight back to caller

redir_drv_offer:
;===============
; The FDOS has called this hook to see if we are operating on an MSNET drive.
; We return if we are not, or stay and process function here if we are
;
;	entry:	SS:BP -> function #, parameter address
;		(MXdisk not owned)
;	exit:	return if not networked

	mov	dl,current_dsk		; assume it's the default drive
	mov	si,2[bp]		; SI -> parameter block
	mov	ax,2[si]		; get drive # from parameter block
	test	al,al			; test if default drive
	 jz	redir_drv_offer10	; skip if default drive
	dec	ax			; else decrement for 0..26
	xchg	ax,dx			; and use that
redir_drv_offer10:
	call	isremote
	 jnz	redir_accept
	ret				; return if not

redir_snext_offer:
;=================
; The FDOS has called this hook to see if we are operating on an MSNET drive.
; We return if we are not, or stay and process function here if we are

	call	redir_restore_srch_state
	test	al,80h			; MSNET drive ?
	 jnz	redir_accept
	ret


redir_accept:
;============
; We have decided to accept an FDOS function.
; Note by this time the functions have been validated as legal
	mov	lfn_search_redir, 0FFh
	mov	file_attrib,16h		; default search attribs to all
	pop	si			; discard the near return address
	mov	si,2[bp]		; SI -> parameter block
	mov	si,ds:[si]		; fdos code number
	add	si,si			; make it a word offset
	jmp	cs:[si+redir_tbl-(39h*WORD)]	; call the relevant function


redir_badfunc:
;-------------
	mov	bx,ED_FUNCTION		; bad function number
	ret				; (shouldn't get here...)

redir_tbl	dw	redir_mkdir	; 39-make directory
		dw	redir_rmdir	; 3A-remove directory
 		dw	redir_chdir	; 3B-change directory
		dw	redir_creat	; 3C-create file
		dw	redir_open	; 3D-open file
		dw	redir_close	; 3E-close file
		dw	redir_read	; 3F-read from file
		dw	redir_write	; 40-write to file
		dw	redir_unlink	; 41-delete file
		dw	redir_lseek	; 42-set file pointer
		dw	redir_chmod	; 43-get/set file attributes
		dw	redir_badfunc	; 44-IOCTL emulation
		dw	redir_badfunc	; 45-duplicate handle
		dw	redir_badfunc	; 46-force duplicate handle
		dw	redir_badfunc	; 47-get current directory
		dw	redir_getdpb	;*48*disk information
		dw	redir_badfunc	;*49*flush buffers
		dw	redir_badfunc	;*4A*drive select
		dw	redir_badfunc	;*4B*create child PSP
		dw	redir_badfunc	;*4C*close child PSP
		dw	redir_badfunc	;*4D*generic FCB call
		dw	redir_first	; 4E-find first matching file
		dw	redir_next	; 4F-find next matching file
		dw	redir_commit	;*50*commit file
		dw	redir_mknew	;*51*make new file
		dw	redir_lock	;*52*lock/unlock block
		dw	redir_badfunc	; 53 build DDSC from BPB
		dw	redir_badfunc	;*54*Int 25/26 emulation
		dw	redir_expand	; 55 expand file name
		dw	redir_move	; 56-rename file
		dw	redir_dattim	; 57-get/set file name

	Public	get_ldt

; To support func5D00 remote server calls we must bypass the LDT and
; go directly to the physical drive. To allow support of CDROM's etc
; on servers we do use the LDT's where no corresonding physical drive
; exists.

get_ldt:
;-------
; On Entry:
;	AL = drive (0 based)
; On Exit:
;	ES:BX -> LDT for that drive, set CY if no valid LDT
;	(All other regs preserved)
;
	cmp	al,ss:phys_drv		; if there is no conflict with
	 jae	get_ldt_raw		;  physical drives it's OK
	test	ss:remote_call,0ffh	; remote calls must get to physical
	 jz	get_ldt_raw		;  for server support
	mov	bx,ED_DRIVE		; invalid drive
	stc				; no-go
	ret

	Public	get_ldt_raw

get_ldt_raw:
;-----------
; On Entry:
;	AL = drive (0 based)
; On Exit:
;	ES:BX -> LDT for that drive, set CY if no valid LDT
;	(All other regs preserved)
;
	push	ax
	mov	bx,ED_DRIVE		; assume invalid drive
	cmp	al,ss:last_drv		; do we have an LDT for this drive ?
	 jae	get_ldt10		;  if not we can't have an LDT
	cmp	ss:word ptr ldt_ptr+2,0	; are the LDT's allocated yet ?
	 je	get_ldt10		;  if not return an error
	mov	bl,LDT_LEN
	mul	bl			; AX = offset of LDT entry for drive
	les	bx,ss:ldt_ptr		; get base of LDT's
	add	bx,ax			; DS:BX -> LDT for this drive
	stc				; ie. CLC on exit
get_ldt10:
	cmc
	pop	ax
	ret

get_ldt_flags:
;-------------
;	entry:	DL = drive number
;	exit:	AX = LDT_FLAGS entry for that drive
;		(All other regs preserved)
;
	push	es
	push	bx
	xor	ax,ax			; assume no LDT around...
	xchg	ax,dx			; AL = drive number
	call	get_ldt			; ES:BX -> LDT
	xchg	ax,dx			; restore drive to DX
	 jc	glf10			; AX = zero if no LDT
	mov	ss:word ptr current_ldt,bx ; set current_ldt
	mov	ss:word ptr current_ldt+2,es
	mov	ax,es:LDT_FLAGS[bx]	; return real flags
glf10:
	pop	bx
	pop	es
	ret
	
islocal:
;-------
;	entry:	AL = drive number (zero based)
;	exit:	CY = set if drive is remote
;		(All other regs preserved)
;
	push	ax
	push	dx
	xchg	ax,dx
	call	get_ldt_flags
ifdef JOIN
	test	ax,LFLG_JOINED+LFLG_NETWRKD
					; are REMOTE/JOINED bits set ?
else
	test	ax,LFLG_NETWRKD		; is REMOTE bit set ?
endif
	 jz	islocal10
	stc				; indicate it's not local
islocal10:
	pop	dx
	pop	ax
	ret

isremote:
;--------
;	entry:	DL = drive number
;	exit:	ZF = clear if drive is remote
;		CY = set if drive is JOIN'd
;		(Only AX corrupted)
;
	call	get_ldt_flags
ifdef JOIN
	test	ax,LFLG_JOINED		; is JOINED bit set ?
	 jnz	isremote10
endif
	test	ax,LFLG_NETWRKD		; is REMOTE bit set ?
	ret
ifdef JOIN
isremote10:
	test	ax,LFLG_NETWRKD		; is REMOTE bit set ?
	stc				; STC to indicate JOIN'd
	ret
endif

redir_dev_check:
;---------------
; Offer the name to the network as a device
; On Entry:
;	PB+2 = dword ptr to ascii name
;	DI -> buffer to parse into
; On Exit:
;	CY set if not recognised
;
	mov	word ptr current_ldt,0ffffh
	mov	err_drv,DHAT_DRVMSK
	push 	ds
	push 	bp
	mov	si,2[bp]		; SI -> parameter block
	lds	si,2[si]		; DS:SI -> user supplied name
	mov	dx,si			; DS:DX as well..
	push 	ss
	pop 	es
	mov	di,offset pri_pathname	; DI -> where to build pathname
	mov	ax,I2F_PPATH
	int	2fh			; offer path build to someone else
	pop 	bp
	pop 	ds
	ret

build_remote_path:
;-----------------
; On Entry:
;	DS:SI -> path to check
;	SS:DI -> position to build remote path
; On Exit:
;	CY clear, CX == 0 if it's a valid remote path
;	CY clear, CX <> 0 if it's a local path
;	CY set if there is an error to be returned (BX = error code)
;
	mov	cx,si			; save source path in CX
	mov	dl,ss:current_dsk	; assume current disk
	lodsw				; get 1st two characters
	test	al,al			; make sure it's not a NUL string
	 jz	build_remote_path10	;  before we check it it's a
	cmp	ah,':'			;  drive specified
	 jne	build_remote_path10	; we want to find "d:\\" format too
	mov	bx,ED_DRIVE		; assume "invalid drive" error
	and	al,not 'a'-'A'		; cheap upper case
	sub	al,'A'
	 jb	build_remote_path30	; return "invalid drive" if error
	cmp	al,ss:last_drv		; check if > 'Z'
	 ja	build_remote_path30	; return "invalid drive" if error
	xchg	ax,dx			; DL = ASCIIZ supplied drive
	lodsw				; get possible '\\'
	jmp	build_remote_path15
build_remote_path10:
	mov	ss:word ptr current_ldt,0ffffh
	call	check_dslash		; is it "\\"
	 je	build_remote_path20		; if so forget about the drive #
build_remote_path15:
	call	isremote		; test if drive DL is remote
ifdef JOIN
	 jb	build_remote_path30	; return "invalid drive" if JOINed
endif
	 jnz	build_remote_path20	; it's remote, go build a path
	xor	cx,cx			; CY clear (no error)
	inc	cx			; CX <> 0, (non-remote drive)
	ret

build_remote_path20:
; Build a path from the CSD and the pathname in the parameter block
	mov	si,cx			; DS:SI -> source ASIIZ name
	push 	ss
	pop 	es			; ES:DI -> MSNET buffer
	call	redir_build_path
	 jc	build_remote_path30
	xor	cx,cx			; CY clear, CX == 0
	ret				; it's a valid remote path

build_remote_path30:
	stc				; CY set, we have error BX
	ret



;	MAKE DIRECTORY (MKDIR)

;	+----+----+----+----+----+----+
;	|    39   |        name       |
;	+----+----+----+----+----+----+

;	entry:
;	------
;	name:	segmented address of ASCIIZ name

;	exit:
;	-----
;	BX:	0000 or error code ( < 0)

redir_mkdir:
	mov	ax,I2F_MKDIR		; it's a make dir
	jmp	redir_pathop_common


;	REMOVE DIRECTORY (RMDIR)

;	+----+----+----+----+----+----+
;	|    3A   |        name       |
;	+----+----+----+----+----+----+

;	entry:
;	------
;	name:	segmented address of ASCIIZ name

;	exit:
;	-----
;	BX:	0000 or error code ( < 0)


redir_rmdir:
	mov	ax,I2F_RMDIR		; it's a remove dir
;	jmp	redir_pathop_common

redir_pathop_common:
	push	ds
	push 	ss
	pop 	ds
	call	int2f_ldt
	pop	ds
	 jc	redir_pathop_common10
	xor	ax,ax			; no problems
redir_pathop_common10:
	xchg	ax,bx			; return result in BX
	ret



;	CHANGE DIRECTORY (CHDIR)

;	+----+----+----+----+----+----+
;	|    3B   |        name       |
;	+----+----+----+----+----+----+

;	entry:
;	------
;	name:	segmented address of ASCIIZ name

;	exit:
;	-----
;	BX:	0000 or error code ( < 0)

redir_chdir:
;------------
; The following code throws out the ASSIGN/SUBST form "f:=d:\"
; The alternative is to allow the Extentions to throw it out as a bad path
; but this is safer, and doesn't cost us much.

	push	ds
	mov	bx,ED_PATH		; assume we have a problem
					; BX = ED_PATH ready for error

	mov	si,2[bp]		; SI -> parameter block
	lds	si,ds:2[si]		; DS:SI -> ASCIIZ string
	cmp	ds:word ptr 1[si],'=:'	; 'd:=' specification?
	 je	redir_chdir40

	push 	ss
	pop 	ds			; DS = PCMODE

	cmp	word ptr current_ldt,-1
	 je	redir_chdir40		; we reject any chdir of the form
					; "\\server\path"
	mov	ax,I2F_CHDIR
	call	int2f_ldt		; is this a valid path ?
	 jc	redir_chdir30
	push 	ds
	pop 	es
	mov	si,offset pri_pathname

; DGM - don't allow path greater than 66 chars
	mov	cx, LDT_FLAGS-LDT_NAME	; calculate max pathlen from LDT
	mov	di, si
	xor	ax,ax
	repne	scasb
	mov	ax, ED_PATH		; assume path too long
	 jne	redir_chdir30		; jump if path too long

	les	di,current_ldt		; ES:DI -> path for this drive
	call	copy_asciiz		; copy new path to LDT current dir
	xor	ax,ax			; no errors
redir_chdir30:
	xchg	ax,bx			; return result in BX
redir_chdir40:
	pop	ds
	ret


;	CREATE FILE (CREAT)

;	+----+----+----+----+----+----+----+----+
;	|    3C   |        name       |  mode   |
;	+----+----+----+----+----+----+----+----+

;	entry:
;	------
;	name:	segmented address of ASCIIZ name
;   mode:   attribute for file

;	exit:
;	-----
;	BX:	file handle or error code ( < 0)


redir_creat:
	call	get_attrib_mode		; AX = mode, CX = attrib
	xchg	ax,cx
	or	ax,20h			; set the ARCHIVE bit on create
	mov	file_attrib,ax
	mov	int2f_stack,ax		; attrib on stack
	mov	int2f_cmd,I2F_CREATE
	cmp	word ptr current_ldt,-1	; valid LDT ?
	 jne	redir_creat10		; no, modify create function
	mov	int2f_cmd,I2F_XCREATE
redir_creat10:
	jmp	redir_open_create_common

;	OPEN FILE (OPEN)

;	+----+----+----+----+----+----+----+----+----+----+
;	|    3D   |        name       |  mode   |  attrib |
;	+----+----+----+----+----+----+----+----+----+----+

;	entry:
;	------
;	name:	segmented address of ASCIIZ name
;   mode:   open mode 
;	attrib:	file attrib for search (default = 16h)

;	exit:
;	-----
;	BX:	file handle or error code ( < 0)

redir_open:
;----------
;
	call	get_attrib_mode		; AX = mode, CX = attrib
	and	ax,7fh			; remove inheritance bit
	mov	int2f_stack,ax
	mov	int2f_cmd,I2F_OPEN
redir_open_create_common:
	call	find_xfn		; get external file handle in DI
	mov	bx,ED_HANDLE		;  assume no handles
	 jc	redir_open20
	push	di
	call	redir_openfile		; now do the open
	pop	di
	 jc	redir_open20
; On Entry:
;	AL = IFN
;	DI = XFN
;	ES:BX -> DHNDL_
; On Exit:
;	PSP fixed up
;
	mov	bx,di
	call	get_xftptr		; ES:DI -> XFN table
	 jc	redir_open10		; no PSP, skip xfn stuff
	add	di,bx			; add external file #
	stosb				; update table entry
	ret

redir_open10:
	xchg	ax,bx			; no PSP, return XFN in BX
redir_open20:
	ret


redir_openfile:
;--------------
; On Entry:
;	pri_pathname and file_attrib have been set up
; On Exit:
;	AL = IFN
;	ES:BX = DHNDL_
;	CY set on error, BX = error code
; We should set up COUNT, MODE, UID, PSP, and SHARE
	call	find_dhndl		; find DHNDL_
	 jc	redir_openf40		; return if a problem with this
	push	ax			; save IFN
	push 	es
	push 	bx			; save DHNDL_

	mov	ax,file_mode
	and	al,not DHM_LOCAL
	mov	es:DHNDL_MODE[bx],ax	; save mode in DOSHNDL
	mov	es:DHNDL_SHARE[bx],0	; zero share record

	mov	ax,int2f_cmd		; either open or create
	call	int2f_dhndl		; lets try the command

	pop 	bx
	pop 	es			; recover DHNDL_
	pop	dx			; recover IFN
	 jc	redir_openf30		; on error discard the handle
	xchg	ax,dx			; return AL = IFN
	mov	es:DHNDL_COUNT[bx],1	; handle now properly in use
	mov	cx,file_mode
	test	ch,DHM_FCB/256		; is this an FCB open ?
	 jz	redir_openf10
	or	es:byte ptr DHNDL_MODE+1[bx],DHM_FCB/100h
redir_openf10:
	test	cl,DHM_LOCAL		; is it a "private" file ?
	 jz	redir_openf20
	or	es:byte ptr DHNDL_WATTR+1[bx],DHAT_LOCAL/100h
redir_openf20:
	ret

redir_openf30:
	xchg	ax,bx			;  returning error in BX
	ret

redir_openf40:
	mov	bx,ED_HANDLE		; no handles are left
	ret

;	CLOSE FILE (CLOSE)

;	+----+----+----+----+
;	|    3E   |  handle |
;	+----+----+----+----+

;	entry:
;	------
;	handle:	open file handle to be closed

;	exit:
;	-----
;	BX:	0000 or error code ( < 0)

redir_close:
;------------
;
	mov	si,2[bp]		; SI -> parameter block
	mov	ax,2[si]		; get external file #
	call	get_xftptr		; ES:DI -> xft table
	 jc	redir_close10
	add	di,ax			; add in XFN
	mov	ax,0FFh			; get "unused" value for XFT
	xchg	al,es:[di]		; release file & get internal #
redir_close10:				; we can now do the actual close
	call	ifn2dhndl		; ES:BX -> DHNDL_
	 jc	redir_close30		;  exit if error occurrs
    mov ax,es:DHNDL_COUNT[bx]   
	mov	ah,3eh			;  count, AH = 3E
	push	ax
	mov	ax,I2F_CLOSE
	call	int2f_dhndl		; close it
	pop	bx
	 jnc	redir_close20		; errors ?
	xchg	ax,bx			; recover return code
redir_close20:
	ret
redir_close30:
	mov	bx,ED_H_MATCH		; assume invalid IFN
	ret

;	READ FROM FILE (READ)

;	+----+----+----+----+----+----+----+----+----+----+
;	|    3F   |  handle |       buffer      |  count  |
;	+----+----+----+----+----+----+----+----+----+----+

;	entry:
;	------
;	handle:	open file handle
;	buffer:	buffer to read into
;	count:	max. number of bytes to read

;	exit:
;	-----
;	BX:	error code ( < 0)

redir_read:
;----------
	mov	ax,I2F_READ
redir_rw_handle:
	mov	si,2[bp]		; SI -> parameter block
	mov	cx,8[si]		; CX = Count
	push	ds
	lds	dx,4[si]		; DS:DX = DMA address
	call	redir_rw
	pop	ds
	mov	si,2[bp]		; SI -> parameter block
	mov	8[si],cx		; CX = Count
	ret

;	WRITE TO FILE (WRITE)

;	+----+----+----+----+----+----+----+----+----+----+
;	|    40   |  handle |       buffer      |  count  |
;	+----+----+----+----+----+----+----+----+----+----+

;	entry:
;	------
;	handle:	open file handle
;	buffer:	buffer to be wriiten
;	count:	max. number of bytes to write

;	exit:
;	-----
;	BX:	error code ( < 0)

redir_write:
;-----------
	mov	ax,I2F_WRITE
	jmp	redir_rw_handle

redir_rw:
;--------
; On Entry:
;	AX = command code
;	ES:BX = DHNDL_
;	CX = count
;	DS:DX = buffer
; On Exit:
;	CX = count transferred
;	BX = zero or error code
;
	cmp	ax,I2F_WRITE		; is it a write ?
	 jne	redir_rw10
	and	es:DHNDL_WATTR[bx],not (DHAT_CLEAN+DHAT_TIMEOK)
redir_rw10:
	push	ss:dma_offset
	push	ss:dma_segment
	push	cx
	mov	cl,4
	mov	di,dx			; save dma offset
	and	dx,15			; make offset within para
	shr	di,cl			; convert offset to para offset
	mov	si,ds			; add to segment
	add	di,si			; DI:DX -> DMA address
	 ja	redir_rw15		; are we within normal TPA ?
	inc	di			; no adjust to offset within
	shl	di,cl			;  magic segment FFFF
	add	dx,di
	mov	di,0ffffh		; use magic segment
redir_rw15:
	pop	cx
	mov	ss:dma_offset,dx	; save for xfer
	mov	ss:dma_segment,di
	call	int2f_dhndl		; try the xfer
	pop	ss:dma_segment
	pop	ss:dma_offset
	mov	bx,0			; assume no error
	 jnc	redir_rw20
	xchg	ax,bx			; return error code
	cmp	bx,ED_LOCKFAIL		; is it a lockfail error ?
	 jne	redir_rw20		; no, just return it
	les	di,ss:current_dhndl	; compatibility modes should generate
	test	es:DHNDL_MODE[di],DHM_SHAREMSK
	 jz	redir_rw20		;  critical errors fro ED_LOCKFAIL
	mov	bx,ED_ACCESS		; sharing modes return access denied
redir_rw20:
	ret
	

;	DELETE FILE (UNLINK)

;	+----+----+----+----+----+----+
;	|    41   |        name       |
;	+----+----+----+----+----+----+

;	entry:
;	------
;	name:	segmented address of ASCIIZ name

;	exit:
;	-----
;	BX:	0000 or error code ( < 0)


redir_unlink:
	mov	ax,I2F_DEL		; it's a delete
;	mov	file_attrib,6		; only delete files
redir_unlink_move_common:
	push	ax
	call	get_attrib_mode		; allow overrides for server calls
	pop	ax
	jmp	redir_pathop_common

;	GET/SET FILE POSITION (LSEEK)

;	+----+----+----+----+----+----+----+----+----+----+
;	|    42   |  handle |       offset      |  method |
;	+----+----+----+----+----+----+----+----+----+----+

; On Entry:
;	ES:BX = DHDNL_
;	method:	0 = begin, 1 = current, 2 = end of file
;
; On Exit:
;	BX = Error Code, offset updated with new value
;

redir_lseek:
;-----------
	mov	di,bx			; ES:DI -> DHNDL_
	mov	si,2[bp]		; SI -> parameter block
	mov	dx,4[si]		; get 32-bit file offset
	mov	cx,6[si]		; into CX,DX
	mov	ax,8[si]		; get seek mode
	test	ax,ax
	 jz	redir_lseek20		; seek from beginning
	dec	ax
	 jz	redir_lseek10		; seek from current position
	dec	ax
	 jz	redir_lseek30		; seek from end
	mov	bx,ED_DATA		; else invalid seek mode
	ret

redir_lseek10:				; seek mode 1: relative to position
;	add	dx,es:DHNDL_POSLO[di]	; add position + offset
;	adc	cx,es:DHNDL_POSHI[di]
	add	es:DHNDL_POSLO[di],dx
	adc	es:DHNDL_POSHI[di],cx
	adc	es:DHNDL_POSXLO[di],0
	adc	es:DHNDL_POSXHI[di],0
	test	cx,8000h		; negative offset?
	 jz	redir_lseek12
	add	es:DHNDL_POSXLO[di],0ffffh; yes, then extend the sign to 64-bit
	adc	es:DHNDL_POSXHI[di],0ffffh
redir_lseek12:
	cmp	es:DHNDL_POSXLO[di],0
	 jne	redir_lseek15
	cmp	es:DHNDL_POSXHI[di],0
	 je	redir_lseek17
redir_lseek15:
	cmp	es:DHNDL_POSXLO[di],0ffffh
	 jne	redir_lseek16
	cmp	es:DHNDL_POSXHI[di],0ffffh
	 je	redir_lseek17
redir_lseek16:
	xor	dx,dx
	dec	dx
	mov	cx,dx
	jmp	redir_lseek90
redir_lseek17:
	mov	dx,es:DHNDL_POSLO[di]
	mov	cx,es:DHNDL_POSHI[di]
	jmp	redir_lseek90

redir_lseek20:				; seek mode 0: set absolute position
	mov	es:DHNDL_POSLO[di],dx	; set new file offset
	mov	es:DHNDL_POSHI[di],cx	; SI = error code/0 at this point
	mov	es:DHNDL_POSXLO[di],ax
	mov	es:DHNDL_POSXHI[di],ax
;	jmp	redir_lseek90

redir_lseek90:
	mov	4[si],dx		; set 32-bit file offset
	mov	6[si],cx		; for return
	xchg	ax,bx			; error code in BX
	ret

redir_lseek30:				; seek mode 2: relative to end
	mov	bx,es:DHNDL_MODE[di]	; ask MSNET if anyone else can write
	and	bl,DHM_SHAREMSK		; isolate sharing bits
	cmp	bl,DHM_DENY_READ	; Only DENY_READ and DENY_NONE a
	 jb	redir_lseek40		;  problem - others might write to
	push	si			;  the file so we must ask the server
					;  how long the file is now
	mov	ax,I2F_LSEEK		; CX:DX = position now
	call	int2f_dhndl		; do a remote seek
	pop	si			; DX:AX = EOF relative position
	 jc	redir_lseek90		; (unless we have an error)
	xchg	ax,dx			; AX:DX = new EOF relative position
	xchg	ax,cx			;  and finally get into CX:DX 
	xor	ax,ax			; no problems...
	;jmp	redir_lseek90		; MYST-removed,file offset wasn't updated
	jmp	redir_lseek20		; MYST-added,go and update the new file offset.
redir_lseek40:
	add	dx,es:DHNDL_SIZELO[di]	; add file size + offset
	adc	cx,es:DHNDL_SIZEHI[di]
	xor	ax,ax
	jmp	redir_lseek20


;	GET/SET FILE ATTRIBUTES (CHMOD)

;	+----+----+----+----+----+----+----+----+----+----+
;	|    43   |        name       |   flag  | attrib  |
;	+----+----+----+----+----+----+----+----+----+----+
;	|        size       |
;	+----+----+----+----+

;	entry:
;	------
;	name:	pointer to ASCIIZ file name
;	flag:	0 = get attribute,
;		1 = set attribute,
;	      2-5 = passwords (ignored)
;	attrib:	new attribute if flag = 1
;		password mode if flag = 3
;	
;	exit:
;	-----
;	BX:	0000 or error code ( < 0)
;	attrib:	file's attribute if flag = 0
;	size:	file's size

redir_chmod:
;-----------
;
	mov	bx,2[bp]		; BX -> parameter block
	mov	cx,8[bx]		; get attribs
	mov	bx,6[bx]		; get access flag
	mov	ax,I2F_SET_ATTR		; assume it's a set
	cmp	bl,1			; is it a set ?
	 je	redir_chmod10		; if not then
	mov	ax,I2F_GET_ATTR		; assume it's a get
	mov	cx,16h			;  with everything attribs
	 jb	redir_chmod10		;  was it ?
	mov	ax,ED_ACCESS		; no, return access denied
	jmp	redir_chmod20		;  cause it DR password stuff
redir_chmod10:
	mov	int2f_stack,cx		; attribs on the stack
	call	int2f_ldt		; do the Int 2F
	 jc	redir_chmod20
	mov	si,2[bp]		; SI -> parameter block
	mov	8[si],ax		;  return attribute
	mov	10[si],di
	mov	12[si],bx
	xor	ax,ax			;  success
redir_chmod20:
	xchg	ax,bx			; return result in BX
	ret

;	GET DISK PARAMETER BLOCK

;	+----+----+----+----+----+----+----+----+----+----+
;	|    48   |  drive  |        dpb        | adjust  |
;	+----+----+----+----+----+----+----+----+----+----+

;	entry:
;	------
;	drive:	drive to get information about

;	exit:
;	-----
;	BX:	0000 or error code ( < 0)
;	dpb:	address of DOS DPB (offset/segment)
;	adjust:	delwatch adjustment of free space

; NB. We only fill in the fields required by the Disk Free Space call.

redir_getdpb:
;------------
	mov	ax,I2F_SPACE
	call	int2f_ldt		; get the info
	 jnc	redir_getdpb10		; if we get an error then make CLMSK=FE
    mov al,0ffh        
redir_getdpb10:        
	mov	si,offset sec_pathname	; let's re-use this as a temp DPB
	dec	al			; make cluster mask
	mov	ds:DDSC_CLMSK[si],al	; and stuff into DPB
	mov	ds:DDSC_FREE[si],dx
	mov	ds:DDSC_SECSIZE[si],cx
	inc	bx			; inc number of clusters
	mov	ds:DDSC_NCLSTRS[si],bx
	mov	al,err_drv		; also fill in drive number
	mov	ds:DDSC_UNIT[si],al
	mov	si,2[bp]		; DI -> parameter block
	mov	4[si],offset sec_pathname
	mov	6[si],ds		; point to my dummy DPB
	mov	word ptr 8[si],0	; zero adjust value
	mov	bx,0ffh			; return 0xFF (ie. bad drive)
	ret

;	FIND FIRST FILE

;	+----+----+----+----+----+----+----+----+----+----+
;	|    4E   |        name       |  *****  |  attrib |
;	+----+----+----+----+----+----+----+----+----+----+

;	entry:
;	------
;	name:	pointer to ASCIIZ file name
;	attrib:	attribute to be used in search
;	
;	exit:
;	-----
;	BX:	0001 or error code ( < 0)

;	Note:	This call returns matching files in
;		the current DMA address and also saves
;		the BDOS state in the there.
;		
;		If there is space for multiple file names we
;		could return as many as will fit into the DTA
;		but it's easier just to return 1 file
;

redir_first:	; 13-find first matching file
;----------
; ONLY 1 file returned for now.....
;
	call	get_attrib_mode		; AX = mode, CX = attrib
	mov	ax,I2F_SFIRST		; srch first, valid LDT
	les	di,current_ldt
	cmp	di,-1		; valid LDT ?
	 jne	redir_first10
	mov	ax,I2F_XSFIRST		; srch first, no valid LDT
redir_first10:
	jmp	srch_buf_common

;	FIND NEXT FILE

;	+----+----+
;	|    4F   |
;	+----+----+
;
;	entry:
;	------
;	
;	exit:
;	-----
;	BX:	0000 or error code ( < 0)

;	Note:	This call returns matching files in
;		the current DMA address and also saves
;		the BDOS state in the there.

redir_next:	; 14-find next matching file
;---------
; ONLY 1 file returned for now.....
;
	push 	ss
	pop 	es
	mov	di,offset srch_buf	; point ES:DI -> search buffer
	mov	ax,I2F_SNEXT
srch_buf_common:
	push	dma_offset
	push	dma_segment
	mov	dma_offset,offset srch_buf
	mov	dma_segment,ds
	call	int2f_op

	pop	dma_segment
	pop	dma_offset
	 jc	srch_buf_common10
	call	redir_save_srch_state	; if no error save state
	xor	ax,ax			;  return AX = 1 file found
srch_buf_common10:
	xchg	ax,bx			; return code in BX
	ret


redir_save_srch_state:
; On entry DS=PCMODE
	les	di,dword ptr dma_offset	; ES:DI -> search state in DMA address
	
	mov	si,offset srch_buf
	mov	cx,21			; save 1st 21 bytes
	rep	movsb

	push	si			; save name/ext
	add	si,11			; skip to name/ext
	movsb				; copy the attribute
	add	si,10			; skip reserved bytes
	movsw				; copy the time
	movsw				; copy the date
	inc	si  			; skip starting cluster
	inc	si
	movsw				; copy the file size
	movsw
	pop	bx			; recover name
	jmp	unparse			; unparse the name

; Restore DOS search area from user DTA
;
redir_restore_srch_state:
;------------------------
; On Entry:
;	DS = SYSDAT
; On Exit:
;	AL = 1st byte of srch buf
;	DS preserved
;
	push	ss
	pop	es
	mov	di,offset srch_buf	; ES:DI -> internal state
	push	ds
	lds	si,ss:dword ptr dma_offset
	lodsb				; DS:SI -> search state in DMA address
	stosb
	mov	cx,10			; copy 1st 20 bytes (21 counting previous stosb)
	rep	movsw
	pop	ds
	ret

;	COMMIT FILE (COMMIT)

;	+----+----+----+----+
;	|    50   |  handle |
;	+----+----+----+----+

;	entry:
;	------
;	handle:	open file handle to be flushed

;	exit:
;	-----
;	BX:	0000 or error code ( < 0)

redir_commit:
	test	es:DHNDL_MODE[bx],DHM_WO+DHM_RW
	 jz	redir_commit10		;  we don't need to commit it
	mov	ax,I2F_COMMIT
	call	int2f_dhndl		; commit this file
	 jc	redir_commit20
redir_commit10:
	xor	ax,ax			; success
redir_commit20:
	xchg	ax,bx			; return result in BX
	ret


;	CREATE NEW FILE

;	+----+----+----+----+----+----+----+----+
;	|    51   |        name       |  mode   |
;	+----+----+----+----+----+----+----+----+

;	entry:
;	------
;	name:	segmented address of ASCIIZ name
;   mode:   attribute for file 

;	exit:
;	-----
;	BX:	file handle or error code ( < 0)

;	Note:	The function is identical to CREATE FILE
;		with the exception that an error is returned
;		if the specified file already exists.

redir_mknew:
	call	get_attrib_mode		; AX = mode, CX = attrib
	xchg	ax,cx
	or	ax,120h			; set ARCHIVE + MKNEW bits
	mov	file_attrib,ax
	mov	int2f_stack,ax
	mov	int2f_cmd,I2F_CREATE
	mov	file_mode,DHM_RW	; Open Compatibility mode, Read/Write
	jmp	redir_open_create_common

;	LOCK/UNLOCK FILE DATA (LOCK/UNLOCK)

;	+----+----+----+----+----+----+----+----+
;	|    52   |  handle |       offset      |
;	+----+----+----+----+----+----+----+----+
;	|       length      |   lock  |
;	+----+----+----+----+----+----+

;	entry:
;	------
;	handle:	open file handle
;	offset:	long integer offset
;	length:	long integer byte count
;	lock:	0 = lock, 1 = unlock

;	exit:
;	-----
;	BX:	byte count or error code ( < 0)

redir_lock:
; Lock uses I2F_LOCK, with CX,DX,SI as per INT 21, DI on stack
; Unlock uses I2F_UNLOCK with same.
	mov	bx,2[bp]		; BX -> parameter block
	push	bp
	lea	bp,4[bx]		; BP -> parameter block 
	mov	dx,bp			; as does DX
	mov	ax,I2F_LOCK
	mov	bl,ds:byte ptr 12[bx]
	mov	bh,5Ch			; lock/unlock in BX
	call	int2f_dhndl		; try the operation
	pop	bp
	 jc	redir_lock20
	xor	ax,ax			; success
redir_lock20:
	xchg	ax,bx			; return result in BX
	ret


;	EXPAND FILE

;	+----+----+----+----+----+----+----+----+----+----+
;	|    55   |      old name     |      new name     |
;	+----+----+----+----+----+----+----+----+----+----+

;	entry:
;	------
;	old name:	segmented address of ASCIIZ name
;	new name:	segmented address of ASCIIZ name

;	exit:
;	-----
;	BX:	0000 or error code ( < 0)

; If we got here pri_pathname already contains expanded name - just copy it
; back to the users buffer.

redir_expand:
;------------
	mov	si,2[bp]		; SI -> parameter block
	les	di,10[si]		; ES:DI -> user supplied name
	mov	si,offset pri_pathname
	call	copy_asciiz
	xor	bx,bx			; no errors
	ret

;	RENAME FILE

;	+----+----+----+----+----+----+----+----+----+----+
;	|    56   |      old name     |      new name     |
;	+----+----+----+----+----+----+----+----+----+----+

;	entry:
;	------
;	old name:	segmented address of ASCIIZ name
;	new name:	segmented address of ASCIIZ name

;	exit:
;	-----
;	BX:	0000 or error code ( < 0)

;	Note:	R/O files can be renamed.
;			  ---

redir_move:
	mov	ax,I2F_REN		; it's a rename
	jmp	redir_unlink_move_common

;	GET/SET FILE DATE/TIME

;	+----+----+----+----+----+----+----+----+----+----+
;	|    57   |  handle |   mode  |   date  |   time  |
;	+----+----+----+----+----+----+----+----+----+----+

;	entry:
;	------
;	handle:	open file handle
;	mode:	0 = get date/time, 1 = set date/time
;	date:	date as in directory FCB
;	time:	time as in directory FCB

;	exit:
;	-----
;	BX:	0000 or error code ( < 0)
;	date:	date of last modification if mode = 0
;	time:	date of last modification if mode = 0

redir_dattim:
;------------
	mov	si,2[bp]		; DS:SI -> param block
	cmp	ds:word ptr 4[si],1	; is it set ?
	 ja	redir_dattim30		; if illegal say so
	 je	redir_dattim10
	mov	ax,es:DHNDL_DATE[bx]	; we need to copy the file date
	mov	word ptr 6[si],ax	;  into the parameter block
	mov	ax,es:DHNDL_TIME[bx]
	mov	word ptr 8[si],ax	; and the time	
	jmp	redir_dattim20
redir_dattim10:
	mov	ax,word ptr 6[si]	; copy the date we are given
	mov	es:DHNDL_DATE[bx],ax	;  into the DOSHNDL
	mov	ax,word ptr 8[si]	; and the time	
	mov	es:DHNDL_TIME[bx],ax
	or	es:DHNDL_WATTR[bx],DHAT_TIMEOK
	and	es:DHNDL_WATTR[bx],not DHAT_CLEAN
redir_dattim20:
	xor	bx,bx			;  all went OK
	jmp	redir_dattim40
redir_dattim30:
	mov	bx,ED_FUNCTION		; bad function number
redir_dattim40:
	ret

	Public	redir_build_path

; AH contains state of path processing, and is normally zero

BP_DOT		equ	1	; we have had a DOT end are processing the .EXT
BP_WILD		equ	2	; we have encountered a wild card
BP_BSLASH	equ	4	; the last character was a BSLASH

; May be called with or without MXDisk

redir_build_path:
;----------------
; On Entry:
;	DS:SI -> source name
;	ES:DI -> destination name (in PCMODE data segment)
;	current_ldt -> LDT_ for specified drive
; On Exit:
;	CY clear if we could build the path
;
; firstly we discard any drive portion
	lodsw				; get 1st two characters
	cmp	ah,':'			; is a drive specified ?
	 jne	redir_bp10		; discard "d:" if so
	lodsw
redir_bp10:
; Is it a "\\server\sharename\subdir\filename.ext" format ?
	call	check_dslash		; if it is \\
	 je	redir_bp20		;  then just copy the lot
; it's a normal "A:\subdir\filename.ext" pathname format
	dec	si			; we have swallowed the 1st two
	dec	si			;  chars - now we change our mind
	push 	ds
	push 	si
	lds	si,es:current_ldt
	mov	cx,ds:LDT_ROOTLEN[si]	; copy the root portion of the name
	rep	movsb			; copy the server stub name
	mov	dx,di			; ES:DX -> root position
	call	check_slash		; do we start from the root ?
	 je	redir_bp11		; yes, then that's all
	call	copy_asciiz		; no, copy the rest of the path
	call	redir_bp_append_slash	; append '\' for our path processing
redir_bp11:
	pop 	si
	pop 	ds
	jmp	redir_bp_next_level	; continue processing given path

redir_bp20:
; It is a "\\server\sharename\subdir\filename.ext" format
	stosw				; copy the "\\"
	xor	ax,ax			; clear "flags" in AH
redir_bp21:
	lodsb				; work along the name
	test	al,al			; unexpected end of name ?
	 jz	redir_bp_exit20		; go with what we've got....
	call	check_slash		; have we found the root '\' ?
	 je	redir_bp23
ifdef KANJI
	call	dbcs_lead		; is it the 1st of a kanji pair
	 jne	redir_bp22		; no, onto next char
	stosb				; copy the 1st character
	movsb				; copy 2nd byte of KANJI pair
	jmp	redir_bp21		; now we can move onto next char
redir_bp22:
endif
	call	toupper			; upper case the character
	stosb				; copy the character
	jmp	redir_bp21		; go and do another one

redir_bp23:
	mov	dx,di			; bodge root to the top
;	mov	al,'\'
	stosb				; put in a '\'
	jmp	redir_bp_next_level	; yes, this is the new "root"

; We have reached the terminating NUL
redir_bp_exit:
	test	ah,BP_WILD		; did we get any wildcards ?
	 je	redir_bp_exit10
	mov	si,2[bp]		; SS:SI -> parameter block
	mov	al,ss:[si]		; fdos code number
	cmp	al,MS_X_FIRST		; search first ?
	 je	redir_bp_exit10
	cmp	al,FD_EXPAND		; expand pathname
	 je	redir_bp_exit10
	cmp	ss:remote_call,0	; should we wildcard REN/DEL ?
	 je	redir_bp_ED_PATH	; reject as not allowed here
	cmp	al,MS_X_RENAME		; rename ?
	 je	redir_bp_exit10
	cmp	al,MS_X_UNLINK		; delete ?
	 jne	redir_bp_ED_PATH	; reject as not allowed here
redir_bp_exit10:
	xor	al,al			; make sure our string is zero
	stosb				;  terminated
	call	redir_bp_append_slash	; append a trailing '\' if we don't
	dec	di			;  have one so we can remove it
	cmp	di,dx			; are we talking about the root ?
	 jne	redir_bp_exit20
	cmp	es:byte ptr [di-1],':'
	 jne	redir_bp_exit20		; if we have a trailing ':' allow
	inc	di			;  a '\' at the root
redir_bp_exit20:
	xor	al,al			;  KANJI aware way of removing trailing
	stosb				;  '\' from the path....
;	clc
	ret


redir_bp_next_level:
; DS:SI -> source pathname, ES:DI -> destination pathname, ES:DX -> root
; AH = current status
	mov	cx,8			; expansion count ready
	xor	ax,ax
redir_bp_next_char:
	lodsb
	test	al,al			; end of the line ?
	 jz	redir_bp_exit		; do the exit

; Is it a '\' ?
redir_bp40:
	call	check_slash		; was it a seperator ?
	 jne	redir_bp50
	test	ah,BP_WILD		; have we encountered wildcards ?
	 jnz	redir_bp_ED_PATH	; reject as not allowed here
	mov	al,'\'			; make sure it's a BSLASH
	stosb
	jmp	redir_bp_next_level	; start at a new level

; Is it a '.' ?
redir_bp50:
	cmp	al,'.'			; seperator ?
	 jne	redir_bp60
	lodsb				; get next letter
	test	al,al			; is it trailing '.' ?
	 je	redir_bp_exit		;  then exit now
	cmp	cx,8			; check for '.' and '..'
	 je	redir_bp52		;  if at start of field
redir_bp51:				; othewise it's a ".EXT"
	mov	bx,ED_FILE		; assume we have a problem
	test	ah,BP_DOT		; have we had an extention before ?
	 jnz	redir_bp_err		;  we've got a problem
	dec	si			; rewind a character
	mov	ax,'.'+256*BP_DOT	; so we are back to the '.'
	stosb				; store the '.' in destination
	mov	cx,3			; expand the extention
	jmp	redir_bp_next_char
redir_bp52:				; It might be a "." or ".."
	call	check_slash		; is it '.\'
	 je	redir_bp_next_char	; discard them both
	cmp	al,'.'			; is it '..' ?
	 jne	redir_bp51		; no, must be an extention after all
	call	redir_bp_ddot		; rewind a level
	 jnc	redir_bp_next_level	; onto next level
redir_bp_ED_PATH:
; set CY flag to indicate error then return
	mov	bx,ED_PATH		; return "invalid path" error
redir_bp_err:
	stc
	ret
	
; Is it a '*' ?
redir_bp60:
	call	check_delim		; is it a delimiter ?
	 jz	redir_bp_ED_PATH	; thats illegal at this point
	cmp	al,'*'			; wildcards ?
	 jne	redir_bp70
	mov	al,'?'
	rep	stosb			; expand it
;	or	ah,BP_WILD		; remember wild-card encountered
;	jmp	redir_bp_next_char	;  check for wildcards
;
;	 				; we can just fall through
;
redir_bp70:
	cmp	al,'?'			; wild card is possibly OK
	 jne	redir_bp80
	or	ah,BP_WILD		; remember wild-card encountered
redir_bp80:
; Normal Character
; AL contains a normal character for us to process.
; Uppercase the character, look out for KANJI etc
	 jcxz	redir_bp_next_char	; discard if no space is left
	dec	cx			; one less to expand
ifdef KANJI
	call	dbcs_lead		; is it the 1st of a kanji pair
	 jne	redir_bp90
	inc	si			; skip 2nd byte
	 jcxz	redir_bp_next_char	; discard if no room for kanji char
	dec	cx			; one less to expand
	stosb				; store 1st byte of kanji character
	dec	si			; point at 2nd byte again
	movsb				; copy 2nd byte of kanji character
	jmp	redir_bp_next_char
redir_bp90:
endif
	call	toupper			; make it upper case
	stosb				; plant the character
	jmp	redir_bp_next_char


redir_bp_ddot:
; We have encountered a '..' in a pathname, so rewind up a level
; On Entry:
; DS:SI -> source position, ES:DI -> destination position
; ES:DX -> root position, AL = Character
; On Exit:
; ES:DI -> start of field one level up, unless we get an error when CY set.
	lodsb				; look at char after '..'
	call	check_slash		; is it '..\'
	 je	redir_bp_ddot10
	test	al,al			; is it a trailing '..'
	 jnz	redir_bp_ED_PATH	; no, anything else is bad...
	dec	si			; trailing '..', rewind to NUL
redir_bp_ddot10:
	dec	di			; move back to last '\'
	cmp	di,dx			; are we at the root anyway ?
	 jle	redir_bp_ED_PATH	;  then don't discard any
; We now start at ES:DX and work along till ES:DI -> char after last '\'
	push 	ds
	push 	si
	push 	es
	pop 	ds
	mov	si,dx			; DS:SI -> char after root
	mov	cx,dx			; last '\' position in CX
redir_bp_ddot20:
	lodsb
	cmp	si,di			; end of the line yet ?
	 jae	redir_bp_ddot30		; yes, stop now
ifdef KANJI
	call	dbcs_lead		; is it 1st of a kanji pair ?
	 jne	redir_bp_ddot25
	lodsb				; skip the 2nd too
	jmp	redir_bp_ddot20		; then go on to next char
redir_bp_ddot25:
endif
	call	check_slash		; is it a '\'
	 jne	redir_bp_ddot20		; no, do next
	mov	cx,si			; save position after the '\'
	jmp	redir_bp_ddot20
redir_bp_ddot30:
	mov	di,cx			; last '\' was here..
	pop 	si
	pop 	ds
	clc				; no errors
	ret

redir_bp_append_slash:	
; On Entry:
;	ES:DX -> ASCIIZ string to append a '\' to
; On Exit:
;	ES:DI -> terminating NUL
;	All but AX preserved
;
	xor	ax,ax			; AH = 0, initially no previous char
	mov	di,dx			; start processing from here
redir_bp_append_slash10:
	mov	ah,al			; save previous char in AH
	mov	al,es:[di]		; get a character
	inc	di			; point to next
	test	al,al			; is it NUL ?
ifdef KANJI
	 je	redir_bp_append_slash20
	call	dbcs_lead		; is it 1st of a kanji pair ?
	 jne	redir_bp_append_slash10
	inc	di			; skip the 2nd too
	jmp	redir_bp_append_slash10	;  (it might be '\')
redir_bp_append_slash20:
else
	 jnz	redir_bp_append_slash10
endif
	mov	al,ah			; get previous char
	call	check_slash		; did we have a '\' ?
	 je	redir_bp_append_slash30
	dec	di			; ES:DI -> existing NUL
	mov	ax,'\'
	stosw				; new terminating '\'
redir_bp_append_slash30:
	dec	di			; ES:DI -> NUL
	ret



get_attrib_mode:
;---------------
; On Entry:
;	SS:2[BP] -> param block
; On Exit:
;	AX = file mode
;	CX = file attributes
;
	mov	si,2[bp]		; SI -> parameter block
	mov	ax,ds:6[si]		; get mode
	mov	cx,ds:8[si]		; get attribs
	mov	file_mode,ax		; save open mode
	mov	file_attrib,cx		; save file attribute
	ret

int2f_ldt:
;---------
; On Entry:
;	AX = Int2F command
; On Exit:
;	CY clear, AX returned unchanged
;	CY set, AX = Our Negative Error Code
;
	les	di,ss:current_ldt
	jmp	int2f_op

int2f_dhndl:
;----------
; On Entry:
;	AX = Int2F command
; On Exit:
;	CY clear, AX returned unchanged
;	CY set, AX = Our Negative Error Code
;
	les	di,ss:current_dhndl
int2f_op:
	push	ds
	push 	ss
	pop 	ds
	push	int2f_stack		; put word on stack
	int	2fh			; get the info
	pop	int2f_stack		; clean up the stack
	pop	ds
	 jnc	int2f_op10
	neg	ax			; AX = we keep error codes negative
;	stc				; we have a problem
int2f_op10:
	ret
BDOS_CODE	ends

end
