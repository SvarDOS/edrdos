;    File              : $Workfile: DOSIF.ASM$
;
;    Description       :
;
;    Original Author   : 
;
;    Last Edited By    : $Author: RGROSS$
;
;    Copyright         : (C) 1992 Digital Research (UK), Ltd.
;                                 Charnham Park
;                                 Hungerford, Berks.
;                                 U.K.
;
;    *** Current Edit History ***
;    *** End of Current Edit History ***
;
;    $Log: $
;    DOSIF.ASM 1.1 94/06/28 16:01:14 RGROSS
;    Initial PUT
;    DOSIF.ASM 1.16 94/06/28 16:01:28 IJACK
;    ms_x_expand returns error codes (for benefit of TRUENAME)
;    DOSIF.ASM 1.15 93/11/29 19:57:24 IJACK
;    
;    --------
;    
;    DOSIF.ASM 1.13 93/09/09 10:24:50 RFREEBOR
;    call_novell() now returns all allowed error codes.
;    
;    DOSIF.ASM 1.12 93/02/24 17:42:49 EHILL
;    _get_scr_width() function added.
;    
;    DOSIF.ASM 1.11 93/01/21 16:19:31 EHILL
;    
;    DOSIF.ASM 1.10 93/01/21 14:32:32 EHILL
;    
;    DOSIF.ASM 1.8 92/09/11 10:46:28 EHILL
;    
;    DOSIF.ASM 1.7 92/08/06 09:56:07 EHILL
;    Added DOS 5 calls to get and set memory allocation strategy and
;    upper memory link.
;    
;    DOSIF.ASM 1.6 92/07/10 17:47:13 EHILL
;    No comment
;
;    ENDLOG
;
;	This file provides all the assembler level interfaces to the
;	underlying operating system that are required by COMMAND.COM.
;	The type of functions calls that will be made is controlled
;	by a Assemble time flag.
;
;	Currently the Operating System Interfaces that are supported
;	are MS-DOS and Concurrent DOS 6.0.
;
;
;	Command Line Flags
;	==================
;
;	MSDOS		If defined then USE MSDOS function Calls
;	CDOS		If defined then Use Concurrent DOS Calls
;
;
;  2/Sep/87 jc	Convert the Concurrent IOCTL function to use the FDOS
;		command.
; 19/Oct/87 jc	Handle Fail on Get current directory correctly
; 23/Feb/88 jc	Use Text substitution function to get the path assigned
;		to floating drives (ms_x_subst).
;  3/Mar/88 jc	Support Server Password Error
;  9/Mar/88 jc	Return a NULL terminated string when an error occurs on the
;		ms_x_subst function.
; 15/Mar/88 jc	Correct ms_x_subst register corruption bug
; 13/Apr/88 jc	Support the FAR_READ and FAR_WRITE routines as well as external
;		copy buffer allocation via MEM_ALLOC and MEM_FREE
; 20/May/88 jc	Return the current country code to the calling application
; 25/May/88 jc	Missing dataOFFSET causing garbage offset to be passed
;		ms_x_subst.
; 18/Jul/88 jc	Modify LOGICAL_DRV test to detect substituted physical drives
; 17/Aug/88 jc	Return the current Break Status using DL not AL
; 22/Sep/88 jc	Replace MS_X_SUBST with more general MS_X_EXPAND routine
; 25/Jan/89 ij	If new DRDOS internal data layout get DPHTBL the new way
; 07/Feb/89 jc	Add the Get and Set Global Codepage MS_X_GETCP/MS_X_SETCP
; 25/Jan/89 ij	Get DPHTBL using DRDOS_DPHTBL_OFFSET equate
; 14/Apr/89 jjs	Add ms_x_setdev
; 31/May/89 ij	Get SYSDAT for DPHTBL using new f4458 function 
; 19/May/89 jc	Remove "Alternative" techniques of getting SYSDAT:DPHTABLE
; 20/Jun/89 js	ms_f_parse, ms_f_delete, for DEL cmd
; 30/Aug/89 js  ms_idle_ptr
;  6/Sep/89 ij	network_drvs really does something on DRDOS
; 16/Oct/89 ach Added double byte character set support routines: dbcs_init,
;		dbcs_expected and dbcs_lead.
; 18/Jan/90 ij	HILOAD interfaces added
;  4/Apr/90 ij	dbcs_init moved to cstart, use system table, then we can throw
;		away the init code
; 24-May-90 ij	ms_x_expand sets up ES....
; 17 Sep 90 ij	TMP Control Break kludge echo's ^C to console
;  4 Oct 90 ij	Use P_CAT, not P_HDS
; 15 Mar 91 jc	DRDOS_DPHTBL is now called SYSDAT_DPHTBL cos thats where it lives
; 28 May 91 ejh No longer use SYSDAT to determine if drives are physical,
;		logical or networked. See _physical_drive, _logical_drive and
;		_network_drive.
; 23 Jun 91 ejh SUBST and ASSIGN are now external commands, so the following
;		are no longer required:
;			_physical_drvs, _logical_drvs, _network_drvs
;			_physical_drive,_logical_drive,_network_drive
;  3 jul 91 ij	except for NETDRIVE in MDOS
;
; 18 Jun 92 ejh Added get_lines_page() function.
; 24 Jun 92 ejh Added novell_copy() function.

CGROUP	group	_TEXT
DGROUP	group	_DATA

codeOFFSET	equ	offset CGROUP:
dataOFFSET	equ	offset DGROUP:

EXT_SUBST	equ	1		; External Subst and Assign commands

CRET	MACRO	num
	ret
	ENDM

ifndef	??Version			;; Turbo Assembler always knows RETF
ifndef	retf				;; some versions of MASM do as well
retf	macro				;; define far return macro for others
	db	0cbh
	endm
endif
endif


ifndef	CDOSTMP
include	msdos.equ
endif

ifndef DOSPLUS
include system.def
include pd.def
include	ccpm.equ
;include udaa.def
include	net.def
include	mserror.equ
else
include	f52data.def
endif
;
ifdef	CDOSTMP
OK_RIF		equ	00111000b	; All Responsese are Valid
OK_RI		equ	00110000b	; Retry and Ignore are Valid
OK_RF		equ	00011000b	; Retry and Fail are Valid
;
;		      Structure of DOS DPB
;		      --------------------
;	The  layout  of  this  structure  is  a  guess  based  on
;	examples.  It is returned by PC MODE on functions 1Fh and
;	32h  and is required  by various  disk-related  utilities
;	like disk editors and CHKDSK.

DDSC_UNIT	equ	es:byte ptr 0		; absolute drive number
DDSC_RUNIT	equ	es:byte ptr 1		; relative unit number
DDSC_SECSIZE	equ	es:word ptr 2		; sector size in bytes
DDSC_CLMSK	equ	es:byte ptr 4		; sectors/cluster - 1
DDSC_CLSHF	equ	es:byte ptr 5		; log2 (sectors/cluster)
DDSC_FATADDR	equ	es:word ptr 6		; sector address of FAT
DDSC_NFATS	equ	es:byte ptr 8		; # of FAT copies
DDSC_DIRENT	equ	es:word ptr 9		; size of root directory
DDSC_DATADDR	equ	es:word ptr 11		; sector address of cluster #2
DDSC_NCLSTRS	equ	es:word ptr 13		; # of clusters on disk
DDSC_NFATRECS	equ	es:byte ptr 15		; # of sectors per FAT
DDSC_DIRADDR	equ	es:word ptr 16		; sector address of root dir
DDSC_DEVHEAD	equ	es:dword ptr 18		; device driver header
DDSC_MEDIA	equ	es:byte ptr 22		; current media byte
DDSC_FIRST	equ	es:byte ptr 23		; "drive never accessed" flag
DDSC_LINK	equ	es:dword ptr 24		; next drive's DDSC
DDSC_BLOCK	equ	es:word ptr 28		; next block to allocate
DDSC_FREE	equ	es:word ptr 30		; total free clusters on drive
DDSC_MAP	equ	es:word ptr 32		; free blocks/FAT sector
endif

BDOS_INT	equ	224		; ##jc##


_DATA	SEGMENT	byte public 'DATA'
	extrn	__psp:word
ifndef DOSPLUS
	extrn	_pd:dword		; Process Descriptor Pointer
endif
	extrn	_country:WORD

ifdef DOSPLUS
	extrn	dbcs_table_ptr:dword	; points to system DBCS table
endif

ifdef CDOSTMP
;
;	The following buffer is used by the P_PATH function.
;	FINDFILE uses the first three fields to get the full path and
;	filename of the command. 
;
exec_block	label	byte
exec_pathoff	dw	?		; Offset of ASCIIZ Load file
exec_pathseg	dw	?		; Segment of ASCIIZ Load File
exec_filetype	db	?		; File Type Index

fdos_data	dw	7 dup(0)	; FDOS parameter Block

mpb_start	dw	?		; Memory parameter Block
mpb_min		dw	?
mpb_max		dw	?
mpb_pdadr	dw	?
mpb_flags	dw	?

mfpb_start	dw	?		; Memory Free Parameter Block
mfpb_res	dw	?

country_data	label	word		; GET country data
cd_country	dw	?		; Requested Country Code
cd_codepage	dw	?		; Requested Code Page
cd_table	dw	?		; Table Number
cd_offset	dw	?		; Buffer Offset
cd_segment	dw	?		; Buffer Segment

valid		dw	0		; Valid Error Responses
retry_ip	dw	0		; Critical Error Retry IP
retry_sp	dw	0		; Critical Error Retry SP
crit_flg	db	FALSE		; Critical Section of Error Handler

include fdos.def
endif

ifdef NETWARE
ipx		label	dword
ipx_offset	dw	0
ipx_segment	dw	0
;
;	Socket Allocation by Novell
;
;	Socket Nos 4000 and 4001 appear to be used by the IPX internally
;	and these are NOT closed by the NET_WARE routine. All other USER
;	sockets are closed.
;
;	List of sockets to be closed on shutdown
;			Start	Count
socket		label	word
;;		dw	0001h,	0BB8h
		dw	4002h,	3FFFh - 2	; User Socket Numbers
		dw	0, 0

aes		label 	byte		; Event Control Block
aes_link	label	dword		; Link Field
aes_linkoff	dw	0
aes_linkseg	dw	0
aes_esr		label	dword		; Service Routine Address
aes_esroff	dw	codeOFFSET aes_retf
aes_esrseg	dw	0000
aes_inuse	db	0		; Flag Field
aes_workspc	db	5 dup(?)	; AES WorkSpace
endif
_DATA	ENDS

