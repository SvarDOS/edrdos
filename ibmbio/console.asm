;    File              : $Workfile$
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
;
;    CONSOLE.ASM 1.8 93/07/22 19:43:16
;    switch over to REQUEST.EQU
;    CONSOLE.ASM 1.7 93/07/19 18:57:15
;    Add header
;
;    ENDLOG

	include BIOSGRPS.EQU
    include DRMACROS.EQU    ; standard DR macros
	include	IBMROS.EQU		; ROM BIOS equates
	include	REQUEST.EQU		; request header equates
	include	DRIVER.EQU		; device driver equates

page
CGROUP	group	CODE, RCODE, ICODE

CG	equ	offset CGROUP

	Assume	CS:CGROUP, DS:CGROUP, ES:CGROUP, SS:CGROUP

CODE	segment 'CODE'

INSERT_ACTIVE	equ	2		; set if cmdline insert active

	extrn	endbios:word		; for device driver INIT function
	extrn	FastConsole:far		; console output vector
    extrn   ControlBreak:far    ; ^C program abort
	extrn	local_flag:byte
	extrn	local_char:byte

CODE	ends

RCODE	segment 'RCODE'

;	Device driver function table

	Public	ConsoleTable

ConsoleTable:
	db	14			; Last supported command
	dw	CG:dd_init		; 0-initialize driver
	dw	CG:dd_error		; 1-media change check (disks only)
	dw	CG:dd_error		; 2-build BPB (disks only)
	dw	CG:dd_inioctl		; 3-IOCTL string input
	dw	CG:dd_input		; 4-input
	dw	CG:dd_poll		; 5-nondestructive input (char only)
	dw	CG:dd_instat		; 6-input status (char only)
	dw	CG:dd_inflush		; 7-input flush
	dw	CG:dd_output		; 8-output
	dw	CG:dd_output		; 9-output with verify
	dw	CG:dd_outstat		; 10-output status (char only)
	dw	CG:dd_outflush		; 11-output flush (char only)
	dw	CG:dd_outioctl		; 12-IOCTL string output
	dw	CG:dd_open		; 13-device open
	dw	CG:dd_close		; 14-device close


	Assume	DS:CGROUP, ES:Nothing, SS:Nothing

page
driver	proc	near

dd_outioctl:
;-----------
	mov	cx,es:RH4_COUNT[bx]	; get # of characters to output
	cmp	cx,2			; is it what we expect ?
	 jne	dd_error		; no, bail out
	push	ds
	lds	si,es:RH4_BUFFER[bx]	; DS:SI -> buffer
	lodsw				; get the data
	pop	ds
	xchg	ax,si			; save data in SI
	mov	ah,3			; read cursor position/type
	mov	bh,0			;  for page zero
	int	VIDEO_INT
	and	ch,0c0h			; make cursor start line = 0
	mov	al,cl			; AL = bottom line of cursor
	dec	ax			; AL = bottom line - 1
	test	si,INSERT_ACTIVE
	 jz	dd_outioctl10
	shr	al,1			; Insert active is 1/2 size block
dd_outioctl10:
	or	ch,al			; cursor start line is now here
	mov	ah,1			; set cursor type
	int	VIDEO_INT
	ret

dd_inioctl:
;----------
;	jmp	dd_error		; input not supported

dd_error:	; used for all unsupported driver functions
;--------
	mov	ax,RHS_ERROR+3		; "invalid command" error
	ret


poll_c1:
	mov	ah,0			; eat the next character
	int	KEYBOARD_INT		; take it out of ROS buffer
					;    and check again
poll_char:
;---------
;	exit:	ZF = 1  =>  no character ready
;		ZF = 0  =>  AL = character

	mov	al,local_char		; get the local character
	cmp	local_flag,TRUE		; do we have local character?
	 je	poll_c4			; no, check ROS keyboard status
	mov	ah,1			; get keyboard status (and character)
	int	KEYBOARD_INT		; read character from keyboard
	 jz	input9 			; skip if no character there
	test	ax,ax			; test if we got Ctrl-Brk
	 jz	poll_c1			;  and eat it if we have
poll_c3:				; we've got a character
	cmp	ax,7200h		; is this Ctrl-PrtSc?
	 jne	poll_c4
	mov	al,'P'-40h		; convert to ^P character
poll_c4:				; return the character in AL
	or	ah,TRUE			; indicate "ready" status
	ret

