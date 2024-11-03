;    File              : $GENERCFG.ASM$
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
;    GENERCFG.A86 1.51 93/12/02 00:15:06
;    When auto-sizing DEVICEHIGH requirements use EXE header info if present
;    GENERCFG.A86 1.49 93/11/29 14:10:29
;    Add NUMLOCK=ON/OFF support
;    GENERCFG.A86 1.48 93/11/28 15:32:22
;    Support HIBUFFERS in UMB's
;    GENERCFG.A86 1.47 93/11/22 15:45:11
;    Ignore [COMMON] statements
;    GENERCFG.A86 1.46 93/11/18 16:20:16
;    Add primitive multi-master checking
;    GENERCFG.A86 1.45 93/11/17 20:07:17
;    change history defaults
;    GENERCFG.A86 1.44 93/11/16 14:10:21
;    F5 has precedence over ?
;    GENERCFG.A86 1.42 93/11/08 17:37:06
;    Move INSTALLHIGH to before INSTALL, so it's now recognised
;    GENERCFG.A86 1.41 93/11/04 16:28:08
;    Cosmetic change - the preload name field now strips off "C:\" properly
;    GENERCFG.A86 1.40 93/11/03 22:52:14
;    Replace chardev test with one for zero units
;    GENERCFG.A86 1.39 93/11/03 18:21:16
;    disable CHARDEV test until it gets fixed
;    GENERCFG.A86 1.38 93/11/03 17:11:05
;    Preloaded compression drivers maybe loaded from C: when booting
;    from a diskette.    
;    GENERCFG.A86 1.37 93/10/29 19:42:51
;    DOS=UMB turns HIDOS on
;    GENERCFG.A86 1.36 93/09/28 19:54:52
;    Support "DEVICE?=" syntax, and "SWITCHES=/N"
;    GENERCFG.A86 1.35 93/09/02 22:35:16 
;    Add header to system allocations
;    GENERCFG.A86 1.32 93/08/02 14:46:21
;    hide preload drives from func_device
;    support INSTALLHIGH
;    GENERCFG.A86 1.30 93/07/29 14:47:15
;    Change SETVER method
;    GENERCFG.A86 1.28 93/07/20 22:32:07
;    default upper memory link = FFFF
;    ENDLOG


	include config.equ
	include	msdos.equ
	include char.def
	include	request.equ
	include	driver.equ
	include	fdos.equ
	include	f52data.def		; Function 52 DOS Data Area
	include	doshndl.def		; DOS Handle Structure Definition
	include country.def

ADDDRV = 0

TRUE	   	equ	0FFFFh		; value of TRUE
FALSE	   	equ	0		; value of FALSE

;F5KEY		equ	3F00h		; keys returned by BIOS
;F8KEY		equ	4200h		;  in boot_options

SWITCH_F	equ	01h		; in boot_switches
SWITCH_N	equ	02h

SWITCH_MAX	equ	10		; maximum number of SWITCH commands

CFG_NAME	equ	word ptr 0000h		; Command Name
CFG_FUNC	equ	word ptr 0002h		; Command Subroutine
CFG_FLAGS	equ	word ptr 0004h		; Command flags
CFG_SIZE	equ	6			; Size of each Entry

CF_LAST		equ	0003h		; execute in last config pass
CF_NOF		equ	0008h		; set if F5/F8 should be ignored
CF_LC		equ	0010h		; set if case should be preserved
CF_QUERY	equ	0020h		; set at run time eg. "DEVICE?"
CF_ALL		equ	0040h		; execute in all config passes

CGROUP		group	INITCODE, INITDATA, INITENV
ASSUME CS:CGROUP,DS:CGROUP

INITCODE	segment public byte 'INITCODE'

	extrn	whitespace:near
	extrn	build_cmd_tail:near
	extrn	device_init:near
	extrn	init_static_request:near
	extrn	block_device:near
	extrn	device_insert:near
if not ADDDRV
	extrn	nls_hook:near
	extrn	nls_unhook:near
endif

CONFIG_ERRLVL	equ	400h		; special 'CONFIG' error level

; config_process returns CF set if an error occurred during command file
; processing for ADDDRV.EXE

	Public config_process
config_process:		; Process CONFIG.SYS

	mov	save_sp,sp		; save SP for unstructured GOSUB's

if ADDDRV
	mov	error_flag,0
else
	mov	ax,offset envstart	; env buffer is para aligned
	mov	cl,4
	shr	ax,cl			; convert offset to paras
	mov	cx,ds
	add	ax,cx			; segment of env variables
	les	bx,drdos_ptr
	mov	es:DRDOS_ENVSEG[bx],ax	; tell COMMAND.COM where we are
	push 	ds
	pop 	es
endif

	mov	ah,MS_DRV_GET		; check whether we are loading from
	int	DOS_INT			;   drive C:
	cmp	al,2
	 je	preload_security
	push	ds
	mov	ah,32h			; get DOS parameter block
	mov	dl,3			; ensure drive C: is valid (no critical
	int	DOS_INT			;  errors)
	pop	ds
	cmp	al,0ffh			; skip if the drive is not valid
	 je	preload_stacker
	mov	alt_drive,1		; drive C: should be used also
	jmp	preload_stacker

preload_security:
	call	preload_device		; preload the SECURITY device driver

preload_stacker:
	mov	preload_file,offset stacker_file+2
	call	preload_device		; preload STACKER from default drive
	 jnc	preload_done

	mov	preload_file,offset dblspace_file+2
	call	preload_device		; STACKER failed, try DBLSPACE from default
	 jnc	preload_done

	cmp	alt_drive,0		; STACKER and DBLSPACE failed on A:,
	 je	preload_done		;   should we look on drive C:?

	mov	preload_file,offset stacker_file
	call	preload_device		; preload STACKER from drive C:
	 jnc	preload_done

	mov	preload_file,offset dblspace_file
	call	preload_device		; STACKER failed, try DBLSPACE from C:

	Public	preload_done
preload_done:
	mov	ax,(MS_X_OPEN*256)+80h	; Open the configuration file
	mov	dx,offset cfg_file	; Try Opening the file DCONFIG.SYS
	int	DOS_INT			; if this fails then open CONFIG.SYS
	 jnc	cfg_20			; Found DCONFIG.SYS

if ADDDRV
	mov	si,dx
	mov	dx,offset err_no_command_file
	xor	al,al
	call	config_error
	jmp	short cfg_exit
else
	mov	si,offset cfg_file+1
	mov	di,offset cfg_file
	call	copy_asciiz		; make DCONFIG.SYS = CONFIG.SYS
	
	mov	ax,(MS_X_OPEN*256)+80h	; Open the configuration file
	int	DOS_INT			; CONFIG.SYS
	 jc	cfg_exit		; Return on error without complaint
endif

cfg_20:
	mov	bx,ax			; get the CONFIG handle
	mov	ah,MS_X_CLOSE		; Close the CONFIG file
	int	DOS_INT

cfg_nextline:				; Read the next command line
	call	readline		; If Carry then Terminal Error
	 jc	cfg_exit		;  so Exit
	mov	ax,boot_options
cfg_continue:
	push	ax			; save query options
	call	scan			; Now Scan the command List 
	pop	ax			; recover query options
	 jc	cfg_error		; for a matching command name
	call	cfg_query		; prompt to see if we want it
	 jc	cfg_nextline
	call	CFG_FUNC[di]		; Execute the request command
	jmp	short cfg_nextline	; and loop till the end of the file

cfg_error:
	mov	dx,offset bad_command	; Display a Bad command error msg
	mov	al,CR			; and the CR terminated string
	call	config_error		; then continue processing
	jmp	short cfg_nextline	; Carry Returned On Error

cfg_exit:
	mov	sp,save_sp		; get back the real stack
	call	preload_complete	; move transcient code to final position
if ADDDRV
	cmp	error_flag,1		;Set CF if error flag is zero
	cmc				;Set CF if error flag is 1
endif
	ret


cfg_query:
; On Entry:
;	AX = boot_options key
;	SI -> command tail
;	DI -> CFG_
; On Exit:
;	CY set if we should skip command
;	SI/DI preserved
;
	push	si
	push	di
	mov	dx,CFG_FLAGS[di]	; flags for this config command
	cmp	configpass,0		; CF_ALL does not include pass 0
	 je	cfg_query05		; so skip the test in this pass
	test	dx,CF_ALL		; present in all phases?
	 jnz	cfg_query06		; yes, then execute it
cfg_query05:
	and	dl,CF_NOF-1		; config pass to execute in
	cmp	dl,configpass		; does the phase number match?
	 je	cfg_query06		; yes
	stc
	jmp	cfg_query90		; else skip the command

cfg_query06:
	test	CFG_FLAGS[di],CF_NOF	; are Function Keys allowed ?
;	clc				; if not process the command
	 jz 	cfg_query06a
	 jmp 	cfg_query90
cfg_query06a:
	cmp	ax,F5KEY		; F5 bypasses CONFIG processing
	stc				;  so bypass this line
;	 je	cfg_query90
	 jne	cfg_query07
	jmp	cfg_query90
cfg_query07:
	test	CFG_FLAGS[di],CF_QUERY	; specific QUERY request ?
	 jnz	cfg_query10
	cmp	ax,F8KEY		; should we prompt for everything ?
	clc				; if not process the command
;	 jne	cfg_query90
	 je	cfg_query10
	jmp	cfg_query90
cfg_query10:
	push	si
	mov	si,CFG_NAME[di]		; DS:SI -> command name we matched
cfg_query20:
	lodsb				; get character
	test	al,al			; zero terminated
	 jz	cfg_query30
	xchg	ax,dx			; DL= character
	mov	ah,MS_C_WRITE
	int	DOS_INT			; output the character
	jmp	short cfg_query20	; "DEVICE"
cfg_query30:
	mov	dl,'='
	mov	ah,MS_C_WRITE
	int	DOS_INT			; "DEVICE="
	pop	si			; rest of command line
cfg_query40:
	lodsb
	cmp	al,CR			; is it the end of the line ?
	 je	cfg_query50		;  no, do another character
	xchg	ax,dx			; DL= character
	mov	ah,MS_C_WRITE
	int	DOS_INT			; output the character
	jmp	short cfg_query40	; "DEVICE=FILENAME.SYS"
cfg_query50:
	mov	ah,MS_C_WRITESTR	; Output msg of form " (Y/N) ? "
	mov	dx,offset confirm_msg1
	int	DOS_INT			; do " ("
	mov	ah,MS_C_WRITE
	mov	dl,yes_char
	int	DOS_INT			; do "Y"
	mov	dl,','
	int	DOS_INT			; do ","
	mov	dl,no_char
	int	DOS_INT			; do "N"
	mov	dl,','
	int	DOS_INT			; do ","
	mov	dl,run_char
	int	DOS_INT			; do "R"
	mov	ah,MS_C_WRITESTR
	mov	dx,offset confirm_msg2
	int	DOS_INT			; do ") ? "
cfg_query60:
	call	wait_for_key		; wait until a key is pressed
	mov	al,default_query_char	; if we timeout default
	 jc	cfg_query70
	mov	ah,MS_C_RAWIN
	int	DOS_INT			; read a char
	test	al,al			; is it a function key ?
	 jnz	cfg_query70
	mov	ah,MS_C_RAWIN
	int	DOS_INT			; throw away function keys
;    jmps    cfg_query60  
cfg_query70:
	cmp	al,13			; accept <CR> for 'yes'
	 jne	cfg_query71
	mov	al,yes_char
	jmp	short cfg_query80
cfg_query71:
	cmp	al,32			; accept <SPACE> for 'no'
	 jne	cfg_query72
	mov	al,no_char
	stc
	jmp	short cfg_query80
cfg_query72:
	cmp	al,27			; accept <ESC> for 'run'
	 jne	cfg_query73
	mov	al,run_char
	mov	boot_options,0
	jmp	short cfg_query80
cfg_query73:
	call	toupper			; make response upper case
	cmp	al,yes_char
	 je	cfg_query80
	cmp	al,no_char
	 jne	cfg_query75
	stc
	jmp	short cfg_query80
cfg_query75:
	cmp	al,run_char
	 je	cfg_query76
	mov	ah,MS_C_WRITE
	mov	dl,7
	int	DOS_INT			; beep
	jmp	short cfg_query60
cfg_query76:
	mov	boot_options,0
cfg_query80:
	pushf
	push	ax			; save response
	mov	ah,MS_C_WRITE
	mov	dl,al
	int	DOS_INT			; echo the char
	mov	ah,MS_C_WRITESTR
	mov	dx,offset confirm_msg3	; "DEVICE=FILENAME.SYS (Y/N) ?"
	int	DOS_INT			; now do CR/LF to tidy up
	pop	ax
;	call	toupper			; make response upper case
;	cmp	al,yes_char		; is it yes ?
;	 je	cfg_query90
;	stc				; return CY set, skip this line
	popf
cfg_query90:
	pop	di
	pop	si
	ret


call_preload_entry:		; call the preload device driver back door
	push	ds		; all DBLSPACE calls destroy DS register
	call	dword ptr preload_entry
	pop	ds
	ret

preload_complete:		; CONFIG processing complete
	push	ds
	push	es
	mov	ax,4a11h		; DBLSPACE presence check
	xor	bx,bx
	int	2fh
	or	ax,ax
	 jnz	reloc_end
	test	dx,8000h		; is relocation already complete (may
	 jz	reloc_end		;   be done by HIDEVICE statement)
	mov	bx,0ffffh		; query the size of the transcient
	mov	ax,4a11h		;   portion
	int	2fh

	mov	cx,mem_current		; pull transcient portion down to low
	mov	es,cx			;   memory
	inc	cx
	mov	es:DMD_ID,'D'		; control block type is 'D' (device
	mov	es:DMD_PSP,cx		;   driver), owner is self
	mov	es:DMD_LEN,ax
	inc	ax			; control block overhead
	add	mem_current,ax
	mov	di,8			; copy the name to the control block
	mov	si,preload_file		; device filename
preload_complete10:
	lodsb				; get a character
	cmp	al,'\'			; have we found the '\' yet ?
	 jne	preload_complete10	; no, go swallow another character
	movsw
	movsw
	movsw
	movsw				; copy the 8 bytes
	mov	ax,es
	inc	ax			; segment address of free memory
	mov	es,ax
	mov	bx,0fffeh		; move transcient portion down
	mov	ax,4a11h
	int	2fh
reloc_end:
	pop	es
	pop	ds
	ret

PreloadFixup:
;------------
; On Entry:
;	None
; On Exit:
;	None
;	All regs preserved
;
	push	es
	push	bx
	push	ax
	mov	al,preload_drv		; get number of preload drives
	les	bx,func52_ptr
	sub	es:F52_PHYDRV[bx],al
	sub	es:F52_LASTDRV[bx],al
	pop	ax
	pop	bx
	pop	es
	ret

PreloadCleanup:
;--------------	
; On Entry:
;	None
; On Exit:
;	None
;
; inform DBLSPACE about each device driver
	push	ds
	push	es
	xor	ax,ax
	xchg	al,preload_drv		; get number of preload drives
	les	bx,func52_ptr
	add	es:F52_PHYDRV[bx],al
	add	es:F52_LASTDRV[bx],al
	mov	ax,4a11h		; DBLSPACE installation check
	xor	bx,bx
	int	2fh
	or	ax,ax
	 jnz	broadcast_exit
	test	dx,8000h		; initialisation complete?
	 jz	broadcast_exit
	mov	preload_drv,ch		; save # preload drives
	mov	dx,mem_max		; top of available memory
	mov	cx,mem_current		; base of available memory
	sub	dx,cx
	mov	ah,55h			; version number
	mov	al,dev_count		; number of new units installed
    mov bx,02h          
	call	dword ptr preload_entry
broadcast_exit:
	pop	es
	pop	ds
	ret

preload_device:			; preload disk compression driver before
				;   processing (D)CONFIG.SYS file
	mov	dx,preload_file
	mov	cx,mem_current		; next available segment address
	mov	es,cx
	inc	cx
	mov	es:DMD_ID,'D'		; control block type is 'D' (device
	mov	es:DMD_PSP,cx		;   driver), owner is self
	mov	di,8			; copy the name to the control block
	mov	si,dx			; device filename