_TEXT	SEGMENT	byte public 'CODE'
	assume	cs:CGROUP, ds:DGROUP, es:DGROUP

extrn	_int_break:near		; Control-C Break Handler

ifdef	CDOSTMP
ifdef MWC
extrn	_critical_error:near	; Default Critical Error Handler
CRITICAL_ERR	equ	_critical_error
else
extrn	CRITICAL_ERROR:near	; Default Critical Error Handler
CRITICAL_ERR	equ	CRITICAL_ERROR
endif
endif

;
;	UWORD	psp_poke(WORD handle, BYTE ifn);
;
	Public	_psp_poke
_psp_poke:
	push	bp
	mov	bp,sp
	push	es

ifdef CDOSTMP
	mov	es,__psp		; ES:0 -> our PSP
else
	mov	ah,MS_P_GETPSP
	int	DOS_INT			; for software carousel
	mov	es,bx
endif
	les	bx,es:[0034h]		; ES:BX -> external file table
	add	bx,4[bp]		; ES:BX -> XFT entry for our handle
	mov	al,6[bp]		; get new value to use
	xchg	al,es:[bx]		; get old value, set new value
	xor	ah,ah

	pop	es
	pop	bp
	ret

ifndef	CDOSTMP


	Public	_ms_drv_set
;-----------
_ms_drv_set:
;-----------
	push	bp
	mov	bp,sp
	mov	dl,04[bp]
	mov	ah,MS_DRV_SET		; Select the Specified Disk Drive
	int	DOS_INT			; Nothing Returned to caller
	pop	bp
	ret

	Public	_ms_drv_get
;-----------
_ms_drv_get:
;-----------
	mov	ah,MS_DRV_GET		; Return the Currently selected
	int	DOS_INT			; disk drive
	cbw
	ret

	Public	_ms_drv_space
;------------
_ms_drv_space:
;------------
;
;	ret = _ms_drv_space (drive, &free, &secsiz, &nclust);
;	where:	drive	= 0, 1-16 is drive to use
;		free    = free cluster count
;		secsiz  = bytes/sector
;		nclust	= clusters/disk
;		ret	= sectors/cluster -or- (0xFFFFh)

	push	bp
	mov	bp,sp
	mov	dx,4[bp]
	mov	ah,MS_DRV_SPACE
	int	DOS_INT
	push	bx
	mov	bx,6[bp]		; get free cluster count
	pop	word ptr [bx]
	mov	bx,8[bp]
	mov	[bx],cx			; bytes/sector
	mov	bx,10[bp]
	mov	[bx],dx			; clusters/disk
	cbw
	pop	bp
	ret

	Public	_ms_s_country
;------------
_ms_s_country:
;------------
	push	bp
	mov	bp,sp
	mov	ax,MS_S_COUNTRY shl 8	; Get the curremt country information
	mov	dx,4[bp]		; and return the current country code
	int	DOS_INT			; to the calling application.
	mov	ax,bx
	pop	bp
	ret


	Public _ms_x_mkdir
;----------
_ms_x_mkdir:
;----------
	mov	ah,MS_X_MKDIR
	jmp	ms_dx_call


	Public	_ms_x_rmdir
;----------
_ms_x_rmdir:
;----------
	mov	ah,MS_X_RMDIR
	jmp	ms_dx_call


	Public	_ms_x_chdir
;----------
_ms_x_chdir:
;----------
	mov	ah,MS_X_CHDIR
	jmp	ms_dx_call

	Public	_ms_x_creat
;----------
_ms_x_creat:
;----------
	mov	ah,MS_X_CREAT
	jmp	ms_open_creat


	Public	_ms_x_open
;---------
_ms_x_open:
;---------
	mov	ah,MS_X_OPEN
ms_open_creat:
	push	bp
	mov	bp,sp
	mov	dx,4[bp]
	mov	cx,6[bp]		; get mode for new file (CREAT)
	mov	al,cl			;          or open mode (OPEN)
	int	DOS_INT
	jnc	ms_open_ret		; AX = handle if no error
	neg	ax			; else mark as error code
ms_open_ret:
	pop	bp
	ret

	Public _ms_x_close
;----------
_ms_x_close:
;----------
	push	bp
	mov	bp,sp
	mov	bx,4[bp]		; get the open handle
	mov	ah,MS_X_CLOSE		; get the function
	jmp	ms_call_dos		; call DOS, handle errors

	Public	_ms_x_unique
;----------
_ms_x_unique:
;----------
	mov	ah,MS_X_MKTEMP
	jmp	ms_open_creat

	Public	_ms_x_fdup
;----------
_ms_x_fdup:
;----------
	push	bp
	mov	bp,sp
	mov	cx,4[bp]		; get the destination handle
	mov	bx,6[bp]		; Get the current handle	
	mov	ah,MS_X_DUP2		; get the function
	jmp	ms_call_dos		; call DOS, handle errors


	Public	_far_read
;---------
_far_read:
;---------
	mov	ah,MS_X_READ
	jmp	far_read_write

	Public	_far_write
;----------
_far_write:
;----------
	mov	ah,MS_X_WRITE
far_read_write:
	push	bp
	mov	bp,sp
	push	ds
	mov	bx,4[bp]		; get file handle
	lds	dx,dword ptr 6[bp]	; get buffer address
	mov	cx,10[bp]		; get byte count
	int	DOS_INT			; call the DOS
	jnc	far_rw_ok		; skip if no error
	neg	ax			; else make it negative error code
far_rw_ok:
	pop	ds
	pop	bp
	ret


	Public	_ms_x_read
;---------
_ms_x_read:
;---------
	mov	ah,MS_X_READ
	jmp	ms_read_write

	Public	_ms_x_write
;----------
_ms_x_write:
;----------
	mov	ah,MS_X_WRITE
ms_read_write:
	push	bp
	mov	bp,sp
	mov	bx,4[bp]		; get file handle
	mov	dx,6[bp]		; get buffer address
	mov	cx,8[bp]		; get byte count
	int	DOS_INT			; call the DOS
	jnc	ms_rw_ok		; skip if no error
	neg	ax			; else make it negative error code
ms_rw_ok:
	pop	bp
	ret

	Public	_ms_x_unlink
;-----------
_ms_x_unlink:
;-----------
	mov	ah,MS_X_UNLINK
	jmp	ms_dx_call


	Public	_ms_x_lseek
;----------
_ms_x_lseek:
;----------
	push	bp
	mov	bp,sp
	mov	ah,MS_X_LSEEK		; get the function
	mov	bx,4[bp]		; get the file handle
	mov	dx,6[bp]		; get the offset
	mov	cx,8[bp]
	mov	al,10[bp]		; get the seek mode
	int	DOS_INT
	jnc	ms_lseek_ok		; skip if no errors
	neg	ax			; make error code negative
	cwd				; sign extend to long
ms_lseek_ok:
	mov	bx,dx			; AX:BX = DRC long return
	pop	bp
	ret

	Public	_ms_x_ioctl
;----------
_ms_x_ioctl:
;----------
	push	bp
	mov	bp,sp
	mov	bx,4[bp]		; get our handle
	mov	ah,MS_X_IOCTL		; get IO Control function
	mov	al,0			; get file/device status
	int	DOS_INT			; do INT 21h
	jnc	ms_x_i10
	neg	ax
ms_x_i10:	
	pop	bp			; 
	ret

	Public	_ms_x_setdev
;------------
_ms_x_setdev:
;------------
	push	bp
	mov	bp, sp
	mov	bx, 4[bp]		; handle
	mov	dx, 6[bp]		; byte value to set
	sub	dh, dh
	mov	ah, MS_X_IOCTL
	mov	al, 1
	int	DOS_INT
	jnc	ms_x_sd10
	neg	ax
ms_x_sd10:
	pop	bp
	ret

	Public	_ms_x_chmod
;----------
_ms_x_chmod:
;----------
	push	bp
	mov	bp,sp
	mov	ah,MS_X_CHMOD
	mov	dx,4[bp]
	mov	cx,6[bp]
	mov	al,8[bp]
	int	DOS_INT
	jnc	ms_chmod_ok
	neg	ax			; make error code negative
	jmp	ms_chmod_ret
ms_chmod_ok:
	sub	ax,ax			; assume no error
	cmp	byte ptr 8[bp],0	; getting attributes
	jne	ms_chmod_ret		; return ax = 0 if setting & no error
	xchg	ax,cx			; return ax = attrib otherwise
ms_chmod_ret:
	pop	bp
	ret


	Public	_ms_x_curdir
;-----------
_ms_x_curdir:
;-----------
	push	bp
	mov	bp,sp
	push	si
	mov	si,6[bp]		; Get the buffer address and 
	mov	byte ptr [si],0		; put a zero in the first byte in
	mov	ah,MS_X_CURDIR		; the command is FAILED
	push	word ptr 4[bp]
	call	ms_dx_call
	pop	dx
	pop	si
	pop	bp
	ret

	Public _ms_x_exit
;---------
_ms_x_exit:
;---------
	push	bp
	mov	bp,sp

ifdef NETWARE
	push	es			; If this is Novell Netware and
	mov	ax,__psp		; the command processor is terminating
	mov	es,ax			; ie PSP_PARENT == PSP then do the
	cmp	ax,es:word ptr 16h	; special Novell Close down sequence
	pop	es
	jnz	ms_x_exit10

	mov	ax,7A00h		; Check for IPX being present using
	int	2Fh			; the Multi-Plex Interrupt.
	cmp	al,0FFh
	jz	net_ware

ms_x_exit10:
endif
	mov	al,04[bp]		; Get the Return Code
	mov	ah,MS_X_EXIT		; terminate process function
	int	DOS_INT			; call the DOS
	pop	bp
	ret

ifdef NETWARE
;
;	The following routine attempts to clean-up after a Novell 
;	session. It does so in the following manner:-
;
;	1)	Close all file handles (May be Networked !!)
;	2)	Close all User Sockets
;	3)	Remove all User Events from Internal lists
;	4)	Use CDOS terminate function
;
net_ware:
	mov	ipx_offset,di
	mov	ipx_segment,es

	mov	cx,20			; Close all the possible handles 
	mov	bx,0			; used by the command processor
