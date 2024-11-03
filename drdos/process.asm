;    File              : $PROCESS.ASM$
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
;    $Log$
;    PROCESS.A86 1.25 94/07/13 16:15:27 
;    Int21/26 (create PSP) copies 1st 20 entries of parental XFT
;    PROCESS.A86 1.24 94/06/28 11:15:28
;    Don't issue an int 21 to get curret psp while within int21/4B load overlay
;    PROCESS.A86 1.20 93/09/28 19:44:03 
;    Don't lose 8th character of name in DMD during exec
;    PROCESS.A86 1.14 93/06/18 21:00:57
;    Support for Int 21/4B05 added
;    PROCESS.A86 1.13 93/06/11 02:11:20
;    GateA20 disabled on EXEC for EXEPACKED apps
;    Fix termination code 
;    ENDLOG
;

PCMDATA group PCMODE_DATA,FDOS_DSEG,PCMODE_CODE
PCMCODE group PCM_CODE

ASSUME DS:PCMDATA

	.nolist
 	include	pcmode.equ
	include fdos.def
	include	psp.def
	include mserror.equ
	include	vectors.def
	include msdos.equ
	include exe.def
	include	char.def
	include	redir.equ
	include	doshndl.def
	.list

HILOAD	equ	TRUE

PCM_CODE	segment public byte 'CODE'
	extrn	check_dmd_id:near
	extrn	dbcs_lead:near
	extrn	error_exit:near
	extrn	fdos_nocrit:near
	extrn	free_all:near
	extrn	get_dseg:near		; Get the PCMODE Data Segment
	extrn	int21_exit:near
	extrn	invalid_function:near
	extrn	dos_entry:near
	extrn	return_AX_CLC:near
	extrn	set_owner:near
	extrn	strlen:near
	extrn	toupper:near
	extrn	valid_drive:near
;
;
;PC-DOS PSP Creation Update and Maintance routines
;
;	*****************************
;	***    DOS Function 55    ***
;	***    Create New PSP     ***
;	*****************************
;
;	entry:	DX = New PSP Segment
;		SI = Top of Available
;
;	This function copies the existing PSP and generates a new Process
;	environment. The file table is updated and dos_SI is used to determine
;	the process' memory size. The PSP is then made the CURRENT_PSP

	Public	func55
func55:
	mov	cx,PSPLEN/2		; copy whole PSP
	call	create_psp
    mov al,0F0h     
    ret             
	
create_psp:
	mov	ax,current_psp		; All based on the Current PSP
	call	copy_psp		; Do the Basic Copy
	mov	ax,current_psp		; get the Current PSP address
	mov	es:PSP_PARENT,ax	;   and save it in child's psp

	cmp	ax,dx			; Is this the ROOT level DOS process
	 jz	create_psp10		; Yes because Current PSP == New PSP
					; therefore skip the EXEC function
					; because this is done by P_CREATE

	mov	FD_FUNC,FD_EXEC		; Must Update the Open Counts ETC.
	mov	FD_PSPSEG,dx		; New PSP address
	call	fdos_nocrit

create_psp10:
	mov	current_psp,es		; set the New PSP address
	ret

;
;	*****************************
;	***    DOS Function 26    ***
;	***    Create New PSP     ***
;	*****************************
;
;	entry:	DX = New PSP Segment
;
	Public	func26
func26:
	les	di,int21regs_ptr	; Get pointer to INT 21 structure of
	mov	es,es:reg_CS[di]	; IP/CS/Flags and get the USER CS this
	mov	si,es:PSP_MEMORY	; is used as the PSP for this function 
	mov	ax,es			; call and NOT current_psp
	mov	cx,PSPLEN/2		; copy whole PSP
	push	dx
	call	copy_psp
	pop	es
	mov	cx,20			; default XFT table has twenty files
	mov	di,offset PSP_XFT	;  and is in the PSP at this offset
	mov	es:PSP_XFNMAX,cx	; say we have 20 files max
	mov	es:PSP_XFTOFF,di
	mov	es:PSP_XFTSEG,es
	push	ds
	mov	ds,current_psp		; we copy 1st 20 entries of current
	lds	si,ds:PSP_XFTPTR	;  XFT to the child PSP
	;rep	movsb			; we do not update file handle use
	shr	cx,1			; Do 10 mov for 20 bytes
	rep	movsw			; we do not update file handle use
	pop	ds			;  counts, unlike Int21/55
	ret

copy_psp:
; copy CX words from AX:0 to DX:0, SI = memory top
	push	si			; Save the Memory TOP
	push	ds
	mov	es,dx			; Point ES to the New PSP
	mov	ds,ax			; Get the current PSP for this function
	xor	ax,ax
	mov 	di,ax
	mov 	si,ax
	rep	movsw			; Copy into New PSP

	mov	ds,ax			; Copy the current Terminate, Critical 
	mov	si,INT22_OFFSET		; Error and Control Break Handlers
	mov	di,offset PSP_TERM_IP	; into the new PSP
	mov	cl,6
	rep	movsw			; BREAK,TERM, CRIT ERR SAVED HERE
	pop	ds
	pop	es:PSP_MEMORY

	mov	es:PSP_INT20,020CDh	; Interrupt 20h Terminate
	mov	es:PSP_RES1,0FFFFh
	mov	es:PSP_RES2,0FFFFh
	mov	es:PSP_DOSCALL,021CDh	; INT 21h Function Call
	mov	es:PSP_DOSRETF,0CBh	; RETF

	mov	es:PSP_LONGCALL,09Ah	; CALLF AnySeg:MemSize
	mov	ax,es:PSP_MEMORY	; Get the Top of Memory
	sub	ax,dx			; Convert it to Memory Size
	cmp	ax,1000h		; Check for Over 64Kb
	mov	bx,0FEF0h		; Assume Over 64Kb
	jae	sce_10
	mov	bx,ax			; Convert the Paragragh Length
	mov	cl,4			; to a Byte Length	
	shl	bx,cl
	sub	bx,110h			; Reserve 110h Bytes for .COM Stack
sce_10:	
	push	dx
	mov	es:PSP_LONGOFF,bx		; Save the Byte Length
	xor 	dx,dx			; Call 5 Entry Segment
	mov 	ax,INT30_OFFSET		; Call 5 Entry Offset
	mov	cl,4			
	shr	ax,cl			; Entry Offset/16 => EO
	shr	bx,cl			; Jump Offset/16 => JO
	add	ax,dx			; EO + ES
	sub	ax,bx			; EO + ES - JO => JS 
	mov	es:PSP_LONGSEG,ax
	pop	dx
	ret

