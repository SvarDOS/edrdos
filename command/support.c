/*
;    File              : $Workfile: SUPPORT.C$
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

/*
	File		SUPPORT.C
	Title		SUPPORT routines for command.com 

Revision History:-
==================

Date       Description
-----------------------------------------------------------------------------
10 Apr 86  EQU function now makes a case independant match.
29 Apr 86  Single $ preceeds the screen control variables
           Fix bug where if the last character of a screen control
           variable was an octal character it was not printed
 6 May 86  yes() now requires a default to be specified previously
           it assumed the default was NO.
21 May 86  Fixed bug with yes() function when default is NO.
22 May 86  Allow the screen control codes to be patched to longer strings
           Upd`te ZAP_SPACES to delete all white space
Version 1.2
===========
31 Jul 86  Conditionally remove functions that cannot be fully supported
           in a CDOS version of COMMAND.COM
 4 Aug 86  ANSI C compatibility MSC /W1
30 Oct 86  FREE_DRIVE now forces the drive to point to the root
           directory of the current drive.
17 Feb 87  Rewrote repwild() function to fix minor problems 
   Aug 87  Make all routines PASCAL calling convention  (for Concurrent 6)
26 Oct 87  Update the F_CHECK routine to support multiple switches ie
           "/wc" as well as "/w /c".
27 Oct 87  Stop F_CHECK from forcing the input line to lower case.
10 Nov 87  Modify F_CHECK flag zapping
18 Nov 87  Prevent GET_FILENAME copying a filename > than MAX_PATHLEN
16 Dec 87  Update D_CHECK to make fewer system calls.
29 Feb 88  Tidy the REPWILD routine - No Functional Change
15 Mar 88  Use ANSI Escape sequences for DOS Plus
27 Apr 88  Restore Range check to D_CHECK routine
25 May 88  Print a CR after a CLS to reset the current column count.
26 May 88  Change the Default HighLight and LowLight strings to NULL
           for DOSPLUS. 
27 May 88  Added string undefs.
23 Jun 88  Add new ONOFF function for XXX [=] ON|OFF parsing 
28 Jun 88  Correct bug in YES routine for FAR messages
 1 Jul 88  Support Control-C from YES for TMP.
 6 Jul 88  Support the CON:filename syntax for COPY.
19 Sep 88  Enhance error checking on the F_CHECK routine. Now traps the
           condition when switchar is at the end of the line.
 1 Dec 88  Convert all path parsing routines to be KANJI friendly.
21 Dec 88  Add generic ISDEV routine to SUPPORT.C
21 Dec 88  "*" to "*.*" conversion moved to CMD_DIR. 
18 Apr 89  c_write: write to STDERR if err_flag set
6 Jun 89   Correct GET_FILENAME to parse path passwords.
6 Jun 89   echo: check for endline after on/off.
10 Aug 89  get rid of sysdate_fmt (year does not need to be %04d, which
           upsets Japanese day)
10 Aug 89  day_name_len for day_names array elements
22 Aug 89  Japanese dayname comes after date
           Remove day_name_len & work out length from array.
11 Sep 89  strupr(), strlwr() and stricmp() are now Kanji aware.
           toupper() is now in DOSIF.ASM and uses international routine.
16 Oct 89  Kanji specific routines replaced with DBCS routines.
30 Oct 89  "Internal Error" moved to message.c (and no longer resident)
15 Dec 89  errors 50-72 give "Network error" rather than "Internal error"
6-Mar-90   Watcom C v 7.0
13-Mar-90  Output CR/LF after errors
4-May-90   append_slash added
4-May-90   get_filename stops at ';' unless followed by pathchar(s)
           ("append;" bug)
20-Sep-90  Created skip_char() and copy_char().
           Created is_blank() and amended deblank(), zap_spaces(),
           is_filechar() and is_pathchar() to use it.
13-Mar-91  changed nofiles() function to cope with DIR.. on NOVELL drives.
18-Mar-91  tolower() ( and therefore strlwr() ) is now aware of TURKISH
           capital I's with dots. 
6-Aug-91   prompt_exec() function no longer uses the heap. This screwed us
           up if the file to be execed was a batch file.
09-Jun-92  is_pathchar and d_check now cope with drive '[', etc, as used
           by some novell applications. See also INVALID_DRV in command.h.
18-Jun-92  Added optional_line() function for '?' support in batch files.
-----------------------------------------------------------------------------
*/

#include	"defines.h"
#include	<setjmp.h>
/*#include	<string.h>*/

#if defined(MWC) && defined(strlen)
#undef strcmp			/* These are defined as macros in string.h */
#undef strcpy			/* which are expaneded in line under */
#undef strlen			/* Metaware C. These undefs avoid this. */
#endif

#include	<portab.h>
#include	<mserror.h>
#if defined(CDOSTMP)
#include	<ccpm.h>
#include	<sysdat.h>
#endif

#include	"command.h"
#include	"toupper.h"
#include	"dosif.h"
#include	"global.h"
#include	"dos.h"

EXTERN jmp_buf break_env;

