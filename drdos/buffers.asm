title 'BUFFERS - buffer handling routines'
;    File              : $BUFFERS.ASM$
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
;    BUFFERS.A86 1.13 94/11/30 16:26:08 
;    added support for using multiple FAT copies on reads if one fails    
;    BUFFERS.A86 1.12 93/08/06 16:19:11
;    make geblk public    
;    BUFFERS.A86 1.8 93/07/07 21:06:25
;    Smirnoff'd
;    BUFFERS.A86 1.6 93/03/16 22:30:29
;    UNDELETE support changes
;    BUFFERS.A86 1.5 93/03/05 18:00:26
;    Fix bug clearing cluster of new sub directory
;    ENDLOG

;	Date	   Who	Modification
;	---------  ---	---------------------------------------
;    9 Sep 91 Initial version created for VLADIVAR
;    3 mar 93 correct zeroblk bug

PCMCODE	GROUP	BDOS_CODE
PCMDATA	GROUP	BDOS_DATA,PCMODE_DATA

	.NOLIST
	include fdos.equ
	include bdos.equ
	include doshndl.def
	.LIST

PCMODE_DATA	segment public word 'DATA'

	extrn	current_ddsc:dword
ifdef DELWATCH
	extrn	fdos_stub:dword
endif
PCMODE_DATA	ends


BDOS_DATA 	segment public word 'DATA'

fatrec		dw	2 dup (0)	; current FAT record

fatbytl		db	0		; low byte of split FAT entry
fatbyth		db	0		; high byte of split FAT entry
split_fat	db	0		; 0/FFh to indicate split entry
tag_flg		db	0		; do not read FAT sector, just tag it

alloc_clus_cl	dw	0,0
alloc_chain_cl	dw	0,0
delfat_cl	dw	0,0

	extrn	adrive:byte
	EXTRN	chdblk:WORD
	EXTRN	clsize:WORD
	EXTRN	cur_dma:WORD
	EXTRN	cur_dma_seg:WORD
	extrn	dosfat:WORD
	EXTRN	fatadd:WORD
	extrn	lastcl:word
	extrn	blastcl:word
	EXTRN	mult_sec:WORD
	EXTRN	nfatrecs:WORD
	EXTRN	nfats:WORD
	extrn	pblock:dword
	extrn	physical_drv:byte
	extrn	psecsiz:word
	extrn	rwmode:byte		; data/directory/FAT, read/write
	extrn	secperclu:word
	extrn	bcb_root:dword		; PCMODE disk buffer root
	extrn	deblock_seg:word
BDOS_DATA	ends

BDOS_CODE 	segment public word 'CODE'
ASSUME DS:PCMDATA

	extrn	clus2sec:near
	extrn	discard_dirbuf:near
	extrn	fdos_error:near
	extrn	flush_dirbuf:near
	extrn	hshdscrd:near
	extrn	read_block:near
	extrn	select_adrive:near	; select drive AL
	extrn	write_block:near
	extrn	output_hex:near
	extrn	div32:near

	public	alloc_cluster		; allocate data block
	public	alloc_chain		; allocate a chain
	public	buffers_check		; check if buffers exist for this drive
	PUBLIC	delfat			; release data blocks
	PUBLIC	discard_all		; discard all buffers on ADRIVE
	public	discard_dir		; discard directory buffers on ADRIVE
	public	discard_dirty		; discard directory buffers on ADRIVE
	PUBLIC	fixfat			; set value of FAT entry
	public	flush_drive		; flush buffers to disk
	public	locate_buffer		; locate a buffer
	PUBLIC	update_dat		; flush write pending buffers
	public	update_ddsc_free	; count free blocks on drive
	PUBLIC	update_dir		; update directory entry
	PUBLIC	update_fat		; write out modified FAT records
	public	zeroblk			; zero cluster (MKDIR)
ifdef DELWATCH
	public	allocate_cluster	; allocate free cluster on adrive
	public	change_fat_entry	; write a new value into the FAT
endif




update_ddsc_free:
;----------------
; make sure DDSC_FREE is up to date
; a by-product of this is to checksum the FAT, so we can spot changes
; of removable media
	push	es
	les	bx,ss:current_ddsc
;	mov	cx,es:DDSC_FREE[bx]	; get current free space
;	 jcxz	update_ddsc_free30	; if none recount to make sure
	cmp	dosfat,FAT32		; FAT32 drive?
	 je	update_ddsc_free03	; yes
	cmp	es:word ptr DDSC_FREE[bx],0	; check current free space
	 je	update_ddsc_free30	; if none recount to make sure
	cmp	es:word ptr DDSC_FREE[bx],0ffffh ; is count uninitialised ? (=FFFF)
	 je	update_ddsc_free30	; if so better count the free space
	jmp	update_ddsc_free10	; skip 32-bit free blocks count
update_ddsc_free03:
	cmp	es:word ptr DDSC_BFREE+2[bx],0	; check current free space
	 jne	update_ddsc_free05
	cmp	es:word ptr DDSC_BFREE[bx],0
	 je	update_ddsc_free30	; if none recount to make sure
update_ddsc_free05:
;	inc	cx			; is count uninitialised ? (=FFFF)
	cmp	es:word ptr DDSC_BFREE+2[bx],0ffffh	; is count uninitialised ? (=FFFF)
	 jne	update_ddsc_free10
	cmp	es:word ptr DDSC_BFREE[bx],0ffffh
	 jz	update_ddsc_free30	; if so better count the free space
update_ddsc_free10:
	cmp	dosfat,FAT32		; FAT32 drive?
	 jne	update_ddsc_free16	; no, then 16-bit value is exact
	mov	ax,es:word ptr DDSC_BFREE[bx]
	cmp	es:word ptr DDSC_BFREE+2[bx],0	; is the 16-bit value valid?
	 je	update_ddsc_free15	; yes, then leave it
	mov	ax,0fffeh		; else use a fake value
update_ddsc_free15:
	mov	es:DDSC_FREE[bx],ax	; update the 16-bit value as well
update_ddsc_free16:
	pop	es
	ret

update_ddsc_free30:
; rebuild our free space count
	cmp	dosfat,FAT32		; FAT32 drive?
	 jne	update_ddsc_free33	; no, then skip
	cmp	es:word ptr DDSC_BFREE+2[bx],0	; out of free space?
	 jne	update_ddsc_free31	; no, just unknown
	cmp	es:word ptr DDSC_BFREE[bx],0
	 je	update_ddsc_free33	; yes, then recount
update_ddsc_free31:			; else try FS info sector value
	cmp	es:DDSC_FSINFO[bx],0ffffh;FS info sector present?
	 je	update_ddsc_free33	; no, then do not try to read from it
	call	read_fsinfo05		; read the info block first, if one exists
	cmp	es:word ptr DDSC_BFREE+2[bx],0	; is free block count on disk zero?
	 jne	update_ddsc_free32	; no
	cmp	es:word ptr DDSC_BFREE[bx],0
	 je	update_ddsc_free33	; yes, recount to make sure
