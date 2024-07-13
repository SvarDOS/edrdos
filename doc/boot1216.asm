; OpenDOS 7.01 floppy boot sector
; reconstructed from OpenDOS 7.01 installation floppy
; on July 2024, Bernd Boeckmann
;
; For documentation purposes only, see the warning below.
;
; MEMORY LAYOUT:
;   boot sector lives at 0:7C00 and stays there
;   stack is right below 0:7C00
;   FAT is loaded as a whole to 0800:0000 (single-sector reads)
;     needing >128K of RAM in worst case (255 FAT sectors)
;   BIO file gets loaded to 0070:0000 (cluster-sized reads)

; WARNING!
;   7C00 - 0700 = 29952 bytes for maximum BIO size
;                 not taking maximum stack size into account!
;   Therefore this code does not work with current DRBIO.SYS,
;   because it is larger!

; If you for whatever reason want to assemble this, JWasm should work.

; There are several [bp+var-bseg] expressions. These are for optimization
; to allow JWasm to encode 8-bit displacements. Otherwise it would
; generate 16-bit displacements + fixupp entries if outputting OMF.

; Potential bugs:
;   - Floppy controller is reset before the FD parameters are patched,
;     not after.
;   - original INT1E vector not handed over to BIO, may case trouble on
;     INT19, if INT1E is restored to 0:7C00.

bseg segment public byte
assume cs:bseg, ds:bseg, ss:bseg

			jmp short start
			nop
oem_name 		db 	"OPENDOS7"	; 0003
bpb_bytes_per_sec	dw 	0200h		; 000b
bpb_secs_per_clst	db 	1		; 000d
bpb_rsrvd_secs		dw 	1		; 000e
bpb_fat_count		db 	2		; 0010
bpb_root_entries	dw 	00e0h		; 0011
bpb_total_secs		dw 	0b40h		; 0013
bpb_media_id		db 	0f0h		; 0015
bpb_fat_secs		dw 	9		; 0016
bpb_secs_per_track	dw 	18		; 0018
bpb_heads		dw 	2		; 001a
bpb_hidden_lo		dw 	0		; 001c
bpb_hidden_hi		dw 	0		; 001e
bpb_total_secs_big	dd 	0		; 0020
bpb_phys_drive		db 	0		; 0024
bpb_reserved		db 	0		; 0025
  bio_secs_remaining	equ	25h
bpb_boot_sig		db 	29h		; 0026
bpb_vol_id		dd 	18d92a3ch	; 0027
bpb_vol_name		db 	"DISK_01    "	; 002b
  secs_to_read		equ	2bh	; how many sectors to read via a single INT13
  first_data_sec_lo	equ	2ch
  first_data_sec_hi	equ	2eh

bpb_fat_id		db "FAT12   "		; 0036

; data area
secs_per_clst		dw	0		; 003e
kernel_vector		label 	dword
kernel_offset		dw	0		; 0040
kernel_seg		dw	0070h		; 0042
fat_mask		dw	0ffffh		; 0044
filename		db	"IBMBIO  COM"	; 0046
			db	0, 50h, 0	; 0051  ??? what are these for
sec_buf_seg		dw	0800h
sec_bug_seg_plus_64k	dw	1800h

org	58h

start:
	cld
	xor	ax,ax
	mov	es,ax		; es = 0000
	cli

	mov	ss,ax		; ss = 0000
	mov	sp,7c00h	; stack right below boot sector
	sti

	xor	dx,dx		; reset floppy controller
	int	13h

