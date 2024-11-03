title 'BDEVIF - Block DEVice Input/Output support'
;    File              : $BDEVIO.ASM$
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
;    BDEVIO.A86 1.27 94/11/30 16:25:22
;    added delayed retry for read/write to locked region
;    added support for using multiple FAT copies on reads if one fails;    
;    BDEVIO.A86 1.26 94/02/22 17:11:25
;    Fix where corrupt dir entry results in read beyond end-of-chain (Filelink bug)
;    BDEVIO.A86 1.25 93/12/15 03:07:11
;    New ddioif entry point so Int 25/26 bypasses address normalisation
;    BDEVIO.A86 1.24 93/12/08 03:15:14
;    Force rebuild_ldt_root if root in JOIN's subdirectory
;    BDEVIO.A86 1.23 93/11/19 18:29:29
;    Fix for SERVER print queue viewing problem
;    BDEVIO.A86 1.22 93/09/21 12:43:37
;    On fdos read/write do EOF checks before SHARE LOCK checks
;    BDEVIO.A86 1.21 93/09/14 20:02:50
;    Trust LFLG_PHYSICAL
;    BDEVIO.A86 1.20 93/09/02 22:22:56
;    Use 32 bit sectors to read fat for build bpb if appropriate (SYQUEST bug)
;    BDEVIO.A86 1.19 93/08/27 18:46:49
;    int 26 discards hash codes
;    BDEVIO.A86 1.18 93/07/20 22:42:25
;    Even fewer checks on int 25/26 
;    BDEVIO.A86 1.12 93/06/23 02:57:07
;    Add auto-commit to fdowrw
;    BDEVIO.A86 1.11 93/05/14 13:47:41
;    Shorten media change code slightly
;    BDEVIO.A86 1.9 93/03/16 22:30:21 IJACK
;    UNDELETE support changes
;    ENDLOG

PCMCODE	GROUP	BDOS_CODE
PCMDATA	GROUP	BDOS_DATA,PCMODE_DATA

ASSUME CS:PCMCODE,DS:PCMDATA

	.nolist
	include mserror.equ	; F_DOS errors
	include fdos.equ
	include driver.equ
	include doshndl.def
	include bdos.equ
	include request.equ
	.list

;*****************************************************
;*
;*	bdos data area
;*
;*****************************************************

PCMODE_DATA	segment public word 'DATA'
	extrn	current_ddsc:dword
	extrn	current_dhndl:dword
	extrn	current_dsk:byte	; default drive
	extrn	current_ldt:dword	; currently selected LDT
	extrn	dma_offset:word		; DTA offset
	extrn	dma_segment:word	; DTA segment
	extrn	ddsc_ptr:dword
	extrn	err_drv:byte
	extrn	error_dev:dword		; failing device for Int 24's
	extrn	fdos_stub:dword
	extrn	ioexerr:byte
	extrn	last_drv:byte
	extrn	ldt_ptr:dword
	extrn	lock_bios:dword
	extrn	phys_drv:byte
	extrn	rwmode:byte
	extrn	share_stub:dword
	extrn	unlock_bios:dword
	extrn	verify_flag:byte
	extrn	net_retry:word
PCMODE_DATA	ends


BDOS_DATA	segment public word 'DATA'

	extrn	bcb_root:dword
	extrn	deblock_seg:word
	extrn	fdos_hds_drv:byte
	extrn	fdos_hds_blk:word
	extrn	fdos_hds_root:word
	extrn	fdos_ret:word

	public	adrive
	public	clsize
	public	dosfat
	public	cur_dma
	public	cur_dma_seg
	public	datadd
	public	diradd
	public	dirinroot
	public	dirperclu
	public	fatadd
	public	hdsaddr
	public	lastcl
	public	blastcl
	public	logical_drv
	public	mult_sec
	public	nfatrecs
	public	nfats
	public	pblock
	public	physical_drv
	public	psecsiz
	public	req_hdr
	public	secperclu
	public	fsroot

; The following specify the drive selected for the current operation

hdsaddr		dw	0		; current HDS address (0 means at root)
logical_drv	db	0		; logical drive number
physical_drv	db	0		; physical disk number

; The following describe the currently active drive - not this may differ from
; the currently selected drive above due to eg. flushing dirty buffers

; Local copy of DDSC_ variables - ORDER CRITICAL - must match DDSC_

local_ddsc	label byte
psecsiz		dw	0		; byte size of sector
clmsk		db	0
clshf		db	0
fatadd		dw	0		; sector offset of 1st FAT sector
byte_nfats	db	0		; number of FAT's
dirinroot	dw	0		; # dir entries in root
datadd		dw	0		; sector offset of data sector
lastcl		dw	0		; # last cluster (after adjustment)
		dw	0		; # sectors per FAT
diradd		dw	0		; sector offset of 1st root DIR sector

LOCAL_DDSC_LEN	equ	offset $ - offset local_ddsc

local_ddsc2	label byte
;		dw	0,0		; total free clusters on drive
;		dw	0		; FAT flags
;		dw	0		; FS info
;		dw	0		; backup boot sec
bdatadd		dw	0,0
blastcl		dw	0,0		; # last cluster (32-bit)
		dw	0,0		; # sectors per FAT (32-bit)
fsroot		dw	0,0		; first cluster of root dir
;		dw	0,0		; next block to allocate
;		dw	0		; version of file system

LOCAL_DDSC2_LEN	equ	offset $ - offset local_ddsc2

;	some extra parameters calculated from local_ddsc for convenience

nfats		dw	0		; # FAT's (WORD is handier)
nfatrecs	dw	0,0		; # sectors per FAT (accurate version)
clsize		dw	0,0		; cluster size in bytes
secperclu	dw	0		; # sectors per cluster
dirperclu	dw	0		; # dir enrties in subdir

dosfat		dw	0		; FAT length indicator (FAT12 or FAT16)

; The following specify the next block read/write operation on the active drive

adrive		db	0ffh		; currently active disk
pblock		dw	0, 0		; absolute block address
mult_sec	dw	1		; multi sector count passed to xios
cur_dma		dw	0
cur_dma_seg	dw	0

fdrwreq		dw	0		; requested count (roundup)

	public	fdrwflg
fdrwflg		db	0		; bdosrw flags
fdrwcnt		dw	0		; requested byte count for read/write
fdrwptr		label dword		; disk transfer address for read/write
fdrwoff		dw	0		; offset for R/W DTA
fdrwseg		dw	0		; segment for R/W DTA

fdrwsec		dd	0		; physical block for fdosrw
fdrwsecoff	dw	0		; offset within sector
fdrwdircnt	dw	0		; # sectors in direct xfer

byteoff		dw	0		; fdosrw local variable
		dw	0		; byte offset with file
		dw	0,0

fsize		dw	0,0,0,0		; used for file size calculations
lastpos		dw	0,0,0,0		; last position that has been written

blk		dw	0,0		; current cluster of filepos
blkidx		dw	0,0		; current cluster index within file
blkoffset	dw	0,0		; offset within cluster

fdrw_seek_cl	dw	0,0
fdw_trunc_cl	dw	0,0
fdw_extend_cl	dw	0,0
check_cont_cl	dw	0,0

lasttsc		dw	0,0,0,0
tscsel		dw	0
tsc1		dw	0,0,0,0,0,0,0,0
tsc2		dw	0,0,0,0,0,0,0,0
tsc3		dw	0,0,0,0,0,0,0,0

;	static request header for DOS device driver I/O

	Public	req_hdr

req_hdr		label byte
req_len		db	22
req_unit	db	0
req_cmd		db	0
req_status	dw	0
req_rwmode	db	0		; action hint for device drivers
		db	7 dup (0)
req_media	db	0
		db	16 dup (0)

req1_return	equ	byte ptr req_media+1
req1_volid	equ	word ptr req_media+2

req2_buffer	equ	word ptr req_media+1
req2_bpb	equ	word ptr req_media+5

req3_buffer	equ	word ptr req_media+1
req3_count	equ	word ptr req_media+5
req3_sector	equ	word ptr req_media+7
req3_volid	equ	word ptr req_media+9

req4_buffer	equ	word ptr req_media+1
req4_count	equ	word ptr req_media+5
req4_sector	equ	word ptr req_media+7
req4_volid	equ	dword ptr req_media+9
req4_bigsector	equ	dword ptr req_media+13

BDOS_DATA	ends


BDOS_CODE	segment public byte 'CODE'

	extrn	alloc_chain:near
	extrn	bpb2ddsc:near		; converts BPB to DDSC
	extrn	buffers_check:near	; look for buffers
	extrn	delfat:near
	extrn	discard_all:near	; discard all buffers
	extrn	discard_dir:near	; discard directory buffers
	extrn	discard_dirty:near	; discard all dirty buffers
	extrn	discard_files:near	; discard open files
	extrn	fdos_error:near
	extrn	fdos_restart:near
	extrn	file_update:near
	extrn	fixfat:near
	extrn	getnblk:near		; get block value from FAT
	extrn	get_ldt:near
	extrn	get_ldt_raw:near
	extrn	hdsblk:near		; get current HDS block
	extrn	hshdscrd:near
	extrn	locate_buffer:near
	extrn	rebuild_ldt_root:near
	extrn	timestamp_dhndl:near
	extrn	update_dat:near
	extrn	update_fat:near
	extrn	share_delay:near
	extrn	fatptr_tag:near

	public	block_device_driver
	public	clus2sec
	public	device_driver
	public	read_block
	public	select_adrive
	public	select_logical_drv
	public	select_physical_drv
	public 	write_block
	public	div32
	public	mul32
	public	div64
	public	mul64

	public	get_ddsc

get_ddsc:
;--------
; On Entry:
;	AL = physical drive
; On Exit:
;	CY set if bad drive, else
;	ES:BX -> DDSC_
;	(All other registers preserved)
;
	cmp	al,ss:phys_drv
	 jae	get_ddsc30
	les	bx,ss:ddsc_ptr
get_ddsc10:
	cmp	bx,0FFFFh		; end of the line
	 je	get_ddsc30
	cmp	al,es:DDSC_UNIT[bx]	; does the unit match ?
	 je	get_ddsc20		; no, try the next
	les	bx,es:DDSC_LINK[bx]
	jmp	get_ddsc10
