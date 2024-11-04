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

;ifndef	??Version			;; Turbo Assembler always knows RETF
;ifndef	retf				;; some versions of MASM do as well
;retf	macro				;; define far return macro for others
;	db	0cbh
;	endm
;endif
;endif


include	msdos.equ
include	f52data.def
include doshndl.def

BDOS_INT	equ	224		; ##jc##


_DATA	SEGMENT	byte public 'DATA'
	extrn	__psp2:word
	extrn	_country:WORD
	extrn	dbcs_table_ptr:dword	; points to system DBCS table


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

;
;	UWORD	psp_poke(WORD handle, BYTE ifn);
;
	Public	_psp_poke
_psp_poke:
	push	bp
	mov	bp,sp
	push	es
	mov	ah,MS_P_GETPSP
	int	DOS_INT			; for software carousel
	mov	es,bx
	les	bx,es:[0034h]		; ES:BX -> external file table
	add	bx,4[bp]		; ES:BX -> XFT entry for our handle
	mov	al,6[bp]		; get new value to use
	xchg	al,es:[bx]		; get old value, set new value
	xor	ah,ah

	pop	es
	pop	bp
	ret

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
;	cbw
	xor	ah,ah
	pop	bp
	ret

	Public	_ms_edrv_space
;------------
_ms_edrv_space:
;------------
;
;	ret = _ms_edrv_space (&drive,&buffer,buflen);
;	where:	drive	= drive path
;		buffer  = buffer for free space structure
;		ret	= error code

	push	bp
	mov	bp,sp
	push	es
	push	di
	mov	dx,4[bp]		; DS:DX pointer to drive path
	push	ds			; ES:DI pointer to buffer
	pop	es
	mov	di,6[bp]
	mov	cx,8[bp]		; CX length of buffer
	mov	ax,MS_EDRV_SPACE
	call	call73
	pop	di
	pop	es
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

	Public _ms_l_mkdir
;----------
_ms_l_mkdir:
;----------
	push	bp
	mov	bp,sp
	mov	dx,4[bp]		; DS:DX directory name
	mov	ax,MS_L_MKDIR
	call	call71
	pop	bp
	ret

	Public	_ms_x_rmdir
;----------
_ms_x_rmdir:
;----------
	mov	ah,MS_X_RMDIR
	jmp	ms_dx_call

	Public	_ms_l_rmdir
;----------
_ms_l_rmdir:
;----------
	push	bp
	mov	bp,sp
	mov	dx,4[bp]		; DS:DX directory name
	mov	ax,MS_L_RMDIR
	call	call71
	pop	bp
	ret

	Public	_ms_x_chdir
;----------
_ms_x_chdir:
;----------
	mov	ah,MS_X_CHDIR
	jmp	ms_dx_call

	Public	_ms_l_chdir
;----------
_ms_l_chdir:
;----------
	push	bp
	mov	bp,sp
	mov	dx,4[bp]		; DS:DX directory name
	mov	ax,MS_L_CHDIR
	call	call71
	pop	bp
	ret

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

	Public	_ms_l_creat
;---------
_ms_l_creat:
;---------
	push	bp
	mov	bp,sp
	push	si
	mov	cx,6[bp]		; create attributes
	mov	bx,OPEN_RW		; create mode
	mov	dx,18			; create or truncate if exists
	jmp	ms_l_creat_entry

	Public	_ms_l_open
;---------
_ms_l_open:
;---------
	push	bp
	mov	bp,sp
	push	si
	mov	bx,6[bp]		; open mode
	mov	dx,1			; open if exists
ms_l_creat_entry:
	mov	si,4[bp]		; DX:SI filename
	mov	ax,MS_L_OPEN
	stc
	int	DOS_INT
	 jnc	ms_l_open10
	call	call71_alt_entry
ms_l_open10:
	pop	si
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

	Public	_ms_l_unlink
;-----------
_ms_l_unlink:
;-----------
	push	bp
	mov	bp,sp
	push	si
	mov	dx,4[bp]		; DS:DX -> filename
	mov	cx,6[bp]		; search attributes
	mov	si,1			; wildcards enabled
	mov	ax,MS_L_UNLINK
	call	call71
	pop	si
	pop	bp
	ret

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
	;mov	ah,MS_X_IOCTL		; get IO Control function
	;mov	al,0			; get file/device status
	mov	ax, (MS_X_IOCTL*256)    ; get IO Control function / get file/device status
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
	xor	dh, dh
	mov	ax, (MS_X_IOCTL * 256) + 1
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

	Public	_ms_l_chmod
