;    File              : $INIT.ASM$
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
;    INIT.ASM 1.25 93/12/07 15:51:27
;    Move int13pointer to offset 0B4h as some app expects it there
;    INIT.ASM 1.24 93/11/18 18:57:20
;    Increase amount reserved for COMMAND.COM by 256 bytes
;    INIT.ASM 1.23 93/11/17 19:29:26
;    Change default DEBLOCK seg to FFFF for performance reasons
;    INIT.ASM 1.19 93/07/22 19:43:59 
;    switch over to REQUEST.EQU
;    ENDLOG


	include config.equ
	include	drmacros.equ
	include	ibmros.equ
	include msdos.equ
	include	request.equ		; request header equates
	include	bpb.equ
	include	udsc.equ
	include	driver.equ
	include keys.equ		; common key definitions


ENDCODE		segment public byte 'ENDCODE'
ENDCODE		ends

RESUMECODE	segment public byte 'RESUMECODE'
RESUMECODE	ends

RESBIOS		segment public byte 'RESBIOS'
RESBIOS		ends

IDATA		segment public word 'IDATA'
IDATA		ends

DATAEND		segment public para 'INITDATA'
DATAEND		ends


; IBM AT Hardware equates

; a little macro to help locate things
; it warns us when the ORG get trampled on
orgabs	MACRO	address, name
	local	was,is
	was = offset $
	org address
	is = offset $
	if was GT is
	%OUT WARNING - absolute data overwritten !! moving it: name
	org	was
endif
ENDM

jmpfar	MACRO	address, fixup
	db	0EAh		; jmpf opcode
	dw	offset CGROUP:address	; offset of destination
fixup	dw	0EDCh		; segment of destination
ENDM

callfar	MACRO	address, fixup
	db	09Ah		; callf opcode
	dw	offset CGROUP:address	; offset of destination
fixup	dw	0EDCh		; segment of destination
ENDM

F5KEY		equ	3F00h
F8KEY		equ	4200h

SWITCH_F	equ	01h
	
IVECT	segment	at 0000h

		org	0000h*4
i0off		dw	?
i0seg		dw	?

		org	0001h*4
i1off		dw	?
i1seg		dw	?

		org	0003h*4
i3off		dw	?
i3seg		dw	?

		org	0004h*4
i4off		dw	?
i4seg		dw	?

		org	0015h*4
i15off		dw	?
i15seg		dw	?

		org	0019h*4
i19off		dw	?
i19seg		dw	?

		org	001Eh*4
i1Eptr		label	dword
i1Eoff		dw	?
i1Eseg		dw	?

		org	002Fh*4
i2Fptr		label	dword
i2Foff		dw	?
i2Fseg		dw	?

		org	006Ch*4
i6Cptr		label	dword
i6Coff		dw	?
i6Cseg		dw	?

IVECT	ends

CGROUP	group	CODE, RCODE, ICODE, INITDATA

CODE	segment public word 'CODE'

	Assume	CS:CGROUP, DS:Nothing, ES:Nothing, SS:Nothing

	public	strat
	public	kernflg
	public COMPRESS_FROM_HERE

	extrn	ConsoleTable:word
	extrn	ClockTable:word
	extrn	SerParCommonTable:word
	extrn	DiskTable:near
	extrn	Int13Deblock:near
	extrn	Int13Unsure:near
	extrn	Int2FHandler:near
	extrn	ResumeHandler:near

	extrn	biosinit_end:byte	; End of the BIOS Init Code and Data
	extrn	biosinit:near
	
	extrn	boot_options:word
	extrn	rcode_fixups:word
	extrn	rcode_seg:word
	extrn	rcode_offset:word
	extrn	rcode_len:word
	extrn	icode_len:word
	extrn	current_dos:word
	extrn	device_root:dword
	extrn	mem_size:word
	extrn	ext_mem_size:word
	extrn	init_buf:byte
	extrn	init_drv:byte
	extrn	init_int13_unit:byte
	extrn	init_runit:byte
	extrn	comspec_drv:byte
	extrn	init_flags:word
	extrn	boot_switches:byte


include	biosmsgs.def			; Include TFT Header File

	Public	A20Enable
A20Enable proc near
;========
; This location is fixed up at run time to be a RET
; If the BIOS is relocated to the HMA then it is fixed up again to be
; CALLF IBMDOS:A20Enable; RET
; Calling this location at run time will ensure that the HMA is mapped
; in so we can access the HMA code.
;
A20Enable endp

init	proc	near			; this is at BIOSCODE:0000h
	jmp	init0			; jump to zero-decompression stage
init	endp

; start offset of zero-compressed file area
compstart	dw	offset CGROUP:COMPRESS_FROM_HERE	

; kernel flags:
;   bit 0: set if assembled for compression
;   bit 1: set if assembled for single-file kernel
;   bit 7: set after kernel was processed by COMPBIOS and COMPKERN 
kernflg		db	(SINGLEFILE shl 1) + COMPRESSED

	org	06h

	db	'COMPAQCompatible'  
	dw	offset CGROUP:RCODE	; lets find offset of RCODE
