;    File              : $BDOSLDR.ASM$
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
;    ENDLOG


	include request.equ
	include driver.equ
	include udsc.equ
	include	config.equ
	include	initmsgs.def				; for dos_msg error msg

;	MISC constants
CR		equ	0dh			;the usual
LF		equ	0ah


DATTS		equ	byte ptr 11
 DA_VOLUME	equ	08h
 DA_DIR		equ	10h
DBLOCK1H	equ	word ptr 20
DBLOCK1		equ	word ptr 26
DSIZE		equ	word ptr 28



CGROUP		group	INITCODE, INITDATA

INITCODE	segment public byte 'INITCODE'
ASSUME CS:CGROUP,DS:CGROUP

VER_MUSTBE	equ	1072h


	Public	detect_boot_drv
if SINGLEFILE eq 0
	Public	dos_version_check
	Public	read_dos		; read BDOS from disk
endif

	; Tries to detect to logical boot drive by the given phys boot drv
	; and a partition offset
detect_boot_drv proc
	les	di,boot_device		; get device driver address
	mov	dl,boot_drv		; get the boot drive sub unit
	xor	dh,dh
	dec	dh			; dh=255
	mov	ax,es
	or	ax,di			; make sure boot device is initialised
	 jz	@@error
@@get_device_procs:
	mov	ax,es:6[di]		; get strategy offset
	mov	strat_off,ax
	mov	strat_seg,es		; get strategy segment
	mov	ax,es:8[di]		; get interrupt offset
	mov	intrpt_off,ax
	mov	intrpt_seg,es		; get interrupt segment
@@test_drv:
	mov	bx,offset req_hdr
	mov	[bx+RH_UNIT],dl		; save logical unit to use
	mov	[bx+RH_CMD],CMD_BUILD_BPB
	call	device_request		; tell it to build a BPB
	 jnc	@@bpb_ok		; BPB successfully built
	jmp	@@next_drv		; if not, try next drive
@@bpb_ok:
	cmp	dl,boot_drv
	 jne	@@compare_part_off
	mov	dh,dl			; dh=boot_drv 
@@compare_part_off:
	les	di,[bx+RH2_BPB]
	mov al, [init_int13_unit]
		; magic: poke into the UPB structure around the BPB
	cmp es:byte ptr - UDSC.BPB + UDSC.RUNIT[di], al
	 jne @@next_drv
	mov	ax,part_off
	cmp	es:word ptr BPB_HIDDEN[di],ax
	 jne	@@next_drv
	mov	ax,part_off+2
	cmp	es:word ptr BPB_HIDDEN+2[di],ax
	 jne	@@next_drv
	mov	dh,dl
	jmp	@@done
@@next_drv:
	inc	dl			; increase log drv num
	 jz	@@done
	jmp	@@test_drv
@@done:
	cmp	dh,255
	 jne	@@store_boot_drv	; boot drv found?
@@error:
	mov	dx,offset bootpart_not_found_msg
	call	bio_output_str
if SINGLEFILE eq 1
	ret
else
	mov	dx,offset dos_msg
	jmp	dos_load_panic		; fatal error for dual-file kernel
endif
@@store_boot_drv:
	mov	dl,dh
	mov	boot_drv,dl
	mov	init_drv,dl
	ret
detect_boot_drv endp


;--------
; Print '$' terminated message at offset DX to console without using the BDOS
;
bio_output_str proc
	push	ax
	push	bx
	push	si
	push	di
	push	es
	les	di,resdev_chain		; get first device driver address
@@dev_scan:
	test	es:[di+DEVHDR.ATTRIB],DA_CHARDEV
	 jz	@@dev_next		; skip if not a character device
	test	es:[di+DEVHDR.ATTRIB],DA_ISCOT
	 jnz	@@dev_found		; skip if console device found
@@dev_next:
	les	di,es:[di]		; get next device
	jmp	@@dev_scan
@@dev_found:
	mov	ax,es:6[di]		; get strategy offset
	mov	strat_off,ax
	mov	strat_seg,es		; get strategy segment
	mov	ax,es:8[di]		; get interrupt offset
	mov	intrpt_off,ax
	mov	intrpt_seg,es		; get interrupt segment

	mov	bx,offset req_hdr
	mov	[bx+RH_CMD],CMD_OUTPUT	; write to console
	mov	[bx+RH_LEN],RH4_LEN	; set request header length
	mov	[bx+RH4_BUFOFF],dx	; set address of string
	mov	[bx+RH4_BUFSEG],ds
	mov	[bx+RH4_COUNT],-1
	mov	si,dx			; now find the end of the string
