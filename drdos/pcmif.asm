;    File              : $PCMIF.ASM$
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
;    $Log: $
;    PCMIF.A86 1.21 93/09/09 22:36:50
;    Int 21/59 uses error stack 
;    PCMIF.A86 1.20 93/08/27 18:56:30 
;    Int 25/26 32 bit sector detection
;    PCMIF.A86 1.19 93/07/22 19:30:54 
;    chnage int 25/26 support for NDD 
;    PCMIF.A86 1.18 93/07/20 22:47:54 
;    Even fewer checks on int 25/26 
;    PCMIF.A86 1.14 93/05/06 19:28:31
;    Move int 23/28 support to CIO.
;    PCMIF.A86 1.13 93/05/05 23:31:0
;    int 2A/84 is now only generated on input-and-wait functions
;    PCMIF.A86 1.12 93/03/25 15:06:48
;    tweak int21 entry
;    ENDLOG
;
; 24 Aug 87 The CARRY flag is now preserved for all DOS functions below
;           038h Get/Set Country Code.
; 04 Sep 87 Display the Interrupt Number and Registers when an illegal
;           software interrupt is executed by an application. This
;           is disabled by DBG OFF.
; 09 Sep 87 DDIO interface changed to support a Double Word sector
;           number.
; 05 Oct 87 Critical Error abort routine now uses the correct 
;           terminate code.
; 14 Oct 87 INT2F responds like a Network Redirector
; 28 Oct 87 Preserve the state of the INDOS_INTERNAL flag during multiple
;           calls through DOS_ENTRY
; 29 Oct 87 DS now points at the IBM PC ROS during an INT1B and INT1B
;           moved into IBMROS.
;  7 Nov 87 Removal of development flags
;  5 Jan 88 Terminate CP/M applications making DOS Calls in Concurrent DOS
; 26 Feb 88 Terminate DOS applications making CP/M calls in DOSPLUS
; 26 Apr 88 INT25/26 error codes only translated for Concurrent
; 18 May 88 Prevent corruption of the EXIT_CODE by INT23 and INT24
;           when the application does not return.
; 23 May 88 Prevent termination during CONFIG.SYS processing in DOSPLUS
; 26 May 88 Force INDOS and ERROR flags to ZERO on terminate
;  1 Jun 88 Modify INT28 to execute delays and work with SideKick.
; 15 Jul 88 Support the IDLECNT field in the Process Descriptor and
;           CCB BUSY bit.
; 07 Sep 88 PolyTron PolyWindows make DOS functions calls whenever
;           CS < SS. Therefore during the INT21 Entry and Exit code
;           interrupts must be disabled untill the stack swap occurs
;           even though the INDOS_FLAG is non-zero.
; 24 Oct 88 File Lock/Unlock is now treated as an INACTIVE function.
;  4 Nov 88 Correct the INT25/26 Error Translation Code
; 21 Nov 88 Make INt25/26 Error Translation even better.
; 29 Nov 88 Command Line Editor Insert on by default.
; 21 Dec 88 IJs IDLE detection improvement only DELAY if someone else is
;           ready to run.
; 11 Jan 89 Inc/Dec INTERNAL_FLAG to support DOS_ENTRY reentrancy.
; 30 Jan 89 Inc/Dec INDOS_FLAG to INT25/26 Direct Disk I/O (CHKDSK/PRINT)
; 19 Feb 89 Check the SHARE_FLAG for SHARING status in DR DOS
;  9 Mar 89 Save/Restore PSP_USERSP/SS round int28's (SKPLUS/LINK/CTRL-C)
; 18 Apr 89 ij	Maintain the INDOS_FLAG correctly while processing INT 24
; 18 Apr 89 Only take over INTs 5B and 5C for Debug Systems
; 22 May 89 Setup DS before testing the state of the Share Flag.
; 25 May 89 Support INT28_FLAG for functions 01 to 0C inclusive
; 31 May 89 Move break_sp into DOS internal data area
;  1 Jun 89 Save PSP_USERSS and SP during a critival Error (INT 24)
; 05 Jun 89 Return NOT present for ASSIGN command and TRUE state for APPEND
; 29 Jun 89 Save/restore retry_sp & retry_off around INT 24
; 10 Jul 89 INT27 corrected to handle memory size of XXX1 (INFORM)
; 31 Jul 89 Move stacks to DATA.PCM (CDROM support under way...)
; 11 Aug 89 Create INT2F.PCM to support real INT 2F functions
;  6 Sep 89 INT2A/84 keyboard busy loop added to do_int28
; 23 Oct 89 MON_PERM removed from func5D/func5E/func5F (pain with MSNET..)
;  9 Nov 89 Int 5B & 5C no longer taken over in DRDOS Debug versions
;           (Conflicts with PC-Net)
; 15 Jan 90 pcmode_swapin/pcmode_swapout added for paged isr support
; 25/Jan/90 Support Idle Data Area
; 25/Jan/90 Add forth stack to support Japanese FEP and PTHOT.
; 29/Jan/90 keep int21 CS/IP/FLAGS on local stack
; 13/Feb/90 Added func63.
; 20/Feb/90 CDOS checks caller is DOS process and aborts if not.
; 22/Feb/90 Int25/26 checks disk label for passwords
;           Also swaps to normal stack like others DOS's
;  7 Mar 90 Convert to register preserved function calls
; 16 Mar 90 Int25/26 checks out for Leopard Beta 2
;  4 Jun 90 Int21/25&35 don't swap stacks-ANSI.SYS Framework DOS window bug
;  7 Jun 90 Print Rite fix moves to init.pcm
; 29 Jun 90 CDOS idle detection uses timer info
;  9 Aug 90 Int 8 tick count packed in P_CMOD
; 19 Sep 90 load current_psp before checking PSP_PIDF (thanks Datapac)
;  4 Oct 90 improved control break handling
; 11 Oct 90 dev_map now supported to set LPTn/COMn mapping
;  1 Nov 90 default Int 24 handler returns "Fail"
; 19 feb 91 do_int28 calls read_time_and_date (BIOS CLOCK needs a call
;           every day)
; 14 jun 91 copy user regs to local copy after int24 for pcshell
;  8 aug 91 SI preserved on Int25/26 for SCAN 7.7

