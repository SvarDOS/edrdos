;    File              : $HEADER.ASM$
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
;    $Log: $
;    HEADER.A86 1.26 94/12/02 09:34:18 
;    added FCB LRU counter and sharing flag    
;    HEADER.A86 1.24 94/11/15 08:53:04
;    Fixed the NWDOS.386 stuff. Still point at startupinfo, but take out the
;    vxdname and the vxdnameseg entries.
;    HEADER.A86 1.23 94/06/28 14:31:07
;    Fix last_key_ext bug
;    HEADER.A86 1.17 93/11/22 15:23:16 
;    Move idle data to instance page to get per domain idle detection 
;    HEADER.A86 1.15 93/11/08 19:09:22 
;    Handle EXEPACK problems even if DOS not in HMA
;    HEADER.A86 1.14 93/11/14 18:14:21
;    Initialise fdos_buf to 2/0
;    HEADER.A86 1.13 93/10/07 19:08:25
;    CALL5 always goes through 0:C0 (or FFFF:D0 alias)
;    HEADER.A86 1.12 93/09/03 20:28:39 
;    Add intl/dbcs support for int 21/6523 (query yes/no char)
;    HEADER.A86 1.11 93/09/02 22:26:24 
;    Make uppercase tables compatible (See COMPATIBLE flag in COUNTRY.SYS)
;    HEADER.A86 1.9 93/08/10 17:41:25 
;    Move code fragments for Rolodex Live
;    HEADER.A86 1.8 93/08/04 15:15:39 
;    re-arrange dummy fcbs
;    HEADER.A86 1.6 93/07/22 19:29:19 
;    add no/yes characters
;    HEADER.A86 1.5 93/07/20 22:46:33 
;    dmd_upper_root defaults to FFFF
;    ENDLOG
;

;	DRDOS Header/Initialization Code
;
; NB.
; On a system where the kernel stays low and history is disabled we throw
; away as much code as possible. This includes the patch area, the command
; line history code, and the BDOS initialisation code.
; As we use the patch area the pointer in the header should be incremented
; in order to retain progressively larger amounts of code.

PCMDATA group PCMODE_DATA,FIXED_DOS_DATA,PCMODE_CODE
PCMDATA group BDOS_DATA,PCMODE_DSIZE

PCMCODE group PCM_HEADER,PCM_HISTORY,PCM_ICODE,PCM_CODEND

	.nolist
	include pcmode.equ
	include	vectors.def

	include	cmdline.equ
	include	doshndl.def
	include	driver.equ
	include exe.def
	include	f52data.def
	include fdos.equ
	include	mserror.equ
	include	psp.def
	include	request.equ
	include	country.def
	.list

PADDING		equ	14*1024		; offset code start by this much

DOSINROM	equ	0800h
DOSINHMA	equ	1000h


;****************************************************************************
;	The format of the header is FIXED and should not be modified.
;****************************************************************************

PCM_HEADER	segment public para 'CODE'

	extrn	edit_size:word

	dw	PADDING
	db	PADDING-2 dup (0)		; Insert Header

	Public	code_start
code_start:

;	jmp	pcmode_init	; PCMODE Init Entry
    db  0E9h       
	dw	pcmode_init-PADDING-3
;	jmp	pcmode_reinit	; PCMODE Re Init Entry
	db	0E9h
;	dw	pcmode_reinit-PADDING-6
	dw	pcmode_init2-PADDING-6

	Public	pcmode_dseg, os_version, patch_version

pcmode_dseg	dw	0			; 0006h PCMODE Data Segment Pointer
		dw	PADDING			; 0008h	offset of start of code
os_version	dw	1072h			; 000Ah OS version
		dw	patch_area-PADDING	; 000Ch offset of disposable code
		dw	pcmode_init-PADDING	; 000Eh offset of initialisation code
		db	0EAh			; 0010h JMPF (MUST be para aligned)
		dw	4*30h			; 0011h  through the Int 30 vec
		dw	0			; 0013h  to CALL 5 entry point
		db	7 dup (0)		; 0015h make following offsets same as 5.0
		dw	0			; 001Ch Compressed Data Flag
		dw	code_end-PADDING	; 001Eh PCMODE Code Size in Bytes
		dw	data_end		; 0020h PCMODE Data Length in Bytes
patch_version	dw	DOSINROM+0000h		; 0022h sub-version (was SYSDAT length)
		db	0			; 0024h Kanji Support Flag
		db	0			; 0025h Reserved
		dw	edit_size-PADDING	; 0026h Pointer Command Line Editor
						;       control table.
		dw	NoYesChars		; 0028h offset in data of pointers to 
						; default country info.
		db 6 dup (0)			; (paragraph alignment)
PCM_HEADER ends

;****************************************************************************
;	The format of the data is FIXED and should not be modified.
;****************************************************************************

PCMODE_DATA	segment public word 'DATA'


	Public	codeSeg			; BDOS code segment
	Public	dmd_root		; Root of DOS Memory List
	Public	hmaRoot			; Root of HMA chain
	Public	func52_data		; Start of the FUNC 52 compatible data
	Public	last_drv		; Last Drive
	Public	phys_drv
	Public	dev_root		; Root of Device List
	Public	nul_device		; NUL Device
	Public	ddsc_ptr
	Public	retcode
	Public	user_retcode
	Public	system_retcode
	Public	break_sp
	Public	net_retry
	Public	net_delay
    Public  file_ptr        
	Public	clk_device		; Clock Device Pointer
	Public	con_device		; Console Device Pointer
	Public	bcb_root		; Linked List of Buffers
	Public	fcb_ptr
	Public	ldt_ptr
	Public	join_drv
	Public	share_stub
	Public	sector_size
	Public	setverPtr
	Public	dos_version

	Public	@hist_flg		; History control flag
	Public	dmd_address		; don't free DMD's with segment under this value
	Public	dmd_owner		; don't free DMD's with owner under this value
	Public	dmd_upper_root		; link to upper memory
	Public	dmd_upper_link
	Public	LocalMachineID		; Normal 0, fixed up by multi-tasker

	Public	biosDate		; 6 byte buffer to read/write clock
	Public	minute
	Public	hour
	Public	hundredth
	Public	second
	Public	dayOfMonth
	Public	month
	Public	yearsSince1980
	Public	daysSince1980
	Public	dayOfWeek


	org	0
		
dos_data	db	0
		dw	code_start
		db	0	; padding
		dw	1


; make end of vladivar instance data public for the multi-tasker
	db	06h - (offset $ - offset dos_data) dup (0)
	dw	endOfInstanceData

	db	0eh - (offset $ - offset dos_data) dup (0)

	Public	netbios, name_num, fcb_lru_count
netbios		db	0		; NetBios Name Number
name_num	db	0		; 0 - Undefined Name
fcb_lru_count	dw	0		; fcb LRU counter

	db	26h-0ch-(offset $ - offset dos_data) dup (0) ; align func52_data on 26

;************************************************************************
;*									*
;*	Below is the DOS defined area of the SYSTEM variables		*
;*	above are variables defined for DR DOS.				*
;*									*
;************************************************************************
net_retry	dw	3		;-000C Network retry count
net_delay	dw	1		;-000A Network delay count
bcb_root	dw	-1,-1		;-0008 Current DOS disk buffer
		dw	0		;-0004 Unread CON input
dmd_root	dw	0		;-0002 Root of DOS Memory List (Segment)
func52_data	label byte
ddsc_ptr	label dword		; 0000 DWORD ptr to DDSC
		dw	-1,-1
file_ptr	label dword		; 0004 DWORD ptr file table
		dw	msdos_file_tbl,0
clk_device	label dword		; 0008 DWORD ptr Clock Device Header
		dw	-1,-1		;      Initialize to an Invalid Address
