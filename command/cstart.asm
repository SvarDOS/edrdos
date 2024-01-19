;    File              : $Workfile: CSTART.ASM$
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
;    CSTART.ASM 1.2 97/03/21 15:01:01
;    Added /n option to disable critical error handler
;    CSTART.ASM 1.38 94/12/21 10:45:05 
;    Reduced Heap size to 860h just to be sure.
;    CSTART.ASM 1.34 94/03/29 16:10:05 
;    _docmd_int2f returns 1 or 0 depending on whether or not the command
;    is accepted.
;    CSTART.ASM 1.31 93/11/18 18:50:18
;    Fix HMA registration problem
;    CSTART.ASM 1.30 93/11/09 00:00:14
;    Shorten _ge_config_env
;    CSTART.ASM 1.28 93/11/05 00:54:25
;    move HMA registration code to where it's actually executed
;    CSTART.ASM 1.27 93/11/04 23:39:11
;    Fix problem with resident data relocation code
;    CSTART.ASM 1.26 93/11/04 20:06:09
;    int2E_far_entry now does CLI and STI the correct way round when loading
;    SS and SP.
;    CSTART.ASM 1.25 93/10/24 13:13:34
;    Added strategy 'best fit upper mem'' & link upper mem'
;    put_resident_high()    
;    CSTART.ASM 1.24 93/09/10 15:56:46
;    CLS checks for ANSI using Int 2F/1A00
;    CSTART.ASM 1.23 93/08/26 09:40:50
;    Now use PSP for stack during func 4b exec. There's some debug
;    code in case things screw up.
;    CSTART.ASM 1.21 93/08/03 10:04:18
;    Stopped using memory above A000 for transient portion because the 
;    stack was disappearing when MEMMAX -V executed.
;    CSTART.ASM 1.20 93/07/05 08:35:00
;    Now switch to a stack located at the top of conventional memory before
;    calling INT 21 ah=4B.
;    CSTART.ASM 1.19 93/05/24 11:38:22
;    alloc_com_memory now allocates copy buffer by allocating largest possible
;    block then shrinking it to the correct size. This prevents the buffer
;    being located in upper memory after a HILOAD.
;    CSTART.ASM 1.16 93/02/24 17:42:01
;    int10_cls() no longer checks position of INT 29 vector.
;    CSTART.ASM 1.12 92/11/17 14:26:40 
;    Change to set_reload_file to allow switches on COMSPEC line.
;    CSTART.ASM 1.10 92/09/17 11:31:43 
;    INT 2e DS=SI=0 now works when we are relocated.
;    CSTART.ASM 1.9 92/09/11 10:45:36
;    our_cmd_int2f altered so we can support multi-line macros in DOSKEY.
;    CSTART.ASM 1.8 92/08/06 09:55:22
;    Correctly support INT 2F AH=AEh for EDOS. See _cmd_line_int2f.
;    Int 2E DS=SI=0 causes batch processing to halt.
;    CSTART.ASM 1.7 92/07/20 17:13:44
;    Added the following maintanence source code changes:
;    29 Apr 92 Now sets Novell error mode to 00 on entry, and restores
;    ;		original mode on exit.
;    18 May 92 Added routine get_original_envsize, to use as default if
;    ;		/E option not used
;    ENDLOG

    page	62,132
	title	COMMAND.COM Startup Routines and Resident Section
;
;  7 Nov 87 Force the initial PATH specification to the root of the
;		boot drive. Also add a new variable TEMPDRV which is 
;		Concurrents Temporary Drive.
;
; 10 Dec 87 If DRNET has been loaded then add the DRNET=x.x string to
;		the initial environment.
; 25 Feb 88 Run the 2nd Phase RSP's before spawning the remaining TMPs
;  1 Mar 88 Initialize the AUTOLOGON and NODE variables for diskless
;		workstation support. Support the NODE environment variable
; 21 Mar 88 Allow for all registers to be corrupted on return from the 
;		DOS EXEC function call.
;  5 Apr 88 Correctly handle incorrect command line length passed by
;		FrameWork Install Program
; 13 Apr 88 Move Memory allocation code to DOSIF and initialise the
;		default console in PD for SunRiver.
; 10 May 88 Clean-Up the segment grouping and force the CGROUP to be
;		linked after the data for everything but the TMP. Add the
;		INT10_CLS function for DOSPLUS
; 12 May 88 Cater for DesqView passing an environment segment of 0000
; 13 May 88 Alter FCB build to giver F & RED when /FRED typed in For FS.COM
; 19 May 88 Prevent CODE being moved to high memory if loaded as an .EXE
;		or no initial environment is supplied
; 20 May 88 Move reload messages into the MESSAGE.C file.
; 24 May 88 Use the internal Critical Error handler and check for ABORT
;		codes while in the Command Processor Code.
;  6 Jun 88 Move Command ReadLine down to resident code - so SK+ can
;		overwrite the hi-mem portion.
; 16 Jun 88 VC_DATA now returns the Physical Console Number as well.
; 21 Jun 88 Add FARPTR routine which determines the correct segment to
;		return to PRINTF based on the offset of a message.
; 22 Jun 88  remove environment & PSP setup & RSP spawning code
;		for banked RSP support. Kludgey CDOS_EXEC code for banking
; 29 Jun 88 Modify MASTER_ENV so it can be called from C and change the
;		exec code to use the internal FCB parsing.
; 30 Jun 88 Set the default PRINTER and AUX using the information in the
;		INT17 and INT14 mapping arrays.
; 20 Jul 88 Increase HEAP Size to 0A00h for the TMP
;  9 Aug 88 Terminate the command line after a CR or LF for 
;		BitStream Fontware.
; 31 Aug 88 Make the READLINE function call from high memory so PolyTron
;		PolyWindows can be invoked from the command line.
; 22 Sep 88 Always use INT_BREAK routine for Control Break Handling
; 03 Oct 88 Invalidate the Old Environment for Novell under CDOS.
; 09 Nov 88 Select the correct DR-DOS history Buffer.
; 15 Nov 88 Re-initilaise Interrupt handlers after an EXEC for Novell
; 21 Nov 88 Install Command Processor Backdoor but just terminate caller
; 13 Dec 88 Generate the FCBs for a DOS exec internally for compatibility
;		with Novell Netware.
; 15 Dec 88 Force the default INT 22, 23, 24 and 2E handlers to be set 
;		relative to the PSP. Update PSP copies of interrupt 22, 23, 24
;		if this is the root DOS process.
; 25 Jan 89 If new DRDOS internal data layout get the PD a new way
; 27 Feb 89 fix MAKE_FCB, use SI from F_PARSE if possible
; 15 Apr 89 INT2E handler
; 17 Apr 89 int10_cls: don't return to 25 lines if in 43 or 50 line mode 
; 31 May 89 DRDOS get PD using new f4458 backdoor
;  6 Jun 89 int2e: amend our copy of command, not users command
; 19 Jun 89 Remove "Alternative" methods of getting PD address
; 14 Jul 89 SideKick Plus checksum only done if STDERR is to CON
;		(so when LAPLINK does CTTY COM1 it goes quicker)
;  6 Sep 89 Call INT21/5D09,5D08 in readline
; 30 Oct 89 Throw away startup code (put it in STACK segment)
; 13 Nov 89 Relocate DRDOS resident code over command line/fcbs in PSP
; 30 Jan 90 in_exec is now incremented and decremented to allow
;		novell menu program to exit successfully.
; 30 Jan 90 Added batch_seg_ptr before first occurance of string
;		'A:\COMMAND.COM' (reload_file). Novell uses it during
;		remote boot.
; 31 Jan 90 restore_term_addr puts back old Int22/23/24 ready for
;		an EXIT command (DESQview bug)
;		If no environment make reload_file in root of default drive
;  7 Feb 90 Turn off HILOAD on DRDOS
;		Add d2cgroupptr support routine (see COM.C)
; 27 Mar 90 turn history buffers to command when in readline, so COPY CON
;		etc will use application buffers
; 30 Mar 90  Stop cleanly when we can't reload transient portion rather
;		than overwriting other peoples memory and crashing
;  4 Apr 90 dbcs_init moved from DOSIF, use system table,
;		throw away init code
; 12 Apr 90 changed for no inherited environment
; 18 Apr 90 add JW's changes to int10_cls to support JW's new VGA card
;  9 May 90 Int2E doesn't trash Int24, returns with CY clear
; 17 May 90 CLI/STI round stack swap in INT2E exit routine.
;  5 Jun 90 Int21/4458 checks CY before fetching PD, so if running on DOS
;		we carry on into the C code which gives version error
; 12 Jun 90 master_env now leaves MS_M_STARTEGY alone, because Novell
;		gets confused if it ends up high
;  3/Jul/90 DLS data into R_TEXT for Watcom C v7.0 (again - I originally
;		did this on 20/Apr/90, but someone screwed up with the
;		archive version	managment).
;  2-Aug-90 RG-00- define LOGIN procedures for Stellar security
;  1-Sep-90 _msgfarptr added for DLS
; 13-Sep-90 COMSPEC=A:\COMMAND.COM even when CDOS.COM
; 21-Sep-90 Increase TMP heap size so we can save initial state for
;		subsequent login's.
; 26-Sep-90 We now switch to our own psp during an INT 2Eh.
; 		This fixes bug experienced with NOVELL MENU.EXE on top of
;		DR DOS 5.0.
; 11-Oct-90 CDOSTMP exec stashes unlinked MD in PSP for TSR auto-load
; 03-Dec-90 Stop corruption of DMD chain when allocating high memory for
;		transient portion of command processor 
; 11 dec 90 CDOS.COM switches to TMP history buffer
; 13 dec 90 save ES around TMP P_EXEC (DRNET sometimes trashes it)
; 17 dec 90 exec of CMD call io_pckbd with cl=40h (must be 24 line)
; 26/Feb/91 Increased _rld_msgs maximum text size from 100 to 120.
; 11/Mar/91 Added show_help function. COMMAND.COM is now really
;       an EXE file with the help messages tagged onto the end.
; 25/Apr/91 Most of the resident code/data is now relocatable to high
;		memory. Some Novell critical data is left in low memory.
; 15/May/91 Added dummy code to force at least one relocation item in
;		.exe header so loader doesn't think file is EXEPACKed.
; 12/Jun/91 Added dummy code to allow Software Carousel to run.
;		See int22_entry.
; 19 jun 91 disable control break until handler initialised
; 24/Jun/91 Changed memory allocation procedure on return from func 4B to
;		allow Novell Remote Boot to work.
;  2 jul 91 our_cmd_int2f only has single parameter
; 26 jul 91 Novell dummy pipe filenames zero terminated
; 29 jul 91 A 1K far buffer is now allocated by alloc_com_memory. It is
;		used by type, batch_read, and printf.
;  5 Aug 91 Call Get Extended Error (int 21 ah=59) after exec.
; 14 Aug 91 Put pointers to _batch, _batchflg, and _echoflg in low memory
;		stub. This is primarily for Software Carousel.
;  4 Dec 91 Fixed problem with full environment trashing next DMD.
; 29 Apr 92 Rearranged DGROUP so that constant code and data appear after
;		the stack - So that Multitasker need not save it.
; 10 Jun 92 show_help function now copes with doubled % characters.
;
;------------------------------------------------------------------------------

.xlist
include msdos.equ          
include mserror.equ
include char.def
.list

MAX_FILELEN	equ	140

; This is the offset in segment FFFF to which we will relocate.
; It is set to E0 to allow for a PCNFS bug
HISEG_OFF	equ	0E0h


FALSE		equ	0h
TRUE		equ	not FALSE

ThreeCOM	equ	TRUE


Copy_Buffer_Size equ	0C80h		; 50k of buffer space in paras
					; matches MAX_COPYBUF in COMCPY.C
