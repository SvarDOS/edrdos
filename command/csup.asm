;    File              : $Workfile: CSUP.ASM$
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
;    ENDLOG
;
; 28 Jan 88 Change the validation check for the environment. Now we look
;		for a valid DOS Memory Descriptor which is owned by the 
;		Command Processor.
; 12 May 88 Handle Empty environments correctly (Thanks DesqView)
; 26 May 88 ach _stack is only defined for MSC
; 16 Jun 88 Support TURBO C Stack checking and enable CHKSTK for
;       MSC only.
; 26 Aug 88 Make the Minimum Stack Address Public
; 14 Apr 89 Make heap_top public
; 14 Jul 89 Move findeof to assembler
; 09 Oct 90 Write heap_size() to return remaining bytes on heap at 
;               any given instance
;

_DLS_INCLS_	equ	1
include	message.def

CGROUP	GROUP	_TEXT
DGROUP	GROUP	_DATA

codeOFFSET	equ	offset CGROUP:
dataOFFSET	equ	offset DGROUP:
STACKSLOP	equ	128		; Minimum Stack Size

jmps	macro	label			; Define a Macro to generate the
	jmp	SHORT label		; Short Jmp instruction
	endm


_TEXT	SEGMENT	byte public 'CODE'
ifdef	MWC
	extrn	longjmp:near		; MetaWare does not preceed library
LONGJUMP	equ	longjmp		; functions with an UNDERSCORE
else
ifdef	WATCOMC
	extrn	longjmp_:near
LONGJUMP	equ	longjmp_
else
	extrn	_longjmp:near
LONGJUMP	equ	_longjmp
endif
endif

	assume	cs:CGROUP, ds:DGROUP, es:nothing

	public	_debug
_debug	proc near
	
	out	0fdh,al
	ret

_debug	endp


;	Environment manipulation routines
;	=================================
;
;BOOLEAN	env_entry(BYTE *buf, WORD entry);
;
;		Copy entry number ENTRY into the buffer BUF. Return FAILURE
;		if ENTRY cannot be found.
;
	assume	cs:CGROUP, ds:DGROUP, es:nothing

	public	_env_entry
_env_entry	PROC	near
	cld
	push	bp
	mov	bp,sp
	push	ds
	push	si
	push	es
	push	di
	call	get_env			; Get the environment segment
	mov	es,bx			; Initialise ES
	mov	cx,ax			; Check the environment size - 1 
	dec	cx			; and FFFF bytes if no env header 
	xor	di,di			; Offset to start scaning for data
	xor	ax,ax
env_e10:
	cmp	es:byte ptr [di],al	; Is this a Null string
	jz	env_fail		; Then hit the end of the search
	cmp	word ptr 06[bp],0	; Is this the entry required
	jz	env_e20
	repnz	scasb			; Scan for the next zero byte
	jcxz	env_fail		; and abort if out of space 
	dec	word ptr 06[bp]		; Decrement the string count
	jmps	env_e10
env_e20:				; Found the correct entry now copy
	mov	si,di			; Get the correct source offset
	push ds
	push es
	pop ds
	pop es
	mov	di,04[bp]
env_e30:
	lodsb
	stosb				; Copy byte through AL
	or	al,al
	jnz	env_e30			; and check for end of string
	jmps	env_exit
_env_entry	ENDP

;BOOLEAN	env_scan(BYTE *key, BYTE *buf);
;
;	Scan through the environment searching for the string KEY then copy
;	the result into buffer.

	Public _env_scan
_env_scan	PROC	near
	cld
	push	bp
	mov	bp,sp
	push	ds
	push	si
	push	es
	push	di
	call	get_env			; Get the environment segment
	call	get_key			; Find the key
	jz	env_fail		; Abort if an error occurs
	add	di,dx			; Add the Key length and just copy
	mov	si,di			; The key definition into the 
	push ds				; Buffer
	push es
	pop ds
	pop es
	mov	di,06[bp]
