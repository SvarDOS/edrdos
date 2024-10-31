;    File              : $DISK.ASM$
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
;    DISK.A86 1.26 94/12/01 10:05:21
;    added attribute support for open/move/unlink during server call
;    DISK.A86 1.24 93/11/16 13:46:21
;    Generate critical error on int21/36 (get free space)
;    DISK.A86 1.23 93/10/25 21:58:02
;    Tighten up error checks on int21/6C modes (DL bits 0-3 = 3 rejected)
;    DISK.A86 1.22 93/10/18 17:40:51
;    fix for >255 open files (PNW Server)
;    DISK.A86 1.21 93/09/03 20:28:02
;    Add "no critical errors" support (int 21/6C)
;    DISK.A86 1.20 93/08/04 15:15:15
;    Int21/6C allows DH=1 
;    DISK.A86 1.19 93/07/22 20:32:12 
;    don't check AL on int 21/6c
;    DISK.A86 1.18 93/07/22 19:28:02
;    correct bug in extended open/create
;    DISK.A86 1.15 93/06/23 04:05:38
;    more int21/6C - we still need no critical errors support
;    DISK.A86 1.14 93/06/23 03:00:27
;    fix bug in int21/6C
;    DISK.A86 1.13 93/05/07 15:09:29
;    Move delwatch free space adjust call inside the MXDisk
;    DISK.A86 1.12 93/03/16 22:33:49
;    UNDELETE support changes
;    DISK.A86 1.11 93/03/05 18:10:55
;    Add UNDELETE definition
;    ENDLOG
;
;	All FCB based PCMODE functions are translated to FDOS function
;	calls in this file.
;
; 22 May 87 Support the extended CHMOD function to get/set the
;           password mode.
; 28 May 87 Support the Update Handle Count Function
;  5 Nov 87 Remove MAJOR_VER reference from func0D
; 15 Mar 88 Return Attributes in CX and AX
;  3 May 88 Return correct disk size from functions 1B, 1C and 36
; 17 May 88 Add valid drive check routine used by FUNC29 and FUNC4B
; 30 Jun 88 Call FDOS to build DDSC for INT21/53
; 18 Aug 88 FUNC67 correctly fill new handle table with 0FFh
;           Sorcim ACCPAC Plus
; 27 Sep 88 Return error codes from Read and Write Random.
; 19 Feb 89 Allowing SHARE to be disabled with DR DOS
; 16 May 89 Include Random Record field on func23 (file size)
; 23 May 89 func3F (Read) now allows Ignore on errors (CopyIIpc)
; 11 Sep 89 MSNET Flush hook added
; 20 Sep 89 func3B "d:=" form fills in LDT (func4B support)
; 24 Oct 89 func32 (getdpb) sets top bit of drive on fdos_getdpb
;           to indicate free space count not required
; 27 Oct 89 mutilate the code to save space
; 24 Jan 90 valid_drive uses dos_entry, doesn't peek at HDS's
;  8 Feb 90 func_43 updated for new password support
; 27 Feb 90 func57 gives ED_FUNCTION if not get/set (HEADROOM bug)
;  7 Mar 90 Convert to register preserved function calls
; 14 Mar 90 Share func3D_mask bodge move to FDOS
; 28 Sep 90 Return sectors xfered on Int21/27 even if error (CALC.EXE>64k)
; 14 mar 91 add delwatch hook to func36 (disk free space)
; 14 jun 91 correct error codes from func3F during func4B
;  8 aug 91 func3B (chdir) now maintains LDT name for all cases
;  1 oct 91  Valdivar it
; 27 feb 92 func3E returns previous open count
;  3 mar 92 fill in default search attribute in Func3D for future
; 23 mar 92 func67 will now shrink #handles
;

PCMDATA group PCMODE_DATA,FDOS_DSEG,GLOBAL_DATA,BDOS_DATA
PCMCODE group PCM_CODE

ASSUME DS:PCMDATA

	.nolist
	include	pcmode.equ
	include	fdos.def
	include	doshndl.def
	include	fdos.equ
	include	psp.def
	include	msdos.equ
	include	mserror.equ
	include	redir.equ
	.list

FCB_LEN		equ	32
XFCB_LEN	equ	FCB_LEN+7

BDOS_DATA	segment public word 'DATA'
	extrn	dosfat:word
BDOS_DATA	ends

PCM_CODE	segment public byte 'CODE'
	extrn	dbcs_lead:near
	extrn	dos_entry:near
	extrn	fdos_nocrit:near
	extrn	fdos_crit:near, fdos_ax_crit:near
	extrn	fcbfdos_crit:near
	extrn	set_retry:near
	extrn	set_retry_RF:near
	extrn	error_exit:near
	extrn	error_ret:near
	extrn	fcberror_exit:near

	extrn	reload_registers:near
	extrn	reload_ES:near
	extrn	return_AX_CLC:near
	extrn	return_BX:near
	extrn	return_CX:near
	extrn	return_DX:near
	extrn	output_hex:near