RLSTACK_SIZE	equ	256+256		; Reserve for ReadLine stack
					; We need 260 bytes for possible
					; buffer, plus a little stack
					; If the stack overflows it isn't
					; a disaster - we will just re-load
           				; COMMAND.COM


;C_HEAP_SIZE	equ	0800h		; C routine Heap Size
					; (observed sizes 500h-600h - IJ)
C_HEAP_SIZE	equ	0CC0h		; C routine Heap Size
; For safety increased that value as UNC filenames require 128 byte buffers
; allocated dynamically on tha stack. With respect to the observed sizes
; above it might be dangerous to leave that value at 0800h. I would have
; increased the value to 0A00 but then it does no longer fit into HMA. (JBM)


include f52data.def

;
;	Standard definitions for PSP variable
;
PSP_TERM_IP	equ	es:word ptr 000Ah
PSP_PARENT	equ	es:word ptr 0016h
PSP_ENVIRON	equ	es:word ptr 002ch

swap	MACRO	reg1, reg2
	push	reg1
	push	reg2
	pop	reg1
	pop	reg2
	ENDM
	
	page


;	The following declarations declare the presence and order of
;	various data segments within the DATA Group of the command
;	processor.
;
DGROUP	GROUP	R_TEXT, ED_TEXT, NULL, _DATA, DATA, CONST, FIXED, _BSS, HEAP, c_common, STACK, DYNAMIC

R_TEXT		SEGMENT para public 'CDOS_DATA'
R_TEXT		ENDS
NULL		SEGMENT byte public 'BEGDATA'
NULL		ENDS
_DATA		SEGMENT byte public 'DATA'
_DATA		ENDS
DATA		SEGMENT byte public 'DATA'
DATA		ENDS
CONST		SEGMENT byte public 'CONST'
CONST		ENDS
FIXED		SEGMENT byte public 'FDATA'
FIXED		ENDS
_BSS		SEGMENT byte public 'BSS'
_BSS		ENDS
HEAP		SEGMENT byte public 'BSS'
HEAP		ENDS
c_common	SEGMENT byte public 'BSS'
c_common	ENDS
STACK		SEGMENT word public 'STACK'
STACK		ENDS
ED_TEXT		SEGMENT para public 'CDATA'
	Public	ed_text_start
ed_text_start	label byte
	Public	_loadfile
_loadfile	db	MAX_FILELEN dup(?)
	Public	_argv0
_argv0		db	MAX_FILELEN dup(?)
ED_TEXT		ENDS
DYNAMIC		SEGMENT para public 'DDATA'
DYNAMIC		ENDS


CGROUP	GROUP	_TEXT, _MSG, _TEXTEND
_TEXT		SEGMENT para public 'CODE'
ifdef	DLS
	extrn	_my_dls_init:far
endif
_TEXT		ENDS

_MSG		SEGMENT byte public 'CODE'
_MSG		ENDS

_TEXTEND	SEGMENT para public 'CODE'
_TEXTEND	ENDS


CEND	GROUP	ETEXT, ETEXTEND
ETEXT		SEGMENT para public 'XEND'
ETEXT		ENDS
ETEXTEND	SEGMENT para public 'XEND'
ETEXTEND	ENDS


codeOFFSET	equ	offset CGROUP:
dataOFFSET	equ	offset DGROUP:
endOFFSET	equ	offset CEND:

code_length		equ	codeOFFSET rlstack 	; Total Code Length
real_code		equ	code_length - RLSTACK_SIZE
static_length		equ	dataOFFSET FIXED	 ; Static Data Length
dynamic_length		equ	dataOFFSET ed_text_start
total_length		equ	dataOFFSET DYNAMIC	 ; Total Data Length
cgroup_length		equ	codeOFFSET _TEXTEND
cend_length		equ	endOFFSET ETEXTEND

; help_length is an APPROXIMATE value, but it must be LARGER than the correct
; length of the help segment.
ifdef DLS
help_length		equ	0A000h		 
else
help_length		equ	05000h
endif

page		
public	__acrtused		; trick to force in startup
	__acrtused = 9876h	; funny value not easily matched in SYMDEB


R_TEXT	SEGMENT
	assume cs:DGROUP, ds:nothing, es:nothing, ss:nothing

ifdef	WATCOMC
	Public	_small_code_		; Watcom C requires this label to
_small_code_	label	near		; be declared in the start-up module
else
ifdef	MWC
	Public	_mwINIT			; MetaWare requires this label
_mwINIT		label	near		; to be declared in the start-up
					; module
else
    Public  __cstart       
__cstart	label	near		; to be declared in the start-up
					; module
endif
endif

	extrn	_gp_far_buff:word
	extrn	com_criterr:near


cstart:					; start address of all "C" programs
	call	near ptr getIP		; Push the IP register and Skip the
retIP:					; version control messages.
	dw	0EDCh			; Digital Research Marker
	dw	code_length		; Length of the Code Group
	;dw	static_length		; Length of the Fixed Data Group
ifdef DLS
	dw	total_length
else
	dw	dynamic_length		; length of dynamic data
endif
	dw	total_length		; Minimum Length of the Runtime
					; Data Group

reloc_off	dw 0		; offset of relocated resident code/data 
reloc_seg	dw 0		; segment of relocated resident code/data
reloc_size	dw 0		; size of relocated resident code/data

	public	_batchptr_off
	public	_batchflg_off
	public	_echoflg_off
_batchptr_off	dw 0		; offset of _batch variable
_batchflg_off	dw 0		; offset of _batchflg variable
_echoflg_off	dw 0		; offset of _echoflg variable

; These are the entry points for INT 23 and INT 24. They will have JMPF
; instructions poked into them.
control_break_entry	db 5 dup(90h)
crit_error_entry	db 5 dup(90h)


; The call to MS_X_EXEC must be made from the same segment as the PSP.
; msdos_exec does a far jump to here and then we far jump back.

psp_dofunc4b:
		mov	ax,(MS_X_EXEC*256)
		int	DOS_INT
		jmp  	i22_entry

; Software Carousel Version 5.0 looks for the following three instructions
; and assumes it is an entry point to int 22 code.
		mov	bx,0ffffh
		mov	ah,48h
		int	21h
		clc
i22_entry:		
int22_entry	db	0eah
		dw	dataOFFSET func4b_return
func4b_seg	dw	0

int2E_entry	db	0eah
		dw	dataOFFSET int2E_far_entry
int2E_seg	dw	0


; IMPORTANT - batch_seg_ptr MUST be just before reload_file. - EJH
;
;	***** Do Not change the order of the following variables *****
;

batch_seg_ptr	dw 0ffffh		; file filename. For novell remote
					; boot support.

reload_file	db	'A:\COMMAND.COM',0
		db	(80-15) dup ('n')	; Expanded LoadPath

;cmdline	db	128 dup ('c')	; Local Copy of Initial Command Line

;	dummy pipe filenames for NOVELL

out_pipe 	db	'_:/' , 0 , '_______.___',0
in_pipe		db	'_:/' , 0 , '_______.___',0

;
;	***** Do Not change the order of the preceeding variables *****
;

; This next bit forces hi_seg_start to be on a paragraph boundary 
	org	HISEG_OFF
hi_seg_start	label byte

; Himem Registration chain entry
himem_link_next	dw	0
himem_link_size	dw	0
		db	5

	public	__psp2
__psp2		dw	0

	Public	_batch_seg_ptr
_batch_seg_ptr	dw	dataOFFSET batch_seg_ptr
		dw	0	; segment will be set to low_seg

	Public	_cbreak_ok

_cbreak_ok	db	0	; set when ctrl-break handler initialised

	; The following causes there to be at least one relocation item
	; in the .exe header so the loader does not think the file is
	; EXEPACKed.
	mov	ax,seg _batch_seg_ptr

R_TEXT	ENDS


_TEXT	SEGMENT

 	extrn	_int2e_handler:far
	extrn	__main:far		; C main program


_TEXT	ENDS

_DATA	SEGMENT
;
;	Data held in this segment remains in the resident portion of 
;	the program image is is not overlayed by transient programs
;	loaded by COMMAND.COM. The variables here are private to the
;	startup module.
;
psp_save_area	dw	6 dup (?)

	extrn	_n_option:word
;
;	The following is the offset and segment of the C routine MAIN
;	which is moved up in memory in order to accomodate the
;	Environment variables and Resident Data area.
;
C_code_entry	label	dword
	Public	code_seg,low_seg	
code_off	dw	codeOFFSET __main	; Offset of MAIN
code_seg	dw	?			; Segment of MAIN
data_seg	dw	?			; DGROUP segment
alloc_seg	dw	?			; the start of hi mem allocated
low_seg		dw	?			; segment of low memory stub.

;
;	Novell 2.1 intercepts the DOSPLUS 4B00  return by updating the
;	PSP USER_SS/SP and  when it returns ALL registers except CS:IP
;	have been corrupted.
;
	extrn	stack_min:word		; Minimum Stack Address
	extrn	heap_top:word

readline	label	dword		; FAR pointer to READLINE routine
		dw	dataOFFSET msdos_readline
readline_seg	dw	?

critical	dd	?		; Critical Error Handler Address
exec_sp		dw	?
exec_ss		dw	?

exec_block	label	byte
exec_env	dw	?		; Environment Segment
exec_clineoff	dw	?		; ASCIIZ Command line Offset
exec_clineseg	dw	?		; ASCIIZ Command Line Segment
exec_fcb1off	dw	dataOFFSET fcb1	; FCB1 Contents Offset
exec_fcb1seg	dw	?		; FCB1 Contents Segment
exec_fcb2off	dw	dataOFFSET fcb2	; FCB2 Contents Offset
exec_fcb2seg	dw	?		; FCB2 Contents Segment

exec		label	dword		; FAR pointer to EXEC routine
		dw	dataOFFSET msdos_exec
exec_seg	dw	?

msdos_exec_ret	label	dword		; FAR pointer to exit EXEC routine
		dw	codeOFFSET _exec_ret
msdos_exec_ret_seg dw	?

fcb1		db	16 dup (?)	; FCB1 Buffer
fcb2		db	16 dup (?)	; FCB2 Buffer
crc		dw	?		; COMMAND.COM crc

; For Dual Language Support...
ifdef DLS
;;ED_TEXT		SEGMENT para public 'CDATA'

	Public	_rld_msgs,_rld_text
_rld_msgs	dw	120 ;RELOAD_LEN	; size of this message buffer
_reload_msgs	dw	0		; First part of Code reload prompt
_reload_msgf	dw	0		; Second part of Code reload prompt
_reload_msgm	dw	0		; Unlikely part of Code reload prompt
		dw	0		; end of list
_rld_text	db	120 dup (?)	; message text is placed here
RELOAD_LEN	equ	$-_reload_msgs
;;ED_TEXT		ENDS
else
	extrn	_reload_msgs:byte	; First part of Code reload prompt
	extrn	_reload_msgf:byte	; Second part of Code reload prompt
	extrn	_reload_msgm:byte	; No memory available message
endif


reload_flag	db	0		; Reloading Command Processor	
in_exec     db  0       
high_code	dw	TRUE		; Enable High Code
exe_file	dw	FALSE		; True if COMMAND.COM is really an EXE
return_code	dw	?		; Exec return code
net_error_mode  db	?

; int2E data

i2e_lock	dw	0		; mutex flag
i2e_user_ss	dw	0		; users ss, sp
i2e_user_sp	dw	0
i2e_stack	dw	0
i2e_cmd		dw	0		; offset of local copy of command line

i2e_c_entry	label	dword
i2e_c_offs	dw	codeOFFSET _int2e_handler
i2e_c_seg	dw	?

i2e_i23vec	label	dword
i2e_i23off	dw	?
i2e_i23seg	dw	?

i2e_i24vec	label	dword
i2e_i24off	dw	?
i2e_i24seg	dw	?

_DATA	ENDS


_BSS	SEGMENT
Public	_edata
_edata	label	BYTE		; end of data (start of bss)
_BSS	ENDS

