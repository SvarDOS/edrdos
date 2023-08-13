;    File              : $CLOCK.ASM$
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
;    CLOCK.ASM 1.12 93/07/22 19:43:10
;    switch over to REQUEST.EQU
;    ENDLOG

	include BIOSGRPS.EQU
	include	DRMACROS.EQU		; standard DR macros
	include	IBMROS.EQU		; ROM BIOS equates
	include	REQUEST.EQU		; request header equates
	include	DRIVER.EQU		; device driver equates

page
CGROUP	group	CODE, RCODE, RESUMECODE, ICODE

CG	equ	offset CGROUP

TIME	struc
DAYS		dw	?
MINUTES		db	?
HOURS		db	?
HUNDREDTHS	db	?
SECONDS		db	?
TIME	ends

	Assume	CS:CGROUP, DS:CGROUP, ES:Nothing, SS:Nothing

CODE	segment 'CODE'

	extrn	endbios:word		; for device driver INIT function
	extrn	daycount:word
	
; There are 1193180/65536 ticks per second, or 0E90Bh/10000h ticks per 5/100th.

CONVERSION_FACTOR	equ	0E90Bh

CODE	ends

RCODE	segment 'RCODE'

	extrn	DataSegment:word

monlen		db	31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31


	Public	ClockTable

ClockTable:
	db	9			; Last supported function
	dw	CG:dd_init		; 0-initialize driver
	dw	CG:dd_error		; 1-media change check (disks only)
	dw	CG:dd_error		; 2-build BPB (disks only)
	dw	CG:dd_error		; 3-IOCTL string input
	dw	CG:dd_input		; 4-input
	dw	CG:dd_error		; 5-nondestructive input (char only)
	dw	CG:dd_error		; 6-input status (char only)
	dw	CG:dd_error		; 7-input flush
	dw	CG:dd_output		; 8-output
	dw	CG:dd_output		; 9-output with verify

page
driver	proc	near

dd_error:	; used for all unsupported driver functions
;--------
	mov	ax,RHS_ERROR+3		; "invalid command" error
	ret

dd_input:	; 4-input
;--------
	les	di,es:RH4_BUFFER[bx]	; ES:DI -> requested date/time buffer
	call	read_system_ticks	; read system tick counter
	mov	ax,daycount		; AX = date
	stosw				; return date
	push	dx			; save low word of ticks
	mov	ax,5
	mul	cx			; multiply high word of ticks by 5
	xchg	ax,cx			; save result in CX
	pop	dx
	mov	ax,5
	mul	dx			; multiply low word of tick by 5
	add	dx,cx			;  and add in high word
	mov	bx,CONVERSION_FACTOR
	div	bx			; convert to centi-secs
	push	ax			; save high word of result
	xor	ax,ax
	div	bx			; divide remainder
	pop	dx			; recover high word of result
					;  giving us time in centi-secs
	mov	bx,60*100		; BX = centi-secs/minute
	div	bx			; AX = # minutes
	push	dx			; save centi-secs remainder
	cwd				; DX = 0
	mov	bx,60+(256*100)		; BL = minutes/hour,BH = centi-secs/sec
	div	bl			; AL = hours, AH = minutes remainder
	xchg	al,ah
	stosw				; return minutes then hours
	pop	ax			; recover centi-secs remainder
	div	bh			; AL = secs, AH = centi-secs remainder
	xchg	al,ah
	stosw				; return centi-secs then secs
	sub	ax,ax
	ret

	page

dd_output:	; 8-output
;---------
	les	si,es:RH4_BUFFER[bx]

;	First we'll convert the date & set the RTC if present:

	mov	ax,es:DAYS[si]		; # of days since 1/1/1980
	mov	daycount,ax

	mov	dx,1980			; get initial year
output1:
	mov	cx,365			; assumed year size
	test	dl,3			; test for leap years
	 jnz	output2			; skip if not a leap year
	inc	cx			; leap years have 366 days
output2:
	cmp	ax,cx			; more days than this year?
	 jb	output3			; skip if less - same year
	sub	ax,cx			; else date in future year
	inc	dx			; subtract from total, next year
	jmps	output1			; check again

output3:				; DX = binary year, AX = day in year
	sub	bx,bx			; start with January
	sub	cx,cx			; CH = 0
output4:
	mov	cl,cs:monlen[bx]	; CX = # of days in next month
	cmp	cl,28			; is it february ?
	 jne	output5
	test	dl,3			; is it a leap year ?
	 jnz	output5
	inc	cx			; leap years have 29 days in february
output5:
	cmp	ax,cx			; remaining day count >= month length?
	 jb	output6			; skip if right month found
	sub	ax,cx			; else subtract days in that month
	inc	bx			; move on to next month
	jmps	output4			; repeat until month found

