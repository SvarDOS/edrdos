/*
;    File              : $Workfile: COMINT.C$
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

#include	"defines.h"
#include	<string.h>

#if defined(MWC) && defined(strlen)
#undef strcmp			/* These are defined as macros in string.h */
#undef strcpy			/* which are expaneded in line under */
#undef strlen			/* Metaware C. These undefs avoid this. */
#endif

#include	<portab.h>
#include	<mserror.h>

#if !defined(DOSPLUS)
#include	<pd.h>
#include	<ccpm.h>
#include	<sysdat.h>
#endif

#include	"command.h"		/* COMMAND Definitions */
#include	"dos.h" 		/* MSDOS Functions */
#include	"dosif.h"		/* DOS interface definitions	 */
#include	"toupper.h"
#include	"support.h"		/* Support routines		 */
#include	"global.h"

/*RG-00-*/
#if !defined(NOXBATCH)
#if !defined(NOSECURITY) && (defined(CDOSTMP) || defined(CDOS))
#define	PATH_LEN	    65		 /* max path length (null terminated) */
#include	"security.h"
#include	"login.h"
#include	"txlogin.h"
#endif
#endif /*NOXBATCH*/
/*RG-00-end*/

EXTERN VOID CDECL restore_error_mode();

EXTERN VOID batch_start(BYTE *, BYTE *, BYTE *);
EXTERN VOID batch_end(VOID);			/* BATCH.C		*/
EXTERN VOID batch_close(VOID);			/* BATCH.C		*/

MLOCAL VOID erase(BYTE *, BOOLEAN);		/* COMINT.C		*/
MLOCAL BYTE * date_format(UWORD);		/* COMINT.C		*/
MLOCAL BOOLEAN check_date(BYTE *);		/* COMINT.C		*/
MLOCAL BOOLEAN check_time(BYTE *);		/* COMINT.C		*/
MLOCAL VOID show_crlf(BOOLEAN);			/* COMINT.C		*/

/*RG-02-*/
#if !defined(NOXBATCH)
GLOBAL VOID CDECL cmd_pauseerr(BYTE *);    /* COMINT.C		*/
/*RG-02-end*/
#endif
GLOBAL VOID CDECL cmd_pause(BYTE *);    /* COMINT.C		*/
GLOBAL VOID CDECL cmd_set(BYTE *);		/* COMINT.C		*/
GLOBAL VOID CDECL cmd_vol(BYTE *);		/* COMINT.C		*/

EXTERN WORD CDECL findfile(BYTE *, UWORD *);	/* DOSIF.A86 || COM.C	*/
EXTERN VOID CDECL int_break(VOID);		/* COM.C		*/
EXTERN VOID docmd(BYTE *, BOOLEAN);		/* COM.C		*/

#if defined(CPM)
EXTERN UWORD CDECL cpm_de_init(VOID);		/* CP/M Clean-Up Routine*/
#endif


MLOCAL WORD linesleft;		/* Remaining lines on Screen	*/
MLOCAL WORD ret;		/* general BDOS return code	*/


#if defined(CDOSTMP) || defined(CDOS)
/*.pa*/
/*
 *	USER BEWARE
 *
 *	A process descriptor exists in both DOS Plus and Concurrent
 *	DOS. But is an internal Structure in DOS Plus and should only
 *	be used with the upmost care.
 */
EXTERN PD FAR * CDECL pd;	/* Far pointer to Current PD */

/*
 *	The following command will enable APPEND processing and set
 *	path searched by the BDOS on every OPEN function call.
 *
 *	APPEND[=][d:]path[[;[d:]path]..] | [;] [/X|/E]
 *
 *	APPEND without any command line options will display the current
 *	search path while APPEND ; will remove the Search Path and disable
 *	the APPEND facility.
 *
 *	/E	Forces the search path to be saved in the environment under
 *		Concurrent DOS this is always true and this flag is ignored.
 *
 *	/X	Forces APPEND to be active for the SEARCH FIRST(0x11), 
 *		FIND FIRST(0x4E) and EXEC(0x4B) functions. In addition
 *		to the normal functions FCB OPEN(0x0F), FCB FileSize(0x23)
 *		and OPEN(0x3D).
 *	/B	Forces APPEND to provide batch command compatible output
 *          that when redirected to a file, can be used to regenerate a
 *          given append state.
 */

MLOCAL BYTE msg_appeq  [] = "APPEND=";	/* Static Environment String	*/

/*RG-03*/
#if !defined(NOXBATCH) && (defined(CDOS) || defined(CDOSTMP))
#define	APPEND_BAT	(flags & 4)	/* /B Append Option		*/
#endif
/*RG-03-end*/
#define	APPEND_X	(flags & 2)	/* /X Append Option		*/
#define	APPEND_E	(flags & 1)	/* /E Append Option		*/

GLOBAL VOID CDECL cmd_append(path)
REG BYTE *path;
{
	REG BYTE *s;
	UWORD	 flags;				/* Command Flags	    */
#if !STACK
	BYTE	 sbuf[MAX_ENVLEN];
#endif

#if defined(CDOS) || defined(CDOSTMP)
	if (f_check (path, "exb", &flags, NO))	/* Check for valid Flags    */
#else
        if (f_check (path, "ex", &flags, NO))	/* Check for valid Flags    */
#endif
            return;

	zap_spaces(path);			/* Remove White Space	    */
	if(!*path && !APPEND_X) {
	    if(env_scan(msg_appeq, s = (BYTE *)heap())) /* look for current value   */
		    s = NULLPTR;

	    if(s && (pd->P_SFLAG & PSF_APPEND)) { /* If a path exists and the */
		    printf(msg_appeq);		/* Append bit is set in the */
		    puts(s);
	    }
/*RG-03*/
            else  {				/* PD then display path     */
#if !defined(NOXBATCH) && (defined(CDOS) || defined(CDOSTMP))
                if (APPEND_BAT)
                    printf("APPEND=");
                else
#endif
                    printf(MSG_APPEND);
            }
/*RG-03-end*/

	    crlfflg = YES;
	    return; 
	}
	
	pd->P_SFLAG |= APPEND_X ? PSF_XAPPEND : 0;

	if(*path == '=' || *path == ';')/* Skip Leading '=' or ';' chars    */
	    path++;			/* and disable the APPEND command   */
					/* if no path is specified.	    */

	if(*path) {			/* Assign APPEND Path		    */
	    pd->P_SFLAG |= PSF_APPEND;	/* Set the APPEND and XAPPEND Bits  */

#if STACK
	    s = stack(strlen(msg_appeq) + strlen(path) + 1);
#else
	    s = &sbuf[0];
#endif
	    strcpy(s, msg_appeq);	/* build command line for "SET"  */
	    strcat(s, strupr(path));	/* Force Path to UPPER case	    */
	    cmd_set(s); 		/* set new path using "SET"	    */
	}
	else if(!APPEND_X) {		/* Disable APPEND Processing	    */
	    pd->P_SFLAG &= ~(PSF_APPEND | PSF_XAPPEND);
	    cmd_set(msg_appeq);
	}	    
}
#endif

#if !defined(EXT_SUBST)

/*.pa*/
/************************************************************************/
/*									*/
/*	ASSIGN (x [=] y ...) [/a][/b]					*/
/*									*/
/*	This command forces future references to the X: to physically	*/
/*	reference the Y: drive.						*/
/*									*/
/*	When no command line parameters are given then all assignments	*/
/*	are removed. If the /A option is used the current drive 	*/
/*	assignments are displayed. For the purpose of the display and	*/
/*	remove functions an "ASSIGNed" drives is any physical drive	*/
/*	which does not reference itself.				*/
/*									*/
/************************************************************************/

/*
 *	ASSIGN_DRV returns TRUE if the drive pointed to by BP
 *	is a valid physical drive.
 */
MLOCAL BOOLEAN assign_drv(bp)
BYTE *bp;
{
	if(!d_check(bp))
	    return FALSE;
	    
	if(physical_drvs() & (1L << ddrive))
	    return TRUE;

	e_check(ED_DRIVE);
	return FALSE;
}


/*RG-03*/
#define	ASSIGN_BAT	(flags & 2)	/* Display Current Assignments in batch form */
/*RG-03-end*/
#define	ASSIGN_ALL	(flags & 1)	/* Display Current Assignments	*/

