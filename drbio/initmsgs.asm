NUL	equ	0
BS	equ	8
TAB	equ	9
LF	equ	10
CR	equ	13

CGROUP	group	INITDATA

INITDATA	segment	word public 'INITDATA'
	assume ds:CGROUP, cs:CGROUP

;		Source .TFT file: 'TMP1.$$$'
	public	_yes_char
	public	yes_char
yes_char	label	byte
_yes_char	db	"Yy", NUL
	public	_no_char
	public	no_char
no_char	label	byte
_no_char	db	"Nn", NUL
	public	_bad_command
	public	bad_command
bad_command	label	byte
_bad_command	db	"Invalid command in CONFIG.SYS file.$", NUL
	public	_bad_filename
	public	bad_filename
bad_filename	label	byte
_bad_filename	db	"Bad or missing file $", NUL
	public	_bad_shell
	public	bad_shell
bad_shell	label	byte
_bad_shell	db	"Invalid SHELL filename $", NUL
	public	_bad_lastdrive
	public	bad_lastdrive
bad_lastdrive	label	byte
_bad_lastdrive	db	"Invalid last drive character (use A..Z) $", NUL
	public	_bad_break
	public	bad_break
bad_break	label	byte
_bad_break	db	"Invalid break switch (use ON or OFF)$", NUL
	public	_bad_buffers
	public	bad_buffers
bad_buffers	label	byte
_bad_buffers	db	"Invalid number of buffers $", NUL
	public	_bad_files
	public	bad_files
bad_files	label	byte
_bad_files	db	"Invalid number of files (use 5..255)", CR, LF, "$", NUL
	public	_bad_fcbs
	public	bad_fcbs
bad_fcbs	label	byte
_bad_fcbs	db	"Invalid number of FCBS", CR, LF, "$", NUL
	public	_bad_fopen
	public	bad_fopen
bad_fopen	label	byte
_bad_fopen	db	"Invalid number of FASTOPEN entries (use 128..32768)", CR, LF, "$", NUL
	public	_bad_drivparm
	public	bad_drivparm
bad_drivparm	label	byte
_bad_drivparm	db	"Invalid or missing DRIVPARM parameters, usage:", CR, LF, "DRIVPARM = /D:d [/C] [/F:f] [/H:h] [/N] [/S:s] [/T:t]", CR, LF, "$", NUL
	public	_bad_history
	public	bad_history
bad_history	label	byte
_bad_history	db	"Invalid HISTORY parameters, usage:", CR, LF, "HISTORY = ON|OFF [,nnn[, ON|OFF]]", CR, LF, "$", NUL
	public	_bad_country
	public	bad_country
bad_country	label	byte
_bad_country	db	"Invalid country code $", NUL
	public	_bad_exec
	public	bad_exec
bad_exec	label	byte
_bad_exec	db	"Bad or missing command interpreter.", CR, LF, "Please enter a valid filename.", CR, LF, "$", NUL
	public	_dos_msg
	public	dos_msg
dos_msg	label	byte
_dos_msg	db	CR, LF, "Can't load DOS file.$", NUL

INITDATA	ends


	end
