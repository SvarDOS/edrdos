/*
;    File              : $Workfile: COMCPY.C$
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
;    ENDLOG
*/

/*
	File		COMCPY.C
	Title		Copy module for command.com

Revision History:-
==================

Date       Description
-----------------------------------------------------------------------------
20/05/86   Command.com copy routine
		Based on earlier comcpy.c but heavily modified
 6/06/86   Destination file given the same attributes as source file
		(only applicable to non concatinate cases etc as per 
		timestamping)
        Verify calls added 
24/06/86   Special case of file+,, ('touch') supported
27/06/86   Destination now only opened at last possible moment
		(in copy1 routine), to speed up floppy to floppy copying
03/07/86   ow supports copy bill+fred bill without destroying the
		original contents of bill. Also supports copy ref.lst+*.lst
		
 4 Aug 86  ANSI C compatibilty MSC /W1
 3 Oct 86  Fix bug in REPWILD temp[12] to temp[13] 
21 Nov 86  Fixed bug in DOSIF MS_DATETIME

-------------	DOS Plus 2.1 and 2.1b internal release
		
 8 Dec 86 Rewritten to handle single drive copying better
		added preread and readsrc
11 Dec 86 Number of files copied message moved into message.c 
11 Dec 86 Gastly fix for single floppy drive copy of large file
		as DOS Plus wont allow us to keep the destination file open
		when swapping floppies
		(ABswap and ABloop1 flags added)
12 Dec 86 Finished and thoroughly tested for DOS Plus 2.1d release
		The few minor bugs remaining are documented in dosplus.doc
		Although the code is now very messy it seems to work well!
31 Dec 86 If copying from aux device, set buffer size to 1
16 Feb 87 Changed check for single physical floppy disk drive
		to make more generic
 8 Sep 87 Incorporation of these DOS Plus sources into the Concurrent
 		DOS COMMAND.EXE and COPY.EXE files. The memory management
		has been modified to use an internal static buffer for
		copying. An unused routines have been deleted.
10 Sep 87 Force BufSize to be a multiple of 512 bytes otherwise
		files greater than the buffer size are not copied.
10 Sep 87 Add an extra check to isfile to check for the case "d:"
13 Oct 87 Add the /Z option which will force the data to be masked
		with 0x7F to zero the top bit.
16 Oct 87 /S option copies hidden files as well as system files
16 Oct 87 Copys files with passwords (if source password specified)
          (nb destination does not receive a password unless one is 
          explicitly set)
19 Oct 87 Added /C confirm option
30 Oct 87 isfile() checks for trailing '\' as a special case
05 Nov 87 Moved isdev(fn1) test till after removing flags from fn1
10 Nov 87 If destination is a device, assume ascii when reading source
          and dont send a final ^Z  (unless overridden by user flags)
 5 Apr 88 If Sharing mode open fails on the source file try using
          a compatibilty mode open. For FrameWork SETUP.EXE.
20 May 88 Update the ISFILE routine to use the FPTR routine. Fixs the
          Novell COPY bug.
25 May 88 Close any open batch files for WS2000 install which copies
          over its installation batch file.
27 May 88 Added string undefs.
28 Sep 88 Read data from the source device till the buffer is full or
          a ^Z has been reached. Donot append a ^Z to a file when copying
          from a device unless /A used.
21 Dec 88 Use IOCTL to determine if a handle is attached to a device
          or not.
1 Mar 89  Ignore '[',']','"' 
14 Apr 89 If dest is a device and /b specified (either src or dst) set
          device to binary
6 Jun 89  Do not explicitly set the hidden attribute on password 
          protected files let OS do it for us.
12 Jun 89 Use all of allocated buffer even for Device Reads
14 Jul 89 Move findeof to assembler for speed
4 Aug 89  Used to ignore /b on concat src if dest was device
6-Mar-90  Watcom C v 7.0
22-Mar-90 Copy with control chars cmd string (get_pno terminate bug)
8-May-90  "File not found" error goes to STDOUT, not STDERR.
24-May-90 samefs uses ms_x_expand to check full physical path
5-Jun-90  BODGE copy to dev to be 1 char at a time so we can retry
          correctly (BDOS bug workaround)
11-Jun-90 "COPY file1 file2 ; " hanging cured. I hate get_pno.
27-Nov-90 samefs() no longer uses ms_x_expand(), for PCNFS
          compatibility.
15-Jan-91 "COPY a+b+c d" no longer stops if b does not exist.

DRDOS BUXTON
------------

1-Mar-91  COPY /B FILE DEVICE is now supported.
          Copying to a dev is no longer 1 char at a time, in anticipation
          of a fix in the BDOS.
2-Apr-91  COPY no longer forces time/date/attributes of source onto
          destination.
7-May-91  time/date is now preserved again, attributes are not.

DRDOS PANTHER
-------------

22-Jun-92 Support for Novell Remote copy added.
          See call to novell_copy().
----------------------------------------------------------------------------
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

#include	"command.h"		/* COMMAND Definitions */
#include	"dos.h" 		/* MSDOS Functions */
#include	"dosif.h"		/* DOS interface definitions	 */
#include	"toupper.h"
#include	"support.h"		/* Support routines		 */
#include	"global.h"


EXTERN VOID batch_close(VOID);		/* BATCH.C		*/

MLOCAL BYTE * skip_switch(BYTE *);
MLOCAL BYTE * get_p1(BYTE *, BYTE *, BYTE *);
MLOCAL BYTE * get_pno(BYTE *, BYTE *);
MLOCAL BOOLEAN isfile(BYTE *);
MLOCAL VOID addwild(BYTE *);
MLOCAL BOOLEAN dopen(BYTE *);
MLOCAL VOID dclose(BYTE *, WORD, WORD);
MLOCAL BOOLEAN preread(BYTE *);
MLOCAL WORD readsrc(VOID);
MLOCAL WORD copy1(BYTE *, BYTE *);
MLOCAL BOOLEAN lseek(BYTE *);
MLOCAL BOOLEAN samefs(BYTE *, BYTE *, WORD);
MLOCAL WORD ABcheck(BYTE *, BYTE *);
MLOCAL VOID prtsrc(BYTE *);
MLOCAL WORD conf_src(BYTE *);
MLOCAL VOID e_check2(WORD);
MLOCAL BOOLEAN touch(BYTE *);
MLOCAL BYTE * get_pswd(BYTE *);


