/*
;    File              : $Workfile$
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
;
;    ENDLOG
*/

#include <message.h>

#if defined(DLS)
EXTERN	BYTE * cdecl dls_msg1(UWORD);

#define	MSG_LBL		dls_msg1(DLS_msg_lbl)
#define	MSG_OKLBL	dls_msg1(DLS_msg_oklbl)
#define	MSG_NOLBL	dls_msg1(DLS_msg_nolbl)
#define	MSG_FILES	dls_msg1(DLS_msg_files)
#define	MSG_FREE	dls_msg1(DLS_msg_free)
#define	MSG_EXIST	dls_msg1(DLS_msg_exist)
#define	MSG_NDIR	dls_msg1(DLS_msg_ndir)
#define	MSG_NSYS	dls_msg1(DLS_msg_nsys)
#define	MSG_BADOPT	dls_msg1(DLS_msg_badopt)
#define	MSG_FULL	dls_msg1(DLS_msg_full)
#define	MSG_SYNTAX	dls_msg1(DLS_msg_syntax)
#define	MSG_BADCMD	dls_msg1(DLS_msg_badcmd)
#define	MSG_PATHDRV	dls_msg1(DLS_msg_pathdrv)
#define	MSG_BATTERM	dls_msg1(DLS_msg_batterm)
#define	MSG_BATMISS	dls_msg1(DLS_msg_batmiss)
#define	MSG_BATNEST	dls_msg1(DLS_msg_batnest)
#define	MSG_DIR		dls_msg1(DLS_msg_dir)
#define	MSG_ECHO	dls_msg1(DLS_msg_echo)
#define	MSG_ERAQ	dls_msg1(DLS_msg_eraq)
#define	MSG_ERAALL	dls_msg1(DLS_msg_eraall)
#define	MSG_ERA		dls_msg1(DLS_msg_era)
#define	MSG_LABEL	dls_msg1(DLS_msg_label)
#define	MSG_MKDIR	dls_msg1(DLS_msg_mkdir)
#define	MSG_PATH	dls_msg1(DLS_msg_path)
#define	MSG_REN		dls_msg1(DLS_msg_ren)
#define MSG_USE_RENDIR	dls_msg1(DLS_msg_use_rendir)
#define	MSG_RMDIR	dls_msg1(DLS_msg_rmdir)
#define	MSG_BREAK	dls_msg1(DLS_msg_break)
#define	MSG_VERIFY	dls_msg1(DLS_msg_verify)
#define	MSG_IDLE	dls_msg1(DLS_msg_idle)
#define	MSG_CPYRIGHT	dls_msg1(DLS_msg_cpyright)
#define	MSG_VERSION	dls_msg1(DLS_msg_version)
#define	MSG_CPYSELF	dls_msg1(DLS_msg_cpyself)
#define	MSG_FCOPIED	dls_msg1(DLS_msg_fcopied)
#define MSG_DISABLED	dls_msg1(DLS_msg_disabled)
#define	MSG_ENVFULL	dls_msg1(DLS_msg_envfull)
#define	MSG_ENVERR	dls_msg1(DLS_msg_enverr)
#define	MSG_BADOS	dls_msg1(DLS_msg_bados)
#define	MSG_LOADPATH	dls_msg1(DLS_msg_loadpath)
#define	MSG_INOP	dls_msg1(DLS_msg_inop)
#define	MSG_BINRD	dls_msg1(DLS_msg_binrd)
#define	MSG_DLOST	dls_msg1(DLS_msg_dlost)
#define	MSG_ONOFF	dls_msg1(DLS_msg_onoff)
#define	MSG_NETWORK	dls_msg1(DLS_msg_network)
#define	ERR_FILE	dls_msg1(DLS_err_file)
#define	ERR02		dls_msg1(DLS_err02)
#define	ERR03		dls_msg1(DLS_err03)
#define	ERR04		dls_msg1(DLS_err04)
#define	ERR05		dls_msg1(DLS_err05)
#define	ERR08		dls_msg1(DLS_err08)
#define	ERR15		dls_msg1(DLS_err15)
#define	ERR20		dls_msg1(DLS_err20)
#define	ERR83		dls_msg1(DLS_err83)
#define	ERR86		dls_msg1(DLS_err86)
#define	ERR19		dls_msg1(DLS_err19)
#define	MSG_NEEDPATH	dls_msg1(DLS_msg_needpath)
#define	MSG_NEEDFILE	dls_msg1(DLS_msg_needfile)
#define	MSG_NEEDDEV	dls_msg1(DLS_msg_needdev)
#define	SUN_D		dls_msg1(DLS_sun_d)
#define	MON_D		dls_msg1(DLS_mon_d)
#define	TUE_D		dls_msg1(DLS_tue_d)
#define	WED_D		dls_msg1(DLS_wed_d)
#define	THU_D		dls_msg1(DLS_thu_d)
#define	FRI_D		dls_msg1(DLS_fri_d)
#define	SAT_D		dls_msg1(DLS_sat_d)
#define	CUR_TIME	dls_msg1(DLS_cur_time)
#define	NEW_TIME	dls_msg1(DLS_new_time)
#define	INV_TIME	dls_msg1(DLS_inv_time)
#define	CUR_DATE	dls_msg1(DLS_cur_date)
#define	NEW_DATE	dls_msg1(DLS_new_date)
#define	INV_DATE	dls_msg1(DLS_inv_date)
#define	US_DATE		dls_msg1(DLS_us_date)
#define	EURO_DATE	dls_msg1(DLS_euro_date)
#define	JAP_DATE	dls_msg1(DLS_jap_date)
#define	INV_NUM		dls_msg1(DLS_inv_num)
#define	MSG_LONGJMP	dls_msg1(DLS_msg_longjmp)
#define	MSG_INACTIVE	dls_msg1(DLS_msg_inactive)
#define	MSG_OUTACTIVE	dls_msg1(DLS_msg_outactive)
#define	MSG_ON		dls_msg1(DLS_msg_on)
#define	MSG_OFF		dls_msg1(DLS_msg_off)
#define	YES_NO		dls_msg1(DLS_yes_no)
#define	MSG_PAUSE	dls_msg1(DLS_msg_pause)
#define	MSG_INTERNAL	dls_msg1(DLS_msg_internal)
#define	MSG_DEBUG	dls_msg1(DLS_msg_debug)
#define	MSG_DEVFAIL	dls_msg1(DLS_msg_devfail)
#define	HELP_COM	dls_msg1(DLS_help_com)
#define MSG_GOSUB	dls_msg1(DLS_msg_gosub)
#define MSG_RETURN	dls_msg1(DLS_msg_return)
#define MSG_OPTLINE	dls_msg1(DLS_msg_optline)
#define AM_TIME		dls_msg1(DLS_am_time)
#define PM_TIME		dls_msg1(DLS_pm_time)
#define GREETING_MORNING   dls_msg1(DLS_greeting_morning)
#define GREETING_AFTERNOON dls_msg1(DLS_greeting_afternoon)
#define GREETING_EVENING   dls_msg1(DLS_greeting_evening)
#define	JAN_M		dls_msg1(DLS_jan_m)
#define	FEB_M		dls_msg1(DLS_feb_m)
#define	MAR_M		dls_msg1(DLS_mar_m)
#define	APR_M		dls_msg1(DLS_apr_m)
#define	MAY_M		dls_msg1(DLS_may_m)
#define	JUN_M		dls_msg1(DLS_jun_m)
#define	JUL_M		dls_msg1(DLS_jul_m)
#define	AUG_M		dls_msg1(DLS_aug_m)
#define	SEP_M		dls_msg1(DLS_sep_m)
#define	OCT_M		dls_msg1(DLS_oct_m)
#define	NOV_M		dls_msg1(DLS_nov_m)
#define	DEC_M		dls_msg1(DLS_dec_m)
#define MSG_DRV_INVALID dls_msg1(DLS_msg_drv_invalid)

