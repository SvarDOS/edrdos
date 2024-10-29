;    File              : $BIOSINIT.ASM$
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
;    BIOSINIT.A86 1.43 93/12/03 00:38:19
;    Fix bug in AllocHMA when base not para aligned
;    BIOSINIT.A86 1.42 93/11/29 21:40:03
;    Fill in name field of system DMD's (owner=8) with 'SC'
;    BIOSINIT.A86 1.41 93/11/18 15:43:14 
;    Add primitive multi-master checking
;    BIOSINIT.A86 1.40 93/11/11 12:25:29 
;    VDISK header changes
;    BIOSINIT.A86 1.39 93/11/08 23:19:22 
;    SetupHMA does CALL5 initialisation
;    BIOSINIT.A86 1.38 93/10/29 20:03:48
;    BIOS relocation services restored for possible 3rd party memory manager use
;    BIOSINIT.A86 1.37 93/10/29 19:42:27
;    Change HIDOS default to off
;    BIOSINIT.A86 1.36 93/09/22 15:22:14
;    Change int21/4458 to les bx,cs:drdos_ptr (smaller, faster)
;    BIOSINIT.A86 1.35 93/09/03 20:10:55
;    Support intl YES/NO
;    BIOSINIT.A86 1.34 93/09/02 22:34:42
;    Add header to system allocations
;    BIOSINIT.A86 1.33 93/09/01 17:36:57
;    increase stack size for aspi4dos.sys
;    BIOSINIT.A86 1.31 93/08/06 20:55:16
;    re-arrange device init order for SCREATE.SYS on a VDISK.SYS
;    BIOSINIT.A86 1.28 93/08/02 14:45:43
;    hide preload drives from func_device
;    ENDLOG

	include config.equ
	include	msdos.equ		; DOS Function Equates
	include	psp.def			; PSP Definition
	include f52data.def		; Internal DOS data area
	include	doshndl.def		; Dummy DOS structures
	include	config.equ
	include	fdos.equ
	include	modfunc.def

TRUE	   	equ	0FFFFh	      ; value of TRUE
FALSE	   	equ	0	      ; value of FALSE

;
;	Equates for INIT_FLAGS which can be modified by the BIOS
;	the default is a RAM based BDOS (Code and Data) with INIT_DRV
;	specifing the default drive and the initial drive for COMSPEC
;

INIT_ROMCODE	equ	0001h		; Rom based DOS CODE
INIT_COMSPEC	equ	0002h		; COMSPEC_DRV specifies the default
					; Command Processor Drive
INIT_WINDOWS	equ	0004h		; Disable windows support

COMMAND_BASE	equ	000E0h		; must cover FFFF:D0 for CALL5 fixup
COMMAND_SIZE	equ	01FA0h

CGROUP	GROUP	CODE, INITCODE, INITDATA, INITPSP, INITENV, DATAEND
ASSUME CS:CGROUP,DS:CGROUP

CODE	segment public byte 'CODE'
CODE ends

;
;	The DOS Code Segment is formatted as follows.
;
DOS_OFFSET	equ	word ptr  0008h	; Offset of code in segment
HISTORY_CODE	equ	word ptr  000Ch	; Start of history code
INIT_CODE	equ	word ptr  000Eh	; Start of initialisation code
DOS_FLAG	equ	word ptr  001Ch	; Compressed Data Flag
DOS_CODE	equ	word ptr  001Eh	; DOS Code Length (Bytes)
DOS_DATA	equ	word ptr  0020h	; DOS Data Length (Bytes)
NO_YES_CHARS	equ	word ptr  0028h	; DOS Data No/Yes characters

INT31_SEGMENT	equ	word ptr 00C6h		; DOS Data Segment pointer
						; for ROM systems
JMPF_OPCODE	equ	0EAh			; 8086 JMPF instruction

;F5KEY		equ	3F00h
;F8KEY		equ	4200h

SWITCH_F	equ	01h
SWITCH_N	equ	02h

	extrn	kernflg:byte
	extrn	oldxbda:word
	extrn	newxbda:word
	extrn	xbdalen:word
	extrn	oldmemtop:word

INITCODE	segment public byte 'INITCODE'
	extrn	cleanup:near			; BIOS Clean Up routine
	extrn	config_init:near		; CONFIG Code Init
	extrn	config_finish:near		; Update DOS with Device Info
	extrn	config:near			; CONFIG.SYS Processor
	extrn	crlf:near			; Output CR/LF to screen
	extrn	resident_device_init:near	; Device Driver Init
	extrn	detect_boot_drv:near
if SINGLEFILE eq 0
	extrn	read_dos:near			; load DOS file
	extrn	dos_version_check:near
endif
	extrn	setup_ldt:near
	extrn	setup_stacks:near
	extrn	preload_done:near

copyright:
	include version.inc
	db COPYRIGHT_STR, 0

	Public	biosinit
;========
biosinit:
;========
;	entry:	MEM_SIZE    = memory size in paragraphs
;		DEVICE_ROOT = address of 1st resident device driver
;		INIT_DRV    = boot drive (0 = A:, 1 = B:, etc.)
;		INIT_BUF    = minimum # of disk buffers
;		CURRENT_DOS = code segment of DOS (if loaded)
;		INIT_FLAGS  = Control Flags
;		COMSPEC_DRV = Drive for Command Processor
;	
;
; we set up the following variables
;		BIOS_SEG    = low memory BIOS code/data (static)
;		DOS_DSEG    = low memory DOS data area (static)
;		RCODE_SEG   = relocated BIOS code segment
;		DOS_CSEG    = relocated DOS code segment
;		INIT_DSEG   = segment based initialisation data
;
	cld
	cli
	mov	ax,cs			; Initialise our stack and Data Segment
	mov	ds,ax
	mov	ss,ax
	mov	sp,offset stack
	sti

	mov	bios_seg,ax		; Save the BIOS Segment

; Now some code which allows Remote Program Loader to reserve some memory
; which will be safe from being trampled on by the system.
; The RPL takes over Int 2F and has a magic signature "RPL" at offset 3 from
; it's entry point. If this is detected an Int2f is issued
;
; On Entry:
;	AX = 4A06, DX = Segment address of top of memory
; On Exit:
;	DX = segment address of the RPL
;
; On return the system will build a DMD entry for the RPL, with an owner field
; of 8 (ie. System). The RPL can poke this entry to 0 when it wishes to free
; the memory.
;
; In addition we now look for "RPLOADER", and if found we remember the address
; of the entry point so we can call it with status information

	mov	dx,mem_size		; get existing size
	dec	dx			; one para less for upper mem DMD link
	xor	ax,ax
	mov	es,ax			; point to vectors
	mov	bx,4*2fh		; we want Int 2F vector
	les	bx,es:dword ptr [bx]	; pick up the contents
	lea	di,3[bx]		; point to magic signature "RPL"
	mov	si,offset rpl_name
	mov	cx,3
	repe	cmpsb			; does the signature match ?
	 jne	biosinit20
	mov	cx,5			; look also for "RPLOADER"
	repe	cmpsb
	 jne	biosinit10
	mov	rpl_off,bx		; save entry point for use later
	mov	rpl_seg,es
biosinit10:
	mov	ax,4a06h		; magic number for RPL
	int	2fh			; does anyone want to steal memory ?
	inc	dx
	cmp	dx,mem_size		; is memory size unchanged ?
	 jnb	biosinit20
	dec	dx			; point back at start of memory
	dec	dx			;  then one below for DMD start
	mov	es,dx			; ES points to DMD
	mov	es:DMD_ID,IDZ		; make it last in the chain
	mov	es:DMD_PSP,8		; owned by system
	lea	di,es:DMD_NAME		; point to name field
	mov	si,offset rpl_name
	mov	cx,(lengthof rpl_name)/2
	rep	movsw			; initialise name field too
	inc	dx			; skip the DMD for real top
	xchg	dx,mem_size		; replace memory size with new value
	sub	dx,mem_size		; whats the difference ?
	mov	es:DMD_LEN,dx		; save it's this length
biosinit20:

; End of RPL support
	mov	ax,mem_size		; get top of memory
	sub	ax,MOVE_DOWN
	mov	mem_max,ax		; last available paragraph

	mov	init_dseg,ax		; initialisation data lives here
	mov	cl,4
	mov	dx,DYNAMIC_DATA_END+15
	shr	dx,cl			; we need this much dynamic data
	add	ax,dx

; Now we try to relocate the BIOS
	mov	dx,rcode_len		; we want to keep this much BIOS code
	add	systemSize,dx		;  so add to reserved space in HMA
	mov	dx,icode_len		; how much do we want to move ?
	shr	dx,cl
	 jz	biosinit30		; if ROMed we have nothing to relocate
	mov	rcode_seg,ax		; relocated BIOS lives here
	add	ax,dx			; remember how much we allocated
	mov	dx,rcode_offset
	mov	si,dx
	mov	di,dx
	shr	dx,cl			; DX = para offset of data
	sub	rcode_seg,dx		; adjust our segment value
	mov	es,rcode_seg
	mov	cx,icode_len
	rep	movsb			; copy it up
biosinit30:
	mov	dos_cseg,ax		; a relocated DOS image will live here

	; Move BDOS to dos_cseg segment if we have combined BIO/BDIOS file
if SINGLEFILE eq 1
	push	ds
	mov	current_dos,ax		; prevent relocated_init from
	mov	es,ax			; trying to load BDOS file
	mov	ax,offset CGROUP:DATAEND	; calculate paragraphs
	mov	cl,4			; of BDOS into the kernel file...
	shr	ax,cl
	push	cs
	pop	si
	add	ax,si			; ... and add kernel load segment to
	mov	ds,ax			; get absolute BDOS segment
	xor	si,si
	xor	di,di
	mov	cx,ds:DOS_CODE		; get code and data size from BDOS
	add	cx,ds:DOS_DATA		; header
	inc	cx
	shr	cx,1
	rep	movsw			; move it
	pop	ds