update_ddsc_free32:
	cmp	es:word ptr DDSC_BFREE+2[bx],0ffffh	; still uninitialized?
	 jne	update_ddsc_free10	; no, then use this value
	cmp	es:word ptr DDSC_BFREE[bx],0ffffh
	 jne	update_ddsc_free10
update_ddsc_free33:			; else really rebuild it
	xor	ax,ax			; assume no free space yet
	xor	dx,dx
	cmp	dosfat,FAT32		; FAT32 drive?
	 jne	update_ddsc_free35	; no, then skip
	lea	di,DDSC_BBLOCK[bx]	; ES:DI -> DDSC_BBLOCK
	stosw				; DDSC_BBLOCK = 0
	stosw
	lea	di,DDSC_BFREE[bx]	; ES:DI -> DDSC_BFREE
	stosw				; DDSC_BFREE = 0
	stosw
update_ddsc_free35:
	lea	di,DDSC_BLOCK[bx]	; ES:DI -> DDSC_BLOCK
	stosw				; DDSC_BLOCK = 0
	stosw				; DDSC_FREE = 0
	inc	ax			; skip reserved block #'s 0 and 1
update_ddsc_free40:
;	inc	ax			; move to next data block #
	add	ax,1			; move to next data block #
	adc	dx,0
;	cmp	ax,lastcl		; are we beyond end of disk
	cmp	dx,blastcl+2		; are we beyond end of disk
;	 ja	update_ddsc_free10	; stop if all free blocks counted
	 ja	update_ddsc_free50	; stop if all free blocks counted
	 jb	update_ddsc_free45
	cmp	ax,blastcl
;	 ja	update_ddsc_free10
	 ja	update_ddsc_free50
update_ddsc_free45:
;	push	ax			; save current index
	push	dx			; save current index
	push	ax
	call	getblk			; get contents of FAT entry, update ZF
	pop	ax			; restore current FAT index
	pop	dx
	 jnz	update_ddsc_free40	; try next block if not free
	inc	es:DDSC_FREE[bx]	; one more free block
	cmp	dosfat,FAT32		; FAT32 drive?
	 jne	update_ddsc_free40	; no, then skip
	add	es:word ptr DDSC_BFREE[bx],1	; one more free block
	adc	es:word ptr DDSC_BFREE+2[bx],0
	jmp	update_ddsc_free40	; try next block
update_ddsc_free50:
	cmp	es:DDSC_FSINFO[bx],0ffffh;FS info sector present?
	 je	update_ddsc_free55	; no, then do not write to it, either
	call	write_fsinfo		; write a new FS info block first if applicable
update_ddsc_free55:
	jmp	update_ddsc_free10


discard_dirty:
;-------------
;	This gets called after a write-protect error is returned

	mov	ah,BF_DIRTY		; discard dirty FAT, dir & data
	jmp	discard_buffers

discard_all:
;-----------
	mov	ah,BF_ISFAT+BF_ISDIR+BF_ISDAT
	jmp	discard_buffers		; discard all the buffers

discard_dir:
;-----------
	mov	ah,BF_ISDIR		; dir only, leave data and FAT
;	jmp	discard_buffers	

discard_buffers:
;---------------
;	entry:	adrive = drive to discard
;		AH = flags for type to discard i.e. BF_ISFAT, etc.

	mov	al,adrive		; get the work drive
	call	discard_dirbuf		; discard 32-byte directory buffer
	call	hshdscrd		; discard hashing info for drive
	les	si,bcb_root		; get first buffer
discard_buffers10:
	cmp	al,es:BCB_DRV[si]	; does the drive match?
	 jne	discard_buffers20	; try next one if not
	test	ah,es:BCB_FLAGS[si]	; does the type match?
	 jz	discard_buffers20	; try next one if not
	mov	es:BCB_DRV[si],0FFh	; else discard the buffer
	mov	es:BCB_FLAGS[si],0
discard_buffers20:
	mov	si,es:BCB_NEXT[si]	; get next buffer address
	cmp	si,word ptr bcb_root
	 jne	discard_buffers10	; and repeat until all done
discard_buffers30:
	push	ds
	pop 	es			; restore ES and return
	ret


;-------------
buffers_check:
;-------------
;	entry:	AL = drive to check (preserved)
;		AH = flags
;	exit:	ZF = 1 if all buffers clean on this drive

	push	ds			; we use DS here cause it's quicker...
	lds	si,ss:bcb_root		; start with most recently used
buffers_check10:
	cmp	al,BCB_DRV[si]		; check if for different drive
	 jne	buffers_check20		;   skip if not our problem
	test	ah,BCB_FLAGS[si]	; test if its one we are looking for
	 jnz	buffers_check30		;   return with non-zero condition
buffers_check20:
	mov	si,BCB_NEXT[si]		; get next buffer address
	cmp	si,ss:word ptr bcb_root
	 jne	buffers_check10		; loop back if more to do
	xor	dx,dx			; set ZF = 1
buffers_check30:
	pop	ds			; restore DS after BCBs done
	ret



;	entry:	DX:AX = first block to release
;	exit:	DX:AX and following released

delfat:			; release chain of clusters
;------
;	cmp	ax,2			; is block number too small?
	cmp	dx,0			; is block number too small?
	 jne	delfat05		; no, proceed
	cmp	ax,2
	 jb	delfat10		; yes, then stop it
delfat05:	
;	cmp	ax,lastcl		; is block number too large?
	cmp	dx,blastcl+2		; is block number too large?
	 ja	delfat10		; yes, then stop it
	 jb	delfat06		; no, proceed
	cmp	ax,blastcl
	 ja	delfat10
delfat06:
	push	dx
	push	ax			; else save the number
	call	getblk			; get the next link
;	xchg	ax,cx			; CX = link
	mov	delfat_cl,ax		; DX:AX = link
	mov	delfat_cl+2,dx
	pop	ax			; AX = this block
	pop	dx
	sub	bx,bx			; set it to 0000
	sub	cx,cx
;	push	cx			; save the link for next pass
	call	fixfat			; release the block
;	pop	ax			; AX = next block or end
	mov	ax,delfat_cl
	mov	dx,delfat_cl+2
	jmp	delfat			; try again until all released
delfat10:				; all blocks in chain freed
	ret


; On Entry:
;	DX:AX = block to read
; On Exit:
;	DX:AX = next FAT block index
;
	Public	getnblk

getnblk:				;UWORD getnblk(blk);
;-------
;
	push	ax
	call	getblk			; get current setting
	pop	bx
	 jz	getnblk10		; return if something there
	ret
getnblk10:
	mov	ax,dosfat		; if unallocated then allocate it
	push	dx
	push	ax
	xchg	ax,bx			; DX:AX = blk, CX:BX = i
	xchg	dx,cx
	call	fixfat
	pop	ax
	pop	dx
