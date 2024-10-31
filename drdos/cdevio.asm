title 'F_DOS Character device I/O'
;    File              : $CDEVIO.ASM$
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
;    CDEVIO.A86 1.18 94/12/21 11:16:29
;    Changed dev_dup to refuse from duplicating remote devices rather
;    than refuse from duplicating FCBs 
;    Made open_dev return IFN rather than XFN for FCB opens 
;    Made open_dev put the current time/date into DHNDL_TIME/DHNDL_DATE
;    CDEVIO.A86 1.16 94/10/07 09:00:18
;    Added patch 004 as source fix. Changed request header length for character
;    device to 16h. Used RH4_CDEV_LEN instead of RH4_LEN.
;    CDEVIO.A86 1.15 93/12/10 00:09:17
;    Move non-inherited bit to correct place in file handle
;    CDEVIO.A86 1.14 93/11/26 16:17:14
;    Update char_error so ES:SI -> device driver header itself;
;    ENDLOG

PCMCODE	GROUP	BDOS_CODE
PCMDATA	GROUP	BDOS_DATA,PCMODE_DATA

ASSUME DS:PCMDATA

	.nolist
	include psp.def
	include modfunc.def
	include fdos.equ
	include mserror.equ
	include doshndl.def
	include driver.equ
	include request.equ
	include cmdline.equ
	.list

PCMODE_DATA	segment public word 'DATA'
	extrn	fdos_buf:byte		; caveat: in PCMODE data segment
PCMODE_DATA	ends

BDOS_DATA	segment public word 'DATA'
	extrn	fdos_pb:word
	extrn	fdos_ret:word
BDOS_DATA	ends

;
;	Critical Error responses from the default INT 24 handler and
;	the DO_INT24 routine.
;
ERR_IGNORE	equ	0		; Ignore Error
ERR_RETRY	equ	1		; Retry the Operation
ERR_ABORT	equ	2		; Terminate the Process
ERR_FAIL	equ	3		; Fail Function

BDOS_CODE	segment public byte 'CODE'

	public	open_dev
	public	close_dev
	public	dup_dev
	public	read_dev
	public	write_dev
	public	first_dev
	public	ioc6_dev
	public	ioc7_dev

	extrn	cooked_write:near	; write to cooked console
	extrn	read_line:near		; read edited line
	extrn	break_check:near	; look for CTRL C
	extrn	char_error:near		; generate Int 24

	extrn	current_dsk2al:near	; get default drive in AL
	extrn	device_driver:near
	extrn	alloc_dhndl:near	; find free DHNDL_ structure
	extrn	alloc_xfn:near
	extrn	les_di_dmaptr:near
	extrn	release_handle:near
	extrn	get_xftptr:near
	extrn	timestamp_dhndl:near


;			   Character device functions
;			   ==========================

open_dev:
;--------
;	Entry:	ES:BX -> character device header

;	Note:	We own the MXdisk here, fdos_pb -> parameter data

	push 	es
	push 	bx			; save device driver address
	call	alloc_xfn		; DI = XFN
	push	di			; save XFN
	call	alloc_dhndl		; ES:BX -> DHNDL, AX = IFN
	pop	dx			; DX = XFN
	xchg	ax,si			; SI = IFN
	xor	ax,ax
	lea	di,DHNDL_DATRB[bx]	; point at start of area to fill
	mov	cx,DHNDL_UID-DHNDL_DATRB
	rep	stosb
	lea	di,DHNDL_SIZEX[bx]
	mov	cx,(DHNDL_LEN - DHNDL_SIZEX) / 2
	rep	stosw			; clear 64-bit high dwords size/seek
	mov	es:DHNDL_SHARE[bx],ax	; also zap share word	
	pop	es:DHNDL_DEVOFF[bx]
	pop	es:DHNDL_DEVSEG[bx]	; save device driver address

	push 	si
	push 	dx			; save IFN/XFN

	mov	es:DHNDL_COUNT[bx],1
	push	ds
	mov	ax,fdos_pb+6		; AX = open mode
	mov	cx,DHAT_DEV+DHAT_CLEAN+DHAT_TIMEOK
	lds	si,es:DHNDL_DEVPTR[bx]	; DS:SI -> device driver
	or	cl,ds:byte ptr DEVHDR.ATTRIB[si]
					; get attrib from device driver
	test	al,DHM_LOCAL		; is it private ?
	 jz	open_dev10
	and	al,not DHM_LOCAL	; clear inherit bit
	or	ch,DHAT_LOCAL/256	; rememmber it's local