GLOBAL VOID CDECL cmd_assign(s)
REG BYTE *s;
{
	BYTE temp[7];			/* Temporary Command Buffer	*/
	BYTE path[MAX_PATHLEN];
	BYTE src, dst;
	ULONG	vec,pvec,lvec,nvec;
	UWORD	drv;
	UWORD	flags;			/* Command Flags		*/
	WORD    ret;			/* General purpose variable	*/

	if (f_check (s, "ab", &flags, NO)) /* Check for Flags if any are   */
            return;			  /* invalid then don't do it     */

	pvec = physical_drvs();
	lvec = logical_drvs();

	/*
	 *	Display the current drive assignments. 
	 */
/*RG-03*/
	if((ASSIGN_ALL)||(ASSIGN_BAT))
        {
	    vec = 1L;
	    drv = 0;
	    while(drv < 26) {
		    if((lvec & vec) && (pdrive(drv) != drv)) {
                    if (ASSIGN_BAT)
		            printf("ASSIGN %c = %c\n", drv+'A', pdrive(drv)+'A');
                    else
/*RG-03-end*/
		            printf("%c: => %c:\n", drv+'A', pdrive(drv)+'A');
                }
		    vec <<= 1;
		    drv++;
	    }
	    return;
	}

	/*
	 *	Remove ALL drive assignments. 
	 */
	s = deblank(s);			/* If no command line options	*/
	if(!*s) {			/* are given then remove the	*/
	    				/* current assignments.		*/
	    vec = 1L;
	    drv = 0;	    
	    while(drv < 26) {
		if((lvec & vec) && (pdrive(drv) != drv)) {
		    sprintf(temp, "%c:=%c:", drv+'A', drv+'A');
		    ms_x_chdir(temp);
		}
		vec <<= 1;
		drv++;
	    }
	    return;
	}

	/*
	 *	Scan the command line and make all the drive assignments
	 *	specified by the user.
	 */
	do {
	    dst = *s++;			/* Get the Destinaion		*/
	    s = deblank(s);
	    if(*s == '=')		/* Skip the optional '=' 	*/
	        s = deblank(s+1);	/* character and get the source */

	    if(!*s) {			/* if no second drive has been	*/
		syntax();		/* specified the return error	*/
		return;
	    }

	    src = *s++;
	    sprintf(temp, "%c:=%c:", dst, src);

#if defined(DOSPLUS)
	    nvec = network_drvs();
	    if ((nvec & (1L << (toupper(src)-'A')))
	          || (nvec & (1L << (toupper(dst)-'A')))) {
	    	eprintf(MSG_NETASSIGN);		/* if either is remote	*/
	    	return;				/* complain and exit	*/
	    }
#endif
	    if(assign_drv(temp) && assign_drv(temp+3)) {
	    	ret = ms_x_chdir(temp);
		if (ret) {
		    e_check(ret);
	 	    return;
		}
	    }
	    else
		return;

	    sprintf (path, "%c:%c", dst, *pathchar);
	    ms_x_curdir (tolower(src) - 'a'+1, path+3);
	    				/* set dst drive to cur path on	*/
					/* source			*/
	    ms_x_chdir (path);

	    s = deblank(s);		/* Deblank the renmainder of	*/
	} while(*s);			/* command line and repeat	*/
}
#endif


/*
 *	The CALL command accepts the name of a batch file with an
 *	optional parameter list. Any current batch processing is
 *	halted and the new batch file is used until the EOF is reached
 *	or an EXIT command is executed. Control then passes back to
 *	the original Batch file.
 */

EXTERN	UWORD CDECL heap_size(VOID);

GLOBAL VOID CDECL cmd_call(line)
REG BYTE *line;
{
	BYTE	path[MAX_FILELEN];
	UWORD	loadtype;
	BYTE	argv0[MAX_FILELEN];
	BYTE	*s;

	heap_get(0);	/* check for stack overflow */

	s = get_filename(path, deblank(line), NO);

	strcpy(argv0, path);
	strlwr(path);
	
	if((ret = findfile(path, &loadtype)) >= 0) {
	    if(loadtype == BAT_FILETYPE) {	/* treat .BAT differently */
		batch_start(argv0, path, s);	/* nested batch files */
		return;
	    }
	}

	line = deblank(line);

	docmd(line,YES);		/* call normal code */
}

/*
 *	Display the current directory assignment of a logical drive
 *	Currently the Absolute path is specified with the physical drive
 */
/*RG-03*/
#define	CHDIR_BAT	(flags & 2)	/* Display dir in command line compatible form	*/

#if !defined(NOXBATCH) && (defined(CDOS) || defined(CDOSTMP))
MLOCAL VOID display_cd(drv,flags)
#else
MLOCAL VOID display_cd(drv)
#endif
REG WORD drv;
#if !defined(NOXBATCH) && (defined(CDOS) || defined(CDOSTMP))
UWORD	flags;			/* Command Flags		*/
#endif
{
BYTE	dispbuf[MAX_PATHLEN];
WORD	ret;

	dispbuf[0] = (BYTE) (drv + 'A');	/* Display the path of the */
	dispbuf[1] = ':';			/* requested drive	   */
	dispbuf[2] = *pathchar;

	ret = ms_x_curdir(drv+1, dispbuf+3);
	if (ret < 0) return;
	
#if !defined(NOXBATCH) && (defined(CDOS) || defined(CDOSTMP))
        if (CHDIR_BAT)
            printf ("CHDIR %s\n", dispbuf);
        else
#endif
            printf ("%s\n", dispbuf);
}
/*RG-03-end*/


#define	CHDIR_ALL	(flags & 1)	/* Display Current Assignments	*/

GLOBAL VOID CDECL cmd_cd(s)
REG BYTE *s;
{
	BYTE	*cp;
	ULONG	login;			/* Login Vector 		*/
	WORD    ret;			/* General purpose variable	*/
	UWORD	flags;			/* Command Flags		*/

/*rbf remove trailing spaces from string 's'*/
char *p = s;

while ( (*p!=' ') && *p)
	p++;
*p=0;
/*rbf-end*/

#if defined(CDOS) || defined(CDOSTMP)
        if (f_check (s, "ab", &flags, NO))	/* Check for valid Flags    */
#else
        if (f_check (s, "a", &flags, NO))	/* Check for valid Flags    */
#endif
            return;			  /* invalid then don't do it     */

	if(CHDIR_ALL) {			/* Display the current drive	*/

	    for(ret = 0; ret < 26; ret++)
/*RG-03*/
#if !defined(NOXBATCH) && (defined(CDOS) || defined(CDOSTMP))
		display_cd(ret,flags);
#else
                display_cd(ret);
#endif
/*RG-03-end*/

	    return;
	}
	
	cp = s = deblank(strlwr(s));	/* Deblank after the Flag Check   */

	if(*(s+1) == ':') {		/* check for a drive specifier	  */
	    ddrive = *s - 'a';		/* Get the drive letter and check */
	    s = deblank(s+2);		/* that it is a valid drive and   */
					/* is not the LOAD Drive.	  */

	    if(INVALID_DRV(ddrive)) {
		e_check(ED_DRIVE);
		return;
	    }
	}
	else
	    ddrive = drive;		/* Use the default drive	  */

	if(*s == '=') { 		/* Floating Drive Assignment	  */
	    if(*++s) {			/* Check source drive if spec.	  */
	    	if((s = d_check(s)) == 0)/* Abort if an illegal drive is   */
		    return; 		/* selected.			  */

		if(!*s)			/* If the command is of the form  */
		    strcpy(s, "."); 	/* x:=y: then append a "."	  */
	    }
	}
	else if(!*s) {			/* Display the selected drives	  */
	    if(d_check(cp))		/* current sub-directory.	  */
/*RG-03-*/
#if !defined(NOXBATCH) && (defined(CDOS) || defined(CDOSTMP))
		display_cd(ddrive,flags);
#else
		display_cd(ddrive);
#endif
/*RG-03-end*/
	    return;
	}

	if (*cp == '.') {
		while (cp[1] == 32) {
			ret = 1;
			while (cp[ret]) {
				cp[ret] = cp[ret+1];
				ret++;
			}
		}
	}	
	/* Make the drive Assignment	  */
	if (!d_check(cp)) ddrive = -1;
	e_check(ddrive != -1 ? ms_x_chdir(cp) : ED_DRIVE);
}


#if !defined(EXT_SUBST)

/*.pa*/
#define	SUBST_DEL	(flags & 1)
/*RG-03-*/
#if !defined(NOXBATCH) && (defined(CDOS) || defined(CDOSTMP))
#define	SUBST_BAT	(flags & 2)
#endif
/*RG-03-end*/