env_s10:
	lodsb 
	stosb				; Copy byte through AL
	or	al,al
	jnz	env_s10			; and check for end of string
	jmps	env_exit
_env_scan	ENDP

;
;	Environment handling exit routines

env_err:				; Invalid Environment descriptor
	mov	ax,-1			; return with -1
	jmps	env_ret

env_fail:				; Environment fail the operation 
	mov	ax,1			; requested has failed.
	jmps	env_ret

env_exit:
	xor	ax,ax

env_ret	PROC	near
	pop	di
	pop	es
	pop	si
	pop	ds
	pop	bp
	ret
env_ret	ENDP

;
;BOOLEAN	env_del(BYTE *key);
;	Delete the entry matching  KEY from the environment and return
;	success or failure
;
	public	_env_del
_env_del	PROC	near
	cld
	push	bp
	mov	bp,sp
	push	ds
	push	si
	push	es
	push	di
	call	get_env			; Get the environment segment
	jz	env_err			; Stop if not the real thing
	call	get_key			; Find the key
	jz	env_fail		; Abort if an error occurs
	mov	ds,bx			; Point DS at the environment
	mov	si,di			; save the destination offset
	add	di,dx			; and search for the end of this string
	xor	ax,ax
	mov	cx,-1
	repnz	scasb			; Now search for the end of string
	xchg	si,di			; Swap the source and destination
env_d10:
	cmp	al,[si]			; Is this the end of the environment
	jz	env_d20			; Yes so terminate
env_d15:
	lodsb
	stosb				; Copy through AL checking for the end
	or	al,al
	jnz	env_d15			; of the environment after each
	jmps	env_d10			; end of string.
env_d20:
	stosw				; Force 0 word to be placed here to 
	jmps	env_exit		; terminate the string
_env_del	ENDP

;BOOLEAN	env_ins(BYTE *str);
;		Insert the string at the end of the current environment
;		checking if there is enough room to save the string.
;
	public _env_ins
_env_ins	PROC	near
	cld
	push	bp
	mov	bp,sp
	push	ds
	push	si
	push	es
	push	di
	call	get_env			; Get the environment segment
	jz	env_err			; and its segment
	sub	ax,2			; Decrement the size of the env
	mov	cx,ax			; to make sure we can store a 0
	xor	ax,ax			; word terminator
	mov	es,bx			; Find the end of the current env
	xor	di,di
env_i10:
	repnz	scasb
	jcxz	env_fail
	cmp	al,es:byte ptr [di]
	jnz	env_i10
	cmp	di,1			; Is this an empty Environment
	jnz	env_i25			; No. If yes then start from offset 0
	dec	di
env_i25:
	mov	bx,di			; Save the starting address of string
	mov	si,04[bp]		; Get the source string offset
env_i20:
	lodsb
	stosb				; Copy the String until a zero byte
	or	al,al			; then add the environment terminator
	loopnz	env_i20
	mov	es:word ptr [di],0
	jz	env_exit		; Exit with no error if the string is
	mov	es:byte ptr [bx],00	; terminated correctly otherwise remove
	jmps	env_fail		; all traces of this string and exit
_env_ins	ENDP
;
	page
;
;	Returns environment size in Bytes in AX or zero if error
;	and BX is the Environment segment.
;
get_env	PROC	near
	push	es
	mov	dx,__psp		; Get the Current PSP in DX
	mov	es,dx			; and point ES at Our PSP
	xor	ax,ax			; and assume an error condition
	mov	bx,es:002Ch		; get environment segment
	dec	bx			; Check for memory descriptor
	mov	es,bx
	inc	bx
	cmp	es:byte ptr 00h,'M'	; Byte 0 must contains either an 
	jz	get_e10			; M or Z and the DMD be owned by
	cmp	es:byte ptr 00h,'Z'	; the Command Processor
	jnz	get_e20
get_e10:
if 0
	cmp	dx,es:word ptr 1h	; Is this "OUR" PSP if not then
	jnz	get_e20			; complain bitterly.