;	mov	dx,ax			; DX = end of chain
	xor	cx,cx			; no blocks follow this one
	ret

; On Entry:
;	DX:AX = block to read
; On Exit:
;	DX:AX = contents
;	ZF = 1 if AX == 0000h (disk full)

	Public	getblk

;------
getblk:
;------
	push	es
	push 	bx
	call	fatptr			; get address of block DX:AX in buffer
	mov	ax,es:[bx]		; get the word from FAT
	 jnz	getblk10		; skip if on odd address (must be 12 bit)
	cmp	dosfat,FAT12		; else check if 16/32 or 12 bit
	 je	getblk20		; skip if even 12 bit
	xor	dx,dx
	cmp	dosfat,FAT32		; check if 32 bit
	 jne	getblk05
	mov	dx,es:2[bx]
	and	dx,0fffh		; mask out reserved bits
getblk05:
	pop	bx
	pop 	es
	test	dx,dx			; update ZF
	 jnz	getblk06
	test	ax,ax			; update ZF
getblk06:
	ret

getblk10:
	shr	ax,1			; shift top 12 bits down
	shr	ax,1
	shr	ax,1
	shr	ax,1
getblk20:
	xor	dx,dx
	and	ax,0FFFh		; leave bottom 12 bits only
	pop	bx
	pop 	es
	ret



alloc_cluster:
;-------------
; On Entry:
;	DX:AX = previous cluster (hint for desired start)
; On Exit:
;	DX:AX = start of chain
;	CY set on failure
;
	mov	cx,1
;	jmp	alloc_chain

alloc_chain:
;-----------
; On Entry:
;	DX:AX = previous cluster (hint for desired start)
;	CX = # clusters wanted
; On Exit:
;	DX:AX = start of chain, 0 on failure
;	CY set on failure
;
; We want to allocate a chain of CX clusters, AX was previous cluster
; We return with CY clear and AX = 1st cluster in chain on success,
; CY set on failure
;
; When allocating a new chain we first ask SSTOR how much physical space is
; present on the disk. Until SSTOR reports at least 2 clusters free we
; repeatedly call DELWATCH to purge files and recover space. If DELWATCH is
; unable to free space we return "disk full".
;
; When allocating a block we normally are normally given a target block to
; start searching from. We allow DELWATCH to alter this value when it frees
; space to optimise the search.
;
	mov	alloc_chain_cl,cx	; save entry parameters
	mov	alloc_chain_cl+2,0
;	push ax ! push cx		; save entry parameters
	push	dx
	push	ax			; save entry parameters
	call	update_ddsc_free	; make sure DDSC_FREE is correct
ifdef DELWATCH
alloc_chain10:
;	push	dx			; DX = clusters wanted
	les	bx,ss:current_ddsc
	mov	al,adrive		; AL = current drive
	cmp	dosfat,FAT32		; FAT32 drive?
	 je	alloc_chain12		; yes
	mov	cx,es:DDSC_FREE[bx]	; CX = clusters available
	cmp	cx,alloc_chain_cl	; do we have enough room in the FAT ?
	 jb	alloc_chain20		; if not ask DELWATCH to purge
	jmp	alloc_chain15
alloc_chain12:
	mov	cx,es:word ptr DDSC_BFREE+2[bx]	; CX = clusters available
;	cmp	cx,dx			; do we have enough room in the FAT ?
	cmp	cx,alloc_chain_cl+2	; do we have enough room in the FAT ?
	 jb	alloc_chain20		; if not ask DELWATCH to purge
	 ja	alloc_chain15
	mov	cx,es:word ptr DDSC_BFREE[bx]
	cmp	cx,alloc_chain_cl
	 jb	alloc_chain20
alloc_chain15:
	mov	ah,SSTOR_SPACE		; does Superstore have room for data?
	call	dword ptr ss:fdos_stub	; call stub routine
	test	cx,cx			; are we out of space ?
	 jnz	alloc_chain40		; no, go ahead and allocate the chain
	mov	es:DDSC_FREE[bx],cx	; SSTOR says there's none, lets agree
	cmp	dosfat,FAT32		; FAT32 drive?
	 jne	alloc_chain16		; no, then skip
	mov	es:word ptr DDSC_BFREE[bx],cx	; SSTOR says there's none, lets agree
	mov	es:word ptr DDSC_BFREE+2[bx],cx
alloc_chain16:
;	call	update_fat		; flush FAT to bring SSTOR up to date
	jmp	alloc_chain10		; go round again and ask DELWATCH to
					;  free up some more space
					; we loop until either SSTOR says OK
					;  or DELWATCH frees all it can
alloc_chain20:
	mov	cx,es:DDSC_FREE[bx]
	mov	ah,DELW_FREECLU		; ask DELWATCH to purge a file
	call	dword ptr ss:fdos_stub	; call stub routine
	cmp	cx,es:DDSC_FREE[bx]	; can DELWATCH free up any space ?
	 jne	alloc_chain10		; yes, go and try again
alloc_chain30:
	pop	ax			; failure, restore stack
	pop	dx
	jmp	alloc_chain80		;  and exit in failure

alloc_chain40:
endif
	pop	ax			; restore entry parameters
	pop	dx
;	push	cx			; save # required
;	xor	dx,dx
	call	allocate_cluster	; try to allocate 1st cluster
;	pop	cx			; recover # required
	test	ax,ax			; could we ?
	 jnz	alloc_chain45
	test	dx,dx
	 jz	alloc_chain80
alloc_chain45:
;	dec	cx			; one less to allocate
	sub	alloc_chain_cl,1	; one less to allocate
	sbb	alloc_chain_cl+2,0

	push	dx
	push	ax			; save head of chain
;	 jcxz	alloc_chain60
	cmp	alloc_chain_cl+2,0
	 jnz	alloc_chain50
	cmp	alloc_chain_cl,0
	 jz	alloc_chain60
alloc_chain50:
;	push	cx

	push	dx
	push	ax			; save current end of chain
	call	allocate_cluster	; allocate another cluster
	pop	bx			; CX:BX = end of chain
	pop	cx

	test	ax,ax			; could we allocate anything ?
	 jnz	alloc_chain55
	test	dx,dx
	 jz	alloc_chain70		; no, bail out and free partial chain

alloc_chain55:
	xchg	ax,bx			; DX:AX = previous cluster, link cluster
	xchg	dx,cx
	push	cx
	push	bx			;  CX:BX to end of the chain
	call	fixfat
	pop	ax			; DX:AX = new end of chain
	pop	dx

;	pop	cx
;	loop	alloc_chain50
	sub	alloc_chain_cl,1
	sbb	alloc_chain_cl+2,0
	cmp	alloc_chain_cl+2,0
	 jne	alloc_chain50
	cmp	alloc_chain_cl,0
	 jne	alloc_chain50
alloc_chain60:
	pop	ax			; return the start of the chain as it's
	pop	dx
	clc				;  long enough now...
	ret

