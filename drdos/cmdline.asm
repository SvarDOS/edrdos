;    File              : $CMDLINE.A86$
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
;    CMDLINE.A86 1.8 93/03/25 15:06:03
;    tweak console block output
;    ENDLOG
;
; 	DOSPLUS Command Line Editor Routines
;

	.nolist
	include	pcmode.equ
	include	msdos.equ
	include char.def
	include	cmdline.equ
	include	request.equ
	include	driver.equ
	.list

PCMDATA group PCMODE_DATA,FDOS_DSEG
PCMCODE group PCM_CODE,PCM_RODATA

ASSUME DS:PCMDATA

EDIT_CNTRL	equ	cs:word ptr 0[bx]	; Character and Esc Flag
EDIT_FUNC	equ	cs:word ptr 2[bx]	; Edit Function Address
EDIT_LEN	equ	4			; Edit Table Entry Size

PCM_CODE	segment public byte 'CODE'
	public	read_line, edit_size

	extrn	dbcs_lead:near
	extrn	cmdline_read:near
	extrn	raw_read:near
	extrn	cooked_write:near
	extrn	get_dseg:near
	extrn	device_driver:near

; WARNING - the following routines are to support history buffers
; As these are optional we muset NEVER call these routines unless
; the HISTORY_ON bit is set in @hist_flag.

	extrn	init_history:near
	extrn	save_history:near
	extrn	prev_cmd:near
	extrn	next_cmd:near
	extrn	match_cmd:near
	extrn	search_cmd:near
	extrn	match_word:near
	extrn	del_cur_history_buffer:near
	extrn	del_history_buffers:near
	extrn	goto_eol:near
	extrn	next_word:near
	extrn	prev_word:near
	extrn	del_bol:near
	extrn	deln_word:near

; The following are public for HISTORY.PCM
	public	next_char, save_line
	public	space_out, bs_out, put_string
	public	goto_bol
	public	del_eol, del_line
	public	char_info
	public	prev_w20
	public	deln_w10


;	READ_LINE will read an editted line from the handle passed in BX
;	into a buffer with the following format:-
;
;	BYTE	Maximum String Length
;	BYTE	Current String Length
;	BYTE(s)	String Buffer
;
;	On Entry:-
;		BX		Input Handle
;		CX		Output Handle
;		ES:DX		Buffer Address
;
;	On Exit:-
;		String input by user
;
;	The following conventions apply for the READ_LINE function
;
;	ES	Buffer segment
;	SI	Current cursor location in buffer (Index)
;	DX	Last Character in Buffer (Index)
;
DISABLE		equ	80h	; Disable when advanced editing is off.
DISABLE_MASK	equ	8000h
ESC_CODE	equ	01h	; Scan code must be preceeded by escape byte.
NESC_CODE	equ	00h	; No lead zero needed.

read_line:
	push	bp			; Save the Stack Frame Pointer
	mov	bp,sp			; Intialise it to the top of the
	sub	sp,RL_LENGTH		; READ_LINE control block and reserve
					; control block
	mov	RL_INPUT,bx		; Initialize the INPUT Handle
	mov	RL_OUTPUT,cx		; the OUTPUT Handle
	inc 	dx
	inc 	dx			; Skip max and Returned Length
	mov	RL_BUFOFF,dx		; and save the buffer offset
	mov	RL_BUFSEG,es		;  and segment
	xor	ax,ax			; now we zero
	mov	RL_SAVPOS,ax		;  both position in it
	mov	RL_SAVMAX,ax		;  and it's size
	mov	al,column
	mov	RL_INICOL,ax		; save initial column
	mov	ax,cle_state		; use to set initial editing state
	and	ax,not (RLF_MATCH+RLF_DIRTY+RLF_RECALLED)
	mov	RL_FLAGS,ax		; save in flags
	test	ax,RLF_ENHANCED
	 jz	read_line10
	call	init_history		;  setup the history buffers
	jmp	read_line20
read_line10:
	and	RL_FLAGS,not RLF_INS	; clear insert mode
read_line20:
	mov	di,dx			; di -> buffer
	xor	bx,bx
	or	bl,es:byte ptr [di-2]	; Get the Maximum number of chars
	mov	RL_MAXLEN,bx		; and save for later
	 jnz	read_line30		; make sure some chars are requested
	jmp	ret_string10		; if no chars just return
	
ret_string:
	pop	ax			; Remove local return address
	mov	ax,RL_FLAGS		; get command line editor state
	mov	cle_state,ax		;  save state for next time
	mov	di,RL_BUFOFF		; Get the buffer Offset
	mov	es:byte ptr [di-1],dl	; Return the number of characters
	push	dx			; Save length of entry
	add	di,dx			; Point to the end of the buffer
	mov	al,CR
	stosb				; Save CR
	call	write_char		; Print a CR and return to the user
	pop	dx
	test	RL_FLAGS,RLF_ENHANCED	; Do not add to history if in
	 jz	ret_string10		; compatibility mode
	call	save_history		; Save state of history buffer