PCMDATA group PCMODE_DATA,FDOS_DSEG
PCMCODE group PCM_CODE,PCM_RODATA

	.nolist
	include	pcmode.equ
	include	fdos.def
	include	vectors.def
	include	msdos.equ
	include	mserror.equ
	include	psp.def
	include	fdos.equ
	.list


PCM_CODE	segment public byte 'CODE'
ASSUME DS:PCMDATA

	extrn	pcmode_dseg:word
	extrn	break_check:near		; Control-C Check 
	extrn	error_exit:near
	extrn	fdos_nocrit:near
	extrn	get_ddsc:near

;
;	This entry point is used when a CALLF PSP:0005 has been executed
;	Here the function number is passed in CL and not AH and only
;	functions 0 to 24 inclusive can be executed.
;
;		Entry Stack	->	INT 21 Stack
;
; SP + 04	Return Offset		Current Flags
; SP + 02	 PSP Segment		 PSP Segment
; SP + 00	   000Ah		Return Offset
;
	Public	call5_entry
call5_entry:
	pop	ax		; Remove 000Ah return Offset
	pushf			; Save the Flags
	push 	bp
	mov 	bp,sp		; Get Stack Frame Pointer
	mov	ax,02[bp]	; Get the FLAGS
	xchg	ax,06[bp]	; Swap with the return offset
	mov	02[bp],ax	; and then save the return offset
	pop	bp		; Restore the BP register
	mov	ah,cl		; Make it look like an INT 21
	cmp	ah,024h		; Check for a valid function for this
	jbe	int21_entry	; entry technique if not return
illegal_iret:
	xor	al,al
	iret

int21_e01:
	mov	ds,word ptr ds:INT31_SEGMENT
	jmp	int21_e02

;	++++++++++++++++++++++++++
;	Int 20 - Program Terminate
;	++++++++++++++++++++++++++
;
	Public	int20_entry
int20_entry:
    	xor	ah,ah
;	jmp	int21_entry		; and jump to the standard entry point

;	+++++++++++++++++++++++++
;	Int 21 - Function Request
;	+++++++++++++++++++++++++
;
	Public	int21_entry
int21_entry:
	cmp	ah,pcmode_ftl		; is it in range ?
	 ja	illegal_iret		;  no, return BEFORE enabling ints
	cld				; Clear the direction flag
	PUSH_DOS			; Save User Registers
	mov	ds,pcmode_dseg		; get CS relative Data Segment
	test	pcmode_dseg,0FFFFh	; if Data Segment is zero then get
	 jz	int21_e01		; the Data segment address from
int21_e02:				; the segment portion of INT 31

;
;	The following routines execute on the users stack without
;	modifing the INDOS_FLAG etc. These routines should only read
;	or update BASIC system variables.
;
	cmp	ah,33h			; Func 33h - Control Break
	 je	int21_e10
	cmp	ah,50h			; Func 50h - Set PSP
	 jb	int21_e20
	cmp	ah,51h			; Func 51h - Get PSP
	 jbe	int21_e10
	cmp	ah,62h			; Func 62h - Get PSP
	 jne	int21_e20
int21_e10:
	mov	bp,sp			; Calculate the Stack Frame address
	call	internal_func		; "jump" to appropriate routine
	jmp	int21_exit

int21_e20:
	inc	indos_flag		; Increment the INDOS Flag

	mov	int21AX,ax		; save function number

	cmp	WindowsHandleCheck,26h	; is windows active ?
	 jne	int21_e30
	mov	ax,LocalMachineID	; get local machine ID (zero unless
	mov	machine_id,ax		;  we are multi-tasking)