#define	MSG_CURCP	dls_msg1(DLS_msg_curcp)
#define	MSG_BADCP	dls_msg1(DLS_msg_badcp)
#define	MSG_CPNF	dls_msg1(DLS_msg_cpnf)
#define	MSG_NETSUBST	dls_msg1(DLS_msg_netsubst)
#define	MSG_NETASSIGN	dls_msg1(DLS_msg_netassign)
#define	MSG_OEMCPYRT	dls_msg1(DLS_msg_oemcpyrt)
#define	MSG_SERNO	dls_msg1(DLS_msg_serialno)

#else

#define	MSG_LBL		msg_lbl		
#define	MSG_OKLBL	msg_oklbl	
#define	MSG_NOLBL	msg_nolbl	
#define	MSG_FILES	msg_files	
#define	MSG_FREE	msg_free	
#define	MSG_EXIST	msg_exist	
#define	MSG_NDIR	msg_ndir	
#define	MSG_NSYS	msg_nsys	
#define	MSG_BADOPT	msg_badopt	
#define	MSG_FULL	msg_full	
#define MSG_DEVFAIL	msg_devfail
#define	MSG_SYNTAX	msg_syntax	
#define	MSG_BADCMD	msg_badcmd	
#define	MSG_PATHDRV	msg_pathdrv	
#define MSG_OPTLINE	msg_optline
#define	MSG_BATTERM	msg_batterm	
#define	MSG_BATMISS	msg_batmiss	
#define	MSG_BATNEST	msg_batnest	
#define	MSG_DIR		msg_dir		
#define	MSG_ECHO	msg_echo	
#define	MSG_XBATCH	msg_xbatch
#define	MSG_ERAQ	msg_eraq	
#define	MSG_ERAALL	msg_eraall	
#define	MSG_ERA		msg_era		
#define	MSG_LABEL	msg_label	
#define MSG_GOSUB	msg_gosub
#define MSG_RETURN	msg_return
#define	MSG_MKDIR	msg_mkdir	
#define	MSG_PATH	msg_path	
#define	MSG_REN		msg_ren		
#define MSG_USE_RENDIR	msg_use_rendir
#define	MSG_RMDIR	msg_rmdir	
#define	MSG_BREAK	msg_break	
#define	MSG_VERIFY	msg_verify	
#define	MSG_IDLE	msg_idle	
#define	MSG_CPYRIGHT	msg_cpyright	
#define	MSG_VERSION	msg_version	
#define	MSG_CPYSELF	msg_cpyself	
#define	MSG_FCOPIED	msg_fcopied	
#define	MSG_DISABLED	msg_disabled
#define	MSG_ENVFULL	msg_envfull	
#define	MSG_ENVERR	msg_enverr	
#define	MSG_BADOS	msg_bados	
#define	MSG_LOADPATH	msg_loadpath	
#define	MSG_INOP	msg_inop	
#define	MSG_BINRD	msg_binrd	
#define	MSG_DLOST	msg_dlost	
#define	MSG_ONOFF	msg_onoff	
#define	ERR_FILE	err_file	
#define	ERR02		err02		
#define	ERR03		err03		
#define	ERR04		err04		
#define	ERR05		err05		
#define	ERR08		err08		
#define	ERR15		err15		
#define	ERR20		err20		
#define	ERR83		err83		
#define	ERR86		err86		
#define	ERR19		err19
#define	MSG_NEEDPATH	msg_needpath	
#define	MSG_NEEDFILE	msg_needfile	
#define	MSG_NEEDDEV	msg_needdev	
#define	SUN_D		sun_d		
#define	MON_D		mon_d		
#define	TUE_D		tue_d		
#define	WED_D		wed_d		
#define	THU_D		thu_d		
#define	FRI_D		fri_d		
#define	SAT_D		sat_d		
#define JAN_M		jan_m
#define FEB_M		feb_m
#define MAR_M		mar_m
#define APR_M		apr_m
#define MAY_M		may_m
#define JUN_M		jun_m
#define JUL_M		jul_m
#define AUG_M		aug_m
#define SEP_M		sep_m
#define OCT_M		oct_m
#define NOV_M		nov_m
#define DEC_M		dec_m
#define	CUR_TIME	cur_time	
#define	NEW_TIME	new_time	
#define	INV_TIME	inv_time	
#define	CUR_DATE	cur_date	
#define	NEW_DATE	new_date	
#define	INV_DATE	inv_date	
#define	US_DATE		us_date		
#define	EURO_DATE	euro_date	
#define	JAP_DATE	jap_date	
#define	INV_NUM		inv_num		
#define	MSG_INACTIVE	msg_inactive	
#define	MSG_OUTACTIVE	msg_outactive	
#define	MSG_ON		msg_on		
#define	MSG_OFF		msg_off		
#define	YES_NO		yes_no		
#define	MSG_PAUSE	msg_pause	
#define	MSG_INTERNAL	msg_internal
#define	MSG_NETWORK	msg_network
#define	MSG_DEBUG	msg_debug
#define	MSG_LONGJMP	msg_longjmp
/*RG-05*/
#define	HELP_COM    help_com
#define	HELP_PROG   help_prog
#define	MSG_NOHELPPROG  msg_nohelpprog
/*RG-05-end*/

