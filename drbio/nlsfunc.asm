;    File              : $NLSFUNC.ASM$
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
;    NLSFUNC.A86 1.6 93/12/01 18:30:10 
;    Read in full 258 bytes of collating info
;    ENDLOG

;
; We have a problem with NLSFUNC.EXE - if this isn't loaded with an INSTALL=
; in CONFIG.SYS then the calls to set language/codepage will fail.
; So we provide the same functionality that NLSFUNC.EXE does here in the
; initialisation code. "nls_hook" is called by CONFIG before the country is
; set, then "nls_unhook" is called afterwards so we can throw away this code.
;

VALID_SIG	equ	0EDC1h	; valid signature in COUNTRY.SYS file

DH_NEXT		equ	ds:dword ptr 0		; Dword Pointer to Next DEV
DH_ATTRIB	equ	ds:word ptr 4		; device attribute bits
DH_NAME		equ	ds:byte ptr 10		; 8-BYTE device name

DA_CHARDEV	equ	8000h		; 1=character device, 0=block device
DA_IOCTL	equ	4000h		; device supports IOCTL string I/O
DA_GETSET	equ	0040h		; supports 3.2 level functionality

	include	config.equ
	include	msdos.equ
	include	mserror.equ
	

CGROUP	GROUP	INITCODE
INITCODE	segment public byte 'INITCODE'

; We share our NLS buffer with other temporary users

	extrn	nls_temp_area:byte

	Public nls_hook, nls_unhook

nls_hook:
;--------
; On Entry:
;	none
; On Exit:
;	none
;
	push	es
	mov	ah,MS_S_GETINT
	mov	al,2fh
	int	DOS_INT			; read and save old INT 2F vector
	mov	old_int2f_off,bx
	mov	old_int2f_seg,es
	mov	ax,(MS_S_SETINT * 256) + 2fh
	mov	dx,offset cgroup:int2f_handler	; install our own INT 2F handler
	int	DOS_INT
	pop	es
	ret

nls_unhook:
;----------
; On Entry:
;	none
; On Exit:
;	none
;
	push	ds
	mov	dx,old_int2f_off
	mov	ds,old_int2f_seg
	mov	ah,MS_S_SETINT		; restore INT 2F vector
	mov	al,2fh
	int	DOS_INT
	pop	ds
	ret

old_int2f	label dword
old_int2f_off	dw	0
old_int2f_seg	dw	0

int2f_handler:
;-------------
	cmp	ah,014h		; is it for us ?
	 je	int2f_handler10
	jmp	dword ptr old_int2f	; no, pass it on

int2f_handler10:
	test	al,al		; installation check ?
	 jne	int2f_handler20
	mov	al,0ffh		; we are already installed
	iret

int2f_handler20:
	cmp	al,0ffh		; Codepage Prep ?
	 jne	int2f_handler30
	call	f66_prep
	retf	2		; iret, keeping flags
	
int2f_handler30:
	cmp	al,0feh		; Country Get Data ?
	 jne	int2f_handler40
	call	f65_locate_and_read
	retf	2		; iret, keeping flags
	
int2f_handler40:
	stc			; CY to indicate an error
	mov	ax,-ED_FUNCTION	; function not supported
	retf	2		; return an error


f66_cp		dw	0		; INT21/66 Local Variable
cp_packet	dw	2		; Packet Size
cp_cpid		dw	0		; Request CodePage
		db	0,0		; Packet Terminators

preperr		dw	0		; Prepare function Error Code
prepname	db	9 dup (0)		; Reserved for ASCIIZ Device Name

;
; Area for country.sys current pointer table 
; (these are all offsets into country.sys)
;
f65xx_code	dw	0	; Country code
f65xx_cp	dw	0	; Code page
		dw	0	; +1 reserved
f65xx_data	dw	0	; Data area
		dw	0	; Upper case table
		dw	0	; +1 reserved		
		dw	0	; Filename upper case table
		dw	0	; Legal file characters
		dw	0	; Collating table
		dw	0	; Double byte character set lead byte table
f65xx_ptable_len	equ	20

f65xx_codepage	dw	0
f65xx_country	dw	0
f65xx_sig	dw	0	; Signature
c_handle	dw	0