con_device	label dword		; 000C DWORD ptr Console Device Header
		dw	-1,-1		;      Initialize to an Invalid Address
sector_size	dw	128		; 0010 WORD Buffer Size (Max Sector Size)
buf_ptr		dw	buf_info,0	; 0012 DWORD ptr to Disk Buffer Info
ldt_ptr		dw	0,0		; 0016 DWORD ptr Path Structures
fcb_ptr		dw	dummy_fcbs,0	; 001A DWORD ptr FCB Control Structures
		dw	0		; 001E WORD UNKNOWN
phys_drv	db	0		; 0020 BYTE Number of Physical Drives
last_drv	db	0		; 0021 BYTE Last Drive
dev_root	label dword		; 0022 DWORD ptr Device Driver List
nul_device	dw	-1,-1		;      Next Device Pointer
		dw DA_CHARDEV+DA_ISNUL	; 0026 NUL Device Attributes
		dw	nul_strat	; 0028 NUL Device Strategy routine
		dw	nul_int		; 002A NUL Device Interrupt routine
		db	'NUL     '	; 002C NUL Device Name
join_drv	db	0		; 0034 BYTE Number of JOIN'd drives
		dw	0		; 0035 DOS 4 pointer to special names (always zero in DOS 5)
setverPtr	dw	0,0		; 0037 setver list
		dw	0		; 003B unknown
		dw	0		; 003D psp of last umb exec
		dw	1		; 003F number of buffers
		dw	1		; 0041 size of pre-read buffer
	public	bootDrv
bootDrv		db	0		; 0043 drive we booted from
		db	0		; 0044 cpu type (1 if >=386)
		dw	0		; 0045 Extended memory