/* define external variables used */


#define	COPY_VERIFY	(global_flg & 1)	/* Set Verify Flag	*/
#define	COPY_SYS	(global_flg & 2)	/* Include SYSTEM Files	*/
#define	COPY_ZERO	(global_flg & 4)	/* Zero the eighth Bit	*/
#define	COPY_CONFIRM	(global_flg & 8)	/* Confirm each file	*/

#define	COPYSRC_ASC	(sflag & 1)		/* Source is ASCII	*/
#define	COPYSRC_BIN	(sflag & 2)		/* Source is Binary	*/

#define	COPYDST_ASC	(dflag & 1)		/* Destination is ASCII	*/
#define	COPYDST_BIN	(dflag & 2)		/* Destination is BINARY*/

#define	MIN_COPYBUF	(10 * (1024/16))	/* Minimum Copy Buffer Size */
#define	MAX_COPYBUF	(50 * (1024/16))	/* Maximum Copy Buffer Size */

/* define static variables for this module */

MLOCAL BYTE	*lp;
MLOCAL UWORD	global_flg;	/* Global Flags	Verify, System & Zero	*/
MLOCAL UWORD	dflag;
MLOCAL BOOLEAN	sascii; 	/* treat current source file as ascii */
MLOCAL BOOLEAN	sbin;
MLOCAL BOOLEAN	concat;
MLOCAL WORD	nfiles; 	/* number of files copied */

MLOCAL WORD	dfh;		/* destination file handle */
MLOCAL BOOLEAN	dstopen;	/* destination open */
MLOCAL WORD	sfh;
MLOCAL ULONG	src_len;
MLOCAL BOOLEAN	srcopen;	/* flag whether src is still open */
MLOCAL BOOLEAN	srcdev; 
MLOCAL BOOLEAN  dstdev;
MLOCAL BOOLEAN	fullbuf;	/* buffer contains data */
MLOCAL BOOLEAN	dfailed;
MLOCAL BOOLEAN	ABswap; 	/* single floppy disk drive copy with disk swap */
MLOCAL BOOLEAN	tstamp; 	/* set destination timestamp to same as source */
MLOCAL UWORD	date,time;	/* source date and time      */
MLOCAL UWORD	attrib; 	/* source file attributes    */

MLOCAL UWORD	amount; 	/* amount of real data in buffer */

/* ---- start of code ---------------------------------------------*/