ETEXT	SEGMENT
;
;	The RLSTACK segment holds the stack used by the READLINE routine.
;	This must be in High memory for the PolyTron PolyWindows product.
;
;	"ETEXT" also forces the linker to pad the CGROUP to at least
;	real_code bytes. Otherwise the file length can be upto 15 bytes 
;	shorter then real_code + total_length. This obviously causes 
;	problems with CALC_CRC and the file reloading.
;
		db	RLSTACK_SIZE dup(0CCh)
rlstack		label	word

ETEXT	ENDS

STACK	SEGMENT

stack_start:
;	HEAP_TOP is initialised to _end so the _RELOAD_FILE and CMDLINE
;	variables are allocated on the HEAP.
;

Public	_end
_end	label	BYTE		; end of bss (start of startup/stack)


	db	255,'3771146-XXXX-654321'

	page
;
;	The CS register is now adjusted so that this startup
;	can be used in the form of an .EXE or .COM. Whatever the 
;	execution format of this file DS still points at the PSP
;	but must be careful when resizing the RAM.
;
getIP	PROC	FAR
	cld				; be sure of DIR flag...
	pop	di			; Get the Program Counter
	sub	di,dataOFFSET retIP	; Correct for retIP
	mov	cl,4			; Convert Offset values to Segments
	mov	ax,cs			; Get the current CS
	shr	di,cl			; Convert Initial IP to Segment
	add	ax,di			; add to CS and save for CALLF to MAIN
	push	ax			; Save the New CS and the offset to
	mov	ax,dataOFFSET gotCS	; the next instruction and then execute
	push	ax
	ret				; a RETF instruction to correct CS.
getIP	ENDP

; Most of the PSP (FCB's and command buffer) is unused - we reclaim this space
; by relocating the resident part of COMMAND.COM

reloc_code:
;----------
; On Entry:
;	CS = DGROUP, DS = PSP, ES = nothing
; On Exit:
;	CS = relocated DGROUP
;
; We build a "REP MOVSB ! RETF 6" on the stack. We also fiddle the near return
; address into a FAR. We then setup our registers appropriately and execute
; this code.
;
	ret


gotCS:
	;out	0fdh,al			; for debug purposes
	
	mov	[__psp2],ds		; Save our PSP in the local variable
	mov	ax,cs			; put our stack somewhere safe
	mov	ss,ax
	mov	sp,dataOFFSET rlstack
	push	ds
	push	di
	call	reloc_code		; relocate code over unused bit of PSP
	pop	di
	pop	ds
ifdef DLS
	call	_my_dls_init
endif

	mov	[code_seg],cs		; Initialise the DATA segment address
	mov	[data_seg],cs		; and calculate the current address
	mov	[exec_seg],cs		; of the Code Segment
	mov	[readline_seg],cs	; use it to fixup some JMPFs
	mov	[_batch_seg_ptr+2],cs
	mov	[low_seg],cs	    ; we may be relocated to upper or high
				    ; memory so remember the current segment

	mov	bx,cs			; Path up the JMPF instructions
	sub	bx,[__psp2]		; around the MSDOS EXEC code to
	mov	cl,4
	shl	bx,cl
	add	cs:[exec_psp-2],bx
	mov	cs:[func4b_seg],cs
	mov	cs:[int2E_seg],cs
	mov	cs:[exec_psp],ds

	cmp	di,0000h		; Disable Code Relocation if we have
	jnz	gotCS_10		; been loaded as an .EXE file
	;;mov	high_code,FALSE
	
	mov	exe_file,TRUE		; Remember we are an EXE

gotCS_10:
	mov	di,total_length
	shr	di,cl
	add	[code_seg],di

	push	ds			; Initialise the Checksum so we can
	mov	ds,[code_seg]		; check the integrity of the high
	mov	si,2			 ; high copy of the command processor
	call	calc_crc		; code
	pop	ds
	mov	[crc],ax

	mov	ah,0ddh			; set Novell error mode
	mov	dl,0			; to 00 - BAP
	int	21h
	mov	net_error_mode,al	; save original error mode

	call	get_ds			; Get DGROUP value in AX
	cli				; turn off interrupts
	mov	ss,ax			; SS = DGROUP
	mov	sp,dynamic_length	; Initialise SP
	;mov	sp,total_length
	sti				; turn interrupts back on

	assume	ss:DGROUP

	push	ax
	call	handler_init		; Initialise the Control Break and
	pop	ax			; Critical Error Interrupt Vectors

	mov	si,total_length		; Get the DGROUP length in bytes
	add	si,code_length		; Add in the Code Length
	mov	cl,4			; and convert to a paragraphs
	shr	si,cl
	mov	bx,ax			; Get the Current DS
	sub	bx,__psp2		; and calculate DS - PSP Seg
	add	bx,si			; DS + Data length in Para's
	mov	es,__psp2
	mov	ah,MS_M_SETBLOCK
	int	DOS_INT

	call	exec_name		; Get our Load Path from the environment

	cmp	high_code,FALSE		; Skip Memory check if HIGH_CODE
	jz	cstart_10		; support has been disabled

	mov	high_code,FALSE		; Assume Failure.
	
	call	alloc_com_memory	; Allocate high memory for command.com
	jnc	carry_on
	
	mov	ax,cs			; if no memory and CS is nearing
	cmp	ax,8000h		; transient part abort and go home.
	jb	cstart_10
	
	mov	ah,4ch
	int	21h	

carry_on:
	mov	high_code,TRUE		; Set HIGH_CODE flag TRUE	
	push	es			; Relocate the command processor code
	push	ds			; into high memory
	mov	es,ax			; es-> destination segment
	mov	di,0
	mov	si,0
	mov	ds,code_seg		; ds-> code to be moved
	mov	cx,real_code		; convert bytes to words
	shr	cx,1
	rep	movsw			; Move code up to high memory
	mov	code_seg,es		; update code_seg

	pop	ds
	pop	es
		
; Shrink memory containing low memory version of step aside code
	mov	si,total_length		; Get the DGROUP length in bytes
	mov	cl,4			; and convert to a paragraphs
	shr	si,cl
	call	get_ds
	mov	bx,ax			; Get the Current DS
	sub	bx,__psp2		; and calculate DS - PSP Seg
	add	bx,si			; DS + Data length in Para's
	mov	ah,MS_M_SETBLOCK
	int	DOS_INT
	
cstart_10:
	mov	ax,4457h		; terminate HILOAD operation
	mov	dx,200h
	int	DOS_INT
	call	dbcs_init		; initialise the DBCS support
	call	get_cs
	push	ax
	mov	ax,codeOFFSET memory_init
	push	ax
	db	0CBh			; a RETF instruction to correct CS.

page
;
;	Build the full path and filename of this process using the
;	loadpath attached to the environment. If no filename exists
;	then prevent the Command Processor code from being located
;	in high memory.
;
exec_name:
	push	es
	mov	es,__psp2		; Get the PSP Segment Address
	mov	dx,PSP_ENVIRON		; Get the environment segment
	cmp	dx,0000			; Have we got an environment ?
	jz	exec_n11		; No prevent High Code Support

	mov	es,dx			; Scan through the environment and
	mov	di,0			; determine the Environment size and
	mov	al,0			; the Load file name
	mov	cx,7FFFh
exec_n05:				; Scan through the Environment
	repne	scasb			; searching for the 00 00 terminator
	jcxz	exec_n10		; Terminate On CX == 0000
	cmp	es:byte ptr [di],al	; If the next byte is zero then this is
	jnz	exec_n05		; then end of the environment
	cmp	es:word ptr 1[di],1	; Are we pointing at the Control Word
	jnz	exec_n10		; No then no Load Path exists

	push	ds
	mov	ds,dx			 ; DS -> Environment Segment
	;call	get_ds
	;mov	es,ax			 ; ES -> Command Processor Data Seg
	mov	es,[low_seg]
	lea	si,03[di]		 ; Fully expand the filename so the
	mov	di,dataOFFSET reload_file ; user can SUBST drives
	mov	ah,60h
	int	DOS_INT
exec_n15:
	pop	ds
	pop	es
	ret

exec_n10:
	mov	high_code,FALSE
exec_n11:
	mov	ah,MS_DRV_GET
	int	DOS_INT			; get default drive
	mov	es,[low_seg]
	add	es:reload_file,al	;  and use that for the comspec
	push	ds
	;call	get_ds
	;mov	es,ax			 ; ES -> Command Processor Data Seg
	jmp	exec_n15

DI_BUF_PTR	equ	dword ptr -4	; pointer to DBCS lead byte table
DI_BUF_ID	equ	byte ptr -5	; buffer id
DI_BUF		equ	byte ptr -5	; buffer

DI_LOCALS	equ	5		; No. bytes storage local to init_dbcs

_DATA		SEGMENT byte public 'DATA'

	Public	dbcs_table_ptr

dbcs_table_ptr	label	dword
dbcs_table_off	dw	dataOFFSET dummy_dbcs_table
dbcs_table_seg	dw	0

dummy_dbcs_table dw	0

_DATA		ENDS

dbcs_init	proc	near
;--------
; To initialise the double byte character set (DBCS) lead byte table.
; MUST be called before the first call to dbcs_lead() or dbcs_expected().
; Entry
;	none
; Exit
;	none (side effect: DBCS table initialised)

	push	bp
	mov	bp, sp
	sub	sp, DI_LOCALS		; allocate local variables
	push	ds
	push	es
	push	di
	push	si

	mov	dbcs_table_seg, ds	; assume DBCS call will fail

	mov	ax, 06507h		; Extended Country Info: get DBCS ptr
	mov	bx, 0FFFFh		; codepage number: -1 for global cp
	mov	cx, 00005h		; size of info. buffer
	mov	dx, 0FFFFh		; country code: -1 for current country
	lea	di, DI_BUF[bp]
	push	ss
	pop	es			; es:di -> DI_BUF
	int	21h			; returns with DI_BUF filled in
	 jc	di_exit			; just exit if function fails

	cmp	DI_BUF_ID[bp], 7	; is table for DBCS?
	 jne	di_exit			;  no - exit
	les	ax, DI_BUF_PTR[bp]	; es:ax -> system DBCS table

	mov	dbcs_table_off,ax
	mov	dbcs_table_seg,es	; fixup pointer to system DBCS table

di_exit:
	pop	si
	pop	di
	pop	es
	pop	ds
	mov	sp, bp
	pop	bp
	ret
dbcs_init	endp

; I want to do
;	db	(C_HEAP_SIZE - 6 - ($ - stack_start)) dup (0DDh)
; but MASM requires dup's be absolute, so instead
rept	C_HEAP_SIZE
if (offset $ - offset stack_start) LT (C_HEAP_SIZE - 6)
	db	0ddh
endif

endm

stack_top	label	word
stack_ip	dw	?		; Initial Offset	
stack_cs	dw	?		; Initial Code Segment (Unknown)
stack_flags	dw	?		; Initial Flags (Unknown)
STACK	ENDS

ED_TEXT	SEGMENT
;
;	Return the CheckSum of All the C code and Static Data. DS:SI 
;	are initialised to point at the C_code_start. AX contains the
;	CheckSum on return.
;
calc_crc:
	mov	cx,real_code		; Number of bytes to move is always
	shr	cx,1			; even because of the segment def.
	dec	cx
	mov	bx,0EDCh		; Checksum Seed
cc_10:					; Sum the words of the image while
	lodsw				; rotating the check value
	add	bx,ax
	rol	bx,1
	loop	cc_10
	xchg	ax,bx
	ret

page
;
;	Return the code segment of the C main routine.
;
get_cs:
	mov	ax,cs:code_seg
	ret

;
;	Return the Data segment of the C data area
;
get_ds:
	mov	ax,cs:data_seg
	ret

	
; Get remaining memory size, subtract code size and allocate high memory for
; transient portion of command processor
;	Exit	AX=Segment of high memory
;		CY set if none available
; 
; This used to allocate only just enough space for the code at the top of
; memory and leave the reset free for use as copy buffers.
; But then came SideKick Plus - this assumes COMMAND.COM only uses the top
; 20K of it's hi-mem partion and overwrites the rest as it gets it's
; overlays. As we are bigger the 20K the result is the system crashes when
; you exit back to the command line.
; In order to minimise this possibility we reserve some space (currently 50K)
; for use as copy buffers and allocate all the rest to the hi-mem portion
; of COMMAND.COM. Since SK starts overwriting from the bottom of memory it
; doesn't usually reach the code.
; The real solution is of course to make sure we are smaller than 20K too...
; (Or transfer the ReadLine code into the resident portion and checksum the
; hi-mem before returning to the hi-mem code ???).
; --ij

public	alloc_com_memory
alloc_com_memory:
	push	es
	mov	bx,0FFFFh		; Allocate more paras than there are
	mov	ah,MS_M_ALLOC		; to find out how many there are.
	int 	DOS_INT
	mov	ah,MS_M_ALLOC
	int	DOS_INT			; allocate it

	mov	si,code_length		; then convert the CODE_LENGTH to 
	mov	cl,4			; paragraphs and check if enough memory
	shr	si,cl			; is available to copy the code high
	add	si,1 			; + para for a memory descriptor 
	sub	bx,si			; Is there enough for the code ?
	 jc	acm_10			; if not exit with error


	cmp	bx,Copy_Buffer_Size	; allocate some memory for Copy Buffers
	 jb	acm_5
	mov	bx,Copy_Buffer_Size	; limit the maximum Copy Buffer size
acm_5:
	mov	es,ax
	mov	ah,MS_M_SETBLOCK
	int	DOS_INT			; shrink to fit
	push	es			; save buffer address
	
; Now allocate remaining memory for step aside code
	mov	bx,0FFFFh		; allocate all memory
	mov	ah,MS_M_ALLOC		; to find out how much there is.
	int 	DOS_INT
	mov	ah,MS_M_ALLOC		; block at the end of memory
	int	DOS_INT			; AX=Segment of new block of memory
	mov	alloc_seg,ax		; save address so we can free it
	add	ax,bx			; go to top of memory we allocated

	cmp	ax,0a000h		; dont use memory above A000 as this
	jb	acm_6a			; may disappear when user does
	mov	ax,0a000h		; MEMMAX -V
acm_6a:

	dec	si
	sub	ax,si			; adjust address we run cmd proc at
; Deallocate intervening block of memory
	pop	es
	push	ax
	mov	ah,MS_M_FREE		; Now free it up
	int	DOS_INT
	pop	ax
	mov	cs:_gp_far_buff,real_code
	mov	cs:_gp_far_buff+2,ax	; save address of temp buffer
	clc				; allocated OK
acm_10:
	pop	es
	ret
	
; called to free up the cmd processor's high memory
free_com_memory:
	
	push	es
	push	ax
	mov	es,alloc_seg
	mov	ah,MS_M_FREE
	int	DOS_INT
	pop	ax
	pop	es
	ret


;Control_Break:
;	The Break handler makes the following checks taking the
;	appropriate action after each test:-
;
;	1) Is COMMAND.COM the current process (Get PSP) if NO ABORT
;	2) Is the break_flag SET if YES jump to the C break handler
;	   "break_handler" after insuring that the segment registers
;	   have all be set correctly.
;	
	assume cs:DGROUP, ds:nothing, es:nothing