EXTERN VOID CDECL printf(BYTE *, ...);
EXTERN VOID CDECL eprintf(BYTE *, ...);
EXTERN VOID CDECL sprintf(BYTE *, BYTE *, ...);
#if defined(CDOSTMP)
EXTERN VOID CDECL int_break(VOID);		/* COM.C Internal Break */
#endif

MLOCAL VOID screen(BYTE *, BYTE *);
MLOCAL VOID outs(BYTE *);
GLOBAL VOID crlf(VOID);
GLOBAL VOID putc(BYTE);
GLOBAL VOID c_write(BYTE *, UWORD);
GLOBAL BYTE * fptr(BYTE *);
GLOBAL BYTE * day_names(UWORD);

/*.pa*/
/*
 *	The following screen control sequences can be redefined or removed
 *	by entries in the environment or the OEM can patch these areas in the
 *	COMMAND.COM object and change the default values.
 *
 */
#define CLS_KEY 	"$CLS=" 	/* CLS entry in environment	    */
#define REVON_KEY	"$ON="		/* REVON entry in environment	    */
#define REVOFF_KEY	"$OFF=" 	/* REVOFF entry in environment	    */

#ifdef DOSPLUS
/*
 *	For DOSPLUS the default screen control sequences are for an
 *	ANSI Terminal (IBM Sub-Set).
 */
#define CLS_DEF 	"\033[2J\0***"	/* Default CLS string "ESC [2J"*/
#define REVON_DEF	"\0********"	/* Default REVON string NULL   */
#define REVOFF_DEF	"\0********"	/* Default REVOFF string NULL  */

EXTERN BOOLEAN CDECL int10_cls(VOID);	/* Dirty Clear Screen Subroutine    */
#else
/*
 *	For Concurrent DOS the default screen control sequences are for a
 *	standard VT52 Terminal.
 */
#define CLS_DEF 	"\033E\0*****"	/* Default CLS string "ESC E"	    */
#define REVON_DEF	"\033p\0*****"	/* Default REVON string "ESC p"     */
#define REVOFF_DEF	"\033q\0*****"	/* Default REVOFF string "ESC q"    */
#endif
					/* Invalid FileName Characters as   */
					/* specified by the IBM DOS Tech    */
					/* Reference Page 6-96 "func 29"    */
MLOCAL BYTE	invalid_filechar[] = "*?\\.:;,=+<>|/\"[]";

/*.pa*/
/*
 *	TIME AND DATE SUPPORT ROUTINES
 *	==============================
 *
 *	The following routines print the TIME and DATE using the international
 *	data. Two sets of routines are provided to display the SYSTEM Time and
 *	Date the second routine displays FILE based time and date.
 */
MLOCAL BYTE	date_fmt []    = "%2d%c%02d%c%02d";

GLOBAL VOID disp_filetime(time)
unsigned time;
{
	WORD	h, m;
	BYTE	ap;
	
	ap = ' ';			/* assume no AM/PM used */
	h = (time >> 11);
	m = (time >> 5) & 0x3f;
	if (country.ampm == 0)		/* if anglo saxon fashion */
	{				/* need to convert things */
	    ap = 'a';			/* assume morning */
	    if (h == 0) 		/* 00:00 through 00:59 */
		h = 12; 		/*    is special... */
	    else if (h >= 12)		/* test if afternoon */
	    {
		ap = 'p';		/* mark as afternoon */
		if (h > 12)		/* if 13:00 through 23:59 */
		    h -= 12;		/* need to make " 1:00p" */
	    }
	}

	printf ("%2d%c%02d%c",
		h, country.dtime[0],	/* print hour, delimiter */
		m, ap); 		/* print minute, am/pm (if enabled) */
}

GLOBAL VOID disp_filedate(date)
unsigned date;
{
	WORD	y, m, d;
	WORD	b;

	y = ((date >> 9) + 80)%100;
	m = (date >> 5) & 0x0f;
	d = date & 0x1f;
	b = country.ddate[0];

	switch (country.dt_fmt)
	{
	 case 1:			/* European format dd/mm/yy */
	    printf (date_fmt, d,b,m,b,y);
	    break;

	 case 2:			/* Japanese format yy/mm/dd */
	    printf (date_fmt, y,b,m,b,d);
	    break;

	 default:			/* US format mm/dd/yy for the rest*/
	    printf (date_fmt, m,b,d,b,y);
	    break;

	};
}

GLOBAL VOID disp_systime()
{
	SYSTIME  time;
	WORD	b = country.dtime[0];
		
	ms_gettime(&time);
	printf ("%2d%c%02d%c%02d.%02d",
		time.hour, b,		/* print hour, delimiter */
		time.min, b,		/* print minute, delimiter */
		time.sec, time.hsec);	/* Print the second and Hundredths */
}


/* Return address of null terminated day name, given index (day). */

GLOBAL BYTE * day_names(day)
UWORD	day;			/* day of week: 0=sunday, 1=monday, .. */
{
    switch (day)
    {
    case 0:	return SUN_D;
    case 1:	return MON_D;
    case 2:	return TUE_D;
    case 3:	return WED_D;
    case 4:	return THU_D;
    case 5:	return FRI_D;
    default:	break;
    }

    return SAT_D;
}


