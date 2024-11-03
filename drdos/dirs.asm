title 'DIRS - dos directory support'
;    File              : $DIRS.ASM$
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
;    DIRS.A86 1.13 94/12/01 13:16:24
;    changed error code if directory entry cannot be allocated;    
;    DIRS.A86 1.12 93/08/27 18:49:04
;    hash code fixup on previously unused entries resets hash count
;    pcformat bug where an extra (zero-length) command.com was left on disk
;    ENDLOG
;
;	Date	   Who	Modification
;	---------  ---	---------------------------------------
;   19 Aug 91 Initial version created for VLADIVAR

PCMCODE	GROUP	BDOS_CODE
PCMDATA	GROUP	BDOS_DATA,PCMODE_DATA,FIXED_DOS_DATA

ASSUME DS:PCMDATA

.nolist
include	bdos.equ
include mserror.equ
include	fdos.equ
.list


PCMODE_DATA	segment public word 'DATA'
PCMODE_DATA	ends

FIXED_DOS_DATA	segment public word 'DATA'
ifdef DELWATCH
	extrn	fdos_stub:dword		; for calling delwatch TSR
endif
FIXED_DOS_DATA	ends

BDOS_DATA	segment public word 'DATA'
	extrn	adrive:byte
	EXTRN	clsize:WORD
	extrn	diradd:word
	extrn	dirinroot:word
	EXTRN	dirperclu:WORD
	EXTRN	dosfat:WORD
	extrn	hashroot:dword
	extrn	hashmax:word
	EXTRN	info_fcb:BYTE
	extrn 	lastcl:word
	extrn 	blastcl:word
	extrn	psecsiz:word
	extrn	fsroot:dword


hash		dw	2 dup (0)	; hash code work area

; The dirbcb says what is in the local dirbuf

dirbcb		db	0ffh		; drive of dirbuf entry
dirbcb_cl	dw	0,0		; cluster of dirbuf entry
dirbcb_dcnt	dw	0		; directory index of dirbuf entry
dirbcb_block	dw	2 dup (0)	; block of dirbuf entry
dirbcb_offset	dw	0		; byte offset in block of dirbuf entry


	public	dirbuf
dirbuf		db	32 dup (0)	; local directory buffer

	public	dirp
dirp		dw	0		; directory entry pointer

	public	dcnt
dcnt	dw	0			; directory index count

	public	finddfcb_mask
finddfcb_mask	dw	0800h		; hi byte = reject DA_VOLUME attribs
					; lo byte = accept non-0 start clusters
					; 00FF = include labels, but not
					;	pending deletes
					; 0000 = include everything
	public	chdblk
chdblk		dw	0,0		; current cluster # of directory

rd_pcdir_cl	dw	0,0		; current cluster in rd_pcdir
rd_pcdir_rel	dw	0		; relative cluster in chain
rd_pcdir_last	dw	0		; last relative position
find_hcb_cl	dw	0,0		; current cluster in find_hcb
BDOS_DATA	ends

BDOS_CODE segment public byte 'CODE'
	extrn	alloc_cluster:NEAR
	extrn	clus2sec:near
	extrn	hdsblk:near		; get current directory block
	extrn	fdos_error:NEAR
	extrn	fixfat:NEAR
	extrn	getnblk:NEAR
	extrn	locate_buffer:near
	extrn	update_dir:NEAR
	extrn	update_fat:NEAR
	extrn	zeroblk:near
	extrn	div32:near
	extrn	output_msg:near
	extrn	output_hex:near

	public	allocdir
	public	discard_dirbuf
	public	finddfcb
	public	finddfcbf
	public	fill_dirbuf
	public	flush_dirbuf
	public	getdir
	public	hshdscrd
	public	mkhsh
	public	setenddir
	public	rd_pcdir


fill_dirbuf:	;get 32 byte directory entry
;----------
; On Entry:
;	DX:AX = cluster to read (0=root)
;	BX = dir within cluster
; On Exit:
;	DI -> dirbuf entry

	call	discard_dirbuf		; invalidate block in case of error
	mov	dirbcb_cl,ax		; remember which cluster
	mov	dirbcb_cl+2,dx
	mov	dirbcb_dcnt,bx		;  and dir entry we want
	test	ax,ax			; are we in the root ?
