;    File              : $CIO.ASM$
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
;    CIO.A86 1.20 94/12/01 10:05:21
;    Made cooked_write and is_device aware of FCB writes;    
;    CIO.A86 1.19 94/06/28 12:21:07
;    Fix last_key_ext bug
;    CIO.A86 1.18 94/05/12 14:06:22
;    The routine cooked_status now sets a flag last_key_ext if the keycode is 0.
;    On entry, it checks this flag to see if the last one was 0, and if so does
;    not do the checks for the control keys. In this way, Alt-R and Alt-Q can
;    be distinguished from Ctrl-S and Ctrl-P.
;    CIO.A86 1.17 93/12/21 17:58:15
;    Preserve BX round clock read
;    Update char_error so DS:SI -> device driver header itself
;    CIO.A86 1.10 93/05/06 19:28:03
;    Move int 23/28 support to CIO.
;    Read the clock in idle_dev, not int 28 loop.
;    CIO.A86 1.9 93/05/05 23:30:44
;    int 2A/84 is now only generated on input-and-wait functions
;    CIO.A86 1.8 93/03/25 15:05:56
;    tweak console block output
;    ENDLOG
;
;	This module contains all the Character I/O functions used by PCMODE
;
; 12 Nov 87 Disable Control-Break when the Console Output mode is RAW
; 24 Feb 88 Display Control characters correctly. ie "^X"
; 23 May 88 Support ^S to Pause screen output.
; 25 May 88 Support Control-P for Cooked_Write and remove Kanji Character
;           check.
; 26 May 88 Check for CTLC on CON_DEV when character input is redirected.
;           Correctly detect EOF on redirected input.
; 17 Aug 88 Call PRN device with Open/Close on ^P
; 30 Aug 88 Jump to correct exit when Open/Close is not supported by a 
;           device driver for ^P.
; 14 Sep 88 Break checking should only be carried out when the INDOS_FLAG
;           is 1. (Novell and Cntrl-C).
; 03 Sep 88 Return the character output by INT21/04,05,06 in AL.
; 10 Nov 88 Preserve ES when calling any Device Driver (Revalation DEVDRVR)
; 15 Dec 88 Check STDERR for Control-C if it is a Device.
; 15 Mar 89 Check for CTLC during Cooked Write.
; 16 Mar 89 Explicitly allow INT 28 during char reads (SmartNotes bug)
; 25 Apr 89 Execute break_check after getting the console status INT21/0B
;  2 May 89 Save Device driver STRAT and INT address's on the stack
; 10 May 89 Now check keyboard more often during cooked write
; 25 May 89 Move INT28 flag to PCMIF.PCM
;  6 Sep 89 Enter/Exit critical region round device request
; 26 Oct 89 saving some bytes again...
; 25 Jan 90 Insert IDLE Detection Code
; 29 Jan 90 Int 2A critical section support added to device_callf
;  7 Mar 90 Convert to register preserved function calls
; 27 Mar 90 cooked_write checks STD_OUT for ctl-s ctl-p etc (STD_IN may
;           have been redirected)
; 29 Mar 90 preserve BX round device_callf (3+Share CLOCK$ bug)
; 12 Jun 90 get_doshndl parameter BX not AX
; 15 Oct 90 Added support for Return Interim Character flag (see PSP_RIC).
; 26 Oct 90 handle PSP=0 (ie. FCB device I/O)
;  1 mar 91 break_check now goes to con_device, not STDERR
; 17 jun 91 ij	fix to cooked_out to avoid status checks if STDOUT redirected

	.nolist
	include	pcmode.equ
	include driver.equ
	include	request.equ
	include	msdos.equ
	include	fdos.equ
	include	psp.def
	include	mserror.equ
	include	char.def
	include	redir.equ
	include	doshndl.def
	.list

PCMDATA group PCMODE_DATA,GLOBAL_DATA,FIXED_DOS_DATA
PCMCODE group PCM_CODE,PCM_RODATA

ASSUME DS:PCMDATA

CIO_CTLP	equ	00000001b	; Printer Echo State
CIO_HANDLE	equ	00000010b	; use handle rather than Int 29
CIO_RAW		equ	00000100b	; no "cooked_status" checks

CHECK_EVERY	equ	80		; check keyboard every "n" characters

PCM_CODE	segment public byte 'CODE'
	extrn	char_error:near
	extrn	device_driver:near
	extrn	dos_entry:near
	extrn	get_dseg:near
	extrn	ifn2dhndl:near
	extrn	int21_entry:near
	extrn	int21_func:near
	extrn	read_line:near
	extrn	ReadTimeAndDate:near
	extrn	reload_registers:near

;	*****************************
;	***    DOS Function 01    ***
;	***  Keybd Input W/Echo   ***
;	*****************************
;
	Public	func01
