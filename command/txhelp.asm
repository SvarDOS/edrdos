NUL	equ	0
BS	equ	8
TAB	equ	9
LF	equ	10
CR	equ	13

PRI	equ	0
ALT	equ	1

DGROUP	group	_DATA
CHELP	group	_HELP

_DATA	segment word public 'DATA'
	assume ds:DGROUP, cs:DGROUP

	public	_single_table

	public	_dls_table

	public	_dls_init
	public	_dls_get_table
	public	_dls_language

_dls_table	dw	0

__dls_init__	db	0

_single_table	label	word

;		Source .TFT file: 'TMP1.$$$'
		public	help_aaa
help_aaa	equ	$ - _single_table
		dw	CHELP:_help_aaa
		public	help_and
help_and	equ	$ - _single_table
		dw	CHELP:_help_and
		public	help_break
help_break	equ	$ - _single_table
		dw	CHELP:_help_break
		public	help_call
help_call	equ	$ - _single_table
		dw	CHELP:_help_call
		public	help_chcp
help_chcp	equ	$ - _single_table
		dw	CHELP:_help_chcp
		public	help_chdir
help_chdir	equ	$ - _single_table
		dw	CHELP:_help_chdir
		public	help_cls
help_cls	equ	$ - _single_table
		dw	CHELP:_help_cls
		public	help_copy
help_copy	equ	$ - _single_table
		dw	CHELP:_help_copy
		public	help_ctty
help_ctty	equ	$ - _single_table
		dw	CHELP:_help_ctty
		public	help_date
help_date	equ	$ - _single_table
		dw	CHELP:_help_date
		public	help_del
help_del	equ	$ - _single_table
		dw	CHELP:_help_del
		public	help_delq
help_delq	equ	$ - _single_table
		dw	CHELP:_help_delq
		public	help_dir
help_dir	equ	$ - _single_table
		dw	CHELP:_help_dir
		public	help_echo
help_echo	equ	$ - _single_table
		dw	CHELP:_help_echo
		public	help_eraq
help_eraq	equ	$ - _single_table
		dw	CHELP:_help_eraq
		public	help_erase
help_erase	equ	$ - _single_table
		dw	CHELP:_help_erase
		public	help_exit
help_exit	equ	$ - _single_table
		dw	CHELP:_help_exit
		public	help_for
help_for	equ	$ - _single_table
		dw	CHELP:_help_for
		public	help_gosubreturn
help_gosubreturn	equ	$ - _single_table
		dw	CHELP:_help_gosubreturn
		public	help_goto
help_goto	equ	$ - _single_table
		dw	CHELP:_help_goto
		public	help_hiload
help_hiload	equ	$ - _single_table
		dw	CHELP:_help_hiload
		public	help_idle
help_idle	equ	$ - _single_table
		dw	CHELP:_help_idle
		public	help_if
help_if		equ	$ - _single_table
		dw	CHELP:_help_if
		public	help_mkdir
help_mkdir	equ	$ - _single_table
		dw	CHELP:_help_mkdir
		public	help_or
help_or		equ	$ - _single_table
		dw	CHELP:_help_or
		public	help_path
help_path	equ	$ - _single_table
		dw	CHELP:_help_path
		public	help_pause
help_pause	equ	$ - _single_table
		dw	CHELP:_help_pause
		public	help_prompt
help_prompt	equ	$ - _single_table
		dw	CHELP:_help_prompt
		public	help_rem
help_rem	equ	$ - _single_table
		dw	CHELP:_help_rem
		public	help_rename
help_rename	equ	$ - _single_table
		dw	CHELP:_help_rename
		public	help_rmdir
help_rmdir	equ	$ - _single_table
		dw	CHELP:_help_rmdir
		public	help_set
help_set	equ	$ - _single_table
		dw	CHELP:_help_set
		public	help_shift
help_shift	equ	$ - _single_table
		dw	CHELP:_help_shift
		public	help_switch
help_switch	equ	$ - _single_table
		dw	CHELP:_help_switch
		public	help_time
help_time	equ	$ - _single_table
		dw	CHELP:_help_time
		public	help_truename
help_truename	equ	$ - _single_table
		dw	CHELP:_help_truename
		public	help_type
help_type	equ	$ - _single_table
		dw	CHELP:_help_type
		public	help_ver