;	 jz	fill_dirbuf10
	 jnz	fill_dirbuf05
	test	dx,dx
	 jnz	fill_dirbuf05
	cmp	dirinroot,0		; is this a FAT32 file system?
	 jne	fill_dirbuf10		; no, proceed with FAT16/12 routine
	mov	ax,word ptr fsroot	; low word of root dir cluster
	mov	dx,word ptr fsroot+2
fill_dirbuf05:
;	mov	cl,FCBSHF
;	shl	bx,cl			; BX = byte offset in cluster
	mov	cx,FCBSHF
	push	ax
	xor	ax,ax
fill_dirbuf07:
	shl	bx,1			; BX = byte offset in cluster
	rcl	ax,1
	loop	fill_dirbuf07
	mov	cx,ax
	pop	ax
	call	clus2sec		; DX:AX -> sector
	jmp	fill_dirbuf20		; BX = offset in sector
fill_dirbuf10:
	mov	ax,FCBLEN
	mul	bx			; DX:AX = byte offset
	div	psecsiz			; AX = sector offset, DX = byte offset
	mov	bx,dx			; BX = byte offset in sector
	xor	dx,dx
	add	ax,diradd		; add in start of root dir
	adc	dx,dx
fill_dirbuf20:
	mov	dirbcb_block,ax		; we want this sector
	mov	dirbcb_block+WORD,dx
	mov	dirbcb_offset,bx
	xchg	ax,dx			; DX = low word of sector, AX = high word
;	mov	ah,al			; AH = low byte of high word
	push	bx			; save byte offset in sector
	mov	cx,0FF00h+BF_ISDIR	; locate directory sector
	call	locate_buffer		; ES:SI -> BCB_
	pop	bx			; BX = offset within sector
	push 	es
	pop 	ds			; DS:SI -> buffer control block
	lea	si,BCB_DATA[si+bx]	; DS:SI -> data in buffer
	push 	ss
	pop 	es
	mov	di,offset dirbuf	; ES:DI -> dir buffer
	push	di
	mov	cx,32/WORD		; copy into local buffer
	rep	movsw
	pop	di			; DI -> dir buffer
	push 	ss
	pop 	ds
	mov	al,adrive		; remember where we are
	mov	dirbcb,al		;  so we can write it back
	ret


;------------
flush_dirbuf:
;------------
	mov	al,0FFh
	xchg	al,dirbcb		; do we have anything to flush ?
	cmp	al,adrive
	 jne	flush_dir20		; skip if invalid contents
	mov	si,offset dirbcb_block
	lodsw				; get low word of block
	xchg	ax,dx			; put it in DX where it belongs
	lodsw				; get high word of block
;	mov	ah,al			; AH:DX -> block to find
	mov	cx,0FF00h+BF_ISDIR	; look for directory
	call	locate_buffer		; locate physical sector
	or	es:BCB_FLAGS[si],BF_DIRTY; mark this buffer as modified
	mov	bx,dirbcb_offset	; BX = offset within buffer
	lea	di,BCB_DATA[si+bx]	; ES:DI -> offset in buffer

	mov	al,es:[di]		; AL = 1st character of dir entry

	mov	si,offset dirbuf	; get CP/M buffer address
	mov	cx,32/WORD
	rep	movsw			; copy modified entry back

	push	ax
;	xor	dh,dh			; we only want HCB_ if it's there
;	mov	cx,dirbcb_cl		;  and it's this cluster
	xor	ch,ch			; we only want HCB_ if it's there
	mov	ax,dirbcb_cl		;  and it's this cluster
	mov	dx,dirbcb_cl+2
	call	find_hcb		; does an HCB_ exist for this entry ?
	pop	ax
	 jc	flush_dir20		; no, skip update
	mov	di,dirbcb_dcnt		; we want this dir entry
	cmp	di,es:HCB_CNT[bx]	; is this within the hashed entries ?
	 jae	flush_dir20		;  no, skip the fixup

	test	al,al			; are we using a never used entry ?
	 jnz	flush_dir10		; if so don't trust subsequent hash
	inc	di			;  codes as they have never been read.
	mov	es:HCB_CNT[bx],di	; Truncate table to force a read of the
	dec	di			;  next dir entry (which will normally
flush_dir10:				;  also be never used)
	shl	di,1			; DI = offset of hashed entry
	lea	di,HCB_DATA[bx+di]
	mov	si,offset dirbuf	; this is the dir entry
	call	mkhsh			; AX = hash code of our entry
	stosw				; update hash code for dir entry