endif

	mov	ax,offset biosinit_end+32
	mov	cl,4			; Leave the Last Paragraph Free for
    	shr 	ax,cl           	;  himem DMD 
	neg	ax			; Calculate the destination
	add	ax,mem_size		; Segment for the BIOS relocation

	mov	cx,offset biosinit_end	; Relocate the BIOSINIT code to 
	mov	si,offset biosinit	; the top of available memory
	mov	di,si
	sub	cx,si			; Size of BIOSINIT
	mov	es,ax			; Initialize ES and copy CX words
	rep	movsb

	push	es			; fiddle RETF to relocated code
	mov	ax,offset relocated_init
	push	ax
	retf
;
;	Generic BIOS INIT Patch area
;
;	include	i:patch.cod
	db 256 dup (90h)
;
;	BIOSINIT CODE and DATA have now been relocated to high memory
;
relocated_init:
	mov	ax,cs
	cli
	mov	ss,ax
	mov	sp,offset stack
	sti
	mov	ds,ax			; All Segment registers now point
	mov	es,ax			; to the relocated BIOSINIT


	call	config_init		; initialize setup module
	call	dd_fixup		; fixup relocatable device drivers
	les	di,device_root		; initialize all the resident
	call	resident_device_init	;   device drivers
	push 	cs
	pop 	es

	mov	dx,1			; phase one of RPL initialisation
	call	rploader		;  inform RPLoader if present
	call	Verify386		; CY set if not a 386
	mov	ax,mem_current		; get ending address returned by BIOS
	 jc	dont_align
	cmp	ax,0100h
	 jae	dont_align		; lets be 4 KByte aligned to benefit
	mov	ax,0100h		;  the multi tasker (386 or above)
dont_align:
	mov	free_seg,ax		;  and save as first Free Segment
	test	init_flags,INIT_ROMCODE ; ROM boot: no boot drv detection
	 jnz	skip_boot_drv_detection
	call	detect_boot_drv
skip_boot_drv_detection:
if SINGLEFILE eq 0
	cmp	current_dos,0		; does the OEM want us to read
	 jnz	dos_reloc		;   the DOS file from disk?
	mov	ax,dos_cseg
	mov	current_dos,ax		; the file is held on the INIT_DRV with
	call	read_dos		;   the name specified in DOS_NAME
endif

;
;	The following code will relocate the DOS code.
;
dos_reloc:
;
; We now move the DOS data to low memory
;
	mov	ax,current_dos
	mov	dos_cseg,ax		; Update the DOS Code Segment
	mov	ds,ax

	mov	cl,4

	mov	ax,ds:DOS_CODE		; get size of DOS code
	add	cs:systemSize,ax	;  and add to the system size
	shr	ax,cl			; convert to para's
	mov	cs:dosCodeParaSize,ax	; save for EMM386.SYS
	
	mov	ax,ds:DOS_OFFSET	; remember we have padding
	add	cs:dos_coff,ax		;  and adjust DOS init offset
	shr	ax,cl			; also adjust DOS segment
	sub	cs:dos_cseg,ax		;  to account for padding

	xor	ax,ax
	mov	es,ax			; ES -> interrupt vectors
	mov	ax,ds:DOS_DATA		; get # of bytes of DOS data
	mov	cs:dosdata_len,ax
	add	ax,15
	shr	ax,cl			; get para size of DOS data
	sub	cs:mem_max,ax
	mov	ax,cs:mem_max
;	xchg	ax,cs:free_seg		; get seg for DOS data
;	add	cs:free_seg,ax		; remember how much we used
	mov	es:INT31_SEGMENT,ax	; update the segment value of INT31
	mov	es,ax			;  so ROMMED systems can find PCM_DSEG
	mov	cs:dos_dseg,ax		; we need to remember where too...

	mov	si,ds:DOS_CODE		; offset of DOS Data
	xor	di,di			; destination offset

	test	ds:DOS_FLAG, 1		; has the DOS Data been compressed
	 jnz	dos_r20			; yes so call the decompress routine
	mov	cx,ds:DOS_DATA		;  otherwise just copy the data.
	rep	movsb
	jmp	short dos_r40

;
;	This routine will decompress the DOS data area which has 
;	been compressed after linking using Andy Wightmans data 
;	compression algorithm.
;
dos_r20:
	lodsw				; get control word
	mov	cx,ax			; as a count
	 jcxz	dos_r40			; all done
	test	cx,8000h		; negative ?
	 jnz	dos_r30			; yes do zeros
	rep	movsb			; else move in data bytes
	jmp	short dos_r20		; and to the next

dos_r30:
	and	cx,7fffh		; remove sign
	 jcxz	dos_r20			; none to do
	xor	ax,ax
	rep	stosb			; fill with zeros
	jmp	short dos_r20

dos_r40:
	push 	cs
	pop 	ds
	push 	cs
	pop 	es

	mov	cl,dev_count
	mov	res_dev_count,cl
	mov	cl,4			; reserve space for resident DDSC's
	mov	ax,DDSC_LEN
	mul	dev_count		; AX byte are required
	add	ax,15
	shr	ax,cl			; AX para are required
	sub	mem_max,ax
	mov	ax,mem_max
;	xchg	ax,free_seg
;	add	free_seg,ax		; we have allocated the space
	mov	res_ddsc_seg,ax		; point res_ddsc_ptr at the space
	mov	dx,dos_dseg
	sub	ax,dx			; DOS resident DDSC_'s use DOS data seg
	cmp	ax,1000h		; surely we must fit ?
	 jae	dos_r50
	shl	ax,cl			; offset within pcmode data segment
	mov	res_ddsc_off,ax
	mov	res_ddsc_seg,dx		; setup pointer to resident DDSC's
dos_r50:

	mov	ax,free_seg		; reserve space for interrupt stubs
	mov	int_stubs_seg,ax
	add	free_seg,11

;
;	Call the DOS INIT Code passing all the information setup
;	by the BIOS.
;
	mov	ax,mem_size		; pass the Memory Size, the first free
	mov	bx,free_seg		;  segment and the initial 
	mov	dl,init_drv		;  drive to the DOS init routine
	mov	es,int_stubs_seg
	cli
	mov	ds,dos_dseg		; DS -> DOS data segment
	call	dword ptr cs:dos_init

;	mov	es,cs:dos_dseg
;	mov	bx,26h			; ES:BX -> list of lists
;	mov	ax,es:word ptr F52_FCBPTR[bx]
;    shr ax,1 ! shr ax,1     
;    shr ax,1 ! shr ax,1     
;	and	es:word ptr F52_FCBPTR[bx],15
;	add	es:word ptr F52_FCBPTR+2[bx],ax
	sti
	push	cs
	pop 	ds
	mov	es,current_dos		; internationalise the yes/no chars
	mov	di,es:NO_YES_CHARS
	mov	es,dos_dseg		; ES:DI -> internal table
	mov	ax,word ptr no_char
	stosw				; replace default no chars
	mov	ax,word ptr yes_char
	stosw				; replace default yes chars
	push 	cs
	pop 	es
	add	dos_coff,3		; next dos_init call just fixes up
					;  segment relocations

	mov	dx,2			; phase two of RPL initialisation
	call	rploader		;  inform RPLoader if present

	call	config_start		; get free memory
	call	config			; read and process CONFIG.SYS
	call	config_end		; relocate DOS code and free memory

	mov	ax,(MS_X_OPEN*256)+2	; Open for Write
	mov	dx,offset idle_dev	; Get the IDLE Device Name#
	int	DOS_INT			; Open the device
	 jc	dos_r70			; Quit on Error
	push	ax			; Save the Handle
	mov	ax,4458h		; Get the address of the IDLE data
	int	DOS_INT			; area in ES:AX
	pop	bx			; Restore the Handle
	mov	idle_off,ax		; Save the data area offset and 
	mov	idle_seg,es		; segment
	mov	ax,4403h
	mov	dx,offset idle_off
	mov	cx,DWORD
	int	DOS_INT
	mov	ah,MS_X_CLOSE
	int	DOS_INT

dos_r70:
	call	mark_system_memory	; ensure any memory we have allocated
					; is marked as system
	mov	bios_offset,offset cleanup
	call	dword ptr bios		; execute BIOS cleanup code

	mov	ax,(MS_M_STRATEGY*256)+3
	xor	bx,bx			; unlink in upper memory region
	int	21h

	mov	dx,3			; phase three of RPL initialisation
	call	rploader		;  inform RPLoader if present

	mov	ax,12ffh		; magic cleanup call to MemMAX
	mov	bx,5			;  to do any tidy ups it wishes
	xor	cx,cx
	xor	dx,dx
	int	2fh

	push 	cs
	pop 	es
load_e10:
	; expand shell filename to absolute path
	mov	si,offset shell
	mov	di,si
	push	ds
	pop	es
	mov	ah,MS_X_EXPAND
	int	DOS_INT
	jc	shell_error

	call	add_comspec_to_env	; append / update COMSPEC in config env
if BIO_SEG ge 70h
	; relocate config environment to segment 60 if kernel is not in the way
	call	copy_config_env_to_seg60
endif
	mov	ax,(MS_X_EXEC * 256)+0	; Exec the Command Processor
	mov	bx,offset exec_env	; Get the Parameter Block Address
	mov	dx,offset shell		; and the Command Processor
	mov	exec_clseg,ds
	mov	exec_fcb1seg,ds
	mov	exec_fcb2seg,ds
	int	DOS_INT			; Go for it

shell_error:
	mov	ah,MS_C_WRITESTR	; Print an error message and wait for
	mov	dx,offset bad_exec	;  the user to enter new name
	int	DOS_INT
	mov	ah,MS_C_READSTR		; get user to input new COMMAND
	mov	dx,offset shell_ask	;  location
	int	DOS_INT
	call	crlf			; tidy up with CR/LF
	xor	bx,bx
	mov	bl,shell_end
	mov	shell[bx],bh		; replace CR with NULL
	jmp	short load_e10


	Public	get_boot_options
