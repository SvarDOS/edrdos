/*
;    File              : $Workfile: CMDLIST.C$
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
;    CMDLIST.C 1.18 94/08/09 15:47:05 
;    Fixed TRUENAME help.
;    CMDLIST.C 1.16 94/06/28 15:42:23
;    Add TRUENAME support
;    CMDLIST.C 1.15 93/12/01 00:17:11
;    Tidy up, commands alphabetical for benefit of help screen
;    CMDLIST.C 1.14 93/10/28 17:08:05
;    ifdef'd out 'more' , since it now external
;    see cmd_list[].
;    CMDLIST.C 1.12 93/04/22 14:50:45 
;    GOSUB, RETURN and SWITCH now have help.  
;    CMDLIST.C 1.11 93/01/21 16:15:03
;    CMDLIST.C 1.7 92/08/06 09:52:44 
;    Added novell_ext_list which is used to expand novell system information
;    statements. See BATCH.C for more info.
;   ENDLOG
*/

/*
*  3 Oct 90  remove 8087 command
*  5 Oct 90  remove logout and lock command
* 23 Oct 90  support AND, OR, INPUT, INPUTC, +BATCH
* 23 Nov 90  add ECHOERR command
*/

#include	"defines.h"
#include	<portab.h>
#include	"command.h"		/* Command Definitions */
#include	"txhelp.h"

/*.pa
 *	CMD_LIST maps command names to routines as well as specifying
 *	the top level of syntax checking. If a command requires parameters
 *      then the message field must point to the error message to be
 *      displayed if no parmeters are given.
 */
EXTERN VOID CDECL cmd_break(BYTE *, BYTE *);
EXTERN VOID CDECL cmd_call(BYTE *, BYTE *); 
EXTERN VOID CDECL cmd_cd(BYTE *, BYTE *);     
EXTERN VOID CDECL cmd_copy(BYTE *, BYTE *); 
EXTERN VOID CDECL cmd_ctty(BYTE *, BYTE *); 
EXTERN VOID CDECL cmd_chcp(BYTE *, BYTE *); 
EXTERN VOID CDECL cmd_idle(BYTE *, BYTE *); /*#NOIDLE#*/
EXTERN VOID CDECL cmd_hiload(BYTE *, BYTE *);
EXTERN VOID CDECL cmd_date(BYTE *, BYTE *);   
EXTERN VOID CDECL cmd_del(BYTE *, BYTE *);    
EXTERN VOID CDECL cmd_dir(BYTE *, BYTE *);    
EXTERN VOID CDECL cmd_delq(BYTE *, BYTE *);   
EXTERN VOID CDECL cmd_md(BYTE *, BYTE *);     
EXTERN VOID CDECL cmd_more(BYTE *, BYTE *);   
EXTERN VOID CDECL cmd_path(BYTE *, BYTE *);   
EXTERN VOID CDECL cmd_prompt(BYTE *, BYTE *); 
EXTERN VOID CDECL cmd_ren(BYTE *, BYTE *);    
EXTERN VOID CDECL cmd_rd(BYTE *, BYTE *);     
EXTERN VOID CDECL cmd_time(BYTE *, BYTE *);   
EXTERN VOID CDECL cmd_truename(BYTE *, BYTE *);   
EXTERN VOID CDECL cmd_type(BYTE *, BYTE *);   
EXTERN VOID CDECL cmd_ver(BYTE *, BYTE *);    
EXTERN VOID CDECL cmd_verify(BYTE *, BYTE *);
EXTERN VOID CDECL cmd_vol(BYTE *, BYTE *);    
EXTERN VOID CDECL cmd_cls(BYTE *, BYTE *);  
EXTERN VOID CDECL cmd_echo(BYTE *, BYTE *);
EXTERN VOID CDECL cmd_echoerr(BYTE *, BYTE *); 
EXTERN VOID CDECL cmd_exit(BYTE *, BYTE *); 
EXTERN VOID CDECL cmd_for(BYTE *, BYTE *);  
EXTERN VOID CDECL cmd_goto(BYTE *, BYTE *); 
EXTERN VOID CDECL cmd_gosub(BYTE *, BYTE *);
EXTERN VOID CDECL cmd_return(BYTE *, BYTE *);
EXTERN VOID CDECL cmd_switch(BYTE *, BYTE *);
EXTERN VOID CDECL cmd_if(BYTE *, BYTE *);   
EXTERN VOID CDECL cmd_pause(BYTE *, BYTE *);
EXTERN VOID CDECL cmd_pauseerr(BYTE *, BYTE *);
EXTERN VOID CDECL cmd_rem(BYTE *, BYTE *);  
EXTERN VOID CDECL cmd_set(BYTE *, BYTE *);  
EXTERN VOID CDECL cmd_shift(BYTE *, BYTE *);
EXTERN VOID CDECL cmd_or(BYTE *, BYTE *); 

