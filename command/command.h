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

#define	SWITCH_ENABLED 1
#define	DOSPLUS 1
#define BETA 1
#define PASSWORD 1

/*
 *	DOS Plus Command Line Processor definitions
 */
#define PIPE_CHAR	'|'	/* Invoke PIPE handling 		     */
#define MULTI_CHAR	'!'	/* Character allows multiple commands on     */
				/* one command line or in batch file line    */
#define BACK_CHAR	'&'	/* This character forces the preceeding      */
				/* command to be placed into the background. */
#define ESC_CHAR	'~'	/* Do not process the following character    */

#define MAX_PATHLEN	131	/* Maximum length of a Path "x:\...."	     */
#define MAX_FILELEN	140	/* Maximum length of full file specification */
				/* ie "x:\....\nnnnnnnn.eee;password"	     */
#define	MAX_ENVLEN	255	/* Maximum length of environment entry       */

#define DEFAULT_PROMPT	"$n$g"		/* Default Prompt string */

#define MAX_MEMSIZE	1000		/* Maximum Memory Size	   */
#define MAX_LIMSIZE	8192		/* Max LIM Memory	   */

/*
 *	The following definitions are used to control console redirection,
 *	pipes, echo status etc.
 */
#define REDIR_ACTIVE	0x0001		/* Redirection Enabled		*/
#define REDIR_BATCH	0x0002		/* Redirect Complete Batch File */
#define REDIR_PIPE	0x0004		/* Redirection from PIPE command*/
#define	REDIR_FOR	0x0008		/* Redirection from FOR command */

#define ECHO_ON 	0x0001		/* Turn Echo ON unconditionally */
#define ECHO_OFF	0x0000		/* Permanently Turn Echo OFF	*/

#define XBATCH_ON 	0x0001		/* Turn Echo ON unconditionally */
#define XBATCH_OFF	0x0000		/* Permanently Turn Echo OFF	*/


/*
 *	The following definitions are "LONGJMP" error codes used
 *	to specify the cause of the Internal Abort.
 */
#define	IA_BREAK	1		/* Control-C "BREAK" termination */
#define	IA_STACK	2		/* Stack Overflow		 */
#define	IA_HEAP		3		/* Heap Overflow		 */
#define	IA_FILENAME	4		/* FileName specification Error	 */

/*.pa*/
#define SYSDATE struct sysdate
SYSDATE {
	WORD	year;		/* Current Year 1980 - 2099 */
	BYTE	month;		/* Month (1 - 12) */
	BYTE	day;		/* Day (1 - 31) */
	BYTE	dow;		/* Day of the Week (0 - 6) (Sun - Sat) */
	};

#define SYSTIME struct systime
SYSTIME {
	BYTE	hour;		/* Hour (0 - 23) */
	BYTE	min;		/* Minute (0 - 59) */
	BYTE	sec;		/* Second (0 - 59) */
	BYTE	hsec;		/* Hundredth of a second (0 - 99) */
	};

#define DTA struct dta
DTA {				/* 128 Data Transfer Buffer in Search	*/
	BYTE	resvd[21];	/* First - Search Next format		*/
	BYTE	fattr;
	WORD	ftime;
	WORD	fdate;
	LONG	fsize;
	BYTE	fname[13];
};

/************************************************************************/
/*									*/
/*	The following structure is initialized by the COMMAND.COM	*/
/*	kernel	via  a call  to MS_S_COUNTRY.	It is needed  for	*/
/*	date/time conversions and directory displays... 		*/
/*									*/
/************************************************************************/
#define INTERNAT struct internat
INTERNAT {
	WORD	dt_fmt; 	/* 0=MM/DD/YY 1=DD/MM/YY 2=YY/MM/DD	*/
	BYTE	currcy[5];	/* currency symbol + nulls		*/
	BYTE	d1000[2];	/* thousands delimiter + null		*/
	BYTE	ddecm[2];	/* decimal delimiter + null		*/
	BYTE	ddate[2];	/* date delimiter + null		*/
	BYTE	dtime[2];	/* time delimiter + null		*/
	BYTE	cflg;		/* currcy sym bits: 01 trailing, 02 = spaced */
	BYTE	cdec;		/* number of decimal places in currency */
	BYTE	ampm;		/* 0=am/pm 1=24h clock			*/
    BYTE    internl[14];
    UWORD   code;      
};