get_boot_options:
;----------------
; On Entry:
;	None
; On Exit:
;	AX = boot options
	call	option_key		; poll keyboard for a while
	 jnz	get_boot_options20	; if key available return that
	test	boot_switches,SWITCH_N	; boot keys disabled?
	 jnz	get_boot_options20	; then do not check shift key, either
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
	test	boot_switches,SWITCH_F	; SWITCHES /F present?
	 jnz	option_key20		; yes, skip delay
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
	test	boot_switches,SWITCH_N	; boot keys disabled?
	 jnz	option_key20		; yes, continue without reading it
	cmp	ax,F5KEY		; if it is a key we want then
	 je	option_key40		;  read it, else just leave
	cmp	ax,F8KEY		;  in the type-ahead buffer
	 jne	option_key20
option_key40:
	xor	ax,ax
	int	16h			; read the key
	test	ax,ax			; clear ZF to indicate we have a key
	ret

;
;	Initialise the PSP and inform DOS of the
;	location of the BIOSINIT PSP. The MS_P_SETPSP *MUST* be the first 
;	INT21 function call because the PSP Address is used during the
;	entry code except when the INDOS flag is set and certain function 
;	calls are made.
;
;	Then open the Resident character devices so that the dynamically
;	devices can output messages to the screen etc.
; 
config_start:
	mov	cl,4
	mov	bx,ds
	mov	ax,offset psp		; Now force DOS Plus to use the 
	shr	ax,cl			; internal PSP for all disk and
	add	bx,ax			; character I/O
	mov	xftbl_seg,bx		; Update the Handle Table Pointer
	mov	parent_psp,bx		; and make this the root process
	mov	ah,MS_P_SETPSP		; Set the current PSP
	int	DOS_INT
	mov	ax,3306h
	int	21h			; get true version
	mov	dosVersion,bx		; and plant in initial PSP
if SINGLEFILE eq 0
	call	dos_version_check	; make sure we are on correct DOS
endif
	mov	ax,4458h
	int	DOS_INT			; we need to access local data
	mov	drdos_off,bx		; so save a pointer to it
	mov	drdos_seg,es
	mov	ax,ext_mem_size
	mov	es:DRDOS_EXT_MEM[bx],ax	; save extended memory size in DOS
	mov	ax,5200h
	int	DOS_INT
	mov	func52_off,bx
	mov	func52_seg,es		; save pointer to internal data
	mov	ax,ext_mem_size
	mov	es:F52_EXT_MEM[bx],ax	; save extended memory size in DOS
	mov	ax,TEMP_LDT/16		; use our temporary LDT's
	add	ax,init_dseg		;  during system init
	mov	es:F52_PATHOFF[bx],0	; point at the LDT's
	mov	es:F52_PATHSEG[bx],ax
	push 	cs
	pop 	es

	mov	ah,MS_M_ALLOC		; Allocate all available memory
	mov	bx,0FFFFh		; BX is returned with the maximum
	int	DOS_INT			; available block size

	mov	ah,MS_M_ALLOC		
	int	DOS_INT
	mov	mem_first_base,ax	; Base of 1st allocated block
	mov	mem_current_base,ax	; Base of allocated memory
	mov	mem_current,ax		; Next available Segment

	mov	byte ptr configPass,0
	call	config_finish		; Update DOS with the information
					; obtained from loading the resident
					; drivers.
	mov	ah,MS_DRV_SET		; Select the Default Drive
	mov	dl,init_drv		; passed to us by the BIOS
	int	DOS_INT

	mov	ah,MS_F_DMAOFF		; Initialise the DMA address for 
	mov	dx,offset search_state	; the Search First State data
	int	DOS_INT

	mov	al,init_drv		; get the boot drive then check
	test	init_flags,INIT_COMSPEC	; flags to see if this is the
	 jz	config_s05		; default COMSPEC drive.
	mov	al,comspec_drv

config_s05:
	add	shell,al		; update the drive letter of shell
	add	shell_drv,al		;  and the reload path

	call	open_stdaux		; Open STDAUX as internal handle #0
	call	open_stdcon		; Open Standard CON Devices as #1
	mov	ah,MS_X_CLOSE		; now close AUX again
	mov	bx,STDAUX		; for CONFIG processing
	int	DOS_INT
	ret


;
;	Relocate the DOS CODE from high memory to immediately above
;	the device drivers, buffers etc. Then call the DOS_CLEANUP code
;	so that any self segment pointers maintained in the DOS DATA
;	can be updated. Then free all the unused memory and reopen the
;	standard devices.
;
config_end:
	push	es
	mov	al,last_drv		; get lastdrive value
	les	bx,func52_ptr
	cmp	al,es:F52_PHYDRV[bx]	; less than the # of Physical drives ?
	 ja	config_end10
	mov	al,es:F52_PHYDRV[bx]	; ensure minimum of # physical drives
config_end10:
	mov	es:F52_LASTDRV[bx],al	; set # of drives installed
	mov	cl,4			; we will be converting byte-paras
	mov	ah,LDT_LEN		; we need this many bytes per drive
	mul	ah			; *lastdrive
	add	ax,15			; round LDT's size up to para
	shr	ax,cl
	mov	dl,'L'			; allocate LDT's
	mov	dh,lastdrvIn
	call	alloc_instseg		; Allocate memory AX is destination

	push	di
	push	ax
	xchg	ax,cx
	mov	al,LDT_LEN
	mov	ah,es:F52_LASTDRV[bx]
	cmp	ah,26
	 jbe	config_end20
	mov	ah,26
config_end20:
	mul	ah
	xchg	ax,cx
	push	ds
	push	es
	lds	si,es:F52_PATHPTR[bx]
	mov	es,ax
	rep	movsb
	pop	es
	pop	ds
	pop	ax
	pop	di

	mov	es:F52_PATHOFF[bx],di	; point at the LDT's
	mov	es:F52_PATHSEG[bx],ax	; save seg we just allocated
	pop	es

;	call	setup_ldt		; initialise LDT structures

	call	setup_stacks		; allocate stacks

	call	relocate_system		; relocate system as requested

	mov	configpass,3
	mov	cfg_head,0
	mov	cfg_tail,0
	mov	cfg_seeklo,0
	mov	cfg_seekhi,0
	call	preload_done

	push	es			; Free all of the unused memory
	mov	es,mem_current_base	; ES: Base Allocated Memory
	mov	bx,mem_current		; Get the currently allocated memory
	sub	bx,mem_current_base	; and subtract mem_current_base to
	mov	ah,MS_M_SETBLOCK	; give the number of paragraphs used
	int	DOS_INT			; and modify block accordingly

; Kludge - if the CONFIG file has had a line of the form INSTALL= to load a TSR
; then that TSR will have inherited the handles, so bumping the open count, but
; the func 31 exit leaves all these files open. As a result we will get the
; wrong internal file numbers unless we force complete closure. So we keep
; trying to close each internal handle until we get an error.

	mov	ah,MS_P_GETPSP
	int	DOS_INT			; get current PSP
	mov	es,bx
	mov	cx,es:PSP_XFNMAX	; Close all the standard handles
	les	di,es:PSP_XFTPTR	; and then reopen them in case a
	xor	bx,bx			; dynamicly loadable device has
cfg_e10:				; replaced the BIOS driver
	mov	dl,es:[di+bx]		; save old internal handle
	mov	ah,MS_X_CLOSE
	int	DOS_INT			; try and close this handle
	mov	es:[di+bx],dl		; put the internal handle back 
	 jnc	cfg_e10			; and try and close it again
	mov	es:byte ptr [di+bx],0ffh
	inc	bx			; mark as closed and try next handle
	loop	cfg_e10
	pop	es
;;	jmp	short open_std	

open_std:
	call	open_stdaux		; open AUX device as STDAUX
	call	open_stdcon		; now STDIN, STDOUT, STDERR
;	jmp	open_stdprn		; finally STDPRN

open_stdprn:
	mov	ax,(MS_X_OPEN * 256) + 1
	mov	dx,offset printer	; Open the PRN device
	int	DOS_INT
	 jc	open_sp10		; No PRN device
	cmp	ax,STDPRN		; If all the previous Opens were
	 jz	open_sp10		; successful then this is STDPRN
	mov	bx,ax			; otherwise force this to STDPRN
	mov	cx,STDPRN
	mov	ah,MS_X_DUP2
	int	DOS_INT
	mov	ah,MS_X_CLOSE
	int	DOS_INT
open_sp10:
	ret

open_stdcon:
	mov	ax,(MS_X_OPEN * 256) + 2
	mov	dx,offset console	; Open the CON device
	int	DOS_INT
	 jc	open_sc10		; No CON device
	mov	bx,ax			; First Open should be STDIN
	mov	cx,STDOUT		; Force Duplicate to STDOUT
	mov	ah,MS_X_DUP2
	int	DOS_INT
	mov	cx,STDERR		; Then Force Duplicate to STDERR
	mov	ah,MS_X_DUP2
	int	DOS_INT
open_sc10:
	ret
	
open_stdaux:
	mov	ax,(MS_X_OPEN * 256) + 2
	mov	dx,offset auxilary	; Open the AUX device
	int	DOS_INT			; to get internal handle 0
	 jc	open_sa10		; No AUX device
	mov	bx,ax			; Force DUP to STDAUX
	mov	cx,STDAUX
	mov	ah,MS_X_DUP2
	int	DOS_INT
	mov	ah,MS_X_CLOSE
	int	DOS_INT
open_sa10:
	ret


relocate_system:
	push 	ds
	push 	es
	cmp	dos_target_seg,0FFFFh	; is the OS going high ?
	 jne	relocate_system10
	call	SetupHMA		; make sure HMA chain is established
	xor	cx,cx
	xchg	cx,systemHMA		; free up any space reserved for the OS
	call	FreeHMA
	call	ReserveCommandHMA	; reserve space for COMMAND.COM

