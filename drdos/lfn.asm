; LFN.ASM - Functions for Long Filename and 64-bit file size support
;
; This file is part of
; The DR-DOS/OpenDOS Enhancement Project - http://www.drdosprojects.de
; Copyright (c) 2002-2009 Udo Kuhnt

	include	bdos.equ
	include	fdos.equ
	include	pcmode.equ
	include doshndl.def
	include	lfn.equ
	include	fdos.def
	include	mserror.equ

BDOS_CODE	cseg	word

	extrn	rd_pcdir:near
	extrn	flush_dirbuf:near

;Entry:		DS:BX = pointer to dir entry
;
;Exit:		carry flag set if LFN entry
	Public	is_lfn
is_lfn:
	cmp	DATTS[bx],DA_LFN	; attribute combination of LFN entry?
	 jne	is_lfn10		; no, must something else
	cmp	word ptr BLOCK1[bx],0	; no cluster chain?
	 jne	is_lfn10		; perhaps it is a Delwatch entry
	stc				; it is probably a Long Filename
	jmps	is_lfn20
is_lfn10:
	clc				; no LFN entry
is_lfn20:
	ret

	Public	del_lfn
del_lfn:
	push	dcnt			; save dir count
del_lfn10:
	cmp	dcnt,0			; first entry in dir?
	 je	del_lfn20		; then no LFN can exist before it
	dec	dcnt			; point dir count to previous entry
	dec	dcnt
	call	rd_pcdir		; read dir entry
	mov	bx,ax
	call	is_lfn			; check if it is a long filename
	 jnc	del_lfn20		; no further LFN entries, done
	mov	DNAME[bx],0e5h		; else mark this entry as deleted
	call	flush_dirbuf		; and copy it to the buffer
	jmps	del_lfn10		; repeat with next entry
del_lfn20:
	pop	dcnt			; restore dir count
	dec	dcnt
	call	rd_pcdir		; and old dir entry
	ret

PCM_CODE	cseg	byte
	extrn	return_AX_CLC:near
	extrn	vfy_dhndl_ptr_AX:near
	extrn	check_handle:near
	extrn	redir_dhndl_offer:near
	extrn	verify_handle:near
	extrn	mul32:near
	extrn	mul64:near
	extrn	dos_entry:near
	extrn	fdos_first:near
	extrn	fdos_next:near
	extrn	fdos_entry:near
	extrn	lds_si_dmaptr:near
	extrn	local_disk:near
	extrn	path_prep:near
	extrn	check_no_wild:near
	extrn	finddfcbf:near
	extrn	update_dir:near

	Public	func71
func71:
	cmp	al,42h			; function 7142h?
	 je	func7142		; yes
	cmp	al,43h			; function 7143h?
	 jne	f71_4e
	jmp	func7143		; yes
f71_4e:
	cmp	al,4eh			; function 714eh?
	 jne	f71_4f
	jmp	func714e		; yes
f71_4f:
	cmp	al,4fh			; function 714fh?
	 jne	f71_a1
	jmp	func714f		; yes
f71_a1:
	cmp	al,0a1h			; function 71a1h?
	 jne	f71_a6
	jmp	func71a1		; yes
f71_a6:
	cmp	al,0a6h			; function 71a6h?
	 jne	func71_a7
	jmp	func71a6
func71_a7:
	cmp	al,0a7h			; function 71a7h?
	 jne	func71_error
	jmp	func71a7		; yes
func71_error:
	mov	ax,7100h		; function not supported
	push	ds
	lds	bp,int21regs_ptr	; set carry flag
	or	ds:reg_FLAGS[bp],CARRY_FLAG
	pop	ds
	stc
	ret

func7142:
	push	ds
	lds	bp,int21regs_ptr
	mov	ax,ds:reg_CX[bp]	; AL = original CL
	pop	ds
	cmp	al,2			; valid subfunction number?
	 jbe	f7142_02
	jmp	f71_error_func
