;    File              : $STACKS.ASM$
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
;    STACKS.ASM 1.6 93/10/26 19:08:13
;    Fix bug when we run out of stacks
;    STACKS.ASM 1.4 93/09/02 22:36:47
;    Add header to system allocations
;    ENDLOG

CGROUP	group	INITCODE, STACKS

STACKS		segment	public para 'STACKS'

	Assume	CS:STACKS, DS:Nothing, ES:Nothing, SS:Nothing

StackCode:

;************
; FIXED DATA
;************

        dw  0       
NumOfStacks	dw	0		; we have this many stacks
StackCB		dw	0		; NumOfStacks*8 = size of control array
StackSize       dw	0		; size of an individual stack
StackPtr	label dword		; pointer to stack data		
StackOff	dw	offset STACKS:StackHeap
StackSeg	dw	0
FirstStack	dw	offset STACKS:StackHeap
LastStack	dw	offset STACKS:StackHeap-STACK_CB_SIZE
NextStack	dw	offset STACKS:StackHeap-STACK_CB_SIZE

;************
; FIXED DATA
;************

STACK_CB_FLAGS	equ	word ptr 0	; stack flags
STACK_CB_SP	equ	word ptr 2	; old stack saved here
STACK_CB_SS	equ	word ptr 4
STACK_CB_TOP	equ	word ptr 6	; stack top lives here
STACK_CB_SIZE	equ	8

STACK_FREE	equ	0		; stack is available to allocate
STACK_INUSE	equ	1		; stack is in use
STACK_OVERFLOW	equ	2		; stack has overflowed

;
; Our hardware interrupt handlers which are of the form
;
;	call	SwapStack
;	db	0EAh			; JMPF opcode
;	dd	oldIntHandler
;
; By looking at the near return address we can find the address of the old
; interrupt handler.
; We try to allocate a stack from our pool of stacks, working downward to
; reduce the problems of stack overflow.
;
; We check the top of the stack contains a pointer to our control block and
; if this is invalid we assume the stack has overflowed, and try the next one.
; We have no way of recovering a stack that has overflowed (eg. by zapping
; everything below us on exit).
;
; If we run out of stacks we just continue on the callers stack, rather than
; halting the system.
;

Int02:
	call	SwapStack
	db	0EAh		; JMPF
i02Off	dw	4*02h,0

Int08:
	call	SwapStack
	db	0EAh		; JMPF
i08Off	dw	4*08h,0

Int09:
	call	SwapStack
	db	0EAh
i09Off	dw	4*09h,0

Int0A:
	call	SwapStack
	db	0EAh		; JMPF
i0AOff	dw	4*0Ah,0

Int0B:
	call	SwapStack
	db	0EAh		; JMPF
i0BOff	dw	4*0Bh,0

Int0C:
	call	SwapStack
	db	0EAh		; JMPF
i0COff	dw	4*0Ch,0

Int0D:
	call	SwapStack
	db	0EAh		; JMPF
i0DOff	dw	4*0Dh,0

Int0E:
	call	SwapStack
	db	0EAh		; JMPF
i0EOff	dw	4*0Eh,0

Int70:
	call	SwapStack
	db	0EAh		; JMPF
i70Off	dw	4*70h,0

Int72:
	call	SwapStack
	db	0EAh		; JMPF
i72Off	dw	4*72h,0

Int73:
	call	SwapStack
	db	0EAh		; JMPF
i73Off	dw	4*73h,0

Int74:
	call	SwapStack
	db	0EAh		; JMPF
i74Off	dw	4*74h,0

Int76:
	call	SwapStack
	db	0EAh		; JMPF
i76Off	dw	4*76h,0

Int77:
	call	SwapStack
	db	0EAh		; JMPF
i77Off	dw	4*77h,0

SwapStack proc near
; On Entry:
;	As per INT except word on stack from near call, which gives old vector
; On Exit:
;	None
;
	cli				; just in case
	push	bp
	push	si			; save work registers
	mov	si,cs:NextStack		; start looking here for a stack
SwapStack10:
	cmp	cs:STACK_CB_FLAGS[si],STACK_FREE
	 jne	SwapStack20		; use this stack if possible
	mov	bp,cs:STACK_CB_TOP[si]	; get the top of this stack
	cmp	si,cs:word ptr [bp]	; does the check match ?
	 jne	SwapStack20		; no, try the next one
	mov	cs:NextStack,si		; remember where we are
	mov	cs:STACK_CB_FLAGS[si],STACK_INUSE
	mov	cs:STACK_CB_SS[si],ss	; save old stack
	mov	cs:STACK_CB_SP[si],sp

	mov	bp,sp
	xchg	bx,ss:word ptr 4[bp]	; BX = return address, BX saved

	mov	bp,cs
	mov	ss,bp
	mov	sp,cs:STACK_CB_TOP[si]	; switch stacks
	pushf
	call	cs:dword ptr 1[bx]	; fake an INT to old handler
	mov	ss,cs:STACK_CB_SS[si]
	mov	sp,cs:STACK_CB_SP[si]	; swap back to the original stack
	mov	cs:STACK_CB_FLAGS[si],STACK_FREE
	mov	cs:NextStack,si		; update in case we were nested
	pop	si			; restore registers
	pop	bp
	pop	bx			; (was return address, now saved BX)
	iret				; exit interrupt handler

SwapStack20:
	sub	si,STACK_CB_SIZE	; it's not, so try the next
	cmp	si,cs:FirstStack	;  if there is one
	 jae	SwapStack10
	pop	si			; restore registers
	pop	bp
	ret				; back to JMPF as we can't swap stacks

SwapStack endp