GLOBAL VOID disp_sysdate()
{
	SYSDATE date;
	WORD	y, m, d;
	WORD	b;

	ms_getdate(&date);		/* Get the current date */
	y = date.year;
	m = date.month;
	d = date.day;
	b = country.ddate[0];

	if (country.dt_fmt != 2)	/* Japanese day comes after date */
	    printf("%s ", day_names(date.dow));
	
	switch (country.dt_fmt)
	{
	 case 1:			/* European format dd/mm/yy */
	    printf (date_fmt, d,b,m,b,y);
	    break;

	 case 2:			/* Japanese format yy/mm/dd */
	    printf (date_fmt, y,b,m,b,d);
	    printf(" %s", day_names(date.dow));
	    break;

	 default:			/* US format mm/dd/yy for the rest*/
	    printf (date_fmt, m,b,d,b,y);
	    break;
	};
}

/*.pa*/
/*
 *	Screen handling routines to CLEAR the screen and emphasise text
*/

GLOBAL VOID CDECL cmd_cls()
{
#if defined(DOSPLUS)
 	if(!int10_cls())			/* If no console device is */
	    screen(CLS_KEY, CLS_DEF);		/* active use the default  */
						/* $CLS string.		   */
#else						/* For Concurrent DOS never*/
	screen(CLS_KEY, CLS_DEF);		/* use INT 10		   */
#endif						/* Finally print a CR to   */
	putc('\r');				/* reset the internal	   */
						/* Column count.	   */
}

GLOBAL VOID revon()
{
	screen(REVON_KEY, REVON_DEF);
}

GLOBAL VOID revoff()
{
	screen(REVOFF_KEY, REVOFF_DEF);
}

MLOCAL VOID screen(key, def)
BYTE	*key;		/* Key name to match in the environment */
BYTE	*def;		/* Default string to output if no match */
{
REG BYTE *cp;

	if(!env_scan(key, cp = (BYTE *)heap()))
					/* and then search for the key  */
	    outs(cp);			/* output the string on a match */
	else				/* otherwise use the default	*/
	    printf(def);		/* supplied on entry		*/
}

/*
 *	This string output function will output a string containing
 *	a C format imbedded Octal number. This is mainly used for the
 *	CLS function.
 */
MLOCAL VOID outs(s)
BYTE *s;
{
BYTE	b = 0;
REG WORD f = 0;

	for(; *s; s++) {
		if(f) { 			/* Generating an OCTAL number*/
		    if(*s >= '0' && *s < '8') { /* check for a valid number  */
			b <<= 3;		/* and flush the buffer if it*/
			b += *s - '0';		/* is illegal. Otherwise add */
		    }				/* to the buffer and flush   */
		    else {			/* after three characters    */
			if(f != 3)
			    putc(b);
			putc(*s);
			f = 0;
			continue;
		    }

		    if(f-- == 1)
			putc(b);

		    continue;
		}

		if(*s == '\\') {
		    f = 3;		/* Initialise the Character count */
		    b = 0;		/* Zero the display value	  */
		    continue;
		}

		putc(*s);
	}

	if(f && b)
	    putc(b);
}


/*.pa*/
/*
 *	GENERAL PURPOSE STRING MANIPULATION ROUTINES
 *	============================================
 *
 */
GLOBAL BYTE tolower(b)
BYTE b;
{
	if (b==0x8D) return('i'); /* For turkish dotted capital I */
	return((b < 'A' || b > 'Z') ? b : b + 0x20);
}

GLOBAL BOOLEAN isdigit(b)
BYTE b;
{
	return (b >= '0' && b <= '9');
}

GLOBAL BYTE * skip_char(s)
REG BYTE *s;
{
	s++;
	if (dbcs_lead(*(s - 1)) && *s >= ' ')
	    s++;
	return(s);
}

GLOBAL BYTE * copy_char(dest, source)
REG BYTE **dest, **source;
{
	if (dbcs_lead(**source))
	{
	    if (*(*source + 1) >= ' ')
	    {
		*(*dest)++ = *(*source)++;
		*(*dest)++ = *(*source);
	    }
	}
	else
	{
	    *(*dest)++ = *(*source);
	}
	(*source)++;
	return(*source);
}

/* Check if character in string is blank.
   Return size in bytes of blank character, zero if not blank character. */

GLOBAL WORD is_blank(s)
REG BYTE *s;
{
WORD blank_size;

	if (*s == ' ' || *s == '\t')
	    blank_size = 1;
	else if (dbcs_expected() && *s == 0x81 && *(s + 1) == 0x40)
	    blank_size = 2;		/* KANJI space */
	else
	    blank_size = 0;
	return(blank_size);
}

GLOBAL BYTE * deblank(s) 		/* scan off leading white space */
REG BYTE *s;				/* starting address of scan */
{
REG WORD blank_size;

	while ((blank_size = is_blank(s)) != 0)
	    s += blank_size;
	return (s);			/* return deblanked string */
}