MemFixup dw	0			;  and its relocated segment	


	Public	cleanup
cleanup	PROC	far			; BIOSINIT will call here later
	ret
cleanup	endp


;	Device driver headers for serial/parallel devices

con_drvr	dw	offset aux_drvr, 0	; link to next device driver
		dw	DA_CHARDEV+DA_SPECIAL+DA_ISCOT+DA_ISCIN+DA_IOCTL
		dw	offset strat, offset IntCon
		db	'CON     '
		db	'COLOUR'
col_mode	db	0,7,0

aux_drvr	dw	offset prn_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	offset strat, offset IntCOM1
		db	'AUX     '

prn_drvr	dw	offset clock_drvr, 0	; link to next device driver
		dw	DA_CHARDEV
		dw	offset strat, offset IntLPT1
		db	'PRN     '

clock_drvr	dw	disk_drvr, 0		; link to next device driver
		dw	DA_CHARDEV+DA_ISCLK
		dw	offset strat, offset IntClock
		db	'CLOCK$  '

com1_drvr	dw	offset lpt1_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	offset strat, offset IntCOM1
		db	'COM1    '

com2_drvr	dw	offset com3_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	offset strat, offset IntCOM2
		db	'COM2    '

com3_drvr	dw	offset com4_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	offset strat, offset IntCOM3
		db	'COM3    '

IFDEF EMBEDDED
	extrn	rdisk_drvr:near
com4_drvr	dw	offset rdisk_drvr, 0	; link to next device driver
ELSE		
com4_drvr	dw	-1, -1			; link to next device driver
ENDIF	
		dw	DA_CHARDEV
		dw	offset strat, offset IntCOM4
		db	'COM4    '


	orgabs	0b4h, i13pointer	; save address at fixed location
					;  for dirty apps

	Public	i13pointer, i13off_save, i13seg_save

i13pointer	label	dword		; address of ROS Int 13h entry
i13off_save	dw	?
i13seg_save	dw	?


	orgabs	0b8h, req_ptr		; REQ_HDR

	public	req_ptr, req_off, req_seg

req_ptr	label	dword
req_off	dw	0			;** fixed location **
req_seg	dw	0			;** fixed location **

;	Local single character buffer for Ctrl-Break handling
	public	serparFlag, serparChar

serparFlag	db	4 dup (FALSE)	; we haven't got any yet
serparChar	db	4 dup (?)	; will store one character

lpt1_drvr	dw	offset lpt2_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	offset strat, offset IntLPT1
		db	'LPT1    '


lpt2_drvr	dw	offset lpt3_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	offset strat, offset IntLPT2
		db	'LPT2    '

lpt3_drvr	dw	offset com2_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	offset strat, offset IntLPT3
		db	'LPT3    '

	orgabs	100h, vecSave		; save vectors at fixed location
					;  for dirty apps

	Public	orgInt13

vecSave		db	10h
		dw	0,0
		db	13h
orgInt13	dw	0,0
		db	15h
		dw	0,0
		db	19h
		dw	0,0
		db	1Bh
		dw	0,0

NUM_SAVED_VECS	equ	($ - vecSave) / 5

strat	proc	far
	mov	cs:req_off,bx
	mov	cs:req_seg,es
	ret
strat	endp

Int19Trap:
	cld
	cli				; be sure...
	push	cs
	pop	ds
	mov	si, offset vecSave
	mov	cx,NUM_SAVED_VECS	; restore this many vectors
Int19Trap10:
	xor	ax,ax			; zero AH for lodsb
	mov	es,ax			; ES -> interrupt vectors
	lodsb				; AX = vector to restore
	shl	ax,1
	shl	ax,1			; point at address
	xchg	ax,di			; ES:DI -> location to restore
	movsw
	movsw				; restore this vector
	loop	Int19Trap10		; go and do another
	cmp	word ptr ds:[oldxbda],0	; has the XBDA been moved?
	 je	Int19Trap20		; no
	mov	ax,word ptr ds:[oldmemtop]; also restore old conventional
					; memory top
	mov	es,word ptr ds:[oldxbda]; yes, move it back
	mov	cx,word ptr ds:[xbdalen]
	mov	ds,word ptr ds:[newxbda]
	xor	si,si
	xor	di,di
	rep	movsw
	mov	ds, cx			; => segment 0
	mov	word ptr ds:[40Eh], es
	mov	word ptr ds:[413h], ax
					; update BIOS data
Int19Trap20:
	int	19h			; and go to original int 19...

	even
	Public	oldxbda,newxbda,xbdalen,oldmemtop
oldxbda		dw	0		; old XBDA segment address
newxbda		dw	0		; new XBDA segment address
xbdalen		dw	0		; length of XBDA in words
oldmemtop	dw	0		; old conventional mem limit

	orgabs	16ch, devno		; PRN:/AUX: the device number