output6:				; DX = binary year
	inc	ax			; AX = day-1    =>  convert to day
	inc	bx			; BX = month-1  =>  convert to month
	mov	ah,bl			; high byte is month
	call	bin2bcd			; convert to month

	xchg	ax,dx			; DL, DH = day, month of date
					; AX = binary year

	mov	bl,100
	div	bl			; AL = century, AH = year
	xchg	al,ah			; AH = century, AL = year
	call	bin2bcd			; convert AL, AH from binary to BCD
	xchg	ax,cx			; CL, CH = year, century for date

	mov	ah,5			; set real time clock date
	int	RTC_INT			;    on AT, XT-286, PS/2, etc.

;	Now we'll convert the time & set the RTC if present

;	mov	ah,es:HOURS[si]
;	mov	al,es:MINUTES[si]		; get binary hours & minutes
	mov	ax,es:word ptr MINUTES[si]
	call	bin2bcd			; convert to BCD values
	xchg	ax,cx			; CH, CL = hh:mm in BCD
	mov	ah,es:SECONDS[si]
	mov	al,0			; get binary seconds & no daylight saving
	call	bin2bcd			; convert to BCD values
	xchg	ax,dx			; DH, DL = ss.000 in BCD

	mov	ah,3			; set real time clock time
	int	RTC_INT			;    on AT, XT-286, PS/2, etc.

	mov	al,100
	mul	es:SECONDS[si]		; AX = seconds in hundredths
	xchg	ax,dx			; save in DX
	mov	al,es:HUNDREDTHS[si]
	cbw				; AX = hundredths
	add	ax,dx			; AX = secs and hundredths in 1/100ths
	cwd				; make the a dword
	mov	bx,5
	div	bx			; AX = secs and hundredths in 5/100ths
	xchg	ax,bx			; save in BX
	mov	al,60			; convert hours into minutes
	mul	es:HOURS[si]		; AX = hours in mins
	xchg	ax,dx
	mov	al,es:MINUTES[si]
	cbw				; AX = minutes value
	add	ax,dx			; AX = hours and mins in mins
	mov	dx,60*20
	mul	dx			; DX:AX = hours and mins in 5/100ths
	add	ax,bx
	adc	dx,0			; DX:AX = total in 5/100ths
	mov	bx,CONVERSION_FACTOR	; load up our magic value
	push	dx			; save high word
	mul	bx			; DX = low word result
	mov	cx,dx			;  save for later
	pop	ax			; recover high word
	mul	bx			; DX:AX = result from high word
	add	ax,cx			; add low and high word results
	adc	dx,0			;  together in DX:AX
	xchg	ax,dx			; DX = low word of result
	xchg	ax,cx			; CX = high word of result

	mov	ah,1			; set system timer
	int	RTC_INT			; CX = high word, DX = low word

	sub	ax,ax			; return successfully when done
	ret


	Public	read_system_ticks

read_system_ticks:
;-----------------
	mov	ah,0			; read system tick counter
	int	RTC_INT
	test	al,al			; have we passed midnight ?
	 jz	read_st10		; if so a new day has dawned
	inc	daycount
read_st10:
	ret

bin2bcd:	; convert AL and AH to BCD values
;-------
	call	bin2bcd1		; swap AL, AH, convert to BCD
;	call	bin2bcd1
;	ret
bin2bcd1:
	push	cx
	mov	ch,ah			; save AH in scratch register
	aam				; AL = AL % 10; AH = AL/10;
	mov	cl,4
	shl	ah,cl			; shift tens into high nibble
	or	ah,al			; combine the nibbles
	mov	al,ch			; restore the high byte into low byte
	pop	cx
	ret

driver	endp

RCODE	ends				; end of device driver code

RESUMECODE segment 'RESUMECODE'

; If the system ROM BIOS supports RESUME mode then it will call Int 6C
; when returning from sleep mode. We take this over and reset the clock
; based upon the RTC value. To save space we only relocate the code if
; required.
;

	Public	ResumeHandler
ResumeHandler	proc	far
	sti
	mov	ax,cs:DataSegment	; we have been asleep and are being
	mov	ds,ax			;  woken by the BIOS
	mov	es,ax			; lets re-read the RTC before
	call	set_clock		;  we return to them
	clc
	ret	2
ResumeHandler	endp

set_monlen	db	31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31


