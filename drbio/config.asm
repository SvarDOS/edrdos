;    File              : $CONFIG.ASM$
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
;    CONFIG.A86 1.35 93/12/01 18:30:29
;    nls_temp_area grows to 258 bytes
;    CONFIG.A86 1.34 93/11/28 15:30:27
;    Support HIBUFFERS in UMB's
;    CONFIG.A86 1.32 93/11/22 15:02:14
;    Bus Master checks do Int 21/0D before/after to discard any buffers
;    CONFIG.A86 1.30 93/11/18 18:02:26 
;    Add primitive multi-master checking
;    CONFIG.A86 1.27 93/11/04 16:34:24
;    Extra callout to STACKER to determine if a drive is valid
;    CONFIG.A86 1.26 93/11/03 17:00:19
;    Stop dblspace phantom drives from appearing (FATsize=0)
;    CONFIG.A86 1.25 93/09/14 20:12:24
;    Initialise LFLG_PHYSICAL better - allow for zero FAT's meaning phantom drive
;    CONFIG.A86 1.24 93/09/02 22:34:50
;    Add header to system allocations
;    CONFIG.A86 1.23 93/08/06 20:55:23
;    re-arrange device init order for SCREATE.SYS on a VDISK.SYS
;    CONFIG.A86 1.22 93/08/02 14:45:55
;    hide preload drives from func_device
;    CONFIG.A86 1.20 93/07/28 19:19:08
;    call to SetupHMA before AllocHMA in setup_buffers allows buffers to go high
;    on novell memory managers
;    ENDLOG

	include	config.equ
	include	msdos.equ
	include char.def
	include	request.equ
	include	driver.equ
	include	fdos.equ
	include	f52data.def		; Function 52 DOS Data Area
	include	doshndl.def		; DOS Handle Structure Definition
	include country.def
	
TRUE	   	equ	0FFFFh	      ; value of TRUE
FALSE	   	equ	0	      ; value of FALSE

CGROUP		group	INITCODE, INITDATA
ASSUME CS:CGROUP,DS:CGROUP

INITCODE	segment public byte 'INITCODE'

	extrn	AllocHMA:near
	extrn	SetupHMA:near
	extrn	alloc_instseg:near	; Allocate "Segment" Instance Memory
	extrn	alloc_hiseg:near	; Allocate "Segment" Upper or Low Memory, depending on hidos flag
	extrn	alloc_seg:near		; Allocate "Segment" Memory
	extrn	alloc_upper:near	; Allocate "Segment" Upper Memory
	extrn	config_process:near
	extrn	InitStacks:near
	extrn	HookInt2F:near
	extrn	UnhookInt2F:near
	extrn	Verify386:near
	extrn	preload_done:near
	extrn	get_boot_options:near
	
	Public config_init
config_init:				; Initialize the CONFIG data
	ret


	Public country_init
country_init:
;------------
	push	ds
	push	es
	push	di
	push	si

; Obtain the address of the DBCS table in the BDOS.
	mov	ax, 06507h		; Extended Country Info: get DBCS ptr
	mov	bx, 0FFFFh		; codepage number: -1 for global cp
	mov	cx, 00005h		; size of info. buffer
	mov	dx, 0FFFFh		; country code: -1 for current country
	mov	di, offset dbcs_buf
	push	ds
	pop	es			; es:di -> 5 byte buffer
	int	DOS_INT			; returns with buffer filled in

; Get the current country information.
	mov	dx, offset ctry_info	; ds:dx -> buffer to be filled in
	mov	ax, 03800h		; get current country info
	int	DOS_INT
	jnc	ctry_info_done		; no carry = no error

; Failed to get country info. Place dummy uppercase routine in table.
	mov	si, offset ctry_info
	mov	CI_CASEOFF[si], offset myretf
	mov	CI_CASESEG[si], cs
	mov	bx, country_code

ctry_info_done:
	mov	country_code, bx

	pop	si
	pop	di
	pop	es
	pop	ds
	ret

myretf:	retf

;
;	CONFIG is called after the BIOS INIT code has been relocated to high
;	memory, the BIOS and BDOS have been initialised. 
;
	Public config			; Process CONFIG.SYS, loading and
config:					; initialising device drivers
	call	country_init		; initialise DBCS tbl and country info
	mov	ax,max_secsize		; get maximum sector size in BIOS
	les	bx,func52_ptr
	cmp	ax,es:F52_SECSIZE[bx]	; larger than default?
	 jbe	cfg_skip		; skip if not
	mov	es:F52_SECSIZE[bx],ax	; else update sector size
cfg_skip:
	call	cpu_init		; initialise CPU type
	push 	ds
	pop 	es

	call	config_process		; Process CONFIG.SYS

	call	get_boot_options	; look for user keypress
	mov	boot_options,ax		;  return any options
	cmp	ax,F5KEY
	 jne	cfg_no_f5
	lea	dx,cs:f5key_msg
	mov	ah,MS_C_WRITESTR
	int	DOS_INT
	jmp	short cfg_no_f8
cfg_no_f5:
	cmp	ax,F8KEY
	 jne	cfg_no_f8
	lea	dx,cs:f8key_msg
	mov	ah,MS_C_WRITESTR
	int	DOS_INT
cfg_no_f8:

	mov	configPass,1		; second pass of CONFIG.SYS
	mov	cfg_head,0
	mov	cfg_tail,0
	mov	cfg_seeklo,0
	mov	cfg_seekhi,0
	call	preload_done

	cmp	num_files,MIN_NUM_FILES	; Ensure the Minimum number of File
	jae	cfg_ex10		; have been allocated.
	mov	num_files,MIN_NUM_FILES
cfg_ex10:
	xor	ax,ax
	mov	al,init_buf		; now ensure we have allocated
	mov	num_buf,ax		; the correct number of buffers

	call	SetupDeblocking		; do our thing with deblocking

	mov	byte ptr configPass,2
	call	config_finish		; clean up configuration
	call	setup_fopen		; allocate disk hashing
	call	setup_history
	ret

cpu_init:
; If we are on a 386 or above set CPU flag
	call	Verify386		; make sure it's a 386
	 jc	cpu_init10		; skip setting falg if not
	les	bx,func52_ptr
	mov	es:F52_CPU_TYPE[bx],1	; we have a 386 !
cpu_init10:
	stc				; it's not a 386
	ret


SetupDeblocking:
;---------------
; Some types of hard disk controller give us problems with disk access of
; mapped memory (eg. upper memory, LIM pages).
; We can force single sector deblocking in the disk driver to avoid these
; problems. On DRDOS 5/6 our default was single sector I/O above A000, but
; this gives performance problems when devices/tsr's are loaded into upper
; memory (eg. STACKER, SERVER). To avoid this we use the following strategy.
;
; Default for CONFIG is A000, and may be updated at any time by a DEBLOCK=
; statement. If this happens the user setting has priority.
;
; At the end of CONFIG, assume no user supplied setting, we do some simple
; tests for multi-master controllers. If these fail we leave the settings
; at A000. If they succeed we go ahead and change the default setting to
; deblock at FFFF. The test is to read the 1st sector into low memory, and
; again into upper memory. If we read the same thing then assume all is well.
; If we can't do this leave the deblocking set at A000.
;
; NB. We will still have problems from LIM, and from DMA crossing page
; boundaries on some memory managers (eg. DRDOS 5.0)
;
	les	bx,func52_ptr
	lea	bx,F52_DEVROOT[bx]	; ES:BX -> NUL device link
	cmp	DeblockSetByUser,FALSE
	 je	SetupDeblocking20	; the user is king