;----------
_ms_l_chmod:
;----------
	push	bp
	mov	bp,sp
	mov	dx,4[bp]		; DS:DX filename
	mov	cx,6[bp]		; file attributes
	mov	bl,8[bp]		; get/set attributes
	mov	ax,MS_L_CHMOD
	stc
	int	DOS_INT
	 jnc	ms_l_chmod10
	call	call71_alt_entry
	jmp	ms_l_chmod20
ms_l_chmod10:
	cmp	byte ptr 8[bp],0	; get attributes?
	 jne	ms_l_chmod20
	mov	ax,cx			; return attributes
ms_l_chmod20:
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

	Public	_ms_l_curdir
;-----------
_ms_l_curdir:
;-----------
	push	bp
	mov	bp,sp
	push	si
	mov	dl,4[bp]		; DL drive number (0 = current drive)
	mov	si,6[bp]		; DS:SI path buffer
	mov	ax,MS_L_CURDIR
	call	call71
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
	mov	ax,__psp2		; the command processor is terminating
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
	xor	bx,bx			; used by the command processor
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
	xor	dh,dh			; Standard Exit
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

	Public	_ms_l_expand
_ms_l_expand:
	push	bp
	mov	bp,sp
	push	es
	push	di
	push	si
	push	ds
	pop	es
	mov	si,6[bp]		; DS:SI source string
	mov	di,4[bp]		; ES:DI destination buffer
	xor	cx,cx			; sub function 0, no subst expansion
	mov	ax,MS_L_EXPAND
	call	call71
	pop	si
	pop	di
	pop	es
	pop	bp
	ret

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

	Public	_ms_l_first
;----------
_ms_l_first:
;----------
	push	bp
	mov	bp,sp
	push	es
	push	di
	push	si
	push	ds
	pop	es
	mov	dx,4[bp]		; get ASCII string
	mov	cx,6[bp]		; get attribute
	mov	si,1			; request DOS date/time format
	mov	di,8[bp]		; get buffer address
	mov	ax,MS_L_FIRST		; LFN FindFirst
	stc
	int	DOS_INT
	mov	es:24h[di],ax		; save search handle
	call	call71_alt_entry
	pop	si
	pop	di
	pop	es
	pop	bp
	ret

	Public	_ms_l_next
;----------
_ms_l_next:
;----------
	push	bp
	mov	bp,sp
	push	es
	push	di
	push	si
	push	ds
	pop	es
	mov	bx,4[bp]		; get search handle
	mov	si,1			; request DOS date/time format
	mov	di,6[bp]		; get buffer address
	mov	ax,MS_L_NEXT		; LFN FindNext
	call	call71
	pop	si
	pop	di
	pop	es
	pop	bp
	ret

	Public	_ms_l_findclose
;----------
_ms_l_findclose:
;----------
	push	bp
	mov	bp,sp
	mov	bx,4[bp]		; get search handle
	mov	ax,MS_L_FINDCLOSE	; LFN FindClose
	jmp	ms_call_dos

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

	Public	_ms_l_rename
;-----------
_ms_l_rename:
;-----------
	push	bp
	mov	bp,sp
	push	es
	push	di
	push	ds
	pop	es
	mov	dx,4[bp]		; DS:DX old filename
	mov	di,6[bp]		; ES:DI new filename
	mov	ax,MS_L_RENAME
	call	call71
	pop	di
	pop	es
	pop	bp
	ret

call71:
	stc				; just in case it is not implemented
	int	DOS_INT
call71_alt_entry:
	 jnc	call71_20
	cmp	ax,7100h		; function implemented?
call73_entry:
	 jne	call71_10
	mov	ax,0ffffh		; error code -1 - invalid function
	jmp	call71_30
call71_10:
	neg	ax
	jmp	call71_30
call71_20:
	sub	ax,ax			; no error
call71_30:
	ret

call73:
	stc				; just in case it is not implemented
	int	DOS_INT
	 jnc	call71_20
	cmp	ax,7300h		; function implemented?
	jmp	call73_entry

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

	Public	_get_lastdrive