GLOBAL VOID CDECL cmd_subst(s)
BYTE	*s;
{
	BYTE	cp[MAX_FILELEN+3];	/* CHDIR Path Buffer		*/
	BYTE	root[4];
	ULONG	login;			/* Logical Drive Vector		*/
	UWORD	flags;			/* Command Flags		*/
	UWORD	drv;
	WORD	i;

#if defined(CDOS) || defined(CDOSTMP)
	if(f_check(s, "db", &flags, NO))	/* Check for Flags if any are   */
#else
        if(f_check(s, "d", &flags, NO))	/* Check for Flags if any are   */
#endif
	    return;			/* invalid then don't do it     */

	s = deblank(strlwr(s));		/* Deblank after the Flag Check   */

	if(!*s) {			/* If the command line is blank   */
	    login = logical_drvs();	/* then display the assignments   */
	    				/* for all the logical drives	  */

	    for(drv = 0; drv < 26; drv++, login >>= 1)
		if(login & 1L) {
		    sprintf(root,"%c:\\", drv+'A');
		    ms_x_expand(cp, root);
/*RG-03*/
#if !defined(NOXBATCH) && (defined(CDOS) || defined(CDOSTMP))
                if(SUBST_BAT)
		        printf("SUBST %c: %s\n", drv + 'A',cp);
                else
#endif
/*RG-03-end*/
		        printf("%c: => %s\n", drv + 'A',cp);
		}

	    return;
	}

	if(*(s+1) == ':') {		/* Check for a drive specifier	  */
	    ddrive = *s - 'a';		/* Get the drive letter and check */
	    s = deblank(s+2);		/* that it is a valid drive and   */
					/* is not the LOAD Drive.	  */

	    if(INVALID_DRV(ddrive)) {
		e_check(ED_DRIVE);
		return;
	    }
	}
	else {
	    syntax();			/* If no drive is specified then  */
	    return;			/* return after displaying a	  */
	}	    			/* syntax error message		  */

#if defined(DOSPLUS)
	if(network_drvs() & (1L << ddrive)) {	/* if requested drive is  */
	    eprintf(MSG_NETSUBST);		/* remote then complain	  */
	    return;				/* and don't do anything  */
	}
#endif
	sprintf(cp, "%c:=", ddrive+'A');	/* Prepare CHDIR command	  */

	if(!SUBST_DEL) {			/* Check for the Delete Flag	  */
	    strcat(cp, s);
	    if((s = d_check(s)) == 0)	/* Abort if an illegal drive	  */
		return; 		/* is selected. 		  */

	    if(!*s) {			/* If no PATH is specified then	  */
		printf(MSG_INOP);	/* display display error message. */
		return;
	    }
	}

	e_check(ms_x_chdir(cp));	/* Make the drive Assignment	  */
}
#endif

/*.pa*/
/*
 *	DATE [DD/MM/YY]
 *
 *	Display or Set the current date making full use of the DOS
 *	international system call.
 */

GLOBAL VOID CDECL cmd_date(s)
BYTE	*s;
{
	BYTE	buffer[18];			/* Local Input Buffer */

	if (*s) {
	    if(check_date(s))
		return;
	    printf (INV_DATE);
	}
	else {
	    printf (CUR_DATE);
	    disp_sysdate();
	}

	FOREVER {
	    printf (NEW_DATE, date_format(country.dt_fmt));
	    buffer[0] = sizeof(buffer) -2;	/* Set maximum string length */
	    system(MS_C_READSTR, buffer);
	    crlf ();

	    if (buffer[1] == 0) 		/* Check for 0 length input */
		return; 			/* and return if so */

	    buffer [buffer[1]+2] = '\0';
	    if (check_date (buffer+2))
		return;

	    printf (INV_DATE);
	}
}


MLOCAL BYTE * date_format(fmt)
UWORD			fmt;
{
    switch (fmt)
    {
    case 1:	return EURO_DATE;
    case 2:	return JAP_DATE;
    default:	break;
    }

    return US_DATE;
}



/*
 *	Parse the string pointed to by s and check for a valid date
 *	specification. If the date has been specified correctly then
 *	set the system date.
 */

MLOCAL BYTE date_sep[] = "/.-";

MLOCAL BOOLEAN check_date(s)
BYTE *s;
{
	SYSDATE date;
	WORD	p1, p2, p3;		/* Input Parameters */

	deblank(s);			/* Remove spaces */

	if (!getdigit (&p1, &s) ||
	    !strchr(date_sep, *s++) ||
	    !getdigit (&p2, &s) ||
	    !strchr(date_sep, *s++) ||
	    !getdigit (&p3, &s))
	{
	    return NO;
	}

	switch (country.dt_fmt) {
	 case 1:			/* European Format dd/mm/yy */
	    date.day = p1;
	    date.month = p2;
	    date.year = p3;
	    break;

	 case 2:			/* Japanese Format yy/mm/dd */
	    date.day = p3;
	    date.month = p2;
	    date.year = p1;
	    break;

	 default:			/* US Format mm/dd/yy */
	    date.day = p2;
	    date.month = p1;
	    date.year = p3;
	    break;
	}

	if (date.year >= 80 && date.year <= 99)
	   date.year += 1900;

	return !ms_setdate(&date);
}


/*.pa*/
/*
 *	DEL [d:][path][filename][.ext]
 *
 *	Erase a file(s) as specified by the path if no path is given
 *	erase all files on the default|specified drive.
 */
GLOBAL VOID CDECL cmd_del(path)
BYTE	*path;
{
	erase (path, NO);		/* erase files, don't confirm */
}

#define	DIR_DIR		(0x0001)	/* Display Directory Files */
#define DIR_SYS		(0x0002)	/* Display System Files	   */
#define	DIR_ALL		(0x0004)	/* Display ALL Files	   */
#define DIR_WIDE	(0x0008)	/* Wide Directory Listing  */
#define	DIR_LONG	(0x0010)	/* Long Directory Listing  */
#define DIR_PAGE	(0x0020)	/* Page Output		   */
#define	DIR_REM		(0x0040)	/* Remember these Options  */
#define DIR_CHANGE	(0x0080)	/* Change the Default Opts */
#define	DIR_NOPAGE	(0x0100)	/* No Paging of Output	   */
#define DIR_2COLS	(0x0200)	/* double column listing   */
#define	OPT(x)		(flags & x)	/* Return Flag Conditions  */

MLOCAL UWORD dir_default = DIR_DIR | DIR_LONG;

MLOCAL UWORD dir_flags(flags)
REG UWORD flags;
{
	if(OPT(DIR_NOPAGE))		/* Force DIR_PAGE to be cleared	*/
	    flags &= ~DIR_PAGE;		/* if NOPAGE has be selected	*/

	if(OPT(DIR_LONG)) {		/* Force DIR_WIDE to be cleared	*/
	    flags &= ~DIR_WIDE;		/* if the LONG format has been	*/
	    flags &= ~DIR_2COLS;	/* selected.			*/
	}

	if(OPT(DIR_2COLS)) {
	    flags &= ~DIR_LONG;
	    flags &= ~DIR_WIDE;
	}

	if(page_wid < 76)		/* Check the screen is wide	*/
	    flags &= ~DIR_WIDE;		/* enough to display directory	*/
	    
	if(page_wid < 78)
	    flags &= ~DIR_2COLS;
	
	if(OPT(DIR_DIR))
	    flags &= ~DIR_SYS;
					/* Check if the new options 	*/
	if(OPT((DIR_CHANGE|DIR_REM))) {	/* should become the default	*/ 
	    dir_default = flags & ~(DIR_CHANGE|DIR_REM);
	}

	if (flags) return(flags);
	else       return(dir_default);
}