ret_string10:
	mov	sp,bp			; Remove READ_LINE control Block
	pop	bp			; Restore BP and return to the caller
	ret


read_line30:
	xor	si,si			; Currently at start of buffer
	mov	dx,si			; with an empty buffer.

	xor	bx,bx
	or	bl,es:byte ptr [di-1]	; Check if the buffer contains any
	 jz	read_line40		; data which is terminated by a CR
	cmp	es:byte ptr [bx+di],CR
	 jnz	read_line40
	mov	dx,bx
read_line40:
	call	save_line		; Update Save Buffer variables
	mov	dx,si
;
; This is out main command loop - we get a character and try to match it
; with a command in our edit_table. If History is on we look at commands
; with the DISABLED bit set ie. enhanced commands.
; It a match isn't found we insert the character in the buffer, and optionally
; try to match with previous lines in the history buffer.
;
read_line_loop:
	and	RL_FLAGS,not RLF_KANJI	; initial flags
	call	get_char		; read the first character (AH Esc Flg)

	mov	cx,edit_size		; now scan the control table looking
	mov	bx,offset edit_table	;  for a match
read_ll_next_cmd:
	and	ax,not DISABLE_MASK	; assume normal function
	test 	RL_FLAGS,RLF_ENHANCED	; compatibilty required? then it
	 jz 	read_ll10		;  has to be a normal function
	test	EDIT_CNTRL,DISABLE_MASK	; history enabled, so we make
	 jz	read_ll10		;  our code match DISABLE mask
	or	ax,DISABLE_MASK		;  of table entry
read_ll10:
	cmp	ax,EDIT_CNTRL		; check for a match (Escape Flag
	 je	read_ll_found_cmd	;  and the character)
	add	bx,EDIT_LEN		; Add the entry length
	loop	read_ll_next_cmd	; and scan the whole table

; We have failed to find a command so insert char in buffer

	test	ah,ESC_CODE		; Ignore non-matched escaped keys
	 jnz	read_line_loop

	call	save_char		; not an command so save the character
	or	RL_FLAGS,RLF_DIRTY	;  and remember we have something new

; Are we in search mode ?

	test 	RL_FLAGS,RLF_ENHANCED	; Compatibilty required?  
	 jz 	read_line_loop
	test	RL_FLAGS,RLF_SEARCH+RLF_MATCH
	 jz	read_line_loop		; is searching/matching on ?
	push	si			; save current offset
	call	search_cmd
	pop	ax			; this is our target offset
read_ll20:
	cmp	ax,si			; are we there yet ?
	 jae	read_line_loop
	push	ax			; no, keep rewinding cursor
	call	prev_char		;  until we reach position
	pop	ax			;  before we tried to match
	jmp	read_ll20

read_ll_found_cmd:			; get the address of the corresponding
	mov	cx,EDIT_FUNC		;  function from the table	
	call	cx			;  execute the correct function
	jmp	read_line_loop		;  and go back for next character

;
;	the SAVE_CHAR routine will write the character in AL into 
;	the buffer in memory and then update the screen image. The
;	RLF_INS flag is used to determine if INSERT is active.
;
save_c10:
	ret

save_char:
	cmp	ah,TRUE	and 0FFh	; Ignore any un-matched escape 
	jz	save_c10		; sequences
	call	save_kanji		; Test if AL is a Kanji Character
					; and setup up the parameter blocks
					; for the INTSAVE_CHAR routine
;
;	INTSAVE_CHAR is the internal entry point to the Character Save
;	routine. It assumes the following:-
;
;	On Entry:-	AX(AL)	    Contains the character
;			CX	    the new character length in bytes
;			RLF_KANJI   Flag is set for a Kanji Character
;			RL_KANJI    Contains the kanji charater
;			
intsave_char:
	mov	bx,cx
	test	RL_FLAGS,RLF_INS	; Overwrite the character in the
	 jnz	save_c50		; buffer currently
	add	bx,si			; Add the current index to the character
	cmp	bx,RL_MAXLEN		; size and compare against the buffer len
	 jae	bell_char		; Full ? Yes Ring dat Bell !

	cmp	dx,si			; Are we at the end of the line
	 jnz	intsave_c10		; No so check character types
	push 	ax
	push 	cx
	call	skip_one_char		; Skip the coresponding character in
	pop 	cx
	pop 	ax			; the save buffer
	jmp	simple_save

intsave_c10:
	push	ax			; Save the Input Character
	call	char_type		; Get the character type
	mov	bx,ax			; and save in BX
	mov	al,es:[di]		; get the byte to be replaced
	call	char_type		; and get its type
	and	ah,CHAR_SIZE		; Mask the Character SIZE attributes
	and	bh,CHAR_SIZE		; and check both storage and display
					; sizes are the same for old and new
	cmp	ah,bh			; and do simple save if the character
	pop	ax			; Restore the input character to AX(AL)
	 jnz	save_c30		; type match
	sub	dx,cx			; Character overwritten so prevent
					; Max Index being incremented