preload_device10:
	lodsb				; get a character
	cmp	al,'\'			; have we found the '\' yet ?
	 jne	preload_device10	; no, go swallow another character
	movsw
	movsw
	movsw
	movsw				; copy the 8 bytes
	mov	ax,es
	inc	ax			; segment address of free memory
	mov	dev_load_seg,ax		; destination segment for EXEC call
	mov	dev_reloc_seg,ax	; relocation factor for .EXE drivers
	push	ax
	push 	ds
	pop 	es
	mov	bx,offset dev_epb	; ES:BX control structure
	mov	ax,(MS_X_EXEC * 256)+3
	int	DOS_INT
	pop	es			; ES:0 -> preload driver
	 jnc	load_ok
load_bad:
	jmp	preload_exit
load_ok:
	cmp	es:WORD PTR 12h,2e2ch	; preload device signature
	 jne	load_bad
	mov	preload_seg,es		; back door entry to preload driver
	cmp	es:word ptr 82h,6	; is it the old DBLSPACE driver ?
	 jne	load_new_dblspace
	mov	preload_ver,6		; yes, give it the old version
load_new_dblspace:
	mov	rel_unit,0		; reset driver relative unit no.
	mov	bx,offset request_hdr	; DS:BX static INIT request header
	mov	ax,mem_max		; highest segment available to the
	mov	ds:RH0_RESIDENT[bx],0	;   driver
	mov	ds:RH0_RESIDENT+2[bx],ax
	mov	ax,cs
	mov	es,ax
	push	ds
	call	init_static_request	; initialise remaining fields
    mov ax,cs:preload_ver   
	call	dword ptr preload_entry
	pop	ds
	 jc	preload_exit		; INIT function fails if CARRY set
	or	ax,ax			;   or AX != 0
	 jnz	preload_exit
;;	mov	ax,ds:RH0_RESIDENT[bx]	; end of resident portion (offset)
;;	add	ax,15			; convert offset to paragraph size
;;	mov	cl,4
;;	shr	ax,cl
;;	add	ax,ds:RH0_RESIDENT+2[bx]	; end of resident portion (segment)
;JS we should check that the source and destination do not overlap here!

	mov	bx,04h			; find the size of the transient code
	call	call_preload_entry
	sub	mem_max,ax		; move the top of available memory down

	mov	es,mem_max		; ES destination for relocatable code
	dec	mem_max			; last free segment address
	mov	bx,06h			; call driver to relocate code etc.
	call	call_preload_entry
    inc ax          
	mov	mem_current,ax		; update base of free TPA

	mov	es,preload_seg
	xor	di,di			; ES:DI -> preload driver
	mov	bx,offset request_hdr
	mov	al,ds:RH0_NUNITS[bx]
	test	al,al
	 jz	preload_char_dev
	add	preload_drv,al		; remember how many preloaded drives
	call	block_device		; setup the DPBs and other block structures

preload_char_dev:
	mov	cx,mem_current
	mov	ax,preload_seg
	sub	cx,ax			; CX = length of preload driver
	dec	ax
	mov	es,ax			; ES:0 -> "DMD" for preload driver
	mov	es:DMD_LEN,cx
	inc	ax
	mov	es,ax
	xor	di,di			; ES:DI -> "device" header
	mov	ax,0FFFFh
	mov	es:[di],ax
	mov	es:2[di],ax
	call	device_insert		; insert device into chain

	mov	dx,mem_max		; top of available memory
	mov	cx,mem_current		; base of available memory
	sub	dx,cx
	mov	ax,5500h		; AH = version, AL = all internal drives
	mov	bx,02h			; mount existing container files
	call	call_preload_entry

	xor	bx,bx			; complete initialisation (hook
	call	call_preload_entry	;   interrupts etc.)

preload_exit:
	push 	cs
	pop 	es
	ret



func_hidevice:		; HIDEVICE=filename
; Look for /L:r1[,s1][;r2[,s2]] [/S] filename
; Look for SIZE=<hexnumber> filename

	mov	himem_region,0		; assume no region supplied
	mov	himem_size,0		;  and no size
	mov	di,offset region_opt	; check out /L: region option
	call	compare
	 jc	hidevice10
	call	parse_region		; get region and size
	 jnc	hidevice20
	xor	si,si			; something wrong, give an error
	mov	dx,offset bad_filename
	jmp	config_error

hidevice10:
	mov	di,offset size_opt	; check out SIZE= option
	call	compare
	 jc	hidevice20		; if no SIZE= just try to load it
	call	parse_size		;  else get supplied value
hidevice20:
	call	whitespace		; we may have a '=' lurking
hidevice30:
	lodsb				; strip off optional '='
	cmp	al,'='			;  before the filename
	 je	hidevice30
	dec	si			; it wasn't a '=' after all
	call	whitespace

	mov	ax,himem_size		; get size parameter
	cmp	ax,6000h		; should we just load low ?
	 jae	func_device
	push	si
	test	ax,ax			; have we been given a size ?
	 jne	hidevice40
	call	size_file		; get requirements from file size
hidevice40:
	call	himem_setup		; try and find some hi memory
	pop	si
	 jc	func_device		; if we can't load low
	push	si
	call	func_device		; now try and install the device
	call	himem_cleanup		; clean up our hi memory
	pop	si
	 jc	func_device		; error loading hi, try low
	ret


func_device:		; DEVICE=filename
	push	si
	mov	di,offset dev_name	; Copy the Device Filename into a 
	mov	byte ptr [di],0		; local buffer and zero terminate
	call	copy_file
	pop	si			; Restore original SI
	 jc 	device_error

	push	es
	push	si
	mov	es,mem_current		; ES points at structure
	call	BuildHeader
	pop	si
	push	si
	call	FindName		; DS:SI -> leafname
	call	SetName			; Fill in name info
	pop	si
	pop	es

	mov	ax,mem_current		; Get Current Memory Base
	inc	ax			; allow a para for a header
	mov	dev_load_seg,ax		; Setup the Load Address and the
	mov	dev_reloc_seg,ax	; relocation factor to be applied to
					; .EXE device drivers
	
	mov	ax,(MS_X_OPEN * 256)+0	; open file r/o
	mov	dx,offset dev_name
	int	DOS_INT
	 jc	device_error
	mov	bx,ax			; now find out how big the file is
	mov	ax,(MS_X_LSEEK * 256)+2
	xor	cx,cx
	xor	dx,dx			; by seeking to zero bytes from end
	int	DOS_INT
	 jc	device_error

	xchg	ax,cx			; save lo byte of length

	mov	ah,MS_X_CLOSE		; close this file
	int	DOS_INT
	 jc	device_error

	mov	ax,cx			; DX:AX file length
	or	cx,dx			; do we have a zero length file
	 jz	device_error		; if so stop now

	mov	cl,4
	shr	ax,cl			; convert file size to para
	mov	cl,12
	shl	dx,cl			; ignore > 1 MByte portion
	or	dx,ax			; dx = file size in para
	inc	dx			; one for rounding error
	
	add	dx,mem_current		; top of area needed for the load
	cmp	dx,mem_max		; will file fit (really HIDEVICE check)
	 jb	func_device10		; no, stop now
	ret

device_error:
	mov	error_level,ax		; save error code
	xor	al,al
	mov	si,offset dev_name
	mov	dx,offset bad_filename
	jmp	config_error

func_device10:
	mov	ax,(MS_X_EXEC * 256)+3	; Use the Load Overlay function to
	mov	bx,offset dev_epb	; Read in and Relocate the Device
	mov	dx,offset dev_name	; driver
	int	DOS_INT			;
	 jc	device_error

;	mov	dosVersion,ax		; set version number

	push	es
	mov	ax,mem_current		; Get Current Memory Base
	push	ax
	inc	ax			; skip the header
	xor	di,di			; Address of the first device header
	mov	es,ax			; in the device chain

if ADDDRV
	test	es:DH_ATTRIB[di],DA_CHARDEV
	 jnz	f_dev30			;Character device driver ?

; Can't install block device drivers so output error message and exit.
	pop	es
	pop	es

	xor	al,al
	mov	si,offset dev_name
	mov	dx,offset err_block_device
	jmp	config_error

f_dev30:
endif

	call	PreloadFixup		; fiddle things for preload
	call	ProtmanFixup		; fiddle int 12 memory for PROTMAN$
	call	device_init		; initialise the device drivers
	call	ProtmanCleanup		; restore int 12 memory after PROTMAN$
	mov	error_level,ax		; save error code
	pop	es			;  by old EMM386.SYS
	mov	ax,mem_current
	mov	es:DMD_LEN,ax		; save memory field
	mov	ax,es
	inc	ax
	sub	es:DMD_LEN,ax
	pop	es
	call	PreloadCleanup		; cleanup after ourselves
	ret


BuildHeader:
;-----------
; On Entry:
;	ES:0 -> header
; On Exit:
;	None
;
	xor	di,di
	mov	al,'D'
	stosb				; ID_FIELD
	mov	ax,es
	inc	ax
	stosw				; OWNER_FIELD
	xor	ax,ax
	stosb
	stosw
	stosw				; zero rest up to name
	ret


FindName:
;--------
; On Entry:
;	DS:SI -> pathname of file
; On Exit:
;	DS:SI -> final leaf name of file
;	CX = length of leaf name
;
	mov	cx,si			; remember start of leaf
FindName10:
	lodsb
	cmp	al,' '			; end of the name ?
	 jbe	FindName30
	call	dbcs_lead		; is it a double byte pair ?
	 jne	FindName20
	lodsb				; include the second byte
	jmp	short FindName10
FindName20:
	cmp	al,'\'			; is it a seperator ?
	 je	FindName
	cmp	al,'/'
	 je	FindName
	jmp	short FindName10
FindName30:
	xchg	cx,si			; SI -> start of leaf name
	sub	cx,si
	dec	cx			; CX = length
	ret


SetName:
;-------
; On Entry:
;	DS:SI -> leaf name to update
;	ES = DMD to update
; On Exit:
;	CX/SI preserved
;
	push	si
	mov	di,offset DMD_NAME	; point at the owners name field
SetName10:
	lodsb
	cmp	al,' '			; end of the name ?
	 jbe	SetName30
	call	dbcs_lead		; is it a double byte pair ?
	 jne	SetName20
	stosb				; copy 1st byte of pair
	cmp	di,(offset DMD_NAME)+DMD_NAME_LEN
	 jae	SetName30		; don't overflow if name too long
	movsb				; and the second
	jmp	short SetName10

SetName20:
	stosb
	cmp	al,'.'			; discard all following '.'
	 je	SetName30
	cmp	di,(offset DMD_NAME)+DMD_NAME_LEN
	 jb	SetName10		; don't overflow if name too long
SetName30:
	dec	di
	xor	ax,ax
SetName40:
	stosb				; zero the '.'
	cmp	di,(offset DMD_NAME)+DMD_NAME_LEN
	 jb	SetName40		; zero the rest of the name
SetName50:
	pop	si
	ret

ROS_MEMORY	equ	413h		; main memory on KB

protmanName	db	'PROTMAN$'

protmanAdjust	dw	0

ProtmanFixup:
;------------
; On Entry:
;	ES:DI -> device driver header
; On Exit:
;	All regs preserved
;
; fiddle int 12 memory for PROTMAN$
;
	push	cx
	push	si
	push	di
	mov	cs:protmanAdjust,0	; assume it's not protman
	mov	si,offset protmanName
	lea	di,DEVHDR.NAM[di]	; ES:DI -> device driver name
	mov	cx,8/2
	repe	cmpsw			; does the name match ?
	 jne	ProtmanFixup10
	mov	si,mem_max		; SI = top of memory in para
	push	ds
;	xor	cx,cx
	mov	ds,cx
	mov	cl,10-4
	shr	si,cl			; convert para to KBytes
	mov	cx,ds:ROS_MEMORY	; CX = existing top of memory
	sub	cx,si			; CX = amount to hide
	sub	ds:ROS_MEMORY,cx	; hide it
	pop	ds
	mov	cs:protmanAdjust,cx	; remember how much we hid
ProtmanFixup10:
	pop	di
	pop	si
	pop	cx
	ret

ProtmanCleanup:
;--------------
; On Entry:
;	None
; On Exit:
;	All regs preserved
; restore int 12 memory after PROTMAN$
;
	push	ds
	push	ax
	xor	ax,ax
	mov	ds,ax
	mov	ax,cs:protmanAdjust	; normally zero..
	add	ds:ROS_MEMORY,ax
	pop	ax
	pop	ds
	ret

;
;	The syntax currently supported is "COUNTRY=NNN,[YYY],[FILENAME]" 
;	where:-
;		NNN 	 is a valid country code based on
;			 the International Dialing Code
;
;		YYY	 is the default CODEPAGE
;
;		FILENAME is the location and name of the COUNTRY.SYS
;			 file containing the extended country info.
;
;
if not ADDDRV
func_country:		; COUNTRY=nnn,[yyy],[filename]
	call	atoi			; ax = country code
	 jc	f_ctry50		; check for error
	mov	country_code,ax		; save the Country Code
	call	separator		; look for ','
	 jc	f_ctry20
	call	atoi			; Get the Code Page
	 jc	f_ctry10		; invalid or non existent code page
	mov	code_page,ax		; save default Code Page
f_ctry10:
	call	separator		; look for ','
	 jc	f_ctry20		; copy the supplied pathname
	les	bx,drdos_ptr		; Get the internal data area
	mov	di,es:DRDOS_COUNTRY_FILE[bx]
					; ES:DI -> pcmode buffer for name
	call	copy_file
	push	cs			; restore ES
	pop	es
f_ctry20:
	call	nls_hook		; install our lang support
	mov	bx, country_code	; bx = country code
	mov	ah, MS_S_COUNTRY
	mov	al, 0FFh		; 16 bit country code
	mov	dx, 0FFFFh		; set country code subfunction
	int	DOS_INT
	 jc	f_ctry40		; check for error
	mov	bx, code_page		; bx = code page
	or	bx,bx
	 jz	f_ctry30		; No Code Page Set leave as 437
	mov	ax, MS_X_SETCP		; set codepage subfunction
	int	DOS_INT			; to set Current CodePage
	jc	f_ctry40
f_ctry30:
	jmp	nls_unhook		; remove our lang support
;	ret

f_ctry40:
	call	nls_unhook		; remove our lang support
f_ctry50:
; Bad or non-existant number in command tail. Display error message.
	xor	si,si
	mov	dx, offset bad_country
	jmp	config_error



func_shell:		; SHELL=filename
	mov	di,offset shell		; Copy the New Command Name
	call	copy_file		; into the BIOSINIT buffer
	jc	shell_error

	mov	di,offset shell_cline+1	; Now copy the default command
	mov 	al,' '
	stosb				; into place
	xor	cx,cx			;
f_sh10:
	lodsb
	stosb				; Copy the next Character
	inc	cx			; Increment the count
	cmp	al,CR			; Was this the end of string Char
	jnz	f_sh10			; No so Repeat
	mov	shell_cline,cl		; Save Command Length
	ret

shell_error:
	mov	al,CR
	mov	dx,offset bad_shell
	jmp	config_error

func_hilastdrive:	; HILASTDRIVE=d:
	or	lastdrvIn,LASTDRV_IN_HMA+LASTDRV_IN_UMB
					; enable HMA and UMB usage for LDT

func_lastdrive:		; LASTDRIVE=d:
	call	atoi			; are we supplying a decimal number?
	 jc	f_lastdrive10
	cmp	al,32			; is it in range ?
	 jbe	f_lastdrive20	
lastdrv_error:
	xor	si,si			; Do not display Failing String
	mov	dx,offset bad_lastdrive	; and display an error message
	jmp	config_error

f_lastdrive10:
	lodsb				; Get the Option Character 
	call	toupper			; and convert to Upper Case
	sub	al, 'A'			; al should be between 0..25
	jc	lastdrv_error
	cmp	al, 'Z'-'A'
	ja	lastdrv_error
	inc	al			; al = number of drives in system
f_lastdrive20:
	mov	last_drv,al		; remember for later
	ret



func_break:		; BREAK=ON/OFF
	call	check_onoff		; Check for ON or OFF
	mov	dl,al			; Get value found
	jnc	set_break		; and check for error

	xor	si,si			; Do not display Failing String
	mov	dx, offset bad_break	; Bad or non-existant ON/OFF string
	jmp	config_error		; in command tail. Display error message.

set_break:
	mov	ah,MS_S_BREAK		; Set the Default Break Flag
	mov	al,01			; Set Sub-Function
	int	DOS_INT			; Execute function and return
	ret



func_numlock:		; NUMLOCK=ON/OFF
	call	check_onoff		; Check for ON or OFF
	 jc	numlock20
	push	ds
	xor	bx,bx
	mov	ds,bx
	mov	bx,417h			; DS:BX -> keyboard control
	or	ds:byte ptr [bx],20h	; set numlock bit
	test	al,al			; was it numlock on ?
	 jnz	numlock10		; if not, better clear the bit
	and	ds:byte ptr [bx],not 20h