endif
	mov	ax,es:word ptr 3h	; Get the memory size in paragraphs
	shl	ax,1			; convert to size in bytes and exit.
	shl	ax,1
	shl	ax,1
	shl	ax,1
get_e20:
	pop	es
	or	ax,ax
	ret
get_env	ENDP

;
;	enter this search function with BX == ENVIRONMENT SEGMENT
;					04[bp] == Key string offset
;	On exit	AX == 0 Failure
;		else	DX is Key string Length
;			DI is Offset
;
get_key	PROC	near
	push ds
	pop es				; Calculate the length of the 
	mov	di,04[bp]		; key by scaning the string for
	mov	al,0			; a zero byte.
	mov	cx,-1
	repnz	scasb
	neg	cx			; CX is the length of the sting + 2
	sub	cx,2
	mov	dx,cx			; Save the count in dx
	
	xor	ax,ax
	mov	es,bx			; Point ES at the environment
	xor	di,di			; and start from the begining
get_k10:
	push	di			; Save incase this is a match
	mov	cx,dx			; Get the string length
	mov	si,04[bp]		; and offset and check for a match
	repz	cmpsb
	jnz	get_k20			; No match so get the next string
	pop	di			; This is the starting offset
	or	ax,-1			; All ok
	ret
get_k20:
	pop	cx			; Throw away the old DI
	mov	cx,-1			; Set the count to maximum
	repnz	scasb			; and search for the end of the string
	cmp	al,es:[di]		; exit with error if this is the end
	jnz	get_k10			; of the environment
	ret
get_key	ENDP

	page
	assume	cs:CGROUP, ds:DGROUP, es:nothing
ifdef MSC
;
;
;	STACK(WORD) allocates memory from the C STACK if at any stage
;	the stack grows to within STACKSLOP of the top of the heap this
;	function executes a LONGJUMP using the BREAK_ENV buffer. This will
;	terminate any internal function.
;
PUBLIC	_stack
_stack:
	pop	bx			; Get the return address
	pop	cx			; and the number of bytes required
	add	cx,1			; Force CX to be a even value to
	and	cx,not 1		; ensure the stack is word aligned
	mov	ax,sp			; Get the Stack
	sub	ax,STACKSLOP		; Include STACKSLOP
	sub	ax,cx			; Subtract requested buffer
	jc	heap_error		; Exit with error if Carry
	cmp	ax,heap_top		; Are we still above the heap
	jc	heap_error		; No
	pop	ax			; Get possible saved SI
	pop	dx			; Get possible saved DI
	push	dx			; Restore the stack to its
	push	ax			; origibnal format	
	sub	sp,cx			; All OK so update SP
	push	dx			; Save possible saved DI
	push	ax			; Save possible saved SI
	mov	ax,sp			; Return pointer
	add	ax,4			; Adjust pointer for saved SI/DI
	push	cx			; Restore the entry parameter
	jmp	bx			; and return to the caller
endif
;
;	HEAP_GET(WORD) allocates memory from the C HEAP if at any stage
;	the heap grows to within STACKSLOP of the base of the stack this
;	function executes a LONGJUMP using the BREAK_ENV buffer. This will
;	terminate any internal function.
;
PUBLIC	_heap_get
_heap_get:
	push	bp
	mov	bp,sp
	mov	ax,heap_top
	add	ax,04[bp]		; Add in the requested value
	jc	heap_error		; Exit with error if Carry
	sub	bp,STACKSLOP		; now check that the stack
	cmp	bp,ax			; is still well above the 
	jc	heap_error		; heap.
	mov	stack_min,ax		; Update the Stack Minimum Variable
	add	stack_min,STACKSLOP	; for the CHKSTK routine
	
	xchg	ax,heap_top		; Return the existing heap top
	pop	bp			; and update the local variable
	ret				; with the new value.

heap_error:
	mov	dx,3			; Return the Heap Overflow error
	push	dx
	mov	ax,dataOFFSET _break_env ; using the JMP_BUF
	push	ax
	call	LONGJUMP			; We are never coming back

