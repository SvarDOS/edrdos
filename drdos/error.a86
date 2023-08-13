;    File              : $ERROR.A86$
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
;    ERROR.A86 1.17 94/12/02 11:01:03
;    added logical error entry 
;    ERROR.A86 1.16 93/11/26 15:51:29 
;    Update char_error so ES:SI -> device driver header itself
;    ERROR.A86 1.14 93/09/09 22:36:26
;    Int 21/59 uses error stack (for benefit of Lantastic)
;    ERROR.A86 1.13 93/09/03 20:28:11
;    Add "no critical errors" support (int 21/6C)
;    ENDLOG
;
;	This file contains the Error handling routines for PCMODE
;	When a function encounters an error it jumps to the ERROR_EXIT
;	function which will process the error consistantly. FCB_ERROR_EXIT
;	is a special case of ERROR_EXIT where the error code is not returned
;	directly to the user but is still saved for func59
;

	include pcmode.equ
	include	fdos.def
	include i:msdos.equ
	include i:mserror.equ
	include i:psp.def
	include	i:char.def
	include	i:reqhdr.equ

;
ERR_TBL_CODE	equ	byte ptr 0	; Error Code in Table
ERR_TBL_CLASS	equ	byte ptr 1	; Error Class entry in Table
ERR_TBL_ACTION	equ	byte ptr 2	; Error Action entry in Table
ERR_TBL_LOCUS	equ	byte ptr 3	; Locus entry in table
ERR_TBL_LEN	equ	4		; 4 bytes per entry
;
PCM_CODE	CSEG	BYTE
	extrn	get_dseg:near
	extrn	do_int24:near
	extrn	reload_registers:near
	extrn	return_AX_CLC:near
;
;	*****************************
;	***    DOS Function 59    ***
;	***   Get Extended Error  ***
;	*****************************
;
	Public	func59

func59:
	les	di,error_dev		; Return device driver address
	mov	bh,error_class		; return the Error Class
	mov	bl,error_action		;        the Action Code
	mov	ch,error_locus		;        the Locus Code
	mov	ax,error_code		;        the Error Code
	
	lds	si,int21regs_ptr	; point to user stack
	mov	reg_ES[si],es
	mov	reg_DI[si],di
	mov	reg_BX[si],bx
	mov	reg_CX[si],cx
	push ss ! pop ds
	jmp	return_AX_CLC	

eject
;	On Entry:-	AX == Internal Error Number 
;
;	On Exit:-	None
;	CY set if error should be returned
;	CY clear if it should be ignored
;
	Public	error_exit
error_exit:
	cmp	internal_flag,0			; If this is an internal
	 jnz	error_ret			; do not generate a critical
	call	disk_error			; error
	 jnz	error_r10			; No Error Occured or Ignored
	ret					; in critcal error handler

;
;	Return the error code to the user and DO NOT generate any
;	critical errors.
;
;	On Entry:-	AX == Internal Error Number 
;
;	On Exit:-	None
;
	Public	error_ret
error_ret:
	call	set_error			; the internal error code
error_r10:					; otherwise negate
	les	di,int21regs_ptr
	or	es:reg_FLAGS[di],CARRY_FLAG	; set the "users" carry Flag
	stc					; also set real one
if offset reg_AX EQ 0
	stosw					; save return code
else
	mov	es:reg_AX[di],ax
endif
	ret

;
;	On Entry:-	AX == Internal Error Number 
;
;	On Exit:-	None
;
	Public	fcberror_exit
fcberror_exit:
	call	disk_error		; Process the error code generating
	 jz	fe_e10			;  a critical error is required
	mov	al,0FFh			; on FCB error return AL = FF
fe_e10:
	ret

eject
;	WARNING - may be called from FDOS with DS = SYSDAT
;
;	CHAR_ERROR is called when any character device function generates
;	an error. First CHAR_ERROR sets the correct parameters for Get 
;	Extended Error. Then it generates a Critical Error by calling
;	DO_INT24.
;
;	Entry:-		ES:SI	-> device driver header
;			SS:BX	-> RH_
;			AX	= RH_STATUS
;
;	Exit		AL	Error Action
;
	Public char_error
char_error:
	test	ss:valid_flg,NO_CRIT_ERRORS
	 jz	char_e10
	mov	al,ERR_FAIL		; no critical errors allowed
	ret				;  so just fail things
char_e10:
	push	ds
	push	es
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push ss ! pop ds		; DS -> our data now
	mov	word ptr error_dev+0,si	; save the device driver address
	mov	word ptr error_dev+2,es	;  and then initialise the FUNC59
	push	es			;  data areas
	and	ax,007Fh		; Mask the Unused Bits
	or	ah,80h+OK_RIF		; Retry/Ignore/Abort/Fail allowable
	cmp	ss:RH_CMD,CMD_OUTPUT	; is this a read or write failure ?
	 jne	char_e20
	inc	ah			; 01 is a Write Failure
