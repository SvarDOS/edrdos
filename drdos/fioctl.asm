title 'FDOS IOCTL - DOS file system input/output control'
;    File              : $FIOCTL.ASM$
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
;    FIOCTL.A86 1.18 93/12/09 23:39:17
;    Move non-inherited bit to correct place in file handle
;    FIOCTL.A86 1.17 93/11/03 13:38:29
;    Int 21 4409 return 0x0080 if drive is joined
;    FIOCTL.A86 1.16 93/11/02 18:04:17
;    Int21/4400 from file returns AH=0
;    FIOCTL.A86 1.15 93/09/14 20:03:15
;    Trust LFLG_PHYSICAL
;    FIOCTL.A86 1.12 93/06/17 22:11:50 
;    support for ioctl 10/11 query ioctl support
;    FIOCTL.A86 1.11 93/06/16 16:21:37
;    Codepage preparation bug fixed
;    ENDLOG

;   Date       Modification
;   ---------  ---------------------------------------
;   29 Jun 89  Initial version splits from FDOS
;   21 Nov 89  iocE/F use relative unit number
;   12 Dec 89  ioc2/3 zero the unused portions of req hdr
;              save a few bytes in other ioc's while I'm here
;    4 Jun 90  default file access permissions and user group support
;    5 Jun 90  ioc0/1 tidied up
;   12 Jun 90  get_doshndl parameter in BX not AX
;    2 Oct 90  net_vec moves to per-VC basis (info held in CCB_)
;   13 feb 91  ioc1 tests FHIO_DEV, not HM_DEV, (123 MSNet printing)
;    7 may 91  ioc2,ioc3,ioc6,ioc7,iocC destabilised for Lanstatic
;              by-product is ioc6 for disks returns read-ahead char
;              in AH
;   28 feb 92  ioctl C checks bit 6 not bit 14 in DEVHDR.ATTRIB
;    3 aug 92  ioctl C/D pass thru' SI/DI
;    5 aug 92  substatial ioctl rework saves a few bytes - ioctl
;              request header now built by PCMODE

PCMCODE	GROUP	BDOS_CODE
PCMDATA	GROUP	BDOS_DATA,PCMODE_DATA

ASSUME DS:PCMDATA

	.nolist
	include fdos.equ
	include request.equ
	include msdos.equ
	include mserror.equ
	include doshndl.def	; DOS Handle Structures
	include driver.equ
	include f52data.def	; DRDOS Structures
	.list

PCMODE_DATA	segment public byte 'DATA'
	extrn	ioctlRH:byte		; request header is build in PCMODE
					;  data area
PCMODE_DATA	ends

BDOS_DATA	segment public word 'DATA'
	extrn	fdos_pb:word
	extrn	fdos_ret:word
	extrn	last_drv:byte
	extrn	req_hdr:byte
ifdef PASSWORD
	extrn	global_password:word
endif
BDOS_DATA	ends

BDOS_CODE	segment public byte 'CODE'

	extrn	local_disk:near
	extrn	device_driver:near
	extrn	block_device_driver:near
	extrn	fdos_error:near
	extrn	fdos_ED_DRIVE:near
	extrn	fdos_ED_FUNCTION:near
	extrn	fdos_read:near
	extrn	get_ddsc:near
	extrn	vfy_dhndl_ptr:near
	extrn	get_pb2_drive:near
	extrn	ioc6_dev:near		; IOCTL(6): input status for device
	extrn	ioc7_dev:near		; IOCTL(7): output status for device
	extrn	vfy_dhndl_ptr:near
	extrn	verify_handle:near
	extrn	reload_registers:near
ifdef JOIN
	extrn	get_ldt:near
endif
ifdef PASSWORD
	extrn	hash_pwd:near
endif

	public	fdos_ioctl

;	INPUT/OUTPUT CONTROL (IOCTL)

;	+----+----+----+----+----+----+----+----+----+----+
;	|    26   |  param  |  func   |   request header  |
;	+----+----+----+----+----+----+----+----+----+----+