;	*****************************
;	***    DOS Function 0D    ***
;	***      Disk Reset       ***
;	*****************************
;
	Public	func0D
func0D:
	mov	FD_FUNC,FD_FLUSH
	call	fdos_nocrit		; flush buffers
	mov	ax,0FFFFh
	push	ax
	mov	ax,I2F_FLUSH
	int	2fh			; magic INT2F flush remote buffers
	pop	ax
	push 	ss
	pop 	ds
	ret

;	*****************************
;	***    DOS Function 0E    ***
;	***      Select Disk      ***
;	*****************************
;
	Public	func0E
func0E:
;
; Entry:
;	DL  ==	drive to set as default (0 == A:)
; Exit:
;	AL  ==  Number of Drives in System (from SYSDAT)
;
	mov	FD_FUNC,FD_SELECT
	xchg	ax,dx			; drive in AL
	cbw				; make that AX
	mov	FD_DRIVE,ax
	call	fdos_nocrit		; ask the FDOS to try to select it
	mov	al,last_drv		; Return the number of valid drives
	ret

;
;	Return with the ZERO flag set if the drive passed in AL is
;	valid. This function is used to set the initial AX value
;	when a program is loaded.
;
;	On Entry:-	AL	00 	 - Default Drive
;				01 to 26 - A: to Z:
;
;	On Exit:-	ZF	If AL referenced a valid drive
;
	Public	valid_drive
valid_drive:
	push	dx
	mov	dl,al			; get drive in DL
	dec	dl			; make drive zero based
	 js	valid_drive10		; if current drive always OK
	mov	ah,MS_DRV_GET
	call	dos_entry		; get current drive
	push	ax			; save for later
	mov	ah,MS_DRV_SET
	call	dos_entry		; try and select new drive
	mov	ah,MS_DRV_GET		;  if we can select it
	call	dos_entry		;  then it's valid
	sub	al,dl			; AL = 0 if drive valid
	pop	dx			; recover old drive
	push	ax			; save result
	mov	ah,MS_DRV_SET
	call	dos_entry		; reset to original drive
	pop	ax			; recover result
valid_drive10:
	pop	dx
	test	al,al			; set ZF if valid drive
	ret

;	*****************************
;	***    DOS Function 0F    ***
;	***    Open File (FCB)    ***
;	*****************************
;
	Public	func0F
func0F:

;	*****************************
;	***    DOS Function 10    ***
;	***    Close File (FCB)   ***
;	*****************************
;
	Public	func10
func10:

;	*****************************
;	***    DOS Function 11    ***
;	***   Search First (FCB)  ***
;	*****************************
;
	Public	func11
func11:

;	*****************************
;	***    DOS Function 12    ***
;	***   Search Next (FCB)   ***
;	*****************************
;
	Public	func12
func12:

;	*****************************
;	***    DOS Function 13    ***
;	***   Delete File (FCB)   ***
;	*****************************
;
	Public	func13
func13:

;	*****************************
;	***    DOS Function 14    ***
;	*** Sequential Read (FCB) ***
;	*****************************
;
	Public	func14
func14:

;	*****************************
;	***    DOS Function 15    ***
;	*** Sequential Write (FCB)***
;	*****************************
;
	Public	func15
func15:

;	*****************************
;	***    DOS Function 16    ***
;	***   Create File (FCB)   ***
;	*****************************
;
	Public	func16
func16:

;	*****************************
;	***    DOS Function 17    ***
;	***   Rename File (FCB)   ***
;	*****************************
;
	Public	func17
func17:

;	*****************************
;	***    DOS Function 21    ***
;	***   Random Read (FCB)   ***
;	*****************************
;
	Public	func21
func21:

;	*****************************
;	***    DOS Function 22    ***
;	***   Random Write (FCB)  ***
;	*****************************
;
	Public	func22
func22:

;	*****************************
;	***    DOS Function 23    ***
;	***    File Size (FCB)    ***
;	*****************************
;
	Public	func23
func23:

;	*****************************
;	***    DOS Function 24    ***
;	***  Set Relative Record  ***
;	*****************************
;
	Public	func24
func24:

;	*****************************
;	***    DOS Function 27    ***
;	***   Random Block Read   ***
;	*****************************
;
	Public	func27
func27:

;	*****************************
;	***    DOS Function 28    ***
;	***   Random Block Write  ***
;	*****************************
;
	Public	func28
func28:
; All FCB function come through here
	call	set_retry_RF		; Valid to RETRY or FAIL
	mov	ax,FD_FCB		; FCB file function
	xchg	ax,FD_FUNC		; recover function number
	mov	FD_FCBFUNC,ax		; pass FCB function number
	mov	FD_FCBOFF,dx		; Initialise the FCB Pointer
	mov	FD_FCBSEG,es
	mov	FD_FCBCNT,cx		; we may need record count
	call	fcbfdos_crit		; Execute the function
	 jc	fcb_error		; Check for an Error
	mov	cx,FD_FCBCNT		; Get the number of records
	jmp	return_CX		; processed and return in CX