SetupDeblocking10:
	push 	cs
	pop 	es			; ES -> local data again
	ret

SetupDeblocking20:			; get next device driver
	les	bx,es:[bx]		; we want resident disk device
	cmp	bx,0FFFFh		; end of the chain ?
	 je	SetupDeblocking10
	test	es:word ptr 4[bx],8000h
	 jnz	SetupDeblocking20	; we assume one disk device at 70:xxxx
	mov	ax,es
	cmp	ax,cs:bios_seg		; scan for resident disk in IO.SYS
	 jne	SetupDeblocking20
	cmp	es:word ptr 18[bx],0EDCh
	 jne	SetupDeblocking20	; is it our disk driver ?
	lea	ax,22[bx]		; deblocking variable is here
	mov	deblockOffset,ax	; remember that for fixups
	mov	deblockSeg,es
	mov	ax,es:DEVHDR.STRATEGY[bx]	; Set up the STRATEGY Entry Point
	mov	strategy_off,ax
	mov	strategy_seg,es	

	mov	ax,es:DEVHDR.INTERRUPT[bx]	; Set up the INTERRUPT Entry Point
	mov	interrupt_off,ax
	mov	interrupt_seg,es
	mov	al,es:DEVHDR.NAM[bx]	; get # supported units
	cbw
	mov	numUnits,ax		; remember for later

	mov	ax,(MS_M_STRATEGY*256)+1; set allocation strategy
	mov	bl,42h			;  to last fit, upper only
	int	DOS_INT
	mov	bx,512/16		; we need a 512 byte buffer
	mov	ah, MS_M_ALLOC		; try to allocate on in upper memory
	int	DOS_INT
	 jc	SetupDeblocking50
	mov	UpperMemoryBuffer,ax	; use this for deblocking checks
	mov	cx,numUnits		; CX = # of drives supported
	mov	dx,'C'-'A'		; start with drive C:
	sub	cx,dx			; CX = # of potential hard disks
	 jbe	SetupDeblocking40	; skip tests if none
SetupDeblocking30:			; DX = next drive, CX = drive count
	push 	cx
	push 	dx
	call	BusMasterCheck		; check if drive DL bus master disk
	pop 	dx
	pop 	cx
	 jc	SetupDeblocking40	; is so leave deblocking alone
	inc	dx			; else move to next drive
	loop	SetupDeblocking30	; repeat for all drives
	les	bx,deblockPointer
	mov	es:word ptr [bx],0FFFFh	; safe to disable deblocking
SetupDeblocking40:
	mov	es,UpperMemoryBuffer
	mov	ah,MS_M_FREE
	int	DOS_INT			; free the upper memory buffer
SetupDeblocking50:
	mov	ax,(MS_M_STRATEGY*256)+1; set allocation strategy
	xor	bl,bl			;  to first fit
	int	DOS_INT
	push 	cs
	pop 	es			; ES -> local data again
	ret


BusMasterCheck:		; determine if we have an old troublesome controller
;--------------
; On Entry:
;	DL = drive to check (zero based)
; On Exit:
;	CY set if troublesome drive
;
	call	BusMasterRemovable	; is it a removable device ?
	 jnc	BMCheck10		; yes, skip the checks
	mov	ax,mem_current		; read into low memory
	call	BusMasterRead		; read one sector from disk
	 jc	BMCheck10		; give up if we couldn't read

	mov	es,mem_current		; ensure at least the 1st word will
	mov	ax,es:0			;  differ if the read doesn't happen
	not	ax
	mov	es,UpperMemoryBuffer
	mov	es:0,ax

	mov	ax,UpperMemoryBuffer	; read into upper memory
	call	BusMasterRead		; read one sector from disk
	 jc	BMCheck10		; give up if we couldn't read
		
	xor	si,si
	xor	di,di
	mov	cx,512/2
	mov	es,mem_current
	mov	ds,UpperMemoryBuffer
	repe	cmpsw			; does the sector match ?
	push 	cs
	pop 	ds
	 je	BMCheck10		; yes, everything is fine
	stc				; no, better leave DEBLOCK at A000
BMCheck10:
	ret

BusMasterRemovable:
;------------------
; On Entry:
;	DL = drive
; On Exit:
;	CY set if not a removable drive
;	DL preserved
;
	push 	cs
	pop 	es
	mov	bx,offset removableMediaRequest
	mov	es:RH_UNIT[bx],dl
	call	dword ptr cs:strategy
	call	dword ptr cs:interrupt
	test	es:RH_STATUS[bx],RHS_BUSY
	 jz	BusMasterRemovable10
	stc				; busy bit set, it's a hard disk
BusMasterRemovable10:
	ret

BusMasterRead:		; Read first sector from drive BL
;-------------
; On Entry:
;	AX = segment of buffer
;	DL = 02 for C:, 03 for D:, etc.
; Exit:
;	CY clear if deblocking not required
;	DL preserved
;
	les	bx,deblockPointer
	mov	es:word ptr [bx],0FFFFh	; no deblocking during the test
	push 	cs
	pop 	es
	mov	bx,offset readRequest
	mov	es:RH_UNIT[bx],dl
	mov	es:RH4_BUFOFF[bx],0
	mov	es:RH4_BUFSEG[bx],ax
	mov	es:RH4_COUNT[bx],1
	call	dword ptr cs:strategy
	call	dword ptr cs:interrupt
	test	es:RH_STATUS[bx],RHS_ERROR
	 jz	BusMasterRead10
	stc				; error bit set, say we had a problem
BusMasterRead10:
	les	bx,deblockPointer
	mov	es:word ptr [bx],0A000h	; enable deblocking again
	ret


	Public	setup_stacks

setup_stacks:
	mov	cx,num_stacks		; we want this many stacks
	 jcxz	setup_stacks10		; skip if we don't want any
	mov	dx,stack_size		; they should be this big
	call	InitStacks		; initialise the stacks
setup_stacks10:
	ret

setup_history:
	test	history_flg,RLF_ENHANCED
	 jz	setup_hist10		; if history not enabled just exit

	push	es
	les	bx,drdos_ptr		; Get the internal data area

	mov	si,es:DRDOS_HIST1CTL[bx]; Get the address of History Control
	mov	ax,history_size		; Get Offset buffer for History data
	call	setup_hist20		; Allocate Buffer 1

	mov	si,es:DRDOS_HIST2CTL[bx]; Get the address of History Control 2
	mov	ax,history_size		; Get Offset buffer for History data
	call	setup_hist20		; Allocate Buffer 2

	mov	al,history_flg		; copy history state
	mov	es:DRDOS_HISTFLG[bx],al	;  into DRDOS data area

	pop	es
setup_hist10:
	ret