numlock10:
	pop	ds
	mov	ah,MS_C_STAT		; get console status
	int	DOS_INT			; (usually int 16 update NUMLOCK state)
numlock20:
	ret



func_hibuffers:		; HIBUFFERS=nn[,nn]
	or	buffersIn,BUFFERS_IN_HMA+BUFFERS_IN_UMB
					; enable HMA and UMB usage for disk buffers
;	jmp	func_buffers

func_buffers:		; BUFFERS=nn[,nn]
	call	atoi			; AX = # of buffers
	 jc	buffer_error		; check for error
	cmp	ax,MIN_NUM_BUFFS	; check if less than minimum
	 jae	func_buf1
	mov	ax,3			; force to use minimum if less
func_buf1:
	cmp	ax,MAX_NUM_BUFFS	; check if more than maximum
	 jbe	func_buf2
	mov	ax,MAX_NUM_BUFFS	; force to use maximum if more
func_buf2:
	mov	init_buf,al		; update if we want more
	call	separator		; look for ','
	 jc	func_buf4
	call	atoi			; Get read-ahead buffer size
	 jc	buffer_error
	cmp	ax,MIN_READ_AHEAD
	 jb	buffer_error
	cmp	ax,MAX_READ_AHEAD
	 ja	buffer_error
	mov	num_read_ahead_buf,al
func_buf4:
	ret

buffer_error:
	xor	si,si			; Do not display Failing String
	mov	dx, offset bad_buffers
	jmp	config_error

func_hifiles:		; HIFILES=nn
	or	filesIn,FILES_IN_HMA+FILES_IN_UMB
					; enable HMA and UMB usage for file handles

func_files:		; FILES=nn
	call	atoi			; AX = # of files
	 jc	files_error		; check for error
	cmp	ax,MIN_NUM_FILES	; check if less than minimum
	 jae	func_fil1
	mov	ax,MIN_NUM_FILES	; force to use minimum if less
func_fil1:
	cmp	ax,MAX_NUM_FILES	; check if more than maximum
	 jbe	func_fil2
	mov	ax,MAX_NUM_FILES	; force to use maximum if more
func_fil2:
	mov	num_files,ax		; update the number required
	ret

files_error:
	xor	si,si			; Do not display Failing String
	mov	dx, offset bad_files
	jmp	config_error

func_hifcbs:		; HIFCBS=nn
	or	filesIn,FILES_IN_HMA+FILES_IN_UMB
					; enable HMA and UMB usage for file handles

func_fcbs:		; FCBS=nn
	call	atoi			; AX = # of files
	 jc	fcbs_error		; check for error
	cmp	ax,MIN_NUM_FCBS		; check if less than minimum
	 jae	func_fcb1
	mov	ax,MIN_NUM_FCBS		; force to use minimum if less
func_fcb1:
	cmp	ax,MAX_NUM_FCBS		; check if more than maximum
	 jbe	func_fcb2
	mov	ax,MAX_NUM_FCBS		; force to use maximum if more
func_fcb2:
	mov	num_fcbs,ax		; update number of FCB's
	ret

fcbs_error:
	xor	si,si			; Do not display Failing String
	mov	dx, offset bad_fcbs
	jmp	config_error
endif					;not ADDDRV



func_common:		; [COMMON]
func_remark:		; REM Comment field
	ret

func_switches:		; SWITCHES=...
			; /N = disable F5/F8 feature
			; /W = zap wina20.386 name
			; /K = disable enhanced keyboard support
			; /F = skip statup delay

	call	whitespace		; skip all spaces
	lodsw				; get '/x'
	cmp	al,CR			; check for end-of-line
	 je	func_switches10
	cmp	ah,CR			; check for end-of-line
	 je	func_switches10
	cmp	ax,'F/'
	 jne	func_switches05
	or	boot_switches,SWITCH_F
	jmp	short func_switches
func_switches05:
	cmp	ax,'N/'
	 jne	func_switches
;	mov	boot_options,0		; disable boot options
	or	boot_switches,SWITCH_N	; disable boot options
func_switches10:
	ret

func_histacks:		; HISTACKS=number,size
	or	stacksIn,STACKS_IN_HMA+STACKS_IN_UMB
					; enable HMA and UMB usage for stacks

func_stacks:		; STACKS=number,size
;-----------
	call	atoi			; ax = number of stacks
	 jc	func_stacks20		; check for error
	test	ax,ax			; special case ? (disabled)
	 jz	func_stacks10
	cmp	ax,MIN_NUM_STACKS	; range check for a sensible value
	 jb	func_stacks20
	cmp	ax,MAX_NUM_STACKS
	 ja	func_stacks20
func_stacks10:
	mov	num_stacks,ax
	call	separator		; look for ','
	 jc	func_stacks20
	call	atoi			; get size of a stack frame
	 jc	func_stacks20
	cmp	ax,MIN_SIZE_STACK	; range check it
	 jb	func_stacks20
	cmp	ax,MAX_SIZE_STACK
	 ja	func_stacks20
	mov	stack_size,ax
func_stacks20:
	ret


if not ADDDRV
func_deblock:		; DEBLOCK=xxxx
;------------
	call	atohex			; read hex number into DX:AX
	 jc	func_deblock10
	test	dx,dx
	 jnz	func_deblock10
	mov	DeblockSetByUser,TRUE and 0FFh	; the user has supplied a setting
	push	ds
	mov	ds,bios_seg
	mov	DeblockSeg,ax		; save deblocking segment
	pop	ds
func_deblock10:
	ret

func_fastopen:		; FASTOPEN=nn
	call	atoi			; AX = # of files to cache
	 jc	fopen_error		; check for error
	test	ax,ax			; disable fast open?
	 jz	func_fopen2		; yes, allow to set to 0000
	cmp	ax,MIN_NUM_FOPEN	; check if less than minimum
	 jae	func_fopen1
	mov	ax,MIN_NUM_FOPEN	; force to use minimum if less
func_fopen1:
	cmp	ax,MAX_NUM_FOPEN	; check if more than maximum
	 jbe	func_fopen2
	mov	ax,MAX_NUM_FOPEN	; force to use maximum if more
func_fopen2:
	mov	num_fopen,ax		; update if we want more
func_fopen3:
	ret

fopen_error:
	xor	si,si			; Do not display Failing String
	mov	dx, offset bad_fopen
	jmp	config_error


func_drivparm:	; DRIVPARM = /d:nn [/c] [/f:ff] [h:hh] [/n] [/s:ss] [/t:tt]
;-------------
;	This function specifies the drive parameters for a device
;	and overrides the defaults assumed by the device driver.

	mov	drivp_drv,0FFh		; invalid drive
	call	get_switch		; get next switch
	cmp	al,'d'			; first option must be /d:dd
	 jne	drivparm_error
	call	get_number		; get numeric parameter
	mov	drivp_drv,al
	mov	drivp_chg,FALSE
	mov	drivp_prm,FALSE
	mov	drivp_trk,80		; assume 80 tracks

	mov	bl,drivp_drv		; get drive to set up
	cmp	bl,'Z'-'A'
	 ja	drivparm_error
	inc	bl
	mov	ioctl_pb,0		; return defaults
	mov	ax,440Dh		; generic IOCTL
	mov	cx,0860h		; get device parameters
	mov	dx,offset ioctl_func
	int	DOS_INT
	 jc	drivparm_error		; skip if we can't get parameters

	mov	drivp_ff,2		; assume 720K 3.5" drive
	call	set_form_factor		; set defaults for form factor

	call	get_switch		; get next switch
	cmp	al,'c'			; is it /c (change line available)
	 jne	drivparm1
	mov	drivp_chg,TRUE and 0FFh	; disk change line available
	call	get_switch		; get next switch
drivparm1:
	cmp	al,'f'			; form factor specification?
	 jne	drivparm2
	call	get_number		; get numeric parameter
	mov	drivp_ff,al		; set form factor
	call	set_form_factor		; set defaults for form factor
	jmp	short drivparm_loop	; get more parameters

drivparm_error:
	xor	si,si
	mov	dx,offset bad_drivparm
	jmp	config_error

drivparm_loop:
	call	get_switch		; get next switch
drivparm2:
	cmp	al,'h'			; specify number of heads
	 jne	drivparm3
	call	get_number		; get numeric parameter
	cmp	ax,99
	 ja	drivparm_error
	mov	drivp_heads,ax		; set # of heads
	jmp	short drivparm_loop

drivparm3:
	cmp	al,'n'
	 jne	drivparm4
	mov	drivp_prm,TRUE and 0FFh	; non-removable media
	jmp	short drivparm_loop

drivparm4:
	cmp	al,'s'
	 jne	drivparm5
	call	get_number		; get numeric parameter
	cmp	ax,63			; range check sector per track
	 ja	drivparm_error
	mov	drivp_spt,ax		; set # of sectors/track
	jmp	short drivparm_loop

drivparm5:
	cmp	al,'t'
	 jne	drivparm_error
	call	get_number		; get numeric parameter
	cmp	ax,999
	 ja	drivparm_error
	mov	drivp_trk,ax		; set # of sectors/track
	jmp	short drivparm_loop

drivparm_done:				; now set drive parameters
	mov	bl,drivp_drv
	cmp	bl,'Z'-'A'
	 ja	drivparm_error

	mov	ioctl_func,00000100b	; normal track layout assumed,
					; set device BPB for drive
	mov	al,drivp_ff		; get form factor
	mov	ioctl_type,al

	sub	ax,ax			; assume removable, no disk change
	cmp	drivp_prm,FALSE
	 je	drivp_d1
	or	ax,1			; drive is permanent media
drivp_d1:
	cmp	drivp_chg,FALSE
	 je	drivp_d2
	or	ax,2			; drive supports disk change line
drivp_d2:
	mov	ioctl_attrib,ax		; set drive attributes

	mov	ax,drivp_trk		; set # of cylinders
	mov	ioctl_tracks,ax
	
	mov	ioctl_mtype,0		; assume standard type

	mov	ax,drivp_spt		; get sectors/track
	mov	di,offset ioctl_layout
	push	ds
	pop 	es			; ES:DI -> layout table
	stosw				; set # of sectors
	xchg	ax,cx			; CX = # of sectors
	mov	ax,1			; start with sector 1
drivp_d3:
	stosw				; set next sector #
	inc	ax			; move to next sector
	loop	drivp_d3		; repeat for all sectors

	mov	ax,drivp_heads
	mul	drivp_spt
	mov	dx,drivp_trk
	mul	dx			; AX/DX = # of sectors/disk
	mov	di,offset ioctl_bpb
	mov	8[di],ax		; set sectors per disk
	test	dx,dx
	 jz	drivp_d4
	mov	word ptr 8[di],0	; indicate large partition
	mov	21[di],ax		; set disk size in sectors
	mov	23[di],dx
drivp_d4:
	mov	bl,drivp_drv
	inc	bl
	mov	ax,440Dh
	mov	cx,0840h		; set drive parameters
	mov	dx,offset ioctl_func
	int	DOS_INT			; tell the BIOS, ignore errors

	ret


get_switch:				; get next command line switch
	call	whitespace		; skip all spaces & tabs
	lodsb				; get next character
	pop	dx			; get return address
	cmp	al,'/'			; did we get a switch?
	 je	get_swt9		; yes, return the character
	jmp	drivparm_done
get_swt9:
	lodsb
	or	al,('a' xor 'A')	; return upper-cased character
	jmp	dx
	

get_number:
;	entry:	SI -> next character (must be ':')

	lodsb				; get next character
	cmp	al,':'			; must be colon
	 jne	get_num_err		; return error if not
	call	atoi			; get numeric value
	 jc	get_num_err		; must be number
	ret				; AX = number

get_num_err:
	pop	dx
	jmp	drivparm_error		; reject this command


set_form_factor:
	mov	bl,drivp_ff
	cmp	bl,7
	 ja	set_form9
	xor	bh,bh
	shl	bx,1
	push	si
	push 	es
	mov	si,ff_table[bx]		; SI -> default media BPB
	push	ds
	pop 	es
	mov	di,offset ioctl_bpb	; ES:DI -> local BPB
	mov	cx,21			; copy initialized portion
	rep	movsb
	pop	es
	pop 	si
	ret

set_form9:
	jmp	drivparm_error


;
;	This function modifies the History buffer support provided by
;	DR DOS the defaults are History OFF, 512 byte buffers,
;	Insert ON, Search OFF, Matching OFF.
;
func_history:	; HISTORY = ON|OFF[,NNNN[,ON|OFF[,ON|OFF[,ON|OFF]]]]
;------------
	mov	history_flg,0		; start with it all off

	call	check_onoff		; Check for ON|OFF Switch 
	 jc	f_hist_err
	test 	al,al
	jz 	f_hist_exit		; if OFF forget the rest
	or	history_flg,RLF_ENHANCED+RLF_INS

	call	separator		; look for ','
	 jc	f_hist_exit		; Buffer Size not Specified
	call	atoi			; Get the Buffer Size
	 jc	f_hist_err		; Invalid on no existant size
	cmp 	ax,128
	jb 	f_hist_err		; Buffer Size to Small
	cmp 	ax,4096
	ja 	f_hist_err		; Buffer Size to Large
	mov	history_size,ax		; Save History Buffer Size

	call	separator		; look for ','
	 jc	f_hist_exit		; Insert mode not Specified
	call	check_onoff		; Check for ON|OFF Switch 
	 jc	f_hist_err
	test	al,al
	jnz 	func_hist10
	and	history_flg,not RLF_INS	; Insert state OFF
func_hist10:
	call	separator		; look for ','
	 jc	f_hist_exit		; Search mode not Specified
	call	check_onoff		; Check for ON|OFF Switch 
	 jc	f_hist_err
	test	al,al
	jz 	func_hist20
	or	history_flg,RLF_SEARCH	; Search state ON
func_hist20:
	call	separator		; look for ','
	 jc	f_hist_exit		; Match mode not Specified
	call	check_onoff		; Check for ON|OFF Switch 
	 jc	f_hist_err
	test	al,al
	jz 	func_hist30
	or	history_flg,RLF_MATCH	; Match state ON
func_hist30:

f_hist_exit:
	ret

f_hist_err:
	xor	si,si			; Do not display Failing String
	mov	dx, offset bad_history	; Bad or non-existant ON/OFF string
	jmp	config_error		; in command tail. Display error message.


;
;	HIINSTALL filename [Command Line Parameters]
;
;	As INSTALL, but uses high memory if possible
;
func_hiinstall:

    mov ax,5802h       
	int	DOS_INT			;   get upper memory link
	cbw
	push	ax			; save upper memory link
	
    mov ax,5800h       
	int	DOS_INT			;   get alloc strategy
	push	ax			; save alloc strategy
	
    mov ax,5803h       
	mov	bx,1			;   set upper memory link
	int	DOS_INT			;   to 1
	
    mov ax,5801h       
	mov	bx,80h			;   set alloc strategy to lowest-upper
	int	DOS_INT			;   if available
	
	call	func_install		; try and install it
	
    mov ax,5801h       
	pop	bx			;   set alloc strategy
	int	DOS_INT			;   to original value
	
    mov ax,5803h       
	pop	bx			;   set upper memory link
	int	DOS_INT			;   to original value
	
	ret



;
;	INSTALL filename [Command Line Parameters]
;
;	INSTALL will load and execute "FILENAME" with the optional command 
;	line parameters and continue processing the DCONFIG.SYS file when
;	the application terminates.
;
; Entry
;	ds:si -> first character of CR terminated filename and option string.
; Exit
;	none
;
; WARNING -
;	This code make certain assumptions about memory layout. 
;	If memory gets fragmented then it all starts falling apart.
;
func_install:
;------------
	push 	ds
	push 	es
;
;	Shrink the previously allocated memory block to MEM_CURRENT
;	in preparation of the INSTALL EXEC function.
;
	mov	es,mem_current_base	; ES: Base Allocated Memory
	mov	bx,mem_current		; Get the currently allocated memory
	sub	bx,mem_current_base	;  and subtract mem_current_base to
	mov	ah,MS_M_FREE		;  give the number of paragraphs used
	 jz	func_i10		; if none, free it all up	
	mov	ah,MS_M_SETBLOCK	; else modify block accordingly
func_i10:
	int	DOS_INT