open_dev10:
	mov	es:DHNDL_MODE[bx],ax
	mov	es:DHNDL_WATTR[bx],cx
	lea	si,DEVHDR.NAM[si]	; copy the device name
	lea	di,DHNDL_NAME[bx]	;  from the device header
	mov	cx,8/WORD
	rep	movsw
	mov	al,' '
	stosb               ; space the file extension
	stosb
	stosb
	pop	ds
	
	pop 	dx
	pop 	ax			; AX = IFN, DX = XFN

	push	es
	call	get_xftptr		; ES:DI -> PSP_XFTPTR for current_psp
	 jc	open_dev20		; no PSP, skip updating XFN
	add	di,dx			; ES:DI -> entry in PSP
	stosb				; update entry in PSP
	xchg	ax,dx
open_dev20:
	pop	es

	mov	fdos_ret,ax		; save XFN (IFN for FCB open) to return
	call	timestamp_dhndl
	or	es:DHNDL_ATTR[bx],DHAT_READY
;	jmp	open_dup_dev

open_dup_dev:
;------------
; On Entry:
;	ES:BX = DHNDL_
; On Exit:
;	None
;
	mov	al,CMD_DEVICE_OPEN
;	jmp	open_close_dev		; call device open routine

open_close_dev:
;--------------
; entry:	ES:BX = DHNDL_
;		AL = cmd_type (CMD_DEVICE_OPEN/CMD_DEVICE_CLOSE)
;
	push 	ds
	push 	es
	push 	bx
	push 	si
	lds	si,es:DHNDL_DEVPTR[bx]	; DS:SI -> device driver
	test	ds:DEVHDR.ATTRIB[si],DA_REMOVE
	 jz	ocdev1			 ; does the device support OPEN/CLOSE/RM
	sub	sp,RH13_LEN-2*word	; make space on stack for RH_
	push	ax			; RH_CMD = AL
	mov	ax,RH13_LEN
	push	ax			; RH_LEN = RH13_LEN
	push 	ss
	pop 	es
	mov	bx,sp			; ES:BX -> RH_
	call	device_driver		; call the device driver
	add	sp,RH13_LEN		; recover stack space
ocdev1:
	pop 	si
	pop 	bx
	pop 	es
	pop 	ds
	ret

dup_dev:
;-------
; On Entry:
;	ES:BX -> DHNDL_
; On Exit:
;	None
;	AX trashed
;
	mov	ax,es:DHNDL_WATTR[bx]
	test	al,DHAT_DEV
	 jz	dup_dev10		; skip if disk file
	test	ax,DHAT_REMOTE		; or remote
	 jz	open_dup_dev
dup_dev10:
	ret


close_dev:	; close character device handle
;---------
;	entry:	FDOS_PB+2 = user file handle
;		ES:BX = file handle
;	NOTE:	This is called with the MXdisk owned

	mov	al,CMD_DEVICE_CLOSE
	call	open_close_dev		; call device close routine
	call	release_handle		; release the XFN
	dec	es:DHNDL_COUNT[bx]	; one less XFN refers to this IFN
	ret


write_dev:	; write to character device handle
;---------
;	entry:	ES:BX -> DHNDL_ structure
;

	mov	cl,CMD_OUTPUT		; OUTPUT driver function
	or	es:DHNDL_ATTR[bx],DHAT_READY
	mov	al,es:DHNDL_ATTR[bx]	; get file info
	and	al,DHAT_BIN+DHAT_NUL+DHAT_CIN+DHAT_COT
	cmp	al,DHAT_CIN+DHAT_COT	; is it cooked console?
	 jne	inst_io			; no, device driver i/o
	mov	si,2[bp]		; SI -> parameter block
	mov	cx,ds:8[si]		; CX = string length
	 jcxz	write_dev20		; exit if nothing to write
	les	di,ds:4[si]		; ES:DI -> string to print
	mov	al,'Z'-40h		; we have to stop at ^Z
	repne	scasb			; scan for ^Z character
	 jne	write_dev10		; skip if ^Z not found
	inc	cx			; include ^Z in count of chars to skip
	sub	ds:8[si],cx		; subtract from total count