devno	db	0,0			;** fixed location **

	Public	NumDiskUnits, DeblockSeg

disk_drvr	dw	offset com1_drvr, 0	; link to next driver
		dw	DA_NONIBM+DA_GETSET+DA_REMOVE+DA_BIGDRV
		dw	offset strat, offset IntDisk
NumDiskUnits	db	5, 7 dup (?)
		dw	0EDCh		; checked by DRIVER.SYS
		dw	0		; was allocate UDSC
DeblockSeg	dw	0A000h		; segment we start deblocking


IntLPT1:				; LPT1
	call	DeviceDriver
	dw	0

IntLPT2:				; LPT2
	call	DeviceDriver
	dw	1

IntLPT3:				; LPT3
	call	DeviceDriver
	dw	2

IntCOM1:				; AUX = COM1
	call	DeviceDriver
	dw	3

IntCOM2:				; COM2
	call	DeviceDriver
	dw	4

IntCOM3:				; COM3
	call	DeviceDriver
	dw	5

IntCOM4:				; COM4
	call	DeviceDriver
	dw	6

IntCon:
	call	DeviceDriver
	dw	offset ConsoleTable

IntClock:
	call	DeviceDriver
	dw	offset ClockTable

	Public	IntDiskTable
IntDisk:
	call	DeviceDriver
IntDiskTable:
	dw	offset DiskTable

DeviceDriver	proc	near
	call	A20Enable		; make sure A20 is on
	jmpfar	DriverFunction, DriverFunctionFixup
DeviceDriver	endp

	extrn	i13_AX:word

	Public	Int13Trap

Int13Trap	proc	far
;--------
; The Int 13 code is in low memory for speed, with unusual conditions
; having the overhead of A20Enable calls
;
	cmp	ah,ROS_FORMAT		; ROS format function?
	 je	Int13TrapFormat
Int13Trap10:
	mov	cs:i13_AX,ax		; save Op/Count in case of error
	clc
	pushf				; fake an Int
	call	cs:i13pointer		; call the ROM BIOS
	 jc	Int13Trap20		; check for error
	ret	2			; none, so return to caller
Int13Trap20:
	cmp	ah,9			; it it a DMA error ?
	 je	Int13TrapDMA		;  then deblock it
	call	Int13TrapUnsure		; else declare floppy drive unsure
	stc				; restore error flag
	ret	2			; return to user

Int13TrapFormat:
	call	Int13TrapUnsure		; mark media as unsure
	jmps	Int13Trap10		;  and resume

Int13TrapDMA:
	call	A20Enable		; make sure A20 is on
	jmpfar	Int13Deblock, Int13DeblockFixup

Int13TrapUnsure proc near
	call	A20Enable		; make sure A20 is on
	callfar	Int13Unsure, Int13UnsureFixup
	ret
Int13TrapUnsure	endp

Int13Trap	endp


	Public	Int2FTrap

Int2FTrap	proc	far
;--------
	jmpfar	Int2FHandler, Int2FFixup
Int2FTrap	endp


Resume	proc	far
;-----
	call	A20Enable		; make sure A20 is on
	jmpfar	ResumeHandler, ResumeFixup
Resume	endp

Int0Trap proc	far
;-------
	call	A20Enable		; make sure A20 is on
	jmpfar	Int0Handler, Int0Fixup
Int0Trap endp

	Public	FastConsole

FastConsole  proc   far
;----------
; RAM entry to ensure INT29 vector is below INT20 vector
; We keep the normal path low to maxmimise performance, but on backspace we
; take the A20Enable hit and call high for greater TPA.
;
	pushx	<ax, bx, si, di, bp>	; old ROS corrupts these
	cmp	al,8			; back space character
	 je	Fastcon30		; special case
Fastcon10:
	push	es
	push	cx
	mov	cx,40h
	mov	es,cx
	mov	bx,cs:word ptr col_mode	; get colour mode
	xchg	bh,bl
	cmp	bh,0			; check if COLOUR is active
	 je	Fastcon15		; no, continue normally
	cmp	al,7			; check for non-printable chars
	 je	Fastcon15
	cmp	al,0ah
	 je	Fastcon13
	cmp	al,0dh
	 je	Fastcon15
	xor	bh,bh			; assume video page 0
	mov	ah,9
	mov	cx,1			; one char to display
	int	10h			; display char with given colour
	mov	bl,ah
	mov	ah,3
	int	10h
	inc	dl
	cmp	dl,es:4ah
	 jb	Fastcon12
	mov	dl,0
Fastcon11:
	inc	dh
	cmp	dh,es:84h
	 jbe	Fastcon12
	dec	dh
	push	dx
	mov	ax,601h
	xor	cx,cx
	mov	dl,es:4ah
	dec	dl
	mov	dh,es:84h
	mov	bh,cs:byte ptr col_mode+1
	int	10h
	pop	dx
Fastcon12:
	mov	ah,2
	mov	bh,es:62h
	int	10h
	jmps	Fastcon20