func01:
;
; Entry:
;	AH  ==	01h
; Exit:
;	AL  ==	char
;
	call	func08			; Read 1 character from Standard Input
					; and check for Control-C
	xchg	ax,dx			; echo using common code

;	*****************************
;	***    DOS Function 02    ***
;	***     Display Output    ***
;	*****************************
;
	Public	func02
func02:
;
; Entry:
;	AH  ==	02h
;	DL  ==	char to display
;
	push	dx			; char on stack
	push 	ss
	pop 	es
	mov	si,sp			; ES:DX -> character
	mov	cx,1
	call	stdout_cooked_write	; write character
	pop	ax			; recover char
	ret

;	*****************************
;	***    DOS Function 03    ***
;	***    Auxiliary Input    ***
;	*****************************
;
	Public	func03
func03:
;
; Entry:
;	AH  ==	03h
; Exit:
;	AL  ==	Char
;
	mov	bx,STDAUX		; Read 1 character from Standard AUX
f03_10:
	jmp	raw_read

;	*****************************
;	***    DOS Function 04    ***
;	***    Auxiliary Output   ***
;	*****************************
;
	Public	func04
func04:
;
; Entry:
;	AH  ==	04h
;	DL  ==	Character to output
;
	mov	bx,STDAUX		; write the character passed in DL
	jmp	f456common		;  to the STDAUX Handle

;	*****************************
;	***    DOS Function 05    ***
;	***    Printer Output     ***
;	*****************************
;
	Public	func05
func05:
;
; Entry:
;	AH  ==	05h
;	DL  ==	character to output to printer
;
	mov	bx,STDPRN		; write the character passed in DL
;	jmp	f456common		;  to the STDPRN Handle

f456common:
	xchg	ax,dx			; character in AL
;	jmp	hndl_write

hndl_write:
;----------
; On Entry:
;	AL = character to write
;	BX = handle
; On Exit:
;	AL preserved
;
	call	is_device		; Does this handle refer to a device
	 jc	hndl_w10
	test	es:DEVHDR.ATTRIB[si],DA_SPECIAL
	 jz	hndl_w10		; Fast Console Output Using Int 29?
	int	29h			; This device supports FAST console
	ret				;  output so write this using Int29

hndl_w10:
	push	ax			; character on stack
	mov	dx,sp			; SS:DX -> char
	mov	cx,1			; do a single character
	 jc	hndl_w20		; was it a file ?
	call	device_write		; send to device driver
	jmp	hndl_w30
hndl_w20:
	push 	ss
	pop 	es			; ES:DX -> character
	mov	ah,MS_X_WRITE		; otherwise call the FDOS to do all
	call	dos_entry		;  the hard work
hndl_w30:
	pop	ax
	ret


;	*****************************
;	***    DOS Function 06    ***
;	***   Direct Console I/O  ***
;	*****************************
;
	Public	func06
func06:
;
; Entry:
;	AH  ==	06h
;	DL  ==	0FFh or Output char
; Exit:
;	AL  ==	Input char, if DL was 0FFh on input
;
	mov	bx,STDOUT			; Assume output DL to console
	cmp	dl,0FFH				; or is it input ?
	 jne	f456common
	dec	bx
;	mov	bx,STDIN			; is there a character ready
	call	char_check			;  to be input
	 jz	func07

	call	is_device			; reading from file?
	 jnc	func06_10			; no, exit
	push	es
	mov	es,current_psp			; get current PSP
	les	bx,es:PSP_XFTPTR		; file handle table
	mov	es:byte ptr STDIN[bx],1		; cancel input redirection
	pop	es
func06_10:

	mov	ax,RHS_IC			; set AL=0 and also set ZF on
	jmp	funcICexit			;  exit as incomplete char


;	*****************************
;	***    DOS Function 07    ***
;	***   Raw Input w/o echo  ***
;	*****************************
;
	Public	func07
func07:
;
; Entry:
;	AH  ==	07h
; Exit:
;	AL  ==	character
;
	mov	bx,STDIN
	call	raw_read			; extra status call made
	jmp	funcICexit			; set incomplete char
	
;	*****************************
;	***    DOS Function 08    ***
;	***    Input w/o echo     ***
;	*****************************
;
	Public	func08
func08:
;
; Entry:
;	AH  ==	08h
; Exit:
;	AL  ==	character
;
	mov	bx,STDIN		; Read 1 character from Standard Input
	call	cooked_read
funcICexit:
; exit point for incomplete character support
; On Entry:
;	AL = character
;	AH = request header status (RHS_IC as on return from device driver)
; On Exit:
;	AL = character
;	dos_FLAGS ZF set if incomplete character
;
	les	di,int21regs_ptr		; point to callers registers
	and	es:reg_FLAGS[di],word ptr not ZERO_FLAG	; clear ZF
	test	ah,RHS_IC/256			; is it an incomplete char ?
	 jz	funcIC10			;  no - exit
	or	es:reg_FLAGS[di],word ptr ZERO_FLAG	;  yes - set ZF