help_ver	equ	$ - _single_table
		dw	CHELP:_help_ver
		public	help_verify
help_verify	equ	$ - _single_table
		dw	CHELP:_help_verify
		public	help_vol
help_vol	equ	$ - _single_table
		dw	CHELP:_help_vol


_DATA	ends

_HELP	segment	word public 'HELP'

	assume ds:CHELP, cs:CHELP

;		Source .TFT file: 'TMP1.$$$'
_help_aaa	db	"Available internal commands are:", LF, LF, NUL
_help_truename	db	"Reserved command.", NUL
_help_break	db	"BREAK", TAB, "Controls how you break out of programs using Ctrl+Break or Ctrl+C.", LF, LF, "Syntax:", LF, TAB, "BREAK /H", LF, TAB, "BREAK [ON|OFF]", LF, LF, TAB, "/H", TAB, "gives this scre"
		db	"en", LF, TAB, "ON", TAB, "turns break checking on (default)", LF, TAB, "OFF", TAB, "turns break checking off", LF, TAB, "none", TAB, "no parameters displays the state of break ON or OFF", LF
		db	LF, "Examples:", LF, TAB, "BREAK OFF", LF, TAB, "BREAK", NUL
_help_call	db	"CALL", TAB, "Used in batch files, this command will call another batch file and", LF, TAB, "return when it has finished executing it.", LF, LF, "Syntax:", LF, TAB, "CALL /H", LF, TAB, "CALL [d"
		db	":][path]file[.BAT][ params[...]]", LF, LF, TAB, "/H", TAB, "gives this screen", LF, TAB, "d:", TAB, "drive where batch file resides", LF, TAB, "path", TAB, "path where batch file resides", LF
		db	TAB, "file", TAB, "name of batch file to call", LF, TAB, ".BAT", TAB, "optional filename extension", LF, TAB, "params", TAB, "parameter list read by called batch file as %%1 %%2 ... etc", LF, LF
		db	"Examples:", LF, TAB, "CALL doit.bat", LF, TAB, "CALL setdate 5 Nov 90", NUL
_help_chdir	db	"CHDIR", TAB, "Shows the path, or changes the current directory. Can be", LF, TAB, "abbreviated to CD.", LF, LF, "Syntax:", LF, TAB, "CHDIR /H", LF, TAB, "CHDIR [[d:]dirpath]", LF, LF, TAB, "/"
		db	"H", TAB, "gives this screen", LF, TAB, "d:", TAB, "drive on which dirpath resides", LF, TAB, "dirpath", TAB, "directory to change to", LF, TAB, "none", TAB, "no parameters displays the curre"
		db	"nt drive and directory", LF, LF, "Examples:", LF, TAB, "CHDIR c:\homedir", LF, TAB, "CD ..", LF, TAB, "CD", NUL
_help_cls	db	"CLS", TAB, "Clears the display screen.", LF, LF, "Syntax:", LF, TAB, "CLS /H", LF, LF, TAB, TAB, "/H", TAB, "gives this screen", LF, LF, "Example:", LF, TAB, "CLS", NUL
_help_copy	db	"COPY", TAB, "Copies or combines files", LF, LF, "Syntax:", LF, "   COPY /H", LF, "   COPY device|wildspec[+wildspec...][switches] [device|filespec[switches]]", LF, LF, "   device", TAB, "is CON"
		db	",LPTn,PRN,NUL,COMn or AUX", LF, "   wildspec", TAB, "source device, file or list of files to be included", LF, "   filespec", TAB, "destination file or device", LF, "   switches", TAB, "/A treat"
		db	" file as ASCII", LF, TAB, TAB, "/B treat source file as binary (ignore Ctrl+Z in file)", LF, TAB, TAB, "/V verify source and destination match", LF, TAB, TAB, "/S include system or hidden fil"
		db	"es in copy", LF, TAB, TAB, "/C prompt for confirmation by user before copying", LF, TAB, TAB, "/Z zeros top bit of every byte in destination", LF, "Examples:", LF, TAB, "COPY file1+file2 file"
		db	"3", LF, TAB, "COPY *.txt c:dir1", NUL
