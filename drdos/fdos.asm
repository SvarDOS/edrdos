title 'F_DOS - DOS file system'
;    File              : $FDOS.ASM$
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
;    $Log$
;    FDOS.A86 1.23 93/12/15 03:07:08
;    New ddioif entry point so Int 25/26 bypasses address normalisation
;    FDOS.A86 1.20 93/09/03 20:25:47
;    Add "no critical errors" support (int 21/6C)
;    ENDLOG
;
;	This is the DOS support function of Concurrent DOS 6.0
;	It is called via BDOS function #113, with DS:DX pointing
;	to a parameter block. The first word of the parameter
;	block is the subfunction number, the remainder are
;	parameters or return values, depending on the function.

;	Date	   Who	Modification
;	---------  ---	---------------------------------------
;   ?? Feb 86  Initial version
;    7 May 86  speedup MXdisk handling
;   ?? Oct 86  used separate file handle & descriptors
;    5 Nov 86  combined with 5.1 BDOS;           
;    7 Nov 86  added multiple file search
;    8 Nov 86  added open file checking
;    9 Nov 86  added lock/unlock code
;   14 Nov 86  converted to use new deblocking code
;   17 Nov 86  use RWXIOSIF code, select drive for flush
;   18 Nov 86  first attempt to support character devices
;              on WRITE, CLOSE, LSEEK, DATTIM
;   19 Nov 86  some WRITE bugs fixed, MOVE implemented
;              RMDIR redone locally (previously BLACK)
;   24 Nov 86  made changes for linked CDOS.CON
;   27 Nov 86  added FCB function entries for BLACK.A86
;   30 Nov 86  added code to support FUNC13 (DRV_RESET)
;    3 Dec 86  added support for CHDIR ("l:=d:\path");
;   16 Dec 86  update file time stamp on any write
;   23 Jan 86  added support for passwords
;    6 Feb 87  added support for IOCTL status
;   27 Feb 87  updated FCB r/w code to latest spec
;              fixed FDOS_CREAT to truncate size to 0L
;    2 Mar 87  Changed FUNC62 to BDOS62 to avoid conflict
;              with the linked PCMODE
;    7 Mar 87  changed MF_READ to 0-pad partial FCB records
;   17 Mar 87  fixed ES corruption in FCB_TERM code
;   29 Apr 87  Fixed CHDIR bug which failed to return an error when
;              attempting to change to a filename.
;      May 87  fixed some FCB bugs
;   19 May 87  changed password mode for FlexOS compatibility
;              added IOCTL functions
;    4 Jun 87  zeroed current block on DOS FCB open
;   14 Jun 87  round up writes at end if > 1 sector and rt. fringe
;   19 Jun 87  supported freeing up floating drives
;   28 Jul 87  MX moved into individual funcs for DR NET support
;   29 Jul 87  WRITE_DEV moved to outside MXdisk
;    6 Aug 87  fix some password & partial close problems
;              IOCTL(0) bug fixed
;   10 Aug 87  fixed CURDIR path too long problem
;   13 Aug 87  F1',F2' compatibility modes supported
;   20 Aug 87  LOCK_REGION fixed
;    5 Sep 87  lower case DOS FCBs converted to upper case
;    6 Sep 87  free up locked drives on process terminate
;   23 Sep 87  support \path1\path2\devname in DEVICE_ASCIZ:
;   28 Sep 87  use international upper case on ASCIZ paths
;   29 Sep 87  support IOCTL(4), IOCTL(5)
;    7 Oct 87  re-init dir entry on CREAT even if existing file
;              return error if CURDIR can't find parent
;    8 Oct 87  don't release handles on disk change
;              check OPEN_MAX and LOCK_MAX in SYSDAT
;   13 Oct 87  allow reduced F_OPEN if W,D password not supplied
;   22 Oct 87  support pseudo-networked drives via NET_VEC
;   26 Oct 87  use CBLOCK instead of HDSBLK for CP/M FCB check
;              (can now CHDIR between F_OPEN and F_READ)
;   27 Oct 87  reject ".", ".." and " " names on MKDIR, CREAT, MKNEW
;   28 Oct 87  fixed OMODE_COMPAT compatibility checks,
;              call SELECT_HANDLE in VFY_DOS_FCB to support
;              FCB close after CHDIR
;   29 Oct 87  create label in root only, update VLDCNT in DPH
;              delete label in root only, update VLDCNT in DPH
;              also update VLDCNT in CREAT and UNLINK
;              find labels in root if label only search
;    2 Nov 87  return ED_PATH if level doesn't exist in PATH_PREP
;              reject "/path/" as legal ASCIZ specification
;    4 Nov 87  fix release_locks -- didn't work if any locks there
;              test F6' on F_LOCK for file size check
;   10 Nov 87  fix F1' compatibility -- test 80h in P_CMOD
;              support CREAT on file open in compatibility mode
;              by the calling process
;   11 Nov 87  attempt to support multiple compatibility opens
;              by several processes in read access mode or
;              deny write/read access modes and still have the
;              rest of the file sharing working...
;              use PCM_ROUT as BIN flag for console handles
;   12 Nov 87  fix file sharing test on MF_OPEN (HM_FCB)
;              fix DOS FCB rename of open file (WS 3.x)