#if !(defined(MSC) || defined(MWC) || defined(TURBOC) || defined(WATCOMC))
GLOBAL BYTE * strchr(s, b)
BYTE *s, b;
{
	while(b != *s && *s)
	    s++;

	if(*s)
	    return s;
	else
	    return NULL;
}
#endif

/* Convert all uppercase characters in ASCIIZ string to lowercase. 
   If country code is JAPAN Kanji character code pairs (ie 8 bit Kanji
   escape code followed immediatly by 8 bit Kanji character code) are 
   not changed. */

GLOBAL BYTE 	*strlwr(s)
BYTE	*s;
{
REG BYTE *bp;


    if (dbcs_expected())		/* are we looking out for DBCS? */
    {					/*  yes - DON'T CHANGE DBCS CODES */
	for (bp = s; *bp; bp++)
	{
    	    if (dbcs_lead(*bp))		/* is this first of a DBCS pair? */
	    {
	    	bp++;			/*  yes - skip over it */
		if (*bp == '\0')	/* it is followed by its partner? */
		    break;		/*  no - invalid DBCS, exit loop */
	    }
	    else
	    	*bp = tolower(*bp);	/*  no - lower case it */
	}
    }
    else
    	for (bp = s; *bp; bp++)
    	    *bp = tolower(*bp);

    return s;
}



/* Convert all lowercase characters in ASCIIZ string to uppercase. 
   Double byte characters are not changed. */

GLOBAL BYTE 	*strupr(s)
BYTE	*s;
{
REG BYTE *bp;


    if (dbcs_expected())		/* are we looking out for DBCS? */
    {					/*  yes - DON'T CHANGE DBCS CODES */
	for (bp = s; *bp; bp++)
	{
    	    if (dbcs_lead(*bp))		/* is this first of a DBCS pair? */
	    {
	    	bp++;			/*  yes - skip over it */
		if (*bp == '\0')	/* it is followed by its partner? */
		    break;		/*  no - invalid DBCS, exit loop */
	    }
	    else
	    	*bp = toupper(*bp);	/*  no - upper case it */
	}
    }
    else
    	for (bp = s; *bp; bp++)
    	    *bp = toupper(*bp);

    return s;
}



/*
 *	STRNICMP does a caseless match on the two input strings for LEN
 *	characters. This function is only used for token matching for
 *	commands like FOR and IF. Double byte character set aware.
 */
GLOBAL WORD 	strnicmp(str1, str2, len)
REG BYTE *str1, *str2;
UWORD	 len;
{

	while (len--)			/* loop until len == 0 */
	{
	    if (dbcs_lead(*str1) || dbcs_lead(*str2))
	    {				/* one or both characters are DBCS */
	    	if (*str1 != *str2)	/* are they identical? */
		    return -1;		/*  no - return SMALER */

		if(!*str1)
	            break;

		str1++; str2++;		/* skip DBCS escape */

		if (*str1 != *str2)	/* are DBCS char codes identical? */
		    return -1;		/*  no - return SMALLER */
	    }
	    else
	    	if (toupper(*str1) != toupper(*str2))
		    return -1;

	    if(!*str1)
	        break;

	    str1++; str2++;
	}

	return 0;			/* return EQUAL */
}



/*
 *	ZAP_SPACES removes all white space from a string
 */
GLOBAL VOID zap_spaces(cp)
REG BYTE *cp;
{
REG BYTE *cp1;

	do {
	    cp1 = deblank(cp);		/* Skip leading whitespace   */

	    if (cp1 != cp)		/* If whitespace has been    */
		strcpy(cp, cp1);	/* skipped then move string  */
					
	    while (*cp && !is_blank(cp))	/* Now skip over     */
		cp++;				/* normal characters */
					/* and repeat till the end    */
	} while (*cp);
}


GLOBAL VOID strip_path(path, dir)
BYTE	*path;
BYTE	*dir;
{
	REG BYTE *cp;
	REG WORD i;

	i = 0;					/* assume empty path	*/
	for (cp=path; *cp; cp++) {		/* scan the file name	*/
	    if(dbcs_lead(*cp)) {		/* If this is a DBCS	*/
	        cp++;				/* character then skip  */
		continue;			/* the next char	*/
	    }		
	    if ((*cp == *pathchar) ||		/* if path delimiter	*/
		(*cp == ':'))			/* or drive specifier	*/
		i = (cp+1)-path;		/* remember offset	*/
	}
	strcpy (dir, path);			/* make a copy		*/
	dir[i] = '\0';				/* discard all but path */
}

GLOBAL BOOLEAN getdigit(n, s)
WORD *n;			/* Pointer to the word number to save */
BYTE **s;			/* String to Process */
{

	*n = 0; 			/* Zero the number */

	while(!isdigit(**s) && **s)	/* Skip all non digits */
	    (*s)++;

	if(**s) {
	    while(isdigit(**s)) {	/* Add all the digits in */
		*n = **s - '0' + *n * 10;
		(*s)++;
	    }
	    return TRUE;		/* and return success */
	}
	else
	    return FALSE;
}

/*
 *	Check that the number input by the user and held in S is in
 *	the range specified by MIN and MAX if this is so then update
 *	VALUE and return SUCCESS otherwise VALUE is unchabged and 
 *	return FAILURE.
 */