setup_hist20:
	and	ax,not 15		; round to a complete paragraph
	add	ax,16			; always be a para bigger
	mov	es:word ptr 02[si],ax	; Buffer Tail Address
	mov	cl,4
	push	ax			; save buffers size in bytes
	shr	ax,cl			; convert to para's
	mov	dl,'H'			; History buffer
	mov	dh,ALLOC_IN_UMB
	call	alloc_instseg		; Allocate Buffer
	mov	es:word ptr 00[si],ax	; Buffer Start Address
	pop	cx			; recover buffer size in bytes
	push	es
	mov	es,ax			; point ES at buffer seg
	xor	di,di			; ES:DI -> buffer
	xor	ax,ax			; zero it
	rep	stosb			; before use
	pop	es
	ret


	Public	device_init, resident_device_init

;	DEVICE_INIT will initialise the device with the Device Header at
;	ES:BX
;
;	Entry:
;		ES:DI		Address of First Device Header
;		DS:SI		Command Line Parameters
;
;	Exit:
;		AX		Top bit set on error, error code in AL
;
device_init:
;-----------
	push 	es
	push 	di
	call	build_cmd_tail		; point DS:SI to dos style cmd line
	pop 	di
	pop 	es
	call	HookInt2F		; hook the Int 2F vector
	call	resident_device_init
	call	UnhookInt2F		; get off the Int 2F vector
	test	ax,ax			; set the flags
	ret

resident_device_init:
;--------------------
	mov	rel_unit,0		; set rel unit to zero for block devices
	mov	dev_count,0
	mov	bx,offset request_hdr	; ds:bx -> command block
if TRUE
	mov	ax,mem_max		; AX:0 -> top of available memory
	mov	ds:RH0_RESIDENT[bx],0	; pass to the device driver
	mov	ds:RH0_RESIDENT+2[bx],ax	;  in the RESIDENT field
else
	mov	ds:RH0_RESIDENT[bx],di	; Force the default RESIDENT field
	mov	ds:RH0_RESIDENT+2[bx],es	;  to be the error condition
endif
dev_i10:
	push	si
	push 	es
	push 	di
	call	save_vecs		; save interrupt vectors
	mov	bx,offset request_hdr	; ds:bx -> command block
	call	dev_init		; initialise the device driver
	test	es:DEVHDR.ATTRIB[di],DA_CHARDEV
	 jnz	dev_i18			; skip if a character device
	cmp	ds:RH0_NUNITS[bx],0		; no drives installed for disk device?
	 je	dev_i_err		; failed if no drives found
dev_i18:
	mov	ax,ds:RH0_RESIDENT[bx]	; Calculate the address of
	mov	cl,4			; last paragraph used by the
	shr	ax,cl			; device driver. If this is the
	add	ax,ds:RH0_RESIDENT+2[bx]	; device driver CS then error
	test	ds:RH0_RESIDENT[bx],15	; allow for partial para ?
	 jz	dev_i19
	inc	ax			; round it up
dev_i19:
	cmp	ax,strategy_seg
	 jbe	dev_i_err

	cmp	ax,mem_max		; Check for Memory Overflow
	 jb	dev_i30			; if it does then we can't install
	call	restore_vecs		; so replace interrupt vectors
dev_i_err:				; device initialization failed!
	les	di,cs:func52_ptr	; ES:DI -> internal data
	mov	ax,es
	or	ax,di			; DOS data area present yet?
	pop 	di
	pop 	es			; recover the device header

	les	di,es:DEVHDR.NEXT[di]	; try next device driver
	 jz	dev_i60			; if it's resident initialisation
	mov	di,0FFFFh		;  else stop now
	jmp	short dev_i60

;	The device driver initialised OK so now build/update internal
;	tables based on the device driver type.
;
;	AX = next available paragraph
;	DS:BX = request header
;	ES:DI = device driver header
;
dev_i30:				; DEV_INIT OK so update the Top of
	mov	mem_current,ax		; memory field
	test	es:DEVHDR.ATTRIB[di],DA_CHARDEV
	 jz	dev_i40

	call	char_device		; Handle Initialization of all
	jmp	short dev_i50		; character devices

dev_i40:
	call	block_device		; Handle Initialization of all
;	jmp	short dev_i50		; Block Devices

dev_i50:
	pop 	di
	pop 	es			; Retrieve the current device header
	push	word ptr es:[di+DEVHDR.NEXT+2]	; save next entry on the list
	push	word ptr es:[di+DEVHDR.NEXT]	; while we deal with existing one
	mov	word ptr es:[di+DEVHDR.NEXT],0FFFFh; terminate the list	
	call	device_insert		;  and insert into the list
	pop	di
	pop	es			; go round till the end
dev_i60:
	pop	si			; recover cmdline for next device
	cmp	di,0FFFFh		; was that the last device to
	 jne	dev_i10			;  initialise, no do next
	mov	bx,offset request_hdr	; ds:bx -> command block
	mov	ax,ds:RH_STATUS[bx]		; return Status Register
	and	ax,80FFh		; is there an error ?
	 js	dev_i70
	xor	ax,ax			; no, return success
dev_i70:
	ret


	public	init_static_request
init_static_request:
					; Set up request header for INIT command.
	sub	ax,ax			; get a convenient zero
	mov	ds:RH_LEN[bx],RH0_LEN	; Init Request Length
	mov	ds:RH_UNIT[bx],al		; relative drive always 0
	mov	ds:RH_CMD[bx],CMD_INIT	; Init Command 
	mov	ds:RH_STATUS[bx],ax		; Zero Status Register

	mov	ds:RH0_BPBOFF[bx],si	; Save the command line offset and
	mov	ds:RH0_BPBSEG[bx],ds	; Segment in the BPB Pointer

	mov	al,next_drv		; the first drive for this device
	sub	al,preload_drv		; (not including preloaded devices)
	mov	ds:RH0_DRIVE[bx],al	 	; will be allocated as NEXT_DRV
;;;	mov	es:DEVHDR.NEXTSEG[di],0	; force seg to zero (386max 4.05)
	ret

dev_init:
;--------
; On Entry:
;	ES:DI -> device driver header
;	DS:BX -> req header
;	DS:SI -> command line
; On Exit:
;	ES:DI/DS:BX <preserved>
;
	mov	ax,es:DEVHDR.STRATEGY[di]	; Set up the STRATEGY Entry Point
	mov	strategy_off,ax
	mov	strategy_seg,es	

	mov	ax,es:DEVHDR.INTERRUPT[di]	; Set up the INTERRUPT Entry Point
	mov	interrupt_off,ax
	mov	interrupt_seg,es
	call	init_static_request

	push 	ds
	push 	es			; Save Segment registers
	push 	bx
	push 	si
	push 	di			; and pointers (not all preserve them)
	push 	ds
	pop 	es			; ES -> Points at the Data Segment
	mov	ds,strategy_seg		; DS == Device Drive Segment
 	mov	si,di			; DS:SI -> device driver header
	push	ds
	push	es
 	call	dword ptr cs:strategy		; Call Device Strategy Routine
	pop	es
	pop	ds
	mov	ax,ds:DEVHDR.INTERRUPT[si]	; Set up the INTERRUPT Entry Point
	mov	es:interrupt_off,ax
	call	dword ptr cs:interrupt		; Call Device Interrupt Routine
	pop 	di
	pop 	si
	pop 	bx			; recover the pointers
	pop 	es
	pop 	ds			; Restore Segment Registers
	mov	word ptr es:[di+DEVHDR.NEXT+2],es	; ignore segment - it MUST be same one
	ret

