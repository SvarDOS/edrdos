;    File              : $Workfile$
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


	include BIOSGRPS.EQU
	include	DRMACROS.EQU
	include	IBMROS.EQU
	include MSDOS.EQU
	include	REQUEST.EQU		; request header equates
	include	BPB.EQU
	include	UDSC.EQU
	include	DRIVER.EQU

; IBM AT Hardware equates

COMPRESSED	equ	TRUE		; enables compressed changes.

; a little macro to help locate things
; it warns us when the ORG get trampled on
orgabs	MACRO	address
	local	was,is
	was = offset $
	org address
	is = offset $
	if was GT is
	if2
		%OUT ERROR - absolute data overwritten !! moving it
	endif
	org	was
endif
ENDM

jmpfar	MACRO	address, fixup
	db	0EAh		; jmpf opcode
	dw	CG:address	; offset of destination
fixup	dw	0EDCh		; segment of destination
ENDM

callfar	MACRO	address, fixup
	db	09Ah		; callf opcode
	dw	CG:address	; offset of destination
fixup	dw	0EDCh		; segment of destination
ENDM

F5KEY		equ	3F00h
F8KEY		equ	4200h
	
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


CGROUP	group	CODE, RCODE, ICODE

CG	equ	offset CGROUP

CODE	segment 'CODE'

	Assume	CS:CGROUP, DS:Nothing, ES:Nothing, SS:Nothing

	public	strat

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
	extrn	init_runit:byte
	extrn	comspec_drv:byte
	extrn	init_flags:word


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
ifndef COPYPROT
	jmp	init0			; jump to reusable init space
else
	extrn	protect:near		; Jump to Copy protection code
	jmp	protect			; which will return control to
endif					; INIT0 on completion
init	endp

compflg	label	word
ifdef COPYPROT
	dw	'  '			; stops any compression working
else
	dw	offset CGROUP:INITDATA	; compresses from INITDATA onwards
endif					; this word set to 0 when compressed

	orgabs	06h
    db  'COMPAQCompatible'  

	dw	offset CGROUP:RCODE	; lets find offset of RCODE
MemFixup dw	0			;  and its relocated segment	


	Public	cleanup
cleanup	PROC	far			; BIOSINIT will call here later
	ret
cleanup	endp

;	Local single character buffer for Ctrl-Break handling
	public	serparFlag, serparChar

serparFlag	db	4 dup (FALSE)	; we haven't got any yet
serparChar	db	4 dup (?)	; will store one character


;	Device driver headers for serial/parallel devices

con_drvr	dw	CG:aux_drvr, 0	; link to next device driver
		dw	DA_CHARDEV+DA_SPECIAL+DA_ISCOT+DA_ISCIN+DA_IOCTL
		dw	CG:strat, CG:IntCon
		db	'CON     '

aux_drvr	dw	CG:prn_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	CG:strat, CG:IntCOM1
		db	'AUX     '

prn_drvr	dw	CG:clock_drvr, 0	; link to next device driver
		dw	DA_CHARDEV
		dw	CG:strat, CG:IntLPT1
		db	'PRN     '

clock_drvr	dw	disk_drvr, 0		; link to next device driver
		dw	DA_CHARDEV+DA_ISCLK
		dw	CG:strat, CG:IntClock
		db	'CLOCK$  '

com1_drvr	dw	CG:lpt1_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	CG:strat, CG:IntCOM1
		db	'COM1    '

com2_drvr	dw	CG:com3_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	CG:strat, CG:IntCOM2
		db	'COM2    '

com3_drvr	dw	CG:com4_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	CG:strat, CG:IntCOM3
		db	'COM3    '

IFDEF EMBEDDED
	extrn	rdisk_drvr:near
com4_drvr	dw	CG:rdisk_drvr, 0	; link to next device driver
ELSE		
com4_drvr	dw	-1, -1			; link to next device driver
ENDIF	
		dw	DA_CHARDEV
		dw	CG:strat, CG:IntCOM4
		db	'COM4    '


	orgabs	0b4h			; save address at fixed location
					;  for dirty apps

	Public	i13pointer, i13off_save, i13seg_save

i13pointer	label	dword		; address of ROS Int 13h entry
i13off_save	dw	?
i13seg_save	dw	?


	orgabs	0b8h			; REQ_HDR

	public	req_ptr, req_off, req_seg

req_ptr	label	dword
req_off	dw	0			;** fixed location **
req_seg	dw	0			;** fixed location **

strat	proc	far
	mov	cs:req_off,bx
	mov	cs:req_seg,es
	ret
strat	endp

lpt1_drvr	dw	CG:lpt2_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	CG:strat, CG:IntLPT1
		db	'LPT1    '