f7142_02:
	mov	ax,bx
	call	vfy_dhndl_ptr_AX_call	; check file handle number
	 jnc	f7142_handle_ok
	mov	ax,bx
	neg	ax
	jmp	f71_error
f7142_handle_ok:
	test	es:byte ptr DHNDL_WATTR+1[bx],DHAT_REMOTE/100h
	jz f7142_not_redirector

f7142_redirector:
	mov di, bx		; es:di -> SFT entry

	push	ds
	lds	bp,int21regs_ptr
	mov	dx,ds:reg_DX[bp]
	mov	ds,ds:reg_DS[bp]; ds:dx -> buffer

		; If either of the calls fails with error 1
		;  it means that call is not supported. So we
		;  try one, and if it returns error 1 then
		;  either it meant to return the actual error
		;  1 or it isn't supported. Either way, we want
		;  to try the other call then.
		; If 11C2h meant to return an actual error 1
		;  then we'll still call 1142h, but either
		;  1142h isn't supported anymore (so we get the
		;  eventual error 1 anyway), or it is also
		;  supported and we will get the same error 1
		;  again from the second call, too.
		; If 11C2h isn't supported we will call 1142h
		;  and return whatever status it gives us.
	mov	ax,11C2h
	stc
	int	2Fh
	jnc	f7142_ret_CF_ds	; supported and successful -->
	cmp	ax,1		; error 1 ?
	stc
	jne	f7142_ret_CF_ds	; error other than 1,
				;  that means it is supported.
				;  return the other error -->
	mov	ax,1142h	; ax = 1142h
	stc
	int	2Fh
f7142_ret_CF_ds:
	pop	ds
f71_ret_CF:
	jc	f71_error_j
	jmp	f7142_ret_success

f71_error_j:
	jmp	f71_error

f7142_not_redirector:
	test	es:DHNDL_ATTR[bx],DHAT_DEV
	jnz	f7142_dev		; skip a part if character device
f7142_05:
	call	check_handle		; check if valid file handle
f7142_dev:
	push	ds
	lds	bp,int21regs_ptr
	mov	ax,ds:reg_CX[bp]	; AL = original CL
	mov	si,ds:reg_DX[bp]	; DS:SI -> QWORD for position offset and result
	mov	ds,ds:reg_DS[bp]
	or	al,al
	 je	f7142_10		; seek from beginning
	dec	al
	 je	f7142_20		; seek from current position
	jmps	f7142_30		; seek from end

f7142_10:				; mode 0: set absolute position
	mov	ax,[si]			; copy 64-bit offset to position
	mov	es:DHNDL_POSLO[bx],ax
	mov	ax,2[si]
	mov	es:DHNDL_POSHI[bx],ax
	mov	ax,4[si]
	mov	es:DHNDL_POSXLO[bx],ax
	mov	ax,6[si]
	mov	es:DHNDL_POSXHI[bx],ax
	jmps	f7142_40

f7142_20:				; mode 1: relative to current position
	mov	ax,[si]			; add 64-bit offset to position
	add	ax,es:DHNDL_POSLO[bx]
	mov	es:DHNDL_POSLO[bx],ax
	mov	[si],ax			; and store new position as result
	mov	ax,2[si]
	adc	ax,es:DHNDL_POSHI[bx]
	mov	es:DHNDL_POSHI[bx],ax
	mov	2[si],ax
	mov	ax,4[si]
	adc	ax,es:DHNDL_POSXLO[bx]
	mov	es:DHNDL_POSXLO[bx],ax
	mov	4[si],ax
	mov	ax,6[si]
	adc	ax,es:DHNDL_POSXHI[bx]
	mov	es:DHNDL_POSXHI[bx],ax
	mov	6[si],ax
	jmps	f7142_40