@@count_chars:
	inc	[bx+RH4_COUNT]		; print another char
	lodsb				; examine the next one
	cmp	al,'$'			; terminating char ?
	 jnz	@@count_chars
	call	device_request		; call the console driver
	pop	es
	pop	di
	pop	si
	pop	bx
	pop	ax
	ret
bio_output_str endp


dos_load_panic proc	; any error has occurred loading the BDOS
	mov	dx,offset dos_msg
	call	bio_output_str
	sti
@@forever:
	jmp	@@forever		; wait for reboot
dos_load_panic endp


device_request:		; general device driver interface
;--------------
;	entry:	BX -> request header
;	exit:	CY = 1 if error

	push	ds
	push	es
	push	ds
	pop	es
	mov	ds,strat_seg
	call	dword ptr cs:strat_ptr
	call	dword ptr cs:intrpt_ptr
	pop	es
	pop	ds
	test	[bx+RH_STATUS],RHS_ERROR
	 jnz	devreq_err
	clc
	ret
devreq_err:
	stc
	ret

if SINGLEFILE eq 0
;--------
read_dos:	; read in the BDOS
;--------
	call	login_drive		; build BPB for the boot drive
	mov	si,offset dos_name	; get name of file to open
	call	open_file		; open the BDOS file
	call	read_file		; read in the system file
	ret

login_drive:
;-----------
	les	di,boot_device		; get device driver address
	mov	dl,boot_drv		; get the boot drive sub unit
	mov	bx,offset req_hdr
	mov	[bx+RH_UNIT],dl		; save logical unit to use
	mov	[bx+RH_CMD],CMD_BUILD_BPB
	call	device_request		; tell it to build a BPB
	 jnc	login_drive10
	jmp	dos_load_panic
login_drive10:
	push	ds
	push 	si
	push	ds
	pop 	es
	mov	di,offset local_bpb	; ES:DI -> local BPB copy
	mov	cx,BPB_LENGTH
	lds	si,[bx+RH2_BPB]		; copy BPB to local memory
	rep	movsb
	pop	si
	pop 	ds

;	Now we have to figure out whether the media uses 12 or 16 bit FATs.
;	To that end, we need to compute the # of clusters on the drive:

	cmp	BT_dirsize,0		; check for FAT32 file system
	 jnz	login_drive20		; fixed root dir, FAT12/16
	mov	fattype,2		; this is probably a FAT32 drive
	mov	ax,BT_big_fat_size
	mov	nfatsecs,ax
	mov	ax,BT_big_fat_size+2
	mov	nfatsecs+2,ax
	ret
login_drive20:
	mov	fattype,0			; assume 12 bit FAT

	mov	al,BT_nfats		; compute FAT size
	mov	ah,0			; AX = # of FAT copies (usually 2)
	mul	BT_fat_size		; AX/DX = size of FAT in sectors

	add	ax,BT_reserved_sectors	; add in bootstrap sectors
	adc	dx,0
	mov	cx,ax			; CX/BP = sector address of root dir
	mov	bp,dx

	mov	ax,32			; compute root directory size
	mul	BT_dirsize		; AX/DX = bytes in directory
	mov	bx,BT_bytes_per_sector
	dec	bx			; BX = sector size - 1 for rounding
	add	ax,bx			; round up to next sector size
	adc	dx,0
	inc	bx			; BX = sector size in bytes
	div	bx			; AX = # of root directory sectors
	add	cx,ax			; CX/BP = sectors before data area
	adc	bp,0

	mov	ax,BT_total_sectors	; AX/DX = total disk size in sectors
	sub	dx,dx
	test	ax,ax			; is it actually larger than 65535?
	 jnz	dev_small		; no, AX/DX is correct
	mov	ax,BT_total_long	; else get real size from extension
	mov	dx,BT_total_long+2
dev_small:				; AX/DX = disk size in sectors
	sub	ax,cx			; AX/DX = data sectors
	sbb	dx,bp
					; now convert this to clusters
	mov	bl,BT_sctr_per_cluster
	mov	bh,0			; BX = sectors per clusters
	div	bx			; AX = # of data clusters
	inc	ax
	inc	ax			; cluster 0,1 are reserved
	cmp	ax,0FF6h		; is this too large for 12 bits?
	 jbe	dev_12bit		; skip if 12 bits will do
	mov	fattype,1		; else we use 16 bits