char_e20:
	mov	rwmode,ah		;  
	push	ax			; save for int 24
	cbw				; zero AH again
	neg	ax			; convert to an internal error
	add	ax,ED_PROTECT		;  code for set_error
	mov	cl,LOC_CHAR
	call	set_error
	add	ax,ED_PROTECT		; convert to hardware error
	xchg	ax,di			; DI == hardware error
	pop	ax
	pop	es
	call	do_int24		;  execute INT 24
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	es
	pop	ds
	ret

eject
;
;	DISK_ERROR gains control after any DOS disk based function
;	has been executed which generates an error. First ERROR set the
;	correct parameters for Get Extended Error. Then it determines if
;	the current error should generate a Critical Error and calls 
;	DO_INT24 if TRUE.
;
;
; On Entry:
;	AX	Internal Error Code
;
; On Exit:
;	AX	0 if no error to return (Ignore)
;	AX	DOS Error Code
;	ZF	reflects AX
;
disk_error:
	mov	cl,LOC_CHAR			; assume character device
						; determine if the error is
	test	rwmode,80h			;  caused by a character or
	 jnz	disk_e10			;  block device and set the
	mov	cl,LOC_BLOCK 			;  the critical error locus
disk_e10:
	call	set_error			; record error information
	 jz	disk_e50			; just return a logical error.

	add	ax,ED_PROTECT			; Convert to HardWare Error
	mov	di,ax				; DI == HardWare Error
						; Now get the information
	mov	ah,rwmode			; about the error location

	and	ah,not OK_RIF			; mask the all responses
;	mov	al,valid_flg			; valid flag contains no crit
;	and	al,not NO_CRITICAL_ERRORS	;  errors bit, but if that was
;	or	ah,al				;  set we wouldn't be here
	or	ah,valid_flg			; or in valid responses

	cmp	bx,ED_GENFAIL			; if it's general failure
	 jne	disk_e20			;  we cannot Ignore the error
	and	ah,not OK_IGNORE		;  but must Abort/Fail/Retry
disk_e20:					;  as appropriate

	mov	al,err_drv			; get the failing drive
	mov	error_drive,al			;  and save locally

	les	si,error_dev			; get device driver header

						; are we are a character device
	test	ah,80h				;  as these have handled at a
	 jnz	disk_e40			;  lower level and just need
						;  to be FAILed back to caller

	call	do_int24			; Execute INT 24

	mov	bl,al				; Copy reponse into BL	

	xor	ax,ax				; Assume Ignore Error
	cmp bl,ERR_IGNORE ! jz disk_e50		; Ignore the Error

	cmp bl,ERR_FAIL ! jz disk_e40		; If not FAIL then RETRY
	call	reload_registers		; get back entry registers
	mov	FD_FUNC,ax			; save AX for a moment
	mov	al,ah				; set up function number
	xor	ah,ah				; in AX
	xchg	ax,FD_FUNC			; save for use by FDOS
	xor	ah,ah				; zero AH 'cause it's handy
	mov	sp,retry_sp			; Must be RETRY so reset the
	jmp	retry_off			; STACK and IP

disk_e40:
;
;	When a Critical Error is FAILED then we do the following
;	if (extended error_code <= ED_SHAREFAIL) then
;		ret = ED_ACCESS;
;	else
;		ret = ED_FAIL;
;	extended error_code = ED_FAIL;
;	return(ret);
;
; nb. above proto-code is at the request of ant
;
	mov	ax,-(ED_FAIL)		; always return ED_FAIL in the
	xchg	ax,error_code		;  extended error_code
	cmp	ax,-(ED_SHAREFAIL)	; did we FAIL on sharing conflict ?
	mov	ax,-(ED_ACCESS)		; assume we did and prepare to return
	 jae	disk_e50		;  ED_ACCESS
	mov	al,-(ED_FAIL)		; woops, return ED_FAIL after all
disk_e50:
	or	ax,ax			; NZ if error return required
	ret

eject
;
;	On Entry:-	AX	Internal Error Code
;			CL	Critical Error Locus
;
;	On Exit:-	AX	DOS Error Code
;			BX	Internal Error Code
;			ZF	set on logical error
set_error:
	mov	bx,ax			; by default we return the raw error
	mov	di,offset critical_error; Scan for critical Errors First
	call	scan_error_table	; look for a matching error
	 jc	set_logical_error
	mov	locus,cl		; Save the critical error LOCUS
	cmp	ax,ED_SHAREFAIL		; watch out for SHAREFAIL - the action
	 jne	set_e10			;  depends on the caller
