;    File              : $Workfile: SERPAR.ASM$
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
;    SERPAR.ASM 1.7 93/07/22 19:44:27
;    switch over to REQUEST.EQU
;    SERPAR.ASM 1.6 93/07/19 18:57:59
;    Add header
;
;    ENDLOG

	include BIOSGRPS.EQU
	include	DRMACROS.EQU		; standard DR macros
	include	IBMROS.EQU		; ROM BIOS equates
	include	REQUEST.EQU		; request header equates
	include	DRIVER.EQU		; device driver equates

page
CGROUP	group	CODE, RCODE, ICODE

CG	equ	offset CGROUP

	Assume	CS:CGROUP, DS:CGROUP, ES:CGROUP, SS:CGROUP

CODE	segment 'CODE'

	extrn	endbios:word		; for device driver INIT function
	extrn	serparFlag:byte
	extrn	serparChar:byte

CODE	ends

RCODE	segment 'RCODE'

	Public	SerParCommonTable

SerParCommonTable:
	db	19			; Last supported function
	dw	CG:dd_init		; 0-initialize driver
	dw	CG:dd_error		; 1-media change check (disks only)
	dw	CG:dd_error		; 2-build BPB (disks only)
	dw	CG:dd_error		; 3-IOCTL string input
	dw	CG:dd_input		; 4-input
	dw	CG:dd_poll		; 5-nondestructive input (char only)
	dw	CG:dd_instat		; 6-input status (char only)
	dw	CG:dd_inflush		; 7-input flush
	dw	CG:dd_output		; 8-output
	dw	CG:dd_output		; 9-output with verify
	dw	CG:dd_outstat		; 10-output status (char only)
	dw	CG:dd_outflush		; 11-output flush (char only)
	dw	CG:dd_error		; 12-IOCTL string output
	dw	CG:dd_open		; 13-device open
	dw	CG:dd_close		; 14-device close
	dw	CG:dd_error		; 15-removable media check (disks only)
	dw	CG:dd_error		; 16-n/a
	dw	CG:dd_error		; 17-n/a
	dw	CG:dd_error		; 18-n/a
	dw	CG:dd_genioctl		; 19-generic IOCTL


	Assume	DS:CGROUP, ES:Nothing, SS:Nothing

page
driver	proc	near

dd_error:	; used for all unsupported driver functions
;--------
	mov	ax,RHS_ERROR+3		; "invalid command" error
	ret

	page

poll_char:
;---------
;	exit:	ZF = 1  =>  no character ready
;		ZF = 0  =>  AL = character

	cmp	serparFlag[si],TRUE	; do we have local character?
	 jne	poll_c2			; skip if not
	mov	al,serparChar[si]	; get the local charcater
	jmps	poll_c4			;    and return it
poll_c2:				; need to check ROS keyboard status
	mov	ah,3			; get serial status status
	int	ASYNC_INT		; read serial status
	test	ah,1			; test "received data" bit
	 jz	poll_c9			; skip if no character there
	mov	ah,2			; read the character
	int	ASYNC_INT		; character returned in AL
	mov	serparChar[si],al	; save it for look ahead
	mov	serparFlag[si],TRUE	; we've got a local character
poll_c4:				; return the character in AL
	or	ah,TRUE			; indicate "ready" status
	ret
poll_c9:
	sub	ax,ax			; indicate "not-ready" status
	ret				; (driver is busy)


char_read:
;---------
    xor ax,ax 
	cmp	serparFlag[si],TRUE	; do we have local character?
	 jne	rdchr1
	mov	serparFlag[si],FALSE	; tell them buffer is invalid
	mov	al,serparChar[si]	; get the local character
	ret				;    and return it
rdchr1:
	mov	ah,2			; read character from serial port
	int	ASYNC_INT		; call the ROM BIOS
	and	ah,0eh			; only worry about these error bits
	ret				; and return the character

	page
dd_input:	; 4-input
;--------
	push	es			; save ES (-> request header!)
	mov	cx,es:RH4_COUNT[bx]	; get # of characters to output
	 jcxz	input9			; return if nothing to input
	sub	dx,3			; convert to serial port #
	 jb	input9			; return none read if parallel port
	mov	si,dx			; SI = serial port index
	les	di,es:RH4_BUFFER[bx]	; get address of string to input
input2:
	call	char_read		; read 8-bit character
	test	ah,ah			; did we read OK ?
	 jnz	input9			; if we have an error stop now
	stosb				; store it in input buffer
	loop	input2			; repeat for all characters
input9:
	pop	es
	sub	es:RH4_COUNT[bx],cx	; update to actual number xfered
	sub	ax,ax
	ret

dd_poll:	; 5-nondestructive input (console only)
;-------
	cmp	dx,3			; check if a parallel port
	 jb	poll_busy		;  they are never ready
	sub	dx,3
	mov	si,dx			; SI = serial port index
	call	poll_char		; check keyboard status
	 jz	poll_busy
	mov	es:RH5_CHAR[bx],al	; return the character
	sub	ax,ax
	ret
