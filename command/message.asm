NUL	equ	0
BS	equ	8
TAB	equ	9
LF	equ	10
CR	equ	13

CGROUP	group	_MSG

_MSG	segment	word public 'CODE'
	assume ds:CGROUP, cs:CGROUP

;		Source .TFT file: 'TMP1.$$$'
	public	_msg_ver111
	public	msg_ver111
msg_ver111	label	byte
_msg_ver111	db	NUL , NUL
	public	_msg_lbl
	public	msg_lbl
msg_lbl	label	byte
_msg_lbl	db	LF, " Volume in drive %c ", NUL
	public	_msg_oklbl
	public	msg_oklbl
msg_oklbl	label	byte
_msg_oklbl	db	"is %s", NUL
	public	_msg_nolbl
	public	msg_nolbl
msg_nolbl	label	byte
_msg_nolbl	db	"does not have a label", NUL
	public	_msg_files
	public	msg_files
msg_files	label	byte
_msg_files	db	"File(s)", NUL
	public	_msg_free
	public	msg_free
msg_free	label	byte
_msg_free	db	"bytes free", NUL
	public	_msg_invalid_file
	public	msg_invalid_file
msg_invalid_file	label	byte
_msg_invalid_file	db	"Destination must be a file", NUL
	public	_msg_exist
	public	msg_exist
msg_exist	label	byte
_msg_exist	db	"%s files exist", LF, NUL
	public	_msg_ndir
	public	msg_ndir
msg_ndir	label	byte
_msg_ndir	db	"System", NUL
	public	_msg_nsys
	public	msg_nsys
msg_nsys	label	byte
_msg_nsys	db	"Directory", NUL
	public	_msg_badopt
	public	msg_badopt
msg_badopt	label	byte
_msg_badopt	db	"Invalid option:  `%c%c'", NUL
	public	_msg_full
	public	msg_full
msg_full	label	byte
_msg_full	db	LF, "Disk full", LF, NUL
	public	_msg_devfail
	public	msg_devfail
msg_devfail	label	byte
_msg_devfail	db	LF, "Failure writing to device", LF, NUL
	public	_msg_syntax
	public	msg_syntax
msg_syntax	label	byte
_msg_syntax	db	"Syntax Error", LF, NUL
	public	_msg_badcmd
	public	msg_badcmd
msg_badcmd	label	byte
_msg_badcmd	db	"Command or filename not recognized", LF, NUL
	public	_msg_pathdrv
	public	msg_pathdrv
msg_pathdrv	label	byte
_msg_pathdrv	db	"Search path contains invalid drive", LF, NUL
	public	_msg_optline
	public	msg_optline
msg_optline	label	byte
_msg_optline	db	"%s (Y/N) ? ", NUL
	public	_msg_batterm
	public	msg_batterm
msg_batterm	label	byte
_msg_batterm	db	"Halt Batch Process (Y/N) ? ", NUL
	public	_msg_batmiss
	public	msg_batmiss
msg_batmiss	label	byte
_msg_batmiss	db	"Batch file %s missing", LF, NUL
	public	_msg_batnest
	public	msg_batnest
msg_batnest	label	byte
_msg_batnest	db	LF, "Batch files nested too deeply", LF, NUL
	public	_msg_dir
	public	msg_dir
msg_dir	label	byte
_msg_dir	db	" Directory of  %s\%s", LF, NUL
	public	_msg_echo
	public	msg_echo
msg_echo	label	byte
_msg_echo	db	"ECHO = %s", LF, NUL
	public	_msg_xbatch
	public	msg_xbatch
msg_xbatch	label	byte
_msg_xbatch	db	"Batch Enhancer is %s", LF, NUL
	public	_msg_eraq
	public	msg_eraq
msg_eraq	label	byte
_msg_eraq	db	"%s (Y/N) ? ", NUL
	public	_msg_eraall
	public	msg_eraall
msg_eraall	label	byte
_msg_eraall	db	"Are you sure (Y/N) ? ", NUL
	public	_msg_era
	public	msg_era
msg_era	label	byte
_msg_era	db	"File not erased: %s - ", NUL
	public	_msg_label
	public	msg_label
msg_label	label	byte
_msg_label	db	"Label ""%s"" not found", NUL
	public	_msg_gosub
	public	msg_gosub
msg_gosub	label	byte
_msg_gosub	db	"GOSUBs nested too deeply", LF, NUL
	public	_msg_return
	public	msg_return
msg_return	label	byte
_msg_return	db	"RETURN without GOSUB encountered", LF, NUL
	public	_msg_mkdir
	public	msg_mkdir
