;    File              : $DISK.ASM$
;
;    Description       :
;
;    Original Author   : 
;
;    Last Edited By    : $Author: RGROSS$
;
;-----------------------------------------------------------------------;
;    Copyright Unpublished Work of Novell, Inc. All Rights Reserved.
;      
;    THIS WORK IS AN UNPUBLISHED WORK AND CONTAINS CONFIDENTIAL,
;    PROPRIETARY AND TRADE SECRET INFORMATION OF NOVELL, INC.
;    ACCESS TO THIS WORK IS RESTRICTED TO (I) NOVELL, INC. EMPLOYEES
;    WHO HAVE A NEED TO KNOW TO PERFORM TASKS WITHIN THE SCOPE OF
;    THEIR ASSIGNMENTS AND (II) ENTITIES OTHER THAN NOVELL, INC. WHO
;    HAVE ENTERED INTO APPROPRIATE LICENSE AGREEMENTS. NO PART OF THIS
;    WORK MAY BE USED, PRACTICED, PERFORMED, COPIED, DISTRIBUTED,
;    REVISED, MODIFIED, TRANSLATED, ABRIDGED, CONDENSED, EXPANDED,
;    COLLECTED, COMPILED, LINKED, RECAST, TRANSFORMED OR ADAPTED
;    WITHOUT THE PRIOR WRITTEN CONSENT OF NOVELL, INC. ANY USE OR
;    EXPLOITATION OF THIS WORK WITHOUT AUTHORIZATION COULD SUBJECT
;    THE PERPETRATOR TO CRIMINAL AND CIVIL LIABILITY.
;-----------------------------------------------------------------------;
;
;    *** Current Edit History ***
;    *** End of Current Edit History ***
;
;    $Log: $
;    DISK.ASM 1.1 93/11/18 17:20:12 RGROSS
;    
;    DISK.ASM 1.41 93/11/18 17:20:25 IJACK
;    
;    DISK.ASM 1.40 93/11/10 00:28:12 IJACK
;    Format changes so you can format your hard disk
;    DISK.ASM 1.39 93/11/08 21:47:25 IJACK
;    Add hidden sectors to ioctl format etc of hard disks
;    DISK.ASM 1.38 93/11/02 16:09:29 IJACK
;    Always zero BPB_HIDDEN_SECTORS on floppies - problem with PCW free disk which
;    has garbage in those fields.
;    DISK.ASM 1.37 93/10/18 17:33:18 IJACK
;    format c: fix
;    DISK.ASM 1.36 93/10/11 18:37:24 IJACK
;    media-change checks serial-numbers for 3.5" disks
;    DISK.ASM 1.35 93/10/06 22:09:16 IJACK
;    vec_save extrn replaced by orgInt13 extrn
;    DISK.ASM 1.34 93/09/03 20:13:32 IJACK
;    Fix bug in disk formatting
;    DISK.ASM 1.33 93/09/01 17:40:31 IJACK
;    update UDSC_TIMER after media check forced by drive change
;    (DBASE IV slow installation problem)
;    DISK.ASM 1.32 93/08/12 15:33:07 IJACK
;    Handle DMA error from multi-track read (ancient PC-XT hard disk)
;    DISK.ASM 1.31 93/08/03 15:29:01 IJACK
;    use serial numbers for media change detection
;    DISK.ASM 1.30 93/08/02 18:44:50 IJACK
;    don't trust the changeline if switching drives
;    DISK.ASM 1.29 93/08/02 18:38:19 IJACK
;    
;    DISK.ASM 1.28 93/08/02 14:47:38 IJACK
;    
;    DISK.ASM 1.27 93/07/29 21:00:24 IJACK
;    get rid of genpb_ptr and genpb_minor
;    DISK.ASM 1.26 93/07/26 21:18:25 IJACK
;    Correctly return UDSC_ root from Int 2F/0803
;    DISK.ASM 1.25 93/07/26 18:07:21 IJACK
;    Switch ms-windows to full screen when prompting for disk
;    DISK.ASM 1.24 93/07/23 17:34:27 IJACK
;    fix floppy/driver.sys support
;    DISK.ASM 1.23 93/07/22 20:37:42 IJACK
;    
;    DISK.ASM 1.22 93/07/22 19:43:46 IJACK
;    switch over to REQUEST.EQU
;    change floppy drive order, add get/set serial number
;    DISK.ASM 1.21 93/07/19 18:57:21 IJACK
;    Add header
;
;    ENDLOG

	include BIOSGRPS.EQU
	include	DRMACROS.EQU		; standard DR macros
	include	IBMROS.EQU		; ROM BIOS equates
	include	REQUEST.EQU		; request header equates
	include	BPB.EQU			; BIOS parameter block equates
	include	UDSC.EQU		; unit descriptor equates
	include	DRIVER.EQU		; device driver equates


int_____DISK_INT macro
	call	Int13
	endm

FASTSETTLE	equ	FALSE		; disable "head settle == 0 ms"

RETRY_MAX	equ	3		; do 3 retries if we get an error
MAX_SPT		equ	40		; maximum sectors per track

SECSIZE		equ	512
IDOFF		equ	SECSIZE-2	; last word in boot sector is ID
PTOFF		equ	IDOFF-40h	; 4*16 bytes for partition def's

DOS20_ID	equ	1		; DOS 2.0 partition, < 4086 clusters
DOS30_ID	equ	4		; DOS 3.0 partition, < 65536 sectors
DOSEX_ID	equ	5		; DOS 3.3 extended partition
DOS331_ID	equ	6		; COMPAQ DOS 3.31 partition > 32 Mb

; Now for the secure partition types
SEC_ID          equ     0C0h            ; New DR secure partition types
SEC_ID2         equ     0D0h            ; Old DR secure partition types

page
CGROUP	group	CODE, RCODE, ICODE, RESBIOS, IDATA

CG	equ	offset CGROUP

	Assume	CS:CGROUP, DS:CGROUP, ES:Nothing, SS:Nothing

IVECT	segment	at 0000h

		org	0013h*4
i13off		dw	?
i13seg		dw	?

		org	001Eh*4
i1eptr		dd	?

		org	002Fh*4
i2Foff		dw	?
i2Fseg		dw	?

		org	0472h
reset_flag	dw	?

		org	0504h
dual_byte	db	?		; multiple drive byte at 50:4

IVECT	ends

ROS	segment	at 0F000h
	org	0FFF0h
reset	proc	far
reset	endp
ROS	ends

CODE	segment	'CODE'

	extrn	endbios:word		; for device driver INIT function
	extrn	read_system_ticks:near	; get system tick count in CX/DX
	extrn	Int13Trap:near
	extrn	Int2FTrap:near
	extrn	orgInt13:dword
	extrn	i13pointer:dword
	extrn	i13off_save:word
	extrn	i13seg_save:word

	extrn	NumDiskUnits:byte
	extrn	DeblockSeg:word
	extrn	local_parms:byte
	extrn	parms_spt:byte
	extrn	parms_gpl:byte
	extrn	local_buffer:byte
	extrn	local_pt:word
	extrn	local_id:word
	extrn	layout_table:word
	extrn	bpbs:word
	extrn	bpb160:byte
	extrn	bpb360:byte
	extrn	bpb720:byte
	extrn	NBPBS:abs
	extrn	bpbtbl:word
	extrn	req_off:word
	extrn	req_seg:word


udsc_root	label	dword
		dw	-1,-1

orig_int1e_off	dw	522h
orig_int1e_seg	dw	0

new_int1e_off	dw	522h
new_int1e_seg	dw	0


	Public	i13_AX
i13_AX		label	word
i13_size	db	?		; number of sectors to xfer
i13_op		db	?		; Int13 Operation
i13_dma_ptr	label	dword
i13_dma_off	dw	?
i13_dma_seg	dw	?

activeRosUnit	db	?		; currently active ROS unit

include	biosmsgs.def				; Include TFT Header File


ifdef JAPAN
		extrn	disk_msgA_jpn	:byte
		extrn	disk_msgB_jpn	:byte
endif

;disk_msgA	db	13,10,'Insert disk for drive '
;disk_msgB	db	': any press any key when ready ', 0

page
	Assume	DS:nothing, SS:nothing, ES:nothing

CODE	ends

RCODE	segment	'RCODE'

	extrn	DataSegment:word

even
Int13	proc	near
	clc
	push	bp
	int	DISK_INT
	pop	bp
	ret
Int13	endp

ros_errors	db	03h, 80h, 08h, 10h, 40h, 04h, 06h, 00h
dos_errors	db	00h, 02h, 04h, 04h, 06h, 08h, 0Fh, 0Ch
NUMROSERR	equ	dos_errors - ros_errors

;	The following  code  is required  in order  to cope  with
;	application  programs  invoking  Int  13h  directly.   It
;	handles applications  that format floppies  or access the
;	disk via Int 13h after a floppy disk change.

	Assume	CS:CGROUP, DS:Nothing, ES:Nothing, SS:Nothing


	Public	Int13Unsure
;----------
Int13Unsure	proc	far
;----------
	sti
	cld
	push	ds
	mov	ds,cs:DataSegment
			Assume DS:CGROUP
	call	i13_unsure		; no longer sure of this drive
	pop	ds
	ret
Int13Unsure	endp

	Public	Int13Deblock

;-----------
Int13Deblock	proc	far
;-----------
; handle user programs formatting the disk
	sti
	cld
	push	ds
	mov	ds,cs:DataSegment
			Assume DS:CGROUP

	pushx	<es, bx, cx, si, di>	; save work registers
	mov	i13_dma_off,bx
	mov	i13_dma_seg,es
i13_deblock10:
	pushx	<cx, dx>
	mov	cl,4
	mov	ax,i13_dma_seg		; get transfer address
	shl	ax,cl			; get A4..A15 from segment
	add	ax,i13_dma_off		; combine with A0..A15 from offset
	not	ax			; AX = # of bytes left in 64K bank
	xor	dx,dx
	mov	cx,SECSIZE
	div	cx			; convert this to physical sectors
	mov	dl,i13_size		; see if we can xfer amount wanted
	cmp	al,dl			; capable of more than requested?
	 jb	i13_deblock20		; skip if we can do it all
	xchg	ax,dx			; we can do them all
i13_deblock20:
	les	bx,i13_dma_ptr		; do the xfer to here
	popx	<dx, cx>
	mov	ah,i13_op		; get read/write/verify operation
	test	al,al			; if zero length possible
	 jz	i13_deblock30		;  then deblock
	mov	di,es			; get transfer address
	cmp	di,DeblockSeg		;  is this in high memory ?
	 jb	i13_deblock50		;  then force through deblock buffer
i13_deblock30:
	push	ds			; if deblocking then we'd better
	pop	es			;  point at local buffer we
	mov	bx,CG:local_buffer	;  will be using for actual I/O
	cmp	i13_op,ROS_WRITE
	 jne	i13_deblock40		; skip data copy if not writing to disk
	push	ds
	push	cx
	mov	di,bx			; ES:DI -> local buffer
	lds	si,i13_dma_ptr		; DS:SI -> data to write
	mov	cx,SECSIZE/2
	rep	movsw			; copy to deblocking buffer
	pop	cx
	pop	ds
i13_deblock40:
	mov	al,1			; do a single sector via buffer
	clc
	pushf				; fake an Int
	call	i13pointer		;  to the track handler
	 jc	i13_deblock90		; stop on error
	mov	al,1			; restore AL for buggy bios's
	cmp	i13_op,ROS_READ		; if we are reading then we'll
	 jne	i13_deblock60		;  have to copy data out of
	push	cx			;  the deblocking buffer
	les	di,i13_dma_ptr		; ES:DI -> dest for data
	mov	si,CG:local_buffer	; point at local buffer which
	mov	cx,SECSIZE/2		;  contains actual data
	rep	movsw			; copy from deblocking buffer
	pop	cx
	jmps	i13_deblock60
	
i13_deblock50:
	push	ax			; save # sectors in xfer
	clc
	pushf				; fake an Int
	call	i13pointer		; do the operation
	pop	bx
	mov	al,bl			; restore AL for buggy bios's
	 jc	i13_deblock90		; stop on error