;	Set up the default Control Break Handler.
handler_init:
	mov	al,24h				; Set the default Critical
	mov	dx,dataOFFSET critical_error	; Error Handler
	mov	bx,dataOFFSET crit_error_entry
	call	set_vector			; Setup correct ISR
	
handler_i10:
	mov	al,23h				; Set the default Control
	mov	dx,dataOFFSET control_break	; Break Handler
	mov	bx,dataOFFSET control_break_entry
;;	jmp	set_vector			; Setup correct ISR
;
;	Convert the address of the interrupt #AL service routine, whose
;	address is CS:DX to be PSP:xxxx. Five NOP must be coded after the
;	interrupt service routine for the JMPF instruction which corrects
;	the code segment.
;
set_vector:
	push	ds
	push	es
	mov	es,[low_seg]
	mov	es:byte ptr 0[bx],0EAh	; JMPF opcode
	mov	es:word ptr 1[bx],dx	; Offset of Interrupt vector
	mov	es:word ptr 3[bx],cs	; Insert the correct code seg
	mov	dx,bx
	mov	bx,es	
	sub	bx,__psp2		; Calculate the correct offset for
	mov	cl,4			; the interrupt handler if the segment
	shl	bx,cl			; must be that of our PSP
	add	dx,bx
	mov	ds,__psp2
	mov	ah,MS_S_SETINT
	int	DOS_INT
	pop	es
	pop	ds
	ret

	;extrn	_int_break:near			; C Break/Error handling routine 

	assume cs:DGROUP, ds:DGROUP, es:nothing

control_break	PROC	FAR
	;;db	5 dup(90h)		; Reserve space for JMPF CS:$+5
	push	ax			; Save the Users registers
	push	bx
	push	ds
	call	get_ds			; Get our Local DS
	mov	ds,ax
	cmp	_cbreak_ok,0		; is our handler initialised ?
	 je	break_05		;  no, don't call it
	cmp	reload_flag,0		; Are we part way through reloading
	clc				;  the command processor?
	 jnz	break_05		; if so do not abort.

	mov	ah, MS_P_GETPSP		; Get the current PSP address
	int	DOS_INT
	cmp	bx,[__psp2]		; Is this our address
	stc				; Assume not and Set the carry flag
	jz	break_10		; if internal, restart the command loop
					; if external, abort process
break_05:
	pop	ds
	pop	bx
	pop	ax
	ret

;
;	This section of code corrects the stack and jumps to the 
;	C code Control Break Handler _int_break. Beware that the
;	stack segment need not be the DS because the READ_LINE routine
;	executes on a high stack and the CED programs will emulates
;	a Control-Break on the wrong Stack.
;
break_10:
	cli				; Swap to the correct stack not
	mov	ax,ds			; forgetting that we might be running
	mov	es,ax			; on old 8088 or 8086 so interrupts
	mov	ss,ax			; must be disabled
	mov	sp,stack_min		; Get the lowest possible stack address
	add	sp,16			; Add a little to avoid problems with
	sti				; the stack check code.

	mov	ax,0100h		; Termination Code Control-C Abort
	push	ax			; Save on the Stack for C routine
	push	ax			; Force a dummy return address on the
					; stack (NOT USED)
	call	get_cs			; Put the Segment and Offset address
	push	ax			; of the C break Handler on the stack
	mov	ax,codeOFFSET _int_break; and execute a RETF to it.
	push	ax
	ret 
control_break	ENDP

critical_error	PROC FAR
	;;db	5 dup(90h)		; Reserve space for JMPF CS:$+5
	push	ds			; Save the Critical Error DS
	push	ax
	call	get_ds			; Get the Command Processor DS
	mov		ds,ax			; and call the original routine
	mov 	ax, _n_option	; check for /n command line option
	cmp		ax, 0
	pop		ax
	jne		skip_criterr
	call	com_criterr		; local criterr handler
	jmp		criterr_cont
skip_criterr:
	mov		al,3			; /n option => always return fail
criterr_cont:
	cmp	al,02h			; Did the user request a Terminate
	 jne	critical_e20		; Yes so check if they are trying to
	push	ax			; terminate the command processor
	push	bx

	mov	ah, MS_P_GETPSP		; Get the current PSP address
	int	DOS_INT
	cmp	bx,[__psp2]		; Is this our address?
	 jne	critical_e10		; no so return with Abort code

	cmp	in_exec,0		; are we EXECing a program ?
	 jne	critical_e10		;  then return the error
	cmp	reload_flag,0		; then unless we are reloading command
	 je	break_10		;  processor break here to prevent
critical_e10:				;  higher levels generating repeated
	pop	bx			;  critical errors (eg. when searching
	pop	ax			;  a path)
critical_e20:
	pop	ds
	iret

critical_error ENDP

;
;	INT2E is a backdoor entry to the "Permanent" Command interpreter 
;	which will execute the command at DS:SI.
;

int2E_far_entry	proc	far
	db	5 dup(90h)		; Reserve space for JMPF CS:$+5

;	ds:si -> command line preceded by byte count

;	check we're not re-entering

	mov	ax, 1
	xchg	cs:i2e_lock, ax
	test	ax, ax
	 jz	i2e_10

	iret

i2e_10:
	push	bx
	push	cx
	push	dx
	push	si
	push	di
	push	bp
	push	ds
	push	es
	
	; if ds = si = 0 then set batch_seg_ptr to zero and get out.
	; This is a clean way of halting batch processing.
	mov	ax,ds
	cmp	ax,0
	jne	i2e_15
	cmp	si,0
	jne	i2e_15

	mov	si,cs:_batch_seg_ptr
	mov	ds,cs:_batch_seg_ptr+2
	mov	[si],ax
	jmp	i2e_exit2
i2e_15:	

;	swap stack

	mov	cs:i2e_user_ss, ss
	mov	cs:i2e_user_sp, sp
	
	cli
	mov	ss, cs:exec_ss
	mov	sp, cs:exec_sp
	sti
	
;	allocate 128 bytes for command line, since the C code needs a 128 
;	byte buffer anyway

	mov	cx, 128

;	save stack p

	mov	cs:i2e_stack, sp

;	have we got enough room for command line 

	mov	ax, sp
	sub	ax, cx
	sub	ax, cs:heap_top
	cmp	ax, 256
	 jge	i2e_25
	jmp	i2e_exit
i2e_25:	
	sub	sp, cx
	mov	cs:i2e_cmd, sp
	
;	copy command line

	push	ss
	pop	es
	mov	di, sp
	lodsb				; get line count
	and	ax,7fh			; limit to 128 bytes
	add	ax,sp			; terminating NULL goes here
	rep	movsb			; copy the command line
	xchg	ax,di			; DI -> NUL posn
	xor	al,al
	stosb				; replace CR with NUL
	push	cs
	pop	ds

;	reload non-resident code if necessary

	cmp	high_code, TRUE
	 jnz	i2e_30
	mov	reload_flag, 1
	call	reload_code
	mov	reload_flag, 0

i2e_30:
;	install our own Break and Criterr handlers - e.g. if second copy
;	of the command processor is running, install original handlers so
;	that they are looking at the same data as we are.
;	N.B. __psp2 is currently that of original command processor

	mov	ax, (MS_S_GETINT*256) + 23h
	int	DOS_INT
	mov	i2e_i23seg, es
	mov	i2e_i23off, bx
	
	mov	ax, (MS_S_GETINT*256) + 24h
	int	DOS_INT
	mov	i2e_i24seg, es
	mov	i2e_i24off, bx
	
	call	handler_init
	
;	save the command processor's __psp2 variable, and then set it to the
;	psp of the process that called us. This is so that the Break and 
;	Criterr abort code can correctly determine whether the int2e command 
;	was internal or external

	mov	ah, MS_P_GETPSP
	int	DOS_INT
	push	bx		; save calling process's psp - EJH	
	mov	bx, [__psp2]

; Set current PSP to our own - EJH	
	mov	ah, MS_P_SETPSP
	int	DOS_INT
	
;	call C code

	mov	ax, code_seg
	mov	i2e_c_seg, ax
	
	push	i2e_cmd	
	call	i2e_c_entry
	pop	ax				; clean up stack
	
; Set current psp back to that of calling process - EJH
	pop	bx
	mov	ah, MS_P_SETPSP
	int	DOS_INT