alloc_chain70:
; We haven't enough free clusters - lets free what we allocated so far
;	pop	cx			; discard count
	pop	ax			; DX:AX = start of chain
	pop	dx
	call	delfat			; release the chain
alloc_chain80:
	xor	ax,ax
	xor	dx,dx
	stc				; we couldn't manage it
	ret

allocate_cluster:
;----------------
; On Entry:
;	DX:AX = cluster to start from (0 = none known)
; On Exit:
;	DX:AX = cluster allocated
;
	test	ax,ax			; previous block known?
	 jnz	alloc_cl10		; skip if it is
	test	dx,dx
	 jnz	alloc_cl10
;	push	ds
;	lds	bx,ss:current_ddsc
;	mov	ax,ds:DDSC_BLOCK[bx]	; else continue from last allocated block
	push	es
	les	bx,ss:current_ddsc
	mov	ax,es:DDSC_BLOCK[bx]	; else continue from last allocated block
	xor	dx,dx
	cmp	dosfat,FAT32		; FAT32 drive?
	 jne	alloc_cl05		; no, then skip
	mov	ax,es:word ptr DDSC_BBLOCK[bx]	; else continue from last allocated block
	mov	dx,es:word ptr DDSC_BBLOCK+2[bx]
alloc_cl05:
;	pop	ds
	pop	es
alloc_cl10:
	mov	bx,lastcl		; highest block number on current disk
;	cmp	ax,bx			; is it within disk size?
	cmp	dx,blastcl+2		; is it within disk size?
	 ja	alloc_cl15
	 jb	alloc_cl20
	cmp	ax,blastcl
	 jb	alloc_cl20		; skip if it is
alloc_cl15:
	sub	ax,ax			; start at the beginning
	sub	dx,dx

alloc_cl20:
;	mov	si,ax			; remember start of search
	mov	alloc_clus_cl,ax	; remember start of search
	mov	alloc_clus_cl+2,dx
	test	ax,ax			; is this the 1st block?
	 jnz	alloc_cl30		; no
	test	dx,dx
	 jnz	alloc_cl30
	inc	ax			; start at beginning
alloc_cl30:				; main loop:
;	inc	ax			; skip to block after current
	add	ax,1			; skip to block after current
	adc	dx,0
	push	dx
	push 	ax			; quick save
	call	getblk			; get the content of this block
	pop	ax
	pop 	dx
	 jz	alloc_cl50		; return if free
;	cmp	ax,bx			; are we at the end yet?
	cmp	dx,blastcl+2		; are we at the end yet?
	 ja	alloc_cl35		; yes
	 jb	alloc_cl30		; no, try next block
	cmp	ax,blastcl
	 jb	alloc_cl30
alloc_cl35:
	xor	ax,ax			; wrap to start of disk
	xor	dx,dx
;	mov	bx,si			; remember starting position last time
	mov	bx,alloc_clus_cl+2	; remember starting position last time
	test	bx,bx			; have we been all the way round ?
	 jnz	alloc_cl20		;  no, lets search from start
	mov	bx,alloc_clus_cl
	test	bx,bx
	 jnz	alloc_cl20
;	push	ds
;	lds	bx,ss:current_ddsc
;	mov	ds:DDSC_FREE[bx],ax	; we definitely have none left
	push	es
	les	bx,ss:current_ddsc
	mov	es:DDSC_FREE[bx],ax	; we definitely have none left
	cmp	dosfat,FAT32		; FAT32 drive?
	 jne	alloc_cl36		; no, then skip
	mov	es:word ptr DDSC_BFREE[bx],ax	; we definitely have none left
	mov	es:word ptr DDSC_BFREE+2[bx],dx
alloc_cl36:
;	pop	ds
	pop	es
	ret				; return (0);

alloc_cl50:
;	push	ds			; block # AX is available
;	lds	bx,ss:current_ddsc
;	mov	ds:DDSC_BLOCK[bx],ax	; remember for next time
	push	es			; block # AX is available
	les	bx,ss:current_ddsc
	mov	es:DDSC_BLOCK[bx],ax	; remember for next time
	cmp	dosfat,FAT32		; FAT32 drive?
	 jne	alloc_cl52		; no, then skip
	mov	es:word ptr DDSC_BBLOCK[bx],ax	; remember for next time
	mov	es:word ptr DDSC_BBLOCK+2[bx],dx
alloc_cl52:
;	pop	ds
	pop	es

	push	dx
	push	ax
	cmp	dosfat,FAT32		; FAT32 file system?
	 je	alloc_cl55		; yes, then handle this case specially
	mov	bx,dosfat		; mark this block as end of file
	xor	cx,cx
	jmp	alloc_cl60
alloc_cl55:
	mov	bx,FAT16
	mov	cx,bx
alloc_cl60:
	call	fixfat			; for convenience
	pop	ax
	pop	dx

	test	ax,ax			; update ZF from AX
	 jnz	alloc_cl65
	test	dx,dx
alloc_cl65:
	ret				; return block number





ifdef DELWATCH

; Update a FAT entry with a new value

change_fat_entry:
;----------------
; On Entry:
;	DX:AX = block number to change
;	CX:BX = new value
; On Exit:
;	None
;
;	mov	bx,dx
;	jmp	fixfat
endif

;	entry:	DX:AX = block number to change
;		CX:BX = new value
;	exit:	DS,ES = sysdat

;------
fixfat:
;------
	push	cx			; save new value
	push	bx
	push	dx
	push	ax
	call	update_ddsc_free	; make sure DDSC_FREE is correct
	pop	ax
	pop	dx
;	cmp	dosfat,FAT16		; check if 16-bit FAT
;	 jne	fixfat30		; skip if 12 bit FAT
	cmp	dosfat,FAT12		; check if 16/32-bit FAT
	 jne	fixfat04		; skip if 12 bit FAT
	jmp	fixfat30
fixfat04:
	call	fatptr			; ES:BX -> FAT word to modify
	pop	ax			; restore new value
	pop	dx
	xor	di,di			; get a zero (no change of space)
	cmp	dosfat,FAT32		; check if 32-bit FAT
	 jne	fixfat09		; skip if 16-bit FAT

	test	ax,ax			; are we setting to 0 or non-zero?
	 jnz	fixfat05
	test	dx,dx
fixfat05:
	xchg	ax,es:[bx]		; set the low word in the buffer
	xchg	dx,es:2[bx]		; and the high word
	 jnz	fixfat08		; skip if releasing block
	test	ax,ax			; check if word was 0 before
	 jnz	fixfat06
	test	dx,dx
	 jz	fixfat20		; skip if setting 0 to 0
fixfat06:
	inc	di			; DI = 0001h, one free cluster more
	jmp	fixfat15
fixfat08:				; allocating or fixing block
	test	ax,ax			; check if word was 0 before
	 jnz	fixfat20		; skip if setting non-0 to non-0
	test	dx,dx
	 jnz	fixfat20
	dec	di			; one free cluster less now
	jmp	fixfat15

