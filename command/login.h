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

/* the following constants are in alphabetical order */
#define	ABORT_CODE      0
#define	CR	            0xd
#define	CMNT_LGTH	    32
#define	DAY_LGTH	    4
#define	ENABLED 	    0xff
#define	EOF_CHAR		0x1a
#define	ENTER		    0xd
#define	FLAGS		    0x0056 	 /*  addr. Flag Table */
#define	FNAME_LEN	    12
#define	LDATE_LGTH	    11
#define	LF	            0xa
#define	MAX_LINE	    128
#define	MXWIDTH	        19
#define	OKAY    	    0
#define	PROCNAME_LGTH   12
#define	ROOT_DIR	    "\\"
#define	SEEK_END	    2
#define	STIME_LGTH	    8
#define	SUPERUSER	    0
#define	SUPERUSERSTR    "0000"
#define	TYPE_PAGE	    (flags & 1)
#define	TIME_LGTH	    8
#define	USERID_LGTH	    4

#define	OWN_PROT_READ	0x0008		/* Owner */
#define	OWN_PROT_WRITE	0x0004
#define	OWN_PROT_EXEC	0x0002
#define	OWN_PROT_DEL	0x0001

#define	GRP_PROT_READ	0x0080		/* Group */
#define	GRP_PROT_WRITE	0x0040
#define	GRP_PROT_EXEC	0x0020
#define	GRP_PROT_DEL	0x0010

#define	WOR_PROT_READ	0x0800		/* World */
#define	WOR_PROT_WRITE	0x0400
#define	WOR_PROT_EXEC	0x0200
#define	WOR_PROT_DEL	0x0100

#define	ALL_PROT_READ	0x0888		/* Owner + Group + World */
#define	ALL_PROT_WRITE	0x0444
#define	ALL_PROT_EXEC	0x0222
#define	ALL_PROT_DEL	0x0111

#define	ALL_PROT	0x0FFF		/* all groups, all access modes */


#define AUTOEXEC_BAT    "AUTOEXEC.BAT"

EXTERN  USER_INF_ENTRY user_info;
EXTERN  UWORD   station;    /* station number */

EXTERN UBYTE login_enabled(VOID);               /* LOGIN.C */
EXTERN VOID login_station(VOID);                /* LOGIN.C */
EXTERN VOID login_consoles(VOID);               /* LOGIN.C */ 
EXTERN VOID lock_station(VOID);                 /* LOGIN.C */
EXTERN WORD get_user_info(UWORD);               /* LOGIN.C */
EXTERN VOID time_stamp(UBYTE**,UBYTE*,UBYTE*);  /* LOGIN.C */
EXTERN VOID wait_for_enter(BOOLEAN);            /* LOGIN.C */
EXTERN WORD logout_user(VOID);                  /* LOGIN.C */
EXTERN VOID login_save_initial_state(VOID); 	/* LOGIN.C */
EXTERN BOOLEAN chk_mail(VOID);	                /* LOGIN.C */
EXTERN UWORD aschextobin(BYTE*);                /* LOGIN.C */
EXTERN WORD sysnamecmp(UBYTE*,UBYTE*);          /* LOGIN.C */
EXTERN VOID logout(VOID); 	                /* LOGIN.C */  
EXTERN VOID lock(VOID);         	        /* LOGIN.C */
EXTERN VOID cmd_logout(VOID);           	/* LOGIN.C */  
EXTERN VOID cmd_lock(VOID);			/* LOGIN.C */
EXTERN VOID logevent(UBYTE*,WORD);              /* LOGIN.C */
EXTERN BOOLEAN logged_in(VOID);           	/* LOGIN.C */
EXTERN BOOLEAN waiting_on_login(VOID);    	/* LOGIN.C */
EXTERN UWORD get_user_on_station(VOID);  	/* LOGIN.C */
EXTERN BOOLEAN lock_requested(VOID);      	/* LOGIN.C */


EXTERN VOID error_code(UWORD);                  /* COM.C */
EXTERN VOID show_file(UWORD, BOOLEAN);          /* COMINT.C */
EXTERN VOID CDECL cmd_set(BYTE *);	        /* COMINT.C */
EXTERN VOID CDECL cmd_cd(BYTE *);		/* COMINT.C */
EXTERN VOID CDECL cmd_exit(BYTE *);             /* COMINT.C */

EXTERN BOOLEAN CDECL ansi_screen(VOID);         /* LOGINASM.ASM */
EXTERN VOID CDECL  get_sys_path(UBYTE*);        /* LOGINASM.ASM */
EXTERN UBYTE CDECL background_proc(VOID);       /* LOGINASM.ASM */
EXTERN VOID CDECL  disable_vc_switch();         /* LOGINASM.ASM */
EXTERN VOID CDECL  enable_vc_switch();          /* LOGINASM.ASM */
EXTERN VOID CDECL disable(VOID);	        /* LOGINASM.ASM */
EXTERN VOID CDECL enable(VOID);		        /* LOGINASM.ASM */
EXTERN UWORD CDECL s_memory(UWORD);	        /* LOGINASM.ASM */

EXTERN UWORD CDECL  heap_size(VOID);            /* CSUP.ASM */

EXTERN PD FAR * CDECL pd;	/* Far pointer to Current PD */
EXTERN UWORD CDECL sysdat_seg;	/* System Data Page */
EXTERN UWORD _psp;		/* PSP Segment */

struct	qpb {	
            UWORD	internal0;
		UWORD	id;
		UWORD	internal1;
		UWORD	*buffer;
		UBYTE	name[9];
		} ;

struct apd {
	UWORD	pd;			    /* PD address			*/
	UWORD	term;			/* Process termination Code	*/
	UWORD	cns;			/* Console Number and Zero field*/
	BYTE	name[PROCNAME_LGTH+1];		/* Process Name 		*/
	};