f66_prep:
;
;	This function scans the complete device list and prepares
;	all devices which support codepage.
;
;	On Entry	BX Requested CodePage
;
;	On Exit		AX Last Error Code
;
DA_CODEPAGE	equ	DA_CHARDEV+DA_IOCTL+DA_GETSET

	push	ds
	push	es
	push	cs
	pop	es
	mov	f66_cp,bx		; Save requested CodePage
	mov	preperr,0000		; Initialize Prepare Error
	mov	ax,122ch		; magic hook get Device List
	int	2fh			; after the NUL entry
	mov	ds,bx			; BX:AX -> header after INT 2F
	mov	bx,ax			; DS:BX -> header to be useful
f66_p10:
	push	ds
	push	bx
	mov	ax,DH_ATTRIB[bx]
	and	ax,DA_CODEPAGE		; Check for a Character Device which
	cmp	ax,DA_CODEPAGE		; supports IOCTL strings and GETSET
	 jnz	f66_p40			; otherwise skip the device

	lea	si,DH_NAME[bx]		; Found a matching device so
	mov	di,offset prepname	; open the device and select the 
	mov	cx,8			; requested codepage

f66_p20:
	lodsb
	cmp	al,' '
	 je	 f66_p30
	stosb
	loop	f66_p20

f66_p30:
	xor	al,al
	stosb	
	push	cs
	pop	ds
	mov	dx,offset prepname	; Write Access
	mov	cl,1			; Open for write
	mov	ax,1226h
	int	2fh			; call magic hook
	 jc	f66_perr
	mov	bx,ax			; Save Device Handle in BX

	mov	si,f66_cp		; Get Requested CodePage in SI
	mov	dx,offset cp_packet	; Offset of CodePage Struct
	mov	cx,006Ah		; Get Unknown CodePage
	push	bp
	mov	bp,0ch			; Generic IOCTL
	mov	ax,122bh
	int	2fh			; call magic hook
	pop	bp
	 jc	f66_p32			; Error so Select requested Code Page

	cmp	si,cp_cpid
	 je	f66_p35			; If this the currently selected
f66_p32:				; skip the select CodePage
	mov	cp_cpid,si
	mov	dx,offset cp_packet	; Offset of CodePage Struct
	mov	cx,004Ah		; Select Unkown CodePage
	push	bp
	mov	bp,0ch			; Generic IOCTL
	mov	ax,122bh
	int	2fh			; call magic hook
	pop	bp
	 jnc	f66_p35			; No Error so skip the error
f66_p33:
 	mov	preperr,ax		; save

f66_p35:	
	mov	ax,1227h
	int	2fh			; magic hook to close handle
	jmp	f66_p40

f66_perr:
	mov	preperr,ax		; Save the error code and try the
f66_p40:				; next device in the chain
	pop	bx			; Restore the Device offset
	pop	ds
	lds	bx,DH_NEXT[bx]		; check next character device for
	cmp	bx,0FFFFh		;  Codepage support
	 jne	f66_p10

	mov	ax,preperr		; All devices have been prepared
	pop	es
	pop	ds
	or	ax,ax			;  now return the last error code
	ret				;  in AX

;
;	**********************************************************************
;	***  Function 65 support - routines for seeking a country/codepage ***
;	***  and loading the required information into the temp data area  ***
;	**********************************************************************
;
;	**************************************************
;	***   Open country.sys and search for the      ***
;	***   table of offsets for the given country/  ***
;	***   codepage, read it in and exit.           ***
;	**************************************************

f65_locate_and_read:
;-------------------
;	Locate and Read info CL for Country DX Codepage BX using file DS:DI
	test	di,di			; valid filename ?
	stc
	 jz	f65_lr_exit

	push	cx
	call	f65x_find_info		; Will need to load up the info 
	pop	ax
	 jc	f65_lr_exit		; so do it if we can.

	mov	dx,offset nls_temp_area
	mov	cx,258			; read 258 bytes into local buffer
	push	ax
	call	f65x_load_info		; Load required info
	pop	ax
	 jc	f65_lr_exit
	mov	bx,c_handle 		; Close the file first
	mov	ax,1227h
	int	2fh			; magic hook to close handle
	 jc	f65_lr_exit
	mov	si,offset nls_temp_area	; Tell subroutines where info is