int21_e30:
	mov	ax,current_psp
	mov	owning_psp,ax
	mov	es,ax			; Get the PSP

	mov	ax,sp
	mov	es:PSP_USERSP,ax	; Save the SS:SP pointer to 
	mov	es:PSP_USERSS,ss	; the register image ready for any
					; Critical errors that might occur

	xchg	ax,int21regs_off	; point to callers registers
	mov	prev_int21regs_off,ax	; while saving current
	mov	ax,ss			;  pointer to cater for
	xchg	ax,int21regs_seg	;  re-entrancy
	mov	prev_int21regs_seg,ax

	xor	ax,ax
	mov	remote_call,ax		; indicate we are a local call
	mov	int28_flag,al		; Do NOT Generate INT 28s
	mov	lfnpathflag, al

	mov	ax,ds
	mov	ss,ax			; swap initially to the error
	mov	sp,offset error_stack	;  stack until we know better
	mov	ax,int21AX		; reload AX

	sti
	cmp	ah,59h			; Func 59h - Return Extended Error
	 je	int21_e50		;  use the error stack
	cmp	ah,0Ch			; are we a character function
	 ja	int21_e40		;  in range 01-0C ?
	test	ah,ah
	 je	int21_e40
	cmp	error_flag,0		; Use the "ERROR" Stack for the above
	 jnz	int21_e50		;  functions 01-0C if error_flag set
	mov	sp,offset indos_stack	; else use the "INDOS" stack for these
	mov	int28_flag,TRUE	and 0ffh	;  functions and generate INT 28s
	jmp	int21_e50

int21_e40:
	mov	error_flag,0		; clear the error flag in case someone
					; hasn't returned from an Int 24
	push	ax			; save function on stack
	mov	ah,82h			; magic number in AH
	int	2ah			; call server hook
	pop	ax			; recover function number

	mov	sp,offset normal_stack	; switch to the NORMAL stack
	test	break_flag,0FFh		; is the Break Flag ON
	 jz	int21_e50		;  NO - So continue
	call	break_check		; Handle the Control-C
int21_e50:
if IDLE_DETECT
	test	idle_flags,word ptr IDLE_DISABLE	; don't break the pipeline unless
	 jz	int21_idle		;  IDLE checking enabled
int21_e60:
endif
	call	int21_func		; Execute the function
	cli				; Stop anybody interfering
	les	bp,int21regs_ptr	; point to user stack
	mov	es:reg_AL[bp],al	; always return AL
	mov	ax,prev_int21regs_off
	mov	int21regs_off,ax
	mov	ax,prev_int21regs_seg
	mov	int21regs_seg,ax
	mov	ax,es
	mov	ss,ax			; back to users stack
	mov	sp,bp
	dec	indos_flag		; Decrement the INDOS_FLAG
;	jmp	int21_exit

	Public	int21_exit
int21_exit:
	POP_DOS				; Restore Registers
	iret

if IDLE_DETECT
; Only called if Idle detection is enabled
; AH,DL as on Int 21 Entry
; Decide if function is active/inactive

int21_idle:
;----------
if IDLE_DETECT
	mov	bx,int28_reload		; reset the INT28 delay counter
	mov	int28_delay,bx		;  with the Reload value
endif
	cmp 	ah,5Ch
	je 	int21_inactive		; Treat Lock/Unlock as inactive some
					; applications poll locked record.
	cmp 	ah,44h
	je 	int21_inactive		; IO Control Treated as Inactive
	cmp 	ah,2Ch
	ja 	int21_active		; > Get Current Time all active
	je 	int21_inactive		; Get Current Time inactive
	cmp 	ah,2Ah
	je 	int21_inactive		; Get Current Date inactive
	cmp 	ah,0Bh
	je 	int21_inactive		; Console Status
	cmp 	ah,0Ch
	je 	int21_inactive		; Flush and Invoke Treated as Inactive
	cmp 	ah,19h
	je 	int21_inactive		; Get Current Disk
	cmp 	ah,06h
	jne 	int21_active		; Treat RAW_IO Status as Inactive
	cmp 	dl,0FFh
	je 	int21_inactive

int21_active:				; Active function Executed
	or	idle_flags,word ptr IDLE_DOSFUNC	; set DOSFUNC flag for BIOS
	call	active			; remember we were active
	jmp	int21_e60		; continue execution

int21_inactive:
	call	inactive		; Process this INACTIVE function
	jmp	int21_e60


	Public	inactive
inactive:
	push 	es
	push 	ax

	dec	active_cnt		; Decrement the count
	jnz	inactive_10		; Return if Non-Zero

	mov	ax,idle_max		; Get the default count value
	mov	active_cnt,ax		; and reset the internal count

	test	idle_flags,IDLE_DISABLE	; Has Idle Checking been enabled
	 jnz	inactive_10		; Skip if NO.
	mov	ax,PROC_IDLE		; Process is IDLE
	call	dword ptr idle_vec	; Call the IDLE Handler

inactive_10:
	pop 	ax
	pop 	es
	ret
;
;	This routine will reset the active count for functions which
;	are treated as INACTIVE but which have active sub-functions.
;
	Public	active
active:
	push	ax
	mov	ax,idle_max		; Get the default count value
	mov	active_cnt,ax		; and reset the internal count
	pop	ax
	ret
endif
;
;
;	This function is invoked for functions number above the last 
;	supported function number. It forces AL to zero and returns.
;	Just that and nothing more.
; 
ms_zero_AL:
	xor	ax,ax			; AL = 0 for return
	ret