simple_save:
	add	si,cx			; Assume at the EOL
	add	dx,cx
	stosb				; Save the character typed
	test	RL_FLAGS,RLF_KANJI	; is this a Kanji character
	 jz	simple_s10		; No so just output 1 character
	call	put_char		; and echo it to the user
	mov	al,byte ptr RL_KANJI+1	; Get the high byte of the Kanji
	stosb				; character save and then display it.
simple_s10:
	jmp	put_char
;	ret

;
;	The SAVE_C30 function supports the Complex overwrite conditions
;	where the size of the character in memory or on the display do not
;	match with those of the present incumbent. eg a SPACE character
;	overwriting a TAB or a KANJI character overwriting a SPACE.
;
;	To minimize the complexity of the code the character to be 
;	overwritten is deleted and the new character then inserted.
;	This is not an optimal solution but drastically reduces the
;	amount of code required.
;
save_c30:
	push 	ax
	push 	cx
	call	deln_char
	pop 	cx
	pop 	ax
	cmp	dx,si
	 jz	simple_save
	or	RL_FLAGS,RLF_INS
	call	save_c50
	and	RL_FLAGS,not RLF_INS
	ret

bell_char:
	mov	al,BELL
	jmp	write_char
;
;	This code is called when INSERT mode is active and a 
;	character (possibly Kanji) is to be inserted in the buffer
;
;	On Entry:-	CX	    the new character length in bytes
;
save_c50:
	mov	bx,cx			; Save new character length
	add	cx,dx			; Add the current max to the character
	cmp	cx,RL_MAXLEN		; size and compare against the buffer len
	 jae	bell_char		; Full ? Yes Ring dat Bell !
	mov	cx,bx			; Restore Character Length
	cmp	dx,si			; If we are at the end of the line
	 je	simple_save		; Use the simple save code
;
;	Create space in the current buffer for the new character
;
	push 	ds
	push 	si
	push 	di
	mov 	cx,dx
	sub 	cx,si			; CX -> Number of bytes to move
	mov 	di,dx
	add 	di,RL_BUFOFF		; DI -> End of Destination Offset
	add 	di,bx
	dec 	di			;    -> + Insert Char len - 1
	mov 	si,di
	sub 	si,bx			; SI -> DI - Insert Char Len
	push 	es
	pop 	ds			; DS == ES
	std				; Make the right amount of space in
	rep	movsb			; the buffer	
	cld
	pop 	di
	pop 	si
	pop	ds

	add	dx,bx			; Update the Buffer Length
	stosb				; Save the New character
	test	RL_FLAGS,RLF_KANJI	; Check if this was a Kanji Character
	 jz	save_c60		; No
	xchg 	al,ah
	stosb		; Yes Save high byte

save_c60:
	mov 	cx,dx
	sub 	cx,si			; Display the updated string
	add 	si,bx
	push 	si			; Save the Updated Index
	mov 	si,di
	sub 	si,bx			; Get the offset of the new char
	call	put_string		; in the buffer and display all
	pop	si			; Restore the new index
	xchg	di,dx			; and calculate the number of BS
	call	calc_chars		; characters required to get back
	xchg	di,dx
	jmp	bs_out
;
;	On Entry:	AL	First byte of Character
;
;	On Exit:	AX	Complete Character Code
;			CX	Character Size Bytes
;			RL_KANJI and RLF_KANJI set correctly
;
save_kanji:
	and	RL_FLAGS,not RLF_KANJI
	mov	RL_KANJI,ax		; Save the Character
	call	char_type		; Is this the first byte of a 
	test	ah,CHAR_KANJI		; two byte Kanji character
	mov	cx,1			; Character size in bytes
	 jz	save_k10		; No
	or	RL_FLAGS,RLF_KANJI	; Set internal Flag
	call	get_char		; Get the high byte and save
	mov	byte ptr RL_KANJI+1,al	; in the local variable
	mov	ax,RL_KANJI		; Get the complete character
	mov	cx,2			; Character size in bytes
save_k10:
	ret

;
;	The following group of functions modify the flags which control
;	the command line editor.
;
toggle_ins:
	xor	RL_FLAGS,RLF_INS	; Toggle the OverWrite/Insert
	ret				; Flag

toggle_search:
	and	RL_FLAGS,not RLF_MATCH	; clear match bit
	xor	RL_FLAGS,RLF_SEARCH	; Toggle the Search on/off flag
	ret

;
;	This group of functions moves the cursor along the display
;	as well as updating the local variables.
;
goto_bol:
	test	si,si			; Move the cursor to the begining of
	 jz	goto_b10		; the displayed line
	mov	di,si			; Set the buffer index to the
	xor	si,si			; start of the line and the current 
	call	calc_chars		; location
	call	bs_out
	xor	si,si
	mov	di,RL_BUFOFF
