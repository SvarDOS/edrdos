;    File              : $Workfile: CRIT.ASM$
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
;    CRIT.ASM 1.11 94/12/01 10:05:21
;    Changed critical error message display so that the default message
;    is 'I/O error' and that all share-related codes are converted to
;    'File sharing conflict'
;    
;    CRIT.ASM 1.9 93/09/10 15:56:08 
;    Use device driver header at BP:SI instead of AH to determine if disk/char device
;    That way we get "device NETWORK" rather than "drive D" on VLM critical errors
;    ENDLOG
;
; 19/Sep/88 Move the messages into a separate module
; 15/Dec/88 Critical Error messages processed by STDERR
; 06/Apr/89 DR DOS version taken from PCMODE & put in COMMAND.COM
; 10/Aug/89 Issue INT 2F's so application can give it's own error message
; 08/Sep/89 'No FCBs' message
; 02/Nov/89 abort_char etc become ABS rather than CHAR (saves a few bytes)
; 13/Nov/89 Reduced number of external messages referenced to one
;		(crit_top) to aid Dual Language Support.
; 12/Feb/90 Changed code to avoid problems with double byte character sets.
;  8/Mar/90 Remove extra pair of CR/LF's that were output after error
; 20/Apr/90 DLS data into R_TEXT for Watcom C v7.0
;  9/May/90 Critical errors go to STDERR on command PSP, not current_psp

	include msdos.equ
	include mserror.equ
	include	driver.equ
;
dataOFFSET	equ offset DGROUP:


PSP_XFTPTR	equ	es:dword ptr 34h	; from i:PSP.DEF

;	Critical Error responses from the default INT 24 handler and
;	the DO_INT24 routine.
;
ERR_IGNORE	equ	0		; Ignore Error
ERR_RETRY	equ	1		; Retry the Operation
ERR_ABORT	equ	2		; Terminate the Process
ERR_FAIL	equ	3		; Fail Function
;
OK_FAIL		equ	00001000b	; Fail is a Valid Response
OK_RETRY	equ	00010000b	; Retry is a Valid Response
OK_IGNORE	equ	00100000b	; Ignore is a valid Response
OK_RIF		equ	00111000b	; All Responsese are Valid
OK_RI		equ	00110000b	; Retry and Ignore are Valid
OK_RF		equ	00011000b	; Retry and Fail are Valid
;
;
;	The following equates allow us to access the users registers
;	and flags during normal system call emulation.
;
;NOTE:-	The users INT21 structure is not normally available because of the
;	stack switch which occurs on entry and only the general purpose
;	registers are copied to the new stack.
;
dos_AX		equ	word ptr 0[bp]
dos_BX		equ	word ptr 2[bp]
dos_CX		equ	word ptr 4[bp]
dos_DX		equ	word ptr 6[bp]
dos_SI		equ	word ptr 8[bp]
dos_DI		equ	word ptr 10[bp]
dos_BP		equ	word ptr 12[bp]
dos_DS		equ	word ptr 14[bp]
dos_ES		equ	word ptr 16[bp]
;
;
;
ifdef CDOSTMP
DGROUP	GROUP	R_TEXT

R_TEXT		SEGMENT byte public 'CDOS_DATA'

else

DGROUP	GROUP	_DATA, R_TEXT, ED_TEXT

R_TEXT		SEGMENT byte public 'CDOS_DATA'
R_TEXT		ENDS

_DATA		SEGMENT byte public 'DATA'

endif
	extrn	_country:WORD
	extrn	__psp:WORD

ifdef DLS
TEXT_LEN	equ	320		; it needs to be this size for Japanese

	Public	_crit_msgs

	; crit_table gives offset into crit_msgs table.

crit_table	db	0		; (00) Write to Read Only Disk
		db	2		; (01) Unknown Unit
		db	4		; (02) Drive Not Ready
		db	2		; (03) Unknown Command
		db	6		; (04) Data Error (CRC)
		db	2		; (05) Bad Request Length Structure
		db	8		; (06) Seek Error
		db	10		; (07) Unknown Media Type
		db	12		; (08) Sector Not Found
		db	14		; (09) Printer Out Of Paper
		db	2		; (0A) Write Fault
		db	2		; (0B) Read Fault
		db	2		; (0C) General Failure
		db	16		; (0D) File Sharing Error
		db	16		; (0E) Locking Error
		db	18		; (0F) FCB Unavailable

_crit_msgs	dw	TEXT_LEN	; size of this message buffer
crit_top	dw	0,0,0,0,0,0,0,0,0,0
msg_crlf	dw	0	
readmsg		dw	0
writemsg	dw	0
drivemsg	dw	0
charmsg		dw	0
abort_char	dw	0
abort_msg	dw	0
retry_char	dw	0
retry_msg	dw	0
ignore_char	dw	0
ignore_msg	dw	0
fail_char	dw	0
fail_msg	dw	0
prompt_msg	dw	0
		dw	0	; end of list