;	DOS_ENTRY is used to call DOS functions internally.
;	eg. Func4B (exec) calls MS_X_OPEN, MS_X_READ, MS_X_CLOSE etc.
;	It is the responsibilty of the caller to make sure that no side
;	effects exist if this entry point is used.
;	eg. critical error handling
;
;
	Public	dos_entry
dos_entry:
	clc
	cld
	pushf				; look like Int21 registers
	pushf
	pushf				; fake CS/IP positions
	push 	ds
	push 	es			; Save registers on the USER stack
	push 	bp			; no Stack Swap is executed and DS
	push 	di
	push 	si			; and ES are swapped.
	push 	dx
	push 	cx
	push 	bx
	push 	ax
	mov	bp,sp			; Initialise Stack Frame

	call	get_dseg		; Get our Data Area

	inc	internal_flag

	push	fdos_data+0*WORD	; save fdos pblk so we can
	push	fdos_data+1*WORD	;  be re-entrant(ish)
	push	fdos_data+2*WORD
	push	fdos_data+3*WORD
	push	fdos_data+4*WORD
	push	fdos_data+5*WORD
	push	fdos_data+6*WORD
	
	push	int21regs_off
	push	int21regs_seg

	mov	int21regs_off,bp
	mov	int21regs_seg,ss

	call	internal_func		; Execute the function
	mov	reg_AL[bp],al		; always return AL to caller

	pop	int21regs_seg
	pop	int21regs_off		; restore previous pointer user REGS

	pop	fdos_data+6*WORD
	pop	fdos_data+5*WORD
	pop	fdos_data+4*WORD
	pop	fdos_data+3*WORD
	pop	fdos_data+2*WORD
	pop	fdos_data+1*WORD
	pop	fdos_data+0*WORD	; restore fdos_pb for nested calls

	dec	internal_flag

	pop 	ax
	pop 	bx			; Update the registers then
	pop 	cx
	pop 	dx			; set the flags and return
	pop 	si
	pop 	di			; to the user
	pop 	bp
	pop 	es
	pop 	ds
	popf				; discard dos_IP
	popf				;  and dos_CS
	popf				; get result
	 jnc	dos_entry10
	neg	ax			; return using our negative error
	stc				; conventions
dos_entry10:
	ret

	Public	int21_func

int21_func:
;----------
; On Entry:
;	AX, CX, DX, SI, DI as per Int 21
;	BX = ??
;	BP = ??
;	DS = pcmode data
;	ES = ??
; On Exit:
;	(to client function)
;	All general purpose registers as per Int 21 entry
;	ES = dos_DS
;

	xor	bx,bx			; BH = 0
	mov	bl,ah			; BX = function number
	shl	bx,1			; make it a word offset
	push	pcmode_ft[bx]		; save address of Function
	les	bp,int21regs_ptr
	mov	bx,es:reg_BX[bp]	; reload from dos_BX,dos_BP,and dos_DS
	les	bp,es:dword ptr reg_BP[bp]
	ret


internal_func:
;-------------
; On Entry:
;	All registers as per Int 21 EXCEPT
;	DS = pcmode data
;	BP = dos_REGS stack frame
; On Exit:
;	(to client function)
;	ES = dos_DS
;
	mov	al,ah			; function number in AL
	cbw				; AH = 0
	xchg	ax,bx			; get subfunction in BX
	shl	bx,1			; make offset in the internal table
	push	pcmode_ft[bx]		; save address of Function
	xchg	ax,bx			; restore BX
	mov	ax,reg_AX[bp]		; recover function number
	mov	es,reg_DS[bp]		; ES = callers DS
	ret				; "jump" to handler

;	INT25 and INT26 direct disk I/O interface
;
;Standard DOS 1.xx - 3.30 INT25/26 Interface
;===========================================
;
;	entry:	al = drive number
;		ds = DMA segment
;		bx = DMA offset
;		cx = number of sectors
;		dx = beginning relative sector
;
;
;Enhanced DOS 3.31 INT25/26 Interface
;====================================
;
;	If CX == 0FFFFh then the application is using the enhanced
;	INT25/INT26 interface which allows access to more than 64K
;	sectors.
;
;	entry:	al = drive number
;		bx = Parameter block Offset
;		ds = Parameter block Segment
;
;	Parameter Block Format
;DS:BX ->	DD	Starting Sector No.
;		DW	Number of Sectors
;		DD	Transfer Address
;
;
;	exit:	C flag = 0 if successful
;		       = 1 if unsuccessful
;		ax = error code(if CF = 1)
;		  ah physical error
;		  al logical error
;		Users orginal flags left on stack
;
;
DDIO_INT13	equ     0
DDIO_READ_OP	equ     1
DDIO_WRITE_OP	equ     2

;	++++++++++++++++++++++++++++
;	Int 26 - Absolute Disk Write
;	++++++++++++++++++++++++++++
;
	Public	int26_entry
int26_entry:
	mov 	ah,DDIO_WRITE_OP	; This is a WRITE operation	
	jmp	int26_10