goto_b10:
	ret

next_char:
	cmp	si,dx
	 jnz	next_c05		; Treat this as "F1" when we at the
	jmp	copy_char		; end of the line

next_c05:
	mov	al,es:[di]		; Get the Offset of the next character
	mov	cx,1			; the character itself and assume
	call	char_type		; it is 1 byte long
	test 	ah,CHAR_KANJI
	jz 	next_c10
	inc	cx
next_c10:
	xchg	si,di			; Get the string offset in SI
	call	put_string		; display the character and
	xchg	si,di			; restore the register contents
	add	si,cx
	add	di,cx
	ret

prev_char:
	test	si,si			; begining of line ?
	 jz	prev_w30
	push 	dx
	push 	si
	push 	di
	mov	si,RL_BUFOFF		; Scan from the begining of the buffer
	mov	dx,si			; keeping the last match in DX
prev_c10:
	call	char_info		; Get the character information
	cmp	si,di			; Stop when we get to the current
	 je	prev_w20		; character location
	mov	dx,si			; Save current location
	jmp	prev_c10		; and repeat

prev_w20:
	sub	si,dx			; Calculate character length
	push	si			; save for update

	sub	di,RL_BUFOFF		; Convert Offset to Index
	neg 	si
	add 	si,di		; Set the buffer index to the current
	call	calc_chars		; location and the previous character
	call	bs_out			; BackSpace over character
	pop	cx			; Restore the character size
	pop 	di
	pop 	si
	pop 	dx
	sub	si,cx			; Update the Index and Pointer
	sub	di,cx			; variables.
prev_w30:
	ret

;
;	This group of functions deletes characters or groups of characters
;	from the buffer.
;

delf_char:              
	cmp	si,dx			; any chars to our right ?
	 jb	deln_char		;  yes, delete them first
    jmp skip_one_char      
;	ret				;  discard next saved char

del_eol:
	mov 	cx,dx
	sub 	cx,si			; Calculate the number of bytes to 
	jcxz	del_eol10		; delete and jump to DELN_WORD if
	add	cx,di			; non zero. Convert to an offset
	jmp	deln_w10		; and jmp to common code.	
del_eol10:
	ret

delp_char:
	or 	si,si
	jz 	del_eol10		; Ignore if the user is at the start 
	call	back_one_char		; of the line otherwise move back one
	call	prev_char		; character in the line buffer


deln_char:
	cmp 	dx,si
	 jz 	del_eol10
	mov	al,es:[di]		; Get the Offset of the next character
	lea	cx,1[di]		; the character itself and assume
	call	char_type		; it is 1 byte long
	test 	ah,CHAR_KANJI
	 jz 	deln_w10
	inc	cx
;	jmp	deln_w10

;
;	The 3 delete functions come together at this point with the standard
;	register format Plus CX is the offset of the first character not to
;	be deleted.
;
deln_w10:
	push	cx			; Save Delete Offset
	xchg	di,dx			; Determine the no of characters
	call	calc_chars		; displayed to the end of the line
	xchg	di,dx
	mov	bx,cx			; Save the Column count
	pop	ax			; restore the delete offset

	push 	bx
	push 	bx			; Save the count twice

	push 	si
	push 	di
	mov 	cx,dx
	sub 	cx,si			; No of chars from old EOL
	mov	si,ax			; Get the Source Offset
	sub	ax,di			; calculate its length.
	sub	dx,ax			; Update the string length

	sub	cx,ax			; Number of chars to copy
	push	ds			; Move the contents of the
	push 	es
	pop 	ds			; string down in memory and
	rep	movsb			; then update the screen image
	pop	ds
	pop 	si
	pop 	di			; Get the current buffer offset
					; Restore SWAPPED SI <-> DI

	mov	cx,dx			; Calculate the length of the
	sub	cx,di			; string and print it alll
	call	put_string
	xchg	si,di			; Restore SI and DI

	 jcxz	deln_w20
	xchg	di,dx			; Calculate the number of columns
	call	calc_chars		; displayed
	xchg	di,dx

deln_w20:
	pop	bx			; Restore the original line length
	sub	bx,cx			; and calculate the number of spaces
	mov	cx,bx			; required to overwrite the data
	call	space_out

	pop	cx			; Finally move the cursor back to
	jmp	bs_out			; its correct place 




;
;	Delete the contents of the complete line
;
del_line:
	mov	RL_SAVPOS,0		; Reset the buffer index
	test	dx,dx
	 jz	del_l10
	call	goto_bol		; Jump to the begining of the line
	mov	di,dx			; calculate the number of display
	call	calc_chars		; columns it currently takes up
	call	space_out		; Overwrite with spaces
	call	bs_out			; Move back to the start of the line
	xor	si,si			; and update all the initial variables
	mov	dx,si
	mov	di,RL_BUFOFF
del_l10:
	ret