funcIC10:
	ret

;	*****************************
;	***    DOS Function 09    ***
;	***     Print String      ***
;	*****************************
;
	Public	func09
func09:
;
; Entry:
;	AH  ==	09h
;    DS:DX  ==	address of character string
;

	mov	al,'$'			; it's terminated with a '$'
	mov	di,dx			; locate the end of the string 
	mov	cx,0FFFFh		; and calculate its length
	repnz	scasb
	not	cx
	dec	cx			; CX is the character count
	mov	si,dx
	call	stdout_cooked_write	; ES:SI -> character buffer
    	mov 	al,'$'          
    	ret


;	*****************************
;	***    DOS Function 0A    ***
;	***      Read String      ***
;	*****************************
;
	Public	func0A
func0A:
;
; Entry:
;	AH  ==	0Ah
;    DS:DX  ==	pointer to input buffer
;
	mov	bx,STDIN		; Read the editted line from STDIN
	mov	cx,STDOUT		; and display the results on STDOUT
	jmp	read_line		; Read the Line

;	*****************************
;	***    DOS Function 0B    ***
;	***    Console Status     ***
;	*****************************
;
	Public	func0B
func0B:
;
; Entry:
;	AH  ==	0Bh
; Exit:
;	AL  ==	0FFh if char available
;	    ==	 00h otherwise
;
	mov	bx,STDIN
	call	cooked_status		; Get the current handle status
	mov 	al,0FFh			; Assume that the handle is ready
	 jz	f0B_exit		; and return 0FFh in AL
	mov	al,0			; Not Ready
f0B_exit:
	jmp	funcICexit		; exit thru incomplete char support



;	*****************************
;	***    DOS Function 0C    ***
;	***    Flush and Execute  ***
;	*****************************
;
	Public	func0C
func0C:
;
; Entry:
;	AH  ==	0Ch
;	AL  ==  function to execute:  1,6,7,8 or A
; Exit:
;	AL = 0 if function in AL is invalid
;
	push	ax			; save sub-function
	mov	bx,STDIN		; Is this Standard Input Handle a
	call	is_device		;  file or device. Do not flush the 
	 jc	f0C_20			;  buffer contents for a FILE
f0C_10:
	call	hndl_instat		; check if any characters are left
	 jnz	f0C_20			;  and quit when buffer empty
	call	raw_read		; read the character
	jmp	f0C_10			; loop till the buffer is empty

f0C_20:
	pop	ax
	cmp 	al,01h
	je	al_ok			; is legal for this command
	cmp 	al,0ah
	je	al_ok
	cmp 	al,06h
	jb	al_nogo
	cmp 	al,08h
	ja	al_nogo

al_ok:					; Valid function so now execute
	call	reload_registers	; all register reloaded as per entry
	mov	ah,al			; Get the requested sub-function in AH
	jmp	int21_func		; execute the function

al_nogo:				; Illegal command to execute
	xor	ax,ax			; from this function so return error
	ret

;
;	BREAK_CHECK checks for a CNTRL-C and is called by functions 01h to 
;	0Ch. Or by the entry code if the break flag is non zero.
;
	Public	break_check
break_check:
	cmp	indos_flag,01		; Skip the check if we are
	 jnz	break_c15		; already in the emulator
	push	ax
	push	es
	push	si
	les	si,con_device
	call	device_instat		; get the input status
	pop	si
	pop	es
	 jnz	break_c10		; No Character Ready
	cmp	al,CTLC			; Is the character a Control-C
	 jz	break_c20		; Yes
break_c10:
	pop	ax
break_c15:
	ret

break_c20:				; The User has Typed Control-C so flush
	mov	bx,0FFFFh		;  input buffer (FFFF=con_device)
	call	char_get
go_int23:
	push 	cs
	pop 	es			; ES:DX -> Character Buffer
	mov	si,offset cntrl_c_msg	; Message Offset
	mov	cx,lengthof cntrl_c_msg	; Message Length
	call	stdout_cooked_write	; write the ^C String to console
;
;	Prepare to execute an Interrupt 23 (Break Check) and process
;	the return values. If the called routine returns with an IRET
;	or with a RETF and the carry flag reset continue the function
;	otherwise Abort.
;
	mov	es,current_psp		; Get the Entry SS and SP
	mov	ax,es:PSP_USERSP	; Get the Users Stack Pointer
	add	ax,18 - 2		; Compensate for the User Registers
	mov	break_sp,ax		; and save for RETF check
	cli
	dec	indos_flag		; Exit the PCDOS emulator
	mov	ss,es:PSP_USERSS	; Switch to the Users Stack
	mov	sp,es:PSP_USERSP	; and Restore the registers

	POP_DOS				; Update the registers then
					; set the flags and return
					; to the user
	clc				; Default to continue function
	int	23h			; Call the Break Handler
	cli				; Check the Flag State
	 jnc	do23_10			; If CARRY then Abort this process
	call	get_dseg		; Get our data segment
	mov	exit_type,TERM_BREAK	; Force EXIT_TYPE to TERM_BREAK
	mov	ax,4C00h		; "Good-Bye Cruel World" 
