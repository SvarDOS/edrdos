;    File              : $SUPPORT.A86$
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
;
;    $Log$
;    SUPPORT.A86 1.11 93/11/29 13:39:28
;    Don't rely on DS when return_ called
;    ENDLOG
;
;	The following Support routines are provided for both the 
;	handle and FCB functions which require critical error handler
;	support.
;
; 15 Jun 88 Modify the SYSDAT and SUPERVISOR variables to enable
;           the relocation of the BDOS into high memory
;  5 Jan 89 Only set PCKBD mode if we own the default console
;  9 Mar 89 Support a split PCMODE and SYSDAT Segments
; 22 Sep 89 LDT support routine added
; 29 Jan 90 Int 2A critical section support added to dpbdos_entry
;  7 Mar 90 Convert to register preserved function calls
;  4 May 90 DRDOS int3x handlers removed (they are pointed to IRET
;           in PCMODE_DATA by INIT.PCM)
; 12 Dec 90 keep error server number inverted so local = 0, more compatible

;

PCMDATA group PCMODE_DATA,FDOS_DSEG
PCMCODE group PCM_CODE

ASSUME DS:PCMDATA

	.nolist
	include	pcmode.equ
	include	fdos.def	
	include mserror.equ
	include	doshndl.def
	.list

PCM_CODE	segment public byte 'CODE'
	extrn	error_exit:near		; Standard Error Exit Routine
	extrn	fcberror_exit:near	; Special FCB function Error Exit
	extrn	fdos_entry:near
	extrn	get_dseg:near

;
;	STRLEN determines the length of the string passed in DS:SI
;	and returns the byte length in CX.
;
	Public	strlen
strlen:
	push 	es
	push 	di
	push 	ds
	pop 	es
	mov	di,si
	mov	cx,0FFFFh
	sub	al,al
	repnz	scasb	
	pop 	di
	pop 	es
	not	cx
	dec	cx
	ret

;
;	This routine sets the address to be returned to by the 
;	FDOS when an error has occured and the RETRY request has been
;	made. The set_retry routine should be used as follows:-
;
;	mov	al,Valid Error Responses
;	call	set_retry
;	Init All FDOS Parameters
;	call	fdos_crit
;
; NB. For register model return with AX = dos_AL extended to 16 bit

	Public	set_retry_RF
set_retry_RF:
	mov	al,OK_RF		; Valid to RETRY or FAIL
;	jmp	set_retry		; (the most common case)

	Public	set_retry
set_retry:
	mov	valid_flg,al		; Save Valid Error Reponses
	pop	retry_off		; Save the Routine Address
	mov	retry_sp,sp		; and the Stack Pointer
	mov	al,ah			; get function number
	xor	ah,ah			; make it a word
	mov	FD_FUNC,ax		; save it for the FDOS
	push	ds
	push	bx
	lds	bx,int21regs_ptr	; point to users registers
	and	reg_FLAGS[bx],not CARRY_FLAG
	mov	al,reg_AL[bx]		; clear CY assuming we will succeed
	pop	bx			;  and reload AL with entry value
	pop	ds
	jmp	retry_off

;
;	The FDOS routine executes the CCP/M FDOS function using the 
;	static FDOS parameter block defined in the Data Segment.
;
	Public	fdos_crit
fdos_crit:
	call	fdos_nocrit
	cmp	ax,ED_LASTERROR		; Compare against last error code
	 jnb	fdos_error		; if NOT below then is ERROR CODE
	or	ax,ax			; Reset the Carry Flag and Return
	ret

	Public	fdos_ax_crit
fdos_ax_crit:
	call	fdos_nocrit
	cmp	ax,ED_LASTERROR		; Compare against last error code
	 jnb	fdos_error		; if NOT below then is ERROR CODE
	or	ax,ax			; Reset the Carry Flag and Return
;	jmp	return_AX_CLC		; Save the Return Code

	Public	return_AX_CLC
return_AX_CLC:
;-------------
; On Entry:
;	AX to be returned to caller in AX
; On Exit:
;	ES:DI trashed
;
	push 	ds
	push 	di
	lds	di,ss:int21regs_ptr
	mov	reg_AX[di],ax		; return AX to caller
	and	reg_FLAGS[di],not CARRY_FLAG
	pop 	di
	pop 	ds
	ret


fdos_error:				; Process the Error
	cmp	sp,retry_sp		; Is the user expecting use to 
	 jnz	fdos_e10		; return or use the default handler
	jmp	error_exit		; If CALLed then return with the error
fdos_e10:				; to the calling routine.
	stc
	ret

	Public	fcbfdos_crit
fcbfdos_crit:
	call	fdos_nocrit
	cmp	ax,ED_LASTERROR		; Compare against last error code
	 jnb	fcbfdos_error		; if NOT below then is ERROR CODE
	or	ax,ax			; Reset the Carry Flag and Return
	ret

fcbfdos_error:				; Process the Error
	cmp	sp,retry_sp		; Is the user expecting use to 
	 jnz	fcbfdos_e10		; return or use the default handler
	jmp	fcberror_exit		; If CALLed then return with the error
fcbfdos_e10:				; to the calling routine.
	stc
	ret

	Public	fdos_nocrit
fdos_nocrit:
	mov	dx,offset fdos_data	; point to fdos parameter block
	push 	ds
	push 	es
	push 	si
	push 	di
	push 	bp
	call	fdos_entry		; BDOS module entry point
	or	ax,ax			; Set the Flags
	pop  	bp
	pop  	di
	pop  	si
	pop 	es
	pop  	ds
	ret


	Public	reload_ES
reload_ES:
; On Entry:
;	None
; On Exit:
;	ES = callers ES
;	All regs preserved
;
	push	bx
	les	bx,ss:int21regs_ptr
	mov	es,es:reg_ES[bx]	; reload with callers ES
	pop	bx
	ret

	
	Public	return_BX
return_BX:
;---------
; On Entry:
;	BX to be returned to caller in BX
; On Exit:
;	All regs preserved
;
	push 	ds
	push 	si
	lds	si,ss:int21regs_ptr
	mov	reg_BX[si],bx		; return BX to caller
	pop 	si
	pop 	ds
	ret

	Public	return_CX
return_CX:
;---------
; On Entry:
;	CX to be returned to caller in CX
; On Exit:
;	All regs preserved
;
	push 	ds
	push 	bx
	lds	bx,ss:int21regs_ptr
	mov	reg_CX[bx],cx		; return CX to caller
	pop 	bx
	pop 	ds
	ret

	Public	return_DX
return_DX:
;---------
; On Entry:
;	DX to be returned to caller in DX
; On Exit:
;	All regs preserved
;
	push 	ds
	push 	bx
	lds	bx,ss:int21regs_ptr
	mov	reg_DX[bx],dx		; return DX to caller
	pop 	bx
	pop 	ds
	ret

PCM_CODE	ends

PCMODE_DATA	segment public word 'DATA'


	extrn	current_psp:word
	extrn	DBCS_tbl:word		; double byte character set table
	extrn	int21regs_ptr:dword
	extrn	retry_off:word
	extrn	retry_sp:word
	extrn	valid_flg:byte

PCMODE_DATA	ends

	end