fixfat09:
	test	ax,ax			; are we setting to 0 or non-zero?
	xchg	ax,es:[bx]		; set the word in the buffer
	 jnz	fixfat10		; skip if releasing block
	test	ax,ax			; check if word was 0 before
	 jz	fixfat20		; skip if setting 0 to 0
	inc	di			; DI = 0001h, one free cluster more
	jmp	fixfat15
fixfat10:				; allocating or fixing block
	test	ax,ax			; check if word was 0 before
	 jnz	fixfat20		; skip if setting non-0 to non-0
	dec	di			; one free cluster less now

fixfat15:				; DI = change in free space (-1,1)
	les	si,current_ddsc
	add	es:DDSC_FREE[si],di	; update free space count
	cmp	dosfat,FAT32		; FAT32 drive?
	 jne	fixfat20		; no, then skip
	cmp	di,0ffffh
	 je	fixfat16
	add	es:word ptr DDSC_BFREE[si],di	; update free space count
	adc	es:word ptr DDSC_BFREE+2[si],0
	jmp	fixfat17
fixfat16:
	sub	es:word ptr DDSC_BFREE[si],1	; update free space count
	sbb	es:word ptr DDSC_BFREE+2[si],0
fixfat17:
	mov	ax,es:word ptr DDSC_BFREE[si]
	cmp	es:word ptr DDSC_BFREE+2[si],0	; does this fit into 16 bits?
	 je	fixfat18		; yes, proceed
	mov	ax,0fffeh		; else use a fake 16-bit value
fixfat18:
	mov	es:DDSC_FREE[si],ax
fixfat20:
	les	si,bcb_root		; ES:SI -> buffer control block
	or	es:BCB_FLAGS[si],BF_DIRTY
					; mark the buffer as dirty
	push	ds
	pop 	es			; ES back to local DS
	ret


	; We're dealing with a 12-bit FAT...

fixfat30:				; changing 12-bit FAT entry
	xor	dx,dx
	call	fatptr			; get address of block AX in ES:BX
	pop	cx			; get new value
	pop	dx			; got 16-bit value from stack, clean up
	mov	dx,es:[bx]		; get old value
	 jz	fixfat40		; skip if even word
	mov	ax,0FFF0h		; set mask for new value
	add	cx,cx			; else shift new value into top bits
	add	cx,cx
	add	cx,cx
	add	cx,cx
	jmp	fixfat50		; set the new word
fixfat40:
	mov	ax,00FFFh		; set mask for new value
	and	cx,ax
fixfat50:				; AX = mask, CX = new, DX = old
	mov	si,0			; assume space doesn't change
	 jnz	fixfat60		; skip if new value is zero
	test	dx,ax			; test if old value was zero as well
	 jz	fixfat70		; yes, no change in free space
	inc	si			; else one more block available
	jmp	fixfat70
fixfat60:				; new value is non-zero
	test	dx,ax			; is old value non-zero as well?
	 jnz	fixfat70		; yes, no change in free space
	dec	si			; else one block less free now
fixfat70:
	not	ax			; flip the mask bits around
	and	dx,ax			; zero out old value
	or	dx,cx			; combine old & new value
	mov	es:[bx],dx		; update the FAT
	xchg	ax,si			; AX = free space change (-1, 0 , 1)
	les	si,current_ddsc
	add	es:DDSC_FREE[si],ax	; update free space count
;	add	es:word ptr DDSC_BFREE[si],ax	; update free space count (32-bit)
;	adc	es:word ptr DDSC_BFREE+2[si],0
	les	si,bcb_root		; get buffer control block
	or	es:BCB_FLAGS[si],BF_DIRTY
					; mark the buffer as dirty
	cmp	split_fat,0		; is 12-bit entry split across sectors
	 je	fixfat80		; need some magic if so
					; handle a split FAT update
	mov	dx,fatrec		; lower sector number
	mov	ax,fatrec+2
;	inc	dx			; get the upper sector
	add	dx,1			; get the upper sector
	adc	ax,word ptr 0
	call	locate_fat		; find the buffer
	or	es:BCB_FLAGS[si],BF_DIRTY
					; mark buffer as write pending
	mov	al,fatbyth		; get the high byte
	mov	es:BCB_DATA[si],al	; store the high byte at the beginning
	mov	dx,fatrec		; get the previous sector
	mov	ax,fatrec+2
	call	locate_fat		; read into memory
	or	es:BCB_FLAGS[si],BF_DIRTY
					; mark buffer as write pending
	mov	bx,psecsiz
	dec	bx			; BX = sector size - 1
	mov	al,fatbytl		; get the low byte
	mov	es:BCB_DATA[si+bx],al

fixfat80:
	push	ds
	pop 	es			; ES back to local DS
	ret


; On Entry:
;	DX:AX = cluster number
; On Exit:
;	DX:AX preserved
;	ES:BX -> address of word
;	BCBSEG = segment of FAT FCB
;	ZF = 1 if word on even address
;	SPLIT_FAT = 0FFh if xing sector boundary
;	
;	CX = entries left in sector (if FAT16 - performance optimisation)
;

	Public	fatptr_tag
fatptr_tag:
	mov	tag_flg,1		; do not actually read FAT, just tag it
	jmp	fatptr05

	Public	fatptr
fatptr:
;------
	mov	tag_flg,0		; normal operation
fatptr05:
	push	dx			; save block number
	push	ax
;	mov	bx,ax
;	sub	dx,dx			; AX/DX = cluster #
	cmp	dosfat,FAT12		; is it 12 bit FAT?
	 je	fatptr09
	shl	ax,1			; * 2
	rcl	dx,1
	cmp	dosfat,FAT32		; is it 32 bit FAT?
	 jne	fatptr10		; no, then it must be FAT16
	shl	ax,1			; * 2 again, making it * 4 in total
	rcl	dx,1
	jmp	fatptr10
fatptr09:
	mov	bx,ax			; * 1.5
	shr	ax,1			; shift for 1 1/2 byte, else 2 byte
	add	ax,bx
	adc	dx,0
fatptr10:
;	add	ax,bx			; AX = offset into FAT
;	adc	dx,0			; AX/DX = 32 bit offset
	mov	cx,psecsiz		; CX = sector size
	push	cx
;	div	cx			; AX = sector offset
	push	dx
	push	ax
	xor	bx,bx
	push	bx
	push	cx
	sub	sp,8			; reserve space for result on stack
	call	div32
	pop	bx
	inc	sp
	inc	sp
	pop	ax
	pop	dx
	add	sp,8			; clean up the stack
	pop	cx
	dec	cx			; CX = sector size - 1