i19Table dw	4*02H, offset STACKS:i02Off
	dw	4*08H, offset STACKS:i08Off
	dw	4*09H, offset STACKS:i09Off
	dw	4*0AH, offset STACKS:i0AOff
	dw	4*0BH, offset STACKS:i0BOff
	dw	4*0CH, offset STACKS:i0COff
	dw	4*0DH, offset STACKS:i0DOff
	dw	4*0EH, offset STACKS:i0EOff
	dw	4*70H, offset STACKS:i70Off
	dw	4*72H, offset STACKS:i72Off
	dw	4*73H, offset STACKS:i73Off
	dw	4*74H, offset STACKS:i74Off
	dw	4*76H, offset STACKS:i76Off
	dw	4*77H, offset STACKS:i77Off
	dw	0

Int19:
; Trap the Int 19 reboot and restore any hardware vectors we have hooked
	cli
	cld
	xor	ax,ax
	mov	es,ax		; ES = interrupt vectors
	push	cs
	pop	ds
	lea	si,i19Table	; DS:SI -> table to restore
Int1910:
	lodsw
	xchg	ax,di		; ES:DI -> address to restore to
	lodsw
	xchg	ax,si		; CS:SI -> value to restore
	movsw
	movsw
	xchg	ax,si		; restore position in table
	cmp	ds:word ptr [si],0
	 jne	Int1910
	db	0EAh		; JMPF
i19Off	dw	4*19h,0

	even				; word align our stacks

StackHeap label	word			; dynamically build stack CB's here

RELOCATE_SIZE	equ	($ - StackCode)

STACKS		ends

INITCODE	segment public para 'INITCODE'

	Assume	CS:CGROUP, DS:CGROUP, ES:Nothing, SS:Nothing

	extrn	alloc_hiseg:near

	Public	InitStacks
;==========
InitStacks:
;==========
; On Entry:
;	CX = number of stacks
;	DX = size of stack
;	Values are checked
; On Exit:
;	None
;
	push	ds
	push	es
	inc	dx			; let's ensure stacks are WORD
	and	dx,0FFFEh		;  aligned...
	mov	NumOfStacks,cx
	mov	StackSize,dx
	mov	ax,STACK_CB_SIZE
	mul	cx			; AX = bytes in control area
	mov	StackCB,ax
	add	LastStack,ax
	add	NextStack,ax
	add	StackOff,ax		; adjust our pointers
	xchg	ax,cx			; AX = NumOfStacks
	mul	StackSize		; AX bytes are required for stacks
	add	ax,StackOff		; add to start of stacks
	push	ax			; save length in bytes
	add	ax,15			; allow for rounding
	mov	cl,4
	shr	ax,cl			; convert it to para's
	mov	dl,'S'			; allocation signature is Stacks
	call	alloc_hiseg		; allocate some memory
	pop	cx			; CX = length in bytes
	mov	StackSeg,ax		; remember where
	mov	es,ax
			Assume ES:STACKS
	xor	di,di
	mov	al,0CCh			; fill stacks with CC for debug
	rep	stosb
	xor	di,di
	mov	si,offset CGROUP:StackCode
	mov	cx,RELOCATE_SIZE
	rep	movsb			; relocate the code

	mov	bx,FirstStack		; lets start building the CB's
	mov	cx,NumOfStacks
	lds	si,StackPtr		; SI = bottom of stack area
			Assume DS:STACKS
	sub	si,WORD			; we want the word below top of stack
InitStacks10:
	add	si,StackSize		; SI = top of stack
	mov	ds:STACK_CB_FLAGS[bx],STACK_FREE
	mov	ds:STACK_CB_TOP[bx],si	; set top of stack
	mov	ds:word ptr [si],bx	; set backlink
	add	bx,STACK_CB_SIZE	; onto next control block
	loop	InitStacks10
			
	xor	ax,ax
	mov	ds,ax
			Assume DS:Nothing
	cli
	mov	si,offset CGROUP:iTable	; now we fixup the vectors
InitStacks20:
	mov	ax,cs:word ptr 0[si]	; ES:AX = entry point
	mov	di,cs:word ptr 2[si]	; ES:DI = fixup location
	mov	bx,es:word ptr [di]	; get the vector to fixup
	xchg	ax,ds:word ptr [bx]	; set entry offset while saving
	stosw				;  previous handler offset
	mov	ax,es
	xchg	ax,ds:word ptr 2[bx]	; now the segment
	stosw
	add	si,2*WORD		; onto next entry
	cmp	cs:word ptr 0[si],0	; (zero terminated)
	 jnz	InitStacks20
	sti
InitStacks30:
	pop	es
	pop	ds
	ret

iTable	dw	offset STACKS:Int02, offset STACKS:i02Off
	dw	offset STACKS:Int08, offset STACKS:i08Off
	dw	offset STACKS:Int09, offset STACKS:i09Off
	dw	offset STACKS:Int0A, offset STACKS:i0AOff
	dw	offset STACKS:Int0B, offset STACKS:i0BOff
	dw	offset STACKS:Int0C, offset STACKS:i0COff
	dw	offset STACKS:Int0D, offset STACKS:i0DOff
	dw	offset STACKS:Int0E, offset STACKS:i0EOff
	dw	offset STACKS:Int70, offset STACKS:i70Off
	dw	offset STACKS:Int72, offset STACKS:i72Off
	dw	offset STACKS:Int73, offset STACKS:i73Off
	dw	offset STACKS:Int74, offset STACKS:i74Off
	dw	offset STACKS:Int76, offset STACKS:i76Off
	dw	offset STACKS:Int77, offset STACKS:i77Off
	dw	offset STACKS:Int19, offset STACKS:i19Off
	dw	0

INITCODE	ends

	end