dev_12bit:
	mov	ax,BT_fat_size
	mov	nfatsecs,ax
	xor	ax,ax
	mov	nfatsecs+2,ax
	ret


dos_version_check proc
;-----------------
	mov	ax,4452h
	int	21h			; try and get DRDOS version number
	 jc	@@fail			;  it's not DRDOS !
	and	ax,0fffeh		; don't be so picky
	cmp	ax,VER_MUSTBE		; version check the DRDOS BDOS
	 jne	@@fail			;  reject all but the one we want
	ret				; return now I'm happy
@@fail:	jmp	dos_load_panic
dos_version_check endp

	
open_file:	; open BDOS system file
;---------
;	entry:	SI -> 11 byte file name

	cmp	fattype,2		; booting from a FAT32 drive?
	 je	open_file10		; yes
	xor	ax,ax
	push	ax
	mov	al,BT_nfats
	cbw
	push	ax
	push	nfatsecs+2
	push	nfatsecs
	sub	sp,8			; reserve space on stack
;	mul	BT_fat_size		; DX:AX = # FAT sectors
	call	mul32
	pop	ax
	pop	dx			; DX:AX = # FAT sectors
	add	sp,12			; clean up the stack
	mov	cx,ax			; BP:CX = rel_sctr dir start
	mov	bp,dx
	mov	dx,BT_dirsize		; dx = # entries to scan
	jmp	open_f1
open_file10:
	mov	bp,BT_fs_root+2		; FAT32 root dir cluster
	mov	cx,BT_fs_root
open_file15:
	mov	start_cluster+2,bp
	mov	start_cluster,cx
	call	clus2sec
	xor	ah,ah
	mov	al,BT_sctr_per_cluster
;	cbw
	mul	BT_bytes_per_sector
	mov	bx,32
	div	bx
open_f1: 				; CX = current dir sector
					; DX = current dir count
					; SI -> file name
	push	bp
	push	cx
	push 	dx
	push 	si
	push	ds
	pop 	es		; ES:BX -> sector buffer
	mov	bx,offset sector_buffer
	mov	dx,1			; read one directory sector
	call	rd_sector_rel		;     via disk driver
	pop	si
	pop	dx
	pop	cx
	pop	bp
;	inc	cx			; increment sector for next time
	add	cx,1			; increment sector for next time
	adc	bp,0

	sub	bx,bx			; start at beginning of sector
open_f2:
	lea	di,sector_buffer[bx]	; ES:DI -> directory entry
	push	si
	push 	di
	push 	cx	; save name ptr and count
	push	ds
	pop 	es
	mov	cx,11
	repe	cmpsb			; check if name matches
	pop	cx
	pop 	di
	pop 	si
	 jne	open_f3			; skip if name doesn't match
	test	DATTS[di],DA_DIR+DA_VOLUME
	 jz	open_foundit		; skip if matches
open_f3:
	dec	dx			; count down root directory entries
;	 jz	open_fail		; skip if root directory done
	 jz	open_f4			; skip if end of root dir or cluster reached
	add	bx,32			; next entry in directory sector
	cmp	bx,BT_bytes_per_sector	; sector complete?
	 jb	open_f2			; loop back while more
	jmp	open_f1			; read next directory sector
open_f4:
	cmp	fattype,2		; FAT32 root dir?
	 jne	open_fail		; no, reached end of root dir
	mov	bp,start_cluster+2	; else look for next dir cluster
	mov	cx,start_cluster
	call	next_cluster		; find next cluster in chain
	 jc	open_fail		; already at last root dir cluster
	jmp	open_file15

open_fail:				; file not found
	jmp	dos_load_panic

open_foundit:				; found the open file handle
	mov	ax,DSIZE[di]		; get length of dosfile
	mov	dx,DSIZE+2[di]
	mov	cx,BT_bytes_per_sector	; in sectors
	div	cx
;	cmp	dx,0			; any remainder?
;	 jne	open_found10		; no
	inc	ax			; round to whole sectors
open_found10:
	mov	dosfile_size,ax		; and save it
	mov	ax,DBLOCK1[di]		; get first disk block
	mov	start_cluster,ax	; save starting cluster
	xor	ax,ax
	cmp	fattype,2		; FAT32 drive?
	 jne	open_found15		; no, then skip high word of cluster
	mov	ax,DBLOCK1H[di]
