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

#include    <portab.h>

#if !defined(CDOS) || defined(NOHELP)
#define 	HELP_AND     NULL
#define 	HELP_APPEND  NULL
#define 	HELP_ASSIGN  NULL
#define 	HELP_BANK    NULL
#define 	HELP_BREAK   NULL
#define 	HELP_CALL    NULL
#define 	HELP_CHDIR   NULL
#define 	HELP_CLS     NULL
#define     HELP_COM     NULL
#define     HELP_COPY    NULL
#define 	HELP_DATE    NULL
#define 	HELP_DBG     NULL
#define 	HELP_DEL     NULL
#define 	HELP_DELQ    NULL
#define 	HELP_DIR     NULL
#define 	HELP_ECHO    NULL
#define 	HELP_ECHOERR NULL
#define 	HELP_ERAQ    NULL
#define 	HELP_ERASE   NULL
#define 	HELP_EXIT    NULL
#define 	HELP_FOR     NULL
#define 	HELP_GOTO    NULL
#define 	HELP_IDLE    NULL
#define 	HELP_IF      NULL
#define 	HELP_INPUT   NULL
#define 	HELP_INPUTC  NULL
#define 	HELP_LIMSIZE NULL
#define 	HELP_MEMSIZE NULL
#define 	HELP_MKDIR   NULL
#define 	HELP_MORE    NULL
#define 	HELP_NETDRIVE NULL
#define 	HELP_NETOFF  NULL
#define 	HELP_NETON   NULL
#define 	HELP_OR      NULL
#define 	HELP_PATH    NULL
#define 	HELP_PAUSE   NULL
#define 	HELP_PAUSEERR NULL
#define 	HELP_PROMPT  NULL
#define 	HELP_REM     NULL
#define 	HELP_RENAME  NULL
#define 	HELP_RMDIR   NULL
#define 	HELP_SET     NULL
#define 	HELP_SHIFT   NULL
#define 	HELP_STOP    NULL
#define 	HELP_SUBST   NULL
#define 	HELP_SUSPEND NULL
#define 	HELP_TIME    NULL
#define		HELP_TRUENAME NULL
#define 	HELP_TYPE    NULL
#define 	HELP_VER     NULL
#define 	HELP_VERIFY  NULL
#define 	HELP_VOL     NULL
#else
#define 	HELP_AND     help_and 
#define 	HELP_APPEND  help_append 
#define 	HELP_ASSIGN  help_assign
#define 	HELP_BANK    help_bank   
#define 	HELP_BREAK   help_break  
#define 	HELP_CALL    help_call
#define 	HELP_CHDIR   help_chdir  
#define 	HELP_CLS     help_cls    
#define     HELP_COM     help_com    
#define     HELP_COPY    help_copy
#define 	HELP_DATE    help_date   
#define 	HELP_DBG     help_dbg   
#define 	HELP_DEL     help_del    
#define 	HELP_DELQ    help_delq   
#define 	HELP_DIR     help_dir    
#define 	HELP_ECHO    help_echo
#define 	HELP_ECHOERR help_echoerr
#define 	HELP_ERAQ    help_eraq   
#define 	HELP_ERASE   help_erase  
#define 	HELP_EXIT    help_exit   
#define 	HELP_FOR     help_for
#define 	HELP_GOTO    help_goto
#define 	HELP_IDLE    help_idle   
#define 	HELP_IF      help_if
#define 	HELP_INPUT   help_input   
#define 	HELP_INPUTC  help_inputc   
#define 	HELP_LIMSIZE help_limsize
#define 	HELP_MEMSIZE help_memsize
#define 	HELP_MKDIR   help_mkdir  
#define 	HELP_MORE    help_more   
#define 	HELP_NETDRIVE help_netdrive
#define 	HELP_NETOFF  help_netoff   
#define 	HELP_NETON   help_neton   
#define 	HELP_OR      help_or
#define 	HELP_PATH    help_path   
#define 	HELP_PAUSE   help_pause
#define 	HELP_PAUSEERR  help_pauseerr
#define 	HELP_PROMPT  help_prompt 
#define 	HELP_REM     help_rem
#define 	HELP_RENAME  help_rename 
#define 	HELP_RMDIR   help_rmdir  
#define 	HELP_SET     help_set    
#define 	HELP_SHIFT   help_shift
#define 	HELP_STOP    help_stop   
#define 	HELP_SUBST   help_subst  
#define 	HELP_SUSPEND help_suspend
#define 	HELP_TIME    help_time
#define		HELP_TRUENAME help_truename   
#define 	HELP_TYPE    help_type   
#define 	HELP_VER     help_ver    
#define 	HELP_VERIFY  help_verify 
#define 	HELP_VOL     help_vol    

EXTERN BYTE	help_and    [];
EXTERN BYTE	help_append [];
EXTERN BYTE	help_assign [];
EXTERN BYTE	help_bank   [];
EXTERN BYTE	help_break  [];
EXTERN BYTE	help_call   [];
EXTERN BYTE	help_chdir  [];
EXTERN BYTE	help_cls    [];
EXTERN BYTE	help_com    [];
EXTERN BYTE	help_copy   [];
EXTERN BYTE	help_date   [];
EXTERN BYTE	help_dbg    [];
EXTERN BYTE	help_del    [];
EXTERN BYTE	help_delq   [];
EXTERN BYTE	help_dir    [];
EXTERN BYTE	help_echo   [];
EXTERN BYTE	help_echoerr[];
EXTERN BYTE	help_eraq   [];
EXTERN BYTE	help_erase  [];
EXTERN BYTE	help_exit   [];
EXTERN BYTE	help_for    [];
EXTERN BYTE	help_goto   [];
EXTERN BYTE	help_idle   [];
EXTERN BYTE	help_if     [];
EXTERN BYTE	help_input  [];
EXTERN BYTE	help_inputc [];
EXTERN BYTE	help_limsize[];
EXTERN BYTE	help_memsize[];
EXTERN BYTE	help_mkdir  [];
EXTERN BYTE	help_more   [];
EXTERN BYTE	help_netdrive[];
EXTERN BYTE	help_netoff [];
EXTERN BYTE	help_neton  [];
EXTERN BYTE	help_or     [];
EXTERN BYTE	help_path   [];
EXTERN BYTE	help_pause  [];
EXTERN BYTE	help_pauseerr [];
EXTERN BYTE	help_prompt [];
EXTERN BYTE	help_rem    [];
EXTERN BYTE	help_rename [];
EXTERN BYTE	help_rmdir  [];
EXTERN BYTE	help_set    [];
EXTERN BYTE	help_shift  [];
EXTERN BYTE	help_stop   [];
EXTERN BYTE	help_subst  [];
EXTERN BYTE	help_suspend[];
EXTERN BYTE	help_time   [];
EXTERN BYTE	help_truename [];
EXTERN BYTE	help_type   [];
EXTERN BYTE	help_ver    [];
EXTERN BYTE	help_verify [];
EXTERN BYTE	help_vol    [];
#endif