flush_dir20:
	push	ds
	pop 	es			; ES = local data segment
	ret

;--------------
discard_dirbuf:
;--------------
	mov	dirbcb,0FFh		; invalidate dirbuf
	ret


;--------
rd_pcdir:
;--------
;	Exit:	AX = offset of directory entry
;		   = 0 if end of directory


	mov	bx,dcnt
	inc	bx
	mov	dcnt,bx		; dcnt=dcnt+1
	call	hdsblk		; AX = current directory block
;	 jz	rd_pcdir40	; skip if we're at the root
	 jnz	rd_pcdir05	; not in root dir
	cmp	dirinroot,0	; is this a FAT32 file system?
	 je	rd_pcdir04
	 jmp	rd_pcdir40	; no, skip to normal root dir routine
rd_pcdir04:
	mov	ax,word ptr fsroot	; else treat it as a normal sub directory
	mov	dx,word ptr fsroot+2
rd_pcdir05:
; we we in a subdirectory - lets follow the chain

	mov	rd_pcdir_cl,ax	; save cluster number for later use
	mov	rd_pcdir_cl+2,dx
	xchg	ax,cx		; keep subdir cluster in CX
	mov	ax,FCBLEN	; AX = size of dir entry
	mul	bx		; DX:AX = offset of set entry we want
;	div	clsize		; AX = # clusters to skip, DX = offset in cluster
	push	cx
	push	dx
	push	ax
	push	word ptr clsize+2
	push	word ptr clsize
	sub	sp,8
	call	div32
	pop	dx
	inc	sp
	inc	sp
	pop	ax
	add	sp,10
	pop	cx
	xchg	ax,dx		; DX = # to skip, AX = offset in cluster
	mov	di,dx
	mov	rd_pcdir_rel,di	; remember cluster offset
	xchg	ax,cx		; AX = start of chain, CX = offset in cluster
	mov	ax,rd_pcdir_cl
	mov	dx,rd_pcdir_cl+2
	xchg	bx,cx		; BX = offset in cluster, CX = dcnt
	 jcxz	rd_pcdir20	; 1st subdir entry, we are already there
;	mov	cx,chdblk	; do we already know where we are ?
;	 jcxz	rd_pcdir10	;  if not trace from start of chain
	cmp	chdblk,0	; do we already know where we are ?
	 jnz	rd_pcdir09
	cmp	chdblk+2,0
	 jz	rd_pcdir10	;  if not trace from start of chain
rd_pcdir09:
	cmp	di,rd_pcdir_last; trying to read cluster before last one?
	 jb	rd_pcdir10	; yes, begin at start of chain
;	xchg	ax,cx		; AX = cluster of last dir entry
	mov	ax,chdblk
	mov	dx,chdblk+2
	test	bx,bx		; have we moved onto next cluster?
	 jnz	rd_pcdir20	; no, trust me..
	cmp	di,rd_pcdir_last; have we moved onto next cluster?
	 je	rd_pcdir20	; no, trust me..
;	mov	dx,1		; move on to next entry in the chain
	mov	di,1		; move on to next entry in the chain
rd_pcdir10:
;	or	dx,dx		; skip along chain until we arrive
	or	di,di		; skip along chain until we arrive
	 jz	rd_pcdir20	;  at the destination cluster
;	dec	dx
	dec	di
	push	bx
;	push	dx
	push	di
	call	getnblk		; AX = next cluster in chain
;	pop	dx
	pop	di
	pop	bx
;	cmp	ax,lastcl	; have we fallen off the end of the chain ?
	cmp	dx,blastcl+2	; have we fallen off the end of the chain ?
	 jb	rd_pcdir10
	 ja	rd_pcdir30
	cmp	ax,blastcl
	 jbe	rd_pcdir10
	jmp	rd_pcdir30	; yes, set end of directory
rd_pcdir20:
	mov	chdblk,ax	; remember this cluster for next time
	mov	chdblk+2,dx
	mov	cx,rd_pcdir_rel	; save relative position in chain
	mov	rd_pcdir_last,cx
	mov	cl,FCBSHF	; to divide by fcb size
	shr	bx,cl		; BX = dir offset in cluster
	jmp	rd_pcdir50	;  now go and find the entry


rd_pcdir30:
	call	setenddir	; yes, set dcnt to end of directory
	jmp	rd_pcdir60

rd_pcdir40:
; we are in the root directory
	cmp	bx,dirinroot	; end of the root directory ?
	 jae	rd_pcdir30