GLOBAL S_CMD cmd_list[] =
{
/*
TO DO: MAKE DUAL LANG AWARE
*/
#if !defined(NOXBATCH)
        { "and",	cmd_if,	    	PARAM_IFCONTEXT,DLS_help_and	},
#endif /*NOXBATCH*/
	{ "break",	cmd_break,	PARAM_NONE,	DLS_help_break	},
	{ "call",	cmd_call,	PARAM_NEEDFILE,	DLS_help_call	},
	{ "cd", 	cmd_cd, 	PARAM_NONE,	DLS_help_chdir	},
	{ "chcp",	cmd_chcp,	PARAM_NONE,	DLS_help_chcp	},
	{ "chdir",	cmd_cd, 	PARAM_NONE,	DLS_help_chdir	},
	{ "cls",	cmd_cls,	PARAM_NONE,	DLS_help_cls	},
	{ "copy",	cmd_copy,	PARAM_NEEDFILE,	DLS_help_copy	},
	{ "ctty",	cmd_ctty,	PARAM_NEEDDEV,	DLS_help_ctty	},
	{ "date",	cmd_date,	PARAM_NONE,	DLS_help_date	},
	{ "del",	cmd_del,	PARAM_NEEDFILE,	DLS_help_del	},
	{ "delq",	cmd_delq,	PARAM_NEEDFILE,	DLS_help_delq	},
	{ "dir",	cmd_dir,	PARAM_NONE,	DLS_help_dir	},
	{ "echo",	cmd_echo,	PARAM_NONE,	DLS_help_echo	},
	{ "era",	cmd_del,	PARAM_NEEDFILE,	DLS_help_erase	},
	{ "eraq",	cmd_delq,	PARAM_NEEDFILE,	DLS_help_eraq	},
	{ "erase",	cmd_del,	PARAM_NEEDFILE,	DLS_help_erase	},
	{ "exit",	cmd_exit,	PARAM_NONE,	DLS_help_exit	},
	{ "for",	cmd_for,	PARAM_SYNTAX,	DLS_help_for	},
	{ "gosub",	cmd_gosub,	PARAM_SYNTAX,	DLS_help_gosubreturn},
	{ "goto",	cmd_goto,	PARAM_SYNTAX,	DLS_help_goto	},
	{ "hiload",	cmd_hiload,	PARAM_NONE,	DLS_help_hiload	},
	{ "idle",	cmd_idle,	PARAM_NONE,	DLS_help_idle	},
	{ "if", 	cmd_if, 	PARAM_SYNTAX,	DLS_help_if	},
	{ "lh",		cmd_hiload,	PARAM_NONE,	DLS_help_hiload	},
	{ "loadhigh",	cmd_hiload,	PARAM_NONE,	DLS_help_hiload	},
	{ "md", 	cmd_md, 	PARAM_NEEDPATH,	DLS_help_mkdir	},
	{ "mkdir",	cmd_md, 	PARAM_NEEDPATH, DLS_help_mkdir	},
#if !defined(NOXBATCH)
	{ "or",	    	cmd_or,	    	PARAM_IFCONTEXT,DLS_help_or	},
#endif /*NOXBATCH*/
	{ "path",	cmd_path,	PARAM_NONE,	DLS_help_path	},
	{ "pause",	cmd_pause,	PARAM_NONE,	DLS_help_pause	},
	{ "prompt",	cmd_prompt,	PARAM_NONE,	DLS_help_prompt	},
	{ "rd", 	cmd_rd, 	PARAM_NEEDPATH,	DLS_help_rmdir	},
	{ "rem",	cmd_rem,	PARAM_NONE,	DLS_help_rem	},
	{ "ren",	cmd_ren,	PARAM_NEEDFILE,	DLS_help_rename	},
	{ "rename",	cmd_ren,	PARAM_NEEDFILE,	DLS_help_rename	},
	{ "return",	cmd_return,	PARAM_NONE,	DLS_help_gosubreturn},
	{ "rmdir",	cmd_rd, 	PARAM_NEEDPATH,	DLS_help_rmdir	},
	{ "set",	cmd_set,	PARAM_NONE,	DLS_help_set	},
	{ "shift",	cmd_shift,	PARAM_NONE,	DLS_help_shift	},
#if SWITCH_ENABLED
	{ "switch",	cmd_switch,	PARAM_SYNTAX,	DLS_help_switch	},
#endif
	{ "time",	cmd_time,	PARAM_NONE,	DLS_help_time	},
	{ "truename",	cmd_truename, 	PARAM_NONE,	DLS_help_truename},
	{ "type",	cmd_type,	PARAM_NEEDFILE,	DLS_help_type	},
	{ "ver",	cmd_ver,	PARAM_NONE,	DLS_help_ver	},
	{ "verify",	cmd_verify,	PARAM_NONE,	DLS_help_verify	},
	{ "vol",	cmd_vol,	PARAM_NONE,	DLS_help_vol	},

	{ NULL, 	NULL,		PARAM_NONE }
};