GLOBAL VOID CDECL cmd_dir (cmd)
REG BYTE *cmd;
{
	WORD	 nfiles, system, others, i;
	LONG	 nfree = 0L;
	DTA	 search;
	BYTE	 path[MAX_FILELEN];
	BYTE	 s[MAX_PATHLEN], temp[3];
	BYTE	 *ext, *memory;
	UWORD	 free, secsiz, nclust;
	UWORD	 flags;

	if(f_check (cmd, "dsawlprcn2", &flags, NO))	/* if any bad flags */
	    return;					/*    don't do it   */

	flags = dir_flags(flags);	/* Manipulate the flags to remove   */
					/* duplication and conflicts	    */
	if(OPT(DIR_CHANGE))		/* Just change the default values   */
	    return;			/* then return to the caller	    */

	get_filename(path, deblank(cmd), YES);	/* Extract the filename     */

	if (path[0]=='.' && path[1]=='.' && path[2]=='.' && path[3]=='\0')
	{
	   path[0]='*';
	   path[2]='\0';
	}
	if (d_check(path) == NULLPTR) return;/* get out now if invalid drive */
	if (ddrive != -1)
	{
	    strcpy(s,"d:"); s[0] = (BYTE) (ddrive + 'A');
	    append_slash(s);
	    ms_x_curdir(ddrive+1,s+3);	/* get the current dir */
	}
	else
	    ms_x_expand(s,path);

	ext = fptr(path);
	if(*ext == '.' && strcmp(dotdot+1, ext) && strcmp(dotdot, ext)) {
	    strcpy(heap(), ext);
	    strcpy(ext, "*");
	    strcat(ext, heap());
	}

#if defined(PASSWORD)
	*(BYTE *)heap() = '\0';			/* Remove the Password	   */
	memory = strchr(ext, *pwdchar);		/* if one has been used	   */
	if(memory) {				/* and save on the heap	   */
	    strcpy(heap(), memory);
	    *memory = '\0';
	}
#endif

	while(*ext && !strchr(ext, '.')) {	/* If a filename has been   */
	    if(!iswild(ext)) {			/* specified and it does not*/

#if defined(PASSWORD)
	      if (ddrive != -1 && ms_x_chdir(s) < 0) {
	/* if cd to current dir fails then current dir must be password     */
	/* protected. So let's do the next bit the non-novell way.	    */

	/* This method of determining if the user has specified a directory */
	/* DOES NOT work on NOVELL drives.				    */

		ret = ms_x_chmod(path, 0, 0);	/* contain a '.'. Skip if   */
		if(ret > 0 && (ret & ATTR_DIR))	/* a path was specified.    */
		    break;			/* Otherwise append ".*".   */

	      }
	      else {
#endif
	/* This method of determining if the user has specified a directory */
	/* DOES work on NOVELL drives.					    */

	/* But not when the current directory is password protected!        */

#if defined(PASSWORD)
		if (memory) strcpy(memory,heap());  /* reattach password */
#endif
		if (ddrive != -1)
		{
		    ret = ms_x_chdir(path);	 /* try to cd to path specified */
#if defined(PASSWORD)
		    if (memory) *memory = 0; /* remove password again */
#endif
		    if (ret >= 0) {		 /* if there wasn't an error... */
			ms_x_chdir(s);	 /* ...restore original directory... */
			break;		 /* ...and get the hell out */
		    }
		}
		else
		{
		    ret = ms_x_chmod(path,0,0);
		    if (ret >= 0 && (ret & ATTR_DIR)) break; 
		}
#if defined(PASSWORD)
	      }
#endif
	    }
	    strcat(ext, ".*");          /* append ".*" to pathname */
	}

#if defined(PASSWORD)
	strcat(ext, heap());			/* Reattach the Password    */
#endif

	if(nofiles(path, ATTR_ALL, NO, YES)) 	/* if no files/dirs or error*/
	    return;				/* then we can't do this    */

	if (ddrive != -1)
	{
	    strcpy (temp, "d:");		/* Display the drive Volume	*/
	    temp[0] = (BYTE) (ddrive+'A');	/* label using the VOL command	*/
	    cmd_vol(temp);
	}
	else
	    show_crlf(OPT(DIR_PAGE));

#if 0
	/* this has been done earlier */
	strcpy(s, "d:"); s[0] = (BYTE) (ddrive + 'A');
	append_slash(s);
	ms_x_curdir(ddrive+1, s+3);	/* Get the current dir		*/
#endif

	strip_path(path, memory = (BYTE *)heap());/* Get the Path Spec and  */
	if((i = strlen(memory)) >		/* Remove the Trailing 	    */
		(memory[1] == ':' ? 3 : 1))	/* Path Character.	    */
		memory[--i] = '\0';

	if(i == 0 || (i == 2 && memory[1] == ':')) {
	    printf (MSG_DIR, temp, s+3);	/* DIR of current Directory  */
	}
	else
	{
	  if (ddrive == -1 || ms_x_chdir(s) < 0) { /* assume this means pword protected */
	    ext = memory+strlen(memory)+1;
	    ms_x_expand(ext,memory);
	    if (ddrive != -1)
	      printf(MSG_DIR, temp, ext+3);
	    else
	      printf(MSG_DIR,"",ext+1);
	  }
	  else {
	    ms_x_chdir(memory); 		/* Change the directory      */
	    ms_x_curdir(ddrive+1, memory);	/* Get the current directory */
	    ms_x_chdir(s);			/* Restore the directory     */
	    printf (MSG_DIR, temp, memory);
	  }
	}

	others = 0;			/* assume no SYS/DIR files	*/
	nfiles = 0;			/* initialize file count	*/
	linesleft = page_len - 4;	/* lines until pause		*/

	system = OPT(DIR_SYS) ? ATTR_SYS : 0;

	ret = ms_x_first(path, ATTR_ALL, &search);

	if(!ret && (search.fattr & ATTR_DEV))	/* Check if the user has     */
	    ret = ED_FILE;			/* specified a device then   */
						/* generate an error.	     */
	while(!ret) {
	    if(!OPT(DIR_ALL) && (search.fattr & ATTR_SYS) != system) {
						/* not the correct file type*/
		others++;			/* remember others do exist */
		ret = ms_x_next(&search);	/* get the next file and    */
		continue;			/* continue the display     */
	    }

	    ext = strchr(search.fname, '.');	/* Get the file extension   */
	    if(ext && ext != search.fname)	/* set the extension to NULL*/
		*ext++ = '\0';			/* if no '.' exists or this */
	    else				/* is the ".." or "." entry.*/
		ext = "";

	    if(OPT(DIR_WIDE)) {
		if ((nfiles % 5) == 0)
		    show_crlf(OPT(DIR_PAGE));

		printf ("%c:%c%-9s%-3s",
			(nfiles % 5) ? ' ' : ddrive + 'A',
			(search.fattr & ATTR_DIR) ? *pathchar : ' ',
			search.fname, ext);
	    }
	    else {
		if (OPT(DIR_2COLS)) {
		    if ((nfiles % 2) == 0) show_crlf(OPT(DIR_PAGE));
		}
		else
		    show_crlf(OPT(DIR_PAGE));
		printf("%-9s%-3s", search.fname, ext);
		if (search.fattr & ATTR_DIR)
		    printf(" <DIR>   ");
		else
		    printf ("%9lu", search.fsize);

		if(search.fdate) {	   /* if timestamp exists */
		    printf (" "); disp_filedate (search.fdate);
		    printf (" "); disp_filetime (search.ftime);
		    if ((OPT(DIR_2COLS)) && (nfiles%2 == 0)) printf ("   ");
		}
		else {
		    if ((OPT(DIR_2COLS)) && (nfiles%2 == 0)) printf("\t\t\t");
		}
	    }
	    nfiles ++;
	    ret = ms_x_next(&search);
	}

	if(others + nfiles == 0) {	/* If no matching files then exit  */
	    e_check(ED_FILE);		/* after displaying File Not Found */
	}

	if(ddrive != -1 && (ret = ms_drv_space(ddrive+1, &free, &secsiz, &nclust)) < 0) {
	    /*e_check(ED_PATH);*/
	    /*return;*/
	    ret = 0; /* This prevents 'Invalid directory...' when looking */
		     /* at a PNW login drive. */
	}

	show_crlf(OPT(DIR_PAGE));
	nfree = (LONG)ret * (LONG)free * (LONG)secsiz;
	if (ddrive != -1)
	    printf ("%9d %s%10ld %s", nfiles, MSG_FILES, nfree, MSG_FREE);
	else
	    printf ("%9d %s", nfiles, MSG_FILES);
	show_crlf(OPT(DIR_PAGE));

	if(others)			/* if others do exist, tell them */
	    printf (MSG_EXIST, system ? MSG_NSYS : MSG_NDIR);
}


GLOBAL VOID CDECL cmd_echo(s, o)
REG BYTE	*s;		/* Deblanked Command Line	*/
REG BYTE	*o;		/* Original Untainted Commmand	*/
{
	
	if (*o) o++;				/* delete 1 whitespace or   */
						/* punctuation char from the*/
						/* original command line    */
	s = deblank(s);

	switch(onoff(s)) {			/* if "ECHO=on/off"	    */
	    case YES:				/* ECHO = ON		    */
		echoflg = ECHO_ON;
		break;

	    case NO:				/* ECHO = OFF		    */
		echoflg = ECHO_OFF;
		break;

	    default:
		if(*s || (o != s && batchflg)) {	/* if command line   */
		    puts(o);			/* display string    */
	    	    crlf();
		}
		else
	    	    printf (MSG_ECHO,			/* print current     */
		    	echoflg ? MSG_ON : MSG_OFF);	/* echo status	     */
		break;
	}
}
#if !defined(NOXBATCH) && (defined(CDOS) || defined(CDOSTMP))
/*RG-02-*/
GLOBAL VOID CDECL cmd_echoerr(s, o)
REG BYTE	*s;		/* Deblanked Command Line	*/
REG BYTE	*o;		/* Original Untainted Commmand	*/
{
        BOOLEAN  err_save;

        err_save=err_flag;
	err_flag = TRUE;
        cmd_echo(s,o);
	err_flag = err_save;
}
#endif
/*RG-02-end*/