poll_busy:
	mov	ax,RHS_BUSY		; indicate no character waiting
	ret

dd_instat:	; 6-input status (char only)
;---------
	cmp	dx,3			; check if a parallel port
	 jb	poll_busy		;  if so it's always busy
	sub	dx,3
	mov	si,dx			; SI = serial port index
	call	poll_char		; check keyboard status
	 jz	poll_busy
	sub	ax,ax			; indicate "not ready" status
	ret

dd_inflush:	; 7-input flush
;---------
	cmp	dx,3			; check if a parallel port
	 jae	inflsh1			; skip if serial port
	mov	ax,RHS_ERROR+11		; return "read error" if attempting
	ret				;  to read from the parallel port
inflsh1:
	sub	dx,3
	mov	si,dx			; SI = serial port index
inflsh2:
	call	poll_char		; check keyboard status
	 jz	inflsh_ret		; skip if not ready
	call	char_read		; else read next character
	jmps	inflsh2			; repeat until buffer empty
inflsh_ret:				; keyboard buffer empty
	sub	ax,ax			; return success
	ret

dd_output:	; 8-output
;---------
	mov	cx,es:RH4_COUNT[bx]	; get # of characters to output
	 jcxz	output5			; return if nothing to output
	push	es			; save ES (-> request header!)
	les	si,es:RH4_BUFFER[bx]	; get address of string to output
	sub	dx,3			; test if parallel port
	 jae	output2			; skip if serial port
	add	dx,3			; back to parallel port number
output1:
	lods	es:byte ptr [si]	; get next character to output
	mov	ah,0			; output AL to parallel port
	int	PRINTER_INT		; output to parallel port
	mov	al,2			; "not ready" error
	test	ah,PRN_TIMEOUT		; printer not ready?
	 jnz	output4			;  yes, return error
	mov	al,9			; "printer out of paper" error
	test	ah,PRN_PAPER		; printer out paper?
	 jnz	output4			;  yes, return error
	inc	ax			; "write fault" error
	test	ah,PRN_ERROR		; test if other errors
	 jnz	output4			; skip if any errors occurred
	loop	output1			; else repeat for all characters
	jmps	output4			; return successfully when done

output2:				; output is for serial port
	lods	es:byte ptr [si]	; get next character to output
	mov	ah,1			; output AL to serial port
	int	ASYNC_INT		; output to serial port
	mov	al,2			; "not ready" error
	test	ah,AUX_ERROR		; test if time out etc.
	 jnz	output4			; skip if any errors occurred
	loop	output2			; else repeat for all characters
output4:
	mov	ah,RHS_ERROR shr 8	; assume an error code
	pop	es
	sub	es:RH4_COUNT[bx],cx	; update to actual number xfered
	 jz	output6			; none xfered is an error
output5:
	sub	ax,ax			; return successfully when done
output6:
	ret



dd_outstat:	; 10-output status (char only)
;----------
	cmp	dx,3			; test if parallel port
	 jae	outstat1
	mov	ah,2			; read parallel port status
	int	PRINTER_INT		; call the ROM BIOS
	test	ah,80h			; test "not busy" bit
	 jnz	outstat_ready		; if not busy then ready for output
	jmps	outstat_busy		;    else we must be still busy
outstat1:
	sub	dx,3
	mov	ah,3			; get status for serial port
	int	ASYNC_INT
	test	ah,20h			; transmit buffer register emmpty?
	 jz	outstat_busy
	test	al,20h			; data set ready?
	 jz	outstat_busy
outstat_ready:
	sub	ax,ax			; always ready, return no busy
	ret
outstat_busy:
	mov	ax,RHS_BUSY
	ret

dd_outflush:	; 11-output flush (char only)
;-----------
	sub	ax,ax			; unbuffered, perform no operation
	ret


	page
dd_open:	; 13-device open
;-------
	sub	ax,ax			; no operation
	ret


dd_close:	; 14-device close
;--------
	sub	ax,ax			; no operation
	ret


	page
dd_genioctl:	; 19-generic IOCTL
;-----------
    sub ax,ax           
	ret

driver	endp

RCODE	ends				; end of device driver code

page

ICODE	segment 'ICODE'			; initialization code

dd_init:	; 0-initialize driver
;-------
	cmp	dx,3			; check if serial or parallel
	 jae	init1			; skip if serial port setup
	mov	ah,1			; initialize parallel port
	int	PRINTER_INT		; call the ROM BIOS
	jmps	init2
init1:
	sub	dx,3
	mov	ah,0			; initialize serial port
	mov	al,0A3h			; 2400 Bd, no parity, 8 data, 1 stop
	int	ASYNC_INT		; call the ROM BIOS
init2:
	les	bx,REQUEST[bp]		; ES:BX -> request header

	mov	ax,endbios
	mov	es:RH0_RESIDENT[bx],ax	; set end of device driver
	mov	es:RH0_RESIDENT+2[bx],ds

	sub	ax,ax			; initialization succeeded
	ret				; (BIOS init always does...)

ICODE	ends

	end