EXTERN	VOID	CDECL	get_login_name(BYTE *);
EXTERN	VOID	CDECL	get_pstation(BYTE *);
EXTERN	VOID	CDECL	get_full_name(BYTE *);
EXTERN	VOID	CDECL	get_hour(BYTE *);
EXTERN	VOID	CDECL	get_hour24(BYTE *);
EXTERN	VOID	CDECL	get_minute(BYTE *);
EXTERN	VOID	CDECL	get_second(BYTE *);
EXTERN	VOID	CDECL	get_am_pm(BYTE *);
EXTERN	VOID	CDECL	get_greeting(BYTE *);
EXTERN	VOID	CDECL	get_year(BYTE *);
EXTERN	VOID	CDECL	get_short_year(BYTE *);
EXTERN	VOID	CDECL	get_month(BYTE *);
EXTERN	VOID	CDECL	get_month_name(BYTE *);
EXTERN	VOID	CDECL	get_day(BYTE *);
EXTERN	VOID	CDECL	get_day_of_week(BYTE *);
EXTERN	VOID	CDECL	get_nday_of_week(BYTE *);
EXTERN	VOID	CDECL	get_os_version(BYTE *);
EXTERN	VOID	CDECL	get_connection(BYTE *);

GLOBAL	N_CMD	novell_ext_list[] = {
	{ "LOGIN_NAME", get_login_name	},
	{ "P_STATION",  get_pstation    },
	{ "FULL_NAME",  get_full_name   },
	{ "HOUR",	get_hour	},
	{ "HOUR24",	get_hour24	},
	{ "MINUTE",	get_minute	},
	{ "SECOND",	get_second	},
	{ "AM_PM",	get_am_pm	},
	{ "GREETING_TIME", get_greeting },
	{ "YEAR",	get_year	},
	{ "SHORT_YEAR", get_short_year  },
	{ "MONTH",	get_month	},
	{ "MONTH_NAME", get_month_name  },
	{ "DAY",	get_day		},
	{ "DAY_OF_WEEK",get_day_of_week },
	{ "NDAY_OF_WEEK",get_nday_of_week},
	{ "OS_VERSION", get_os_version  },
	{ "STATION",    get_connection  },
	{ NULL,		NULL		}
};