set_fd_parameters:
	mov	bp,78h		; ss:bp = 0000:0078 is INT1E vector
	mov	di,sp		; di = 7C00
	lds	si,[bp+0]	; ds:si -> BIOS FD parameters
	mov	[bp+0],di	; set INT1E to new FD parameter	
	mov	[bp+2],es	; ..location 0:7C00
	mov	cx,11		; copy BIOS FD parameters to 0:7C00
	rep	movsb		; ..overwrite start of bootsect
	xchg	ax,cx		; ax = 0
	mov	ds,ax		; ds = 0
	mov	bp,sp		; bp = 7C00
	; the following sets the FD parameters sectors per track to a
	; maximum of 36 to support 2.88M floppy disks
	mov	byte ptr [bp+4], 24h

	mov	al,[bp+bpb_secs_per_clst-bseg]
	mov	[bp+secs_per_clst-bseg],ax
	mov	al,[bp+bpb_fat_count-bseg]
	mul	word ptr [bp+bpb_fat_secs-bseg]
	add	ax,[bp+bpb_rsrvd_secs-bseg]
	adc	dx,0				; dx:ax = first rootdir sector
	mov	cx,[bp+bpb_bytes_per_sec-bseg]

	; if BPB bytes per sectors is greater than 512, all sector
	; quantities will be scaled
scale_sector_numbers:
	cmp	cx,200h			; test if sector size is 512 byte
	jz	sector_size_good
	jc	error			; ..error if less than 512 byte

	shr	cx,1			; divide current sector size by two

	; NOTE: the following seems to contain a bug, because dx is not
	; multiplied by two, but only the ax part of dx:ax.

	add	ax,ax		; multiply dx:ax by two
	adc	dx,0

	shl	word ptr [bp+secs_per_clst-bseg],1
	shl	word ptr [bp+bpb_fat_secs-bseg],1
	jmp	short scale_sector_numbers

sector_size_good:
	; Code assumes FAT16 if number of FAT sectors is greater than 12
	;   12 * 512 / 1.5 = 4096
	cmp	word ptr [bp+bpb_fat_secs-bseg],12
	ja	is_fat16
is_fat12:
	mov	word ptr [bp+fat_mask-bseg],0fffh
is_fat16:
	; potential bug: BPB_HIDDEN not scaled like above
	; likely never triggered
	add	ax,[bp+bpb_hidden_lo-bseg]	; add hidden sectors to dx:ax
	adc	dx,[bp+bpb_hidden_hi-bseg]
	push	ax			; dx:ax contains first root dir sector
	push	dx

read_root_dir:
	mov	bx,[bp+bpb_root_entries-bseg]
	push	bx			; push root dir entries
	add	bx,0fh			; calculate number of rootdir sectors
	mov	cl,4			; ..16 entries per sector, round up
	shr	bx,cl
	mov	[bp+secs_to_read],bl
	mov	es,[bp+sec_buf_seg-bseg]	; read into sec_buf_seg
	push	es
	call	read_sectors			; read root directory
	pop	es
	mov	[bp+first_data_sec_lo],ax	; dx:ax contains start of 
	mov	[bp+first_data_sec_hi],dx	; data area after rootdir read
	pop	cx				; pops number of dir entries
	sub	di,di
next_entry:
	push	cx
	push	di
	lea	si,[bp+filename-bseg]
	mov	cx,0bh
	repe	cmpsb			; compare dir entry with bio file name
	pop	di
	pop	cx
	jz	read_fat		; we found it!
	add	di,20h
	loop	next_entry

error:
	; fallthrough: no BIO file found!
	mov	si,(errormsg-bseg) + 7c00h
	call	print_string
	cbw				; ax = 0
	int	16h			; wait for key pressed
;	jmp	0ffff00000h		; reboot on error
	db	0eah,0,0,0ffh,0ffh

dirent_start_clst	equ 1ah
dirent_file_size	equ 1ch

read_fat:
	mov	cx,[es:di+dirent_start_clst]
	mov	ax,[es:di+dirent_file_size]	; file size may not be larger than 65536-511 bytes
	add	ax,1ffh				; add 511 to round up to next sector
	shr	ax,1
	mov	[bp+bio_secs_remaining],ah	; ah = file size in sectors
	pop	dx
	pop	ax				; dx:ax = first root dir sector
	push	cx
	mov	cx,[bp+bpb_fat_secs-bseg]
	sub	ax,cx				; subtract fat size from root dir start
	sbb	dx,0				; to get first fat sector
	mov	es,[bp+sec_buf_seg-bseg]	; es:di = 0800:0 (di = 0)
read_fat_sector:
	push	cx
	mov	byte ptr [bp+secs_to_read],1
	call	read_sectors			; read FAT, sector by sector
	pop	cx
	loop	read_fat_sector