;
;	*****************************
;	***    DOS Function 50    ***
;	***    Set Current PSP    ***
;	*****************************
;
	Public	func50

; WARNING - called on USER stack

func50:
	mov	current_psp,bx
	ret

;	*****************************
;	***  DOS Function 51/62   ***
;	***    Get Current PSP    ***
;	*****************************
;
	Public	func51, func62

; WARNING - called on USER stack

func51:
func62:
	mov	bx,current_psp
	mov	reg_BX[bp],bx
	ret

;**************************************************
;**************************************************
;***						***
;***	    Process Control Functions		***
;***						***
;**************************************************
;**************************************************

;	*****************************
;	***    DOS Function 31    ***
;	***   Terminate and Keep  ***
;	*****************************
;
	Public	func31
func31:
	mov	ax,6			; make 6 paragraphs our minimum size
	cmp	ax,dx			; Are we at our minimum size ?
	 jb	func31_05
	xchg	ax,dx			; no, enforce 6 paragraphs
func31_05:
	mov	exit_type,TERM_RESIDENT	; Exit by Terminate and Stay Resident
	mov	bx,current_psp		; and set the termination PSP to
	mov	term_psp,bx		; be the Current PSP

	push	ds			; Attempt to modify the memory
	mov	ds,bx			; partition size to that given in DX
	mov	bx,dx			; Remember DS and ES are swapped for
	call	mem_setblock		; the internal function.

	mov	ax,ds			; Now update the PSP_MEMORY field to
	add	ax,bx			; reflect the memory available to
	mov	ds:PSP_MEMORY,ax	; to the application now. Required by
	pop	ds			; MicroPro WordFinder

	mov	load_psp,0000		; Do not free PSP memory
	jmp	f31_term		; Common terminate handler

;
;	*****************************
;	***    DOS Function 4B    ***
;	*** Load or Execute Prog  ***
;	*****************************
;
;	An extra sub-function has been defined which is used by the
;	ROOT DOS process loader to ensure compatibility between the
;	Initial Register conditions for the ROOT DOS process and that
;	of any child process.
;
;	4B80h	-	GO Sub-Function expects all the internal and
;			external data areas to have been setup by a 
;			previous 4B01h function. Never Fails !
;
; Undocumented feature:
;	AX=4B03 returns SETVER version in AX, or zero
;

	Public	func4B
func4B:
	cmp	al,80h			; Is this the special GO sub-function
	 jnz	f4B_01			; No Process Normally
	jmp	start_child		; Go for It every thing else OK

f4B_01:
	cmp 	al,5
	 je 	f4B05			; Sub-Func 5:- Exec Hook
	cmp 	al,3
	 je 	f4B_02			; Sub-Func 3:- Load Overlay
	cmp 	al,1
	 jbe 	f4B_02			; Sub-Func 1:- Load and No Execute
					; Sub-Func 0:- Load and Execute
f4B_invalid:
	jmp	invalid_function	; Otherwise illegal Sub-Function

f4B05:
;-----
; On Entry:
;	ES:DX -> ExecState
esReserved	equ	word ptr 0	; reserved, must be zero
esFlags		equ	word ptr 2	; type flags
esProgName	equ	dword ptr 4	; points to ASCIIZ name
esPSP		equ	word ptr 8	; PSP of new program
esStartAddress	equ	dword ptr 10	; CS:IP of new program
esProgSize	equ	dword ptr 14	; program size, including PSP
;
;	type flags
ES_EXE		equ	0001h
ES_OVERLAY	equ	0002h
;
; On Exit:
;	None (A20 gate disabled)
;
	mov	di,dx			; ES:DI -> ExecState
	test	es:esFlags[di],not ES_EXE
	 jnz	f4B_invalid		; only COM or EXE supported
    call    return_AX_CLC       ; assume success
	lds	si,es:esProgName[di]	; DS:SI -> ASIIZ name
	mov	es,es:esPSP[di]		; ES = PSP
	push	es			; save for DX on exit
	call	SetPspNameAndVersion	; set up the name/version fields
	pop	dx			; DX = PSP
	push	ss
	pop	ds			; DS = pcmode data again
	cli				; Stop anybody interfering
	les	bp,int21regs_ptr	; point to user stack
	mov	es:reg_AX[bp],0		; return successful
	and	es:reg_FLAGS[bp],not CARRY_FLAG
	mov	ax,prev_int21regs_off
	mov	int21regs_off,ax
	mov	ax,prev_int21regs_seg
	mov	int21regs_seg,ax
	dec	indos_flag		; no longer in DOS
	jmp	dword ptr func4B05_stub	; exit via stub code


f4B_02:
	xor	ax,ax
	mov	load_env,ax		; Load environment NOT allocated
	mov	load_psp,ax		; Load memory NOT allocated
	dec	ax
	mov	load_handle,ax		; Mark Load file as CLOSED

	push 	es
	push 	dx			; expand the filename to a
	call	get_filename		;  full path to be inherited
	pop 	dx
	pop 	es			;  in the environment
	 jc	f4B_10			; Exit on error
	mov	ax,(MS_X_OPEN*256)+20h	; Open File
;	mov	al,0$010$0$000B		; ReadOnly & DenyWrite
	call	dos_entry
	 jnc	f4B_05			; Save Handle if No Error

	cmp	ax,ED_SHAREFAIL		; Check for a Sharing Error or Access
	 jz	f4B_04			; Denied if neither error codes then
	cmp	ax,ED_ACCESS		; Don't retry the Open function
	 jnz	f4B_10			; in compatibility

f4B_04:
	mov	ax,(MS_X_OPEN*256)+0	; retry the open in read-only
;	mov	al,0$000$0$000B		;  compatibility mode
	call	dos_entry
	 jc	f4B_10			; Stop On error

f4B_05:
	push 	ds
	pop 	es			; ES local again
	mov	load_handle,ax		; Save for Error Handling
	xchg	ax,bx			; Get the File Handle
	mov	si,offset exe_buffer
	call	get_execdata
	 jc	f4B_10
	call	point_param_block	; CL = subfunc, ES:DI -> param block
	cmp	cl,3			; Sub-Func 3:- Load Overlay
	 jne	f4B_go			; Sub-Func 0:- Load and Execute
					; Sub-Func 1:- Load and No Execute

	mov	si,es:2[di]		; si = Relocation Factor
	mov	di,es:[di]		; di = Load Segment

	call	loadimage		; load and relocate image
	 jc	f4B_10			; f4B_error - Return with an error
	mov	si,offset load_file	; Copy the process name into the DMD
	call	FindName		; DS:SI -> start of name
	call	GetVersion		; AX = version to return
	mov	es,current_psp		; poke the current psp
	mov	es:PSP_VERSION,ax	;  with the version number
	jmp	return_AX_CLC		; All done