;
;	HEAP_SIZE returns the size remaining on the C HEAP 
;
PUBLIC	_heap_size
_heap_size:
	push	bp
	mov	bp,sp
	mov	ax,heap_top
        add     ax,STACKSLOP
	sub	bp,ax		
        jnc     noprobs
        xor     bp,bp
noprobs:
	mov	ax,sp		
	pop	bp		
	ret			

;
;	HEAP() can only return a pointer to the top of the C Heap
;	and is identical in function to HEAP_GET(0) except that no
;	overflow checking is required and the calling overhead is 
;	minimal.
;
PUBLIC	_heap
_heap:
	mov	ax,heap_top
ifndef FINAL
ifdef WATCOMC
	add	ax,STACKSLOP	; we'd better do some stack checking
	cmp	ax,sp		; 'cause the C isn't doing it now
	 jae	heap_error
	sub	ax,STACKSLOP
endif
endif
	ret
	
;
;	VOID HEAP_SET(BYTE *) forces the heap to a specified value
;
PUBLIC	_heap_set
_heap_set:
	push	bp
	mov	bp,sp
	mov	ax,04[bp]		; Get the new value for the HEAP
	cmp	ax,dataOFFSET _end	; base and check against the 
	jnb	heap_s10		; absolute base. If below then force
	mov	ax,dataOFFSET _end	; the heap to the absolute base
heap_s10:
	mov	heap_top,ax	
	mov	stack_min,ax
	add	stack_min,STACKSLOP
	pop	bp
	ret

	page
ifdef MSC
;
;	This is our own Stack Check routine which is called on 
;	entry to every C routine. AX contains the number of bytes
;	to be reseved on the stack.
;
PUBLIC	__chkstk
__chkstk:
	pop	cx		; Get the Return Address

	mov	bx,sp		; Calculate the new SP value
	sub	bx,ax		; AX contains the number of bytes
	jc	OVERFLOW@	; to reserve.

	cmp	bx,stack_min	; Check we are still above the heap
	jc	OVERFLOW@	; No !!! Help
	mov	sp,bx		; Update the Stack pointer
	jmp	cx		; Its Ok lets go back
endif

ifdef WATCOMC
	Public	__STK
__STK:
	cmp	ax,sp
	 jnb	OVERFLOW@
	sub	ax,sp
	neg	ax
	cmp	ax,stack_min
	 jbe	OVERFLOW@
	ret
endif

ifdef TURBOC
	Public	OVERFLOW@		; Public TURBOC Stack Error Handler
endif
OVERFLOW@:
	mov	dx,2			; Return the STACK Overflow error
	push	dx
	mov	ax,dataOFFSET _break_env ; using the JMP_BUF
	push	ax
	call	LONGJUMP		; We are never coming back

; MLOCAL UWORD CDECL findeof(s, count)		/* find ^Z in buffer	   */
; BYTE FAR   *s;					/* buffer to search	   */
; UWORD  count;					/* # of bytes in buffer    */
; {
; REG UWORD i;
; 
; 	i = count;
; 	while(i) {				/* Scan through the data   */
; 	    if(*s++ == (BYTE) 0x1A)		/* looking for a Control-Z */
; 	        break;
; 	    i--;
; 	}
; 
; 	return (count - i);
; }

PUBLIC	_findeof
_findeof:
	push	bp			; establish a stack frame
	mov	bp,sp			;  s	dword 04[bp]
	push	es			;  count word 08[bp]
	push	di			; save important registers
	cld
	les	di,4[bp]		; load up the pointer
	mov	cx,8[bp]		;  and the count
	mov	al,26			; looking for EOF mark in the buffer
	repne	scasb			;  scan until we find one
	 jne	findeof10		; if we do find one
	inc	cx			;  then include it in the count
findeof10:
	mov	ax,8[bp]		; we wanted this many
	sub	ax,cx			;  subtract any past EOF
	pop	di
	pop	es
	pop	bp
	ret