read_bio:
	pop	bx				; bx = first BIO cluster
	mov	es,[bp+kernel_seg-bseg]		; where to load BIO? (di = 0)
read_bio_next:
	mov	ax,[bp+secs_per_clst-bseg]
	mov	[bp+secs_to_read],al		; we read a whole cluster
	sub	[bp+bio_secs_remaining],al
	pushf
	jnc	read_bio_cluster
	mov	dl,[bp+bio_secs_remaining]	; read less than a cluster
	add	[bp+secs_to_read],dl
read_bio_cluster:
	push	bx				; bx = current BIO cluster
	dec	bx				; subtract two clusters, first two
	dec	bx				; ..are reserved!
	mul	bx				; dx:ax = (current cluster-2) * cluster size
	add	ax,[bp+first_data_sec_lo]	; add first data sector to dx:ax
	adc	dx,[bp+first_data_sec_hi]
	call	read_sectors			; read data cluster
	pop	bx				; bx = current BIO cluster
	push	es				; save BIO load segment
determine_next_cluster:
	mov	ax,bx				; ax = current BIO cluster
	shl	bx,1				; bx = BIO cluster * 2
	les	di,dword ptr [bp+sec_buf_seg-bseg]	; es = 0800 + 64K, di = 0800
	jc	no_64k_overflow			; if 64K overflow, leave es = 1800
	mov	es,di				; otherwise set back to 0800
no_64k_overflow:
	cmp	word ptr [bp+fat_mask-bseg],0fffh	; FAT12 filesystem?
	jnz	fat16_entry
fat12_entry:
	add	bx,ax				; bx = BIO cluster * 3
	shr	bx,1				; bx / 2 is cluster offset into FAT
	mov	bx,[es:bx]			; get FAT12 cluster entry
	jnc	mask_fat12_entry
	mov	cl,4				; adjust uneven FAT12 cluster entries
	shr	bx,cl				; by shifting 4 to the right
mask_fat12_entry:
	and	bh,0fh
	jmp	short got_next_entry
fat16_entry:
	mov	bx,[es:bx]
got_next_entry:					; we have next cluster in bx
	pop	es				; restore BIO load segment
	popf
	ja	read_bio_next
	mov	dl,[bp+bpb_phys_drive-bseg]

; 	Handoff to BIO:
;		bx = should be 0ff8-0fffh or 0fff8-0ffffh depending on FAT
;		dl = physical drive number
;		es = segment of BIO image
;		0:7C00-7C11 contain floppy drive parameters, INT1E -> 0:7C00

	jmp	dword ptr [bp+kernel_vector-bseg]

read_sectors:
	xor	bx,bx
	push	ax
	push	dx
	call	read_sector
	mov	ax,es
	add	ax,word ptr 20h	; add 20 paras = 512 byte to es
	mov	es,ax
	pop	dx
	pop	ax
	add	ax,word ptr 1	; increas 32-bit sector number
	adc	dx,0
	dec	byte ptr [bp+secs_to_read]
	jnz	read_sectors
ret_instr:
	ret
read_sector:
	div	word ptr [bp+bpb_secs_per_track-bseg]
	inc	dx
	mov	cl,dl
	xor	dx,dx
	div	word ptr [bp+bpb_heads-bseg]
	mov	dh,dl
	ror	ah,1
	ror	ah,1
	and	ah,0c0h
	or	cl,ah
	mov	ch,al
	mov	dl,[bp+bpb_phys_drive-bseg]
tryread:
	mov	ax,0201h			; read single sector
	int	13h
	jnc	ret_instr
	dec	byte ptr [bp+bpb_boot_sig-bseg] 	; boot signature = 29h mis-used
	jnz	tryread				; for retry counter
	jmp	error


print_char:
	mov	ah,0eh
	sub	bx,bx
	int	10h
print_string:
	lodsb
	test	al,al
	jnz	print_char
	ret

errormsg	db 0dh,0ah,"Cannot load DOS press key to retry",0dh,0ah

	org	510

bios_signature	db 55h, 0aah

bseg ends

end
