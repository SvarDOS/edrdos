NUL	equ	0
BS	equ	8
TAB	equ	9
LF	equ	10
CR	equ	13

include BIOSGRPS.EQU

CGROUP	group	RCODE


RCODE	segment	word public 'RCODE'

;		Source .TFT file: 'TMP1.$$$'
	public	_disk_msgA
	public	disk_msgA
disk_msgA	label	byte
_disk_msgA	db	CR, LF, "Insert diskette for drive ", NUL
	public	_disk_msgB
	public	disk_msgB
disk_msgB	label	byte
_disk_msgB	db	": and", CR, LF, "   strike any key when ready", CR, LF, LF, NUL
	public	_div_by_zero_msg
	public	div_by_zero_msg
div_by_zero_msg	label	byte
_div_by_zero_msg	db	CR, LF, "Divide Error", CR, LF, NUL
	public	_starting_dos_msg
	public	starting_dos_msg
starting_dos_msg	label	byte
_starting_dos_msg	db	CR, LF, "Starting DOS...", CR, LF, NUL

RCODE	ends


	end