;	+++++++++++++++++++++++++++
;	Int 25 - Absolute Disk Read
;	+++++++++++++++++++++++++++
;
	Public	int25_entry
int25_entry:
	mov 	ah,DDIO_READ_OP		; This is a READ operation	
int26_10:				; Common Direct Disk I/O code
	cld
	push 	ds
	push 	es
	push	di
	push	dx			; save DX for FLASHCARD
	push 	ds
	pop 	es			; ES = callers DS
	call	get_dseg		; Get PCMODE Data Segment
	inc	indos_flag		; Update the INDOS_FLAG
	mov	normal_stack+2,ss	; save users SS:SP
	mov	normal_stack,sp
	cli
	push 	ds
	pop 	ss			; use normal stack when in here
	mov	sp,offset normal_stack
	sti
	inc	cx			; CX = FFFF indicates this is
     jz int26_30       
; CHECK FOR PARITIONS > 32 MBytes...
	dec	cx			; CX restored
	push	es
	push	ax
	push	bx
	push	dx
	call	get_ddsc		; ES:BX -> DDSC_
	mov	di,0201h		; assume bad drive
	 jc	int26_20
	mov	di,0207h		; assume large media, and this error
if 0
; This code works out the total number of sectors on a drive
	mov	ax,es:DDSC_NCLSTRS[bx]	; get last cluster #
	dec	ax			;  make it # data clusters
	xor	dx,dx
	mov	dl,es:DDSC_CLMSK[bx]	; get sec/cluster -1
	inc	dx			; DX = sec/cluster
	mul	dx			; DX:AX = # data sectors
	add	ax,es:DDSC_DATADDR[bx]	; add in address of 1st data sector
	adc	dx,0
else
	mov	ax,es:DDSC_NCLSTRS[bx]	; get last cluster #
	xor	dx,dx
	mov	dl,es:DDSC_CLMSK[bx]	; get sec/cluster -1
	inc	dx			; DX = sec/cluster
	mul	dx			; DX:AX is vaguely the # sectors
	test	dx,dx			; close enough for bill
endif
	stc				; assume an error
	 jnz	int26_20
	xor	di,di			; DI = zero, no error
int26_20:
	pop	dx
	pop	bx
	pop	ax
	pop	es
	 jnc	int26_40
	xchg	ax,di			; AX = error code
	jmp	int26_60		; return it
int26_30:	
	mov	dx,es:word ptr 0[bx]	; Get Starting Sector Low
	mov	di,es:word ptr 2[bx]	; Get Starting Sector High
	mov	cx,es:word ptr 4[bx]	; Get No. of sectors to transfer
	les	bx,es:dword ptr 6[bx]	; Tranfer Address Offset
int26_40:
	mov	FD_DDIO_DRV_OP,ax	; save drive and operation
	mov	FD_DDIO_NSECTORS,cx	; No. of Sectors
	mov	FD_DDIO_STARTLOW,dx	; Starting Sector No.
	mov	FD_DDIO_STARTHIGH,di	; High Word of Sector Number
	mov 	FD_DDIO_DMAOFF,bx	; DMA Offset
	mov	FD_DDIO_DMASEG,es	; DMA Segment

	mov	FD_FUNC,FD_DDIO
	call	fdos_nocrit		; let the FDOS do the work
	neg	ax			; AX is DOS extended error
	 jz	int26_exit
	sub	al,-ED_PROTECT		; get AL to Int24 error format
	cmp	al,-(ED_GENFAIL-ED_PROTECT)
     jbe    int26_50       
	mov	al,-(ED_GENFAIL-ED_PROTECT)
int26_50:				; no, make it general failure
	mov	ah,al			; save error in AH
	mov	bx,offset int13_error
	xlat	int13_error		; convert error to int13 format
	xchg	al,ah			; get errors in correct registers
int26_60:
	stc				; Set the Carry Flag when an error
int26_exit:				; Occurs and return to the calling app.
	cli
	mov	ss,normal_stack+2	; back to user stack
	mov	sp,normal_stack
	sti
	dec	indos_flag		; Update the INDOS_FLAG
	sti
	pop	dx
	pop	di
	pop 	es
	pop 	ds			; restore callers registers
	retf				; leave flags on stack

int13_error	db	03h,02h,80h,01h,10h,02h,40h,02h,04h,02h,02h,02h,02h

;	++++++++++++++++++++++++++++++++++++
;	Int 27 - Terminate but Stay Resident
;	++++++++++++++++++++++++++++++++++++
;
	Public	int27_entry
int27_entry:
	mov	ax,3100h	; Convert this to a DOS 'Terminate and 
	add	dx,15		; Stay Resident' function by converting the
	rcr	dx,1		; memory size in bytes to paragraphs.
	shr	dx,1		; On entry DX == memsize + 1 bytes therefore
	shr	dx,1		; round upto a paragraph boundary by adding
	shr	dx,1		; 15 then divide by 16
	jmp	int21_entry