#define	AM_TIME		am_time
#define	PM_TIME		pm_time

#define GREETING_MORNING	greeting_morning
#define GREETING_AFTERNOON	greeting_afternoon
#define GREETING_EVENING	greeting_evening

#define MSG_DRV_INVALID		msg_drv_invalid

#if	defined(CPM)
#define	CUR_USER	cur_user	
#define	INV_USER	inv_user	
#define	MSG_SINGLECPM	msg_singlecpm	
#endif


#if	defined(CDOSTMP) || defined(CPM)
#define	MSG_CE_NO0	msg_ce_no0	
#define	MSG_CE_NO2	msg_ce_no2	
#define	MSG_CE_NO3	msg_ce_no3	
#define	MSG_CE_NO4	msg_ce_no4	
#define	MSG_CE_NO6	msg_ce_no6	
#define	MSG_CE_NO7	msg_ce_no7	
#define	MSG_CE_NO8	msg_ce_no8	
#define	MSG_DRIVE	msg_drive	
#define	MSG_READ	msg_read	
#define	MSG_WRITE	msg_write	
#define	MSG_ABORT	msg_abort	
#define	MSG_RETRY	msg_retry	
#define	MSG_IGNORE	msg_ignore	
#define	MSG_FAIL	msg_fail	
#define	MSG_NE_NO0	msg_ne_no0	
#define	MSG_NE_NO1	msg_ne_no1	
#define	MSG_NE_NO2	msg_ne_no2	
#define	MSG_NE_NO3	msg_ne_no3	
#define	MSG_NE_NO4	msg_ne_no4	
#define	MSG_NE_NO5	msg_ne_no5	
#define	MSG_NE_NO6	msg_ne_no6	
#define	MSG_SERVER	msg_server	
#endif