;	push	dx			; DX = offset within FAT sector
	push	bx			; BX = offset within FAT sector
	push	cx
	add	ax,fatadd		; make it absolute sector address
	adc	dx,0
	mov	fatrec,ax		; save FAT sector for FIXFAT
	mov	fatrec+2,dx
	xchg	ax,dx			; AX:DX = FAT sector
	test	tag_flg,1		; tag mode requested?
	 jz	fatptr15		; no, locate the sector normally
	call	tag_fat			; else tag the buffer if it exists
	jmp	fatptr16
fatptr15:
	call	locate_fat		; locate the sector
fatptr16:
	pop	cx			; CX = sector size - 1
	pop	bx			; restore offset within FAT sector
	pop	ax			; restore cluster #
	pop	dx
	sub	cx,bx			; CX = bytes left in sector - 1
	lea	bx,BCB_DATA[si+bx]	; ES:BX -> buffer data
;	cmp	dosfat,FAT16		; is it 16 bit media
;	 jne	fatptr20		; skip if 12 bit media
	cmp	dosfat,FAT12		; is it 16 bit media
	 je	fatptr20		; skip if 12 bit media
	shr	cx,1			; CX = extra entries left in sector
	cmp	ax,ax			; always set ZF = 1
	ret				; return ES:BX -> word in FAT

fatptr20:				; it's a 12 bit FAT, is it a split FAT?
	mov	split_fat,0		; assume no boundary crossing
	 jcxz	fatptr30		; end of sector, it's a split FAT
	test	al,1			; ZF = 1 if even cluster
	ret				; return ES:BX -> word in FAT buffer

fatptr30:				; block split across two sectors
	push	dx
	push	ax
	mov	split_fat,0FFh		; yes, the difficult case
	mov	al,es:[bx]		; get the low byte from 1st sector
	mov	fatbytl,al		; save it for later
	mov	dx,fatrec		; get the FAT record is
	mov	ax,fatrec+2
;	inc	dx			; get 2nd sector
	add	dx,1			; get 2nd sector
	adc	ax,word ptr 0
	test	tag_flg,1		; tag mode requested?
	 jz	fatptr35		; no, locate the sector normally
	call	tag_fat			; else tag the buffer if it exists
	jmp	fatptr36
fatptr35:
	call	locate_fat		; read the 2nd sector
fatptr36:
	sub	bx,bx
	lea	bx,BCB_DATA[si+bx]	; ES:BX -> buffer data
	mov	al,es:[bx]		; get 1st byte from next sector
	mov	fatbyth,al		; save the high byte
	push	ds			; ES = local DS
	pop	es
	mov	bx,offset fatbytl	; ES:BX -> <fatbytl,fatbyh>
	pop	ax
	pop	dx
	test	al,1			; set non-zero condition, odd word
	ret


;	entry:	AX:DX = sector number to read
;	exit:	ES:SI = BCB

tag_fat:
	xor	cx,cx			; do not read the buffer, just tag it
	jmp	locate_buffer

locate_fat:
;----------
;	mov	ah,0			; set sector address overflow = 0
;	mov	ax,0			; set sector address overflow = 0
	mov	cx,0ff00h+BF_ISFAT	; request a FAT buffer w/ preread
locate_buffer:
;-------------
; On Entry:
;	AX:DX = sector to locate
;	adrive = driver
;	CH = 0FFh if preread required
;	CL = buffer type, 0 means tag only
; On Exit:
;	ES:SI -> BCB_
;

;	mov	al,adrive		; get our drive number
	mov	bl,adrive		; get our drive number
	les	si,bcb_root		; get it from the right buffer list
locate10:
	cmp	dx,es:BCB_REC[si]	; does our sector address match?
	 jne	locate20		; skip if it doesn't
;	cmp	ah,es:byte ptr BCB_REC2[si]	; does record address overflow match?
	cmp	ax,es:BCB_REC2[si]	; does record address overflow match?
	 jne	locate20		; skip if not
;	cmp	al,es:BCB_DRV[si]	; does the drive match?
	cmp	bl,es:BCB_DRV[si]	; does the drive match?
	 je	locate30		; found if it all matches
locate20:				; MRU buffer doesn't match
	mov	si,es:BCB_NEXT[si]	; try the next
	cmp	si,word ptr bcb_root	; while there are more buffers
	 jne	locate10

	test	cl,cl			; shall we only tag an existing buffer?
	 je	locate50		; yes, then do not sacrifice this one

	; find cheap buffer to recycle
	mov	si,es:BCB_PREV[si]	; start with LRU
	mov	di,si
locate23:
	cmp	es:BCB_DRV[si],0ffh	; discarded buffer?
	 je	locate25		; happily use discarded
	mov	si,es:BCB_PREV[si]
	cmp	si,di			; back at LRU?
	jne	locate23		; if not inspect previous buffer

locate25:
	push	ax
	push 	cx
	push 	dx			; save all registers
	call	flush_buffer		; write buffer to disk
	pop	dx
	pop 	cx
	pop 	ax			; restore all registers

;	mov	es:BCB_DRV[si],al	; fill in the BCB: drive
	mov	es:BCB_DRV[si],bl	; fill in the BCB: drive
	mov	es:BCB_REC[si],dx	; 		  record low
;	mov	es:byte ptr BCB_REC2[si],ah	; 		  record high
	mov	es:BCB_REC2[si],ax	; 		  record high
	mov	es:BCB_FLAGS[si],cl	; mark as clean, ISFAT,ISDIR or ISDAT
	test	ch,ch			; is preread required?
	 jz	locate30		; skip if it isn't
	call	fill_buffer		; read it from disk
locate30:
	cmp	si,word ptr bcb_root	; are we already at the head ?
	 jne	locate40		;  if not move ourself there
	ret
locate40:
	mov	bx,es:BCB_NEXT[si]	; BX = next buffer
	mov	di,es:BCB_PREV[si]	; DI = previous buffer
	mov	es:BCB_NEXT[di],bx	; unlink buffer from the
	mov	es:BCB_PREV[bx],di	;  chain
	mov	bx,si
	xchg	bx,word ptr bcb_root	; become the new head, BX = old head
	mov	es:BCB_NEXT[si],bx	; old chain follow us
	mov	di,si
	xchg	di,es:BCB_PREV[bx]	; back link to our buffer, DI = LRU buffer
	mov	es:BCB_PREV[si],di	; link ourselves to LRU buffer
	mov	es:BCB_NEXT[di],si	; forward link to our buffer
locate50:
	ret


;	Flush all dirty FAT buffers for drive AL
;	entry:	AL = drive to flush (0-15)
;	exit:	CY = 0 if no error
;		ax,bx,cx,dx,es preserved

flush_fat:
;---------
;	entry:	AL = drive for FAT flush

	mov	ah,BF_ISFAT		; flush all dirty FAT buffers
	jmp	flush_drive		; shared code for all flushes

;----------
update_dir:
;----------
	call	flush_dirbuf		; flush local dirbuf to buffers
;---------
flush_dir:
;---------
	mov	ah,BF_ISDIR		; write out dirty directories
	jmp	flush_adrive		; update the disk