open_found15:
	mov	start_cluster+2,ax
	xor	ax,ax
	ret				; return success


read_file:	; read BDOS files into memory at MEM_CURRENT:0000
;---------
	mov	ax,current_dos		; Get the Segment address to
	mov	dta_seg,ax		; load the BDOS at
	sub	ax,ax
	mov	dta_off,ax
rd_file1:
	mov	cluster_count,1		; we can read at least one cluster
	mov	cx,start_cluster
	mov	bp,start_cluster+2
rd_file2:				; check if next cluster contiguous
	push	bp
	push	cx			; save current cluster number
	call	next_cluster		; get link to next cluster
	pop	dx			; get previous cluster #
	pop	ax
;	inc	dx			; is current cluster contiguous?
	add	dx,1			; is current cluster contiguous?
	adc	ax,0
	cmp	cx,dx			; contiguos if BP:CX == AX:DX
	 jne	rd_file3		; no, need a separate read
	cmp	bp,ax
	 jne	rd_file3
	inc	cluster_count		; else read one more cluster
	jmp	rd_file2		; try again with next cluster
rd_file3:				; BP:CX = next chain, multi cluster read
	push	bp
	push	cx			; save start of next chain
	les	bx,dta_ptr		; ES:BX -> transfer address
	mov	cx,start_cluster	; previous contiguous chain starts here
	mov	bp,start_cluster+2
	mov	dx,cluster_count	; length of chain in clusters
	call	rd_cluster		; read DX clusters
	mov	al,BT_sctr_per_cluster
	mov	ah,0			; AX = sectors per cluster
	mul	cluster_count		; AX = sectors in chain to read
	mul	BT_bytes_per_sector	; AX = bytes in chain to read
	add	dta_off,ax
	pop	cx			; BP:CX = next (noncontiguous) cluster
	pop	bp
	mov	start_cluster,cx	; start of new chain
	mov	start_cluster+2,bp
	inc	cx			; was it end of file cluster number?
	 jnz	rd_file1		; go back for more if not
	inc	bp
	 jnz	rd_file1
					; else all clusters done
	ret


get_FAT_byte:
;------------
;	entry:	BX = offset into FAT

	mov	ax,bx			; BX = offset into FAT
	sub	dx,dx			; AX/DX = 32 bit offset
	div	BT_bytes_per_sector	; AX = sector, DX = offset in sector
	push	dx			; save offset in sector
	xor	dx,dx
	call	locate_FAT		; read FAT sector AX
	pop	bx			; BX = offset in FAT sector
	mov	al,sector_buffer[bx]	; get byte from FAT buffer
	ret


locate_FAT:
;----------
;	entry:	DX:AX = FAT sector to locate

	cmp	ax,current_fatsec	; AX = sector offset into FAT
	 jne	locate_fat10
	cmp	dx,current_fatsec+2
	 je	locate_FAT_match	; O.K. if same as last time
locate_fat10:
	mov	current_fatsec,ax	; set new sector for next time
	mov	current_fatsec+2,dx
	push	cx
	push 	si		; preserve FAT index
	mov	bp,dx
	mov	cx,ax			; BP:CX = sector number
	mov	bx,offset sector_buffer
	push	ds
	pop 	es		; ES:BX -> sector buffer
	mov	dx,1			; DX = single sector
	call	rd_sector_rel		; read FAT sector
	pop	si
	pop 	cx		; restore FAT index

locate_FAT_match:			; return with right sector in buffer
	ret



;	reads sectors relative to start of DOS area on disk (start=0)
;	same parameters as rd_sector
rd_sector_rel:
;-------------
;	entry:	BP:CX = sector address relative to first FAT sector (32-bit)
;		DX = sector count

;	sub	bp,bp				;overflow word = 0
	add	cx,BT_reserved_sectors
	adc	bp,0
;	jmp	rd_sector
	

;	reads absolute sectors from hard disk using rom bios
rd_sector:
;---------
;	entry:	DX = number of sectors
;		ES:BX -> data transfer buffer
;		DS -> program global data segment
;		CX/BP = absolute sector # (32 bit) (low/high)

	push	cx
	push 	dx		; save parameters
	mov	req3_bufoff,bx		; save transfer offset
	mov	req3_bufseg,es		; save transfer segment
	mov	req3_count,dx		; set sector count
	mov	bx,offset req_hdr	; BX -> request header
	mov	[bx+RH_CMD],CMD_INPUT	; read from disk device
	mov	req3_sector,cx		; set requested sector address
	mov	req_hdr,RH4_LEN
	mov	req3_sector32,cx	;  with 32 sector number
	mov	req3_sector32+2,bp
	test	bp,bp			; large sector number?
	 jz	rd_sec1			; no, normal request header
	mov	req3_sector,0FFFFh	; mark as a large request