_help_date	db	"DATE", TAB, "Displays and changes the date.", LF, LF, "Syntax:", LF, TAB, "DATE /H", LF, TAB, "DATE [mm-dd-yy] (US format)", LF, TAB, "DATE [dd-mm-yy] (European format)", LF, TAB, "DATE [yy-"
		db	"mm-dd] (Japanese format)", LF, LF, TAB, "/H", TAB, "gives this screen", LF, TAB, "mm", TAB, "month 1 to 12", LF, TAB, "dd", TAB, "day 1 to 31", LF, TAB, "yy", TAB, "2 or 4 digit year", LF
		db	TAB, "none", TAB, "no parameters displays date then prompts for new date", LF, LF, "Examples:", LF, TAB, "DATE 16-11-90", LF, TAB, "DATE", NUL
_help_del	db	"DEL", TAB, "Erases files.", LF, LF, "Syntax:", LF, TAB, "DEL /H", LF, TAB, "DEL wildspec [/C|/P][/S]", LF, LF, TAB, "/H", TAB, "  gives this screen", LF, TAB, "/C|/P", TAB, "  prompt befo"
		db	"re deletion", LF, TAB, "/S", TAB, "  include system files", LF, TAB, "wildspec  file to be deleted (wildcards allowed)", LF, LF, "Examples:", LF, TAB, "DEL *.EXE /CS", LF, TAB, "DEL MYFILE."
		db	"TXT", NUL
_help_delq	db	"DELQ", TAB, "Erases files but queries you before doing so.", LF, LF, "Syntax:", LF, TAB, "DELQ /H", LF, TAB, "DELQ wildspec [/S]", LF, LF, TAB, "/H", TAB, "  gives this screen", LF, TAB, "/"
		db	"S", TAB, "  include system files", LF, TAB, "wildspec  file to be deleted (wildcards allowed)", LF, LF, "Examples:", LF, TAB, "DELQ *.EXE /S", LF, TAB, "DELQ MYFILE.TXT", NUL
_help_dir	db	"DIR", TAB, "Displays the files in a directory.", LF, LF, "Syntax:", TAB, "DIR /H", LF, TAB, "DIR [wildspec] [/L|/2|/W] [/P|/N] [/A|/D|/S] [/C|/R]", LF, LF, TAB, "/H", TAB, "  gives this scree"
		db	"n", LF, TAB, "wildspec  files to be displayed (wildcards allowed)", LF, TAB, "/A", TAB, "  displays all files", LF, TAB, "/C or /R  make other switches default for next time", LF, TAB, "/D", TAB
		db	"  displays files without system attribute set (default)", LF, TAB, "/L", TAB, "  long format. Include size, date and time (default)", LF, TAB, "/2", TAB, "  as above except files are displayed i"
		db	"n two columns", LF, TAB, "/N", TAB, "  return to default paging switch", LF, TAB, "/P", TAB, "  pause at end of full page. Default is no paging", LF, TAB, "/S", TAB, "  displays files with sy"
		db	"stem attribute set", LF, TAB, "/W", TAB, "  wide format. Displays file and directory names only", LF, TAB, "none", TAB, "  no parameters displays all files using current default", LF, TAB, TAB
		db	"  switches", LF, "Example:", LF, TAB, "DIR /C /W", NUL
_help_echo	db	"ECHO", TAB, "Used in batch files, this command is used to display a message", LF, TAB, "to the screen.", LF, LF, "Syntax:", LF, TAB, "ECHO /H", LF, TAB, "ECHO [ON|OFF|string]", LF, LF, TAB, "/"
		db	"H", TAB, "gives this screen", LF, TAB, "ON", TAB, "turn echoing on (default)", LF, TAB, "OFF", TAB, "turn echoing off", LF, TAB, "string", TAB, "display ""string""", LF, LF, "Examples:", LF
		db	TAB, "ECHO OFF", LF, TAB, "ECHO You are running the %%OS%% operating system.", NUL
_help_eraq	db	"ERAQ", TAB, "Erases files but queries you before doing so.", LF, TAB, "ERAQ wildspec [/S]", LF, LF, TAB, "/H", TAB, "  gives this screen", LF, TAB, "/S", TAB, "  include system files", LF, TAB
		db	"wildspec  file to be deleted (wildcards allowed)", LF, LF, "Examples:", LF, TAB, "ERAQ *.EXE /S", LF, TAB, "ERAQ MYFILE.TXT", NUL
