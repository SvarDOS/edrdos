;    File              : $DOSMEM.ASM$
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
;    DOSMEM.A86 1.13 94/12/01 10:05:21
;    now freeing UMBs also during program termination
;    DOSMEM.A86 1.12 93/07/20 22:46:25
;    dmd_upper_root defaults to FFFF
;    DOSMEM.A86 1.10 93/06/18 21:00:11
;    Remove historic CDOS comment
;    ENDLOG
;

PCMDATA group PCMODE_DATA,FDOS_DSEG
PCMCODE group PCM_CODE

ASSUME DS:PCMDATA

	.nolist
	include	pcmode.equ
	include msdos.equ
	include mserror.equ
	.list
	
BEST_FIT	equ	01h		; allocate BEST match memory block
LAST_FIT	equ	02h		; allocate LAST matching memory block
UPPER_FIT	equ	80h		; preferably allocate from upper memory
UPPER_ONLY_FIT	equ	40h		; only allocate from upper memory

FIRST_FIT	equ	04h		; we use this internally...

PCM_CODE	segment public byte 'CODE'
	extrn	error_exit:near		; Standard Error Handler
	extrn	return_AX_CLC:near
	extrn	return_BX:near
	extrn	reload_ES:near
	extrn	toupper:near

;	*****************************
;	***    DOS Function 48    ***
;	*** Allocate Memory Block ***
;	*****************************
;
	Public	func48
func48:					; bx = request size
	call	dword ptr lock_tables	; lock global tables
	call	search_mem		; look for block bx or bigger
	 jc	memory_avbl_error	;  skip on error
	test	mem_strategy,LAST_FIT	; is it last fit ?
	 jz	f48_10			; no, use from begining
	mov	ax,cx			; work out how much we have
	sub	ax,bx			;  to leave free
	 je	f48_10
	dec	ax
	mov	bx,ax
	call	make_dmd		; allocate this DMD as free
	mov	bx,cx			; real block is the next one
f48_10:
	mov	ax,current_psp		; Change the Owner
	mov	es:DMD_PSP,ax		; we now own this block

	push	es
	call	make_dmd		; make new DMD for allocated mem
	pop	ax
	inc	ax			; return starting segment
	jmp	memory_exit		; unlock global tables


;	*****************************
;	***    DOS Function 49    ***
;	***   Free Memory Block	  ***
;	*****************************
;
	Public	func49
func49:
	call	dword ptr lock_tables	; lock global tables
	call	get_dmd			; es -> dmd
	 jc	memory_error		; skip if block invalid
	mov	ax,es:DMD_PSP		; get owner field
	cmp	ax,dmd_owner
	mov	ax,es			; return DMD address in AX
	 jb	func49_10
	mov	dx,dmd_address		; nothing below this block get's freed
	cmp	ax,dx			; should we free it ?
	 jb	func49_20		; no, give it a new owner
func49_10:
	xor	dx,dx			; yes, owner = 0 means free block
func49_20:
	mov	es:DMD_PSP,dx		; free/set new owner
	call	merge_mem		; merge with adjacent free blocks
;	jmp	memory_exit

; centralised exit point to unlock system tables

memory_exit:
;-----------
; On Entry:
;	AX = return value
; On Exit
;	None
;
	call	dword ptr unlock_tables	; unlock global tables
	jmp	return_AX_CLC		; return DMD address

memory_avbl_error:
	mov	bx,cx
	call	return_BX		; return biggest block available
memory_error:
	call	dword ptr unlock_tables	; unlock global tables
	mov	locus,LOC_MEMORY
	jmp	error_exit		; Jump to error handler


;	*****************************
;	***    DOS Function 4A    ***
;	***   Alter Memory Block  ***
;	*****************************
;
	Public	func4A