msg_mkdir	label	byte
_msg_mkdir	db	"Unable to create directory", LF, NUL
	public	_msg_path
	public	msg_path
msg_path	label	byte
_msg_path	db	"No Path", LF, NUL
	public	_path_template
	public	path_template
path_template	label	byte
_path_template	db	"%.122s", LF, NUL
	public	_msg_ren
	public	msg_ren
msg_ren	label	byte
_msg_ren	db	"File already exists", LF, NUL
	public	_msg_use_rendir
	public	msg_use_rendir
msg_use_rendir	label	byte
_msg_use_rendir	db	"Use RENDIR to rename directories", LF, NUL
	public	_msg_rmdir
	public	msg_rmdir
msg_rmdir	label	byte
_msg_rmdir	db	"Directory invalid, in use, or not empty", LF, NUL
	public	_msg_break
	public	msg_break
msg_break	label	byte
_msg_break	db	"BREAK = %s", LF, NUL
	public	_msg_verify
	public	msg_verify
msg_verify	label	byte
_msg_verify	db	"VERIFY = %s", LF, NUL
	public	_msg_idle
	public	msg_idle
msg_idle	label	byte
_msg_idle	db	"IDLE detection is %s", LF, NUL
	public	_help_prog
	public	help_prog
help_prog	label	byte
_help_prog	db	"help$.exe", NUL
	public	_msg_nohelpprog
	public	msg_nohelpprog
msg_nohelpprog	label	byte
_msg_nohelpprog	db	"Cannot find help file HELP$.EXE", LF, NUL
	public	_help_com
	public	help_com
help_com	label	byte
_help_com	db	"COMMAND", TAB, "Executes a second copy of the default command processor.", LF, LF, "Syntax:", TAB, "COMMAND /H", LF, TAB, "COMMAND [dirpath][ /E:n][ /P[:filename]][ /Mx][ /Ccommand]", LF, LF, TAB
		db	"/H", TAB, "gives this screen.", LF, TAB, "dirpath", TAB, "drive and path to be used to reload COMMAND.COM.", LF, TAB, "/E:n", TAB, "allocate n number of bytes to the environment (512 default).", LF
		db	TAB, "/P", TAB, "Makes COMMAND.COM permanent. EXIT will not terminate it.", LF, TAB, TAB, "Optional filename causes filename to be used instead of", LF, TAB, TAB, "AUTOEXEC.BAT.", LF, TAB, "/"
		db	"C", TAB, "Executes ""command"" then terminates.", LF, TAB, "/ML", TAB, "Force resident portion to be in conventional (low) memory.", LF, TAB, "/MU", TAB, "Force resident portion to be in UPPER "
		db	"memory.", LF, TAB, "/MH", TAB, "Force resident portion to be in HIGH memory.", LF, LF, "Examples:", LF, TAB, "COMMAND /E:1024 /P", LF, TAB, "COMMAND /Cdir c:", LF, NUL
	public	_msg_curcp
	public	msg_curcp
msg_curcp	label	byte
_msg_curcp	db	"Active Code Page is %d", LF, NUL
	public	_msg_badcp
	public	msg_badcp
msg_badcp	label	byte
_msg_badcp	db	"Code Page %d has not been prepared", LF, NUL
	public	_msg_cpnf
	public	msg_cpnf
msg_cpnf	label	byte
_msg_cpnf	db	"Invalid Code Page, NLSFUNC not loaded, or COUNTRY.SYS not found", LF, NUL
	public	_msg_netsubst
	public	msg_netsubst
msg_netsubst	label	byte
_msg_netsubst	db	"Cannot SUBST a Networked Drive", LF, NUL
	public	_msg_netassign
	public	msg_netassign
msg_netassign	label	byte
_msg_netassign	db	"Cannot ASSIGN a Networked Drive", LF, NUL
	public	_msg_cpyright
	public	msg_cpyright
msg_cpyright	label	byte
_msg_cpyright	db	"Copyright (c) 1976, 1997 Caldera, Inc. ", LF, "All rights reserved.", LF, NUL
	public	_msg_serialno
	public	msg_serialno
msg_serialno	label	byte
_msg_serialno	db	"Serial number %s", LF, NUL
	public	_msg_oempatch
	public	msg_oempatch
msg_oempatch	label	byte
_msg_oempatch	db	"SeRiAlNuMbEr=", NUL
	public	_msg_serno
	public	msg_serno
msg_serno	label	byte
_msg_serno	db	0, "XXX-0000-987654321X", NUL
	public	_msg_oemcpyrt
	public	msg_oemcpyrt