rd_pcdir50:
	call	fill_dirbuf	;locate directory entry
	xchg	ax,di		; AX -> dir entry
	cmp	dcnt,ENDDIR
	 jnz	rd_pcdir70
rd_pcdir60:
	xor	ax,ax		; return 0 if endofdir
rd_pcdir70:
	mov	bx,ax
	ret


;---------
setenddir:	;set dcnt to the end of directory (dcnt = 0ffffh)
;---------
	mov	dcnt,ENDDIR
	mov	chdblk,0
	mov	chdblk+2,0
	ret


chk_wild:	;check fcb for ? marks
;--------
; On Entry:
;	bx -> FCB
; On Exit:
;	ZF set if ? found
;	BX preserved
	push	ds
	pop 	es			; ES -> SYSDAT
	lea	di,byte ptr FNAME[bx]	; ES:DI -> name to scan
	mov	cx,11
	mov	al,'?'			; scan for wild cards
	repne	scasb
	ret

;---------
finddfcbf:	; Find matching directory fcb(dfcb) from beginning of directory
;---------
	call	setenddir	; set up for search first

;--------
finddfcb:	; Find matching directory fcb(dfcb)
;--------
	mov	cx,2

;------
getdir:
;------
;	entry:	CH  =	offset info_fcb	(always 0 except from rename)
;		CL  = 	search length
;			0 = return next fcb
;			1 = return empty fcb
;			2 = find match  (Based on info_fcb)
;			3 = find match?  Based on info_fcb
;
;	exit:	AX,BX,DIRP = pointer to dfcb
;			     0 = no match (end of directory)
;			     other = offset of requested directory entry
;		ZF = zero flag is set based on AX
;