net_w05:				; in case any have been redirected
	mov	ah,MS_X_CLOSE		; accross the Network
	int	DOS_INT
	inc	bx
	loop	net_w05

	mov	si,dataOFFSET socket
net_w10:
	mov	cx,word ptr 02[si]	; Get the number of sockets to close
	mov	dx,word ptr 00[si]	; starting at Socket No.
	jcxz	net_w30			; Terminate on a 0 Count
	push	si
net_w20:
	push	cx
	push	dx			; Save Count and Socket No.
	xchg	dl,dh			; Swap socket no to High/Low
	mov	bx,1			; Close Socket Function
	call	ipx			; Close Socket.
	pop	dx
	pop	cx
	inc	dx			; Increment Socket No
	loop	net_w20			; and Loop
	pop	si	
	add	si,4			; Point to next entry in the array
	jmp	net_w10			; and repeat till count is 0

net_w30:				; All sockets have been closed
	mov	aes_esrseg,cs
	mov	ax,0FFFFh		; Create Special event with the 
	mov	bx,7			; maximum time delay
	push	ds
	pop 	es			; Pass the address of the Special
	mov	si,dataOFFSET aes	; Event control block call the IPX
	call	ipx

net_w40:
	les	si,aes_link		; Remove all entries from the Link
					; Which are not owned by the IPX
net_w50:
	mov	bx,es			; get the AES segment
	cmp	bx,ipx_segment		; and check for a match
	jnz	net_w60			; Remove this entry
	les	si,es:dword ptr [si]	; get the next entry and try again
	jmp short net_w50

net_w60:
	or	bx,si			; End of List
	jz	net_w70			; Yes terminate our entry
	mov	bx,0006h		; Cancel this event
	call	ipx
	jmp short net_w40

net_w70:
	mov	bx,0006h		; Cancel our event
	push	ds
	pop 	es
	mov	si,dataOFFSET aes
	call	ipx
	
net_exit:
	mov	dh,0			; Standard Exit
	mov	dl,04[bp]		; With the supplied ExitCode
	mov	cx,P_EXITCODE		; Set the ExitCode for the Parent
	int	BDOS_INT
	mov	cx,P_TERMCPM		; Use a Concurrent Terminate Call
	int	BDOS_INT		; because Novell has taken over 4Ch

aes_retf:				; Dummy AES routine
	retf
endif

;
;	ms_x_expand(dstbuf, srcbuf) returns the full path of SRCBUF
;
	Public	_ms_x_expand
;-----------
_ms_x_expand:
;-----------
	push	bp
	mov	bp,sp
	push	si
	push	di
	mov	si,06[bp]		; Get the source String Address
	mov	di,04[bp]		; Get the destination string
	mov	byte ptr [di],0		; address and force it to be a NULL
	push	ds
	pop	es			; ES:DI -> destination
	mov	ah,60h			; terminated string in case of errors
	int	DOS_INT
	jc	ms_exp_ret		; skip if error
	xor	ax,ax			; signal no errors
ms_exp_ret:
	neg	ax			; make error negative, 0 = 0
	pop	di
	pop	si
	pop	bp
	CRET	4

	Public	_ms_x_wait
;---------
_ms_x_wait:		; retrieve child return code
;---------
	mov	ah,MS_X_WAIT		; Top byte is abort code ie ^C
	int	DOS_INT			; Bottom byte is return code
	ret

	Public	_ms_x_first
;----------
_ms_x_first:
;----------
	push	bp
	mov	bp,sp
	mov	dx,8[bp]		; get DMA buffer address
	mov	ah,MS_F_DMAOFF
	int	DOS_INT
	mov	dx,4[bp]		; get ASCII string
	mov	cx,6[bp]		; get attribute
	mov	ah,MS_X_FIRST		; get search function
	jmp	ms_call_dos		; call DOS, check for errors

	Public	_ms_x_next
;---------
_ms_x_next:
;---------
	push	bp
	mov	bp,sp
	mov	dx,4[bp]		; get DMA buffer address
	mov	ah,MS_F_DMAOFF
	int	DOS_INT
	mov	ah,MS_X_NEXT		; get the function
	jmp	ms_call_dos		; get DX, call DOS, handle errors

ms_dx_call:				; call DOS with parameter in DX
	push	bp
	mov	bp,sp
	mov	dx,4[bp]
ms_call_dos:
	int	DOS_INT
	jnc	ms_dos_ok		; no carry = no error
	neg	ax			; else make it negative
	jmp	ms_dos_ret		; and return with error
ms_dos_ok:
	sub	ax,ax			; return 0 if no error
ms_dos_ret:
	pop	bp			; return 0 or negative error code
	ret


	Public _ms_x_rename
;-----------
_ms_x_rename:
;-----------
	push	bp
	mov	bp,sp
	push	di
	push	ds
	pop	es
	mov	ah,MS_X_RENAME
	mov	di,6[bp]		; ES:DI = new name
	push	word ptr 4[bp]		; make it look like DRC call
	call	ms_dx_call		; DX = 4[bp], call DOS, handle errors
	pop	di			; remove parameter
	pop	di
	pop	bp
	ret

	Public	_ms_x_datetime
;	ret = _ms_x_datetime (gsflag, h, &time, &date);
;-------------
_ms_x_datetime:
;-------------
	push	bp
	mov	bp,sp
	mov	ah,MS_X_DATETIME	; set/get time stamp function
	mov	al,4[bp]		; get/set subfunction (0/1)
	mov	bx,8[bp]		; get address of time
	mov	cx,[bx]			; get time
	mov	bx,10[bp]		; get address of date
	mov	dx,[bx]			; get date
	mov	bx,6[bp]		; get handle
	int	DOS_INT			; call the DOS
	jc	ms_dt_ret		; skip if error
	sub	ax,ax			; signal no errors
	cmp	byte ptr 4[bp],0	; geting time/date?
	jne	ms_dt_ret		; skip if setting
	mov	bx,8[bp]		; get time address
	mov	[bx],cx			; update time
	mov	bx,10[bp]		; get date address
	mov	[bx],dx			; update date
ms_dt_ret:
	neg	ax			; make error negative, 0 = 0
	pop	bp
	ret


;
;	The following routines allow COMMAND.COM to manipulate
;	the system time and date. Four functions are provided and
;	these are MS_GETDATE, MS_SETDATE, MS_GETTIME and MS_SETTIME
;
;	Date information is passed and return in a structure which 
;	has the following format.
;
;	WORD		Year (1980 - 2099)
;	BYTE		Month
;	BYTE		Day
;	BYTE		Day of the Week (Ignored on SET DATE)

	Public	_ms_getdate
_ms_getdate:
	push	bp
	mov	bp,sp
	mov	ah,MS_T_GETDATE		; get the current date from DOS
	int	DOS_INT
	mov	bx,4[bp]		; and get the structure address
	mov	[bx],cx			; save the year
	xchg	dh,dl			; swap month and day
	mov	2[bx],dx		; and save
	mov	4[bx],al		; and finally save the day number
	pop	bp			; and exit
	ret

	Public	_ms_setdate
_ms_setdate:
	push	bp
	mov	bp,sp
	mov	bx,4[bp]		; and get the structure address
	mov	cx,0[bx]		; det the year
	mov	dx,2[bx]		; get the month and day
	xchg	dh,dl			; swap month and day
	mov	ah,MS_T_SETDATE		; set the current date
	int	DOS_INT
	cbw				; 0000 = Ok and FFFF = Bad
	pop	bp			; and exit
	ret


;	Time information is passed and return in a structure which 
;	has the following format.
;
;	BYTE		Hours (0 - 23)
;	BYTE		Minutes (0 - 59)
;	BYTE		Seconds (0 - 59)
;	BYTE		Hundredths of a second (0 - 99)

	Public	_ms_gettime
_ms_gettime:
	push	bp
	mov	bp,sp
	mov	ah,MS_T_GETTIME		; get the current date from DOS
	int	DOS_INT
	mov	bx,4[bp]		; and get the structure address
	xchg	cl,ch
	mov	[bx],cx			; save the hours and minutes
	xchg	dh,dl
	mov	2[bx],dx		; save seconds and hundredths
	pop	bp			; and exit
	ret

	Public _ms_settime
_ms_settime:
	push	bp
	mov	bp,sp
	mov	bx,4[bp]		; and get the structure address
	mov	cx,[bx]			; get the hours and minutes
	xchg	cl,ch
	mov	dx,2[bx]		; get seconds and hundredths
	xchg	dh,dl
	mov	ah,MS_T_SETTIME		; get the current date from DOS
	int	DOS_INT
	cbw				; 0000 = Ok and FFFF = Bad
	pop	bp			; and exit
	ret

	Public _ms_idle_ptr
;------------
_ms_idle_ptr:
;------------
	push	es
	push	si
	push	di
	mov	ax, 4458h
	int	DOS_INT			; ptr in ES:AX
	mov	dx, es
	pop	di
	pop	si
	pop	es
	ret

	Public _ms_switchar
;-----------
_ms_switchar:
;-----------
	mov	ax,3700h
	int	DOS_INT
	sub	ah,ah
	mov	al,dl
	ret
if 0
	Public	_ms_p_getpsp
;-----------
_ms_p_getpsp:
;-----------
	mov	ah,51h			; Note: SeCRET DOS 2.x entry
	int	DOS_INT
	xchg	ax,bx
	ret
endif
	Public	_ms_f_verify
;-----------
_ms_f_verify:
;-----------
	push	bp
	mov	bp,sp
	mov	ah,MS_F_VERIFY
	mov	al,4[bp]		;get 0/1 al parameter 
	int	DOS_INT
	pop	bp
	ret

	Public	_ms_f_getverify
;--------------
_ms_f_getverify:
;--------------
	mov	ah,MS_F_GETVERIFY
	int	DOS_INT
	cbw
	ret

ifndef	CDOSTMP
	Public	_ms_f_parse
;-----------
_ms_f_parse:
;-----------
	push	bp
	mov	bp, sp
	push	es
	push	si
	push	di
	
	push	ds
	pop	es
	mov	di, 4[bp]		; fcb
	mov	si, 6[bp]		; filename
	mov	al, 8[bp]		; flags
	mov	ah, MS_F_PARSE
	int	DOS_INT
	
	cbw				; return code in ax
	pop	di
	pop	si
	pop	es
	pop	bp
	ret

	Public	_ms_f_delete
