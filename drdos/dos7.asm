; DOS7.ASM - Functions for DOS 7 compatibility
;
; This file is part of
; The DR-DOS/OpenDOS Enhancement Project - http://www.drdosprojects.de
; Copyright (c) 2002-2004 Udo Kuhnt

	include	pcmode.equ
	include	fdos.equ
	include	fdos.def
	include	dos7.equ

PCM_CODE	cseg	byte

	extrn	get_path_drive:near
	extrn	fdos_diskinfo:near
	extrn	fdos_nocrit:near
	extrn	mul32:near
	extrn	return_AX_CLC:near
	extrn	error_exit:near
	extrn	get_dseg:near

	public	func73
func73:
	cmp	al,2			; function 7302h?
	 je	func7302		; yes
	cmp	al,3			; function 7303h?
	 jne	f73_10
	jmp	func7303		; yes
f73_10:
	cmp	al,5			; function 7305h?
	 jne	func73_error
	jmp	func7305		; yes
func73_error:
	mov	ax,7300h		; function not supported
	clc
	ret

;	*************************************
;	***    DOS Function 7302h         ***
;	***    Get Extended DPB           ***
;	*************************************
;
;Entry:	DL	= drive number
;	ES:DI	= pointer to buffer for Extended DPB structure
;	CX	= length of buffer
;Exit:	ES:DI	preserved
;	CF clear
;Error:	CF set
;	AX	= error code

func7302:
	cmp	cx,EDPB_LEN+2		; enough buffer space for data?
	 jae	f7302_10
	mov	ax,18h			; return 18h (bad request structure length)
	stc
	jmp	error_exit		; no, then exit with error
f7302_10:
	xor	dh,dh
	call	fdos_DISKINFO		; get drive info, ES:BX -> DDSC
	 jnc	f7302_20
	mov	ax,0fh			; return 0fh (invalid drive)
	stc
	jmp	error_exit		; error if invalid drive
f7302_20:
	push	ds
	lds	bp,int21regs_ptr	; DS:DI -> Extended DPB structure
	mov	di,ds:reg_DI[bp]
	mov	si,ds:reg_SI[bp]	; SI = signature
	mov	ds,ds:reg_ES[bp]
	mov	word ptr [di],EDPB_LEN	; length of data
	inc	di			; skip to begin of EDPB
	inc	di
	push	ds
	push	es
	pop	ds
	pop	es			; ES:DI -> EDPB, DS:BX -> DDSC
	push	si
	push	di
	mov	si,bx			; copy standard DPB from DDSC
	mov	cx,DDSC_BFREE
	rep	movsb
	pop	di
	pop	si
	xor	dh,dh
	mov	es:EDPB_DPBFLAGS[di],dh	; clear DBP flags
	cmp	si,0f1a6h		; check signature
	 je	f7302_25
	xor	ax,ax			; wrong signature, clear driver header and link address fields
	dec	ax
	mov	es:word ptr EDPB_DEVHEAD[di],ax
	mov	es:word ptr EDPB_DEVHEAD+2[di],ax
	mov	es:word ptr EDPB_LINK[di],ax
	mov	es:word ptr EDPB_LINK+2[di],ax
f7302_25:
	lea	si,ds:DDSC_BFREE[bx]
	mov	cx,DDSC_FSVER-DDSC_BFREE
	cmp	ds:DDSC_DIRENT[bx],0	; is this a FAT32 drive?
	 jnz	f7302_30		; no, then build the remaining portion from scratch
	add	di,DDSC_FREE
	rep	movsb			; else copy remaining EDPB portion from DDSC
	jmps	f7302_40