;	restore interrupt vecs

	push	ds
	lds	dx, i2e_i23vec
	mov	ax, (MS_S_SETINT*256) + 23h
	int	DOS_INT
	
	lds	dx, cs:i2e_i24vec
	mov	ax, (MS_S_SETINT*256) + 24h
	int	DOS_INT
	pop	ds
	
	cmp	high_code, TRUE			; If not a .EXE then free
	 jnz	i2e_ret				; any memory alocated by
	call	free_com_memory			; the Command Processor
i2e_ret:

i2e_exit:
;	swap back the stack

	cli
	mov	ss, i2e_user_ss
	mov	sp, i2e_user_sp
	sti

i2e_exit2:
	pop	es
	pop	ds
	pop	bp
	pop	di
	pop	si
	pop	dx
	pop	cx
	pop	bx

    sub ax, ax          

	mov	cs:i2e_lock, 0
	ret	2

int2E_far_entry	endp


_TEXT	SEGMENT
	assume cs:CGROUP, ds:DGROUP, es:nothing, ss:nothing
	public	_exec			; EXEC routine

;
; WORD CDECL exec(BYTE *path, UWORD type, BYTE *line, BOOLEAN back);
;
;   back    10[bp]      
;	line	08[bp]
;	type	06[bp]
;	path	04[bp]
;
_exec:
;-----
	push	bp
	mov	bp,sp
	push	si
	push	di
	push	ds
	push	es
    inc in_exec         
    cmp in_exec,1       
	 je	_exec10			; Menuing system
	push	exec_ss			; save old stack_save if we
	push	exec_sp			;  are being re-entered
_exec10:
	mov	si,08[bp]		; the Command Line
	mov	exec_env,0000
	mov	exec_clineoff,si
	mov	exec_clineseg,ds
	mov	exec_fcb1seg,ds
	mov	exec_fcb2seg,ds

	push	ds
	pop	es
;
;	Extract two valid filenames from the CR terminated
;	string passed in DS:SI. The FCBs will be generated in FCB1 and FCB2.
;
	inc	si
	mov	di,dataOFFSET fcb1	; Blank fill the first FCB
	call	zap_fcb
	call	make_fcb		; Build first FCB

	mov	di,dataOFFSET fcb2	; Blank fill the Second FCB
	call	zap_fcb
	call	make_fcb		; Build second FCB

	mov	ax,cs
	jmp	exec			; do FAR jmp to msdos_exec as we can't
_exec_ret:				;  trust the stack when CALLing
	dec	in_exec			; Has PCTOOLS un-installed itself ?
	 jz	_exec20			; No so the stack contents are valid
	 js	_exec_bad		; Yes, so exit by Ctrl-Break
	pop	exec_sp			; old stack save back again
	pop	exec_ss			;  in the case of re-entry
_exec20:
	
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	mov	ax,return_code
	neg	ax
	ret
;
;	We have returned from the EXEC function un-expectedly (because
;	of PCTOOLS De-installation ?). Therefore the contents of the stack
;	are invalid and we generate a Control-Break.
;
_exec_bad:
	mov	ax,0100h		; Termination Code Control-C Abort
	push	ax			; Save on the Stack for C routine
	push	ax			; Force a dummy return address on stack
	mov	in_exec,al		; zero in_exec count for next time

	extrn	_int_break:near		; C Break/Error handling routine 
	jmp	_int_break		; now treat as ctrl-break

;
;	Initialise the FCB entry a DX:DI and copy the Drive, FileName
;	and extension form DS:SI when SI != 0FFFFh
;
zap_fcb:
	mov	ax,2000h		; Zero Fill first byte and last 4
	stosb				; Drive code 0
	xchg	al,ah
	mov	cx,11			; FileName and Ext to ' '
	rep	stosb
	xchg	al,ah
	mov	cl,4			; Last four bytes to 00
	rep	stosb
	sub	di,16
	ret

make_fcb:
	call	scan_filechar		; Get the Next File Character
	push	si
	push	di
	push	ax			; Save Character and Pointers

	mov	ax,(MS_F_PARSE shl 8) + 1 ; Parse the command line
	int	DOS_INT

	pop	ax
	pop	di			; Restore the Character and Pointer

	cmp	ah,'/'			; Was the arg preceeded by a '/'
	jne	make_fcb10		; If it was roll back the cmd line 
	pop	si			; pointer and blank all but the 1st
	inc	si			; char in the FCB

	add	di,2			; Such that /FRED gives an FCB of 'F'
	mov	cx,10			; and si points to the 'R'	
	mov	al,' '
	rep	stosb
	ret

make_fcb10:
	pop	ax			; discard original SI, skip name
	jmp	scan_sepchar		; skip until separator

;
;	SCAN_SEPCHAR will search through the command line DS:SI
;	which contains CX characters and return with SI pointing
;	to the next SEPARATOR character.
;
;	On Entry:	DS:SI	Character String
;
;	On Exit:	DS:SI	First Non Separator
;
scan_sepchar:
	push	di			; Save DI  ES points at this segment
	mov	ah,0			; Invalidate Separator Character

scan_s10:
	mov	al,[si]			; Get the Character to Test
	cmp	al,CR
	jz	scan_s20		; Have we reached the end of the string
	mov	cx,legal_length			; Scan the table of legal 
	mov	di,dataOFFSET legal_table	; separators
	repnz	scasb				; Scan the List
	jz	scan_s20			; Separator Located
	inc	si				; the character pointer
	jmp SHORT scan_s10

scan_s20:	
	pop	di
	ret
;
;	SCAN_FILECHAR will search through the command line DS:SI
;	and return with SI pointing to the next NON_SEPARATOR character.
;
;	On Entry:	DS:SI	Character String
;
;	On Exit:	DS:SI	First Non Separator
;			AH	Last Valid Separator
;
scan_filechar:
	push	di			; Save DI  ES points at this segment
	mov	ah,0			; Invalidate Separator Character
scan_f10:
	mov	al,[si]			; Get the Character to Test
	cmp	al,CR
	jz	scan_f20		; Have we reached the end of the string
	mov	cx,legal_length			; Scan the table of legal 
	mov	di,dataOFFSET legal_table	; separators
	repnz	scasb				; Scan the List
	jnz	scan_f20			; Non Separator Located
	mov	ah,al				; Save the Separator and increment
	inc	si				; the character pointer
	jmp SHORT scan_f10

scan_f20:	
	pop	di
	ret

_TEXT	ENDS

legal_table	db	':.;,=+',9,' /<>|',22h,'[]'	
legal_length	equ	15

	assume cs:DGROUP, ds:DGROUP, es:nothing, ss:nothing

	public	msdos_exec	; so it shows in map file
	
msdos_exec PROC FAR
	push	ax
	cmp	high_code,TRUE		; Check if the Command Processor Code
	jnz	msdos_e10		; has been relocated to high memory

	call	free_com_memory		; free cmd processor memory

msdos_e10:
	pop	ax
	mov	bx,dataOFFSET exec_block
	mov	dx,04[bp]		; Get the Full Command Name
	mov	exec_ss,ss		; Save SS:SP in case somebody (NOVELL)
	mov	exec_sp,sp		; corrupts them

;	The following 2 JMPF are kludged so that the INT22 vector saved in
;	the child's PSP has the segment of the comand processors PSP.
;	This is vital for many TSR management utilities.
;

					; swap stack to conventional memory
	cli				;
	mov	ax,__psp2		;
	mov	ss,ax			;
	mov	sp,0100h		;
	sti				;

		db	0EAh			; JMPF Opcode
		dw	dataOFFSET psp_dofunc4b	; Corrected Offset
exec_psp	dw	0			; PSP Segment

	assume cs:DGROUP, ds:nothing, es:nothing, ss:nothing
func4b_return:
	mov	ss,exec_ss		; Restore the real SS:SP
	mov	sp,exec_sp		; Using a CS overide 
	 jc	msdos_e20		; if no error
	xor	ax,ax			; then zero return code
	jmp	msdos_e21
msdos_e20:
	mov	ah,59h			; get extended error code
	sub	bx,bx
	int	21h
msdos_e21:
	mov	return_code,ax
	call	get_ds			; Point DS & ES to CSdata
	mov	ds,ax
	mov	es,ax
	assume cs:DGROUP, ds:DGROUP, es:nothing, ss:nothing

	call	handler_init		; Re-initialise Control-Break and
					; Critical error handlers for Novell
	cmp	high_code,TRUE		; Is the Command Code in High
	 jnz	msdos_e30		; memory ?
	mov	reload_flag,1		; Reloading Command Processor
	call	reload_code		; Reload Command Processor Code
	mov	reload_flag,0		; Command Processor Loaded
msdos_e30:
	mov	ax,code_seg		; Update the CS for the high code
	mov 	msdos_exec_ret_seg,ax	; in case it has moved and return
	jmp	msdos_exec_ret

msdos_exec ENDP

_TEXT	SEGMENT
	assume cs:CGROUP, ds:DGROUP, es:nothing, ss:nothing

	Public	_readline
	
_readline:
;---------
	cld
	push	bp
	mov	bp,sp
	push	si
	push	di
	push	es
	mov	ax,4456h		; Swap to the Command process
	mov	dl,1			; History Buffer in DR DOS
	int	DOS_INT
	mov	ax,5d09h
	int	DOS_INT			; close remote spool files
	mov	ax,5d08h
	mov	dl,1
	int	DOS_INT			; Set truncate flag with redirected I/O

	mov	ah,MS_P_GETPSP		; get the current PSP
	int	DOS_INT			;  then compare the STDERR entry in the
	mov	es,bx			;  XFT with the Magic Number for CON
	cmp	es:byte ptr [18h+STDERR],1
	mov	dx,4[bp]		; get the buffer address and current
	mov	ax,cs			; AX = transient code segment
	call	readline		; do far call to msdos_readline
	mov	ax,4456h		; Swap to the Application process
	mov	dl,0			; History Buffer in DR DOS
	int	DOS_INT
	pop	es
	pop	di
	pop	si
	pop	bp
	ret

_TEXT	ENDS

	assume cs:DGROUP, ds:DGROUP, es:nothing

;
; msdos_readline(BYTE *buffer);
;
; On Entry:
;	flags - ZF set if we need to do Sidekick Plus check
;	DS:DX -> buffer
;	AX:0  -> Resident Section
;	buffer
;
; The memory allocation for the hi-mem part of command.com has already been
; altered to minimise the chances of SideKick Plus overwriting the code.
; But it still can happen, say either on a machine with limited memory or
; other TSR's also loaded. In order to cater for this case we move the actual
; readline call into the resident portion and checksum things before returning
; to high memory - thus we can reload command.com if it get overwritten.
;
msdos_readline PROC FAR
	pushf				; save the result for later

	mov	bx,sp			; SP before swapping stacks.
	cli				; to RLSTACK
	mov	ss,ax			; above the Code and Messages
	mov	sp,codeOFFSET rlstack
	sti
	
	push	bx			; save old SP
	push	ds

	sub	sp,260			; make room for buffer on stack
	mov	di,sp			; save the address

	push	ds
	push	dx			; save real BUFFER for later...
	push	di			;  and buffer on stack

	mov	si,dx			; point DS:SI at real buffer
	mov	dx,di			; point DX at stack buffer
	push	ss			; now get all the seg regs
	pop	es			; pointing to himem
	mov	cx,256/2
	rep	movsw			; copy resident buffer to stack
	push	ss			; DS:DX is stack buffer
	pop	ds

	mov	ax,4810h		; give DOSKEY a chance
	int	2Fh
	or	ax,ax			; zero means DOSKEY has done it
	 jz	msdos_rl10

	mov	word ptr [di],21cdh	; poke INT 21 and
	mov	byte ptr 2[di],0cbh	;  RETF instruction
	push	cs			; save an address for the
	mov	ax,dataOFFSET msdos_rl10;  RETF to return to
	push	ax

	mov	ah, MS_C_READSTR	; parameter for INT 21 readline

	push	ds			; finally jump to the INT 21
	push	di			;  we have poked
    ret             