i13_deblock60:				; we succeeded in doing AL sectors
	sub	i13_size,al		; forget about those we have done
	 jbe	i13_deblock90		;  and do more if there are any
	push	ax
	mov	ah,SECSIZE/16
	mul	ah			; AX = paras to inc DMA address
	add	i13_dma_seg,ax		;  up DMA address by this amount
	pop	ax
	call	i13_point_unit		; ES:DI -> UDSC_
	 jc	i13_deblock90		; exit if we can't find it
	mov	bx,cx			; get sector/cylinder in BX
	and	bx,0003Fh		; BX = sector
	and	cx,0FFC0h		; CX = mandled cylinder bits
	add	bl,al			; work out new sector
i13_deblock70:
	mov	ax,es:UDSC_BPB+BPB_SPT[di]
	cmp	bx,ax			; still on the same track ?
	 jbe	i13_deblock80		; easy if no overflow onto next track
	sub	bx,ax			; subtract a tracks worth
	inc	dh			;  and move onto next head
	mov	al,dh			; isolate head from cylinder
	and	ax,003Fh		;  bits 10/11
	cmp	ax,es:UDSC_BPB+BPB_HEADS[di]
	 jb	i13_deblock70		; onto next track yet ?
	and	dh,0C0h			; back to head zero
	add	ch,1			; onto next track (bits 0-7)
	 jnc	i13_deblock70		; overflow to bits 8-9 ?
	add	cl,040h			; yes, "inc" bits 8/9 of cylinder
	 jnc	i13_deblock70		; overflow to bits 10-11 ?
	add	dh,040h			; yes, "inc" bits 10/11 of cylinder
	jmps	i13_deblock70

i13_deblock80:
	or	cx,bx			; recombine sector/cylinder
	jmp	i13_deblock10		;  and do some more

i13_deblock90:
	popx	<di, si, cx, bx, es>	; restore work registers
	pop	ds			; recover user DS
	ret	2			; return to user with result

i13_point_unit	proc	near
;-------------
; On Entry:
;	DL = ROS unit
; On Exit:
;	ES:DI -> UDSC_ for that unit
;	All other regs preserved
;
	les	di,udsc_root		; ES:DI -> 1st es:UDSC_
i13_point_unit10:
	cmp	dl,es:UDSC_RUNIT[di]	; find the physical unit
	 je	i13_point_unit20
	les	di,es:UDSC_NEXT[di]
	cmp	di,0FFFFh		; else try the next es:UDSC_
	 jne	i13_point_unit10
	mov	ah,09h			; return DMA error to caller as we
	stc				;  don't know about this unit
i13_point_unit20:
	ret
i13_point_unit	endp

Int13Deblock	endp

i13_unsure	proc	near
;---------
; mark physical drive DL as unsure
;
	pushx	<ds, si>
	lds	si,udsc_root
i13_unsure10:
	cmp	dl,ds:UDSC_RUNIT[si]	; does it match ROS drive?
	 jne	i13_unsure20		; skip if not
	or	ds:UDSC_FLAGS[si],UDF_UNSURE
i13_unsure20:				; next drive
	lds	si,ds:UDSC_NEXT[si]
	cmp	si,0FFFFh
	 jne	i13_unsure10
	popx	<si, ds>		; restore registers
	ret

i13_unsure	endp

	Assume	DS:Nothing, SS:Nothing, ES:Nothing

	Public	Int2FHandler

Int2FHandler	proc	far
;-----------
; On Entry we have offset/seg of next in chain on the stack
; (ie. we can pass on by a RETF)
;
	cmp	ah,8				; DRIVER.SYS support
	 je	i2F_driver
	cmp	ah,13h				; int13 intercept
	 jne	i2F_iret
;
; Int 13 interception support
; ---------------------------
;
; On Entry:
;	DS:DX -> New Int 13 vector
;	ES:BX -> Int 13 vector restored by Int 19
;
; On Exit:
;	DS:DX -> Old Int 13 vector
;	ES:BX -> Old Int 13 vector restored by Int 19
;
i2F_i13_intercept:
	mov	ax,ds
	mov	ds,cs:DataSegment
			Assume DS:CGROUP
	xchg	dx,ds:i13off_save
	xchg	ax,ds:i13seg_save
	push	ax
	xchg	bx,ds:word ptr orgInt13
	mov	ax,es
	xchg	ax,ds:word ptr orgInt13+2
	mov	es,ax
	pop	ds
			Assume DS:Nothing
i2F_iret:
	iret


;
; DRIVER.SYS support
; -------------------
;
; On Entry:
;	AX=0800, installation check
;	AX=0801, add new block device at DS:SI
;	AX=0802, execute driver request at ES:BX
;	AX=0803, return address of first es:UDSC_
;
i2F_driver:
	cmp	al,1
	 jb	i2F_driver_check
	 je	i2F_driver_add
	cmp	al,3
	 jb	i2F_driver_req
	 je	i2F_driver_point
	iret

i2F_driver_check:
;
; Installation check
;
	mov	al,0ffh			; say we are installed
	iret

i2F_driver_add:
;
; Add new block device DS:DI
;
	push	ds
	push	es
	push	ds
	pop	es			; ES:DI -> unit
	mov	ds,cs:DataSegment
	call	add_unit
	pop	es
	pop	ds
	iret

i2F_driver_point:
;
; return DS:DI -> first UDSC_
;
	mov	ds,cs:DataSegment	; DS -> our data
	lds	di,ds:udsc_root
	iret
;
; Execute DRIVER.SYS request ES:BX
;
i2F_driver_req:
	push	ds
	mov	ds,cs:DataSegment
			Assume DS:CGROUP
	mov	ds:req_off,bx			; fill in request pointer
	mov	ds:req_seg,es			;  as if it was local
	pop	ds
			Assume DS:Nothing
	push	cs:driverTable			; fiddle the table address
	jmp	DriverFunction			;  then go to normal handler

	extrn	DriverFunction:near
	extrn	IntDiskTable:word		; = DiskTable

driverTable	dw	CG:IntDiskTable		; push address of table on
						; stack as DriverFunction
						; examines it

Int2FHandler	endp

	Assume	DS:CGROUP, SS:Nothing, ES:Nothing

	Public	DiskTable

DiskTable label word
	db	24			; Last supported function
	dw	CG:dd_init		; 0-initialize driver
	dw	CG:dd_medchk		; 1-media change check
	dw	CG:dd_build_bpb		; 2-build BIOS Parameter Block
	dw	CG:dd_error		; 3-IOCTL string input
	dw	CG:dd_input		; 4-input
	dw	CG:dd_error		; 5-nondestructive input (char only)
	dw	CG:dd_error		; 6-input status (char only)
	dw	CG:dd_error		; 7-input flush
	dw	CG:dd_output		; 8-output
	dw	CG:dd_output_vfy	; 9-output with verify
	dw	CG:dd_error		; 10-output status (char only)
	dw	CG:dd_error		; 11-output flush (char only)
	dw	CG:dd_error		; 12-IOCTL string output
	dw	CG:dd_open		; 13-device open
	dw	CG:dd_close		; 14-device close
	dw	CG:dd_remchk		; 15-removable media check
	dw	CG:dd_error		; 16-n/a
	dw	CG:dd_error		; 17-n/a
	dw	CG:dd_error		; 18-n/a
	dw	CG:dd_genioctl		; 19-generic IOCTL
	dw	CG:dd_error		; 20-n/a
	dw	CG:dd_error		; 21-n/a
	dw	CG:dd_error		; 22-n/a
	dw	CG:dd_getdev		; 23-get logical drive
	dw	CG:dd_setdev		; 24-set logical drive

driver	proc	near

point_unit:	; get unit descriptor for work drive
;----------
; On Entry:
;	ES:BX -> Request Header
; On Exit:
;	AL = logical drive
;	ES:DI -> es:UDSC_
;	(All other registers preserved)
;
	mov	al,es:RH_UNIT[bx]	; get the unit number (0=A:, 1=B:, etc)
	les	di,udsc_root		; ES:DI -> 1st es:UDSC_
point_unit10:
	cmp	al,es:UDSC_DRIVE[di]	; stop if the logical drive matches
	 je	point_unit20	
	les	di,es:UDSC_NEXT[di]
	cmp	di,0FFFFh		; else try the next es:UDSC_
	 jne	point_unit10
	pop	ax			; don't return to the caller
	mov	ax,RHS_ERROR+1		; return "invalid unit" error
point_unit20:
	ret

add_unit:	; add a new unit to the list
;--------
; On Entry:
;	ES:DI -> UDSC to add
; On Exit:
;	ES:DI preserved
;
	mov	al,es:UDSC_DRIVE[di]	; get the logical unit
	cmp	al,MAXPART		; is it too many ?
	 jae	add_unit40
	push	ds
	mov	es:word ptr UDSC_NEXT[di],0FFFFh
					; make sure it's terminated
	and	es:UDSC_FLAGS[di],UDF_HARD+UDF_CHGLINE
	lea	si,udsc_root		; DS:SI -> [first UDSC_]
add_unit10:
	cmp	ds:word ptr UDSC_NEXT[si],0FFFFh
	 je	add_unit30
	lds	si,ds:UDSC_NEXT[si]	; DS:SI -> UDSC_ we already have
	mov	al,es:UDSC_RUNIT[di]
	cmp	al,ds:UDSC_RUNIT[si]	; do the logical units match ?
	 jne	add_unit10
	mov	ax,ds:UDSC_FLAGS[si]	; inherit some flags
	push	ax
	and	ax,UDF_HARD+UDF_CHGLINE
	mov	es:UDSC_FLAGS[di],ax	; hard disk/changeline inherited
	pop	ax
	test	ax,UDF_HARD
	 jnz	add_unit10		; skip owner stuff on hard drive
	test	ax,UDF_VFLOPPY		; is this a multiple drive anyway ?
	 jnz	add_unit20
	or	ax,UDF_OWNER+UDF_VFLOPPY
	mov	ds:UDSC_FLAGS[si],ax	; no, 1st person becomes owner
add_unit20:
	or	es:UDSC_FLAGS[di],UDF_VFLOPPY
	jmps	add_unit10		; go and try the next
add_unit30:
	mov	ds:word ptr UDSC_NEXT[si],di
	mov	ds:word ptr UDSC_NEXT+2[si],es
	pop	ds
add_unit40:
	ret

dd_error:	; 3-IOCTL string input
;--------
	mov	ax,RHS_ERROR+3		; "invalid command" error
	ret

dd_medchk:	; 1-media change check
;---------
;	entry:	ES:BX -> request header
;	exit:	RH1_RETURN = 0, 1 or FF
;		  00 = media may have changed
;		  01 = media hasn't changed
;		  FF = media has been changed

	call	point_unit		; get unit descriptor
	test	es:UDSC_FLAGS[di],UDF_HARD
	 jnz	medchk2			; "hasn't changed" if hard disk
	call	ask_for_disk		; make sure we've got correct floppy
	mov	ax,es:UDSC_FLAGS[di]	; get flags
	test	ax,UDF_UNSURE		; has format/diskcopy occurred?
	 jnz	medchk6			; may have changed to different format
	test	ax,UDF_CHGLINE
	 jz	medchk3			; skip ROS call if no change line
	mov	dl,es:UDSC_RUNIT[di]
	mov	al,dl			; don't trust changeline if we are
	xchg	al,activeRosUnit	;  changing floppies
	cmp	al,dl			; return may have changed
	 jne	medchk3
	mov	ah,ROS_DSKCHG		; get disk change status function
	int_____DISK_INT		; AH=0: DC low, AH=6: DC active
	 jc	medchk5			; disk change not active?
medchk2:
	mov	al,01h			; disk hasn't changed
	jmps	medchk_ret


medchk3:				; no changeline support, use timer
	call	read_system_ticks	; get system tick count in CX/DX
	mov	ax,dx
	xchg	ax,es:UDSC_TIMER[di]	; get previous time and update
	sub	dx,ax
	mov	ax,cx
	xchg	ax,es:UDSC_TIMER+2[di]
	sbb	cx,ax			; CX/DX = # ticks since last access
	 jne	medchk5			; media could have changed if > 64k
	cmp	dx,18*3			; more than three seconds expired?
	 jb	medchk2			; "not changed" if access too recent
medchk5:
	mov	cx,1			; read track 0, sector 1 (boot sector)
	call	login_read		; to check the builtin BPB
	 jc	medchk6			; may have changed if read error
	mov	al,local_buffer+11+BPB_FATID
	cmp	al,0F0h			; check if we find a BPB
	 jb	medchk6			; may have changed if not good BPB
	cmp	al,es:UDSC_BPB+BPB_FATID[di]
	 jne	medchk8			; has media byte changed ?
	mov	si,offset CGROUP:local_buffer+UDSC_BPB_LENGTH+11+2
	lodsb				; get extended boot
	sub	al,29h			; do we have an extended boot ?
	 je	medchk7			; no, test against our dummy value
	push	cs
	pop	ds			; DS:SI -> our dummy value
	mov	si,offset CGROUP:dummyMediaID