f7142_30:				; mode 2: relative to end of file
	mov	ax,[si]			; add 64-bit offset to file size
	add	ax,es:DHNDL_SIZELO[bx]
	mov	es:DHNDL_POSLO[bx],ax	; and store as new position
	mov	[si],ax			; and result
	mov	ax,2[si]
	adc	ax,es:DHNDL_SIZEHI[bx]
	mov	es:DHNDL_POSHI[bx],ax
	mov	2[si],ax
	mov	ax,4[si]
	adc	ax,es:DHNDL_SIZEXLO[bx]
	mov	es:DHNDL_POSXLO[bx],ax
	mov	4[si],ax
	mov	ax,6[si]
	adc	ax,es:DHNDL_SIZEXHI[bx]
	mov	es:DHNDL_POSXHI[bx],ax
	mov	6[si],ax
f7142_40:
	pop	ds
f7142_ret_success:
	xor	ax,ax
	call	return_AX_CLC
	clc
	ret

func7143:
	cmp	bl,3			; check subfunction range
	 je	f7143_10
	cmp	bl,4
	 je	f7143_10
	jmp	f71_error_func
f7143_10:
	mov	FD_FUNC,ax		; function number
	mov	FD_NAMEOFF,dx		; filename
	mov	FD_NAMESEG,es
	mov	dx,offset fdos_data	; parameter block
	push	ds			; set up FDOS stack frame
	push	dx
	push	ax
	push	ax
	call	local_disk		; make local copy of parameters
	call	path_prep		; parse path
	call	check_no_wild		; wildcards not allowed
	 jnz	f7143_20
	mov	ax,2			; file not found
	jmp	f71_error
f7143_20:
	call	finddfcbf		; locate dir entry
	 jnz	f7143_30
	mov	ax,2			; file not found
	jmp	f71_error
f7143_30:
	les	bp,int21regs_ptr
	mov	ax,es:reg_BX[bp]
	cmp	al,3			; subfunction 3?
	 je	f7143_set_writetime
f7143_get_writetime:
	mov	cx,DTIME[bx]		; last write time
	mov	di,DDATE[bx]		; last write date
	mov	es:reg_CX[bp],cx
	mov	es:reg_DI[bp],di
	jmps	f7143_exit
f7143_set_writetime:
	mov	cx,es:reg_CX[bp]	; new last write time
	mov	di,es:reg_DI[bp]	; new last write date
	mov	DTIME[bx],cx
	mov	DDATE[bx],di
	call	update_dir		; update dir entry
f7143_exit:
	xor	ax,ax			; no error
	jmp	return_AX_CLC

func714e:
	mov	ax,4eh			; FindFirst
	xor	ch,ch
	mov	FD_ATTRIB,cx		; search attributes
	mov	FD_NAMEOFF,dx		; search pattern
	mov	FD_NAMESEG,es
	jmps	f714e_entry

func714f:
	mov	ax,4fh			; FindNext
f714e_entry:
	mov	FD_FUNC,ax
;	mov	FD_LFNSEARCH,1		; use FAT+/LFN extensions
	mov	fdos_pb+10,1		; use FAT+/LFN extensions
	push	ds
	push	ss:dma_segment		; save old DTA
	push	ss:dma_offset
	mov	ss:dma_segment,ds
	lea	di,f714e_dta
	mov	ss:dma_offset,di
	mov	dx,offset fdos_data
	call	fdos_entry		; call FindNext function
	cmp	ax,ED_LASTERROR		; has an error occurred?
	 jb	f714f_10		; no
	pop	ss:dma_offset		; restore old DTA
	pop	ss:dma_segment
	pop	ds
	neg	ax
	jmp	f71_error