_help_erase	db	"ERASE", TAB, "Erases files. Can be abbreviated to ERA.", LF, LF, "Syntax:", LF, TAB, "ERASE /H", LF, TAB, "ERASE wildspec [/C|/P][/S]", LF, LF, TAB, "/H", TAB, "  gives this screen", LF, TAB
		db	"/C|/P", TAB, "  prompt before deletion", LF, TAB, "/S", TAB, "  include system files", LF, TAB, "wildspec  file to be deleted (wildcards allowed)", LF, LF, "Examples:", LF, TAB, "ERASE *.EXE"
		db	" /CS", LF, TAB, "ERA MYFILE.TXT", NUL
_help_exit	db	"EXIT", TAB, "Terminates a batch file or secondary command processor.", LF, LF, "Syntax:", LF, TAB, "EXIT [/H]", LF, LF, TAB, "/H", TAB, "gives this screen", LF, LF, "Example:", LF, TAB, "E"
		db	"XIT", NUL
_help_for	db	"FOR", TAB, "Most commonly used in batch files, this command is used to repeat", LF, TAB, "a sequence of commands substituting a filename from a list with each", LF, TAB, "iteration of the loop.", LF
		db	LF, "Syntax:", LF, TAB, "FOR /H", LF, TAB, "FOR %%[%%]var IN (fileset) DO command", LF, LF, TAB, "%%%%var", TAB, "  variable used to reference a filename in a batch file", LF, TAB, "%%var", TAB
		db	"  variable used to reference a filename at the command line", LF, TAB, "fileset", TAB, "  list of files to perform operation upon", LF, TAB, "command", TAB, "  operation to be performed", LF, LF
		db	"Example:", LF, TAB, "FOR %%%%f IN (myprog.asm acct.bas acct2.bas)DO TYPE %%%%f", LF, TAB, "FOR %%f IN (myprog.asm acct.bas acct2.bas)DO TYPE %%f", NUL
_help_goto	db	"GOTO", TAB, "Used in batch files, this command causes execution of commands", LF, TAB, "to alter to a specified point in the batch file.", LF, LF, "Syntax:", LF, TAB, "GOTO /H", LF, TAB, "GOTO"
		db	" label", LF, LF, TAB, "/H", TAB, "gives this screen", LF, TAB, "label", TAB, "label to jump to", LF, LF, "Example:", LF, TAB, ":start", LF, TAB, "type myfile.txt", LF, TAB, "goto start", NUL
_help_gosubreturn	db	"GOSUB/RETURN", LF, TAB, "The GOSUB command causes execution to jump to a specified point ", LF, TAB, "in a batch file. When a RETURN command is encountered, execution ", LF, TAB, "will continue f"
		db	"rom the line after the GOSUB.", LF, LF, "Syntax:", LF, TAB, "GOSUB label", LF, LF, "Example:", LF, TAB, "GOSUB myfunc", LF, TAB, "GOTO finished", LF, TAB, ":myfunc", LF, TAB, "ECHO Hello"
		db	LF, TAB, "RETURN", LF, TAB, ":finished", NUL
_help_switch	db	"SWITCH", TAB, "This command allows the user to select an entry from a menu ", LF, TAB, "in a batch file. The keys 1 - 9 will select the appropriate label ", LF, TAB, "from the command line. A RETU"
		db	"RN command returns execution to the ", LF, TAB, "line after the SWITCH command.", LF, LF, "Syntax:", LF, TAB, "SWITCH label [,label..]", LF, LF, "Example:", LF, TAB, "SWITCH label1,label2,la"
		db	"bel3,label4", LF, TAB, "GOTO finished", LF, TAB, ":label1", LF, TAB, "ECHO Hello", LF, TAB, "RETURN", LF, TAB, ":label2", LF, TAB, "ECHO World", LF, TAB, "RETURN", LF, TAB, "...", NUL
_help_idle	db	"IDLE", TAB, "Turns dynamic idle detection on or off.", LF, LF, "Syntax:", LF, TAB, "IDLE /H", LF, TAB, "IDLE [= ][ON|OFF]", LF, LF, TAB, "/H", TAB, "gives this screen", LF, TAB, "ON", TAB
		db	"enables idle detection", LF, TAB, "OFF", TAB, "disables idle detection", LF, TAB, "none", TAB, "no parameters displays the state ON or OFF", LF, LF, "Example:", LF, TAB, "IDLE = ON", LF, TAB
		db	"IDLE OFF", NUL