public	_crit_text
_crit_text	db	TEXT_LEN dup(?)	; message text is placed here

CRIT_LEN	equ	$-crit_top


else

	extrn	msg0:byte, msg2:byte, msg3:byte, msg4:byte
	extrn	msg6:byte, msg7:byte, msg8:byte
	extrn	msg20:byte, msg21:byte, msg22:byte

crit_top	dw	offset DGROUP:msg0	; (00) Write to Read Only Disk
		dw	offset DGROUP:msg3	; (01) Unknown Unit
		dw	offset DGROUP:msg2	; (02) Drive Not Ready
		dw	offset DGROUP:msg3	; (03) Unknown Command
		dw	offset DGROUP:msg4	; (04) Data Error (CRC)
		dw	offset DGROUP:msg3	; (05) Bad Request Length Structure
		dw	offset DGROUP:msg6	; (06) Seek Error
		dw	offset DGROUP:msg7	; (07) Unknown Media Type
		dw	offset DGROUP:msg8	; (08) Sector Not Found
		dw	offset DGROUP:msg21	; (09) Printer Out Of Paper
		dw	offset DGROUP:msg3	; (0A) Write Fault
		dw	offset DGROUP:msg3	; (0B) Read Fault
		dw	offset DGROUP:msg3	; (0C) General Failure
		dw	offset DGROUP:msg20	; (0D) File Sharing Error
		dw	offset DGROUP:msg20	; (0E) Locking Error
		dw	offset DGROUP:msg22	; (0F) FCB Unavailable


	Extrn	msg_crlf:byte
	Extrn	readmsg:byte, writemsg:byte, drivemsg:byte, charmsg:byte
	Extrn	abort_char:byte, abort_msg:byte
	Extrn	retry_char:byte, retry_msg:byte
	Extrn	ignore_char:byte, ignore_msg:byte
	Extrn	fail_char:byte, fail_msg:byte, prompt_msg:byte
endif
ifndef CDOSTMP
_DATA	ends
ED_TEXT		SEGMENT para public 'CDATA'
endif

	assume cs:DGROUP, ds:nothing, es:nothing, ss:nothing
;
;	This is the default critical error handler which will prompt
;	the user with an error message and wait for a response. This handler
;	is usually replaced by the DOS application
;
;	+++++++++++++++++++++++++++++++
;	Int 24 - Critical Error Handler
;	+++++++++++++++++++++++++++++++
;
;	INT 24 Critical Error:-
;	    On Entry:-	AH/7	0 = Disk Device
;			AH/5	0 = IGNORE is an Invalid Response
;			AH/4	0 = RETRY in an Invalid Response
;			AH/3	0 = FAIL is an Invalid Response
;			AH/2-1	00= DOS Area
;				01= File Allocation Table
;				10= Directory
;				11= Data
;			AH/0	0 = Read, 1 = Write
;
;			AL	Failing Disk Drive if AH/7 == 0
;			BP:SI	Device Header Control Block
;			DI	High Byte DRNET server (inverted, CDOS only)
;				Low Byte Error Code 
;
;	    On Exit:-	AL	0 = IGNORE Error
;				1 = RETRY the Operation
;				2 = TERMINATE using INT 23
;				3 = FAIL the current DOS function
;
;

	Public	com_criterr	
com_criterr:
;
;	This is called by the int24 handler 'critical_error', in CSTART.ASM.
;
	sti
	cld
	push	es
	push	ds
	push	bp
	push	di
	push	si
	push	dx
	push	cx
	push	bx
	push	ax
	
	mov	bp,sp
	mov	ah,MS_P_GETPSP
	int	DOS_INT			; Get PSP into DS
	mov	ds,cs:__psp	
	mov	al,ds:byte ptr 1ah	; use COMMAND STDERR for Console INPUT
	mov	ah,al			;  and OUTPUT
	mov	es,bx
	lds	bx,PSP_XFTPTR		; Get the handle table pointer
	push	word ptr [bx]		; Save the current Values
	mov	word ptr [bx],ax

	push	cs
	pop	ds			; DS == CS
	call	i24_crlf		;output carriage return - line feed

	mov	ah,MS_F_ERROR
	xor	bx,bx
	int	DOS_INT			; Get extended error code
	mov	cx,ax			; Get the Real Error Code (ie INT21/59)
	mov	bx,0Fh			; assume FCB unavailable
	cmp	al,-(ED_NOFCBS)		; if FCB exhausted/closed then generate
	 je	int24_e10		;  a more appropriate error message
	dec	bx
    dec bx          
	cmp	al,-(ED_SHAREFAIL)	;  check for sharing failure which
	 je	int24_e10		;  is forced to be a DRIVE NOT READY
	cmp	al,-(ED_NOLOCKS)	; check for sharing buffer overflow
	 je	int24_e10
	dec	bx			; BX = 0Ch, default error
	mov	ax,dos_DI		; get the REAL error code
	cmp	ax,0Eh			; is it a sensible value ?
	 ja	int24_e10		; no, return GENERAL FAILURE
	xchg	ax,bx			; yes, use it