func4A:
	call	dword ptr lock_tables	; lock global tables
	call	get_dmd			; es -> dmd
	 jc	memory_error		; skip if block invalid

	push	es:DMD_LEN		; save the current DMD length
	call	merge_mem		; pick up unallocated blocks
	pop	ax			; return original DMD length
	 jc	memory_error		; if dmd's destroyed

	mov	ax,ED_MEMORY		; assume insufficient mem
	mov	cx,es:DMD_LEN		; cx = available size
	cmp	cx,bx			; if avail < req, then
	 jb	memory_avbl_error	; return maximum possible

	mov	ax,current_psp		; Force this block to be owned by the
	mov	es:DMD_PSP,ax		; current PSP. MACE Utilities

	call	make_dmd		; new block on top
    call    reload_ES       
	mov	ax,es
	jmp	memory_exit

;	*****************************
;	***    DOS Function 58    ***
;	*** Get/Set Alloc Strategy***
;	*****************************
;
;		On Entry:-	AL == 0 Get Allocation Strategy
;				AL == 1 Set Allocation Strategy
;				AL == 2 Get Upper Memory Link
;				AL == 3 Set Upper Memory Link
	Public	func58

func58:
	call	dword ptr lock_tables	; lock global tables
	cmp	al,3
	 ja	f58_error		; Range Check Sub-Function
	cbw				; AH = 0
	mov	si,ax
	add	si,si			; SI = word offset of sub-function
	call	cs:f58_tbl[si]		; execute the sub-function
	 jnc	memory_exit		; return the result
	jmp	memory_error		;  or the error
	

f58_error:
	mov	ax,ED_FUNCTION
	jmp	memory_error

f58_tbl	dw	f58_get_strategy
	dw	f58_set_strategy
	dw	f58_get_link
	dw	f58_set_link

f58_get_strategy:
;	mov	ah,0			; AX = subfunction = 0-3
	mov	al,mem_strategy
;	clc
	ret

f58_set_strategy:
	mov	ah,MS_M_STRATEGY
	mov	mem_strategy,bl
;	clc
	ret

f58_get_link:
	mov	ah,MS_M_STRATEGY
	mov	al,dmd_upper_link
;	clc
	ret

f58_set_link:
	mov	ax,ED_FUNCTION		; return function not implemented
	mov	cx,dmd_upper_root	;  if no upper memory chain 
	inc	cx			; CX = FFFF
	stc
	 jcxz	f58_set_link20
	dec	cx
	mov	dmd_upper_link,bl	; set link field
	mov	ax,dmd_root		; now find dmd before upper memory root
	mov	dl,IDM			; assume we want to link
	test	bl,bl			; do we want to link/unlink UMBs?
	 jnz	f58_set_link10
	mov	dl,IDZ			; no, we want to unlink
f58_set_link10:
	mov	es,ax			; point to DMD
	call	check_dmd_id		; stop if id is invalid
	 jc	f58_set_link20		;  and return an error
	push	es
	call	next_dmd		; does the next DMD match our
	pop	es
	cmp	ax,cx			; upper memory chain ?
	 jne	f58_set_link10
	mov	es:DMD_ID,dl		; set appropriate link type
	mov	ax,(MS_M_STRATEGY*256)+3; return AX unchanged
;	clc
f58_set_link20:
	ret




;****************************************
;*					*
;*	Memory Function Subroutines	*
;*					*
;****************************************
;
;	FREE_ALL takes the PSP passed in the BX register and free's all 
;	memory associated with that PSP.
; 
;	entry:		bx = requested PSP
;
;	exit:
;
	Public	free_all
free_all:
	mov	es,dmd_root		; es -> first dmd

free_all_loop:
	call	check_dmd_id		; if block is invalid
	jc	free_all_fail		;   then quit now

	mov	dl,al			; dl = id code
	cmp	es:DMD_PSP,bx		; if block is owned by another
	jnz	free_all_next		;   then check next

	and	es:DMD_PSP,0		; Free this partition
free_all_next:
	push	es
	call	next_dmd		; es -> next block up
	pop	ax
	cmp	dl,IDM			; if previous block wasn't last
	jz	free_all_loop		;   then keep going
	cmp	dmd_upper_root,ax
	jbe	free_all_end
	mov	ax,dmd_upper_root	; free UMBs as well
	cmp	ax,-1			; if UMB head is valid
	mov	es,ax
	jne	free_all_loop