GLOBAL VOID CDECL cmd_exit(cmd)
BYTE *cmd;
{
	err_ret = 0;
	
	if(*deblank(cmd))			/* If a number has be 	   */
	    check_num(cmd, 0, 255, &err_ret);	/* specified use this for  */
	    					/* the exit code.	   */
	if(batchflg) {			/* If processing a batch file	    */
	    batch_end();		/* then exit batch file 	    */
#if defined(CDOSTMP)
	    return;
#endif
	}

#if defined(CDOSTMP)	     
	bdos(C_DETACH, 0);		/* Allow another process to attach */
	bdos(P_DISPATCH, 0);		/* to the console if they are	   */
	bdos(C_ATTACH, 0);		/* waiting in the background.	   */

#else
	if(execed) {			/* If command.com has been execed   */
	    *parent_psp = save_parent;

	    ms_set_break(break_flag);	/* then return to the invoking prog */
	    				/* Otherwise ignore the command     */

#if	defined(CPM)			/* Clean-Up the CPM disk handling   */
	    cpm_de_init();		/* code before we terminate.	    */
#endif
	    restore_error_mode();
	    restore_term_addr();	/* restore the PSP terminate address*/
	    ms_x_exit(err_ret);		/* If we return from the EXIT call  */
	    execed = NO;		/* then this must be the root	    */
	    printf("Hello\n");
	}				/* process. Invoked without '/P'    */
#endif
}


GLOBAL VOID CDECL cmd_md(s)
REG BYTE *s;
{
	/*BYTE	 path[MAX_FILELEN];*/

	crlfflg = YES;
#if 0
	get_filename(path, deblank(s), FALSE);	/* Pathname  */

	if(!d_check(path))
	    return;
#endif
	if((ret = ms_x_mkdir(s)) != 0) {	/* if any errors occurred    */
	    if (ret == ED_DRIVE)		/* if invalid drive	     */
		e_check(ret);			/*    then say so	     */
	    else				/* else use standard formula */
		eprintf(MSG_MKDIR);		/* Unable to create directory*/
	    return;
	}

	crlfflg = NO;
}


/*.pa*/
/*
 *	PATH [[d:]path[[;[d:]path]..]] | [;]
 *
 *	Display or set the command search path in environment.
 */
GLOBAL BYTE msg_patheq [] = "PATH=";	/* Static Environment String   */

GLOBAL VOID CDECL cmd_path(path)
REG BYTE *path;
{
	REG BYTE *s;
#if !STACK
	BYTE	 sbuf[MAX_ENVLEN];
#endif

	zap_spaces(path);		/* Remove all white space	    */
	if(!*path) {
	    if(env_scan(msg_patheq, s = (BYTE *)heap()))
		printf(MSG_PATH);		/* If no path exists then    */
	    else {				/* display "NO PATH" otherwise */
		printf(msg_patheq);		/* display the current path  */
		/*printf("%.122s\n",s);*/
		printf(path_template,s);
	    }
	    crlfflg = YES;
	    return;
	}

	if(*path == '=' || *path == ';')/* Skip Leading '=' or ';' chars    */
	    path++;			/* then set the PATH		    */

#if STACK
	s = stack(strlen(msg_patheq) + strlen(path) + 1);
#else
	s = &sbuf[0];
#endif
	strcpy(s, msg_patheq);		/* build command line for "SET"   */
	strcat(s, strupr(path));
	cmd_set(s); 			/* set new path using "SET"	    */
}

GLOBAL VOID CDECL cmd_pause(msg)
BYTE	*msg;
{
BYTE	c;

	if (*msg) printf("%s\n",msg);

	batch_close();			/* Close Any Batch files in case */
					/* the user is going to swap the */
					/* disk with the batch file.	 */
	printf(MSG_PAUSE);		/* prompt to hit any key	*/

#if defined(CDOSTMP)
	c =(BYTE) bdos(C_RAWIO, 0xFD);	/* Get a character from console */

	if ((c==0) ||(dbcs_lead(c)))
	    bdos(C_RAWIO, 0xFD);	/* skip second byte in DBCS pair */
#else
	c = (BYTE) msdos(MS_C_RAWIN, 0);/* Get a character from console */
	if ((c==0) || (dbcs_lead(c)))
	    msdos(MS_C_RAWIN, 0);	/* skip second byte in DBCS pair */
#endif

	sprintf(heap(), "%s", MSG_PAUSE);	/* Copy MSG_PAUSE into  */
	printf("\r%*s\r", strlen(heap()), "");  /* Data Segment and 	*/
						/* then calculate length*/

	if(c == 0x03)			/* Control C Check		*/
	    int_break();
}

/*
 *	This PAUSE command will output the prompt string to STDOUT regardless
 *	of its destination. However it will ensure that the character is read
 *	from the console device by "POKING" the PSP.
 */
GLOBAL VOID CDECL cmd_stdin_pause(void)
{
UWORD	in_h,stderr_h;
BYTE	c;

	batch_close();			/* Close Any Batch files in case */
					/* the user is going to swap the */
					/* disk with the batch file.	 */
	printf(MSG_PAUSE);		/* prompt to hit any key	*/

	stderr_h = psp_poke(STDERR,1);
	in_h = psp_poke(STDIN, stderr_h); /* Get the Real Console		*/
	psp_poke(STDERR,stderr_h);

#if defined(CDOSTMP)
	c =(BYTE) bdos(C_RAWIO, 0xFD);	/* Get a character from console */

	if ((c==0) ||(dbcs_lead(c)))
	    bdos(C_RAWIO, 0xFD);	/* skip second byte in DBCS pair */
#else
	c = (BYTE) msdos(MS_C_RAWIN, 0);/* Get a character from console */
	if ((c==0) || (dbcs_lead(c)))
	    msdos(MS_C_RAWIN, 0);	/* skip second byte in DBCS pair */
#endif

	psp_poke(STDIN, in_h);		/* restore original handle 	*/

	sprintf(heap(), "%s", MSG_PAUSE);	/* Copy MSG_PAUSE into  */
	printf("\r%*s\r", strlen(heap()), "");  /* Data Segment and 	*/
						/* then calculate length*/

	if(c == 0x03)			/* Control C Check		*/
	    int_break();
}

#if !defined(NOXBATCH) && (defined(CDOS) || defined(CDOSTMP))
/*
 *	The PAUSE command will output the prompt string to STDOUT regardless
 *	of its destination. However it will ensure that the character is read
 *	from the console device by "POKING" the PSP.
 */
GLOBAL VOID CDECL cmd_pauseerr()
{
        BOOLEAN  err_save;

        err_save=err_flag;
	err_flag = TRUE;
        cmd_pause();
	err_flag = err_save;
}
#endif
/*RG-02-end*/

/*.pa*/
/*
 *	PROMPT [prompt-text]
 *
 *	Set the system prompt as specified by the prompt text if no 
 *	prompt text is specified then the default $n$g is used.
 */
GLOBAL BYTE msg_prmeq  [] = "PROMPT=";	/* Static Environment String */

GLOBAL VOID CDECL cmd_prompt(s)
REG BYTE    *s;
{
	REG BYTE *bp;
#if !STACK
	BYTE	 bpbuf[MAX_ENVLEN];
#endif

	if (!*s)			/* if no string */
	    s = DEFAULT_PROMPT; 	/* use the default */

	while ((*s == '=') || (*s == ' ')) s++;

#if STACK
	bp = stack(strlen(msg_prmeq) + strlen(s) + 1);
#else
	bp = &bpbuf[0];
#endif
	strcpy(bp, msg_prmeq);		/* environment variable */
	strcat(bp, s);			/* add new value */
	cmd_set(bp);			/* update environment */
}


GLOBAL VOID CDECL cmd_rem ()
{
	crlfflg = 0;
/* Make sure REM turns off pipes too */
/* You can't do this !!!!! MSDOS allows "REM | DIR" etc - IJ */
#if 0
	pipe_in=pipe_out=NO;
#endif
}



#define	REN_CHECK	(flags & 1)

