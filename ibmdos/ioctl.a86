;    File              : $IOCTL.A86$
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
;    IOCTL.A86 1.17 94/11/28 15:42:19 
;    f440B now does not modify net_retry if DX=0    
;    IOCTL.A86 1.16 93/11/08 19:15:18
;    SETVER to subversion 0xFF disabled int 21/4452
;    IOCTL.A86 1.15 93/07/26 18:16:16
;    add some code which disables drdos check if app is SETVER'd
;    leave said code disabled unless required
;    IOCTL.A86 1.14 93/07/22 19:29:54
;    get/set serial number now the correct way round
;    IOCTL.A86 1.11 93/06/17 22:14:34
;    support for ioctl 10/11 query ioctl support
;    ENDLOG
;
;  7 Nov 87 Removal of development flags
; 17 Dec 87 Return "Single device Supported" for IOCTL sub-functions
;           0Eh and 0Fh.
; 24 Feb 88 Return 1060h from IOCTL sub-function 51h under DOS PLUS
;           instead of the Concurrent DOS OS version.
; 24 Feb 88 Correct Generic IOCTL function and prevent the generation
;           of critical errors.
; 24 May 88 sub-function 53h returns the address of the INT24 handler
;           for the command processor.
; 01 Jun 88 Add sub-function 4454 to support setting the default password
; 03 Nov 88 Add History Buffer Sub-Command f4456 for DOSPLUS
; 02 Feb 89 Add code page switching sub-function 0Ch
; 19 Feb 89 Support Sub-Command f4457 to control SHARE
; 15 Mar 89 Do not generate critical errors from 4402 and 4403.
; 18 Apr 89 Sub-function 53 only suported for Concurrect DOS
; 19 Apr 89 Don't clobber error code on 440D and 440E (pc-cache)
; 31 May 89 New function f4458 to return pointer to private data.
; 31 May 89 f440B sets up DOS internal data
; 15 Jun 89 Don't throw away inheritance bit when masking Share Mode Flags
; 11 Oct 89 f4407/07 set AX on return, not just AL
; 26 Oct 89 for a few bytes more...
; 18 Jan 90 HILOAD interface added onto f4457
; 25 Jan 90 INT21/4458 returns a pointer to IDLE_DATA in ES:AX
; 13 Jan 90 private_data exported in CDOS for DEBUG systems
; 27 Feb 90 4459 provides Int21 function that does Int224 calls
;  7 Mar 90 Convert to register preserved function calls
; 14 Mar 90 No critical error generated in IOCTL functions
;  3 May 90 stop forcing ioctl 4403/3/4/5 errors to ED_ACCESS
;  4 Jun 90 445A provides user group support on CDOS
;  3 jun 92 Add 4456/2+3 to examine history state, toggle history enable
; 30 jul 92 HILOAD now uses official memory strategy calls
;
	include	pcmode.equ
	include fdos.def
	include	i:msdos.equ
	include i:mserror.equ
	include	i:cmdline.equ
	include	i:driver.equ
	include	i:reqhdr.equ
	include	i:psp.def

PCM_CODE	CSEG	BYTE
	extrn	os_version:word
	extrn	patch_version:word

	extrn	invalid_function:near
	extrn	error_ret:near
	extrn	fdos_nocrit:near
	extrn	fdos_crit:near
	extrn	fdos_ax_crit:near
	extrn	return_AX_CLC:near
	extrn	return_DX:near
	extrn	return_DSBX_as_ESBX:near
	extrn	set_retry_RF:near
	extrn	patch_version:word


;	*****************************
;	***    DOS Function 69    ***
;	***   set/get serial num  ***
;	*****************************
;
	Public	func69
func69:
	call	set_retry_RF			; Prepare for an FDOS function
	mov	FD_FUNC,MS_X_IOCTL
	mov	cx,866h				; assume a get serial num
	cmp	al,1				; check for 0/1
	mov	al,0Dh				; ready for ioctl 0D
	 jb	func44common			; go ahead with get serial num
	mov	cl,46h				; maybe it's a set
	 je	func44common			; go ahead with set serial num
;	jmp	invalid_function		; ah well, it's an invalid one
	jmps	f44_30

;	*****************************
;	***    DOS Function 44    ***
;	***       I/O Control     ***
;	*****************************
;
	Public	func44
func44:
	call	set_retry_RF			; Prepare for an FDOS function
func44common:
	mov	FD_IOCTLFUNC,ax			; save subfunction for FDOS
	mov	ioctlRH,22			; assume RH will be wanted
	mov	ioctlRH+13,0			;  init len and media byte
	mov	word ptr ioctlRH+14,dx		; point at buffer segment
	mov	word ptr ioctlRH+16,es
	mov	word ptr ioctlRH+18,cx		; the Byte Count
	cmp	ax,dosf44_ftl			; Check for a valid PC-DOS
	 jae	f44_20				; sub-functions
f44_10:
	xchg	ax,si
	shl	si,1
	mov	si,func44_ft[si]
	xchg	ax,si
	jmp	ax