f714f_10:
	les	bp,int21regs_ptr	; ES:BP -> initial parameters
	mov	di,es:reg_DI[bp]
	push	es:reg_ES[bp]
	pop	es			; ES:DI -> Find Data buffer
	call	lds_si_dmaptr		; DS:SI -> DTA
	add	si,15h			; start at file attribute field
	lodsb				; file attribute
	xor	ah,ah
	stosw
	xor	ax,ax			; set additional file times to 0
	stosw
	stosw
	stosw
	stosw
	stosw
	stosw
	stosw
	stosw
	stosw
	movsw				; file time
	movsw				; file date
	xor	ax,ax			; zero high dword
	stosw
	stosw
	mov	al,-7[si]		; extended file size
	stosw
	xor	ax,ax
	stosw
	movsw				; file size low
	movsw
	add	di,8			; skip over reserved bytes
	mov	cx,13
	repnz	movsb			; copy file name
	add	di,260 - 13		; start of short name field
	stosb				; no short name (0)
	pop	ss:dma_offset		; restore old DTA
	pop	ss:dma_segment
	pop	ds
	les	bp,int21regs_ptr
	mov	es:reg_CX[bp],ax	; Unicode conversion flags (0)
	call	return_AX_CLC		; no error
	ret

func71a1:
	call	return_AX_CLC
	ret

func71a6:
	mov	ax,bx
	call	vfy_dhndl_ptr_AX_call	; check file handle number
	 jnc	f71a6_handle_ok
	mov	ax,bx
	neg	ax
	jmp	f71_error
f71a6_handle_ok:
	test	es:byte ptr DHNDL_WATTR+1[bx],DHAT_REMOTE/100h
	jz	f71a6_not_redirector

f71a6_redirector:
	mov di, bx		; es:di -> SFT entry

	push	ds
	lds	bp,int21regs_ptr
	mov	dx,ds:reg_DX[bp]
	mov	ds,ds:reg_DS[bp]; ds:dx -> buffer

	mov	ax,11A6h
	stc
	int	2Fh		; dosemu2 extension function
	jnc	f71a6_ret_CF_ds	; supported and successful -->
	cmp	ax,1		; error 1 ?
	stc			; indicate error (CY)
	jne	f71a6_ret_CF_ds
	mov	ax, 7100h	; MSWindows 4 returns CY, ax=7100h on redirector
				; (still CY)

f71a6_ret_CF_ds:
	jmp	f7142_ret_CF_ds

f71a6_dev:
	mov	ax, 7100h
	stc
	jmp	f71_ret_CF

f71a6_not_redirector:
	test	es:DHNDL_ATTR[bx],DHAT_DEV
	 jnz	f71a6_dev		; skip if character device
	call	verify_handle		; check if valid file handle
	push	ds
	lds	bp,int21regs_ptr	; DS:DI -> buffer for Get File Info structure
	mov	di,ds:reg_DX[bp]
	mov	ds,ds:reg_DS[bp]
	push	ds			; ES:DI -> buffer, DS:BX -> DHNDL
	push	es
	pop	ds
	pop	es
	xor	ah,ah
	mov	al,DHNDL_ATTR[bx]	; file attributes
	stosw
	xor	ax,ax
	stosw
	mov	cx,8
	rep	stosw			; creation time (0 = unsupported)
					; last access time (0 = unsupported)
	push	bx
	mov	dx,DHNDL_DATE[bx]	; last write time
	mov	cx,DHNDL_TIME[bx]
	xor	bx,bx			; 0 milliseconds
	call	f71a701_entry2
	pop	bx
	add	di,8
	push	ds			; save DS
	mov	bp,sp			; restore PCM DS
	mov	ds,2[bp]
	sub	sp,25			; reserve space on stack
	mov	bp,sp
	push	es			; save registers
	push	bx
	push	di
	mov	ax,ss			; ES:DX -> buffer for media info
	mov	es,ax
	mov	dx,bp
	xor	bx,bx			; current drive
	mov	ax,6900h		; Get Volume Serial Number
	call	dos_entry
	pop	di			; restore registers
	pop	bx
	pop	es
	mov	ax,2[bp]		; volume serial number
	stosw
	mov	ax,4[bp]
	stosw
	add	sp,25			; clean up stack again
	pop	ds			; restore DS
	mov	ax,DHNDL_SIZEXLO[bx]	; file size high
	stosw
	mov	ax,DHNDL_SIZEXHI[bx]
	stosw
	mov	ax,DHNDL_SIZELO[bx]	; file size low
	stosw
	mov	ax,DHNDL_SIZEHI[bx]
	stosw
	xor	ax,ax
	inc	ax			; links to file (1)
	stosw
	dec	ax
	stosw
	stosw				; file identifier
	stosw
	stosw
	stosw
	pop	ds
	call	return_AX_CLC
	clc
	ret