get_ddsc20:
;	clc
	ret
get_ddsc30:
	stc
	ret

;	Read/Write from/to disk file

;	entry:	CURRENT_DNHDL -> file handle
;		BDRWFLG = 1 => read
;			  0 => write
;		ES:DI = buffer (32 bit: off/seg)
;		CX = requested byte count (16 bit)

;	exit:	FDOS_RET = number of bytes read/written
;		CURRENT_DHNDL incremented by FDOS_RET

	public	fdosrw			; read/write to/from disk file

fdosrw:
;------
	call	fdrw_prepare		; set up address, where we are in file
	 jc	fdrw_error		;  stop if we have a problem
	call	fdrw_size		; extend file if necessary
	 jc	fdrw_error		;  bail out if we can't
	cmp	fdrwcnt,0		; are we truncating?
	 jne	fdrw_loop		; read/write if non-zero count
	test	fdrwflg,1		; writing zero bytes?
	 jnz	fdrw_error		; (reading has no meaning)
	call	fdw_trunc		; writing truncates the file
	jmp	fdrw_nobigger
fdrw_error:
	ret

fdrw_loop:				; loop here for long reads/writes
	call	fdrw_seek		; seek to position for xfer
;	 jc	fdrw_exit		;  should get error's now...
	 jnc	fdrw_noerror
	jmp	fdrw_exit
fdrw_noerror:
	 jnz	fdrw_buffered		; deblocking required if not aligned
	mov	cx,fdrwcnt		; CX = requested transfer size
	cmp	cx,psecsiz		; at least one sector transferred?
;	 jb	fdrw_buffered		; if less, need deblocked transfer
	 jae	fdrw_direct
	test	fdrwflg,1
	 jnz	fdrw_buffered
	mov	ax,byteoff
	sub	ax,lastpos
	mov	ax,byteoff+2
	sbb	ax,lastpos+2
	mov	ax,byteoff+4
	sbb	ax,lastpos+4
	mov	ax,byteoff+6
	sbb	ax,lastpos+6
	 jc	fdrw_buffered
	call	deblock_rw_npr
	jmp	fdrw_more
fdrw_direct:
	mov	fdrwreq,cx		; requested count for direct r/w
	call	direct_rw		; transfer straight to/from TPA
	jmp	fdrw_more
fdrw_buffered:				; perform deblocked read/write
	call	deblock_rw		; transfer via BDOS buffer
fdrw_more:
	add	fdrwoff,ax		; adjust buffer address
	add	fdos_ret,ax		; adjust return code

	add	byteoff,ax		; adjust file offset
	adc	byteoff+2,0
	adc	byteoff+4,0
	adc	byteoff+6,0

	push	ax
	mov	ax,psecsiz
	dec	ax
	or	ax,lastpos
	sub	ax,byteoff
	mov	ax,lastpos+2
	sbb	ax,byteoff+2
	mov	ax,lastpos+4
	sbb	ax,byteoff+4
	mov	ax,lastpos+6
	sbb	ax,byteoff+6
	 jnc	fdrw_nohigher
	mov	ax,byteoff
	mov	lastpos,ax
	mov	ax,byteoff+2
	mov	lastpos+2,ax
	mov	ax,byteoff+4
	mov	lastpos+4,ax
	mov	ax,byteoff+6
	mov	lastpos+6,ax

fdrw_nohigher:
	pop	ax
	sub	fdrwcnt,ax		; adjust remaining count
;	 ja	fdrw_loop		; still more to do
	 jna	fdrw_exit
	jmp	fdrw_loop
fdrw_exit:
	les	bx,current_dhndl
	mov	ax,fdos_ret		; get total xfered and update position
	add	es:DHNDL_POSLO[bx],ax
	adc	es:DHNDL_POSHI[bx],0
	adc	es:DHNDL_POSXLO[bx],0
	adc	es:DHNDL_POSXHI[bx],0
	test	fdrwflg,1
	 jnz	fdrw_return		; skip if reading
;	mov	ax,byteoff		; has the file grown ?
;	mov	dx,byteoff+WORD
;	sub	ax,es:DHNDL_SIZELO[bx]
;	sbb	dx,es:DHNDL_SIZEHI[bx]
	mov	ax,byteoff
	sub	ax,es:DHNDL_SIZELO[bx]
	mov	fsize,ax
	mov	ax,byteoff+2
	sbb	ax,es:DHNDL_SIZEHI[bx]
	mov	fsize+2,ax
	mov	ax,byteoff+4
	sbb	ax,es:DHNDL_SIZEXLO[bx]
	mov	fsize+4,ax
	mov	ax,byteoff+6
	sbb	ax,es:DHNDL_SIZEXHI[bx]
	mov	fsize+6,ax
	 jb	fdrw_nobigger		; yes, update the file size
;	add	es:DHNDL_SIZELO[bx],ax
;	adc	es:DHNDL_SIZEHI[bx],dx
	mov	ax,fsize
	add	es:DHNDL_SIZELO[bx],ax
	mov	ax,fsize+2
	adc	es:DHNDL_SIZEHI[bx],ax
	mov	ax,fsize+4
	adc	es:DHNDL_SIZEXLO[bx],ax
	mov	ax,fsize+6
	adc	es:DHNDL_SIZEXHI[bx],ax
fdrw_nobigger:
	call	timestamp_dhndl		; record the current time
	test	es:DHNDL_MODE[bx],DHM_COMMIT
	 jz	fdrw_return		; is auto-commit in place ?
	call	file_update		; yes, commit the file
fdrw_return:
	ret



fdw_trunc:
;---------
; On Entry:
;	BLKIDX = block number within file
;	BLKOFFSET = block offset
; On Exit:
;	DHNDL_SIZE adjusted, any excess clusters freed
;

	les	bx,current_dhndl
;	mov	cx,blkoffset		; get offset within current block
	mov	ax,blkidx		; get logical block number
	mov	dx,blkidx+2
	cmp	blkoffset,0		; get offset within current block
;	 jcxz	fdw_t10			; skip if no data in last block
	 jnz	fdw_t05			; skip if no data in last block
	cmp	blkoffset+2,0
	 jz	fdw_t10
fdw_t05:
;	inc	ax			; else add in another cluster
	add	ax,1			; else add in another cluster
	adc	dx,0
fdw_t10:				; AX = # of clusters required in file
	test	ax,ax
	 jnz	fdw_t20
	test	dx,dx
	 jnz	fdw_t20
	xchg	ax,es:DHNDL_BLK1[bx]	; forget about chain
	xchg	dx,es:DHNDL_BLK1H[bx]
	jmp	fdw_t50

fdw_t20:
;	xchg	ax,cx			; CX = # of blocks to keep
	mov	fdw_trunc_cl,ax		; # of blocks to keep
	mov	fdw_trunc_cl+2,dx
	mov	ax,es:DHNDL_BLK1[bx]	; get first block in file
	mov	dx,es:DHNDL_BLK1H[bx]
fdw_t30:				; scan all block we want to keep
;	push	cx
	push	dx
	push	ax
	call	getnblk			; get next block
	pop	bx
	pop	cx
;	cmp	ax,lastcl		; stop on premature end of chain
	cmp	dx,blastcl+2		; stop on premature end of chain
	 ja	fdw_t60
	 jb	fdw_t35
	cmp	ax,blastcl
	 ja	fdw_t60
fdw_t35:
;	loop	fdw_t30
	sub	fdw_trunc_cl,1
	sbb	fdw_trunc_cl+2,0
	cmp	fdw_trunc_cl+2,0
	 jne	fdw_t30
	cmp	fdw_trunc_cl,0
	 jne	fdw_t30
	push	dx
	push	ax			; yep, remember what
	mov	ax,dosfat
	xor	dx,dx
	cmp	ax,FAT32		; FAT32 file system?
	 jne	fdw_t36			; no, proceed normally
	mov	ax,FAT16		; use 0ffffh instead
	mov	dx,ax
fdw_t36:
	xchg	ax,bx			; truncate chain at cluster AX
	xchg	dx,cx
	call	fixfat			;  as thats all we need
	pop	ax
	pop	dx
fdw_t50:
	call	delfat			; release the chain
fdw_t60:
	les	bx,current_dhndl
	mov	ax,byteoff		; now truncate the file
	mov	es:DHNDL_SIZELO[bx],ax
	mov	ax,byteoff+2
	mov	es:DHNDL_SIZEHI[bx],ax
	mov	ax,byteoff+4
	mov	es:DHNDL_SIZEXLO[bx],ax
	mov	ax,byteoff+6
	mov	es:DHNDL_SIZEXHI[bx],ax
	xor	ax,ax			; cause reads/writes to scan
	mov	es:DHNDL_BLK[bx],ax	;   block chain from start
	mov	es:DHNDL_BLKH[bx],ax
	mov	es:DHNDL_IDX[bx],ax
	mov	es:DHNDL_IDXH[bx],ax
	mov	fdos_ret,ax		; no logical errors
	ret



fdrw_prepare:
;------------
; Normalise the xfer address and count
; Calculate current position in the file
;
; On Entry:
;	ES:DI -> buffer
;	CX = bytes to xfer
; On Exit:
;	FDRWSEG:FDRWOFF -> normalised buffer
;	FDRWCNT = bytes to xfer
;	FDOS_RET = bytes xfer'd (0)
;	PREREAD = TRUE
;	BYTEOFF = current offset in file
;	BLKIDX = cluster containing current file position
;	BLKOFFSET = offset within cluster
;	CY set if current position theoretically impossible
;

	xor	ax,ax			; AX = 0
	mov	fdos_ret,ax		; initialize byte return count
	mov	fdrwcnt,cx		; save byte count for read/write
	mov	ax,000Fh
	and	ax,di			; get offset within paragraph
	mov	fdrwoff,ax		; save normalized offset for read/write
	add	ax,cx			; do we overflow 64k ?
	 jnc	fdrw_p10		; yes, then forget about what would
	sub	fdrwcnt,ax		;  overflow this segment
fdrw_p10:
	mov	cl,4
	shr	di,cl			; DI = paragraph offset
	mov	ax,es
	add	ax,di			; AX = effective segment
	 jnc	fdrw_p20		; if above 1 MByte base it at FFFF
	inc	ax			; AX = para's above FFFF
	shl	ax,cl			; make it bytes
	add	fdrwoff,ax		;  add to offset
	mov	ax,0ffffh		; use our magic segment