; Now to protect the CONFIG code in high memory
	mov	ah,MS_M_ALLOC		; we now try to find base of TPA
	mov	bx,0ffffh		; ASSUME it is the biggest bit
	int	21h			;  of free memory about
	mov	ah,MS_M_ALLOC		; give it to me please
	int	21h			; ax:0 -> exec memory
	push	bx			; we have allocated BX para's
	mov	es,ax			; ES -> exec memory
;	mov	bx,init_dseg		; we want to protect BX:0 and above
	mov	bx,res_ddsc_seg		; we want to protect BX:0 and above
	dec	bx			; allow for DMD
	sub	bx,ax			; we can spare this many paras
	mov	ah,MS_M_SETBLOCK	;  for the exec so grow the 
	int	21h			;  block accordingly
	pop	ax			; AX = total, BX = amount for install

	sub	ax,bx			; AX = amount we just freed
	dec	ax			; allow for DMD
	xchg	ax,bx			; BX = freed portion (the Init code)
	mov	ah,MS_M_ALLOC		; ASSUME an allocation of this size
	int	21h			;  will contain SYSDAT/CONFIG
	push	ax			; save seg so we can free mem later

	mov	ah, MS_M_FREE		; now free up the bit we prepared
	int	21h			;  earlier so exec has something
	push 	ds
	pop 	es			;  to work in

	mov	di,offset dev_name	; Copy the filename into a local
	call	copy_file		; buffer

					; Calculate the command line length
	mov	di,si			; by scanning the command line for
	mov	al,CR			; the terminating CR
	mov	cx,128
	repnz	scasb
	dec	di
	mov	ax,di
	sub	ax,si
	dec	si			; Point to the byte before the 
	mov	byte ptr [si],al	; command line string and update 
					; the count	

	mov	ax,offset envstart	; env buffer is para aligned
	mov	cl,4
	shr	ax,cl			; convert offset to paras
	mov	cx,ds
	add	ax,cx			; segment of env variables
	mov	exec_envseg,ax
	mov	exec_lineoff,si
	mov	exec_lineseg,ds
	mov	exec_fcb1off,0FFFEh	  ; Force PCMODE to generate
	mov	exec_fcb2off,0FFFEh	  ; correct FCB References

	mov	system_ss,ss
	mov	system_sp,sp

	mov	dx,offset dev_name	; Get ASCIIZ Command
	mov	bx,offset exec_envseg	; and Parameter Block Offset
	mov	ax,4B00h		; Load and Execute Program with Handle
	int	DOS_INT			; EXEC the application

	cli				; Swap back to the original stack
	mov	ss,cs:system_ss		; again with interrupts disabled
    mov sp,cs:system_sp
	sti

	mov	ah,MS_X_WAIT		; if all went well return the
	 jnc	func_i20		;  termination code
	mov	ah,MS_F_ERROR		; if we had an error from EXEC
	xor	bx,bx			;  get extended error
func_i20:
	int	DOS_INT			; retrieve error value
	mov	cs:error_level,ax	;  and save for testing

	pop	es			; recover the seg we protected
	mov	ah, MS_M_FREE		; so we can free that memory up
	int	21h
	
	mov	ah,MS_M_ALLOC		; try and allocate as much as possible
	mov	bx, 0FFFFh		; ASSUME this will cover CONFIG
	int	21h			; bx = No. of paras available
	mov	ah, MS_M_ALLOC		;  give me bx paras please
	int	21h			;  ax:0 -> my memory

	pop 	es
	pop 	ds
	mov	mem_current_base,ax	; save memory base
	mov	mem_current,ax		; for future allocations
	ret



func_hidos:		; HIDOS ON/OFF
	call	check_onoff		; Check for ON or OFF
	 jc	f_hidos10		; Return on error
	mov	hidos,al		; update hidos flag
f_hidos10:
	ret

func_dosdata:		; DOSDATA=UMB - relocate DOS data segment to upper memory
	call	separator
	mov	di,offset low_opt
	call	compare
	 jc	func_dosdata10
	mov	hidosdata,0
	jmp	short func_dosdata
func_dosdata10:
	mov	di,offset umb_opt
	call	compare
	 jc	func_dosdata20
	or	hidosdata,DOSDATA_IN_UMB
	jmp	short func_dosdata
func_dosdata20:
	ret

func_ddscs:		; DDSCS=HIGH,UMB - relocate DDSCs to high or upper memory
	call	separator
	mov	di,offset low_opt
	call	compare
	 jc	func_ddscs10
	mov	hiddscs,0
	jmp	short func_ddscs
func_ddscs10:
	call	separator
	mov	di,offset high_opt
	call	compare
	 jc	func_ddscs20
	or	hiddscs,DDSCS_IN_HMA
	jmp	short func_ddscs
func_ddscs20:
	call	separator
	mov	di,offset umb_opt
	call	compare
	 jc	func_ddscs30
	or	hiddscs,DDSCS_IN_UMB
	jmp	short func_ddscs
func_ddscs30:
	ret

func_xbda:		; XBDA=LOW,UMB
	call	separator
	mov	di,offset low_opt
	call	compare
	 jc	func_xbda10
	or	hixbda,MOVE_XBDA_LOW
	jmp	short func_xbda
func_xbda10:
	call	separator
	mov	di,offset umb_opt
	call	compare
	 jc	func_xbda20
	or	hixbda,MOVE_XBDA_HIGH
	jmp	short func_xbda
func_xbda20:
	ret


func_dos:		; DOS=HIGH - relocate BIOS/BDOS/Buffer etc to FFFF
	call	separator		; Deblank Command
	mov	di,offset high_opt	; es:di -> "HIGH"
	call	compare			; do we have an "HIGH"?
	 jc	func_dos10
	push	si
	call	func_dos_high		; execute HIGH
	pop	si
	jmp	short func_dos
func_dos10:
	mov	di,offset low_opt	; es:di -> "LOW"
	call	compare
	 jc	func_dos20
	push	si
	call	func_dos_low		; execute LOW
	pop	si
	jmp	short func_dos
func_dos20:
	mov	di,offset umb_opt	; es:di -> "UMB"
	call	compare
	 jc	func_dos30
	push	si
	call	func_dos_umb		; execute UMB
	pop	si
	jmp	short func_dos
func_dos30:
	mov	di,offset noumb_opt	; es:di -> "NOUMB"
	call	compare
	 jc	func_dos40
	push	si
	call	func_dos_noumb		; execute NOUMB
	pop	si
	jmp	short func_dos
func_dos40:
	ret

func_dos_high:
;-------------
; Move DOS into the HMA and allocate buffers etc. high too.
;
	mov	dos_target_seg,0FFFFh
	mov	bios_target_seg,0FFFFh
	mov	hidos,TRUE and 0FFh	; update hidos flag to be ON
	or	buffersIn,BUFFERS_IN_HMA; buffers at seg FFFF too
;	or	filesIn,FILES_IN_HMA	; and also files
	ret

func_dos_low:
;------------
; force all allocation to be low
;
	mov	dos_target_seg,0
	mov	bios_target_seg,0
	mov	hidos,FALSE		; system allocation from low memory
	mov	buffersIn,0		; buffers from low memory
	mov	filesIn,0		; also files
	mov	stacksIn,0		; and stacks
	mov	lastdrvIn,0		; and LDT
	ret

func_dos_umb:
;------------
; allocate Upper Memory Blocks and link them to the DMD chain
;
	mov	hidos,TRUE and 0FFh	; update hidos flag to be ON
	or	buffersIn,BUFFERS_IN_UMB; enable UMB usage for buffers
	or	filesIn,FILES_IN_UMB	; and files
	or	stacksIn,STACKS_IN_UMB	; and stacks
	or	lastdrvIn,LASTDRV_IN_UMB; and LDT
	call	initialise_dmd_upper	; build initial upper memory DMD
	 jc	func_dos_umb30
func_dos_umb10:
	call	alloc_xms_umb		; allocate XMS upper memory
	 jc	func_dos_umb20
	call	add_dmd_upper		; add to upper memory DMD's
	jmp	short func_dos_umb10	;  go around again
func_dos_umb20:
	call	remove_last_dmd		; get rid of useless last DMD
func_dos_umb30:
	mov	ax,(MS_M_STRATEGY*256)+3
	mov	bx,1			; link in upper memory region
	int	21h
	ret

func_dos_noumb:
;--------------
; Unlink Upper Memory blocks from the DMD chain
;
	mov	ax,(MS_M_STRATEGY*256)+3
	xor	bx,bx			; unlink upper memory region
	int	21h
	ret

alloc_xms_umb:
; On Entry:
;	None
; On Exit:
;	CY set is no upper memory available
; else
;	BX = para base address
;	DX = para size
;
; Try to allocate the largest possible block of XMS memory
; so we can link it to the upper memory chain
;
	push	es
	mov	ax,4300h		; check for XMS installation
	int	2fh
	cmp	al,80h
	 jne	alloc_xms10
	mov	ax,4310h		; get address of XMS driver
	int	2fh
	mov	word ptr cs:xms_driver,bx
	mov	word ptr cs:xms_driver+2,es
	mov	ah,10h			; allocate upper memory block
	mov	dx,0FFFFh		; DX set to find largest block
	call	dword ptr cs:xms_driver
	cmp	dx,3			; we need at least 3 para's
	 jb	alloc_xms10		;  before we contruct a DMD
	mov	ah,10h			; now allocate largest block
	call	dword ptr cs:xms_driver
	cmp	ax,1			; did we succeed ?
	 je	alloc_xms20
alloc_xms10:
	stc				; return CY set indicating failure
alloc_xms20:
	pop	es
	ret

xms_driver	label dword
	dw	0,0

initialise_dmd_upper:
; On Entry:
;	None
; On Exit:
;	CY set if chain already exists
;	(BX/DX preserved)
;
; build initial upper memory DMD
; we rely on the fact the last para in memory is unused
; (but BIOSINIT makes sure that is true)
;
	push	es
	push	bx
	push	dx
	les	bx,func52_ptr		; ES:BX -> list of lists
	cmp	es:F52_DMD_UPPER[bx],0FFFFh
	stc				; assume error return required
	 jne	initialise_dmd_upper30	; bail out if chain already established
	mov	es,es:F52_DMDROOT[bx]	; ES -> 1st DMD
initialise_dmd_upper10:
	cmp	es:DMD_ID,IDZ		; end of DMD chain ?
	 je	initialise_dmd_upper20
	cmp	es:DMD_ID,IDM		; do we have any more DMD's ?
	stc
	 jne	initialise_dmd_upper30 	; woops, chain must be bad
	mov	ax,es			; better point to it
	inc	ax
	add	ax,es:DMD_LEN		; AX:0 -> next DMD
	mov	es,ax
	jmp	short initialise_dmd_upper10

initialise_dmd_upper20:
	mov	ax,es
	add	ax,es:DMD_LEN		; AX:0 -> will be upper memory chain
	cmp	ax,0A000h		; if the DMD chain is already into
	cmc				;  upper memory, lets make sure we
	 jb	initialise_dmd_upper30	;  stop before we fall apart
	mov	es:DMD_ID,IDM		; no longer the last entry
	dec	es:DMD_LEN		; shorten last DMD to make room
	mov	es,ax			; point to new DMD
	mov	es:DMD_ID,IDZ		; there is only one entry in the chain
	mov	es:DMD_PSP,8		; its' owned by "system"
	xchg	ax,cx			; CX = DMD
	mov	ax,0FFFFh
	sub	ax,cx			; it's this big
	mov	es:DMD_LEN,ax
	les	bx,func52_ptr
	mov	es:F52_DMD_UPPER[bx],cx
	clc
initialise_dmd_upper30:
	pop	dx
	pop	bx
	pop	es
	ret


remove_last_dmd:
; On Entry:
;	None
; On Exit:
;	None
;
; We have build an upper memory DMD chain, but we have left an extra
; DMD around covering the ROMs at the top of memory. Remove it if
; it's not required.
;
	push	es
	les	bx,func52_ptr		; ES:BX -> list of lists
	mov	es,es:F52_DMDROOT[bx]	; ES -> 1st DMD
remove_last_dmd10:
	cmp	es:DMD_ID,IDM		; do we have any more DMD's ?
	 jne	remove_last_dmd20	; bail out if we don't
	mov	ax,es			; remember previous DMD
	mov	dx,es
	inc	dx
	add	dx,es:DMD_LEN		; DX:0 -> next DMD
	mov	es,dx
	cmp	es:DMD_ID,IDZ		; end of DMD chain ?
	 jne	remove_last_dmd10
	cmp	es:DMD_PSP,8		; is it owned by "system" ?
	 jne	remove_last_dmd20	;  if so we can ditch this entry
	mov	es,ax			; ES = next to last DMD
	mov	es:DMD_ID,IDZ		; new end of chain
	inc	es:DMD_LEN		; include last para
	les	bx,func52_ptr		; ES:BX -> list of lists
	cmp	dx,es:F52_DMD_UPPER[bx]
	 jne	remove_last_dmd20	; remove upper memory link if none left
	mov	es:F52_DMD_UPPER[bx],0FFFFh
remove_last_dmd20:	
	pop	es
	ret


add_dmd_upper:
; On Entry:
;	BX = base address of DMD
;	DX = size of DMD
; On Exit:
;	None
;
; Add this block into the upper memory chain.
; To do this we find the DMD containing the block and link it into place
;
	push	es
	push	bx			; save base address
	les	bx,func52_ptr		; ES:BX -> list of lists
	mov	ax,es:F52_DMDROOT[bx]	; AX -> 1st DMD
	pop	bx			; 1st DMD is always below XMS
	cmp	ax,bx			;  memory, so bomb out if not
	 jae	add_dmd_upper40		;  as our DMD's must be corrupt
add_dmd_upper10:
	mov	es,ax
	add	ax,es:DMD_LEN		; AX:0 -> end of this block
	cmp	ax,bx			; is the next block above us ?
	 ja	add_dmd_upper20		; if not try the next block
	inc	ax			; AX:0 -> next DMD
	cmp	es:DMD_ID,IDM		; do we have any more DMD's ?
	 je	add_dmd_upper10		;  we should have......
	jmp	short add_dmd_upper40	; stop, DMD's are screwed up

add_dmd_upper20:
; We have found the block we wish to insert a new free block into
	cmp	es:DMD_PSP,8		; it must be owned by "system"
	 jne	add_dmd_upper40
; Shorten existing DMD to point to new block
	mov	ax,bx			; work out how far to new DMD
	mov	cx,es
	sub	ax,cx			; it's this many para's
	dec	ax			; forget the header
	xchg	ax,es:DMD_LEN		; set new length
; now we need to work out how much is left above the new DMD
	sub	ax,dx			; subtract length of new block
	sub	ax,es:DMD_LEN		; subtract the portion below
; Create DMD covering new block
	mov	cl,IDM			; create a new entry
	xchg	cl,es:DMD_ID		; CL = existing ID (M/Z)
	mov	es,bx			; ES -> base of new DMD
	mov	es:DMD_ID,IDM		; it's a link field
	mov	es:DMD_PSP,0		; it's free
	dec	dx			; forget the header
	add	bx,dx			; last para is here
	dec	dx			; forget the next link
	mov	es:DMD_LEN,dx		; it's this long
; Build a new DMD at the top if the new block for anything above it
	mov	es,bx
	mov	es:DMD_ID,cl		; inherit the ID field
	mov	es:DMD_LEN,ax		; and it's this long
	test	ax,ax			; if zero length then
	 jz	add_dmd_upper30		;  it's free
	mov	ax,8			; else it's system
add_dmd_upper30:
	mov	es:DMD_PSP,ax		; set owner
add_dmd_upper40:
	pop	es
	ret




func_set:		; SET envar=string
	call	whitespace		; deblank the command
	mov	di,offset envstart-1	; point to our environment area
func_set5:
	inc	di
	cmp	es:word ptr [di],0	; are we at the end yet
	 jne	func_set5
	cmp	di,offset envstart	; if nothing is there yet start
	 je	func_set10		;  at the NUL, else skip the NUL
	inc	di			;  to leave a seperator
func_set10:
	lodsb				; get a character
	cmp	al,CR			; end of the line yet ?
	 je	func_set20
	cmp	di,offset envend	; have we room ?
	 jae	func_set30		; bail out if not
	stosb				; save the character
	jmp	short func_set10
func_set20:
	xor	ax,ax			; terminate with NULL
	stosb
func_set30:
	ret
endif					;not ADDDRV


func_echo:		; ECHO "string"	
	call	whitespace		; Scan off all white space
	lodsb				; before the optional
	cmp	al,'='			; '=' character.
	 je	func_echo10
	dec	si			; point at char