;----------
update_dat:
;----------
	mov	ah,BF_ISDAT		; write out dirty data
	jmp	flush_adrive		; update the disk

;----------
update_fat:		;write out modified FAT buffers
;----------
	push	es
	push	bx
	les	bx,current_ddsc
	cmp	es:DDSC_FSINFO[bx],0ffffh;FS info sector present?
	 je	update_fat10		; no, then do not to write it, either
	call	write_fsinfo		; update fs info block if applicable
update_fat10:
	pop	bx
	pop	es
	mov	ah,BF_ISFAT		; flush all dirty FAT buffers
;	jmp	flush_adrive		; update the disk if dirty

flush_adrive:
;------------
	mov	al,adrive		; AL = currently selected drive
;	jmp	flush_drive

;	Write out all dirty data buffers for a given drive
;	entry:	AL = drive to be flushed
;		AH = mask of buffer types to be flushed
;	exit:	AX,DX preserved
;	Note:	sector buffers will be written in the
;		sequence in which they appear on disk (low to high)

flush_drive:
;-----------
	push	es
	push	si
flush_drive10:
	les	si,bcb_root		; start with the first buffer
	mov	bx,0FFFFh		; assume no buffer found
flush_drive20:
	test	es:BCB_FLAGS[si],BF_DIRTY
					; has buffer been written to?
	 jz	flush_drive40		; no, do the next one
	test	es:BCB_FLAGS[si],ah	; is it one of these buffers?
	 jz	flush_drive40		; no, do the next one
	cmp	al,es:BCB_DRV[si]	; does the drive match?
	 jne	flush_drive40		; skip if wrong drive
					; we've found a buffer to flush
	cmp	bx,0FFFFh		; first buffer ever found in list?
	 jz	flush_drive30		; yes, save as new best candidate
					; else check if < previous lowest addr
	mov	dx,es:BCB_REC[si]
	sub	dx,ds:BCB_REC[bx]
;	mov	dl,es:byte ptr BCB_REC2[si]	; compare the disk addresss
;	sbb	dl,ds:byte ptr BCB_REC2[bx]
	mov	dx,es:BCB_REC2[si]	; compare the disk addresss
	sbb	dx,ds:BCB_REC2[bx]
	 jnb	flush_drive40		; CY = 0 if new BCB higher
flush_drive30:				; else ES = best BCB so far
	mov	bx,si			; save it for later
flush_drive40:
	mov	si,es:BCB_NEXT[si]	; get next buffer address
	cmp	si,ss:word ptr bcb_root
	 jne	flush_drive20
	cmp	bx,0FFFFh		; did we find a dirty buffer?
	 jz	flush_drive50		; no, all buffers cleaned
	mov	si,bx			; ES:SI -> BCB to flush
	call	flush_buffer		; write sector to disk
	jmp	flush_drive10		; check if more dirty buffers
flush_drive50:
	pop	si
	pop	es
	ret

flush_buffer:
;------------
;	entry:	ES:SI = address of BCB
;	exit:	buffer flushed if BCB_FLAGS & BF_DIRTY

;	note:	preserves AX,BX,CX,DX,ES

	test	es:BCB_FLAGS[si],BF_DIRTY
					; is the buffer dirty?
	 jz	flush_buf9		; skip update if not modified
flush_buf1:
	push 	es
	push 	si
	push 	ax
	push 	bx			; else save all registers
	push 	cx
	push 	dx
	mov	al,es:BCB_DRV[si]	; get the buffer drive
	cmp	al,adrive		; same as the selected drive?
	 je	flush_buf2		; skip if already selected
	push	es			; save the BCB
	push	si
	push	ds
	pop 	es			; ES = SYSDAT
	call	select_adrive		; select drive AL, ZF = 1 if logged in
	pop	si
	pop	es			; recover BCB
	 jc	flush_buf5		; don't flush to bad drive
	test	es:BCB_FLAGS[si],BF_DIRTY ; re-test dirty after select_adrive
	jz	flush_buf5		  ; (we may be called recursively)
flush_buf2:
	mov	cx,nfats		; else FAT sectors written CX times
	mov	al,00000011b		; mark as FAT write
	test	es:BCB_FLAGS[si],BF_ISFAT
	 jnz	flush_buf3		; go ahead
	mov	cx,1			; directory/data written once only
	mov	al,00000101b		; mark as directory write
	test	es:BCB_FLAGS[si],BF_ISDIR
	 jnz	flush_buf3		; if not dir, must be data
	mov	al,00000111b		; mark as data buffer write
flush_buf3:				; CX = # of times to write sector
	mov	rwmode,al
	sub	ax,ax			; offset for write = 0
	sub	dx,dx
flush_buf4:				; loop back to here for other copies
	push	dx
	push	ax
	push	cx			; save loop variables
	call	setup_rwx		; compute disk address
	call	write_buff		; write the sector
	pop	cx
	pop	ax
	pop	dx
	add	ax,nfatrecs		; move to next FAT copy
	adc	dx,nfatrecs+2
	loop	flush_buf4		; repeat for all FAT copies
flush_buf5:
	and	es:BCB_FLAGS[si],not BF_DIRTY
					; mark it as no longer dirty
	mov	al,physical_drv		; work drive for BDOS function
	cmp	al,adrive		; drive from last IO_SELDSK
	 je	flush_buf6		; skip if flush to work drive
					; else reselect BDOS drive after flush
	push	ds
	pop 	es			; ES = SYSDAT
	call	select_adrive		; reselect the work drive
flush_buf6:
	pop 	dx
	pop 	cx			; restore all registers
	pop 	bx
	pop 	ax
	pop 	si
	pop 	es
flush_buf9:				; all done, CY = 0 if O.K.
	ret


;-------
zeroblk:				; DX:AX = blk
;-------
	xor	bx,bx			; Start at begining of cluster
	xor	cx,cx
	call	clus2sec		; translate to sector address
	xchg	ax,dx			; AX:DX = 32 bit sector address
;	mov	ah,al			; AH:DX = 24 bit sector address
	mov	cx,secperclu		; CX == sectors/cluster
zeroblk10:				; repeat for all sectors in cluster
	push	ax
	push	cx
	push	dx
	mov	cx,BF_ISDIR		; locate directory sector w/o preread
	call	locate_buffer		; this will find the cheapest buffer
	or	es:BCB_FLAGS[si],BF_DIRTY
	lea	di,BCB_DATA[si]		; ES:DI -> disk buffer
	mov	cx,psecsiz		; CX = byte count for REP STOSB
	shr	cx, 1
	xor	ax,ax
	rep	stosw			; zero the whole data buffer
	pop	dx
	pop	cx
	pop	ax
	add	dx,1			; onto the next block
;	adc	ah,0
	adc	ax,0
	loop	zeroblk10		; repeat for all sectors in cluster
	jmp	flush_dir