fdrw_p20:
	mov	fdrwseg,ax		; save normalized segment for read/write
	les	bx,current_dhndl
	mov	ax,es:DHNDL_POSLO[bx]	; copy position to local variables
	mov	byteoff,ax
	mov	ax,es:DHNDL_POSHI[bx]
	mov	byteoff+2,ax
	mov	ax,es:DHNDL_POSXLO[bx]
	cmp	ax,63			; greater than 256 GB-1
	 jbe	fdrw_p25
	jmp	fdrw_p40		; then it is too big even for FAT+
fdrw_p25:
	mov	byteoff+4,ax
	mov	ax,es:DHNDL_POSXHI[bx]
	cmp	ax,0
;	 ja	fdrw_p40
	 jna	fdrw_p27
	jmp	fdrw_p40
fdrw_p27:
	mov	byteoff+6,ax
	mov	ax,es:DHNDL_SIZELO[bx]	; copy file size
	mov	lastpos,ax
	mov	ax,es:DHNDL_SIZEHI[bx]
	mov	lastpos+2,ax
	mov	ax,es:DHNDL_SIZEXLO[bx]
	mov	lastpos+4,ax
	mov	ax,es:DHNDL_SIZEXHI[bx]
	mov	lastpos+6,ax
;	mov	cx,clsize
;	mov	ax,lastcl
;	mul	cx			; DX:AX = maximum size of disk
	push	word ptr clsize+2
	push	word ptr clsize
	push	blastcl+2
	push	blastcl
	sub	sp,8			; reserve space on stack
	call	mul32			; compute maximum size of disk
;	pop	ax
;	pop	dx
;	pop	cx
	pop	fsize
	pop	fsize+2
	pop	fsize+4
	pop	fsize+6
;	add	sp,10			; clean up the stack again
	add	sp,8			; clean up the stack again
;	sub	ax,byteoff
;	sbb	dx,byteoff+WORD		; beyond this we can't go
;	sbb	cx,0
	mov	ax,fsize
	sub	ax,byteoff
	mov	ax,fsize+2
	sbb	ax,byteoff+2
	mov	ax,fsize+4
	sbb	ax,byteoff+4
	mov	ax,fsize+6
	sbb	ax,byteoff+6
	 jc	fdrw_p30
;	mov	ax,byteoff		; DX:AX = current file size
;	mov	dx,byteoff+WORD
;	div	clsize
;	mov	blkidx,ax		; save it for later
;	mov	blkoffset,dx		; DX = offset within cluster
	push	word ptr byteoff+6	; current file size
	push	word ptr byteoff+4
	push	word ptr byteoff+2
	push	word ptr byteoff
	push	word ptr clsize+2
	push	word ptr clsize
	sub	sp,8			; reserve space on stack
;	call	div32
	call	div64
	pop	word ptr blkoffset	; offset within cluster
	pop	word ptr blkoffset+2
;	add	sp,2			; skip high word
	pop	word ptr blkidx		; save it for later
	pop	word ptr blkidx+2
;	add	sp,8			; clean up stack
	add	sp,12			; clean up stack
	clc				; theoretically possible
fdrw_p30:
	ret

fdrw_p40:
	stc
	ret

fdrw_size:
;---------
; On reads check xfer starts within file, and clip size to reflect EOF.
; On writes try to extend to cluster chain so it is big enough to contain
; the data we wish to write.
;
; On Entry:
;	BYTEOFF = current position in file
;	FDRWCNT = extra bytes requested
; On Exit:
;	FDRWCNT adjusted if read past EOF
;	CY set if problem extending file
;
	les	bx,current_dhndl
;	mov	ax,es:DHNDL_SIZELO[bx]	; are we past the end of file
;	mov	dx,es:DHNDL_SIZEHI[bx]	;  if so we may wish to extend on write
;	sub	ax,byteoff		; AX,DX = current offset
;	sbb	dx,byteoff+WORD		; are we already beyond EOF ?
	mov	ax,es:DHNDL_SIZELO[bx]
	sub	ax,byteoff
	mov	fsize,ax
	mov	ax,es:DHNDL_SIZEHI[bx]
	sbb	ax,byteoff+2
	mov	fsize+2,ax
	mov	ax,es:DHNDL_SIZEXLO[bx]
	sbb	ax,byteoff+4
	mov	fsize+4,ax
	mov	ax,es:DHNDL_SIZEXHI[bx]
	sbb	ax,byteoff+6
	mov	fsize+6,ax
	 jb	fdrw_s40
;	sub	ax,fdrwcnt		; will we be going beyond EOF ?
;	sbb	dx,0
	mov	ax,fdrwcnt
	sub	fsize,ax
	sbb	fsize+2,0
	sbb	fsize+4,0
	sbb	fsize+6,0
	 jnb	fdrw_s10		; no, whole xfer is OK
	test	fdrwflg,1		; check if we're reading
	 jz	fdrw_s50		;  if we are just adjust the
	mov	ax,fsize
	add	fdrwcnt,ax		;  amount we can xfer
fdrw_s10:
; We call share concerning the XFER to check if any of the proposed
; file region is locked.

;	les	bx,current_dhndl	; check for locked regions
	mov	cx,net_retry
fdrw_s15:
	push	cx
	mov	cx,fdrwcnt		;  in the file
	call	dword ptr share_stub+S_FDOSRW
	pop	cx
	 jnc	fdrw_s20		; CY set on error
	dec	cx
	 jz	fdrw_s30
	call	share_delay
	jmp	fdrw_s15
fdrw_s20:
	ret

fdrw_s30:
	jmp	fdos_error		; CY clear, AX = error code


fdrw_s40:
; We are going beyond EOF - if it is a read we fail it, if a write
;  try to extend the file
	test	fdrwflg,1		; check if we're reading
	stc				;  assume failure
	 jnz	fdrw_s20		; reads fail now, writes extend file
fdrw_s50:
	call	fdrw_s10		; make sure SHARE doesn't object
;	jmp	fdwrite_extend		; if not try to extend the file


fdwrite_extend:
;--------------
; Try to extend to file to the required size before we write to it
; On Entry:
;	ES:BX -> DHNDL_
;	BYTEOFF = current position in file
;	FDRWCNT = extra requested
; On Exit:
;	CY clear if cluster chain now big enough for desired file size
;

;	mov	ax,byteoff		; AX,DX = current offset
;	mov	dx,byteoff+2
;	add	ax,fdrwcnt		; AX,DX = offset after r/w if success
;	adc	dx,0			; add offset from lower 16 bits
	mov	ax,byteoff
	add	ax,fdrwcnt
	mov	fsize,ax
	mov	ax,byteoff+2
	adc	ax,0
	mov	fsize+2,ax
	mov	ax,byteoff+4
	adc	ax,0
	mov	fsize+4,ax
	mov	ax,byteoff+6
	adc	ax,0
	mov	fsize+6,ax
;	div	clsize			; AX whole blocks required
;	push	dx
;	push	ax
	push	fsize+6
	push	fsize+4
	push	fsize+2
	push	fsize
	push	word ptr clsize+2
	push	word ptr clsize
	sub	sp,8
;	call	div32
	call	div64
	pop	ax
	pop	dx
	pop	fdw_extend_cl
	pop	fdw_extend_cl+2
;	add	sp,8
	add	sp,12
	test	dx,dx			; any remainder ?
	 jnz	fdw_e04
	test	ax,ax
	 jz	fdw_e05			; yes, we have a partial block
fdw_e04:
;	inc	ax			; round up blocks required
	add	fdw_extend_cl,1		; round up blocks required
	adc	fdw_extend_cl+2,0
fdw_e05:
;	xchg	ax,cx			; CX blocks are required
	mov	ax,es:DHNDL_BLK1[bx]	; assume we need to follow from start
	mov	dx,es:DHNDL_BLK1H[bx]
	test	ax,ax
	 jnz	fdw_e06
	test	dx,dx
	 jnz	fdw_e06			; if no starting block do the lot
	 jmp	fdw_e30
fdw_e06:
;	dec	cx			;  else count # extra blocks required
	sub	fdw_extend_cl,1		;  else count # extra blocks required
	sbb	fdw_extend_cl+2,0
;	mov	dx,es:DHNDL_BLK[bx]	; do we have a current block ?
	mov	ax,es:DHNDL_BLK[bx]	; do we have a current block ?
	mov	dx,es:DHNDL_BLKH[bx]
	test	dx,dx			; if not we have to start
	 jnz	fdw_e07
	test	ax,ax
	 jz	fdw_e10			;  with the first block
fdw_e07:
;	mov	ax,dx			; new starting block as this must
	mov	ax,es:DHNDL_BLK[bx]
	mov	dx,es:DHNDL_BLKH[bx]
;	sub	cx,es:DHNDL_IDX[bx]	;  be less than extended size
	mov	cx,es:DHNDL_IDX[bx]	;  be less than extended size
	sub	fdw_extend_cl,cx
	mov	cx,es:DHNDL_IDXH[bx]
	sbb	fdw_extend_cl+2,cx
	jmp	fdw_e11
fdw_e10:
	mov	ax,es:DHNDL_BLK1[bx]
	mov	dx,es:DHNDL_BLK1H[bx]
fdw_e11:
;	 jcxz	fdw_e20			; bail out of we have enough
	cmp	fdw_extend_cl+2,0
	 jnz	fdw_e15
	cmp	fdw_extend_cl,0
	 jz	fdw_e20			; bail out of we have enough
fdw_e15:
	push	dx
	push	ax			; save current block
;	push	cx			; save # required
	call	getnblk			; AX = next block in chain	
;	pop	cx			; restore # required
	pop	bx			; recover previous block
	pop	cx
;	cmp	ax,lastcl		; end of chain yet ?
	cmp	dx,blastcl+2		; end of chain yet ?
	 ja	fdw_e40
	 jb	fdw_e17
	cmp	ax,blastcl
	 ja	fdw_e40
fdw_e17:
;	loop	fdw_e15			; try another one
	sub	fdw_extend_cl,1
	sbb	fdw_extend_cl+2,0
	cmp	fdw_extend_cl+2,0
	 jne	fdw_e15
	cmp	fdw_extend_cl,0
	 jne	fdw_e15
