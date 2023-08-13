;    File              : $HISTORY.A86$
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
; 	DOSPLUS Command Line Editor Routines
;

	include	pcmode.equ
	include	i:msdos.equ
	include i:char.def
	include	i:cmdline.equ



PCM_HISTORY	CSEG

	public	init_history, save_history
	public	del_history_buffers, del_cur_history_buffer
	public	prev_cmd, next_cmd, match_cmd, search_cmd
	public	prev_word, next_word, match_word
	public	goto_eol
	public	del_bol
	public	deln_word

	extrn	next_char:near
	extrn	save_line:near
	extrn	space_out:near
	extrn	bs_out:near
	extrn	goto_bol:near
	extrn	del_eol:near
	extrn	del_line:near
	extrn	char_info:near
	extrn	put_string:near
	extrn	prev_w20:near
	extrn	deln_w10:near

init_history:
;------------
; On Entry:
;	SS:BP -> history structure
; On Exit:
;	SS:SP filled in with appropriate history buffer
;	Preserve DX
;
	push	ds
	push	es
	push	ss
	pop	es
	lea	di,RL_HIST_SEG		; point at history buffer variables
	mov	si,offset histbuf1	; assume root buffer
	test	RL_FLAGS,RLF_INROOT	; root task after all?
	 jnz	init_history10		; if not we need to switch
	mov	si,offset histbuf2	;  application buffer
init_history10:
	movsw				; copy the seg
	lodsw				; get overall length
	sub	ax,2*WORD		; last two words contain pointers
	stosw				; save the working length
	xchg	ax,si			; SI -> saved buffer positions
	mov	ds,RL_HIST_SEG		;  in the buffer segment
	movsw				; update save and
	movsw				;  recall positions
	pop	es
	pop	ds
	ret


save_history:
;------------
; We are exiting from READLINE - if line has been modified save the
; current line and update our pointers.
;
	test	dx,dx			; skip update of sav/recall pointers
	 jz	save_history30		;  if empty line
	call	save_current		; save away current command line
	mov	di,RL_HIST_SAVE		; start with the old one
	call	find_current_hist	; wrap it if we need to
	call	find_next_null		; find end of "new" command
	inc	di			; onto next character
	cmp	di,RL_HIST_SIZE		; do we need to wrap ?
	 jb	save_history10
	xor	di,di			; wrap the line
save_history10:
	mov	RL_HIST_SAVE,di		; update "save" pointer
	test	RL_FLAGS,RLF_DIRTY	; if a line has been changed we'd
	 jz	save_history30		;  better update "recall" pointer
	mov	RL_HIST_RECL,di		;  too
save_history30:
	push	ds
	push	es
	push ss ! pop ds
	lea	si,RL_HIST_SAVE		; point at history buffer variables
	mov	es,RL_HIST_SEG
	mov	di,RL_HIST_SIZE
	movsw				; save the "save" pointer
	movsw				;  and the "recall" one
	pop	es
	pop	ds
	ret

save_current_if_dirty:
;---------------------
	test	RL_FLAGS,RLF_DIRTY	; if data is dirty (ie. user modified)
	 jz	save_current20		;  then save it
save_current:
;------------
; Copy current buffer contents to next free location in history buffer
;
	push	si
	push	di
	push	dx
	cmp	dx,RL_HIST_SIZE		; is history buffer big enough ?
	 jae	save_current10		;  no, skip saving this line
	call	find_free_hist		; Find the next bit of space
	pop cx ! push cx		; CX = chars to save
	 jcxz	save_current10		; none, forget about it
	push	ds
	push	es
	lds	si,RL_BUFPTR
	mov	es,RL_HIST_SEG
	rep	movsb			; and save the data.  
	xor	ax,ax			; Null terminate it.
	stosb
	pop	es
	pop	ds
	push	di
	call	find_next_null		; Find the end of the entry we just
	mov	cx,di			;  overwrote - if any remains zap it
	pop	di
	cld
	xor	ax,ax			; Null terminate this entry
	sub	cx,di			; Figure out number of zeros to write
	 jbe	save_current10
	push	es
	mov	es,RL_HIST_SEG
	rep	stosb			; and pad to the next entry	
	pop	es
save_current10:
	pop	dx
	pop	di
	pop	si