;
;	DO_INT24:
;	    On Entry:-
;			AH	Set for INT 24
;			AL	Drive Number (0 = A:)
;			DI	Error Code
;			ES:SI	Device Header Control Block
;
;	    On Exit:-
;			AL	Error Response Retry/Ignore/Fail
;
;	INT 24 Critical Error:-
;	On Entry:-	AH/7	0 = Disk Device
;			AH/5	0 = IGNORE is an Invalid Response
;			AH/4	0 = RETRY in an Invalid Response
;			AH/3	0 = FAIL is an Invalid Response
;			AH/2-1	00= DOS Area
;				01= File Allocation Table
;				10= Directory
;				11= Data
;			AH/0	0 = Read, 1 = Write
;
;			AL	1 Retry the Operation
;			BP:SI	Device Header Control Block
;			DI	High Byte Undefined, Low Byte Error Code 
;
;	    On Exit:-	AL	0 = IGNORE Error
;				1 = RETRY the Operation
;				2 = TERMINATE using INT 23
;				3 = FAIL the current DOS function
;
	Public	do_int24
do_int24:
	cmp	error_flag,0		; Skip the critical error routine
	jz	di24_05			; if the handler is active
	mov	al,ERR_FAIL		; Then return the FAIL condition
	ret				; to the calling routine
di24_05:
	push 	ax
	push 	bp			; Save our Base Pointer and then the
	cli				; Disable Interupts

	mov	bp,es			; BP:SI points to dev header
	mov	es,current_psp		; Get the current PSP and USER Stack

	push	es:PSP_USERSS		; Save the Users Real SS and SP
	push	es:PSP_USERSP		; on the internal Stack
	push	retry_sp		; also the retry info
	push	retry_off
	push	remote_call
	push	machine_id

	mov	critical_sp,sp		; Internal Stack Pointer Offset

	inc	error_flag		; Entering Critical Error Handler
	dec	indos_flag		; I may be gone some time....
					; (an application error handler need
					; never return so tidy up first)

	mov	ss,es:PSP_USERSS	; Switch to the Users Stack
	mov	sp,es:PSP_USERSP

	int	24h			; Call the Critical Error Handler

	cld
	cli				; paranioa.....
	call	get_dseg		; Reload DS just in case someone at
					; A-T or Lotus cannot read

	push 	ds
	pop 	ss		; Swap back to the Internal stack
	mov	sp,critical_sp		; and process the returned info.

	pop	machine_id
	pop	remote_call
	pop	retry_off		; restore retry info
	pop	retry_sp
	mov	es,current_psp		; Restore the Users original SS and
	pop	es:PSP_USERSP		; SP registers from the Stack
	pop	es:PSP_USERSS

	pop 	bp
	pop 	bx			; Restore BP and original AX
	sti

	mov	error_flag,0
    inc indos_flag  

	cmp al,ERR_IGNORE
	jnz di24_10			; Check for IGNORE and force
	test bh,OK_IGNORE
	jnz di24_10 			; to become a FAIL if its an 
	mov	al,ERR_FAIL		; invalid response.

di24_10:
	cmp 	al,ERR_RETRY
	jnz 	di24_20			; Check for RETRY and force
	test 	bh,OK_RETRY
	jnz 	di24_20			; to become a FAIL if its an
	mov	al,ERR_FAIL		; invalid response.	

di24_20:
	cmp 	al,ERR_FAIL
	jnz 	di24_30			; Check for FAIL and force
	test 	bh,OK_FAIL
	jnz 	di24_30			; to become a ABORT if its an
	mov	al,ERR_ABORT		; invalid response.	

di24_30:
	cmp	al,ERR_ABORT		; Do not return if the ABORT option
	jz	di24_abort		; has been selected but execute
					; INT 23 directly
	cmp	al,ERR_FAIL		; All invalid reponses are converted
	ja	di24_abort		; to ABORT
di24_40:
	ret

di24_abort:				; Abort this Process
	mov	ax,current_psp		; check not root application because
	mov	es,ax			; it must not be terminated so force
	cmp	ax,es:PSP_PARENT	; Is this the root Process
	mov	al,ERR_FAIL		; convert the error to FAIL
	 je	di24_40			; if not we terminate
	mov	exit_type,TERM_ERROR	; Set the correct exit Type
	mov	ax,04C00h		; and return code.
	mov	int21AX,ax
	jmp	func4C			; Then terminate

;
;	Get the PCMODE Emulator data Segment from the PD
;
	Public	get_dseg
get_dseg:
	mov	ds,pcmode_dseg		; get CS relative Data Segment
	test	pcmode_dseg,0FFFFh	; If Data Segment is zero then get
	jz	get_d10			; the Data segment address from
	ret				; the segment portion of INT 31
get_d10:
	mov	ds,word ptr ds:INT31_SEGMENT
	ret


;
;INVALID_FUNCTION is called when any unsupported function has been executed
;
	Public	invalid_function
invalid_function:
	mov	ax,ED_FUNCTION		; Mark as Invalid Function
	jmp	error_exit		; and Exit


	Public	reload_registers