f4b_10:
	jmp	f4B_error


;
;	F4B_GO loads and executes the file whose handle is in BX.
;	This routine corresponds to sub-functions 0 and 1.
;
f4B_go:
	xor	ax,ax
	mov	si,offset exe_buffer	; .COM and .EXE file loading
	mov	exe_loadhigh,al		; Reset the Load High Flag
	cmp	ax,EXE_MAXPARA[si]
	 jnz	f4B_g15			; Load High Flag (MAXPARA == 0)
	dec	ax
	mov	exe_loadhigh,al		; Set the internal LOADHIGH flag
	mov	EXE_MAXPARA[si],ax	; and allocate all memory
f4B_g15:
	mov	ax,es:[di]		; get ENV pointer from param block
	call	build_env		; Build the environment
	 jc	f4B_error		; Stop on error

	call	calc_psp		; calculate new psp
	 jc	f4B_error		; Stop on error
	call	pblk_to_psp		; Copy parameters into PSP
	mov	si,load_image		; read the Load image
	mov	di,si			; to previously calculated address
	call	loadimage		; load in com file
	 jc	f4B_error		; quit if no memory
	call	set_up_psp		; build child's psp
	mov	dx,load_psp		; point at PSP seg

	mov	exit_type,TERM_NORMAL	; Initialise the Return code type
	mov	si,offset exe_buffer	; to normal an go
	call	check_exe
	 jc	f4B_go_com	

	mov	dx,load_image		; Get the Load Paragraph
	add	EXE_CS[si],dx		; bias the code segment
	add	EXE_SS[si],dx		;   and the stack segment too
	jmp	start_child		; goodbye!
;
f4B_go_com:				; Go for it .COM
;	mov	dx,load_psp		; based at PSP seg
	mov	EXE_CS[si],dx		; set up initial cs:ip
	mov	EXE_IP[si],100h		;   and ss:sp for child
	mov	EXE_SS[si],dx
	mov	es,dx
	mov	bx,es:PSP_LONGOFF	; ax = segment size in bytes
	add	bx,110h - 2		; Initialise stack in reserved area
	mov	EXE_SP[si],bx		; save as stack ptr
	mov	es:word ptr[bx],0	; put one zero on the stack
	jmp	start_child		; goodbye!
;
;	Function 4B Error Handler. This exit routine will free all
;	resources allocated to a process during the EXEC function and
;	exit to the standard error handler with the original error code
;	if any further errors occur they are ignored.
;
f4B_error:
	push	ax			; Save the return Code
	mov	bx,load_handle		; Is the load file still open ?
	inc	bx			; (FFFF = closed)
	 jz	f4B_e10			; YES then Close
	dec	bx
	mov	ah,MS_X_CLOSE
	call	dos_entry
f4B_e10:				; Now Free any memory allocated
	mov	cx,load_psp		; during the execution of FUNC4B
	call	conditional_mem_free	; firstly free PSP/code/data memory
	mov	cx,load_env		; Secondly free the memory allocated
	call	conditional_mem_free	; to hold the ENVIRONMENT
	pop	ax			; Restore the return code and exit
	mov	valid_flg,OK_RF		; fiddle to resume func 4B if we get
	mov	retry_sp,sp		;  a critical error
	mov	retry_off,offset func4B
	call	error_exit		; call the standard error handler
	cmp	ax,-ED_FORMAT		; errors less than ED_FORMAT are OK.
	 jb	f4B_e20			;  (eg. ED_MEMORY, ED_FILE)
	mov	ax,load_handle		; if we didn't manage to open exec file
	inc	ax			;  load_handle=FFFF and we want to
	mov	al,-ED_PATH		;  return ED_PATH
	 jz	f4B_e20			; else we had an error during the load
	mov	al,-ED_FORMAT		;  and should return ED_FORMAT
f4B_e20:
	ret

start_child:
	mov	es,current_psp		; ds -> psp
	mov	dx,0080h		; default dma offset
	mov	ah,MS_F_DMAOFF		; Set the DMA address
	call	dos_entry		; set child's dma address
	mov	si,offset exe_buffer	; Get EXE Buffer Offset
	call	point_param_block	; CL = subfunc, ES:DI -> param block
	cmp	cl,1
	 jne	start_child_go		; load restisters and go
;
;	The following code updates the Extended parameter block
;	used with the LOAD for DEBUG sub-function.
;
	add	di,DWORD*3+WORD		; skip user supplied info
	mov	ax,EXE_SP[si]
	dec 	ax
	dec 	ax			; return ss:sp-2
	stosw
	xchg	ax,bx			; save SP for later
	mov	ax,EXE_SS[si]
	stosw

	push	ds
	mov	ds,ax
	mov	word ptr [bx],0		; zero on user stack
	pop	ds

	lea	si,EXE_IP[si]		; point at IP
	lodsw
	stosw				; copy it, and get in AX for return
	movsw				; copy EXE_CS too
	jmp	return_AX_CLC		; all went OK

start_child_go:
;--------------
;
;	Set the initial registers conditions for a DOS process
;	Check the validity of the drives specified in FCB 1 and FCB 2
;	of the loading PSP and initialise the AX register accordingly.
;
	xor	dx,dx			; start with valid drives
	mov	es,current_psp		; Get the PSP Address and check
	push	dx
	mov	al,es:PSP_FCB1		; if the drive specifier for FCB1
	call	valid_drive		; is invalid set AL to FF
	pop	dx
	 jz	reg_s10
	mov	dl,0FFh
reg_s10:
	push	dx
	mov	al,es:PSP_FCB2		; if the drive specifier for FCB2
	call	valid_drive		; is invalid set AH to FF
	pop	dx
	 jz	reg_s20
	mov	dh,0FFh
reg_s20:
	mov	di,EXE_SP[si]		; Get the new stack address
	push	di			; save it
	mov	cl,4
	shr	di,cl			; convert SP to para's
	 jnz	reg_s30
	mov	di,1000h		; if 0k make it 64k
reg_s30:
	mov	ax,load_max		; find top of prog area
	sub	ax,EXE_SS[si]		; find para's left for stack
	cmp	di,ax			; SP too high ?
	pop	di			; assume OK
	 jb	reg_s40
	mov	di,ax			; no, so lower SP
	shl	di,cl			; convert to bytes
reg_s40:
	mov	cx,EXE_SS[si]		; CX:DI -> initial stack
	les	si,dword ptr EXE_IP[si]	; get initial CS:IP
	cli
	mov	ax,current_psp		; AX = PSP we are going to use
	xchg	ax,dx
	mov	indos_flag,0		; zap the indos flag