Fastcon13:
	mov	ah,3
	xor	bh,bh
	int	10h
	jmps	Fastcon11
Fastcon15:
	mov	ah,0eh			; use ROS TTY-like output function
	mov	bx,7			; use the normal attribute
	int	VIDEO_INT		; output the character in AL
Fastcon20:
	pop	cx
	pop	es
	popx	<bp, di, si, bx, ax>
	iret

Fastcon30:
	call	A20Enable		; make sure A20 is on
	jmpfar	OutputBS, OutputBSFixup	; call up to the HMA

FastConsole endp

	Public	ControlBreak
ControlBreak:

;-----------
	mov	cs:word ptr local_char,'C'-40h + (256*TRUE)
;;	mov	local_char,'C'-40h	; force ^C into local buffer
;;	mov	local_flag,TRUE		; indicate buffer not empty
Int1Trap:
Int3Trap:
Int4Trap:
	iret

	even
	public	daycount
daycount	dw	0



; More Disk Data

	public	local_buffer,local_id,local_pt


		even

; DRBIO/DRKERNEL uncompression and relocation stage. This is executed right
; after the jump at the beginning of the CODE segment. This area is shared
; with the 512 byte deblocking buffer and gets eventually overwritten.
;
; If the kernel is not loaded to segment 70h it is relocated to it.

init0	proc near

local_buffer 	label 	byte

	mov	cs:byte ptr A20Enable,0C3h
					; fixup the RET
	mov	si,TEMP_RELOC_SEG - 200
	mov	ss,si
	mov	sp,1024

	sti
	cld

	; the following expects ds:bp to point to the boot sector, in
	; particular the BPB, to push its hidden sectors field to stack
	; NOTE: part_off currently not used anymore
	push	ds:1eh[bp]		; push BPB hidden sectors
	push	ds:1ch[bp]		; ..popped at biosinit to part_off

	push	cx			; save entry registers
	push	di			; (important in ROM systems)

	xor	si,si
	mov	ds,si
	mov	es,si

	Assume	DS:IVECT, ES:IVECT

	; Copy diskette parameters (11 bytes) from the location stored
	; at INT1E over to 0000:0522. This MAY previously be located at 7C00
	; or another (non-)BIOS location depending on the boot sector code.
	; After copying, set INT1E to point to the new location.

	mov	di,522h			; ES:DI -> save area for parameters
	lds	si,i1Eptr		; DS:SI -> FD parameters for ROS

	Assume	DS:Nothing

	mov	i1Eoff,di
	mov	i1Eseg,es		; setup new location
	mov	cx,11
	rep	movsb
	mov	es:byte ptr [di-7],36	; enable read/writing of 36 sectors/track

	pop	di
	pop	cx

	push	ax			; ROM boot: BDOS seg
	mov	ax, cs			; preserve entry registers
	mov	ds, ax			; other than si, ds and es
	xor	si, si

	; determine which register holds the boot drive unit
	; EDR load protocol: CS=70h, DL=unit
	; FreeDOS load protocol: CS=60h, BL=unit
	; standardize to DL holding drive unit
	cmp	ax,60h			; are we loaded at segment 60h?
	jne	uncompress_and_relocate_kernel
	mov	dl,bl			; copy phys boot drive fron BL to DL

uncompress_and_relocate_kernel:
if COMPRESSED eq 0
	; if kernel is uncompressed and we live at the correct segment, then
	; skip whole uncompression and relocation
	push	cs
	pop	ax
	cmp	ax,BIO_SEG
	jne	@F
	jmp	not_compressed
@@:
endif
	push	di			; ROM boot: DL=0ffh, Disk boot: DL=phys boot drv
	push	bx			; ROM boot: memory size, Disk boot: unused
	push	cx			; ROM boot: initial drives, Disk boot: unused
	push	dx			; ROM boot: BIO seg, Disk boot: unused

	mov	ax,TEMP_RELOC_SEG
	mov	es,ax
if (SINGLEFILE eq 1) or (COMPRESSED eq 1)
	; determine kernel file size in words
	; this is set by COMPBIOS and COMPKERN tools
	mov	ax,kernel_size
else
	 ; for an uncompressed DRBIO.SYS we must determine kernel_size, as
	 ; neither COMPBIO or COMPKERN are run on this (kernel_size=0)
	mov	ax,offset CGROUP:DATAEND
	shr	ax,1
	mov	kernel_size,ax
endif
	; we now copy up to 128K to TEMP_RELOC_SEG for relocation
	; and / or uncompression
	call	copywords

	; we now far jmp to our kernel copy at TEMP_RELOC_SEG
	db	0eah
	dw	@@farjmp_tmp_seg,TEMP_RELOC_SEG	
 @@farjmp_tmp_seg:

  	mov	ax,TEMP_RELOC_SEG
  	mov	ds,ax
  	mov	ax,BIO_SEG
  	mov	es,ax

