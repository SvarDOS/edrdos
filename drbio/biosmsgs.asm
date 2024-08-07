include version.inc

NUL	equ	0
BS	equ	8
TAB	equ	9
LF	equ	10
CR	equ	13


CGROUP	group	RCODE


RCODE	segment public byte 'RCODE'

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

	public	kernel_ver_msg
kernel_ver_msg db KERNEL_VER_STR, 0

	public repository_msg
repository_msg db REPOSITORY_STR, 0

	public	_lba_supp_msg
	public	lba_supp_msg
lba_supp_msg		label	byte
_lba_supp_msg		db	"Supported version of int 13 extensions: ", NUL

RCODE	ends


	end