/* Possible values of needparam in S_CMD. */
#define	PARAM_NONE	0
#define	PARAM_NEEDFILE	1
#define	PARAM_NEEDPATH	2
#define	PARAM_NEEDDEV	3
#define	PARAM_SYNTAX	4
#define PARAM_IFCONTEXT 6

#define S_CMD struct s_cmd
S_CMD {
#if defined(MWC)
    BYTE *cmnd;			/* ASCII command string 	    */
    CDECL VOID (* CDECL func)(BYTE *, BYTE *);
    UWORD needparm; 		/* Pointer to Null command line msg */
    WORD help_index; 		/* help msg index */
#else
#if defined(__WATCOMC__)
    BYTE *cmnd;			/* ASCII command string 	    */
    VOID CDECL (*func)(BYTE *, BYTE *);
    UWORD needparm; 		/* Pointer to Null command line msg */
    WORD help_index; 		/* help msg index */
#else
    BYTE *cmnd;			/* ASCII command string 	    */
    VOID (* CDECL func)();	/* corresponding 'C' function	    */
    UWORD needparm; 		/* Pointer to Null command line msg */
    WORD help_index; 		/* help msg index */
#endif
#endif
};

#define N_CMD struct n_cmd
N_CMD {
#if defined(MWC)
    BYTE *string;			/* ASCII command string 	    */
    CDECL VOID (* CDECL func)(BYTE *);
#else
#if defined(__WATCOMC__)
    BYTE *string;			/* ASCII command string 	    */
    VOID CDECL (*func)(BYTE *);
#else
    BYTE *string;			/* ASCII command string 	    */
    VOID (* CDECL func)();	/* corresponding 'C' function	    */
#endif
#endif
};

#if defined(CDOSTMP)
#define	INVALID_DRV(drv)    (drv < 0 || drv > 25 || (drv == *SYSDATB(SRCHDISK)))
#else
#define	INVALID_DRV(drv)    (drv < 0 || drv > 31)
#endif

/*	DOS file attribute bit masks		*/

#define 	ATTR_RO 	0x0001	/* file is read/only		*/
#define 	ATTR_HID 	0x0002	/* file is hidden		*/
#define 	ATTR_SYS	0x0004	/* file system is system 	*/
#define 	ATTR_STD	(ATTR_SYS | ATTR_RO)
#define 	ATTR_ALL	0x0014	/* find all but labels & hidden */
#define 	ATTR_LBL	0x0008	/* find labels		 	*/
#define 	ATTR_DIR	0x0010	/* find directories, too	*/
#define		ATTR_DEV	0x0040	/* Attribute returned for Device*/

#define STDIN		0	/* Standard Console Input Handle	*/
#define STDOUT		1	/* Standard Console Output Handle	*/ 
#define STDERR		2	/* Standard Error Output		*/
#define STDAUX		3	/* Auxilary Device Handle		*/
#define STDPRN		4	/* Printer Device Handle		*/
#define STDCON		5	/* Internal Console Handle		*/

#define OPEN_RO 	0x0000		/* Open in Read Only		*/
#define OPEN_WO 	0x0001		/* Open in Write Only		*/
#define OPEN_RW 	0x0002		/* Open in Read/Write mode	*/

#define OPEN_DRW	0x0010		/* Deny Read/Write Access	*/
#define OPEN_DW 	0x0020		/* Deny Write Access		*/
#define OPEN_DR 	0x0030		/* Deny Read Access		*/
#define OPEN_DN 	0x0040		/* Deny None			*/

#define OPEN_NI 	0x0080		/* Prevent Child Inheriting	*/

#define OPEN_READ	(OPEN_RO | OPEN_DW)	/* Open Read Only	*/
#define OPEN_WRITE	(OPEN_WO | OPEN_DRW)	/* Open Write Only	*/
#define	OPEN_RDWR	(OPEN_RW | OPEN_DRW)	/* Open Read and Write	*/

/*
 *	Set STACK to 1 to use dynamic string storage fuunction STACK
 *	which will reserve a any number of bytes on the stack for
 *	the life of the calling function. However this routine relies
 *	on a certain type of function exit code and cannot be used
 *	with all compilers
 */
#define	STACK		defined(MSC)

/* macros to break 'far' pointers into segment and offset components */

#define FP_OFF(__p) ((unsigned)(__p))
#define FP_SEG(__p) ((unsigned)((unsigned long)(void far*)(__p) >> 16))

/*	make a far pointer from segment and offset */
#define MK_FP(__s,__o) ((void far*)(((unsigned long)(__s)<<16)|(unsigned)(__o)))