int24_e10:
	call	int24_errmsg		; print out the offending error msg
	call	i24_crlf		; Print CR/LF

;
;	This section of the Critical Error handler prints the correct
;	prompt repeatedly until the user responds with a correct
;	response. This value is returned to the PCMODE.
;
i24_query:
ifdef DLS
	mov dx,abort_msg		; Print "Abort" as this is always
else
	mov dx,dataOFFSET abort_msg	; Print "Abort" as this is always
endif
	call i24_print			; a valid response

	test bh,OK_RETRY
	 jz i24_q10			; Display ", Retry" if RETRY 
ifdef DLS
	mov	dx,retry_msg		; is a Valid Response
else
	mov	dx,dataOFFSET retry_msg	; is a Valid Response
endif
	call	i24_print

i24_q10:
	test bh,OK_IGNORE
	 jz i24_q20			; Display ", Ignore" if IGNORE
ifdef DLS
	mov	dx,ignore_msg		; is a valid response
else
	mov	dx,dataOFFSET ignore_msg ; is a valid response
endif
	call	i24_print

i24_q20:
	test bh,OK_FAIL
	 jz i24_q30			; Display ", Fail" if FAIL is
ifdef DLS
	mov	dx,fail_msg		; a valid response
else
	mov	dx,dataOFFSET fail_msg	; a valid response
endif
	call	i24_print

i24_q30:
ifdef DLS
	mov	dx,prompt_msg
else
	mov	dx,dataOFFSET prompt_msg
endif
	call	i24_print

	mov	ah,MS_C_FLUSH		; Clear type ahead buffer
	mov	al,MS_C_READ		; and then get a character
	int	DOS_INT

; In case we get double byte characters...
; If we had access to the dbcs_lead() routine (in the non-resident code)
; we could test for a double byte character and consume the second byte.
; Since we can't do this I have used the following code, which simply
; consumes and displays all bytes in type-ahead buffer.
	push	ax			; save first character received
dbcs_loop:
	mov	ah, MS_C_RAWIO		; char in type-ahead buffer?
	mov	dl, 0FFh
	int	DOS_INT
	 jz	dbcs_exit		;  no - exit loop
	mov	dl, al
	mov	ah, MS_C_WRITE		;  yes - display char
	int	DOS_INT
	jmp short dbcs_loop		; loop until type-ahead buffer empty
dbcs_exit:
	pop	ax			; restore the first character

; Check that character lies in the range 'a' <= ch <= 'z' before anding it
; with 5Fh to uppercase it (incase the character is a DBCS lead byte).

	cmp	al, 'a'			; ch < 'a' ?
	 jb	uc_done			;  yes - skip upper casing
	cmp	al, 'z'			; ch > 'z' ?
	 ja	uc_intl			;  yes - may be intl
	and	al, 5Fh			; uppercase ch
	jmp short uc_done
uc_intl:
	cmp	al, 80h			; international char?
	 jb	uc_done
; ch >= 80h  -- call international routine
UCASE	equ	18			; offset of dword ptr to uppercase func
	call	dword ptr [_country+UCASE]
uc_done:

	push	ax
	call	i24_crlf
	pop	dx

	mov	ah,bh
	xor	al,al			; AL == 0 IGNORE Error
ifdef DLS
	test	ah,OK_IGNORE
	 jz	i24_q40			; Is it a valid response
	mov	bx,ignore_char
	cmp	dl,[bx]
else
	test	bh,OK_IGNORE
	 jz	i24_q40			; Is it a valid response
	cmp	dl,ignore_char
endif
	 jz 	i24_exit

i24_q40:
	inc	ax			; AL == 1 RETRY Function
ifdef DLS
	test	ah,OK_RETRY
	 jz	i24_q50			; Is it a valid response
	mov	bx,retry_char
	cmp	dl,[bx]
else
	test	bh,OK_RETRY
	 jz	i24_q50			; Is it a valid response
	cmp	dl,retry_char
endif
	 jz	i24_exit

i24_q50:
	inc	ax			; AL == 2 ABORT Process
ifdef DLS
	mov	bx,abort_char
	cmp	dl,[bx]
else
	cmp	dl,abort_char
endif
	 jz	i24_exit

	inc	ax			; AL == 3 FAIL Function