msg_oemcpyrt	label	byte
_msg_oemcpyrt	db	LF, "LICENSED FOR NON-COMMERCIAL USE ONLY", LF, 0, "FILLERFILLERFILLERFILLER", NUL
	public	_msg_version
	public	msg_version
msg_version	label	byte
_msg_version	db	LF, "Caldera OpenDOS %s.01", LF, NUL
	public	_msg_cpyself
	public	msg_cpyself
msg_cpyself	label	byte
_msg_cpyself	db	"Source and Destination cannot be the same file", LF, NUL
	public	_msg_fcopied
	public	msg_fcopied
msg_fcopied	label	byte
_msg_fcopied	db	" File(s) copied", LF, NUL
	public	_msg_envfull
	public	msg_envfull
msg_envfull	label	byte
_msg_envfull	db	"Environment Full", NUL
	public	_msg_enverr
	public	msg_enverr
msg_enverr	label	byte
_msg_enverr	db	"Environment error", NUL
	public	_msg_bados
	public	msg_bados
msg_bados	label	byte
_msg_bados	db	"Incorrect version of Operating System", LF, NUL
	public	_msg_loadpath
	public	msg_loadpath
msg_loadpath	label	byte
_msg_loadpath	db	"Invalid COMMAND search directory specified", LF, LF, NUL
	public	_msg_inop
	public	msg_inop
msg_inop	label	byte
_msg_inop	db	"Wrong number of parameters", LF, NUL
	public	_msg_binrd
	public	msg_binrd
msg_binrd	label	byte
_msg_binrd	db	"Binary reads from a device are not allowed", LF, NUL
	public	_msg_dlost
	public	msg_dlost
msg_dlost	label	byte
_msg_dlost	db	"Destination file contents lost before copy", LF, NUL
	public	_msg_onoff
	public	msg_onoff
msg_onoff	label	byte
_msg_onoff	db	"ON or OFF parameter required", LF, NUL
	public	_err_file
	public	err_file
err_file	label	byte
_err_file	db	"Filename too long", LF, NUL
	public	_err02
	public	err02
err02	label	byte
_err02		db	"File not found", NUL
	public	_err03
	public	err03
err03	label	byte
_err03		db	"Invalid directory specified", NUL
	public	_err04
	public	err04
err04	label	byte
_err04		db	"Too many files open", NUL
	public	_err05
	public	err05
err05	label	byte
_err05		db	"Access denied", NUL
	public	_err08
	public	err08
err08	label	byte
_err08		db	"Not enough Memory", NUL
	public	_err15
	public	err15
err15	label	byte
_err15		db	"Invalid drive specified", NUL
	public	_err19
	public	err19
err19	label	byte
_err19		db	"Disk write-protected", NUL
	public	_err20
	public	err20
err20	label	byte
_err20		db	"File Sharing Conflict", NUL
	public	_err83
	public	err83
err83	label	byte
_err83		db	"Physical Media Error", NUL
	public	_err86
	public	err86
err86	label	byte
_err86		db	"Invalid Password", NUL
	public	_msg_needpath
	public	msg_needpath
msg_needpath	label	byte
_msg_needpath	db	"Path required", NUL
	public	_msg_needfile
	public	msg_needfile
msg_needfile	label	byte
_msg_needfile	db	"Filename(s) required", NUL
	public	_msg_needdev
	public	msg_needdev
msg_needdev	label	byte
_msg_needdev	db	"Device name required", NUL
	public	_msg_drv_invalid
	public	msg_drv_invalid
msg_drv_invalid	label	byte
_msg_drv_invalid	db	"Current drive is no longer valid", NUL
	public	_sun_d
	public	sun_d
sun_d	label	byte
_sun_d		db	"Sun", NUL
	public	_mon_d
	public	mon_d
mon_d	label	byte
_mon_d		db	"Mon", NUL
	public	_tue_d
	public	tue_d
tue_d	label	byte
_tue_d		db	"Tue", NUL
	public	_wed_d
	public	wed_d
wed_d	label	byte
_wed_d		db	"Wed", NUL
	public	_thu_d
	public	thu_d
thu_d	label	byte
_thu_d		db	"Thu", NUL
	public	_fri_d
	public	fri_d
fri_d	label	byte
_fri_d		db	"Fri", NUL
	public	_sat_d
	public	sat_d
sat_d	label	byte
_sat_d		db	"Sat", NUL
	public	_jan_m
	public	jan_m
jan_m	label	byte
_jan_m		db	"January", NUL
	public	_feb_m
	public	feb_m