GLOBAL BOOLEAN check_num(s, min, max, value)
BYTE *s;	/* Input String */
WORD min, max;	/* Minimum and Maximum values */
UWORD *value;	 /* Value Input */
{
	WORD u;

	deblank(s);

	if(getdigit(&u, &s) == FALSE)
	    return FAILURE;

	if(*s)
	    return FAILURE;

	if(u < min || u > max)
	    return FAILURE;

	*value = u;
	return SUCCESS;
}

GLOBAL BOOLEAN iswild (path)
REG BYTE *path;
{
	while (*path && (*path != '*') && (*path != '?'))
	    path ++;
	return (*path != '\0');
}

GLOBAL BOOLEAN is_filechar(s)
REG BYTE *s;
{
	if (*s == 0) return FALSE;
	
	if (is_blank(s) || strchr(invalid_filechar, *s))
	    return FALSE;

	return TRUE;
}

GLOBAL BOOLEAN is_pathchar(s)
REG BYTE *s;
{
	if (is_filechar(s) ||
	   *s == *pathchar ||
	   *s == '.' ||
	   *s == ':' ||
	   (*s >= 'Z'+1 && *s <= 'Z'+6))

		return TRUE;

	return FALSE;
}

/*
 *	Copy the file specification from OLDPATH to the buffer NEWPATH
 *	and return a pointer to the first byte after the extracted name.
 *	Remove any terminating ':' character from the file specification
 *	as the FDOS/PCMODE will try to match all characters in the string.
 */