#if	defined(CDOSTMP) || defined(CDOS)
#define	MSG_NOGOOD	msg_nogood	
#define	MSG_NOFAIL	msg_nofail	
#define	MSG_NOATCH	msg_noatch	
#define	MSG_NFGOOD	msg_nfgood	
#define	MSG_NFFAIL	msg_nffail	
#define	MSG_NFATCH	msg_nfatch	
#define	MSG_PWDPRMPT	msg_pwdprmpt	
#define	MSG_BADSTOP	msg_badstop	
#define	MSG_BANK	msg_bank	
#define	MSG_SUSPEND	msg_suspend	
#define	MSG_MEMSIZE	msg_memsize	
#define	MSG_LIMSIZE	msg_limsize	
#define	MSG_LOCAL	msg_local	
#define	MSG_REMOTE	msg_remote	
#define	MSG_APPEND	msg_append	
#define	MSG_CPYPRMPT	msg_cpyprmpt	
#define	ERR_RSC		err_rsc		
#define	MSG_LIMOFF	msg_limoff	
/*RG-01*/
#if !defined(NOSECURITY)
#define MSG_UHAVEMAIL msg_uhavemail
#endif
/*RG-01-end*/
/*RG-05-*/
#define MSG_HELP    msg_help
/*RG-05-end*/
#endif

#if	defined(DOSPLUS)
#define	MSG_CURCP	msg_curcp	
#define	MSG_BADCP	msg_badcp	
#define	MSG_CPNF	msg_cpnf	
#define	MSG_NETSUBST	msg_netsubst
#define	MSG_NETASSIGN	msg_netassign
#define	MSG_OEMCPYRT	msg_oemcpyrt	
#define	MSG_SERIALNO	msg_serialno
#endif

#endif