fcb_error:
	jmp	fcberror_exit		; Use default Error handler



;	*****************************
;	***    DOS Function 19    ***
;	***      Current Disk     ***
;	*****************************

	Public	func19
func19:
	mov	al,current_dsk		; Get the current logical disk
	ret				; and return


;	*****************************
;	***    DOS Function 1A    ***
;	***   Set Disk Trans Adr  ***
;	*****************************

	Public	func1A
func1A:
	mov	dma_offset,dx		; set the PCMODE DMA Offset
	mov	dma_segment,es		;  and then the DMA Segment
	ret

;	*****************************
;	***    DOS Function 1B    ***
;	***    Def. Disk Info     ***
;	*****************************
;
	Public	func1B
func1B:

;	*****************************
;	***    DOS Function 1C    ***
;	***    Sel. Disk Info     ***
;	*****************************
;
	Public	func1C
func1C:
	call	set_retry_RF		; Valid to RETRY or FAIL
	xor	dh,dh			; Pass the drive requested
	call	fdos_DISKINFO		; find out about drive
	 jc	fdos_DI_error

	mov	cx,es:DDSC_SECSIZE[bx]	; Get the Physical Sector Size
	call	return_CX		; in bytes

	mov	dx,es:DDSC_NCLSTRS[bx]	; Convert the last cluster no
	dec	dx			; returned in DDSC to maximum
	call	return_DX		; number of clusters and return

	mov	al,es:DDSC_CLMSK[bx]	; get (sectors per cluster)-1
	inc	ax			; return sectors per cluster
	lea	bx,DDSC_MEDIA[bx]	; return address of media byte
f1B1C1F32_common:
	push	ds
	lds	di,int21regs_ptr
	mov	reg_DS[di],es
	mov	reg_BX[di],bx
	pop	ds
	ret

;	*****************************
;	***    DOS Function 1F    ***
;	***    Get Default DPB    ***
;	*****************************
;
	Public	func1F
func1F:

;	*****************************
;	***    DOS Function 32    ***
;	***   Get Requested DPB   ***
;	*****************************
;
	Public	func32
func32:
	call	set_retry_RF		; Valid to RETRY or FAIL
	mov	dh,80h			; set top bit - free space not needed
	call	fdos_DISKINFO		; and make the function call
	 jnc	f1B1C1F32_common	; exit using common code
;	 jc	fdos_DI_error		; check if error
;	cmp	dosfat,FAT32		; attempt to use on FAT32 drive?
;	 jne	f1B1C1F32_common	; exit using common code
;	mov	ax,0ffh
fdos_DI_error:
	jmp	fcberror_exit		; exit thru FCB error


;	*****************************
;	***    DOS Function 36    ***
;	***    Disk Free Space    ***
;	*****************************
;
	Public	func36
func36:
	call	set_retry_RF		; Valid to RETRY or FAIL
	xor	dh,dh			; clear out DH
	call	fdos_DISKINFO		; find out about drive
	 jnc	f36_OK			; CY set if we had a problem
	push	es
	push	bx
	call	error_exit		; generate a critical error
	pop	bx
	pop	es
	mov	ax,0FFFFh		; Invalid Drive Return 0FFFFh
	 jc	f36_exit		; No Carry
f36_OK:
	mov	cx,es:DDSC_SECSIZE[bx]	; Get the Physical Sector Size
	call	return_CX		; in bytes

	mov	dx,es:DDSC_NCLSTRS[bx]	; Convert the last cluster no
	cmp	dosfat,FAT32		; FAT32 file system?
	 jne	f36_OK20		; no, then use the 16-bit value
	mov	dx,es:word ptr DDSC_BCLSTRS[bx]	; Convert the last cluster no
	cmp	es:word ptr DDSC_BCLSTRS+2[bx],0	; more than fits into 16-bit register?
	 je	f36_OK20			; no, the value is exact
	mov	dx,0ffffh		; yes, so fake the value for maximum compatibility
f36_OK20:
	dec	dx			; returned in DDSC to maximum
	call	return_DX		; number of clusters

	mov	cx,es:DDSC_FREE[bx]	; get number of free clusters
	xor	dx,dx
	cmp	es:DDSC_NFATRECS[bx],0	; could this be a FAT32 drive?
	 jne	f36_OK25		; nah, it must be FAT12/16
	cmp	es:DDSC_MEDIA[bx],8fh	; or is it a CD-ROM drive?
	 je	f36_OK25		; apparently it is one, so handle it like FAT12/16
	mov	cx,es:word ptr DDSC_BFREE[bx]	; get number of free clusters (32-bit)
	mov	dx,es:word ptr DDSC_BFREE+2[bx]