;	entry:
;	------
;	param:	handle/drive on some functions
;	func:	sub function (0-A)
;	request header:	far pointer to IOCTL request header

;	exit:
;	-----
;	AX:	return code or error code ( < 0)
;	param:	return value from some functions



ioctl_tbl	dw	ioctl0		; 0-get handle status
		dw	ioctl1		; 1-set handle status
		dw	ioctl2		; 2-receive control string (handle)
		dw	ioctl3		; 3-send control string (handle)
		dw	ioctl4		; 4-receive control string (drive)
		dw	ioctl5		; 5-send control string (drive)
		dw	ioctl6		; 6-input status
		dw	ioctl7		; 7-output status
		dw	ioctl8		; 8-removable media check
		dw	ioctl9		; 9-networked drive check
		dw	ioctlA		; A-networked handle check
ifdef PASSWORD
		dw	ioctl54		; B-set global password
else
		dw	device_ED_FUNCTION
endif
		dw	ioctlC		; C-code page support
		dw	ioctlD		; D-generic IOCTL disk i/o
		dw	ioctlE		; E-get logical drive
		dw	ioctlF		; F-set logical drive
		dw	ioctl10		; 10-query IOCTL for char devs
		dw	ioctl11		; 11-query IOCTL for disks

NUM_IOCTL	equ	(offset $ - offset ioctl_tbl)/WORD



fdos_ioctl:
;----------
	mov	bx,2[bp]		; BX -> parameter block
	mov	bx,4[bx]		; get I/O control subfunction
	cmp	bx,NUM_IOCTL		; is it in the supported range?
	 jae	device_ED_FUNCTION	; skip if value too large
	shl	bx,1			; else make it word index
	jmp	ioctl_tbl[bx]		; call the right function
device_ED_FUNCTION:
	mov	bx,ED_FUNCTION		; "invalid function"
	ret



ioctl0:		; get device status
;------
;	Note:	We store the binary flag for the standard console
;		handles in the console mode, not in the file handle,
;		as the handles are shared across all consoles...

	call	vfy_dhndl_ptr		; check if good handle
	mov	ax,es:DHNDL_WATTR[bx]	; get attrib from doshndl
	test	ah,DHAT_REMOTE/256
	mov	ah,0			; files/networks return 0 in AH/DH
	 jnz	device_OK		; return attrib if network device
	test	al,DHAT_DEV		; or a file
	 jz	device_OK
	les	bx,es:DHNDL_DEVPTR[bx]	; get real device driver address
	mov	ah,es:byte ptr 5[bx]	; get device driver attribute
;	jmp	device_OK

device_OK:
;---------
	mov	bx,2[bp]		; get parameter block address
	mov	6[bx],ax		; save returned status
	xor	bx,bx			; successful return code
	ret

ioctl1:		; set device status
;------
	call	vfy_dhndl_ptr		; make sure this is an open handle
	test	es:DHNDL_WATTR[bx],DHAT_DEV
	 jz	device_ED_FUNCTION	; can't set status of disk files
	mov	ax,word ptr ioctlRH+14
					; pick up new device status
	test	ah,ah			; test if high byte is zero
	 jnz	device_ED_FUNCTION	; skip if O.K.
	or	al,DHAT_DEV		; make sure it stays a device
	mov	es:DHNDL_ATTR[bx],al	; store ioctl state in doshndl
	jmp	device_OK		; success


ioctl2:		; receive control string (devicehandle)
;------
ioctl3:		; send control string (device handle)
;------
ioctlC:		; generic ioctl (device handle)
;------
ioctl10:	; query ioctl support (device handle)
;-------
	call	vfy_dhndl_ptr		; check file handle #
	call	local_disk		; get MXdisk
	call	verify_handle		; make sure the handle is good
	 jnc	short_fdos_ED_FUNCTION	;  and is for a DEVICE
	xor	cx,cx			; device relative unit # always zero
	les	si,es:DHNDL_DEVPTR[bx]	; ES:SI -> device driver
	jmp	ioc2345CDcommon		;  now use common code