lpt2_drvr	dw	CG:lpt3_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	CG:strat, CG:IntLPT2
		db	'LPT2    '

lpt3_drvr	dw	CG:com2_drvr, 0		; link to next device driver
		dw	DA_CHARDEV
		dw	CG:strat, CG:IntLPT3
		db	'LPT3    '

	orgabs	100h			; save vectors at fixed location
					;  for dirty apps

	Public	orgInt13

NUM_SAVED_VECS	equ	5

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
	
Int19Trap:
	cld
	cli				; be sure...
	push	cs
	pop	ds
	lea	si,vecSave
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
	int	19h			; and go to original int 19...


	orgabs	16ch			; PRN:/AUX: the device number

devno	db	0,0			;** fixed location **

	Public	NumDiskUnits, DeblockSeg

disk_drvr	dw	CG:com1_drvr, 0	; link to next driver
		dw	DA_NONIBM+DA_GETSET+DA_REMOVE+DA_BIGDRV
		dw	CG:strat, CG:IntDisk
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
	dw	offset CGROUP:ConsoleTable

IntClock:
	call	DeviceDriver
	dw	offset CGROUP:ClockTable

	Public	IntDiskTable
IntDisk:
	call	DeviceDriver
IntDiskTable:
	dw	offset CGROUP:DiskTable

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
	mov	ah,0Eh			; use ROS TTY-like output function
	mov	bx,7			; use the normal attribute
	int	VIDEO_INT		; output the character in AL
Fastcon20:
	popx	<bp, di, si, bx, ax>
	iret

Fastcon30:
	call	A20Enable		; make sure A20 is on
	jmpfar	OutputBS, OutputBSFixup	; call up to the HMA

FastConsole endp

	Public	ControlBreak

ControlBreak	proc	far
;-----------
	mov	cs:word ptr local_char,'C'-40h + (256*TRUE)
;;	mov	local_char,'C'-40h	; force ^C into local buffer
;;	mov	local_flag,TRUE		; indicate buffer not empty
Int1Trap:
Int3Trap:
Int4Trap:
	iret
ControlBreak	endp

	public	daycount
daycount	dw	0



; More Disk Data

	public	local_buffer,local_id,local_pt

local_buffer	db	512 dup (?)	; local deblocking buffer
SECSIZE		equ	512
IDOFF		equ	SECSIZE-2	; last word in boot sector is ID
PTOFF		equ	IDOFF-40h	; 4*16 bytes for partition def's
local_id	equ	word ptr local_buffer + IDOFF
local_pt	equ	word ptr local_buffer + PTOFF

	public	bpbs,bpb160,bpb360,bpb720,NBPBS

;	List of BPBs that we usually support

bpb160		BPB	<512,1,1,2, 64, 40*1*8,0FEh,1, 8,1,0,0>
bpb180		BPB	<512,1,1,2, 64, 40*1*9,0FCh,2, 9,1,0,0>
bpb320		BPB	<512,2,1,2,112, 40*2*8,0FFh,1, 8,2,0,0>
bpb360		BPB	<512,2,1,2,112, 40*2*9,0FDh,2, 9,2,0,0>
bpb1200		BPB	<512,1,1,2,224,80*2*15,0F9h,7,15,2,0,0>
bpb720		BPB	<512,2,1,2,112, 80*2*9,0F9h,3, 9,2,0,0>
bpb1440		BPB	<512,1,1,2,224,80*2*18,0F0h,9,18,2,0,0>
bpb2880		BPB	<512,2,1,2,240,80*2*36,0F0h,9,36,2,0,0>
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

	orgabs	600h			; CON: one character look-ahead buffer
; nb. it's at 61B in DOS 4.0

	Public	local_char, local_flag

local_char	db	0		;** fixed location **
local_flag	db	0		;** fixed location **

	public	endbios
endbios		dw	offset CGROUP:RESBIOS	; pointer to last resident byte

CODE	ends

ICODE	segment 'ICODE'			; reusable initialization code

	Assume	CS:CGROUP, DS:CGROUP, ES:CGROUP, SS:Nothing