free_all_end:
	xor	ax,ax			; Otherwise Stop

free_all_fail:
	ret

;
;	SET_OWNER allows the OWNING PSP to specify the new owner of
;	the partition. An error is returned if an incorrect partition address
;	is given or the partition is not owned by the current PSP.
;
;	Entry:-	AX == New PSP
;		BX == Partition Start
;
;	Exit:-
;		no carry	AX == Unknown
;		carry		AX == Error Code
;
	Public	set_owner
set_owner:
	push	es
	dec	bx
	mov	es,bx			; ES points at DMD (We Hope)
	xchg	ax,bx			; Save the New PSP address in BX
	call	check_dmd_id		; Check for a valid DMD
	 jc	s_o20
	mov	ax,current_psp
	cmp	ax,es:DMD_PSP		; Check the Current PSP owns the memory
	 jnz	s_o10
	mov	es:DMD_PSP,bx		; Set the new owner and return	
	jmp	s_o20

s_o10:
	mov	ax,ED_BLOCK
	stc
s_o20:
	pop	es
	ret

;
;	Search for a free memory block at least as big as bx
;	entry:		bx = requested size
;	success exit:	cf clear, es -> dmd
;			cx = block size
;	failure exit:	cf set, ax = error code
;			cx = biggest block available

search_mem:
	mov	ax,ED_DMD		; assume bad DMD chain
	mov	cx,dmd_root		; start at the bottom
	 jcxz	search_mem_exit
	mov	es,cx			; lets clean up memory list
	or	mem_strategy,FIRST_FIT	; grab 1st block we come to
search_mem_init:
	xor	si,si			; si = max mem available
	mov	di,0FFFFh		; di = size of candiate (FFFF=none)
					; dx = dmd of candidate
search_mem_loop:
	call	check_dmd_id		; if block is invalid
	 jc	search_mem_exit		;   then quit now

	cmp	es:DMD_PSP,0		; if block is owned
	 jnz	search_mem_next		;   then check another

	call	merge_mem		; group with unallocated blocks

	mov	ax,es			; AX = current DMD
	mov	cx,es:DMD_LEN		; cx = block length

	cmp	cx,si			; is it the biggest block we
	 jb	search_mem40		;   have found so far ?
	mov	si,cx			;  if so then save the new size
search_mem40:

	cmp	cx,bx			; if it's not long enough
	 jb	search_mem_next		;  then try the next block

	test	mem_strategy,FIRST_FIT+LAST_FIT
	 jnz	search_mem50		; grab this block ?

	test	mem_strategy,BEST_FIT	; if BEST FIT then we only save this
	 jz	search_mem_next		;  candidate if the previous
	cmp	cx,di			;  candidate was bigger
	 jae	search_mem_next
search_mem50:
	mov	dx,es			; save this DMD candidate
	mov	di,cx			;  along with it's length
	and	mem_strategy,not FIRST_FIT
search_mem_next:
	call	search_next_dmd		; try for another DMD
	mov	ax,ED_MEMORY		; assume insufficient mem
	 jc	search_mem_exit		; stop if it's true

	mov	ax,es
	cmp	ax,dmd_upper_root	; if we reach the dmd upper root
	 jne	search_mem_loop		;  then we have a special case
	test	mem_strategy,UPPER_FIT+UPPER_ONLY_FIT	; upper memory block preferred or explicitly requested?
	 jnz	search_mem_next10	; then also search UMBs
	cmp	di,0FFFFh		; no block found in lower mem?
	 je	search_mem_next10	; then also search UMBs
	jmp	search_mem_exit		; else return the previously found block 
search_mem_next10:
	or	mem_strategy,FIRST_FIT	; grab 1st high memory block we find
	test	mem_strategy,UPPER_ONLY_FIT
	 jnz	search_mem_init		; upper only is another special case
	jmp	search_mem_loop	

search_mem_exit:
	and	mem_strategy,not FIRST_FIT
	mov	cx,di			; DX&DI contain our best candidate
	inc	di			; if DI=FFFF then we don't have one
	 je	search_mem_bad		;  else we return with CX = size
	mov	es,dx			;  and ES = DMD
	clc				; clear the error flag
	ret