fdw_e20:
	clc				; chain is already long enough
	ret

fdw_e30:
; We have no initial block, so allocate them all
;	xor	ax,ax			; no preconceptions over where we
	mov	cx,fdw_extend_cl	; this value *should* not exceed 16 bits...
	call	alloc_chain		;  allocate chain of CX clusters
	 jc	fdw_e35
	les	bx,current_dhndl
	mov	es:DHNDL_BLK1[bx],ax	; remember initial block
	mov	es:DHNDL_BLK1H[bx],dx
	clc
fdw_e35:
	ret

fdw_e40:
; We have a partial chain, ending at cluster CX:BX
	push	cx
	push	bx			; save current end of chain
	xchg	ax,bx			; start allocating from cluster AX a
	xchg	dx,cx
	mov	cx,fdw_extend_cl	; this value *should* not exceed 16 bits...
	call	alloc_chain		;  a chain of CX clusters
	pop	bx
	pop	cx
	 jc	fdw_e45
	xchg	ax,bx			; AX = previous cluster, link cluster
	xchg	dx,cx
	call	fixfat			;  BX to end of the chain
	clc
fdw_e45:
	ret



fdrw_seek:
;---------
; On Entry:
;	BYTEOFF = offset within file
; On Exit:
;	BLK = cluster containing current filepos
;	BLKOFFSET = offset within cluster
;	BLKIDX = cluster index within file
;	PBLOCK = sector containing current filepos
;	POFFSET = offset within sector (reflected in ZF)
;
;	mov	ax,byteoff		; where are we now ?
;	mov	dx,byteoff+WORD
;	div	clsize
;	mov	blkidx,ax		; save cluster
;	mov	blkoffset,dx		;  and offset within it
	push	word ptr byteoff+6	; where are we now ?
	push	word ptr byteoff+4
	push	word ptr byteoff+2
	push	word ptr byteoff
	push	word ptr clsize+2
	push	word ptr clsize
	sub	sp,8			; reserve space on stack for result
;	call	div32
	call	div64
	pop	word ptr blkoffset	; save cluster and offset within it
	pop	word ptr blkoffset+2
;	add	sp,2
	pop	word ptr blkidx
	pop	word ptr blkidx+2
;	add	sp,8			; clean up stack
	add	sp,12			; clean up stack
	les	bx,current_dhndl
	mov	ax,blkidx
	mov	dx,blkidx+2
;	cmp	ax,es:DHNDL_IDX[bx]	; do we know this block ?
	cmp	dx,es:DHNDL_IDXH[bx]	; do we know this block ?
	 jb	fdrw_seek10		; we can't go backwards, use 1st block
	 ja	fdrw_seek05
	cmp	ax,es:DHNDL_IDX[bx]
	 jb	fdrw_seek10
fdrw_seek05:
;	mov	cx,es:DHNDL_BLK[bx]	; get last index block
;	 jcxz	fdrw_seek10		; use 1st block if it isn't valid
	mov	cx,es:DHNDL_BLK[bx]	; get last index block
	mov	fdrw_seek_cl,cx
	mov	cx,es:DHNDL_BLKH[bx]
	mov	fdrw_seek_cl+2,cx
	cmp	fdrw_seek_cl+2,0
	 jne	fdrw_seek06
	cmp	fdrw_seek_cl,0
	 je	fdrw_seek10		; use 1st block if it isn't valid
fdrw_seek06:
	sub	ax,es:DHNDL_IDX[bx]	; skip this many
	sbb	dx,es:DHNDL_IDXH[bx]
	jmp	fdrw_seek20
fdrw_seek10:
	mov	cx,es:DHNDL_BLK1[bx]	; start with 1st block
	mov	fdrw_seek_cl,cx
	mov	cx,es:DHNDL_BLK1H[bx]
	mov	fdrw_seek_cl+2,cx
fdrw_seek20:
;	xchg	ax,cx			; AX = starting cluster
;	 jcxz	fdrw_seek40		; CX = clusters to skip
	xchg	ax,fdrw_seek_cl		; DX:AX = starting cluster
	xchg	dx,fdrw_seek_cl+2
	cmp	fdrw_seek_cl+2,0
	 jne	fdrw_seek30
	cmp	fdrw_seek_cl,0
	 je	fdrw_seek40		; CX = clusters to skip
fdrw_seek30:
	push	cx
	call	getnblk			; get next block
	pop	cx
;	cmp	ax,lastcl		; stop on premature end of chain
	cmp	dx,blastcl+2		; stop on premature end of chain
	 ja	fdrw_seek_error		; (file size must be wrong..)
	 jb	fdrw_seek35		; continue
	cmp	ax,blastcl
	 ja	fdrw_seek_error
fdrw_seek35:
;	loop	fdrw_seek30
	sub	fdrw_seek_cl,1
	sbb	fdrw_seek_cl+2,0
	cmp	fdrw_seek_cl+2,0
	 jne	fdrw_seek30
	cmp	fdrw_seek_cl,0
	 jne	fdrw_seek30
fdrw_seek40:
	les	bx,current_dhndl
	push	dx
	push	ax
;	mov	dx,blkidx
	mov	ax,blkidx
	mov	dx,blkidx+2
;	mov	es:DHNDL_IDX[bx],dx	; remember this position for next time
	mov	es:DHNDL_IDX[bx],ax	; remember this position for next time
	mov	es:DHNDL_IDXH[bx],dx
	pop	ax
	pop	dx
	mov	es:DHNDL_BLK[bx],ax
	mov	es:DHNDL_BLKH[bx],dx
	mov	blk,ax			; save the block for coniguous checks
	mov	blk+2,dx
	call	fatptr_tag
	mov	bx,blkoffset
	mov	cx,blkoffset+2
	call	clus2sec		; convert to sector/offset
	mov	word ptr fdrwsec,ax	; remember this block
	mov	word ptr fdrwsec+WORD,dx
	mov	fdrwsecoff,bx		;  and offset within it
	test	bx,bx			; set ZF
;	clc				; no problems
	ret