_help_if	db	"IF", TAB, "Used in batch files, this command allows conditional execution", LF, TAB, "of commands based upon specified conditions.", LF, LF, "Syntax:", TAB, "IF /H", LF, TAB, "IF [NOT] conditio"
		db	"n [AND [NOT] condition] [OR [NOT] condition] command", LF, LF, TAB, "/H", TAB, "   gives this screen", LF, LF, TAB, "condition  ERRORLEVEL [==] number", LF, TAB, TAB, "   EXIST [==] filespec"
		db	LF, TAB, TAB, "   string1 ==|!=|>|>=|<|<=|<> string2", LF, TAB, TAB, "   #value1 ==|!=|>|>=|<|<=|<> #value2", LF, LF, "Examples: IF EXIST c:\bin\editor.exe c:\bin\editor %%1", LF, TAB, "  IF "
		db	"NOT ""%%1"" == ""english"" ECHO Invalid Language Specified", LF, TAB, "  IF #%%mem%% < #540 ECHO Not Enough Memory", NUL
_help_and	db	"AND", TAB, "Used with the IF command.", LF, TAB, "Enter IF /? for more information.", LF, NUL
_help_or	db	"OR", TAB, "Used with the IF command.", LF, TAB, "Enter IF /? for more information.", LF, NUL
_help_mkdir	db	"MKDIR", TAB, "Creates a subdirectory. Can be abbreviated to MD.", LF, LF, "Syntax:", LF, TAB, "MKDIR /H", LF, TAB, "MKDIR [d:]dirpath", LF, LF, TAB, "/H", TAB, "  gives this screen", LF, TAB
		db	"d:", TAB, "  drive", LF, TAB, "dirpath", TAB, "  subdirectory to create", LF, LF, "Examples:", LF, TAB, "MKDIR \USERS\ROGER", LF, TAB, "MD ..\USERS\LESLEY", NUL
_help_path	db	"PATH", TAB, "Sets or displays a search path for commands or batch files.", LF, LF, "Syntax:", LF, TAB, "PATH /H", LF, TAB, "PATH [[d:]dirpath[;[d:]dirpath...]]", LF, LF, TAB, "d:", TAB, "dri"
		db	"ve on which dirpath resides", LF, TAB, "dirpath", TAB, "subdirectory path", LF, TAB, ";", TAB, "path separator, or on its own, sets PATH to nothing", LF, TAB, "none", TAB, "no parameters disp"
		db	"lays current path", LF, LF, "Examples:", LF, TAB, "PATH", LF, TAB, "PATH c:\osutils;c:\bin;d:\users\roger", LF, TAB, "PATH;", NUL
_help_pause	db	"PAUSE", TAB, "Used in batch files, this command halts execution of the batch", LF, TAB, "file until a key is pressed.", LF, LF, "Syntax:", LF, TAB, "PAUSE /H", LF, TAB, "PAUSE [comment]", LF, LF
		db	TAB, "/H", TAB, "gives this screen", LF, TAB, "comment", TAB, "displays ""comment"" if echo is on", LF, TAB, "none", TAB, "no parameters displays default pause message", LF, LF, "Examples:", LF
		db	TAB, "PAUSE", LF, TAB, "Strike a key when ready . . .", LF, LF, TAB, "PAUSE Put disk number 2 in drive A:", LF, TAB, "Strike a key when ready . . .", NUL
_help_prompt	db	"PROMPT", TAB, "Modifies the command prompt.", LF, LF, "Syntax:", TAB, "PROMPT /H or PROMPT [$list]", LF, LF, "Where list can be:", LF, "  $  $ character", TAB, TAB, "t  time", LF, "  d  date", TAB
		db	TAB, TAB, "p  current directory", LF, "  v  OS version number", TAB, TAB, "n  drive letter", LF, "  g  the "">"" character", TAB, TAB, "l  the ""<"" character", LF, "  b  the ""|"" character", TAB
		db	TAB, "q  the ""="" character", LF, "  h  backspace", TAB, TAB, TAB, "e  the escape character (ASCII 27)", LF, "  x  run the program defined in the PEXEC environment variable", LF, "  -  turns th"
		db	"e prompt off", LF, LF, "Example:", LF, "  PROMPT $p$g   ==>   C:\DIR>", NUL