;
;	The following routines manipulate the SAVE Buffer data. Which
;	is initialised on entry to this function.
;
;	SKIP_ONE_CHAR increments the Save Buffer control variables and
;	returns the number of bytes skipped in CX.
;
;	On Entry:	Standard Registers
;
;	On Exit:	AX 	Next Character in Buffer
;			CX	Character Size (Bytes)
;
skip_one_char:
	xor	cx,cx			
	mov	bx,RL_SAVPOS		; Update the Save Buffer variables
	cmp	bx,RL_SAVMAX		; Check the current save buffer is
	 jae	soc_20			; valid and has not been exhausted.
					; Otherwise increment the RL_SAVPOS
	mov	bx,offset savbuf	; pointer by one character. This 
	add	bx,RL_SAVPOS		; means that the RL_SAVPOS can be 
	mov	al,ds:[bx]		; incremented by 1 or 2 depending on 
	call	char_type		; the contents of the buffer
	test	ah,CHAR_KANJI
	 jz	soc_10
	mov	ah,ds:1[bx]
	inc	cx
soc_10:
	inc	cx
soc_20:
	add	RL_SAVPOS,cx
	ret
;
;
;	BACK_ONE_CHAR decrements the Save Buffer control variables and
;	returns the number of bytes skipped in CX.
;
;	On Entry:	Standard Registers
;
;	On Exit:	RL_SAVPOS	points to previous buffer char
;			AX,BX,CX,DX	Unknown
;
back_one_char:
	push	dx
	mov	bx,offset savbuf	; Get the Buffer address
	mov 	cx,bx
	add 	cx,RL_SAVPOS		; CX is the Current location
	mov	dx,bx			; DX is last matching character	
boc_10:
	cmp	bx,cx			; Have we reached the current Char
	 jz	boc_20			; Yes exit and update buffer
	mov	dx,bx			; Update last character location
	mov	al,ds:[bx]		; incremented by 1 or 2 depending on 
	call	char_type		; the contents of the buffer
	inc	bx
	test	ah,CHAR_KANJI		; Increment pointer by 2 for a Kanji
	 jz	boc_10			; character
	inc	bx
	jmp	boc_10

boc_20:	
	sub	dx,offset savbuf	; Calculate the character Index
	mov	RL_SAVPOS,dx		; and save in RL_SAVPOS
	pop	dx
	ret

copy_char:
	cmp	dx,si		; If at end of line copy characters 
	jz	copy_c5
	call	next_char	; Otherwise just move by 1
	jmp	copy_c10

copy_c5:
	call	skip_one_char		; Calculate Bytes to copy
	jcxz	copy_c10		; Skip Update in no characters skipped
	sub	RL_SAVPOS,cx		; Restore the Buffer Position
	jmp	copy_a10		; and copy the data
copy_c10:
	ret

copy_till_char:
	cmp	dx,si			; Copy out if at end of line
	jnz	move_till_char
	call	skip_till_char		; Returns index to the next char
	sub	RL_SAVPOS,cx
	jmp	copy_a10
move_till_char:
	mov	RL_SAVPOS,si		; Start search from the current
	call	skip_till_char		; position
	jcxz	no_move			; CX=0 - dont move
move_along:
	push	cx
	call	next_char		; Shuttle along the line until
	pop	cx			; we reach the character
	loop	move_along
no_move:
	ret
	
copy_all:
	mov	cx,RL_SAVMAX		; Calculate the number of bytes to
	sub	cx,RL_SAVPOS		; copy from the buffer.
copy_a10:
	cmp	cx,0			; do we have nothing to copy
	 jle	copy_a30		; (or less than nothing..)

	push	RL_FLAGS		; Save State flags and prevent
	or	RL_FLAGS,RLF_INS	; SAVPOS being modified
copy_a20:
	push	cx
	and	RL_FLAGS,not RLF_KANJI
	call	skip_one_char		; Return the next character and its 
	cmp 	cx,1 
	jz 	copy_a25		; size in bytes
	mov	RL_KANJI,ax		; Save the Kanji Character and
	or	RL_FLAGS,RLF_KANJI	; set the control flag
	pop 	bx
	dec 	bx
	push 	bx			; Decrement the Loop Count
	
copy_a25:
	call	intsave_char		; Save the character
	pop	cx			; and repeat till all bytes have
	loop	copy_a20		; been copied
	pop	RL_FLAGS		; Restore State Flags
copy_a30:
	ret

skip_till_char:
	call	get_char		; Get the first character
	call	save_kanji		; Setup RL_KANJI etc.
	push	dx
	call	skip_one_char		; don't match on 1st char
	mov	dx,cx			; remember we've skipped 1st char
	 jcxz	stc_40			; buffer exhausted
