/*
;    File              : $Workfile$
;
;    Description       : Definitions of common security related structures.
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


/* All security information files have the following header before any
   data entries. */

typedef	struct
{
    UWORD	signature;		/* file identifier, see SIG_ */
    BYTE	version;		/* version No., see SECURE_VERSION */
    BYTE	crlf[2];
} INF_HEADER_ENTRY;


/* All security info files must be at the following version level
   to be compatible with the definitions in this file. */
#define	SECURE_VERSION	'0'


#define FNAME_LOGIN_TXT	"LOGIN.TXT"
#define FNAME_LOCK_TXT	"LOCK.TXT"

#define FNAME_LOGIN_ERR	"LOGIN.ERR"
#define FNAME_LOCK_ERR	"LOCK.ERR"



/******************************************************************************

	User information file.

******************************************************************************/


/* The following structure defines the contents of a single entry in the
   user information file. This file associates user id numbers, user names,
   group names, etc for all users on a secure Concurrent DOS system.

   The file is in ASCII with one entry per line. Each variable is separated
   by one space character and variables are all left justified space padded.
   The lines are a fixed length, equal to sizeof(USER_INF_ENTRY).
   Entries in the file are sorted on the userid field.

   An example file (where ... indicates absent space padding) -

UI0
0100 RogerGross  Stellar      rwdr----- C \roger  ...   08-23-1990 10:30:52 ...
0101 Ant         Stellar      rwdr----- C \ant    ...   08-22-1990 16:10:08 ...
0200 Stan        Accounts     rwd------ C \stan   ...   08-10-1990 09:27:00 ...
0900 Julie       Doc          rwdrwdr-- C \julie  ...   08-22-1990 08:09:11 ...

*/


#define FNAME_USER_INF	"USER.INF"	/* user information file name */
#define	SIG_USER_INF	0x4955		/* file signature "UI" in word order */

#define	USERID_LGTH	4
#define	SYS_NAME_LGTH	12
#define	DEFACCESS_LGTH	9
#define DATE_LGTH	10
#define	TIME_LGTH	8
#define	CMNT_LGTH	32


typedef struct
{
    BYTE	userid		[USERID_LGTH+1];	
    BYTE	loginname	[SYS_NAME_LGTH+1];	
    BYTE	groupname	[SYS_NAME_LGTH+1];
    BYTE	defaccess	[DEFACCESS_LGTH+1];
    BYTE	homedrv		[2];
    BYTE	homedir		[PATH_LEN];
    BYTE	date		[DATE_LGTH+1]; 		/* mm-dd-yyyy */
    BYTE	time		[TIME_LGTH+1]; 		/* hh:mm:ss */
    BYTE	comment		[CMNT_LGTH+1];
    BYTE	crlf		[2];
} USER_INF_ENTRY;


#define	DEFLT_SU_NAME	"Superuser"
#define	DEFLT_SU_GROUP	"Supergroup"



/******************************************************************************

	User password file.

******************************************************************************/



/* The following structure defines the contents of a single entry in the
   user password file. This file associates user id numbers with passwords
   for all users on a secure Concurrent DOS system.

   The file is in a binary format.
   Entries in the file are sorted on the userid field.
*/


#define FNAME_USER_SYS	"USER.SYS"	/* user password file name */
#define	SIG_USER_SYS	0x5355		/* file signature "US" in word order */

typedef struct
{
    UWORD	userid;
    ULONG	pword;
} USER_SYS_ENTRY;



/******************************************************************************

	Login history file.

******************************************************************************/



/* The following structure defines the contents of a single entry in the
   login.log history file. This file is a history of events on the system
   such as login/out lock and errors. 

   The file is in a binary format.
   New Entries are appended to the file. 
*/


#define FNAME_LOGIN_LOG	"LOGIN.LOG"
#define	SIG_LOGIN_LOG	0x4C4C		/* file signature "LL" in word order */

typedef struct
{
    UWORD	year;			/* 1980 - 2099 */
    UBYTE	month;
    UBYTE	day;
    UBYTE	day_of_week;		/* Ignored by ms_setdate */
} SYSDAT;

typedef struct
{
    UBYTE	hour;			/* (0 - 23) */
    UBYTE	minute;			/* (0 - 59) */
    UBYTE	second;			/* (0 - 59) */
    UBYTE	hundredth;		/* (0 - 99) */
} SYSTIM;

typedef struct
{
    UWORD	userid;
    UWORD	station;
    WORD	event;
    SYSTIM	time;
    SYSDAT	date;
} LOGIN_LOG_ENTRY;

#define LOG_LOGIN       0
#define LOG_LOGOUT      1
#define LOG_LOCK        2
#define LOG_UNLOCK      3
#define LOG_REBOOT      4
#define LOG_POWERON     5

#define	ERR_BASE	0
#define	ERR_USERPWORD	ERR_BASE-1
#define	ERR_NOFILE	ERR_BASE-2
#define	ERR_OPENFILE	ERR_BASE-3
#define	ERR_BADFILE	ERR_BASE-4
#define	ERR_READFILE    ERR_BASE-5
#define	ERR_WRITEFILE   ERR_BASE-6
#define	ERR_BADID       ERR_BASE-7
#define	ERR_FATALSYSTEM ERR_BASE-8
#define	ERR_LOGIN       ERR_BASE-9
#define	ERR_LOGOUT      ERR_BASE-10
#define	ERR_LOCK        ERR_BASE-11
#define	ERR_UNLOCK      ERR_BASE-12


/******************************************************************************

	Miscellaneous definitions.

******************************************************************************/


#define	SYS_PWORD_MINLEN	3	/* minimum password length */
#define	SYS_PWORD_MIN		6	/* minimum pw len (INSTALL only) */
#define	SYS_PWORD_MAX	SYS_NAME_LGTH

#define	ID_NUM(n)	((n)&0x00FF)	/* extract user No. from 16 bit id */
#define	ID_GROUP(n)	((n)>>8)	/* extract group No. from 16 bit id */
#define	ID_GRP_USR(g,u)	(((g)<<8)+(u))	/* convert group/user to 16 bit id */


/* The following definition is used when accessing USER.SYS, USER.INF, etc.
   Because these files may be open by other processes in a mode which denies
   access to any other several attempts must be made to open them before
   giving up. This definition governs the number of attempts to be made.
   Note that a utility should perform a P_DISPATCH after each unsuccessful
   attempt. */
#define	ACCESS_ATTEMPTS	1000


/*******************   E N D   O F   S E C U R I T Y . H   *******************/