reload_registers:
;----------------
; This routine is called to reload the registers we expect to have correct
; at the start of a PCMODE function.
	push	ds
	lds	bp,int21regs_ptr
	mov	ax,ds:reg_AX[bp]
	mov	bx,ds:reg_BX[bp]
	mov	cx,ds:reg_CX[bp]
	mov	dx,ds:reg_DX[bp]
	mov	si,ds:reg_SI[bp]
	mov	di,ds:reg_DI[bp]
	les	bp,ds:dword ptr reg_BP[bp]
	pop	ds
	ret

PCM_CODE ends

PCMODE_DATA	segment public word 'DATA'
	extrn	retry_sp:word
	extrn	retry_off:word
	extrn	break_flag:byte
	extrn	current_psp:word
	extrn	current_dsk:byte
	extrn	dma_offset:word
	extrn	dma_segment:word
	extrn	error_flag:byte
	extrn	error_stack:word
	extrn	exit_type:byte
	extrn	int21regs_ptr:dword
	extrn	int21regs_off:word
	extrn	int21regs_seg:word
	extrn	prev_int21regs_ptr:dword
	extrn	prev_int21regs_off:word
	extrn	prev_int21regs_seg:word
	extrn	indos_flag:byte
	extrn	indos_stack:word
	extrn	LocalMachineID:word
	extrn	machine_id:word
	extrn	int21AX:word
	extrn	normal_stack:word
	extrn	owning_psp:word
	extrn	remote_call:word
	extrn	WindowsHandleCheck:byte
	extrn	lfnpathflag:byte

if IDLE_DETECT
	extrn	active_cnt:word
	extrn	idle_max:word
	extrn	idle_flags:word
	extrn	idle_vec:dword
	extrn	int28_delay:word
	extrn	int28_reload:word
endif
	
	extrn	critical_sp:word
	extrn	internal_flag:byte
	extrn	int28_flag:byte
PCMODE_DATA 	ends

PCM_CODE	segment public byte 'CODE'
	extrn	func00:near, func01:near, func02:near, func03:near
	extrn	func04:near, func05:near, func06:near, func07:near
	extrn	func08:near, func09:near, func0A:near, func0B:near
	extrn	func0C:near, func0D:near, func0E:near, func0F:near
	extrn	func10:near, func11:near, func12:near, func13:near
	extrn	func14:near, func15:near, func16:near, func17:near
	extrn	func19:near, func1A:near, func1B:near, func1C:near
	extrn	func1F:near, func21:near, func22:near, func23:near
	extrn	func24:near, func25:near, func26:near, func27:near
	extrn	func28:near, func29:near, func2A:near, func2B:near
	extrn	func2C:near, func2D:near, func2E:near, func2F:near
	extrn	func30:near, func31:near, func32:near, func33:near
	extrn	func34:near, func35:near, func36:near, func37:near
	extrn	func38:near, func39:near, func3A:near, func3B:near
	extrn	func3C:near, func3D:near, func3E:near, func3F:near
	extrn	func40:near, func41:near, func42:near, func43:near
	extrn	func44:near, func45:near, func46:near, func47:near
	extrn	func48:near, func49:near, func4A:near, func4B:near
	extrn	func4C:near, func4D:near, func4E:near, func4F:near
	extrn	func50:near, func51:near, func52:near, func53:near
	extrn	func54:near, func55:near, func56:near, func57:near
	extrn	func58:near, func59:near, func5A:near, func5B:near
	extrn	func5C:near, func5D:near, func5E:near, func5F:near
	extrn	func60:near, func62:near, func63:near, func65:near
	extrn	func66:near, func67:near, func68:near, func69:near
	extrn	func6C:near, func71:near, func73:near
PCM_CODE 	ends

;
;	The following Function tables are forced onto a word boundary
;	because of the word alignment of the PCMODE_RODATE segment.
;	Only word based Read Only data is held in this segment.
;

PCM_RODATA segment public word 'CODE'
	Public	pcmode_ft, pcmode_ftl