relocate_system10:
	call	reloc_bios		; move down relocatable drivers
	call	reloc_dos		; move DOS above drivers if RAM based
	call	reloc_dosdata
	call	reloc_xbda
	xor	cx,cx
	xchg	cx,commandHMA
	call	FreeHMA			; return command.com HMA space to pool
	cli
	mov	es,int_stubs_seg
	mov	ds,dos_dseg		; DS -> DOS data segment
	call	dword ptr cs:dos_init	; (in case of CS relative fixups)
	sti
	pop es
	pop ds
	ret

reloc_dos:				; move DOS down to just above drivers
;----------
	push	ds
	push	es
	test	init_flags,INIT_ROMCODE	; Run the DOS code in ROM
	 jz reloc_dos05
	jmp reloc_dos90	; at CURRENT_DOS - No Code Reloc
reloc_dos05:
	mov	es,current_dos
	mov	dx,es:DOS_OFFSET
	mov	cx,es:DOS_CODE		; get DOS code size in bytes
	mov	ax,dos_target_seg	; get DOS target
	cmp	ax,0FFFFh		; it it seg FFFF ?
	 jne	reloc_dos10
;	mov	es,current_dos
;	mov	dx,es:DOS_OFFSET
	call	AllocHMA		; allocate CX bytes, offset < DX
	 jnc	reloc_dos50		;  if we can use high memory
	xor	ax,ax			; can't, so try auto-allocation
reloc_dos10:
	test	ax,ax			; has a specific address been
	 jnz	reloc_dos40		;  specified ?
	push	cx			; save DOS code size
	xchg	ax,cx
	mov	cl,4
	shr	ax,cl			; convert to paragraphs
	pop	cx
	cmp	hidos,0			; do we want to relocate DOS ?
	 je	reloc_dos20		;  no, allocate conventionally
	call	alloc_upper		;  else allocate space for the DOS
	 jnc	reloc_dos40		;  in upper memory if possible
reloc_dos20:
	mov	es,current_dos		; if conventional memory we
;	mov	ax,es:INIT_CODE		;  can discard INIT code
;	cmp	history_flg,0		; is history enabled ?
;	 jne	reloc_dos30
;	mov	ax,es:HISTORY_CODE	; no, discard history code as well
;reloc_dos30:
;	push	cx
;	add	ax,15
;	mov	cl,4			; convert to paragraphs
;	shr	ax,cl
;	pop	cx
	call	alloc_seg_with_padding	; allocate in conventional memory
reloc_dos40:
	xchg	ax,dx			; save segment address
	mov	es,current_dos		; point at code
	mov	ax,es:DOS_OFFSET	; get offset of code start
	xor	di,di
	mov	es,dx			; ES:DI -> destination address
	push	cx			; save DOS size
	mov	cl,4
	shr	ax,cl			; AX = header size in para's
	sub	dx,ax			; adjust DOS segment accordingly
	pop	cx			; CX = DOS size in bytes
reloc_dos50:
; At this point
; CX = # bytes to move
; ES:DI -> destination
; DX = segment to fixup
;
	mov	dos_cseg,dx		; new code segment for DOS
	mov	ds,current_dos		; DS -> DOS code
	xor	si,si
	shr	cx,1			; CX = # of words in DOS
	rep	movsw			; copy DOS down

reloc_dos90:				; fixups performed
	pop	es
	pop	ds
	ret

reloc_dosdata:
	push	es			; save ES

	mov	ax,DDSC_LEN		;length of DDSC structure
	mul	res_dev_count		; * number of resident devices
	push	ax
	test	hiddscs,DDSCS_IN_HMA	; is HMA usage enabled?
	 jz	reloc_data20		; no, skip it
	push	es
	push	ax
	call	SetupHMA		; prepare HMA
	pop	cx
	mov	dx,0ffffh
	call	AllocHMA		; and try to allocate CX bytes there
	 jc	reloc_data10		; did not work, try other mem instead
	mov	ax,es
	pop	es
	jmp	reloc_data50
reloc_data10:
	pop	es
reloc_data20:
	pop	ax
	push	ax
	mov	cl,4			; convert bytes to paragraphs
	add	ax,15			; and round it
	shr	ax,cl
	mov	dl,'M'			; MCB type
	test	hiddscs,DDSCS_IN_UMB	; is upper mem usage enabled
	 jz	reloc_data30		; no, try low mem instead
	call	alloc_hiseg		; try to allocate upper mem
	 jnc	reloc_data40		; if it did not work, try low
reloc_data30:
	call	alloc_seg		; allocate low mem
reloc_data40:
	xor	di,di
reloc_data50:
	mov	es,ax			; mem position is at ES:DI
	pop	cx
	mov	dx,di
	push	ds
	lds	si,res_ddsc_ptr		; copy DDSCs there
	rep	movsb
	pop	ds
	mov	di,dx
	mov	cl,res_dev_count
	push	ds
	push	es
	les	bx,func52_ptr
	lds	si,es:F52_PATHPTR[bx]
	pop	es
reloc_data60:				; fix up new DDSC addresses in LDTs
	mov	ds:word ptr LDT_PDT[si],di
	mov	ds:word ptr LDT_PDT+2[si],ax
	cmp	cl,1			; and in DDSCs
	 je	reloc_data65		; skip last one
	mov	es:word ptr DDSC_LINK[di],di
	add	es:word ptr DDSC_LINK[di],DDSC_LEN
	mov	es:word ptr DDSC_LINK+2[di],ax
reloc_data65:
	add	di,DDSC_LEN		; next DDSC
	add	si,LDT_LEN		; next LDT
	loop	reloc_data60
	pop	ds
	mov	res_ddsc_seg,ax		; fix up pointers in DOS data segment
	mov	res_ddsc_off,dx
	les	bx,func52_ptr
	mov	es:word ptr F52_DDSCPTR+2[bx],ax
	mov	es:word ptr F52_DDSCPTR[bx],dx

	mov	ax,dosdata_len		; length of DOS data segment
	mov	cl,4			; convert this to paragraphs
	add	ax,15
	shr	ax,cl
	mov	dl,'M'			; MCB type
	test	hidosdata,DOSDATA_IN_UMB ; shall the DOS data go high?
	 jz	reloc_data70		; no, then try low mem instead
	call	alloc_hiseg		; try to allocate upper mem
	 jnc	reloc_data80		; did not work, try low instead
reloc_data70:
	call	alloc_seg		; allocate low
reloc_data80:
	mov	cx,dosdata_len		; copy the DOS data segment to new location
	mov	es,ax
	xor	di,di
	xor	si,si
	push	ds
	mov	ds,dos_dseg
	rep	movsb
	pop	ds
	mov	dos_dseg,ax		; and fix up the pointers
	mov	drdos_seg,ax
	mov	func52_seg,ax
	xor	di,di
	mov	es,di
	mov	es:INT31_SEGMENT,ax

	pop	es			; restore ES again
	ret

reloc_xbda:
	cmp	hixbda,0		; shall the XBDA be moved?
	 jne	reloc_xbda02		; yes
	jmp	reloc_xbda140		; no, nothing to do
reloc_xbda02:
	push	es			; save ES
	mov	ax,40h			; address of BIOS data area
	mov	es,ax
	xor	bx,bx
	mov	ax,es:0eh[bx]		; segment address of XBDA if one exists
	cmp	ax,mem_size		; is it at the top of conventional mem?
	 je	reloc_xbda03		; yes, go on
	jmp	reloc_xbda130		; no, then moving it is no good
reloc_xbda03:
	mov	es,ax			; ES = XBDA segment
	xor	ah,ah
	mov	al,es:[bx]		; length of XBDA in kilobytes
	mov	cl,6			; make this paragraphs
	shl	ax,cl
	mov	cx,ax
	mov	dx,es
	add	ax,dx			; end of XBDA
	cmp	ax,0a000h		; is it just before the video RAM?
	 je	reloc_xbda05		; yes, that is just what we want
	jmp	reloc_xbda130		; if not, do not move it
reloc_xbda05:
	mov	dl,'M'			; MCB type
	mov	ax,cx
	test	hixbda,MOVE_XBDA_HIGH	; shall we try to move it to upper mem?
	 jz	reloc_xbda10		; no
	call	alloc_upper		; try to allocate in upper mem
	 jnc	reloc_xbda20		; did not work, try low instead
reloc_xbda10:
	test	hixbda,MOVE_XBDA_LOW	; shall we move it to low base mem?
	 jnz	reloc_xbda15		; yes
	jmp	reloc_xbda130		; no, then just leave it where it is
reloc_xbda15:
	call	alloc_seg		; allocate low mem
reloc_xbda20:
	push	cx
	xor	bx,bx
	xchg	ax,dx
	xor	ah,ah
	mov	al,es:[bx]		; length of XBDA in kilobytes
	mov	cl,9			; make this words instead
	shl	ax,cl
	xchg	ax,cx
	push	ds
	mov	ax,es			; save old XBDA segment address,
	push	es
	mov	es,BIOS_SEG		; segment address of low memory code
	mov	es:oldxbda,ax		; save old XBDA segment address,
	mov	es:newxbda,dx		; new address
	mov	es:xbdalen,cx		; and length for Int 19h
	pop	es
	push	es			; copy XBDA to new position
	pop	ds
	mov	es,dx
	xor	di,di
	xor	si,si
	rep	movsw
	mov	ax,40h			; and update the BIOS data area with the new address
	mov	ds,ax
	mov	ds:0eh[bx],es
	pop	ds
	pop	cx
	les	bx,func52_ptr		; now get the start of the MCB chain
	mov	es,es:F52_DMDROOT[bx]
	mov	si,mem_size
	dec	si
reloc_xbda30:
	mov	ax,es
	mov	di,ax
	add	ax,es:DMD_LEN		; and check them to find the right one
	inc	ax
	cmp	di,si			; is this the one that includes the old XBDA?
	 je	reloc_xbda40		; yes
	cmp	es:DMD_ID,IDZ		; already the last one?
	 jne	reloc_xbda31		; no
	push	si
	inc	si
	cmp	ax,si			; XBDA immediately following this block?
	pop	si
	 je	reloc_xbda35		; yes
	jmp	reloc_xbda130		; did not find it