if 0
	mov	ss,cx			; switch to new USER stack
	mov	sp,di
	push	es
	push	si			; CS:IP on USER stack
	mov	ds,dx			; DS = ES = PSP we are exec'ing
	mov	es,dx
	xor	bx,bx			; BX = zero, set flags
	sti
	retf				; lets go!
else
	jmp	dword ptr exec_stub
endif

;	*****************************
;	***    DOS Function 00    ***
;	***   Terminate Process	  ***
;	*****************************
;
;	This code is executed for both INT 20 and INT 21/00 and they both
;	implicitly set the current PSP to the users calling CODE segment.
;	This overwrites the correct value held in CURRENT_PSP.
;
	Public	func00
func00:
	mov	byte ptr int21AX,0	; force return code of zero
	les	di,int21regs_ptr
	mov	bx,es:reg_CS[di]	; normally users CS is current_psp
	mov	ax,current_psp		; but application call here
	cmp	ax,bx			;  with an Int 20 at funny moments
	 je	func4c			;  (I have "NOW!" in mind)
	mov	es,bx			; fiddle CS PSP parent so we return to
	mov	es:PSP_PARENT,ax	;  current_psp then fiddle current_psp
	mov	current_psp,bx		;  to be user CS

;	*****************************
;	***    DOS Function 4C    ***
;	***   Terminate Process	  ***
;	*****************************
;
	Public	func4C
func4c:
	mov	ax,current_psp		; the current PSP is terminating
	mov	term_psp,ax		;  so set term_psp and load_psp
	mov	load_psp,ax		;  to that value

f31_term:				; INT27 and INT21/31 Entry Point
	push	ds
	mov	ds,term_psp
	xor	ax,ax
	mov	es,ax			; Copy the Three interrupt vectors
	mov	si,offset PSP_TERM_IP	; saved on process creation from the 
	mov	di,INT22_OFFSET		; termination PSP to the interrupt
	mov	cx,6			; vector table.
	rep	movsw
	mov	ax,8200h		; call the REDIR hooks to clean up
	int	2ah			; first the server hook
	mov	ax,I2F_PTERM		; then call cleanup code
	int	2fh			; via magic INT 2F call
	pop	ds			; back to PCMODE data
	mov	al,byte ptr int21AX	; Get the User Return Code
	mov	user_retcode,al		; Save the User Ret Code and Set the 
	mov	al,TERM_NORMAL		; Now get the Termination Type
	xchg	al,exit_type		; and exchange with the default value
	mov	system_retcode,al	; EXIT_TYPE is set so Non-Zero values
					; when a Special Form of termination
					; takes place. ie INT 27h

; But thence came VTERM, and it looked upon terminating the ROOT process,
; and saw that it was good.
;
; VTERM gives access to the cmdline by doing func31 and becoming a TSR. You can
; then re-invoke it with a hot-key but the next time you invoke the cmdline
; option does a func4C in whatever context it was re-invoked in. This will
; either blow away an application, or try and terminate the ROOT process.


	mov	es,term_psp		; make the terminating PSP's
	mov	ax,es:PSP_PARENT	;  parental PSP into the
	mov	bx,current_psp
	cmp	ax,bx			; Is the user trying to terminate
	 jz	f4C_20			;  the ROOT DOS process if YES then
					;  skip freeing resources (VTERM)

	mov	cx,load_psp		; if we are TSR'ing
	 jcxz	f4C_20			;  skip the free

	push	ax			; save parental PSP
	mov	es,bx			; ES = current PSP
	xor	bx,bx			; start with handle zero
f4C_10:
	mov	ah,MS_X_CLOSE		; close this handle
	call	dos_entry		; so freeing up PSP entry
	inc	bx			; onto next handle
	cmp	bx,es:PSP_XFNMAX	; done them all yet?
	 jb	f4C_10
	mov	FD_FUNC,FD_EXIT		; Must Close all Open FCB's
	call	fdos_nocrit
	push	ds 			; We have already closed all the
	pop	es			; open MSNET files we know about
	mov	ax,I2F_PCLOSE		; but we will call the MSNET
	int	2fh			; extention's cleanup code anyway

	push 	ss
	pop 	ds			; reload DS with data segment

	mov	bx,current_psp		; free all memory associated
	call	free_all		;  with this PSP

	push ss
	pop ds
	mov di, offset lfn_find_handles
f4C_close_lfn_handle_loop:
	mov bx, word ptr [di]
	test bx, bx			; in use ?
	jz f4C_close_lfn_handle_next	; no -->
	mov ax, current_psp
	cmp word ptr [bx], ax		; we are owner ?
	jne f4C_close_lfn_handle_next	; no -->
	push di
	call lfn_free_handle
	pop di
f4C_close_lfn_handle_next:
	scasw				; di += 2
	cmp di, offset lfn_find_handles_end
	jb f4C_close_lfn_handle_loop

	pop	ax			; recover parental PSP
f4C_20:
	mov	current_psp,ax		; make current PSP = parental PSP