;------------
_ms_f_delete:
;------------
	push	bp
	mov	bp, sp
	mov	dx, 4[bp]			; fcb
	mov	ah, MS_F_DELETE
	int	DOS_INT
	
	cbw					; return code
	pop	bp
	ret
endif
;
;	The SET BREAK function returns the previous Break Flag Status
;	
	Public	_ms_set_break
;------------
_ms_set_break:
;------------
	push	bp
	mov	bp,sp
	mov	dl,04[bp]
	mov	ax,(MS_S_BREAK SHL 8) + 2
	int	DOS_INT
	pop	bp
	mov	al,dl
	cbw
	ret

if 0
	Public _ms_get_break
;------------
_ms_get_break:
;------------
	mov	ax,MS_S_BREAK SHL 8
	int	DOS_INT
	mov	al,dl
	cbw
	ret
endif

;
;	mem_alloc(BYTE FAR * NEAR * bufaddr, UWORD * bufsize, UWORD min, UWORD max);
;
;	max		10[bp]
;	min		08[bp]
;	bufsize		06[bp]
;	buffadr 	04[bp]
;
	Public _mem_alloc
;---------
_mem_alloc:
;---------
	push	bp
	mov	bp,sp
	mov	bx,10[bp]		; Start with request maximum size
mem_all10:
	mov	ah,MS_M_ALLOC		; Attempt to allocate the maximum
	int	DOS_INT			; memory requested by the user. 
	jnc	mem_all20		; Allocation OK
	cmp	bx,08[bp]		; Is this less than the requested
	jae	mem_all10		; No then allocate this amount
	xor	ax,ax			; Force the Buffer address and Buffer
	mov	bx,ax			; Size to Zero

mem_all20:
	mov	cx,bx			; Save the Buffer Size
	mov	bx,04[bp]		; Update the Buffer Address
	mov	word ptr 00[bx],0	; Offset 0
	mov	word ptr 02[bx],ax	; Segment AX
	mov	bx,06[bp]		; Now Update the Buffer Size
	mov	word ptr 00[bx],cx	; and return to the caller
	pop	bp
	ret
;
;	mem_free(BYTE FAR * NEAR * bufaddr);
;
;	buffadr 	04[bp]
;
	Public _mem_free
;---------
_mem_free:
;---------
	push	bp
	mov	bp,sp
	xor	ax,ax
	mov	bx,04[bp]		; Get the Buffer Pointer address
	xchg	ax,word ptr 02[bx]	; and from this the segment of the
	cmp	ax,0			; allocated memory. If the memory
	jz	mem_free10		; has already been freed the quit
	push	es			; Otherwise Free the Memory
	mov	es,ax
	mov	ah,MS_M_FREE
	int	DOS_INT
	pop	es
mem_free10:
	pop	bp
	ret

	Public _msdos
;-------
_msdos:
;-------
	push	bp
	mov	bp,sp
	push	si
	push	di

	mov	ah,4[bp]
	mov	dx,6[bp]
	int	DOS_INT

	pop	di
	pop	si
	pop	bp
	ret

	Public	_ioctl_ver
;---------
_ioctl_ver:	
;---------
ifdef DOSPLUS
 	mov	ax,4452h		; Get DOS Plus BDOS version Number
else
 	mov	ax,4451h		; Get Concurrent BDOS Version
endif
	int	DOS_INT			; Real DOS returns with Carry Set
	jc	cdos_v10
	and	ax,not 0200h		; Reset the Networking Bit
	ret
cdos_v10:	
	xor	ax,ax
	ret

ifdef DOSPLUS
;
;	Get CodePage information form the system. Return both the currently
;	active CodePage and the System CodePage.
;
;	ms_x_getcp(&globalcp, &systemcp);
;
	Public	_ms_x_getcp
;-----------
_ms_x_getcp:	
;-----------
	push	bp
	mov	bp,sp
	mov	ax,MS_X_GETCP			; Get the CodePage Information
	int	DOS_INT				; and return an error if not
	jc	ms_x_getcp10			; supported.
	mov	ax,bx				; Now update the callers
	mov	bx,04[bp]			; Global and System Codepage
	mov	word ptr [bx],ax		; variables 
	mov	bx,06[bp]
	mov	word ptr [bx],dx
	xor	ax,ax

ms_x_getcp10:
	neg	ax				; Negate the error code has 
	pop	bp				; no effect on 0
	ret
;
;	Change the current CodePage
;
;	ms_x_setcp(globalcp);
;
	Public	_ms_x_setcp
;-----------
_ms_x_setcp:	
;-----------
	push	bp
	mov	bp,sp
	mov	bx,04[bp]			; Get the requested CodePage
	mov	ax,MS_X_SETCP			; and make this the default
	int	DOS_INT
	jc	ms_x_getcp10
	xor	ax,ax
	pop	bp
	ret
endif
endif

ifdef CDOSTMP


	Public	_ms_drv_set
;-----------
_ms_drv_set:
;-----------
	push	bp
	mov	bp,sp
	mov	dl,04[bp]		; Get the Specified drive
	or	dl,80h			; Prevent any Select Errors
	mov	cl,DRV_SET		; and go select the bugger
	int	BDOS_INT
	pop	bp
	ret

	Public	_ms_drv_get
;-----------
_ms_drv_get:
;-----------
	mov	cl,DRV_GET		; Return the Currently selected
	int	BDOS_INT		; disk drive
	cbw
	ret

	Public	_ms_drv_space
;------------
_ms_drv_space:
;------------
;
;	ret = _ms_drv_space (drive, &free, &secsiz, &nclust);
;	where:	drive	= 0, 1-16 is drive to use
;		free    = free cluster count
;		secsiz  = bytes/sector
;		nclust	= clusters/disk
;		ret	= sectors/cluster -or- (0xFFFFh)

	push	bp
	mov	bp,sp
	mov	al,OK_RF			; Retry or Fail
	call	fdos_retry
	mov	FD_FUNC, FD_DISKINFO
	mov	ax,04[bp]
	mov	FD_DRIVE,ax
	call	fdos_entry
	or	ax,ax				; Check for Errors
	mov	ax,0FFFFh
	jnz	ms_drv_exit			; Error Exit

	push	es				; Save ES
	push	di
	les	di,FD_DPB			; Get the DPB Address

	mov	ax,es:DDSC_FREE[di]		; Get the number of free
	mov	bx,06[bp]			; clusters on the drive
	mov	[bx],ax

	mov	ax,es:DDSC_SECSIZE[di]		; Get the Physical Sector Size
	mov	bx,08[bp]			; in bytes
	mov	[bx],ax
	
	mov	ax,es:DDSC_NCLSTRS[di]		; Get the disk size in
	mov	bx,10[bp]			; clusters and save in DX
	mov	[bx],ax

	mov	al,es:DDSC_CLMSK[di]		; Get the sectors per Cluster -1
	cbw					; and save in AX
	inc	ax
	pop	di
	pop	es

ms_drv_exit:
	pop	bp
	CRET	8

	Public	_ms_s_country
;------------
_ms_s_country:
;------------
	push	bp
	mov	bp,sp
	mov	ax,04[bp]		; Get the data Block Offset

	mov	cd_country,0		; Get the Current Country	
	mov	cd_codepage,0		; Current CodePage
	mov	cd_table,0		; Country Information
	mov	cd_offset,ax		; Save the Buffer Offset
	mov	cd_segment,ds		; and the Buffer Segment

	mov	dx,dataOFFSET country_data
	mov	cl,S_GETCOUNTRY		; Get the country information
	int	BDOS_INT		; and return the current country
	pop	bp			; code to the caller
	CRET	2

	Public _ms_x_mkdir
;----------
_ms_x_mkdir:
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RIF			; Retry, Ignore or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_MKDIR	; Make Directory

mkdir_10:
	mov	ax,04[bp]
	mov	FD_NAMEOFF,ax
	mov	FD_NAMESEG,ds
	call	fdos_entry
	pop	bp
	CRET	2
	
	Public	_ms_x_rmdir
;----------
_ms_x_rmdir:
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RIF			; Retry, Ignore or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_RMDIR
	jmp	mkdir_10

	Public	_ms_x_chdir
;----------
_ms_x_chdir:
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RF			; Retry or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_CHDIR
	jmp	mkdir_10

	Public	_ms_x_creat
;----------
_ms_x_creat:
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RF			; Retry or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_CREAT
	jmp	ms_open_creat


	Public	_ms_x_open
;---------
_ms_x_open:
;---------
	push	bp
	mov	bp,sp
	mov	al,OK_RF			; Retry or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_OPEN
ms_open_creat:
	mov	ax,4[bp]
	mov	FD_NAMEOFF,ax
	mov	FD_NAMESEG,ds
	mov	ax,6[bp]		; get mode for new file (CREAT)
	mov	FD_MODE,ax		; or the OPEN mode
	call	fdos_entry		; Call the FDOS and return either
	pop	bp			; a handle or error code
	CRET	4

	Public _ms_x_close
;----------
_ms_x_close:
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RIF			; Retry, Ignore or Fail
	call	fdos_retry
	mov	ax,4[bp]		; get the open handle
	mov	FD_FUNC,FD_CLOSE
	mov	FD_HANDLE,ax
	call	fdos_entry
	pop	bp
	CRET	2

	Public	_ms_x_unique
;----------
_ms_x_unique:
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RF			; Retry or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_MKTEMP
	jmp	ms_open_creat

	Public	_ms_x_fdup
;----------
_ms_x_fdup:
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RIF			; Retry, Ignore or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_FDUP
	mov	ax,4[bp]		; get the destination handle
	mov	FD_NEWHND,ax
	mov	ax,6[bp]		; Get the current handle	
	mov	FD_HANDLE,ax
	call	fdos_entry
	pop	bp
	CRET	4

	Public	_far_read
;---------
_far_read:
;---------
	push	bp
	mov	bp,sp
	mov	al,OK_RF			; Retry or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_READ
	jmp	far_read_write

	Public	_far_write
;----------
_far_write:
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RIF			; Retry, Ignore or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_WRITE

far_read_write:
	mov	ax,4[bp]		; get file handle
	mov	FD_HANDLE,ax
	mov	ax,6[bp]		; get buffer offset address
	mov	FD_BUFOFF,ax
	mov	ax,8[bp]		; get buffer Segment address
	mov	FD_BUFSEG,ax
	mov	ax,10[bp]		; get byte count
	mov	FD_COUNT,ax
	call	fdos_entry
	or	ax,ax
	jnz	far_rw_fail	
	mov	ax,FD_COUNT		; Get the Byte Count