save_current20:
	ret


;
; Here is the code to deal with history buffers
;
; match_cmd	Does a string search based on what the user has typed so far
; search_cmd	Matches string, but doesn't change match state
; prev_cmd	Retrieves the previous command from the history buffer
; next_cmd 	     "     "  next       "      "     "    "      "
;
match_cmd:
	mov	al,@hist_flg		; is matching enabled ?
	and	ax,RLF_MATCH
	 jz	search_cmd		; no, always match
	xor	RL_FLAGS,ax		; toggle match bit
	test	RL_FLAGS,ax		; turning matching off ?
	 jz	match30			;  then just exit
search_cmd:
	mov	RL_SAVPOS,si		; any chars to save ?
	test	si,si
	 jz	prev_cmd		; blank line - just get previous
	call	save_current_if_dirty	; save current line if it needs saving
	push	si			; save current offset in line
	push	di
	push	dx			; Save index to end of current line
	mov	dx,si			; discard rest of line if no match
	mov	di,RL_HIST_RECL		; Point to the current entry
match_loop:
	call	find_prev_hist		; DI-> previous cmd in buffer
	push	di			; save this command position
	mov	di,RL_HIST_RECL		; get starting position
	call	find_current_hist	;  handle any wrapping
	pop	si			; recover previous command
	cmp	di,si			; have we been all round ?
	 je	match_error		; YES - We've looped so no match found
	push	ds
	push	si			; save this entry
	mov	ds,RL_HIST_SEG
	mov	di,RL_BUFOFF		; ES:DI -> match string
	mov	cx,RL_SAVPOS		; try to match CX characters
	repe	cmpsb
	pop	di			; recover this entry
	pop	ds
	 jne	match_loop		; try again if we didn't match
	call	copy_from_hist		; if it did match copy it
match_error:
	pop	cx			; Get end of displayed line
	pop	di			; user's buffer
	pop	si
	push	si			; save current position in lines
	call	space_out		; Rub the displayed line out
	call	bs_out			; And backspace to it's start
	call	goto_eol		; display the line
	call	goto_bol		; Move cursor to begining
	pop	cx			; CX = end of matched portion
	mov	RL_SAVPOS,cx		; CX = Current position in command
	 jcxz	match20
match10:				; Move cursor forward to current
	push	cx			;  position
	call	next_char		; next_char destroys our loop count
	pop	cx			;  so keep it
	loop	match10
match20:
	mov	cx,RL_SAVMAX		; we can't copy any more
	mov	RL_SAVPOS,cx
match30:
	ret


prev_cmd:
; Get the previous command from the buffer
	test	RL_FLAGS,RLF_RECALLED	; is this the 1st recall ?
	 jnz	prev_cmd10
	push	cx
	push	di
	mov	di,RL_HIST_SAVE		; get existing "save" ptr
	call	find_current_hist	; wrap it if we need to
	mov	RL_HIST_RECL,di		;  and update "recall" pointer
	pop	di
	pop	cx
prev_cmd10:
	call	save_current_if_dirty	; save current line if it needs saving
	call	del_line		;  then delete it
	push	si
	push	di
	mov	di,RL_HIST_RECL		; point to the current entry
	call	find_prev_hist		; DI -> previous entry
	jmps	found_cmd		; now go and copy it to the user buffer

next_cmd:
; Get the next command from the buffer
	call	save_current_if_dirty	; save current line if it needs saving
	call	del_line		;  then delete it
	push	si
	push	di
	mov	di,RL_HIST_RECL		; point to the current entry
	call	find_next_hist		; DI -> next entry
;	jmps	found_cmd		; now go and copy it to the user buffer

found_cmd:
	call	copy_from_hist		; Copy from history to user buffer
	pop	di
	pop	si
;	jmp	goto_eol		; Display new line.

goto_eol:				; Move the cursor to the end of the
	mov cx,dx ! sub cx,si		; displayed line
	 jcxz	goto_e10		; Already at the EOL
	add	si,RL_BUFOFF		; Get the Offset in the buffer
	call	put_string		; Output the sub_string
	add	di,cx			; Update the local variables
	mov	si,dx			; and return
goto_e10:
	ret