;
;	Character Device Driver Initialised OK so now build/update internal
;	tables based on the device driver type.
;
;	DS:BX		Request Header
;	ES:DI		Device Driver Header
;
char_device:
	test	es:DEVHDR.ATTRIB[di],DA_ISCIN
	 jz	char_d10		; is this the standard console device?
	mov	condev_off,di		; save console device driver address
	mov	condev_seg,es
	ret

char_d10:
	test	es:DEVHDR.ATTRIB[di],DA_ISCLK
	 jz	char_d20		; is this the standard clock device?
	mov	clkdev_off,di		; save clock device driver address
	mov	clkdev_seg,es
char_d20:
	ret


;	Block  device  driver  initialised  OK.  Save  the values
;	returned from the INIT call so we can later build all the
;	required internal tables.
;
;	entry:	DS:BX -> request header
;		ES:DI -> device driver header
;
	public	block_device
block_device:
	mov	al,BLKDEV_LENGTH	; bytes per block device table entry
	mul	byte ptr num_blkdev	;   * # of block devices installed
	add	ax,offset blkdev_table	; AX -> block dev init result table
	xchg	ax,si			; pointer to next block device struct
	mov	devoff,di
	mov	devseg,es		; point to device driver header
	mov	0[si],di
	mov	2[si],es		; save device driver address for later
	mov	ax,ds:RH0_BPBOFF[bx]
	mov	4[si],ax		; save BPB table address (offset)
	mov	ax,ds:RH0_BPBSEG[bx]
	mov	6[si],ax		; save BPB table address (segment)
	mov	cl,ds:RH0_NUNITS[bx]
	mov	8[si],cl		; get # of units supported by driver
	mov	es:DEVHDR.NAM[di],cl	; set # of units in device name
	inc	num_blkdev		; we've installed another block device
	add	next_drv,cl		; update drive base for next driver
	add	dev_count,cl		; number of new units

	mov	ax,boot_device		; now for Andy's bit about boot device
	or	ax,boot_device+2	; have we already got a boot device?
	 jnz	not_boot_dev
	mov	ch,init_drv
	sub	ch,next_drv		; is sub unit in this driver
	 ja	not_boot_dev		; no, skip it
	add	ch,cl			; work out which sub unit it is
	mov	boot_drv,ch		; and remember it
	mov	boot_device,di
	mov	boot_device+2,es
not_boot_dev:

	push	si
	push 	es
	push 	di
	mov	cl,8[si]
	xor	ch,ch			; CX = # of drives found in driver
	les	si,4[si]		; ES:SI -> BPB array in BIOS
	mov	bpbseg,es		; remember the segment
blkdev_loop:
	lods	word ptr es:[si]	; AX = offset of next BPB
	push 	es
	push 	si
	push 	cx
	mov	bpboff,ax		; remember the offset
	xchg	ax,di			; ES:DI -> next BPB
	mov	ax,es:[di]		; AX = sector size for BPB
	cmp	ax,max_secsize		; new maximum for sector size
	 jbe	blkdev_next1		; skip if sector size not grown
	mov	max_secsize,ax		; else set new maximum
blkdev_next1:
	mov	dl,es:2[di]		; get sectors per cluster
	xor	dh,dh			; make this a word
	mul	dx			; AX = bytes per cluster
	cmp	ax,max_clsize		; more than previous maximum
	 jbe	blkdev_next2		; skip if no new high score
	mov	max_clsize,ax		; else record max. sector size
blkdev_next2:
	les	bx,func52_ptr		; ES:BX -> internal data
	mov	ax,es
	or	ax,bx			; DOS data area present yet?
	 jz	blkdev_next3		; skip if BDOS not present yet
	call	setup_drives		; update drives in BDOS data
	mov	es,mem_current		; MUST create a DDSC just after driver
	add	mem_current,(DDSC_LEN+15)/16
	xor	bp,bp			; ES:BP points to the DDSC
	call	setup_ddsc		; add new DDSC_ to chain
	call	setup_ldt		; initialise LDT for that drive
blkdev_next3:
	pop 	cx
	pop 	si
	pop 	es
	loop	blkdev_loop		; repeat for all BPBs in driver
	pop	di
	pop 	es
	pop 	si
	ret

resident_ddscs:
;--------------
; Allocate DDSC's for the resident device drivers - we can only do this
; after the DOS data area is established.
;
	push	word ptr res_ddsc_ptr
	sub	bx,bx			; start with 1st block device
	mov	cx,num_blkdev		; get # of block devices
	 jcxz	res_ddsc40		; skip if no block devices
res_ddsc10:
	push	bx
	push 	cx
	mov	ax,BLKDEV_LENGTH
	mul	bx
	add	ax,offset blkdev_table
	xchg	ax,si			; SI -> block device table
	sub	cx,cx
	mov	cl,8[si]		; CX = # of units on device
	sub	bx,bx			; BX = relative unit # * 2
	mov	rel_unit,bx		; start with relative unit # 0

res_ddsc20:				; CX = remaining units
	push	bx
	push 	cx
	push 	si			; BX = offset, SI -> drive structure
	lodsw
	mov	devoff,ax		; save device header offset
	lodsw
	mov	devseg,ax		; save device header segment 
	les	si,[si]			; get offset of BPB array
	mov	ax,es:[bx+si]		; get offset for our BPB
	mov	bpboff,ax
	mov	bpbseg,es		; save pointer to BPB

	les	bp,res_ddsc_ptr		; point to position for DDSC_
	add	ds:word ptr res_ddsc_ptr,DDSC_LEN
	call	setup_ddsc		; setup one unit
	pop	si
	pop 	cx
	pop 	bx
	inc	bx
	inc 	bx			; increment (unit index*2)
	loop	res_ddsc20		; repeat for next unit, same driver

	pop	cx
	pop 	bx
	inc	bx
	loop	res_ddsc10		; repeat for next driver
res_ddsc40:				; all block devices done
	pop	word ptr res_ddsc_ptr
	ret

	
setup_ddsc:
;----------
; On Entry:
;	ES:BP -> DDSC_ to initialise and link into chain
;	bpbptr -> BPB to initialise from
;	devseg:devoff -> device driver header
;	abs_unit, rel_unit reflect drive
; On Exit:
;	None
;
	push	ds
	lds	si,bpbptr		; DS:SI points to the BPB
	mov	ah,53h			; build DDSC from BPB call
	int	DOS_INT			;  initialises the structure
	pop	ds
	mov	ax,devoff
	mov	es:DDSC_DEVOFF[bp],ax
	mov	ax,devseg
	mov	es:DDSC_DEVSEG[bp],ax

	mov	ax,abs_unit
	inc	abs_unit
	mov	es:DDSC_UNIT[bp],al	; set absolute unit (global)
	mov	ax,rel_unit
	inc	rel_unit
	mov	es:DDSC_RUNIT[bp],al	; set relative unit (driver relative)

	mov	ax,-1			; set link to FFFFh:FFFFh
	mov	es:word ptr DDSC_LINK[bp],ax
	mov	es:word ptr DDSC_LINK+2[bp],ax
	mov	es:DDSC_FIRST[bp],al	; set drive never accessed flag
	mov	ax,es			; now link into device chain