far_rw_fail:
	pop	bp
	CRET	6

	Public	_ms_x_read
;---------
_ms_x_read:
;---------
	push	bp
	mov	bp,sp
	mov	al,OK_RF			; Retry or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_READ
	jmp	ms_read_write

	Public	_ms_x_write
;----------
_ms_x_write:
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RIF			; Retry, Ignore or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_WRITE

ms_read_write:
	mov	ax,4[bp]		; get file handle
	mov	FD_HANDLE,ax
	mov	ax,6[bp]		; get buffer address
	mov	FD_BUFOFF,ax
	mov	FD_BUFSEG,ds
	mov	ax,8[bp]		; get byte count
	mov	FD_COUNT,ax
	call	fdos_entry
	or	ax,ax
	jnz	ms_rw_fail	
	mov	ax,FD_COUNT		; Get the Byte Count
ms_rw_fail:
	pop	bp
	CRET	6

	Public	_ms_x_unlink
;-----------
_ms_x_unlink:
;-----------
	push	bp
	mov	bp,sp
	mov	al,OK_RIF			; Retry, Ignore or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_UNLINK
	jmp	mkdir_10


	Public	_ms_x_lseek
;----------
_ms_x_lseek:
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RIF			; Retry, Ignore or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_LSEEK	; get the function
	mov	ax,4[bp]		; get the file handle
	mov	FD_HANDLE,ax
	mov	ax,6[bp]		; get the offset
	mov	word ptr FD_OFFSET+0,ax
	mov	ax,8[bp]
	mov	word ptr FD_OFFSET+2,ax
	mov	ax,10[bp]		; get the seek mode
	mov	FD_METHOD,ax
	call	fdos_entry
	cwd
	or	ax,ax
	jnz	ms_lseek_fail		; skip if errors
	mov	ax,word ptr FD_OFFSET+0 ; Return the New Location
	mov	dx,word ptr FD_OFFSET+2
ms_lseek_fail:
	mov	bx,dx			; AX:BX = DRC long return
	pop	bp
	CRET	8


	Public	_ms_x_ioctl
;----------
_ms_x_ioctl:
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RF		; Retry or Fail
	call	fdos_retry
	mov	ax,4[bp]		; get Enquiry Handle
	mov	FD_FUNC,FD_IOCTL	; Use the IOCTL function
	mov	FD_HANDLE,ax		; For Handle AX
	mov	FD_CTLFUNC,0000		; Get the Handle Status
	mov	FD_CTLSTAT,0		; Invalidate CTLSTAT
	call	fdos_entry		; Call the FDOS
	mov	ax,FD_CTLSTAT		; and return the STATUS
	pop	bp
	CRET	2

	Public	_ms_x_setdev
;------------
_ms_x_setdev:
;------------
	push	bp
	mov	bp,sp
	mov	al,OK_RF		; Retry or Fail
	call	fdos_retry
	mov	ax,4[bp]		; get Handle
	mov	FD_HANDLE,ax
	mov	FD_FUNC,FD_IOCTL	; Use the IOCTL function
	mov	FD_CTLFUNC,1		; Set device info
	mov	ax, 6[bp]		; status to set
	sub	ah, ah
	mov	FD_CTLSTAT,ax
	call	fdos_entry		; Call the FDOS
	mov	ax,FD_CTLSTAT		; and return the STATUS
	pop	bp
	CRET	2

	Public	_ms_x_chmod
;----------
_ms_x_chmod:			;	ms_x_chmod(path, attrib, get/set)
;----------
	push	bp
	mov	bp,sp
	mov	al,OK_RIF		; Retry, Ignore or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_CHMOD
	mov	ax,4[bp]		; Get the FileName
	mov	FD_NAMEOFF,ax
	mov	FD_NAMESEG,ds
	mov	ax,6[bp]		; Get the Required Attributes
	mov	FD_ATTRIB,ax
	mov	ax,8[bp]		; Finally Get the GET/SET flag
	mov	FD_FLAG,ax
	call	fdos_entry		; Returns with AX equal to the  
	or	ax,ax			; error code or with the file
	js	chmod10			; attributes.
	mov	ax,FD_ATTRIB
chmod10:
	pop	bp
	CRET	6


	Public	_ms_x_curdir
;-----------
_ms_x_curdir:
;-----------
	push	bp
	mov	bp,sp
	mov	al,OK_RF		; Retry or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_GETDIR
	mov	ax,04[bp]		; Get the drive
	mov	FD_DRIVE,ax
	mov	bx,06[bp]		; and then the path
	mov	byte ptr [bx],0		; Put a Zero byte in the buffer in
	mov	FD_PATHOFF,bx		; case the command fails and the
	mov	FD_PATHSEG,ds		; user selects the FAIL Option
	call	fdos_entry
	pop	bp
	CRET	4

;
;	ms_x_expand(dstbuf, srcbuf) returns the full path of SRCBUF
;
	Public	_ms_x_expand
;-----------
_ms_x_expand:
;-----------
	push	bp
	mov	bp,sp
	mov	al,OK_RF		; Retry or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_EXPAND
	mov	ax,06[bp]		; Get Source Buffer Offset
	mov	FD_ONAMEOFF,ax
	mov	FD_ONAMESEG,ds
	mov	bx,04[bp]		; Get the destination string
	mov	byte ptr [bx],0		; address and force it to be a NULL
	mov	FD_NNAMEOFF,bx		; terminated string in case of errors
	mov	FD_NNAMESEG,ds
	call	fdos_entry
	pop	bp
	CRET	4

	Public	_ms_x_wait
;---------
_ms_x_wait:		; retrieve child return code
;---------
	mov	cl,P_EXITCODE		; Return the Exit Code
	mov	dx,0FFFFh		; Get the Exit Code
	int	BDOS_INT
	CRET	0

	Public	_ms_x_first
;----------
_ms_x_first:
;----------
	push	bp
	mov	bp,sp

	mov	dx,8[bp]		; get DMA buffer address
	mov	cl,F_DMAOFF
	call	bdos_entry

	mov	dx,ds			;##jc##
	mov	cl,F_DMASEG		;##jc##
	call	bdos_entry		;##jc##

	mov	al,OK_RF		; Retry or Fail
	call	fdos_retry

	mov	FD_FUNC,FD_FFIRST	; Search First
	mov	ax,04[bp]		; Get the FileName
	mov	FD_NAMEOFF,ax
	mov	FD_NAMESEG,ds
	mov	ax,06[bp]		; Get the Attributes
	mov	FD_ATTRIB,ax
	mov	FD_COUNT, 0		; Search for a File at a time
	call	fdos_entry
	cmp	ax,1			; Did we match 1 entry
	jnz	ms_x_f10		; No so return Error Code
	mov	ax,0			; Return Zero on sucess
ms_x_f10:
	pop	bp
	CRET	6

	Public	_ms_x_next
;---------
_ms_x_next:
;---------
	push	bp
	mov	bp,sp

	mov	dx,4[bp]		; get DMA buffer address
	mov	cl,F_DMAOFF
	call	bdos_entry

	mov	dx,ds			;##jc##
	mov	cl,F_DMASEG		;##jc##
	call	bdos_entry		;##jc##

	mov	al,OK_RF		; Retry or Fail
	call	fdos_retry

	mov	FD_FUNC,FD_FNEXT	; Search Next
	mov	FD_NEXTCNT, 0		; Search for a File at a time
	call	fdos_entry
	cmp	ax,1			; Did we match 1 entry
	jnz	ms_x_n0		; No so return Error Code
	mov	ax,0			; Return Zero on sucess
ms_x_n0:
	pop	bp
	CRET	2


	Public _ms_x_rename
;-----------
_ms_x_rename:
;-----------
	push	bp
	mov	bp,sp
	mov	al,OK_RIF		; Retry, Ignore or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_RENAME
	mov	ax,04[bp]		; Get the Old Name
	mov	FD_ONAMEOFF,ax
	mov	FD_ONAMESEG,ds
	mov	ax,06[bp]		; Get the New Name
	mov	FD_NNAMEOFF,ax
	mov	FD_NNAMESEG,ds
	call	fdos_entry
	pop	bp
	CRET	4

	Public	_ms_x_datetime
;-------------
_ms_x_datetime:			; ms_x_datetime (gsflag, h, &time, &date);
;-------------
	push	bp
	mov	bp,sp
	mov	al,OK_RIF		; Retry, Ignore or Fail
	call	fdos_retry
	mov	FD_FUNC,FD_DATETIME	; set/get Time Stamp
	mov	ax,4[bp]		; get/set subfunction (0/1)
	mov	FD_SFLAG,ax
	mov	ax,6[bp]		; get handle
	mov	FD_HANDLE,ax
	mov	bx,8[bp]		; get address of time
	mov	ax,[bx]			; get time
	mov	FD_TIME,ax		; and Save
	mov	bx,10[bp]		; get address of date
	mov	ax,[bx]			; get date
	mov	FD_DATE,ax
	call	fdos_entry
	or	ax,ax			; Skip if Failed
	jnz	ms_dt_ret
	mov	ax,FD_TIME
	mov	bx,8[bp]		; get time address
	mov	[bx],ax			; update time
	mov	ax,FD_DATE
	mov	bx,10[bp]		; get date address
	mov	[bx],ax			; update date
	xor	ax,ax
ms_dt_ret:
	pop	bp
	CRET	8


;
;	The following routines allow COMMAND.COM to manipulate
;	the system time and date. Four functions are provided and
;	these are GETDATE, SETDATE, GETTIME and SETTIME
;
;	Date information is passed and return in a structure which 
;	has the following format.
;
;	WORD		Year (1980 - 2099)
;	BYTE		Month
;	BYTE		Day
;	BYTE		Day of the Week (Ignored on SET DATE)

	Public	_ms_getdate
;-----------
_ms_getdate:
;-----------
	push	bp
	mov	bp,sp
	mov	dx,04[bp]		; Get the structure address
	mov	cl,T_GETDATE		; and call the BDOS
	call	bdos_entry
	pop	bp
	CRET	2

	Public	_ms_setdate
;----------
_ms_setdate:
;----------
	push	bp
	mov	bp,sp
	mov	dx,4[bp]		; and get the structure address
	mov	cl,T_SETDATE		; and call the BDOS to do the work
	call	bdos_entry		; Return 0 Good and FFFF Bad
	pop	bp
	CRET	2