;	19 Nov 87  	Release 6.0/2.0
;	---------	---------------

;   21 Nov 87  make NUL device first device in the list
;    1 Dec 87  various network fixes (dup, exec, exit, etc.)
;    2 Dec 87  implement DOS FCB calls across DR Net
;    3 Dec 87  fix CHECK_NOT_OPEN (CALL FILE_UPDATE) (fixes CB86)
;    4 Dec 87  pass drive on network FCB calls
;    7 Dec 87  supported FCB reads/writes across network (via handles)
;   10 Dec 87  fixed month dependant MKDIR bug.
;   11 Dec 87  fixed networked CURDIR bug (for SUBST)
;    5 Jan 88  don't delete labels via FDOS_UNLINK,
;              don't access labels via FDOS_CHMOD
;    7 Jan 88  make NUL device first device in chain, in SYSDAT
;   12 Jan 88  setup MAKE_FLAG in FCB_MAKE_TEST
;   15 Jan 88  prevent SUBSTitution of networked drives
;    9 Feb 88  temporarily force door open interrupts
;              add GET_FHND, FREE_FHND for dynamic handle create
;   10 Feb 88  update file size in DOS FCB for AutoCAD
;   15 Feb 88  update CUR_IFN in OPEN_HANDLE for MF_OPEN FCB setup
;   25 Feb 88  pass correct unit to driver on generic IOCTL request
;              fix removable media check with DOS drivers
;    3 Mar 88  permit multiple compatibility mode opens
;    9 Mar 88  CHDIR ("d:=") always handled locally
;              reject CHMOD on character devices
;              use LUL_ALLOC for lock list allocation
;   10 Mar 88  Get PSP_XFNMAX before corrupting ES (RMCOBOL)
;   15 Mar 88  split file into three include files
;   28 Jul 88  Support PCMODE Private Device List
;   29 Jul 88  make PRN=LPT1, AUX=COM1
;   27-Feb-89  change PID equate for CDOS, work around RASM bug
;              ("PID equ RLR" would cause external ref's to PID!)
;   29-Jun-89  Split off IOCTL into seperate module
;   11-Sep-89  Split off MSNET into seperate module

PCMCODE	GROUP	BDOS_CODE
PCMDATA	GROUP	BDOS_DATA,PCMODE_DATA

ASSUME DS:PCMDATA

	.nolist
	include psp.def
	include modfunc.def
	include fdos.equ
	include request.equ
	include msdos.equ
	include mserror.equ
	include doshndl.def	; DOS Handle Structures
	include driver.equ
	include f52data.def	; DRDOS Structures
	include bdos.equ
	.list

FD_EXPAND equ 55h

PCMODE_DATA	segment public byte 'DATA'

	extrn	current_ddsc:dword
	extrn	current_device:dword
	extrn	current_dhndl:dword
	extrn	current_dsk:byte	; default drive
	extrn	current_ifn:word
	extrn	current_ldt:dword
	extrn	current_psp:word	; PSP segment
	extrn	dev_root:dword
	extrn	dma_offset:word		; DTA offset
	extrn	dma_segment:word	; DTA segment
	extrn	file_ptr:dword
	extrn	fdos_stub:dword
	extrn	internal_flag:byte
	extrn	ioexerr:byte
	extrn	join_drv:byte
	extrn	last_drv:byte
	extrn	ldt_ptr:dword		; Pointer to LDT's for the drives
	extrn	lock_tables:dword
	extrn	machine_id:word		; remote process
	extrn	name_buf:byte		; 32 byte name buffer
	extrn	nul_device:dword	; NUL in PCMODE data segment
	extrn	owning_psp:word		; remote PSP segment
	extrn	phys_drv:byte
	extrn	remote_call:word	; remote machine flag
	extrn	share_stub:dword
	extrn	srch_buf:byte
	extrn	pri_pathname:byte
	extrn	sec_pathname:byte
	extrn	temp_ldt:byte
	extrn	unlock_tables:dword
	extrn   WindowsHandleCheck:byte
	extrn	net_delay:word
	extrn lfnpathflag:byte

ifdef KANJI
	extrn	DBCS_tbl:word		; Double Byte Character Table
endif

PCMODE_DATA	ends

BDOS_DATA	segment public word 'DATA'

	extrn	adrive:byte
	extrn	cur_dma:word
	extrn	cur_dma_seg:word
	extrn	mult_sec:word
	extrn	rwmode:byte
	extrn	valid_flg:byte
	extrn	dosfat:word

chdir_cl	dw	0,0
chkcds_cl	dw	0,0

NO_CRIT_ERRORS	equ	01000000b	; critical error shouldn't be generated
					; warning - must match PCMODE.EQU
	
	extrn	fdrwflg:byte
	extrn	chdblk:word
	extrn	dcnt:word
	extrn	dirp:word
	extrn	dirperclu:word
	extrn	finddfcb_mask:word
	extrn	hdsaddr:word
	extrn	intl_xlat:dword
	extrn 	lastcl:word
	extrn	blastcl:word
	extrn	logical_drv:byte
	extrn	pblock:dword
	extrn	physical_drv:byte
	extrn	req_hdr:byte
	

	extrn	yearsSince1980:word
	extrn	month:byte
	extrn	dayOfMonth:byte
	extrn	hour:byte
	extrn	minute:byte
	extrn	second:byte

orig_drive	dw	0
path_drive	dw	0


	Public	fdos_hds_blk, fdos_hds_root, fdos_hds_drv

fdos_hds	label word		; temporary HDS that we make up
fdos_hds_blk	dw	0,0
fdos_hds_root	dw	0,0
fdos_hds_drv	db	0

HDS_LEN		equ	offset $ - offset fdos_hds

saved_hds	label word		; saved HDS on F_DOS rename
saved_hds_blk	dw	0,0
saved_hds_root	dw	0,0
saved_hds_drv	db	0

saved_dcnt	dw	0		; saved DCNT on F_DOS rename

dta_ofl		db	0		; non-zero if read/write > DTA size

extflg		dw	0		; DOS FCB was extended FCB

blk		dw	0,0		; temp variable for cluster #

attributes	db	0		;fcb interface attributes hold byte

	public	info_fcb
info_fcb	db	1+8+3 dup (0)	;local user FCB drive+name+ext

save_area	db	32 dup (0)	;save area for dirbuf during rename and
					;info_fcb during create(mustbe_nolbl)
					;parental name during chdir

;	local variables for fdos operations

sp_save		dw	0

fdos_addr	dw	0		; address of F_DOS function

	Public	fdos_info, fdos_pb, fdos_ret
	
fdos_info	dw	3 dup (0)	; off, seg, size of parameter block
fdos_pb		dw	7 dup (0)	; copy of parameter block
fdos_ret	dw	0		; return value for function

ifdef PASSWORD
; Password support uses the following data stuctures:
;
; The global_password field is set by an IOCTL call and remains constant.
;
; When a password is encountered during parsing a path the ASCII form is
; copied into the password_buffer. It is then encrypted and stored in the
; local_password field. If a password protected file is encountered then
; it's encrypted password is compared with both the global and local passwords.
;
; During a file/directory create the local_password field is examnined. If
; non-zero then this encrypted password is applied to the file, which is given
; full protection.
;
	Public	global_password
global_password	dw	0
local_password	dw	0
password_buffer	db	8 dup (0)

endif

BDOS_DATA	ends

BDOS_CODE	segment public byte 'CODE'


	extrn	pcmode_dseg:word	; Pointer to System Data Page

	extrn	get_ldt:near
	extrn	get_ldt_raw:near
	extrn	islocal:near		; redirector support
	extrn	redir_asciiz_offer:near
	extrn	redir_asciiz_dev_offer:near
	extrn	redir_asciiz_file_offer:near
	extrn	redir_drv_offer:near
	extrn	redir_dhndl_offer:near
	extrn	redir_move_offer:near
	extrn	redir_snext_offer:near

	extrn	alloc_cluster:NEAR
	extrn	allocdir:NEAR		; will extend subdirectory if full
	extrn	buffers_check:near
	extrn	discard_all:near
	extrn	close_dev:near		; close character device handle
	extrn	delfat:NEAR
	extrn	fdosrw:near		; read/write from/to disk file
	extrn	finddfcb:NEAR		; find next matching directory entry
	extrn	finddfcbf:NEAR		; find first matching directory entry
	extrn	first_dev:near		; find first matching character device
	extrn	fill_dirbuf:near
	extrn	flush_dirbuf:near
	extrn	flush_drive:near
	extrn	get_ddsc:near
	extrn	getdir:NEAR
	extrn	getnblk:NEAR
	extrn	hshdscrd:near		; discard hashing for drive AL

	extrn	mark_ldt_unsure:near
	extrn	redir_build_path:near	; build ASCII path

	extrn	open_dev:near		; open character device handle
	extrn	dup_dev:near		; call device driver on handle dup
	extrn	read_dev:near		; read from character device
	extrn	ReadTimeAndDate:near	; read date/time from CLOCK driver
	extrn	blockif:near
	extrn	ddioif:near
	extrn	select_logical_drv:near
	extrn	select_physical_drv:near
	extrn	setenddir:NEAR
	extrn	update_dat:NEAR		; flush dirty data buffers
	extrn	update_ddsc_free:NEAR	; count free blocks on drive
	extrn	update_dir:NEAR		; flush modified directory buffer
	extrn	update_fat:NEAR
	extrn	write_dev:near		; write to character device
	extrn	zeroblk:near		; fill cluster with 0's
	extrn	is_lfn:near		; check if long filename entry
	extrn	del_lfn:near		; delete long filenames

	public	bpb2ddsc		; build DDSC from a BPB
	Public	check_slash
	public	dbcs_lead
	public	discard_files		; discard open files (unconditional)
	public	fdos_ED_DRIVE		; Return ED_DRIVE error
	public	fdos_ED_FUNCTION	; Return ED_FUNCTION error
	public	find_dhndl
	public	find_xfn
	public	get_pb2_drive
	public	release_handle		; release file handle
	public	toupper			; upper case a character
	Public	unparse
	public	update_dir_fat		; flush DIR then FAT to disk
	public	get_path_drive		; get drive number for given path
	public	path_prep
	public	check_no_wild

	public	fdos_getdpb	; 0-disk information
	public	fdos_mkdir	; 1-make directory
	public	fdos_rmdir	; 2-remove directory
	public	fdos_chdir	; 3-change directory
	public	fdos_creat	; 4-create file
	public	fdos_open	; 5-open file
	public	fdos_close	; 6-close file
	public	fdos_read	; 7-read from file
	public	fdos_write	; 8-write to file
	public	fdos_unlink	; 9-delete file
	public	fdos_lseek	; 10-set file pointer
	public	fdos_chmod	; 11-get/set file attributes
	public	fdos_curdir	; 12-get current directory
	public	fdos_first	; 13-find first matching file
	public	fdos_next	; 14-find next matching file
	public	fdos_move	; 15-rename file
	public	fdos_dattim	; 16-get/set file name
	public	fdos_flush	; 17-flush buffers
	public	fdos_mknew	; 18-make new file
	public	fdos_lock	; 19-lock/unlock block
	public	fdos_dup	; 20-duplicate handle
	public	fdos_fdup	; 21-force duplicate handle
	extrn	fdos_fcb:near	; 22-FCB emulation
	public	fdos_exec	; 23-create child PSP
	extrn	fdos_exit:near	; 24-FCB close for PSP
	public	fdos_ddio	; 25-direct disk access
	extrn	fdos_ioctl:near	; 26-IOCTL emulation
	public	fdos_commit	; 27-commit file
	public	fdos_expand	; 28-expand file name
	public	fdos_mkddsc	; 29-build DDSC from BPB
	public	fdos_select	; 30-select drive

ifdef JOIN
	Public	check_join
	Public	mv_join_root
endif

BDOS_CODE	ends

include	funcs.fdo
include	utils.fdo

BDOS_DATA	segment public word 'DATA'

BDOS_DATA	ends

	END
