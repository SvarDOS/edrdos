NUL	equ	0
BS	equ	8
TAB	equ	9
LF	equ	10
CR	equ	13

DGROUP	group	_DATA

_DATA	segment	word public 'DATA'
	assume ds:DGROUP

;		Source .TFT file: 'TMP1.$$$'
	public	_msg0
	public	msg0
msg0	label	byte
_msg0		db	"Write protect error$"
	public	_msg3
	public	msg3
msg3	label	byte
_msg3		db	"I/O error$"
	public	_msg2
	public	msg2
msg2	label	byte
_msg2		db	"Not ready error$"
	public	_msg4
	public	msg4
msg4	label	byte
_msg4		db	"Data error$"
	public	_msg6
	public	msg6
msg6	label	byte
_msg6		db	"Seek error$"
	public	_msg7
	public	msg7
msg7	label	byte
_msg7		db	"Bad media type$"
	public	_msg8
	public	msg8
msg8	label	byte
_msg8		db	"Sector not found$"
	public	_msg21
	public	msg21
msg21	label	byte
_msg21		db	"Printer out of paper$"
	public	_msg20
	public	msg20
msg20	label	byte
_msg20		db	"File Sharing Conflict$"
	public	_msg22
	public	msg22
msg22	label	byte
_msg22		db	"FCB table exhausted$"
	public	_msg_crlf
	public	msg_crlf
msg_crlf	label	byte
_msg_crlf	db	CR, LF, "$"
	public	_readmsg
	public	readmsg
readmsg	label	byte
_readmsg	db	" reading$"
	public	_writemsg
	public	writemsg
writemsg	label	byte
_writemsg	db	" writing$"
	public	_drivemsg
	public	drivemsg
drivemsg	label	byte
_drivemsg	db	" drive $"
	public	_charmsg
	public	charmsg
charmsg	label	byte
_charmsg	db	" device $"
	public	_abort_char
	public	abort_char
abort_char	label	byte
_abort_char	db	"A$"
	public	_abort_msg
	public	abort_msg
abort_msg	label	byte
_abort_msg	db	"Abort$"
	public	_retry_char
	public	retry_char
retry_char	label	byte
_retry_char	db	"R$"
	public	_retry_msg
	public	retry_msg
retry_msg	label	byte
_retry_msg	db	", Retry$"
	public	_ignore_char
	public	ignore_char
ignore_char	label	byte
_ignore_char	db	"I$"
	public	_ignore_msg
	public	ignore_msg
ignore_msg	label	byte
_ignore_msg	db	", Ignore$"
	public	_fail_char
	public	fail_char
fail_char	label	byte
_fail_char	db	"F$"
	public	_fail_msg
	public	fail_msg
fail_msg	label	byte
_fail_msg	db	", Fail$"
	public	_prompt_msg
	public	prompt_msg
prompt_msg	label	byte
_prompt_msg	db	" ? $"
	public	_reload_msgs
	public	reload_msgs
reload_msgs	label	byte
_reload_msgs	db	CR, LF, "Cannot load the file ", 0
	public	_reload_msgf
	public	reload_msgf
reload_msgf	label	byte
_reload_msgf	db	CR, LF, "Insert correct disk and Strike any key", 0
	public	_reload_msgm
	public	reload_msgm
reload_msgm	label	byte
_reload_msgm	db	" No Memory", 0

_DATA	ends


	end