;	Time information is passed and return in a structure which 
;	has the following format.
;
;	BYTE		Hours (0 - 23)
;	BYTE		Minutes (0 - 59)
;	BYTE		Seconds (0 - 59)
;	BYTE		Hundredths of a second (0 - 99)

	Public	_ms_gettime
;----------
_ms_gettime:
;----------
	push	bp
	mov	bp,sp
	mov	dx,04[bp]		; Get the Time Structure address
	mov	cl,T_GETTIME		; and call the OS
	call	bdos_entry
	pop	bp
	CRET	2

	Public _ms_settime
;----------
_ms_settime:
;----------
	push	bp
	mov	bp,sp
	mov	dx,4[bp]		; and get the structure address
	mov	cl,T_SETTIME		; and call the BDOS SET Time Function
	call	bdos_entry		; Return 0 Good and FFFF Bad
	pop	bp
	CRET	2

	Public	_ms_f_verify
;-----------
_ms_f_verify:
;-----------
	push	bp
	mov	bp,sp
	push	es
	mov	ax,04[bp]			; Get the required state
	les	bx,_pd				; Update the Verify flag in
	and	es:P_SFLAG[bx],not PSF_VERIFY	; current PD
	or	ax,ax				; Set the Flag
	jz	ms_fv10				; No
	or	es:P_SFLAG[bx],PSF_VERIFY	; Flag set in PD
ms_fv10:
	pop	es
	pop	bp
	ret

	Public	_ms_f_getverify
;--------------
_ms_f_getverify:
;--------------
	push	es
	xor	ax,ax				; Assume the flag is RESET
	les	bx,_pd				; now test the state of the
	test	es:P_SFLAG[bx],PSF_VERIFY	; flag in the current PD
	jz	ms_fgv10			; Verify = OFF
	inc	ax				; Verify = ON
ms_fgv10:
	pop	es
	ret

;
;	mem_alloc(BYTE FAR * NEAR * bufaddr, UWORD * bufsize, UWORD min, UWORD max);
;
;	max		10[bp]
;	min		08[bp]
;	bufsize		06[bp]
;	buffadr 	04[bp]
;
	Public _mem_alloc
;---------
_mem_alloc:
;---------
	push	bp
	mov	bp,sp

	mov	mpb_start,0
	mov	ax,08[bp]		; Get the Minimum and Maximum values
	mov	mpb_min,ax		; and fill in the parameter block
	mov	ax,10[bp]
	mov	mpb_max,ax
	mov	mpb_pdadr,0
	mov	mpb_flags,0
	
	mov	cx,M_ALLOC		; Call the Concurrent Allocate function
	mov	dx,dataOFFSET mpb_start	; 
	call	bdos_entry
	xor	cx,cx			; Assume that the function fails
	mov	dx,cx			; and zero the start and size fields
	cmp	ax,0
	jnz	mem_all10
	mov	cx,mpb_min		; Get the Allocation Size
	mov	dx,mpb_start		; and the starting segment

mem_all10:
	mov	bx,04[bp]		; Update the Buffer Address
	mov	word ptr 00[bx],0	; Offset 0
	mov	word ptr 02[bx],dx	; Segment DX
	mov	bx,06[bp]		; Now Update the Buffer Size
	mov	word ptr 00[bx],cx	; and return to the caller
	pop	bp
	ret
;
;	mem_free(BYTE FAR * NEAR * bufaddr);
;
;	buffadr 	04[bp]
;
	Public _mem_free
;---------
_mem_free:
;---------
	push	bp
	mov	bp,sp
	xor	ax,ax
	mov	bx,04[bp]		; Get the Buffer Pointer address
	xchg	ax,word ptr 02[bx]	; and from this the segment of the
	cmp	ax,0			; allocated memory. If the memory
	jz	mem_free10		; has already been freed the quit
	mov	mfpb_start,ax		; Otherwise Free the Memory
	mov	mfpb_res,0
	mov	cx,M_FREE
	mov	dx,dataOFFSET mfpb_start
	call	bdos_entry

mem_free10:
	pop	bp
	ret
;
;	findfile(BYTE *loadpath, UWORD *loadtype)
; 
	Public	_findfile
_findfile:
	push	bp
	mov	bp,sp
	mov	al,OK_RF		; Retry, Ignore or Fail
	call	fdos_retry
	mov	ax,word ptr 04[bp]
	mov	exec_pathoff,ax
	mov	exec_pathseg,ds
	mov	cx,P_PATH
	mov	dx,dataOFFSET exec_block
	call	ppath_entry
	or	ax,ax
	jnz	ff_error
	mov	al,exec_filetype
	cbw
	mov	bx,word ptr 06[bp]
	mov	word ptr [bx],ax
	xor	ax,ax
ff_error:	
	pop	bp
	ret

;
fdos_retry:
	xor	ah,ah
	mov	valid,ax		; Save the Valid Error responses
	pop	retry_ip		; Get the return Address
	mov	retry_sp,sp		; and Stack Pointer
	jmp	retry_ip
;
;	FDOS_ENTRY is an internal function entry point which makes the
;	F_DOS function call. As the F_DOS data area used by COMMAND.COM 
;	is always FDOS_DATA.
;
;	WORD PASCAL critical_error(error, valid, drive, mode, server);
;
;	critical_error will return an WORD response which (R,I,A,F)
;	after displaying the appropriate error message and get the
;	correct response from the user.
;
fdos_entry:
	mov	cl,F_DOS
	mov	dx,dataOFFSET fdos_data
ppath_entry:
	call	bdos_entry
	cmp	ax,ED_LASTERROR		; Did an Error Occur
	jb	fdos_exit		; No So Exit OK
	cmp	crit_flg,TRUE		; Already in handler
	jz	fdos_exit		; Yes Skip Critical Error
	cmp	ax,ED_PROTECT		; Is this a Physical Error
	jg	fdos_exit		; if so then simulate a 
	cmp	ax,ED_GENFAIL		; Critical Error by calling
	jge	fdos_e05		; the COMMAND routine Critical
					; error
	cmp	ax,ED_NETPWD		; Now check for DR-NET errors
	jg	fdos_exit		; if so then simulate a 
	cmp	ax,ED_NETLOG		; Critical Error by calling
	jge	fdos_e05		; the COMMAND routine Critical
					; error
fdos_exit:
	ret

fdos_e05:
	push	retry_ip		; Save Retry IP and SP and valid
	push	retry_sp		; responses
	push	valid
	mov	crit_flg,TRUE		; Start Critical Section
	mov	cx,es			; Save the Segment Regsiter
 	push	ax 			; Save the Error Code
	push	valid			; Save the Valid Responses (R,I,F)
	les	bx,_pd			; Get the PD address
	mov	es,es:P_UDA[bx]		; and then the UDA address
	xor	ah,ah			; Zero the top byte of AX and
	mov	al,es:byte ptr 15h ;;U_ERR_DRV		; Get the Failing Drive
	push	ax			; Save on the Stack
	mov	al,es:byte ptr 14h ;;U_ERR_RW		; Get the Error Mode
	push	ax			; and Save

	mov	ax,00FFH		; Default Server NO is (INVALID)
	les	bx,_pd			; Get the PD address Again
	mov	bx,es:P_NDA[bx]		; and then the NDA address
	cmp	bx,0			; Are we attached to DR-NET
	jz	fdos_e08		; NO
	mov	es,bx			; ES -> DR-Net NDA
	mov	al,es:byte ptr 0Ch 	;; NDA_CXRTN

fdos_e08:	
	push	ax			; Pass the DR-NET Server No.
	mov	es,cx			; Restore ES
	call	CRITICAL_ERR		; Handle the Critical Error. Parameters
					; are removed by the CALLEE
	mov	crit_flg,FALSE		; Critical Section complete
	pop	valid			; Restore our original RETRY IP
	pop	retry_sp		; and SP values which have been
	pop	retry_ip		; corrupted by the "CRITICAL_ERROR"
					; routine during message printing
	cmp	ax,0			; Ignore the Error
	jz	fdos_exit		; Then Exit with no Error

	cmp	ax,1			; Retry the Operation
	jnz	fdos_e10		; using information saved by FDOS_RETRY
	mov	sp,retry_sp		; Reset the Stack Pointer
	jmp	retry_ip		; and retry the Operation

fdos_e10:
	cmp	ax,3			; FAIL this function
	mov	ax,ED_FAIL		; Fail the function
	jz	fdos_exit		; Yes otherwise ABORT

	call	_int_break		; Simulate a Control C to terminate
					; We are never coming back
;
;	BDOS_ENTRY is the usual method of calling the Operating System.
;	In order to provide a DOS compatible environment this function.
;	does Control-C checking on function exit.
; 
bdos_entry:
	int	BDOS_INT
	push	es
	les	bx,_pd			; Get our process descriptor address
	test	es:P_SFLAG[bx],PSF_CTLC	; Check if a Control-C has been typed
	jnz	bdos_e10		; Jump to Abort Handler
	mov	bx,ax			; Restore BX and Return.
	pop	es
	ret

bdos_e10:
	and	es:P_SFLAG[bx],not PSF_CTLC
	pop	es
bdos_e20:
	mov	cl,C_RAWIO		; Flush the Character buffer until
	mov	dl,0FFh			; Return the character or 00 if queue
	int	BDOS_INT		; is empty. Repeat till the Keyboard
	or 	al,al			; Buffer has been flushed
	jnz	bdos_e20
	push	ds
	push	cs
	pop	ds
	mov	cl,C_WRITESTR
	mov	dx,offset break_str	; echo ^C to screen
	int	BDOS_INT
	pop	ds
	call	_int_break		; Place the Control Break Code on the 
					; Stack and the call the error handler
					; ** We will never return **

break_str	db	'^C$'

endif

ifndef DOSPLUS
	Public	__BDOS
;-------
__BDOS:
;-------
	push	bp
	mov	bp,sp
	push	si
	push	di
	mov	cl,4[bp]
	mov	dx,6[bp]
	int	BDOS_INT
	pop	di
	pop	si
	pop	bp
	ret
;
endif

ifdef DOSPLUS
ifndef EXT_SUBST
	Public	_physical_drvs		; Physical Drives returns a LONG
_physical_drvs:				; Vector with bits set for every drive
	mov	ax,0			; start with drive A:
	mov	cx,16			; check the first 16 drives
	mov	bx,0