f7302_30:
	push	di
	add	di,DDSC_FREE
	xor	al,al			; zero contents of remaining EDPB part
	rep	stosb
	pop	di
	xor	ax,ax			; AX=FFFFh
	dec	ax
	mov	es:EDPB_FSINFO[di],ax	; then fill in the 16-bit values
	mov	es:EDPB_BOOTBAK[di],ax
	mov	ax,word ptr DDSC_DATADDR[bx]
	mov	es:word ptr EDPB_BDATADDR[di],ax
	mov	ax,word ptr DDSC_NCLSTRS[bx]
	mov	es:word ptr EDPB_BCLSTRS[di],ax
	mov	ax,word ptr DDSC_NFATRECS[bx]
	mov	es:word ptr EDPB_BFATRECS[di],ax
	mov	ax,word ptr DDSC_BLOCK[bx]
	mov	es:word ptr EDPB_BBLOCK[di],ax
f7302_40:
	pop	ds
	xor	ax,ax
	call	return_AX_CLC
	clc
f7302_exit:
	ret

;	*************************************
;	***    DOS Function 7303h         ***
;	***    Extended Free Disk Space   ***
;	*************************************
;
;Entry:	DS:DX	= pointer to ASCIZ string for path
;	ES:DI	= pointer to buffer for extended free space structure
;	CX	= length of buffer
;Exit:	ES:DI	preserved
;	CF clear
;Error:	CF set
;	AX	= error code

func7303:
	les	bp,int21regs_ptr	; ES:DI = pointer to drive path
	mov	di,es:reg_DX[bp]
	mov	es,es:reg_DS[bp]
	call	get_path_drive
	 jnc	f7303_10
	mov	ax,0fh			; return 0fh (invalid drive)
	stc
	jmp	error_exit		; error if invalid drive
f7303_10:
	mov	dl,al			; drive number
	inc	dl
	xor	dh,dh
	call	fdos_DISKINFO		; get drive info, ES:BX -> DDSC
	 jnc	f7303_20
	mov	ax,0fh			; return 0fh (invalid drive)
	stc
	jmp	error_exit		; error if invalid drive
f7303_20:
	cmp	cx,FREED_LEN		; enough buffer space for data?
	 jbe	f7303_30
	mov	ax,18h			; return 18h (bad request structure length)
	stc
	jmp	error_exit		; no, then exit with error
f7303_30:
	push	ds
	lds	bp,int21regs_ptr	; DS:DI -> free space structure
	mov	di,ds:reg_DI[bp]
	mov	ds,ds:reg_ES[bp]
	xor	dx,dx
	mov	ax,FREED_LEN		; length of data
	mov	FREED_SIZE[di],ax
	xor	ax,ax			; structure version
	mov	FREED_VER[di],ax
	xor	ah,ah			; sector per cluster
	mov	al,es:DDSC_CLMSK[bx]	; this is minus one
	inc	ax			; so add one again
	mov	word ptr FREED_SECPCLUS[di],ax
	mov	word ptr FREED_SECPCLUS+2[di],dx
	mov	ax,es:DDSC_SECSIZE[bx]	; bytes per sector
	mov	word ptr FREED_BYTEPSEC[di],ax
	mov	word ptr FREED_BYTEPSEC+2[di],dx
	cmp	es:DDSC_DIRENT[bx],0	; is this a FAT32 drive?
	 je	f7303_40		; yes
	mov	ax,es:DDSC_FREE[bx]	; free clusters on drive (16-bit)
	mov	word ptr FREED_FREECL[di],ax
	mov	word ptr FREED_FREEPCL[di],ax
	mov	word ptr FREED_FREECL+2[di],dx
	mov	word ptr FREED_FREEPCL+2[di],dx
	mov	ax,es:DDSC_NCLSTRS[bx]	; highest cluster on drive (16-bit)
	dec	ax			; total clusters (16-bit)
	mov	word ptr FREED_NCLUSTER[di],ax
	mov	word ptr FREED_NPCLUS[di],ax
	mov	word ptr FREED_NCLUSTER+2[di],dx
	mov	word ptr FREED_NPCLUS+2[di],dx
	jmps	f7303_50