ifdef	DLS
public	_my_dls_init
;	void my_dls_init()

	;extrn	_dls_init:near
	;extrn	_dls_get_table:near

_my_dls_init proc far

	push	ds

	push	cs
	pop	ds
	
	call	_dls_init
	mov	ax,1
	push	ax
	call	_dls_get_table
	pop	ax

	pop	ds
	ret

_my_dls_init endp

public	_copy_crit_msgs
_copy_crit_msgs proc near 

	extrn	_crit_msgs:word
	extrn	_crit_text:byte

	push	ds
	push	es
	push	di
	push	si

	push	ds
	pop	es
	push	cs
	pop	ds

	mov	si,_dls_table
	add	si,msg0
	mov	si,[si]

	mov	di,offset DGROUP:_crit_text
	add	di,2
	mov	bx,offset DGROUP:_crit_msgs
	add	bx,2

	mov	cx,24
ccm_loop1:
	mov	es:[bx],di
	add	bx,2
ccm_loop2:
	lodsb
	stosb
	cmp	al,'$'
	jne	ccm_loop2
	loop	ccm_loop1

	pop	si
	pop	di
	pop	es
	pop	ds
	ret

_copy_crit_msgs endp

public	_copy_rld_msgs
_copy_rld_msgs proc near

	extrn	_rld_msgs:word
	extrn	_rld_text:byte

	push	ds
	push	es
	push	di
	push	si

	push	ds
	pop	es
	push	cs
	pop	ds

	mov	si,_dls_table
	add	si,reload_msgs
	mov	si,[si]

	mov	di,offset DGROUP:_rld_text
	add	di,2
	mov	bx,offset DGROUP:_rld_msgs
	add	bx,2

	mov	cx,3
crm_loop1:
	mov	es:[bx],di
	add	bx,2
crm_loop2:
	lodsb
	stosb
	cmp	al,0
	jne	crm_loop2
	loop	crm_loop1

	pop	si
	pop	di
	pop	es
	pop	ds
	ret

_copy_rld_msgs endp

public	_dls_msg1
;	char *dls_msg1(int)

_dls_msg1:
	push	bp
	mov	bp,sp
	push	bx

	mov	ax,4[bp]
	shl	ax,1
	mov	bx,cs:_dls_table	
	add	bx,ax
	mov	ax,cs:[bx]
		
	pop	bx
	pop	bp
	ret

endif   ; ifdef DLS

public	_dos_parse_filename
_dos_parse_filename	proc near

	push	bp
	mov	bp,sp
	sub	sp,30h
	push	es
	
	push	ds
	pop	es
	
	lea	di,-30h[bp]
	mov	si,4[bp]
	
	mov	ax,2901h
	int	21h
	
	mov	ah,0
	pop	es
	add	sp,30h
	pop	bp
	ret	

_dos_parse_filename	endp

public	_flush_cache
_flush_cache	proc near

	push	si
	push	di
	push	bp
	
	mov	ax,4a10h
	mov	bx,0
	mov	cx,0edch
	int	2fh
	
	cmp	ax,6756h	; NWCACHE
	je	do_flush
	cmp	ax,0BABEh	; SmartDrive
	jne	skip_flush

do_flush:
	mov	ax,4a10h
	mov	bx,1
	mov	cx,0edch
	int	2fh	
	
skip_flush:
	pop	bp
	pop	di
	pop	si
	ret



_flush_cache	endp


_TEXT	ENDS

	page
_DATA	SEGMENT	byte public 'DATA'
	extrn	__psp:word
	extrn	_end:byte
	extrn	_break_env:word
	extrn	low_seg:word

	public	stack_min
	public	heap_top
ifdef TURBOC
	public	___brklvl		; Turbo C does an inline check against
___brklvl	label	word		; ___brklvl and id SP < ___brklvl then
endif					; it calls OVERFLOW@
stack_min	dw	dataOFFSET _end + STACKSLOP
heap_top	dw	dataOFFSET _end	; Current Top of Heap

_DATA	ENDS
	END