;
	les	bx,func52_ptr		; ES:BX -> secret 52h data
	lea	bx,(F52_DDSCPTR-offset DDSC_LINK)[bx]
setup_ddsc10:
	cmp	es:word ptr DDSC_LINK[bx],0FFFFh
	 je	setup_ddsc20		; is there another one ?
	les	bx,es:DDSC_LINK[bx]	; onto next DDSC_
	jmp	short setup_ddsc10
setup_ddsc20:				; link new DDSC to end of chain
	mov	es:word ptr DDSC_LINK[bx],bp
	mov	es:word ptr DDSC_LINK+2[bx],ax
	ret				; now RAF will be happy
	

	Public	setup_ldt

setup_ldt:
	push	ds
	push	es
	les	bx,func52_ptr		; get internal data in ES:BX
	mov	al,LDT_LEN		; we need this many bytes per drive
	mul	es:F52_LASTDRV[bx]	; *lastdrive
	xchg	ax,cx			; CX = size to initialise
	mov	al,es:F52_LASTDRV[bx]	; lastdrive
	push	ax			; save for later
	les	di,es:F52_PATHPTR[bx]	; now initialise the CSD's
	mov	bx,di
	xor	al,al			; to zero
	rep	stosb			; zero them
	pop	ax			; recover lastdrive

;	xor	bx,bx			; start with zero offset
	xor	cx,cx			; start with drive A
	xchg	al,cl			; AH = physical limit, CX logical limit
ldt_init:
	push	ax
	push	cx
	push	ax
	lea	di,LDT_NAME[bx]
	add	al,'A'			; make drive ASCII
	stosb
	mov	ax,'\:'			; point at the root
	stosw
	mov	ax,0FFFFh
	lea	di,LDT_BLK[bx]		; set to FFFF to force LDT_ rebuild
	stosw
	stosw
	stosw				;  next two words are FFFF too
	lea	di,LDT_BLKH[bx]
	stosw
	lea	di,LDT_ROOTH[bx]
	stosw
	lea	di,LDT_ROOTLEN[bx]
	mov	ax,2
	stosw				; set the length field
	pop	ax
	lds	si,cs:func52_ptr	; get internal data in DS:SI
	sub	si,offset DDSC_LINK
ldt_init20:
	lds	si,ds:DDSC_LINK[si]	; point to next PDT
	cmp	si,-1			; skip if there isn't one
	 je	ldt_init40
	cmp	al,ds:DDSC_UNIT[si]	; is this the DDSC for the drive
	 jne	ldt_init20		; if not try another
	mov	es:word ptr LDT_PDT[bx],si
	mov	es:word ptr LDT_PDT+2[bx],ds
	cmp	ds:DDSC_NFATS[si],0	; no FATS, then it's a reserved drive
	 je	ldt_init40		
	push	es
	push	bx
	push	ax			; save drive we are processing
	mov	ax,4A11h
	xor	bx,bx
	int	2Fh			; do an STACKER installation check
	pop	dx			; DL = drive we are processing
	test	ax,ax
	mov	ax,LFLG_PHYSICAL	; assume a physical drive
	 jnz	ldt_init30		; no STACKER, it's physical
	sub	cl,'A'			; zero base STACKER drive returned
	cmp	cl,dl			; should we check this drive ?
	 ja	ldt_init30		; below 1st drive, it's physical
	push	ax
	push	dx
	mov	ax,4A11h
	mov	bx,1			; ask STACKER for host drive
	int	2Fh
	pop	dx
	pop	ax
	cmp	bl,dl			; is this the host drive ?
	 jne	ldt_init30
	xor	ax,ax			; drive is invalid
ldt_init30:
	pop	bx
	pop	es
	mov	es:LDT_FLAGS[bx],ax
ldt_init40:
	add	bx,LDT_LEN		; move onto next LDT_
	pop	cx
	pop	ax
	inc	ax			; and next drive
	loop	ldt_init		; done to lastdrive ? no, do another

	pop	es
	pop	ds
	ret

	Public	device_insert

device_insert:
;-------------
; insert device drivers at ES:DI into global chain
; if we are initialising the resident device drivers then we don't have
;  a global chain, so insert them on a local chain and try again later
	push	ds
	lds	bx,func52_ptr		; Internal Data Pointer
	lea	si,F52_DEVROOT[bx]	; DS:SI -> NUL device
	mov	ax,ds			; if BDOS data area isn't present
	or	ax,bx			;  we are initialising resident
	 jnz	dev_ins_next		;  devices
	push 	cs
	pop 	ds
	mov	si,offset resdev_chain	; it's resident devices
dev_ins_next:
	cmp	di,-1			; end of device chain reached?
	 je	devins_done		; yes, all devices inserted
	mov	ax,0[si]
	mov	dx,2[si]		; DX:AX = original chain 
	mov	0[si],di
	mov	2[si],es		; link our device at head of chain
	xchg	ax,es:0[di]		; link old global chain to device
	xchg	dx,es:2[di]		;  & get next device in local chain
	mov	di,ax			; point to next device in chain
	mov	es,dx
	jmp	short dev_ins_next	; repeat until chain empty
devins_done:
	pop	ds
	ret


	public	config_finish

config_finish:		; finish off configuration
;-------------
	cmp	resdev_off,-1		; are resident devices already
	 je	cfg_fin10		;  installed
	les	di,resdev_chain		; insert all the resident device
	call	device_insert		;  drivers into DOS chain
	call	resident_ddscs		; build DDSC's for resident devices
	mov	resdev_off,-1		; only do this once...
cfg_fin10:

	cmp	byte ptr configPass,0	; skip if second pass
	 jne	cfg_fin20
	les	bx,func52_ptr		; ES:BX -> base of DOS variables
	call	setup_drives		; Update No of Physical Drives in case
					; this is the first pass
	call	setup_ldt		; setup the ldt's
cfg_fin20:
	les	bx,func52_ptr
	lea	di,F52_CLKDEV[bx]	; ES:DI -> clock ptr, console ptr
	mov	si,offset clkdev_off	; DS:SI -> local pointer values
	movsw				; set offset of clock device driver
	movsw				; set segment of clock device driver
	movsw				; set offset of console device driver
	movsw				; set segment of console device driver

	push	num_files
	push	num_fcbs
	mov	al,filesIn
	push	ax
	mov	num_fcbs,MIN_NUM_FCBS
	mov	num_files,MIN_NUM_FILES
	mov	filesIn,0
	call	setup_doshndl
	pop	ax
	mov	filesIn,al
	pop	num_fcbs
	pop	num_files

	call	setup_doshndl		; Allocate DOS compatible Handles
					; NB must immediately follow devices !
	call	setup_buffers		; allocate the requested #
	ret