medchk7:
	push	di
	lea	di,UDSC_SERIAL[di]
	mov	cx,2
	repe	cmpsw			; is serial number unchanged ?
	pop	di
	 je	medchk6			; then return may have changed
medchk8:
	lea	ax,UDSC_LABEL[di]	; ES:AX -> ASCII label
	lds	bx,REQUEST[bp]
	mov	ds:word ptr RH1_VOLID[bx],ax
	mov	ds:word ptr RH1_VOLID+2[bx],es
	mov	al,0FFH			; return disk changed
	jmps	medchk_ret

medchk6:
	mov	al,00h			; disk may have changed

medchk_ret:
	and	es:UDSC_FLAGS[di],not UDF_UNSURE
	les	bx,REQUEST[bp]
	mov	es:RH1_RETURN[bx],al	; set return value
	sub	ax,ax
	ret


	page
dd_build_bpb:	; 2-build BIOS Parameter Block
;------------
	call	point_unit		; get unit descriptor
	test	es:UDSC_FLAGS[di],UDF_HARD
	 jnz	bldbpb1			; BPB doesn't change for hard disks
	call	login_media		; try to determine media type (BPB)
	 jc	bldbpb_err
bldbpb1:
	mov	es:UDSC_OPNCNT[di],0	; no files open at this time
	and	es:UDSC_FLAGS[di],not UDF_UNSURE
					; media is sure
	lea	si,UDSC_BPB[di]
	mov	ax,es
	les	bx,REQUEST[bp]
	mov	es:RH2_BPBOFF[bx],si	; return the current BPB
	mov	es:RH2_BPBSEG[bx],ax

	xor	ax,ax
	ret

bldbpb_err:
	jmp	xlat_error		; return error code
;	ret



login_media:		; determine BPB for new floppy disk
;-----------
	push	ds
	mov	cx,1			; read track 0, sector 1 (boot)
	call	login_read		; to determine media type
	 jc	login_media_err		; abort if physical error
	cmp	local_buffer+11+BPB_FATID,0F0h
	 jb	login_media10		; fail unless FATID sensible
	lodsw				; get JMP instruction from boot sector
	xchg	ax,bx			; save in BX
	lodsb				; get next 3rd byte in AX
	add	si,8			; skip JMP, OEM name, SI -> BPB
	cmp	bl,0E9h			; does it start with a JMP ?
	 je	login_media40
	cmp	bl,069h
	 je	login_media40
	cmp	bl,0EBh			; how about a JMPS ?
	 jne	login_media10
	cmp	al,090h			; then we need a NOP
	 je	login_media40
login_media10:
	mov	cx,2			; read track 0, sector 2 (FAT)
	call	login_read		; try to read the sector
	 jc	login_media_err		; abort if physical error
	cmp	word ptr 1[si],-1	; bytes 1, 2 must be 0FFh, 0FFh
	 jne	login_media30		; default media if bad FAT
	lodsb				; else get FAT ID byte
	mov	si,CG:bpb160		; look through builtin BPB table
	mov	cx,NBPBS		; # of builtin BPBs
login_media20:
	cmp	al,BPB_FATID[si]	; does it match one we know?
	 je	login_media40		; yes, use builtin BPB
	add	si,BPB_LENGTH		; else move to next BPB
	loop	login_media20		; repeat for all BPBs
login_media30:				; can't find that FAT ID
	lea	si,UDSC_DEVBPB[di]	; use the default type
	push	es
	pop	ds			; use BPB at DS:SI ->
login_media40:
	push	di
	lea	di,UDSC_BPB[di]		; ES:DI -> unit descriptor (UDSC)
	mov	cx,UDSC_BPB_LENGTH	; size of a BPB (less reserved stuff)
	rep	movsb			; copy into unit descriptor
	pop	di
	mov	es:UDSC_BPB+BPB_SECSIZ[di],SECSIZE
;	mov	cx,0
	mov	es:word ptr (UDSC_BPB+BPB_HIDDEN)[di],cx
	mov	es:word ptr (UDSC_BPB+BPB_HIDDEN+2)[di],cx
	cmp	si,offset CGROUP:local_buffer+UDSC_BPB_LENGTH+11
	 jne	login_media50		; is the BPB from the boot sector ?
;	mov	ax,ds			; if so then check for media id
;	cmp	ax,cs:DataSegment	; seg check redundant as UDSC_DEVBPB
;	 jne	login_media50		;  is followed by 7 bytes of zero
	lodsw				; skip 2 bytes
	lodsb				; now get possible boot signature
	cmp	al,29h			; is it an extended boot sector ?
	 je	login_media60		; yes, use it
login_media50:
	push	cs
	pop	ds			; DS:SI -> our dummy value
	mov	si,offset CGROUP:dummyMediaID
login_media60:
	call	UpdateMediaID		; update UDSC_ with media info
	clc
login_media_err:
	pop	ds
	ret

dummyMediaID	dd	0	; serial number 0
		db	'NO NAME    '
		db	'FAT12   '

UpdateMediaID:
;-------------
; On Entry:
;	DS:SI -> extended boot record info
;	ES:DI -> UDSC_ to update
; On Exit:
;	ES:DI preserved
;
	push	di
	xor	ax,ax			; AX = a handy zero	
	lea	di,UDSC_SERIAL[di]
	movsw
	movsw				; copy serial number
	pop	di
	push	di
	lea	di,UDSC_LABEL[di]
	mov	cx,11
	rep	movsb			; copy the volume label
	stosb				; zero terminate it
	pop	di
	push	di
	lea	di,UDSC_FSTYPE[di]
	movsw
	movsw
	movsw
	movsw				; copy the file system type
	stosb				; zero terminate it
	pop	di
	ret


login_read:
;	entry:	CH, CL = cylinder/sector to read
;	exit:	CY = 1, AH = status if error
;		else local_buffer filled in

	mov	dl,es:UDSC_RUNIT[di]	; DL = ROS drive
	mov	dh,0			; DH = head number

login_read_dx:				; read on drive DL, head DH
;-------------				; (entry for hard disk login)
	mov	P_RETRY[bp],RETRY_MAX	; initialize retry count
logrd1:
	push	es
	mov	ax,ROS_READ*256 + 1	; read one sector from ROS
	push	ds
	pop	es			; ES = DS = local segment
	mov	bx,CG:local_buffer
	int_____DISK_INT		; call the ROM BIOS
	pop	es
	 jnc	logrd3			; skip if no disk error
	push	ax
;	mov	ah,ROS_RESET
	xor	ax,ax
	int_____DISK_INT		; reset the drive
	pop	ax
	dec	P_RETRY[bp]
	 jnz	logrd1			; loop back if more retries
logrd2:
	stc
logrd3:
	mov	si,CG:local_buffer
	ret

	page
dd_output:	; 8-output
;---------
	mov	P_ROSCMD[bp],ROS_WRITE	; write to floppy/hard disk
	jmps	io_common

dd_output_vfy:	; 9-output with verify
;-------------
	mov	P_ROSCMD[bp],ROS_VERIFY	; write & verify floppy/hard disk
	jmps	io_common

dd_input:	; 4-input
;--------
	mov	P_ROSCMD[bp],ROS_READ	; read from floppy/hard disk
;	jmps	io_common

io_common:				; common code for the above three
	call	point_unit		; get unit descriptor
	call	ask_for_disk		; make sure we've got correct floppy
	call	setup_rw		; setup for read/write operation
	 jc	io_ret			; return if bad parameters
io_loop:
	call	track_rw		; read as much as possible on track
	 jc	xlat_error		; return if physical disk error
	cmp	P_COUNT[bp],0		; test if any more stuff to read
	 jne	io_loop			; yes, loop back for more

	mov	al,es:UDSC_RUNIT[di]	; remember the drive that is active
	mov	activeRosUnit,al
	test	es:UDSC_FLAGS[di],UDF_HARD+UDF_CHGLINE
	 jnz	io_exit			; skip timer read for hard/changeline

	call	read_system_ticks	; get system tick count in CX/DX
	mov	es:UDSC_TIMER[di],dx
	mov	es:UDSC_TIMER+2[di],cx	; save time of successful access
io_exit:
	xor	ax,ax			; all done, no error encountered
io_ret:
	ret

xlat_error:	;  translate ROS error to DOS error
;----------
;	entry:	AH = ROS disk error code, CY = 1
;	exit:	AX = status to be returned to BDOS

	pushx	<es, di>		; save some registers
	mov	al,ah			; AL = ROS error code
	push	cs
	pop	es
	mov	di,CG:ros_errors	; ES:DI -> ROS error code table
	mov	cx,NUMROSERR
	repne	scasb			; scan for match
	mov	ax,RHS_ERROR		; get basic error indication
	or	al,cs:(CG:dos_errors-CG:ros_errors-1)[di]
					; combine with type of error
	popx	<di, es>
	stc
	ret



setup_rw:	; prepare for INPUT, OUTPUT or OUTPUT_VFY
;--------
; On Entry:
;	ES:DI -> UDSC
; On Exit:
;	if CY == 0:
;	  P_CYL, P_HEAD, P_SECTOR,
;	  P_DMAOFF, P_DMASEG, P_COUNT initialized
;	if CY == 1: invalid parameters detected
;	ES:DI preserved

	push	ds
	lds	bx,REQUEST[bp]
	mov	ax,ds:RH4_BUFOFF[bx]	; get offset of transfer buffer
	mov	P_DMAOFF[bp],ax		; set transfer offset
	mov	ax,ds:RH4_BUFSEG[bx]	; get segment of transfer buffer
	mov	P_DMASEG[bp],ax		; set transfer segment
	mov	ax,ds:RH4_COUNT[bx]	; get sector count from request header
	mov	P_COUNT[bp],ax		; save it locally for later
	mov	ax,ds:RH4_SECTOR[bx]	; get low 16 bit of sector #
	sub	dx,dx			; assume value is 16 bit only
	cmp	ds:RH_LEN[bx],22	; check if small request
	 je	setrw2			; if so forget the rest
	cmp	ds:RH_LEN[bx],24	; check if large request
     jne    setrw1          
	mov	dx,ds:RH4_SECTOR+2[bx]	; yes, get 32-bit record number
	jmps	setrw2
setrw1:	
	cmp	ds:RH_LEN[bx],30
     jne    setrw2          
	cmp	ax,-1			; magic number indicating it's
	 jne	setrw2			; a 32-bit record number
	mov	ax,ds:RH4_BIGSECTORLO[bx]
	mov	dx,ds:RH4_BIGSECTORHI[bx]
setrw2:
	pop	ds

	mov	cx,P_COUNT[bp]		; get requested count
	 jcxz	setrw3			; invalid count
	dec	cx			; CX = count - 1
	cmp	es:word ptr (UDSC_BPB+BPB_TOTSEC)[di],0
	 jne	setrw4			; skip if < 65536 sectors on disk
	add	ax,cx
	adc	dx,0			; AX/DX = # of last sector for I/O
	 jc	setrw3			; error if > 32 bits
	cmp	dx,es:word ptr (UDSC_BPB+BPB_SIZE+2)[di]
	 ja	setrw3			; skip if too large
	 jb	setrw5			; O.K. if small enough
	cmp	ax,es:word ptr (UDSC_BPB+BPB_SIZE)[di]
	 jb	setrw5			; fail if too large
setrw3:
	mov	ax,RHS_ERROR+8		; return "sector not found"
	stc
	ret

setrw4:					; less than 65536 records
	add	ax,cx			; compute end of transfer
	 jc	setrw3			; skip if overflow
	cmp	ax,es:UDSC_BPB+BPB_TOTSEC[di]
	 jae	setrw3			; skip if too large