;    jmp    do23_20
    do23_10:
	push	ds			; Otherwise restart the aborted func
	call	get_dseg
	cmp	sp,break_sp
	pop	ds			; Restore the the USER DS correct
	 jz	do23_30			; Did we Use a RETF or Not
do23_20:
	add	sp,2			; Yes so correct the stack pointer
do23_30:				; and restart the aborted function
	jmp	int21_entry		; re-start the function call



;
; cooked_status is called on input or output and looks for live keys ^C,^P,^S.
; If any of these are found they are dealt with.
; If ^P is encountered it is swallowed.
; If ^C is encountered we always do an Int23.
; If ^S is pressed we swallow it, and the next character (checking for ^C, but
; not for ^P), then say a character is ready.
; Note that this can lead to status calls (func0B) hanging inside the OS,
; or the return of ^S characters from input calls (func01), but this is
; intentional.
;

cooked_status:
;-------------
; check input
; On Entry:
;	BX = handle to check
; On Exit:
;	ZF set if character available
;	AL = character
;	AH = RHS_IC
;
	call	break_check		; check for a ^C on console
	call	char_check		; is there a character ready
	 jnz	cooked_s50		;  no so keep scanning

	cmp	last_key_ext,0		; was last char an zero ?
	mov	last_key_ext,0		; (clear flag for next time)
	 jne	cooked_s40		; skip ^P,^S,^C checks if so
	
	cmp	al,CTLP			; has the user typed ^P
	 jne	cooked_s10		;  flush the buffer and
	xor	cio_state,CIO_CTLP	;  toggle ^P flag
	call	char_get		;  flush the character from buffer
	call	open_or_close_prn	;  open/close printer device
	test	ax,ax			; ZF clear, ie. no char available
	jmp	cooked_s50

cooked_s10:
	cmp	al,CTLC
	 jnz	cooked_s30		; has the user typed ^C
	call	char_get		; so get the RAW character
cooked_s20:
	jmp	go_int23		; and terminate the function

cooked_s30:
	cmp	al,CTLS			; pause if the user has typed
	 jnz	cooked_s40		;  a ^S
	call	char_get		; remove ^S and resume when
	call	raw_read_wait		; the next character is typed
	cmp	al,CTLC
	 je	cooked_s20		; has the user typed ^C
cooked_s40:
	test	al,al
	 jne	cooked_s45
	mov	last_key_ext,1
cooked_s45:
	cmp	ax,ax			; ZF set, ie. char available
cooked_s50:
	ret
	
;
;	The COOKED, CMDLINE and RAW Read functions are basically the same
;	except in their treatment of 'live' characters ^C,^P, and ^S.
;	COOKED will look for and act upon all three live characters.
;	CMDLINE will look for and act upon ^C and ^P, but ^S will be returned
;	so we can use it as a line editing key.
;	RAW will not check for any live keys.
;
	public	cmdline_read, raw_read	; for CMDLINE.PCM

cmdline_read_wait:			; Waiting for a device to become
	call	idle_dev		; ready. So call IDLE routines to
					; put the processor to sleep.
cmdline_read:
	call	break_check		; check for a ^C on console
	call	char_check		; is there a character ready
;	 jnz	cmdline_read_wait	;  no so keep scanning
	 jz	cmdline_read10		; yes, proceed
	call	is_device		; reading from file?
	 jnc	cmdline_read_wait	; no, keep scanning
	push	es
	mov	es,current_psp		; get current PSP
	les	bx,es:PSP_XFTPTR	; file handle table
	mov	es:byte ptr STDIN[bx],1	; cancel input redirection
	pop	es
	jmp	cmdline_read_wait
cmdline_read10:
	cmp	al,CTLS			; if the user has typed ^S
	 jne	cooked_read		;  we have to do a raw read
;	jmp	raw_read		;  else we do a cooked read

raw_read_wait:				; Waiting for a device to become
	call	idle_dev		; ready. So call IDLE routines to
					; put the processor to sleep.
raw_read:
	call	char_check		; Is there a character Ready
;	 jnz	raw_read_wait		; loop until character available
	 jz	char_get		; yes, proceed
	call	is_device		; reading from file?
	 jnc	raw_read_wait		; no, keep scanning
	push	es
	mov	es,current_psp		; get current PSP
	les	bx,es:PSP_XFTPTR	; file handle table
	mov	es:byte ptr STDIN[bx],1	; cancel input redirection
	pop	es
	jmp	raw_read_wait