msdos_rl10:
	pop	si			; source is readline buffer
	pop	di			; recover old address
	pop	es			;  and seg of real buffer

	mov	cl,ds:byte ptr [si]	; get MAX length
	xor	ch,ch			; make it a word
	cld
	rep	movsb			; copy the string

	add	sp,260			; recover my readline buffer space
	pop	ds
	pop	bx			; recover old SP

	cli				; Now restore the normal C stack
	call	get_ds			; which is at DS:BX.
	mov	ss,ax
	mov	sp,bx
	mov	es,ax
	sti

	popf				; recover result of STDERR test
	 jne	msdos_r10		; if not CON, then skip the check
	cmp	high_code,TRUE		; Is the Command Code in High
	 jnz	msdos_r10		; memory ?
	mov	reload_flag,1		; Reloading Command Processor
	call	reload_code		; Reload Command Processor Code
	mov	reload_flag,0		; Command Processor Loaded
msdos_r10:
	mov	ax,code_seg		; Update the CS for the high code
	mov 	word ptr -08[bp],ax	; in case it has moved and return
	ret
msdos_readline ENDP

; Cmd processor is in high memory so check it out
reload_code:
	cmp	in_exec,1	; If we landed here from an undefined area
	je	alloc_mem	; then free cmd processor memory
	call	free_com_memory

alloc_mem:
	call	alloc_com_memory	; Allocate memory for the Command
	 jc	alloc_mem_error		; processor code.
	push	ax
	call	check_crc		; see if code has been trashed
	pop	ax
	je	still_there
	mov	code_seg,ax
	jmp	load_com		; Read in command Processor Code

still_there:
	cmp	ax,code_seg		; has the memory configuration changed?
	je	hasnt_moved		; (it will during Novell remote boot)

	push	ds
	push	es

	mov	cx,real_code
	mov	es,ax			; move the code to the new location
	mov	ds,code_seg		;
	sub	si,si			; ds:si -> old location
	sub	di,di			; es:di -> new location

	rep	movsb			; do it

	mov	cs:code_seg,es		; update code_seg with new location
	
	pop	es
	pop	ds

	call	check_crc		; recalculate the crc
	jne	load_com		; if its not valid we need to load
					; from disk

hasnt_moved:
	ret

alloc_mem_error:
; We can't reload COMMAND.COM because we haven't any memory
ifdef DLS
	mov	dx,_reload_msgm
else
	mov	dx,dataOFFSET _reload_msgm
endif
	call	reload_err		; say we can't reload COMMAND.COM
	jmp	$			; stop forever....

check_crc:
; return with ZF set if himem crc's correctly
	push	ds
	mov	ds,code_seg
	mov	si,2
	call	calc_crc
	pop	ds		; Compare this crc with the one we got earlier
	cmp	crc,ax
	ret
	
; If checksum is wrong load a new copy into high memory and patch new RET addr

open_err:			
ifdef DLS
	mov	dx,_reload_msgf
else
	mov	dx,dataOFFSET _reload_msgf
endif
	call	reload_err		; prompt for COMMAND.COM
	mov	ah,MS_C_RAWIN		; Wait for the User to Press
	int	DOS_INT			; a key

load_com:
	push	ds
	mov	ds,[low_seg]
	mov	dx,dataOFFSET reload_file
	mov	ax,(MS_X_OPEN*256)+40h	; Try to open COMMAND.COM
	int	DOS_INT			; al=40h means NONE DENIED share mode
	pop	ds
	 jc	open_err
	mov	bx,ax

	xor	dx,dx
	cmp	exe_file,FALSE		; if we were loaded as an EXE
	je	load_com_10

	; read .EXE header size
	push	ds
	mov	cx,16			; read first paragraph of EXE header
	mov	ds,code_seg		; DS:DX - > High memory area
	mov	ah,MS_X_READ		; Read the code into memory
	int	DOS_INT
	mov	si,8			; headersize / paras at offset 8
	mov	dx,[si]
	pop	ds
	 jc	read_err		; exit on error
	mov	cl,4			; multiply header size by paragraph
	shl	dx,cl			; DX now contains EXE header size

load_com_10:
	xor	cx,cx			; Now read the command processor code
	add	dx,total_length		; Seek to area of COMMAND.COM
	mov	ax,(MS_X_LSEEK*256)+0	; containing code
	int	DOS_INT
	 jc	read_err

	push	ds
	mov	cx,real_code
	mov	ds,code_seg		; DS:DX - > High memory area
	xor	dx,dx
	mov	ah,MS_X_READ		; Read the code into memory
	int	DOS_INT

	pop	ds
read_err:
	mov	ah,MS_X_CLOSE		; Close the file
	int	DOS_INT

	call	check_crc		; try and see if we loaded OK
	 jne	open_err		; if not complain and try again

	ret

reload_err:
; On Entry:
;	DX = offset of final part of error message
;
	push	dx				; save final part of message
	mov	bx,STDERR			; Display on standard Error
ifdef DLS
	mov	dx,_reload_msgs	
else
	mov	dx,dataOFFSET _reload_msgs	
endif
	call	reload_err10

	push	ds
	mov	ds,[low_seg]
	mov	dx,dataOFFSET reload_file	; Filename
	call	reload_err10
	pop	ds

	pop	dx				; recover msg offset
;
;	Calculate the length of the message to be displayed and output using
;	MS_X_WRITE.
;
;	DS:DX		String to Output
;	BX		Output Handle
;
reload_err10:
	xor	al,al				; String Terminator
	push	es
	push	ds				; look for terminating BYTE
	pop	es				;  in string at DS:DX
	mov	di,dx				;  and get length to display
	mov	cx,0ffffh
	repnz	scasb				; look for terminator
	not	cx				; see how far we had to look
	dec	cx				; forget about the terminator
	mov	ah,MS_X_WRITE
	int	DOS_INT
	pop	es
	ret

ED_TEXT	ENDS


	page
_TEXT	SEGMENT
	assume cs:CGROUP, ds:DGROUP, es:DGROUP, ss:DGROUP

;	zero data areas (_BSS and c_common)
;
memory_init:
	push	ss
	pop	es

	cld				; set direction flag (up)
	mov	di,dataOFFSET _edata	; beginning of bss area
	mov	cx,dataOFFSET _end	; end of bss area
	sub	cx,di
	xor	ax,ax
	rep	stosb			; zero bss

;	C segmentation conventions set up here	(DS=SS and CLD)

	push	ss			; set up initial DS=ES=SS, CLD
	pop	ds
	assume ds:DGROUP

;	do necessary initialization BEFORE command line processing !


	push	es
	mov	ax,4458h		; We now have an IOCTL function
	int	21h			;  to get our private data
     jc mem_init10  
mem_init10:
	pop	es
	xor	bp,bp			; mark top stack frame for SYMDEB
	call	get_cmdline		; Copy the command line to a local
	push	ax			; buffer and pass the address to MAIN
	call	C_code_entry		; main ( cmd )
	add	sp,2			; Restore the Stack
	mov	ah,MS_X_EXIT		; use whatever is in ax after 
	int	DOS_INT			; returning here from main

page
;
;	For TURBOC and METAWARE C the majority of the Command Processor
;	messages are linked with the CGROUP in the MSG segment. When the
;	compiler generates DGROUP relative references large offsets are
;	produced. This occurs because the DGROUP is linked before the CGROUP
;	and its MSG Segment. FARPTR converts a NEAR pointer into a FAR
;	by checking the value of the offset against the DGROUP length.
;	Offset greater than TOTAL_LENGTH must be in MSG so the pointer
;	is converted to CS:x-TOTAL_LENGTH otherwise DS:x.
;
	public	_farptr
_farptr:
	push	bp
	mov	bp,sp
	mov	ax,04[bp]
	mov	dx,ds
	cmp	ax,total_length
	jbe	farptr_10
ifndef WATCOMC
	sub	ax,total_length
endif
	mov	dx,cs
farptr_10:
	mov	bx,dx
	pop	bp
	ret

ifdef DLS
	public	_msgfarptr
_msgfarptr:
	push	bp
	mov	bp,sp
	mov	ax,04[bp]
	add	ax,offset CGROUP:_MSG
	mov	dx,cs
	mov	bx,dx
	pop	bp
	ret
endif

; We need some additional support for the CMD_LIST - it contains near pointers
; to other items in the CGROUP. This routine turns a NEAR pointer into a FAR
; pointer.
	public	_cgroupptr
_cgroupptr:
	push	bp
	mov	bp,sp
	mov	ax,04[bp]
	mov	dx,cs
	mov	bx,dx
	pop	bp
	ret

ifdef DLS

;/* Get the address of the msg_language variable in the DR BDOS. */
;GLOBAL BYTE FAR	* CDECL get_msg_lang()

	public	_get_msg_lang
_get_msg_lang:
	mov	ax, 4458h		; IOCTL func: get ptr private data
	int	21h			; pointer returned in ES:BX
	 jc	_get_msg_lang_err	; skip if invalid function
	add	bx, 9			; DLS version byte at offset 9
	cmp	es:byte ptr [bx], 1	; correct version?
	 jne	_get_msg_lang_err	;  no - skip
	inc	bx			; DLS language byte at offset 10
	mov	ax,bx
	mov	dx,es			; return pointer in DX:AX
	ret

_get_msg_lang_err:
	mov	ax,codeOFFSET dummy_lang
	mov	dx,cs
	ret

dummy_lang	db	0		; default to primary language

endif

page

;
;	This following routine copies the initial command line from the PSP
;	into the CMDLINE data area. Processing any special switches and
;	adding a terminating null character. The offset of the copy is
;	returned in AX.
;

get_cmdline:
	mov	di,heap_top			; copy cmdline onto the heap
	push	ds				; Preserve DS and point to PSP
	mov	ds,__psp2			; Get the PSP address
	xor	cx,cx				; Now copy the command line
	mov	cl,ds:0080h			; Get the Command length
	mov	si,0081h			; and its start location
	 jcxz	get_cmdl20
get_cmdl10:
	lodsb					; Terminate the copy after
	cmp	al,0Dh				; CX bytes or earlier if a
	jz	get_cmdl20			; CR or LF character is found.
	cmp	al,0Ah				; FrameWork Install Program and
	jz	get_cmdl20			; Bitstream FontWare
	stosb
	loop	get_cmdl10

get_cmdl20:	
	xor	al,al				; Zero Terminate the command
	stosb					; line copy for C.
	pop	ds
	mov	ax,di				; new bottom of heap
	xchg	ax,heap_top			; return old one = cmdline
	ret

;
;	This routine will install the DS relative dummy INT 2E handler with
;	a PSP:XXXX entry in the interrupt vector table. A JMPF is coded
;	after the handler entry point inorder to correct CS.
;
	Public	_install_perm
_install_perm:
	push	es
	mov	ax,__psp2			; Modify the INT 22 and 2E
	mov	es,ax				; vectors if the current process
	cmp	ax,PSP_PARENT			; is the ROOT DOS process. ie
	jnz	inst_p10			; PSP_PARENT == PSP

	mov	al,2Eh				; Install the Command Processor
	mov	dx,dataOFFSET int2E_entry	; Backdoor entry
	call	inst_p30

	mov	al,22h				; Update the Command Processor
	mov	dx,dataOFFSET int22_entry	; Terminate address
	call	inst_p30

	push	ds				; When this is the ROOT process
	push	si				; then update the PSP copies of
	push	di				; interrupt vectors 22, 23, 24
	push	ds				; because some TSR management
	pop	es				; programs examine these variables
	lea	di,psp_save_area		; ES:DI -> save area for PSP
	mov	ds,__psp2
	lea	si,PSP_TERM_IP			; DS:SI -> data in PSP to save
	mov	cx,6
	rep	movsw				; save the data for later EXIT
	push	ds
	pop	es
	lea	di,PSP_TERM_IP			; ES:DI -> PSP
	mov	ds,cx
	mov	si,022h * 4			; DS:SI	-> real interrupt vecs
	mov	cx,6
	rep	movsw
	pop	di
	pop	si
	pop	ds