func_echo10:
	mov	dx,offset msg_dollar	; NUL error message
	mov	al,CR			; SI -> config line anyway
	jmp	config_error		; use error reporting routine

func_yeschar:		; yeschar "string"	
	call	whitespace		; Scan off all white space
	lodsb				; before the optional
	cmp	al,'='			; '=' character.
	 je	func_yeschar10
	dec	si			; point at char
func_yeschar10:
	call	whitespace
	lodsb
	mov	yes_char,al		; update YES character
	ret

func_chain:		; CHAIN="filename" - use as new CONFIG.SYS
	mov	di,offset dev_name	; Copy the Device Filename into a 
	mov	byte ptr [di],0		; local buffer and zero terminate
	call	copy_file
	 jc	func_chain10		; ignore if any problems
	mov	ax,(MS_X_OPEN*256)+80h	; Try to open the file
	mov	dx,offset dev_name	; as a new config file
	int	DOS_INT			; if we can't ignore it
	 jc	func_chain10
	mov	bx,ax
	mov	ah,MS_X_CLOSE
	int	DOS_INT			; close the new file
	mov	si,offset dev_name
	mov	di,offset cfg_file
	call	copy_asciiz		; copy the new name
	mov	cfg_seeklo,0		; start at begining of it
	mov	cfg_seekhi,0
	mov	cfg_tail,0		; force a read
func_chain10:
	ret

func_switch:				; SWITCH=option0, option1
; GOSUB to appropriate label
	cmp	configpass,1
	 ja	func_switch05
	call	wait_for_key		; wait until a key is pressed
	 jc	func_switch01		; ignore if timeout
	mov	ah,MS_C_RAWIN
	int	DOS_INT			; read a char
	cmp	al,CR
	 jne	func_switch02
func_switch01:
	mov	al,default_switch_char	; use default character
func_switch02:
	cmp	al,'0'			; ignore if < '0'
	 jb	func_switch
	cmp	al,'9'			;  or > '9'
	 ja	func_switch
	sub	al,'1'			; convert from ASCII
	 jns	func_switch05
	mov	al,10			; make '0' into 10
func_switch05:
	xor	di,di
	xor	bx,bx
	mov	cx,cfg_seeklo
	mov	dx,cfg_seekhi
	sub	cx,cfg_tail
	sbb	dx,0
	add	cx,cfg_head
	adc	dx,0
func_switch06:
	cmp	di,cfg_switchnum
	 jae	func_switch10
	cmp	word ptr cfg_switchbuf[bx],cx
	 jne	func_switch07
	cmp	word ptr cfg_switchbuf+2[bx],dx
	 je	func_switch11
func_switch07:
	cmp	di,SWITCH_MAX
	 jae	func_switch11
	inc	di
	add	bx,5
	jmp	short func_switch06
func_switch10:
	cmp	configpass,1
	 ja	func_switch12
	inc	di
	mov	cfg_switchnum,di
func_switch11:
	cmp	configpass,1
	 ja	func_switch12
	mov	word ptr cfg_switchbuf[bx],cx
	mov	word ptr cfg_switchbuf+2[bx],dx
	mov	cfg_switchbuf+4[bx],al
	jmp	short func_switch15
func_switch12:
	mov	al,cfg_switchbuf+4[bx]
func_switch15:
	cbw				; AX = lines to skip
	xchg	ax,cx			; make CX the loop count
	 jcxz	func_switch30
	mov	bx,si			; BX -> saved command line start
func_switch20:
	push	bx
	push	cx
	mov	di,offset dev_name	; copy and discard a label
	call	copy_file
	pop	cx
	pop	bx
	 jc	func_switch40		; ignore if any problems
	push	bx
	push	cx
	call	separator		; look for ','
	pop	cx
	pop	bx
	 jc	func_switch40		; stop at end of line
	loop	func_switch20
func_switch30:
	jmp	func_gosub		; execute a GOSUB

func_switch40:
	mov	si,bx			; retract to start of line
	jmp	func_switch		;  then back to sleep again

func_gosub:		; GOSUB="label"
;----------
	pop	ax			; get return address
	mov	bx,cfg_seeklo		; get existing offset
	mov	cx,cfg_seekhi		;  in CONFIG file
	sub	bx,cfg_tail		; work out begining of buffer
	sbb	cx,0
	add	bx,cfg_head		; add in current offset in buffer
	adc	cx,0
	push	bx			; save as position to RETURN to
	push	cx
	push	ax			; save return address again
	call	func_goto		; try to GOTO label
	 jc	func_return
	ret				; RET, with old offset on stack

func_return:		; RETURN [n]
;-----------
	pop	bx			; get return address
	cmp	sp,save_sp		; is anything on stack ?
	 jae	func_return20		; no, cannot RETURN
	pop	cfg_seekhi
	pop	cfg_seeklo		; restore position in file
	mov	cfg_tail,0		; force a read
	push	bx
	call	atoi			; returning a value ?
	pop	bx
	 jnc	func_return10		; default to 0
	xor	ax,ax
func_return10:
	mov	error_level,ax		; return result in error level
func_return20:
	push	bx			; save return address
	ret				;  and return to it

func_goto:		; GOTO="label"
;---------
	mov	di,offset dev_name	; Copy the label into a 
	mov	byte ptr [di],0		; local buffer and zero terminate
	call	copy_file
	 jc	func_goto10		; ignore if any problems

	mov	cfg_seeklo,0		; Seek to start of file
	mov	cfg_seekhi,0
	mov	cfg_tail,0		; force a re-read

func_goto5:
	call	readline		; read in a line
	 jc	func_goto10		; stop if end of file
	call	strupr			; upper case possible label
	mov	bx,offset cfg_buffer
	cmp	ds:byte ptr [bx],':'		; is it a label ?
	 jne	func_goto5		; no, try next line
	mov	si,offset dev_name
func_goto6:
	inc	bx			; next char in possible label
	lodsb				; get a character
	test	al,al			; end of label ?
	 je	func_goto10		; we have a match !
	cmp	al,ds:byte ptr [bx]	; does it match
	 jne	func_goto5		; no, try next line
	jmp	short func_goto6	; yes, look at next character
func_goto10:
	ret

func_exit:
; Stop processing CONFIG.SYS
	call	readline		; read in a line
	 jnc	func_exit		;  until we can read no more..
	ret

func_cls:
; CLEAR SCREEN
; This is PC specific - sorry
	mov	ah,15			; get current
	int	10h			; screen mode
	xor	ah,ah
	int	10h			; reset it to clear screen
	ret

func_cpos:
; Set cursor position
	call	atoi			; AX = row
	 jnc	func_cpos10		; check for error
	xor	ax,ax			; default to top left
	jmp	short func_cpos40
func_cpos10:
	push	ax			; save row
	call	separator		; look for ','
	 jc	func_cpos20		; no col specified
	call	atoi			; get col
	 jnc	func_cpos30
func_cpos20:
	mov	ax,1			; default to left
func_cpos30:
	pop	dx
	mov	ah,dl			; AH = row, AL = col
	sub	ax,0101h		; compensate for being one based
func_cpos40:
	xchg	ax,dx			; DH = row, DL = col
	xor	bx,bx			; page zero
	mov	ah,2			; set cursor position
	int	10h			; Eeeek!! call the ROS
	ret

func_colour:				; Set fore-/background/border colour
	push	es
	call	comma			; check for leading ','
	 jnc	func_colour10		; no fg col set, skip to bg
	call	atoi			; else get foreground colour code
	 jc	func_colour30		; no numerical value follows, skip
	and	al,15			; only 0-15 supported
	les	bx,dword ptr condev_off	; store in console driver
	mov	es:byte ptr 24[bx],1	; and mark COLOUR as active
	mov	es:25[bx],al
	call	separator		; more to set?
	 jc	func_colour30		; no
func_colour10:
	call	comma			; another comma following?
	 jnc	func_colour20		; then skip to next section
	call	atoi			; get value
	 jc	func_colour30		; none found, done
	and	al,15			; mask to 0-15
	mov	cl,4			; * 16
	shl	al,cl
	les	bx,dword ptr condev_off	; store in console driver
	mov	es:byte ptr 24[bx],1	; mark COLOUR as active
	or	es:25[bx],al
	call	separator		; finished now?
	 jc	func_colour30		; it seems so
func_colour20:
	call	atoi			; else get border colour
	 jc	func_colour30		; if there is one
	and	al,15			; only use lower four bits
	les	bx,dword ptr condev_off	; store in console driver
	mov	es:byte ptr 24[bx],1	; mark COLOUR as active
	or	es:26[bx],al
	mov	bh,al			; and set border colour right away
	mov	ax,1001h
	int	10h
func_colour30:
	les	bx,dword ptr condev_off	; get address of console driver
	cmp	es:byte ptr 24[bx],1	; check if any colour was changed
	 jne	func_colour40		; apparently not
	mov	bl,es:byte ptr 25[bx]	; else get the fg/bg colour
	call	col_screen		; and apply it to the whole screen
func_colour40:	
	pop	es			; done
	ret

col_screen:
	mov	ah,0fh			; get current screen page
	int	10h			; screen page in BH
	mov	ah,3			; get cursor position
	int	10h
	push	dx

	mov	si,40h			; BIOS data segment
	mov	es,si
	xor	si,si
	xor	dx,dx			; start in upper left corner
	mov	cx,1			; only one char per time
col_screen10:
	push	es
	push	si
	mov	ah,2			; set cursor position
	int	10h
	mov	ah,8			; read character with colour
	int	10h			; AL = char, AH = colour
	mov	ah,9			; write char back, BL = colour
	int	10h
	pop	si
	pop	es
	inc	dl			; mov to next column
	cmp	dl,es:4ah[si]		; already at the end of the line?
	 jne	col_screen10		; no, do it again
	xor	dl,dl			; else continue at first column
	inc	dh			; in next line
	cmp	dh,es:84h[si]		; already last in last line
	 jbe	col_screen10		; not finished, yet

	pop	dx
	mov	ah,2			; restore cursor position
	int	10h
	ret

func_timeout:
; set TIMEOUT for keyboard input
	call	atoi			; AX = # timeout count
	 jnc	func_timeout10		; check for error
	xor	ax,ax			; bad values mean no timeout
func_timeout10:
	mov	keyb_timeout,ax		; save timeout count
	call	separator		; look for ','
	 jc	func_timeout20
	lodsb				; get default query char
	cmp 	al,LF
	je 	func_timeout20
	cmp 	al,CR
	je 	func_timeout20
	mov	default_query_char,al
	call	separator		; look for ','
	 jc	func_timeout20
	lodsb				; get default switch char
	cmp 	al,CR
	je 	func_timeout20
	cmp 	al,LF
	je 	func_timeout20
	mov	default_switch_char,al
func_timeout20:
	ret

func_error:
; ERROR='n'
	call	atoi			; AX = error count to match
	 jc	func_error10
	mov	error_level,ax		; set error level
func_error10:
	ret

func_onerror:
; ONERROR='n' optional command
;
	call	whitespace		; Scan off all white space
	xor	bx,bx			; index relationship = 1st item
	xor	dx,dx			; DX is bit to set
func_onerror10:
	or	bx,dx			; set reationship bit
	lodsb				; now process a character
	mov	dx,2
	cmp	al,'='			; if '=' set bit 1
	 je	func_onerror10
	mov	dx,4
	cmp	al,'<'			; if '<' set bit 2
	 je	func_onerror10
	mov	dx,8
	cmp	al,'>'			; if '>' set bit 3
	 je	func_onerror10
	dec	si			; point at char
	push	bx			; save relationship
	call	atoi			; AX = error count to match
	pop	bx			; recover relationship
	 jc	func_onerror20
	cmp	error_level,ax		; is it the error level we want ?
	jmp	cs:func_onerror_tbl[bx]	; jump to handler
func_onerror20:
	ret

func_onerror_tbl:
	dw	func_onerror_eq		; . . .
	dw	func_onerror_eq		; . . =
	dw	func_onerror_lt		; . < .
	dw	func_onerror_le		; . < =
	dw	func_onerror_gt		; > . .
	dw	func_onerror_ge		; > . =
	dw	func_onerror_ne		; > < .
	dw	func_onerror_take	; > < =
	
func_onerror_eq:
	 je	func_onerror_take
	ret

func_onerror_ne:
	 jne	func_onerror_take
	ret

func_onerror_lt:
	 jb	func_onerror_take
	ret

func_onerror_le:
	 jbe	func_onerror_take
	ret

func_onerror_gt:
	 ja	func_onerror_take
	ret

func_onerror_ge:
	 jae	func_onerror_take
	ret

func_onerror_take:
	pop	ax			; discard return address
	xor	ax,ax			; boot key options = none
	jmp	cfg_continue		; and execute this command



func_query:
; ?optional command
	cmp	boot_options,F5KEY	; if F5 has been pressed then
;	 je	func_query50		;  do nothing
	 jne	func_query05
	jmp	func_query50
func_query05:
	call	whitespace		; discard any following whitespace
	lodsb				; get a character	
	cmp	al,'?'			; is it another '?', is so swallow it
	 je	func_query		;  and go round again
	dec	si			; it wasn't a '?', forget we looked
	mov	dl,1			; assume execution in main phase
	push	si
	push	dx
	call	scan			; scan the command list
	pop	dx
	pop	si
	 jc	func_query06
	mov	dx,CFG_FLAGS[di]	; flags for this config command
	cmp	configpass,0		; CF_ALL does not include pass 0
	 je	func_query06
	test	dx,CF_ALL		; present in all phases?
	 jnz	func_query07		; yes, proceed with query
func_query06:
	and	dl,CF_NOF-1		; config pass to execute in
	cmp	dl,configpass		; does the phase number match?
	 je	func_query07		; yes, proceed with query
	stc
	jmp	func_query50		; no, no need to ask for it
func_query07:
	push	si			; save current position
	lodsb				; get next real char
	xor	cx,cx			; assume no prompt string
	cmp	al,'"'			; '?"user prompt"' - keep silent as
	 jne	func_query10		; user has supplied prompt
	xchg	ax,cx			; CL = " if user prompt
	lodsb
func_query10:
	cmp	al,cl			; is this the user prompt char ?
	 je	func_query20		;  then stop now
	xchg	ax,dx			; DL= character
	mov	ah,MS_C_WRITE
	int	DOS_INT			; output the character
	lodsb
	cmp	al,CR			; is it the end of the line ?
	 jne	func_query10		;  no, do another character
	mov	ah,MS_C_WRITESTR	; Output msg of form " (Y/N) ? "
	mov	dx,offset confirm_msg1
	int	DOS_INT			; do " ("
	mov	ah,MS_C_WRITE
	mov	dl,yes_char
	int	DOS_INT			; do "Y"
	mov	dl,'/'
	int	DOS_INT			; do "/"
	mov	dl,no_char
	int	DOS_INT			; do "N"
	mov	ah,MS_C_WRITESTR
	mov	dx,offset confirm_msg2
	int	DOS_INT			; do ") ? "
func_query20:
	 jcxz	func_query30		; if no user supplied prompt
	pop	ax			; don't discard original starting
	push	si			;  position
func_query30:
	call	wait_for_key		; wait until a key is pressed
	mov	al,default_query_char	; if we timeout default
	 jc	func_query40
	mov	ah,MS_C_RAWIN
	int	DOS_INT			; read a char
	test	al,al			; is it a function key ?
	 jnz	func_query40
	mov	ah,MS_C_RAWIN
	int	DOS_INT			; throw away function keys
;    jmps    func_query30
func_query40:
	cmp	al,13			; accept <CR> for 'yes'
	 jne	func_query41
	mov	al,yes_char
	jmp	short func_query45
func_query41:
	cmp	al,32			; accept <SPACE> for 'no'
	 jne	func_query42
	mov	al,no_char
	jmp	short func_query45
func_query42:
	call	toupper
	cmp	al,yes_char
	 je	func_query45
	cmp	al,no_char
	 je	func_query45
	mov	ah,MS_C_WRITE
	mov	dl,7
	int	DOS_INT
	jmp	short func_query30
func_query45:
	push	ax			; save response
	mov	ah,MS_C_WRITE
	mov	dl,al
	int	DOS_INT			; echo the char
	mov	ah,MS_C_WRITESTR
	mov	dx,offset confirm_msg3
	int	DOS_INT			; now do CR/LF to tidy up
	pop	ax
;	call	toupper			; make response upper case
	pop	si			; recover starting position
	cmp	al,yes_char
	 jne	func_query50
	pop	ax			; Discard Return Address
	xor	ax,ax			; boot key options = none
	jmp	cfg_continue		; Execute the command
