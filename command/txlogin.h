/*
;    File              : $Workfile$
;
;    Description       : login security extensions
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

#if	defined(CDOSTMP) || defined(CDOS) 
#define	STD_MSG	        std_msg
#define	MSG_BADHOMEDRV	msg_badhomedrv
#define	MSG_BADHOMEDIR	msg_badhomedir	
#define	MSG_LOGGEDIN	msg_loggedin	
#define	NAME_PROMPT	    name_prompt	
#define	PWORD_PROMPT    pword_prompt	
#define	MSG_BADUSERPWORD msg_baduserpword	
#define	MSG_LOGINFAILED msg_loginfailed
#define	MSG_SEP         msg_sep
#define	MSG_LOGGEDOUT   msg_loggedout
#define	MSG_BADFILE     msg_badfile
#define	MSG_NOFILE      msg_nofile
#define	MSG_BADREADFILE msg_badreadfile
#define	MSG_BADWRITEFILE msg_badwritefile
#define	MSG_BADOPENFILE msg_badopenfile
#define	MSG_ENTERTOCONT msg_entertocont
#define	MSG_LOGLOCKED   msg_loglocked
#define	MSG_LOCKED      msg_locked
#define	MSG_UNLOCKFAILED msg_unlockfailed
#define	MSG_UNLOCKED    msg_unlocked
#define	SUN_D		sun_d		
#define	MON_D		mon_d		
#define	TUE_D		tue_d		
#define	WED_D		wed_d		
#define	THU_D		thu_d		
#define	FRI_D		fri_d		
#define	SAT_D		sat_d		
#define MSG_PROCRUNNING msg_procrunning
#define MSG_VCNUM       msg_vcnum
#define MSG_PROCNAME    msg_procname
#define MSG_STOPPROC    msg_stopproc
#define MSG_FAILABORT   msg_failabort
#define UNKNOWN         msg_unknown
#define MSG_GETSUPERPWORD1  msg_getsuperpword1
#define MSG_GETSUPERPWORD2  msg_getsuperpword2
#define MSG_CANNOTLOCK  msg_cannotlock
#define MSG_CANNOTLOGOUT msg_cannotlogout
#define MSG_TYPEEXIT msg_typeexit
#define MSG_HEAPSIZE msg_heapsize
#define MSG_WILLNOTLOCK msg_willnotlock

EXTERN BYTE yesch;
EXTERN BYTE noch;
EXTERN BYTE std_msg[];
EXTERN BYTE err_msg[];
EXTERN BYTE log_msg[];
EXTERN BYTE msg_baduserpword[];
EXTERN BYTE msg_badhomedir[];
EXTERN BYTE msg_badhomedrv[];
EXTERN BYTE msg_loggedin[];
EXTERN BYTE name_prompt[];
EXTERN BYTE pword_prompt[];
EXTERN BYTE msg_loginfailed[];
EXTERN BYTE msg_sep[];
EXTERN BYTE msg_loggedout[];
EXTERN BYTE msg_erroccurred[];
EXTERN BYTE msg_badfile[];
EXTERN BYTE msg_nofile[];
EXTERN BYTE msg_badreadfile[];
EXTERN BYTE msg_badwritefile[];
EXTERN BYTE msg_badopenfile[];
EXTERN BYTE msg_entertocont[];
EXTERN BYTE msg_loglocked[];
EXTERN BYTE msg_locked[];
EXTERN BYTE msg_unlockfailed[];
EXTERN BYTE msg_unlocked[];
EXTERN BYTE sun_d[];
EXTERN BYTE mon_d[];
EXTERN BYTE tue_d[];
EXTERN BYTE wed_d[];
EXTERN BYTE thu_d[];
EXTERN BYTE fri_d[];
EXTERN BYTE sat_d[];
EXTERN BYTE msg_procrunning[];
EXTERN BYTE msg_vcnum[];
EXTERN BYTE msg_procname[];
EXTERN BYTE msg_stopproc[];
EXTERN BYTE msg_failabort[];
EXTERN BYTE msg_unknown[];
EXTERN BYTE msg_getsuperpword1[];
EXTERN BYTE msg_getsuperpword2[];
EXTERN BYTE msg_cannotlock[];
EXTERN BYTE msg_cannotlogout[];
EXTERN BYTE msg_typeexit[];
EXTERN BYTE msg_heapsize[];
EXTERN BYTE msg_willnotlock[];

#endif