stc_10:
	call	skip_one_char		; Get the Next Character
	jcxz	stc_40			; Buffer exhausted
	add	dx,cx			; Update the Total Byte Count
	cmp 	cx,2
	 jz 	stc_20			; Was this a Kanji Character
	test RL_FLAGS,RLF_KANJI		; No but are we looking for one ?
	 jnz	stc_10			; Yes so get the next character
	cmp	al,byte ptr RL_KANJI	; Have we got a matching character ?
	jnz	stc_10			; No so look again
	jmp	stc_30			; Return Sucess 

stc_20:					; Kanji Character in Buffer
	test RL_FLAGS,RLF_KANJI		; Are we looking for a Kanji Char
	 jz	stc_10			; No so try again
	cmp	ax,RL_KANJI		; Check the character and repeat
	jnz	stc_10			; if they donot match

stc_30:					; Character Match
	sub	dx,cx			; Correct the Total Byte Count
	sub	RL_SAVPOS,cx		; point to the matching char
	xchg	cx,dx			; and return the Match Count
	pop	dx
	ret

stc_40:					; No Match
	sub	RL_SAVPOS,dx		; Restore RL_SAVPOS to orginal value
	xor	cx,cx			; and return 0000 characters skipped
	pop	dx
	ret

;
;	Update the Save buffer with the contents of the users
;	line buffer.
;
;	On Entry:	ES:DI -> Current location in Buffer
;			DX	 No. of bytes in buffer
;
;	On Exit:	Update RL_SAVMAX, RL_SAVPOS, RL_SAVBUF
;
save_line:
	xor	ax,ax
	mov	RL_SAVPOS,ax
	mov	RL_SAVMAX,ax
	mov	cx,dx			; Current Line Length
	 jcxz	save_l10
	cmp	cx,savbuf_size		; clip the amount saved
	 jb	save_l5			; to be a maximum of
	mov	cx,savbuf_size		; the save buffer size
save_l5:
	mov	RL_SAVMAX,cx		; Set the Save Data Length
	push 	ds
	push 	es
	push 	si
	push 	di

	push 	ds
	pop 	es
	lds	si,RL_BUFPTR
	mov	di,offset savbuf
	rep	movsb			; save the data
	pop 	di
	pop 	si
	pop 	es
	pop 	ds
save_l10:
;	ret

ignore_char:
	ret

mem_line:		;; JFL save from beginning of line 
	call	save_line
	jmp	goto_bol
;	ret	


eof_char:		;; JFL make F6 return a CTL Z
	mov	al,01Ah
	mov	cx,1
	jmp	intsave_char
;	ret

ctlat_char:		;; JFL make F7 return a CTL @
	xor	al,al
	mov	cx,1
	jmp	intsave_char
;	ret


;
;	CHAR_TYPE get the next character from the buffer ES:SI and returns
;	its type in AH using the equates CHAR_????. The character is returned
;	in AL.
;
;
;	
char_type:
	mov 	ah,CHAR_SPACE or CHAR_STD	; WhiteSpace
	cmp 	al,' '
	 jz 	char_t100
	mov	ah,CHAR_TAB		; Tab Character
	cmp 	al,TAB
	 jz 	char_t100
	mov 	ah,CHAR_ALPHAN or CHAR_STD	
	cmp 	al,CTLU
	 jz 	char_t100		; Control-U and Control-T are treated
	cmp 	al,CTLT
	 jz 	char_t100		; as normal characters
	mov	ah,CHAR_CTL		; Control Character
	cmp 	al,' '
	 jb 	char_t100

	mov 	ah,CHAR_ALPHAN or CHAR_STD	
	cmp 	al,'0'
	 jb  	char_t90		; Return SYMBOL
	cmp 	al,'9'
	 jbe 	char_t100		; Return AlphaNumeric
	cmp 	al,'A'
	 jb  	char_t90		; Return Symbol
	cmp 	al,'Z'
	 jbe 	char_t100		; Return AlphaNumeric
	cmp 	al,'a'
	 jb  	char_t90		; Return Symbol
	cmp 	al,'z'
	 jbe 	char_t100		; Return AlphaNumeric
	cmp 	al,80h
	 jb  	char_t90		; Return Symbol

	mov	ah, CHAR_KANJI		; assume character is 16 bits
	call	dbcs_lead		; is byte a DBCS lead?
	 je	char_t100		;  yes - done
char_t90:
	mov	ah,CHAR_OTHER or CHAR_STD ; no - Normal Character Symbol

char_t100:
	ret





;
;	CHAR_INFO will return various information about the character
;	at ES:SI
;
;	On Entry:	ES:SI	Character Pointer
;			BX	Current Column No.
;			CX	Byte Scan Count
;
;	On Exit:	ES:SI	Points to the next Character
;			BX	Updates Column No.
;			CX	Updates Byte Scan Count
;			AH	Character type Flags
;			AL	First byte of Character
char_info:
	lodsb	es:0
	call	char_type		; Test the character type and assume
	inc	bx			; it will take 1 Screen location
	test	ah,CHAR_ONECOL
	 jnz	char_i20

	inc	bx			; Now check for the Control Characters
	test	ah,CHAR_CTL		; which take up 2 cols
	 jnz	char_i20

	test	ah,CHAR_KANJI		; If this was the first byte of a 
	 jz	char_i10		; KANJI character then skip the
	inc 	si
	dec 	cx			; next byte
	jmp	char_i20