if COMPRESSED eq 1
  	; copy uncompressed part of compressed DRBIO / KERNEL to BIO_SEG
  	mov	ax,COMPRESS_FROM_HERE
  	inc	ax
  	shr	ax,1
else
  	; copy whole kernel if uncompressed
  	mov	ax,kernel_size
endif
	call	copywords

	; we now far jmp to ourself at BIO_SEG
	db	0eah
	dw	@@farjmp_bio_seg,BIO_SEG	
@@farjmp_bio_seg:

if COMPRESSED eq 1
	; now decompress the compressed part of DRBIO/KERNEL
	mov	si,COMPRESS_FROM_HERE
	mov	di,si
@@uncompress_block:
	mov	cl,4
	mov	bx,ds			; canonicalize ds:si
	mov	ax,si			; to support kernel images >64K
	shr	ax,cl			; and make sure we do not wrap around
	add	ax,bx			; at segment boundary while
	mov	ds,ax			; uncompressing
	and	si,0fh
	mov	bx,es			; canonicalize es:di
	mov	ax,di			; to support kernel images >64K
	shr	ax,cl			; and make sure we do not wrap around
	add	ax,bx			; at segment boundary while
	mov	es,ax			; uncompressing
	and	di,0fh
	lodsw				; get control word
	mov	cx,ax			; as a count
	jcxz	@@uncompress_fini	; all done
	test	cx,8000h		; negative ?
	jnz	@@uncompress_zeros	; yes do zeros
	rep	movsb			; else move in data bytes
	jmp 	@@uncompress_block	; and to the next
@@uncompress_zeros:
	and	cx,7fffh		; remove sign
	jcxz	@@uncompress_block	; none to do
	xor	ax,ax
	rep	stosb			; fill with zeros
	jmp 	@@uncompress_block
@@uncompress_fini:
endif
	pop	dx			; ROM boot: DL=0ffh, Disk boot: DL=phys boot drv
	pop	cx			; ROM boot: memory size, Disk boot: unused
	pop	bx			; ROM boot: initial drives, Disk boot: unused
	pop	di			; ROM boot: BIO seg, Disk boot: unused
not_compressed:

	pop	ax			; ROM boot: BDOS seg
	jmp	init1			; next initialization stage is
					; part of discardable ICODE segment
init0	endp

copywords proc
	; copies up to 0ffffh words
	; ax = count
	; ds:0 = source segment
	; es:0 = destination segment
	; destroyed: si, di
	xor	si,si
	xor	di,di
 	test	ax,ax
 	js	@F		; more than 64K, take long route
	mov	cx,ax
	rep	movsw
	ret
@@:	mov	cx,8000h
	rep	movsw		; copy first 64K
	sub	ax,8000h	
	mov	cx,ax		; CX now contains how much left
	mov	ax,ds
	add	ax,1000h
	mov	ds,ax		; increase DS by 1000h (64K)
	mov	ax,es
	add	ax,1000h
	mov	es,ax		; increase ES by 1000h (64K)
	rep	movsw		; copy what is left
	ret

copywords endp

kernel_size	dw	0		; kernel file size in words
					; patched by compbios and compkern
COMPRESS_FROM_HERE:

if ($ - init0) gt 512
	error "too much code in deblocking buffer"
endif
		; grow deblocking buffer to 512 byte
		db	512 - ($ - init0) dup (?)

SECSIZE		equ	512
IDOFF		equ	SECSIZE-2	; last word in boot sector is ID
PTOFF		equ	IDOFF-40h	; 4*16 bytes for partition def's
local_id	equ	word ptr local_buffer + IDOFF
local_pt	equ	word ptr local_buffer + PTOFF

	even
	Public	diskaddrpack
diskaddrpack:				; disk address packet structure for LBA access
		db	10h		; size of packet
		db	0		; reserved
		dw	1		; number of blocks to transfer
		dd	0		; transfer buffer address
		dq	0		; starting absolute block number

	public	bpbs,bpb160,bpb360,bpb720,NBPBS

;	List of BPBs that we usually support

bpb160		OLDBPB	<512,1,1,2, 64, 40*1*8,0FEh,1, 8,1,0,0>
bpb180		OLDBPB	<512,1,1,2, 64, 40*1*9,0FCh,2, 9,1,0,0>
bpb320		OLDBPB	<512,2,1,2,112, 40*2*8,0FFh,1, 8,2,0,0>
bpb360		OLDBPB	<512,2,1,2,112, 40*2*9,0FDh,2, 9,2,0,0>
bpb1200		OLDBPB	<512,1,1,2,224,80*2*15,0F9h,7,15,2,0,0>
bpb720		OLDBPB	<512,2,1,2,112, 80*2*9,0F9h,3, 9,2,0,0>
bpb1440		OLDBPB	<512,1,1,2,224,80*2*18,0F0h,9,18,2,0,0>
bpb2880		OLDBPB	<512,2,1,2,240,80*2*36,0F0h,9,36,2,0,0>
NBPBS		equ	8