_help_rem	db	"REM", TAB, "Used in batch files, this command causes the remainder of the", LF, TAB, "line to be ignored.", LF, LF, "Syntax:", LF, TAB, "REM /H", LF, TAB, "REM [comment]", LF, LF, TAB, "/H", TAB
		db	TAB, "gives this screen", LF, TAB, "comment", TAB, TAB, "comment text", LF, LF, "Examples:", LF, TAB, "REM Ignore the rest of this line", LF, TAB, "REM XDEL \*.* /sdrn THIS IS SAFE SINCE IT "
		db	"WONT GET EXECUTED", NUL
_help_rename	db	"RENAME", TAB, "Renames files, or moves files between subdirectories on the same", LF, TAB, "disk. Can be abbreviated to REN.", LF, LF, "Syntax:", LF, TAB, "RENAME /H", LF, TAB, "RENAME oldwild"
		db	"spec newwildspec", LF, LF, TAB, "/H", TAB, TAB, "gives this screen", LF, TAB, "oldwildspec", TAB, "full path and filename of source file(s)", LF, TAB, "newwildspec", TAB, "full path and fil"
		db	"ename of destination file(s)", LF, LF, "Examples:", LF, TAB, "RENAME *.TXT *.DOC", LF, TAB, "REN AUTOEXEC.BAT *.SAV", LF, TAB, "REN \MYFILE.BAT \ARCHIVE\MYFILE.BAT", NUL
_help_rmdir	db	"RMDIR", TAB, "Removes specified subdirectory. Can be abbreviated to RD.", LF, LF, "Syntax:", LF, TAB, "RMDIR /H", LF, TAB, "RMDIR [d:]dirpath", LF, LF, TAB, "/H", TAB, TAB, "gives this scre"
		db	"en", LF, TAB, "d:", TAB, TAB, "drive upon which dirpath resides", LF, TAB, "dirpath", TAB, TAB, "subdirectory to remove", LF, LF, "Examples:", LF, TAB, "RMDIR \users\ian", LF, TAB, "RD \"
		db	"work\test", NUL
_help_set	db	"SET", TAB, "Inserts strings into the command processors environment.", LF, LF, "Syntax:", LF, TAB, "SET /H", LF, TAB, "SET [name=[string]]", LF, LF, TAB, "/H", TAB, "gives this screen", LF, TAB
		db	"name=", TAB, "environment variable name to be assigned", LF, TAB, "string", TAB, "string to assign to name", LF, TAB, "none", TAB, "no parameters displays all environment strings", LF, LF, "E"
		db	"xamples:", LF, TAB, "SET archive=c:\archive\", LF, TAB, "SET flags=-b-t$r", LF, TAB, "SET backup=", NUL