GLOBAL VOID CDECL cmd_ren(s)
REG BYTE *s;
{
	BYTE	 srcfile[MAX_FILELEN], dstfile[MAX_FILELEN];
	BYTE	 pattern[MAX_FILELEN-MAX_PATHLEN];  
	BYTE	 *enddir;
#if defined(PASSWORD)
	BYTE	*password;
#endif
	DTA	 search;
	UWORD	flags;
	WORD	attr;
#if !STACK
	BYTE	passbuf[MAX_FILELEN];
#endif
        char lastchar;
        unsigned length;

	if(f_check(s, "c", &flags, NO))		/* Check the selected flags */
	    return;				/* and return on error	    */

	s = get_filename(srcfile, deblank(s), TRUE);	/* Source Filename  */

	s = get_filename(dstfile, deblank(s), TRUE);	/* Destination File */

	length = strlen(dstfile);
	lastchar = dstfile[ length-1];
        
	if (dbcs_expected()){
	 if ( (length > 2) && (!dbcs_lead(dstfile[length-2])) ){
/*
		if ( (lastchar == ':') || (lastchar == '\\') ){
*/
		if (lastchar == ':'){
		printf(msg_invalid_file);
		return;
		}
	 }
	}
	else{
/*
	if ( (lastchar == ':') || (lastchar == '\\') ){
*/
	if (lastchar == ':'){
		printf(msg_invalid_file);
		return;
	    }
	}

	if (!iswild(srcfile)) {
	    attr = ms_x_chmod(srcfile,0,0);
	    if ((attr > 0) && (attr & ATTR_DIR)) {

		/* Don't try to rename directories. Leave it to RENDIR. */

		printf(MSG_USE_RENDIR);
		return;
	    }
	}

	if(nofiles(srcfile, ATTR_ALL, YES, NO))	/* if no source files then  */
	    return;				/* error message and stop   */

	if(nofiles(dstfile, ATTR_ALL, NO, NO))	/* Check the Destination    */
	    return;				/* path exists		    */

	if(fptr(srcfile) != srcfile && fptr(dstfile) == dstfile) {
	    strcpy(heap(), dstfile);		/* If no path is specified  */
	    strip_path(srcfile, dstfile);	/* on the NewFile then force*/
	    strcat(dstfile, heap());		/* use the OldFile Path.    */
						/* Because of the Holy Grail*/
	}					/* of MS-DOS compatiblity.  */

	enddir = fptr(srcfile); 		/* Isolate source filename  */
#if defined(PASSWORD)
	password = strchr(enddir, *pwdchar);	/* Check for Source password*/
	if(password) {				/* and save in internal buf.*/
#if STACK
	    password = stack(strlen(password)+1);
#else
	    password = &passbuf[0];
#endif
	    strcpy(password, strchr(enddir, *pwdchar));
	}
#endif

	strcpy(pattern, fptr(dstfile)); 	/* Save the destination	    */
						/* match pattern.	    */

	ms_x_first (srcfile, (ATTR_STD&(~ATTR_SYS)), &search);
	do {
	    strcpy(enddir, search.fname);	/* append file name to path */

	    if(REN_CHECK) {			/* confirm option active?   */
		printf(MSG_ERAQ, srcfile);	/* then prompt the user and */
		if(!yes(YES, NO))		/* act on the reponse	    */
		    continue;
	    }

	    strcpy(fptr(dstfile), pattern);	/* Assert the Destination   */
	    repwild(srcfile, dstfile);		/* pattern.		    */

#if defined(PASSWORD)
	    if(password)			/* Append the password to   */
		strcat(srcfile, password);	/* the sorce file if one    */
						/* has been specified.	    */
#endif

	    if((ret = ms_x_rename(srcfile, dstfile)) < 0) {
		crlfflg = YES;
#if defined(CDOSTMP) || defined(CDOS)
		if((ret == ED_ACCESS) &&
		   (ms_x_first(dstfile, ATTR_ALL, &search) >= 0))
#else
		if(ret == ED_ACCESS)
#endif
		    eprintf(MSG_REN);
		else
		    e_check(ret);
		return;
	    }
	} while(!ms_x_next(&search));		/* get the next file */
}


/*.pa*/
/*
 *
 */
GLOBAL VOID CDECL cmd_rd(s)
REG BYTE *s;
{
	/*BYTE	 path[MAX_FILELEN];*/

	crlfflg = YES;
#if 0
	get_filename(path, deblank(s), FALSE);	/* Pathname  */

	if(!d_check(path))
	    return;
#endif
	if((ret = ms_x_rmdir(s)) != 0) {	/* if can't remove directory */
	    if(ret == ED_DIR || ret == ED_FILE || ret == ED_ACCESS)
	    					/* because its in use by     */	
		eprintf(MSG_RMDIR);		/* by another process or is  */
	    else				/* empty then print special  */
		e_check(ret);			/* message other wise use    */
	    return;				/* standard error handler    */
	}

	crlfflg = NO;
}


GLOBAL VOID CDECL cmd_set(s)
BYTE *s;
{
	BYTE	 c;
	REG BYTE *key;
	BYTE	*t;
	WORD	 i;

	if(!*s) {				/* if no cmd, display env */
	    for(i=0; !env_entry(key = (BYTE *)heap(), i); i++) {
	        puts(key);			/* Print the Environment   */	
		crlf();				/* variables directly to   */
	    }					/* avoid size problems.	   */
	    return;
	}
					/* else need to set env var */

	/* msdos removes leading blanks, commas, semicolons and equal signs,
	but keeps spaces in the variable name (SPR 770044) JBM */

/*	remove any spaces before the equals sign
	key = s;
	while (*s && (*s != '=')) {
		if (*s == 32 || *s == 9) {
			t = s;
			while (*t++) *(t-1) = *t;
		}
		if (*s == '=') break;
		s++;
	}
*/
	key = s;
	while (*s && (*s == 0x20 || *s == 0x09 || *s == ',' || *s == ';' || *s == '=')) {
		t = s;
		while (*t++) *(t-1) = *t;
	}

	s = key;
	while (*s && (*s != '='))	/* look for end of variable */
	    s ++;

	if (!*s || key == s) {		/* If no key has been specified */
	    syntax();			/* or the '=' is missing return */
	    return;
	}				/* a syntax error.		*/
	
	s++;

#if 0
	/* msdos doesn't do this */

	/* remove any space after the equals sign */
	while (*s == 32 || *s == 9) {
		t = s;
		while (*t++) *(t-1) = *t;
	}
#endif

	c = *s;				/* Save Character		*/
	*s = '\0';			/* terminate keyword		*/
	strupr (key);			/* make keyword upper case	 */
	if(env_del(key) < 0) {		/* remove it first		*/
	    printf(MSG_ENVERR); 	/* check for an error.		*/
	    crlfflg = YES;
	    return;
	}
	if((*s-- = c) != 0) {		/* Add the definition to the end*/
					/* of the environment if the new*/
	    if(env_ins(key)) {		/* definition is not NULL	*/
		printf(MSG_ENVFULL);	/* check for an error.		*/
		crlfflg = YES;
		return;
	    }
	}
}


/*.pa*/
/*
 *	Displays or Sets the current system time 
 */
#define	TIME_CON	(flags & 1)

GLOBAL VOID CDECL cmd_time(s)
REG BYTE *s;
{
	BYTE	buffer[18];			/* Local Input Buffer */
	UWORD	flags;				/* Continuous Display	*/

	if(f_check (s, "c", &flags, NO))	/* Check for valid Flags    */
	    return;

	if(TIME_CON) {
	    crlfflg = YES;
	    printf(CUR_TIME);			/* Display the Message */ 

	    FOREVER {
		disp_systime ();		/* Display the Current Time  */
		printf("\b\b\b\b\b\b\b\b\b\b\b"); /* BackSpace over the Time */
#if defined(CDOSTMP)
		if(bdos(C_RAWIO, 0xFE)) 	/* check for a character     */
		    return;			/* and return if one typed   */
#else
		if(msdos(MS_C_STAT, 0) & 0xFF) { /*  Check for a character   */
		    msdos(MS_C_RAWIN, 0xFF);	 /* read it and return to the*/
		    return;			 /* main routine.	     */
		}
#endif
	    }
	}

	if(*s) {
	    if (check_time(s))
		return;
	    printf(INV_TIME);
	}
	else {
	    printf(CUR_TIME);
	    disp_systime ();
	}

	FOREVER {
	    printf (NEW_TIME);
	    buffer[0] = sizeof(buffer)-2;	/* Set maximum string length */
	    system(MS_C_READSTR, buffer);
	    crlf ();

	    if (!buffer[1])			/* Check for 0 length input */
		return; 			/* and return if so */

	    buffer[buffer[1]+2] = '\0';
	    if (check_time (buffer+2))
		return;

	    printf (INV_TIME);
	}
}

/*.pa*/
/*
 *
 */
GLOBAL VOID CDECL cmd_truename(s)
REG BYTE *s;
{
	BYTE	 path[MAX_FILELEN];

	*path = 0;

	/* expand path, current directory if none specified */
	if (*s)
		ret = ms_x_expand(path, s);
	else
		ret = ms_x_expand(path, ".");

	/* if we get an error report it, otherwise display expanded path */
	if (ret)
		e_check(ret);
	else
		printf(path);
}


/*
 *	Parse the string pointed to by s and check for a valid date
 *	specification. If the time has been specified correctly then
 *	set the system time.
 */
MLOCAL BYTE    hour_sep[] = ":.";
MLOCAL BYTE    sec_sep[]  = ".,";