bpbs		dw	CG:bpb360	; 0: 320/360 Kb 5.25" floppy
		dw	CG:bpb1200	; 1: 1.2 Mb 5.25" floppy
		dw	CG:bpb720	; 2: 720 Kb 3.5" floppy
		dw	CG:bpb360	; 3: (8" single density)
		dw	CG:bpb360	; 4: (8" double density)
		dw	CG:bpb360	; 5: hard disk
		dw	CG:bpb360	; 6: tape drive
		dw	CG:bpb1440	; 7: 1.44 Mb 3.5" floppy
		dw	CG:bpb1440	; 8: Other
		dw	CG:bpb2880	; 9: 2.88 Mb 3.5" floppy

	Public	init0
init0	proc	near
;
; We now uncompress to > (7C00h (ie. boot stack) - 700h (ie. base of code)
; This means our stack collides with our code, very bad news.
; To avoid this we switch stacks into a safer area ie. 0C000h
; The floppy parameters also live at 7C00, so we have to relocate these
; before we expand.

	mov	cs:byte ptr A20Enable,0C3h
					; fixup the RET

	mov	sp, 0C000h		; switch to magic stack

	sti
	cld

	push	cx			; save entry registers
	push	di			; (important in ROM systems)

	xor	si,si
	mov	ds,si
	mov	es,si

	Assume	DS:IVECT, ES:IVECT

	mov	di,522h			; ES:DI -> save area for parameters
	lds	si,i1Eptr		; DS:SI -> FD parameters for ROS

	Assume	DS:Nothing

	mov	i1Eoff,di
	mov	i1Eseg,es		; setup new location
	mov	cx,11
	rep	movsb
	mov	es:byte ptr 0-7[di],36	; enable read/writing of 36 sectors/track

	pop	di
	pop	cx

if COMPRESSED
	mov	si, cs			; preserve entry registers
	mov	ds, si			; other than si, ds and es
	mov	es, si
	xor	si, si
	mov	si, compflg		; Get Compresed BIOS Flag
	or	si, si			; Set to Zero if the BIOS has
	jnz	not_compressed		; been compressed
	mov	si, CG:INITDATA
	push	di			; bios_seg
	push	ax			; bdos_seg
	push	bx			; initial drives
	push	cx			; memory size
	push	dx			; initial flags
	lea	cx, biosinit_end
	sub	cx, si
	inc	cx			; length of compressed part plus one
	mov	di, cx
	neg	di			; furthest offset we can use
	and	di, 0fff0h		; on the next para below
	push	di
	push	si
	shr	cx, 1
	rep movsw			; take a copy
	pop	di			; di is now -> compressed dest
	pop	si			; this is now -> compressed source
bios_r20:
	lodsw				; get control word
	mov	cx,ax			; as a count
	jcxz	bios_r40		; all done
	test	cx,8000h		; negative ?
	jnz	bios_r30		; yes do zeros
	rep	movsb			; else move in data bytes
	jmp short bios_r20		; and to the next

bios_r30:
	and	cx,7fffh		; remove sign
	jcxz	bios_r20		; none to do
	xor	ax,ax
	rep	stosb			; fill with zeros
	jmp short bios_r20
bios_r40:
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	di
not_compressed:
endif
	mov	si,cs
	mov	ds,si			; DS -> local data segment
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

	mov	i0off,CG:Int0Trap
	mov	i0seg,cs		; now grab int0 vector
	mov	i1off,CG:Int1Trap
	mov	i1seg,cs		; now grab int1 vector
	mov	i3off,CG:Int1Trap
	mov	i3seg,cs		; now grab int3 vector
	mov	i4off,CG:Int1Trap
	mov	i4seg,cs		; now grab int4 vector
	mov	i19off,CG:Int19Trap
	mov	i19seg,cs		; now grab int19 vector

	popx	<es, ds>

	Assume	DS:CGROUP, ES:CGROUP

	call	get_boot_options	; look for user keypress
	mov	boot_options,ax		;  return any options

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
	mov	ax,CG:RCODE
	mov	rcode_offset,ax		; fixup variable need
	mov	bx,CG:IDATA
	sub	bx,ax
	mov	icode_len,bx		; during init we need RCODE and ICODE
	mov	bx,CG:RESUMECODE
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
	mov	i6Coff,CG:Resume
	mov	i6Cseg,cs		; point Int 6C at resume code
Assume DS:CGROUP
	pop	ds
	mov	ax,cs			; check if we are on a rommed system
	cmp	ax,rcode_seg
	 jne	resume_exit		; if so nothing extra to keep
	mov	ax,CG:RESBIOS
	sub	ax,CG:RCODE
	mov	rcode_header,ax		; keep Resume code as well...
	mov	rcode_len,ax		; afterwards we just need RCODE
resume_exit:
	mov	ax,CG:ENDCODE		; discard RCODE (we will relocate it)
	mov	endbios,ax
	mov	rcode_fixups,CG:bios_fixup_tbl

	mov	bx,CG:con_drvr		; get first device driver in chain
	mov	word ptr device_root+0,bx
	mov	word ptr device_root+2,ds

init1:
	cmp	word ptr [bx],0FFFFh	; last driver in BIOS?
	 je	init3
	mov	2[bx],ds		; fix up segments in driver chain
	mov	bx,[bx]
	jmps	init1
init3:
	jmp	biosinit		; jump to BIOS code

init0	endp

get_boot_options:
;----------------
; On Entry:
;	None
; On Exit:
;	AX = boot options
	mov	si,offset CGROUP:starting_dos_msg
	lodsb				; get 1st character (never NULL)
get_boot_options10:
	mov	ah,0Eh
	mov	bx,7
	int	VIDEO_INT		; TTY write of character	
	lodsb				; fetch another character
	test	al,al			; end of string ?
	 jnz	get_boot_options10
	call	option_key		; poll keyboard for a while
	 jnz	get_boot_options20	; if key available return that
	mov	ah,2			; else ask ROS for shift state
	int	16h
	and	ax,3			; a SHIFT key is the same as F5KEY
	 jz	get_boot_options20
	mov	ax,F5KEY		; ie. bypass everything
get_boot_options20:
	ret

option_key:
;----------
; On Entry:
;	None
; On Exit:
;	AX = keypress if interesting (F5/F8)
;	ZF clear if we have an interesting key
;
; Poll keyboard looking for a key press. We do so for a maximum of 36 ticks
; (approx 2 seconds).
;
	xor	ax,ax
	int	1Ah			; get ticks in DX
	mov	cx,dx			; save in CX for later
option_key10:
	push	cx		
	mov	ah,1
	int	16h			; check keyboard for key
	pop	cx
	 jnz	option_key30		; stop if key available
	push	cx
	xor	ax,ax
	int	1Ah			; get ticks in DX
	pop	cx
	sub	dx,cx			; work out elapsed time
	cmp	dx,36			; more than 2 secs ?
	 jb	option_key10
option_key20:
	xor	ax,ax			; timeout, set ZF, no key pressed
	ret

option_key30:
	cmp	ax,F5KEY		; if it is a key we want then
	 je	option_key40		;  read it, else just leave
	cmp	ax,F8KEY		;  in the type-ahead buffer
	 jne	option_key20
option_key40:
	xor	ax,ax
	int	16h			; read the key
	test	ax,ax			; clear ZF to indicate we have a key
	ret

ICODE	ends

INITDATA	segment 'INITDATA'

; This is a zero terminated list of locations to be fixed up with the
; segment of the relocated BIOS RCODE


bios_fixup_tbl	dw	CG:MemFixup
		dw	CG:OutputBSFixup
		dw	CG:DriverFunctionFixup
		dw	CG:Int0Fixup
		dw	CG:Int13DeblockFixup
		dw	CG:Int13UnsureFixup
		dw	CG:Int2FFixup
		dw	CG:ResumeFixup
IFDEF EMBEDDED
		dw	CG:RdiskFixup
endif
		dw	0

INITDATA	ends

CODE	segment	'CODE'
IFDEF EMBEDDED
	extrn	RdiskFixup:word
endif
CODE	ends


RCODE_ALIGN	segment public para 'RCODE'
ifndef ROMSYS
	db	1100h dup(0)		; reserve space for command.com
endif
RCODE_ALIGN	ends

RCODE		segment public word 'RCODE'

rcode_header	dw	0

	Public	DataSegment

DataSegment	dw	0070h		; segment address of low data/code

; Called to vector to appropriate sub-function in device driver
; The Function table address immediately follows the near call, so we can index
; into it using the return address. If the offset is in the range 0-6 it's
; actually a device number for the serial/parallel driver
;
;
; On Entry to subfunctions ES:BX -> req_hdr, DX = devno (serial/parallel)
;

FunctionTable	struc
FunctionTableMax	db	?
FunctionTableEntry	dw	?
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
	mov	si,(size P_STRUC)-2[bp]	; get return address = command table
	lodsw				; AX = following word
	xchg	ax,dx			; DX = device number (0-6)
	mov	si,offset CGROUP:SerParCommonTable
	cmp	dx,6			; if not a device number it's a table
	 jbe	DriverFunction10
	mov	si,dx			; DS:SI -> table
DriverFunction10:
	les	bx,req_ptr		; ES:BX -> request header
	mov	REQUEST_OFF[bp],bx
	mov	REQUEST_SEG[bp],es
	mov	al,es:RH_CMD[bx]	; check if legal command
	cmp	al,cs:FunctionTableMax[si]
	 ja	cmderr			; skip if out of range
	cbw				; convert to word
	add	ax,ax			;  make it a word offset
	add	si,ax			; add index to function table
	call	cs:FunctionTableEntry[si]
	les	bx,REQUEST[bp]
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
	mov	si,CG:div_by_zero_msg	; DS:SI points at ASCIZ message
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