f36_OK25:
	xor	ax,ax
	mov	al,es:DDSC_CLMSK[bx]	; get the sectors per cluster -1
	inc	ax			; AX = sectors per cluster
ifdef DELWATCH
	add	cx,FD_ADJUST		; now add in DELWATCH adjustment
	adc	dx,0
endif
f36_OK30:
	cmp	dx,0			; more than fits into 16-bit register?
	 je	f36_OK50			; no, the value is exact
	cmp	al,64			; cluster size already 64K?
	 jae	f36_OK40
	shl	al,1			; cluster size * 2
	shr	dx,1			; free clusters / 2
	rcr	cx,1
	jmp	f36_OK30			; try again
f36_OK40:
	test	dx,dx			; more than fits into 16-bit register?
	 je	f36_OK50			; no, the value is exact
	mov	cx,0fffeh		; yes, use a sane value for compatibility's sake
f36_OK50:
;	xor	ax,ax
;	mov	al,es:DDSC_CLMSK[bx]	; get the sectors per cluster -1
;	inc	ax			; AX = sectors per cluster

	mov	bx,cx
	call	return_BX		; return free clusters

f36_exit:
	jmp	return_AX_CLC

	public	fdos_DISKINFO
fdos_DISKINFO:
;-------------
; Called by func1B, func1C, func1F, func32, func36
; Even number functions have drive in DL
; Odd numbered function use default drive (0)
; 
	mov	ax,FD_DISKINFO		; get information about drive
	xchg	ax,FD_FUNC		; while getting orginal function #
;	test	al,1			; is it func1B/func1F ?
	cmp	al,1bh			; is it func1B/func1F ?
;	 jz	fdos_DI10		; if so these use the default
	 je	fdos_DI05		; if so these use the default
	cmp	al,1fh
	 jne	fdos_DI10
fdos_DI05:
	xor	dl,dl			;  drive so zero DL
fdos_DI10:
	mov	FD_DRIVE,dx		; drive in DX
	call	fdos_crit
	les	bx,FD_DPB		; get the DPB pointer
	ret

;	*****************************
;	***    DOS Function 2F    ***
;	***   Get Disk Trans Adr  ***
;	*****************************

	Public	func2F
func2F:
	les	bx,dword ptr dma_offset	; current dma address
	push	ds
	lds	di,int21regs_ptr
	mov	reg_ES[di],es
	mov	reg_BX[di],bx
	pop	ds
	ret


;	*****************************
;	***    DOS Function 41    ***
;	***    Delete File(s)     ***
;	*****************************
;
	Public	func41
func41:
	cmp	ss:remote_call,0
	 jne	fdos_common41
	mov	cl,06h

;	*****************************
;	***    DOS Function 39    ***
;	***  Create SubDirectory  ***
;	*****************************
;
	Public	func39
func39:

;	*****************************
;	***    DOS Function 3A    ***
;	***  Delete SubDirectory  ***
;	*****************************
;
	Public	func3A
func3A:

;	*****************************
;	***    DOS Function 3B    ***
;	***  Change SubDirectory  ***
;	*****************************
;
	Public	func3B
func3B:
;	*****************************
;	***    DOS Function 4E    ***
;	***    Find First File    ***
;	***    DOS Function 4F    ***
;	***    Find Next File     ***
;	*****************************
;
	Public	func4E
func4E:
	Public	func4F
func4F:
; Func 4F has no parameters, but using the same routine saves code

fdos_common41:
	call	set_retry_RF		; Valid to RETRY or FAIL
;	jmp	fdos_name

fdos_name:
	mov	FD_NAMEOFF,dx		; Initialise Pointer
	mov	FD_NAMESEG,es
	mov	FD_ATTRIB,cx		; and attributes
	mov	FD_LFNSEARCH,0		; do not use FAT+/LFN extensions
	jmp	fdos_ax_crit

;	*****************************
;	***    DOS Function 5B    ***
;	***   Create New File     ***
;	*****************************
;
	Public	func5B
func5B:

;	*****************************
;	***    DOS Function 3C    ***
;	***     Create a File     ***
;	*****************************
;
	Public	func3C
func3C:
	call	set_retry_RF		; Valid to RETRY or FAIL
	cmp	FD_FUNC,MS_X_CREAT	; is it a standard create ?
	 je	f3C_10
	mov	FD_FUNC,FD_NEW		; no, create a new file
f3C_10:
	mov	FD_MODE,DHM_RW		; create as read/write
	jmp	fdos_name		; go do it

;	*****************************
;	***    DOS Function 3D    ***
;	***      Open a File      ***
;	*****************************
;
	Public	func3D
func3D:
	call	set_retry_RF			; Valid to RETRY or FAIL
	cmp	ss:remote_call,0
	 jne	funcExtendedOpenCreate
	mov	cl,06h				; default search mode for local