GLOBAL VOID CDECL cmd_copy(cmd)
BYTE	*cmd;
{
	WORD	rmode = 0x0000; 	/* read mode - normal files only */
	BYTE	delim;
	BYTE	npara;
	BYTE	src[MAX_FILELEN];	/* buffer in which to expand wild source filespec */
	BYTE	dest[MAX_FILELEN];	/* buffer in which to expand wild destination filespec */
#if defined(PASSWORD)
	BYTE	password[10];		/* keep note of src password    */
#endif
	BYTE	*olp, *tp;
	BYTE	*last_delim;
	WORD	ret;
	BOOLEAN scheme1;
	BOOLEAN init = YES;		/* do initialisations during 1st loop */
	BOOLEAN pflag;
	BOOLEAN tflag;			/* touch flag (special case) */
	BOOLEAN confirmed;
	UWORD	dosvf;			/* used to save current dos verify state */
	UWORD	sflag;			/* Source File Options		*/
					/* scheme2 extra bits */
	BYTE	wdfn[13];		/* used by scheme2 to save wild destination filename */
	BYTE	*dfptr;
	BYTE	*ocmd;	 
	BYTE	src2[MAX_FILELEN];	/* 2nd src buffer for scheme2 */
	DTA	search; 		/* DOS Search Buffer		*/

	sascii = NO;		/* indicates if current source is ascii or not */
	sbin   = NO;		/* sbin indicates if an explicit /b found */
	concat = NO;
	dfailed = ABswap = NO;		
	srcopen = dstopen = NO;		/* No file are Open		*/
	nfiles=0;			/* number of files copied	*/
	cmd = deblank(cmd);		/* remove leading spaces */
	strlwr(cmd);			/* force it all to lower case first */
	strcpy(heap(),cmd);		/* make temp copy of cmd line */
	if(f_check(heap(), "vszcab", &global_flg, NO))	/* check for any bad flags */
	   return;				/* exit if any (with message) */    
						/* also zaps any valid flags but not important is this is a temp copy */
	f_check(cmd,"vszc",&global_flg,YES);	/* check for, and zap verify, sys, zero and confirm flags */
	if(COPY_SYS) {
	    rmode |= ATTR_SYS;			/* read system files also*/
	    rmode |= ATTR_HID;			/* read hidden files also*/
	}					/* nb  /s flag acts globally */

	cmd = deblank (cmd);			/* deblank incase /v was at start of line */

	while(*cmd == *switchar) {	       /* process any initial switches */
	    if(*(cmd+1)=='a')
		sascii=YES;
	    if(*(cmd+1)=='b') {
		sascii=NO;
		sbin=YES;
	    }
	    cmd = deblank (cmd+2);
	}		    
	
	lp = get_pno(cmd,&npara);
	olp =lp;			/* save lp ptr (as lp possibly modified later) */
					/* olp is used as the end of the list of source parameters */
	if(npara > 1)	       /* dont remove switches if npara=1 as they will be processed when fn1 switches are checked */
	    f_check( lp, "ab", &dflag, YES);	/* check for, and zap destination a and b flags */
					/* store them in dflag for later use */

	last_delim = lp-1;	
	while (*last_delim == 32) last_delim--;
	
	zap_spaces(lp);
		
	cmd = get_p1(src, deblank(cmd), &delim); 		/* separate 1st filename spec from rest */

	if(delim == '=') {			/* if the user spells PIP as COPY */
	    syntax();				/* exit with syntax error */
	    return;
	}

	if(npara>2 && delim!='+') {
	    printf(MSG_INOP);		    /* invalid number of parameters */
	    return;
	}


	if(!d_check(src))
	    return;			    /* invalid	drive */

	f_check( src, "ab", &sflag, YES);	/* check for, and zap flags in fn1 */

	if(COPYSRC_ASC)
	    sascii=YES;
	if(COPYSRC_BIN) {
	    sascii=NO;		/* nb /b checked last by default */
	    sbin=YES;
	}

	zap_spaces (src);

/* do adjustments for special cases */

	if (COPYDST_BIN) {
	    sbin = YES;		/* Does it make sense to have source ascii */
	    sascii = NO;	/* and dest binary? I think not. */
	}
	
	if(lp[strlen(lp)-1] == ',') 
	    lp[strlen(lp)-1] = '\0';	/* remove comma from end of lp */
	
	if(npara==1 && delim!='+')
	    if(isfile(lp)) {		/* strip drive and path from lp    */
		lp = fptr(lp);		/* ie path\file becomes \path\file */
	    }				/* to file but not if \path\file+  */
	    else
		lp=lp+strlen(lp);  	/* if dir, lp=\0  */
	 
	if(npara==1 && delim=='+') {
	    delim=' ';			/* not concat if 1 parameter */
	    tp=lp;
	    while (*tp) {			/* remove the + sign from end of lp filespec */
		if(*tp == '+') 
		    *tp = ' ';
		tp++;
	    }
	}
		
	if(npara>=2 && delim=='+' && *last_delim=='+') {	
					/* copy fred+bill   dest is fred   */
	    lp = fptr(src); 		/* copy path\fred+bill	dest is fred */
	    olp=cmd+strlen(cmd);	/* fiddle olp to end of list of source parameters */
	}
		
	if(npara==2 && iswild(src) && 		/* handle special case */
	     isfile(lp) && !iswild(lp)) 	/* of copy *.lst file */
		concat = YES;			/* (implied concatination) */

	tflag = (npara>=3 && delim=='+' && *cmd==',');	/* touch special case so set tflag */
	
	if(delim == '+')
	    concat = YES;

	if(concat && !sbin)		/* concat is ascii unless a /b switch has occured */
	    sascii = YES;

	dstdev = NO;

	if (!iswild(lp) && *lp)
	{
	    get_filename(dest,lp,YES);		/* this turns lpt1: into lpt1 */
	    
	    ret = ms_x_open(dest, OPEN_READ);	/* Check if destination	is */
	    if (ret >= 0)			/* a device. If so, if /b  */
	    {					/* on src OR dst, copy is  */
	    	if (isdev(ret))			/* binary		   */
	       	{
		   dstdev = YES;
	           if (COPYSRC_BIN || (COPYDST_BIN && !concat) || sbin)
		   {
		       sbin = YES;
		       sascii = NO;
		   }				/* If no /b, default to    */
		   else				/* ascii		   */
		   {
		       sbin = NO;
		       sascii = YES;
		   }
		}

		ms_x_close (ret);
	    }
	}
	
	mem_alloc(&bufaddr, &bufsize, MIN_COPYBUF, MAX_COPYBUF);
	bufsize <<= 4;			/* Allocate the Buffer		*/
	bufsize &= ~511;		/* Force the buffer size to be a*/
					/* multiple of 512 Bytes	*/
	if(bufsize == 0) {		/* If the memory allocation	*/
	    e_check(ED_MEMORY);		/* print a memory error and 	*/
	    return;			/* return to the caller.	*/
	}
#if 0 /* UNBODGE */
/** BODGE **/
	if(dstdev)			/* copy to dev 1 char at a time */
	    bufsize = 1;		/* so retry operates correctly  */
/** BODGE **/
#endif /* UNBODGE */

	if(batchflg)			/* close the BATCH file if OPEN cos  */
	    batch_close();		/* installation routines copy over   */
					/* the current batch file.	     */

	dosvf = ms_f_getverify(); 	/* read present dos verify flag*/
	if(COPY_VERIFY)
	    ms_f_verify(1); 		/* set verify */
	

	if (lp == get_filename(dest, lp, YES)) {
	    if (strlen(lp)) {
		printf(MSG_SYNTAX);	/* bad filename specified */
		return;
	    }
	}

#if TRUE
/* ##jc##
 *	This Code is a Special for IBM Display Write 4 which attempts
 *	to copy "A:DEFAULT.P*TÌ". Treat this a a secial case and convert
 *	it to "A:DEFAULT.P*".
 */
	tp = strchr(fptr(src), '.');		/* Search for . in the 	*/
	if(tp && !strnicmp(tp, ".p*t", 4))	/* and check for an ext */
	    strcpy(tp, ".p?t");			/* of "P*T".		*/
#endif
	
	/* never add *.* to CON */
	if (stricmp(src,"CON")) addwild(src);
				/* if just a drive or path, add *.*  */

/*	cant do addwild(dest); yet as it will cause a drive B access on single floppy copy */
		
	
	tstamp = !concat;	/* if concatinating, then dont alter timestamp */
	/*tstamp = NO;*/	/* ie leave timestamp as current time */

	pflag = concat || iswild(src);	/* pflag indicates whether to print out */
					/* intermediate file names as they are copied */


	/* see later for a description of schemes 1 and 2 */

	/* common start for schemes 1 and 2 */

more1:
#if defined(PASSWORD)
	strcpy(password,get_pswd(src));	/* keep copy of the src password */
					/* password incorporates the leading ';' */
					/* password = '\0' if no password */
#endif

	tp=fptr(src);			/* get ptr to filename part of src  */

	ret=ms_x_first(src,rmode,&search); /* get first explicit source (if src wild) */
					/* if(ret < 0) check moved till after prtsrc */

loop12: 
	if(ret >= 0) {			/* copy explicit filename to src */
	    strcpy(tp,search.fname);	/* only do this if a file was found */
#if defined(PASSWORD)
	    strcat(tp,password);	/* add the src password             */
#endif
	}
				
	strlwr(tp);		 	/* convert to lower case */
		
	if(pflag && !COPY_CONFIRM)
	    prtsrc(src);		/* print name of this file */

	if(COPY_CONFIRM && ret>=0) 
	    confirmed = conf_src(src);	/* print source name and ask whether to copy */
	else
	    confirmed = YES;
	     		
	if(ret < 0) {			/* break out of wild src loop    */
	    if(ret == ED_ROOM) {
		printf(ERR02);		/* print "File not found" error  */
		crlf();			/* to STDOUT, not STDERR, because*/
	    }
	    else
	    	e_check2(ret);		/* dst open or not determines if */
	    goto nextfile;	    		/* nfiles gets incremented	 */
	}		

	if(preread(src)==FAILURE) 	/* pre read a buffer full if error */
	    /* goto sum1; */	    	/* break out of wild src loop - too drastic ! */
	    confirmed=NO; 		/* if error just skip this file */

	if(init) {		/* if 1st time round the loop do dest checks */
	    if (!dstdev) addwild(dest);
	    scheme1 = !iswild(dest);
						/* do bits for scheme 2    */
	    dfptr=fptr(dest);		/* ptr to filename (wild)  */
	    strcpy(wdfn,dfptr);		/* copy wild dest filename */
	    ABswap=ABcheck(src,dest);	/* check for single drive copy */
	    init=NO;
	}

	/* now we branch to scheme 1 or 2 */
	
	if(scheme1) {			/* ----- scheme1 ----- */
	   if(confirmed) {
   	      if(!dstopen && concat &&		/* special case for copy bill+fred */
   	               samefs(src,dest,NO)) {	/* bill, copy ref.lst+*.lst etc    */
   		 if(lseek(dest)==FAILURE)	/* opens dest and lseeks to the end of it */
   		    goto end1;			/* exit if dest error */
   	      }		
   	      else {				/* this is the normal case */
   		 if(!samefs(src,dest,YES)) {	/* check src!=dest */
   					/* if src=dest then prints message and skips copying */
		    if(copy1(src,dest)==FAILURE) {	/* copy src to dest */
   			if(dfailed)			/* also opens destination if necessary */
   			    goto end1;		/* dfailed if disk full or dest error */
   		    }
   		 }			/* nb nfiles++ done on dclose as refers to no of destination files */
   	      }
	   }				/* above section skipped in not confirmed */
	   else {
	     if (srcopen) ms_x_close(sfh);
	   }
	   ret = ms_x_next(&search);
	   if(!ret)  goto loop12;	    /* loop round and do it again */
					    /* if more files match wild src */
	 
	/* concatinate under scheme1 */
	/* if not concat or !dstopen could goto end1 */
nextfile:    while (*cmd==',')		   /* skip over commas */
		cmd++;	   	

	    if(cmd < olp && *cmd) {	   /* if there are more source parameters */
		cmd = get_p1(src, deblank(cmd), &delim); 		/* separate filename spec from rest */
		f_check( src, "ab", &sflag, YES);	/* check for, and zap flags in fn1 */

		if(COPYSRC_ASC)
		    sascii=YES;

		if(COPYSRC_BIN) {
		    sascii=NO;		/* nb /b checked last by default */
		    sbin=YES;
		    if (dstdev)		/* 4 Aug JJS */
		        ms_x_setdev (dfh, ms_x_ioctl (dfh) | 0x20);
					/* set device to binary		*/
		}

		zap_spaces(src);
		addwild(src);		/* if just a drive or path, add *.*  */

		goto more1;			/* loop back and copy next lot */
	    }
		
	    end1:			/* closing of dest (if necessary) */
	    ;				/* done by sum1 		  */

	}	/* end of scheme1 */

	else {		/* ----- scheme2 ----- */

	    if(!confirmed) {
	        if (srcopen) ms_x_close(sfh);
	        goto skip2;		/* forget it if user doesnt want to copy */
	    }		

	    strcpy(dfptr,wdfn);		/* get back wild dest fname */
	    repwild(src,dest);		/* replace wild part of dest with corresponding explicit details from src */
	  
	    if(tflag && samefs(src,dest,NO)) {	/* touch special case */
		if(touch(src)==SUCCESS) 	/* set timestamp */
		    nfiles++;	 		/* inc count if successful*/

		goto skip2;		 	/* jump to end of do loop */
	    }
		
	    if(samefs(src,dest,YES))	/* check src!=dest */
		goto end2;	    /* if src=dest then prints message */
			
	    copy1(src,dest);	/* copy src to dest */
				/* also opens destination if necessary */

	    if(dfailed) {		/* dfailed if disk full or dest error */
		dclose(dest,dfh,YES);
		goto end2;		    /* get out of loop */
	    }
		
	    while(*cmd==',')		/* skip over commas */
		cmd++;

	    if(cmd < olp) {			/* if there are more source */
		ocmd=cmd;			/* parameters (concat only) */
		dfailed=NO;
					
		while (cmd < olp && *cmd) {
		    cmd = get_p1(src2, deblank(cmd), &delim); /* separate filename spec from rest */
		    f_check(src2, "ab", &sflag, YES);	    /* check for, and zap flags in fn1 */
		    if(COPYSRC_ASC)
		        sascii=YES;
		    if(COPYSRC_BIN) {
			sascii=NO;		/* nb /b checked last by default */
			sbin=YES;
		    }

		    zap_spaces (src2);	/* use src2 for these parameters so */
		    addwild(src2);		/* if just a drive or path, add *.*  */
		    repwild(dest,src2);		/* replace wild part of src2 */
		    if(pflag) 
			prtsrc(src2); 	/* print name of this file */

		    samefs(src2,dest,YES);	 /* do 'content of dest lost' mssg if applicable */

		    copy1(src2,dest);		/* copy src2 to dest */
		    if(dfailed)		/* dfailed if disk full or dest error */
			break;		/* break out of while cmd<olp loop */
		} 			/* end of while cmd<olp */

		cmd=ocmd;		/* restore cmd for next time round */
	    }			
		
	    if(dstopen) {
		dclose(dest,dfh,dfailed);	  /* for concat case */

		if(!dfailed) 		  
		    nfiles++;		 /* nfiles refers to no of dest files */
		else
		    goto end2;		/* break out of loop */
	    }
						     
	    skip2:

	    ret = ms_x_next(&search);
	    if(!ret) 			/* loop round and do it again */
		goto loop12;		/* if wild src */

	    end2:  ;
	}	/* end of scheme 2 */



sum1:
	if(dstopen) {			/* tidy up if dest still open */
	    dclose(dest,dfh,dfailed);	
	    if(!dfailed)			
		nfiles++;	 /* nfiles refers to no of dest files */
	}			/* nb nfiles only incremented if dest was open */
	
summary:
	printf("%8d",nfiles);		/* do summary */
	printf(MSG_FCOPIED);
	
	mem_free(&bufaddr);			/* Free the COPY buffer	*/

	if(COPY_VERIFY)
	    ms_f_verify(dosvf);			/* retore verify state */

}	/* end of cmd_copy */