buf_info	dd	0		; 0047 disk buffer chain
		dw	0		; 004B 0 (DOS 4 = # hashing chains)
		dd	0		; 004D pre-read buffer
		dw	0		; 0051 # of sectors
		db	0		; 0053 00=conv 01=HMA
		dw	0		; 0054 deblock buf in conv
deblock_seg	dw	0		; 0056 (offset always zero)
		db	3 dup (0)	; 0058 unknown
		dw	0		; 005B unknown
		db	0, 0FFh, 0	; 005D unknown
		db	0		; 0060 unknown
		dw	0		; 0061 unknown
dmd_upper_link	db	0		; 0063 upper memory link flag
		dw	0		; 0064 unknown
dmd_upper_root	dw	0FFFFh		; 0066 dmd_upper_root
		dw	0		; 0068 para of last mem search

		dw	invalid_stub,0	; 006A DWORD ptr to 15
		dw	nul_int,0	; 006E  SHARE STUB routines
		dw	nul_int,0	; 0072
		dw	nul_int,0	; 0076
		dw	nul_int,0	; 007A
		dw	nul_int,0	; 007E
		dw	nul_int,0	; 0082
		dw	nul_int,0	; 0086
		dw	nul_int,0	; 008A
		dw	nul_int,0	; 008E
		dw	invalid_stub,0	; 0092
		dw	nul_int,0	; 0096
		dw	nul_int,0	; 009A
		dw	nul_int,0	; 009E
		dw	nul_int,0	; 00A2

msdos_file_tbl	dw	-1		; 00A6 1st HDB entries
		dw	-1		; Pointer to next Entry (None)
		dw	3		; Number of Entries

		db	3*DHNDL_LEN dup (0)	; Reserve 5 Internal Handles

	db	1fbh - (offset $ - offset dos_data) dup (0)

	Public	savbuf
;savbuf		rb	128		; cmdline editing temp buffer
savbuf		db	CMDLINE_LEN dup (0)	; cmdline editing temp buffer
	Public	fdos_buf
fdos_buf	db	2,0		; initialise buffer to empty
;		rb	128+1		; room for 128 byte readline + LF
		db	CMDLINE_LEN+1 dup (0)	; room for 128 byte readline + LF

	db	2feh - (offset $ - offset dos_data) dup (0)
; this byte is used for ^P support
	Public	cio_state
cio_state	db	0		; 0 = no printer echo, ~0 echo
	Public	verify_flag
verify_flag	db	0		; ~0, write with verify

	db	300h - (offset $ - offset dos_data) dup (0)
; this byte is used for TAB's
	Public column
column		db	0		; Current Cursor Column
	Public	switch_char
switch_char	db	'/'
	Public	mem_strategy
mem_strategy	db	0		; memory allocation strategy
	Public	sharing_flag
sharing_flag	db	0		; 00 = sharing module not loaded
					; 01 = sharing module loaded, but
					;      open/close for block devices
					;      disabled
					; FF = sharing module loaded,
					;      open/close for block devices
					;      enabled (not implemented)
	Public	net_set_count
net_set_count	db	1		; count the name below was set
	Public	net_name
net_name	db	'               ' ; 15 Character Network Name
		db	00		  ; Terminating 0 byte

; These tables point to routines to be patched by MSNET
		dw	criticalSectionEnable
		dw	criticalSectionEnable
		dw	criticalSectionEnable
		dw	criticalSectionEnable
		dw	0		; terminating null

		db	0		; padding

;
;	Variables contained the the "STATE_DATA" segment contain
;	information about the STATE of the current DOS Process. These
;	variables must be preserved regardless of the state of the INDOS
;	flag.
;
;	All variables that appear in "STATE_DATA" **MUST** be declared
;	in this file as the offsets from the INTERNAL_DATA variable are
;	critical to the DOS applications that modify this data area.
;
;
	Public	error_flag, indos_flag
	Public	error_locus, error_code
	Public	error_action, error_class
	Public	error_dev, error_drive
	Public  dma_offset, dma_segment
	Public	current_psp, current_dsk
	Public	break_flag

	Public	internal_data

internal_data	label word		; <-- Address returned by INT21/5D06
error_flag	db	0		; INDOS - 01 - Error Mode Flag
indos_flag	db	0		; INDOS + 00 - Indos Flag
error_drive	db	0		; INDOS + 01 - Drive on write protect error
error_locus	db	0		; INDOS + 02 - Error Locus
error_code	dw	0		; INDOS + 03 - DOS format error Code
error_action	db	0		; INDOS + 05 - Error Action Code
error_class	db	0		; INDOS + 06 - Error Class
error_dev	dd	0		; INDOS + 07 - Failing Device Address
dma_offset	dw	0		; INDOS + 0B - DMA Offset
dma_segment	dw	0		; INDOS + 0D - DMA Segment	
current_psp	dw	0		; INDOS + 0F - Current PSP
break_sp	dw	0		; INDOS + 11 - used in int 23
retcode		label word
user_retcode	db	0		; INDOS + 13 - return code from process
system_retcode	db	0		; INDOS + 14 - reason for process terminate
current_dsk	db	0		; INDOS + 15 - Current Drive
break_flag	db	0		; INDOS + 16 - Break Flag
		dw	0		; INDOS + 17 - unknown

	Public	swap_always
swap_always	label dword

	Public	int21AX
int21AX		dw	0		; INDOS + 19 - AX from last Int 21

	Public	owning_psp, machine_id
owning_psp	dw	0		; INDOS + 1B - owning psp
machine_id	dw	0		; INDOS + 1D - remote machine ID


	public	load_psp, load_image, load_top, load_max, load_handle
	
load_psp	dw	0		; Paragraph of the new PSP.
load_image	dw	0		; Paragraph of the Load Image.
load_top	dw	0		; Last paragraph of Allocated Memory
load_max	dw	0		; ditto, but not messed with
load_handle	dw	0		; Handle allocated to load file on OPEN

	Public	locus, valid_flg, retry_off, retry_sp
locus		db	0		; Public Error Locus Value
valid_flg	db	0		; Valid Options for Critical Error 
retry_off	dw	0		; IP for Error Retry
retry_sp	dw	0		; SP for Error Retry



; Some important data structures....
	db	0350h - ($ - offset dos_data) dup (0) ; DOS 5
dayOfMonth		db	0
month			db	0
yearsSince1980		dw	0
daysSince1980		dw	0FFFFh	; force rebuild on first clock read
dayOfWeek		db	0

	public	internal_flag
internal_flag   db  0      

	Public	int28_flag
int28_flag		db	FALSE


	public	ioctlRH

ioctlRH		db	23 dup (0)	; up to 23 bytes possible

	public	load_env, load_envsize, exe_loadhigh
load_env	dw	0		; Paragraph of the new environment
load_envsize	dw	0		; Size of new environment
exe_loadhigh	db	0		; load high flag


	Public	fcb_pb, fcb_path, fcb_path2

; These variables are used during FCB processing - we build another parameter
; block outside the MXDisk which makes handle calls to the FDOS

fcb_pb		dw	7 dup (0)
fcb_path	db	15 dup (0)
fcb_path2	db	15 dup (0)

	public	char_count
char_count	db	0

PCMODE_DATA ends

;****************************************************************************
;	The format of the data is FIXED and should not be modified.
;****************************************************************************

; WARNING - if anyone adds/deletes PCMODE_DATA they MUST adjust these
; values so the following data will origin correctly
FIXED_DOS_DATA	segment public word 'DATA'

FIXED_DATA_START	equ	3B0h
	public	MUSTBE03B0
MUSTBE03B0:

	org	03b6h - FIXED_DATA_START	; DOS 5
biosDate	dw	0		; days since 1980
minute		db	0
hour		db	0
hundredth	db	0
second		db	0
		db	2 dup (0)	; padding

	Public	reloc_buf, load_file, RELOC_CNT
RELOC_CNT	equ	80h/16		; buffer 128 bytes here

; function 4B uses these data area's as workspace during an EXEC

	Public	pri_pathname
reloc_buf	label byte		; shared with primary pathname
pri_pathname	db	80h dup (0)
	Public	sec_pathname
load_file	label	byte
sec_pathname	db	80h dup (0)
	Public	srch_buf
srch_buf	db	21+32 dup (0)	; 21 byte srch state, 32 byte dir entry
	Public	temp_ldt
temp_ldt	db	LDT_LEN dup (0)
	Public	name_buf
name_buf	db	32 dup (0)	; space enough for 1 dir entry

magic_byte	db	0
		db	0		; padding
	Public	file_attrib
file_attrib	dw	0
		db	3 dup (0)	; padding
	Public	remote_call
remote_call	dw	0


    org 057Ch - FIXED_DATA_START 
	Public	exit_type		; used by break and critical error
exit_type	db	0		;  handlers during termination
		db	0		; padding
	Public	term_psp
term_psp    	dw  0       

	Public	int24_esbp
int24_esbp	dw	2 dup (0)
	Public	int21regs_ptr, int21regs_off, int21regs_seg
int21regs_ptr	label word
int21regs_off	dw	0
int21regs_seg	dw	0
	public	critical_sp
critical_sp	dw	0		; critical error internal stack
	Public	current_ddsc
current_ddsc	dw	2 dup (0)

    org 059ah - FIXED_DATA_START 
	Public	current_device
current_device	dw	2 dup (0)
	Public	current_dhndl
current_dhndl	dw	2 dup (0)
	Public	current_ldt
current_ldt	dw	2 dup (0)
		dw	2 dup (0)		; pointer to callers FCB
	Public	current_ifn
current_ifn	dw	0

    org 05b2h - FIXED_DATA_START 
		dw	offset pri_pathname
		dw	offset sec_pathname
		dw	offset pri_pathname

    org 05ceh - FIXED_DATA_START 
	Public	current_filepos
current_filepos	dw	4 dup (0)

    org 05f0h - FIXED_DATA_START 
	Public	prev_int21regs_ptr, prev_int21regs_off, prev_int21regs_seg
prev_int21regs_ptr	label word
prev_int21regs_off	dw	0
prev_int21regs_seg	dw	0

    org 0620h - FIXED_DATA_START 

	Public	indos_stack, error_stack, normal_stack

	Public	fcb_search_buf		; during FCB search 1st/next use bottom
fcb_search_buf	label byte		;  of error stack as scratch buffer
	;	db	43 dup (0)	;  - only used during int 21 call

		dw	STACK_SIZE dup (0)	; Error Processing Stack
error_stack	label word

		dw	STACK_SIZE dup (0)	; Normal Function Stack Area
normal_stack	label word

		dw	STACK_SIZE dup (0)	; Indos Function Stack
indos_stack	label word

lookahead_flag	db	0

	Public	rwmode, err_drv, ioexerr
err_drv     db  0       
rwmode      db  0       
ioexerr     db  0       
	public	int2f_cmd, int2f_stack, file_mode
int2f_cmd   dw  0       
int2f_stack dw  0       
file_mode   dw  0       
	Public	cle_state
cle_state   dw  0       
	Public	swap_indos
swap_indos	label word

    org 0AADh - FIXED_DATA_START 

Ucasetbl	dw  128	; Table Size
	db	080h, 09ah,  'E',  'A', 08eh,  'A', 08fh, 080h
	db	 'E',  'E',  'E',  'I',  'I',  'I', 08eh, 08fh
	db	090h, 092h, 092h,  'O', 099h,  'O',  'U',  'U'
	db	 'Y', 099h, 09ah, 09bh, 09ch, 09dh, 09eh, 09fh
	db	 'A',  'I',  'O',  'U', 0a5h, 0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
info2_len	equ	word ptr (offset $ - offset Ucasetbl)


    org 0B2Fh - FIXED_DATA_START 
; Filename upper case table
FileUcasetbl	dw  128	; Table Size
standard_table	label byte
	db	080h, 09ah,  'E',  'A', 08eh,  'A', 08fh, 080h
	db	 'E',  'E',  'E',  'I',  'I',  'I', 08eh, 08fh
	db	090h, 092h, 092h,  'O', 099h,  'O',  'U',  'U'
	db	 'Y', 099h, 09ah, 09bh, 09ch, 09dh, 09eh, 09fh
	db	 'A',  'I',  'O',  'U', 0a5h, 0a5h, 0a6h, 0a7h
	db	0a8h, 0a9h, 0aah, 0abh, 0ach, 0adh, 0aeh, 0afh
	db	0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	0e0h, 0e1h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh

info4_len	equ	word ptr (offset $ - offset FileUcasetbl)

    org 0BB1h - FIXED_DATA_START 

FileCharstbl:
		dw  22	; Table Size
	db	 001h, 000h, 0ffh, 000h, 000h, 020h, 002h, 00eh
	db	 02eh, 022h, 02fh, 05ch, 05bh, 05dh, 03ah, 07ch
	db	 03ch, 03eh, 02bh, 03dh, 03bh, 02ch
info5_len	equ	word ptr (offset $ - offset FileCharstbl)

    org 0BE1h - FIXED_DATA_START    

Collatingtbl:
		dw  256	; Table Size
	db	 000h, 001h, 002h, 003h, 004h, 005h, 006h, 007h
	db	 008h, 009h, 00ah, 00bh, 00ch, 00dh, 00eh, 00fh
	db	 010h, 011h, 012h, 013h, 014h, 015h, 016h, 017h
	db	 018h, 019h, 01ah, 01bh, 01ch, 01dh, 01eh, 01fh
	db	 020h, 021h, 022h, 023h, 024h, 025h, 026h, 027h
	db	 028h, 029h, 02ah, 02bh, 02ch, 02dh, 02eh, 02fh
	db	 030h, 031h, 032h, 033h, 034h, 035h, 036h, 037h
	db	 038h, 039h, 03ah, 03bh, 03ch, 03dh, 03eh, 03fh
	db	 040h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 05bh, 05ch, 05dh, 05eh, 05fh
	db	 060h, 041h, 042h, 043h, 044h, 045h, 046h, 047h
	db	 048h, 049h, 04ah, 04bh, 04ch, 04dh, 04eh, 04fh
	db	 050h, 051h, 052h, 053h, 054h, 055h, 056h, 057h
	db	 058h, 059h, 05ah, 07bh, 07ch, 07dh, 07eh, 07fh
	db	 043h, 055h, 045h, 041h, 041h, 041h, 041h, 043h
	db	 045h, 045h, 045h, 049h, 049h, 049h, 041h, 041h
	db	 045h, 041h, 041h, 04fh, 04fh, 04fh, 055h, 055h
	db	 059h, 04fh, 055h, 024h, 024h, 024h, 024h, 024h
	db	 041h, 049h, 04fh, 055h, 04eh, 04eh, 0a6h, 0a7h
	db	 03fh, 0a9h, 0aah, 0abh, 0ach, 021h, 022h, 022h
	db	 0b0h, 0b1h, 0b2h, 0b3h, 0b4h, 0b5h, 0b6h, 0b7h
	db	 0b8h, 0b9h, 0bah, 0bbh, 0bch, 0bdh, 0beh, 0bfh
	db	 0c0h, 0c1h, 0c2h, 0c3h, 0c4h, 0c5h, 0c6h, 0c7h
	db	 0c8h, 0c9h, 0cah, 0cbh, 0cch, 0cdh, 0ceh, 0cfh
	db	 0d0h, 0d1h, 0d2h, 0d3h, 0d4h, 0d5h, 0d6h, 0d7h
	db	 0d8h, 0d9h, 0dah, 0dbh, 0dch, 0ddh, 0deh, 0dfh
	db	 0e0h, 053h, 0e2h, 0e3h, 0e4h, 0e5h, 0e6h, 0e7h
	db	 0e8h, 0e9h, 0eah, 0ebh, 0ech, 0edh, 0eeh, 0efh
	db	 0f0h, 0f1h, 0f2h, 0f3h, 0f4h, 0f5h, 0f6h, 0f7h
	db	 0f8h, 0f9h, 0fah, 0fbh, 0fch, 0fdh, 0feh, 0ffh
info6_len	equ	word ptr (offset $ - offset Collatingtbl)

    org 0CE3h - FIXED_DATA_START    

DBCS_tbl:
		dw	0	; Table Size
	db	 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
	db	 000h, 000h, 000h, 000h, 000h, 000h, 000h, 000h
info7_len	equ	word ptr (offset $ - offset DBCS_tbl)

;    org 0d12h - FIXED_DATA_START    
    org 0d10h - FIXED_DATA_START    

true_version	dw	107h			; true DOS version
dos_version	dw	6			; our DOS version number

; Don't know what these are for.....
		db	0c8h,0a6h
		db	0c8h,0a5h
		db	0c8h,0a5h
		db	0c8h,0a5h

; Now we have a list of days in each month
	Public	days_in_month

days_in_month	db	31,28,31,30,31,30	; Jan, Feb, Mar, Apr, May, Jun
		db	31,31,30,31,30,31	; Jul, Aug, Sep, Oct, Nov, Dec
	
    org 0d90h - FIXED_DATA_START    

	Public	last_key_ext

	last_key_ext	db	0			; flag set if last key zero

    org 0e5bh - FIXED_DATA_START    
	
; 
; Extended Error/Class/Action/Locus table. Used in conjuction with
; Int2F/1222 to setup extended error information
		db	13h,0Bh,07h,02h
		db	14h,04h,05h,01h
		db	15h,05h,07h,0FFh
		db	16h,04h,05h,01h
		db	17h,0Bh,04h,02h
		db	18h,04h,05h,01h
		db	19h,05h,01h,02h
		db	1Ah,0Bh,07h,02h
		db	1Bh,0Bh,04h,02h
		db	1Ch,02h,07h,04h
		db	1Dh,05h,04h,0FFh
		db	1Eh,05h,04h,0FFh
		db	1Fh,0Dh,04h,0FFh
		db	20h,0Ah,02h,02h
		db	21h,0Ah,02h,02h
		db	22h,0Bh,07h,02h
		db	32h,09h,03h,03h
		db	23h,07h,04h,01h
		db	24h,01h,04h,05h
		db	0FFh,0Dh,05h,0FFh

    org 0eabh - FIXED_DATA_START    

; This is a translation table from old error codes to extended errors
	db	13h,14h,15h,16h,17h,18h,19h,1Ah
	db	1Bh,1Ch,1Dh,1Eh,1Fh,1Fh,1Fh,22h
	db	24h


; KLUDGE for DRDOS 6.0 security - the word at offset zero in SYSDAT (the
; SYStem DATa page) was the segment of the secure path string, with
; a zero value indicating a non-secure system.
; In order for DRDOS 6 level utilities to run we point SYSDAT at offset
; 10h in the DOS data segment (this unused word is zero). On secure systems
; the new LOGIN TSR will fix up both SYSDAT and the PD value to point to
; it's own dummy SYSDAT, and the utilities will behave correctly.

	Public	@private_data

@private_data	label byte		; We need some private data
		dw	endOfInstanceData ; 0000 historical PD offset
dummy_sysdat	dw	1		; 0002 historical SYSDAT segment
		dw	offset histbuf1	; 0004 History Control Block 1
		dw	offset histbuf2	; 0006 History Control Block 2
@hist_flg	db	0		; 0008 History Control
					;   Bit 0 = Buffer Select 1 = COMMAND
					;   Bit 1 = History Enable 1 = ENABLE
		db	1		; 0009 Dual Language Version
		db	0		; 000A Current message language
		dw	0		; 000B Extended memory
		db	0		; 000D (was # JMPF entries to fix up)
codeSeg		dw	0		; 000E BDOS code segment (was seg of JMPF table)
hmaRoot		dw	0		; 0010 Root of himem free chain
		dw	0		; 0012 Initial Environment
hmaAlloc	dw	0		; 0014 Root of himem allocation chain
dmd_owner	dw	0		; 0016 Owner below which DMD's not freed
		dw	0		; 0018 Link to upper memory DMD's
LocalMachineID	dw	0		; 001A Patched by multi-tasker to correct value
dmd_address	dw	0		; 001C Address below which DMD's not freed
		dw	offset country_filename
hashptr		dw	0,0		; 0020 hash root
hashmax		dw	0		; 0024 max dir entries hashed
		dw	0		; 0026 was deblock seg
		dw	offset share_stub
					; 0028 share stub offset
		dw	offset globalPrivateData
					; 002A pointer to global private data
		dw	offset int2FBiosHandler
					; 002C pointer to int 2F internal hook
		dw	10 dup (0)	; space for expansion

	Public	deblock_seg, fdos_stub

fdos_stub	dw	fdos_stub_entry
		dw	0		; fixup up at run time

share_stub	dw	invalid_stub,0	; DWORD ptr to 15
		dw	nul_int,0	; SHARE STUB routines
		dw	nul_int,0	; 
		dw	nul_int,0	; 
		dw	nul_int,0	; 
		dw	nul_int,0	; 
		dw	nul_int,0	; 
		dw	nul_int,0	; 
		dw	nul_int,0	; 
		dw	nul_int,0	; 
		dw	invalid_stub,0	; 
		dw	nul_int,0	; 
		dw	nul_int,0	; 
		dw	nul_int,0	; 
		dw	nul_int,0	; 


	Public	WindowsHandleCheck
WindowsHandleCheck db	26h		; MUST follow share_stub
					; patched by switcher


	org	0FC0h - FIXED_DATA_START

childSP		dw	0
childSS		dw	0
childIP		dw	0
childCS		dw	0

;	The following table defines the format of a DOS .EXE format file.
;	The .EXE header is read into this data area and check for integrity
;	
	Public	exe_buffer
exe_buffer	db	EXE_LENGTH dup (0)	; Local EXE header buffer


ifdef IDLE_DETECT

	Public	idle_data
	Public	active_cnt, idle_max
	Public	idle_flags, idle_vec

idle_data	label word		; Idle State Data Area
active_cnt	dw	0		; InActive Function Count
idle_max	dw	10		; Max No. of consecutive funcs.
idle_flags	dw	IDLE_INIT	; $IDLE$ Has not been loaded
idle_vec	dd	0 		; DWORD pointer to IDLE handler


		Public	int28_delay, int28_reload
int28_delay	dw	0		; No. Consecutive INT28's 
int28_reload	dw	10		; INT28 Delay Reload Value
		dw	indos_flag	; Offset of INDOS_FLAG
		dw	2 dup (0)	; 2 OEM Reserved Words
endif

	org	1000h - FIXED_DATA_START	; nice 4K boundry
						; for multitasker

FIXED_DOS_DATA ends

PCMODE_DSIZE	segment public para 'DATA'

	Public	data_end
data_end	label word

PCMODE_DSIZE ends


	extrn	int20_entry:near, int21_entry:near
	extrn	int25_entry:near, int26_entry:near
	extrn	int27_entry:near, int2F_entry:near
	extrn	call5_entry:near

PCMODE_CODE	segment public word 'DATA'


PCMODE_CODE_START	equ	1000h
	public	MUSTBE1000
MUSTBE1000:

	Public	endOfInstanceData

endOfInstanceData	label word

;*** fixed data - init does segment fixups ***

stub_entries	label word

	Public	lock_bios, unlock_bios, lock_tables, unlock_tables

lock_bios	dw	lockbios,0		; MSNET critical region stubs
unlock_bios	dw	unlockbios,0		; MSNET critical region stubs
lock_tables	dw	locktables,0		; MSNET critical region stubs
unlock_tables	dw	unlocktables,0		; MSNET critical region stubs

	Public	exec_stub
exec_stub	dw	ExecStub,0		; Int 21 EXEC hook
	public	func4B05_stub
func4B05_stub	dw	Func4B05Stub,0		; Int 21/4B05 hook

NUM_STUB_ENTRIES	equ	(offset $ - offset stub_entries)/4
;*** fixed data ends ***

	cmp	ds:error_flag,0		; JT-FAX uses this code sequence to
	jnz	$			; find the address of the ERROR_FLAG
	mov	sp,0A06h

	test	ss:error_flag,0FFh	; SIDEKICK usues this fragment to
	 jnz	$			; locate the ERROR_FLAG
	push	ss:word ptr int28_flag
	int	28h

;==========================
; Entry points for DOS Code
;==========================
;
; These are normally all of the form
;
;EntryPoint:
;	JMPF	xxxx:RealEntryPoint
;	db	3 dup(?)
;
; When we are in the HMA, and so may disable the HMA during EXEC for EXEPACK
; problems, we convert them to the following
;
;EntryPoint:
;	call	A20Enable
;	JMPF	xxxx:RealEntryPoint
;
; On an exec the A20 gate is disabled. This allows EXEPACKed programs to
; unpack properly. (some exepacked apps have a wrap-round bug which addresses
; the bottom 64K via the HMA).
;
; On the first Int 21 etc the A20Enable routine enables the A20 gate.
;

FirstCodeEntryPoint	label word

Int20Entry:
	db	0EAh			; JMPF
	dw	int20_entry
	db	5 dup (0)		; filled in at run time
	

Int21Entry:
	db	0EAh			; JMPF
	dw	int21_entry
	db	5 dup (0)		; filled in at run time

Int25Entry:
	db	0EAh			; JMPF
	dw	int25_entry
	db	5 dup (0)		; filled in at run time

Int26Entry:
	db	0EAh			; JMPF
	dw	int26_entry
	db	5 dup (0)		; filled in at run time

Int27Entry:
	db	0EAh			; JMPF
	dw	int27_entry
	db	5 dup (0)		; filled in at run time

Int2FEntry:
	db	0EAh			; JMPF
	dw	int2f_entry
	db	5 dup (0)		; filled in at run time

Call5Entry:
	db	0EAh			; JMPF
	dw	call5_entry
	db	5 dup (0)		; filled in at run time

LastCodeEntryPoint	label word


BIOSA20Enable:
;-------------
; CALLF'd by the BIOS
	call	A20Enable		; do a near call
	sti				; re-enable interrupts
	retf				; RETF to BIOS


A20Disable:
;----------
; On Entry:
;	DX = psp we are execing
	cmp	dx,0FF0h		; if we are above 64K skip the
	 jae	A20Disable10		;  EXE pack kludge
	push	ax
	mov	ah,6			; disable the A20 gate during EXEC
	call	dword ptr cs:xmsDriver	;  so buggy EXE packing will work
	pop	ax
A20Disable10:
	ret

A20Enable:
;---------
; On Entry:
;	None
;	WARNING - DS/ES/STACK could be anything
; On Exit:
;	All regs preserved
;
; Unhook our Entry stubs so we don't get here again.
; Enable the global A20 line to make the DOS/BIOS/COMMAND code visible
;
	cli
	push	ax
	push	ds
	mov	ax,0FFFFh
	mov	ds,ax
	mov	ax,ds:94h		; is the HMA alias for Int 21
	or	ax,ds:96h		;  zero - if so the HMA is there
	pop	ds
	 jnz	A20Enable10
	pop	ax
	ret

A20Enable10:
; We need to enable the A20 gate, go do so
	push	bx
	mov	cs:oldSS,ss		; save stack
	mov	cs:oldSP,sp
	mov	ax,cs
	mov	ss,ax			; swap to the error stack in case
	mov	sp,offset error_stack	;  3rd part XMS driver needs a lot

	mov	ah,5			; enable A20, ignoring errors as we
	call	dword ptr cs:xmsDriver	;  can't do anything about them

	mov	ss,cs:oldSS		; switch back to callers stack
	mov	sp,cs:oldSP

	pop	bx
	pop	ax
	ret

oldSS		dw	0		; save area for stack swap
oldSP		dw	0

;	+++++++++++++++++++++++++++++++++
;	Default Int 24 Handler for DR DOS
;	+++++++++++++++++++++++++++++++++
;
;	Our default critical error handler during boot simply FAIL's all
;	critical errors. When COMMAND.COM is loaded this will install
;	the "normal" Retry/Abort/Ignore handler.
;
;	These interrupts normally point to an IRET.
;
;

Int24Entry:
;==========
	mov	al,3			; return "FAIL"
DummyIRET:
;=========
	iret

;	EXEC Code
;
;	In order to cope with old buggy EXEPACKED programs we need to turn
;	the A20 gate of during the exec, and turn it back on asap.
;	To do this we hook all the DOS code entry points and re-enable the
;	A20 whenever the app issues an Int 21 etc
;


ExecStub:
;========
; On Entry:
;	AX = FCB validity flags
;	DX = current PSP
;	ES:SI -> new CS:IP
;	CX:DI -> users stack
; On Exit:
;	AX = FCB validity flags
;	BX = 0
;	SS:SP = users stack
;	CS:IP = values from EXE header
;	DS = ES = DX = current PSP
;
; When we start execing the application we have the A20 gate disabled so
; buggy EXE packed programs will unpack properly.
; We also hook Int 21 and Int 2F to re-enable the A20 gate on the first
; calls made to them. (These should only happen AFTER the unpacking).
;

	call	A20Disable
	mov	ss,cx			; switch to new USER stack
	mov	sp,di
	push	es
	push	si			; CS:IP on USER stack
	mov	ds,dx			; DS = ES = PSP we are exec'ing
	mov	es,dx
	xor	bx,bx			; BX = zero, set flags
	sti
	retf				; lets go!

Func4B05Stub:
;============
; On Entry:
;	ES:BP -> callers stack
;	DX = PSP to exec on
; On Exit:
;	callers registers restored
;
	call	A20Disable		; turn off A20
	mov	ax,es
	mov	ss,ax			; back to users stack
	mov	sp,bp
	POP_DOS				; Restore Registers
	iret


	Public	int2FNext, int2FBiosHandler

Int2FBios:
;---------
; On Entry:
;	DS on stack
; On Exit:
;	All regs preserved
;
; Pass on an Int 2F call to the BIOS
	pop	ds			; recover DS and pass on to BIOS
	db	0EAh			; JMPF bios Int 2F entry point
int2FBiosHandler dw	0,0		; filled in at run time
int2FNext	dw	Int2FBios, 0	; seg filled in at run time


nul_strat:
	cmp	es:RH_CMD[bx],CMD_INPUT
	 jne	nul_strat10		; if it's input
	mov	es:RH4_COUNT[bx],0		; Say none transferred #IJ
nul_strat10:
	mov	es:RH_STATUS[bx],RHS_DONE	; Set the DONE bit in the
nul_int:				; Request Header and Return
	clc				; (indicate success for SHARE)
	retf

	Public	invalid_stub

invalid_stub:
	mov	ax,ED_FUNCTION		; indicate bad function
fdos_stub_entry:
	stc				; indicate error
	retf

	Public	lock_bios, unlock_bios, lock_tables, unlock_tables

lockbios:
;--------
	push	ax
	mov	ax,8002h
	jmp	short CriticalSection
	
unlockbios:
;----------
	push	ax
	mov	ax,8102h
	jmp	short CriticalSection

locktables:
;----------
	push	ax
	mov	ax,8001h
	jmp	short CriticalSection

unlocktables:
;------------
	push	ax
	mov	ax,8101h
;	jmps	CriticalSection

CriticalSection:
;---------------
; On Entry:
;	AX = critical section number
;	STACK = original AX
; On Exit:
;	AX poped from stack
;
	cmp	cs:criticalSectionEnable,0
	 je	CriticalSection10
	int	2ah			; issue critical section callout
CriticalSection10:
	pop	ax
	retf

	public	criticalSectionEnable
	
criticalSectionEnable	db	0


	Public	SwStartupInfo

SwStartupInfo	dw	3		; version
		dw	0
		dw	0		; link to next in chain

;;      dw  offset vxdName  ; Virtual Dev file
;; replaced above line with DW 0 as vxd no longer required BAP
		dw	0
		dw	0

        dw  0,0     ; Reference Data
		dw	offset instanceItems
instanceSeg	dw	0

;vxdName		db	'A:\OPENDOS.386',0

	public	histbuf1, histsiz1, histbuf2, histsiz2

instanceItems:
		dw	0		; offset zero (for instancing)
histbuf1	dw	0		; Command history buffer segment
histsiz1	dw	0		; size (in bytes)

		dw	0		; offset zero (for instancing)
histbuf2	dw	0		; Application history buffer segment
histsiz2	dw	0		; size (in bytes)


; some ROS fixups
		dw	000h,050h,002h	; BASIC variables
		dw	00Eh,050h,014h	; BASIC variables

; some BIOS fixups
		dw	0B8h,070h,004h	; BIOS req_hdr
;		dw	16Ch,070h,002h	; BIOS dev_no (no longer required)
		dw	600h,070h,002h	; BIOS local_char

bdosInstanceFixups	label word
		dw	con_device,0,4	; CON: device ptr
		dw	savbuf,0,column-savbuf+1
		dw	dmd_upper_root,0,2
		dw	dmd_upper_link,0,1
		dw	exe_buffer,0,EXE_LENGTH

		dw	0,0		; zero terminated instance list


xmsDriver	dd	0

globalPrivateData:
		dd	0		; 0000 delwatch driver vector
		dw	4 dup (0)	; space for expansion


;** COUNTRY INFO **


;
;	The following routines are called by the end user using the DWORD 
;	pointers in the Country Data. Each Country Data area contains a 
;	pointer to one of the following routines. All valid charcater
;	codes above 7Fh are translated to Upper Case
;

	Public	xlat_xlat

xlat_xlat:
	cmp	al,080h
	 jb	xlat_exit
	sub	al,080h
	push	bx
	mov	bx,offset Standard_table
	xlat	cs:0
	pop	bx
xlat_exit:
	retf


	Public	cur_country
	Public	cur_cp
	Public	default_country
	Public	country_data
	Public  Ucasetbl
	Public  FileUcasetbl
	Public	FileCharstbl
	Public  Collatingtbl
	Public	DBCS_tbl
	Public	info1_len
	Public	info2_len
	Public	info4_len
	Public	info5_len
	Public	info6_len
	Public	info7_len
	Public	intl_xlat

; table of pointers to default country info. pointed to in BDOS header 
	Public	NoYesChars

NoYesChars	db	'NnYy'
		dw	country_data
		dw	default_country
		dw	Ucasetbl
		dw	FileUcasetbl
		dw	FileCharstbl
		dw	Collatingtbl
		dw	DBCS_tbl


	org	11F0h - PCMODE_CODE_START


dummy_fcbs	dw	0ffffh		; terminate now
		dw	0
		dw	1		; with one entry
		db	DHNDL_LEN dup (0)	; this many bytes in it

    org 1232h - PCMODE_CODE_START   

	Public	country_filename
country_filename db	'\COUNTRY.SYS'
		db	64 - (lengthof country_filename) dup (0)

    org 1276h - PCMODE_CODE_START   

; We fix the country tables at this location for the benefit of
; LAN Manager 2.2 extended edition. It peeks directly rather than use
; int 21/65 !

countryTable:
	db	2
	dw	offset UCasetbl,0
	db	4
	dw	offset FileUCasetbl,0
	db	5
	dw	offset FileCharstbl,0
	db	6
	dw	offset Collatingtbl,0
	db	7
	dw	DBCS_tbl,0
	db	1
	dw	26h
country_data:
cur_country	dw	1		; Country Code
cur_cp		dw	437		; Code Page
default_country:
	dw	US_DATE		; Date Format (Binary)
	db	'$',0,0,0,0	; Currency Symbol
	db	',',0		; Thousands Separator
	db	'.',0		; Decimal Separator
	db	'-',0		; Date Separator
	db	':',0		; Time Separator
	db	0		; Symbol before Value without Space ($n.nn)
	db	2		; Significant Currency Digits
	db	CLOCK_12	; Time Format
intl_xlat dw	xlat_xlat	; Case Translation Routine
	dw	0000h		; Case Translation Segment (Runtime Fixup)
	db	',',0		; Data List Separator
info1_len	equ	word ptr (offset $ - offset country_data)
				; If NOT COUNTRY.SYS then include the
	db	10 dup (0)	; 10 zero bytes held at the end of the
				; country information.


	Public lfn_find_handles
	Public lfn_find_handles_end
lfn_find_handles:
	dw	32 dup (0)
lfn_find_handles_end:

	Public lfn_find_handle_heap
	Public lfn_find_handle_heap_end
lfn_find_handle_heap:
	db	2Eh * 32 dup (0)
lfn_find_handle_heap_end:

	Public lfn_find_handle_heap_free
lfn_find_handle_heap_free:
	dw lfn_find_handle_heap

	Public lfnpathflag
lfnpathflag:
	db 0

	Public lfn_search_redir
lfn_search_redir:
	db 0

PCMODE_CODE ends

PCM_CODEND	segment public para 'CODE'

	Public	code_end
code_end	label byte

PCM_CODEND ends

BDOS_DATA	segment public word 'DATA'

	Public	hashroot, hashmax

; The hashroot must be global, but we also need to make it accessible
; during CONFIG so we copy it from the private data area

hashroot	dw	0,0
BDOS_DATA ends


PCM_HISTORY	segment public byte 'CODE'

patch_area	dw	0666h
		db 256 dup (090h)

PCM_HISTORY ends

PCM_ICODE	segment public byte 'CODE'

;
;	The following routine initializes all the standard MS-DOS interrupt
;	vectors which are initialized to point to the PC-MODE handlers.
;
;	Entry:		AX	Memory Size - Paragraphs
;			BX	First Available Paragraph	
;			DL	Initial Drive
;			DS	PCM Dseg
;			ES	Interrupt Stubs Seg
;
pcmode_init:
	mov	cs:int_stubs_seg,es
	and	cs:patch_version,not DOSINROM
					; won't clear if we are in ROM...
	mov	cs:pcmode_dseg,ds	; save PCM Dseg
	mov	ds:instanceSeg,ds	; fixup pointer to instance items

; removed this as VxD no longer required   BAP
;	mov	ds:vxdNameSeg,ds	;  and vxdName

;	add	ds:vxdName,dl		; fixup drive letter
	mov	ds:word ptr buf_ptr+2,ds
	mov	ds:word ptr file_ptr+2,ds
	mov	ds:word ptr fcb_ptr+2,ds
	push	ax			; Save the memory size
	push	bx			; First Free Paragraph
	mov	ds:current_dsk,dl	; save initial drive
	inc	dl			; make drive one based
	mov	ds:bootDrv,dl		;  and save for func 3305
	mov	ax,ds			; AX = PCMode Data
	mov	ds:word ptr fdos_stub+WORD,ax
	add	ds:dummy_sysdat,ax	; point dummy "sysdat" at a zero word
					;  ie. dummy "secure path" segment
	mov	si,offset countryTable
countryFixupLoop:
	mov	ds:word ptr 3[si],ds	; fixup the segment
	add	si,5			; onto the next entry
	cmp	ds:word ptr 3[si],0	; done the lot yet ?
	 je	countryFixupLoop
	mov	es,ax			; ES -> PCMode Data
	mov	di,offset stub_entries	; ES:DI -> stub segs
	mov	cx,NUM_STUB_ENTRIES	; entries to initialise
stubs_loop:
	add	di,WORD			; skip the offset
	stosw				; fixup segment
	loop	stubs_loop		; do the next one
	mov	di,offset share_stub	; fixup the SHARE entries
	mov	cx,NUM_SHARE_STUB_ENTRIES
share_loop:
	add	di,WORD			; skip the offset
	stosw				; fixup segment
	loop	share_loop
;	mov	cx,0
	mov	es,cx			; Initialize the DOS vectors

	mov	ax,es:INT2F_OFFSET	; remember address of BIOS Int 2F
	mov	ds:int2FBiosHandler,ax
	mov	ax,es:INT2F_SEGMENT
	mov	ds:int2FBiosHandler+2,ax
	mov	ds:int2FNext+2,ds	; fixup seg of out stub

	mov	cx,40h-2Ah		; 2A-3F point at IRET in DOS Data Seg
	mov	di,INT2A_OFFSET
	mov	bp,cs:int_stubs_seg
	xor	bx,bx
dummy_vecs_loop:
	cmp	cx,40h-31h
	 je	dummy_vecs_skip
	push	es
	mov	es,bp
	mov	es:byte ptr [bx],0eah	; jmp far instruction
	mov	ax,offset DummyIRET	; point at an IRET
;	stosw				; do the offset
	mov	es:1[bx],ax
;	mov	ax,ds
;	stosw				; then the segment
	mov	es:3[bx],ds
	pop	es
	mov	es:[di],bx
	mov	es:2[di],bp
	add	bx,5
dummy_vecs_skip:
	add	di,4
	loop	dummy_vecs_loop


	mov	si,offset def_data_vecs	; the following vector point to
	mov	cx,no_def_data_vecs	; pcmode DATA seg
def_data_vecs_loop:
	push	es
	mov	es,bp
	lods 	cs:word ptr ax
	mov 	di,ax			; Get the Vector Offset (from CS)
;	db	2Eh			; CS:
;	movsw				; copy service routine offset
	mov	es:byte ptr [bx],0eah	; jmp far
	mov	ax,cs:[si]
	inc	si
	inc	si
	mov	es:1[bx],ax
	mov	ax,ds			; finally fixup the segment too
;	stosw
	mov	es:3[bx],ax
	pop	es
	mov	ax,bx
	stosw
	mov	ax,bp
	stosw
	add	bx,5
	loop	def_data_vecs_loop

	mov	es:byte ptr INT30_OFFSET,0EAh
					; fixup CALL 5 JMPF

	mov	si,offset bdosInstanceFixups
InstanceFixupLoop:
	mov	ds:2[si],ds		; fixup data segment
	add	si,6			; onto next item
	mov	ax,ds:[si]		; still BDOS ?
	or	ax,ds:2[si]
	 jnz	InstanceFixupLoop	; yep, do another one

	push	cs			; we will have a RETF
	call	pcmode_reinit		; to return from this call

	pop	ax			; First Free Paragraph
	pop	dx			; Restore the BIOS memory size
	sub	dx,ax			; convert to TPA size
	dec	dx			; Decrement the Size by DMD Size
	push	ax	
	add	ax,dx			; AX = possible next DMD
	mov	es,ax
	mov	al,IDZ			; assume no extra DMD's
	cmp	al,es:DMD_ID		; have we extra one ?
	 jne	pcmode_init10
	mov	al,IDM			; yes, no longer end of chain
	dec	dx			; decrement by size of existing DMD
pcmode_init10:	
	pop	es
	mov	es:DMD_ID,al		; Last DMD in list
	mov	es:DMD_PSP,0000h	; This is Free Memory Owning PSP == 0
	mov	es:DMD_LEN,dx		; Save Memory Length
	mov	es:word ptr DMD_NAME,'S'+256*'D'
	mov	es:DMD_NAME+2,0
	mov	ds:dmd_root,es		; Save the DMD address in root
	retf

;	Entry:		DS	PCM Dseg
;			ES	Interrupt Stubs Seg

pcmode_init2:
	mov	cs:int_stubs_seg,es
;	and	cs:patch_version,not DOSINROM
					; won't clear if we are in ROM...
	mov	cs:pcmode_dseg,ds	; save PCM Dseg
	mov	ds:instanceSeg,ds	; fixup pointer to instance items

; removed this as VxD no longer required   BAP
;	mov	ds:vxdNameSeg,ds	;  and vxdName

;	add	ds:vxdName,dl		; fixup drive letter
	mov	ds:word ptr buf_ptr+2,ds
	mov	ds:word ptr file_ptr+2,ds
	mov	ds:word ptr fcb_ptr+2,ds
	mov	ax,ds:word ptr fcb_ptr
	mov	cl,4
	shr	ax,cl
	and	word ptr ds:fcb_ptr,15
	add	word ptr ds:fcb_ptr+2,ax
;	push	ax			; Save the memory size
;	push	bx			; First Free Paragraph
;	mov	ds:current_dsk,dl	; save initial drive
;	inc	dl			; make drive one based
;	mov	ds:bootDrv,dl		;  and save for func 3305
	mov	ax,ds			; AX = PCMode Data
	mov	ds:word ptr fdos_stub+WORD,ax
	add	ds:dummy_sysdat,ax	; point dummy "sysdat" at a zero word
					;  ie. dummy "secure path" segment
	mov	si,offset countryTable
countryFixupLoop2:
	mov	ds:word ptr 3[si],ds	; fixup the segment
	add	si,5			; onto the next entry
	cmp	ds:word ptr 3[si],0	; done the lot yet ?
	 je	countryFixupLoop2
	mov	es,ax			; ES -> PCMode Data
	mov	di,offset stub_entries	; ES:DI -> stub segs
	mov	cx,NUM_STUB_ENTRIES	; entries to initialise
stubs_loop2:
	add	di,WORD			; skip the offset
	stosw				; fixup segment
	loop	stubs_loop2		; do the next one
	mov	di,offset share_stub	; fixup the SHARE entries
	mov	cx,NUM_SHARE_STUB_ENTRIES
share_loop2:
	add	di,WORD			; skip the offset
	stosw				; fixup segment
	loop	share_loop2
;	mov	cx,0
	mov	es,cx			; Initialize the DOS vectors

;	mov	ax,es:.INT2F_OFFSET	; remember address of BIOS Int 2F
;	mov	ds:int2FBiosHandler,ax
;	mov	ax,es:.INT2F_SEGMENT
;	mov	ds:int2FBiosHandler+2,ax
	mov	ds:int2FNext+2,ds	; fixup seg of out stub

	mov	cx,40h-2Ah		; 2A-3F point at IRET in DOS Data Seg
	mov	di,INT2A_OFFSET
	mov	bp,cs:int_stubs_seg
	xor	bx,bx
	push	es
	mov	es,bp
dummy_vecs_loop2:
	cmp	cx,40h-31h
	 je	dummy_vecs_skip2
;	mov	ax,offset DummyIRET	; point at an IRET
;	stosw				; do the offset
;	mov	ax,ds
	mov	es:3[bx],ds
;	stosw				; then the segment
	add	bx,5
dummy_vecs_skip2:
	loop	dummy_vecs_loop2
	pop	es

;	mov	si,offset def_data_vecs	; the following vector point to
	mov	cx,no_def_data_vecs	; pcmode DATA seg
	push	es
	mov	es,bp
def_data_vecs_loop2:
;	lods cs:ax ! mov di,ax		; Get the Vector Offset (from CS)
;	mov	ax,cs:[si]
;	db	2Eh			; CS:
;	movsw				; copy service routine offset
;	mov	ax,ds			; finally fixup the segment too
;	stosw
	mov	es:3[bx],ds
	add	bx,5
	loop	def_data_vecs_loop2
	pop	es

;	mov	es:byte ptr .INT30_OFFSET,0EAh
					; fixup CALL 5 JMPF

	mov	si,offset bdosInstanceFixups
InstanceFixupLoop2:
	mov	ds:2[si],ds		; fixup data segment
	add	si,6			; onto next item
	mov	ax,ds:[si]		; still BDOS ?
	or	ax,ds:2[si]
	 jnz	InstanceFixupLoop2	; yep, do another one

	push	cs			; we will have a RETF
	call	pcmode_reinit		; to return from this call

;	pop	ax			; First Free Paragraph
;	pop	dx			; Restore the BIOS memory size
;	sub	dx,ax			; convert to TPA size
;	dec	dx			; Decrement the Size by DMD Size
;	push	ax	
;	add	ax,dx			; AX = possible next DMD
;	mov	es,ax
;	mov	al,IDZ			; assume no extra DMD's
;	cmp	al,es:DMD_ID		; have we extra one ?
;	 jne	pcmode_init2_10
;	mov	al,IDM			; yes, no longer end of chain
;	dec	dx			; decrement by size of existing DMD
;pcmode_init2_10:	
;	pop	es
;	mov	es:DMD_ID,al		; Last DMD in list
;	mov	es:DMD_PSP,0000h	; This is Free Memory Owning PSP == 0
;	mov	es:DMD_LEN,dx		; Save Memory Length
;	mov	es:word ptr DMD_NAME,'S'+256*'D'
;	mov	es:DMD_NAME+2,0
;	mov	ds:dmd_root,es		; Save the DMD address in root
	retf

;	
;
; On Entry:
;	DS = DOS data seg

pcmode_reinit:
;=============
	mov	ds:word ptr intl_xlat+2,ds
					; fixup intl case routine
	mov	ds:codeSeg,cs		; fixup code segment


	mov	ax,ds:hashptr		; make a copy of the hashroot
	mov	ds:hashroot,ax		;  so it's global
	mov	ax,ds:hashptr+WORD
	mov	ds:hashroot+WORD,ax
	mov	al,ds:@hist_flg		; get initial history flags
	and	ax,RLF_ENHANCED+RLF_INS+RLF_SEARCH
	mov	ds:cle_state,ax		; use to set initial editing state

	mov	ds:word ptr xmsDriver,offset invalid_stub
	mov	ds:word ptr xmsDriver+2,ds

	mov	bx,offset FirstCodeEntryPoint
pcmode_reinit10:
	mov	ds:3[bx],cs		; fixup segment of the JMPF
	add	bx,8			; onto the next one
	cmp	bx,offset LastCodeEntryPoint
	 jb	pcmode_reinit10
	mov	ax,ds:hmaRoot		; have we established an HMA free chain
	or	ax,ds:hmaAlloc		;  or have any registered users ?
	 jz	pcmode_reinit30		; if so hook for EXEPACK support	
	mov	ax,4300h
	int	2Fh			; do we have an XMS driver ?
	cmp	al,80h			;  80h says yes
	 jne	pcmode_reinit30
	mov	ax,4310h		; get it's entry point
	int	2Fh			;  in ES:BX
	mov	ds:word ptr xmsDriver,bx
	mov	ds:word ptr xmsDriver+2,es

	mov	ax,0FFFFh
	mov	es,ax
	inc	ax			; AX = 0
	mov	es:94h,ax		; zero the HMA alias for Int 21
	mov	es:96h,ax		;  we use this as our A20 gate test

	mov	bx,offset FirstCodeEntryPoint
pcmode_reinit20:
	mov	ax,offset A20Enable-3	; we need a relative offset to
	sub	ax,bx			;  poke in a "call A20Enable"
	xchg	ax,ds:1[bx]		; pick up the entry point segment
	mov	ds:byte ptr 0[bx],0E8h	; CALL NEAR
	mov	ds:byte ptr 3[bx],0EAh	; JMPF
	mov	ds:4[bx],ax		; fixup the offset
	mov	ds:6[bx],cs		; fixup the segment
	add	bx,8			; ready to do the next entry
	cmp	bx,offset LastCodeEntryPoint
	 jb	pcmode_reinit20

	mov	ax,70h			; now fixup the BIOS A20 Enable
	mov	es,ax
	xor	di,di			; patch entry point at 70:0
	mov	al,09Ah			; CALLF
	stosb
	mov	ax,offset BIOSA20Enable
	stosw				; offset
	mov	ax,ds
	stosw				; seg
	mov	al,0C3h
	stosb				; RET

	cmp	ds:codeSeg,0F000h	; have we relocated DOS into the HMA ?
	 jb	pcmode_reinit30		;  if so we must remember it
	or	cs:patch_version,DOSINHMA
pcmode_reinit30:
	retf


def_data_vecs	label word
	dw	INT22_OFFSET, DummyIRET
	dw	INT23_OFFSET, DummyIRET
	dw	INT24_OFFSET, Int24Entry
	dw	INT28_OFFSET, DummyIRET

	dw	INT20_OFFSET, Int20Entry
	dw	INT21_OFFSET, Int21Entry
	dw	INT25_OFFSET, Int25Entry
	dw	INT26_OFFSET, Int26Entry
	dw	INT27_OFFSET, Int27Entry
	dw	INT2F_OFFSET, Int2FEntry
	dw	INT30_OFFSET+1,Call5Entry


no_def_data_vecs	equ	(offset $ - offset def_data_vecs)/4

int_stubs_seg	dw	0

PCM_ICODE ends

end