f7303_40:
	mov	ax,es:word ptr DDSC_BFREE[bx]	; free clusters on drive (32-bit)
	mov	word ptr FREED_FREECL[di],ax
	mov	word ptr FREED_FREEPCL[di],ax
	mov	ax,es:word ptr DDSC_BFREE+2[bx]
	mov	word ptr FREED_FREECL+2[di],ax
	mov	word ptr FREED_FREEPCL+2[di],ax
	mov	ax,es:word ptr DDSC_BCLSTRS[bx]	; highest cluster on drive (32-bit)
	mov	dx,es:word ptr DDSC_BCLSTRS+2[bx]
	sub	ax,1				; total clusters (32-bit)
	sbb	dx,0
	mov	word ptr FREED_NCLUSTER[di],ax
	mov	word ptr FREED_NPCLUS[di],ax
	mov	word ptr FREED_NCLUSTER+2[di],dx
	mov	word ptr FREED_NPCLUS+2[di],dx
f7303_50:
	push	word ptr FREED_FREEPCL+2[di]	; number of free physical clusters
	push	word ptr FREED_FREEPCL[di]
	push	word ptr FREED_SECPCLUS+2[di]	; number of sectors per cluster
	push	word ptr FREED_SECPCLUS[di]
	sub	sp,8			; reserve space on stack
	call	mul32			; multiply these values
	pop	ax			; to get free physical sectors
	mov	word ptr FREED_FREESEC[di],ax
	pop	ax
	mov	word ptr FREED_FREESEC+2[di],ax
	add	sp,12			; clean up the stack again
	push	word ptr FREED_NPCLUS+2[di]	; number of total physical clusters
	push	word ptr FREED_NPCLUS[di]
	push	word ptr FREED_SECPCLUS+2[di]	; number of sectors per cluster
	push	word ptr FREED_SECPCLUS[di]
	sub	sp,8			; reserve space on stack
	call	mul32			; multiply these values
	pop	ax			; to get total physical sectors
	mov	word ptr FREED_NSECS[di],ax
	pop	ax
	mov	word ptr FREED_NSECS+2[di],ax
	add	sp,12			; clean up the stack again
	pop	ds
	xor	ax,ax
	call	return_AX_CLC
	clc
f7303_exit:
	ret

;	*************************************
;	***    DOS Function 7305h         ***
;	***    Extended Disk Read/write   ***
;	*************************************
;
;Entry:	DL	= drive number
;	DS:BX	= pointer to disk address packet
;	CX	= FFFFh
;	SI	= read/write mode
;Exit:	CF clear
;Error:	CF set
;	AX	= error code

func7305:
	cmp	cx,0ffffh		; is CX=FFFFh given?
	 je	f7305_10		; yes
	mov	ax,57h			; if not, return 18h (invalid parameter)
	stc
	jmp	f7305_exit		; no, then exit with error
f7305_10:
	push	es
	les	bp,int21regs_ptr	; ES:BX -> disk address structure
	mov	si,es:reg_SI[bp]
	mov	bx,es:reg_BX[bp]
	mov	es,es:reg_DS[bp]
	mov	FD_FUNC,FD_DDIO
	dec	dl			; 0-based drive number
	mov	byte ptr FD_DDIO_DRV_OP,dl
	mov	ax,es:[bx]		; logical sector number
	mov	FD_DDIO_STARTLOW,ax
	mov	ax,es:2[bx]
	mov	FD_DDIO_STARTHIGH,ax
	mov	ax,es:4[bx]		; sectors to transfer
	mov	FD_DDIO_NSECTORS,ax
	mov	ax,es:6[bx]		; buffer address
	mov	FD_DDIO_DMAOFF,ax
	mov	ax,es:8[bx]
	mov	FD_DDIO_DMASEG,ax
	test	si,1			; test if read or write operation is requested
	 jnz	f7305_20
	mov	byte ptr FD_DDIO_DRV_OP+1,1
	jmps	f7305_30
f7305_20:
	mov	byte ptr FD_DDIO_DRV_OP+1,2
f7305_30:
	pop	es
	call	fdos_nocrit		; call fdos function
f7305_exit:
	ret

PCMODE_DATA	dseg	word

	extrn	int21regs_ptr:dword