;-----------
_get_lastdrive:
;-----------
	push	es
	mov	ah,52h			; get List of Lists
	int	DOS_INT
	mov	ax,es:20h[bx]		; number of drives
;	xor	ah,ah
	pop	es
	ret

	Public	_get_driveflags
;-----------
_get_driveflags:
;-----------
	push	bp
	mov	bp,sp
	push	es
	mov	ah,52h			; get List of Lists
	int	DOS_INT
	les	bx,es:16h[bx]		; ES:BX -> Path Control Table
	mov	ax,LDT_LEN		; length of table entry
	mul	word ptr 4[bp]		; drive number (A=0)
	add	bx,ax			; offset in LDT
	mov	ax,es:LDT_FLAGS[bx]
	pop	es
	pop	bp
	ret

	Public	_conv64
;-----------
_conv64:
;-----------
	push	bp
	mov	bp,sp
	push	si
	push	di
	mov	si,4[bp]
	mov	di,6[bp]
	xor	dx,dx
conv64_10:
	cmp	word ptr [di],0		; greater than 2^32-1?
	 jne	conv64_20
	cmp	word ptr 2[di],0
	 je	conv64_40
conv64_20:
	mov	ax,1[si]		; /256
	mov	[si],ax
	mov	al,3[si]
	mov	ah,[di]
	mov	2[si],ax
	mov	ax,1[di]
	mov	[di],ax
	mov	al,3[di]
	xor	ah,ah
	mov	2[di],ax
	mov	cx,2
conv64_30:
	shr	byte ptr 2[di],1	; /4
	rcr	word ptr [di],1
	rcr	word ptr 2[si],1
	rcr	word ptr [si],1
	loop	conv64_30
	inc	dx
conv64_40:
	xchg	ax,dx
	pop	di
	pop	si
	pop	bp
	ret

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
	test	ax,ax			; allocated memory. If the memory
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
 	mov	ax,4452h		; Get DOS Plus BDOS version Number
	int	DOS_INT			; Real DOS returns with Carry Set
	jc	cdos_v10
	and	ax,not 0200h		; Reset the Networking Bit
	ret
cdos_v10:	
	xor	ax,ax
	ret

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
	

ifndef EXT_SUBST
	Public	_physical_drvs		; Physical Drives returns a LONG
_physical_drvs:				; Vector with bits set for every drive
	xor	ax,ax			; start with drive A:
	mov	cx,16			; check the first 16 drives
	xor	bx,bx
p_d10:
	push	ax			; pass drive no. to _physical_drive
	call	_physical_drive		; call it
	test	ax,ax			; check return value
	pop	ax			; restore ax
	jz	p_d20			; if zero skip setting the bit in 
	or	bx,1			; the bitmap
p_d20:
	ror	bx,1			; shift bitmap right
	inc	ax			; next drive
	loop	p_d10			; Loop 16 Times
	mov	cx,10			; Finally check the last 10 drives
	xor	dx,dx
p_d30:
	push	ax			; pass drive no. to _physical_drive
	call	_physical_drive		; call it
	test	ax,ax			; check return val
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
	xor	ax,ax			; start with drive A:
	mov	bx,ax	

l_d10:
	push	ax			; pass the drive to _logical_drive
	call	_logical_drive		; call it
	test	ax,ax			; check return value
	pop	ax			; restore ax
	jz	l_d20			; skip if zero return
	or	bx,1			; set bit in bitmap
l_d20:
	ror	bx,1			; shift bitmap right
	inc	ax			; next drive
	loop	l_d10			; Loop 16 Times

	mov	cx,10			; Finally check the last 10 drives
	xor	dx,dx
l_d30:
	push	ax			; pass the drive to _logical_drive
	call	_logical_drive		; call it
	test	ax,ax			; check return value
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
	mov	ax,(MS_X_IOCTL * 256) + 9 ; is device local ?
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
	test	dx,dx
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
	xor	ax,ax
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
	test	dx,dx
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
	xor	ax,ax
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
	test	dx,dx
	jne	not_networked	; its a network drive

	mov	ax,-1
	jmp 	network_exit
not_networked:
	xor	ax,ax
network_exit:
	pop	bx
	pop	cx
	pop	dx
	pop	bp
	ret 

_network_drive	ENDP

endif	;EXT_SUBST


	Public	_dr_toupper