ioctlD:		; generic ioctl (drive)
;------
	call	local_disk		; get MXdisk, switch stack
	call	get_pb2_ddsc		; get drives DDSC_
	; We do not pass the logical and physical (un)locking to the device
	; driver, but simply return success.
	push	bx
	mov	bx,offset ioctlRH	; ES:BX -> request header
	mov	ax,ss:RH19_CATEGORY[bx]
	cmp	al,8h			; category must be 8 or 48h
	 je	ioctlD_cat_good
 	cmp	al,48h
 	 je	ioctlD_cat_good
 	jmp	ioctlD_10
 ioctlD_cat_good:
 	cmp	ah,RQ19_LOCKLOG
 	 je	ioctlD_ret
 	cmp	ah,RQ19_UNLOCKLOG
 	 je	ioctlD_ret
 	cmp	ah,RQ19_LOCKPHYS
 	 je	ioctlD_ret
 	cmp	ah,RQ19_UNLOCKPHYS
 	 je	ioctlD_ret
 ioctlD_10:
 	; All other functions than (un)locking are passed to the driver
	pop	bx
	jmp	ioctl11_10
ioctlD_ret:
	; Return "fake" success for (un)locking functions
	pop	bx
	xor	ax,ax			; zero is success
	ret

ioctl4:		; receive control string (drive)
;------
ioctl5:		; send control string (drive)
;------
ioctl11:	; query ioctl support (drive)
;-------
	call	local_disk		; get MXdisk, switch stack
	call	get_pb2_ddsc		; get drives DDSC_
ioctl11_10:
	mov	cl,es:DDSC_RUNIT[bx]	; get relative unit #
	les	si,es:DDSC_DEVHEAD[bx]	; ES:SI -> device header
;	jmp	ioctl2345Common		;  now use common code

ioc2345CDcommon:
;---------------
; On Entry:
;	ES:SI -> device driver header
;	CL = media byte (0 if character device)
;	CH = relative unit  (0 if character device)
;	MXDisk obtained
; On Exit:
;	IOCTL performed
;
	mov	ax,fdos_pb+6		; device driver support required
	test	es:DEVHDR.ATTRIB[si],ax	; does device driver support function ?
	 jz	short_fdos_ED_FUNCTION
	push	ds
	push 	es
	pop 	ds			; DS:SI -> device driver
	push 	ss
	pop 	es
	mov	bx,offset ioctlRH	; ES:BX -> request header
	mov	es:RH_UNIT[bx],cl	; set relative unit for block devices
	call	device_driver		; call the device driver
	pop	ds			; check for errors on return
;	jmp	fdos_error_check

fdos_error_check:
;-------------
; On Entry:
;	AX = Req Status
; On Exit:
;	SIGN set if an error, AX&BX = Internal DOS error code
;
	test	ax,ax			; top bit == 1 if error
	 jns	fdos_ioc_ec10		; skip if no errors
	xor	ah,ah
    add ax,-ED_PROTECT      
    neg ax          
	jmp	fdos_error		; return critical error
fdos_ioc_ec10:
	ret

;	IOCTL subfunctions:
	

get_pb2_ddsc:
;------------
; On Entry:
;	local_disk called, pick us drive from pb2
; On Exit:
;	ES:BX -> DDSC_ for the drive
;
	call	get_pb2_drive		; get specified drive
	cmp	al,last_drv		; is it a valid drive
	 ja	bad_drive
	call	get_ldt			; ES:BX -> LDT for this drive
	 jc	get_pb2_ddsc10		;  no LDT, physical=logical
	mov	ax,es:LDT_FLAGS[bx]
	test	ah,LFLG_NETWRKD/256
	 jnz	short_fdos_ED_FUNCTION	; reject network drives
	test	ah,LFLG_PHYSICAL/256
	 jz	bad_drive
	test	ah,LFLG_JOINED/256
	 jnz	bad_drive		; reject JOIN'd drives
	mov	al,es:LDT_NAME[bx]	; get physical drive from LDT
	and	al,1Fh			; convert to 1 based drive
	dec	ax			; make that zero based