char_i10:
	push	ax			; Save AX and calculate the number
	dec 	bx
	dec 	bx			; of screen locations that this TAB
	mov	ax,bx			; character will use based on the fact
	and 	ax,7			; BX contains the current column
	neg 	ax
	add 	ax,8
	add	bx,ax
	pop	ax

char_i20:
	ret

;
;	CALC_CHARS calculates the number of character locations used
;	on the screen to display a particular sub-string of the current
;	buffer. This routine takes account of the Kanji, Control and TAB
;	characters.
;
;	On Entry:	SI	Start Buffer Index
;			DI	End Buffer Index
;
;	On Exit:	CX	Count
;
calc_chars:
	push	bx
	push 	si
	push 	di
	mov	bx,RL_INICOL		; Get the initial Column
	sub	di,si			; DI = Sub-string length bytes
	mov	cx,si			; Use the Start Index for the
	mov	si,RL_BUFOFF		; initial count and scan from the
	jcxz	calc_c20		; start of the buffer

calc_c10:
	call	char_info
	loop	calc_c10

calc_c20:
	mov	cx,di			; Sub-String Length
	mov	di,bx			; Current Column position

calc_c30:
	call	char_info
	loop	calc_c30

	sub	bx,di
	mov	cx,bx
	pop 	di
	pop 	si
	pop	bx
	ret

;
;	The following functions are purely Low level character output
;	functions.
;
space_out:				; Write CX Space characters to the
	mov	al,' '			; Output handle
	jmp	block_out
	
bs_out:
	mov	al,CTLH			; Write CX BackSpace characters to
;;	jmp	block_out		; Output Handle

block_out:
	 jcxz	block_o20
	push	cx
block_o10:
	call	write_char		; output this character
	loop	block_o10
	pop	cx
block_o20:
	ret

;
;	Display CX characters from the string at ES:SI
;
put_string:
	jcxz	puts_s20
	push 	cx
	push 	si
put_s10:
	push	cx
	lodsb	es:0
	call	put_char
	pop	cx
	loop	put_s10
	pop 	si
	pop 	cx
puts_s20:
	ret

;
;	Display the character in AL
;
put_char:
	cmp 	al,' '
	 jae 	write_char		; skip if it's printable
	cmp 	al,CTLT
	 je 	write_char		; Control-T and Control-U are treated
	cmp 	al,CTLU
	 je	write_char		; like normal Characters.
	cmp 	al,TAB
	 je 	write_char		; skip if it's TAB
	or	al,040h			; Convert Character to Uppercase
	push	ax			; save it
	mov	al,'^'			; display the character
	call	write_char		;  in ^X format
	pop	ax
write_char:
	push	es
	push	dx
	push	cx
	push	si
	push	di
	push	ax			; char on stack
	mov	bx,RL_OUTPUT		; Output AL to the OUTPUT Handle
	push 	ss
	pop 	es			; ES:DX -> Character Buffer
	mov	si,sp			; buffer offset
	mov	cx,1			; character count
	call	cooked_write		; Write Character
	pop	ax
	pop	di
	pop	si
	pop	cx
	pop	dx
	pop	es
	ret
;
;	Read 1 a character from RL_INPUT saving all the vital registers
;	from corruption. If the first character is the ESCAPE character
;	set AH to TRUE and read the next byte. Otherwise AH is FALSE
;
get_char:
	push	ds
	push	es
	push	dx
	push	si
	push	di

	call	get_dseg		; point at pcmode data
	lds	si,con_device		; DS:SI -> current console device
	test	ds:DEVHDR.ATTRIB[si],DA_IOCTL ; test bit 14: IOCTL bit
	 jz	get_c05			; error if IOCTL not supported
	sub	sp,RH_SIZE		; reserve this many words on the stack
	mov	bx,sp			; SS:BX -> request packet
	push 	ss
	pop 	es			; ES:BX -> request packet
	lea	dx,RL_FLAGS		; point at flags
	mov	es:RH_CMD[bx],CMD_OUTPUT_IOCTL
	mov	es:RH_LEN[bx],RH4_LEN
	mov	es:RH4_BUFOFF[bx],dx	; set up for a normal
	mov	es:RH4_BUFSEG[bx],ss	;  IOCTL read/write
	mov	es:RH4_COUNT[bx],WORD
	call	device_driver		; execute the command
	add	sp,RH_SIZE		; reclaim the stack
get_c05:

	call	get_dseg		; point at pcmode data
	mov	bx,RL_INPUT		; BX = input stream
	call	cmdline_read		; get a character

	mov	ah,FALSE		; Assume this is NOT the Escape 
	cmp	al,esc_char		; character and set high byte of the
	 jnz	get_c10			; match word to FALSE

	call	raw_read		; read the second byte of the escape
	mov	ah,ESC_CODE		;  sequence, setting high byte to ESC