UCASE	equ	18			; offset of dword ptr to uppercase func

;-------
_dr_toupper	proc	near
;-------
; Return the uppercase equivilant of the given character.
; The uppercase function defined in the international info block is 
; called for characters above 80h.
;
; char	ch;				char to be converted
; char	result;				uppercase equivilant of ch
;
; result = dr_toupper(ch);

	push	bp
	mov	bp, sp

	mov	ax, 4[bp]
	xor	ah, ah			; al = character to be converted
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

_dr_toupper	endp

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
	ret
_dbcs_lead	endp


	PUBLIC	_extended_error
_extended_error PROC NEAR

	mov	ah,59h
	xor	bx,bx
	int	21h
	neg	ax
	ret

_extended_error	ENDP

	PUBLIC	_get_lines_page
_get_lines_page PROC NEAR

	push	bp
	push	es

	mov	ax,1130h
	xor	bx,bx
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
	xor	ax,ax
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

	xor	ax,ax
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
	xor	ax,ax
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
	xor	ax,ax
	mov	es,ax
	xor	si,si
	mov	ax,0ef03h
	int	21h
	
	mov	ax,es
	test	ax,ax
	jne	nc_ok
	test	si,si
	jne	nc_ok
	mov	ax,-1
	jmp	nc_exit	

nc_ok:
	mov	al,es:23[si]
	xor	ah,ah
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

	Public	_get_colour
;-----------
_get_colour:
;-----------
	push	bp
	mov	bp,sp
	push	es
	mov	ah,52h			; get List of Lists
	int	DOS_INT
	les	bx,F52_CONDEV		; get console driver address
get_colour10:
	xor	cx,cx
	dec	cx			; CX=FFFFh
	mov	ax,es
	cmp	ax,cx			; check if CON driver address valid
	 jne	get_colour20
	cmp	bx,cx
	 jne	get_colour20
	xor	ax,ax			; FFFF:FFFFh means end of chain
	xor	dx,dx
	jmp	get_colour40
get_colour20:
	call	check_colour		; test for CON with COLOUR support
	 je	get_colour30
	les	bx,es:[bx]		; go to next driver in chain
	jmp	get_colour10
get_colour30:
	mov	ax,es:24[bx]		; get current COLOUR parameters
	mov	dl,es:26[bx]
get_colour40:
	mov	bx,4[bp]		; and store them in variables
	mov	ds:[bx],ax
	mov	ds:2[bx],dl
	pop	es
	pop	bp
	ret

	Public	_set_colour
;-----------
_set_colour:
;-----------
	push	bp
	mov	bp,sp
	push	es
	mov	ah,52h			; get List of Lists
	int	DOS_INT
	les	bx,F52_CONDEV		; get console driver address
set_colour10:
	xor	cx,cx
	dec	cx			; CX=FFFFh
	mov	ax,es
	cmp	ax,cx			; check if CON driver address valid
	 jne	set_colour20
	cmp	bx,cx
	 je	set_colour40		; FFFF:FFFFh means end of chain
set_colour20:
	call	check_colour		; test for CON with COLOUR support
	 je	set_colour30
	les	bx,es:[bx]		; go to next driver in chain
	jmp	set_colour10
set_colour30:
	push	bx
	mov	bx,4[bp]		; get new parameters
	mov	ax,ds:[bx]
	mov	dl,ds:2[bx]
	pop	bx
	mov	dh,al
	and	al,1
	mov	es:24[bx],al		; and update COLOUR with these
	test	dh,2
	 jnz	set_colour35
	mov	es:25[bx],ah
	mov	es:26[bx],dl
set_colour35:
	push	ax
	mov	bh,dl
	mov	ax,1001h		; set new border colour
	int	10h
	pop	bx
	xchg	bh,bl
	call	col_screen		; update screen colours
set_colour40:
	pop	es
	pop	bp
	ret

check_colour:
	push	ds			; check for COLOUR support in driver
	push	si
	push	di
	push	cs
	pop	ds
	lea	si,cs:colour_sig	; signature
	lea	di,10[bx]
	mov	cx,14			; length of signature
	cld
	repz	cmpsb			; compare string
	pop	di
	pop	si
	pop	ds
	ret				; zero flag set if COLOUR supported

colour_sig	db	"CON     ","COLOUR"

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

_TEXT	ENDS
	END