;	The following is a template, that gets overwritten
;	with the real parameters and is used while formatting

	public	local_parms,parms_spt,parms_gpl
	public	layout_table,bpbtbl

local_parms	db	11011111b	; step rate
		db	2		; DMA mode
		db	37		; 2*18.2 = 2 second motor off
		db	2		; 512 bytes per sector
parms_spt	db	18		; sectors per track
		db	2Ah		; gap length for read/write
		db	0FFh		; data length (128 byte/sector only)
parms_gpl	db	50h		; data length for format
		db	0F6h		; fill byte for format
		db	15		; head settle time in ms
		db	8		; motor on delay in 1/8s

; The BPB table need not survive config time, so share with layout table

bpbtbl		label	word

	MAX_SPT	equ	40
	
layout_table	label word		; current # of sectors/track

S	= 	1

rept	MAX_SPT
		;	C  H  S  N
		;	-  -  -  -
		db	0, 0, S, 2
S	=	S + 1
endm

	orgabs	600h, local_char	; CON: one character look-ahead buffer
; nb. it's at 61B in DOS 4.0

	Public	local_char, local_flag

local_char	db	0		;** fixed location **
local_flag	db	0		;** fixed location **

	even
	public	endbios
endbios		dw	offset CGROUP:RESBIOS	; pointer to last resident byte

CODE	ends

ICODE	segment public byte 'ICODE'			; reusable initialization code

	Assume	CS:CGROUP, DS:CGROUP, ES:CGROUP, SS:Nothing