MLOCAL BOOLEAN check_time(s)
BYTE *s;
{
	SYSTIME time;
	WORD	hour, min, sec, hsec;

	min = sec = hsec = 0;		/* Seconds and Hundredths are optional */
					/* and default to zero when omitted */
	zap_spaces(s);			/* Remove all spaces from command   */

	if (!getdigit (&hour, &s))
	    return NO;

	while(*s) {				/* if more than HH */
	    if (!strchr(hour_sep,*s)) return NO;	/* Check for Minute */
	    s++;
	    if (!getdigit (&min, &s)) return NO;

	    if (!*s) break;
	    
	    if (!strchr(hour_sep,*s)) break;	/* Check for Seconds */
	    s++;
	    if (!getdigit (&sec, &s)) break;

	    if (!*s) break;
	    
	    if (!strchr(sec_sep,*s)) break;
	    s++;
	    if (!getdigit (&hsec, &s)) break;

	    break;
	}
	
	if (*s) {
	    *s = toupper(*s);
	    if (*s == 'P' && hour != 12) hour += 12;
            if (*s == 'A' && hour == 12) hour = 0;
	}
	
	time.hour = hour;
	time.min  = min;
	time.sec  = sec;
	time.hsec = hsec;

	return !ms_settime(&time);
}

#define BUFSIZE 256		/* SHOW_FILE buffer size	*/

MLOCAL VOID show_crlf(paging)
BOOLEAN paging;
{
	crlf();
	if(paging && (--linesleft == 0)) {
	    cmd_pause("");
	    linesleft = page_len - 1;
	}
}

/*
 *	Read from channel h until the first Control-Z or the endof file
 *	has been reached. The display is paged if the PAGE_MODE flag is
 *	true otherwise the information is displayed continuous using
 *	the standard flow control.
 */
/*RG-00-make this one public*/
/* MLOCAL VOID show_file(h, paging) */
VOID show_file(h, paging)
/*RG-00-end*/
UWORD h;		/* Channel for File access */
BOOLEAN paging; 	/* Page Mode Flag	   */
{
	BYTE FAR *cp;			/* pointer to end of path	  */
	BYTE FAR *ptr;			/* temporary address for printing */
	BYTE FAR *buf;			/* Input Buffer 		  */
	UWORD bufsize;
	WORD	 n;
	/*BOOLEAN  lfflg = NO;*/	/* Last character a LineFeed	  */
	BOOLEAN  eof = FALSE;		/* End of File Flag		  */
	UWORD	scr_width;
	UWORD	nchars    = 0;
	UWORD	stderr_h,in_h;

	scr_width = get_scr_width();

	mem_alloc(&show_file_buf,&bufsize,BUFSIZE,BUFSIZE);
	buf = show_file_buf;
	
	while (!eof && (n = far_read (h, buf, BUFSIZE)) > 0) {

	    cp = ptr = buf;
	    while (n) { 			/* while more data	*/

		while (n &&			/* while more data	*/
		      (*cp != 0x1a) &&		/* and not EOF Char	*/
		      (*cp != '\n') &&		/* and Linefeed Char	*/
		      (nchars<scr_width)) {     
			if (*cp == 9) nchars = (nchars&-8)+7;
			n--; cp++; nchars++;	/* count chars, next	*/
		}

		if (cp != ptr) {		/* if any ordinary data */
		    far_write(STDOUT, ptr, (UWORD) (cp-ptr));
		    				/* write to CON:        */
		    ptr = cp;			/* flush the rest	*/
		    /*lfflg = NO;*/
		}

		if(n == 0)			/* if end of data	*/
		    break;

		if(*cp == 0x1a) {		/* If ^Z then set	*/
		    eof = TRUE; 		/* EOF flag to TRUE	*/
		    break;			/* and stop printing	*/
		}

		if (*cp == '\n') {		
		    ms_x_write(STDOUT,"\n",1);	/* Display a LF	*/
		    /*lfflg = YES;*/		/* Set the LineFeed Flag*/
		    n--;			/* count LF		*/
		    ptr = ++cp;			/* point past it	*/
		}

	        if(paging && (--linesleft == 0)) {

		    cmd_stdin_pause();

		    linesleft = page_len - 1;
		}
	        nchars = 0;
	    }
	}

	mem_free(&show_file_buf);
}

/*.pa*/
/*
 *
 */
#define	TYPE_PAGE	(flags & 1)

GLOBAL VOID CDECL cmd_type(cmd)
REG BYTE *cmd;
{
	WORD 	ret, h;			/* file handle			  */
	BYTE	path[MAX_FILELEN];	/* Path and File Name		  */
	BYTE	*files;			/* pointer to file spec 	  */
#if defined(PASSWORD)
	BYTE	*password;
#endif
	DTA	search; 		/* Local Search Buffer		  */
	UWORD	flags;			/* only one switch permitted	  */
	BOOLEAN wild_flag = FALSE;	/* Wild Card Type		  */
	BYTE	passbuf[MAX_FILELEN];

	if(f_check(cmd, "p", &flags, NO))       /* if any bad flags */
	    return;				/*    don't do it */

	get_filename(path, deblank(cmd), YES);	/* Extract the Filename     */

	if(d_check(path) == NULLPTR)		/* Check if the specified   */
	    return;				/* drive is valid	    */

	files = fptr(path);			/* isolate the filename     */
#if defined(PASSWORD)
	password = strchr(files, *pwdchar);	/* Check for Source password*/
	if(password) {				/* and save in internal buf.*/
	    strcpy(passbuf, password);
	    *password = 0;			/* discard path password */
	    password = &passbuf[0];		/* and use local copy */
	}
#endif

	if(iswild(files))
	    wild_flag = TRUE;

	linesleft = page_len - 1;		/* Initialize the paging     */
						/* variable used by SHOW_?   */

	/*
	 *	For wild card searches we must initialise search.fname
	 *	with an initial ms_x_first for the DO/WHILE loop.
	 */

	if (wild_flag) {
	    search.fattr = ATTR_STD;
	    ret = ms_x_first(path, ATTR_STD, &search);

	    if (ret < 0) {
	    	e_check(ret);		/* if we can't find anything */
		return;			/* we'd better say so */
	    }
	}

	do {
	    if (wild_flag)
		strcpy(files, search.fname);  	/* make it full pathname     */
	    strcpy(heap(), path);

#if defined(PASSWORD)
	    if(password)
	        strcat(heap(), password);
#endif

	    h = ms_x_open(heap(), OPEN_READ);	/* Open file in sharing mode */
	    if(h == ED_SHAREFAIL || h == ED_ACCESS)	/* if fails with a   */
	        h = ms_x_open(heap(), 0);	/* sharing violation then try*/
						/* opening with compatibilty */
	    if(h < 0) {				/* mode.		     */
		e_check(h);
		return;
	    }

	    if (wild_flag) {		/* if wild card type		*/
		strupr(path);		/* Display UpperCase Filename	*/
		show_crlf(TYPE_PAGE);	/* Print a CRLF with PAGING flag*/
		revon(); printf ("%s:", path); revoff();
		show_crlf(TYPE_PAGE);	/* Print a CRLF with PAGING flag*/
	    }

	    show_file(h, TYPE_PAGE);	/* Output the File to the Screen */
	    ms_x_close(h);		/* Close the File */
	} while (wild_flag && (ms_x_next(&search) >= 0));
}

/*
 *	Displays the data read from Channel 0 until the end of file or 
 *	Control-Z. If no output redirection is inforce then MORE pages
 *	the display using the CMD_PAUSE function.
 *
 *	MORE will only enable PAGING if the output device is the CONSOLE
 *	otherwise paging is disabled.
 */
GLOBAL VOID CDECL cmd_more()
{
	linesleft = page_len -1;		/* Set the Page length and */
	show_file(STDIN, YES);			/* display STDIN till EOF  */
						/* or a Control-Z	   */
}

/*.pa*/
/*
 *
 */
GLOBAL VOID CDECL cmd_ver()
{
	printf(MSG_VERSION, (env_scan("VER=", heap()) ? "" : heap()));
	printf(MSG_CPYRIGHT);
#if !defined(FINAL)
	if(!env_scan("BETA=", heap()))
	    printf("%s\n", heap());
#endif
}

GLOBAL VOID CDECL cmd_vol(path)
BYTE *path;
{
	BYTE	*s;
	BYTE	temp[7];
	DTA	search;
	WORD	ret,i;
	BYTE	label[12];
	
	strcpy(temp,d_slash_stardotstar);
	
	if ((path = d_check(path)) == 0)
	    return;
	if (ddrive == -1) return;

	temp[0] = (BYTE) (ddrive+'A');

	ret = ms_x_first(temp, ATTR_LBL, &search);
	if (ret == ED_DRIVE)
	    e_check(ret);		/* display error if invalid drive */
	else {	
	    printf(MSG_LBL, ddrive+'A');

	    if (ret)
		printf(MSG_NOLBL);
	    else {
		s = search.fname;
		for (i = 0; *s && (i < 8); i++)
		    label[i] = (*s == '.') ? ' ' : *s++;

		if (*s == '.') s++;       /* if there was a '.' skip it */
		for (; *s && (i < 11); ) label[i++] = *s++; /* copy the rest */
		label[i] = '\0';	        /* null terminate label */

		printf(MSG_OKLBL, label);
	    }
	    crlf();
	}
}