; DI-> Current entry in history buffer
;
copy_from_hist:
	or	RL_FLAGS,RLF_RECALLED	; remember we have recalled something
	and	RL_FLAGS,not RLF_DIRTY	; this entry is already in buffers
	mov	RL_HIST_RECL,di		; update pointer for next time
	call	find_next_null		; how big is this entry ?
	mov	cx,di
	mov	si,RL_HIST_RECL
	sub	cx,si			; (CX-SI)=No of bytes to copy
	cmp	cx,RL_MAXLEN		; is the line bigger than our buffer ?
	 jb	copy_from_hist1		; if so we want to clip it
	mov	cx,RL_MAXLEN		; to the maximum possible value
copy_from_hist1:
	mov	dx,cx
	push	ds
	mov	ds,RL_HIST_SEG
	mov	di,RL_BUFOFF
	rep	movsb			; copy to line buffer
	pop	ds
	call	save_line		; save the line
	mov	cx,RL_SAVMAX		; we can't copy any more
	mov	RL_SAVPOS,cx
	ret

; Some primitives for history buffer handling:
;
; find_free_hist	Find the next free entry in the history buffer
; find_next_null	Finds the end of the current entry
; find_prev_hist	Finds the start of the previous entry
; find_next_hist	Finds the start of the next entry
; find_current_hist	Finds the start of current entry

;
; Make DI-> next entry of sufficient length for the current cmd buffer
; If we can't fit at the end zero the remainder of the buffer then wrap
; back to the start.
;

find_free_hist:
	mov	di,RL_HIST_SAVE		; Point at current last entry
	push	di			; Will DX bytes fit?
	add	di,dx
	cmp	di,RL_HIST_SIZE		; Did we run out of buffer?
	pop	di
	 jb	find_free_hist20
	xor	ax,ax			; doesn't fit, so zero to end of buffer
find_free_hist10:
	push	es
	mov	es,RL_HIST_SEG
	stosb				; keep on zeroing
	pop	es
	cmp	di,RL_HIST_SIZE
	 jb	find_free_hist10
	xor	di,di			; wrap back to start of history buffer
find_free_hist20:
	ret

; Entry DI-> entry in the history buffer
; Make DI-> next NULL in the history buffer ( end of current entry )
;
find_next_null:
	mov	cx,RL_HIST_SIZE
	sub	cx,di			; Calc no of bytes left
	xor	ax,ax			; Look for next terminator
	push	es
	mov	es,RL_HIST_SEG
	repnz	scasb	
	dec	di			; point at the NUL
	pop	es
	ret

; Entry DI-> entry in the history buffer
; Make DI-> previous entry in the history buffer
; Preserve CX
find_prev_hist:
	call	find_current_hist	; handle any wrapping
	mov	ax,di			; AX = entry we want previous for
find_prev_hist10:
	push	ax			; save current offset
	push	di			; save initial offset
	xchg	ax,di			; find next from here until
	call	find_next_hist		;  we get back where we started
	xchg	ax,di			; AX = current offset
	pop	di			; recover initial value
	pop	bx			; recover previous offset
	cmp	ax,di			; have we wrapped yet ?
	 je	find_prev_hist20	; yes, BX = previous entry
	 ja	find_prev_hist10	; we are above target so continue
	cmp	bx,di			; we are below target - if previous
	 jae	find_prev_hist10	;  was above target we are OK
	cmp	ax,bx			; if new below previous then we
	 jnb	find_prev_hist10	;  have ERROR wrap, so stop
find_prev_hist20:
	mov	di,bx			; DI -> Previous entry
	ret

find_next_hist:	
	call	find_current_hist	; handle any wrapping
	call	find_next_null		; point to end of current entry
;	jmp	find_current_hist	; handle any wrapping

find_current_hist:
; This routine is complicated by the need to handle switchers, where
;  our buffers and pointers may get out of step
	push	es
	xor	ax,ax
	mov	es,RL_HIST_SEG		; now work backwards to start of line
find_current_hist10:
	cmp	di,1			; are we at the start of the buffer
	 jb	find_current_hist30	;  then don't wrap
	std
	scasb				; is previous char a NUL ?
	cld				;  (it should be!)
	 jne	find_current_hist10
	inc	di			; ES:DI -> 1st char of line