write_dev10:
	mov	bx,ds:2[si]		; BX = handle number
	mov	cx,ds:8[si]		; CX = string length
	mov	si,ds:4[si]		; ES:SI -> string to print
	call	cooked_write		; write w/ tab expansion & ^C checking
write_dev20:
	sub	bx,bx			; no errors
	ret				; return the result



read_dev:	; read to character device handle
;--------
;	entry:	ES:BX -> DHNDL_ structure

	mov	al,es:DHNDL_ATTR[bx]	; get the file info
	mov	ah,al			; save ioctl info
	and	al,DHAT_BIN+DHAT_CIN+DHAT_COT
	cmp	al,DHAT_CIN+DHAT_COT	; is it cooked console?
	 jne	rddev1			; skip if binary or not console
	jmp	read_con		; read from console handle
					; return the result
rddev1:
	test	ah,DHAT_READY		; previous EOF ?
	 jnz	rddev2			; yes we return now
	mov	di,2[bp]		; DI -> parameter block
	mov	ds:word ptr 8[di],0	; zero bytes xfered
	ret
rddev2:
	mov	cl,CMD_INPUT
inst_io:
; ES:BX = DHNDL_, CL = command
	sub	sp,RH4_CDEV_LEN		; make RH_ on stack
	mov	di,bx			; save address DHNDL_ in DI
	mov	bx,sp			; SS:BX -> request header

	mov	ds:RH_CMD[bx],cl
	mov	ds:RH_LEN[bx],RH4_CDEV_LEN
	mov	ds:RH_STATUS[bx],0	; status OK in case of zero chars
	mov	si,2[bp]		; DS:SI -> parameter block
	lea	si,4[si]		; point at buffer offset
	lodsw				; get buffer offset
; Normalising the address has been unnecessary so far
;	push	ax
;	and	ax,15			; normalise the address
;	pop	cx
;	shr	cx,1 ! shr cx,1
;	shr	cx,1 ! shr cx,1
	mov	ds:RH4_BUFOFF[bx],ax	; set buffer offset in request header
	lodsw				; get buffer segment
;	add	ax,cx			; add in normalised offset/16
	mov	ds:RH4_BUFSEG[bx],ax	; get buffer segment in request header
	lodsw				; get byte count
	xchg	ax,cx			; byte count in CX

; Parameter block created on stack at SS:BX and initialised for xfer
; ES:DI -> DHNDL_, CX = total number of bytes to xfer

inst_io20:
	mov	ds:RH4_COUNT[bx],cx	; try and do this many
	test	es:DHNDL_ATTR[di],DHAT_BIN+DHAT_NUL
					; are we in binary mode ?
	 jcxz	inst_io30		; return on zero length xfer
	 jnz	inst_io25		; binary, skip calling PCMODE
    mov ds:RH4_COUNT[bx],1  ; do one char at a time
	call	break_check		; call the break check routine
	cmp	ds:RH_CMD[bx],CMD_OUTPUT ; which way are we going 
	 jne	inst_io25
	call	inst_io_getchar		; AL = 1st char in the buffer
	cmp	al,1Ah			; EOF - don't send it or anything after
	 je	inst_io30		;  and exit without xfering any
inst_io25:
	push 	ds
	push 	es
	push 	di
	push 	cx
	lds	si,es:DHNDL_DEVPTR[di]	; DS:SI -> device driver
	push 	ss
	pop 	es			; ES:BX -> RH_
	call	device_driver		; execute the command
	pop 	cx
	pop 	di
	pop 	es
	pop 	ds
	 jns	inst_io_continue	; if no errors carry on
	push	es
	les	si,es:DHNDL_DEVPTR[di]	; ES:SI -> device driver
	call	char_error		; this will handle the Int 24
	pop	es
	cmp	al,ERR_RETRY		; what should we do ?
	 je	inst_io20		; retry the operation
	 ja	inst_io30		; fail - return error
	mov	ds:RH_STATUS[bx],RHS_DONE
	jmp	inst_io_ignore		; ignore - fiddle status and