inst_p10:
	pop	es
	ret

inst_p30:
	push	ds
	mov	bx,[low_seg]
	sub	bx,__psp2		; Calculate the correct offset for
	mov	cl,4			; the interrupt handler if the segment
	shl	bx,cl			; must be that of our PSP
	add	dx,bx
	mov	ds,__psp2
	mov	ah,MS_S_SETINT
	int	DOS_INT
	pop	ds
	ret

page
;
;	This routine will restore the Int 22 terminate address copy in
;	the PSP in preperation for an EXIT (DeskView bug).
;
	Public	_restore_term_addr
_restore_term_addr:
	push	es
	mov	ax,__psp2			; Restore the PSP we altered
	mov	es,ax				; if the current process
	cmp	ax,PSP_PARENT			; is the ROOT DOS process. ie
	 jne	restore_ta10			; PSP_PARENT == PSP

	push	si
	push	di
	lea	si,psp_save_area
	lea	di,PSP_TERM_IP
	mov	cx,6
	rep	movsw
	pop	di
	pop	si

restore_ta10:
	pop	es
	ret

page
;
;	This routine will restore the Novell error mode - BAP
;	
	Public	_restore_error_mode
_restore_error_mode:
	mov	dl,net_error_mode
	mov	ah,0ddh			; set error mode to the value
	int	21h			; it was when COMMAND was
	ret				; executed

page
;
;	MASTER_ENV will create a Master Environment of 04[bp] bytes unless
;	the environment is already larger in which case the environment
;	is increased by 128 bytes.
;
	Public	_master_env
_master_env:
	push	bp
	mov	bp,sp
	push	si
	push	di
	push	es
	mov	bx,04[bp]		; Save the Specified Size
	add	bx,15			; and force it to be an integer 
	and	bx,not 15		; multiple of 16
	mov	es,__psp2		; Get the PSP Segment Address
	
	mov	cx,PSP_ENVIRON		; Get the environment segemnt
	jcxz	master_env10		; Have we been loaded by DesQview ?

	mov	es,cx			; Scan through the environment and
	xor	di,di			; determine the Environment size and
	xor	ax,ax			; the Load file name
	mov	cx,7FFFh

master_env05:
	repne	scasb			; Scan for a ZERO byte
	jcxz	master_env10		; Abort if maximum size exceeded
	inc	di			; Check if the next character was a 0
	cmp	al,es:-1[di]		; if YES then this is the end of the
	jnz	master_env05		; environment
	mov	cx,di			; Calculate the environment Size
;
;	CX contains the current environment size in bytes. 0 for a DesQview
;	system or an empty environment.
;
master_env10:	
	cmp	bx,cx			; Is the current environment larger
	jae	master_env15		; No allocate requested value
	mov	bx,128
	add	bx,cx

master_env15:
	push	cx			; Save current Environment Size
	mov	cl,4			; convert request to paragraphs
	shr	bx,cl
	mov	ah,MS_M_ALLOC		; Allocate Memory
	int	DOS_INT
	pop	cx
	jc	master_env30		; Abort Memory Allocation Failed

	mov	es,__psp2		; Copy the Environemt
	xchg	ax,PSP_ENVIRON		; Update the Environment Pointer
	push	ds
	mov	ds,ax			; DS -> Initial Environment
	mov	es,PSP_ENVIRON		; ES -> Master Environment
	mov	si,0
	mov	di,si
	jcxz	master_env20		; If this was a Desqview exec then
	rep	movsb			; skip the environment copy and
					; just initialize to 0000
					; Invalidate the contents of the
	not	ds:word ptr 00h		; current environment so Novell
					; Netware finds the correct Master

master_env20:
	pop	ds
	xor	ax,ax
	stosw

master_env30:
	pop	es
	pop	di
	pop	si
	pop	bp
	ret

	page
;
;	BOOLEAN CDECL int10_cls();
;
;	int10_cls will return TRUE if it issued an INT10 function to
;	clear the screen.
;
	Public	_int10_cls
_int10_cls:
	push	bp
	push	si
	push	di
	push	es
	mov	ax,(MS_X_IOCTL*256)+0	; Get the device attributes for
	mov	bx,STDOUT		; STDOUT
	int	DOS_INT
	mov	ax,0000			; Assume that the test fails
	 jc	int10_exit		; and return FALSE to the caller
	and	dl,092h			; Check that STDOUT is the Console
	cmp	dl,092h			; Out DEVICE and it supports INT29
	 jnz	int10_exit		; Fast output

	;;mov	es,ax			; Now check that the INT29 routine
	;;mov	bx,es:word ptr (29h*4)+2; is below the INT20 service routine
	;;cmp	bx,es:word ptr (20h*4)+2; ie that this is a BIOS device driver
	;; jae	int10_exit		; No way Jose
					; So what if it isn't?

	mov	ax,1A00h		; ANSI.SYS installation check
	int	2Fh			; AL = FF on return if ANSI installed
	cbw				; AX = FFFF if ANSI present
	inc	ax			; AX = 0 if ANSI present
	 jz	int10_exit


;	get number of lines

	call	cginfo			; get screen resolution
	push	dx			; screen lines

	mov	ah, 0fh			; get mode
	int	10h
	and	al,7fh
	mov	ah, 0			; set mode, clear screen (al bit 7 clear)
	int	10h

	push	es
	mov	ah,52h			; get List of Lists address
	int	21h
	les	bx,F52_CONDEV		; address of console device driver
	mov	ax,es:24[bx]		; COLOUR command active?
	cmp	al,01
	 jne	int10_cls10		; no, then skip
	push	ax
	mov	bh,es:26[bx]		; colour of the border
	mov	ax,1001h		; set border colour
	int	10h
	pop	ax
	mov	dx,40h			; BIOS data segment
	mov	es,dx
	xor	bx,bx
	xor	cx,cx
	push	bp
	mov	bp,sp
	mov	dh,4[bp]
	pop	bp
;	mov	dh,byte ptr es:84h[bx]
	mov	dl,byte ptr es:4ah[bx]
	dec	dl
	mov	bh,ah			; character colour
	mov	ax,600h
	int	10h

int10_cls10:
	pop	es
	call	cginfo			; has resolution changed?
	pop	ax			; restore screen lines

	cmp	al, dl			; has # of screen lines changed?
	 je	int10_done		; skip if still the same
	
	mov	ax, 1112h		; character generator
	mov	bl, 0			; set 8x8 double dot font
	int	10h
	
	mov	ax, 1103h		; set block specifier
	mov	bl, 0
	int	10h

int10_done:	
	mov	ax,1			; All done

int10_exit:
	pop	es
	pop	di
	pop	si
	pop	bp
	ret

cginfo:
	mov	dl, 24			; assume default # for CGA/MDA
	mov	ax, 1130h		; character generator info
	mov	bh, 0
	int	10h
	ret				; dl = nlines - 1

_TEXT	ENDS

	page

_TEXT	SEGMENT
	public	_show_help
	public	_put_resident_high
	public	_get_config_env	
	public	_get_original_envsize		; BAP added this

_show_help	PROC NEAR
;
;	VOID	show_help(index)
;	WORD	index
;
	;out	0fdh,al

	push	bp
	mov	bp,sp
	sub	sp,20			; require 20 bytes of local space
	
	mov	ah,MS_M_ALLOC		; allocate memory for the help text
	mov	bx,help_length		; bx = no. paragraphs
	mov	cl,4
	shr	bx,cl
	int	DOS_INT			; do it
	jnc	show_help_05
	jmp	show_help_err0		; exit on error
show_help_05:
	mov	-2[bp],ax		; save segment of allocated memory

	push	ds
	mov	ds,[low_seg]
	mov	dx,dataOFFSET reload_file
	mov	ax,(MS_X_OPEN*256)+0	; Open the COMMAND.COM file
	int	DOS_INT			; do it
	pop	ds
	jc	show_help_err1		; exit on error
	mov	bx,ax			; bx = file handle
	mov	-4[bp],ax		; save handle for later
	xor	dx,dx
	cmp	exe_file,TRUE		; if command.com is an EXE file take
	jne	show_help_10		; account of the EXE header

	  ; read .EXE header size
	mov	ah,MS_X_READ		; read from COMMAND.COM file
	lea	dx,-20[bp]		; 16-byte data buffer
	push	ds
	push	ss
	pop	ds			; point DS to data buffer on stack
	mov	cx,16			; cx = no. bytes required
	int	DOS_INT			; do it
	pop	ds
	mov	dx,-12[bp]		; read header size in paragraphs
	jc	show_help_err2		; exit on error
	mov	cl,4
	shl	dx,cl			; DX now contains EXE header size

show_help_10:
	xor	cx,cx
	add	dx,total_length
	add	dx,cgroup_length
	add	dx,cend_length		; dx = file offset of help text
	mov	ax,(MS_X_LSEEK*256)+0	; seek to the right location
	mov	bx,-4[bp]		; bx = file handle
	int	DOS_INT			; do it
	jc	show_help_err2		; exit on error
	
	push	ds
	mov	ds,-2[bp]		; ds = help text segment
	xor	dx,dx			; dx = 0; 
	mov	ah,MS_X_READ		; read from COMMAND.COM file
	mov	cx,help_length		; cx = no. bytes required
	int	DOS_INT			; do it
	pop	ds
	jc	show_help_err2		; exit on error
	cmp	ax,0			; zero bytes read means there's no
	je	show_help_err2		; help seg tagged to file.

ifdef DLS
	call	_get_msg_lang		; get a far pointer to msg_language var
	mov	es,dx			; dx:ax = far pointer on return
	mov	bx,ax			;
	mov	bx,es:[bx]		; bx = msg_language
	shl	bx,1			; multiply bx by 2
else
	xor	bx,bx			; bx = 0
endif
	mov	es,-2[bp]		; ds = help text segment
	mov	bx,es:[bx]		; bx -> help message offset table
	mov	ax,4[bp]		; ax = message index
	shl	ax,1			; multiply by 2
	add	bx,ax			; bx -> offset of required message
	mov	bx,es:[bx]		; bx -> message

	call	write_string		; display the message

show_help_err2:
	mov	ah,MS_X_CLOSE		; close the file
	mov	bx,-4[bp]		; bx = file handle
	int	DOS_INT			; do it

show_help_err1:
	mov	ah,MS_M_FREE		; free the memory
	push	es
	mov	es,-2[bp]		; es = segment to free
	int	DOS_INT			; do it
	pop	es
	
show_help_err0:
	add	sp,20
	pop	bp
	ret


write_string:
	;extrn	_str:byte
	
	; es -> help segment
	; bx -> message in help segment

write_string_00:
	;mov	di,dataOFFSET _str	; di -> local buffer
	mov	di,[heap_top]
write_string_05:
	mov	al,es:[bx]		; get a character
	cmp	al,0ah			; check for NEWLINE...
	jnz	write_string_10		; ...jump if its not
		
	mov	al,0dh			; replace LF with CR LF
	mov	[di],al			; 
	inc	di			; 
	mov	al,0ah			;
	mov	[di],al			; 
	inc	di			;
	mov	al,0			;
	mov	[di],al			; terminate string
	call	flush_buff		; display it
	inc	bx			;
	jmp	write_string_00		; start again

write_string_10:
	cmp	al,0			; check for NULL...
	jnz	write_string_20		; ...jump if its not
	
	mov	[di],al			; store char
	call	flush_buff		; display string
	jmp	write_string_90		; exit

write_string_20:
	cmp	al,'%'			; messages have doubled %'s because
	jnz	write_string_30		; were intended for printf originally.
	inc	bx			; => skip next character.