/*.pa*/
/*
 *
 */
GLOBAL VOID CDECL cmd_delq(path)		  /* erase files with query */
BYTE	*path;
{
	erase (path, YES);		/* erase files, confirm deletes */
}

EXTERN BYTE FAR * CDECL farptr(BYTE *);
#define	YES_CHAR	(*farptr(YES_NO+0))
#define	NO_CHAR		(*farptr(YES_NO+1))

#define	ERASE_CONFIRM	(flags & 3)
#define	ERASE_SYS	(flags & 4)

MLOCAL VOID erase(s, confirm)
BYTE *s;
BOOLEAN  confirm;
{
	BYTE	path[MAX_FILELEN];		/* FileName Buffer	    */
	BYTE	answer[20];			/* Yes/No string	    */
	BYTE 	*files;				/* pointer to file spec	    */
#if defined(PASSWORD)
	BYTE	*password;
#endif
	UWORD	flags;				/* only one switch permitted*/
	DTA	search; 			/* Local Search Buffer	    */
	UWORD	attr;				/* Erase Search Attributes  */
#if !STACK
	BYTE	passbuf[MAX_FILELEN];
#endif
#if !(defined (CDOSTMP))
	BYTE	savepath[MAX_PATHLEN+1];
	BYTE	newpath[MAX_PATHLEN+2];		/* including trailing \	    */
	BYTE	fcb[37];
	WORD	ret;
	WORD	i;
#endif

	if(f_check(s, "cps", &flags, NO))     	/* if any bad flags return  */
	    return;

	get_filename(path, s, YES);		/* Extract the Filename	    */
	if(strlen(path) == 0) {			/* and check for 0 length   */
	    printf(MSG_NEEDFILE);		/* path caused by invalid   */
	    crlfflg = YES;			/* filename characters in   */
	    return;				/* the command line.	    */
	}

	if ((strcmp(path,dotdot+1) == 0) || (strcmp(path,dotdot) == 0)) {
		strcat(path,d_slash_stardotstar+2);
	}

/* Neil's bodge */
/* del d:. should be the same as del d:*.* */
	if (strlen(path)==3 && path[1] == ':' && path[2] == '.') {
	    path[2] = 0;
	    strcat(path,d_slash_stardotstar+3);
	}
/* end of Neil's bodge */

	attr = ATTR_STD & ~ATTR_SYS;		/* Prevent SYS files from   */
	attr |= ERASE_SYS ? ATTR_SYS : 0;	/* being deleted unless the */
						/* /S option is specified.  */

	if(nofiles(path, attr, YES, YES))	/* if no files or error	    */
	    return;				/*    then we can't do this */

	files = fptr(path);			/* isolate the filename	    */

#if defined(PASSWORD)
	password = strchr(files, *pwdchar);	/* Check for Source password*/
	if(password) {				/* and save in internal buf.*/
#if STACK
	    password = stack(strlen(password)+1);
#else
	    password = &passbuf[0];
#endif
	    strcpy(password, strchr(files, *pwdchar));
	}
#endif

	confirm |= ERASE_CONFIRM;	/* DELQ implies "/c" switch */
	if (!confirm &&			/* if not confirming anyway */
	    (!strncmp(files, "*", 1)&&	/* and all files specified  */
	    strstr(files, ".*")))	/* ie * at start of name & ext */
	{
	    printf(MSG_ERAALL); 	  /* "Are you sure (Y/N)? " */
	    answer[0] = sizeof(answer)-2; /* max. one character	  */
	    answer[1] = 0;		  /* no command recall permitted */
	    system (MS_C_READSTR, answer);/* read the response */
	    crlf();
	    if ((answer[2] & 0xdf) != YES_CHAR) {
	    	crlfflg = YES;		/* if not 'Y' or 'y' given */
		return;			/* then return		  */
	    }
	}

	if(!confirm && ERASE_SYS &&	/* If no confirmation is required */
#if !(defined (CDOSTMP))
	   !iswild(path) &&		/* and this is an ambigous file   */
#endif
	   !ms_x_unlink(path))		/* specification and all the files*/
	    return;			/* are deleted without error then */
					/* return to the calling function */
					/* otherwise delete files	  */
					/* individually.		  */

#if !(defined (CDOSTMP))
/*	use fcb delete if no confirm and system files are not to be	  */
/*	deleted, since it's much quicker. Any problems, go and do it the  */
/*	standard way so we can report on problem files.			  */

	d_check (path);
	if (ddrive != -1 && (!confirm) && (!ERASE_SYS)
#if defined(PASSWORD)
		&& (!password)
#endif
	) {
	    if (!d_check (path))
	        return;

	    if ((ms_f_parse (fcb, files, 0)) < 0) /* set up fname in fcb  */
	        goto fcbdel_end;
	    *fcb = ddrive+1;

	    strcpy (savepath, "d:\\");	/* get curpath on relevant drive  */
	    *savepath = ddrive + 'A';
	    ms_x_curdir (ddrive+1, savepath+3);
	    
	    strncpy (newpath, path, files - path);
	    				/* extract new path		*/
	    newpath[files - path] = '\0';

	    if ((i = strlen (newpath)) > (newpath[1] == ':' ? 3 : 1))
	        newpath[--i] = '\0';	/* remove trailing backslash	*/
	
	    if (! ((i == 0) || ((i == 2) && (newpath[1] == ':'))) )
	        if (ms_x_chdir (newpath))
		    goto fcbdel_end;
	
	    ret = ms_f_delete (fcb);
	    ms_x_chdir (savepath);
	    
	    if (!ret)
	        return;			/* all done			  */
fcbdel_end:
	    ;
	}
#endif
	    
	if (ms_x_first(path, attr, &search)) return;
	do {
	    strcpy(files, search.fname);	/* make it full file name */
	    strcpy(heap(), path);		/* copy to an internal    */
#if defined(PASSWORD)
	    if(password)			/* buffer and append the  */
		strcat(heap(), password);	/* password if present	  */
#endif

	    if(confirm) {
		printf(MSG_ERAQ, path);
		if(!yes(YES, NO))
		    continue;
	    }

	    if((ret = ms_x_unlink(heap())) != 0) {
		printf(MSG_ERA, path);
		e_check(ret);
		crlf();
	    }
	} while (!ms_x_next (&search));
}

#if defined(DOSPLUS)
/*
 *	The HILOAD command accepts a trailing command line.
 *	It will attempt to execute the command line, running any programs
 *	specified in high memory.
 */
GLOBAL VOID CDECL cmd_hiload(s)
REG BYTE *s;
{
int	region, i;

	s = deblank(s);
	if (*s == 0) {
	    printf(msg_inop);
	    return;
	}
	
	global_in_hiload++;
	
	if (global_in_hiload == 1) {
	    global_link  = get_upper_memory_link();
	    global_strat = get_alloc_strategy();
	    region = 1;

	    set_upper_memory_link(1);

	    /* Look out for /L:r1[,s1][;r2[,s2]...] */
	    /* We parse r1, and discard the rest */

	    if ((s[0]==*switchar)&&(toupper(s[1])=='L')&&(s[2]==':')&&isdigit(s[3])){
		region = s[3]-'0';	/* assume region is 1 digit */
		s += 4;			/* skip what we parsed */
		while ((*s==';') || (*s==',') || isdigit(*s))
			s++;
		s = deblank(s);		/* deblank rest of line */
	    }

	    /* discard any /S we find (really we should minimise) */
	    if ((s[0]==*switchar) && (toupper(s[1])=='S')) {
		s += 2;			/* skip the /S */
		s = deblank(s);		/* deblank rest of line */
	    }

	    /* only bother if we have upper memory and are forcing location */
	    if ((region > 1) && (get_upper_memory_link() != 0)) {
		set_alloc_strategy(0x40);	/* First fit high only */
		for(i=1;i<region;i++)		/* allocate regions to skip */
			hidden_umb[i] = alloc_region();
	    }
	
	    set_alloc_strategy(0x80);	/* First fit high */
	}
	
	docmd(s,YES);			/* call normal code */

	if (global_in_hiload == 1) {
	    for(i=1;i<10;i++) {		/* free up any UMB's we have */
		if (hidden_umb[i]) {
			free_region(hidden_umb[i]);
			hidden_umb[i] = 0;
		}
	    }

	    set_upper_memory_link(global_link);
	    set_alloc_strategy(global_strat);
	}
	global_in_hiload --;		/* all back as before */
}

#endif