;	jmp	funcExtendedOpenCreate		;  calls (remote it's in CL)
funcExtendedOpenCreate:
; On Entry:
;	FD_FUNC = function to carry out
;	ES:DX -> name
;	AX = open mode
;	CX = file attributes
;
	push	ax
	and	al,DHM_SHAREMSK
	cmp	al,DHM_DENY_NONE		; any funny share bits ?
	pop	ax
	 ja	open_mode_err
	push	ax
	and	al,DHM_RWMSK
	cmp	al,DHM_RW			; check RW bits are valid
	pop	ax
	 ja	open_mode_err
	mov	FD_MODE,ax			; Set Open Mode
	jmp	fdos_name

open_mode_err:
	mov	ax,ED_ACC_CODE			; This is an illegal open mode
	jmp	error_exit			;  return an error


;	*****************************
;	***    DOS Function 3F    ***
;	***    Read from Handle   ***
;	*****************************
;
	Public	func3F
func3F:

;	*****************************
;	***    DOS Function 40    ***
;	***    Write to a Handle  ***
;	*****************************
;
	Public	func40
func40:
	mov	al,OK_RIF			; Valid to RETRY,IGNORE or FAIL
	call	set_retry
	mov	FD_BUFOFF,dx
	mov	FD_BUFSEG,es
	mov	FD_COUNT,cx
	call	fdos_handle
	mov	dx,FD_COUNT
	 jnc	f40_10				; no error, return # xfered
	push	FD_HANDLE
	push	dx				; an error, try critical error
	call	error_exit			;  and if we get back here that
	pop	dx				;  means we Fail/Ignore it
	pop	bx
	 jc	f40_20				; are we returning an error ?
	push	dx				; no, we are ignoring it
	xor	cx,cx				;  CX:DX offset to skip
	mov	ax,(MS_X_LSEEK*256)+1		;  seek to current+offset
    call    dos_entry           
	pop	dx				; finally return # we wanted
f40_10:						;  to xfer
	xchg	ax,dx				; AX = return code
	jmp	return_AX_CLC
f40_20:
	ret

;	*****************************
;	***    DOS Function 42    ***
;	***    Move R/W Pointer   ***
;	*****************************
;
	Public	func42
func42:
	call	set_retry_RF			; Valid to RETRY or FAIL
	mov	word ptr FD_OFFSET+0,dx
	mov	word ptr FD_OFFSET+2,cx
	mov	FD_METHOD,ax
	call	fdos_handle
	 jc	f42_error			; Do not return the current
	mov	ax,word ptr FD_OFFSET+0		; file position if
	mov	dx,word ptr FD_OFFSET+2		; an error occurs
	call	return_DX
	jmp	return_AX_CLC

f42_error:
	jmp	error_exit

fdos_handle:
	mov	FD_HANDLE,bx
	jmp	fdos_crit

;	*****************************
;	***    DOS Function 43    ***
;	***    Change File Mode   ***
;	*****************************
;
;	Concurrent Password Support:-
;
;	     *WO* *GR* *OW*		This is the format of the Password
;	P---$RWED$RWED$RWED 		mode word which is compatible with
;					the FlexOS F_PROTECT field.
;	*WO* World (Ignored)
;	*GR* Group (Ignored)		The P flag is only used to designate
;	*OW* Owner (Used)		that the password is being updated.
;
	Public	func43
func43:
	call	set_retry_RF		; Valid to RETRY or FAIL
	mov	FD_FLAG,ax		; Requested Attributes ignored
	call	fdos_name		; if flags are not being set
	 jc	f42_error
	call	reload_registers	; get back AL
	test	al,81h
	 jnz    f43_exit        
	mov	cx,FD_ATTRIB
	call	return_CX		; Return Attribs/Password
	xchg	ax,cx			; Also in AX
f43_exit:
	jmp	return_AX_CLC

;	*****************************
;	***    DOS Function 46    ***
;	***    Force Dup Handle   ***
;	*****************************
;
	Public	func46
func46:
	xchg	bx,cx			; destination handle in BX
	mov	ah,MS_X_CLOSE		; try to close it but ignore
	call	dos_entry		;  errors as it may be already
	xchg	bx,cx			; now fall thru to handle func
	mov	ah,MS_X_DUP2		;  do do the duplicate
	
;	*****************************
;	***    DOS Function 45    ***
;	***    Duplicate Handle   ***
;	*****************************
;
	Public	func45
func45:

;	*****************************
;	***    DOS Function 3E    ***
;	***      Close a File     ***
;	*****************************
;
	Public	func3E
func3E:
	mov	al,OK_FAIL
	call	set_retry		; Valid to FAIL
	mov	FD_NEWHND,cx		; (in case it's force dup)
;	jmp	fdos_ax_handle

fdos_ax_handle:
	mov	FD_HANDLE,bx
	jmp	fdos_ax_crit

;	*****************************
;	***    DOS Function 5C    ***
;	***Lock/Unlock File Access***
;	*****************************
;
	Public	func5C
func5C:
	call	set_retry_RF		; Valid to RETRY or FAIL
	mov	FD_FUNC,FD_LOCK		; Lock/Unlock File
	mov	word ptr FD_OFFSET+0,dx	; Lock Offset (LOW)
	mov	word ptr FD_OFFSET+2,cx	; Lock Offset (HIGH)
	mov	word ptr FD_LENGTH+0,di	; Lock Length (LOW)
	mov	word ptr FD_LENGTH+2,si	; Lock Length (HIGH)
	mov	FD_LFLAG,ax		; Lock Type
	jmp	fdos_ax_handle

;	*****************************
;	***    DOS Function 47    ***
;	***    Get Current Dir    ***
;	*****************************
;
	Public	func47
func47:
	call	set_retry_RF		; Valid to RETRY or FAIL
	mov	FD_PATHOFF,si		; Initialise Pointer
	mov	FD_PATHSEG,es
	xchg	ax,dx			; drive in AL
	cbw				; make that AX
	mov	FD_DRIVE,ax
	jmp	fdos_ax_crit		; return garbage in AH (SPJ bug)

;	*****************************
;	***    DOS Function 53    ***
;	***  Build DPB from BPB   ***
;	*****************************
;
;	This function takes the BPB at DS:SI and builds a DDSC at ES:BP
;	
	Public	func53
func53:
	call	set_retry_RF		; Valid to RETRY or FAIL
	mov	FD_BPBOFF,si		; Segment and Offset of BPB
	mov	FD_BPBSEG,es
	mov	FD_DDSCOFF,bp		; Segment and Offset of DDSC
	mov	FD_SIG1,cx		; signatures for extended function
	mov	FD_SIG2,dx
	call	reload_ES
	mov	FD_DDSCSEG,es
	jmp	fdos_nocrit
;
;	*****************************
;	***    DOS Function 56    ***
;	***    Rename/Move a File ***
;	*****************************
;
	Public	func56
func56:
	call	set_retry_RF		; Valid to RETRY or FAIL
	mov	FD_NNAMEOFF,di		; New FileName
	push	es
	call	reload_ES		; callers ES:DI
	mov	FD_NNAMESEG,es		; point to new filename
	pop	es
	mov	FD_ONAMEOFF,dx		; Old FileName
	mov	FD_ONAMESEG,es
	cmp	ss:remote_call,0
	 jne	func56_10
	mov	cl,17h
func56_10:
	mov	FD_ATTRIB,cx
	jmp	fdos_crit

;	*****************************
;	***    DOS Function 57    ***
;	***   Get/Set File Time   ***
;	*****************************
;
	Public	func57
func57:
	call	set_retry_RF		; Valid to RETRY or FAIL
	mov	FD_DATE,dx
	mov	FD_TIME,cx
	mov	FD_SFLAG,ax
	cmp	al,1			; allow get/set only
	mov	ax,ED_FUNCTION		; all else fails horribly
	 ja	f57_error
	call	fdos_handle
	 jc	f57_error
    call    reload_registers  
	test	al,al
	 jnz	f57_exit
	mov	cx,FD_TIME
	call	return_CX		; return TIME in CX
	mov	dx,FD_DATE
	jmp	return_DX		; and DATE in DX

f57_exit:
	ret

f57_error:
	jmp	error_exit

;	*****************************
;	***    DOS Function 5A    ***
;	***   Create Unique File  ***
;	*****************************
;
	Public	func5A
func5A:
	mov	ax,ED_ACCESS		; assume we will have an error
	test	cx,DA_FIXED		;  because of silly attributes
	 jnz	func5A_40		; did we ?
	mov	si,dx			; find end of pathname
	xor	ax,ax			; no previous char
func5A_10:
	xchg	ax,bx			; BL = previous char
	lodsb	es:0			; get next char
	test	al,al			; is it the end of the string?
	 jz	func5A_20
	call	dbcs_lead		; is it a KANJI char?
	 jnz	func5A_10
	inc	si			; skip 2nd char of pair
	jmp	func5A_10
func5A_20:
	dec	si			; SI -> NUL
	cmp	bl,'\'			; was last char a '\' ?
	 je	func5A_30
	cmp	bl,'/'			; (or a '/' for unix freaks)
	 je	func5A_30
	mov	es:byte ptr [si],'\'	; append a '\' to name
	inc	si
func5A_30:
; Here ES:DX -> start of name, ES:SI -> position to append <unique name>,0
; CX = attribute for file.
; We generate a unique name based upon the time and date - if this already
; exists we keep retrying knowing the number of files is finite and we must
; succeed eventually
	push 	cx
	push 	dx
	push 	si			; append a unique'ish name
	call	func5A_append_unique_name
	pop 	si
	pop 	dx
	pop 	cx
	mov	ah,MS_X_MKNEW		; try to create unique file
	call	dos_entry
	 jnc	func5A_50		; exit if we succeeded
	mov	es:byte ptr [si],0	;  else forget extention
	cmp	ax,ED_EXISTS		; we only retry if it already exists 
	 je	func5A_30
func5A_40:
	jmp	error_exit		; return error to caller
func5A_50:
	jmp	return_AX_CLC		; return handle to caller

func5A_append_unique_name:
;-------------------------
; On Entry:
;	ES:DX -> start of name
;	ES:SI -> position to append <unique name>,0
;	CX = attribute for file.
; On Exit:
;	None
;
; We append a unique 8 character filename to this based upon the current
; date/time.
	push	si
	mov	ax,120dh
	int	2fh			; get date/time in AX & DX
	pop	di
	add	ax,unique_name_seed	; randomise the date otherwise we would
	inc	unique_name_seed	;  have one second wait between names
	call	func5A_app_AX		; store 4 ascii bytes
	xchg	ax,dx			; was DX = time
	call	func5A_app_AX		; store 4 ascii bytes
	xor	ax,ax
	stosb				; and a terminating NUL
	ret

func5A_app_AX:
; On Entry AX = word, ES:DI -> string
; Store 4 ASCII chars at ES:DI, based upon value in AX
	call	func5A_app_AL		; do low byte, falling thru to do high
func5A_app_AL:
	call	func5A_app_NIB		; low nibble, falling thru for high
func5A_app_NIB:
	push	ax
	and	al,0fh			; mask out a nibble
	add	al,'A'			; make it ASCII character
	stosb				; plant the string
	pop	ax
	mov	cl,4
	shr	ax,cl			; shift nibble
	ret


;	*****************************
;	***    DOS Function 60    ***
;	***Perform Name Processing***
;	*****************************
;
;	DS:SI point to a source string which contains a relative path
;	specification ES:DI points to a buffer which is at least 80
;	bytes longer than the source string.
;
;	The carry flag is set and AX contains an error code if the 
;	source string is mal formed. This function is used by the
;	Ryan-McFarland COBOL compiler.
;
	Public	func60
func60:
	call	set_retry_RF		; Valid to RETRY or FAIL
	mov	FD_FUNC,FD_EXPAND	; Expand a relative Path
	mov	FD_ONAMEOFF,si		; Initialise Source Pointer
	mov	FD_ONAMESEG,es
	mov	FD_NNAMEOFF,di		; Initialise Destination
	call	reload_ES		;  pointer
	mov	FD_NNAMESEG,es
	jmp	fdos_crit

;	*****************************
;	***    DOS Function 67    ***
;	***    Set/Handle Count   ***
;	*****************************
;
;	We impose a minimum of 20 handles regardless of what the caller
;	requests. If the request is <=20 we use the default handle table in
;	the PSP, else we allocate a memory block for the new table.
;	If the old handle table was in a memory block (ie. zero offset) we
;	will free that block up afterwards.
;	When shrinking the handle count the error ED_HANDLE will be given if
;	open files would have been lost.
;

	Public	func67
func67:
	push	ds
	mov	ds,current_psp		; DS -> current PSP blk
	cmp	bx,20			; force to minimum value of 20
	 jae	f67_10
	mov	bx,20			; never have less than 20 handles
f67_10:

	mov	cx,ds:PSP_XFNMAX	; we have this many handles
	sub	cx,bx			; are we growing ?
	 jbe	f67_20			; if shrinking make sure none open
	les	di,ds:PSP_XFTPTR	; point to existing handle table
	lea	di,[di+bx]		; point to 1st handle we will lose
	mov	al,0FFh			; they must all be closed
	repe	scasb			;  or we fail
	mov	ax,ED_HANDLE		; fail if we are in danger of losing
	 jne	f67_error		;  open handles
f67_20:
	
	push	bx			; save # of handles wanted
	push ds
	pop es
	mov	di,offset PSP_XFT	; ES:DI -> new handle table
	cmp	bx,20			;  if we are setting to the
	 je	f67_30			;   default size
	add	bx,15			; calculate memory required
	mov 	cl,4
	shr 	bx,cl			; num of paragraphs required
	xor	di,di			;  offset will be zero
	mov	ah,MS_M_ALLOC		;  allocate the memory
	call	dos_entry
	mov	es,ax			; ES:DI -> new handle table
f67_30:
	pop	bx			; BX = # handles wanted
	 jc	f67_error		; ES:DI -> new handle table

	mov	cx,bx			; CX = new # handles
	xchg	cx,ds:PSP_XFNMAX	; Update the Handle Count	

	mov	si,di			; Update the Table Offset
	xchg	si,ds:PSP_XFTOFF
	mov	ax,es
	xchg	ax,ds:PSP_XFTSEG	; Update the Table Segment
	mov	ds,ax			; DS:SI -> old handle table
					; ES:DI -> new handle table
					; CX = # old handles to copy
					; BX = # new handles desired 

	sub	bx,cx			; BX = # extra "closed" handles
	 jae	f67_40			; negative if we are shrinking
	add	cx,bx			; CX = # handles we inherit
	xor	bx,bx			; BX = no extra "closed" handles
f67_40:

	push	si			; save offset old handle table
	rep	movsb			; Copy the existing Handles
	pop	si			; SI = offset old handle table

	mov	al,0FFh			; AL = unused handle
	mov	cx,bx			; mark extra handles as unused
	rep	stosb			; mark as unused

	test	si,si			; do we have memory to free ?
	 jnz	f67_50
	mov	ah,MS_M_FREE
	call	dos_entry		; free up old handle table DMD
f67_50:
	pop	ds
	jmp	return_AX_CLC		; clear carry on return

f67_error:
	pop	ds			; restore DS
	jmp	error_exit		;  and return error AX to caller

;	*****************************
;	***    DOS Function 68    ***
;	***      Commit File      ***
;	*****************************
;
	Public	func68
func68:
	call	set_retry_RF		; Valid to RETRY or FAIL
	mov	FD_FUNC,FD_COMMIT	; Close a File Handle
	jmp	fdos_handle


;	*****************************
;	***    DOS Function 6C    ***
;	***     Extended Open     ***
;	*****************************
;

	Public	func6C
func6C:
	mov	al,OK_RF		; Valid to RETRY or FAIL
	test	bh,20h			; should we allow critical errors ?
	 jz	f6C10
	or	al,NO_CRIT_ERRORS	; no, so remember that
f6C10:
	call	set_retry
	mov	ax,ED_FUNCTION		; assume an illegal action code
	test	dx,not 0113h		; now check for sensible bits
	 jnz	f6C_error
	inc	dx
	test	dl,4			; also reject bits 0-3 = 3
	 jnz	f6C_error
	dec	dx

	xchg	ax,si			; ES:AX -> name
	xchg	ax,dx			; AX = action, ES:DX -> name
	xchg	ax,bx			; AX = open mode, BX = action

	test	bl,010h			; should we create if not there ?
	 jz	f6C_open		; no, skip the attempt at make new

	and	ah,(DHM_COMMIT+DHM_NOCRIT)/100h
	mov	FD_FUNC,FD_NEW		; create only if not there
	call	funcExtendedOpenCreate	; try to open/create the file

	mov	cx,2			; CX = file created
	 jnc	f6C_exit		; return this if we succeeded

f6C_open:
	call	reload_registers	; all registers as per entry
	xchg	ax,si			; ES:AX -> name
	xchg	ax,dx			; AX = action, ES:DX -> name
	xchg	ax,bx			; AX = open mode, BX = action
	push	bx			; save action
	and	ah,(DHM_COMMIT+DHM_NOCRIT)/100h
	mov	FD_FUNC,MS_X_OPEN	; try an open an existing file
	call	funcExtendedOpenCreate
	pop	bx			; recover action
	 jc	f6C_error		; return error if we can't open file

	mov	cx,1			; CX = file opened
	test	bl,001h			; should we open if it exists ?
	 jnz	f6C_exit		; yes, return the handle

	xchg	ax,bx			; BX = handle, AX = action
	test	al,002h			; should we replace the file ?
	mov	ax,ED_EXISTS		; if not close and return error
	 jz	f6C_close_on_error
	mov	ah,MS_X_WRITE
	xor	cx,cx			; write zero bytes to truncate file
	call	dos_entry
	 jc	f6C_close_on_error	; on error AX = error code, return it
	xchg	ax,bx			; AX = handle
	mov	cx,3			; CX = file replaced
f6C_exit:
	jmp	return_CX		; return CX to caller

f6C_close_on_error:
; File exits, but open should be failed (error code in AX)
	push	ax
	mov	ah,MS_X_CLOSE
	call	dos_entry		; close that file
	pop	ax
f6C_error:
	jmp	error_exit		; generate critical error

PCM_CODE	ends

PCMODE_DATA	segment public word 'DATA'
	extrn	current_psp:word
	extrn	current_dsk:byte
	extrn	dma_offset:word
	extrn	dma_segment:word
	extrn	int21regs_ptr:dword
	extrn	last_drv:byte
	extrn	remote_call:word
ifdef DELWATCH
	extrn	fdos_stub:dword
endif
PCMODE_DATA	ends

GLOBAL_DATA	segment public word 'DATA'
; When creating unique files we use the date/time to make the name.
; We add this seed value to "randomise" things, INCing on failure so the next
; attempt usually succeeds.

unique_name_seed	dw	0	; so we don't have to wait 1 second

GLOBAL_DATA	ends

end