/*
 *  Notes about schemes 1 and 2
 *
 *  scheme1 is used with explicit destination filenames
 *   eg  copy fred bill
 *       copy 1.lst + 2.prn fred
 *       copy *.lst + *.prn fred
 *       copy *.lst fred		 (concatination special case)
 *       copy fred+bill fred	 (special case using lseek)	
 *
 *   scheme2 is used with wild (or blank) destination filenames
 *   eg  copy *.lst *.prn
 *       copy *.lst + *.prn *.res    
 *       copy a:fred  b:		 (b:*.*)		
 *       copy fred+,,		 (special case using touch)	 
 */


/* ---- functions defined in this module --------------------------*/
/*
 *	SKIP_SWITCH will skip over the next switch character 
 *	sequence. This allows copy to correctly support Multiple
 *	options.
 */
MLOCAL BYTE * skip_switch(cmd)
BYTE *cmd;
{
BYTE ch;

	if(*cmd == *switchar) {			/* If this is a valid 	    */
	    do {				/* switch sequence then skip*/
	    	cmd++;				/* the following alpha chars*/
		ch = tolower(*cmd);
	    } while(ch >= 'a' && ch <= 'z');
	}
	return cmd;
}

/*
 *	Copy the next parameter including FILENAME and SWITCHES into
 *	PARAM and set DELIM to be the delimiting character. The return
 *	value is the start address of the next parameter.
 */