;	Note:	The most common call for this function is with CX =
;		2 (match with name, not extent)  with 'dcnt' set to
;		0FFFFh  (search  from  beginning  of the  directory
;		(e.g.   open,  create,   delate,   rename,   etc.).
;		Therefore  we try  to optimize  directory  searches
;		using a dynamic hash table...

					;struct dirfcb *getdir(offset,srchl);

	cmp	dcnt,0FFFFh		;if ((dcnt == 0xffff) &&
;	 jne	gtd_next
	 je	gtdo10
	 jmp	gtd_next
gtdo10:
	mov	hash+2,cx		; Save off calling option
	xor	ax,ax			; hash code 0 for free entry
	cmp	cx,1			; what kind of search?
	 je	gtdo15			; CL=1: find free entry (AX=0)
;	 jb	gtd_next		; CL=0: find any entry (unhashed)
	 jae	gtdo12
	jmp	gtd_next		; CL=0: find any entry (unhashed)
gtdo12:
	or	ch,ch			; name in INFO_FCB+1?
	 jnz	gtd_next		; no, unhashed search
	mov	bx,offset info_fcb
	call	chk_wild		; wildcards used in search?
	 jz	unhshd1			; yes, can't use hashing
	mov	si,offset info_fcb+1	; else compute hash code
	call	mkhsh			;    for name to find
gtdo15:
	mov	hash,ax			; save it for search
	call	hdsblk			; get directory block
	test	ax,ax			; is this the root dir?
	 jne	gtdo3			; no
	test	dx,dx
	 jne	gtdo3
	cmp	dosfat,FAT32		; if yes, is this a FAT32 file system?
	 jne	gtdo3			; no, then skip
	mov	ax,word ptr fsroot	; else use the real root cluster number instead
	mov	dx,word ptr fsroot+2
gtdo3:
	push	dx			; save dir block for later
	push	ax
	call	hashsrch		; try and use hashing to find a match
	 jnc	gtdo4			; look closer if we get possible match
	add	dcnt,ax			;  else skip known non-matches
	pop	ax			; recover current dir block
	pop	dx
	test	ax,ax			; if we are in the root
	 jnz	gtdo31
	test	dx,dx
	 jz	unhashed		;  we must search the hard way
gtdo31:
;	xchg	ax,bx
	push	dx
	push	ax
	mov	ax,dcnt			; should we go onto next cluster ?
	inc	ax			; only if next entry is the start
	xor	dx,dx			;  of a cluster
	div	dirperclu
;	xchg	ax,bx
	test	dx,dx			; at start of cluster ?
	pop	ax
	pop	dx
	 jnz	unhashed
	call	getnblk			; onto next cluster until we are
;	cmp	ax,lastcl		;  at the end of the chain
	cmp	dx,blastcl+2		;  at the end of the chain
	 jb	gtdo3
	 ja	unhashed
	cmp	ax,blastcl
	 jbe	gtdo3
	jmp	unhashed		; out of luck
gtdo4:
	add	dcnt,ax			; we have found a match, so start
	pop	ax			;  search here
	pop	dx
;	jmp	unhashed
unhashed:				;   /* locate entry */
	mov	chdblk,0
	mov	chdblk+2,0
unhshd1:
	mov	cx,hash+2		;}
gtd_next:
;--------
	push	cx
	call	rd_pcdir		; Get Next DFCB
	pop	cx
gtd_exit:
	mov	dirp,ax			; assume this is the one
	mov	bx,ax
	or	ax,ax			; should we exit with not found ?
	 jz	gtd2
	cmp	cl,NEXT			; Caller wishes next dfcb?
	 jne	gtd3			; NO
gtd2:
	mov	ax,bx			; return BX (DIRP or NULLPTR)
	or	ax,ax			; return ZF (1 = not found)
	ret

gtd3:
	cmp	cl,EMPTY		; Caller wishes an empty dfcb?
	 jne	gtd4			; NO
	mov	al,DNAME[bx]		; Get directory type
	or	al,al			; Is it free?
	 jz	gtd2			; YES		(00 -> never used)
	cmp	al,0E5h			; Is the dfcb empty?
	 je	gtd2			; YES		 (E5 -> erased)
	jmp	gtd_next		; NO, try the next

gtd4:					; looking for particular entry
	call	hdsblk			; Are we at the root?
	 jnz	gtd5			; skip if not
	cmp	dirinroot,0		; is this FAT32?
	 jz	gtd5			; yes, proceed normally
	mov	ax,dcnt			; check for end of directory
	cmp	ax,dirinroot		; have we reached end of root?
	mov	ax,0			; assume we have
	 jae	gtd_exit		; exit if we have
gtd5:
	mov	al,DNAME[bx]		; Get dfcb type
	cbw
	or	ax,ax			; Are we at End Of Directory(EOD)
	 jz	gtd_exit		; YES
	cmp	al,0E5h			; Is this a free fcb?
	 je	gtd_next		; Yes, try again
	mov	ax,finddfcb_mask	; do we want labels/pending deletes
	test	DATTS[bx],ah		; filter out volume labels?
	 jnz	gtd_next		;  we normally reject them
ifdef DELWATCH
	cbw				; we want labels - do we want
	test	word ptr DBLOCK1[bx],ax	;  DELWATCH pending deletes
	 jnz	gtd_next		;  ie. labels with fat chain
endif
	push	cx			; we are interested - but does
	mov	al,ch			;  the name match ?
	cbw
	add	ax,offset info_fcb+1
	xor	si,si			; we want SI = entry to match and
	xchg	ax,si			;   AL = 0 indicating assumed match
	mov	cx,11			; 11 chars in filename
	mov	di,bx			; ES:DI -> directory entry
match3:
	 jcxz	match4			; stop if we have done all 11
	repe	cmpsb			; compare if 11 bytes the same
	 je	match4			;  skip if all bytes the same
	cmp	byte ptr [si-1],'?'	; else was INFO_FCB byte = '?'
	 je	match3			;  in that case it matches too
	inc	ax			; else we didn't match (AL<>0)
match4:
	pop	cx
	or	al,al			; did we match ?
;	 jnz	gtd_next		; no, try for another
	 jz	match5
	 jmp	gtd_next		; no, try for another
match5:
	mov	bx,dirp			; Return (BX)
	jmp	gtd2



find_hcb:				; find HCB_ for given drive
;--------
; On Entry:
;	DX:AX = cluster we are looking for
;	CH = 00 if exact match required
;	     FF if we want to recyle oldest HCB_
; On Exit:
;	CY set, AX=0 if HCB_ not found
;	CY clear ES:BX = offset of HCB_ (moved to head of list)
;	(AX/CX trashed, All other regs preserved)
;

	mov	find_hcb_cl,ax
	mov	find_hcb_cl+2,dx
	les	bx,hashroot		; get our hashing pointer
	mov	ax,es
	or	ax,bx			; is hashing enabled ?
	 jz	find_hcb30
	mov	cl,adrive		; look for this drive
	mov	dx,find_hcb_cl
	cmp	dx,es:HCB_CLU[bx]	; does cluster match?
	 jne	find_hcb10		; goto next if not
	mov	dx,find_hcb_cl+2
	cmp	dx,es:HCB_CLUH[bx]
	 jne	find_hcb10
	cmp	cl,es:HCB_DRV[bx]	; does drive match?
	 jne	find_hcb10		; goto next if not
;	clc
	ret				; we have a match on the 1st one

find_hcb10:
; no match, so look futher along the chain
	mov	ax,es:HCB_LINK[bx]	; onto the next entry
	test	ax,ax			; is there one ?
	 jz	find_hcb20
	xchg	ax,bx			; AX = previous entry, BX = current
	mov	dx,find_hcb_cl
	cmp	dx,es:HCB_CLU[bx]	; does cluster match?
	 jne	find_hcb10		; goto next if not
	mov	dx,find_hcb_cl+2
	cmp	dx,es:HCB_CLUH[bx]
	 jne	find_hcb10
	cmp	cl,es:HCB_DRV[bx]	; does drive match?
	 jne	find_hcb10		; goto next if not
; we have a match, but it's not the first so recycle it
	mov	cx,es:HCB_LINK[bx]	; get link to the rest of the chain
	xchg	ax,bx			; BX = previous entry
	mov	es:HCB_LINK[bx],cx	; unlink ourselves from chain
	mov	bx,ax			; BX = current entry
	xchg	ax,word ptr hashroot	; put current entry at the head
	mov	es:HCB_LINK[bx],ax	;  and relink the rest of the chain
;	clc
	ret

find_hcb20:
; we have been all along the chain with no luck
	xor	ax,ax
	test	ch,ch			; no HCB_ - do we want to recyle ?
	 jz	find_hcb30		;  if not skip
	mov	es:HCB_CNT[bx],ax	; we need to recycle oldest HCB_
	mov	dx,find_hcb_cl
	mov	es:HCB_CLU[bx],dx	;  so mark as us, but with nothing
	mov	dx,find_hcb_cl+2
	mov	es:HCB_CLUH[bx],dx
	mov	es:HCB_DRV[bx],cl	;  in it
;	clc
	ret

find_hcb30:
	stc				; return failure
	ret

;-----
mkhsh:
;-----
;
;	entry:	SI = 11 byte FCB to convert to hash code
;	exit:	AX = 1..FFFF is hash code (00/E5 == 0)
;	uses:	DX
;	saves:	BX,CX,DI,BP
;
;	used for hashing the INFO_FCB &
;	directory entries for DOS media

	xor	dx,dx			;assume hash code is 0000
	lodsb
	cmp	al,0E5h			;if deleted file
	 je	mkhsh2			;   or
	cmp	al,0			;if virgin entry
	 je	mkhsh2			;then hash code = 0;
	push	cx			;else save CX
	and	al,7fh
	mov	dh,al			;initialize hash code MSB
	mov	cx,10			;involve other 10 characters
mkhsh1:
	lodsb				;get next character
	rol	dx,1			;rotate hash code by one bit
	and	al,7fh			;strip top bit off character
	xor	dl,al			;XOR the character into the hash code
	loop	mkhsh1			;repeat for all characters
	pop	cx			;restore CX
	test	dx,dx			;test if zero by any chance
	 jnz	mkhsh2			;skip if non-zero
	inc	dx			;else force it to 1
mkhsh2:					;return hash code in AX
	xchg	ax,dx
	ret


ifdef DELWATCH
	Public	fixup_hashing
;
; update hashing for current drive if DELWATCH changes a directory entry
;
fixup_hashing:
;-------------
; On Entry:
;	CX =	segment of dir buffer
;	DX:AX =	cluster to fixup (0 = root)
;	DI =	directory entry index (clipped to cluster if subdir)
;	CX:SI->	dir entry (single entry for hashing)
;
; On Exit:
;	None
;
	push	ds
	push	es

;	xor	dh,dh			; we only want HCB_ if it's there
	push	cx			; save seg of dir entry
	xor	ch,ch			; we only want HCB_ if it's there
	call	find_hcb		; does an HCB_ exist for this entry ?
	pop	ds			; DS:SI -> entry to hash
	 jc	fixup_ck10		; not hashed, skip update
	cmp	di,es:HCB_CNT[bx]	; is this within the hashed entries ?
	 jae	fixup_ck10		;  no, skip the fixup
	call	mkhsh			; cx = hash code of our entry

	shl	di,1			; DI = offset of hashed entry
	lea	di,HCB_DATA[bx+di]
	stosw				; update hash code for dir entry

fixup_ck10:
	pop	es
	pop	ds
	ret				; no
endif



hashsrch:
;--------
;	entry:	DX:AX = starting cluster of directory
;	exit:	AX is possible match index
;
;	mov	dh,0FFh			; we want HCB_ even if it's recycled
	mov	ch,0FFh			; we want HCB_ even if it's recycled
;	xchg	ax,cx			;  and this block
	call	find_hcb		; does an HCB_ exist for this entry ?
;	mov	ax,0			; assume unhashed search required
	 jc	hashsrch20		;  start one if no hashing
hashsrch10:
	mov	cx,es:HCB_CNT[bx]	; we have this many entries hashed
	 jcxz	hashsrch30		; skip if nothing hashed yet
	mov	ax,hash			; look for this hash code
	lea	di,HCB_DATA[bx]		; DI = offset of start of search
	repne	scasw			; try to find a match
	 jne	hashsrch30		; skip if no match found
	lea	ax,HCB_DATA+2[bx]	; find word offset of match
	xchg	ax,di			; return matching index
	sub	ax,di
	shr	ax,1			; make dir offset
hashsrch20:
	push 	ds
	pop 	es
	clc				; we have found it
	ret

hashsrch30:
	call	rehash_entry		; try and hash another entry
	 jnc	hashsrch10		;  look again if we succeeded

	mov	ax,es:HCB_CNT[bx]	; failure, so return # to skip
	push 	ds
	pop 	es
;	stc				;  for quicker search
	ret


rehash_entry:
;------------
;	entry:	ES:BX -> HCB
;		AX = hash cluster number ??? This does not seem to be used...

	call	hash_entries_to_do	; how many entries still to hash ?
	 jcxz	rehash_entry40		; if we have hashed them all exit

	push	dcnt			; save directory count

	mov	ax,dcnt			; get previous position
	inc	ax			; we start looking here
	xor	dx,dx
	div	dirperclu		; mask to start of cluster
	mul	dirperclu
	add	ax,es:HCB_CNT[bx]	; skip entries we already have
	dec	ax			; make previous entry BEFORE this
	mov	dcnt,ax
	mov	chdblk,0		; non-sequential access
	mov	chdblk+2,0
	cmp	cx,512/32		; don't try reading more than 512 bytes
	 jb	rehash_entry20		;  at a time - then with 512 byte secs
	mov	cx,512/32		;  we only read when we
rehash_entry20:
	push	es
	push	bx			; save hash control pointer
	push	cx			; save # entries to do
	push 	ds
	pop 	es			; back to small model
	xor	cx,cx			; return any entry
	call	gtd_next		; unhashed search
	pop	cx			; restore # entries to do
	pop	bx			; restore hash control pointer
	pop	es
	test	ax,ax			; anything found
	 jz	rehash_entry30		; end of directory
	xchg	ax,si			; else get directory pointer
	mov	di,es:HCB_CNT[bx]
	shl	di,1			; DI -> 1st new entry
	lea	di,HCB_DATA[bx+di]
	push	si
	call	mkhsh			; else calculate hash into AX
	stosw				; add it to hash table
	inc	es:HCB_CNT[bx]		; remember we did
	pop	si
	lodsb				; get 1st byte of hashed entry
	test	al,al			; is it zero (ie. never used)?
	loopne	rehash_entry20		; get all hash codes
	 jcxz	rehash_entry30		; all done ?
	call	hash_entries_to_do	; how many entries still to hash ?
	add	es:HCB_CNT[bx],cx	;  we will do them all..
	rep	stosw			; zap rest of cluster
rehash_entry30:	
	pop	dcnt			; restore count
	mov	chdblk,0		; non-sequential access
	mov	chdblk+2,0
	clc				; we have new hashing codes
	ret				; HCB updated with new cluster

rehash_entry40:
	stc				; cannot hash no more...
	ret

hash_entries_to_do:
;------------------
; On Entry:
;	ES:BX -> HCB_
; On Exit:
;	CX = maximum possible entries we still need to hash for HCB_
;	(All other regs preserved)
;
	mov	cx,dirinroot		; assume root dir
	cmp	es:HCB_CLU[bx],0	; was it ?
;	 je	hash_etd10
	 jne	hash_etd09		; no, proceed normally
	cmp	es:HCB_CLUH[bx],0
	 jne	hash_etd09
	cmp	dirinroot,0		; is this FAT32?
	 jne	hash_etd10		; no, proceed with FAT12/16 routine
hash_etd09:
	mov	cx,dirperclu		; subdir, so cluster limit
hash_etd10:
	cmp	cx,hashmax		; do we support this many ?
	 jb	hash_etd20		;   yes, skip it
	mov	cx,hashmax		; else limit it to this many
hash_etd20:
	sub	cx,es:HCB_CNT[bx]	; subtract number we have already done
	ret



hshdscrd:
;--------
;	purge hash blocks for physical drive
;	On Entry:
;		AL = drive to discard (FF = all drives)
;	On Exit:
;		None (All regs preserved)

	push	ds
	push	bx
	lds	bx,hashroot		; get root of hash codes
hshdsc1:
	test	bx,bx
	 jz	hshdsc4			; all blocks done
	cmp	al,0FFh			; FF means discard all drives
	 je	hshdsc2
	cmp	al,ds:HCB_DRV[bx]	; check if matching drive
	 jne	hshdsc3
hshdsc2:
	mov	ds:HCB_DRV[bx],0ffh	;	h->hd = 0xff;
hshdsc3:
	mov	bx,ds:HCB_LINK[bx]	; get next hash code block
	jmp	hshdsc1
hshdsc4:
	pop	bx
	pop	ds
	ret



enlarge_root:
ifdef DELWATCH
	mov	ah,DELW_FREERD		; lets ask DELWATCH if it can
	mov	al,adrive		; free a root directory entry
	call	dword ptr ss:fdos_stub		;  for this drive
	 jnc	allocdir		; it says it has so try again
endif
allocdir_err:
	pop	ax			; discard return address
	mov	ax,ED_MAKE
	jmp	fdos_error		; return "cannot make dir entry"


;--------
allocdir:			; Called by rename and MAKE
;--------
	call	setenddir		; search for first match
	mov	cx,1			; return empty fcb
	call	getdir			; is there an empty fcb?
	 jz	allocdir10		; if so use that
	ret
allocdir10:
	call	hdsblk			; Are we at the root?
	 jnz	allocdir20		; no, proceed
	cmp	dosfat,FAT32		; FAT32 file system?
;	 jz	enlarge_root		; YES -- Report error(no room)
	 jne	enlarge_root		; NO -- Report error(no room)
	mov	dx,word ptr fsroot+2	; use starting cluster of root dir
	mov	ax,word ptr fsroot

	; We are in a subdirectory so enlarge it
	; AX has 1st block of subdirectory   NOTE -- AX is never
	; above 'lastcl' on entry.
allocdir20:
;	cmp	ax,lastcl		; Are we at end of subdirectory?
	cmp	dx,blastcl+2		; Are we at end of subdirectory?
	 ja	allocdir30		; YES
	 jb	allocdir25
	cmp	ax,blastcl
	 ja	allocdir30
allocdir25:
	push	dx
	push	ax
	call	getnblk			; NO -- get next block then
        pop	bx
	pop	cx
	jmp	allocdir20

allocdir30:
	push	cx
	push	bx			; save last block number
	xchg	ax,bx			; Get a new block (start from old)
	xchg	dx,cx
	call	alloc_cluster
	pop	bx
	pop	cx
	 jc	allocdir_err		; Report Error(no room on disk)
	push	dx
	push	ax			; save new block
	xchg	ax,bx
	xchg	dx,cx
	call	fixfat			; Update fat (AX,BX) old last block
					;  points to new last block
	pop	ax			; Get new last block
	pop	dx
	push	dx
	push	ax
	xor	cx,cx
	mov	bx,dosfat		; 12 or 16 bit fat
	cmp	dosfat,FAT32		; FAT32 file system
	 jne	allocdir35		; no, then proceed with this value
	mov	bx,0ffffh		; else use this one instead
	mov	cx,bx
allocdir35:
	call	fixfat			; Update fat (AX,BX)  new last block
					;  has end of cluster marker
	call	update_fat		; Write out to disk
	pop	ax			; Get new last block
	pop	dx
	call	zeroblk			; Zero it out
        call	setenddir		; Set up for search first
	mov	cx,1			; Find empty fcb
	jmp	getdir			; Can not return with not found error

BDOS_CODE	ends

	END