reloc_xbda31:
	cmp	ax,si			; already past the right position?
	 jna	reloc_xbda32		; no
	jmp	reloc_xbda130		; that cannot be helped
reloc_xbda32:
	mov	es,ax			; get the address of the next MCB
	jmp	reloc_xbda30		; try again
reloc_xbda35:
	add	es:DMD_LEN,cx		; length of XBDA
	jmp	reloc_xbda45
reloc_xbda40:
	push	ax			; save length of old MCB
	push	es:DMD_PSP		; and the old PSP pointer
	mov	ch,es:DMD_ID		; and also its ID code
	mov	ax,09fffh		; compute the new length
	sub	ax,di
	dec	ax
	mov	es:DMD_LEN,ax		; and update the MCB accordingly
	mov	es:DMD_PSP,0		; make this free mem
	mov	es:word ptr DMD_NAME,'S'+256*'D'
	mov	es:DMD_NAME+2,0
	mov	es:DMD_ID,IDM		; there surely follows another one
	mov	ax,09fffh		; this is where the system area starts now
	mov	es,ax
	mov	es:DMD_ID,ch		; use these values from the old MCB
	pop	es:DMD_PSP
	pop	ax
	sub	ax,9fffh
	dec	ax
	mov	es:DMD_LEN,ax		; and this is the new length
	les	bx,func52_ptr		; update the upper memory chain
	mov	es:F52_DMD_UPPER[bx],9fffh
	les	bx,drdos_ptr
	mov	es:DRDOS_DMD_UPPER[bx],9fffh
reloc_xbda45:
	mov	mem_size,0a000h		; and the base mem top
	mov	ax,40h			; also update the new base mem size
	mov	es,ax			; in the BIOS data area
	mov	bx,13h
	mov	ax,640
	xchg	es:[bx],ax
	mov	es,BIOS_SEG
	mov	es:oldmemtop,ax		; save old conventional memory top
reloc_xbda130:
	pop	es			; restore ES again
reloc_xbda140:
	ret

	Public	HookInt2F

HookInt2F:
;---------
; Hook Int 2F during device driver initialisation so we can intercept
; some broadcasts
; On Entry:
;	None (beware DS/ES can be anything)
; On Exit:
;	None (All regs preserved)
;
	push	es
	push	ax
	push	bx
	les	bx,cs:drdos_ptr
	mov	bx,es:DRDOS_INT2F[bx]	; ES:BX -> Int 2F hooks
	mov	ax,offset Int2FHandler
	xchg	ax,es:4[bx]		; get Int 2F offset
	mov	cs:int2FOff,ax
	mov	ax,cs
	xchg	ax,es:6[bx]		; get Int 2F segment
	mov	cs:int2FSeg,ax
	pop	bx
	pop	ax
	pop	es
	ret

	Public	UnhookInt2F

UnhookInt2F:
;-----------
; Device driver initialisation has finished, so unhook from Int 2F
; On Entry:
;	None (beware DS/ES can be anything)
; On Exit:
;	None (All regs preserved)
;
	push	es
	push	ax
	push	bx
	les	bx,cs:drdos_ptr
	mov	bx,es:DRDOS_INT2F[bx]	; ES:BX -> Int 2F hooks
	mov	ax,cs:int2FOff
	mov	es:4[bx],ax		; restore Int 2F offset
	mov	ax,cs:int2FSeg
	mov	es:6[bx],ax		; restore Int 2F segment
	pop	bx
	pop	ax
	pop	es
	ret


; During device driver init we provide some services on Int 2F
; eg. 12FF for EMM386.SYS and 4A01/4A02 for Windows HIMEM.SYS

Int2FHandler:
;------------
; On Entry:
;	callers DS on stack
; On Exit:
;	if not handled pass on to BIOS, callers DS on stack, all regs preserved
;
	pop	ds			; pop DS from stack
	cmp	ax,4A01h		; Query Free HMA Space ?
	 je	HMAQueryFree
	cmp	ax,4A02h		; Allocate HMA Space ?
	 je	HMAAlloc
	cmp	ax,12FFh		; is it a relocation service ?
	 jne	OldInt2F
	sti				; if we RETF don't leave IF disabled
	cmp	bx,9			; register upper memory link
	 je	DOSUpperMemoryRoot
	cmp	bx,1			; Relocate BDOS
	 jb	DOSQuerySize		; what's the size of DOS
	 je	DOSRelocate		; where to put it
	cmp	bx,3			; Relocate BIOS
	 jb	BIOSQuerySize		; what's the size of BIOS
	 je	BIOSRelocate		; where to put it

OldInt2F:
	push	ds			; DS on stack as expected
		db	JMPF_OPCODE
int2FOff	dw	0
int2FSeg	dw	0


; Enquire DOS size
DOSQuerySize:
;------------
; On Entry:
;	None
; On Exit:
;	AX = 0
;	DX = DOS Size in para's
;
	mov	dx,cs:dosCodeParaSize	; DX = para's required for DOS code
	jmp	short RelocExit

; Relocate DOS
DOSRelocate:
;-----------
; On Entry:
;	DX = para to reloacte to (FFFF=HMA)
; On Exit:
;	AX = 0
;
	mov	cs:dos_target_seg,dx	; save where
	jmp	short RelocExit


; Enquire BIOS size
BIOSQuerySize:
;-------------
; On Entry:
;	None
; On Exit:
;	AX = 0
;	DX = BIOS Size in para's
;
	mov	dx,cs:rcode_len		; DX = bytes required for BIOS code
	add	dx,15
	mov	cl,4
	shr	dx,cl			; DX para's required
	jmp	short RelocExit

; Relocate BIOS
BIOSRelocate:
;------------
; On Entry:
;	DX = para to reloacte to (FFFF=HMA)
; On Exit:
;	AX = 0
;
	mov	cs:bios_target_seg,dx	; save where
;	jmp	short RelocExit

RelocExit:
	xor	ax,ax			; indicate success
	retf	2


DOSUpperMemoryRoot:
;------------------
	les	bx,cs:drdos_ptr
	mov	es:DRDOS_DMD_UPPER[bx],dx	; remember upper memory link
	les	bx,cs:func52_ptr
	mov	es:F52_DMD_UPPER[bx],dx		; remember upper memory link
	xor	ax,ax
	retf	2

HMAAlloc:
;--------
; On Entry:
;	BX = # bytes to allocate
; On Exit:
;	ES:DI -> start of allocated block
;	BX trashed
;
	push	ds
	push	ax
	push	cx
	push	dx
	push	si
	push	bp
	push 	cs
	pop 	ds			; establish data seg
	mov	cx,bx			; CX = bytes wanted
	mov	dx,0FFFFh		; anywhere is OK
	call	AllocHMA		; ES:DI -> allocated data
	pop	bp
	pop	si
	pop	dx
	pop	cx
	pop	ax
	pop	ds
	iret


HMAQueryFree:
;------------
; On Entry:
;	None
; On Exit:
;	BX = Size of block remaining (0 if no HMA)
;	ES:DI -> start of available HMA (FFFF:FFFF if no HMA)
;
	push	ds
	push	ax
	push	cx
	push	dx
	push	si
	push	bp
	push 	cs
	pop 	ds			; establish data seg
	call	SetupHMA		; allocate the HMA for OS use
	les	bx,cs:drdos_ptr
	mov	di,es:DRDOS_HIMEM_ROOT[bx]
	mov	ax,0FFFFh		; get offset of HMA entry
	mov	es,ax
	test	di,di			; do we have a himem root ?
	 jz	HMAQueryFree10		; no, return failure
	mov	bx,es:2[di]		; BX = size of region
	mov	ax,di			; para align the base
	add	ax,15			; because the allocation will
	and	ax,0FFF0h
	sub	ax,di			; AX bytes left in the para
	add	di,ax			; bias the starting location
	sub	bx,ax			; that many less available
	 ja	HMAQueryFree20		; if non-zero, return it
HMAQueryFree10:
	xor	bx,bx			; BX = zero on failure
	mov	di,0FFFFh		; ES:DI -> FFFF:FFFF
HMAQueryFree20:
	pop	bp
	pop	si
	pop	dx
	pop	cx
	pop	ax
	pop	ds
	iret


	Public	AllocHMA

AllocHMA:
;--------
; On Entry:
;	CX = bytes to allocate
;	DX = offset of allocation
; On Exit:
;	CY set if no can do and ES:DI = FFFF:FFFF
; else
;	ES:DI -> memory allocated (para aligned)
;	CX preserved
;	DX = segment to fixup
;
	les	bx,cs:drdos_ptr
	mov	di,es:DRDOS_HIMEM_ROOT[bx]
	test	di,di			; have we a HIMEM chain ?
	 jz	AllocHMA20
	cmp	di,dx			;  low enough for us
	 ja	AllocHMA20
	mov	ax,0FFFFh		; relocate to magic segment	
	mov	es,ax			; lets examine high memory
	mov	ax,es:2[di]		; get size of himem entry
	mov	si,es:[di]		;  and get himem link
	mov	bx,di
	add	bx,15
	and	bx,0FFF0h		; BX is now para aligned
	sub	bx,di			; BX is bytes left in para
	sub	ax,bx			; so we only have this much
	 jc	AllocHMA20		;  less than a para ?
	add	di,15			; para align the base, dropping
	and	di,0FFF0h		;  non-aligned bit on floor
	cmp	ax,cx			; is himem entry big enough ?
	 jb	AllocHMA20		; no, allocate from 1st MByte
	 je	AllocHMA10		; just made it!
	sub	ax,cx			; how much is left
	cmp	ax,2*WORD		; is it to small to keep ?
	 jb	AllocHMA10		; no, discard the remainder
	mov	bx,di			; point to new entry
	add	bx,cx			;  this many byte up
	mov	es:[bx],si		; fill in link field
	mov	es:2[bx],ax		;  and length
	mov	si,bx			; make this new root