;	jmp	char_get

cooked_read_wait:			; Waiting for a device to become
	call	idle_dev		; ready. So call IDLE routines to
					; put the processor to sleep.
cooked_read:
	call	break_check		; check for a ^C on console
	call	cooked_status		; check for a ^S,^P,^C on handle BX
;	 jnz	cooked_read_wait	; wait until char is available
	 jz	char_get		; yes, proceed
	call	is_device		; reading from file?
	 jnc	cooked_read_wait	; no, keep scanning
	push	es
	mov	es,current_psp		; get current PSP
	les	bx,es:PSP_XFTPTR	; file handle table
	mov	es:byte ptr STDIN[bx],1	; cancel input redirection
	pop	es
	jmp	cooked_read_wait
;	jmp	char_get		;  else get the character

char_get:
	push es
	push ax				; Input one character and
	mov	dx,sp			;  return it in AL
	call	is_device		; Does this handle refer to a device
	mov	cx,1
	 jc	char_get30		; if it's a device then
	call	device_read		;  use device_read
char_get20:
	pop 	ax
	pop 	es
	ret

char_get30:
; We are redirected, so call to the FDOS to get a character
	pop	ax			; get previous status
	xor	ah,ah			; clear AH so that it is not mistaken
	push	ax			; for a device request header
	push 	ss
	pop 	es			; EX:DX -> character to read
	mov	ah,MS_X_READ		; call the FDOS to do all
	call	dos_entry		;  the hard work
	jmp	char_get20


stdout_cooked_write:
	mov	bx,STDOUT		; output to the console device
;	jmp	cooked_write

;
;	The COOKED_WRITE routine will expand TABS etc in the string
;	passed passed by the calling routine. 
;
;	On Entry:
;		ES:SI		Buffer Address
;		CX		Character Count
;		BX		Output Handle
;	On Exit:
;		AL = last char written
;
	Public cooked_write
cooked_write:
	push	es
	push	bx
	mov	ah,cio_state		; get CIO_CTLP status
	or	ah,CIO_RAW+CIO_HANDLE	; assume we will want raw handle output
	mov	al,bl
	test	byte ptr remote_call+1,DHM_FCB/100h
	 jnz	cook_w03
	mov	es,current_psp		; get our PSP
	cmp	bx,es:PSP_XFNMAX	; range check our handle
	 jae	cook_w05
	les	di,es:PSP_XFTPTR
	mov	al,es:byte ptr [bx+di]	; AL = Internal File Handle
cook_w03:
	call	ifn2dhndl		; ES:BX -> DHNDL_
	 jc	cook_w05		; skip if bad handle
	mov	dx,es:DHNDL_WATTR[bx]	; get handle attributes
	and	dx,DHAT_DEV+DHAT_CIN+DHAT_COT+DHAT_BIN+DHAT_REMOTE
	cmp	dx,DHAT_DEV+DHAT_CIN+DHAT_COT+DHAT_BIN
	 je	cook_w04		; accept binary console device
	cmp	dx,DHAT_DEV+DHAT_CIN+DHAT_COT
	 jne	cook_w05		; skip if not cooked console device
	and	ah,not CIO_RAW		; we want cooked output
cook_w04:
	les	bx,es:DHNDL_DEVPTR[bx]	; its the console - but is it FAST ?
	test	es:DEVHDR.ATTRIB[bx],DA_SPECIAL
	 jz	cook_w05		; skip if not
	and	ah,not CIO_HANDLE	; don't use handle functions
cook_w05:
	pop	bx
	pop	es
     jcxz   cook_w80        
cook_w10:
	lodsb	es:0			; Read the next character
	cmp 	al,DEL
	je 	cook_w60		; DEL is a NON Printing Character
	cmp 	al,' '
	jae 	cook_w50		; Space and Above are Normal
	cmp 	al,LF 
	je 	cook_w60		; Just print LineFeeds
	cmp 	al,ESC
	je 	cook_w60		; Just print Escape
	cmp 	al,BELL
	je 	cook_w60		; Just ring the Bell
	cmp 	al,CR 
	jne 	cook_w20		; CR zeros the column number
	mov	column,0
	mov	char_count,1		; check for ^S etc NOW
	jmp	cook_w60
cook_w20:
	cmp 	al,CTLH
	jne 	cook_w30		; BackSpace decrements the
	dec	column			; column count by one
	jmp	cook_w60
cook_w30:
	cmp 	al,TAB
	jne 	cook_w60		; is it a TAB ?
cook_w40:
	mov	al,' '			;  spaces
	call	cooked_out		; output a space char
	inc	column
	test	column,7		; are we at a TAB stop yet ?
	 jnz	cook_w40
	jmp	cook_w70
cook_w50:
	inc	column			; Update the column count and