f44_20:
	sub	al,52h-dosf44_ftl		; adjust to our base of 52h
	 jc	f44_30				; bail out if too low
	cmp	ax,ourf44_ftl			; is it too high ?
	 jb	f44_10
f44_30:
	jmp	invalid_function

;	***********************************************
;	***    Sub Function 00 - Get Device Info    ***
;	***********************************************
f4400:
	call	fdos_handle			; execute the function
	mov	dx,ax				; return in DX too
return_AX_and_DX:
	call	return_DX			; return to caller in DX
	jmp	return_AX_CLC			; return AX too

;	***********************************************
;	***    Sub Function 01 - Set Device Info    ***
;	***    Sub Function 06 - Get Input Status   ***
;	***    Sub Function 07 - Get Output Status  ***
;	***********************************************
f4401:
f4406:
f4407:
	call	fdos_handle			; Execute the Function
	jmp	return_AX_CLC

;	************************************************
;	***    Sub Function 04 -  Read Blk Device    ***
;	***    Sub Function 05 -  Write Blk Device   ***
;	***    Sub Function 11 -  Query ioctl Blk    ***
;	************************************************
;
f4404:
f4405:
f4411:
	xor	bh,bh				; BX = drive number

;	************************************************
;	***    Sub Function 02 - Read Character Dev  ***
;	***    Sub Function 03 - Write Character Dev ***
;	***    Sub Function 10 - Query ioctl Char    ***
;	************************************************
;
f4402:
f4403:
f4410:
	mov	dx,DA_QUERY			; assume we will query support
	mov	al,CMD_QUERY_IOCTL		;  and be ready to go
	mov	cx,FD_IOCTLFUNC			; re-read the function number
	test	cl,10h				; is it function 10 of 11?
	 jnz	f44ioctl			; yes, we are ready
	mov	dx,DA_IOCTL			; no, we actually want to do it
	mov	al,CMD_INPUT_IOCTL		; even functions are input
	test	cl,1				; test for input functions
	 jz	f44ioctl
	mov	al,CMD_OUTPUT_IOCTL		; odd functions are output
f44ioctl:
	mov	FD_IOCTLSTAT,dx			; this device driver support is required
	mov	ioctlRH+2,al			;  this is the function
	call	fdos_handle			; Execute the Function
	mov	ax,word ptr ioctlRH+18		; return # xfered
	jmp	return_AX_CLC

;	*****************************
;	***    Sub Function 09    ***
;	***    Networked Media    ***
;	*****************************
;
f4409:
	call	fdos_drive			; Execute the Function
	mov	dx,ax				; Get the Return Information
    mov ax,0300h            
	jmps	return_AX_and_DX

;	*****************************
;	***    Sub Function 0A    ***
;	***    Networked Handle   ***
;	*****************************
;
f440A:
	call	fdos_handle			; Execute the Function
	mov	dx,ax				; Get the Return Information
	jmp	return_DX			;  and return in DX

;	*****************************
;	***    Sub Function 0B    ***
;	***   Update Share Retry  ***
;	*****************************
;
;	dos_CX [1]	Number of times to execute the delay loop
;			which consists of xor cx,cx ! loop $
;
;	dos_DX [3]	Number of times to retry
;
;
f440B:
	mov	net_delay,cx
	test	dx,dx
	 jz	f440B_10
	mov	net_retry,dx
f440b_10:
	ret

;	*****************************
;	***    Sub Function 0D    ***
;	***   Device Driver Req   ***
;	*****************************
;
f440D:
	xor	bh,bh
;	jmp	f440C

;	*****************************
;	***    Sub Function 0C    ***
;	***  Code Page Switching  ***
;	*****************************
;
f440C:
	mov	FD_IOCTLSTAT,DA_GETSET		; device driver support required
	mov	FD_HANDLE,bx			; Save the Handle Number
	mov	ioctlRH,23			; different RH length
	mov	ioctlRH+2,CMD_GENERIC_IOCTL
	xchg	cl,ch				; swap minor/major functions
	mov	word ptr ioctlRH+13,cx		;  and store in request header
	mov	word ptr ioctlRH+15,si
	mov	word ptr ioctlRH+17,di
	mov	word ptr ioctlRH+19,dx		; point at buffer segment
	mov	word ptr ioctlRH+21,es
	call	fdos_ax_crit			; Execute the Function and
	 jc	fdos_error			; return all error codes
	ret

;	***********************************************
;	***    Sub Function 08 - Removable Media    ***
;	***    Sub Function 0E - Get Logical Drive  ***
;	***    Sub Function 0F - Set Logical Drive  ***
;	***********************************************
;
f4408:
f440E:
f440F:
	call	fdos_drive		; Execute the Function
	jmp	return_AX_CLC		; return result in AX


fdos_drive:
;----------
	xor	bh,bh			; BX = the drive number
fdos_handle:
;----------
	mov	FD_HANDLE,bx
	call	fdos_crit		; then execute the FDOS
	 jnc	fdos_OK			; exit on Error
	add	sp,WORD			; discard near return address
