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
	public	_drdosprojects_msg
	public	drdosprojects_msg

drdosprojects_msg		label	byte
ifdef LDOS
	_drdosprojects_msg	db	CR, LF
db "lDOS Enhanced DR-DOS kernel fork               https://hg.pushbx.org/ecm/edrdos"
				db CR, LF, NUL
;lDOS Enhanced DR-DOS kernel fork               https://hg.pushbx.org/ecm/edrdos
;Enhanced DR-DOS continuation                  https://github.com/svardos/edrdos
;The DR-DOS/OpenDOS Enhancement Project              http://www.drdosprojects.de
;12345678901234567890123456789012345678901234567890123456789012345678901234567890
elseifdef SVARDOS
	_drdosprojects_msg	db	CR, LF, "Enhanced DR-DOS continuation                  https://github.com/svardos/edrdos", CR, LF, NUL
else
	_drdosprojects_msg	db	CR, LF, "The DR-DOS/OpenDOS Enhancement Project              http://www.drdosprojects.de", CR, LF, NUL
endif
	public	_starting_dos_msg
	public	starting_dos_msg
starting_dos_msg	label	byte
_starting_dos_msg	db	CR, LF, "Starting "
shortversion equ 1
			include version.inc
			db	CR, LF, NUL
	public	_lba_supp_msg
	public	lba_supp_msg
lba_supp_msg		label	byte
_lba_supp_msg		db	"Supported version of int 13 extensions: ", NUL

RCODE	ends


	end