ifdef DLS
	test	ah,OK_FAIL
	 jz	i24_query_again		; Is it a valid response
	mov	bx,fail_char
	cmp	dl,[bx]
	 jz	i24_exit
i24_query_again:
	mov	bh, ah			; restore valid response bit set
	jmp	i24_query
else
	test	bh,OK_FAIL
	 jz	i24_query_again		; Is it a valid response
	cmp	dl,fail_char
	 jz	i24_exit
i24_query_again:
	jmp	i24_query
endif


i24_exit:
	mov	dos_AX,ax
	mov	ah,MS_P_GETPSP
	int	DOS_INT			; Get PSP into DS
	mov	es,bx
	lds	bx,PSP_XFTPTR		; the handle table pointer
	pop	word ptr [bx]		; Restore the original handle Values
	
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	pop	si
	pop	di
	pop	bp
	pop	ds
	pop	es

	ret

int24_errmsg:
; Print out an appropriate error message (eg. "Drive not ready")
; Call INT 2F functions in case system extentions (eg. CDROM) wish to
; give another error message.
	push	bx			; save error code
	push	cx
	mov	ax,500h
	int	2fh			; query if user msg handler installed
	cmp	al,0ffh			; yes if FF returned
	pop	cx
	pop	bx
	 jne	int24_errmsg10
	push	bx
	push	cx
if 0
; the DOS 3 way
	mov	ah,5			; OK. now we ask for a message
	mov	al,cl			;  with the error code in AL
else
; the DOS 5 way
	mov	ax,501h
	mov	bx,cx
endif
	int	2fh			; ES:DI -> msg
	pop	cx
	pop	bx
	 jc	int24_errmsg10		; did they give us a msg ?
	mov	si,di			; ES:SI -> msg
	mov	ah,MS_C_WRITE		; write it out
int24_errmsg1:
	lods	es:byte ptr [si]	; get a character
	test	al,al			; until end of an ASCIIZ string
	 jz	int24_errmsg2
	mov	dl,al			; character into DL
	int	DOS_INT			; write it
	jmp short int24_errmsg1
int24_errmsg2:
	mov	bx,dos_AX		; get original AX for Abort/Retry etc
	ret
	
int24_errmsg10:
; No-one wants to supply a message - we'd better generate one ourselves
;
	xor	bh,bh			 
ifdef	DLS
	mov	bl, crit_table[bx]
else
	shl	bx,1
endif
	mov	dx, crit_top[bx]	
	call	i24_print		

	mov	bx,dos_AX		; Get the Original AX
	test 	bh,01h			; check to see if the error occured 
	jnz 	prwrite			; while reading or writing
ifdef DLS
	mov 	dx,readmsg 		; print 'reading'
else
	mov 	dx,dataOFFSET readmsg 	; print 'reading'
endif
	jmp short prread
prwrite:
ifdef DLS
	mov 	dx,writemsg		; print 'writing'
else
	mov 	dx,dataOFFSET writemsg	; print 'writing'
endif
prread:
	call	i24_print		; appropriate string
;;	test	bh,80h
	mov	es,dos_BP		; ES:SI = driver header
	test	es:DH_ATTRIB[si],DA_CHARDEV
	 jz	disk_error		; Was this a DISK error

;
;	For Character Device errors print the failing Device Name
;	and then prompt the user for a valid response.
;
;character_error:
ifdef DLS
	mov	dx,charmsg
else
	mov	dx,dataOFFSET charmsg
endif
	call	i24_print

;;	mov	es,dos_BP		; ES:SI = driver header
	mov	cx,8			; Print the 8 Character device name
char_name:
	mov	dl,DH_NAME[si]		; Get the next character and
	mov	ah,MS_C_WRITE		; display on the console
	int 	DOS_INT
	inc	si			; Increment the character pointer
	loop	char_name		; and Loop till complete name displayed
	ret				; Now query the user

;
;	For DISK errors print the failing drive code and then
;	prompt the user for a valid response.
;
disk_error:
ifdef DLS
	mov	dx,drivemsg		;
else
	mov	dx,dataOFFSET drivemsg	;
endif
	call	i24_print		; print 'drive d'
	mov	dl,bl			; Get the Drive Code
	add 	dl,'A'			; convert drive to ascii 
	mov 	ah,MS_C_WRITE		; print the drive
	int	DOS_INT
	ret

i24_crlf:
ifdef DLS
	mov	dx,msg_crlf
else
	mov	dx,dataOFFSET msg_crlf
endif

i24_print:
	mov 	ah,MS_C_WRITESTR
	int	DOS_INT
	ret

ifdef CDOSTMP
R_TEXT	ENDS
else
ED_TEXT	ENDS
endif
	end