write_string_30:
	mov	[di],al			; store char
	inc	di			;			
	inc	bx			;
	jmp	write_string_05		; loop

write_string_90:
	ret

flush_buff:
	push es
	extrn	strlen_:near
	extrn	c_write_:near

	;mov	ax,dataOFFSET _str	; watcom C requites first param in AX
	mov	ax,[heap_top]
	call	strlen_			; get length of string
	mov	dx,ax			; watcom C requires second param in DX
	;mov	ax,dataOFFSET _str	; watcom C requires first param in AX
	mov	ax,[heap_top]
	call	c_write_		; display the string
	pop es
	ret

_show_help	ENDP



try_high_memory		PROC NEAR
; This function attempts to allocate some high memory at FFFF:E0 by modifying
; the HIMEM FREE CHAIN maintained by the BDOS.
; on entry: bx = no. paras required (preserved)
; on exit:  Carry Set = unsuccessful
;           otherwise
;           ax = FFFF = segment of allocated memory
;           HIMEM Free Chain is modified.
  

	push	ds
	push	es
	push	bx
	
	mov	cl,4		; multiplying bx by 4...
	shl	bx,cl		; ...gives memory required in bytes
	mov	dx,bx		; put it in dx because bx is used for
				; somthing else


	add	dx,HISEG_OFF

	mov	ax,4458h	; get private data area
	int	DOS_INT		; do it
	mov	si,es:10h[bx]	; ax = start of HIMEM Free Chain
	test	si,si		; zero means there's no chain so...
	je	thm_unsuccessful; ...return unsuccessful

	mov	ax,0FFFFh	;
	mov	ds,ax		; ds:si -> first free himem area
	
	cmp	si,HISEG_OFF	; check if area starts at or below HISEG_OFF
	ja	thm_unsuccessful; ...return unsuccessful	
	mov	cx,2[si]	; CX = length of free area
	cmp	cx,dx		; check if length >= that required
	jb	thm_unsuccessful; ...return unsuccessful	

	mov	ax,[si]		; assume we will use the entire block
	mov	es:10h[bx],ax	;  so unlink it from the chain

	mov	di,HISEG_OFF	; generate HIMEM REGISTRATION link and
	mov	ax,di		;  update root in private data area
	xchg	ax,es:14h[bx]
	mov	[di],ax
	mov	2[di],dx	; remember how much we have used

; JBM commented this line out, I put it back in. (BAP)
	sub	2[di],di
; see above comment (JBM)

	sub	cx,dx		; subtract amount used from actual size
	cmp	cx,256		; if less than 256 bytes are left
	jb	thm_success	;  then just forget about them

	mov	si,di		; there is enough to be worth recyling
	add	si,dx		; SI -> free block following allocation
	mov	2[si],cx	; it's this long
	mov	ax,si
	xchg	ax,es:10h[bx]	; put at head of HMA free chain
	mov	[si],ax
thm_success:
	mov	ax,0ffffh	; return success
	clc			;
	jmp	thm_exit	;
	
thm_unsuccessful:
	stc			; return failure
thm_exit:
	pop	bx
	pop	es
	pop	ds
	ret

try_high_memory		ENDP


_put_resident_high	PROC NEAR
;
;	VOID	put_resident_high(param)
;	WORD	param;
;	
;	param = 0	Try HIGH memory, then UPPER memory
;	param = 1	Only try HIGH memory
;	param = 2	Only try UPPER memory
;

PRH_PARAM	equ word ptr 4[bp]

	push	bp
	mov	bp,sp
	push	si
	push	di

	
	mov	ax,(MS_M_STRATEGY*256)+2
	int	DOS_INT			; get existing HMA link
	mov	ah,0
	push	ax			; save it
	mov	bx,total_length		; get size of resident code/data
	sub	bx,(dataOFFSET hi_seg_start)-15
	mov	cl,4			; subtract size of low memory stub
	shr	bx,cl			; bx = block size in paras.

	cmp	PRH_PARAM,2		; skip the next bit if we're only 
	je	prh_upper		; looking at UPPER memory

	call	try_high_memory		; first try to allocate high memory
					; ie seg FFFF
	jnc	prh_success		; jump if successful

	cmp	PRH_PARAM,0		; if we're only looking at HIGH memory
	jne	prh_exit		; then we exit now

prh_upper:
	push	bx			; save length
	mov	ax,(MS_M_STRATEGY*256)+1
	mov	bx,41h			; set memory strategy to best fit
	int	DOS_INT			;  upper only
	mov	ax,(MS_M_STRATEGY*256)+3
	mov	bx,1			; try to link in upper memory
	int	DOS_INT
	pop	bx			; recover length
	 jc	prh_exit		; no upper memory, stop now

	mov	ah,MS_M_ALLOC		; allocate some memory
	int	DOS_INT			; do it
	 jc	prh_exit		; no upper memory, stop now

	sub	ax,HISEG_OFF/16		; bias segment appropriately

prh_success:
;	AX = segment to relocate to
;
	mov	es,ax			; es = new block
	
	mov	si,dataOFFSET hi_seg_start ; start at R_TEXT segment
	mov	di,si

	mov	cx,total_length		; get size of resident code/data
	sub	cx,si			; subtract size of low memory stub

	mov	[reloc_seg],ax		; These values in the low memory
	mov	[reloc_off],di		; stub are used by TaskMAX to find
	mov	[reloc_size],cx		; the relocated code/data


	mov	[data_seg],ax		; update data_seg variable
	mov	[exec_seg],ax		; and some others...
	mov	[readline_seg],ax
	mov	[func4b_seg],ax
	mov	[int2E_seg],ax
	mov	ds:word ptr [control_break_entry+3],ax
	mov	ds:word ptr [crit_error_entry+3],ax

	add	si,4			; take account of HIMEM
	add	di,4			; REGISTRATION link
	sub	cx,4	

	rep	movsb			; move'em
	
	mov	bx,ds
	sub	bx,[__psp2]		; ax = difference between psp and data
	add	bx,HISEG_OFF/16		; add size of bit we leave behind

	mov	es,[__psp2]		; es -> old location	

	mov	ds,ax			; this is the new data seg
	mov	ss,ax			; and also the new stack seg

	mov	ah,MS_M_SETBLOCK	; modify old segment size 
	int	DOS_INT			; do it

prh_exit:
	pop	bx			; recover upper memory link
	mov	ax,(MS_M_STRATEGY*256)+3
	int	DOS_INT			; restore to original state

	mov	ax,(MS_M_STRATEGY*256)+1
	xor	bx,bx			; set memory strategy to first fit
	int	DOS_INT

	
	pop	di
	pop	si
	pop	bp

	ret

_put_resident_high	ENDP


_get_config_env		PROC NEAR

	; BYTE	FAR *get_config_env();
	; This function returns a pointer to the start of the config.sys
	; environment.
	
	mov	ax,4458h	; get pointer to private data
	int	DOS_INT		; do it
	mov	ax,0		; es:bx -> private data
	 jc	get_cfg_env10
	xchg	ax,es:18[bx]	; ax = segment of config environment
get_cfg_env10:
	mov	bx,ax		; return FARNULL (0000:0000)
	mov	dx,ax	
	xor	ax,ax
	ret

_get_config_env		ENDP


; BAP - This routine finds the orignal COMMAND.COM's environment size.
; This may not be the best way of doing it .. !
; It finds the PSP of the original COMMAND.COM by checking the PSP seg
; against the parent PSP seg. If they are not the same, it repeats for
; the parent. When they are the same, it has found the original COMMAND
; and finds the environment size.

_get_original_envsize	PROC	NEAR
	push	bp
	mov	bp,sp
	push	si
	push	di
	push	es
	push	cx
	mov	ah,51h
	int	DOS_INT			; get current PSP seg
try_next:
	mov	es,bx
	mov	cx,bx			; move into CX
	mov	bx,0
	mov	ax,es:16h[bx]		; get parent PSP seg in ax
	cmp	ax,cx			; are they the same ?
	je	got_org_psp		; yes - found COMMAND.COM PSP
	cmp	ax,0			; on MS-DOS parent PSP seg=0
	je	null_org_psp
	mov	bx,ax			; else make this current seg and
	jmp	try_next		; try again
null_org_psp:
	mov	ax,cx
got_org_psp:
	mov	es,ax			; ES = COMMAND.COM PSP seg
	mov	bx,0
	mov	ax,es:2ch[bx]		; get env seg in ax
	cmp	ax,0			; seg = 0000 ?
	je	bomb_out		; yes - forget it
	dec	ax			; AX:0000 points to memory descriptor
	mov	es,ax
	mov	ax,es:3[bx]		; find length of seg ( in paras)
	mov	cl,4
	shl	ax,cl			; convert to bytes
bomb_out:
	mov	bx,ax
	mov	dx,ax
	pop	cx
	pop	es
	pop	di
	pop	si
	pop	bp
	ret
_get_original_envsize	ENDP


_TEXT	ENDS


R_TEXT	SEGMENT
	extrn	_out_pipe:byte
	extrn	_kbdbuf:byte
R_TEXT		ENDS

_TEXT	SEGMENT

	public	_get_reload_file
_get_reload_file:

; copy reload_file to heap

	push	ds
	push	es
	push	si
	push	di

	;mov	ax,0e40h
	;int	10h

	mov	ax,ds
	mov	es,ax
	mov	ds,[low_seg]
	mov	di,[heap_top]
	mov	si,offset reload_file
	cld
grf_loop:
	lodsb
	stosb
	cmp	al,0
	jnz	grf_loop	

	pop	di
	pop	si
	pop	es
	pop	ds
	ret
	
	public	_set_reload_file
_set_reload_file:

; copy string on heap to reload file

	push	es
	push	si
	push	di

	;mov	ax,0e40h
	;int	10h

	mov	es,[low_seg]
	mov	si,[heap_top]
	mov	di,offset reload_file
	cld
srf_loop:
	lodsb
	stosb	

	cmp	al,20h			; BAP from here
	jne	srf_brian		; if AL = 20h, poke a 00
	xor	al,al			; in instead, to terminate
	dec	di			; the file. COMSPEC can then have
	stosb				; switches, but reload_file is
srf_brian:				; just the file name.

	cmp	al,0
	jnz	srf_loop

	pop	di
	pop	si
	pop	es
	ret

	public	_get_out_pipe
_get_out_pipe:

; copy out_pipe filename from low_seg to data seg

	push	ds
	push	es
	push	si
	push	di

	;mov	ax,0e40h
	;int	10h

	mov	ax,ds
	mov	es,ax
	mov	di,offset DGROUP:_out_pipe
	
	mov	ds,[low_seg]
	mov	si,offset out_pipe
	
	mov	cx,8
	cld
	rep	movsb	

	pop	di
	pop	si
	pop	es
	pop	ds
	ret

	public	_docmd_int2f
;
;	BOOLEAN	docmd_int2f(BYTE *cmdline, BYTE *cmd, UWORD count);
;
;	cmdline	db	max, actual, 'COMMAND LINE', CR
;	cmd	db	length, 'COMMAND', CR
;	count	db	remaining length of tail, FF/00 internal/external flag
;
;	

_docmd_int2f:

	push	bp
	mov	bp,sp
	push	bx
	push	si

	mov	bx,4[bp]			; bx -> original command line
	mov	si,6[bp]			; si -> upper cased command
	mov	cx,8[bp]
	mov	dx,0ffffh
	
	mov	ax,0AE00h
	int	2fh	
	
	test	al,al
	 jz	docmd_int2f_exit

	mov	bx,4[bp]
	mov	si,6[bp]
	mov	cx,8[bp]
	mov	dx,0ffffh
	
	mov	ax,0AE01h
	int	2fh
	mov	al,1
docmd_int2f_exit:
	cbw				; return true if handled
	pop	si
	pop	bx
	pop	bp
	mov	bx,ax
	mov	dx,ax
	ret

_TEXT	ENDS

	end				; start address