setrw5:
	sub	ax,cx
	sbb	dx,0			; add partition address for hard disk
	add	ax,es:word ptr (UDSC_BPB+BPB_HIDDEN)[di]
	adc	dx,es:word ptr (UDSC_BPB+BPB_HIDDEN+2)[di]
	push	ax			; AX/DX = 32 bit starting record address
	push	dx			; save starting record
	mov	ax,es:UDSC_BPB+BPB_SPT[di]
	mul	es:UDSC_BPB+BPB_HEADS[di]; get sectors per track * heads
	mov	cx,ax			; CX = sectors per cylinder
	pop	dx			; recover 32 bit start block
	pop	ax
	div	cx			; AX = cylinder #, DX = head/sec offset
	mov	P_CYL[bp],ax		; save physical cylinder number
	xor	ax,ax			; make remainder 32 bit so
	xchg	ax,dx			; DX:AX = (head # * SPT) + sector #
	div	es:UDSC_BPB+BPB_SPT[di]	; divide by sectors per track
	mov	P_SECTOR[bp],dl		; DX = sector #, AX = head #
	mov	P_HEAD[bp],al		; save physical sector/head for later

	clc				; tell them we like the parameters
	ret				; we've figured out starting address

track_rw:
;--------
;	entry:	P_CYL    = cylinder for start of transfer
;		P_HEAD   = head # for start of transfer
;		P_SECTOR = sector # for start of transfer
;		P_COUNT  = remaining sector count
;		P_DMAOFF = transfer offset
;		P_DMASEG = transfer segment
;		ES:DI -> UDSC structure
;	exit:	CY = 0 if no error, P_COUNT = remaining sectors
;		CY = 1 if error, AH = ROS error code

	call	track_setup		; compute size of transfer
if FASTSETTLE
	call	new_settle		; set new head settle delay
endif
	cmp	P_DIRECT[bp],0		; DMA boundary problem?
	 jne	trkrw10			; no, direct transfer performed
	cmp	P_ROSCMD[bp],ROS_READ
	 je	trkrw10			; skip if not writing to disk
	pushx	<ds, es, di>
	mov	cx,SECSIZE/2		; CX = # of word per sector
	push	ds
	pop	es			; ES:DI -> destination
	mov	di,CG:local_buffer
	lds	si,P_DMA[bp]		; DS:SI -> source
	rep	movsw			; copy from deblocking buffer
	popx	<di, es, ds>
trkrw10:
	mov	P_RETRY[bp],RETRY_MAX	; perform up to three retries
trkrw20:				; loop back here for retries
	mov	cx,P_CYL[bp]		; get cylinder #
	xchg	cl,ch			; CH = bits 0..7, CL = bits 8..11
	ror	cl,1
	ror	cl,1			; cylinder bits 8..9 in bits 6..7
	mov	dh,cl			; cylinder bits 10.11 in bits 0..1
	and	cl,11000000b		; isolate cylinder bits 8..9
	add	cl,P_SECTOR[bp]		; bits 0..5 are sector number
	inc	cx			; make it one-relative for ROS
	ror	dh,1
	ror	dh,1			; cylinder bits 10..11 in bits 6..7
	and	dh,11000000b		; isolate cylinder bits 10..11
	add	dh,P_HEAD[bp]		; add physical head number
	mov	dl,es:UDSC_RUNIT[di]	; get ROS unit #

	push	es
	mov	ax,ds
	mov	es,ax
	mov	bx,CG:local_buffer	; point at our local buffer
	cmp	P_DIRECT[bp],0		; DMA boundary problem?
	 je	trkrw30			; no, direct transfer performed
	les	bx,P_DMA[bp]		; ES:BX -> transfer address
trkrw30:
	mov	ax,P_MCNT[bp]		; AL = physical sector count
	mov	ah,P_ROSCMD[bp]		; AH = ROS read command
	cmp	ah,ROS_VERIFY		; write with verify?
	 jne	trkrw40			; skip if ROS_READ or ROS_WRITE
	mov	ah,ROS_WRITE		; else first perform normal write
	int_____DISK_INT		; call ROS to write to disk
	 jc	trkrw50			; skip if any errors occurred
	mov	ax,P_MCNT[bp]		; else get sector count
	mov	ah,ROS_VERIFY		; verify disk sectors
trkrw40:				; AH = function, AL = count
	int_____DISK_INT		; read/write/verify via ROM BIOS
trkrw50:				; CY = 1, AH = error code
	pop	es
	 jnc	trkrw70			; skip if no errors occurred
	call	disk_reset		; reset the hardware
	cmp	ah,11h			; ECC corrected data?
	 je	trkrw60			; first sector known to be good
	cmp	ah,03h			; write protect error
	 je	trkrw_error		; don't recover, report to user
	dec	P_RETRY[bp]		; count # of errors so far
	 jnz	trkrw20			; retries done, declare it permanent
trkrw_error:				; disk error occurred
if FASTSETTLE
	call	old_settle		; restore head settle delay
endif
	stc				; CY = 1 indicates error, AH = code
	ret

trkrw60:				; ECC error, only 1st sector OK
	mov	P_MCNT[bp],1		; say we have done one sector
trkrw70:				; read/write/verify succeeded
	cmp	P_DIRECT[bp],0		; DMA boundary problem?
	 jne	trkrw80			; no, direct transfer performed
	cmp	P_ROSCMD[bp],ROS_READ
	 jne	trkrw80			; skip if not reading from disk
	pushx	<di, ds, es>
	mov	cx,SECSIZE/2		; CX = # of word per sector
	mov	si,CG:local_buffer
	les	di,P_DMA[bp]		; DS:SI -> source, ES:DI -> destination
	rep	movsw			; copy from deblocking buffer
	popx	<es, ds, di>
trkrw80:
	mov	ax,P_MCNT[bp]		; get physical transfer length
	sub	P_COUNT[bp],ax		; subtract from total transfer length
	 jz	trkrw90			; exit if none left
	add	P_SECTOR[bp],al		; update current sector
	mov	ah,SECSIZE/16
	mul	ah			; AX = paras to inc DMA address
	add	P_DMASEG[bp],ax		; update DMA segment
	xor	ax,ax
	mov	al,P_SECTOR[bp]		; get current sector
	cmp	ax,es:UDSC_BPB+BPB_SPT[di]
	 jb	trkrw90			; skip if on same track
	mov	P_SECTOR[bp],0		; else start at beginning of new track
	inc	P_HEAD[bp]		; move to the next head
	mov	al,P_HEAD[bp]		; get current head
	cmp	ax,es:UDSC_BPB+BPB_HEADS[di]
	 jb	trkrw90			; did we go over end of cylinder?
	mov	P_HEAD[bp],0		; start with first head...
	inc	P_CYL[bp]		;  ... on the next cylinder
trkrw90:
if FASTSETTLE
	call	old_settle		; restore head settle delay
endif
	clc				; indicate no errors
	ret



disk_reset:
;----------
;	entry:	DL = ROS drive code

	push	ax			; save the error status
;	mov	ah,ROS_RESET		; try a restore
	xor	ax,ax
	int_____DISK_INT		; might sort things out
	pop	ax			; restore error status
	ret


track_setup:		; prepare for I/O on disk track
;-----------
;	entry:	P_CYL    = cylinder for start of transfer
;		P_HEAD   = head # for start of transfer
;		P_SECTOR = sector # for start of transfer
;		P_COUNT  = remaining sector count
;		P_DMAOFF = transfer offset
;		P_DMASEG = transfer segment
;		ES:DI -> UDSC structure
;	exit:	P_DIRECT = 1 if no deblocking
;		P_MCNT = # of sectors possible in one ROS call


	mov	ax,P_DMASEG[bp]		; get transfer address
	cmp	ax,DeblockSeg		; is this in high memory ?
	 jae	trksu20			;  then force through deblock buffer
	mov	ax,P_COUNT[bp]		; assume we can transfer all
	mov	P_MCNT[bp],ax		;  that's requested this time
	mov	P_DIRECT[bp],1		;  directly to destination
	test	es:UDSC_RUNIT[di],80h	; is it a hard disk transfer ?
	 jnz	trksu30			;  yes, transfer the lot
; floppy transfer, break up into tracks
	mov	dx,es:UDSC_BPB+BPB_SPT[di]
					; DX = sectors per track
	sub	dl,P_SECTOR[bp]		; subtract starting sector
	cmp	dx,ax			; more than we want?
	 jae	trksu10			; no, use this count
	mov	P_MCNT[bp],dx		; set count for this pass
trksu10:
	mov	ax,P_DMASEG[bp]		; get transfer address
	mov	cl,4
	shl	ax,cl			; get A4..A15 from segment
	add	ax,P_DMAOFF[bp]		; combine with A0..A15 from offset
	not	ax			; AX = # of bytes left in 64K bank
	sub	dx,dx
	mov	cx,SECSIZE
	div	cx			; convert this to physical sectors
	cmp	ax,P_MCNT[bp]		; capable of more than requested?
	 jae	trksu30			; skip if we can do it all
	mov	P_MCNT[bp],ax		; else update possible transfer length
	test	ax,ax			; can we transfer anything at all?
	 jnz	trksu30			; yes, perform the transfer
trksu20:
	mov	P_MCNT[bp],1		; single sector transfer via buffer
	mov	P_DIRECT[bp],0		; if DIRECT = 0, deblocked transfer
trksu30:
	ret




if FASTSETTLE
new_settle:
;----------
	test	es:UDSC_FLAGS[di],UDF_HARD	; fix head settle on floppies
	 jnz	new_settle9
	cmp	P_ROSCMD[bp],ROS_READ
	 jne	new_settle9
	push	ax
	pushx	<bx, ds>
	sub	ax,ax
	mov	ds,ax
	Assume	DS:IVECT
	lds	bx,i1eptr
	xchg	al,9[bx]
	Assume	DS:CGROUP
	popx	<ds, bx>
	mov	P_SETTLE[bp],al
	pop	ax
new_settle9:
	ret

old_settle:
;----------
	test	es:UDSC_FLAGS[di],UDF_HARD	; fix head settle on floppies
	 jnz	old_settle9
	cmp	P_ROSCMD[bp],ROS_READ
	 jne	old_settle9
	pushx	<ax, bx, ds>
	mov	al,P_SETTLE[bp]
	sub	bx,bx
	mov	ds,bx
	Assume	DS:IVECT
	lds	bx,i1eptr
	mov	9[bx],al
	Assume	DS:CGROUP
	popx	<ds, bx, ax>
old_settle9:
	ret
endif


dd_open:	; 13-device open
;-------
	call	point_unit		; get unit descriptor
	inc	es:UDSC_OPNCNT[di]	; increment open count
	sub	ax,ax
	ret


dd_close:	; 14-device close
;--------
	call	point_unit		; get unit descriptor
	dec	es:UDSC_OPNCNT[di]	; decrement open count
	sub	ax,ax
	ret


dd_remchk:	; 15-removable media check
;---------
	call	point_unit		; get unit descriptor
	sub	ax,ax			; assume floppy disk
	test	es:UDSC_FLAGS[di],UDF_HARD
	 jz	remchk1			; skip if it really is a floppy
	mov	ax,RHS_BUSY		; else return "busy" for hard disk
remchk1:
	ret

dd_genioctl:	; 19-generic IOCTL
;-----------
	mov	cx,es:RH19_CATEGORY[bx]	; get major & minor function
	xchg	cl,ch			; swap them around
	call	point_unit		; get unit descriptor

	cmp	ch,8			; is it the right major category?
	 jne	ioctl20			; no, return an error

	or	es:UDSC_FLAGS[di],UDF_UNSURE
					; media unsure after IOCTL

	mov	si,offset CGROUP:genioctlTable
ioctl10:
	lods	cs:byte ptr [si]	; get category
	mov	ch,al			; keep in CH
	lods	cs:word ptr [si]	; AX = function address
	cmp	cl,ch			; is it the category we want ?
	 je	ioctl30			; yes, go do it
	test	ch,ch			; is it the end of the list ?
	 jnz	ioctl10			; no, do another one
ioctl20:
	mov	ax,RHS_ERROR+3		; "unknown command"
	ret
ioctl30:
	jmp	ax			; go do our routine

genioctlTable	label	byte
	db	RQ19_SET		; set device parameters
	dw	offset CGROUP:ioctl_set
	db	RQ19_GET		; get device parameters
	dw	offset CGROUP:ioctl_get
	db	RQ19_WRITE		; write track
	dw	offset CGROUP:ioctl_write
	db	RQ19_READ		; read track
	dw	offset CGROUP:ioctl_read
	db	RQ19_FORMAT		; format & verify track
	dw	offset CGROUP:ioctl_format
	db	RQ19_VERIFY		; verify track
	dw	offset CGROUP:ioctl_verify
	db	RQ19_GETMEDIA		; get media id
	dw	offset CGROUP:ioctl_getmedia
	db	RQ19_SETMEDIA		; set media id
	dw	offset CGROUP:ioctl_setmedia
	db	0			; terminate the list

point_ioctl_packet:
;------------------
; On Entry:
;	None
; On Exit:
;	DS:BX -> ioctl request packet
;	All other regs preserved
;
	lds	bx,REQUEST[bp]
	lds	bx,ds:RH19_GENPB[bx]	; ES:BX -> request packet
	ret


ioctl_get:
;---------
	push	ds
	call	point_ioctl_packet	; DS:BX -> ioctl packet
	mov	al,es:UDSC_TYPE[di]	; get drive type
	mov	ds:1[bx],al		; return drive type (0/1/2/5/7)

	mov	ax,es:UDSC_FLAGS[di]	; get device attributes
	and	ax,UDF_HARD+UDF_CHGLINE	; isolate hard disk + change line bits
	mov	ds:2[bx],ax		; return device attributes

	mov	ax,es:UDSC_NCYL[di]	; get # of cylinders
	mov	ds:4[bx],ax		; return # of cylinders

	sub	ax,ax			; for now always say "default"
	mov	ds:6[bx],al		; return media type

	test	ds:byte ptr [bx],1	; return default BPB?
	pop	ds
	lea	si,UDSC_DEVBPB[di]	; assume we want device BPB
	 jz	get1			; skip if yes
	test	es:UDSC_FLAGS[di],UDF_HARD
	 jnz	get1			; BPB doesn't change for hard disks
	call	ask_for_disk		; make sure we've got correct floppy
	call	login_media		; determine floppy disk type
	 jc	get_err			; abort if can't login disk
	lea	si,es:UDSC_BPB[di]	; get current BPB
get1:
	push	ds
	push	es
	push	di
	push	es
	call	point_ioctl_packet	; DS:BX -> ioctl packet
	push	ds
	pop	es
	lea	di,7[bx]		; ES:DI -> BPB in parameter block
	pop	ds			; DS:SI -> BPB to copy
	mov	cx,UDSC_BPB_LENGTH
	rep	movsb			; copy the BPB across to user
	pop	di
	pop	es
	pop	ds
	xor	ax,ax			; return success
	ret
get_err:
	jmp	xlat_error		; return error code
;	ret

ioctl_set:	; set device parameters
;---------

	push	ds
	push	es
	call	point_ioctl_packet	; DS:BX -> ioctl packet
	test	ds:byte ptr [bx],2	; ignore all but track layout?
	 jnz	set2			; yes, skip BPB stuff

	mov	al,ds:1[bx]		; get new drive type (0/1/2/5/7)
	mov	es:UDSC_TYPE[di],al	; set drive type

	and	es:UDSC_FLAGS[di],not (UDF_HARD+UDF_CHGLINE)
	mov	ax,ds:2[bx]		; get new device attributes
	and	ax,UDF_HARD+UDF_CHGLINE	; isolate hard disk + change line bits
	or	es:UDSC_FLAGS[di],ax	; combine the settings

	mov	ax,ds:4[bx]		; get new # of cylinders
	mov	es:UDSC_NCYL[di],ax	; set # of cylinders

	lea	ax,UDSC_BPB[di]		; AX -> media BPB in es:UDSC_
	test	ds:byte ptr [bx],1	; fix BPB for "build BPB" call?
	 jnz	set1			; skip if new media BPB only
	lea	ax,UDSC_DEVBPB[di]	; AX -> device BPB in es:UDSC_
set1:
	lea	si,7[bx]		; DS:SI -> new BPB from user
	xchg	ax,di			; ES:DI -> BPB in es:UDSC_
	mov	cx,UDSC_BPB_LENGTH
	rep	movsb			; copy BPB into UDSC as new default
	xchg	ax,di			; ES:DI -> UDSC_ again

set2:					; now set track layout
	lea	si,BPB_LENGTH+7[bx]	; DS:SI -> new user layout
	mov	es,cs:DataSegment
	mov	di,CG:layout_table	; ES:DI -> BIOS layout table
	lodsw				; get sector count
	test	ax,ax			; make sure this is good value
     jz set6            
	cmp	ax,MAX_SPT		; make sure this is good value
	 ja	set6			;   so we don't overflow table
	xchg	ax,cx			; CX = sector count
set3:					; loop here for every sector
	inc	di
	inc	di
	lodsw				; get sector number
	stosb				; write sector number
	lodsw				; get sector size (0080, 0100, 0200, 0400)
	shl	ax,1			; double it (0100, 0200, 0400, 0800)
set4:
	shr	ah,1			; halve the sector size until = 128
	 jc	set5			; we've shifted out bottom bit
	inc	al			; count the # of bits
	 jnz	set4			; (this should always jump)
set5:
	stosb				; store LOG2 (sector size/128)
	loop	set3			; repeat for all sectors
set6:
	pop	es
	pop	ds
	xor	ax,ax
	ret

ioctl_read:
;----------

	mov	P_ROSCMD[bp],ROS_READ	; read physical track
	jmps	ioctl_rw_common		; use common code

ioctl_write:
;-----------

	mov	P_ROSCMD[bp],ROS_WRITE	; write physical track
;	jmps	ioctl_rw_common		; use common code

ioctl_rw_common:
	call	ask_for_disk		; make sure we've got correct floppy
	push	ds
	call	point_ioctl_packet	; DS:BX -> ioctl packet
	mov	al,ds:5[bx]		; get logical sector (0..SPT-1)
	mov	P_SECTOR[bp],al
	mov	ax,ds:7[bx]		; get sector count
	mov	P_COUNT[bp],ax
	mov	ax,ds:9[bx]		; get transfer address
	mov	P_DMAOFF[bp],ax
	mov	ax,ds:11[bx]
	mov	P_DMASEG[bp],ax
	mov	ax,ds:1[bx]		; get head number
	mov	P_HEAD[bp],al
	mov	ax,ds:3[bx]		; get cylinder number
	mov	P_CYL[bp],ax
	pop	ds
rw_loop:
	call	track_rw		; read as much as possible on track
	 jc	rw_err			; return if physical disk error
	cmp	P_COUNT[bp],0		; test if any more stuff to read
	 jne	rw_loop			; yes, loop back for more
	sub	ax,ax			; all done, no error encountered
	ret				; return O.K. code
rw_err:
	jmp	xlat_error		; translate ROS code to DOS error
;	ret

ioctl_verify:
;------------
ioctl_format:
;------------
	call	ask_for_disk		; make sure we've got correct floppy
	mov	P_RETRY[bp],RETRY_MAX	; perform up to three retries
format_retry:
	call	set_format		; attempt data rate setup
	push	ds
	call	point_ioctl_packet	; DS:BX -> ioctl packet
	test	ds:byte ptr [bx],1	; are we testing parameters only ?
	 jz	format10
	mov	ds:[bx],al		; return AL
	pop	ds
	xor	ax,ax			; we succeeded
	ret

format10:
	mov	ax,es:UDSC_BPB+BPB_SPT[di]
	test	ds:byte ptr [bx],2	; is it undocumented "do 2 tracks" bit?
	 jz	format20
	add	ax,ax			; yes, double the count
format20:
	mov	P_COUNT[bp],ax		; save it locally for later
	mov	dh,ds:1[bx]		; get head #
	mov	cx,ds:3[bx]		; get cylinder #
	ror	ch,1
	ror	ch,1
	xchg	cl,ch
	or	cl,1			; start with sector 1
	mov	dl,es:UDSC_RUNIT[di]	; get ROS drive #
	lds	bx,REQUEST[bp]		; DS:BX -> Request Header
	mov	bx,ds:RH19_CATEGORY[bx]	; get major & minor function
	pop	ds

	push	es
	xor	ax,ax
	mov	es,ax
	mov	ax,new_int1e_off	; point floppy paramters at local
	xchg	ax,es:[4*1Eh]
	mov	orig_int1e_off,ax	; save old value
	mov	ax,new_int1e_seg
	xchg	ax,es:[4*1Eh+2]
	mov	orig_int1e_seg,ax
	pop	es

format30:
	cmp	bh,RQ19_FORMAT		; skip if verify only
	 jne	format40
	test	es:UDSC_FLAGS[di],UDF_HARD
	 jnz	format40		; hard disks are always verify

	mov	ax,P_COUNT[bp]
	mov	ah,ROS_FORMAT
	push	es
	push	bx
	push	ds
	pop	es
	mov	bx,CG:layout_table	; ES:BX -> parameter table
	int_____DISK_INT
	pop	bx
	pop	es
	 jc	format50
format40:				; no error on format, try verify
	mov	ax,P_COUNT[bp]
	mov	ah,ROS_VERIFY
	push	es
	push	bx
	xor	bx,bx
	mov	es,bx
	int_____DISK_INT
	pop	bx
	pop	es
	 jc	format50
	xor	ax,ax			; return success
format50:
	push	es
	push	di
	push	ax
	mov	ax,0
	mov	es,ax
	mov	di,78h
	mov	ax,orig_int1e_off
	stosw
	mov	ax,orig_int1e_seg
	stosw
	pop	ax
	pop	di
	pop	es
	 jnc	format60		; if no error's just exit
	call	xlat_error		; translate to DOS error
	dec	P_RETRY[bp]		; any more retries ?
	 jz	format60		; no, just exit with error
;	mov	ah,ROS_RESET
	xor	ax,ax
	int_____DISK_INT		; reset the drive
	jmp	format_retry		; now give it another go
format60:
	ret


;	The following table indicates which combinations of drive
;	types, sectors per track and tracks per disk are O.K. and
;	which value in AL is required for those combinations  for
;	INT 13h, AH = 17h ("set DASD type for format").

;			+----------------------	0 = 360Kb, 1 = 1.2Mb, 2 = 720Kb
;			|   +------------------	# of sectors/track (9, 15, 18)
;			|   |  +---------------	# of tracks per disk (40 or 80)
;			|   |  |   +-----------	1 = 360 Kb in 360 Kb
;			|   |  |   |		2 = 360 Kb in 1.2 Mb
;			|   |  |   |		3 = 1.2 Mb in 1.2 Mb
;			|   |  |   |  		4 = 720 Kb in 720 Kb
;			|   |  |   |  +--------	gap length for format
;			|   |  |   |  |
;			V   V  V   V  V

ok_fmt_table	db	0,  9, 40, 1, 50h	; 360 Kb
		db	1,  9, 40, 2, 50h	; 360 Kb in 1.2 Mb
		db	1, 15, 80, 3, 54h	; 1.2 Mb in 1.2 Mb
		db	2,  9, 80, 4, 50h	; 720 Kb in 720 Kb
		db	-1			; end of table

set_format:
;----------
; On Entry:
;	ES:DI -> UDSC_
; On Exit:
;	AL = 0 on success, else value to return in parameter block
;	ES:DI preserved
;
	push	ds
	call	point_ioctl_packet	; DS:BX -> ioctl packet
	mov	dh,ds:1[bx]		; get the head number
	mov	cx,ds:3[bx]		; get the cylinder number
	pop	ds

	mov	si,CG:layout_table	; SI -> track layout table
	mov	ax,MAX_SPT		; AX = # of sectors per track
set_format10:
	mov	0[si],cl		; set cylinder number
	mov	1[si],dh		; set head number
	add	si,4			; next sector entry
	dec	ax			; count down # of sectors
	 jnz	set_format10		; repeat until all done

	call	get_ncyl		; return # of tracks
	dec	ax			; AX = max. cylinder #
	ror	ah,1
	ror	ah,1			; move bits 8,9 into 6,7
	xchg	al,ah
	mov	cx,es:UDSC_BPB+BPB_SPT[di]
					; get desired sectors/track
	or	cx,ax			; CL, CH = max. cylinder/max. sector #
	cmp	cx,2708h		; check for 40 track, 8 sectors/track
	 jne	set_format20		; we convert 160, 320 to 180, 360
	inc	cx			; make it 9 sectors per track
set_format20:
	mov	dl,es:UDSC_RUNIT[di]	; get ROS unit number
	pushx	<es, di>
	mov	ah,ROS_SETMEDIA		; set type for format
	int_____DISK_INT		; check if combination is legal
	mov	new_int1e_off,di
	mov	new_int1e_seg,es	; ES:DI -> new parameters if legal
	popx	<di, es>
	 jc	set_format40		; did we succeed ?
set_format30:
	xor	ax,ax			; success, return no errors
	ret

set_format40:
; ROM BIOS has given an error, if the function isn't supported drop
; thru' and try the older method's
;
	mov	al,2			; assume ROS doesn't support it
	cmp	ah,0Ch			; media combination not supported ?
	 je	set_format80		; return AL=2
	inc	ax			; AL = 3
	cmp	ah,80h			; drive not ready ?
	 je	set_format80		; return AL=3

; Lets look for a match in our tables

	call	get_ncyl		; AX = number of cylinders
	mov	cx,es:UDSC_BPB+BPB_SPT[di]
					; CL = sectors per track
	mov	ch,al			; CH = tracks per disk
	cmp	cx,2808h		; 40 tracks, 8 sectors?
     jne    set_format50        
	inc	cx			; force it to 9 sectors/track
set_format50:
	mov	si,CG:ok_fmt_table-4
set_format60:
	add	si,4			; next table entry
	lods	cs:byte ptr [si]	; get drive type
	cmp	al,0FFh			; end of device/media list?
	 je	set_format70		; yes, can't handle this combination
	cmp	al,es:UDSC_TYPE[di]	; does the drive type match?
	 jne	set_format60		; try next one if wrong drive
	cmp	cx,cs:[si]		; do tracks/sectors match?
	 jne	set_format60		; no, try next one

	mov	parms_spt,cl		; set sectors/track
	mov	al,cs:3[si]		; get required gap length from table
	mov	parms_gpl,al		; set gap length for format
	mov	ax,CG:local_parms
	mov	new_int1e_off,ax	; use local parameters for formatting
	mov	new_int1e_seg,ds	; set new interrupt vector address
	mov	dl,es:UDSC_RUNIT[di]
	mov	al,cs:2[si]		; get media/drive combination
	mov	ah,ROS_SETTYPE		; set the drive type
	int_____DISK_INT
	 jnc	set_format30		; return if no errors
	cmp	es:UDSC_TYPE[di],0	; is this a 360 K drive?
	 je	set_format30		; go ahead, might be old ROS
	cmp	es:UDSC_TYPE[di],2	; is this a 720 K drive?
	 je	set_format30		; go ahead, might be old ROS
set_format70:
	mov	al,1			; return not supported
set_format80:
	ret


get_ncyl:
;--------
	mov	ax,es:UDSC_BPB+BPB_TOTSEC[di]
	xor	dx,dx			; get sectors on disk
	test	ax,ax			; zero means we use 32 bit value
	 jnz	get_ncyl10
	mov	ax,es:word ptr (UDSC_BPB+BPB_SIZE)[di]
	mov	dx,es:word ptr (UDSC_BPB+BPB_SIZE+2)[di]
get_ncyl10:
	div	es:UDSC_BPB+BPB_SPT[di]	; AX = # of cylinders * heads
	call	get_ncyl20		; round up
	div	es:UDSC_BPB+BPB_HEADS[di]; AX = # of cylinders
get_ncyl20:
	test	dx,dx			; do we have overflow ?
	 jz	get_ncyl30
	inc	ax			; round up
	xor	dx,dx			; make it a 32 bit value
get_ncyl30:
	ret


ioctl_getmedia:
;--------------
	mov	P_ROSCMD[bp],ROS_READ	; read from floppy/hard disk
	call	rw_media		; read the boot sector
	 jc	getmedia10
	push	es
	push	di
	push	ds
	call	point_ioctl_packet	; DS:BX -> ioctl packet
	push	ds
	pop	es
	lea	di,2[bx]		; ES:DI -> skip info word
	pop	ds			; DS:SI -> boot sector media id
	mov	cx,4+11+8
	rep	movsb			; copy the boot sector image
	pop	di
	pop	es
	xor	ax,ax
getmedia10:
	ret


ioctl_setmedia:
;--------------
	mov	P_ROSCMD[bp],ROS_READ	; read from floppy/hard disk
	call	rw_media		; read the boot sector
	 jc	setmedia10
	push	ds
	push	si
	push	es
	push	di
	push	ds
	push	si
	call	point_ioctl_packet	; DS:BX -> ioctl packet
	lea	si,2[bx]		; DS:SI -> skip info word
	pop	di
	pop	es			; ES:DI -> boot sector image
	mov	cx,4+11+8
	rep	movsb			; update the boot sector image
	pop	di
	pop	es
	pop	si
	pop	ds
	mov	P_ROSCMD[bp],ROS_WRITE	; write to floppy/hard disk
	jmp	rw_media		; write the boot sector
setmedia10:
	ret

rw_media:
;--------
; On Entry:
;	ES:DI -> UDSC
; On Exit:
;	ES:DI preserved
;	CY clear, SI -> boot record info
;	CY set on error, AX = error code
;
; setup parameters to read/write boot sector to/from local buffer
;
	call	ask_for_disk		; make sure we've got correct floppy
	mov	P_DMAOFF[bp],CG:local_buffer
	mov	P_DMASEG[bp],ds		; set transfer address
	mov	P_COUNT[bp],1		; read 1 sector
	mov	ax,es:UDSC_BPB+BPB_SPT[di]
	mul	es:UDSC_BPB+BPB_HEADS[di]; get sectors per track * heads
	xchg	ax,cx			; CX = sectors per cylinder
	mov	ax,es:word ptr (UDSC_BPB+BPB_HIDDEN)[di]
	mov	dx,es:word ptr (UDSC_BPB+BPB_HIDDEN+2)[di]
	div	cx			; AX = cylinder #, DX = head/sec offset
	mov	P_CYL[bp],ax		; save physical cylinder number
	xor	ax,ax			; make remainder 32 bit so
	xchg	ax,dx			; DX:AX = (head # * SPT) + sector #
	div	es:UDSC_BPB+BPB_SPT[di]	; divide by sectors per track
	mov	P_SECTOR[bp],dl		; DX = sector #, AX = head #
	mov	P_HEAD[bp],al		; save physical sector/head for later
	call	rw_loop			; read the boot sector
	 jc	rw_media20
	cmp	local_buffer+11+BPB_FATID,0F0h
	 jb	rw_media10
	mov	si,offset CGROUP:local_buffer+UDSC_BPB_LENGTH+11+2
	lodsb				; get extended boot
	sub	al,29h			; do we have an extended boot ?
	 je	rw_media20		; no, well we can't write a new one
rw_media10:
	mov	ax,RHS_ERROR+3		; "unknown command"
rw_media20:
	ret


dd_getdev:	; 23-get logical drive
;---------
;	get logical drive that corresponds to the physical drive
	call	point_unit		; get unit descriptor
	call	get_owner		; DL = owning drive (zero not owned)
	jmps	dd_setdev10		; return the owner


dd_setdev:	; 24-set logical drive
;---------
;	set logical drive that corresponds to the physical drive
;
	call	point_unit		; get unit descriptor
	call	set_owner		; set new owner
dd_setdev10:
	les	bx,REQUEST[bp]
	mov	es:RH_UNIT[bx],dl	; return current logical drive
	xor	ax,ax
	ret

get_owner:
;---------
; On Entry:
;	ES:DI -> UDSC_
; On Exit:
;	DL = owning drive (zero = no owner)
;
	xor	dx,dx			; assume one unit per physical drive
	mov	ax,es:UDSC_FLAGS[di]
	test	ax,UDF_HARD
	 jnz	get_owner40
	test	ax,UDF_VFLOPPY
	 jz	get_owner40
	push	ds
	mov	ds,dx			; DS -> low memory
		Assume	DS:IVECT
    mov dl,dual_byte        
	pop	ds
		Assume	DS:CGROUP
	mov	al,es:UDSC_RUNIT[di]	; lets look for this ROS drive
	test	al,al			; is it physical unit zero ?
	 jz	get_owner30		; yes, return dual_byte
	push	ds			; no, search our internal info
	lds	si,udsc_root
		Assume	DS:Nothing
get_owner10:
	cmp	al,ds:UDSC_RUNIT[si]	; do we use the same drive ?
	 jne	get_owner20
	test	ds:UDSC_FLAGS[si],UDF_OWNER
	 jz	get_owner20		; do we own it ?
	mov	dl,ds:UDSC_DRIVE[si]	; get the logical drive owner
get_owner20:
	lds	si,ds:UDSC_NEXT[si]
	cmp	si,0FFFFh		; try the next drive
	 jne	get_owner10
	pop	ds
		Assume	DS:CGROUP
get_owner30:
	inc	dx			; make drive one based
get_owner40:
	ret

set_owner:
;---------
; On Entry:
;	ES:DI -> UDSC_
; On Exit:
;	ES:DI preserved
;	DL = owning drive (zero = no owner)
;
	xor	dx,dx			; assume one unit per physical drive
	mov	ax,es:UDSC_FLAGS[di]
	test	ax,UDF_HARD
	 jnz	set_owner40
	test	ax,UDF_VFLOPPY
	 jz	set_owner40
	mov	al,es:UDSC_DRIVE[di]
	mov	ah,es:UDSC_RUNIT[di]	; get ROS unit
	test	ah,ah			; is it unit zero ?
	 jnz	set_owner10
	push	ds
	mov	ds,dx			; DS -> low memory
		Assume	DS:IVECT
	mov	dual_byte,al		; set dual drive support byte
	pop	ds
		Assume	DS:CGROUP
set_owner10:
	push	ds
	lds	si,udsc_root
		Assume	DS:Nothing
set_owner20:
	cmp	ah,ds:UDSC_RUNIT[si]	; does this unit use the same drive ?
	 jne	set_owner30
	or	ds:UDSC_FLAGS[si],UDF_UNSURE+UDF_OWNER
	cmp	al,ds:UDSC_DRIVE[di]
	 je	set_owner30
	and	ds:UDSC_FLAGS[si],not UDF_OWNER
set_owner30:
	lds	si,ds:UDSC_NEXT[si]
	cmp	si,0FFFFh		; end of the line ?
	 jne	set_owner20
	pop	ds
		Assume	DS:CGROUP
	xchg	ax,dx			; DL = owning drive
	inc	dx			; make it one based
set_owner40:
	ret


ask_for_disk:		; make sure the right disk is in the floppy drive
;------------
	call	get_owner		; DL = owning drive
	dec	dx			; make DL zero based
	 js	askfdsk30		; stop if not a logical drive
	mov	dh,es:UDSC_DRIVE[di]	; DH = new drive, DL = old drive
	cmp	dl,dh			; do we own the drive ?
	 je	askfdsk30		; yes, stop now
	push	dx			; save for broadcast
	mov	dl,dh			; new owner in DL
	call	set_owner		; we are now the owner
	push	es
	push	di
	push	cs
    call    FullScreen      
	pop	di
	pop	es
	pop	dx
	mov	ax,4A00h		; should we prompt ?
	xor	cx,cx
	int	2Fh			; lets ask
	inc	cx			; CX = FFFF ?
	 jcxz	askfdsk30		; then skip prompt
ifdef JAPAN
	mov	ax,5001h		; get adaptor mode
	int	VIDEO_INT		; ..
	cmp	bx,81			; japanese mode ?
	mov	si,CG:disk_msgA_jpn	; get message to print for Japanese
	 je	askfdsk10		; yes
endif
	mov	si,CG:disk_msgA		; get message to print
askfdsk10:
	call	WriteASCIIZ		; output the string
	mov	al,es:UDSC_DRIVE[di]	; get drive letter for new drive
	add	al,'A'
	dec	si			; point to NUL
	call	WriteNext		; output char, stop at NUL
ifdef JAPAN
	mov	ax,5001h		; get adaptor mode
	int	VIDEO_INT		; ..
	cmp	bx,81			; japanese mode ?
	mov	si,CG:disk_msgB_jpn	; get message to print for Japanese
	 je	askfdsk20		; yes
endif
	mov	si,CG:disk_msgB		; get message to print
askfdsk20:
	call	WriteASCIIZ		; output the string
	mov	ah,0			; wait for any key to be pressed
	int	KEYBOARD_INT		; read one key from keyboard
askfdsk30:
	ret				; we've got the right drive

WriteNext:
	int	29h			; output via fastconsole entry
WriteASCIIZ:
	lods	cs:byte ptr [si]	; get next char
	test	al,al
	 jnz	WriteNext		; stop at NUL
	ret

FullScreen:
	xor	di,di
	mov	es,di
	mov	ax,1684h		; get the entry point
	mov	bx,21			;  for DOSMGR
	int	2Fh
	mov	bx,es
	or	bx,di			; anyone there ?
	 jz	FullScreen10
	mov	ax,1			; yes, go full screen please
	push	es			; fake a JMPF to ES:DI
	push	di
FullScreen10:
	retf


driver	endp


RCODE	ends				; end of device driver code

page

ICODE	segment	'ICODE'			; initialization code

	Assume	CS:CGROUP, DS:CGROUP, ES:Nothing, SS:Nothing

dd_init:	; 0-initialize driver
;-------

	call	hard_init		; setup hard disk units
	call	floppy_init		; setup floppy units

	les	bx,REQUEST[bp]
	mov	al,nunits		; get # of units installed
	mov	es:RH0_NUNITS[bx],al	; return value to the BDOS
	mov	NumDiskUnits,al		; also set it in device header

	mov	ax,endbios		; get pointer to last resident byte
	mov	es:RH0_RESIDENT[bx],ax	; set end of device driver
	mov	es:RH0_RESIDENT+2[bx],ds

	mov	ax,CG:bpbtbl
	mov	es:RH0_BPBOFF[bx],ax	; set BPB table array
	mov	es:RH0_BPBSEG[bx],ds

	sub	ax,ax			; initialization succeeded
	ret				; (BIOS init always does...)


floppy_init:
;-----------
	mov	nunits,0		; floppies start at drive A:
	mov	ah,ROS_RESET		; reset the disk system
	xor	dx,dx			; for NEAT hard disk boot bug
	int_____DISK_INT
	int	EQUIPMENT_INT		; determine equipment status
	mov	cl,6
	shr	ax,cl			; shift down floppy bits
	and 	ax,03h			; mask for floppy
	inc	ax			; correct 0 based code
	mov	nfloppy,al

	cmp	al,1			; if there is only one floppy
	 jne	equip_check_des		;   then use 2 designators
	inc	ax			;   this fakes a B: drive
equip_check_des:
	mov	cx,ax			; CX = # of units to set up
	xor	dx,dx			; DL = physical drive
equip_loop:
	push	cx

	call	new_unit		; ES:DI -> UDSC
	mov	es:UDSC_RUNIT[di],dl	; set physical drive (ROS code)

	call	floppy_type		; determine type, build default BPB

	cmp	nfloppy,1		; do we only have single drive?
	 je	equip_single		; yes, use same physical drive for all
	inc	dx			; else use new drive for each unit
equip_single:				; we only have one physical drive

	call	add_unit		; add ES:DI to list of UDSC_'s

	pop	cx
	loop	equip_loop		; repeat for all logical floppies

	pushx	<ds, es>

	push	ds			; DS -> i13_trap segment
	
	mov	di,ds
	mov	es,di
	sub	si,si
	mov	ds,si
	lds	si,78h[si]
	mov	di,CG:local_parms	; copy parameters to template
	mov	cx,11
	rep	movsb

	pop	es			; now ES -> i13_trap segment
	Assume	ES:CGROUP
	sub	ax,ax
	mov	ds,ax			; DS -> interrupt vectors
	Assume	DS:IVECT
	mov	ax,CG:Int2FTrap		; hook Int 2F
	mov	i2Foff,ax
	mov	i2Fseg,es
	mov	ax,CG:Int13Trap		; hook Int 13
	xchg	ax,i13off
	mov	es:i13off_save,ax
	mov	ax,es
	xchg	ax,i13seg
	mov	es:i13seg_save,ax

	mov	di,500h			; dual drive byte & friends live here
	mov	cx,20h/2		; zero some bytes at 50h:0
	sub	ax,ax			; get a quick zero
	mov	es,ax			; ES:DI -> 0:500h
	rep	stosw			; setup dual drive byte & friends

	Assume	DS:CGROUP, ES:Nothing
	popx	<es, ds>

	ret


floppy_type:
;-----------
;	entry:	DI -> unit descriptor

	mov	UDSC_TYPE[di],0		; assume 360K 5.25" floppy
	mov	UDSC_NCYL[di],40	; 40 tracks only
	mov	ah,ROS_GETTYPE		; "Read DASD type"
	int_____DISK_INT		; find out if disk change line available
	 jc	equip_no_chgline	; skip if function not supported
	cmp	ah,2			; floppy with disk change line?
	 jne	equip_no_chgline	; no, must be old 360K
	or	es:UDSC_FLAGS[di],UDF_CHGLINE
	mov	es:UDSC_TYPE[di],1	; assume 1.2Mb floppy
	mov	es:UDSC_NCYL[di],80	; 80 tracks
equip_no_chgline:
	pushx	<es, di, dx>		; save our registers
	mov	ah,ROS_PARAM		; read drive parameters
	int_____DISK_INT		; find out floppy type
	popx	<dx, di, es>
	 jc	equip_no_type		; skip if PC,XT,jr,AT before 10 Jan 84
	dec	bx			; make values 0 based
	 jns	equip_type		; (CMOS invalid - type = 0)
	xor	bx,bx			; assume 360K
	cmp	ch,4fh			; is it 80 track ?
	 jne	equip_no_type		; if not forget it
	mov	bl,1			; BL = 1 (ie. 1.2M)
	cmp	cl,15			; 15 spt ?
	 je	equip_type
	inc	bx			; BL = 2 (ie. 720k)
	cmp	cl,9			; 9 spt ?
	 je	equip_type
	inc	bx			; BL = 3 (ie. 1.4M)
	cmp	cl,18			; 18 spt ?
	 je	equip_type
	inc	bx
	inc	bx			; BL = 5 (ie. 2.8M)
	cmp	cl,36			; 36 spt ?
	 jne	equip_no_type		; don't recognise anything
equip_type:
	cmp	bl,3			; is it 1.44 Mb 3.5" type?
	 jb	equip_type_ok		; skip if 360K, 1.2Mb, 720K (0, 1, 2)
	mov	bl,7			; use reserved "Other" type
     je equip_type_ok      
	inc	bx			; else make it 2.88 Mb type 9
	inc	bx
equip_type_ok:
	mov	es:UDSC_TYPE[di],bl	; set the default drive type for format
equip_no_type:

	mov	al,es:UDSC_TYPE[di]	; AL = 0, 1, 2 or 7 (360/1.2/720/1.44)
	cbw				; make it a word
	xchg	ax,si			; SI = drive type
	shl	si,1			; SI = drive type * 2
	mov	si,bpbs[si]		; get default BPB for drive
	cmp	si,CG:bpb360		; is this is a 360 K drive?
	 jne	equip_360		; skip if any other type
	mov	bpbtbl[bx],CG:bpb720	; use larger default BPB
equip_360:	
	mov	cx,UDSC_BPB_LENGTH	; CX = size of BPB
	pushx	<es, di, si, cx>
	lea	di,es:UDSC_BPB[di]
	mov	ax,ds
	mov	es,ax			; ES = DS
	rep	movsb			; make default BPB current BPB in UDSC
	popx	<cx, si, di, es>
	pushx	<es, di>
	lea	di,es:UDSC_DEVBPB[di]
	rep	movsb			; copy default BPB device BPB in UDSC
	popx	<di, es>
	ret


	page

LOG_PRIM	equ	01h		; log in primary partitions
LOG_EXTD	equ	02h		; log in extended partitions

log_flag	dw	LOG_PRIM	; scan for primary only initially

hard_init:	; setup all hard disk units
;---------
;	mov	log_flag,LOG_PRIM	; log in primary only initially
	call	hardi0			; C: & D:
	mov	log_flag,LOG_EXTD	; log in extended only
;	call	hardi0
;	ret

hardi0:
	mov	ah,ROS_PARAM		; get hard disk parameters
	mov	dl,80h
	int_____DISK_INT		; get # of hard disks we have
	 jc	hardi9			; skip if hard disks not supported
	test	dl,dl			; test if any hard disks found
	 jz	hardi9			; skip if there weren't any
	mov	al,dl
	cbw
	xchg	ax,cx			; CX = # of hard disks
	mov	dl,80h			; start with first hard disk
hardi1:
	pushx	<cx, dx>		; save drive count, physical drive
	call	login_hdisk		; find all partitions on hard disk
	popx	<dx, cx>		; restore physical drive, drive count
	inc	dx			; next physical hard disk
	loop	hardi1			; next physical hard disk
hardi9:					; all hard disks done
	ret


login_hdisk:	; find all partitions on a hard disk
;-----------
;	entry:	DL = 80h, 81h for 1st/2nd hard disk

	push	log_flag		; save state for next drive

	mov	p_unit,dl		; save physical drive
	mov	cx,0001h		; track 0, sector 1
	mov	dh,0			; partition tables start on head 0
log_h1:
	mov	dl,p_unit		; get physical unit
	call	login_read_dx
	 jnc	log_h1a
	jmp	log_h9			; give up if disk error
log_h1a:
	push	cx
	push	dx

	mov	ah,ROS_PARAM
	int_____DISK_INT		; return disk drive parameters
	inc	dh			; DH = number of heads
	mov	nhead,dh		; set # of heads on drive
	and	cl,3Fh			; isolate sector count
	mov	nsect,cl		; set sectors per track

	pop	dx
	pop	cx

;;	cmp	local_id,0AA55h
;;	 jne	log_h9			; give up if not initialized

	test	log_flag,LOG_PRIM	; scanning for primary?
	 jz	log_h5			; no, ignore all primary partitions

	mov	si,CG:local_pt		; point to partition table
log_h2:
;** SECURE PARTITIONS **
	mov	al,init_runit
	test	al,al			; booting from a hard disk ?
;** SECURE PARTITIONS **
	mov	al,4[si]		; get system ID
;** SECURE PARTITIONS **
	 jns	log_h2a			; booting from a hard disk ?
	mov	ah,al			; yes, allow secure partitions
	and	ah,0F0h
	cmp	ah,SEC_ID
	 je	log_h02
	cmp	ah,SEC_ID2
	 jne	log_h2a
log_h02:
	sub	al,ah			; turn into a sensible partition ID
log_h2a:
;** SECURE PARTITIONS **
	cmp	al,DOS20_ID		; is this a DOS 2.x partition?
	 je	log_h3			; yes, try to log it in
	cmp	al,DOS30_ID		; is this a DOS 3.0/3.1/3.2 partition?
	 je	log_h3			; yes, try to log it in
	cmp	al,DOS331_ID		; is this a DOS 3.31/4.0 partition?
	 jne	log_h4			; skip if not a good partition
log_h3:
	push	si			; save partition table index
	pushx	<cx, dx>		; save partition table address
	call	login_primary		; login primary partition
	popx	<dx, cx>		; get partition table address
	call	login_read_dx		; re-read partition table
	pop	si			; get partition table index
	 jc	log_h9			; give up if error
log_h4:
	add	si,16			; next partition table entry
	cmp	si,CG:local_id		; all partitions checked?
	 jb	log_h2			; loop back if more

log_h5:					; primary partitions done
	test	log_flag,LOG_EXTD	; scanning for extended?
	 jz	log_h9			; skip if no extended scan

	or	log_flag,LOG_PRIM	; scan for both types now
	mov	si,CG:local_pt		; SI -> partition table
; RG-01
log_h6:
;** SECURE PARTITIONS **
	mov	al,init_runit
	test	al,al			; booting from a hard disk ?
;** SECURE PARTITIONS **
	mov	al,4[si]		; get system ID
;** SECURE PARTITIONS **
	 jns	log_h6a			; booting from a hard disk ?
	mov	ah,al			; yes, allow secure partitions
	and	ah,0F0h
	cmp	ah,SEC_ID
	 je	log_sec2
	cmp	ah,SEC_ID2
	 jne	log_h6a
log_sec2:
	sub	al,ah
log_h6a:
;** SECURE PARTITIONS **
	cmp	al,DOSEX_ID		; DOS 3.3 extended partition found?
	 jne	log_h7
log_h6b:
	mov	dh,1[si]		; get head # for next table
	mov	cx,2[si]		; get cylinder, sector for next table
	jmp	log_h1			; read & scan next partition table

log_h7:					; entry not an extended partition
	add	si,16			; next partition table entry
	cmp	si,CG:local_buffer+IDOFF; all partitions checked?
	 jb	log_h6			; loop back if more

log_h9:					; drive login done
	pop	log_flag		; restore state for next drive
	ret


login_primary:
;-------------
;	entry:	SI -> partition table entry

	mov	ax,12[si]		; get size of partition (low)
	mov	part_size,ax
	mov	ax,14[si]		; get size of partition (high)
	mov	part_size+2,ax
	mov	cl,2
	mov	bx,5[si]		; get last head/sector
	and	bx,1100000011000000b	; isolate cylinder bits 10..11,8..9
	rol	bl,cl			; bits 10..11 from head into position
	or	bh,bl			;  or in bits 8..9
	rol	bh,cl			; bits 8..11 into place
	mov	bl,7[si]		; get cylinder bits 0..7
	mov	dh,1[si]		; get head of DOS partition
	mov	cx,2[si]		; get cylinder, sector of DOS partition
	pushx	<bx,cx,dx>
	call	login_read_dx		; try to read the partition boot
	popx	<dx,cx,bx>
	 jc	login_p9		; skip if partition not readable
					; CX, DX = disk addr of 1st sector
					; SI -> boot sector
					; PART_SIZE = 32 bit partition address
	cmp	nunits,MAXPART		; do we already have the maximum?
	 jb	log_p0			; skip if space for more units
login_p9:
	ret				; else ignore this partition

log_p0:
	call	new_unit		; ES:DI -> new UDSC
	mov	es:UDSC_FLAGS[di],UDF_HARD
	mov	es:UDSC_RUNIT[di],dl	; set physical drive (ROS code)
	mov	es:UDSC_TYPE[di],5	; set type = hard disk

	mov	al,dh			; copy head byte
	and	al,11000000b		; cylinder # bits 10..11 are in 6..7
	rol	al,1			; shift bits to bottom of word
	rol	al,1
	mov	ah,cl			; cylinder # bits 8..9 are in 6..7
	and	ah,11000000b		; strip off non-cylinder # bits
	or	ah,al			; combine the bits
	rol	ah,1			; shift the bits into place
	rol	ah,1
	mov	al,ch			; cylinder # bits 0..7
	sub	bx,ax			; bx = # cylinders
	inc	bx			; make it inclusive
	mov	es:UDSC_NCYL[di],bx	; and save it
	push	ax			; save # CYLINDERS
	mov	al,nsect
	and	dh,00111111b		; DH = head offset
	mul	dh			; AX = HEAD_OFF * NSECT
	xchg	ax,bx			; keep in BX
	mov	al,nsect
	mul	nhead			; AX = HEADS * NSECT
	pop	dx			; recover # CYLINDERS
	mul	dx			; DX:AX = CYLINDERS * HEADS * NSECT
	add	ax,bx
	adc	dx,0			; DX:AX = (CYL*HEADS + HEAD_OFF)*NSECT

	and	cx,00111111b		; isolate bottom 6 bits (sector #)
	dec	cx			; sector numbers are one-relative
	add	ax,cx			; add in non-partition sectors
	adc	dx,0			;   (usually 2.x partition table)

	lea	bx,UDSC_BPB[di]		; BX -> BPB to build
	add	si,11			; skip JMP + OEM name in boot sector

	mov	es:word ptr BPB_HIDDEN[bx],ax	; set the partition address
	mov	word ptr BPB_HIDDEN+2[bx],dx	;   (32 bit sector offset)
	mov	ax,part_size
	mov	dx,part_size+2
	mov	word ptr BPB_SIZE[bx],ax	; set partition size in sectors
	mov	word ptr BPB_SIZE+2[bx],dx

	mov	BPB_TOTSEC[bx],ax	; set partition size for < 32 Mb
					; we'll zero this later if > 32 Mb
	push	es
	push	di
	push	ax
	push	dx
	push	si
	call	hd_bpb			; build BPB from scratch
	pop	si
	pop	dx
	pop	ax
	pop	di
	pop	es
	
	cmp	byte ptr -11[si],0E9h	; look for a jmp
	jz	log_p1a
	cmp	word ptr -11[si],0EB90h	; look for a nop!jmps
	jz	log_p1a
	cmp	byte ptr -11[si],0EBh	; look for a jmps
	jnz	log_p1			; at the start of the boot sector. 
	cmp	byte ptr -9[si],90h	; EJH 7-1-91
	jnz	log_p1
log_p1a:

	test	BPB_SECSIZ[si],SECSIZE-1; not a multiple of 512 byte?
	 jnz	log_p1
	cmp	BPB_FATID[si],0F8h	; is this a good hard disk?
	 jne	log_p1
	cmp	BPB_NFATS[si],2		; too many FATs?
	 ja	log_p1
	cmp	BPB_NFATS[si],1		; no FATs at all?
	 jae	log_p2			; continue if BPB is valid
					; elsa build new BPB
log_p1:					; any of the above:  BPB invalid
					; (propably FDISKed, not FORMATted yet)
	jmps	log_p9

log_p2:					; valid BPB for partition, AX/DX = size
	push	ax
	mov	al,BPB_ALLOCSIZ[si]	; copy a few parameters from the 
	mov	BPB_ALLOCSIZ[bx],al	; Boot Sector BPB to our new BPB
	mov	ax,BPB_DIRMAX[si]	; EJH 7-1-91
	mov	BPB_DIRMAX[bx],ax
	mov	ax,BPB_FATSEC[si]
	mov	BPB_FATSEC[bx],ax
	mov	ax,BPB_SECSIZ[si]
	mov	BPB_SECSIZ[bx],ax
	mov	ax,BPB_FATADD[si]
	mov	BPB_FATADD[bx],ax
	mov	al,BPB_NFATS[si]
	mov	BPB_NFATS[bx],al
	pop	ax

	cmp	BPB_TOTSEC[bx],0	; is it an 32 bit sector partition ?
	 jne	log_p3			; no, carry on
	test	dx,dx			; would it fit in 16 bit sector sizes ?
	 jnz	log_p3			; yes, then make BPB_TOTSEC
	mov	BPB_TOTSEC[bx],ax	;  a valid 16 bit value too
log_p3:					; valid BPB for partition, AX/DX = size
	cmp	BPB_SECSIZ[bx],SECSIZE
	 jbe	log_p9			; skip if no large sectors
	shr	BPB_SECSIZ[bx],1	; halve the sector size
	shl	BPB_ALLOCSIZ[bx],1	; double the cluster size
	shl	BPB_FATSEC[bx],1	; double the FAT size
	shl	BPB_FATADD[bx],1	; double the FAT address
	shl	BPB_TOTSEC[bx],1	; double # of sectors
	 jnc	log_p3			; skip if still < 65536 sectors
	mov	BPB_TOTSEC[bx],0	; else indicate large partition
	jmps	log_p3			; try again
					; we've adjusted the sector size
log_p9:
	pushx	<ds, di>
	push	es
	pop	ds
	lea	si,UDSC_BPB[di]		; DS:SI -> new BPB
	lea	di,UDSC_DEVBPB[di]	; ES:DI -> fixed BPB
	mov	cx,UDSC_BPB_LENGTH
	rep	movsb			; make this the fixed BPB
	popx	<di, ds>
	call	add_unit		; register this DDSC_
	inc	nhard			; yet another hard disk
	ret

hd_bpb:
;------
	mov	BPB_SECSIZ[bx],SECSIZE	; set standard sector size
	mov	BPB_FATADD[bx],1	; one reserved (boot) sector
	mov	BPB_NFATS[bx],2		; two FAT copies
	mov	BPB_DIRMAX[bx],512	; assume 512 entry root directory
					; BPB_TOTSEC set up already
	mov	BPB_FATID[bx],0F8h	; standard hard disk ID
	mov	al,nsect
	mov	ah,0
	mov	BPB_SPT[bx],ax		; set sectors/track
	mov	al,nhead
	mov	BPB_HEADS[bx],ax	; set # of heads
					; determine FAT size:
	mov	BPB_ALLOCSIZ[bx],2*2	; assume 2 K clusters
	mov	ax,word ptr BPB_SIZE[bx]; AX/DX = 32 bit sector count
	mov	dx,word ptr BPB_SIZE+2[bx]
	test	dx,dx			; have we got huge partition (type 6)?
	 jnz	hd_bpb10		; yes, it's 16-bit
	cmp	ax,7FCEh		; more than 16 Mb?
	 jae	hd_bpb20		; yes, use 16 bit FAT
	mov	cx,4*2			; else we've got old 12-bit FAT
	mov	BPB_ALLOCSIZ[bx],cl	; we use 4 K clusters
	add	ax,cx			; adjust DX:AX for rounding
	dec	ax			;  when we work out num clusters
	div	cx			; AX = # of clusters
	mov	cx,ax
	add	ax,ax			; * 2
	add	ax,cx			; * 3
	shr	ax,1			; AX = num clus * 3/2 = bytes
	adc	ax,512-1		; allow for rounding
	xor	dx,dx
	mov	cx,512
	div	cx			; AX = # fat sectors
	mov	BPB_FATSEC[bx],ax	; remember FAT size
	ret

hd_bpb10:
	mov	BPB_TOTSEC[bx],0	; zero this if BPB_SIZE is required
	cmp	dx,2			; less than 2*65536 sectors (64 Mb)?
	 jb	hd_bpb20		; yes, leave cluster size the same
	mov	BPB_ALLOCSIZ[bx],4*2	; use 4 K clusters if 64-128 Mb
	cmp	dx,4			; less than 4*65536 sectors (128 Mb)?
	 jb	hd_bpb20		; yes, leave cluster size the same
	mov	BPB_ALLOCSIZ[bx],8*2	; use 8 K clusters if 128-512 Mb
	cmp	dx,16			; less than 16*65536 sectors (512 Mb)?
	 jb	hd_bpb20		; yes, leave cluster size the same
	mov	BPB_ALLOCSIZ[bx],16*2	; use 16 K clusters if 512-1024 Mb
	cmp	dx,32			; less than 32*65536 sectors (1 Gb)?
	 jb	hd_bpb20		; yes, leave cluster size the same
	mov	BPB_ALLOCSIZ[bx],32*2	; use 32 K clusters if 1-2 Gb

hd_bpb20:				; cluster size determined
	sub	ax,1+(512*32/SECSIZE)	; subtract reserved+root directory
	sbb	dx,0			; (note: 32 bytes per entry)
	xor	cx,cx
	mov	ch,BPB_ALLOCSIZ[bx]	; CX = (256 * # of clusters on drive)
	dec	cx
	add	ax,cx			; add in for rounding error
	adc	dx,0
	inc	cx
	div	cx			; AX = # of fat sectors
	mov	BPB_FATSEC[bx],ax	; remember FAT size
	mov	es:UDSC_FSTYPE+4[di],'6'; change "FAT12" to "FAT16"
	ret
	


new_unit:
	push	ds
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	mov	es,cs:DataSegment
	mov	di,endbios		; get next unit descriptor
	mov	cx,UDSC_LENGTH
	add	endbios,cx		; grow the BIOS size
	xor	ax,ax
	push	di
	rep	stosb			; zero the UDSC
	pop	di
	xor	bx,bx
	mov	bl,nunits		; BX = unit we are working on
	mov	es:UDSC_DRIVE[di],bl	; make that our logical unit
	shl	bx,1			; make it a BPB index
	lea	ax,es:UDSC_DEVBPB[di]	; get storage area for device BPB
	mov	bpbtbl[bx],ax		; update entry in BPB table
	shr	bx,1			; get the latest drive
	inc	bx			; onto next unit
	cmp	bl,2			; 3rd floppy ?
	 jne	new_unit10
	add	bl,nhard		; yes, skip past hard disks
new_unit10:
	mov	nunits,bl		; store ready for next time
	mov	es:UDSC_RUNIT[di],0FFh	; set physical drive (ROS code)
	push	cs
	pop	ds			; DS:SI -> our dummy value
	mov	si,offset CGROUP:dummyMediaID
	call	UpdateMediaID		; update UDSC_ with media info
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	ds
	ret


ICODE	ends

RESBIOS		segment	'RESBIOS'
; NOTE: we extend the resident BIOS size by the amount of
; memory required by the disk driver.
		db	MAXPART*UDSC_LENGTH dup (?)
RESBIOS		ends

IDATA	segment
p_unit		db	?		; 80h, 81h for hard disks
nsect		db	?		; # of sectors per track
nhead		db	?		; # of heads on disk
part_size	dw	2 dup (?)	; temporary save address for size
nunits		db	2		; start with driver C:
nhard		db	0		; # of hard disk partitions
nfloppy		db	0		; # of floppy drives

	Public	init_runit
init_runit	db	0		; poked with ROS Unit at boot

IDATA	ends

	end