search_mem_bad:
	mov	cx,si			; no allocation made, so return
search_mem_error:			;  biggest block and flag the error
	stc
	ret

search_next_dmd:
; On Entry:
;	ES = current DMD
; On Exit:
;	ES = AX = next DMD
;	DX/DI preserved
;
	cmp	es:DMD_ID,IDM		; do we have any more blocks ?
	 jne	search_mem_error	;  no, return CY set
;	jmp	next_dmd		; else try next DMD

;	Point to next DOS Memory Descriptor (dmd) in the chain
;	entry:	es -> current dmd
;	exit:	es -> next dmd

next_dmd:
	mov	ax,es
	add	ax,es:DMD_LEN
	inc	ax			; allow for dmd itself
	mov	es,ax
	ret

;	Increase the size of the current mem block
;	by gobbling all adjacent unallocated blocks
;	entry:	es -> dmd
;	exit:	cf = 1, al = 7 if chain is broken
;		ES,SI,DI,DX,BX preserved

merge_mem:
	push	es
	cmp	es:DMD_ID,IDM		; if no more dmd's
	 jnz	merge_mem_done		;   then just quit

	call	next_dmd
	call	check_dmd_id		; if id is invalid
	 jc	merge_mem_quit		;   then return an error

	cmp	es:DMD_PSP,0		; if next dmd is owned
	 jnz	merge_mem_done		;   then done

	mov	cx,es:DMD_LEN		; if free, grab its length
	pop	es			; restore base dmd

	mov	es:DMD_ID,al		; use next's id (in case of last)
	inc	cx
	add	es:DMD_LEN,cx		; add new memory to base
	jmp	merge_mem		;   and try again

merge_mem_done:
	clc				; clear error flag
merge_mem_quit:
	pop	es			; restore base dmd
	ret				; with cf and error flag


;	If needed, create a new dmd on top of allocated memory
;	entry:	es -> current block
;		bx = requested block size
;		cx = current block size

make_dmd:
	cmp	bx,cx			; if request and size match
	 jz	make_dmd_done		;   then that's all we need

	mov	dl,es:DMD_ID		; get current block id
	mov	es:DMD_LEN,bx		; else shrink this block
	mov	es:DMD_ID,IDM		; not the last now
	call	next_dmd
	mov	es:DMD_ID,dl		; our old id for the new dmd
	mov	es:DMD_PSP,0		; new block is free
	sub	cx,bx
	dec	cx
	mov	es:DMD_LEN,cx		; length is whatever is left

make_dmd_done:
	ret

;	Get passed value of memory block
;	exit:	es -> dmd
;		al = DMD_ID, cf cleared if valid
;		al = 7, cf set if invalid

get_dmd:
	call	reload_ES
	mov	ax,es
	dec	ax			; back up to dmd
	mov	es,ax
;	jmp	check_dmd_id		; fall through

;	Check first byte in the dmd for a valid id code
;	entry:	es -> dmd
;	exit:	al = DMD_ID, cf cleared if valid
;		al = 7, cf set if invalid

	Public	check_dmd_id

check_dmd_id:
	mov	al,es:DMD_ID
	cmp	al,IDM			; if not last
	jz	check_dmd_done		;   then good
	cmp	al,IDZ			; if last
	jz	check_dmd_done		;   also good

	mov	ax,ED_BLOCK		; Invalid DMD
check_dmd_error:
	stc				; flag the error
check_dmd_done:
	ret

PCM_CODE	ends
	
PCMODE_DATA	segment public word 'DATA'

	extrn	lock_tables:dword
	extrn	unlock_tables:dword

	extrn	dmd_address:word	; don't free DMD's with segment under this value
	extrn	dmd_owner:word		; don't free DMD's with owner under this value
	extrn	dmd_upper_root:word
	extrn	dmd_upper_link:byte
	extrn	current_psp:word
	extrn	locus:byte
	extrn	mem_strategy:byte
	extrn	dmd_root:word

PCMODE_DATA	ends

	end