inst_io_continue:			;  say we did it all
	mov	dx,ds:RH4_COUNT[bx]	; how many did we xfer ?
	test	dx,dx			;  if we haven't done any
	 jz	inst_io30		;  we are stuck so exit now
inst_io_ignore:
	call	inst_io_getchar		; AL = 1st char in the buffer
	add	ds:RH4_BUFOFF[bx],dx	; it may not enough so adjust offset
	sub	cx,dx			;  and number still to do
	cmp	ds:RH_CMD[bx],CMD_INPUT	; which way are we going - if input
	 jne	inst_io20		;  we need to check for CR/EOF
	test	es:DHNDL_ATTR[di],DHAT_BIN+DHAT_NUL
	 jnz	inst_io30		; if BIN then exit now
	cmp	al,13			; is it a CR character ?
	 je	inst_io30		;  yes, we stop now
	cmp	al,1Ah			; is it the EOF character ?
	 jne	inst_io20		;  yes, we aren't ready
	and	es:DHNDL_ATTR[di],not DHAT_READY
inst_io30:
	mov	di,2[bp]		; DI -> parameter block
	sub	ds:8[di],cx		; subtract # not xfered from byte count

	mov	ax,ds:RH_STATUS[bx]	; get result for later
	sub	bx,bx			; assume no errors
	test	ax,ax			; test error bit (8000h)
	 jns	rddev_no_err		; skip if ERROR set
	mov	bl,al			; AL is error code
	neg	bx			; make it negative code
	add	bx,ED_PROTECT		; normalize for extended errors
rddev_no_err:
	add	sp,RH4_CDEV_LEN		; free up RH_ on stack
	ret				; return BX

inst_io_getchar:
	push	ds
	lds	si,ds:RH4_BUFFER[bx]	; point to the users buffer
	lodsb				; get 1st char in the buffer
	pop	ds
	ret


read_con:	; handle read from cooked console
;--------
;	entry:	AH = DHNDL_ATTR
;		ES:BX -> DHNDL_
;		2[BP] -> F_DOS parameter block
;	exit:	BX = return value

	xor	cx,cx			; assume we've already had EOF
	test	ah,DHAT_READY		; now see if we have
	 jnz	con_dev_not_eof
	jmp	con_dev_exit		; yes, just return zero chars read
con_dev_not_eof:
	push	es
	push	bx			; save DHNDL_
con_dev_loop:
	mov	bx,word ptr fdos_buf	; get # of bytes already used
	xor	ax,ax
	xchg	al,bh			; get # bytes in the buffer
	inc 	ax
	inc 	ax			; also count the CR/LF
	sub	ax,bx			; have we any bytes left in the buffer?
	 ja	con_dev_cont		; yes, return them
	 				; no, we need a fresh input line
;	mov	fdos_buf,128		; read up to 128 characters
	mov	fdos_buf,CMDLINE_LEN	; read up to 128 characters
	mov	si,2[bp]		; SI -> parameter block
	mov	bx,ds:2[si]		; BX = input handle
	push	ds
	pop 	es
	mov	dx,offset fdos_buf	; ES:DX -> console buffer
	mov	cx,bx			; output to same handle as input
	push	bx
	push	bp
	call	read_line		; read edited line
	pop	bp
	mov	bl,fdos_buf+1		; # byte we have read
	xor	bh,bh			; BX = # of characters read
	mov	word ptr fdos_buf+2[bx],0A0Dh; append carriage return/line feed
	mov	fdos_buf,0		; start reading at beginning
	lea	si,fdos_buf+3[bx]	; Echo the LF character to the 
	pop	bx			; Same Output handle
	mov	cx,1			; Only One Character
	call	cooked_write
	jmp	con_dev_loop