feb_m	label	byte
_feb_m		db	"February", NUL
	public	_mar_m
	public	mar_m
mar_m	label	byte
_mar_m		db	"March", NUL
	public	_apr_m
	public	apr_m
apr_m	label	byte
_apr_m		db	"April", NUL
	public	_may_m
	public	may_m
may_m	label	byte
_may_m		db	"May", NUL
	public	_jun_m
	public	jun_m
jun_m	label	byte
_jun_m		db	"June", NUL
	public	_jul_m
	public	jul_m
jul_m	label	byte
_jul_m		db	"July", NUL
	public	_aug_m
	public	aug_m
aug_m	label	byte
_aug_m		db	"August", NUL
	public	_sep_m
	public	sep_m
sep_m	label	byte
_sep_m		db	"September", NUL
	public	_oct_m
	public	oct_m
oct_m	label	byte
_oct_m		db	"October", NUL
	public	_nov_m
	public	nov_m
nov_m	label	byte
_nov_m		db	"November", NUL
	public	_dec_m
	public	dec_m
dec_m	label	byte
_dec_m		db	"December", NUL
	public	_am_time
	public	am_time
am_time	label	byte
_am_time	db	"am", NUL
	public	_pm_time
	public	pm_time
pm_time	label	byte
_pm_time	db	"pm", NUL
	public	_greeting_morning
	public	greeting_morning
greeting_morning	label	byte
_greeting_morning	db	"morning", NUL
	public	_greeting_afternoon
	public	greeting_afternoon
greeting_afternoon	label	byte
_greeting_afternoon	db	"afternoon", NUL
	public	_greeting_evening
	public	greeting_evening
greeting_evening	label	byte
_greeting_evening	db	"evening", NUL
	public	_cur_time
	public	cur_time
cur_time	label	byte
_cur_time	db	"Time: ", NUL
	public	_new_time
	public	new_time
new_time	label	byte
_new_time	db	LF, "Enter time: ", NUL
	public	_inv_time
	public	inv_time
inv_time	label	byte
_inv_time	db	LF, "Invalid time specified", NUL
	public	_cur_date
	public	cur_date
cur_date	label	byte
_cur_date	db	"Date: ", NUL
	public	_new_date
	public	new_date
new_date	label	byte
_new_date	db	LF, "Enter date (%s): ", NUL
	public	_inv_date
	public	inv_date
inv_date	label	byte
_inv_date	db	LF, "Invalid date specified", NUL
	public	_us_date
	public	us_date
us_date	label	byte
_us_date	db	"mm-dd-yy", NUL
	public	_euro_date
	public	euro_date
euro_date	label	byte
_euro_date	db	"dd-mm-yy", NUL
	public	_jap_date
	public	jap_date
jap_date	label	byte
_jap_date	db	"yy-mm-dd", NUL
	public	_inv_num
	public	inv_num
inv_num	label	byte
_inv_num	db	"Invalid Number", LF, NUL
	public	_msg_inactive
	public	msg_inactive
msg_inactive	label	byte
_msg_inactive	db	"Input Redirection Already Active", NUL
	public	_msg_outactive
	public	msg_outactive
msg_outactive	label	byte
_msg_outactive	db	"Output Redirection Already Active", NUL
	public	_msg_on
	public	msg_on
msg_on	label	byte
_msg_on		db	"on", NUL
	public	_msg_off
	public	msg_off
msg_off	label	byte
_msg_off	db	"off", NUL
	public	_yes_no
	public	yes_no
yes_no	label	byte
_yes_no		db	"YN", NUL
	public	_msg_pause
	public	msg_pause
msg_pause	label	byte
_msg_pause	db	"Strike a key when ready . . . ", NUL
	public	_msg_disabled
	public	msg_disabled
msg_disabled	label	byte
_msg_disabled	db	"IDLE is disabled", NUL
	public	_msg_internal
	public	msg_internal
msg_internal	label	byte
_msg_internal	db	"Internal Error Code %03d", NUL
	public	_msg_network
	public	msg_network
msg_network	label	byte
_msg_network	db	"Network Error %03d", NUL
	public	_msg_debug
	public	msg_debug
msg_debug	label	byte
_msg_debug	db	"DEBUG is %s", LF, NUL
	public	_msg_longjmp
	public	msg_longjmp
msg_longjmp	label	byte
_msg_longjmp	db	"LONGJMP Error %d", LF, NUL
	public	_msg_nohelp
	public	msg_nohelp
msg_nohelp	label	byte
_msg_nohelp	db	"Unable to give Help. Cannot find file %s.", LF, NUL

_MSG	ends


	end