pcmode_ft	label word
	dw	func00			; (00) Terminate Program
	dw	func01			; (01) Read Keyboard and Echo
	dw	func02			; (02) Display Character
	dw	func03			; (03) Auxilary Input
	dw	func04			; (04) Auxilary Output
	dw	func05			; (05) Print Character
	dw	func06			; (06) Direct Console I/O
	dw	func07			; (07) Direct Console Input
	dw	func08			; (08) Read Keyboard
	dw	func09			; (09) Display String
	dw	func0A			; (0A) Buffered Keyboard Input
	dw	func0B			; (0B) Check Keyboard Status
	dw	func0C			; (0C) Flush Buffer, Read Keyboard
	dw	func0D			; (0D) Reset Disk
	dw	func0E			; (0E) Select Disk
	dw	func0F			; (0F) Open File
	dw	func10			; (10) Close File
	dw	func11			; (11) Search for First
	dw	func12			; (12) Search for Next
	dw	func13			; (13) Delete File
	dw	func14			; (14) Sequential Read
	dw	func15			; (15) Sequential Write
	dw	func16			; (16) Create File
	dw	func17			; (17) Rename File
	dw	ms_zero_AL		; (18) Unused DOS function (AL = 0)
	dw	func19			; (19) Current Disk
	dw	func1A			; (1A) Set Disk Transfer Address
	dw	func1B			; (1B) *Get Default Drive Data
	dw	func1C 			; (1C) *Get Drive Data
	dw	ms_zero_AL		; (1D) Unused DOS function (AL = 0)
	dw	ms_zero_AL		; (1E) Unused DOS function (AL = 0)
	dw	func1F 			; (1F) Get Default DPB
	dw	ms_zero_AL		; (20) Unused DOS function (AL = 0)
	dw	func21			; (21) Random Read
	dw	func22			; (22) Random Write
	dw	func23			; (23) File Size
	dw	func24			; (24) Set Relative Record
	dw	func25			; (25) Set Interrupt Vector
	dw	func26			; (26) Duplicate PSP
	dw	func27			; (27) Random Block Read
	dw	func28			; (28) Random Block Write
	dw	func29			; (29) Parse File Name
	dw	func2A			; (2A) Get Date
	dw	func2B			; (2B) Set Date
	dw	func2C			; (2C) Get Time
	dw	func2D			; (2D) Set Time
	dw	func2E			; (2E) Set/Reset Verify Flag
	dw	func2F			; (2F) Get Disk Transfer Address
	dw	func30			; (30) Get Version Number
	dw	func31 			; (31) Keep Process
	dw	func32			; (32) Get DPB
	dw	func33			; (33) CONTROL-C Check
	dw	func34			; (34) Get the Indos Flag
	dw	func35			; (35) Get Interrupt Vector
	dw	func36			; (36) Get Disk Free Space
	dw	func37			; (37) Get/Set Switch Character
	dw	func38			; (38) Return Country Dependant Info
	dw	func39			; (39) Create Sub-directory
	dw	func3A			; (3A) Remove Sub-directory
	dw	func3B			; (3B) Change Sub-directory
	dw	func3C			; (3C) Create a File
	dw	func3D			; (3D) Open a File Handle
	dw	func3E			; (3E) Close a File Handle
	dw	func3F			; (3F) Read from a File/Device
	dw	func40			; (40) Write to a File/Device
	dw	func41			; (41) Delete a Directory Entry
	dw	func42			; (42) Move a File Pointer
	dw	func43			; (43) Change Attributes
	dw	func44			; (44) I/O Control
	dw	func45			; (45) Duplicate File Handle
	dw	func46			; (46) Force a Duplicate File Handle
	dw	func47			; (47) Return Text of Current Directory
	dw	func48			; (48) Allocate Memory
	dw	func49			; (49) Free Allocated Memory
	dw	func4A			; (4A) Modify Allocated Memory
	dw	func4B			; (4B) Load and Execute Program
	dw	func4C			; (4C) Terminate a Process
	dw	func4D			; (4D) Get Return Code
	dw	func4E			; (4E) Find Matching File
	dw	func4F			; (4F) Find Next Matching File
	dw	func50			; (50) Set Current PSP
	dw	func51			; (51) Get Current PSP
	dw	func52			; (52) *Get In Vars
	dw	func53			; (53) *Build DPB from BPB
	dw	func54			; (54) Return Verify State
	dw	func55			; (55) Create a New PSP
	dw	func56			; (56) Move a Directory Entry
	dw	func57			; (57) Get/Set File Date and Time
	dw	func58			; (58) Memory Allocation Strategy
	dw	func59			; (59) Get Extended Error
	dw	func5A			; (5A) Create Temporary File
	dw	func5B			; (5B) Create New File
	dw	func5C			; (5C) File Lock Control
	dw	func5D			; (5D) Internal DOS Function
	dw	func5E			; (5E) Control Local Machine Data
	dw	func5F			; (5F) Get Network Assignments
	dw	func60			; (60) Perform Name Processing
	dw	ms_zero_AL		; (61) ?? Parse Path (AL = 0)
	dw	func62			; (62) Get Current PSP
	dw	func63			; (63) Get Lead Byte Table
	dw	invalid_function	; (64) *Saves AL and Returns
	dw	func65			; (65) Get Extended Country Information
	dw	func66			; (66) Get/Set Global Code Page
	dw	func67			; (67) Set Handle Count
	dw	func68			; (68) Commit File
	dw	func69			; (69) Get Serial number
	dw	func68			; (6A) Commit File (again)
	dw	invalid_function	; (6B) Unknown DOS 4
	dw	func6C			; (6C) Extended Open/Create
	dw	ms_zero_AL		; (6D) Unused DOS function (AL = 0)
	dw	ms_zero_AL		; (6E) Unused DOS function (AL = 0)
	dw	ms_zero_AL		; (6F) Unused DOS function (AL = 0)
	dw	ms_zero_AL		; (70) Unused DOS function (AL = 0)
	dw	func71			; (71) LFN and 64-bit file functions
	dw	ms_zero_AL		; (72) Unused DOS function (AL = 0)
	dw	func73			; (73) DOS 7 FAT32 functions
pcmode_ftl	equ	(offset $ - offset pcmode_ft)/2
	;**************************
	;* Do Not Move This Entry *
	;**************************
	dw	ms_zero_AL		; Illegal Function Handler

PCM_RODATA ends

	end