con_dev_cont:				; BX = buffer offset
	mov	di,2[bp]		; DI -> parameter block
	mov	cx,ds:8[di]		; CX = # of bytes to read
	cmp	cx,ax			; reading more than available?
	 jbe	con_dev_ok		; no, read as much as you want
	mov	cx,ax			; else take all that there is
con_dev_ok:
	add	fdos_buf,cl		; update buffer index for next time
	les	di,ds:4[di]		; ES:DI -> buffer to read into
	lea	si,fdos_buf+2[bx]	; DS:SI -> function 10 buffer
	push	cx			; save count
	rep	movsb			; read all the data
	pop	cx			; restore count
	mov	al,1Ah			; now we look for EOF mark...
	push 	ds
	pop 	es
	lea	di,fdos_buf+2[bx]	; ES:DI -> function 10 buffer
	mov	si,cx			; keep count safe
	repne	scasb
	xchg	cx,si			; restore count
	pop	bx			; recover DHNDL_
	pop	es
	 jne	con_dev_exit		; if no EOF, skip to exit
	sub	cx,si			; subtract any after EOF mark
	dec	cx			; and the EOF mark itself
	and	es:DHNDL_ATTR[bx],not DHAT_READY
con_dev_exit:
	mov	di,2[bp]		; DI -> parameter block
	mov	ds:8[di],cx		; set # of characters read
	sub	bx,bx			; good return code
	ret



first_dev:	; F_DOS FIRST call on device performed
;---------	; Called with MXDisk
; On Entry:
;	ES:BX -> device header
; On Exit:
;	dma_buffer initialised with device name
;
	mov	dx,es			; DX:BX -> device header
	call	les_di_dmaptr		; ES:DI -> DMA buffer
	mov	al,0FFh			; invalidate search state for NEXT
	mov	cx,21
	rep	stosb
	mov	al,40h			; mark it as a device
	stosb
	sub	ax,ax
	mov	cx,4
	rep	stosw			; zero time, date, file size

	lea	si,10[bx]
	push	ds
	mov	ds,dx			; DS:SI -> name in device header
	mov	cx,4
	rep	movsw			; copy device name across
	pop	ds

	mov	cx,8
frstdev1:				; scan off trailing spaces
	cmp	es:byte ptr [di-1],' '
	 jne	frstdev2
	dec	di
	loop	frstdev1
frstdev2:
	xor	al,al
	stosb				; add a trailing NUL
	ret


ioc6_dev:	; IOCTL(6) - input status for device
;--------
;	entry:	ES:BX -> DHNDL_

	mov	al,CMD_INPUT_NOWAIT
	jmp	ioc67d			; call the device driver


ioc7_dev:	; IOCTL(7) - output status for device
;--------
;	entry:	ES:BX -> DHNDL_

	mov	al,CMD_OUTPUT_STATUS	; OUTPUT STATUS
ioc67d:					; common code for I/O STATUS
	push	ds
	sub	sp,RH5_LEN-2*word	; allocate request header on stack
	push	ax			; RH_CMD = AL
	mov	ax,RH5_LEN
	push	ax			; RH_LEN = RH5_LEN
	lds	si,es:DHNDL_DEVPTR[bx]	; DS:SI -> device driver
	push 	ss
	pop 	es
	mov	bx,sp			; ES:BX -> RH_
	mov	es:RH5_CHAR[bx],0	; zero the char
	call	device_driver		; do the CALLF's to the device driver
	xor	dl,dl			; assume not ready
	mov	dh,es:RH5_CHAR[bx]	; possible peeked character
	add	sp,RH5_LEN		; recover stack space
	pop	ds
	test	ax,RHS_ERROR+RHS_BUSY	; test if BUSY bit set in status
	 jnz	ioc67d_ret		; device not ready if error or busy
	dec	dl			; return ready DL = FF
ioc67d_ret:
	mov	si,2[bp]		; SI -> user's parameter block
	mov	ds:6[si],dx		; update returned status
	sub	bx,bx			; no error occurred
	ret				;	for now

BDOS_CODE	ends

	end				; of CDEVIO.A86