p_d10:
	push	ax			; pass drive no. to _physical_drive
	call	_physical_drive		; call it
	cmp	ax,0			; check return value 
	pop	ax			; restore ax
	jz	p_d20			; if zero skip setting the bit in 
	or	bx,1			; the bitmap
p_d20:
	ror	bx,1			; shift bitmap right
	inc	ax			; next drive
	loop	p_d10			; Loop 16 Times
	mov	cx,10			; Finally check the last 10 drives
	mov	dx,0
p_d30:
	push	ax			; pass drive no. to _physical_drive
	call	_physical_drive		; call it
	cmp	ax,0			; check return val
	pop	ax			; restore ax
	jz	p_d40			; id zero skip setting the bit in 
	or	dx,1			; the bitmap
p_d40:
	ror	dx,1			; shift bitmap right
	inc	ax			; next drive
	loop	p_d30			; Loop 10 Times
	
	mov	cl,6			; Now rotate the contents of 
	ror	dx,cl			; DX 6 more times for correct
					; alignment of the Physical Drive Vector
	mov	ax,bx
	mov	bx,dx			; Return the long value in both
					; AX:BX and AX:DX
	ret

	Public	_logical_drvs		; Logical Drives returns a LONG
_logical_drvs:				; vector with bits set for every

	mov	cx,16			; check the first 16 drives
	mov	ax,0			; start with drive A:
	mov	bx,ax	

l_d10:
	push	ax			; pass the drive to _logical_drive
	call	_logical_drive		; call it
	cmp	ax,0			; check return value
	pop	ax			; restore ax
	jz	l_d20			; skip if zero return
	or	bx,1			; set bit in bitmap
l_d20:
	ror	bx,1			; shift bitmap right
	inc	ax			; next drive
	loop	l_d10			; Loop 16 Times

	mov	cx,10			; Finally check the last 10 drives
	mov	dx,0
l_d30:
	push	ax			; pass the drive to _logical_drive
	call	_logical_drive		; call it
	cmp	ax,0			; check return value
	pop	ax			; restore ax
	jz	l_d40			; skip if zero return
	or	dx,1			; set bit in bitmap
l_d40:
	ror	dx,1			; shift bitmap right
	inc	ax			; next drive
	loop	l_d30			; Loop 10 Times

	mov	cl,6			; Now rotate the contents of 
	ror	dx,cl			; DX 6 more times for correct
					; alignment of bits
	mov	ax,bx
	mov	bx,dx			; Return the long value in both
	ret				; AX:BX and AX:DX

	Public	_network_drvs		; Network Drives returns a LONG
_network_drvs:				; vector with bits set for every drive
	xor	ax,ax			; Start with BX:AX as
	mov	bx,ax			; zeros.
	mov	cx,'Z'-'A'		; We look at drives A-Z
n_d10:
	add	ax,ax			; we move the dword vector
	adc	bx,bx			;  one place left
	push	ax
	push	bx			; save the vector
	mov	ah,MS_X_IOCTL
	mov	al,9			; is device local ?
	mov	bl,cl			; drive number in BL
	int	DOS_INT
	pop	bx
	pop	ax			; recover the vector
	 jc	n_d20			; if an error skip network bit
	test	dx,1000h		; is device local ?
	 jz	n_d20			; if not then
	or	ax,1			;  set bit for this drive
n_d20:
	loop	n_d10
	mov	dx,bx			; long value in both AX:BX and AX:DX
	ret
	public	_physical_drive
_physical_drive	PROC NEAR

;	BOOLEAN	physical_drive(WORD);
;	returns true if given drive (0-25) is physical.
;
	push	bp
	mov	bp,sp
	push	ds
	push	es
	push	si
	push	di
	push	dx
	push	cx
	push	bx
	
	mov	bx,4[bp]	; get the drive number
	inc	bx		; A=1, B=2, etc
	mov	ax,4409h	; IOCTL Network/Local
	int	21h		; do it
	jc	not_phys	; carry means invalid drive
	and	dx,1000h	;
	cmp	dx,0
	jne	not_phys	; its a network drive

	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	si,offset func60_in
	mov	di,offset func60_out
	mov	ax,4[bp]	; insert drive letter in input string
	add	al,'A'
	mov	[si],al		;
	mov	ah,60h		; Expand Path string
	int	21h		; do it
	jc	not_phys	; carry set means invalid drive
	
	mov	ax,4[bp]	; if drive letter changes then drive is
	add	al,'A'		; substed
	cmp	al,cs:[func60_out]
	jne	not_phys	

	mov	ax,-1
	jmp 	phys_exit
not_phys:
	mov	ax,0
phys_exit:
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	si
	pop	es
	pop	ds
	pop	bp
	ret 

func60_in	db "d:con",0
func60_out	db 0,0,0,0,0,0,0,0,0,0

_physical_drive	ENDP

;
;	This function translates a logical to physical drive.
;
	Public	_pdrive
;------
_pdrive:
;------
	push	bp
	mov	bp,sp
	push	ds
	push	es
	push	si
	push	di

	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	si,offset func60_in
	mov	di,offset func60_out
	mov	ax,4[bp]		; insert drive letter in input string
	add	al,'A'
	mov	[si],al
	mov	ah,60h			; Expand Path string
	int	21h			; do it
	mov	ax,4[bp]		; assume invalid, hence no change
	 jc	pdrive_exit		; carry set means invalid drive
	mov	al,cs:[func60_out]
	sub	al,'A'
pdrive_exit:
	pop	di
	pop	si
	pop	es
	pop	ds
	pop	bp
	CRET	2

	public	_logical_drive
_logical_drive	PROC NEAR

;	BOOLEAN	logical_drive(WORD);
;	returns TRUE if given drive (0-25) is logical
;
	push	bp
	mov	bp,sp
	push	ds
	push	es
	push	si
	push	di
	push	dx
	push	cx
	push	bx
	
	mov	bx,4[bp]	; get the drive number
	inc	bx		; A=1, B=2, etc
	mov	ax,4409h	; IOCTL Network/Local
	int	21h		; do it
	jc	not_logical	; carry means invalid drive
	and	dx,1000h	;
	cmp	dx,0
	jne	not_logical	; its a network drive

	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	mov	si,offset func60_in
	mov	di,offset func60_out
	mov	ax,4[bp]	; insert drive letter in input string
	add	al,'A'
	mov	[si],al		;
	mov	ah,60h		; Expand Path string
	int	21h		; do it
	jc	not_logical	; carry set means invalid drive
	
	mov	ax,4[bp]	; if drive letter changes then drive is
	add	al,'A'		; substed
	cmp	al,cs:[func60_out]
	je	not_logical

	mov	ax,-1
	jmp 	logical_exit
not_logical:
	mov	ax,0
logical_exit:
	pop	bx
	pop	cx
	pop	dx
	pop	di
	pop	si
	pop	es
	pop	ds
	pop	bp
	ret 

_logical_drive	ENDP

	public	_network_drive
_network_drive	PROC NEAR

;	BOOLEAN	network_drive(WORD);
;	returns TRUE if given drive (0-25) is networked
;
	push	bp
	mov	bp,sp
	push	dx
	push	cx
	push	bx
	
	mov	bx,4[bp]	; get the drive number
	inc	bx		; A=1, B=2, etc
	mov	ax,4409h	; IOCTL Network/Local
	int	21h		; do it
	jc	not_networked	; carry means invalid drive
	and	dx,1000h	;
	cmp	dx,0
	jne	not_networked	; its a network drive

	mov	ax,-1
	jmp 	network_exit
not_networked:
	mov	ax,0
network_exit:
	pop	bx
	pop	cx
	pop	dx
	pop	bp
	ret 

_network_drive	ENDP

endif	;EXT_SUBST

else	;!DOSPLUS
	
	Public	_physical_drvs		; Physical Drives returns a LONG
_physical_drvs:				; Vector with bits set for every
	mov	cx,DRV_LOGINVEC		; Physical or Networked Drive 
	int	BDOS_INT		; attached to the system
	xor	dx,dx			; Return the LONG value in both
	mov	bx,dx			; AX:DX and AX:BX for maximum
	ret				; compatibility

	Public	_network_drvs		; Network Drives returns a LONG
_network_drvs:				; vector with bits set for every
	push	es			; physical drive which has been
	mov	ax,0			; mapped to a remote DRNET server
	mov	dx,ax
	les	bx,_pd			; Get Our Process Descriptor
	mov	cx,es:P_NDA[bx]		; and then the NDA Segment
	 jcxz	n_d20			; Skip Drive Test if no NDA
	mov	es,cx			; Get the RCT Address
	les	bx,es:dword ptr 04h	;; NDA_RCT ; From the NDA
	mov	cx,16
n_d10:
	test	es:RCT_DSK[bx],080h	; Is this a Remote drive
	 jz	n_d15			; No
	or	ax,1			; Set Drive Bit
n_d15:
	ror	ax,1			; Rotate Drive Bit Vector
	add	bx,2			; Update the Drive Pointer
	loop	n_d10			; Loop Till Done
n_d20:
	mov	bx,dx			; Return the long value in both
	pop	es			; AX:BX and AX:DX
	ret

ifndef	EXT_SUBST

	Public	_logical_drvs		; Logical Drives returns a LONG
_logical_drvs:				; vector with bits set for every
	push	es
	push	si
	push	di

	les	si,_pd			; Get Our Process Descriptor
	mov	si,es:P_CAT[si]		; and then the address of the 
	mov	cx,16			; first HDS and check the first
	mov	ax,0			; 16 Drives
	mov	bx,ax	

l_d10:
	mov	di,es:word ptr [si]	; Has this drive got an HDS
	test	di,di			; then skip setting the bit in 
	 jz	l_d20			; the vector register
	cmp	es:byte ptr [di],bl	; Is the HDS pointing to same drive
	 jz	l_d20			; Yes then this is a Physical Drive
	or	ax,1
l_d20:
	ror	ax,1
	add	si,2
	inc	bx
	loop	l_d10			; Loop 16 Tines

	mov	cx,10			; Finally check the last 10 HDS
	mov	dx,0
l_d30:
	mov	di,es:word ptr [si]	; Has this drive got an HDS
	test	di,di			; then skip setting the bit in 
	 jz	l_d40			; the vector register
	cmp	es:byte ptr [di],bl	; Is the HDS pointing to same drive
	 jz	l_d40			; Yes then this is a Physical Drive
	or	dx,1