get_pb2_ddsc10:
	call	get_ddsc		; ES:BX -> DDSC_
	 jc	bad_drive		;  or does it?
	ret

bad_drive:
	jmp	fdos_ED_DRIVE		; invalid drive specified

short_fdos_ED_FUNCTION:
	jmp	fdos_ED_FUNCTION


ioctl8:		; removable media check
;------
	call	local_disk		; get MXdisk, switch stack
	call	get_pb2_ddsc		; get drives DDSC_
	push	ds
	lds	si,es:DDSC_DEVHEAD[bx]	; DS:SI -> device driver
	test	ds:DEVHDR.ATTRIB[si],DA_REMOVE
	pop	ds			; do we support the check ?
	 jz	short_fdos_ED_FUNCTION	; if we don't then don't ask
	mov	req_hdr,RH15_LEN
	mov	req_hdr+2,CMD_FIXED_MEDIA
	call	block_device_driver	; call the device driver
	 js	short_fdos_ED_FUNCTION
	and	ax,RHS_BUSY		; BUSY bit set if permanent - we just
	xchg	ah,al			;  need to get bit in the right place
	shr	ax,1			; now 1 if permanent media
	mov	fdos_pb+6,ax		; return status removable (=0)
ioctl8_10:
	ret



ioctl6:		; file input status
;------
	call	vfy_dhndl_ptr		; make sure this is an open handle
	mov	ax,es:DHNDL_WATTR[bx]
	test	ax,DHAT_REMOTE
	 jnz	ioctl6_10		; always ask networked handles
	test	ax,DHAT_DEV
	 jz	ioctl6_10		; files are always askable
	jmp	ioc6_dev

ioctl6_10:				; disk files/network devices
	push	es:DHNDL_POSLO[bx]	; save current position in file
	push	es:DHNDL_POSHI[bx]	;  so we can read ahead
ifdef FATPLUS
	push	es:DHNDL_POSXLO[bx]
	push	es:DHNDL_POSXHI[bx]
endif
	push	es
	push	bx			; save DHNDL_ too..
	push	bp			; save stack frame
	mov	si,2[bp]		; SI -> parameter block
	mov	ax,1
	push	ax			; read 1 byte ahead
	push	ds			; use fdos_pb as read-ahead
	lea	ax,6[si]		;  buffer
	push	ax			
	push	ds:word ptr 2[si]	; user file number 
	mov	ax,MS_X_READ		; READ function #, so we create
	push	ax			;  a dummy fdos_pb
	mov	bx,sp			; SS:BX -> dummy fdos_pb
	mov	cx,offset ioctl6_20	; CX -> return address
	push	cx			; Return to here
	push	ss			; save parameter segment
	push	bx			; save parameter offset
	push	ax			; save sub-function
	mov	bp,sp			; SS:BP -> working variables
	call	fdos_read		; make FDOS_READ do the hard word
	add	sp,4*WORD		; discard param's on stack
ioctl6_20:
	add	sp,4*WORD		; discard most of dummy fdos_pb
	pop	cx			; return # read
	cmp	bx,ED_LASTERROR		; did we succeed ?
	 jb	ioctl6_30		; if so we can trust # read
	xor	cx,cx			; else in error assume nothing
ioctl6_30:
	pop	bp			; recover stack frame
	pop	bx			; rewind DHNDL_POS to where
	pop	es
ifdef FATPLUS
	pop	es:DHNDL_POSXHI[bx]	;  it was before we started
	pop	es:DHNDL_POSXLO[bx]
