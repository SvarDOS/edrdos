;    File              : $NETWORK.A86$
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
;    ENDLOG
;
;   DOS Network Function Calls

	include	pcmode.equ
	include	i:mserror.equ
	include	i:redir.equ
	include	i:doshndl.def

PCM_CODE	CSEG	BYTE

	extrn	reload_ES:near
	extrn	return_AX_CLC:near
	extrn	return_CX:near
	extrn	error_exit:near
	extrn	get_ldt_raw:near

;	*****************************
;	***    DOS Function 5E    ***
;	***    Get Machine Name   ***
;	*****************************
;
	Public	func5E
func5E:
	cmp al,1 ! jb f5E00		; Get Machine Name Sub-Function
		   je f5E01		; Set Machine Name Sub-Function
	mov	ax,I2F_REDIR_5E	; magic int 2F number
	jmp	func5F_common		; use common routine
;
;	Get the current Machine Name
;
f5E00:
	mov	di,dx			; Copy the 15 Byte Network Name
	mov	si,offset net_name	
	mov	cx,16/2
	rep	movsw
;	mov	ch,name_num		; 00 -> Undefined Name
;	mov	cl,netbios		; 00 -> Name Number
	mov	cx,word ptr netbios
	call	return_CX
f5E_success:
	xor	ax,ax			; return zero
	jmp	return_AX_CLC

;
;	Set the Network Name
;
f5E01:
;	mov	name_num,ch		; Get the Network and NetBios Nos.
;	mov	netbios,cl		; and save in local variables
	mov	word ptr netbios,cx
	inc	net_set_count
	push ds ! push es
	pop ds ! pop es			; Copy the specified name
	mov	si,dx			; to internal save area
	mov	di,offset net_name
	mov	cx,15			; Copy 15 byte name leave
	rep	movsb			; Terminating 00
	push es ! pop ds
	jmps	f5E_success


;	*****************************
;	***    DOS Function 5F    ***
;	***    Network Control    ***
;	*****************************
;
	Public	func5F
func5F:
	cmp	al,07h
	 je	func5F_10
	cmp	al,08h
	 jne	func5F_40
func5F_10:
	push	ax
	mov	al,dl
	call	get_ldt_raw
	pop	ax
	 jc	func5F_30
	cmp	es:word ptr LDT_PDT[bx],1
	 jb	func5F_30
	or	es:byte ptr LDT_FLAGS+1[bx],LFLG_PHYSICAL/100h
	cmp	al,07h
	 je	func5F_30
	and	es:byte ptr LDT_FLAGS+1[bx],(not LFLG_PHYSICAL)/100h
func5F_30:
	jnc	func5F_OK
	mov	ax,ED_DRIVE
	jmp	error_exit

func5F_40:
	mov	ax,I2F_REDIR_5F	; magic int 2F number

Public	func5F_common
func5F_common:
	push	ds
	push	int21AX			; AX passed on the stack..
	push	es
	call	reload_ES		; get the segment registers
	pop	ds			;  back to entry state
	stc				; assume it will fail
	int	2fh			; pass it on to MSNET
	pop	ds			; throw away word on the stack
	pop	ds
	 jc	func5F_error
func5F_OK:
	jmp	return_AX_CLC		;  return the result
func5F_error:
	neg	ax			; our error convention is negative..
	jmp	error_exit		; Error for all sub functions

PCMODE_DATA	DSEG	WORD

	extrn	net_name:byte
	extrn	net_set_count:byte
	extrn	name_num:byte
	extrn	netbios:byte
	extrn	int21AX:word

end