char_read:
;---------
	cmp	local_flag,TRUE		; do we have local character?
	 je	rdchr3			; handle that specially
	mov	ah,0
	int	KEYBOARD_INT		; read character from keyboard
	test	ax,ax			; test if we got Ctrl-Brk
	 jz	char_read		; retry in that case
	cmp	ax,7200h		; is this Ctrl-PrtSc?
	 jne	rdchr1			; skip if any other
	mov	al,'P'-40h		; convert to ^P character
	ret				;    and return it
rdchr1:					; else it is normal or function key
	test	al,al			; test if function key
	 jnz	rdchr2			; skip if normal character
	mov	local_flag,TRUE		; else return scan code as next
	mov	local_char,ah		;    character from next INPUT
rdchr2:					; return the character in AL
	ret
rdchr3:
	mov	local_flag,FALSE	; tell them buffer is invalid
	mov	al,local_char		; get the local charcater
	ret				;    and return it

	page
dd_input:	; 4-input
;--------
	mov	cx,es:RH4_COUNT[bx]	; get # of characters to output
	 jcxz	input9			; return if nothing to input
	push	es			; save ES (-> request header!)
	les	di,es:RH4_BUFFER[bx]	; get address of string to input
input1:
	call	char_read		; read 8-bit character
	stosb				; store it in input buffer
	loop	input1			; repeat for all characters
	pop	es
input9:
;	sub	ax,ax
;	ret

dd_outstat:	; 10-output status (char only)
;----------	; always ready, return no busy

dd_outflush:	; 11-output flush (char only)
;-----------	; unbuffered, perform no operation

dd_open:	; 13-device open
;-------	; no operation

dd_close:	; 14-device close
;--------	; no operation
	sub	ax,ax
	ret

dd_poll:	; 5-nondestructive input (char only)
;-------
	call	poll_char		; check keyboard status
	 jz	dd_instat20
	mov	es:RH5_CHAR[bx],al	; return the character
dd_poll10:
	sub	ax,ax
	ret

dd_instat:	; 6-input status (char only)
;---------
	call	poll_char		; check keyboard status
	 jnz	dd_poll10
dd_instat20:
	mov	ax,RHS_BUSY
	ret


dd_inflush:	; 7-input flush
;---------
	call	poll_char		; check keyboard status
	 jz	dd_poll10 		; skip if not ready
	call	char_read		; else read next character
	jmps	dd_inflush		; repeat until buffer empty

dd_output:	; 8-output
;---------
	mov	cx,es:RH4_COUNT[bx]	; get # of characters to output
	 jcxz	output9			; return if nothing to output
	push	es			; save ES (-> request header!)
	les	si,es:RH4_BUFFER[bx]	; get address of string to output
output1:
	lods	es:byte ptr [si]	; get next character to output
	pushf				; stack as per Int 29
	db	09Ah			; CALLF to our fastconsole entry
	dw	CG:FastConsole
	dw	70h
	loop	output1			; repeat for all characters
	pop	es
output9:
	sub	ax,ax
	ret


driver	endp

RCODE	ends				; end of device driver code

page

ICODE	segment	'ICODE'			; initialization code

dd_init:	; 0-initialize driver
;-------

	push	es
	sub	ax,ax
	mov	es,ax
	mov	ax,CG:FastConsole	; console output vector
	mov	di,FASTCON_INT*4	; setup fast single character
	stosw				; console output vector
	mov	ax,ds			; (identified by DA_SPECIAL)
	stosw
	mov	di,CTRLBRK_INT*4	; setup Ctrl-Break ROS vector
	mov	ax,CG:ControlBreak	;   for ^C program abort
	stosw				;   when a character has already
	mov	ax,ds			;   been typed into the ROS buffer
	stosw
	pop	es

ifdef JAPAN

	mov	ax,05000H		; Japanese mode (AX machine)
	mov	bx,81			; 081 : Japanese mode select
	int	VIDEO_INT		;

	mov	ax,05000h		; Japanese mode (AX machine)
	mov	bx,81			; 081 : Japanese mode select
	int	KEYBOARD_INT		;

endif

	mov	ax,14*256 + 13		; output a carriage return
	int	VIDEO_INT
	mov	ax,14*256 + 10		; output a line feed
	int	VIDEO_INT

	les	bx,REQUEST[bp]		; ES:BX -> request header

	mov	ax,endbios		; get last resident byte in BIOS
	mov	es:RH0_RESIDENT[bx],ax	; set end of device driver
	mov	es:RH0_RESIDENT+2[bx],ds

	sub	ax,ax			; initialization succeeded
    ret             

ICODE	ends

end