endif
	pop	es:DHNDL_POSHI[bx]
	pop	es:DHNDL_POSLO[bx]
	mov	ax,1a00h		; assume not ready
	 jcxz	ioctl6_40
	dec	ax			; AL = FF, ie. ready
	mov	si,2[bp]		; SI -> parameter block
	mov	ah,ds:byte ptr 6[si]	; get character we read
ioctl6_40:
	jmp	device_OK


ioctl7:		; file output status
;------
	call	vfy_dhndl_ptr		; make sure this is an open handle
	mov	ax,0FFh			; assume it's networked/disk
	mov	dx,es:DHNDL_WATTR[bx]
	test	dx,DHAT_REMOTE
	 jnz	ioctl6_40		; networked handles are always ready
	test	dx,DHAT_DEV
	 jz	ioctl6_40		; files are always ready
	jmp	ioc7_dev		; devices we ask...



ioctl9:		; networked drive check
;------
	call	local_disk		; get disk semaphore
	call	get_pb2_drive		; get specified drive
	call	get_ldt			; ES:BX -> LDT for this drive
	 jc	ioctl940
	mov	ax,es:LDT_FLAGS[bx]
	test	ah,LFLG_NETWRKD/256
	 jz	ioctl910
if 1
	mov	ax,1000h		; return drive as remote
else
	les	di,es:LDT_PDT[bx]	; pick up network internal pointer
	mov	ax,es:4[di]		; pick up garbage
	or	ah,10h			; return drive as remote
endif
	jmp	ioctl930

ioctl910:
	test	ah,LFLG_PHYSICAL/256
	 jz	ioctl940
	test	ah,LFLG_SUBST/256
	xchg	ax,dx			; save flags
	mov	ax,8000h		; assume it's SUBST'd
	 jnz	ioctl920
	test	dh,LFLG_JOINED/256
	xchg	al,ah			; assume it's JOIN'd
	 jnz	ioctl930
	xor	ax,ax			; clear if not
ioctl920:
	push	ax
	call	get_pb2_ddsc		; get drives DDSC_
	pop	ax
	les	si,es:DDSC_DEVHEAD[bx]	; ES:SI -> device driver
	or	ax,es:4[si]		; get device attributes
ioctl930:
	mov	fdos_pb+6,ax		; return updated status
	ret

ioctl940:
	jmp	fdos_ED_DRIVE		; return ED_DRIVE error


ioctlA:		; networked handle check
;------
	call	vfy_dhndl_ptr
	mov	ax,es:DHNDL_WATTR[bx]
	jmp	device_OK		; return attributes


ioctlE:
;------
	call	local_disk
	mov	al,CMD_GET_DEVICE	; get logical device
	jmp	iocEFcommon		; common code for IOCTL(E)/IOCTL(F)

ioctlF:
;------
	call	local_disk
	mov	al,CMD_SET_DEVICE	; set logical device
iocEFcommon:
    mov req_hdr,RH24_LEN    
	mov	req_hdr+2,al
	call	get_pb2_ddsc		; get drives DDSC_
	inc	ax			; make drive one-relative
	mov	req_hdr+13,al		; set this as new drive
	xor	ax,ax			; assume not supported
	push	ds
	lds	si,es:DDSC_DEVHEAD[bx]	; does device driver support function ?
	test	ds:DEVHDR.ATTRIB[si],DA_GETSET
	pop	ds
	 jz	iocF_single		; skip if not supported
	call	block_device_driver	; call the device driver
	call	fdos_error_check	; return any errors
	mov	al,req_hdr+1		; get returned drive
iocF_single:				; AX = return value
    mov ah,7            
	mov	fdos_pb+6,ax		; return the drive
	ret

ifdef PASSWORD

ioctl54:	; set global password
;-------
	call	local_disk		; get the MX disk
	push	ds
	lds	si,dword ptr ioctlRH+14
	call	hash_pwd		; encrypt new default password
	pop	ds
	mov	global_password,ax
	ret

endif

BDOS_CODE	ends

end