MLOCAL BYTE * get_p1(param, s, delp)
BYTE 	 *param;
REG BYTE *s;
BYTE	 *delp;
{
	REG BYTE *ep;

	ep = s = get_filename(param, s, YES);	/* Copy the Filename	    */
	s = deblank (s);			/* skip trailing spaces     */
	while( *s=='"' || *s=='[' || *s==']' || *s==';')
	    s++;		/* Ignore non file character params*/
	s = deblank (s);			/* skip trailing spaces     */
	
	while (*s == *switchar)			/* Skip any Switches	    */
	    s = deblank(skip_switch(s));
	
	if(s-ep)				/* Concatinate any switches */
	    strncat(param, ep, s - ep);		/* to the end of PARAM.	    */

	if(*s && strchr("+=,", *s)) {		/* Check for a separator    */
	    *delp = *s;				/* return it in DELP and    */
	    return deblank(s+1);		/* skip the character	    */
	}

	*delp = (*s ? ' ' : '\0');
	return s;
}

/*
 *	Get number of filename parameters (including their switches)
 *	in string. Returns the address of the last command
 *	line parameter.
 */
MLOCAL BYTE * get_pno(s, nptr)
BYTE	*s,*nptr;
{
REG BYTE *tp;
BYTE	temp;

	*nptr = 0;
	tp = s;

	do {
	    (*nptr)++;
	    tp = s;
	    s = get_p1(heap(), s, &temp);
	}
	while (*s && s!=tp);
	
	return (tp);
}

/* 
 *	returns true if s is an explicit file 
 *	(nb may not yet have been created)
 *	ie isnt just a drive designator or just a path
 */
MLOCAL BOOLEAN isfile(s)
REG BYTE  *s;
{
	REG WORD  ret;
	
	if(strlen(fptr(s)) == 0)	/* point to the file sub-string */
	    return(NO); 		/* if this is zero length then  */
	    				/* this is not a file.		*/
        if (!strcmp(s,dotdot))
		return(NO);
		
	if(iswild(s))			/* If an ambiguous reference    */
	    return (NO);		/* then no a specific file ref. */
		
	ret = ms_x_chmod (s, ATTR_ALL, 0);	/* get attributes of filespec */
	
	if(ret == ED_FILE)		/* file not found (file yet to be created) */
	    return (YES);		/* it will be a file */

	if(ret < 0)
	    return (NO);			/* any other error is not a file */
		
	if(!(ret & ATTR_DIR))
	    return (YES);			/* if not a dir, then its a file */

	return (NO);
}

/* 
 *	if s is just a drive designator or just a path, add *.*  
 *	(or \*.* as appropriate) to it
 */
MLOCAL VOID addwild(s)
REG BYTE  *s;
{
	REG BYTE  tb;

	if(!iswild(s) && !isfile(s)) {	 /* if s is sub dir only, add *.*  */
	    if(*fptr(s))
	        append_slash(s);

	    strcat(s,d_slash_stardotstar+3);
	}
}


/* 
 *	Opens destination file (sets static variable dfh to destination file handle) 
 *	Returns success or failure
 *	Uses/sets static variables -
 *	dstopen
 *	tstamp		sets tstamp=NO if dest is a device
 */
MLOCAL BOOLEAN dopen(dest)
REG BYTE  *dest;			/* destination filename */
{
	if(dstopen)
	    return (FAILURE);	/* already open */

	if(iswild(dest) || !*dest)
	    return (FAILURE);	/* DONT create if wild */
					/* or nul	       */
		
	if(!d_check(dest)) {
	    crlf();
	    return (FAILURE);	/* invalid dest drive */
	}
		
	if((dfh=ms_x_creat(dest,0)) < 0) {  /* create destination file or truncate to empty */
	    e_check2(dfh);		/* if error */
	    return (FAILURE);
	}

	if(isdev(dfh))			/* if writing to a device */
	{
	    tstamp = NO;		/* dont set timestamp	  */	

	    if (sbin)			/* if binary, set device to binary */
	    {
	        ms_x_setdev (dfh, ms_x_ioctl (dfh) | 0x20);
	    }
	}
	
	dstopen = YES;
	return (SUCCESS);	
}

/* 
 *	Closes destination file
 *	adds ^Z eof if necessary
 *	changes its timestamp if necessary
 *	deletes incomplete dest if failed flag set
 *	NB only does any of this if dstopen
 *	Uses static variables -
 *		dstopen
 *		tstamp
 *		date,time 
 *		dflag
 *		sascii
 */