setup_buffers:
;-------------
;	entry:	num_buf = minimum # of buffers required
;		          0 - use temporary high buffers
;
	les	bx,func52_ptr		; ES:BX -> internal data structure
	mov	ax,num_buf		; fill in info in DOS for diagnostic
	mov	es:F52_NUM_BUF[bx],ax	;  programs
	mov	al,num_read_ahead_buf
	mov	es:F52_READ_AHEAD[bx],ax
	mov	ax,es:F52_SECSIZE[bx]	; get DOS data sector size
	cmp	ax,max_secsize		; has it been poked to a bigger value ?
	 ja	setup_b10		; if so we must discard anyway
	mov	ax,max_secsize		; get max. sector size found
setup_b10:
	mov	es:F52_SECSIZE[bx],ax	; update max. sector size in PCMODE
	mov	max_secsize,ax		; update max. sector size locally
	add	ax,offset BCB_DATA	; add in the header size

	mov	es,init_dseg		; ES:DI -> init buffers
	mov	di,offset INIT_BUFFERS
	mov	cx,NUM_BUFFS		; CX buffs, DX in size, at ES:DI
	mov	dx,SIZEOF_BUFFS		; size of init buffers
	cmp	num_buf,0		; (zero at init time)
	 je	setup_b70		; go ahead and initialise

	push	ax			; save size of buffer
	mul	num_buf			; AX = total bytes required
	test	dx,dx			; > 64 K ?
	 jz	setup_b30
	mov	ax,0FFFFh		; do the maximum
setup_b30:
	pop	bx			; BX = size of a buffer
	mov	cx,ax			; CX bytes required
	xor	dx,dx
	div	bx			; AX = # buffers

	push	ax			; save # buffers
	push	bx			; save size of a buffer
	push	cx			; save bytes wanted
	test	buffersIn,BUFFERS_IN_HMA
	stc				; do we want buffers at FFFF ?
	 jz	setup_b40
	call	SetupHMA		; make sure HMA chain is established
	pop 	cx
	push 	cx			; CX = bytes wanted
	mov	dx,0FFFFh		; anywhere is OK
	call	AllocHMA		; ES:DI -> allocated data
setup_b40:
	pop	ax			; AX = bytes wanted
	pop	dx			; DX = size of a buffer
	pop	cx			; CX = number of buffer
	 jnc	setup_b70		; if CY clear ES:DI -> our space

	shr 	ax,1
	shr 	ax,1
	shr 	ax,1
	shr 	ax,1
	inc	ax			; convert from bytes to para's
	push	dx
	mov	dl,'B'			; allocate as a Buffer
	test	buffersIn,BUFFERS_IN_UMB
	 jz	setup_b50		; allocation from UMB's OK ?
	call	alloc_upper		; yes, try and allocate memory there
	 jnc	setup_b60
setup_b50:
	call	alloc_seg		; allocate memory in bottom 640 K
setup_b60:
	pop	dx
	mov	es,ax			; ES = segment
	xor	di,di			; ES:DI -> start of buffer
setup_b70:
; Buffer space for CX buffers, of size DX, allocated at ES:DI
	mov	si,di			; remember where 1st buffer is
setup_b80:
	push	cx
	mov	bx,di			; BX = current buffer
	mov	cx,dx
	xor	ax,ax
	rep	stosb			; zero the buffer, ES:DI -> next buffer
	mov	es:BCB_DRV[bx],0FFh	; invalidate buffer
	mov	es:BCB_NEXT[bx],di	; point to where "next" will be
	mov	ax,bx
	sub	ax,dx			; work out what our previous was
	mov	es:BCB_PREV[bx],ax	;  and point to it
	pop	cx
	loop	setup_b80		; do them all

	mov	es:BCB_NEXT[bx],si	; the last's "next" is our first buffer
	mov	es:BCB_PREV[si],bx	; the first's "previous" is our last
	mov	ax,es			; AX:SI -> 1st buffer
	les	bx,func52_ptr		; ES:BX -> internal data structure
	mov	es:F52_BCBOFF[bx],si
	mov	es:F52_BCBSEG[bx],ax	; fixup buffer pointers
	mov	es:word ptr F52_BUF_INFO[bx],si
	mov	es:word ptr F52_BUF_INFO+2[bx],ax
	inc	ax			; seg FFFF ?
	 jnz	setup_b90		; skip if not
	mov	es:F52_HMAFLAG[bx],1	; buffers are in HMA
	mov	ax,es:F52_SECSIZE[bx]
	add	ax,15
	mov	cl,4
	shr	ax,cl			; convert to para size
	mov	dl,'B'			; allocate as a Buffer
	call	alloc_hiseg		; allocate a deblocking buffer
	mov	es:F52_DEBLOCK[bx],ax
	les	bx,drdos_ptr		; ES:BX -> data area
	mov	es:DRDOS_DEBLOCK[bx],ax	;  of deblocking buffer
setup_b90:
	ret

setup_doshndl:
	push	es
	les	bx,func52_ptr			; Internal Data Pointer
	lea	bx,F52_FILEPTR[bx]		; Start of Handle List
	mov	cx,num_files			; Number of DOS Handles
	add	cx,num_fcbs			; + some for FCB's
	cmp	cx,255
	 jbe	setup_dh10
	mov	cx,255				; maximum IFN is 255
setup_dh10:
	cmp	es:DCNTRL_DSOFF[bx],0FFFFh	; Last entry ?
	 je	setup_dh20			; no, loop round again
	les	bx,es:DCNTRL_DSADD[bx]		; Get the Next Entry
	sub	cx,es:DCNTRL_COUNT[bx]		; Update the count
	 jc	setup_dh30			; going negative isn't allowed
	jmp	short setup_dh10

setup_dh20:
	jcxz	setup_dh30			; any left to allocate ?

	mov	ax,DHNDL_LEN			; How many bytes do we need
	mul	cx				; for the structure
	add	ax,DCNTRL_LEN			; including the control
	mov	dx,ax

	test	filesIn,FILES_IN_HMA
	 jz	setup_dh23
	push	es
	push	bx
	push	ax
	push	cx
	push	dx
	call	SetupHMA			; make sure HMA chain is established
	pop 	cx
	push 	cx				; CX = bytes wanted
	mov	dx,0FFFFh			; anywhere is OK
	call	AllocHMA			; ES:DI -> allocated data
	pop	dx
	pop	cx
	pop	ax
	pop	bx
	 jc	setup_dh22
	mov	ax,es
	pop	es
	jmp	short setup_dh27
setup_dh22:
	pop	es
setup_dh23:
	add	ax,15				; Ensure the new structure is
	shr 	ax,1
	shr 	ax,1				; a paragraph value
	shr 	ax,1
	shr 	ax,1				; allocate some memory
	mov	dl,'F'				; allocate for Files
	test	filesIn,FILES_IN_UMB		; UMB usage activated?
	 jz	setup_dh25			; no, use conventional mem
	call	alloc_upper			; then try to move them there first
	 jnc	setup_dh26			; if upper fails, try low mem
setup_dh25:
	call    alloc_seg           
setup_dh26:
	xor	di,di