find_current_hist20:
	mov	cx,RL_HIST_SIZE
	sub	cx,di			; CX= Remaining no: of bytes in buffer
	 jbe	find_current_hist30
	repe	scasb			; skip over zero's
	 jne	find_current_hist40
find_current_hist30:
	mov	di,1			; wrap to start of buffer
find_current_hist40:
	dec	di
	pop	es
	ret

del_history_buffers:
;-------------------
; Delete contents of both history buffers
;
	mov	ax,histbuf1		; Segment of 1st history buffer
	mov	cx,histsiz1		; End of 1st history buffer
	call	zap_buffer
	mov	ax,histbuf2		; Segment of 2nd history buffer
	mov	cx,histsiz2		; End of 2nd history buffer
	jmps	zap_buffer
	
del_cur_history_buffer:
;----------------------
; Delete contents of the current history buffer
;
	mov	ax,RL_HIST_SEG		; zero the current buffer
	mov	cx,RL_HIST_SIZE
zap_buffer:
	push	es			; zero fill CX bytes at AX:0
	push	di
	mov	es,ax
	xor	ax,ax
	mov	RL_HIST_RECL,ax
	mov	RL_HIST_SAVE,ax
	xor	di,di
	rep	stosb			; zero fill the buffer
	pop	di
	pop	es
	call	del_line		; then delete current line
	jmp	save_line


next_word:
	mov	cx,dx			; Calculate the number of bytes
	sub	cx,si			; left to scan
	jcxz	next_w10		; Skip if at the EOL
	push	si			; Save the current Index
	mov	si,di			; Scan from the current location
	call	match_word		; Get the next word boundary
	mov	cx,si
	sub	cx,di			; Calculate the string length
	mov	si,di			; to be displayed from the current
	call	put_string		; location and output the data
	pop	si
	add	si,cx			; Update the Index and Offset pointers
	add	di,cx
next_w10:
	ret

;
;	MATCH_WORD scans the buffer at ES:SI for word boundaries
;	and returns to the calling routine whenever it detects such
;	a boundary.
;
;	On Entry:	ES:SI	Buffer Address
;			CX	Maximum No of bytes to Scan
;
;	On Exit:	ES:SI	Next Word Boundary
;
match_word:
	call	char_info
	test	ah,CHAR_ALPHAN or CHAR_KANJI
	loopnz	match_word		; scan the rest of the current word
	 jcxz	match_w30		; end of word or kanji ?

	push	dx
match_w10:
	mov	dx,si
	call	char_info
	test	ah,CHAR_ALPHAN or CHAR_KANJI
	loopz	match_w10
	 jz	match_w20
	sub	si,dx			; Correct the count in CX
	add	cx,si			; and return the location of the
	mov	si,dx			; word boundary

match_w20:
	pop	dx
match_w30:
	ret

prev_word:
	mov cx,si ! jcxz match_w30	; Initialize the count
	push dx ! push si ! push di
	mov	si,RL_BUFOFF		; Scan from the begining of the buffer
	mov	dx,si			; keeping the last match in DX
prev_w10:
	call	match_word		; Find the next word boundary
	jcxz	prev_w15		; Stop when we get to the current offset
	mov	dx,si			; Save current location
	jmps	prev_w10		; and repeat
prev_w15:
	jmp	prev_w20

del_bol:				; Delete to the begining of the line
	or si,si ! jz del_bol10		; Ignore if at the begining
	or dx,dx ! jz del_bol10		; Or the line is empty
	push	di			; Save the current index
	call	goto_bol		; Move to the start of the line
	pop	cx			; Restore the current offset
	jmp	deln_w10		; and jump to common code
del_bol10:
	ret

deln_word:
	mov	cx,dx			; Calculate the number of bytes
	sub	cx,si			; left to scan
	jcxz	del_bol10		; Skip if at the EOL
	push	si			; Save the current Index
	mov	si,di			; Scan from the current location
	call	match_word		; Get the next word boundary
	mov	cx,si
	pop	si
	jmp	deln_w10

PCMODE_DATA	DSEG	WORD

	extrn	@hist_flg:byte		; To select between histbufs 1 or 2

GLOBAL_DATA	dseg	word

	extrn	histbuf1:word, histsiz1:word, histbuf2:word, histsiz2:word

	end