MLOCAL VOID dclose(dest,dfh,failed)
BYTE	*dest;			/* destination filename */
REG WORD  dfh;			/* destination filehandle */
BOOLEAN failed; 		
{
	BOOLEAN dascii; 		/* destination is ascii */
	UWORD	 dattrib; 
	BYTE	xeof = ('Z'-64);	/* ^Z */
	
	dascii = sascii;	/* use the (last) source ascii flag */

	if(dstopen) {		/* dont do anything if not open */
	    if(!failed) {

		if(isdev(dfh))  
		    dascii=NO;  	/* dont send ^Z if dest is a device */
	
		if(COPYDST_ASC)
		    dascii=YES;

		if(COPYDST_BIN)
		    dascii=NO;	/* check for explicit /b last */
		
		if(dascii)
		    ms_x_write(dfh,&xeof,1);	/* add ^Z */
		
		if(tstamp)		/* change timestamp from current time to source files timestamp */
		    ms_x_datetime(1,dfh,&time,&date);
	    }

	    ms_x_close(dfh);	/* close destination */
	    dstopen = NO;

	    if(failed) 		/* if failed, delete incomplete destination */
		ms_x_unlink(dest);
	    
	    else {			/* (didnt fail) */
#if 0
	        if(tstamp) {
		    dattrib = attrib;		/* dest attribs = src attribs */
		    if (!COPY_SYS) {
		        dattrib &= ~ATTR_HID;	/* if not /S , then dont let hidden attribute be set */
		    }
		    ms_x_chmod(dest,dattrib,1);	/* change destination attributes  */
	        }				/* under same conditions as tstamp */
#endif
	    }					/* nb must be done after dest closed */
	}
	return;
}

/* 
 *	Reads a buffer full of the source
 *	If eof src then closes source
 *	Returns success or failure
 *		 
 *	Uses/sets static variables -
 *		sascii
 *		tstamp		sets tstamp=NO if source is a device
 *		date,time
 *		bufaddr
 *		bufsize    
 *		
 *		srcopen 	indicates if src still open
 *		srcdev		indicates if current source is a device
 *		fullbuf 	indicates if data in buffer
 *		amount
 *		sfh
 */
MLOCAL BOOLEAN preread(src)
BYTE	*src;			/* source filename */
{
	srcopen=NO;
	fullbuf=NO;
			
	if(!d_check(src)) {
	    crlf();
	    return (FAILURE);	/* invalid src drive */
	}

	sfh = ms_x_open(src, OPEN_READ);	/* Open the File/Device using*/
	if(sfh == ED_ACCESS)			/* a sharing mode if Access  */
	    sfh = ms_x_open(src, OPEN_RO);	/* denied try compatibility  */
						/* mode. FrameWork Setup     */
	if(sfh < 0) {				/* leaves a control file Open*/
	    e_check2(sfh);			/* during the copy.	     */
	    return (FAILURE);
	}

	srcdev = isdev(sfh);		/* Check if Source is a Device	*/
	if(srcdev) {			/* Don't set the timestamp if   */
	    tstamp = NO;		/* the source is a device	*/
	    if(sbin) {			/* If a Binary Read has been    */
	    	ms_x_close(sfh);	/* specified then terminate as  */
	    	printf(MSG_BINRD);	/* the source is a Device	*/
	    	return (FAILURE);
	    }
	}
	else {
	   ms_x_datetime(0,sfh,&time,&date);	/* read files time stamp */
	   /*tstamp = YES;*/
	}

	src_len = ms_x_lseek(sfh,0,2);
	ms_x_lseek(sfh,0,0);

	srcopen=YES;
	attrib=ms_x_chmod(src,attrib,0);	/* read src file attributes */

	/* Don't copy 0 length files */
	if (src_len == 0L && !srcdev) return(FAILURE);
#if 0
	if(readsrc()==FAILURE) 		/* read a buffer full */
	    return (FAILURE);
		
	/* amount contains the size of real data in the buffer */	  
	/* srcopen set if source is still open		       */
	
	fullbuf=YES;			/* buffer contains data */
#endif	
	return (SUCCESS);	
}

/* 
 *	source already open
 *	Reads a buffer full of the source
 *	If eof src then closes source
 *	If error then closes source
 *	Returns success or failure
 *
 *	Uses/sets static variables -
 *		sascii
 *		bufaddr
 *		bufsize    
 *		
 *		srcopen 	indicates if src still open
 *		srcdev
 *		fullbuf 	indicates if data in buffer
 *		amount
 *		sfh
 */

MLOCAL BOOLEAN readsrc()
{
	WORD	ret;		/* return code from source open */
	UWORD	i;
	BOOLEAN eofsrc;
	
	fullbuf = NO;		/* Buffer Empty		*/
	eofsrc = NO;		/* EOF not found	*/
	amount = 0;		/* 0 Bytes read so far	*/
		
	while(!eofsrc) {
	    ret = far_read(sfh, bufaddr+amount, bufsize-amount);
	    if((ret&(-256))==(-256)) {		/* if error */
		e_check2(ret);
		ms_x_close(sfh);
		return (FAILURE);		
	    }

	    if(sascii || srcdev) {		/* Check data for ^Z	    */
	    	i = findeof(bufaddr+amount, ret);/* if FINDEOF returns a    */
	    	if(i < ret) {			/* count less than RET	    */
		    eofsrc=YES;			/* then end of transfer     */
		    amount += i-ret;		/* using the updated size   */
		}
	    }
	    amount += ret;
		
	    if(amount == bufsize)		/* Check for a full buffer  */
	        break;				/* and break when full. Else*/
	    else if(!srcdev || ret == 0)	/* if the source is not a   */
	        eofsrc = YES;			/* device then must have    */
						/* reached the EOF.	    */
	}
	
	if(eofsrc) {			/* if eof src then close src */
	    ms_x_close(sfh);
	    srcopen=NO;
	}
		
	/* amount contains the size of real data in the buffer */	  
	/* srcopen set if source is still open		       */
	
	fullbuf=YES;			/* buffer contains data */

#if 0
	if (amount == 0) return(FAILURE); /* BAP - if file is 0 bytes, don't */
					  /* copy it */
#endif

	return (SUCCESS);	
}

/* 
 *	If the destination is not open it gets opened (file handle dfh).
 *	Copies source file to destination file dfh
 *	(actually concatinates source file onto end of destination file).
 *	Returns success or failure
 *	If source has been preread then uses preread buffer full
 *	else opens the source
 *	Always ends by closing the source
 *	Destination is always closed except if concat ****
 *
 *	Uses/sets static variables -
 *		dfh		destination file handle
 *		sfh
 *		fullbuf
 *		sascii
 *		tstamp		sets tstamp=NO if source is a device
 *		date,time
 *		dfailed 	if destination error
 *		bufaddr
 *		bufsize     
 *		amount
 *		concat
 */