setup_dh27:
	mov	es:DCNTRL_DSOFF[bx],di		; link the new seg
	mov	es:DCNTRL_DSSEG[bx],ax		; to the end of the list
	
; We can now initialise the new structure
	les	bx,es:DCNTRL_DSADD[bx]		; Get the New Entry
	mov	es:DCNTRL_DSOFF[bx],0FFFFh	; terminate the list
	mov	es:DCNTRL_DSSEG[bx],0FFFFh	; with -1,-1
 	mov	es:DCNTRL_COUNT[bx],cx		; Number of elements
; Now zero the tables
	mov	ax,DHNDL_LEN			; How many bytes do we have
 	mul	cx				; with this number of elements
	mov	cx,ax				; in the structure
	lea	di,DCNTRL_LEN[bx]		; Zero the contents of the
	xor	al,al				; structure
	rep	stosb
	 
setup_dh30:
	pop	es
	ret


setup_drives:
	mov	al,next_drv		; AL = # of drives supported
	push	es
	push 	bx
	les	bx,func52_ptr		; ES:BX -> base of DOS variables
	mov	es:F52_PHYDRV[bx],al	; set # of Physical drives installed
;	mov	es:F52_LASTDRV[bx],al	; set # of Logical drives installed
	mov	es:F52_LASTDRV[bx],26	; set # of Logical drives installed
	pop	bx
	pop 	es
	ret


setup_fopen:		; allocate file hashing information
;-----------
	les	bx,drdos_ptr
	mov	ax,num_fopen		; get # of hashed directory entries
	cmp	ax,-1			; has it been set yet ?
	 jne	setup_fopen10		; yes, then leave it alone
	mov	ax,DEF_NUM_FOPEN
	cmp	es:DRDOS_HIMEM_ROOT[bx],0; do we have a high memory chain ?
	 jne	setup_fopen10		; high memory means no TPA hit
	xor	ax,ax			; keep things small otherwise