GLOBAL BYTE * get_filename(newpath, oldpath, ambiguous)
REG BYTE *oldpath, *newpath;
BOOLEAN ambiguous;
{
UWORD	count = 0;
BYTE	*pathname = oldpath;

#if defined(PASSWORD)
	while(is_pathchar(oldpath) ||
	      ((*oldpath == *pwdchar) && (is_pathchar(oldpath + 1))) ||
	      (ambiguous && (*oldpath == '*' || *oldpath == '?'))) {
#else
	while(is_pathchar(oldpath) ||
	      (ambiguous && (*oldpath == '*' || *oldpath == '?'))) {
#endif
	    if(++count < MAX_PATHLEN) {
	        *newpath++ = *oldpath;
		if(dbcs_lead(*oldpath)) {
	 	    *newpath++=*++oldpath;
		    count++;
		}

	    }
	    if(*oldpath++ == ':' && count > 2 && !is_pathchar(oldpath)) {
						/* Handle the CON:filename  */
	        newpath--;			/* so loved by the users of */
		break;				/* the COPY command.	    */
	    }
	}

	*newpath = '\0';			/* Terminate newpath with \0 */

	if(count >= MAX_PATHLEN) {
	    longjmp(break_env, IA_FILENAME);
	}
	
	return oldpath;
}


/*
 *	Returns the offset of the filename in a correctly formatted 
 *	pathname string.
 */
GLOBAL BYTE * fptr(s)
REG BYTE  *s;
{
	REG BYTE  *tp;

	for(tp = s; *s; s++) {
	    if(dbcs_lead(*s)) {
	        s++;
		continue;
	    }

	    if(*s == ':' || *s == *pathchar)
		tp = s+1;	 
	}
	return(tp);		       
}

/*	repwild replaces the wildcards in the destination filespec with
 *      the relevant information from the source filespec 
 *	src is an explicit filename
 *	dest is a filename with wildcards
 *
 *	eg  src = fred.lst
 *	    dest = *.txt      becomes  fred.txt
 *	    dest = ?.*	      becomes  f.lst
 *	    dest = z*.*       becomes  zred.lst
 * 
 *	nb dest must be in a buffer with room for expansion
 */
GLOBAL VOID repwild(src,dest)
REG BYTE  *src,*dest;
{
        BYTE    t[13];
	BYTE	*temp;
	
	temp=&t[0];				/* ptr to temp array */

        if(!iswild(dest))			/* return if not wild */
            return;

        src = fptr(src);        	/* point to filename 		*/
	if(!*src)			/* If a blank filename has been */
	    return;			/* specified then return as an	*/
					/* invalid source specification */
	dest = fptr(dest);	

	strcpy(temp,dest);	/* copy wild dest to temp, as dest will get overwritten */
	
	while (*temp) {		/* while still more temp to process */
	    if(*temp=='.') {		/* advance src ptr to '.' */
		while(*src && *src!='.')
		    src++;
	    }		/* drop into next check */

	    if(*src=='.') {
		if(*temp=='.') {
		    *dest=*temp;	/* copy '.' */
		    goto inc;
		}
		else {            /* advance temp to '.' or '\0', copying valid chars to dest */
		    while(*temp && *temp!='.') {
			if(*temp!='*' && *temp!='?') { 
			    *dest=*temp;  
			    dest++;
			}
			temp++;
		    } 
		    goto skipinc;		
		}
	    }

	    if(*temp=='*') {
		while(*src && *src!='.') {	/* copy rest of src till */
		    *dest=*src;			/* src = '.' or '\0' 	 */
		    dest++;
		    src++;
		}
		while(*temp && *temp!='.')	/* inc temp past '*' */
		    temp++;
		goto skipinc;
	    }			

	    if (*temp=='?')
		*dest=*src;		/* copy src character to dest */
	    else   			/* else  *temp==normal char */
		*dest=*temp;		/* copy temp character to dest */

inc:
	    if(*src)			/* dont advance past terminator */
		src++;

	    dest++;
	    temp++;
skipinc:
	    ;
	}			/* loop till end of while */	

	*dest='\0';		/* add terminator to dest */
}


/*.pa*/
/*
 *	Read a character from the console. The ABORT flag determines
 *	whether a ^C will abort the command or be treated as a negative
 *	reponse. DEF determines the default value that yes() will use.
 *
 */

EXTERN BYTE FAR * CDECL farptr(BYTE *);

#define	YES_CHAR	(*farptr(YES_NO+0))
#define	NO_CHAR		(*farptr(YES_NO+1))

GLOBAL BOOLEAN yes(abort, def)
BOOLEAN abort, def;
{
BYTE	yn;

#if defined(CDOSTMP)
	yn = (BYTE) bdos(C_RAWIO, 0xFD);	/* Input a character and */
	if(abort && yn == 0x03)			/* check for Control-C   */
	    int_break();
#else
	yn = (BYTE) msdos((abort ? MS_C_NOECHO : MS_C_RAWIN), NULL);	 
#endif						/* read the response	*/
	if(yn >= ' ')				/* If its printable then*/
	    putc(yn);				/* display the charcter */
	crlf(); 				/* new line		*/
	if(def) 				/* Now using the correct*/
	    return((yn & 0xdf) != NO_CHAR);	/* default value return */
	else					/* process the users	*/
	    return((yn & 0xdf) == YES_CHAR);	/* input and return.	*/
}

/*
 *	ONOFF scans the command line for [=](ON|OFF) and returns
 *	YES, NO or FAILURE 
 */
GLOBAL WORD onoff(cmd)
BYTE *cmd;
{

	cmd = deblank(cmd);			/* Deblank the string and    */
	if (*cmd == '=')			/* remove optional '='	     */
	    cmd = deblank(cmd+1);

	sprintf(heap(), "%s", MSG_ON);		/* Check for ON		    */
	if(!strnicmp(cmd, heap(), strlen(heap())))
	    if (*(deblank (cmd + strlen(heap()))) == 0)	/* end of line?	    */
		return YES;

	sprintf(heap(), "%s", MSG_OFF);		/* Check for OFF	    */
	if(!strnicmp(cmd, heap(), strlen(heap())))
	    if (*(deblank (cmd + strlen(heap()))) == 0)	/* end of line?	    */
		return NO;

	return FAILURE;
}

GLOBAL VOID syntax()
{
	eprintf(MSG_SYNTAX);
	crlfflg = YES;
}

GLOBAL VOID crlf()
{
	printf("\n");
}

GLOBAL VOID putc(c)
BYTE	c;
{
	printf("%c", c);
}


GLOBAL VOID puts(s)
BYTE	*s;
{
	printf("%s",s);
}


GLOBAL VOID c_write(s, l)
BYTE	*s;
UWORD	 l;
{
	ms_x_write (err_flag ? STDERR : STDOUT, s, l);
}


GLOBAL WORD e_check(ret)
REG WORD    ret;
{
REG BYTE   *s;

    if (ret >= 0)			/* if no error code */
	return ret; 			/* it's O.K. */

    if (ret == ED_GENFAIL) ret = extended_error();

    crlfflg = YES;			/* Force a CR LF after the error    */

    switch (ret)
    {
	case ED_ROOM:	  /* Force ED_ROOM to return File Not Found msg */
	case ED_FILE:	  s = ERR02;	break;	/* File Not Found Error	*/
	case -1:
	case ED_PATH:	  s = ERR03;	break;	/* Path Not Found	*/
	case ED_HANDLE:	  s = ERR04;	break;	/* Too many Open Files	*/
	case ED_ACCESS:	  s = ERR05;	break;	/* Access denied	*/
	case ED_MEMORY:	  s = ERR08;	break;	/* Insufficient Memory	*/
	case ED_ENVIRON:  s = MSG_ENVERR;break;	/* Invalid Environment	*/
	case ED_DRIVE:	  s = ERR15;	break;	/* Invalid Drive Spec	*/
	case ED_PROTECT:  s = ERR19;	break;	/* Write Protect Disk	*/
	case ED_SHAREFAIL:s = ERR20;	break;	/* Sharing Conflict	*/
	default:
	    if(ret==ED_FAIL)
	 		 {s = ERR83;	break;} /* Physical Media - FAILED */
	    if(ret==ED_PASSWORD)
			 {s = ERR86;	break;}	/* Invalid Password	*/
#if defined(CDOS) || defined(CDOSTMP)
	    if(ret==(-255))
	    		 {s = ERR_RSC;	break;}	/* Resource is not Available */
#endif
	    if (ED_NET >= ret && ret > ED_NETPWD)
		      {s = MSG_NETWORK;	break;}	/* Network Error	*/

	    s = MSG_INTERNAL; break;		/* Internal Error	*/
    }

    eprintf(s, 0-ret);
    eprintf("\n");
    return ret;
}

#if 0
MLOCAL BYTE *err_tab[] =  { NULLPTR,	/* 01 - Invalid Function Code	*/
			    err02,	/* 02 - File Not Found Error	*/
			    err03,	/* 03 - Path Not Found		*/
			    err04,	/* 04 - Too many Open Files	*/
			    err05,	/* 05 - Access denied		*/
			    NULLPTR,	/* 06 - Invalid Handle		*/
			    NULLPTR,	/* 07 - Invalid Memory Cntl Blk */
			    err08,	/* 08 - Insufficient Memory	*/
			    NULLPTR,	/* 09 - Invalid Memory Cntl Blk */
			    msg_enverr, /* 10 - Invalid Environment	*/
			    NULLPTR,	/* 11 - Invalid Format		*/
			    NULLPTR,	/* 12 - Invalid Access Code	*/
			    NULLPTR,	/* 13 - Invalid Data		*/
			    NULLPTR,	/* 14 - Unused Error Code	*/
			    err15,	/* 15 - Invalid Drive Spec	*/
			    err20,	/* 20 - Sharing Conflict	*/
			    err83,	/* 83 - Physical Media - FAILED */
			    err86,	/* 86 - Invalid Password	*/
			    err_rsc};	/* Resource is not Available	*/

GLOBAL WORD e_check(ret)
REG WORD    ret;
{
REG WORD    error;			/* Local copy of the error code */

	if (ret >= 0)			/* if no error code */
	    return ret; 		/* it's O.K. */

	crlfflg = YES;			/* Force a CR LF after the error    */
	error = ret;			/* message has been displayed	    */
	if(error == ED_ROOM) 		/* Force ED_ROOM to return File Not */
	    error = ED_FILE;		/* found message.		    */

	if(error < ED_DRIVE) {		/* Check for error codes which have */
	    if(error == ED_SHAREFAIL)	/* been remapped so save space	    */
		error = (-16);

	    if(error == ED_FAIL)	/* Check for FAIL		    */
	        error = (-17);

	    if(error == ED_PASSWORD)	/* Password Error		    */
	        error = (-18);
	}

	error = -error;
	if(error <= sizeof(err_tab)/sizeof(BYTE *) && err_tab[error-1])
	    eprintf(err_tab[error-1]);
	else
	    eprintf("Internal Error Code %03d", error);

	return ret;
}
#endif

GLOBAL BOOLEAN UNC(char *path) {
	if (*path == '\\' && path[1] == '\\') return TRUE;
	if (!*(path++) || !*(path++)) return FALSE;
	while (*path) if (*(path++) == ':') return TRUE;
	return FALSE;
}


GLOBAL BYTE * d_check(path)
REG BYTE *path;
{

	ddrive = -1;				/* return -1 for UNC names  */
	if (UNC(path)) return(path);
	ddrive = drive;				/* if no drive is specified */
	if(!*path || path[1] != ':')		/* then DDRIVE is set to    */
	    return(path);			/* the default drive.	    */

	ddrive = toupper(path[0]) - 'A';	/* Otherwise the requested  */
	path += 2;				/* drive is selected and    */
						/* range checked	    */
	if(ddrive == drive)			/* If the requested drive is*/
	    return(path); 			/* the default drive is OK. */

/*
 *	If TRUE the D_CHECK only range checks the selected drive and
 *	returns a pointer to the next element of the path. If FALSE
 *	the drive is phyically selected.
 */
#if TRUE
	if(!INVALID_DRV(ddrive))
	    return(path);
#else
	if(!INVALID_DRV(ddrive) && ms_drv_set(ddrive) == ddrive) {
	    ms_drv_set(drive);			/* Restore Original Drive   */
	    return(path);			/* and return Path	    */
	}
#endif
	e_check(ED_DRIVE);			/* Print an error message   */
	return (NULL);				/* and return a NULLPTR	    */
}


GLOBAL BOOLEAN f_check(cmd, fchars, farray, ignore)
REG BYTE *cmd;
BYTE	 *fchars;
UWORD	 *farray;
BOOLEAN  ignore;		/* Ignore Illegal Options */
{
	BYTE 	*s, *flg_start;
	BOOLEAN	 flg_skip, flg_error;
	BYTE	 c;

	*farray = 0;		/* assume none of the flags present */

	while(*cmd) {
	    if(*cmd++ != *switchar)
	        continue;

	    flg_start = cmd - 1;		/* Save switchar offset	    */
	    flg_skip = FALSE;			/* No Chars skipped	    */
	    flg_error = TRUE;			/* Assume first char is bad */
	    FOREVER {
	        c = tolower(*cmd);		/* Scan the string till the */
		if(!((c>='a' && c<='z')||(c>='0' && c<='9')))
		    break;			/* first non-alpha character*/

		if((s=(BYTE *)strchr(fchars, c))) {/* check each char against  */
		    *farray |= 1 << (s-fchars); /* options string passed by */
		    strcpy(cmd, cmd+1); 	/* the calling routine.	    */
		    flg_error = FALSE;		/* Reset error flag and set */
		}				/* correct flag bit.	    */
		else {
		    flg_skip = flg_error = TRUE;/* On error set flg_skip and*/
		    if(!ignore)			/* break out of the loop if */
		        break;			/* ignore is FALSE.	    */
		    cmd++;
		}
	    }

	    if(!flg_skip)			/* If all characters have    */
	        *flg_start = ' ';		/* been used then remove '/' */

	    if(flg_error && !ignore) {		/* If an invalid char and    */
		eprintf(MSG_BADOPT, *switchar, c); /* ignore is FALSE then    */
		crlfflg = YES;			/* print the error message   */
		return FAILURE;
	    }
	}
	return SUCCESS;
}


GLOBAL BOOLEAN nofiles(path, attrib, exist, append_stardotstar)
REG BYTE *path; 		/* Search Path		*/
WORD	 attrib;		/* Search Attributes	*/
BOOLEAN  exist; 		/* Must files exist	*/
BOOLEAN  append_stardotstar;
{
	REG BYTE *cp;
	DTA	search;
	WORD	ret;

	if ((cp = d_check (path)) == NULLPTR)	/* if bad drive letter */
	    return FAILURE;			/*    don't do it */

	if (!*fptr(cp)) {			/* If only a path has been */
	    strcat(cp, d_slash_stardotstar+3);	/* specified expand to *.* */
	}
	else if(!iswild (cp))			/* else is it path or file? */
	{					/* wild cards imply files */
	    ret = ms_x_first(path, ATTR_ALL, &search);	/* get attributes */

	    if(ret == ED_ROOM)
	        ret = ED_FILE;

	    if (ret < 0)			/* if any errors	     */
		if(!exist && (ret == ED_FILE || ret == ED_PATH)) {
						/* If file does not exist and*/
						/* this is NOT an error...   */
		    if (append_stardotstar) {
		        append_slash(path);	/* "DIR .." on NOVELL drives */
		        strcat(path, d_slash_stardotstar+3);
					   	/* requires that we append   */
						/* "*.*" here                */
		    }
		    return SUCCESS;		/* return OK.                */
		}
		else {
		    e_check (ret);		/* otherwise print message   */
		    return FAILURE;		/* no files found	     */
		}

	    if (search.fattr & ATTR_DIR) {	/* if path names directory   */
		append_slash(path); 		/* make it all files in it   */
		strcat(path, d_slash_stardotstar+3);
	    }
	    
	    if(!exist)				/* Must we check the file(s) */
		return SUCCESS; 		/* exist. If no return	     */
	}

	ret = ms_x_first(path, attrib, &search);  /* Search for the file     */

	if(ret < 0)				/* Check the error returned  */
	    if(!exist && (ret==ED_FILE || ret==ED_ROOM)) /* If file does not exist but*/
		return SUCCESS; 		/* this is not an error then */
	    else {				/* return Ok.		     */
		e_check (ret);			/* otherwise print message   */
		return FAILURE; 		/* no files found	     */
	    }

	return SUCCESS;
}

/*
 *	Check if FILENAME can be opened in Read Only mode and return the
 *	result. The file is then closed
 */
GLOBAL BOOLEAN file_exist(filename)
BYTE *filename;
{
BYTE filebuf[MAX_PATHLEN];
WORD h;

	get_filename(filebuf, filename, NO);
	if((h = ms_x_open(filebuf, OPEN_READ)) > 0) {
	    ms_x_close(h);
	    return TRUE;
	}

	return FALSE;	     
}

/*
 *	Check if the handle passed to this routine is open on a FILE
 *	or a DEVICE.
 */
GLOBAL BOOLEAN isdev(handle)
UWORD handle;
{
	return (0x0080 & ms_x_ioctl(handle) ? TRUE : FALSE);
}

/*
 *	If the string that has been passed doesn't end with a '\' add one
 */
GLOBAL	append_slash(s)
BYTE	*s;
{
BYTE	lastchar;
    while (*s) {
    	lastchar = *s;
	if (dbcs_lead(*s))		/* is this first of a DBCS pair? */
	    s++;
	s++;
    }
    if ((lastchar != '\\') && (lastchar != '/'))
	strcat(s, pathchar);		/* append a slash */
}


GLOBAL	VOID prompt_exec()
{
	BYTE	temp[128];
	
	if (!env_scan("PEXEC=",temp)) docmd(temp,TRUE);
}

GLOBAL	VOID optional_line(line)
BYTE	*line;
{
	BYTE	c;
	BYTE	*s;	

	if (*line == 13 || *line == 10 || *line == 0) return;

	if (*line == '?') strcpy(line,line+1);

	if (*line == '\"') {
	    s = line+1;
	    while (*s && *s != '\"') putc(*s++);	    
	    s++;
	    strcpy(line,s);
	}
	else printf(MSG_OPTLINE,line);
	
	if (!yes(NO,NO)) *line = 0;

	/*printf("\n");*/
	
}