func_query50:
	ret				; Return without Executing Command



func_getkey:				; GETKEY
	call	wait_for_key		; wait until a key is pressed
	mov	ax,CONFIG_ERRLVL	; assume we have timed out
	 jc	func_getkey10		; ignore if timeout
	mov	ah,MS_C_RAWIN
	int	DOS_INT			; read a char
	xor	ah,ah			; convert to word
func_getkey10:
	mov	error_level,ax
	ret

func_version:				; VERSION=x.xx,x.xx
	call	comma			; check for leading ','
	 jnc	func_version20		; if yes, then skip to true version
	xor	dx,dx
	call	atoi			; get major version number
	 jc	func_version40		; no numerical value
	test	ax,ax
	 jz	func_version40
	mov	dl,al
	call	dot			; check for '.'
	 jc	func_version10
	call	atoi			; get minor version number
	 jc	func_version40
	mov	dh,al
func_version10:
	push	es
	push	bx
	mov	es,dos_dseg
	mov	bx,0d12h		; use as new DOS version
	mov	es:[bx],dx
	pop	bx
	pop	es
	call	separator		; check for ','
	 jc	func_version40
func_version20:
	xor	dx,dx
	call	atoi			; get major version number
	 jc	func_version40		; no numerical value
	test	ax,ax
	 jz	func_version40
	mov	dl,al
	call	dot			; check for '.'
	 jc	func_version30
	call	atoi			; get minor version number
	 jc	func_version40
	mov	dh,al
func_version30:
	push	es
	push	bx
	mov	es,dos_dseg
	mov	bx,0d10h		; use as new DOS version
	mov	es:[bx],dx
	pop	bx
	pop	es
func_version40:
	ret
	
;	CONFIG_ERROR is the global error handler for the CONFIG.SYS
;	commands. It is called with SI pointing to the CR/LF terminated string
;	that caused the error and with DX pointing to an "informative" error
;	message.
;
;	On Entry:- 	AL	Terminating Character
;			DX	Offset of Error Message
;			SI	0000 No Message to display
;				Offset of AL terminated string
;
config_error:

if ADDDRV
	mov	error_flag,1
endif

	push	ax
	mov	ah,MS_C_WRITESTR	; Print the Error Message
	int	DOS_INT			; passed in DX
	pop	ax

	mov	ah,al			; AH = terminating character
	test	si,si			; display the failing string ?
	 jz	cfg_e20			;  YES then scan for terminator
cfg_e10:
	lodsb				; get char to display
	cmp	al,ah			; have we reached the terminator ?
	 je	cfg_e20
	xchg	ax,dx			; DL = character to display
	mov	ah,MS_C_WRITE		; print a character at a time
	int	DOS_INT
	xchg	ax,dx			; terminator back in AH
	jmp	short cfg_e10
cfg_e20:
;;	jmp	crlf			; Terminate with a CRLF

	Public	crlf
crlf:
	push	dx
	mov	dx,offset msg_crlf	; Print a CR LF
	mov	ah,MS_C_WRITESTR
	int	DOS_INT
	pop	dx
	ret

;
;	Scan the command table for a match with the first entry in the
;	CR/LF terminated string passed in SI
scan:
	call	whitespace		; scan off all white space
	push	bx			; save the CONFIG Handle
	mov	bx,offset cfg_table - CFG_SIZE

scan_10:
	add	bx,CFG_SIZE		; bx -> next entry in table
	mov	di,CFG_NAME[bx]		; es:di -> next entry name
	test	di,di			; end of table ?
	stc				; assume so
	 jz	scan_exit		; Yes Exit with the Carry Flag Set
	push	si			; Save the String Offset
	call	compare
	pop	ax			; Remove String Address
	 jnc	scan_20			; String Matched
	xchg	ax,si			; Restore the original String Address
	jmp	short scan_10		; and test the next entry

scan_20:
	and	CFG_FLAGS[bx],not CF_QUERY
	test	CFG_FLAGS[bx],CF_LC	; should we upper case line ?
	 jnz	scan_50			;  skip if not
	xchg	ax,si
	call	strupr			; upper case the command line
	xchg	ax,si
scan_30:
	call	whitespace		; Scan off all white space before and
	lodsb				;  after the option '=' character
	cmp	al,'?'			; are we querying things ?
	 jne	scan_40
	or	CFG_FLAGS[bx],CF_QUERY	; remember the query, now go and
	jmp	short scan_30		;  remove any other whitespace
scan_40:
	cmp	al,'='			; '=' character.
	 je	scan_30
	dec	si
scan_50:
	mov	di,bx			; Save the Table Entry
	xor	ax,ax			; and exit with the Carry Flag Reset
scan_exit:
	pop	bx
	ret

; Compare two strings in case insensitive manner
; On Entry:
;	ds:si -> String 1 (upper/lower case, length determined by string 2)
;	es:di -> String 2 (uppercase, null terminated)
; On Exit:
;	Carry clear:	strings are the same
;	ds:si -> character immediately following end of string 1
;	es:di -> character immediately following end on string 2
;
;	Carry set:	strings different
;	ds:si -> As on entry
;	es:di -> undefined
;
compare:
;-------
	push	bx
	push	si			; save starting position
compare10:
	mov	al,es:[di]		; al = next character 
	inc	di
	test	al,al			; end of string 2 yet ?
	 jz	compare40		; yes, strings must be equal
	call	dbcs_lead		; DBCS lead byte?
	 jnz	compare20		;  no
	mov	ah,al
	lodsb				; is 1st byte of pair the same ?
	cmp	al,ah
	 jne	compare30
	cmpsb				; is 2nd byte of pair equal ?
	 jne	compare30
	jmp	short compare10