rd_sec1:
	call	device_request		; tell it to read sectors
	 jnc	rd_sec2
	jmp	dos_load_panic
rd_sec2:
	pop	cx
	pop 	dx
	ret				; if CY, AH=error code


rd_cluster:
;----------
;	entry:	BP:CX = DOS cluster number.
;		DX = cluster count
;		ES:BX -> transfer buffer

	push	bx
	push 	es

	mov	al,BT_sctr_per_cluster
	mov	ah,0			; AX = sectors per cluster
	mul	dx			; AX = sectors in all clusters
	cmp	ax,dosfile_size		; is this longer than actual file size?
	 jbe	rd_cluster10		; no
	mov	ax,dosfile_size		; do not read more than remaining
rd_cluster10:
	sub	dosfile_size,ax		; less to read next time
	push	ax			; save the sector count

	sub	cx,2			; cluster 2 is data area start
	sbb	bp,0
	xor	ax,ax
	push	ax
	mov	al,BT_sctr_per_cluster
;	cbw
	xor	ah,ah
	push	ax
	push	bp
	push	cx
	sub	sp,8			; reserve space on stack
;	mul	cx			; AX,DX = relative sector #
	call	mul32
	pop	ax
	pop	dx			; DX:AX = relative sector #
	add	sp,12			; clean up the stack
	mov	cx,ax
	mov	bp,dx			; CX,BP = data area sector #

	push	bp
	xor	ax,ax
	push	ax
	mov	al,BT_nfats		; compute FAT size
	mov	ah,0			; AX = # of FAT copies (usually 2)
	push	ax
	push	nfatsecs+2
	push	nfatsecs
	sub	sp,8			; reserve space on stack
;	mul	BT_fat_size		; AX/DX = size of FAT in sectors
	call	mul32
	pop	ax
	pop	dx			; DX:AX = size of FAT in sectors
	add	sp,12			; clean up the stack
	pop	bp
	add	cx,ax
	adc	bp,dx			; CX,BP = end of FAT sectors

	mov	ax,32
	mul	BT_dirsize		; AX,DX = bytes in root directory
	mov	bx,BT_bytes_per_sector
	dec	bx
	add	ax,bx			; round up directory size
	adc	dx,0
	inc	bx
	div	bx			; AX = root directory sectors
	add	cx,ax
	adc	bp,0			; add root directory size

	add	cx,BT_reserved_sectors	; add in boot sector(s)
	adc	bp,0

	pop	dx
	pop 	es
	pop 	bx	; sector count, disk address

	jmp	rd_sector		; DX secs from CX/BP to ES:BX


;	Finds the NEXT cluster after the one passed in CX in an allocation
;	chain by using the FAT.  Returns the carry set if the end of chain
;	mark is found, otherwise returns the NEW cluster # in CX.
next_cluster:
;------------
	push	dx
	push 	bx		; save some registers
	cmp	fattype,0		; check if this is 12 bit media
	 je	next_cluster12		; skip if old fashioned 12 bit
	xor	ax,ax
	push	ax
	cmp	fattype,1		; is this FAT16?
	 jne	next_cluster5		; no, it must be FAT32
	mov	ax,2
	jmp	next_cluster6
next_cluster5:
	mov	ax,4
next_cluster6:
	push	ax
	push	bp
	push	cx
	sub	sp,8			; reserve space on stack
;	mul	cx			; AX/DX = byte offset in FAT (max. 128K)
	call	mul32
	pop	ax
	pop	dx
	add	sp,12			; clean up the stack again
	push	dx
	push	ax
	xor	ax,ax
	push	ax
	push	BT_bytes_per_sector
	sub	sp,8			; reserve space on stack
;	div	BT_bytes_per_sector	; AX = FAT sector #, DX = byte offset
	call	div32
	pop	bx
	add	sp,2
	pop	ax
	pop	dx
	add	sp,8			; clean up the stack