get_c10:
	pop	di
	pop	si
	pop	dx
	pop	es
	pop	ds
	ret

PCM_CODE	ends

PCM_RODATA	segment public word 'CODE'

esc_char	db	0		; Command Line Editor Escape Character
edit_size	dw	(offset edit_end - edit_table)/EDIT_LEN

edit_table db CR
	db NESC_CODE
	dw ret_string

	db LF
	db NESC_CODE
	dw ignore_char

	db CTLH
	db NESC_CODE
	dw delp_char

	db DEL
	db NESC_CODE
	dw delf_char

	db ESC
	db NESC_CODE
	dw del_line

	db ';' 
	db ESC_CODE 
	dw copy_char		; Function 1

	db '<'
	db ESC_CODE 
	dw copy_till_char	; Function 2

	db '='
	db ESC_CODE 
	dw copy_all		; Function 3

	db '>'
	db ESC_CODE 
	dw skip_till_char	; Function 4

	db '?'
	db ESC_CODE 
	dw mem_line		; Function 5

	db '@'
	db ESC_CODE 
	dw eof_char		; Function 6

	db 'A'
	db ESC_CODE 
	dw ctlat_char		; Function 7

	db 'B'
	db ESC_CODE or DISABLE
	dw match_cmd		; Function 8

	db 'R'
	db ESC_CODE 
	dw toggle_ins		; Insert

	db 'S'
	db ESC_CODE 
	dw delf_char		; Delete

	db 'K'
	db ESC_CODE or DISABLE 
	dw prev_char ; Left Arrow 

	db 'M'
	db ESC_CODE or DISABLE 
	dw next_char	; Right Arrow

; When advanced editing is disabled the match for Left/Right arrows will fall
; through to here
	db 'K' 
	db ESC_CODE 
	dw delp_char		; Left Arrow - compat

	db 'M' 
	db ESC_CODE 
	dw copy_char		; Right Arrow - compat
;
; Extended functions from here on
;
	db 'C' 
	db ESC_CODE or DISABLE
	dw del_cur_history_buffer ; Func 9

	db 'D' 
	db ESC_CODE or DISABLE
	dw del_history_buffers ; Func 10

	db 'G' 
	db ESC_CODE or DISABLE 
	dw goto_bol		; Home

	db 'O' 
	db ESC_CODE or DISABLE 
	dw goto_eol		; End

	db 't' 
	db ESC_CODE or DISABLE 
	dw next_word	; Control Right Arrow

	db 's' 
	db ESC_CODE or DISABLE 
	dw prev_word	; Control Left Arrow

	db CTLV
	db NESC_CODE or DISABLE
	dw toggle_ins

	db CTLQ
	db NESC_CODE or DISABLE
	dw goto_bol

	db CTLW
	db NESC_CODE or DISABLE
	dw goto_eol

	db CTLR
	db NESC_CODE or DISABLE
	dw match_cmd

	db CTLD
	db NESC_CODE or DISABLE
	dw next_char

	db CTLS
	db NESC_CODE or DISABLE
	dw prev_char
	db CTLF
	db NESC_CODE or DISABLE
	dw next_word

	db CTLA
	db NESC_CODE or DISABLE
	dw prev_word

	db CTLG
	db NESC_CODE or DISABLE
	dw deln_char

	db CTLT
	db NESC_CODE or DISABLE
	dw deln_word

	db CTLY
	db NESC_CODE or DISABLE
	dw del_line

	db CTLB
	db NESC_CODE or DISABLE
	dw del_bol

	db CTLK
	db NESC_CODE or DISABLE
	dw del_eol

	db 'I'
	db ESC_CODE or DISABLE 
	dw ignore_char	; PageUP

	db 'Q'
	db ESC_CODE or DISABLE 
	dw ignore_char	; PageDown

	db 'H'
	db ESC_CODE or DISABLE 
	dw prev_cmd 	; Up Arrow

	db 'P'
	db ESC_CODE or DISABLE 
	dw next_cmd		; Down Arrow

	db CTLE
	db NESC_CODE or DISABLE
	dw prev_cmd

	db CTLX
	db NESC_CODE or DISABLE
	dw next_cmd

	db CTLUB
	db NESC_CODE or DISABLE
	dw toggle_search	; Default search mode
edit_end	label byte

PCM_RODATA	ends

PCMODE_DATA	segment public word 'DATA'

	extrn	con_device:dword	; Current Console Device
	extrn	column:byte 		; Console Cursor Location

;	savbuf_size	equ	128
	savbuf_size	equ	CMDLINE_LEN

	extrn	savbuf:byte		; fixed location in DOS data area

	extrn	cle_state:word		; command line editing state
PCMODE_DATA	ends

	end