MLOCAL BOOLEAN copy1(src,dest)
BYTE	*src;			/* source filename */
BYTE	*dest;			/* destination filename */
{
	UWORD	ret;		/* return code from source open */
	UWORD	bytes_left;
	UWORD	bytes_written;
	BYTE FAR *tp;
	BOOLEAN ABloop1;	/* special case if single drive copy */
				/* must not leave destination open   */

	ABloop1=NO;

	/*printf("copying %s to %s\n",src,dest);*/

	if (!ABswap && !concat && srcopen && !sascii) {
	    dfailed=dopen(dest);
	    if(dfailed) {
	    	if(srcopen) 
		    ms_x_close(sfh);
	        return (FAILURE);	/* error - cant open dest */
	    }
	    
#if 0
	    src_len = ms_x_lseek(sfh,0,2);
	    ms_x_lseek(sfh,0,0);
#endif
#if 0	    
/* taken out as it screws POWERLAN. */
	    /*printf("novell_copy(%d,%d,%ld)\n",sfh,dfh,src_len);*/
	    
	    if (novell_copy(sfh,dfh,src_len)) {
	        ms_x_close(sfh);
		srcopen = NO;
		ms_x_close(dfh);
		dstopen = NO;
		nfiles++;
		return(SUCCESS);
	    }
#endif
	}
	
	do {
	    if(!fullbuf) {			/* if buffer not prefilled */
						/* then fill the buffer    */
		if(!srcopen) {			/* if src not open then use preread */
		    if(preread(src)==FAILURE)	/* (opens src)*/
			return (FAILURE);	
		}
		/*else {*/		/* source open, therefore use readsrc */
		    if(readsrc()==FAILURE) 	/* read next buffer full */
			return (FAILURE);
		/*}*/
	    }
	
	/* at this point we have a buffer full		 */
	/* src is closed if this is the last buffer full */

	    if(!dstopen) {		/* if destination not open, open it */
		if(ABloop1) {		/* special case if 2nd time round the loop */
					/* and single drive copy */
		    dfh=ms_x_open(dest,OPEN_RDWR);	/* open dest for rw	*/
		    dstopen=YES;
		    ms_x_lseek(dfh, (LONG) 0,2);	/* lseek to end of dest */
		}
		else {			/* normal case */
		    dfailed=dopen(dest);
		    if(dfailed) {
		    	if(srcopen) 
			    ms_x_close(sfh);
		        return (FAILURE);	/* error - cant open dest */
		    }
		}
	    }

	    /* write to destination */
	    if(COPY_ZERO) {
		for(tp = bufaddr, ret = 0; ret < amount; ret++, tp++)
		    *tp &= 0x7F;
	    }
	    

#if TRUE
	/* This is a better way to do do things */
	    bytes_left = amount;
	    bytes_written = 0;
	    while(bytes_left > 0) {
		ret = far_write(dfh, bufaddr+bytes_written, bytes_left);
		if ((ret > 0xFF00)||(ret == 0)) {
			if (isdev(dfh)) printf(MSG_DEVFAIL);
			else printf(MSG_FULL);
			dfailed=YES;
			if (srcopen) ms_x_close(sfh);
	    		return(FAILURE);
		}
		bytes_left -= ret;
		bytes_written += ret;
	    }
#else 
	    if(far_write(dfh, bufaddr, amount)!=amount)  {
		if (isdev(dfh)) printf(MSG_DEVFAIL);
		else printf(MSG_FULL);	 /* disk full error */
		dfailed=YES;
		if(srcopen)
		    ms_x_close(sfh);
		return (FAILURE);
	    }
#endif
	    fullbuf=NO;

	    if(srcopen && ABswap) {	/* must temp close destination if */
		ms_x_close(dfh);	/* single drive copy with AB swap */
		dstopen=NO;
		ABloop1=YES;
	    }
	} while(srcopen);		/* loop till end of source */
	
	if(!concat) {			/* CLOSE dest except if concatinating */
	    dclose(dest,dfh,dfailed);
	    if(!dfailed)			
		nfiles++;	 /* nfiles refers to no of dest files */
	    if(dfailed)
		return (FAILURE);
	}
	return (SUCCESS);	
}

/* 
 *	The destination file is opened, and the file pointer is 
 *	lseeked to the end of the file. (or to the 1st ^Z if ascii)
 *	Returns success or failure
 *	
 *	Used by scheme1 for special case of  copy bill+fred bill, 
 *	copy ref.lst+*.lst etc 
 *	
 *	Uses/sets static variables -
 *		dfh		destination file handle
 */
MLOCAL BOOLEAN lseek(dest)
REG BYTE  *dest;			/* destination filename */
{
	LONG	lsize;
	BOOLEAN seof;
	WORD	ret;
	REG UWORD  u, i;
	
	if(!d_check(dest)) {
	    crlf();
	    return (FAILURE);	/* invalid drive */
	}

	/* dont need to read files date and time as always concat case */
	/* but must set todays date */
	
	touch(dest);			/* set timestamp */
		
	dfh=ms_x_open(dest,OPEN_RDWR);		/* open file for read and write */

/*	if(dfh==ED_FILE)		  */ /* if file doesnt exist, create it */
/*		return(dopen(dest)); */ /* not necessary as src/dest must exist as found by ms_x_first */
		 
	if(dfh < 0) {
	    e_check2(dfh);			/* error (not necessary to set dfailed) */
	    return (FAILURE);
	}
	
	dstopen=YES;			/* dest in now open */

	if(sascii) {			/* ascii file so look for 1st ^Z */
	    lsize=0;
	    seof=NO;		
	    do {		/* do while !seof */
		u=ret=far_read(dfh, bufaddr, bufsize);    /* read a buffer full */
		if((u&(-256))==(-256)) {			/* if error */
		    e_check2(ret);
		    return (FAILURE);		
		}
	
	        i = findeof(bufaddr, u);	/* if FINDEOF returns a     */
	        if(i < u) {			/* count less than AMOUNT   */
		    seof=YES;			/* then end of transfer     */
		    u = i;			/* using the updated size   */
	        }
		
		if(u!=bufsize)		  /* if not full */
		    seof=YES;		/* then eof    */

		lsize += u;
			
	    } while (!seof);	/* lsize = size of file up to 1st ^Z (or total size if no ^Z) */

	    if(ms_x_lseek(dfh,lsize,0) < 0)	/* lseek to ^Z or end of file (mode 0) */
		return (FAILURE);		/* if error */
				
	}
	else {				/* binary file so just lseek to end */
	    lsize=0;	
	    if(ms_x_lseek(dfh,lsize,2) < 0)		/* lseek to end of file (mode 2) */
		return (FAILURE);		/* if error */
	}

	return (SUCCESS);	
}