;	push	dx			; save byte offset within sector
	push	bx			; save byte offset within sector
	call	locate_FAT		; get FAT sector AX
	pop	bx			; BX = offset within sector
	mov	cx,word ptr sector_buffer[bx]
					; get 16 bit from FAT
	xor	bp,bp
	cmp	fattype,2		; is this FAT32?
	 jne	next_cluster7		; no, skip high word
	mov	bp,word ptr sector_buffer+2[bx]
					; get high 16 bit from FAT
	and	bp,0FFFh		; mask out reserved high nibble
next_cluster7:
	cmp	cx,0FFF7h		; check if too large for #
;	 jae	next_cluster_eof	; set carry, EOF
	 jb	next_cluster9
	cmp	fattype,2		; FAT32?
	 jne	next_cluster_eof	; no, then it is already EOF
	cmp	bp,0FFFh		; else also check high word
	 je	next_cluster_eof	; set carry, EOF
next_cluster9:
	clc
	jmp	next_cluster_ret	; good link

next_cluster12:				; DOS 2.x disk
	push	cx			; save cluster number
	mov	bx,cx
	add	bx,bx			; BX = cluster# * 2
	add	bx,cx			; BX = cluster# * 3
	shr	bx,1			; BX = cluster# * 1.5
	push	bx			; save offset in the FAT
	inc	bx			; BX = offset of high byte
	call	get_FAT_byte		; get the high byte in AL
	pop	bx			; BX = offset of low byte
	push	ax			; save high byte on stack
	call	get_FAT_byte		; get the low byte in AL
	pop	bx			; pop off high byte into BL
	mov	ah,bl			; set high byte, AX = word
	pop	cx			; restore cluster number
	shr	cx,1			; test if even or odd
	 jnc	even_fat		; if even entry, done
	mov	cl,4			; odd entry, shift down one nibble
	shr	ax,cl			; else need to justify
even_fat:				; even entry, strip off top bits
	and	ax,0fffh		; bx[0..11] are cluster
	mov	cx,ax			; CX = cluster number
	xor	bp,bp
	cmp	cx,0ff7h		; compare with largest legal 12 bit #
	 jae	next_cluster_eof	; check for end mark
	clc
	jmp	next_cluster_ret	; return value in CX, CY = 0
next_cluster_eof:
	mov	cx,-1			; indicate end of chain
	mov	bp,-1
	stc				; end of chain
next_cluster_ret:
	pop	bx
	pop 	dx
	ret

clus2sec:
;----------
;	entry:	BP:CX = DOS cluster number
;	exit:	BP:CX = sector number

	sub	cx,2			; cluster 2 is data area start
	sbb	bp,0
	xor	ax,ax
	push	ax
	mov	al,BT_sctr_per_cluster
;	cbw
	xor	ah,ah
	push	ax
	push	bp
	push	cx
	sub	sp,8			; reserve space on stack
;	mul	cx			; AX,DX = relative sector #
	call	mul32
	pop	ax
	pop	dx			; DX:AX = relative sector #
	add	sp,12			; clean up the stack
	mov	cx,ax
	mov	bp,dx			; CX,BP = data area sector #

	push	bp
	xor	ax,ax
	push	ax
	mov	al,BT_nfats		; compute FAT size
	mov	ah,0			; AX = # of FAT copies (usually 2)
	push	ax
	push	nfatsecs+2
	push	nfatsecs
	sub	sp,8			; reserve space on stack
;	mul	BT_fat_size		; AX/DX = size of FAT in sectors
	call	mul32
	pop	ax
	pop	dx			; DX:AX = size of FAT in sectors
	add	sp,12			; clean up the stack
	pop	bp
	add	cx,ax
	adc	bp,dx			; CX,BP = end of FAT sectors
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
;	AX,DX,BP,SP
	mov	bp,sp			; base address of temporary variables
	add	bp,2
	mov	ax,10[bp]		; multiply high word of factors
	mul	word ptr 14[bp]
	mov	4[bp],ax		; store result
	mov	6[bp],dx
	mov	ax,10[bp]		; multiply high word of first factor with low word of second
	mul	word ptr 12[bp]
	mov	2[bp],ax		; add result to previous
	add	4[bp],dx
	adc	word ptr 6[bp],0
	mov	ax,8[bp]		; multiply low word of first factor with high word of second
	mul	word ptr 14[bp]
	add	2[bp],ax		; add result to previous
	adc	4[bp],dx
	adc	word ptr 6[bp],0
	mov	ax,8[bp]		; multiply low word of first factor with low word of second
	mul	word ptr 12[bp]
	mov	[bp],ax			; add result
	add	2[bp],dx
	adc	word ptr 4[bp],0
	adc	word ptr 6[bp],0
	cmp	word ptr 4[bp],0	; 64-bit result?
	 jnz	mul32_1			; yes
	cmp	word ptr 6[bp],0
	 jz	mul32_2			; no