l_d40:
	ror	dx,1
	add	si,2
	inc	bx
	loop	l_d30			; Loop 10 Tines

	mov	cl,6			; Now rotate the contents of 
	ror	dx,cl			; DX 6 more times for correct
					; alignment of bits
	pop	di
	pop	si
	pop	es
	mov	bx,dx			; Return the long value in both
	ret				; AX:BX and AX:DX


;
;	This function use the CONCURRENT 5.xx CP/M function to translate
;	a logical to physical drive.
;
	Public	_pdrive
;------
_pdrive:
;------
	push	bp
	mov	bp,sp
	mov	dl,4[bp]		; get the logical drive
	mov	cl,175			; Logical to Physical Xlat
	int	BDOS_INT
	cbw
	pop	bp
	CRET	2

endif	;!EXT_SUBST
endif	;!DOSPLUS


	Public	_toupper

UCASE	equ	18			; offset of dword ptr to uppercase func

;-------
_toupper	proc	near
;-------
; Return the uppercase equivilant of the given character.
; The uppercase function defined in the international info block is 
; called for characters above 80h.
;
; char	ch;				char to be converted
; char	result;				uppercase equivilant of ch
;
; result = toupper(ch);

	push	bp
	mov	bp, sp

	mov	ax, 4[bp]
	mov	ah, 0			; al = character to be converted
	cmp	al, 'a'			; al < 'a'?
	jb	exit_toupper		;  yes - done (char unchanged)
	cmp	al, 'z'			; al <= 'z'?
	jbe	a_z			;  yes - do ASCII conversion
	cmp	al, 80h			; international char?
	jb	exit_toupper		;  no - done (char unchanged)

; ch >= 80h  -- call international routine
	call	dword ptr [_country+UCASE]
	jmp	exit_toupper

a_z:
; 'a' <= ch <= 'z'  -- convert to uppercase ASCII equivilant
	and	al, 0DFh

exit_toupper:
	pop	bp
	ret

_toupper	endp



ifdef DOSPLUS
if 0
	Public	_hiload_status
;----------
_hiload_status:
;----------
	push	bp
	mov	bp,sp
	mov	dx,100h			; get hiload state
	mov	ax,(MS_X_IOCTL*256)+57h	; IO Control function
	int	DOS_INT			; do INT 21h
	pop	bp			; 
	ret

	Public	_hiload_set
;----------
_hiload_set:
;----------
	push	bp
	mov	bp,sp
	mov	dx,4[bp]		; get state
	mov	dh,2			; set hiload state
	mov	ax,(MS_X_IOCTL*256)+57h	; IO Control function
	int	DOS_INT			; do INT 21h
	pop	bp			; 
	ret
endif

	Public	_get_upper_memory_link
_get_upper_memory_link:

	mov	ax,5802h
	int	21h
	cbw
	ret

	Public	_set_upper_memory_link
_set_upper_memory_link:

	push	bp
	mov	bp,sp
	mov	bx,4[bp]
	mov	ax,5803h
	int	21h
	pop	bp
	ret

	Public	_get_alloc_strategy
_get_alloc_strategy:
	
	mov	ax,5800h
	int	21h
	ret

	Public	_set_alloc_strategy
_set_alloc_strategy:

	push	bp
	mov	bp,sp
	mov	bx,4[bp]
	mov	ax,5801h
	int	21h
	pop	bp
	ret

	Public	_alloc_region

_alloc_region:
	push	es
	xor	ax,ax
	mov	es,ax			; assume no block allocated
	mov	ah,MS_M_ALLOC
	mov	bx,1
	int	21h			; allocate a small block
	 jc	_alloc_region10
	mov	es,ax
	mov	ah,MS_M_SETBLOCK
	mov	bx,0FFFFh
	int	21h			; find out how big the block is
	mov	ah,MS_M_SETBLOCK
	int	21h			; now grow to take up the block
_alloc_region10:
	mov	ax,es			; return address of block
	pop	es
	ret

	Public	_free_region

_free_region:
	push	bp
	mov	bp,sp
	push	es
	mov	es,4[bp]
	mov	ah,MS_M_FREE
	int	21h			; free the block
	pop	es
	pop	bp
	ret

endif

; The Double Byte Character Set lead byte table.
; Each entry in the table except the last specifies a valid lead byte range.
;
;   0	+---------------+---------------+
;   	|    start of	|    end of 	|	DBCS table entry 0
;	|    range 0	|    range 0	|
;   2	+---------------+---------------+
;    	|    start of	|    end of 	|	DBCS table entry 1
;	|    range 1	|    range 1	|
;	+---------------+---------------+
;			:
;   n	+---------------+---------------+
;	|       0	|       0 	|	end of DBCS table
;	|    		|    		|
;	+---------------+---------------+


	Public	_dbcs_expected

_dbcs_expected	proc	near
;-------------
; Returns true if double byte characters are to be expected.
; A call to dbcs_init() MUST have been made.
; Entry
;	none
; Exit
;	ax	= 1 - double byte characters are currently possible
;		  0 - double byte characters are not currently possible

ifdef DOSPLUS
	push	ds
	push	si
	lds	si, dbcs_table_ptr	; DS:SI -> system DBCS table
	lodsw				; ax = first entry in DBCS table
	test 	ax, ax			; empty table?
	 jz	de_exit			;  yes - return 0 (not expected)
	mov	ax, 1			; return 1 (yes you can expect DBCS)
de_exit:
	pop	si
	pop	ds
else
	xor	ax,ax			; CDOS doesn't support them
endif
	ret
_dbcs_expected	endp


	Public	_dbcs_lead

_dbcs_lead	proc	near
;---------
; Returns true if given byte is a valid lead byte of a 16 bit character.
; A call to init_dbcs() MUST have been made.
; Entry
;	2[bp]	= possible lead byte
; Exit
;	ax	= 1 - is a valid lead byte
;		  0 - is not a valid lead byte

ifdef DOSPLUS
	push	bp
	mov	bp, sp
	push	ds
	push	si

	mov	bx, 4[bp]		; bl = byte to be tested
	lds	si,dbcs_table_ptr	; ds:si -> system DBCS table
	lodsw				; any entries ?
	test	ax,ax
	 jz	dl_not_valid		; no DBC entries

dl_loop:
	lodsw				; al/ah = start/end of range
	test 	ax, ax			; end of table?
	 jz	dl_not_valid		;  yes - exit (not in table)
	cmp	al, bl			; start <= bl?
	 ja	dl_loop			;  no - try next range
	cmp	ah, bl			; bl <= end?
	 jb	dl_loop			;  no - try next range

	mov	ax, 1			; return 1 - valid lead byte

dl_not_valid:
	pop	si
	pop	ds
	pop	bp
else
	xor	ax,ax			; CDOS doesn't support them
endif
	ret
_dbcs_lead	endp


	PUBLIC	_extended_error
_extended_error PROC NEAR

	mov	ah,59h
	mov	bx,0
	int	21h
	neg	ax
	ret

_extended_error	ENDP

	PUBLIC	_get_lines_page
_get_lines_page PROC NEAR

	push	bp
	push	es

	mov	ax,1130h
	mov	bx,0
	mov	dx,24	; preset dx to 24 in case function not supported 
	int	10h	 
	
	mov	ax,dx	; returns (no. rows)-1 in dx
	inc	ax

	pop	es
	pop	bp
	ret
	
_get_lines_page ENDP

	PUBLIC	_get_scr_width
_get_scr_width PROC NEAR

	push	bp
	mov	ah,0fh
	int	10h
	xor	al,al
	xchg	ah,al
	pop	bp
	ret
	
_get_scr_width ENDP

	PUBLIC	_novell_copy
_novell_copy PROC NEAR

	push	bp
	mov	bp,sp
	push	si
	push	di
	
	mov	ax,11f0h
	mov	si,4[bp]	; si = source handle
	mov	di,6[bp]	; di = destination handle
	mov	dx,8[bp]	; lo word of source length
	mov	cx,10[bp]	; hi word of source length
	clc			; start with carry cleared
	
	int	2fh		; do it

	jc	novcop_failure	; carry set means novell couldn't handle it

	cmp	ax,11f0h	
	je	novcop_failure  ; ax hasn't changed, so novell isn't there
	
	mov	ax,1		; success !
	jmp	novcop_exit
	
novcop_failure:
	mov	ax,0
novcop_exit:	
	pop	di
	pop	si
	pop	bp
	ret
	
_novell_copy ENDP

	PUBLIC	_call_novell
_call_novell	PROC NEAR
	
	push	bp
	mov	bp,sp
	push	es	
	push	si
	push	di

	mov	ah,8[bp]
	mov	al,0ffh
	push	ds
	pop	es
	mov	si,4[bp]
	mov	di,6[bp]
	int	21h

	cmp	al,0
	jne	call_nov_err
	jc	call_nov_err

	mov	ax,0	
	jmp	call_nov_exit

call_nov_err:
	mov	ah,0 ;; clear ah, BUT allow all ret' values in al 
call_nov_exit:	
	pop	di
	pop	si
	pop	es
	pop	bp
	ret

_call_novell	ENDP

	PUBLIC	_nov_station
_nov_station	PROC	NEAR

	push	bp
	mov	bp,sp
	push	si
	
	mov	ax,0eeffh
	int	21h	
	cmp	ax,0ee00h
	je	ns_err
	
	mov	si,4[bp]
	mov	[si],cx
	mov	2[si],bx
	mov	4[si],ax
	mov	ax,0
	jmp	ns_exit

ns_err:
	mov	ax,-1

ns_exit:
	pop	si
	pop	bp
	ret	

_nov_station	ENDP

	public	_nov_connection
_nov_connection	PROC NEAR

	push	es
	push	si

if 0
	mov	ax,0
	mov	es,ax
	mov	si,0
	mov	ax,0ef03h
	int	21h
	
	mov	ax,es
	cmp	ax,0
	jne	nc_ok
	cmp	si,0
	jne	nc_ok
	mov	ax,-1
	jmp	nc_exit	

nc_ok:
	mov	al,es:23[si]
	mov	ah,0
endif

	mov	ax,0dc00h
	int	21h
	jc	nc_err
	sub	ah,ah
	jmp	nc_exit

nc_err:
	mov	al,-1;	

nc_exit:
	pop	si
	pop	es
	ret

_nov_connection	ENDP

_TEXT	ENDS
	END