fdos_error:
	jmp	error_ret		; and return the error
fdos_OK:
	mov	ax,FD_IOCTLSTAT		; get the return information
	ret
eject
;	*****************************
;	***    CCP/M Extension    ***
;	***    Sub Function 52    ***
;	***  Return CCP/M Version ***
;	*****************************
;
f4452:
if DOS5
	mov	es,current_psp		; version is kept in the PSP
	cmp	PSP_VERSION,0FF00h	; sub-version of 255 ?
	 jae	f4452_10		; then say we ain't DRDOS
endif
	mov	ax,cs:os_version	; Get OS ver number
	mov	dx,cs:patch_version
	call	return_DX		; return in DX
	jmp	return_AX_CLC		; return in AX

if DOS5
f4452_10:
    jmp invalid_function    
endif

if PASSWORD

;	*****************************
;	***    CCP/M Extension    ***
;	***    Sub Function 54    ***
;	*** Set Default PASSWORD  ***
;	*****************************
;
f4454:
	mov	FD_IOCTLFUNC,0Bh		; save subfunction for FDOS
	jmp	fdos_nocrit			; Execute the Function

endif


;	*****************************
;	***    CCP/M Extension    ***
;	***    Sub Function 56    ***
;	*** History Buffer Cntrl  ***
;	*****************************
;
;	This function changes the default history buffer used for func0A:
;
; On Entry:
;	DL = 0 -> Standard Process Buffer
;	DL = 1 -> Command.com history Buffer
;	DL = 2 -> Toggle history enable/disable
;	DL = 3 -> Get current state of history buffers
;	DL = 4 -> Toggle insert mode
;
; On Exit:
;	AL = previous history state (Bit 0 set if history on)
;		Bit 0 -> set if history enabled
;		Bit 1 -> set if insert enabled
;		Bit 7 -> set if command history buffer
;
f4456:
	mov	ax,cle_state		; Get the current History Status
	cmp	dl,2			; are we disabling/enabling ?
	 jb	f4456_10		; below, switch buffers
	 je	f4456_05		; yes, try and do it
	cmp	dl,4			; toggle insert state ?
	 jne	f4456_20		; no, return existing state
	xor	al,RLF_INS		; toggle insert state
	jmps	f4456_20		;  set and return prev state

f4456_05:
	mov	cl,RLF_ENHANCED		; we are interested in enhancements
	test	@hist_flg,cl		;  only if history possible
	 jz	f4456_20		; just return existing state
	xor	al,cl			; invert current setting
					; and fall thru' to enable/disable
					; standard buffer (never called
					; by COMMAND...)
f4456_10:
	or	al,RLF_INROOT		; assume we are in the root
if IDLE_DETECT
	or	idle_flags,IDLE_COMMAND
endif
	test	dl,1			; Get new state and mask bit
	 jnz	f4456_20
	and	al,not RLF_INROOT	; we are in application buffer
if IDLE_DETECT
	and	idle_flags,not IDLE_COMMAND
endif
f4456_20:
	xchg	ax,cle_state		; set state, returning old state
	ret


;	*****************************
;	***    CCP/M Extension    ***
;	***    Sub Function 58    ***
;	***   Private Data Func   ***
;	*****************************
;
;	On Exit ES:BX points to our DRDOS private data.
;	        ES:AX points to the IDLE Data Area

f4458:
	mov	bx,offset @private_data
	call	return_DSBX_as_ESBX	; return ES:BX pointing to private data
	mov	ax,offset idle_data
	jmp	return_AX_CLC




PCM_RODATA	CSEG	WORD
;
;		PCDOS Sub-Functions Only
;
func44_ft	dw	f4400
		dw	f4401
		dw	f4402
		dw	f4403
		dw	f4404
		dw	f4405
		dw	f4406
		dw	f4407
		dw	f4408
		dw	f4409
		dw	f440A
		dw	f440B
		dw	f440C
		dw	f440D
		dw	f440E
		dw	f440F
		dw	f4410
		dw	f4411
dosf44_ftl	equ	(offset $ - offset func44_ft)/2
;
;		CCP/M Sub-Functions Only
;
		dw	f4452			; 4452 OS version no
		dw	invalid_function	; 4453 Invalid Function
if PASSWORD
		dw	f4454			; 4454 set default password
else
		dw	invalid_function	; 4454 was set default password
endif
		dw	invalid_function	; 4455 Invalid Function
		dw	f4456			; 4456 history buffer support
		dw	invalid_function	; 4457 was share enable/disable
		dw	f4458			; 4458 pointer to private data

ourf44_ftl	equ	(offset $ - offset func44_ft)/2

PCMODE_DATA	DSEG	WORD
	extrn	net_delay:word, net_retry:word
	extrn	@hist_flg:byte
	extrn	@private_data:byte
if IDLE_DETECT
	extrn	idle_data:word
	extrn	idle_flags:word
endif
	extrn	cle_state:word
	extrn	ioctlRH:byte
	extrn	dos_version:word
	extrn	current_psp:word

	end