;
; ED_SHAREFAIL will return ED_ACCESS if the result of an attempt to open
; a file in shared mode, otherwise (FCB's and compatibility) it will
; generate a critical error.
;
	mov	bx,ED_GENFAIL		; assume we want a critical error
	cmp	FD_FUNC,MS_X_OPEN	; is it a shared open ?
	 jnz	set_error_data
	test	FD_MODE,0$111$0$000b	;  mode
	 jz	set_error_data
	jmps	set_e30			; return a logical "access denied"

set_e10:
	cmp	ax,ED_LOCKFAIL		; have we a lockfail error ?
	 jne	set_e20
;
; ED_LOCKFAIL returns ED_ACCESS if a lock attempt fails, but a critical error
; on an attempt to read/write a locked region.
;
	cmp	FD_FUNC,FD_LOCK		; was it a result of specific lock
	 je	set_logical_error	;  call ? yes, it's a logical error
	mov	bx,ED_GENFAIL		; no, generate a critical error
	jmps	set_error_data

set_e20:
	test	valid_flg,NO_CRIT_ERRORS
	 jz	set_error_data		; do we allow critical errors ?
	mov	ax,ED_ACCESS		; extended error code is Access Denied
set_e30:
	mov	bx,ED_ACCESS		; return access denied to caller
;	jmps	set_logical_error

set_logical_error:
	xor	di,di
	mov	word ptr error_dev+0,di	; must be a logical error so force
	mov	word ptr error_dev+2,di	;  the ERROR_DEV to 0000:0000
	mov	di,offset logical_error	; scan the Logical error table 
	call	scan_error_table
	cmp	ax,ED_NETACCESS		; if it's a networked access denied
	 jne	set_error_data		;  turn it into ordinary one
	mov	bx,ED_ACCESS		; return a logical "access denied"
;	jmps	set_error_data

set_error_data:
; On Entry:
;	AX = Internal Error Code for extended error
;	BX = Internal Error Code for returned error
;	CS:DI -> error table entry
; On Exit:
;	AX = DOS Error Code
;	BX = Internal Error Code
;	ZF set on logical error
;
	neg	ax
	mov	error_code,ax		; Save the Error Code
	mov	al,cs:ERR_TBL_CLASS[di]
	mov	error_class,al		; Save the Class
	mov	al,cs:ERR_TBL_ACTION[di]
	mov	error_action,al		; Save the Action
	mov	al,cs:ERR_TBL_LOCUS[di]	; Get the Locus
	mov	error_locus,al		; Save the Locus and then check
	test	al,al			; if the function overrides
	 jnz	set_d10			; this value
	mov	al,locus		; Get the Global Locus value
	mov	error_locus,al		; set by the calling function
set_d10:				; and save for FUNC 59
	mov	ax,bx			; Return to the caller with
	neg	ax			; the DOS error code.
	mov	di,word ptr error_dev	; set ZF if logical error
	or	di,word ptr error_dev+2	; error_dev = 0:0
	ret

scan_error_table:
	cmp	cs:ERR_TBL_CODE[di],0
	 je	scan_et10		; Check for the end of the list
	cmp	al,cs:ERR_TBL_CODE[di]
	 je	scan_et20
	add	di,ERR_TBL_LEN
	jmps	scan_error_table
scan_et10:
	stc
scan_et20:
	ret


eject
PCM_RODATA	CSEG	WORD
logical_error	rb	0
;
;	Internal Code	Error Class	Error Action	Error Locus
;	=============	===========	============	===========
   db   ED_FUNCTION,	CLASS_APPLIC,	ACT_ABORT,	00
   db   ED_FILE,	CLASS_LOST,	ACT_USER,	LOC_BLOCK
   db   ED_PATH,	CLASS_LOST,	ACT_USER,	LOC_BLOCK
   db   ED_HANDLE,	CLASS_RESOURCE,	ACT_ABORT,	LOC_UNKNOWN
   db   ED_ACCESS,	CLASS_AUTHOR,	ACT_USER,	00
   db   ED_NETACCESS,	CLASS_AUTHOR,	ACT_USER,	00
   db   ED_H_MATCH,	CLASS_APPLIC,	ACT_ABORT,	LOC_UNKNOWN
   db   ED_DMD,		CLASS_APPLIC,	ACT_TERM,	LOC_MEMORY
   db   ED_MEMORY,	CLASS_RESOURCE,	ACT_ABORT,	LOC_MEMORY
   db   ED_BLOCK,	CLASS_APPLIC,	ACT_ABORT,	LOC_MEMORY
   db   ED_ENVIRON,	CLASS_APPLIC,	ACT_ABORT,	LOC_MEMORY
   db   ED_FORMAT,	CLASS_FORMAT,	ACT_USER,	LOC_UNKNOWN
   db   ED_ACC_CODE,	CLASS_APPLIC,	ACT_ABORT,	LOC_UNKNOWN
   db   ED_DATA,	CLASS_FORMAT,	ACT_ABORT,	LOC_UNKNOWN
   db   ED_DRIVE,	CLASS_LOST,	ACT_USER,	LOC_BLOCK
   db   ED_DIR,		CLASS_AUTHOR,	ACT_USER,	LOC_BLOCK
   db   ED_DEVICE,	CLASS_UNKNOWN,	ACT_USER,	LOC_BLOCK
   db   ED_ROOM,	CLASS_LOST,	ACT_USER,	LOC_BLOCK
   db   ED_EXISTS,	CLASS_EXISTS,	ACT_USER,	LOC_BLOCK
   db   ED_STRUCT,	CLASS_RESOURCE,	ACT_ABORT,	00
   db   ED_PASSWORD,	CLASS_AUTHOR,	ACT_USER,	LOC_UNKNOWN
   db   ED_MAKE,	CLASS_RESOURCE,	ACT_ABORT,	LOC_BLOCK
;; db   ED_NET,		CLASS_FORMAT,	ACT_USER,	LOC_NET
   db   ED_ASSIGN,	CLASS_EXISTS,	ACT_USER,	LOC_NET
   db   ED_PARAM,	CLASS_FORMAT,	ACT_USER,	LOC_UNKNOWN
   db   ED_FAIL,	CLASS_UNKNOWN,	ACT_ABORT,	LOC_UNKNOWN
   db   ED_SHAREFAIL,	CLASS_LOCKED,	ACT_DELAY,	LOC_BLOCK
   db   ED_LOCKFAIL,	CLASS_LOCKED,	ACT_DELAY,	LOC_BLOCK
   db   ED_NOLOCKS,	CLASS_RESOURCE,	ACT_ABORT,	LOC_MEMORY
   db   00,		CLASS_SYSTEM,	ACT_TERM,	LOC_UNKNOWN

critical_error	rb	0
;
;	Internal Code	Error Class	Error Action	Error Locus
;	=============	===========	============	===========
   db   ED_PROTECT,	CLASS_MEDIA,	ACT_URETRY,	LOC_BLOCK
   db   ED_BADUNIT,	CLASS_INTERNAL,	ACT_TERM,	LOC_UNKNOWN
   db   ED_NOTREADY,	CLASS_HARDWARE,	ACT_URETRY,	00
   db   ED_BADCMD,	CLASS_INTERNAL,	ACT_TERM,	LOC_UNKNOWN
   db   ED_BADDATA,	CLASS_MEDIA,	ACT_ABORT,	LOC_BLOCK
   db   ED_BADSEEK,	CLASS_HARDWARE,	ACT_RETRY,	LOC_BLOCK
   db   ED_BADMEDIA,	CLASS_MEDIA,	ACT_URETRY,	LOC_BLOCK
   db   ED_RNF,		CLASS_MEDIA,	ACT_ABORT,	LOC_BLOCK
   db   ED_NOPAPER,	CLASS_TEMP,	ACT_URETRY,	LOC_CHAR
   db   ED_WRFAIL,	CLASS_HARDWARE,	ACT_ABORT,	00
   db   ED_RDFAIL,	CLASS_HARDWARE,	ACT_ABORT,	00
   db   ED_GENFAIL,	CLASS_UNKNOWN,	ACT_ABORT,	00
   db   ED_SHAREFAIL,	CLASS_LOCKED,	ACT_DELAY,	LOC_BLOCK
   db   ED_LOCKFAIL,	CLASS_LOCKED,	ACT_DELAY,	LOC_BLOCK
   db   ED_NOFCBS,	CLASS_APPLIC,	ACT_ABORT,	LOC_UNKNOWN

default_error	rb	0
   db   00,		CLASS_SYSTEM,	ACT_TERM,	LOC_UNKNOWN

PCMODE_DATA	DSEG	WORD
	extrn	indos_flag:byte
	extrn	internal_flag:byte
	extrn	int21regs_ptr:dword
	extrn	current_psp:word
	extrn	retry_off:word, retry_sp:word
	extrn	valid_flg:byte
	extrn	error_locus:byte	; Error Locus
	extrn	error_code:word		; DOS format error Code
	extrn	error_action:byte	; Error Action Code
	extrn	error_class:byte	; Error Class
	extrn	error_dev:dword		; Failing Device Header
	extrn	error_drive:byte	; Failing Disk Drive
	extrn	err_drv:byte
	extrn	locus:byte
	extrn	rwmode:byte
end