mul32_1:
	stc				; yes, set carry flag to indicate this
mul32_2:
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
	add	bp,2
	xor	ax,ax			; clear work registers
	xor	dx,dx
	mov	cx,32			; 32 bits
div32_loop:
	shl	word ptr 4[bp],1	; multiply quotient with two
	rcl	word ptr 6[bp],1
	shl	word ptr 12[bp],1	; shift one bit from dividend
	rcl	word ptr 14[bp],1
	rcl	ax,1			; to work registers
	rcl	dx,1
	cmp	dx,10[bp]		; compare high word with divisor
	 jb	div32_2
	 ja	div32_1
	cmp	ax,8[bp]		; compare low word
	 jb	div32_2
div32_1:
	or	word ptr 4[bp],1	; divisor fits one time
	sub	ax,8[bp]		; subtract divisor
	sbb	dx,10[bp]
div32_2:
	loop	div32_loop		; loop back if more bits to shift
	mov	[bp],ax			; save remainder onto stack
	mov	2[bp],dx
	ret

endif	; SINGLEFILE=0

INITCODE	ends



;
;	INITIALIZED DATA SEGMENT
;	========================
INITDATA	segment public word 'INITDATA'

		extrn	resdev_chain:dword	; resident device driver root
		extrn	current_dos:word	; current BDOS segment
		extrn	boot_device:dword	; device driver we boot from
		extrn	boot_drv:byte		; boot drive
		extrn	init_drv:byte		; init drive
		extrn	init_int13_unit:byte
		extrn	dos_name:byte		; name of BDOS file
		extrn	part_off:word		; 4-byte boot partition offset

strat_ptr	label	dword
strat_off	dw	?
strat_seg	dw	?

intrpt_ptr	label	dword
intrpt_off	dw	?
intrpt_seg	dw	?

if SINGLEFILE eq 0

dta_ptr		label	dword
dta_off		dw	?
dta_seg		dw	?

start_cluster	dw	2 dup (?)
cluster_count	dw	?
dosfile_size	dw	?

current_fatsec	dw	-1,-1			; no FAT sector read yet
fattype		dw	0			; defaults to 12 bit FAT
nfatsecs	dw	0,0			; number of FAT sectors (32-bit)

endif

;	static request header for DOS device driver I/O

req_hdr		db	22
req_unit	db	?
req_cmd		db	?
req_status	dw	?
		dd	2 dup (?)
req_media	db	?
		db	16 dup (?)

req1_return	equ	byte ptr req_media+1
req1_volid	equ	word ptr req_media+2

req2_bufoff	equ	word ptr req_media+1
req2_bufseg	equ	word ptr req_media+3
req2_bpb	equ	word ptr req_media+5

req3_buffer	equ	dword ptr req_media+1
req3_bufoff	equ	word ptr req_media+1
req3_bufseg	equ	word ptr req_media+3
req3_count	equ	word ptr req_media+5
req3_sector	equ	word ptr req_media+7
req3_volid	equ	word ptr req_media+9
req3_sector32	equ	word ptr req_media+13

;	local copy of the BPB for the boot device

local_bpb		label	byte
BT_bytes_per_sector	dw	?
BT_sctr_per_cluster	db	?
BT_reserved_sectors	dw	?
BT_nfats		db	?
BT_dirsize		dw	?
BT_total_sectors	dw	?
BT_fatid		db	?
BT_fat_size		dw	?
BT_sectors_per_track 	dw	?
BT_nheads		dw	?
BT_hidden_sectors	dw	2 dup (?)
BT_total_long		dw	2 dup (?)
BT_big_fat_size		dw	2 dup (?)
BT_fat_flags		dw	?
BT_fs_version		dw	?
BT_fs_root		dw	2 dup (?)
BT_fs_info		dw	?
BT_boot_backup		dw	?
BPB_LENGTH		equ	(offset $ - offset local_bpb)
BPB_HIDDEN		equ	17

	extrn	sector_buffer:byte
INITDATA	ends

	end