setup_fopen10:
	xor	dx,dx			; AX/DX = 32 bit # of entries
	mov	si,max_clsize		; max. cluster size
	mov	cl,5			; 32 byte per directory entry
	shr	si,cl			; SI = directory entries per cluster
	add	ax,si			; round up count to multiple of cluster
	dec	ax
	div	si			; AX = # of hashed blocks
	mov	cx,ax
	 jcxz	setup_fopen90		; skip if hashing disabled

	mov	es:DRDOS_HASHMAX[bx],si	; maximum # dir entries allowed

	shl	si,1			; SI = bytes required for data
	lea	si,HCB_DATA[si]		;  + control information
	mul	si			; AX bytes of data required
	test	dx,dx
	 jnz	setup_fopen90		; overflow (shouldn't happen)

; Allocate CX HCB_'s of size SI bytes, AX bytes in total

	mov	bx,es:DRDOS_HIMEM_ROOT[bx]; do we have a high memory chain ?
	test	bx,bx			;  zero indicates we don't
	 jz	setup_fopen30
	mov	dx,0FFFFh		; use the magic FFFF segment
	mov	es,dx
	cmp	ax,es:2[bx]		; is there enough room ?
	 ja	setup_fopen30		; no, forget try conventinal memory
	sub	es:2[bx],ax		; else allocate the memory
	mov	di,es:2[bx]		; get base+length
	add	di,bx			;  = our allocation
	mov	ax,es:2[bx]		; if the section left is under
	cmp	ax,2*WORD		;  2 words discard it
	 jae	setup_fopen20		;  as we may overwrite size/link
	mov	ax,es:[bx]		; get next entry
	les	bx,drdos_ptr		;  and make it the new himem root
	mov	es:DRDOS_HIMEM_ROOT[bx],ax
setup_fopen20:
	xchg	ax,dx			; AX = FFFF
	jmp	short setup_fopen40	; AX:DI -> data block allocated

setup_fopen30:
	shr	ax,1			; convert size to para's
	shr	ax,1
	shr	ax,1
	shr	ax,1
	inc	ax			; allow for rounding
    mov dl,'E'          
	call	alloc_hiseg		; allocate it para aligned
	dec	ax			; zero offset terminates the chain
	mov	di,10h			;  so start with a non-zero offset
;	jmp	short setup_fopen40	; AX:DI -> data block allocated

setup_fopen40:
; setup CX HCB_'s of size SI at AX:DI
	les	bx,drdos_ptr
	mov	es:DRDOS_HASHOFF[bx],di
	mov	es:DRDOS_HASHSEG[bx],ax
	mov	es,ax

setup_fopen50:
	mov	es:HCB_DRV[di],-1	; discard the HCB initially
	mov	bx,di			; remember where it is
	add	di,si			; onto next HCB_
	mov	es:HCB_LINK[bx],di	; link it to previous HCB_
	loop	setup_fopen50		; allocate all hash control blocks
	mov	es:HCB_LINK[bx],0	; zero terminate the list
setup_fopen90:				; all HCBs done, return
	push	cs
	pop	es			; back to 8080 model
	ret


	Public	whitespace

whitespace:
	lodsb				; Skip any White Space in the 
	cmp 	al,' '
	jz 	whitespace		; CR/LF terminated string
	cmp 	al,TAB
	jz 	whitespace
	dec	si
	ret

	Public	build_cmd_tail
build_cmd_tail:
	push 	ds
	pop 	es
	mov	cx,(lengthof cfg_buffer) - 3 ; (leave room for 3 extra chars)
	mov	di,offset cfg_buffer
build_cl1:
	lodsb			; Copy the device name
	cmp	al,' '		; until a Control char (end of line)
	 jbe	build_cl2	; or a Space (end of name)
	cmp	al,'/'		; Also stop scanning when a switch 
	 je	build_cl2	; character is detected
	stosb
	loop	build_cl1
	mov	al,CR		; indicate we can go no more....
	jmp	short build_cl4
build_cl2:
	cmp	al,CR		; it it really the end ?
	mov	al,' '		; now insert a space character
	stosb
	 je	build_cl_exit	; CR meant it's time to go
	cmp	byte ptr [si-1],' '
	 je	build_cl3
	dec	si		; rewind the source one character	
build_cl3:
	lodsb			; Copy the tail
	cmp	al,CR		; until we find a CR
	 je	build_cl4	; at the end of the line
	stosb
	loop	build_cl3
	mov	al,CR		; no more room, so terminate
build_cl4:
	stosb
build_cl_exit:
	mov	al,LF		; now insert the terminating linefeed
	stosb			; at the end of the buffer
	mov	si,offset cfg_buffer
	ret

save_vecs:
; save interrupt vectors so we can restore if device init fails
	push 	ds
	push 	es
	push 	si
	push 	di
	push 	cx
	mov	cx,(lengthof vec_save_buf)*2	; CX = words to save
	xor	si,si
	mov	ds,si				; DS:SI -> vectors to save
	push 	cs
	pop 	es
	mov	di,offset vec_save_buf		; ES:DI -> save area
	rep	movsw				; save them
	pop 	cx
	pop 	di
	pop 	si
	pop 	es
	pop 	ds
	ret
	
restore_vecs:
; replace interrupt vectors after a dd_init fails
	push 	ds
	push 	es
	push 	si
	push 	di
	push 	cx
	mov	cx,lengthof vec_save_buf	; CX = vectors to restore
	push 	cs
	pop 	ds
	mov	si,offset vec_save_buf		; DS:SI -> save area
	xor	di,di
	mov	es,di				; ES:DI -> vectors to restore
rest_vec1:
	mov	ax,es:2[di]			; get updated vector
	cmp	ax,mem_current			; below attempted driver?
	 jb	rest_vec2			; yes, don't zap it
	cmp	ax,mem_max			; above attempted driver?
	 jae	rest_vec2			; yes, don't zap it
	movsw
	movsw					; else restore vector
	jmp	short rest_vec3			;   overwritten by driver
rest_vec2:
	add	si,dword			; skip vector in source
	add	di,dword			;   and in destination
rest_vec3:
	loop	rest_vec1			; next vector
	pop 	cx
	pop 	di
	pop 	si
	pop 	es
	pop 	ds
	ret

INITCODE ends


INITDATA	segment public word 'INITDATA'
	
	extrn	shell:byte		; Default Command Processor
	extrn	shell_cline:byte	; Default Command Line
	extrn	num_files:word		; default # of file handles
	extrn	num_fcbs:word		; default # of fcb file handles
	extrn	num_fopen:word		; default value for fast open
	extrn	country_code:word	; Requested Country Code (Default US)
	extrn	num_stacks:word		; # hardware stacks wanted
	extrn	stack_size:word		; size of a hardware stack


	extrn	mem_current:word	; Current Load Address
	extrn	mem_max:word		; Top of Available Memory
	extrn	init_dseg:word		; Current init Data Segment

	extrn	dos_dseg:word
	extrn	bios_seg:word
	extrn	func52_ptr:dword
	extrn	drdos_ptr:dword
	extrn	res_ddsc_ptr:dword
	extrn	cfg_head:word
	extrn	cfg_tail:word
	extrn	cfg_seeklo:word
	extrn	cfg_seekhi:word
	extrn	boot_options:word

include	initmsgs.def				; Include TFT Header File
include	biosmsgs.def


	extrn	preload_drv:byte
	extrn	init_drv:byte		; the initial boot drive

	Public	dev_load_seg, dev_reloc_seg, dev_epb, dev_name, dev_count
	Public	rel_unit, dev_epb
	Public	strategy_off, strategy_seg, interrupt_off, interrupt_seg, request_hdr
	Public	next_drv, strategy_seg, strategy, interrupt
	Public	strategy_seg, condev_off, condev_seg, clkdev_off, clkdev_seg
	Public	num_blkdev, blkdev_table, next_drv, max_secsize
	Public	max_clsize, init_buf, num_read_ahead_buf
	Public	buffersIn, history_flg, history_size
	Public	dbcs_tbl, ctry_info, boot_device, boot_drv, resdev_chain
	Public	filesIn, stacksIn, lastdrvIn


history_flg	db	0	; Disable history buffers to save RAM
history_size	dw	256	; When enabled 2*history size are used for bufs

cfg_buffer	db	CFG_BUF_LEN dup (0)	; extra termination for buggy Windows
		db	CR,LF,0		; device driver - give it CR/LF to hit
	
init_buf	db	MIN_NUM_BUFFS	; default # of buffers
num_read_ahead_buf db	DEF_READ_AHEAD	; default # of read-ahead
buffersIn	db	0		; desired location of buffers, default is low

filesIn		db	0		; desired location of file handles, default is low
stacksIn	db	0		; desired location of stacks, default is low
lastdrvIn	db	0		; desired location of LDT, default is low

dev_count	db	0		; count of new drives (used by preload)
next_drv	db	0		; Next Drive to Allocate
num_blkdev	dw	0		; # of block devices installed

boot_device	dw	0,0		; ptr to boot device
boot_drv	db	0		; and the sub unit number

max_secsize	dw	0		; max. sector size encountered
max_clsize	dw	0		; max. cluster size encountered

;	Do not change the order of the next four words:
clkdev_off	dw	0		; clock device driver
clkdev_seg	dw	0
condev_off	dw	0		; console device driver
condev_seg	dw	0

bpbptr		label dword		; temporary BPB pointer
bpboff		dw	0
bpbseg		dw	0

devptr		label dword		; temporary device header pointer
devoff		dw	0
devseg		dw	0

resdev_chain	label dword		; head of chain for resident device
resdev_off	dw	-1		; drivers
resdev_seg	dw	-1
	
abs_unit	dw	0		; absolute unit #
rel_unit	dw	0		; relative unit #

blkdev_table	db	BLKDEV_LENGTH*26 dup (0); save block device driver addr. here

;
;	Variable for the FUNC_DEVICE and DEV_INIT sub routines
;

strategy	label dword		; Device Strategy Entry Point
strategy_off	dw	0		; Offset 
strategy_seg	dw	0		; Segment Address

interrupt	label dword		; Device Entry Point
interrupt_off	dw	0		; Offset
interrupt_seg	dw	0		; Segment Address

dev_root	label dword		; Pointer to Root of Device List
dev_offset	dw	0		; Offset of First Device
dev_segment	dw	0		; Segment of First Device

request_hdr	db	RH_SIZE dup (0)		; DOS Request Header

dev_name	db	MAX_FILELEN dup (0)

dev_epb		label dword
dev_load_seg	dw	0		; Load Segment for Device Driver
dev_reloc_seg	dw	0		; Relocation Factor to be Applied

;
; A number of routines share this common buffer as they are never required
; at the same time. The current clients are -
;
; BDOSLDR.A86:	a sector buffer for boot load of IBMDOS
; CONFIG.A86:	vector save buffer (during devicehigh)
; NLSFUNC.A86:	scratch area for country info

	Public	sector_buffer
sector_buffer	label byte
;		rb	512		; we need to read a single sector

	Public	nls_temp_area
nls_temp_area	label byte		; NLS buffer can be shared with
;		db	258 dup (0)	;  vec_save_buf as they are never
					;  used together


vec_save_buf	dd	256 dup (0)	; reserve space to save int vectors

dbcs_buf	db	0		; BDOS puts a 7 here
dbcs_tbl	dd	0		; pointer to DBCS table in BDOS

ctry_info	db	CI_LENGTH dup (0)	; country information 

num_buf		dw	0		; # of buffers allocated


; The following are used for detecting old bus master controllers:

removableMediaRequest	db	13		; length of request
			db	0		; unit
			db	15		; removable media check command
			dw	0		; status
			db	8 dup (0)	; reserved bytes


readRequest		db	30		; length of request
			db	0		; unit
			db	4		; read command
			dw	0		; status
			db	8 dup (0)	; reserved bytes
			db	0F8h		; media ID
			dw	0,0		; buffer address
			dw	1		; read one sector
			dw	0FFFFh		; use big sector read
			dw	0,0		; Volume ID
			dw	1,0		; starting sector zero


UpperMemoryBuffer	dw	0

numUnits		dw	0

deblockPointer		label dword
deblockOffset		dw	0
deblockSeg		dw	0

	Public	DeblockSetByUser
DeblockSetByUser	db	FALSE

	Public	configPass
configPass		db	0

INITDATA ends

	end