f65_lr_exit:
	ret
;
; Entry:  dx=country code, bx=codepage
; Exit :  carry set, and country.sys closed if failure
;         country.sys open ready for more reads if success
;
f65x_find_info:
	mov	f65xx_country,dx
	mov	f65xx_codepage,bx
	mov	dx,di
	xor	cx,cx			; Open for read
	mov	ax,1226h
	int	2fh			; call magic hook
	push	cs			; get DS pointing to this segment
	pop	ds			;  for future reads
	 jnc	f65x_10
	ret				; Successful open?
f65x_10:
	mov	c_handle,ax		; Save handle
	mov	dx,f65xx_country
	cmp	f65xx_code,dx		; do we already have the information?
	 jne	f65x_30			; No - get it from country.sys
f65x_20:
	cmp	f65xx_cp,bx		; Does codepage agree too?
	 je	f65x_35			; Yes so exit with no more ado
f65x_30:
	mov	dx,007Eh	
	xor	cx,cx			; Seek within country.sys
	mov	bx,c_handle
	push	bp
	xor	bp,bp			; seek from begining
	mov	ax,1228h
	int	2fh
	pop	bp
	 jc	f65x_err
	mov	bx,c_handle		; check them
	mov 	cx,2
	mov 	dx,offset f65xx_sig
	mov	ax,1229h
	int	2fh			; read the signature bytes
	 jc	f65x_err
	cmp	f65xx_sig,VALID_SIG
	 jne	f65x_err		; If signature bad exit
f65x_32:
	mov	bx,c_handle		; Read from country.sys header until
	mov	cx,f65xx_ptable_len	; Country/codepage found or NULL
	mov	dx,offset f65xx_code
	mov	ax,1229h
	int	2fh
	 jc	f65x_err	
	cmp	f65xx_code,0		; Found NULL so reqd combination
	 je	f65x_err		; was not found
	mov	dx,f65xx_code		; Get the country/codepage values
	mov	bx,f65xx_cp		; read from Country.SYS
	cmp	dx,f65xx_country	; Check against the requested
	 jne	f65x_32			; Country. 
	cmp	f65xx_codepage,0	; If a codepage match is not
	 jz	f65x_35			; then return success
	cmp	bx,f65xx_codepage	; Check against the requested
	 jne	f65x_32			; Codepage
f65x_35:
	mov	f65xx_country,dx	; Force the Search Country and
	mov	f65xx_codepage,bx	; CodePage to be Updated
	ret

f65x_err:
	mov	bx,c_handle 		; and set the carry flag before
	mov	ax,1227h
	int	2fh			; magic hook to close handle
	stc
	ret

;
;	**************************************************
;	***   Load the type of information requested   ***
;	***   For the country currently active in the  ***
;	***   offset table			       ***
;	**************************************************
;
; Entry:  al=type of info, dx=offset of buffer to read info into cx=no of bytes
; Exit :  carry set, and country.sys closed if failure
;
f65x_load_info:
	push	es
	push	cx
	push	dx
	push	ds			; Make es=ds
	pop	es
	dec	al			; 1=Data , 2=uppercase, 4=fuppercase
	sub	bh,bh			; 5=filechars, 6=Collating table
	mov	bl,al			; 7=DBCS table
	shl	bx,1			; Retrieve relevant offset
	mov	dx,f65xx_data[bx]	
	xor	cx,cx			; Seek within country.sys
	mov	bx,c_handle
	push	bp
	mov	bp,0			; seek from begining
	mov	ax,1228h
	int	2fh
	pop	bp
	pop	dx			; Get buffer address back
	pop	cx			; and number of bytes to read
	 jc	f65x_err
	test	ax,ax			; zero offset is a problem
	 jz	f65x_err		; (probably DBCS with old COUNTRY.SYS)
	mov	bx,c_handle		; Now read that info into our data area
	mov	ax,1229h
	int	2fh
	 jc	f65x_err
	pop	es
	ret

INITCODE ENDS

	end