_help_shift	db	"SHIFT", TAB, "Used in batch files, this command allows you to change the", LF, TAB, "position of command line parameters to access more than 10", LF, TAB, "(%%0 through %%9) replacement variables."
		db	LF, LF, "Syntax:", LF, TAB, "SHIFT [/H]", LF, LF, TAB, "/H", TAB, "gives this screen", LF, LF, "Example:", LF, TAB, ":loop", LF, TAB, "if ""%%1"" == """" goto done", LF, TAB, "copy %%1 "
		db	"c:\archive", LF, TAB, "shift", LF, TAB, "goto loop", LF, TAB, ":done", NUL
_help_time	db	"TIME", TAB, "Displays and changes the time of day.", LF, LF, "Syntax:", LF, TAB, "TIME /H", LF, TAB, "TIME [hh[:mm[:ss]][a|p] [/C]", LF, LF, TAB, "/H", TAB, "gives this screen", LF, TAB, "h"
		db	"h", TAB, "hours 0 to 23 (24 hour clock) or 1 to 12 if a or p specified", LF, TAB, "mm", TAB, "minutes 0 to 59", LF, TAB, "ss", TAB, "seconds 0 to 59", LF, TAB, "a|p", TAB, "am|pm", LF, TAB
		db	"/C", TAB, "displays time continuously", LF, TAB, "none", TAB, "no parameters displays the current time, then prompts for a", LF, TAB, TAB, "new time. Press Return to leave the time unchanged", LF
		db	LF, "Examples:", LF, TAB, "TIME 5:23:8", LF, TAB, "TIME 7:32", LF, TAB, "TIME", NUL
_help_type	db	"TYPE", TAB, "Displays the contents of a text file on screen.", LF, LF, "Syntax:", LF, TAB, "TYPE /H", LF, TAB, "TYPE wildspec [/P]", LF, LF, TAB, "/H", TAB, "  gives this screen", LF, TAB, "w"
		db	"ildspec  file to be displayed (wildcards allowed)", LF, TAB, "/P", TAB, "  pause when screen full", LF, LF, "Examples:", LF, TAB, "TYPE *.TXT /P", LF, TAB, "TYPE C:\AUTOEXEC.BAT", NUL
_help_ver	db	"VER", TAB, "Displays the version number of the operating system in use.", LF, LF, "Syntax:", LF, TAB, "VER [/H]", LF, LF, TAB, "/H", TAB, "gives this screen", LF, LF, "Example:", LF, TAB, "V"
		db	"ER", NUL
_help_verify	db	"VERIFY", TAB, "Switches the Verify option on or off, which causes the operating", LF, TAB, "system to check that data is correctly written to disk after each", LF, TAB, "disk write operation.", LF
		db	LF, "Syntax:", LF, TAB, "VERIFY /H", LF, TAB, "VERIFY [ON|OFF]", LF, LF, TAB, "/H", TAB, "gives this screen", LF, TAB, "ON", TAB, "turns VERIFY on", LF, TAB, "OFF", TAB, "turns VERIFY of"
		db	"f (default)", LF, TAB, "none", TAB, "no parameters displays the current VERIFY state, on or off", LF, LF, "Examples:", LF, TAB, "VERIFY ON", LF, TAB, "VERIFY", NUL
_help_vol	db	"VOL", TAB, "Displays the disk volume label.", LF, LF, "Syntax:", LF, TAB, "VOL /H", LF, TAB, "VOL [d:]", LF, LF, TAB, "/H", TAB, "gives this screen", LF, TAB, "d:", TAB, "drive to display"
		db	" volume label", LF, TAB, "none", TAB, "no parameters displays the volume label of the default drive", LF, LF, "Example:", LF, TAB, "VOL", NUL
_help_chcp	db	"CHCP", TAB, "Change the active Code Page.", LF, LF, "Syntax:", LF, TAB, "CHCP /H", LF, TAB, "CHCP [cp]", LF, LF, TAB, "/H", TAB, "gives this screen", LF, TAB, "cp", TAB, "new active Code "
		db	"Page", LF, TAB, "none", TAB, "no parameters displays the current active Code Page", LF, LF, "Example:", LF, TAB, "CHCP 850", NUL
_help_ctty	db	"CTTY", TAB, "Redirect console input and output to a port.", LF, LF, "Syntax:", LF, TAB, "CTTY /H", LF, TAB, "CTTY port", LF, LF, TAB, "/H", TAB, "gives this screen", LF, TAB, "port", TAB, "p"
		db	"ort to redirect to", LF, LF, "Example:", LF, TAB, "CTTY COM1:", NUL
_help_hiload	db	"HILOAD", TAB, "Load and execute a program in upper memory.", LF, LF, "Syntax:", LF, TAB, "HILOAD /H", LF, TAB, "HILOAD fname", LF, LF, TAB, "/H", TAB, "gives this screen", LF, TAB, "fname", TAB
		db	"filename of program to load", LF, LF, TAB, "(LOADHIGH and LH can be used instead of HILOAD)", LF, LF, "HILOAD only has an effect if MemoryMAX software is present and there is", LF, "upper memory"
		db	" available. If this is not so then the program will load and", LF, "execute in conventional memory.", LF, LF, "Example:", LF, TAB, "HILOAD CURSOR", NUL

_HELP	ends


_TEXT	segment word public 'CODE'
	assume	cs:_TEXT, ds:DGROUP

; unsigned dls_language(void)
_dls_language	proc near

	xor	ax, ax
	ret

_dls_language	endp

; void dls_init(void)
_dls_init	proc near

	inc	__dls_init__
	ret

_dls_init	endp

; void * dls_get_table(unsigned param)
_dls_get_table	proc near

	mov	al, __dls_init__
	cbw
	test	al, al
	je	dls_gt_end
	mov	ax, offset DGROUP:_single_table
	mov	word ptr _dls_table, ax

dls_gt_end:
	ret

_dls_get_table	endp

_TEXT	ends


	end