cook_w60:
	call	cooked_out		;  output the character
cook_w70:
	loop	cook_w10		; onto the next character
cook_w80:
	ret

cooked_out:
; On Entry:
;	AH = handle status
;	AL = character
;	BX = handle
; On Exit:
;	AX, BX, CX, ES:SI preserved
;
	dec	char_count		; time to check keyboard input ?
	 jz	cooked_o10		;  no, skip status check
	test	ah,CIO_HANDLE+CIO_CTLP	; is it complicated ?
	 jnz	cooked_o10
	int	29h			; This device supports FAST console
	ret

cooked_o10:
	push	es
	push	ax
	push	cx
	push	si
	call	hndl_write		; display the character
	test	ah,CIO_CTLP		; Check for Printer Echo
	 jz	cooked_o20		; Off so No Echo
	push	bx			; Save Output Handle
	mov	bx,STDPRN		; and output the same data to the
	call	hndl_write		; to the Printer Handle
	pop	bx
cooked_o20:
	test	ah,CIO_RAW		; is it a cooked console ?
	 jnz	cooked_o30		; skip check if not
	call	cooked_status		; look for keyboard input
	mov	char_count,CHECK_EVERY	; look again in a while
cooked_o30:
	pop	si
	pop	cx
	pop	ax
	pop	es
	ret

;	IDLE_DEV is called when the PCMODE is waiting for a character.
;	This routine must determine if the request is for a device or not
;	and call the IDLE interface for device requests to the system can be
;	put to sleep until a character is ready.
;
;	On Entry:-	BX Handle Number
;	
idle_dev:
	push	bx			; preserve handle
	mov	ax,8400h
	int	2ah			; Server hook for idle
	dec	clock_count
	 jnz	idle_dev10		; Zero if NO skip delay and execute
	call	ReadTimeAndDate		; for PC BIOS's who must read every day
idle_dev10:
if IDLE_DETECT
	test	idle_flags,IDLE_DISABLE	; Has Idle Checking been enabled
	 jnz	idle_dev40		; Skip if NO
	push 	es
	push 	si
	call	is_device		; The requested handle a file or device
	 jc	idle_dev30		; File Access skip IDLE
	mov	ax,PROC_KEYIN		; Assume this is the REAL Console
	test	es:DEVHDR.ATTRIB[si],DA_ISCIN; Test Attribute Bits
	 jnz	idle_dev20		; Yes this is Default Console Device
	mov	ax,PROC_DEVIN		; Input from Another Device
idle_dev20:
	call	dword ptr idle_vec	; Call the IDLE Handler
idle_dev30:
	pop 	si
	pop 	es
idle_dev40:
endif
	pop	bx			; recover handle
	ret

;	The following routine reads CX bytes from the device whose address 
;	is held in the DWORD pointer passed by DS:SI. A Request Header 
;	is built on the stack and the command is executed.
;
;	On Entry:
;		ES:SI		DWORD Pointer to Device Header
;		SS:DX		Buffer Address
;		CX		Character Count
;
;	On Exit:
;		AX		Request Header Status
;		Zero		No Error
;
	Public	device_read
device_read:
	mov	al,CMD_INPUT		; we want input
	jmp	device_common		; now use common code

;	The following routine writes CX bytes to the device whose address 
;	is held in the DWORD pointer passed by DS:SI. A Request Header 
;	is built on the stack and the command is executed.
;
;	On Entry:
;		ES:SI		DWORD Pointer to Device Header
;		SS:DX		Buffer Address
;		CX		Character Count
;
;	On Exit:
;		AX		Request Header Status
;		Zero		No Error
;
	Public	device_write
device_write:
	mov	al,CMD_OUTPUT		; we want output
device_common:
	push	bx
	sub	sp,RH4_LEN		; reserve space on the stack
	mov	bx,sp			; request header offset
	mov	ss:RH_LEN[bx],RH4_LEN	; request header length
	mov	ss:RH4_BUFOFF[bx],dx	; buffer offset
	mov	ss:RH4_BUFSEG[bx],ss	; buffer segment
device_common10:
	mov	ss:RH4_COUNT[bx],cx	; character count
	call	device_req		; execute command
	 jns	device_common20		; if no errors return to the caller
	sub	cx,ss:RH4_COUNT[bx]	; CX = chars remaining
	push	ax			; save the error code
	call	char_error		; ask int 24 what to do
	cmp	al,ERR_RETRY		; should we retry the operation ?
	pop	ax			; recover the error code
	 ja	device_common20		; Fail/Abort return error
	mov	al,ss:RH_CMD[bx]		; reload the command
	 je	device_common10		; Retry, re-issue the device request
	mov	ax,RHS_DONE		; Ignore, pretend no errors
device_common20:
	add	sp,RH4_LEN		; restore the stack to its normal
	test	ax,RHS_ERROR		;  state and return the status.	
	pop	bx
	ret