set_clock:
;---------
; We may also be called after a RESUME when we have to reset the time.

	mov	ah,2			; read real time clock
	xor	cx,cx
	xor	dx,dx			; assume it won't work
	stc
	int	RTC_INT			; CH = hours, CL = mins, DH = secs
	 jc	set_clock40		; (all in BCD remember)

	xchg	al,dh			; AL = secs
	call	bcd2bin			; AL = secs in binary
	cmp	al,59
	 ja	set_clock40		; reject invalid seconds
	mov	ah,100
	mul	ah			; AX = seconds in hundredths
	cwd				; make it a dword
	mov	bx,5
	div	bx			; AX = secs and hundredths in 5/100ths
	xchg	ax,bx			; save in BX

	mov	al,ch			; AL = hours in BCD
	call	bcd2bin			; AL = hours in binary
	cmp	al,23
	 ja	set_clock40		; reject invalid hours
	mov	ah,60			; convert hours into minutes
	mul	ah			; AX = hours in mins
	xchg	ax,dx			; save in DX

	mov	al,cl			; AL = mins in BCD
	call	bcd2bin			; AL = mins in binary
	cmp	al,59
	 je	set_clock40		; reject invalid mins
	cbw				; AX = minutes value
	add	ax,dx			; AX = hours and mins in mins
	mov	dx,60*20
	mul	dx			; DX:AX = hours and mins in 5/100ths
	add	ax,bx
	adc	dx,0			; DX:AX = total in 5/100ths
	mov	bx,CONVERSION_FACTOR	; load up our magic value
	push	dx			; save high word
	mul	bx			; DX = low word result
	mov	cx,dx			;  save for later
	pop	ax			; recover high word
	mul	bx			; DX:AX = result from high word
	add	ax,cx			; add low and high word results
	adc	dx,0			;  together in DX:AX
	xchg	ax,dx			; DX = low word of result
	xchg	ax,cx			; CX = high word of result

	mov	ah,1			; set system timer
	int	RTC_INT			; CX = high word, DX = low word

set_clock40:
	mov	ah,4			; read RTC (if present)
	int	RTC_INT			; validate date - CMOS may be corrupt
	cmp	cx,1980h		; Too low?
	 jb	set_clock45		; Yes so skip
	cmp	cx,2099h		; Too high ?
	 ja	set_clock45		; Yes so skip
	cmp	dx,0101h		; Too low?
	 jb	set_clock45		; Yes so skip
	cmp	dx,3112h		; Too high ?
	 jbe	set_clock50		; No its okay so scram
set_clock45:	
    mov cx,1980h        ; assume the year 1980
	mov	dx,0101h		; assume 1st of January of that year
set_clock50:
	xchg	ax,cx			; AL, AH = year, century in BCD
	call	bcd2bin			; convert values to binary
	xchg	ax,cx			
	xchg	ax,dx			; AL, AH = day, month in BCD
	call	bcd2bin			; convert values to binary
	xchg	ax,dx

	mov	daycount,0		; zero the daycount in case of RESUME
    mov ax,19*256 + 80      ; assume 1980 
set_clock55:
	cmp	ax,cx			; same year?
	 je	set_clock65
	mov	bx,365			; assume 365 days in that year
	test	al,3			; test for leap year
	 jnz	set_clock60		; (this works til 2400 A.D.)
	inc	bx			; add FEB 29 if divisible by four
set_clock60:
	add	daycount,bx		; add days in previous year to total
	inc	al			; next year
	cmp	al,100			; end of century?
	 jb	set_clock55		; skip if same century
	mov	al,0			; continue with XX00
	inc	ah			;   ...next century
	jmps	set_clock55		; check year again


set_clock65:				; same year by now
	xchg	ax,cx			; CX = year
	sub	dx,0101h		; make month, day 0 relative
	sub	bx,bx			; assume January
	sub	ax,ax			; AH = 0
set_clock70:
	cmp	dh,bl			; does current month match?
	 je	set_clock80		; skip if it does
	mov	al,cs:set_monlen[bx]	; get length of that month
	cmp	al,28			; is it february ?
	 jne	set_clock75
	test	cl,3			; is it a leap year ?
	 jnz	set_clock75
	inc	ax			; leap year, 29 days in february
set_clock75:
	add	daycount,ax		; add it to total day count
	inc	bx			; move on to next month
	jmps	set_clock70

set_clock80:
	mov	al,dl			; get days in that month
	add	daycount,ax		; add them to day count
	ret

bcd2bin:
;-------
;	entry:	AL, AH = BCD values
;		AL, AH = binary equivalents

	call	bcd2bin1		; swap AL, AH, convert AL to binary
;	call	bcd2bin1		; swap AL, AH, convert AL to binary
;	ret

bcd2bin1:				; convert BCD to binary
	xchg	al,ah			; swap the two values
	push	bx
	mov	bl,0			; start off without tens
bcd2bin2:
	cmp	al,10h			; check if more tens
	 jb	bcd2bin3		; all tens done
	sub	al,10h			; else subtract 10 in BCD
	add	bl,10			; ...and add it in binary
	jmps	bcd2bin2		; repeat for all tens
bcd2bin3:				; AL = ones, BL = tens
	add	al,bl			; AL = binary value
	pop	bx			; restore BX
	ret


RESUMECODE ends


ICODE	segment 'ICODE'			; initialization code

	Assume	CS:CGROUP, DS:CGROUP

dd_init:	; 0-initialize driver
;-------
	call	set_clock		; set elapsed ticks

	les	bx,REQUEST[bp]		; ES:BX -> request header

	mov	ax,endbios
	mov	es:RH0_RESIDENT[bx],ax	; set end of device driver
	mov	es:RH0_RESIDENT+2[bx],ds

	sub	ax,ax			; initialization succeeded
	ret				; (BIOS init always does...)


ICODE	ends

	end