AllocHMA10:
	push	cx			; save length of CODE
	push	dx			;  and offset of CODE
	les	bx,cs:drdos_ptr
	mov	es:DRDOS_HIMEM_ROOT[bx],si
	pop	ax			; AX = offset of CODE
	mov	cl,4
	shr	ax,cl			; make it paras
	mov	dx,0ffffh
	mov	es,dx			; ES:DI -> destination of CODE
	mov	dx,di
	mov	cl,4
	shr	dx,cl			; DX = offset from FFFF in para's
	dec	dx			; DX = offset from 10000
	sub	dx,ax			; DX = fixup segment
	pop	cx			; CX = bytes to move
	clc				; made it!
	ret

AllocHMA20:
	mov	di,0FFFFh		; set ES:DI = FFFF:FFFF
	mov	es,di
	stc				; can't do it
	ret

	Public	SetupHMA

SetupHMA:
;--------
; We have a client for the high memory area at segment FFFF
; We should try and setup a high memory free chain
; XMS only supports allocation of the complete area, so try and grab
;  it all and do our own sub-allocations within it.
;
	push	es
	les	bx,cs:drdos_ptr
	cmp	es:DRDOS_HIMEM_ROOT[bx],0; do we already have a chain ?
	 jnz	SetupHMA10		;  if so skip XMS allocation
	mov	ax,4300h		; check for XMS installation
	int	2fh
	cmp	al,80h
	 jne	SetupHMA20
	mov	ax,4310h		; get address of XMS driver
	int	2fh
	mov	word ptr xms_driver,bx
	mov	word ptr xms_driver+2,es
	xor	ah,ah			; version number check
	call	dword ptr xms_driver
	cmp	dx,1			; does HiMem exist ?
	 jne	SetupHMA20
	mov	ah,1			; allocate whole HiMem
	mov	dx,0ffffh
	call	dword ptr xms_driver
	cmp	ax,1			; did we succeed ?
	 jne	SetupHMA20
	mov	ah,3			; enable a20 gate
	call	dword ptr xms_driver
	cmp	ax,1			; did we succeed ?
	 jne	SetupHMA20
	les	bx,cs:drdos_ptr
	mov	es:DRDOS_HIMEM_ROOT[bx],COMMAND_BASE
	mov	ax,0FFFFh		; one entry of FFF0 bytes covers
	mov	es,ax			;  the complete HMA
	inc	ax
	mov	es:word ptr COMMAND_BASE,ax
	mov	es:word ptr COMMAND_BASE+2,-COMMAND_BASE
	mov	di,10h			; copy a dummy VDISK header
	mov	si,offset dummyVDISK
	mov	cx,10h
	rep	movsw			; copy up 0x20 bytes
	push	ds			; now fixup JMPF in hi-memory for CALL5
	mov	ds,ax			;  link for PC-NFS
	mov	si,4*30h		; DS:SI -> Int 30 vector
	lea	di,10h[si]		; ES:DI -> himem alias
	movsw
	movsw
	movsb				; copy the JMPF
	pop	ds
SetupHMA10:
	les	bx,cs:drdos_ptr		; private data area in ES:BX
	mov	dx,COMMAND_BASE
	cmp	dx,es:DRDOS_HIMEM_ROOT[bx]
	 jne	SetupHMA20		; should we be reserving space for OS?
	mov	cx,systemSize		; we should reserve this much
	call	ReserveHMA		;  for the OS in the HMA
	 jc	SetupHMA20
	mov	systemHMA,ax		; save for re-use
SetupHMA20:
	pop	es
	ret


	Public	alloc_instseg

alloc_instseg:
; allocate AX paragraphs for data that will have to be instanced during
; multitasking. if Vladivar kernel available ask that, or else just
; try for normal upper memory
	push	ax
	push	bx			; save registers
	push	cx
	mov	cx,F_Version		; is the multi-tasker loaded ?
	mov	ax,OS386_FUNC
	int	OS386_INT
	int	2Fh			; check for Vladivar
	test	cx,cx			; CX=0 if it's there
	pop	cx
	pop	bx
	pop	ax
	 jnz	alloc_instseg20		; no, allocate normally
	push	ax
	push	bx
	push	cx
	push	dx
	mov	dx,ax			; DX = paragraphs required
	mov	cx,F_RealAllocI		; ask nicely for memory
	mov	ax,OS386_FUNC
	int	OS386_INT
	pop	dx
	pop	cx
	pop	bx
	 jc	alloc_instseg10		; did we get any ?
	add	sp,WORD
	xor	di,di
	clc				; we've done it !!
	ret	

alloc_instseg10:
	pop	ax			; we didn't manage it...
;	jmp	alloc_hiseg

alloc_instseg20:
	push	bx
	test	dh,ALLOC_IN_HMA
	 jz	alloc_instseg30
	push	es
	push	ax
	mov	cl,4			; convert paragraphs to bytes
	shl	ax,cl
	push	ax
	call	SetupHMA		; make sure HMA chain is established
	pop cx				; CX = bytes wanted
	mov	dx,0FFFFh		; anywhere is OK
	call	AllocHMA		; ES:DI -> allocated data
	pop	ax
	 jc	alloc_instseg25
	mov	ax,es
	pop	es
	jmp	short alloc_instseg55
alloc_instseg25:
	pop	es
alloc_instseg30:
	test	dh,ALLOC_IN_UMB
	 jz	alloc_instseg40		; allocation from UMB's OK ?
	call	alloc_upper		; yes, try and allocate memory there
	 jnc	alloc_instseg50
alloc_instseg40:
	call	alloc_seg		; allocate memory in bottom 640 K
alloc_instseg50:
	xor	di,di
alloc_instseg55:
	pop	bx
	ret

	Public	alloc_hiseg
alloc_hiseg:
; allocate AX paragraphs in high memory if possible, otherwise allocate
; it in conventional memory
	cmp	hidos,0			; do we want to relocate DOS ?
	 je	alloc_seg		;  no, allocate conventionally
	call	alloc_upper		; try to allocate some upper memory
	 jc	alloc_seg		;  can't, so allocate conventional
	ret				;  else return address of allocated mem

alloc_seg_with_padding:
; On Entry:
;	AX = para's required
;	DX = minimum acceptable offset
; On Exit:
;	AX = base para
;
; If gate A20 is enabled we can't use negative offset's for DOS/BIOS so
; we pad conventional memory to avoid this. Avoid seg=0 while here.
	push	cx
	push	dx
	add	dx,15+16		; DX is the offset we will be using
	mov	cl,4			;  so make sure base is high enough
	shr	dx,cl			; convert "offset" to a segment value
	cmp	dx,mem_current		;  make sure we don't generate a
	 jbe	alloc_seg_nopad		;  negative segement value as this
	mov	mem_current,dx		;  will crash if a20 enabled
alloc_seg_nopad:			; pad if necessary
	mov	dl,'M'			; allocate for DOS
	call	alloc_seg		; now we can allocate OK
	pop	dx
	pop	cx
	ret

	Public	alloc_seg
alloc_seg:
;---------
; On Entry:
;	AX = para's required
;	DL = subsegment type
; On Exit:
;	AX = base para
;
	push	ds
	push	cx
	mov	cx,ax			; remember how much was wanted
	inc	ax			; allow an extra para for a header
	add	ax,mem_current		; Return a pointer to AX paragraphs
	cmp	ax,mem_max		; of memory to the calling routine.
	 jae	alloc_s10
	xchg	ax,mem_current
	mov	ds,ax			; DS:0 -> header
	inc	ax			; AX:0 -> buffer
	mov	ds:DMD_ID,dl		; remember the type
	mov	ds:DMD_PSP,ax		; owner = itself
	mov	ds:DMD_LEN,cx		; size in para
	xor	cx,cx			; zero rest for cosmetic reasons
	mov	ds:word ptr DMD_NAME-3,cx
	mov	ds:word ptr DMD_NAME-2,cx
	mov	ds:word ptr DMD_NAME,'S'+256*'D'
	mov	ds:word ptr DMD_NAME+2,cx
	mov	ds:word ptr DMD_NAME+4,cx
	mov	ds:word ptr DMD_NAME+6,cx
	pop	cx
	pop	ds
	ret

alloc_s10:
	hlt				; ##jc##
	jmp	short alloc_s10

	Public	alloc_upper
alloc_upper:
;-----------
; On Entry:
;	AX = paragraphs required
; On Exit:
;	CY clear: 	AX = paragraphs address of allocated memory
;	CY set:		cannot allocate memory (All regs preserved)
;
	push	bx
	push	ax			; save para required
	cmp	himem_base,0		; we have already allocated some ?
	 je	alloc_upper10		; nothing to grow, allocate new block
	mov	bx,himem_size		; himem was this big
	add	bx,ax			; try and extend it
	push	es
	mov	es,himem_base		; point at existing himem
	mov	ah,MS_M_SETBLOCK	; and try and set to new size
	int	DOS_INT
	pop	es
	 jc	alloc_upper10		; can't grow, so allocate new block
	mov	ax,himem_base
	add	ax,himem_size		; return seg above old alloc
	pop	bx			; recover para required
	add	himem_size,bx		; add into himem size
	pop	bx
	clc				; success..
	ret				; return AX = seg

alloc_upper10:
	mov	ax,(MS_M_STRATEGY*256)+1; set allocation strategy
	mov	bl,41h			;  to best fit, high only
	int	DOS_INT
	pop 	bx
	push 	bx			; recover para required in BX
	mov	ah, MS_M_ALLOC		;  and try to allocate them
	int	DOS_INT
	pushf
	push 	ax			; save CF and possible address
	mov	ax,(MS_M_STRATEGY*256)+1; set allocation strategy
	xor	bl,bl			;  to first fit
	int	DOS_INT
	pop ax
	popf				; restore CF and possible address
	 jc	alloc_upper20		; can't allocate, use conventional
	cmp	ax,mem_size		; is it from upper memory ?
	 ja	alloc_upper15		; yes, we can use it
	push	es			; it's conventional, free it up
	mov	es,ax			;  seg address in ES
	mov	ah,MS_M_FREE
	int	DOS_INT			; free up this memory
	pop	es
	jmp	short alloc_upper20	; try again with XMS