char_check:
; On Entry:
;	BX = handle to check
; On Exit:
;	ZF set if character ready
;	AL = character (if device handle)
;	AH = RIC status
;
	push	bx			; Save the current handle status
if IDLE_DETECT
	test	idle_flags,IDLE_DISABLE	; Has Idle Checking been enabled
	 jnz	char_check10		; Skip if NO
	dec	int28_delay		; Has the INT28 Loop count reached
	 jnz	char_check10		; Zero if NO skip delay and execute
	mov	ax,int28_reload		; INT28. Otherwise DELAY/DISPATCH
	mov	int28_delay,ax
	mov	ax,PROC_INT28		; Process is IDLE
	call	dword ptr idle_vec	; Call the IDLE Handler
char_check10:
endif
	cmp	indos_flag,1		; Only execute an INT 28
	 jnz	char_check20		; when the INDOS flag is 1
	cmp	int28_flag,TRUE	and 0FFh	; Only generate INT 28s for the
	 jnz	char_check20		; selected functions
	
	push	remote_call
	push	machine_id
	mov	es,current_psp		; Get the PSP
	push	es:PSP_USERSP		; Save the SS:SP pointer to 
	push	es:PSP_USERSS		; the register image

if IDLE_DETECT				; Set IDLE_INT28 so $IDLE$ knows
	or	idle_flags,word ptr IDLE_INT28	; that we are nolonger inside DOS
endif
	int	28h			; Execute an INT 28 for SideKick and
					; the PRINT utility. INDOS flag is 1

if IDLE_DETECT				; Reset IDLE_INT28 so $IDLE$ knows
	and	idle_flags,word ptr not IDLE_INT28; that we are back DOS
endif
	mov	int28_flag,TRUE	and 0FFh	; Restore INT28_FLAG
	mov	es,current_psp		; Get the PSP
	pop	es:PSP_USERSS		; Restore the SS:SP pointer to 
	pop	es:PSP_USERSP		; the register image
	pop	machine_id
	pop	remote_call
char_check20:
	pop	bx
;	jmp	hndl_instat		; Check Input Status. ZERO == Ready

;
;
hndl_instat:
	call	is_device		; Does this handle refer to a device
	 jnc	device_instat
	mov	ax,(MS_X_IOCTL shl 8)+6	; Get the file status
	call	dos_entry		; for the specified handle
	cmp	al,0FFh			; and return ZERO until the EOF
	ret

;	The following routine executes the Non Destructive Input
;	command to the device whose address passed in ES:SI.
;
;	On Entry:
;		ES:SI		DWORD Pointer to Device Header
;
;	On Exit:
;		Zero		Character Ready
;		AH		Top Byte Request Header Status
;		AL		Next Character if ZERO
;

device_instat:
	push	bx
	sub	sp,RH5_LEN		; Reserve Space on the Stack
	mov	bx,sp			; Request Header Offset
	mov	ss:RH_LEN[bx],RH5_LEN	; Set Request Header Length
	mov	al,CMD_INPUT_NOWAIT	; Command Number
	call	device_req		; Execute the Command
	mov	al,ss:RH5_CHAR[bx]	; Assume a character is ready
	add	sp,RH5_LEN		; Restore the Stack to its normal
	test	ax,RHS_BUSY		; state and return the status.	
	pop	bx			; Zero if a Character is ready
	ret

;	The following routine handles the low level device interface to
;	the character device drivers. All the generic Request Header 
;	initialization is carried out here.
;
;	On Entry:
;		AL		Command
;		ES:SI		Device Header
;		SS:BX		Current Request Header
;
;	On Exit:
;		AX		Request Header Status
;

device_req:
;----------
	mov	ss:RH_CMD[bx],al		; save the command
	push	ds
	push	es
	push 	es
	pop 	ds			; DS:SI -> device driver
	mov	es,ss:current_psp	; es = current PSP
	mov	al,es:PSP_RIC		; al = Return Interim Character flag
	mov	ss:RH4_RIC[bx],al		; Return Interim Char flag
	push 	ss
	pop 	es			; ES:BX -> RH_
	call	device_driver
	pop	es
	pop	ds
	ret

;
;	IS_DEVICE checks the internal handle structures to determine
;	if the handle referenced in BX is a file or device. Invalid
;	handles all map to the default console device.
;
; On Entry:
;	BX	Handle Number
;
; On Exit:
;	CY set if handle is for a file
;	CY clear if handle is for device at ES:SI
;
is_device:
	push	ax
	push	bx			; Convert the Standard Handle number
	mov	ax,bx			; get XFN in AL