/*
 *	Checks whether the filespecs are different
 *	(src and dest are explicit filespecs (ie not wild))
 *	Actually just checks relative filespec, taking drive into account
 *	(ie doesnt check full absolute filespecs)
 *	As per msdos
 *
 *	Actually that isn't as per msdos - now we expand to physical path
 *	to catch SUBST drives, absolute filespecs etc.
 *
 *	Prints message if same file, and returns YES or NO
 */
MLOCAL BOOLEAN samefs(src,dest,mess)
REG BYTE *src,*dest;
BOOLEAN  mess;
{
#if 1
BYTE	sp[MAX_PATHLEN+MAX_FILELEN+3];
BYTE	dp[MAX_PATHLEN+MAX_FILELEN+3];
	
 	ms_x_expand(sp, src);
 	ms_x_expand(dp, dest);
 
 	if(strcmp(sp,dp)!=0)
 	    return (NO);
 
#else
/* EJH 27-11-90 START */

 	BYTE	sd,dd;
	
	sd=drive + 'a';			/* assume current drive */    
	dd=sd;
		
	/* if either src or dest end in a dot, remove dot */
	if(*src && src[strlen(src)-1]=='.')
	    src[strlen(src)-1]='\0'; 
	if(*dest && dest[strlen(dest)-1]=='.')
	    dest[strlen(dest)-1]='\0'; 
	
	if(strlen(src)>2 && src[1]==':') {
	    sd=src[0];		/* get drive */
	    src=src+2;		/* skip drive */
	}

	if(strlen(dest)>2 && dest[1]==':') {
	    dd=dest[0];		/* get drive */
	    dest=dest+2;		/* skip drive */
	}

	if(sd!=dd)
	    return (NO);
		
	if(strcmp(src,dest)!=0)
	    return (NO);

/* EJH 27-11-90 END */
#endif
	if(mess) {
	    if(concat)
		eprintf(MSG_DLOST);
	    else
		eprintf(MSG_CPYSELF);
	}

	if(srcopen)			/* if same file, close src */ 
	    ms_x_close(sfh);		/* as this is always an error return */
					/* or a special case */
	return (YES);			
}


/*
 *	Checks for single physical floppy disk drive, 
 *	with src and dest being different diskettes
 */
MLOCAL BOOLEAN ABcheck(src,dest)
REG BYTE *src,*dest;
{
	BYTE	sd,dd;
	
	sd=drive+'a';			/* assume current drive */    
	dd=sd;
		
	if(strlen(src)>2 && src[1]==':')
	    sd=src[0];		/* get drive */

	if(strlen(dest)>2 && dest[1]==':')
	    dd=dest[0];		/* get drive */

	/* should do logical to physical drive conversion */
	/* sd=pdrive(sd-'a')+'a'  etc			  */

	if(sd>'b' || dd>'b' || sd==dd)
	    return (NO);		/* either src or dest is not floppy, */
					/* or they are on the same disk */
					/* then 'normal' case		*/
	/* reasonably safe to assume only A and B can be mapped onto a single physical floppy disk */
	 
	return (YES);		/* single physical floppy drive special case */
				/* src and dest possibly on different diskettes */
	/* Returns YES even if there are two physical floppy disk drives */
}

/*
 *	Prints name of source file copied (in upper case)
 *	and handles msdos pecularities
 *	eg
 *		\fred  prints out as a:\fred  
 *		ie adds drive if 1st char = pathchar
 */
MLOCAL VOID prtsrc(src)
REG BYTE  *src;
{
	strupr(src);			 /* convert to upper case */
	if(*src==*pathchar && src[1] != *pathchar)
	    printf("%c:", drive+'A');

	printf("%s\n",src);
	strlwr(src);			 /* convert back to lower case */
	return;
}

/* Confirm copy message routine
 * prints filename and asks Y/N
 * returns TRUE if confirmed 
 */
MLOCAL BOOLEAN conf_src(src)
REG BYTE  *src;
{
BOOLEAN answer;

	strupr(src);			 /* convert to upper case */

	/* could do *src==*pathchar check etc as per prtsrc  */

	printf(MSG_ERAQ,src);		/* same format as delq message */
	answer = yes(YES,NO);		/* get answer, default = NO    */

	strlwr(src);			 /* convert back to lower case */
	return(answer);
}


MLOCAL VOID e_check2(ecode)	/* e_check() + CR/LF */
REG WORD ecode;
{
	e_check(ecode);
	crlf();
	return;
}

/* 
 *	modifies file s's timestamp to todays date and time
 *	s maybe wild
 */
MLOCAL BOOLEAN touch (s)
REG BYTE  *s;
{
	SYSDATE tdate;
	SYSTIME ttime;

	WORD	fh;
	
	ms_getdate(&tdate);
	ms_gettime(&ttime);
	
	/* covert todays date to timestamp format  */
	/* date = (year-1980)*512 + month*32 + day */
	/* time = hour*2048 + minute*32 + second/2 */
	
	date=((tdate.year-1980)<<9) + (tdate.month<<5) + tdate.day;
	time=(ttime.hour<<11) + (ttime.min<<5) + (ttime.sec>>1);
	
	if((fh=ms_x_open(s,OPEN_RDWR)) >=0) {	/* open file for r/w if no error */
	    ms_x_datetime(1,fh,&time,&date); /* change files timestamp */
	    ms_x_close(fh);
	    return (SUCCESS);
	}
	else {
	    e_check2(fh);		/* if error */
	    return (FAILURE);
	}
}

#if defined(PASSWORD)
MLOCAL BYTE * get_pswd(s)		/* return ptr to password part of s */
REG BYTE   *s;				/* (including the ';' )		   */
					/* return ptr to '\0' if no password */
{
	while(*s) {			/* while not at end	   */
	    if(*s == *pwdchar)		/* if next char is password delimiter */
		return (s);		/* return its address	   */
	    s ++;			/* else goto next position */
	}				
	return (s);			/* if end, return ptr to '\0' terminator */
}
#endif