compare20:
	call	toupper			; just uppercase this byte
	xchg	ax,bx			; BL = string2 character
	lodsb				; al = next char in string 1
	call	toupper			; (can't be KANJI if it matches)
	cmp	al,bl			; check the characters are
	 je	compare10		;  identical stop the compare 
compare30:
	stc				; on a mismatch and set CY
compare40:
	pop	bx			; recover starting position
	 jnc	compare50
	mov	si,bx			; SI = original start
compare50:
	pop	bx
	ret


separator:
;---------
; On Entry:
;	DS:SI -> string
; On Exit:
;	DS:SI -> next option
;	CY set if end of line
;
; Strips off all whitespace, and the optional ','
; CY set at end of line
	call	whitespace			; deblank string and
	lodsb					;  check for ',' separator
	cmp	al,','				;  discarding if found
	 je	separator10
	cmp	al,CR				; end of the line ?
	stc					; assume so
	 je	separator10
	dec	si				; something else, leave alone
	clc					; not end of line
separator10:
	ret

separator20:
	call	whitespace			; strip of following spaces
	clc					; not end of line
	ret

dot:
;---------
; On Entry:
;	DS:SI -> string
; On Exit:
;	DS:SI -> next option
;	CY set if '.' not found
;
; Strips off all whitespace, and the optional '.'
	call	whitespace			; deblank string and
	lodsb					;  check for '.' separator
	cmp	al,'.'				;  discarding if found
	 je	dot10
	dec	si
	stc					; else set carry
dot10:
	ret

comma:
;---------
; On Entry:
;	DS:SI -> string
; On Exit:
;	DS:SI -> next option
;	CY set if ',' not found
;
; Strips off all whitespace, and the optional ','
	call	whitespace			; deblank string and
	lodsb					;  check for ',' separator
	cmp	al,','				;  discarding if found
	 je	comma10
	dec	si
	stc					; else set carry
comma10:
	ret

strupr:
;------
; Uppercase a null terminated string.
; Entry
;	ds:si ->	null terminated string
; Exit
;	none		(string is uppercased)
; Lost
;	no registers changed


	push	si
	push	ax

spr_loop:
	mov	al, [si]		; al = next byte from string
	test	al, al			; end of string?
	jz	spr_done		;  yes - exit
	
;	cmp	al,' '			; BAP. End at first space
;	je	spr_done		; or comma or slash
;	cmp	al,','			; so that parameters
;	je	spr_done		; are not uppercased
;	cmp	al,'/'			; Took out again cos it caused
;	je	spr_done		; problems with labels (I think).

	call	dbcs_lead		; DBCS lead byte?
	jnz	spr_not_dbcs		;  no
	inc	si			;  yes - skip first and second bytes of
	inc	si			;  pair as they cannot be uppercased
	jmp	spr_loop		; loop round
spr_not_dbcs:

	call	toupper			; just uppercase this byte
	mov	[si], al		; return the result to the string
	inc	si
	jmp	spr_loop		; continue

spr_done:
	pop	ax
	pop	si
	ret


dbcs_lead:
;---------
; Return true if given byte is the first of a double byte character.
; Entry
;	al 	= byte to be tested
; Exit
;	Z Flag	= 1 - byte is a DBCS lead
;		  0 - byte is not a DBCS lead
; Lost
;	no registers changed


	push	ds
	push	si
	push	bx
	push	ax

; First get a pointer to the double byte lead table in the COUNTRY info.
	lds	si, dbcs_tbl		; ds:si -> double byte table
	inc	si
	inc	si			; skip table length

; Examine each entry in the table to see if it defines a range that includes
; the given character.
	mov	bl, al			; bl = byte to be tested
dbcs_loop:
	lodsw				; al/ah = start/end of range
	test 	ax, ax			; end of table?
	jz	dbcs_no			;  yes - exit (not in table)
	cmp	al, bl			; start <= bl?
	ja	dbcs_loop		;  no - try next range
	cmp	ah, bl			; bl <= end?
	jb	dbcs_loop		;  no - try next range

	cmp	al, al			; return with Z flag set
	jmp	dbcs_exit

dbcs_no:
	cmp	al, 1			; return with Z flag reset

dbcs_exit:
	pop	ax
	pop	bx
	pop	si
	pop	ds
	ret



toupper:
;-------
; Return the uppercase equivilant of the given character.
; The uppercase function defined in the international info block is 
; called for characters above 80h.
; Entry
;	al = character to uppercase
; Exit
;	al uppercased
; Lost
; 	no registers lost

	push	bx
	mov	bh, ah
	xor	ah, ah			; ax = character to be converted
	cmp	al, 'a'			; al < 'a'?
	jb	exit_toupper		;  yes - done (char unchanged)
	cmp	al, 'z'			; al <= 'z'?
	jbe	a_z			;  yes - do ASCII conversion
	cmp	al, 80h			; international char?
	jb	exit_toupper		;  no - done (char unchanged)

; ch >= 80h  -- call international routine
	call	dword ptr ctry_info+CI_CASEOFF
	jmp	exit_toupper

a_z:
; 'a' <= ch <= 'z'  -- convert to uppercase ASCII equivilant
	and	al, 0DFh

exit_toupper:
	mov	ah, bh
	pop	bx
	ret




;
;	Scan the string DS:SI for ON or OFF return with the carry flag set
;	on error or AL = 1 for ON and AL = 0 for OFF.
;
check_onoff:
	call	whitespace		; Deblank Command
	push	si
	mov	di,offset cmd_on	; es:di -> "ON"
	call	compare			; do we have an "ON"?
	mov	al,01			; Assume ON found
	jnc	chk_onoff10

	pop 	si
	push 	si			; Save String Location in Case of Error
	mov	di,offset cmd_off	; es:di -> "OFF"
	call	compare			; do we have an "OFF"?
	mov	al,0
	jnc	chk_onoff10		
	pop	si			; No match so return original address
	stc				; with the CARRY falg set.
	ret

chk_onoff10:
	pop	di			; Remove Old String address
	ret				; and return to caller 

atohex:
;------
; To convert a hex number in the form of an ASCII string to a 32 bit 
; integer.
;
; On Entry:
;	DS:SI -> ASCII hex number 
;		 (the end of the number is taken as the first non-digit)
; On Exit:
;	CY clear:	
;		DX:AX = converted number
;		ds:si -> first non-digit
;
;	CY set:	
;		Either the first character was not a digit
;		or the number could not be represented in 32 bits
;		ds:si -> point at which error occured
;		ax undefined
; Lost
;	no other register

	push	bx
	push	cx
	push	di
	call	whitespace			; Deblank Line
	mov	di,si				; save string start offset
	xor	dx,dx
	xor	bx,bx				; number is formed in DX:BX

atohex10:
	lodsb					; AL = next char from string
	call	toupper				; upper case it
	cmp	al,'A'
	 jb	atohex20
	cmp	al,'F'
	 ja	atohex20
	sub	al,'A'-10
	jmp	short atohex30
atohex20:
	sub	al, '0'
	 jc	atohex40			; stop if invalid character
	cmp	al, 9
	 ja	atohex40
atohex30:
	cbw					; AX = digit
	test	dh,0f0h				; will we overflow ?
	 jnz	atohex_error
	mov	cl,4
	push	bx				; save (top 4 bits)
	shl	bx,cl				; *16
	add	bx,ax				; add in new digit
	pop	ax
	rol	ax,cl				; top 4 bits to bottom 4 bits
	and	ax,000Fh			; isolate them
	shl	dx,cl
	add	dx,ax				; add in new digit
	jmp	atohex10

atohex40:
	dec	si				; forget the char we stopped on
	cmp	si, di				; was there at least one digit?
	 ja	atohex50			;  yes - exit with carry clear
atohex_error:
	stc					; set error flag
atohex50:
	xchg	ax,bx				; AX = result
	pop	di
	pop	cx
	pop	bx
	ret

atoi:
;----
; To convert a decimal number in the form of an ASCII string to a 16 bit 
; integer.
;
; Entry
;	ds:si -> ASCII decimal number 
;		 (the end of the number is taken as the first non-digit)
; Exit
;	Carry clear:	
;		ax = converted number
;		ds:si -> first non-digit
;
;	Carry set:	
;		Either the first character was not a digit
;		or the number could not be represented in 16 bits
;		ds:si -> point at which error occured
;		ax undefined
; Lost
;	no other register

	push 	bx
	push 	cx
	push 	dx
	push 	di
	call	whitespace			; Deblank Line
	mov	di, si				; save string start offset
	mov	cx, 10				; for multiply
	xor	ax, ax				; number is formed in ax

atoi_loop:
	mov	bl, [si]			; bl = next char from string
	sub	bl, '0'
	jc	atoi_done
	cmp	bl, 9
	ja	atoi_done
	xor	bh, bh				; bx = next digit

	mul	cx				; ax = 10 * ax
	jc	exit_atoi			; check for 16 bit overflow
	add	ax, bx				; ax = (10 * ax) + bx
	jc	exit_atoi
	
	inc	si				; ds:si -> next char in string
	jmp	atoi_loop

atoi_done:
	cmp	si, di				; was there at least one digit?
	jne	exit_atoi			;  yes - exit with carry clear
	stc					;  no - set error flag

exit_atoi:
	pop 	di
	pop 	dx
	pop 	cx
	pop 	bx
	ret

atol:
;----
; To convert a decimal number in the form of an ASCII string to a 32 bit 
; integer.
;
; Entry
;	ds:si -> ASCII decimal number 
;		 (the end of the number is taken as the first non-digit)
; Exit
;	CY clear:	
;		DX:AX = converted number
;		ds:si -> first non-digit
;
;	CY set:	
;		Either the first character was not a digit
;		or the number could not be represented in 32 bits
;		ds:si -> point at which error occured
;		ax undefined
; Lost
;	no other register

	push	bx
	push	cx
	push	di
	call	whitespace			; Deblank Line
	mov	di, si				; save string start offset
	xor	ax, ax				; number is formed in
	cwd					;  DX/AX
	
atol10:
	xor	bx,bx				; use CX/BX for next digit
	xor	cx,cx
	mov	bl,[si]				; BL = next char from string
	sub	bl,'0'
	 jc	atol20
	cmp	bl, 9				; validate digit
	 ja	atol20
	add	ax,ax
	adc	dx,dx				; * 2
	 jc	atol30
	add	bx,ax				; * 2 + new digit
	adc	cx,dx
	 jc	atol30
	add	ax,ax
	adc	dx,dx				; * 4
	 jc	atol30
	add	ax,ax
	adc	dx,dx				; * 8
	 jc	atol30
	add	ax,bx				; * 10 + new digit
	add	dx,cx
	 jc	atol30
	inc	si				; ds:si -> next char in string
	jmp	atol10

atol20:
	cmp	si,di				; was there at least one digit?
	 jne	atol30				;  yes - exit with carry clear
	stc					;  no - set error flag
atol30:
	pop	di
	pop	cx
	pop	bx
	ret

readline:
;--------
; On Entry:
;	None
; On Exit:
;	DS:SI -> line in buffer
;	CY set if we have a problem (eg at EOF)
;
	mov	cx,CFG_BUF_LEN-2	; Read the next command line
	mov	di,offset cfg_buffer	; into the CFG_BUFFER
	mov	si,di			; Save the Destination String
					; address
read_l10:
	call	getchar			; al = next char from file
	cmp 	al,CR
	jz 	read_l10		; end of line ?
	cmp 	al,LF
	jz 	read_l10		; end of line ?
	cmp 	al,EOF
	jne 	read_l20		; end of file ?
	stc				; indicate a problem
	ret

read_l20:
	stosb				; put next char into the buffer
	call	getchar			; al = next char from file

	cmp 	al,EOF
	jz 	read_l30		; end of file ?
	cmp 	al,CR
	jz 	read_l30		; end of line ?
	cmp 	al,LF
	jz 	read_l30		; end of line ?
	loop	read_l20		; loop while space remains

; If we fall through to this point the line is too long. Make it a comment.
	mov	di, si			; ds:di -> start of buffer
	mov 	al, ';'
	stosb				; place ';' at buffer start
	mov	cx, 1			; get another one character
	jmp	short read_l20		; loop until all of this line consumed

; At this point buffer contains a line of text from CCONFIG.SYS.
; Terminate it properly
read_l30:
	mov al,CR
	stosb				; terminate line with CR
	mov al,LF
	stosb				; and a LF
	xor al,al
	stosb				; Reset the Carry Flag
	ret

getchar:
	mov	bx,cfg_head		; we are here in the buffer
	cmp	bx,cfg_tail		; are there any more characters ?
	 jae	getchar10		; no, read some in from disk
	push	ds
	mov	ds,init_dseg
	mov	al,CONFIG_BUF[bx]	; get a character from the buffer
	pop	ds
	inc	cfg_head		; inc the pointer
	ret

getchar10:
; we need to read some characters from disk into our buffer
	push 	cx
	push 	dx			; Assume something will go wrong
	mov	cfg_tail,0		;  say nothing is in the buffer

	mov	ax,(MS_X_OPEN*256)+80h	; Open the configuration file
	mov	dx,offset cfg_file
	int	DOS_INT
	 jc	getchar40		; failure, return EOF

	mov	bx,ax
	mov	ax,(MS_X_LSEEK*256)+0
	mov	dx,cfg_seeklo
	mov	cx,cfg_seekhi
	int	DOS_INT			; seek to current file position
	 jc	getchar30		; failure to seek, close and exit

	mov	ah,MS_X_READ
	mov	cx,CONFIG_BUF_SIZE
	push	ds
	mov	ds,init_dseg
	mov	dx,offset CONFIG_BUF	; lets try and fill out buffer
	int	DOS_INT
	pop	ds
	 jc	getchar30
	mov	cfg_tail,ax		
	mov	ax,(MS_X_LSEEK*256)+1
	xor	dx,dx
	xor	cx,cx
	int	DOS_INT			; get current file position
	mov	cfg_seeklo,ax		;  and save for possible
	mov	cfg_seekhi,dx		;  future re-opens
getchar30:
	mov	ah,MS_X_CLOSE		; Close the CONFIG file
	int	DOS_INT
getchar40:
	mov	bx,cfg_tail		; now lets see if we filled the buffer
	cmp	bx,CONFIG_BUF_SIZE	;  if not its EOF so mark it as such
	 je	getchar50
	push	ds
	mov	ds,init_dseg
	mov	CONFIG_BUF[bx],EOF	; add an EOF mark
	pop	ds			;  in case there isn't one already
	inc	cfg_tail
	inc	cfg_seeklo
	 jnz	getchar50
	inc	cfg_seekhi
getchar50:
	push	ds
	mov	ds,init_dseg
	mov	al,ds:CONFIG_BUF	; return 1st char from buffer
	pop	ds
	mov	cfg_head,1		; remember we have returned char
	pop 	dx
	pop 	cx
	ret


;
; On a DEVICEHIGH we have encountered a line
; /L:r1[,s1][;r2[,s2]]... [/S]
; where r1 = load region, s1 = hex size in bytes, r2,s2 etc are further regions
; currently only r1/s1 are supported
; /S says the regions should m#be minimised

parse_region:
;On Entry:
;	DS:SI -> command line following '/L:'	
; On Exit:
;	DS:SI -> 1st non-parsed character
;	CY set on error
;
	call	atoi			; get a region to load in
	 jc	parse_region40
	mov	himem_region,ax		; remember region to try
	call	whitespace		; scan off all white space
	lodsb
	dec 	si			; now see is we have an optional size
	cmp	al,','			; have we a ',' character ?
	mov	ax,0			; assume minimum size not supplied
	 jne	parse_region30
	inc	si
	call	atol			; read number into DX:AX
	cmp	dx,15			; is number too big ?
	 ja	parse_region40
	mov	cx,16			; convert to para's
	div	cx
	inc	ax			; allow for round up
	inc	ax			;  and for header
	push	ax			; save size of region
parse_region10:
	mov	di,offset slashs_opt	; do we have a "/S" to minimise
	call	compare			;  the UMB's (ignore it if so)
	 jnc	parse_region20
	call	whitespace		; scan off all white space
	lodsb
	dec 	si			; strip off other regions
	cmp	al,';'			; another region follows ';'
	 jne	parse_region20
	inc	si
	call	atoi			; eat the region number
	 jc	parse_region20
	call	whitespace		; scan off all white space
	lodsb
	dec 	si
	cmp	al,','			; is a size specified ?
	 jne	parse_region10		; no, check for another region
	inc	si
	call	atol			; eat the size
	 jnc	parse_region10
parse_region20:
	pop	ax
parse_region30:
	clc				; we can proceed
	ret

parse_region40:
	mov	himem_size,0FFFFh	; 1 MByte wanted (ho, ho)
	stc				; we had problems..
	ret

; On a DEVICEHIGH we may encounter a line
; SIZE [=] s
; where s = size of region in hex bytes

parse_size:
;On Entry:
;	DS:SI -> command line following '/L:'	
; On Exit:
;	DS:SI -> 1st non-parsed character
;	CY set on error
;
	call	whitespace		; Scan off all white space
	lodsb				; before and after the optional
	cmp	al,'='			; '=' character.
	 je	parse_size
	dec	si
	call	atohex			; read hex number into DX:AX
	 jc	parse_size10
	cmp	dx,15			; is number too big ?
	 ja	parse_size20		; just load low	
	mov	cx,16			; convert to para's
	div	cx
	inc	ax			; allow for round up
	inc	ax			;  and for header
	mov	himem_size,ax		; remember size required
parse_size10:
	clc
	ret

parse_size20:
	mov	himem_size,0FFFFh	; 1 MByte wanted (ho, ho)
	stc
	ret


; A size has not been suppleied with DEVICEHIGH, so guess-timate one
; based on file size

size_file:
; On Entry:
;	DS:SI -> filename
; On Exit:
;	DS:SI preserved
;
	push	si
	mov	di,offset dev_name	; copy the device filename into a
	mov	byte ptr [di],0		;  local buffer and zero terminate
	call	copy_file
	pop	si
	mov	ax,(MS_X_OPEN * 256)+0	; open file r/o
	mov	dx,offset dev_name
	int	DOS_INT
	 jnc	size_file10
	mov	ax,0FFFFh		; can't open file, force low to prevent
	ret				;  two sets of error messages

size_file10:
	xchg	ax,bx			; handle in BX
	mov	ah,MS_X_READ
	mov	cx,EXE_LENGTH
	mov	dx,offset exeBuffer
	int	DOS_INT			; read in possible exe header
	 jc	size_file20
	cmp	ax,cx			; did we read all we wanted ?
	 jb	size_file40		; if not it can't be an EXE
	cmp	exeSignature,'ZM'	; check the signature
	 jne	size_file40		; if invalid can't be an EXE
	mov	ax,512
	mul	exeSize			; DX/AX bytes in image
	add	ax,exeFinal
	adc	dx,0
	mov	cx,16
	cmp	dx,cx			; are we too big ?
	 jae	size_file20		; yes, force low
	div	cx			; AX = para's required
	inc	ax			; one for rounding error
	 jz	size_file20
	add	ax,exeMinpara		; add on extra para's required
	 jnc	size_file30
size_file20:
	mov	ax,0FFFFh		; problems, force a load low
size_file30:
	push	ax			; save para's required
	mov	ah,MS_X_CLOSE		; close this file
	int	DOS_INT
	pop	ax			; AX para's required
	ret

size_file40:
	mov	ax,(MS_X_LSEEK * 256)+2
	xor	cx,cx			; now find out how big the file is
	xor	dx,dx			;  by seeking to zero bytes from end
	int	DOS_INT
	 jc	size_file20
	mov	cx,16
	cmp	dx,cx			; are we too big ?
	 jae	size_file20		; yes, force low
	div	cx			; AX = para's required
	inc	ax			; one for rounding error
	jmp	short size_file30

himem_setup:
; On Entry:
;	AX = minimum amount of upper memory required (in para's)
; On Exit:
;	CY clear if able to satisfy request
;	CY set on error (we then load low)
;
; try and find some hi memory
; we allocate the biggest available chunk of upper memory
;
	push	es
	mov	cx,ax			; CX = para's required
	mov	ax,mem_current_base
	mov	himem_current_base,ax	; save mem_current_base
	mov	ax,mem_current
	mov	himem_current,ax	; save mem_current
	mov	ax,mem_max
	mov	himem_max,ax		; save mem_max
	mov	ah,MS_M_ALLOC
	mov	bx,0FFFFh		; give me all memory (please)
	int	21h			; bx = No. of paras available
	cmp	bx,cx			; do we have enough ?
	 jc	himem_setup40		; no, give up now

	cmp	himem_region,0		; is there a region specified ?
	 je	himem_setup20		; no, allocate largest block

; Allocate the region specified by /L:
	les	bx,func52_ptr		; ES:BX -> list of lists
	mov	ax,es:F52_DMD_UPPER[bx]	; get upper memory link
	cmp	ax,0FFFFh		; make sure there is one
	 je	himem_setup20		; shouldn't happen....
	mov	es,ax
himem_setup10:
	cmp	es:DMD_ID,'M'		; is there another block ?
	stc				; if we run out of blocks then
	 jne	himem_setup40		;  we load low
	mov	es,ax			; ES -> DMD
	mov	bx,es:DMD_LEN		; get length in para'a
	inc	ax
	add	ax,bx			; AX -> next DMD
	cmp	es:DMD_PSP,0		; is it free ?
	 jne	himem_setup10		; no, try the next
	dec	himem_region		; found the right region yet ?
	 jnz	himem_setup10
	cmp	bx,cx			; do we have enough ?
	 jc	himem_setup40		; no, go low
	mov	ax,es			; ES -> DMD header to allocate
	inc	ax
	mov	es,ax			; ES -> data in block
	mov	ah, MS_M_SETBLOCK
	int	21h			; "allocate" this block
	mov	ax,es
	 jnc	himem_setup30		; this can only fail if DMD chain
	jmp	short himem_setup40	;  is corrupt...

himem_setup20:
; allocate the largest block available for DEVICEHIGH
	mov	ah, MS_M_ALLOC
	mov	bx, 0FFFFh		; give me all memory (please)
	int	21h			; bx = No. of paras available
	mov	ah, MS_M_ALLOC		; give me bx paras please
	int	21h			; ax:0 -> my memory
	 jc	himem_setup40		; woops, what happened ?
himem_setup30:
	mov	mem_current_base,ax
	mov	mem_current,ax		; save base of himem area
	mov	mem_max,ax
	add	mem_max,bx		; top of himem area
himem_setup40:
	pop	es
	ret

himem_cleanup:
; clean up our high memory - this hook should free up any difference
; between himem_current and himem_max
	mov	ax,himem_max
	mov	mem_max,ax		; restore mem_max
	mov	ax,himem_current_base
	xchg	mem_current_base,ax	; restore mem_current_base
	mov	bx,himem_current
	xchg	mem_current,bx		; restore mem_current
	push	es
	mov	es,ax			; ES -> memory block
	sub	bx,ax			; has any memory been used ?
	 jz	himem_cleanup10
	mov	ah,MS_M_SETBLOCK	; try and shrink the block
	int	DOS_INT			; to the size we used
	pop	es
;	clc				; return success
	ret

himem_cleanup10:
	mov	ah,MS_M_FREE		; free it all up
	int	DOS_INT
	pop	es
	stc				; return an error
	ret

copy_asciiz:
;-----------
	lodsb				; get a character
	stosb				; copy it
	test	al,al			; is it the terminating NUL ?
	 jnz	copy_asciiz		; do next char
	ret

wait_for_key:
;------------
; On Entry:
;	None
; On Exit:
;	CY set if no key pressed within timeout
;
	mov	cx,keyb_timeout		; get timeout value
	clc				; assume no timeout
	 jcxz	wait_for_key30
wait_for_key10:
	push	cx
	mov	ah,MS_T_GETTIME		; get current time
	int	DOS_INT			;  so we can do timeout
	mov	bx,dx			;  save secs in BH
	pop	cx
wait_for_key20:
	mov	ah,MS_C_STAT		; is a character ready ?
	int	DOS_INT			; if so process it
	test	al,al			; do we have a character ?
	 jnz	wait_for_key30
	push	cx
	mov	ah,MS_T_GETTIME		; get current time
	int	DOS_INT			;  so we can do timeout
	pop	cx
	cmp	bh,dh			; have we timed out ?
	 je	wait_for_key20
	loop	wait_for_key10		; another second gone by
	stc				; we have timed out
wait_for_key30:
	ret

;
;	COPY_FILE copies the next parameter from DS:SI into the buffer
;	at ES:DI and terminates with a NULL character. The parameter is
;	expected to be a FileName. DS:SI are returned pointing to the 
;	next parameter in the command.
;
copy_file:
	call	whitespace	; DeBlank the Command Line
	mov	cx,MAX_FILELEN	; Limit FileName Length
	push	si		; Save SI in case of error
copy_f10:
	lodsb			; Copy upto the first Space or 
	cmp	al,' '		; Control Character
	 jbe	copy_f20
	cmp	al,','		; stop at ',' too
	 je	copy_f20
	cmp	al,'/'		; Also stop scanning when a switch 
	 je	copy_f20	; character is detected
	stosb
	loop	copy_f10
	pop	si		; Restore the original SI	
	mov	ax,13		; 13 = invalid data error
	stc			; and return with an error
	ret

copy_f20:
	pop	ax		; Remove Original String address
	dec	si		; Point at the failing character 
	xor	ax,ax
	stosb			; Zero Terminate FileName
	ret

INITCODE ends


INITDATA	segment public word 'INITDATA'

if ADDDRV
	extrn	err_no_command_file:byte
	extrn	err_block_device:byte
else
	extrn	shell:byte		; Default Command Processor
	extrn	shell_cline:byte	; Default Command Line
endif
	extrn	dev_epb:byte
	extrn	dev_count:byte
	extrn	rel_unit:word

	extrn	dos_target_seg:word
	extrn	bios_target_seg:word
	extrn	mem_current_base:word	; Current Base Address
	extrn	mem_current:word	; Current Load Address
	extrn	mem_max:word		; Top of Available Memory
	extrn	mem_size:word		; Real top of Memory

	extrn	init_dseg:word		; Current Init Data Segment
	extrn	res_ddsc_seg:word

include	initmsgs.def				; Include TFT Header File


;	extrn	bad_command:byte
;	extrn	bad_filename:byte

if not ADDDRV
;	extrn	bad_shell:byte
;	extrn	bad_country:byte
;	extrn	bad_lastdrive:byte
;	extrn	bad_break:byte
;	extrn	bad_buffers:byte
;	extrn	bad_files:byte
;	extrn	bad_fcbs:byte
;	extrn	bad_fopen:byte
;	extrn	bad_drivparm:byte
;	extrn	bad_history:byte
endif

;	extrn	yes_char:byte		; In BIOSMSGS.ASM
;	extrn	no_char:byte
	
	extrn	dev_load_seg:word
	extrn	dev_reloc_seg:word
	extrn	dev_epb:byte
	extrn	dev_name:byte
	extrn	dev_name:byte
	extrn	dosVersion:word
	extrn	strategy_off:word
	extrn	strategy_seg:word
	extrn	interrupt_off:word
	extrn	interrupt_seg:word
	extrn	request_hdr:byte
	extrn	next_drv:byte
	extrn	strategy_seg:word
	extrn	strategy:dword
	extrn	interrupt:dword
	extrn	func52_ptr:dword
	extrn	strategy_seg:word
	extrn	condev_off:word
	extrn	condev_seg:word
	extrn	clkdev_off:word
	extrn	clkdev_seg:word
	extrn	num_blkdev:byte
	extrn	blkdev_table:byte
	extrn	last_drv:byte
	extrn	next_drv:byte
	extrn	max_secsize:word
	extrn	max_clsize:word
	extrn	country_code:word
	extrn	code_page:word
	extrn	drdos_ptr:dword
	extrn	init_buf:byte
	extrn	num_read_ahead_buf:byte
	extrn	buffersIn:byte
	extrn	num_files:word
	extrn	num_fcbs:word
	extrn	num_fopen:word
	extrn	history_flg:byte	; In INIT code
	extrn	history_size:word	;
	extrn	num_stacks:word
	extrn	stack_size:word
	extrn	filesIn:byte
	extrn	stacksIn:byte
	extrn	lastdrvIn:byte
	extrn	hidosdata:byte
	extrn	hiddscs:byte
	extrn	hixbda:byte
	extrn	configpass:byte

if not ADDDRV
	extrn	hidos:byte
	extrn	bios_seg:word
	extrn	DeblockSetByUser:Byte
	extrn	DeblockSeg:word		; In BIOS data
endif

	extrn	dbcs_tbl:dword
	extrn	ctry_info:byte
	extrn	dos_dseg:word


	Public	cfg_file, cfg_file_end

preload_entry	label dword		; preload back door entry
		dw	14h		; offset is pre-initialised to 14h
preload_seg	dw	0

preload_ver	dw	10		; version to give DBLSPACE

	Public	preload_drv
preload_drv	db	0		; number of preload drives
alt_drive	db	0		; preload checks alternative drive,
					;   (only used loading from A:)

; The preload_file is used as is to open a preload device
; It is also used to initialise a "DMD" name, and the code to do this
; currently finds the "\" and then copies the next 8 characters.
; This works with the current names - any new names may require modifications

preload_file	dw	offset security_file	; initially '\SECURITY.BIN'
security_file	db	'\SECURITY.BIN',0
stacker_file	db	'C:\STACKER.BIN',0
dblspace_file	db	'C:\DBLSPACE.BIN',0

cfg_file	db	'DCONFIG.SYS',0	; Configuration File
		db	64 dup (0)	; space for bigger CHAIN'd file
cfg_file_end	label byte

	Public	cfg_seeklo,cfg_seekhi
cfg_seeklo	dw	0		; offset we have reached in CONFIG file
cfg_seekhi	dw	0		; in case Richards CONFIG file > 64k

	Public	cfg_head,cfg_tail
cfg_head	dw	0		; offset we are at in CONFIG_BUF
cfg_tail	dw	0		; # bytes currently in CONFIG_BUF

cfg_switchnum	dw	0		; number of SWITCH decisions stored
cfg_switchbuf	db	5*SWITCH_MAX dup (0)	; buffer for config lines/key presses

cfg_buffer	db	CFG_BUF_LEN dup (0)	; individual lines live here

;
;	EXEC parameter blocks for INSTALL function
;
exec_envseg	dw	0		; Environment Segment
exec_lineoff	dw	0		; Command Line Offset
exec_lineseg	dw	0		; Command Line Segment
exec_fcb1off	dw	0		; Offset of FCB 1 (5Ch)
exec_fcb1seg	dw	0		; Segment of FCB 1 (5Ch)
exec_fcb2off	dw	0		; Offset of FCB 2 (6Ch)
exec_fcb2seg	dw	0		; Segment of FCB 2 (6Ch)
		dd	2 dup (0)	; Initial SS:SP & CS:IP

system_sp	dw	0
system_ss	dw	0

ioctl_pb	label byte
ioctl_func	db	0		; special functions
ioctl_type	db	0		; device type (form factor)
ioctl_attrib	dw	0		; device attributes
ioctl_tracks	dw	0		; # of tracks
ioctl_mtype	db	0		; media type, usually zero
ioctl_bpb	db	31 dup (0)	; default BPB for this type of disk
ioctl_layout	dw	1+64 dup (0)	; support 64 sectors/track max.

drivp_drv	db	0		; drive 0-15
drivp_chg	db	0		; change line support
drivp_prm	db	0		; permanent media flag
drivp_ff	db	0		; form factor
drivp_trk	dw	80
drivp_spt	equ	word ptr ioctl_bpb+13
drivp_heads	equ	word ptr ioctl_bpb+15	; # of heads

ff_table	dw	bpb360, bpb1200, bpb720		; 360/1200/720 Kb
		dw	bpb243, bpb1200			; 8" sd/dd
		dw	bpb360, bpb360			; hard disk, tape
		dw	bpb1440				; 1440 Kb

bpb360	dw	512
	db	2
	dw	1
	db	2
	dw	112
	dw	40*2*9
	db	0FDh
	dw	2
	dw	9
	dw	2

bpb1200	dw	512
	db	1
	dw	1
	db	2
	dw	224
	dw	80*2*15
	db	0F9h
	dw	7
	dw	15
	dw	2

bpb720	dw	512			; bytes per sector
	db	2			; sectors/cluster
	dw	1			; FAT address
	db	2			; # of FAT copies
	dw	112			; root directory size
	dw	80*2*9			; sectors/disk
	db	0F9h			; media byte
	dw	3			; size of single FAT copy
	dw	9			; sectors per track
	dw	2			; # of heads

bpb1440	dw	512
	db	1
	dw	1
	db	2
	dw	224
	dw	80*2*18
	db	0F9h
	dw	7
	dw	18
	dw	2

bpb243	dw	128
	db	4
	dw	1
	db	2
	dw	64
	dw	77*1*26
	db	0E5h
	dw	1
	dw	26
	dw	1

msg_crlf	db	CR, LF
msg_dollar	db	'$'

cfg_table	label word
if not ADDDRV
	dw	cmd_country,	func_country,	1	; COUNTRY=nnn,nnn,country
	dw	cmd_shellhigh,	func_shell,	1	; SHELLHIGH=filename (SHELL alias FreeDOS compatibility)
	dw	cmd_shell,	func_shell,	1	; SHELL=filename
	dw	cmd_lastdrivehigh,func_hilastdrive,1	; LASTDRIVEHIGH=d:
	dw	cmd_lastdrive,	func_lastdrive,	1	; LASTDRIVE=d:
	dw	cmd_hilastdrive,func_hilastdrive,1	; HILASTDRIVE=d:
	dw	cmd_break,	func_break,	1	; BREAK=ON/OFF
	dw	cmd_buffershigh,func_hibuffers,	1	; BUFFERSHIGH=nn
	dw	cmd_buffers,	func_buffers,	1	; BUFFERS=nn
	dw	cmd_hibuffers,	func_hibuffers,	1	; HIBUFFERS=nn
	dw	cmd_fcbs,	func_fcbs,	1	; FCBS=nn
	dw	cmd_hifcbs,	func_hifcbs,	1	; HIFCBS=nn
	dw	cmd_fileshigh,	func_hifiles,	1	; FILESHIGH=nn
	dw	cmd_files,	func_files,	1	; FILES=nn
	dw	cmd_hifiles,	func_hifiles,	1	; HIFILES=nn
	dw	cmd_stacks,	func_stacks,	1	; STACKS=nn
	dw	cmd_histacks,	func_histacks,	1	; HISTACKS=nn
	dw	cmd_fastopen,	func_fastopen,	1	; FASTOPEN=nnn
	dw	cmd_drivparm,	func_drivparm,	1	; DRIVPARM=/d:nn ...
	dw	cmd_history,	func_history,	1	; HISTORY=ON|OFF,NNN
	dw	cmd_hiinstalllast,func_hiinstall,CF_LAST; HIINSTALLLAST=cmdstring
	dw	cmd_hiinstall,	func_hiinstall,	1	; HIINSTALL=cmdstring
	dw	cmd_installhigh, func_hiinstall, 1	; INSTALLHIGH=cmdstring
	dw	cmd_installlast,func_install,	CF_LAST	; INSTALLLAST=cmdstring
	dw	cmd_install,	func_install,	1	; INSTALL=cmdstring
	dw	cmd_hidos,	func_hidos,	1	; HIDOS=ON/OFF
	dw	cmd_dosdata,	func_dosdata,	1	; DOSDATA=UMB
	dw	cmd_ddscs,	func_ddscs,	1	; DDSCS=HIGH,UMB
	dw	cmd_xbda,	func_xbda,	1	; XBDA=LOW,UMB
	dw	cmd_dos,	func_dos,	1	; DOS=HIGH
	dw	cmd_set,	func_set,	1+CF_LC	; SET envar=string
	dw	cmd_switches,	func_switches,	CF_NOF	; SWITCHES=...
endif
	dw	cmd_hidevice,	func_hidevice,	1	; HIDEVICE=filename
	dw	cmd_devicehigh,	func_hidevice,	1	; DEVICEHIGH=filename
	dw	cmd_device,	func_device,	1	; DEVICE=filename
	dw	cmd_remark,	func_remark,	1+CF_NOF; REM Comment
	dw	cmd_semicolon,	func_remark,	1+CF_NOF; ; Comment
	dw	cmd_colon,	func_remark,	1+CF_NOF; :label
	dw	cmd_chain,	func_chain,	CF_ALL	; CHAIN=filename
	dw	cmd_goto,	func_goto,	CF_ALL	; GOTO=label
	dw	cmd_gosub,	func_gosub,	CF_ALL	; GOSUB=label
	dw	cmd_return,	func_return,	CF_ALL	; RETURN (from GOSUB)
	dw	cmd_cls,	func_cls,	1	; Clear Screen
	dw	cmd_cpos,	func_cpos,	1	; Set Cursor Position
	dw	cmd_colour,	func_colour,	1	; Set Fore-/Background/Border Colour
	dw	cmd_timeout,	func_timeout,	1	; set ? TIMEOUT
	dw	cmd_switch,	func_switch,	1+CF_ALL; SWITCH=n
	dw	cmd_onerror,	func_onerror,	1+CF_ALL+CF_LC; ONERROR='n' optional command
	dw	cmd_query,	func_query, CF_ALL+CF_NOF+CF_LC; ?optional command
	dw	cmd_echo,	func_echo,	1+CF_LC	; ECHO=string
	dw	cmd_exit,	func_exit,	CF_ALL	; EXIT
	dw	cmd_error,	func_error,	1+CF_ALL; ERROR='n'
	dw	cmd_getkey,	func_getkey,	1	; GETKEY
	dw	cmd_yeschar,	func_yeschar,	1	; YESCHAR=
	dw	cmd_deblock,	func_deblock,	1	; DEBLOCK=xxxx
	dw	cmd_numlock,	func_numlock,	1	; NUMLOCK=ON/OFF
	dw	cmd_version,	func_version,	1	; VERSION=x.xx
	dw	cmd_common,	func_common,	1	; [COMMON]
 	dw	0				; end of table

if not ADDDRV
cmd_country	db	'COUNTRY',0
cmd_shellhigh	db	'SHELLHIGH',0
cmd_shell	db	'SHELL',0
cmd_lastdrivehigh	db	'LASTDRIVEHIGH',0
cmd_hilastdrive db      'HI'            ;'HILASTDRIVE',0
cmd_lastdrive	db	'LASTDRIVE',0
cmd_break	db	'BREAK',0
cmd_buffershigh	db	'BUFFERSHIGH',0
cmd_hibuffers   db      'HI'            ;'HIBUFFERS',0
cmd_buffers	db	'BUFFERS',0
cmd_hifcbs      db      'HI'            ;'HIFCBS',0
cmd_fcbs	db	'FCBS',0
cmd_fileshigh	db	'FILESHIGH',0
cmd_hifiles     db      'HI'            ;'HIFILES',0
cmd_files	db	'FILES',0
cmd_histacks    db      'HI'            ;'HISTACKS',0
cmd_stacks	db	'STACKS',0
cmd_fastopen	db	'FASTOPEN',0
cmd_drivparm	db	'DRIVPARM', 0
cmd_history	db	'HISTORY', 0
cmd_hiinstall   db      'HI'            ;'HIINSTALL', 0
cmd_install	db	'INSTALL', 0
cmd_hiinstalllast       db 'HI'         ;'HIINSTALLLAST', 0
cmd_installlast	db	'INSTALLLAST', 0
cmd_installhigh	db	'INSTALLHIGH', 0
cmd_dosdata	db	'DOSDATA',0
cmd_ddscs	db	'DDSCS',0
cmd_xbda	db	'XBDA',0
cmd_hidos       db      'HI'            ;'HIDOS',0
cmd_dos		db	'DOS',0
cmd_set		db	'SET',0
cmd_switches	db	'SWITCHES',0
endif
cmd_devicehigh	db	'DEVICEHIGH',0
cmd_hidevice    db      'HI'            ;'HIDEVICE',0
cmd_device	db	'DEVICE',0
cmd_remark	db	'REM', 0
cmd_semicolon	db	';',0
cmd_colon	db	':',0
cmd_chain	db	'CHAIN',0
cmd_goto	db	'GOTO',0
cmd_gosub	db	'GOSUB',0
cmd_return	db	'RETURN',0
cmd_cls		db	'CLS',0
cmd_cpos	db	'CPOS',0
cmd_colour	db	'COLOUR',0
cmd_timeout	db	'TIMEOUT',0
cmd_switch	db	'SWITCH',0
cmd_query	db	'?',0
cmd_echo	db	'ECHO',0
cmd_exit	db	'EXIT',0
cmd_onerror     db      'ON'            ;'ONERROR',0
cmd_error	db	'ERROR',0
cmd_getkey	db	'GETKEY',0
cmd_yeschar	db	'YESCHAR',0
cmd_deblock	db	'DEBLOCK',0
cmd_numlock	db	'NUMLOCK',0
cmd_version	db	'VERSION',0
cmd_common	db	'[COMMON]',0

cmd_on		db	'ON',0
cmd_off		db	'OFF',0

confirm_msg1	db	' ($'
confirm_msg2	db	') ? $'
confirm_msg3	db	CR,LF,'$'

region_opt	db	'/L:',0
slashs_opt	db	'/S',0
size_opt	db	'SIZE',0
high_opt	db	'HIGH',0
low_opt		db	'LOW',0
noumb_opt       db      'NO'            ;'NOUMB',0
umb_opt		db	'UMB',0

himem_region	dw	0		; region to hidevice into
himem_size	dw	0		; minimum size wanted
himem_current	dw	0
himem_current_base dw	0
himem_max	dw	0

if ADDDRV
error_flag	db	0		;1 if error occurred during command
					;file processing, 0 otherwise
endif

default_query_char	db	CR
default_switch_char	db	'1'

keyb_timeout	dw	0		; default is no timeout
error_level	dw	0		; default is no error
save_sp		dw	0		; save SP here for GOSUB/RETURN's

INITDATA ends

INITENV		segment public para 'INITDATA'
Public envstart
envstart	db	250 dup (0)	; <<< initial env buffer, copied to seg 60
Public envend				; 
envend		dw	0		; make it double null terminated
		db	1Ah		; EOF marker env buffer
	Public	boot_options, boot_switches
boot_options	dw	0
boot_switches	db	0
; set by BIOS to either the SHIFT states, or to F5KEY or F8KEY
					; >>> end of range copied to seg 60
					;     may not exceed 256 bytes
EXE_LENGTH	equ	001Ch

exeBuffer	label word
exeSignature	dw	0	; 0000 Valid EXE contains 'MZ'
exeFinal	dw	0	; 0002 Image Length MOD 512
exeSize		dw	0	; 0004 Image Length DIV 512
exeRelcnt	dw	0	; 0006 No. of Relocation Items
exeHeader	dw	0	; 0008 Header Size in paragraphs
exeMinpara	dw	0	; 000A Minimum No extra paragraphs
exeMaxpara	dw	0	; 000C Maximum No of extra paragraphs
exeSS		dw	0	; 000E Displacment of Stack Segment
exeSP		dw	0	; 0010 Initial SP
exeChecksum	dw	0	; 0012 Negative CheckSum
exeIP		dw	0	; 0014 Initial IP
exeCS		dw	0	; 0016 Code Segment displacement
exeReloff	dw	0	; 0018 Byte Offset of First REL item
exeOverlay	dw	0	; 001A Overlay Number (0 == Resident)

INITENV ends

	end