bpbs		dw	offset bpb360	; 0: 320/360 Kb 5.25" floppy
		dw	offset bpb1200	; 1: 1.2 Mb 5.25" floppy
		dw	offset bpb720	; 2: 720 Kb 3.5" floppy
		dw	offset bpb360	; 3: (8" single density)
		dw	offset bpb360	; 4: (8" double density)
		dw	offset bpb360	; 5: hard disk
		dw	offset bpb360	; 6: tape drive
		dw	offset bpb1440	; 7: 1.44 Mb 3.5" floppy
		dw	offset bpb1440	; 8: Other
		dw	offset bpb2880	; 9: 2.88 Mb 3.5" floppy

init1	proc	near

	mov	si,cs
	mov	ds,si			; DS -> local data segment
	pop	ds:part_off		; pushed at init0 from BPB hidden sectors
	pop	ds:part_off+2

	cmp	dl,0ffh			; booting from ROM?
	 jz	rom_boot
	cmp	si,1000h		; test if debugging
	 jb	disk_boot		; skip if not

;	When the BIOS is loaded by the DOSLOAD or LOADER utilities under
;	Concurrent for DEBUGGING or in a ROM system then on entry AX
;	contains the current location of the BDOS and CX the memory Size.
;	Bx is the current code segment

	mov	rcode_seg,dx		; rom segment of bios
	mov	current_dos,ax		; current location of the BDOS
	mov	mem_size,cx		; total memory size
	mov	init_drv,bl		; initial drive
	mov	comspec_drv,bh		;
	mov	init_buf,3		; assume default # of buffers
	mov	init_flags,3	
	jmp	bios_exit
	
rom_boot:				; BIOS is copied from ROM:
					; 	DL = 0FFh
					;	AX = segment address of DRBDOS
					;	BH = COMSPEC drive
					;	BL = INIT_DRV
	mov	rcode_seg,di		;	DI = BIOS ROM SEG
	mov	current_dos,ax		; current location of the BDOS
	mov	init_drv,bl		; initial drive C:
	mov	comspec_drv,bh		; commspec drive C:
	mov	init_flags,3		; it is a ROM system, use comspec drive
	jmps	rom_boot10		; common code

disk_boot:
	mov	rcode_seg,cs
	sub	ax,ax
	mov	current_dos,ax		; current BDOS location to disk load
	xchg	ax,dx			; AL = boot drive
	mov	init_runit,al		; save the ROS unit
	mov	init_int13_unit,al	; save the ROS unit
	test	al,al			; test the boot drive
	 jz	floppy_boot		; skip if floppy boot
	mov	al,2			; it's drive C:
floppy_boot:
	mov	init_drv,al		; set boot drive

rom_boot10:
	pushx	<ds, es>		; save registers
	sub	bx,bx
	mov	ds,bx			; DS:BX -> interrupt vectors

	Assume	DS:IVECT

	push	cs			; we want to save vectors some
	pop	es			;  locally

	lea	di,vecSave
	mov	cx,NUM_SAVED_VECS	; restore this many vectors
SaveVectors:
	xor	ax,ax			; zero AH
	mov	al,es:[di]		; AX = vector to save
	inc	di			; skip to save position
	shl	ax,1
	shl	ax,1			; point at address
	xchg	ax,si			; DS:SI -> location to save
	movsw
	movsw				; save this vector
	loop	SaveVectors		; go and do another

	clc
	int 	3
	jc debugger_detected

	mov	i0off,offset Int0Trap
	mov	i0seg,cs		; now grab int0 vector
	mov	i1off,offset Int1Trap
	mov	i1seg,cs		; now grab int1 vector
	mov	i3off,offset Int1Trap
	mov	i3seg,cs		; now grab int3 vector

debugger_detected:
	mov	i4off,offset Int1Trap
	mov	i4seg,cs		; now grab int4 vector
	mov	i19off,offset Int19Trap
	mov	i19seg,cs		; now grab int19 vector

	popx	<es, ds>

	Assume	DS:CGROUP, ES:CGROUP

	mov	si,offset kernel_ver_msg
	call	output_msg
	mov	si,offset repository_msg
	call	output_msg

;	call	get_boot_options	; look for user keypress
;	mov	boot_options,ax		;  return any options

	mov	ah,EXT_MEMORY
	int	SYSTEM_INT		; find out how much extended memory
	 jnc	bios_extmem
	xor	ax,ax			; say we have no memory
bios_extmem:
	mov	ext_mem_size,ax		;  we have and store for reference
	
	mov	init_buf,3		; assume default of 3 buffers
	int	MEMORY_INT		; get amount of conventional memory
	cmp	ax,128
	 jbe	bios_mem
	mov	init_buf,5		; use 5 buffers if > 128K of memory
bios_mem:				; get amount of conventional memory
	mov	cl,6			;    in kilobytes (AX)
	shl	ax,cl			; convert Kb's to paragraphs
	mov	mem_size,ax		; set end of TPA

bios_exit:
; The following code performs the fixups necessary for ROM executable
; internal device drivers.
	mov	ax,cs			; check if we are on a rommed system
	cmp	ax,rcode_seg
	 jne	keep_rcode		; if so no relocation required
	mov	ax,offset CGROUP:RCODE
	mov	rcode_offset,ax		; fixup variable need
	mov	bx,offset CGROUP:IDATA
	sub	bx,ax
	mov	icode_len,bx		; during init we need RCODE and ICODE
	mov	bx,offset CGROUP:RESUMECODE
	sub	bx,ax
	mov	rcode_header,bx
	mov	rcode_len,bx		; afterwards we just need RCODE
keep_rcode:

; If the system ROM BIOS supports RESUME mode then it will call Int 6C
; when returning from sleep mode. We take this over and reset the clock
; based upon the RTC value. To save space we only relocate the code if
; required.
;
	mov	ax,4100h		; does the BIOS support resume mode
	xor	bx,bx
	int	15h			; lets ask it
	 jc	resume_exit
	push	ds
	xor	ax,ax
	mov	ds,ax			; DS = vectors
Assume DS:IVECT
	mov	i6Coff,offset Resume
	mov	i6Cseg,cs		; point Int 6C at resume code
Assume DS:CGROUP
	pop	ds
	mov	ax,cs			; check if we are on a rommed system
	cmp	ax,rcode_seg
	 jne	resume_exit		; if so nothing extra to keep
	mov	ax,offset CGROUP:RESBIOS
	sub	ax,offset CGROUP:RCODE
	mov	rcode_header,ax		; keep Resume code as well...
	mov	rcode_len,ax		; afterwards we just need RCODE
resume_exit:
	mov	ax,offset CGROUP:ENDCODE	; discard RCODE (we will relocate it)
	mov	endbios,ax
	mov	rcode_fixups,offset bios_fixup_tbl

	mov	bx,offset con_drvr		; get first device driver in chain
	mov	word ptr device_root+0,bx
	mov	word ptr device_root+2,ds

@@next_fixup:
	cmp	word ptr [bx],0FFFFh	; last driver in BIOS?
	 je	@@fixup_done
	mov	2[bx],ds		; fix up segments in driver chain
	mov	bx,[bx]
	jmp	short @@next_fixup
@@fixup_done:
	jmp	biosinit		; jump to BIOS code

init1	endp

	public	output_msg
output_msg:
;----------------
; On Entry:
;	si = offset message_msg
; On Exit:
;	None
	pushx	<ax,bx>
	lodsb				; get 1st character (never NULL)
output_msg10:
	mov	ah,0Eh
	mov	bx,7
	int	VIDEO_INT		; TTY write of character	
	lodsb				; fetch another character
	test	al,al			; end of string ?
	 jnz	output_msg10
	popx	<bx,ax>
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
	pushx	<ax,bx,cx,si>
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
	int	VIDEO_INT
	push	cx
	mov	cl,4
	shl	dx,cl
	pop	cx
	loop	output_hex10
	mov	si,offset output_hex40
	call	output_msg
	popx	<si,cx,bx,ax>
	ret
output_hex40	db	20h,NUL		; end of string

ICODE	ends

INITDATA	segment public word 'INITDATA'

	extrn	part_off:word

; This is a zero terminated list of locations to be fixed up with the
; segment of the relocated BIOS RCODE

bios_fixup_tbl	dw	offset MemFixup
		dw	offset OutputBSFixup
		dw	offset DriverFunctionFixup
		dw	offset Int0Fixup
		dw	offset Int13DeblockFixup
		dw	offset Int13UnsureFixup
		dw	offset Int2FFixup
		dw	offset ResumeFixup
IFDEF EMBEDDED
		dw	offset RdiskFixup
endif
		dw	0

INITDATA	ends

CODE	segment
IFDEF EMBEDDED
	extrn	RdiskFixup:word
endif
CODE	ends


RCODE_ALIGN	segment public byte 'RCODE'
ifndef ROMSYS
;	db	1100h dup(0)		; reserve space for command.com
	db	1A00h dup(0)		; reserve space for command.com
endif
RCODE_ALIGN	ends

RCODE		segment public byte 'RCODE'

rcode_header	dw	0

	Public	DataSegment

DataSegment	dw	BIO_SEG		; segment address of low data/code

; Called to vector to appropriate sub-function in device driver
; The Function table address immediately follows the near call, so we can index
; into it using the return address. If the offset is in the range 0-6 it's
; actually a device number for the serial/parallel driver
;
;
; On Entry to subfunctions ES:BX -> req_hdr, DX = devno (serial/parallel)
;

FunctionTable	struc
Max	db	?
Entry	dw	?
FunctionTable	ends

	Public	DriverFunction

DriverFunction	proc	far
	cld
	sub	sp,(size P_STRUC)-4	; make space for stack variables
	push	bp			; (BP and RET are included)
	mov	bp,sp			; set up stack frame
	pushx	<ds,es>
	pushx	<ax,bx,cx,dx,si,di>	; save all registers
	mov	ds,cs:DataSegment
	mov	si,[bp+(size P_STRUC)-2]	; get return address = command table
	lodsw				; AX = following word
	xchg	ax,dx			; DX = device number (0-6)
	mov	si,offset SerParCommonTable
	cmp	dx,6			; if not a device number it's a table
	 jbe	DriverFunction10
	mov	si,dx			; DS:SI -> table
DriverFunction10:
	les	bx,req_ptr		; ES:BX -> request header
	mov	P_STRUC.REQUEST_OFF[bp],bx
	mov	P_STRUC.REQUEST_SEG[bp],es
	mov	al,es:RH_CMD[bx]	; check if legal command
	cmp	al,cs:FunctionTable.Max[si]
	 ja	cmderr			; skip if out of range
	cbw				; convert to word
	add	ax,ax			;  make it a word offset
	add	si,ax			; add index to function table
	call	cs:FunctionTable.Entry[si]
	les	bx,P_DSTRUC.REQUEST[bp]
cmddone:
	or	ax,RHS_DONE		; indicate request is "done"
	mov	es:RH_STATUS[bx],ax	; update the status for BDOS
	popx	<di,si,dx,cx,bx,ax>	; restore all registers
	popx	<es,ds>
	pop	bp
	add	sp,(size P_STRUC)-2	; discard stack variables 
	ret

cmderr:
	mov	ax,RHS_ERROR+3		; "invalid command" error
	jmps	cmddone			; return the error

DriverFunction	endp



OutputBS proc far
;-------
;	pushx	<ax, bx, si, di, bp>	; these are on the stack
	pushx	<cx, dx>
	mov	ah,3			; get cursor address
	mov	bh,0			; on page zero
	int	VIDEO_INT		; BH = page, DH/DL = cursor row/col
	test	dx,dx			; row 0, col 0
	 jz	OutputBS10		; ignore if first line
	dec	dl			; are we in column 0?
	 jns	OutputBS10		; no, normal BS
	dec	dh			; else move up one line
	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	dl,ds:byte ptr [44ah]	; DL = # of columns
	dec	dx			; DL = last column
	pop	ds
	mov	ah,2			; set cursor, DH/DL = cursor, BH = page
	int	VIDEO_INT		; set cursor address
	jmps	OutputBS20

OutputBS10:
	mov	ax,0E08h		; use ROS TTY-like output function
	mov	bx,7			; use the normal attribute
	int	VIDEO_INT		; output the character in AL
OutputBS20:
	popx	<dx, cx>
	popx	<bp, di, si, bx, ax>
	iret

OutputBS endp


Int0Handler proc far
;----------
	cld
	push	cs
	pop	ds
	mov	si,offset div_by_zero_msg	; DS:SI points at ASCIZ message
	mov	bx,STDERR		; to STDERR - where else ?
	mov	cx,1			; write one at a time
int0_loop:
	mov	dx,si			; DS:DX points at a char
	lodsb				; lets look at it first
	test	al,al			; end of string ?
	 je	int0_exit
	mov	ah,MS_X_WRITE		; write out the error
	int	DOS_INT
	 jnc	int0_loop		; if it went OK do another
int0_exit:
	mov	ax,MS_X_EXIT*256+1	; time to leave - say we got an error
	int	DOS_INT			; go for it!

Int0Handler endp

RCODE		ends

	end	init