func71a7:
	cmp	bl,01			; sub function 01?
	 je	f71a701			; yes
	jmp	f71_error_func
f71a701:				; Convert DOS time to Windows time
	call	f71a701_entry
	xor	ax,ax
	call	return_AX_CLC
	clc
	ret

f71a701_entry:
	les	bp,int21regs_ptr	; ES:DI -> 64-bit time
	mov	di,es:REG_DI[bp]
	mov	es,es:REG_ES[bp]
f71a701_entry2:
	mov	bp,sp
	push	dx			; save date
	push	cx			; save time
	xchg	bl,bh
	xor	bh,bh
	push	bx
	cmp	dx,0			; special case - date and time zero
	 jnz	f71a701_05
	cmp	cx,0
	 jnz	f71a701_05
	xor	ax,ax			; clear buffer
	cld
	mov	cx,4
	rep	stosw
	sub	di,8
	jmp	f71a701_80
f71a701_05:
	mov	ax,dx
	and	ax,0fe00h		; bits 9-15 contain the year - 1980
	mov	cl,9
	shr	ax,cl
	add	ax,379			; AX = year - 1601
	push	ax
	mov	cx,365
	mul	cx			; convert to days (without leap days)
	mov	es:[di],ax		; save to ES:DI
	mov	es:2[di],dx
	pop	ax
	xor	bx,bx			; compute leap days in 400 years
	xor	dx,dx
	mov	cx,400
	div	cx
	cmp	al,0			; at least 400 years?
	 jz	f71a701_10		; no
	mov	bl,97			; 97 leap days
f71a701_10:
	mov	ax,dx			; divide remainder by 100
	mov	cl,100			; to compute leap days in 100 years
	div	cl
	cmp	al,3
	 jne	f71a701_20
	mov	ch,4
f71a701_20:
	push	ax
	mov	cl,24			; 24 leap days
	mul	cl
	add	bl,al
	pop	ax
	xchg	ah,al
	xor	ah,ah			; divide remainder by 4
	mov	cl,4			; to compute remaining leap days
	div	cl
	cmp	al,24
	 jne	f71a701_30
	or	ch,2
f71a701_30:
	add	bl,al			; remaining leap days in century
	cmp	ah,3
	 jne	f71a701_40
	or	ch,1
f71a701_40:
	xor	ax,ax			; add leap days
	mov	al,bl
	add	es:[di],ax
	adc	es:word ptr 2[di],0
	mov	ax,-2[bp]		; restore date
	and	ax,1e0h			; bits 5-8 contain the month
	mov	cl,5
	shr	ax,cl
	mov	bx,ax
	xor	si,si
	inc	si
	xor	dx,dx
	xor	ax,ax
f71a701_50:
	cmp	si,bx
	 je	f71a701_60
	mov	dl,cs:ndays[si]
	add	ax,dx
	inc	si
	jmps	f71a701_50
f71a701_60:
	cmp	bx,2			; has February already passed?
	 ja	f71a701_70		; no
	test	ch,1			; is the year a leap year?
	 jz	f71a701_70		; no
	cmp	ch,3			; 100/400-years rule
	 je	f71a701_70		; 100 but not 400, no leap year
	inc	ax			; yes, add one leap day