alloc_upper15:
	mov	himem_base,ax		; save base value
	pop	himem_size		; save size
	pop	bx			; and return seg in AX
	clc				; success..
	ret

alloc_upper20:
	pop	ax
	pop	bx			; restore regs
	push 	ds
	push 	es
	push 	bx
	push 	cx
	push 	dx
	push 	si
	push 	di
	push 	bp
	push	ax			; save allocation size
	mov	ax,4300h		; check for XMS installation
	int	2fh
	cmp	al,80h
	 jne	alloc_upper30
	mov	ax,4310h		; get address of XMS driver
	int	2fh
	mov	word ptr xms_driver,bx
	mov	word ptr xms_driver+2,es
	pop dx
	push dx		; DX = allocation size
	mov	ah,10h			; allocate upper memory block
	call	dword ptr xms_driver
	cmp	ax,1			; did we succeed ?
	 jne	alloc_upper30
	pop	ax			; recover allocation size
	mov	ax,bx			; return para address of himem
	pop 	bp
	pop 	di
	pop 	si
	pop 	dx
	pop 	cx
	pop 	bx
	pop 	es
	pop 	ds
	clc				; success
	ret
	
alloc_upper30:
	pop	ax			; recover allocation size
	pop 	bp
	pop 	di
	pop 	si
	pop 	dx
	pop 	cx
	pop 	bx
	pop 	es
	pop 	ds
	stc				; failure....
	ret


mark_system_memory:
;------------------
; ensure any memory we have allocated is owned by PSP 0008, a magic value
;  used to indicate system memory
	push	es
	les	bx,func52_ptr		; get internal data in ES:BX
	mov	es,es:F52_DMDROOT[bx]	; get 1st DMD entry
	mov	ah,MS_P_GETPSP
	int	DOS_INT			; get our PSP in BX
mark_sm10:
	cmp	es:DMD_ID,'M'
	 je	mark_sm20		; check we have a valid DMD
	cmp	es:DMD_ID,'Z'
	 jne	mark_sm50		; stop if we don't
mark_sm20:
	cmp	bx,es:DMD_PSP		; is it ours ??
	 jne	mark_sm30
	mov	es:DMD_PSP,0008		; mark as system
mark_sm30:
	cmp	es:DMD_PSP,0008		; if system mark as SC
	 jne	mark_sm40
	xor	ax,ax			; zero rest for cosmetic reasons
	mov	es:word ptr DMD_NAME-3,ax
	mov	es:word ptr DMD_NAME-2,ax
	mov	es:word ptr DMD_NAME,'S'+256*'C'
	mov	es:word ptr DMD_NAME+2,ax
	mov	es:word ptr DMD_NAME+4,ax
	mov	es:word ptr DMD_NAME+6,ax
mark_sm40:
	cmp	es:DMD_ID,'Z'		; is it the last DMD ?
	 je	mark_sm50		;  then stop
	mov	ax,es
	inc	ax			; skip DMD header and add
	add	ax,es:DMD_LEN		;  length to find next DMD
	mov	es,ax
	jmp	short mark_sm10		; now go and look at that
mark_sm50:
	pop	es
	ret

; Relocate the BIOS code from top of memory
reloc_bios:
	mov	dx,rcode_offset
	mov	cx,rcode_len		; we need to relocate this much
	test	cx,cx			; do we need to move anything ?
	 jnz	reloc_bios10
	ret
reloc_bios10:
	add	cx,15			; round rcode size up to a para
	and	cx,0FFF0h
	mov	ax,bios_target_seg	; where do we go
	test	ax,ax
	 jz	reloc_bios20		; zero - do it ourselves
	inc	ax			; FFFF - unlikely as it's not
	 jz	reloc_bios25		;  currently supported
	dec	ax			; else we've been given a seg
	jmp	short reloc_bios40
reloc_bios20:	
	cmp	dos_target_seg,0FFFFh	; if DOS goes up, so does BIOS
	 jne	reloc_bios30
reloc_bios25:
	call	AllocHMA		;  in HIGH memory
	 jnc	reloc_bios50
reloc_bios30:
	mov	ax,cx			; allocate conventionally
	shr 	ax,1
	shr 	ax,1			;  in para's of course
	shr 	ax,1
	shr 	ax,1
	cmp	hidos,0			; do we want to relocate DOS ?
	 je	reloc_bios35		;  no, allocate conventionally
	call	alloc_upper		; try to allocate some upper memory
	 jnc	reloc_bios40		;  can't, so allocate conventional
reloc_bios35:				;  padding out if required
	call	alloc_seg_with_padding
reloc_bios40:
	mov	es,ax
	xor	di,di			; ES:DI -> destination
	shr 	dx,1
	shr 	dx,1			; convert offset to para's
	shr 	dx,1
	shr 	dx,1
	sub	ax,dx			; bias segment appropriately
	xchg	ax,dx			;  and have in DX
reloc_bios50:
	push	es
	push	cx
	push	di

	push	ds
	mov	si,rcode_offset
	mov	ds,rcode_seg
	rep	movsb
	pop	ds
	mov	rcode_seg,dx		; new RCODE location

	call	dd_fixup		; fixup any device drivers

	pop	di
	pop	cx
	pop	es
	ret


;
; The following code performs the fixups necessary for RELOCATABLE executable
; internal device drivers.

dd_fixup:
; On Entry:
;	None
; On Exit:
;	None

	push	es
	mov	di,rcode_seg		; fixup to this segment
	mov	si,rcode_fixups		; get fixup table
	test	si,si			; is there one ?
	 jz	dd_fixup20
	mov	es,bios_seg
dd_fixup10:
	lodsw				; get a fixup offset
	test	ax,ax			; last of the fixups ?
	 jz	dd_fixup20
	xchg	ax,di			; point to the fixup
	stosw				; do the fixup
	xchg	ax,di			; save segment again
	jmp	short dd_fixup10
dd_fixup20:
	pop	es
	ret


ReserveOSHMA:
;------------
; reserve space in HMA for OS
; On Entry:
;	None
; On Exit:
;	None
;

ReserveCommandHMA:
;----------------
; reserve space in HMA for COMMAND.COM
; On Entry:
;	None
; On Exit:
;	None
;
	cmp	commandHMA,0		; been here already ??
	 jne	ReserveCommandHMA10
	mov	cx,COMMAND_SIZE
	mov	dx,COMMAND_BASE
	call	ReserveHMA		; reserve the space in HMA
	 jc	ReserveCommandHMA10	;  if we can
	mov	commandHMA,ax		; save for re-use
ReserveCommandHMA10:
	ret

ReserveHMA:
;----------
; reserve some space in the HMA
; On Entry:
;	CX = size require
;	DX = maximum offset acceptable
; On Exit:
;	AX = offset of reserved space
;
	push	es
	call	AllocHMA		; allocate space in HIGH memory
	 jc	ReserveHMA10
	mov	es:word ptr [di],0	; no link, it's this big
	mov	es:word ptr 2[di],cx
	mov	bx,es
	mov	ax,0FFFFh
	sub	ax,bx			; AX = para offset adjustment required
	mov	cl,4
	shl	ax,cl			; convert to byte offset
	add	ax,di			; AX = offset from FFFF:0
ReserveHMA10:
	pop	es
	ret


FreeHMA:
;-------
; Return reserved HMA space to pool
; On Entry:
;	CX = offset of HMA block to relink (0 = noblock)
; On Exit:
;	None
;
	 jcxz	free_himem10		; no block, don't recycle
	push	es
	push	cx			; save offset
	les	bx,cs:drdos_ptr
	pop	ax			; recover offset
	mov	di,ax			; remember offset for later
	xchg	ax,es:DRDOS_HIMEM_ROOT[bx]; become new head of HMA
	mov	bx,0FFFFh
	mov	es,bx			; point ES:DI at our section
	stosw				;  chain on rest of HMA
	pop	es
free_himem10:
	ret


rploader:
;--------
; On Entry:
;	DX = phase code
; On Exit:
;	None, All regs preserved
	push	es
	push	ax
	push	bx
	push	cx
	push	dx
	mov	ax,rpl_off		; do we have an RPL sitting on
	or	ax,rpl_seg		;  Int 13h
	 jz	rploader10
	mov	ax,12ffh		; magic cleanup call to RPL
	mov	bx,5			;  to do any tidy ups it wishes
	xor	cx,cx			;  following resident BIOS
	mov	dx,1			;  initialisation
	pushf
	cli
	call	dword ptr rpl_entry	; fake an INT
rploader10:
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	es
	ret

	Public	Verify386

Verify386:
;---------
; On Entry:
;	None
; On Exit:
;	CY clear if 386 or above
;
	push	sp			; really old CPU's inc SP
	pop	ax			;  before pushing
	cmp	ax,sp			; newer ones push original SP
	 jne	Verify386fail
	mov	ax,3000h		; now try to set IOPL = 3
    	push    ax
	popf
	pushf
	pop	bx
	and	ax,bx			; any IOPL bits set ?
	 jz	Verify386fail
;	clc				; it's at least a 386
	ret
Verify386fail:
	stc				; it's not a 386
	ret

; append COMSPEC to config environment
add_comspec_to_env proc
	push	es
	push	bx
	push	ds
	pop	es
	cmp	comspec_env_offset,-1	; COMSPEC= already present in env?
	 je	@@search		; if not, search env end
	mov	di,comspec_env_offset
	add	di,8			; skip COMSPEC=
	jmp	@@copy_shell		; COMSPEC= already there, update only filename
@@search:				
	mov	di,offset envstart	; search end of environment
	cmp	byte ptr [di],0		; special case: environment empty?
	 je	@@copy_comspec		; then skip right to setting COMSPEC
	dec	di
@@search_next:
	inc	di
	cmp	word ptr [di],0
	 jne	@@search_next
	inc	di			; DI points to free part of env