;	mov	cx,current_psp		; into an internal handle number
;	 jcxz	is_dev10		; no PSP, we have IFN already
;	mov	es,cx
	test	byte ptr remote_call+1,DHM_FCB/100h; if FCB initiated access
	 jnz	is_dev10		; we have IFN already
	mov	es,current_psp
	cmp	bx,es:PSP_XFNMAX	; Check if the handle is in range for
	 jae	is_dev_bad		; this PSP.
	les	si,es:PSP_XFTPTR
	mov	al,es:byte ptr [bx+si]	; AL = Internal File Handle
is_dev10:
	call	ifn2dhndl		; ES:BX -> DHNDL_
	 jc	is_dev_bad
	mov	ax,es:DHNDL_WATTR[bx]	; get file attributes
	and	ax,DHAT_REMOTE+DHAT_DEV
	cmp	ax,DHAT_DEV		; is it a local device ?
	stc				; assume it's a file
	 jne	is_dev30
	les	si,es:DHNDL_DEVPTR[bx]	; its a device
is_dev20:
	clc
is_dev30:
	pop	bx
	pop	ax
	ret

is_dev_bad:
	les	si,con_device		; bad handles map to console
	jmp	is_dev20

open_or_close_prn:
;-----------------
; called when CIO_CTLP toggled - call prn device with Open or Close as appropriate
;
	push 	ds
	push 	ax
	push 	bx
	mov	ax,CTLP
	push	ax			; ^P on stack
	mov	cx,current_psp		; look in PSP
	 jcxz	oc_prn30		; no PSP, forget it
	mov	es,cx
	cmp	bx,es:PSP_XFNMAX	; Check if the handle is in range for
	 jae	oc_prn30		; this PSP. 
	les	si,es:PSP_XFTPTR	; for the internal handle number
	mov	al,es:byte ptr STDPRN[si]
	cmp	al,0FFh			; AL = Internal File Handle
	 je 	oc_prn30		;  skip if invalid Handle Number
	call	ifn2dhndl		; ES:BX -> doshndl
	 jc	oc_prn30
	test	es:DHNDL_WATTR[bx],DHAT_NETPRN
	 jz	oc_prn10
	mov	ax,I2F_CTLP		; turn on the network printer
	int	2fh			; with a magic INT 2F call
	 jnc	oc_prn10
	and	cio_state,not CIO_CTLP	; make sure Printer Echo is off
	mov	ax,I2F_CTLP_ERR
	int	2fh
	jmp	oc_prn30
oc_prn10:
	mov	ax,es:DHNDL_WATTR[bx]	; get file attributes
	and	ax,DHAT_REMOTE+DHAT_DEV
	cmp	ax,DHAT_DEV		; is it a local device ?
	 jne	oc_prn30
	mov	al,CMD_DEVICE_OPEN	; assume we've just opened
	test	cio_state,CIO_CTLP	; Check for Printer Echo
	 jnz	oc_prn20		; yes, skip next bit
	mov	al,CMD_DEVICE_CLOSE	; no, we must close
oc_prn20:
	les	si,es:DHNDL_DEVPTR[bx]	; get the device driver address
	test	es:DEVHDR.ATTRIB[si],DA_REMOVE
	 jz	oc_prn30		; no, skip call if not supported
	sub	sp,RH13_LEN		; Reserve Space on the Stack
	mov	bx,sp			; and point to it
	mov	ss:RH_LEN[bx],RH13_LEN	; Set Request Header Length
	mov	ss:RH_CMD[bx],al	; Command Number
	call	device_driver		; issue the command
	add	sp,RH13_LEN		; Restore the Stack to its normal
oc_prn30:
	pop	ax			; discard ^P from stack
	pop 	bx
	pop 	ax
	pop 	ds
	ret
PCM_CODE	ends	
	
PCM_RODATA 	segment public word 'CODE'

cntrl_c_msg	db	'^C', CR, LF	; Control-Break Message

PCM_RODATA	ends

GLOBAL_DATA 	segment public word 'DATA'

clock_count	db	0

GLOBAL_DATA	ends

PCMODE_DATA	segment public word 'DATA'

	extrn	break_sp:word		; For Control-Break handler
	extrn	char_count:byte
	extrn	cio_state:byte		; Character I/O State
	extrn	column:byte		; Console Cursor Location
	extrn	con_device:dword	; Current Console Device
	extrn	current_psp:word	; Current PSP Address
	extrn	exit_type:byte
	extrn	indos_flag:byte		; INDOS Count
	extrn	int21regs_ptr:dword	; pointer to callers registers
	extrn	machine_id:word
	extrn	remote_call:word
if IDLE_DETECT
	extrn	idle_flags:word		; IDLE State Flags
	extrn	idle_vec:dword		; IDLE routine Vector
	extrn	int28_delay:word
	extrn	int28_reload:word
	extrn	int28_flag:byte
endif
PCMODE_DATA	ends

FIXED_DOS_DATA	segment public word 'DATA'
	extrn	last_key_ext:byte
FIXED_DOS_DATA	ends

	end