f71a701_70:
	mov	dx,-2[bp]		; restore date
	and	dx,1fh			; bits 0-4 contain the days
	add	ax,dx			; AX = days in year
	dec	ax			; minus one for the first day in 1601
	add	es:[di],ax		; date converted to days
	adc	es:word ptr 2[di],0

	push	es:word ptr 2[di]	; number of days
	push	es:word ptr [di]
	xor	ax,ax
	push	ax
	mov	ax,43200		; 2-seconds per day
	push	ax
	sub	sp,8			; reserve space on stack
	call	mul32			; convert to 2-seconds
	pop	es:word ptr [di]	; save subtotal
	pop	es:word ptr 2[di]
	pop	es:word ptr 4[di]
	pop	es:word ptr 6[di]
	add	sp,8			; clean up stack again
	mov	ax,-4[bp]		; restore time
	and	ax,0f800h		; bits 11-15 contain the hours
	mov	cl,11
	shr	ax,cl
	mov	cx,1800
	mul	cx			; convert to 2-seconds
	add	es:[di],ax		; and add subtotal
	adc	es:2[di],dx
	adc	es:word ptr 4[di],0
	adc	es:word ptr 6[di],0
	mov	ax,-4[bp]		; restore time
	and	ax,7e0h			; bits 5-10 contain the minutes
	mov	cl,5
	shr	ax,cl
	mov	cl,30
	mul	cl			; convert to 2-seconds
	add	es:[di],ax		; and add subtotal
	adc	es:2[di],dx
	adc	es:word ptr 4[di],0
	adc	es:word ptr 6[di],0
	mov	ax,-4[bp]		; restore time
	and	ax,1fh			; bits 0-4 contain the 2-seconds
	add	es:[di],ax		; and add subtotal
	adc	es:2[di],dx
	adc	es:word ptr 4[di],0
	adc	es:word ptr 6[di],0
f71a701_80:
	push	es:word ptr 6[di]	; number of 2-seconds
	push	es:word ptr 4[di]
	push	es:word ptr 2[di]
	push	es:word ptr [di]
	xor	ax,ax
	push	ax
	push	ax
	mov	ax,131h			; 1312d00h = 20000000 100-nanoseconds
	push	ax
	mov	ax,2d00h
	push	ax
	sub	sp,16			; reserve space on stack
	call	mul64			; convert to 100-nanoseconds
	pop	es:word ptr [di]	; save subtotal
	pop	es:word ptr 2[di]
	pop	es:word ptr 4[di]
	pop	es:word ptr 6[di]
	add	sp,24			; clean up stack again
	xor	ax,ax			; centiseconds
	push	ax
	push	word ptr -6[bp]
	mov	ax,1			; 186A0h = 100000 100-nanoseconds
	push	ax
	mov	ax,86a0h
	push	ax
	sub	sp,8			; reserve space on stack
	call	mul32
	pop	ax
	pop	dx
	add	sp,12			; clean up stack again
	add	es:[di],ax		; and add to result
	adc	es:2[di],dx
	adc	es:word ptr 4[di],0
	adc	es:word ptr 6[di],0
	add	sp,6
	ret

ndays		db	31,28,31,30,31,30,31,31,30,31,30,31

vfy_dhndl_ptr_AX_call:
	call	vfy_dhndl_ptr_AX	; setup stack for vfy_dhndl_ptr_AX
	ret

f71_error_func:
	mov	ax,1			; invalid function number

f71_error:
	les	bp,int21regs_ptr
	mov	es:reg_AX[bp],ax	; return error code
	or	es:reg_FLAGS[bp],CARRY_FLAG ; set carry flag
	stc
	ret

BDOS_DATA	dseg	word

	extrn	dcnt:word
	extrn	fdos_pb:word

f714e_dta	rb	43

PCMODE_DATA	dseg	word

	extrn	int21regs_ptr:dword
	extrn	dma_segment:word
	extrn	dma_offset:word