;
;	Function 4C requires a different termination technique. It needs
;	to return to the parent process on the stack that was used on the
;	function 4B. The interrupt structure has been forced to contain
;	the interrupt 22 vector. Therefore all registers will contain
;	their original values unless the stack has been overlayed
;
;
	cli				; Stop anybody interfering
	mov	indos_flag,0		; Force the INDOS_FLAG to 0 for PCTOOLS
	mov	error_flag,0		; and SideKick Plus.
	mov	ax,retcode
	mov	ds,current_psp
	mov	ss,ds:PSP_USERSS	; Retrieve the entry SS and SP from
	mov	sp,ds:PSP_USERSP	;  the PSP and return with all
	mov	bp,sp			;  registers as on user entry
	mov	ss:reg_AX[bp],ax	; Set AX to the Process RETCODE
	xor	ax,ax
	mov	ds,ax
	mov	ax,ds:word ptr INT22_OFFSET
	mov	ss:reg_IP[bp],ax   	; PSP_TERM_IP
	mov	ax,ds:word ptr INT22_OFFSET+WORD
	mov	ss:reg_CS[bp],ax   	; PSP_TERM_CS
	mov	ss:reg_FLAGS[bp],0b202h	; force flags to 0F202h
					;  ie Interrupts enabled and
					;  NEC processor Mode Switch SET
					; changed to B202 to have clear
					; NT flag (DPMS doesn't like it)
	jmp	int21_exit		; Jump to the Exit routine	


;	*****************************
;	***    DOS Function 4D    ***
;	*** Get Sub-Func Ret-Code ***
;	*****************************
;
	Public	func4D
func4D:
	xor	ax,ax			; Zero the return code for
	xchg	ax,retcode		; subsequent calls and return the
	jmp	return_AX_CLC		; saved value to the caller

;****************************************
;*					*
;*	Process Control Subroutines	*
;*					*
;****************************************

;
; We need a full pathname for the application to inherit in it's environment.
; MS_X_EXPAND can't do the job - it returns a PHYSICAL path which may be
; unreachable (bug circa DRDOS 3.41).
; On Entry:
;	ES:DX	Points to the Original FileName
; On Exit:
;	None
;

get_filename:
	push	ds
	push	es			; swap ES and DS
	pop	ds
	pop	es
	mov	si,dx			; DS:SI -> filename
	mov	di,offset load_file	; ES:DI -> local buffer
	mov	cx,MAX_PATHLEN-4	; max length (allow for d:\,NUL)
	lodsw				; get 1st two chars in filename
	cmp	ah,':'			; is a drive specified ?
	 je	get_filename10
	dec 	si
	dec 	si			; forget we looked
	mov	al,ss:current_dsk	; and use the default drive
	add	al,'A'
get_filename10:
	stosb				; put in the drive
	and	al,1fh			; convert from ASCII to 1 based
	xchg	ax,dx			; keep in DL for ms_x_curdir
	mov	ax,':'+256*'\'		; make it "d:\"
	stosw
	lodsb				; do we start at the root ?
	cmp	al,'\'
	 je	get_filename20
	cmp	al,'/'
	 je	get_filename20
	dec	si			; forget we looked for a root
	push	si			; save where we were
	mov	ah,MS_X_CURDIR
	mov	si,di			; ES:SI -> buffer
	call	dos_entry		; get current directory
	xor	ax,ax
	repne	scasb			; look for NUL
	xchg	ax,si			; AX = start of path
	pop	si			; recover pointer to source
	 jne	get_filename30
	dec	di			; point at NUL
	cmp	ax,di			; are we at the root ?
	 je	get_filename20
	mov	al,'\'
	stosb				; no, append a '\'
get_filename20:
	rep	movsb			; copy the remainder of the string
get_filename30:
	xor	ax,ax
	stosb				; ensure we are terminated
	push	es
	pop	ds			; DS back to nornal
	ret


;
;	BUILD_ENV determines the size of the Source environment and 
;	allocates memory and finally copies it.
;
;	ON entry AX contains the segment address of the environment
;	to be used or zero if the parents is to be copied.
build_env:
	mov	es,ax			; Assume user has specified the
	or	ax,ax			; environment to be used. If AX is
	 jnz	b_e10			; 0000 then use the current environment
	mov	es,current_psp
	mov	cx,es:PSP_ENVIRON		; Current Environment Segment 
	mov	es,cx			; If the current environment segment
	mov	di,cx			; is zero then return a size of
	 jcxz	b_e35			; zero bytes

b_e10:
	xor	ax,ax			; Now determine the Environment size
	mov	cx,32*1024		; CX is maximum size
	mov	di,ax
b_e20:
	repnz	scasb			; Look for two zero bytes which
	 jcxz	b_e40			; mark the end of the environment
	cmp	al,es:byte ptr [di]	; continue search till the end is found
	 jnz	b_e20
	dec	di			; DI == Environment Size - 2

b_e30:
	mov	si,offset load_file	; Get the Load pathname length
	call	strlen			; String length returned in CX
	inc	cx			; Add in the terminator

	push	bx
	mov	bx,cx			; Get the String Length
	add	bx,di			; Add the environment size
	add	bx,15 + 4		; and convert to paragraphs
	shr 	bx,1
	shr 	bx,1
	shr 	bx,1
	shr 	bx,1
	mov	load_envsize,bx		; Save the Environment Size
	call	mem_alloc		; allocate the memory
	pop	bx
	 jc	b_e50
	mov	load_env,ax		; Save the Environment location
	push 	cx
	push 	di			; Save STRLEN and Offset
	push	ds			; Save DS
	push	es
	mov	es,ax			; Point ES at the NEW environment
	pop	ds			; Point DS at the Old environment
	mov	cx,di			; Get the environment size
	xor 	si,si
	mov 	di,si			; Initialize the pointers
	rep	movsb 			; and copy. Nothing moves if CX == 0
	pop	ds

	pop 	di
	pop 	cx			; Get the string pointers
	xor 	ax,ax
	stosw				; Add terminating zeros
	inc 	ax
	stosw				; Initialise the String COUNT field


	mov	si,offset load_file	; and size information and 
	rep	movsb			; copy the load filename.
b_e35:
	clc				; Return with no errors	
	ret
b_e40:
	mov	ax,ED_ENVIRON		; Invalid environment
b_e50:
	stc
	ret


;	Calculate the new program segment prefix
;	save:	bx -> Handle
calc_psp:
	push	bx
	mov	si,offset exe_buffer	; Calculate the Minimum and Maximum
					; amount of memory required to load
	call	image_size		; the program image (Returned in DX)
	add	dx,PSPLEN/16		; Do not forget the PSP
	mov	cx,dx			; Save the Load Image Size
	mov	bx,dx			; BX will be memory required
	mov	ax,ED_MEMORY
	add	dx,EXE_MINPARA[si]	; force DX to be the minimum and if
	 jc	cp_exit			;  more than 1 MByte exit with error
	add	bx,EXE_MAXPARA[si]	; add the maximum amount of memory
	 jnc	c_p10			;  to the load image size
	mov	bx,0FFFFh		;  clipping to 1 MByte
c_p10:
if HILOAD
	test	mem_strategy,80h	; HILOAD ON ?
	 jz	c_p15
	mov	bx,dx			; use minimum amount of memory
	add	bx,40h			; add 1 K extra for luck (stack etc)
	call	mem_alloc		; Allocate the requested block
	 jc	cp_exit			; if alloc fails exit with error
	push	ds
	mov	ds,ax
	mov	bx,0ffffh		; find how much we can grow this block
	call	mem_setblock
	call	mem_setblock		; then grow it to that size
	mov	ax,ds			; ax = base of the block again
	pop	ds
	jmp	c_p20			
c_p15:
endif
	call	mem_alloc		; allocate size and if error occurs
	 jnc	c_p20			; then the maximum size is greater
	cmp	bx,dx			; than the minimum required
	 jc	cp_exit			; if not exit with error

	call	mem_alloc		; Allocate what we've got
	 jc	cp_exit			; Exit on error	
c_p20:
	mov	load_psp,ax		; Save the load paragraph == PSP
	add	bx,ax			; Save the block top
	mov	load_top,bx
	mov	load_max,bx		; save top of block for SP adjust
	add	ax,PSPLEN/16		; Set AX to be the Relocation Paragraph

	cmp	exe_loadhigh,0		; Should the Load Image be
	 jz	c_p30			; forced into to High Memory with the
	mov	ax,bx			; data area and PSP loaded low.
	sub	ax,cx			; Subtract the Load Image Size from
	mov	cx,PSPLEN/16		; the top of allocated memory and
	add	ax,cx			; load at that address.	

c_p30:
	mov	load_image,ax		; Save the Address of the Load Image
cp_exit:
	pop	bx
	ret

;LOADIMAGE:
;
;	This function reads in the load image of the file into memory
;	(Paragraph DI) asserting the relocation factor (SI) if any relocation
;	items exist in the file. The size of the load image is calculated 
;	using the EXE_SIZE and EXE_FINAL fields enough memory exists at DI
;	to load the image. The valid .EXE header has been moved to exe_buffer.
;
;	Read in and relocate the EXE image
;	entry:	bx -> handle
;		di = load segment
;		si = reloc segment
;	exit:	cf = 1, ax = Error Code if load fails
;
loadimage:
;---------
	call	readfile		; Read the load image into memory
	 jc	load_error		; Exit if error

	mov	cx,exe_buffer+EXE_RELCNT
					; get number of reloc entries
	 jcxz	load_done		; if none there, forget it .COM's
					; drop out here because RELCNT is zero

	push	cx			; seek to 1st relocation entry
	xor	cx,cx			;  in the file
	mov	dx,exe_buffer+EXE_RELOFF
	mov	ax,(MS_X_LSEEK*256)+0
	call	dos_entry
	pop	cx
	 jc	load_error		; stop on error
	xchg	ax,cx			; AX = # items to relocate
	call	reloc_image		; relocate the image
	 jc	load_error
load_done:
	mov	load_handle,-1
	mov	ah,MS_X_CLOSE		; and close the loadfile
	jmp	dos_entry		; close the com file

load_error:				; Error exit from relocation
	push	ax			; save error code
	call	load_done		; close the file
	pop	ax			; recover error code
	stc				; say we had an error
	ret
	
;
;	The following code will relocate CX items from the open handle BX
;
reloc_image:
; On Entry:
;	BX = handle
;	AX = # items to relocate
;	SI = relocation segment
;	DI = relocation fixup
;
; On Exit:
;	CY clear if OK, else AX = error code


	push 	ds
	pop 	es			; ES -> Local Buffer Segment
	mov	dx,offset reloc_buf	; DX -> Local Buffer Offset

	mov	cx,RELOC_CNT		; AX -> Buffer Size
	shl	cx,1			; convert reloc size from paras
	shl	cx,1			;  to an item count
	sub	ax,cx			; buffer. which contains a maximum
	 jnc	reloc_i10		; of RELOC_SIZE items.
	add	cx,ax			; CX contains # of items to Read
	xor	ax,ax			; AX contains # left to read
reloc_i10:
	push	ax			; save # items left to read
	push	cx			; and # reloc to read
	shl 	cx,1
	shl 	cx,1			; calculate # byte to read
	mov	ah,MS_X_READ		; relocation buffer.
	call	dos_entry
	pop	cx
	 jnc	reloc_i20		; Exit on Error
	pop	cx			; clean up stack
	ret				; return with error

reloc_i20:
	push	bx			; save handle
	xchg	ax,di			; AX = reloc fixup

	mov	bx,dx			; Get buffer offset
reloc_i30:
	add	word ptr 2[bx],ax	; Correct segment to Load Seg
	les	di,dword ptr [bx]	; es:di = reloc entry
	add	es:[di],si		; add reloc seg into image
	add	bx,4			; and update for next entry
	loop	reloc_i30

	xchg	ax,di			; restore fixup to DI
	pop	bx			; recover handle
	pop	ax			; recover # left to do
	test	ax,ax
	 jnz	reloc_image		; keep going until all done
	ret
	
;READFILE
;
;	This function reads in the load image of the file into memory
;	(Paragraph DI) the size of the load image is calculated using
;	the EXE_SIZE and EXE_FINAL fields enough memory exists at DI
;	to load the image. The valid .EXE header has been moved to 
;	exe_buffer.
;
;	Read in a Binary Image .COM or .EXE
;	entry:	bx -> handle
;		di = load segment
;	
;	exit:	bx, si, di Preserved
;		cf = 1, ax = Error Code if load fails
;
MAX_READPARA	equ	3200		; Maximum Number of Paragraphs to 
					; read in one command 50Kb
readfile:
	push 	si
	push 	di
	mov	si,offset exe_buffer	; Get the .EXE header
	mov	dx,EXE_HEADER[si]	; get the header size in paragraphs
	mov	cx,4			; and seek to that offset in the
	rol	dx,cl			; file before reading any data
	mov	cl,dl
	and 	cx,0Fh
	and 	dx,not 0Fh
	mov	ax,(MS_X_LSEEK*256)+0
	call	dos_entry		; Execute LSEEK Function
	jc	rf_error
	call	image_size		; Get the Load Image Sizes in Paras
	mov	si,dx			; Returned in DX save in SI
rf_10:
	mov	es,di			; Set the Buffer address
	sub	dx,dx			; es:dx -> load segment

	cmp	si,MAX_READPARA		 ; Can we read the rest of the file
	jbe	rf_20		 	 ; in one command jif YES
	sub	si,MAX_READPARA		 ; Decrement the Image Size
	mov	cx,MAX_READPARA * 16	 ; Number of bytes to read
	add	di,MAX_READPARA		 ; Number of Paragraphs Read
	mov	ah,MS_X_READ		 ; Read the Block into the
	call	dos_entry		 ; buffer Exit if Error
	jc	rf_error
	jmp	rf_10			 ; Else go for the next bit

rf_20:					; Now reading the last part of
	mov	cl,4			; the image so convert remainder
	shl	si,cl			; in SI to bytes and Read File
	mov	cx,si
	mov	ah,MS_X_READ		; Read data into the buffer
	call	dos_entry
	jc	rf_error		; Stop on Error
	xor	ax,ax			; Reset the carry Flag and Zero AX
rf_error:				; Error exit Carry Flag Set and AX
	pop di
	pop si				; contains the error code.
	ret

;	Copy old PSP contents to new PSP.
;	Parameter block supplied by user contains command line
;	and default FCB's - copy these into the load_psp.
;	save:	bx -> Handle
pblk_to_psp:
	push	ds			; Save the PcMode Data Segment
	push	bx			; and file handle
	mov	dx,load_psp
	call	point_param_block	; ES:DI -> users parameter block

	push 	es
	push 	di
	lds	si,es:dword ptr 2[di]	; Get the Source Pointer
	mov	cx,64			; Copy the complete command line (128 bytes)
	mov	di,offset PSP_COMLEN	; because BASCOM places a segment value
	mov	es,dx			; after the CR which was not previously
	rep	movsw			; copied.
	pop 	di
	pop 	es

	lds	si,es:dword ptr 6[di]	; get 1st FCB address
	mov	ax,offset PSP_FCB1	; First FCB Offset
	call	copy_fcb		; copy FCB
	lds	si,es:dword ptr 10[di]	; Get the Source Pointer
	mov	ax,offset PSP_FCB2	; Second FCB Offset
	call	copy_fcb		; copy FCB
	pop	bx			; file handle back again
	pop	ds			; Restore PcMode Data Segment
	ret

copy_fcb:
;--------
; On Entry:
;	DS:SI -> source
;	DX:AX -> destination
; On Exit:
;	None
;	ES:DI, DX preserved
;
	push	es
	push	di
	mov	es,dx
	xchg	ax,di			; ES:DI -> destination
	mov	cx,6			; Copy Drive, Name and Extension
	rep	movsw			;  and copy it
	xchg	ax,cx			; AX = 0
	stosw
	stosw				; zero last 4 bytes
	pop	di
	pop	es
	ret



;	Set up a new psp for the child
;
set_up_psp:
	mov	ax,load_psp		; Change the ownership of the
	mov	bx,load_env		; Environment and Load Memory
	call	set_owner		; partitions.
	mov	ax,load_psp
	mov	bx,ax
	call	set_owner
	
	cmp	current_psp,1		; Is This the ROOT DOS process
	jnz	setup_psp10		; No! Continue as Normal

	mov	ax,load_psp		; Force the LOAD_PSP to
	mov	current_psp,ax		; to be the current PSP

	mov	es,ax			; Now Zero Fill the New PSP
	mov	cx,(offset PSP_FCB1)/2	;  up to user supplied parameters
	xor 	ax,ax
	mov 	di,ax
	rep	stosw
	jmp	setup_psp20		; and skip the INT22 Fudge

setup_psp10:				; Get the Function return address
	xor 	di,di
	mov 	es,di			;  and force into INT 22
	mov	di,INT22_OFFSET		; Set Interrupt Vectors 22
	push	ds
	lds	si,int21regs_ptr
	lea	si,reg_IP[si]		; DS:SI -> callers IP
	movsw				; Save User IP
	movsw				; Save User CS
	pop	ds
setup_psp20:
	mov	dx,load_psp		; Get the new PSP address
	mov	si,load_top		; Get the last paragraph allocated
	mov	cx,(offset PSP_FCB1)/2	; Copy PSP up to user supplied bits
;
;	CREATE_PSP is a local function called by the DOS EXEC function (4B)
;	to create a new PSP and initialize it as a new process. 
;
;	The PSP_MEMORY field was original calculated as the highest memory
;	location that could be allocated to a process. However this caused
;	Carbon Copy Plus to Fail so the routine now uses the LOAD_TOP
;	value calculated by the CALC_PSP function. This is the last
;	paragraph allocated to the current PSP.
;
	call	create_psp		; Create the New Process
	mov	ax,load_env		; Now Update the Environment
	mov	es:PSP_ENVIRON,ax
	mov	si,offset load_file	; Copy the process name into the DMD
;	jmp	SetPspNameAndVersion

SetPspNameAndVersion:
;---------------------
; On Entry:
;	ES = PSP
;	DS:SI -> pathaname (nb. DS need not be dos data seg!)
; On Exit:
;	None
;
	mov	bx,es
	dec	bx
	mov	es,bx			; ES points at DMD (We Hope)
	call	check_dmd_id		; Check for a valid DMD
	 jc	SetPspNameAndVersion10	; bail out now if none
	inc	bx			; BX -> PSP again
	push	bx			; keep it on the stack
	call	FindName		; DS:SI -> start of name
	push	si
	call	SetName			; update the name field
	pop	si
	call	GetVersion		; AX = version to return
	pop	es			; ES = PSP
	mov	es:PSP_VERSION,ax	; set version number
SetPspNameAndVersion10:
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
	jmp	FindName10
FindName20:
	cmp	al,'\'			; is it a seperator ?
	 je	FindName
	cmp	al,'/'
	 je	FindName
	jmp	FindName10
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
;	CX preserved
;
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
	jmp	SetName10

SetName20:
	stosb
	cmp	al,'.'			; discard all following '.'
	 je	SetName30
	cmp	di,(offset DMD_NAME)+DMD_NAME_LEN
	 jb	SetName10		; don't overflow if name too long
	ret

SetName30:
	dec	di
	xor	ax,ax
SetName40:
	stosb				; zero the '.'
	cmp	di,(offset DMD_NAME)+DMD_NAME_LEN
	 jb	SetName40		; zero the rest of the name
	ret

GetVersion:
;----------
; On Entry:
;	DS:SI -> start of name
;	CX = length
; On Exit:
;	AX = dos version to return
;
	les	di,ss:setverPtr
	mov	ax,es
	or	ax,di			; check for a setver list
	 jnz	GetVersion30
GetVersion10:
	mov	ax,ss:dos_version	; better use default version
	ret

GetVersion20:
	mov	al,es:[di-1]		; skip the name
	cbw
	inc 	ax
	inc 	ax			; skip the version
	add	di,ax			; try the next entry
GetVersion30:
	mov	al,es:byte ptr [di]	; get length field
	test	al,al			; end of the list ?
	 jz	GetVersion10

	inc	di			; point at potential name
	cmp	al,cl			; do the lengths match ?
	 jne	GetVersion20
	xor	bx,bx			; start scan with 1st character
GetVersion40:
	mov	ax,ds:[bx+si]		; get a character from filename
	call	dbcs_lead		; is it a DBCS character ?
	 jne	GetVersion50
	inc	bx			; we will skip 2 characters
	cmp	ax,es:[bx+di]		; do both character match ?
	jmp	GetVersion60

GetVersion50:
	call	toupper			; upper case it
	mov	ah,al			; save it
	mov	al,es:[bx+di]		; get a character from setver list
	call	toupper			; upper case it
	cmp	al,ah			; do we match ?
GetVersion60:
	 jne	GetVersion20		; no, try next name in list
	inc	bx			; we match, have we done them all ?
	cmp	bx,cx			; check against length
	 jb	GetVersion40
	mov	ax,es:[bx+di]		; get version number from setver list
	ret

;
;	GET_DATA reads the EXE header using the handle passed in BX
;

get_execdata:
; On Entry:
;	BX = handle
;	ES:SI = buffer
; On Exit:
;	CY set if error, AX = error code
;	BX/SI preserved

	mov	ah,MS_X_READ
	mov	cx,EXE_LENGTH		; read the exe header
	mov	dx,si			; ES:DX -> buffer
	call	dos_entry		; try and read the data
	 jc	gd_exit			; Error Exit
	mov	EXE_FINAL[si],0200h	; Force value to Full Page
	call	check_exe		; all done if it's an .EXE
	 jnc	gd_exit
	mov	ax,(MS_X_LSEEK*256)+2	; it's a .COM
	xor	cx,cx			; seek to end of file
	xor	dx,dx
	call	dos_entry		; get file length in DX:AX
	 jc	gd_exit
	xchg 	al,ah
	mov 	ah,dl			; DX:AX / 512
	shr 	dx,1
	rcr 	ax,1
	inc	ax			; Handle Final Partial Page
	mov	EXE_SIZE[si],ax		; No. of 512 Byte Pages
	xor	ax,ax
	mov	EXE_HEADER[si],ax	; Load Image starts a 0000
	mov	EXE_RELCNT[si],ax	; No Relocation Items
	dec	ax			; Force Maximum Memory Allocation
	mov	EXE_MAXPARA[si],ax	;  to the .COM
	mov	EXE_MINPARA[si],0010h	; give it at least an extra 100h
					; bytes for the Default Stack
gd_exit:
	ret

;
;	Determine if the file to be loaded is a DOS EXE format file
;	if YES then return with the carry flag reset. Assume that the
;	header has already been read into EXE_HEADER
;
	public	check_exe
check_exe:
	cmp	EXE_SIGNATURE[si],'ZM'	; look for exe signature
	 jz	check_e10
	cmp	EXE_SIGNATURE[si],'MZ'	; look for exe signature
	 jz	check_e10
	stc 				; flag the error
check_e10:
	ret

;
;	IMAGE_SIZE assumes SI points to a valid EXE header and from this
;	it calculates the size of the load image and returns this value
;	in paragraphs in DX. AX and CX are corrupted.
;
	Public	image_size
image_size:
	mov	dx,EXE_SIZE[si]		; No of 512 pages in System Image
	dec	dx			; Adjust for Final Partial Page
	mov 	cl,5
	shl 	dx,cl			; No. 512 Byte Blocks to Para
	sub	dx,EXE_HEADER[si]	; Remove the Header Size	

	mov 	ax,EXE_FINAL[si]
	add	ax,15
	dec 	cl
	shr 	ax,cl			; AX is Partial Block in PARA
	add	dx,ax			; DX is Image Size in PARA's
	ret

mem_alloc:
	mov	ah,MS_M_ALLOC			; call DOS to allocate
	jmp	dos_entry			; some memory

mem_setblock:
	mov	ah,MS_M_SETBLOCK		; call DOS to ajust
	jmp	dos_entry			; a memory block

conditional_mem_free:
; On Entry:
;	CX = para to free
;	    (0 = none to free)
; On Exit:
;	None
;
	 jcxz	cmem_free10			; only free up allocated
	push	ds				;  memory
	mov	ds,cx
	mov	ah,MS_M_FREE			; free up a memory block
	call	dos_entry
	pop	ds 
cmem_free10:
	ret

point_param_block:
;-----------------
; On Entry:
;	None
; On Exit:
;	CL = subfunction number (callers AL)
;	ES:DI -> parameter block (callers ES:BX)
;	AX corrupted
;
	les	di,int21regs_ptr	; point at callers registers
	mov	cl,es:reg_AL[di]	; CL = subfunction# (range-checked)
	mov	ax,es:reg_BX[di]
	mov	es,es:reg_ES[di]	; callers ES:BX -> parameter block
	xchg	ax,di			; ES:DI -> parameter block
	ret

PCM_CODE	ends
	
		
PCMODE_DATA	segment public word 'DATA'
	extrn	current_dsk:byte
	extrn	current_psp:word
	extrn	retcode:word		; Complete return code passed to F4B
	extrn	user_retcode:byte	; User retcode set by funcs 4C and 31
	extrn	system_retcode:byte	; System retcode returns the cause of
	extrn	switch_char:byte
	extrn	mem_strategy:byte	; memory allocation strategy
	extrn	int21AX:word		; Int 21's AX
	extrn	indos_flag:byte
	extrn	int21regs_ptr:dword
	extrn	int21regs_off:word
	extrn	int21regs_seg:word
	extrn	prev_int21regs_off:word
	extrn	prev_int21regs_seg:word
	extrn	error_flag:byte
	extrn	exe_buffer:word
	extrn	valid_flg:byte
	extrn	retry_off:word
	extrn	retry_sp:word
	extrn	last_drv:byte
	extrn	exec_stub:dword
	extrn	func4B05_stub:dword

	extrn	dos_version:word
	extrn	setverPtr:dword

;	To improve Network performance the EXE relocation items are
;	now read into the following buffer. All the data items contained
;	between RELOC_BUF and RELOC_SIZE are destroyed by the LOADIMAGE
;	sub-routine when it relocates a DOS .EXE file.
;
;	Only variables which are unused after the LOADIMAGE function can
;	be placed in this buffer.
;
;	******** Start of .EXE Relocation Buffer ******** 
;

; We can re-use the MSNET pathname buffers during an EXEC

	extrn	reloc_buf:byte
	extrn	load_file:byte
	extrn	RELOC_CNT:abs

;
;	******** End of .EXE Relocation Buffer ******** 
;

	extrn	exit_type:byte
	extrn	term_psp:word
	extrn	load_handle:word
	extrn	load_env:word			; Paragraph of the new environment
	extrn	load_envsize:word		; Size of new environment
	extrn	load_psp:word			; Paragraph of the new PSP.
	extrn	load_image:word			; Paragraph of the Load Image.
	extrn	load_top:word			; Last paragraph of Allocated Memory
	extrn	load_max:word			; ditto, but not messed with
	extrn	exe_loadhigh:byte		; load high flag

PCMODE_DATA	ends

PCMODE_CODE	segment public word 'DATA'

	extrn lfn_find_handles:word
	extrn lfn_find_handles_end:word
	extrn lfn_find_handle_heap:word
	extrn lfn_find_handle_heap_end:word
	extrn lfn_find_handle_heap_free:word

PCMODE_CODE	ends

PCM_CODE	segment public byte 'CODE'

	extrn lfn_free_handle:near

PCM_CODE	ends

	end