fdrw_seek_error:
	stc				; we hit unexpected end of chain
	ret				; (shouldn't happen)

;	Read/write partial sector via deblocking code
; On Entry:
;	FDRWSEC = sector address on disk
;	FDRWSECOFF = offset within sector
;	FDRWCNT = byte count for read/write
; On Exit:
;	AX = # of bytes transferred

deblock_rw_npr:
	mov	cx,BF_ISDAT		; CH = no preread, buffer is data
	jmp	deblkrw05

deblock_rw:
;----------
	mov	cx,0FF00h+BF_ISDAT	; CH = preread, buffer is data
deblkrw05:
	mov	dx,word ptr fdrwsec	; set sector to xfer from
;	mov	ah,byte ptr fdrwsec+WORD
	mov	ax,word ptr fdrwsec+WORD
	call	locate_buffer		; ES:SI -> buffer
	mov	bx,fdrwsecoff		; BX = offset within sector
	mov	ax,psecsiz
	mov	dx,ax			; DX = physical sector size
	sub	ax,bx			; AX = bytes left in sector
	cmp	ax,fdrwcnt		; more than we want to transfer?
	 jb	deblkrw10		; yes, only do up to end of sector
	mov	ax,fdrwcnt		; else do up to end of request
deblkrw10:
	mov	cx,ax			; AX, CX = byte count
					; (AX for return, CX for MOVSW)
	push	ds
	test	fdrwflg,1		; check if reading or writing
	 jz	dblkrw30		; skip if writing

	push	es
	les	di,fdrwptr		; destination is user memory
	pop	ds			; source segment is data buffer
	lea	si,BCB_DATA[si+bx]	; DS:SI -> data
	jmp	dblkrw40		; copy the data

dblkrw30:				; we're writing
	or	es:BCB_FLAGS[si],BF_DIRTY; mark buffer as dirty
	lea	di,BCB_DATA[si+bx]	; ES:DI -> data
	lds	si,fdrwptr		; source is user memory

dblkrw40:
	shr	cx,1			; make it a word count
	rep	movsw			; move the words
	 jnc	dblkrw50		; skip if even # of bytes
	movsb				; else move last byte
dblkrw50:
	pop	ds			; restore registers
	ret


;	entry:	BYTEOFF = 32-bit offset into file
;		BLKOFFSET = byte offset within cluster
;		PRVBLK = block in which transfer starts
;		FDRWREQ = requested transfer length

;---------
direct_rw:
;---------
	sub	dx,dx			; assume no extra blocks required
	mov	ax,fdrwreq		; total byte count
	mov	cx,clsize		; get number of bytes
	mov	bx,clsize+2
	sub	cx,blkoffset		; BX:CX = bytes remaining in this block
	sbb	bx,blkoffset+2
	cmp	dx,bx
	 jne	direct_rw03
	cmp	ax,cx
	 je	direct_rw10
direct_rw03:
	sub	ax,cx			; if wholly containined within block
	sbb	dx,bx
;	 jbe	direct_rw10		; then leave it alone
	jnc	direct_rw05
	xor	dx,dx
	jmp	direct_rw10		; then leave it alone
direct_rw05:
;	div	clsize			; else get # of extra clusters
;	push	cx
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
;	pop	cx
	xchg	ax,dx			; DX = clusters, AX = remainder
	or	ax,ax			; round up if any remainder
	 jz	direct_rw10		; skip if even number
	inc	dx			; else one more cluster
direct_rw10:				; DX = # of contiguous clusters req'd
	call	check_cont		; check how many contiguous blocks
;	mov	ax,clsize		; space = cnt * dpbptr->clsize;
;	mul	cx			; AX:DX = # of bytes transferrable
	push	word ptr clsize+2
	push	word ptr clsize
	xor	ax,ax
	push	ax
	push	cx
	sub	sp,8
	call	mul32
	pop	ax
	pop	dx
	add	sp,12
	sub	ax,blkoffset		; BX = skipped bytes in 1st cluster
	sbb	dx,blkoffset+2
					; AX:DX = max # of bytes transferrable
					;    from current position
	test	dx,dx
	 jnz	direct_rw20		; if > 64 K, use up request
	cmp	ax,fdrwreq		; if less than we requested
	 jb	direct_rw30		; then lets do it
direct_rw20:
	xor	dx,dx
	mov	ax,fdrwreq		; else use requested count
direct_rw30:
	div	psecsiz			; AX = # complete sectors
	mov	fdrwdircnt,ax		; save direct sector count
	mov	mult_sec,ax		; set multi sector count
	mul	psecsiz			; AX = bytes to xfer
	push	ax			; save for later

	mov	ax,fdrwoff		; FDRWPTR = disk transfer address
	mov	cur_dma,ax
	mov	ax,fdrwseg
	mov	cur_dma_seg,ax
	mov	ax,word ptr fdrwsec	; set sector to xfer from
	mov	word ptr pblock,ax
	mov	ax,word ptr fdrwsec+WORD
	mov	word ptr pblock+WORD,ax
	mov	rwmode,00000110b	;data read/write
	mov	cl,fdrwflg
	and	cl,1			; CL = read/write flag
	 jz	direct_rw40
	xor	cx,cx			; indicate no retries
	call	read_block		; read in the data
	jmp	direct_rw50
direct_rw40:
	call	write_block		; write out the data
direct_rw50:
	call	SynchroniseBuffers	; synchronize BCBs with direct transfer
	pop	ax			; recover bytes xfered
	push	ds
	pop 	es			; restore ES = SYSDAT
	ret


check_cont:	; check for adjacent blocks or space
;----------
;	entry:	DX = # of extra contiguous blocks req'd
;	exit:	CX = # of contiguous blocks available

;	We first check all adjacent allocated clusters.
;	If we'd like more and we find the end of file
;	and we are writing and the adjacent blocks aren't
;	allocated, then we count them as well and link
;	them into the file.

	mov	di,dx			; save # of blocks req'd
	mov	ax,blk			; current block number
	mov	dx,blk+2
	xor	cx,cx			; contiguous blocks found = 0
	test	di,di			; any extra required ?
	 jz	check_cont20
check_cont10:				; get link of current block
;	push	ax			; save current block
	mov	check_cont_cl,ax	; save current block
	mov	check_cont_cl+2,dx
	push	cx			; save extra blocks so far
	push	di			; save extra blocks we'd like
	call	getnblk			; get the link
	pop	di
	pop	cx
;	pop	bx
;	inc	bx			; BX = current block + 1
	add	check_cont_cl,1		; current block + 1
	adc	check_cont_cl+2,0
;	cmp	ax,bx			; check if next block is contiguous
	cmp	ax,check_cont_cl	; check if next block is contiguous
	 jne	check_cont20		;  and try for another
	cmp	dx,check_cont_cl+2
	 jne	check_cont20
	inc	cx			; extra contiguous cluster
	dec	di			; one less block to check
	 jnz	check_cont10		; try again if we still want more
check_cont20:				; we can do CX extra clusters
	inc	cx			; include 1st cluster too..
	ret


;------------------
SynchroniseBuffers:	; synchronize BCBs after multi sector transfer
;------------------
; On Entry:
;	FDRWSEG:FDRWOFF = transfer address for IO_READ/IO_WRITE
;	FDRWDIRCNT = physical sector count for direct transfer
;	FDRWSEC = sector address for transfer
;	FDWRFLG = even for write, odd for read
; On Exit:
;	direct transfer buffer or BCB updated if BCB overlap
;
;	If any data buffer is found, that falls into the region affected
;	by the direct sector transfer, the following action is performed:
;	If the operation was a read and the sector buffer is clean,
;	no action is required. If it was dirty, the buffer contents is
;	copied to the corresponding location in the DTA buffer.
;	If the operation was a write, the sector buffer is discarded.
;
;
	mov	dx,word ptr fdrwsec
;	mov	ah,byte ptr fdrwsec+WORD
	mov	ax,word ptr fdrwsec+2
;	mov	al,adrive		; get our drive number
	mov	cl,adrive		; get our drive number
	lds	bx,bcb_root		; DS:BX -> 1st buffer
SynchroniseBuffers10:
	test	ds:BCB_FLAGS[bx],BF_ISDAT; is this a data buffer?
	 jz	SynchroniseBuffers30	; skip if directory or FAT
;	cmp	al,ds:BCB_DRV[bx]	; does the drive match?
	cmp	cl,ds:BCB_DRV[bx]	; does the drive match?
	 jne	SynchroniseBuffers30	; skip if different
	mov	si,ds:BCB_REC[bx]	; compute bcb->rec - prec
	sub	si,dx			; result in SI,DI (lsb..msb)
;	mov	cl,ds:byte ptr BCB_REC2[bx]
;	sbb	cl,ah			; get bits 16-23 of result
	mov	di,ds:BCB_REC2[bx]
	sbb	di,ax			; get bits 16-31 of result
	 jne	SynchroniseBuffers30	; skip if bcb->rec < prec
	cmp	si,ss:fdrwdircnt	; else check against transfer length
	 jae	SynchroniseBuffers30	; skip if beyond transfer length

	test	ss:fdrwflg,1		; test direction:  read or write
	 jz	SynchroniseBuffers20	; skip if disk write

	test	ds:BCB_FLAGS[bx],BF_DIRTY; if buffer dirty, did read old data
	 jz	SynchroniseBuffers30	; else data read was valid

	push	ax
	push 	dx			; save record address

	mov	ax,ss:psecsiz		; # of bytes in sector buffer
	push	cx			; save drive number
	mov	cx,ax
	shr	cx,1			; CX = words per sector
	mul	si			; AX = byte offset from start buffer
	add	ax,ss:fdrwoff		; AX = offset
	xchg	ax,di			; DI = offset
	mov	es,ss:fdrwseg		; ES:DI -> data to be replaced
	lea	si,BCB_DATA[bx]
	rep	movsw			; move CX words (one physical sector)
	pop	cx			; restore drive number
	pop	dx
	pop 	ax			; restore record address
	jmp	SynchroniseBuffers30

SynchroniseBuffers20:			; multi sector write
	mov	ds:BCB_DRV[bx],0FFh	; discard this sector
SynchroniseBuffers30:
	mov	bx,ds:BCB_NEXT[bx]
	cmp	bx,ss:word ptr bcb_root
	 jne	SynchroniseBuffers10	; if so stop
	push 	ss
	pop 	ds			; restore DS
	ret

	Public	blockif, ddioif
	
;=======	================================
blockif:	; disk read/write bios interface
;=======	================================
;	entry:	AL = BIOS Request function number
;		ADRIVE = block device to xfer to/from
;		RWMODE = read/write mode
;		CUR_DMA_SEG:CUR_DMA -> xfer address
;		PBLOCK = starting block of xfer
;		MULT_SEC = # blocks to xfer
;	exit:	AX = BX = output

	mov	req_cmd,al
	mov	al,rwmode		; copy rwmode to where the device
	mov	req_rwmode,al		;  driver can get the hint
	mov	ax,cur_dma		; get DMA offset
	push	ax			; (save it)
	and	ax,000Fh		; get offset within paragraph
	mov	req4_buffer,ax		; set transfer offset
	pop	ax			; (restore offset)
	mov	cl,4
	shr	ax,cl			; convert to paragraphs
	add	ax,cur_dma_seg		; add in the segment
	mov	req4_buffer+2,ax	; set transfer segment
	mov	ax,mult_sec		; get requested sector count
	mov	req4_count,ax		; set requested sector count
;------
ddioif:
;------
	push	es
	mov	al,adrive		; get selected drive
	call	get_ddsc		; ES:BX -> DDSC
	mov	ax,word ptr pblock
	mov	dx,word ptr pblock+WORD	; DX:AX = starting block
	push	es
	les	si,es:DDSC_DEVHEAD[bx]	; ES:SI -> device driver
; DOS 4 support
	mov	word ptr req4_bigsector,ax
	mov	word ptr req4_bigsector+2,dx
	mov	req_len,RH4_LEN		; set length of request header
	test	es:DEVHDR.ATTRIB[si],DA_BIGDRV ; large sector number support?
	 jz	blockif10		; no, normal request header
	mov	ax,-1			; indicate we use 32-bit sector number
blockif10:
	mov	req4_sector,ax		; set requested sector address
	pop	es

	call	block_device_driver	; make call to device driver
	 js	blockif20
	xor	ax,ax			; no error
blockif20:
	mov	mult_sec,1		; reset sector count
	mov	bx,ax			; AX, BX = return code
	pop	es
	ret



block_device_driver:
;------------------
;	entry:	ES:BX -> DDSC, req_hdr partly filled in
;	exit:	AX = status after function
;		SF = 1 if error occurred
;	note:	BX preserved

	mov	al,es:DDSC_MEDIA[bx]
	mov	req_media,al		; set current media byte
	mov	al,es:DDSC_RUNIT[bx]	; get relative unit #
	mov	req_unit,al		; set the unit
	push	ds
	push	es
	push	bx
	push	ds
	lds	si,es:DDSC_DEVHEAD[bx]
	pop	es
	mov	bx,offset req_hdr	; ES:BX -> request packet
	call	device_driver		; do operation
	pop	bx
	pop	es
	pop	ds
	ret

;	On Entry:
;		DS:SI		Device Header
;		ES:BX		Current Request Header
;
;	On Exit:
;		AX		Request Header Status
;
device_driver:
;------------
	xor	ax,ax
	mov	es:RH_STATUS[bx],ax	; Initialise return status
	push	es
	push	bx
	push	bp
	call	dword ptr ss:lock_bios	; lock access to BIOS
	push	cs
	call	device_driver10		; fake a callf
	call	dword ptr ss:unlock_bios	; unlock access to BIOS
	pop	bp
	pop	bx
	pop	es
	sti
	cld				; Restore Flags
	mov	ax,es:RH_STATUS[bx]	; Return the Status to the caller
	test	ax,ax			; set SF=1 if error
	ret

device_driver10:
;	push	ds
;	push	ds:DH_INTERRUPT[si]	; interrupt routine address on stack
;	push	ds
;	push	ds:DH_STRATEGY[si]	; strategy routine address on stack
;	retf				; retf to strategy, interrupt, us
	push	ds
	push	si
	push	cs
	mov	ax,offset device_driver11
	push	ax
	push	ds
	push	ds:DEVHDR.STRATEGY[si]	; strategy routine address on stack
	retf				; retf to strategy and device_driver11
device_driver11:
	pop	si
	pop	ds
	push	ds
	push	ds:DEVHDR.INTERRUPT[si]	; interrupt routine address on stack
	retf				; retf to interrupt, us

;	Select drive and check for door open ints
;	Build fdos_hds to refer to the drive

;	Exit:	DL = drive to be selected (0-15)

select_logical_drv:
;------------------
; On Entry:
;	AL = logical drive to select (with change media checks)
; On Exit:
;	ES:BX -> LDT_
;
	cmp	al,last_drv		; is it a legal drive ?
;	 jae	select_drv_bad		;  no, reject it now
	 jb	select_logical_drv05
	 jmp	select_drv_bad		;  no, reject it now
select_logical_drv05:
	mov	logical_drv,al		; save logical drive
	call	get_ldt			; ES:BX -> LDT_ for drive
	 jc	select_physical_drv	; no LDT_ during init, must be physical
	mov	word ptr current_ldt,bx
	mov	word ptr current_ldt+WORD,es
	mov	al,es:byte ptr LDT_FLAGS+1[bx]	; is the drive valid ?
;	test	al,(LFLG_NETWRKD+LFLG_JOINED)/100h
;	 jnz	select_drv_bad		; reject networked/joined drives
	test	al,LFLG_JOINED/100h
	 jnz	select_drv_bad		; reject joined drives
	test	al,LFLG_PHYSICAL/100h
	 jz	select_drv_bad		; reject non-physical drives
	test	al,LFLG_NETWRKD/100h	; skip if networked drive
	 jnz	select_logical_drv30
	mov	al,es:LDT_NAME[bx]	; get the drive from the ascii name
	and	al,1fh			;  as the drive may require rebuilding
	dec	ax			; make it zero based
	push 	es
	push 	bx
	call	select_physical_drv	; select the physical root
	pop 	bx
	pop 	es
	cmp	es:LDT_ROOTLEN[bx],2	; if logical and physical roots
	 jbe	select_logical_drv30	;  are the same we are OK now
ifdef JOIN
	mov	al,es:LDT_DRV[bx]	; should we be on a different
	cmp	al,fdos_hds_drv		;  physical drive ?
	 jne	select_logical_drv10	; if so then we'd better rebuild
endif
	cmp	es:LDT_BLK[bx],0FFFFh	; did we have a media change ?
	 jne	select_logical_drv20	; then we'd better rebuild
	cmp	es:LDT_BLKH[bx],0FFFFh
	 jne	select_logical_drv20
select_logical_drv10:
	call	rebuild_ldt_root	;  the LDT_ root block
select_logical_drv20:
	mov	ax,es:LDT_ROOT[bx]	; get virtual root from LDT
	mov	dx,es:LDT_ROOTH[bx]
	mov	fdos_hds_root,ax	; move there
	mov	fdos_hds_root+2,dx
	mov	fdos_hds_blk,ax
	mov	fdos_hds_blk+2,dx
ifdef JOIN
	mov	al,es:LDT_DRV[bx]	; same with drive
	mov	fdos_hds_drv,al
endif
select_logical_drv30:
	ret

select_physical_drv:
;-------------------
; On Entry:
;	AL = physical drive to select (with change media checks)
; On Exit:
;	None
;
	xor	dx,dx
	mov	fdos_hds_blk,dx		; put it in the root by default
	mov	fdos_hds_blk+2,dx
	mov	fdos_hds_root,dx
	mov	fdos_hds_root+2,dx
	mov	fdos_hds_drv,al		; set physical drive in working HDS
	cmp	al,phys_drv		; should we have a DDSC_ for this drive
	 jae	select_drv_bad		;  no, we can't select it then
	mov	physical_drv,al		; save physical drive number
	call	select_adrive		; no, better select it
	 jc	select_drv_critical_error
	ret

select_drv_bad:
;--------------
; An attempt has been made to select a bad drive,
; return a logical error "invalid drive"
	mov	ax,ED_DRIVE		; ED_DRIVE "invalid drive"
	jmp	fdos_error

select_drv_critical_error:
;-------------------------
; The drive is logically correct, so all error at this point must
; be physical ones - so we want a critical error
	jmp	generate_critical_error

select_adrive:
;-------------
; This entry is called to physically select a drive (eg. when flushing buffers)
; It does not alter the current physical_drv setting, which must be re-selected
; afterwards by the caller.
;
; On Entry:
;	AL = disk to select (range validated)
; On Exit:
;	CY set if a problem selecting the drive

	mov	adrive,al
	mov	err_drv,al		; save error drive
	call	get_ddsc		; ES:BX -> DDSC_ for drive
	mov	al,1			; AL = "Unknown Unit"
	 jc	select_drv_err		;  error if no DDSC_
	mov	ax,es:word ptr DDSC_DEVHEAD[bx]
	mov	word ptr error_dev+0,ax
	mov	ax,es:word ptr DDSC_DEVHEAD+2[bx]
	mov	word ptr error_dev+2,ax
	push	es			; remember driver address for error's
	push	bx			; preserve DDSC_
	call	check_media		; see if media has changed
	pop	bx			; restore DDSC_
	pop	es
	 jc	select_drv_err

;	select the disk drive and fill the drive specific variables
;	entry:	ES:BX -> DDSC_ of disk to select
;		AX <> 0 if drive requires BPB rebuilt
;	exit:	CY flag set on error

	test	ax,ax			; device driver, new select?
	 jz	select_ddsc		; use current DDSC if old select
	call	build_ddsc_from_bpb	; else get BPB and build new DDSC
	 jc	select_drv_err		; carry flag reset
	call	select_ddsc		; use to DDSC for select
ifdef DELWATCH
	mov	ah,DELW_NEWDISK		; we have a new disk so I guess
	mov	al,physical_drv		;  I'd better tell delwatch
	les	bx,current_ddsc		;  about the new disk so it
	call	dword ptr fdos_stub	;  knows to update itself
endif
	clc				;select disk function ok
	ret

select_drv_err:
; On Entry:
;	AL = extended error code
;	CY set
;
	mov	ioexerr,al		; save error code
	ret


select_ddsc:
;-----------
; On Entry:
;	ES:BX -> DDSC_ of drive to be selected
	mov	word ptr current_ddsc,bx
	mov	word ptr current_ddsc+WORD,es
	push 	ds
	push 	es
	pop 	ds
	pop 	es			; swap ES and DS
	lea	si,DDSC_SECSIZE[bx]	; DS:SI -> DDSC_ original
	mov	di,offset local_ddsc	; ES:DI -> DDSC_ copy
	mov	cx,LOCAL_DDSC_LEN
	rep	movsb			; make a local copy of interesting bits
	cmp	ds:DDSC_NFATRECS[bx],0	; is it a 32 bit FAT ?
	 je	select_ddsc04		; yes, then also copy extended DDSC
	mov	ax,es:datadd		; these values are used as 32-bit
	mov	es:bdatadd,ax
	mov	ax,es:lastcl
	mov	es:blastcl,ax
	xor	ax,ax
	mov	es:bdatadd+2,ax
	mov	es:blastcl+2,ax
	jmp	select_ddsc05
select_ddsc04:
	lea	si,DDSC_BDATADDR[bx]
	mov	di,offset local_ddsc2
	mov	cx,LOCAL_DDSC2_LEN
	rep	movsb			; more interesting bits to copy
select_ddsc05:
;	push 	es ! pop ds		; DS=ES=local data segment
	push 	ds
	push 	es
	pop 	ds
	pop 	es			; swap ES and DS
;	mov	ax,psecsiz		; now initialise some other vaiiables
;	mov	cl,clshf
;	shl	ax,cl			; AX = bytes per cluster
;	mov	clsize,ax
	xor	ax,ax
	mov	al,clmsk
	inc	ax			; AX = sectors per cluster
	mov	secperclu,ax
	mul	psecsiz			; DX:AX byte size of cluster
	mov	clsize,ax
	mov	clsize+2,dx
	xor	ax,ax
	mov	al,byte_nfats		; AX = number of FATs
	mov	nfats,ax		;  (it's handier as a word
;	mov	ax,diradd		; number of FAT records can be
;	sub	ax,fatadd		;  bigger than 255 
;	xor	dx,dx
;	div	nfats
	cmp	es:DDSC_NFATRECS[bx],0	; is it a 32 bit FAT ?
	 je	select_ddsc10		; yes, then use 32-bit value
	mov	ax,es:word ptr DDSC_NFATRECS[bx]	; # of sectors per FAT
	mov 	nfatrecs,ax
	xor	ax,ax
	mov	nfatrecs+2,ax
	jmp	select_ddsc20
select_ddsc10:
	mov	ax,es:word ptr DDSC_BFATRECS[bx]	; # of sectors per FAT
	mov 	nfatrecs,ax
	mov	ax,es:word ptr DDSC_BFATRECS+2[bx]
	mov 	nfatrecs+2,ax
select_ddsc20:
	mov	cx,FCBLEN
	mov	ax,clsize		; convert from cluster size
;	xor	dx,dx			;  to number of dir entries
	mov	dx,clsize+2		;  to number of dir entries
	div	cx			;  per cluster - handy for
	mov	dirperclu,ax		;  subdirectories
	mov	ax,FAT32
	cmp	es:DDSC_NFATRECS[bx],0	; is it a 32 bit FAT ?
	 je	select_ddsc30
	mov	ax,FAT12
	cmp	lastcl,MAX12		; is it a 12 bit FAT ?
	 jbe	select_ddsc30
	mov	ax,FAT16		; no, it's 16 bit
select_ddsc30:
	mov	dosfat,ax		; remember which for later
	clc				; drive all selected
	ret





build_ddsc_from_bpb:	; call device driver to build BPB, convert to DDSC_
;-------------------
;	On Entry:
;		ES:BX -> DDSC_ to rebuild
;	On Exit:
;		ES:BX preserved
;		CY set on error
;		AL = error code

	push	es
	push	bx			; save DDSC_ address
	xor	di,di
	mov	ax,deblock_seg
	mov	es,ax			; ES:DI -> deblock seg
	test	ax,ax			; if we are deblocking spare buffer
	 jnz	build_bpb10		;  might be in high memory
	dec	ax			; AX = FFFF
	mov	dx,ax			; compute impossible record #
	mov	cx,BF_ISDIR		; locate directory sector w/o preread
	call	locate_buffer		; this will find the cheapest buffer
	mov	es:BCB_DRV[si],0FFh	; don't really want this...
	lea	di,BCB_DATA[si]		; ES:DI -> disk buffer
build_bpb10:
	mov	req4_buffer,di		; xfer to ES:DI
	mov	req4_buffer+2,es
	pop	bx			; restore DDSC_ address
	pop	es

	push	ds
	lds	si,es:DDSC_DEVHEAD[bx]	; DS:SI -> device header
	mov	ax,ds:DEVHDR.ATTRIB[si]	; non-FAT ID driver ("non-IBM") bit
	pop	ds			;   in device header attributes
	test	ax,DA_NONIBM
	 jnz	bldbpb30		; skip if media byte in FAT not used

	mov	req_rwmode,0		; read of system area
	mov	req_len,RH4_LEN		; set length field
	mov	req_cmd,CMD_INPUT	; read first FAT sector off disk
	test	ax,DA_BIGDRV		; large sector numbers ?
	mov	ax,1
	mov	req4_count,ax		; read 1st FAT sector
	cwd				; DS:AX = sector 1
	mov	word ptr req4_bigsector,ax
	mov	word ptr req4_bigsector+2,dx
	 jz	bldbpb20
	dec 	ax
	dec 	ax			; AX = 0FFFFh
bldbpb20:
	mov	req4_sector,ax		; set requested sector address
	mov	req4_sector+2,dx	; (support large DOS drives)
	call	block_device_driver	; try to read FAT sector, AX = status
	 js	bldbpb_err		; skip if errors (AX negative)
bldbpb30:
	mov	req_len,RH2_LEN		; length of req
	mov	req_cmd,CMD_BUILD_BPB	; "build bpb"
	call	block_device_driver	; call the device driver
	 js	bldbpb_err		; skip if errors (AX negative)
	push	ds
	push	es
	push	bx
	mov	di,bx			; ES:DI -> DDSC_ to initialise
	lds	si,dword ptr req2_bpb	; DS:SI -> BPB to convert
	call	bpb2ddsc		; rebuild the DDSC_
	pop	bx
	pop	es
	pop	ds
	clc				; success - we have a new DDSC_
	ret


bldbpb_err:
	stc				; we had a problem
	ret



;-----------
check_media:	; check media if DPH media flag set
;-----------
; On Entry:
;	ES:BX -> DDSC_ of physical drive to check
; On Exit:
;	CY set on error, AX = error code
;	else
;	AX <> 0 if disk requires BPB rebuild
;	If definite/possible change then LDT's marked as invalid
;	If possible then buffers/hashing discarded provided they are clean
;	If definite then all buffers/hashing for drive discarded even if dirty
;
	mov	req_len,RH1_LEN		; set length field
	mov	req_cmd,CMD_MEDIA_CHECK	; media check routine
	call	block_device_driver	; call the device driver
	 jns	chkmed10
	stc				; we have a problem, generate
	ret				;  an error
chkmed10:
	mov	al,req_media+1		; else get returned value
	xor	ah,ah			;  watch out for 1st access too..
	xchg	ah,es:DDSC_FIRST[bx]	; treat never accessed as changed
	cmp	al,1			; 1 = no change
	 jne	chkmed20
	dec	ax			; AL=0, build bpb only if DDSC_FIRST
;	clc				; it all went OK
	ret

chkmed20:
	mov	dl,adrive		; media may have/has changed
	call	mark_ldt_unsure		;  so force LDT's to unsure
	
; AL = 00 if maybe changed, FF for definitely changed
	test	al,al
	 jz	chkmed_maybe		; media may have changed

chkmed_changed:				; disk has changed for sure
	call	discard_files		; discard open files
	jmp	chkmed30		; discard buffers, build bpb required

chkmed_maybe:				; disk has possibly changed
	call	discard_dir		; we can always discard dir as they
	mov	ah,BF_DIRTY		;  won't be dirty
	mov	al,adrive
	call	buffers_check		; any dirty buffers on adrive?
	 jnz	chkmed40		; yes, can't discard FAT
chkmed30:
	call	discard_all		; discard buffers for drive
chkmed40:
	or	ax,0FFFFh		; better rebuild bpb
;	clc
	ret


	Public	mark_ldt_unsure

mark_ldt_unsure:
;---------------
; On Entry:
;	DL = physical drive
; On Exit:
;	All corresponding LDT's marked as unsure
;	All reg preserved
;
	push	es
	push	ax
	push	bx
	xor	ax,ax			; start with drive A:
mlu10:
	call	get_ldt_raw		; ES:BX -> LDT_
	 jc	mlu30			; CY = no more LDT's
	test	es:LDT_FLAGS[bx],LFLG_NETWRKD+LFLG_JOINED
	 jnz	mlu20			; if networked leave it alone
	cmp	dl,es:LDT_DRV[bx]	; does the physical drive match ?
	 jne	mlu20
	mov	es:LDT_BLK[bx],0FFFFh	; indicate we shouldn't trust BLK
	mov	es:LDT_BLKH[bx],0FFFFh
mlu20:
	inc	ax			; onto next LDT
	jmp	mlu10
mlu30:
	pop	bx
	pop	ax
	pop	es
	ret

;-----------
write_block:
;-----------
;	entry:	RWMODE = write type
;			bit 0:
;			  1 - write, not read
;			bits 2-1 (affected disk area)
;			0 0 - system area
;			0 1 - FAT area
;			1 0 - root or sub directory
;			1 1 - data area

	or	rwmode,1		; mark it as a write
	xor	cx,cx			; indicate no second attempt
	mov	al,CMD_OUTPUT		; assume normal write
	cmp	verify_flag,0		; is verify on ?
	 je	rdwr_block
	mov	al,CMD_OUTPUT_VERIFY	; assume use write w/ verify
	jmp	rdwr_block

;----------
read_block:
;----------
;	entry:	RWMODE = read type
;			bit 0:
;			  0 - read, not write
;			bits 2-1 (affected disk area)
;			0 0 - system area
;			0 1 - FAT area
;			1 0 - root or sub directory
;			1 1 - data area
;		CX <> 0	if FAT retry possible (critical error should then
;			be avoided)
;	exit:	SF = 0 if success
;		SF = 1 if failure (CX was non-zero on call)

	and	rwmode,not 1		;mark it as a read
	mov	al,CMD_INPUT
rdwr_block:
	push	cx
	call	blockif			;current drive, track,....
	pop	cx
	 jns	rdwrb5
	jcxz	rdwrb10			; test if any disk error detected
rdwrb5:
	ret				; skip if yes
rdwrb10:
	mov	ioexerr,al		; save extended error
	test	al,al			; is it write protect error ?
	 jnz	rdwrb20			;  we have dirty buffers we can't write
	call	discard_dirty		;  out, so throw 'em away
rdwrb20:
	mov	al,adrive		; if error on different drive
	cmp	al,physical_drv		;  treat error as media change
	 je	generate_critical_error	; if same drive, report error
	call	discard_all		; discard all buffers on drive
	call	discard_files		;  and flush files
	jmp	fdos_restart		; try to restart the instruction

generate_critical_error:
;-----------------------
; On Entry:
;	err_drv, rwmode, ioexerr set up
; On Exit:
;	None - we don't come back
;
	mov	al,ioexerr		; AL = BIOS error return byte
	cbw				;  make it a word
	cmp	ax,15			; only handle sensible errors
	 jb	gen_crit_err10		;  anything else becomes
	mov	ax,12			;  general failure
gen_crit_err10:
	neg	ax			; convert to our negative errors
	add	ax,ED_PROTECT		;  and start with write protect
	jmp	fdos_error		;  now return with error


clus2sec:		; convert from cluster/offset to sector/offset
;--------
; On Entry:
;	DX:AX = cluster
;	CX:BX = byte offset in cluster
; On Exit:
;	DX:AX = sector
;	BX = byte offset in sector
;
;	xchg	ax,cx			; remember cluster in CX
	sub	ax,2			; minus 2 reserved clusters
	sbb	dx,0
	push	dx			; save cluster on stack
	push	ax
;	xor	dx,dx
	xchg	dx,cx
	xchg	ax,bx			; DX:AX = byte offset
	div	psecsiz			; AX = sector offset, DX = byte offset
	mov	bx,dx			; BX = byte offset in sector
;	xchg	ax,cx			; AX = cluster, CX = sector offset
	mov	cx,ax			; CX = sector offset
;	dec	ax
;	dec	ax			; forget about 2 reserved clusters
;	mul	secperclu		; DX:AX = offset of cluster
	xor	ax,ax			; sectors per cluster
	push	ax
	push	secperclu
	sub	sp,8			; reserve space for product
	call	mul32			; multiply cluster with sectors per cluster
	pop	ax			; DX:AX = sector number
	pop	dx
	add	sp,12			; clean up stack
;	add	ax,datadd
;	adc	dx,0			; DX:AX = offset of start of dir
	add	ax,bdatadd
	adc	dx,bdatadd+2			; DX:AX = offset of start of dir
	add	ax,cx			; DX:AX - add in sector offset
	adc	dx,0
	ret

div64:					; 64-bit division
;--------
; On Entry:
;	64-bit dividend & 32-bit divisor on stack
;	space for 32-bit quotient & remainder reserved on stack
;	SP-20
; On Exit:
;	32-bit quotient & remainder on stack
;	SP-20
; Modified registers:
;	AX,CX,DX,BP,SI
	mov	bp,sp			; base address of temporary variables
	xor	ax,ax			; clear work registers
	cmp	word ptr [bp+2+18],ax	; revert to div32 if highest 32 bits
	jne	div_need64		; of dividend are zero
	cmp	word ptr [bp+2+16],ax
	 je	div32
div_need64:
	xor	dx,dx
	xor	si,si
	mov	cx,64			; 64 bits
div64_loop:
	shl	word ptr 2+4[bp],1	; multiply quotient with two
	rcl	word ptr 2+6[bp],1
	shl	word ptr 2+12[bp],1	; shift one bit from dividend
	rcl	word ptr 2+14[bp],1
	rcl	word ptr 2+16[bp],1
	rcl	word ptr 2+18[bp],1
	rcl	ax,1			; to work registers
	rcl	dx,1
	rcl	si,1
	cmp	si,0			; larger than divisor?
	 jne	div64_1
	cmp	dx,2+10[bp]		; compare second word with divisor
	 jb	div64_2
	 ja	div64_1
	cmp	ax,2+8[bp]		; compare first word
	 jb	div64_2
div64_1:
	or	word ptr 2+4[bp],1	; divisor fits one time
	sub	ax,2+8[bp]		; subtract divisor
	sbb	dx,2+10[bp]
	sbb	si,0
div64_2:
	loop	div64_loop		; loop back if more bits to shift
	mov	2[bp],ax		; save remainder onto stack
	mov	2+2[bp],dx
	ret

div32:					; 32-bit division
;--------
; On Entry:
;	32-bit dividend & divisor on stack
;	space for 32-bit quotient & remainder reserved on stack
;	SP-16
; On Exit:
;	32-bit quotient & remainder on stack
;	SP-16
; Modified registers:
;	AX,CX,DX,BP
	mov	bp,sp			; base address of temporary variables
	xor	dx,dx
	cmp	2+10[bp],dx		; if divisor high != 0 => 32bit div
	 jne	div32_full
	mov	cx,2+8[bp]		; CX <- divisor low
	mov	2+2[bp],dx		; clear remainder high, guaranteed to
					; ...be zero here
	mov	ax,2+14[bp]		; AX <- dividend high
	test	ax,ax			; if both dividend and divisor are
					; ...16bit, perform one 16bit division
	 jz	div16			; ...else perform two 16bit divisions
	div	cx			; divide dividend high by divisor low
div16:	mov	2+6[bp],ax		; 6[bp] <- quotient high
	mov	ax,2+12[bp]		; AX <- dividend low
	div	cx			; divide dividend low by divisor low
					; ...DX -> remainder of previous
					; ...      division or zero
	mov	2[bp],dx		; store remainder low
	mov	2+4[bp],ax		; store quotient low
	ret
div32_full:
	xor	ax,ax			; clear registers, DX cleared above
	mov	cx,32			; 32 iterations (bits)
div32_loop:
	shl	word ptr 2+4[bp],1	; multiply quotient with two
	rcl	word ptr 2+6[bp],1
	shl	word ptr 2+12[bp],1	; shift one bit from dividend
	rcl	word ptr 2+14[bp],1
	rcl	ax,1			; to work registers
	rcl	dx,1
	cmp	dx,2+10[bp]		; compare high word with divisor
	 jb	div32_2
	 ja	div32_1
	cmp	ax,2+8[bp]		; compare low word
	 jb	div32_2
div32_1:
	or	word ptr 2+4[bp],1	; divisor fits one time
	sub	ax,2+8[bp]		; subtract divisor
	sbb	dx,2+10[bp]
div32_2:
	loop	div32_loop		; loop back if more bits to shift
	mov	2[bp],ax		; save remainder onto stack
	mov	2+2[bp],dx
	ret


mul64:					; 64-bit multiplication
;--------
; On Entry:
;	64-bit factors on stack
;	space for 128-bit product reserved on stack
;	SP-32
; On Exit:
;	64-bit product on stack
;	SP-32
;	Carry flag set if result does not fit in quad word
; Modified registers:
;	AX,BX,CX,DX
	push	es			; save ES
	push	bp			; save BP
	push	si			; save SI
	push	di			; save DI
	push	ss
	pop	es
	mov	bp,sp			; base address of temporary variables
	add	bp,10
	mov	di,bp			; clear result
	xor	ax,ax
	mov	cx,4
	cld
	rep	stosw
	xor	si,si			; start with lowest words of factors
mul64_10:
	xor	di,di
mul64_20:
	mov	bx,si			; compute offset in result
	add	bx,di
	add	bx,4
	mov	cx,16			; number of carry additions left
	sub	cx,bx
	shr	cx,1			; / 2 = number of word additions
	mov	ax,16[bp+si]		; multiply two words
	mul	word ptr 24[bp+di]
	xchg	bx,di
	add	[bp+di-4],ax		; and add the product to the result
	adc	[bp+di-2],dx
	jcxz	mul64_40		; skip if highest words
mul64_30:
	jnc	mul64_40		; no carry, so no further adds needed
	adc	word ptr [bp+di],0	; otherwise add zero
	inc	di
	inc	di
	loop	mul64_30		; until no carry left over
mul64_40:
	xchg	bx,di
	inc	di			; next word in first factor
	inc	di
	cmp	di,6			; already highest word?
	 jbe	mul64_20		; next multiplication
	inc	si			; next word in second factor
	inc	si
	cmp	si,6			; already highest word?
	 jbe	mul64_10		; next multiplication
	mov	cx,4			; check if results fits in 64 bits
	xor	si,si
mul64_45:
	cmp	word ptr 8[bp+si],0	; zero?
	 jnz	mul64_50		; if not, then skip and set carry
	inc	si			; next word to compare
	inc	si
	loop	mul64_45		; until highest dword has been checked
	jmp	mul64_60		; 64-bit result
mul64_50:
	stc
mul64_60:
	pop	di			; restore DI again
	pop	si			; restore SI
	pop	bp			; restore BP
	pop	es			; restore ES
	ret

mul32:					; 32-bit multiplication
;--------
; On Entry:
;	32-bit factors on stack
;	space for 64-bit product reserved on stack
;	SP-16
; On Exit:
;	64-bit product on stack
;	SP-16
;	Carry flag set if result does not fit in double word
; Modified registers:
;	AX,DX
	push	bp			; save BP
	mov	bp,sp			; base address of temporary variables
	mov	ax,4+10[bp]		; multiply high word of factors
	mul	word ptr 4+14[bp]
	mov	4+4[bp],ax		; store result
	mov	4+6[bp],dx
	mov	ax,4+10[bp]		; multiply high word of first factor with low word of second
	mul	word ptr 4+12[bp]
	mov	4+2[bp],ax		; add result to previous
	add	4+4[bp],dx
	adc	word ptr 4+6[bp],0
	mov	ax,4+8[bp]		; multiply low word of first factor with high word of second
	mul	word ptr 4+14[bp]
	add	4+2[bp],ax		; add result to previous
	adc	4+4[bp],dx
	adc	word ptr 4+6[bp],0
	mov	ax,4+8[bp]		; multiply low word of first factor with low word of second
	mul	word ptr 4+12[bp]
	mov	4[bp],ax		; add result
	add	4+2[bp],dx
	adc	word ptr 4+4[bp],0
	adc	word ptr 4+6[bp],0
	cmp	word ptr 4+4[bp],0	; 64-bit result?
	 jnz	mul32_1			; yes
	cmp	word ptr 4+6[bp],0
	 jz	mul32_2			; no
mul32_1:
	stc				; yes, set carry flag to indicate this
mul32_2:
	pop	bp			; restore BP again
	ret

	public	read_tsc
read_tsc:
	push	dx
	push	ax
	db	0fh,31h			; RDTSC
	db	66h			; MOV lasttsc+4,EDX
	mov	lasttsc+4,dx
	db	66h			; MOV lasttsc,EAX
	mov	lasttsc,ax
	pop	ax
	pop	dx
	ret

	public	diff_tsc
diff_tsc:
	push	dx
	push	cx
	push	bx
	push	ax
	db	0fh,31h			; RDTSC
	db	66h			; MOV ECX,lasttsc+4
	mov	cx,lasttsc+4
	db	66h			; MOV EBX,lasttsc
	mov	bx,lasttsc
	db	66h			; SUB EAX,EBX
	sub	ax,bx
	db	66h			; SBB EDX,ECX
	sbb	dx,cx
	cmp	tscsel,0
	 je	diff_tsc10
	db	66h
	push	dx
	db	66h
	push	ax
	mov	dx,tscsel
	call	output_hex
	db	66h
	pop	ax
	db	66h
	pop	dx
	db	66h
	xor	bx,bx
	mov	bx,tscsel
	dec	bx
	shl	bx,1
	shl	bx,1
	shl	bx,1
	db	66h
	add	tsc1[bx],ax
	db	66h
	adc	tsc1+4[bx],dx
	db	66h
	mov	ax,tsc1[bx]
	db	66h
	mov	dx,tsc1+4[bx]
diff_tsc10:
	db	66h			; PUSH EAX
	push	ax
	db	66h			; PUSH EDX
	push	dx
	pop	ax
	pop	dx
	call	output_hex
	xchg	ax,dx
	call	output_hex
	pop	ax
	pop	dx
	call	output_hex
	xchg	ax,dx
	call	output_hex
	pop	ax
	pop	bx
	pop	cx
	pop	dx
	ret

	public	output_msg
output_msg:
;----------------
; On Entry:
;	si = offset CGROUP:message_msg
; On Exit:
;	None
	push	ax
	push	bx
	lodsb				; get 1st character (never NULL)
output_msg10:
	mov	ah,0Eh
	mov	bx,7
	int	10h			; TTY write of character	
	lodsb				; fetch another character
	test	al,al			; end of string ?
	 jnz	output_msg10
	pop	bx
	pop	ax
	ret

	public	output_hex
output_hex:
;----------------
; On Entry:
;	dx = 2 byte hex value
; On Exit:
;	None
; Used Regs:
;	ax,bx,cx,dx,si
	push	ax
	push	bx
	push	cx
	push	si
	push	ds
	mov	cx,4
	mov	ah,0eh
	mov	bx,7
output_hex10:
	mov	al,dh
	push	cx
	mov	cl,4
	shr	al,cl
	pop	cx
	and	al,0fh
	cmp	al,09h			; greater 0-9?
	jg	output_hex20
	add	al,30h
	jmp	output_hex30
output_hex20:
	add	al,37h
output_hex30:
	int	10h
	push	cx
	mov	cl,4
	shl	dx,cl
	pop	cx
	loop	output_hex10
	push	cs
	pop	ds
ASSUME DS:PCMCODE
	lea	si,output_hex40
	call	output_msg
ASSUME DS:PCMDATA
	pop	ds
	pop	si
	pop	cx
	pop	bx
	pop	ax
	ret
output_hex40	db	20h,0		; end of string

BDOS_CODE	ends

	end