fill_buffer:
;-----------
; On Entry:
;	ES:SI = address of BCB to be filled
; On Exit:
;	ES:SI preserved
;	data read into buffer
;
	test	es:BCB_FLAGS[si],BF_ISFAT
					; are we reading a FAT sector?
	 jz	fill_buf1		; skip if directory/data
;	mov	al,es:BCB_DRV[si]	; get the drive
;	call	flush_fat		; write out all dirty buffers
	call	flush_buffer		; write out buffer if dirty
	mov	al,00000010b		; reading from FAT area
	jmp	fill_buf3		; go ahead
fill_buf1:
	mov	al,00000100b		; else mark as directory
	test	es:BCB_FLAGS[si],BF_ISDIR; test if directory read
	jnz	fill_buf3		; go ahead
fill_buf2:				; neither FAT nor directory => data
	mov	al,00000110b		; mark read as data buffer read
fill_buf3:
	mov	rwmode,al
	push	cx
	xor	cx,cx
	cmp	al,00000010b
	 jne	fill_buf4
	mov	cx,nfats
	dec	cx
fill_buf4:
	mov	es:BCB_DRV[si],0FFh	; discard in case of error
	sub	ax,ax			; no offset for 2nd copy yet
	sub	dx,dx
fill_buf5:
	push	dx
	push	ax
	call	setup_rwx		; compute disk address
	call	read_buff		; read the sector
	pop	ax
	pop	dx
	 jns	fill_buf6
; we can end here only if CX was non-zero above and we failed to read a
; FAT copy while there is still another one we could use
	add	ax,nfatrecs
	adc	dx,nfatrecs+2
	dec	cx
	jmp	fill_buf5
fill_buf6:
	pop	cx
	mov	al,adrive		; restore the drive
	mov	es:BCB_DRV[si],al	; set the drive #
	ret

read_buff:
;---------
	push	es
	push	si			; save BCB_
	push	cur_dma_seg
	push	cur_dma			; save DMA address
	push	cx
	mov	cx,ss:deblock_seg
	 jcxz	read_buff10
	mov	cur_dma_seg,cx
	mov	cur_dma,0		; xfer via deblocking buffer
read_buff10:
	pop	cx
	call	read_block
	pop	cur_dma			; restore DMA address
	pop	cur_dma_seg
	 js	read_buff20		; can happen only on FAT read
	mov	cx,ss:deblock_seg	; if deblocked, copy data
	 jcxz	read_buff20
	les	di,dword ptr cur_dma	; point to destination
	mov	cx,psecsiz		; CX = sector size
	shr	cx,1			; CX = words per sector
	push	ds
	mov	ds,ss:deblock_seg
	xor	si,si			; DS:SI = source
	rep	movsw			; copy the data
	pop	ds
read_buff20:				; SF still indicating error here
	pop	si			; recover BCB_
	pop	es
	ret

write_buff:
;----------
	push	es
	push	si
	push	cur_dma_seg
	push	cur_dma
	mov	cx,ss:deblock_seg	; if deblocking we have to
	 jcxz	write_buff10		;  copy the data first
	push	ds			; save SYSDAT
	les	si,dword ptr cur_dma	; ES:SI -> source
	push	es			; save source seg 
	mov	es,cx
	xor	di,di			; ES:DI -> deblocking buffer
	mov	cur_dma_seg,es
	mov	cur_dma,di		; do xfer via deblocking buffer
	mov	cx,psecsiz		; CX = sector size
	shr	cx,1			; CX = words per sector
	pop	ds			; DS:SI -> source
	rep	movsw			; copy to deblocking buffer
	pop	ds			; restore SYSDAT
write_buff10:
	call	write_block
	pop	cur_dma
	pop	cur_dma_seg
	pop	si
	pop	es
	ret

setup_rwx:
;---------
;	entry:	DX:AX = sector offset (multiple FAT writes)
;		ES:SI = BCB, BCB_REC filled in
;	exit:	all values set up for RWXIOSIF

	mov	cur_dma_seg,es		; segment = BCB_SEGMENT
	push	dx
	lea	dx,BCB_DATA[si]
	mov	cur_dma,dx		; offset
	pop	dx
;	xor	dx,dx
	add	ax,es:BCB_REC[si]
;	adc	dl,es:byte ptr BCB_REC2[si]
	adc	dx,es:BCB_REC2[si]
	mov	word ptr pblock,ax	; xfer starts at this block
	mov	word ptr pblock+WORD,dx
	mov	mult_sec,1		; single sector transfer
	ret

read_fsinfo:
	cmp	dosfat,FAT32		; is this a FAT32 partition?
	 jne	read_fsinfo10		; no, then there is no fs info block
read_fsinfo05:
	push	es
	push	ds
	mov	dx,es:DDSC_FSINFO[bx]	; sector number of FS info block
	xor	ax,ax
	mov	cx,0FF00h+BF_ISDAT	; data buffer with preread
	push	es
	push	bx
	call	locate_buffer		; read FS info block
	pop	bx
	pop	ds
	mov	ax,es:word ptr BCB_DATA+FS_BFREE[si]	; free cluster count in FS info block
	mov	dx,es:word ptr BCB_DATA+FS_BFREE+2[si]
	mov	ds:word ptr DDSC_BFREE[bx],ax	; use this as new free cluster count
	mov	ds:word ptr DDSC_BFREE+2[bx],dx
	mov	ax,es:word ptr BCB_DATA+FS_BBLOCK[si]	; next free block in FS info block
	mov	dx,es:word ptr BCB_DATA+FS_BBLOCK+2[si]

	; TODO: why is DDSC_BBLOCK not actually set here? (Boeckmann)

	pop	ds
	pop	es
read_fsinfo10:
	ret

write_fsinfo:
	cmp	dosfat,FAT32		; is this a FAT32 partition?
	 jne	write_fsinfo10		; no, then there is no fs info block
	push	es
	push	ds
	mov	dx,es:DDSC_FSINFO[bx]	; sector number of FS info block
	xor	ax,ax
	mov	cx,0FF00h+BF_ISDAT	; data buffer with preread
	push	es
	push	bx
	call	locate_buffer		; read FS info block
	pop	bx
	pop	ds
	mov	ax,ds:word ptr DDSC_BFREE[bx]	; update buffer
	mov	dx,ds:word ptr DDSC_BFREE+2[bx]
	mov	es:word ptr BCB_DATA+FS_BFREE[si],ax
	mov	es:word ptr BCB_DATA+FS_BFREE+2[si],dx
	mov	ax,ds:word ptr DDSC_BBLOCK[bx]
	mov	dx,ds:word ptr DDSC_BBLOCK+2[bx]
	mov	es:word ptr BCB_DATA+FS_BBLOCK[si],ax
	mov	es:word ptr BCB_DATA+FS_BBLOCK+2[si],dx
	or	es:BCB_FLAGS[si],BF_DIRTY	; mark buffer as modified
	pop	ds
	call	flush_buffer		; and write it back to disk
	pop	es
write_fsinfo10:
	ret

BDOS_CODE	ends

	END