@@copy_comspec:
	mov	comspec_env_offset,di	; remember comspec offset
	cmp	di,offset envend - 8
	jae	@@err			; not much room enough to copy COMSPEC=
	mov	si,offset comspec
	movsw
	movsw
	movsw
	movsw
@@copy_shell:
	mov	si,offset shell
@@copy_next:
	cmp	di,offset envend
	 jae	@@err			; environment full!!!
	lodsb				; copy single filename char
	stosb
	test	al,al
	 jnz	@@copy_next
	stosb				; append second zero
	jmp	@@ret
@@err:	mov	di,comspec_env_offset	; revert appending of comspec
	mov	word ptr [di],0		; terminate env with double zero
	mov	comspec_env_offset,-1	; set comspec not appended
@@ret:	pop	bx
	pop	es
	ret
add_comspec_to_env endp

copy_config_env_to_seg60 proc
	push	es
	mov	ax,60h
	mov	es,ax
	mov	si,offset envstart
	xor	di,di
	mov	cx,80h
	rep	movsw
	les	bx,drdos_ptr
	mov	es:DRDOS_ENVSEG[bx],ax	; tell COMMAND.COM where we are
	pop	es
	ret
copy_config_env_to_seg60 endp

INITCODE ends

INITDATA	segment public word 'INITDATA'


include	initmsgs.def				; Include TFT Header File


	extrn	history_flg:byte
	extrn	next_drv:byte
	extrn	dev_count:byte
	extrn	lastdrvIn:byte
	extrn	configPass:byte
	extrn	cfg_head:word
	extrn	cfg_tail:word
	extrn	cfg_seeklo:word
	extrn	cfg_seekhi:word
	extrn	boot_options:word
	extrn	boot_switches:byte
	extrn	envstart:near
	extrn	envend:near

;
;	PUBLIC Variables which are initialised by the BIOS before the
;	BIOSINIT code has been executed. 
;
data_start	label byte		; used to para-align PSP & ENV

	Public	func52_ptr
func52_ptr	label dword		; address of internal BDOS variables
func52_off	dw	0		; offset	"	"	"
func52_seg	dw	0		; segment	"	"	"

	Public	drdos_ptr
drdos_ptr	label dword		; address of internal BDOS variables
drdos_off	dw	0		; offset	"	"	"
drdos_seg	dw	0		; segment	"	"	"


	Public	res_ddsc_ptr
res_ddsc_ptr	label dword
res_ddsc_off	dw	0
	Public	res_ddsc_seg
res_ddsc_seg	dw	0

	Public	rcode_offset, rcode_seg, icode_len, rcode_len, rcode_fixups

rcode_offset	dw	0		; current offset of relocated code
rcode_seg	dw	0		; current segment of relocated code
icode_len	dw	0		; initial size of relocated code
rcode_len	dw	0		; final size of relocated code
rcode_fixups	dw	0		; offset of rcode fixup table

	Public	current_dos
current_dos	dw	0		; Current Segment Address of DOS Code

	Public	dos_target_seg, bios_target_seg
dos_target_seg	dw	0		; target address for DOS relocation
bios_target_seg	dw	0		; 0000 - auto-relocate
					; FFFF - high memory (not allocated)
					; xxxx - driver allocated address

dosCodeParaSize	dw	0		; Size of DOS code in para's

systemSize	dw	COMMAND_SIZE	; BIOS+DOS code sizes are added to
					;  give total size to reserve in HMA

systemHMA	dw	0		; offset of area in HMA reserved 
					;  for SYSTEM (BIOS/DOS/COMMAND)
commandHMA	dw	0		; offset of area in HMA reserved 
					;  for COMMAND.COM


	Public	device_root
device_root	dd	0		; Root of Resident Device driver Chain

	Public	mem_size, ext_mem_size, comspec_drv
	Public	init_flags, init_drv, init_int13_unit

mem_size	dw	0		; Total Memory Size (in Paragraphs)
ext_mem_size	dw	0		; Total Extended Memory Size (in KB.)
init_flags	dw	0		; BIOS INIT Flags
init_drv	db	0		; Boot Drive (A is 0 .....)
init_int13_unit	db	0
comspec_drv	db	0		; Default COMSPEC Drive

	Public	num_stacks, stack_size

num_stacks	dw	DEF_NUM_STACKS
stack_size	dw	DEF_SIZE_STACK

	Public	num_files, num_fcbs, num_fopen
	Public	country_code, code_page
	
num_files	dw	DEF_NUM_FILES	; # of file handles
num_fcbs	dw	DEF_NUM_FCBS	; # of fcb file handles
num_fopen	dw	-1		; "unset" value for fast open
country_code	dw	DEF_COUNTRY	; Country Code 
code_page	dw	DEF_CODEPAGE	; Code Page

	Public	dos_name
dos_name	db	'DRDOS   SYS',0	; default DOS filename

rpl_name	db	'RPLOADER'

rpl_entry	label dword		; remember RPL entry point for
rpl_off		dw	0		;  startup broadcasts
rpl_seg		dw	0

;
;	Internal variables used by the BIOSINIT code
;
	Public	bios_seg
bios		label dword		; Far pointer to the BIOS Cleanup
bios_offset	dw	0		; routines.
bios_seg	dw	0

	Public	init_dseg
init_dseg	dw	0		; Init data segment

	Public	dos_dseg
dos_dseg	dw	0		; DOS Data Segment Address

	Public	mem_current_base, mem_current, mem_max
mem_first_base	dw	0		; Base of First Allocated Memory
mem_current_base dw	0		; Base of Current Allocated Memory
mem_current	dw	0		; Next Free Paragraph
mem_max		dw	0		; Last available Paragraph


dos_init	label dword		; DOS Initialization Code
dos_coff	dw	0		; DOS Init Code Offset
dos_cseg	dw	0		; DOS Init Code Segment

free_seg	dw	0		; First available paragraph.

xms_driver	dd	0		; address of himem driver

	Public	hidos
hidos		db	0		; set true if HIDOS requested
himem_base	dw	0		; base of HIMEM seg allocations
himem_size	dw	0		; length of HIMEM seg allocations

	Public	hidosdata
hidosdata	db	0
	Public	hiddscs
hiddscs		db	0
	Public	hixbda
hixbda		db	0

	Public	last_drv

last_drv	db	5		; default is "E:"

console		db	'CON',0		; Default Console Device
printer		db	'PRN',0		; Default Printer Device
auxilary	db	'AUX',0		; Default Auxilary Device

idle_dev	db	'$IDLE$',0	; Idle Device Name
idle_off	dw	0		; Idle Data Area Offset
idle_seg	dw	0		; Idle Data Area Segment

dummy_fcb	db	0,'           '

exec_env	dw	0		; Environment Segment
exec_cloff	dw	shell_cline	; Command Line Offset
exec_clseg	dw	0		; Command Line Segment
		dw	dummy_fcb
exec_fcb1seg	dw	0		; FCB 1 Offset and Segment
		dw	dummy_fcb
exec_fcb2seg	dw	0		; FCB 2 Offset and Segment
		dd	0		; SS:SP
		dd	0		; CS:IP

	Public	shell_cline
shell_cline	db	0		; Initial Command Line
shell_drv	db	0Dh
		db	126 dup (0)

dummyVDISK	db	0, 0, 0		; jump instruction
		db	'VDISK3.3'	; OEM name
		dw	128		; bytes per sector
		db	1		; sectors per allocation unit
		dw	1		; number of reserved sectors
		db	1		; number of FATs
		dw	40		; number of root directory entries
		dw	512		; total number of sectors
		db	0FEh		; media descriptor byte
		dw	6		; sectors per FAT
		dw	8		; sectors per track
		dw	1		; number of heads
		dw	0		; number of hidden sectors
		dw	1024+64		; KB of extended memory used

search_state	db	43 dup (0)	; Search First/Next State

even
		dw	384 dup (0)	; big stack for ASPI4DOS.SYS driver
stack		label word

res_dev_count	db	0
dosdata_len	dw	0
int_stubs_seg	dw	0

	Public	part_off
part_off	dw	0,0			; offset of boot partition

INITDATA ends

INITPSP		segment public para 'INITDATA'
		db	'Z'			; dummy DMD header
		dw	0008h			; owner is system
		dw	0010h			; length of PSP
		db	3 dup (0)		; pad to 8 bytes
		db	'DOS',0,0,0,0,0		; name field (must be 8 bytes)
psp		db	16h dup (0)		; Zero Fill PSP Header
parent_psp	dw	0			; parent, patched to itself
		db	0FFh, 0FFh, 0FFh	; STDIN, STDOUT, STDERR
		db	0FFh, 0FFh		; STDAUX, STDPRN
		db	0FFh, 0FFh, 0FFh	; Remainder CLOSED
		db	0FFh, 0FFh, 0FFh
		db	0FFh, 0FFh, 0FFh
		db	0FFh, 0FFh, 0FFh
		db	0FFh, 0FFh, 0FFh
		dw	0000			  ; PSP Environment Pointer
		dw	0000, 0000		  ; DOS User SS:SP
		dw	20			  ; Maximum of 20 Handles
		dw	offset PSP_XFT		  ; Handle Table Offset
xftbl_seg	dw	0			  ; Handle Table Segment
		db	(offset PSP_VERSION - offset PSP_RES1) dup (0)
	Public	dosVersion
dosVersion	dw	7			  ; DOS version is 7.0
		db	(PSPILEN - offset PSP_VERSION - 2) dup (0)
						  ; PAD to Partial PSP Size
INITPSP ends

INITENV		segment public para 'INITDATA'

shell_ask	db	79			; max len
shell_end	db	0			; end of the line
	Public	shell
shell		db	'A:\COMMAND.COM', 0	
		db	(80-lengthof shell) dup (0)
comspec		db	'COMSPEC='
comspec_env_offset	dw -1			; comspec offset of environment

INITENV ends

DATAEND	segment public para 'INITDATA'

	Public	biosinit_end
biosinit_end	label byte
DATAEND ends

	end
