/*
;    File              : $Workfile: BATCH.C$
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
 * 27 Oct 87 Improve GOTO command to ignore trailing white space, only
 *		match on the first 8 characters and only allow valid
 *		filename characters.
 * 28 Oct 87 Correct duplicate prompt display when a batch file label
 *		is read and the echo flag is ON.
 *  9 Nov 87 Change Batch file termination so that Output Redirection is
 *		correctly handled.
 * 13 Jan 88 If prompt display is aborted because of a critical error
 *		the following prompt will be forced to "$n$g".
 * 25 Jan 88 Support redirection on the FOR command correctly
 * 24 Feb 88 Generate batch file parameter %0 correctly as WS200 install
 *		requires that the drive specifier be present. Garry Silvey
 *  5 May 88 Batch paramater %0 is now a copied from the invoking command
 *		line.
 * 18 May 88 Support the ESC_CHAR in the command line.
 * 20 May 88 Disable MULTI_CHAR support in DOSPLUS when the user enters the
 *		first command.
 * 26 May 88 Added STACK switch and support $q in prompt.
 * 27 May 88 Added string undefs.
 *  6 Jun 88 Call resident portion to do readline (SideKick+ problem)
 * 23 Jun 88 Support CR only delimited batch files and if errorlevel ==
 *		syntax used in installation files.
 *  6 Jul 88 Support the FOR ... CALL syntax correctly. (IMS)
 * 17 Aug 88 Jump to labels followed by comments (Ashton Tate By-Line)
 * 21 Sep 88 Use KEYIN_FLG to allow the default ECHO state to be ON.
 * 16 Nov 88 Disable BACK_CHAR in Concurrent DOS.
 * 21 Dec 88 Allow leading whitespace before labels
 *  5 Jan 89 Support Quoted strings in Batch files.
 * 18 Apr 89 Support Quoted strings in IF command
 * 19 Apr 89 Quotes in IF command: "x == "x" parses, "x=x" == "x.. doesn't
 * 24 Apr 89 Increase MAX_LINE to 128 for pctools ver 5
 * 19 May 89 Take out support for quoted strings in IF command
 * 05 Jun 89 Do not echo command or display the prompt during FOR command.
 *		Restore support for batch files with long lines.
 * 02 Nov 89 batch_line bodge which substitutes 0xFF for 0x00 changed - we
 *		now substitute '\r\n', then throw away rest of the line.
 * 01 Dec 89 batch_line - trailing % at end of line is discarded
 * 15 Dec 89 "if errorlevel -1" allowed
 * 30 Jan 90 Added int2e_start and int2e_finish to save and restore
 *		important batch file variables to allow novell menu program
 *		to use int 2e to invoke batch files.
 * 30 Jan 90 Forced batch data structures to appear on segment boundaries;
 *		Added dummy memory descriptor before batch structure;
 *		Put segment address of batch structure in batch_seg_ptr;
 *		All so novell can find and patch the drive letter of
 *		autoexec.bat during a remote boot.
 *  6-Mar-90 Watcom C v 7.0
 *  7-Mar-90 allow ESC_CHAR through unless followed by MULTI/BACK_CHAR
 * 14-Mar-90 Reduce batch_buf to 32 bytes like wot dos is
 * 20-Mar-90 Batch structures allocated by mem_alloc (ie. MS_M_ALLOC)
 *		rather than on heap. Batch file nesting no longer heap limited.
 * 27-Mar-90 Allow "=", "==", "===" etc in "if errorlevel==n"
 * 10-Apr-90 Make errorlevel 999 same as errorlevel 231 (mod 256)
 *  8-May-90 Don't echo getcmd unless batch file (eg. "dir|more" shouldn't
 *		echo "C:>more")
 * 23-May-90 batch_read no longer repeatedly deblanks line (which leads
 *		to the buffer happily wandering up memory).
 * 30-May-90 "if ab de==ef" form doesn't generate syntax error
 * 13-Jun-90 batch_line rejects unmatched "|" as syntax error
 * 20-Sep-90 is_filechar() and is_pathchar() now take pointer instead of byte
 *		Changed batch_char() to return pointer instead of byte,
 *		renamed to batch_ptr().
 *		Amended make_label(), batch_start() and cmd_for() to check for
 *		DBCS lead bytes.
 * 24-Sep-90 Add $m and $u option to PROMPT to display status of mail
             and user name respectively
 * 27-Sep-90 Add IF USERID <userid> COMMAND
                       IF LOGINNAME <loginname> COMMAND
                       IF GROUPNAME <groupname> COMMAND 
                       IF ASK ["string"] <char> COMMAND
                       .. AND .. OR .. to IF processing
                       INPUT ["string"] <environment-variable>
                       INPUTC ["string"] <environment-variable>
 * 10-Oct-90 inherit batch files from TMP when TSR auto-loads CDOS.COM
 		(a bodge for Stellar)
 * 25-Oct-90 inherit echoflg from TMP when TSR auto-loads CDOS.COM
 * 31-Oct-90 change IF ASK command to IF KEY command

DRDOS BUXTON
------------
 * 25-Apr-91 '!' is now ignored during COMMAND /C processing.
 * 28-May-91 leading white space is now ignored before labels.
 * 09-Jun-91 Added GOSUB, RETURN and SWITCH commands.  
 * 24-Jul-91 if batch_seg_ptr is poked to zero all batch processing is
 		 terminated.
 * 26-Jul-91 batch files are now read into a far buffer. This avoids
 		 reading directly to seg FFFF if we happen to be there and so
		 solves some NOVELL problems.

 * 18-Jun-92 Support ? in batch files as in config.sys.
 * 23-Jun-92 $u in prompt causes LOGINNAME in environment to be displayed.
 * 07-Jul-92 IF EXIST now finds hidden files. 
*/

#include <ctype.h>
#include <string.h>
#if defined( MWC ) && defined( strlen )
#undef strcmp /* These are defined as macros in string.h */
#undef strcpy /* which are expanded in line under */
#undef strlen /* Metaware C. These undefs avoid this. */
#endif

#include <portab.h>

#include "command.h"
#include "dos.h"
#include "dosif.h"
#include "global.h"
#include "support.h"
#include "toupper.h"
#include <setjmp.h>

EXTERN VOID CDECL cmd_pause();

EXTERN BOOLEAN parse( BYTE * );

EXTERN UWORD boot_key_scan_code; /* in COM.C */

/*RG-03*/
BOOLEAN if_context = FALSE;
BOOLEAN ifcond = FALSE;
/*RG-03-end*/

EXTERN jmp_buf break_env;

/*#define	MAX_LINE	128*/ /* Maximum No of Chars in input line	*/

EXTERN BYTE msg_prmeq[]; /* Static Environ String "PROMPT="	*/

#if 0
#define FCONTROL struct fcc
MLOCAL FCONTROL {
	BOOLEAN  sflg;			/* FOR File Search Flag 	*/
	DTA	 search;		/* FOR Search structure 	*/
	BYTE	 *files;		/* FOR File list		*/
	BYTE	 *cmd;			/* FOR Command Line		*/
	BYTE	 forvar;		/* FOR variable char		*/
};
#endif

MLOCAL FCONTROL *forptr;

#if 0
#define BCONTROL struct bcc
GLOBAL BCONTROL {
	BCONTROL FAR *bcontrol;		/* Previous Batch Control Structure  */
	BOOLEAN  eof;			/* End of File Flag		     */
	LONG	 offset;		/* Offset in BATCH file 	     */
	LONG	 ret_offset[4];		/* return offset from gosub          */
	BYTE	 *batcmd;		/* Batch File Input parameters	     */
	UWORD	 batshift;		/* Shift Offset 		     */
	BYTE	 batfile[MAX_PATHLEN];	/* Batch File Name		     */
	UWORD	 stream;		/* Stream for this Batch File	     */
	FCONTROL *fcontrol;		/* Pointer to previous FOR command   */
	BYTE	 *heap_start;		/* Heap pointer before extra bytes   */
	WORD	 heap_size;		/* are added to shift to segment     */
	BYTE     save_area[1];		/* boundary. - EJH		     */
	} FAR *batch, FAR *batch_save;	/* Master Batch Control Stucture     */
#endif

/* Handle 255 is closed */
#define CLOSED 0xff

/*	Keyboard  Variables		*/
GLOBAL BYTE kbdbuf[MAX_LINE + 2] = {
   0 };                           /* Keyboard Input Buffer	     */
GLOBAL BYTE *kbdptr = kbdbuf + 2; /* Keyboard Buffer Pointer	     */
MLOCAL BOOLEAN keyin_flg = FALSE; /* This flag is set to TRUE when the */
                                  /* initial command line buffer setup */
                                  /* by INIT() has been exhausted.     */
MLOCAL WORD batchflg_save;        /* Used during INT 2E handling.      */
MLOCAL WORD echoflg_save;         /* ditto above                       */
GLOBAL WORD echoflg_save2;        /* saves echo state when batch file  */
                                  /* execed.			     */
/*
 *	Batch file buffering control structures.
 */
MLOCAL LONG batch_off;     /* Offset of buffered data in File */
MLOCAL WORD batch_cnt = 0; /* Number of bytes in buffer	   */
MLOCAL BYTE batch_buf[32];
MLOCAL BYTE batch_eof[] = "\x1a"; /* End of file string */

MLOCAL BYTE batch_sep[] = "\t ;,="; /* Batch Command line option delimiters */

EXTERN VOID CDECL cmd_ver( BYTE * );  /* COMINT.C Display Version */
EXTERN VOID docmd( BYTE *, BOOLEAN ); /* COM.C		    */
EXTERN VOID CDECL int_break( VOID );  /* COM.C		    */

GLOBAL BOOLEAN getcmd( BYTE * );
GLOBAL VOID for_end();
GLOBAL VOID batch_start( BYTE *, BYTE *, BYTE * );
GLOBAL VOID batch_new( VOID );
MLOCAL VOID batch_old( VOID );
GLOBAL VOID batch_end( VOID );
GLOBAL VOID batch_endall( VOID );
GLOBAL VOID batch_close( VOID );
MLOCAL VOID for_in( BYTE * );
MLOCAL WORD batch_open( VOID );
MLOCAL VOID batch_read( BYTE *, BOOLEAN );
MLOCAL VOID batch_line( BYTE *, BOOLEAN );
MLOCAL BYTE *batch_ptr( VOID );
MLOCAL VOID prompt( VOID );
MLOCAL BOOLEAN following_command( VOID );
MLOCAL BOOLEAN novell_extension( BYTE *, BYTE * );

EXTERN UWORD FAR *batch_seg_ptr; /* For novell remote boot. see CSTART.ASM */

/*.pa*/
GLOBAL BOOLEAN getcmd( BYTE *line ) /* read command line */
{
   BYTE *s, *s1;
   BOOLEAN quote = FALSE;
   BOOLEAN cancel_prompt = FALSE;
   WORD i;
   BYTE cmd_name[16];
   BYTE envvar[128];
   BYTE varbuf[128];

   back_flag = FALSE; /* Disable BackGround Processing*/

   *line = '\0';

   FOREVER
   {
      if ( for_flag ) {  /* If Processing a FOR command	*/
         for_in( line ); /* then call then use the FOR_IN*/
         return NO;      /* routine to fill the keyboard */
      }                  /* buffer and then return	*/

      if ( !batchflg ) { /* If no batch processing then  */
         break;          /* skip further tests		*/
      }
   batch_restart:

      if ( !*batch_seg_ptr ) { /* if batch_seg_ptr has been set to */
         batch_endall();       /* zero terminate all batch files   */
         return NO;
      }

      if ( batchflg && batch->eof ) { /* Close the batch file if at */
         batch_end();                 /* the end of the file.	*/
         if ( batchflg == 0 ) {       /* BREAK if batch processing	*/
            return NO;                /* is complete. 		*/
         }
         continue;
      }

      if ( !batch_open() ) { /* Open the file and read a line*/
         return YES;         /* from the file		*/
      }

      batch_read( line, NO ); /* Read Line			*/

      if ( batch->eof ) { /* If the end of the batch file */
         batch_close();   /* has been detected then close */
      }
      /* the file.			*/

      if ( *line == '?' || boot_key_scan_code == 0x4200 ) {
         optional_line( line );
      }

      if ( *line == '@' ) {        /* If first character in the	*/
         strcpy( line, line + 1 ); /* command line is '@' donot	*/
         return NO;                /* echo the command and move the*/
      }                            /* string down 1 character.	*/

      if ( !cancel_prompt ) {
         if ( crlfflg && echoflg ) {
            crlf();
         }
         prompt();
      }
      return echoflg;
   }

   if ( !*kbdptr ) {    /* Set the Keyboard Input flag  */
      keyin_flg = TRUE; /* after a initial command line */
                        /* buffer has been exhausted	*/
#if 1
      if ( c_option ) {       /* insert an EXIT command if we */
         kbdptr = &kbdbuf[2]; /* are processing a /C command  */
         strcpy( &kbdbuf[2], "exit" );
      }
#endif
   }

   if ( !*kbdptr ) { /* Check for existing line      */

      /* NEIL */
      if ( crlfflg && echoflg ) {
         crlf();
      }
      /* NEIL end */
      prompt(); /* issue command line prompt	*/
      allow_pexec = FALSE;

      /* $x in prompt string may cause batchflg to be set. */
      /* If so we must jump to batch processing code.	 */
      if ( batchflg ) {
         cancel_prompt = TRUE;
         goto batch_restart;
      }

      kbdptr = ""; /* Force KBDPTR to point to '\0'*/
      /* in case we get ABORTED and	*/
      /* drop through here again.	*/
      kbdbuf[0] = MAX_LINE;         /* set max. input length	*/
      kbdbuf[kbdbuf[1] + 2] = '\r'; /* Terminate current line.	*/
      readline( kbdbuf );

      crlf();

      if ( kbdbuf[kbdbuf[1] + 1] == '\r' ) {
         /* remove trailing \r */
         kbdbuf[1]--;
      }

      kbdbuf[kbdbuf[1] + 2] = '\0'; /* terminate input		*/
      kbdptr = kbdbuf + 2;
   }

   s = kbdptr;

   while ( *s ) {
      if ( *s == '"' ) { /* Check for a " character and  */
         quote = !quote; /* update the flag correctly	*/
      }

      if ( *s == '%' ) {
         if ( *( s + 1 ) == '%' ) {
            s++;
         }
         else {
            s1 = s + 1;
            i = 0;
            envvar[i] = '\0';
            while ( *s1 ) {
               if ( *s1 == '%' ) {
                  if ( *( s1 + 1 ) == '%' ) {
                     s1++;
                     envvar[i++] = *s1++;
                  }
                  else {
                     envvar[i] = '\0';
                     strcat( envvar, "=" );
                     s = s1 + 1;
                     strupr( envvar );
                     if ( env_scan( envvar, varbuf ) ) {
                        if ( novell_extension( envvar, varbuf ) ) {
                           break;
                        }
                     }
                     s1 = varbuf;
                     while ( *s1 ) {
                        *line++ = *s1++;
                     }
                  }
               }
               else {
                  envvar[i++] = *s1++;
               }
            }
         }
      }

      if ( *s == ESC_CHAR && /* If the Escape character has  */
           !quote &&         /* been specified then do not	*/
           ( ( *( s + 1 ) == MULTI_CHAR ) || ( *( s + 1 ) == BACK_CHAR ) ) ) {
         *line++ = *++s; /* process the following char.	*/
         s++;
         continue;
      }

      if ( !( keyin_flg || c_option || k_option ) ) {
         /* after the init command line  */
         /* has been exhausted.		*/
         if ( *s == MULTI_CHAR && /* If a Multiple command char	*/
              !quote ) {          /* and the QUOTE flag is FALSE	*/
            s++;                  /* then break the command here	*/
            break;                /* and save the rest of the line*/
         }                        /* for next time.		*/
      }

#if FALSE
      if ( *s == BACK_CHAR && /* If a Back Ground processing	*/
           !quote ) {         /* and the QUOTE flag is FALSE	*/
         s++;                 /* then treat as for MULTI_CHAR	*/
         back_flag = TRUE;    /* except that the current      */
         break;               /* command is executed in the   */
      }                       /* background.			*/
#endif
      if ( *s == PIPE_CHAR && /* If a Pipe enable character	*/
           !quote ) {         /* and the QUOTE flag is FALSE	*/
         s++;                 /* then break the command here	*/
         pipe_out = YES;      /* and save the rest of the line*/
         break;               /* for next time.		*/
      }

      copy_char( &line, &s ); /* Just save the character	*/
   }

   *line = '\0';          /* Terminate the Buffer 	*/
   kbdptr = deblank( s ); /* Copy the possibly null length*/
   return NO;             /* string to KBDBUF for next    */
                          /* next invocation and save CCP */
}

MLOCAL VOID for_in( BYTE *line ) /* A FOR command is currently	*/
                                 /* line: executing so build the line	*/
{                                /* from the internal FOR data	*/
   BYTE *s, *t;                  /* initialized by CMD_FOR	*/
   BYTE *bp1, *fp;
   WORD i;

   FOREVER
   {
      fp = forptr->files;        /* Get the next string and stop     */
      if ( strlen( fp ) == 0 ) { /* if its the zero length string    */
         *line = '\0';           /* which marks the end of the FOR   */
         crlfflg = YES;          /* search list. 		    */
         for_end();
         return;
      }

      if ( !iswild( fp ) ) {                /* If not an ambiguous file  */
         forptr->sflg = NO;                 /* then update the FOR	     */
         forptr->files += strlen( fp ) + 1; /* pointer to the next file  */
         break;                             /* in the search list.	     */
      }

      if ( forptr->sflg ) {                /* Search for the next file  */
         i = ms_x_next( &forptr->search ); /* file on the disk if	     */
      }
      else { /* FOR_SFLG otherwise get first */
         i = ms_x_first( fp, ATTR_RO, &forptr->search );
      }

      if ( i < 0 ) {                        /* If the search failed      */
         forptr->sflg = NO;                 /* then update the FOR	     */
         forptr->files += strlen( fp ) + 1; /* pointer to the next file  */
         continue;                          /* in the search list.	     */
      }                                     /* and get the next  entry   */

      fp = (BYTE *)heap();
      strip_path( forptr->files, fp );    /* Extract the Path	     */
      strcat( fp, forptr->search.fname ); /* and then add the matching */
      forptr->sflg = YES;                 /* filename and update the   */
      strupr( fp );                       /* variables.		     */
      break;                              /* Force name to uppercase   */
   }

   s = forptr->cmd;
   t = line;
   while ( *s && ( t - line ) < MAX_LINE ) { /* Copy the command 	 */
      if ( *s == '%' &&
           *( s + 1 ) == forptr->forvar ) { /* line looking for  */
         s += 2;                            /* the imbedded %c and insert*/
         bp1 = fp;                          /* the current substition    */
         while ( *bp1 &&
                 ( t - line ) < MAX_LINE ) { /* string pointed at by FP   */
            copy_char( &t, &bp1 );
         }
         continue;
      }

      copy_char( &t, &s );
   }

   *t = '\0'; /* and terminate the string */
}

/*.pa*/
/*
 *	BATCH FILE CONTROL ROUTINES
 *	===========================
 *
 *	The following routines provide the interface from COMMAND.COM to
 *	a batch file. BATCH_START sets up all the local variables to enable
 *	batch processing while BATCH_END terminates batch processing. BATCH_READ
 *	reads a line of data from the batch file and expands it to contain the
 *	command line variables and variables from the environment.
 */
GLOBAL VOID batch_start( BYTE *argv0, BYTE *path, BYTE *tail )
/* argv0: Invoking Command	*/
/* path: Complete filename	*/
/* tail: Command Line Options	*/
{
   BYTE *s2;
   BYTE dirbuf[MAX_PATHLEN];
   WORD i;
   BYTE quoteflag;

   if ( batchflg ) { /* If a batch file is currently */
      batch_close(); /* close it. So minimum number	*/
   }
   /* of handles are used. 	*/

   s2 = path;                                  /* Save the original Path	*/
   if ( ( path = d_check( path ) ) == NULL ) { /* Check that the file	*/
      return;                                  /* exists.			*/
   }

   batch_new(); /* new incarnation of batch	*/

   forptr = (FCONTROL *)NULL; /* Disable current FOR control	*/
   for_flag = NO;             /* and Global FOR flag		*/

   /*
	 *	Generate the full path specification for the batch file
	 *	and store in the batch control information. If the user
	 *	has specified the full path use it otherwise determine the
	 *	full path using ms_x_curdir.
	 */
   if ( ddrive != -1 && *path != *pathchar ) {
      ms_x_curdir( ddrive + 1, dirbuf );
      sprintf( heap(), "%c:%s%s%s%s", ddrive + 'A', pathchar, dirbuf,
               ( *dirbuf ? pathchar : "" ), path );
   }
   else if ( ddrive != -1 ) {
      sprintf( heap(), "%c:%s", ddrive + 'A', path );
   }
   else {
      ms_x_expand( heap(), path );
   }

   for ( i = 0; i < MAX_PATHLEN; i++ ) { /* save the batch pathname */
      batch->batfile[i] = heap()[i];
   }
   batch->batfile[MAX_PATHLEN - 1] = 0;

   /*
	 *	Copy the invoking command and the individual elements
	 *	of the command line into a buffer ready for processing
	 */
   batch->batcmd = (BYTE *)heap();   /* Initialize Parameter Buffer	*/
   strcpy( heap(), argv0 );          /* Copy the invoking command	*/
   heap_get( strlen( heap() ) + 1 ); /* and protect the buffer	*/

   quoteflag = 0;
   while ( *tail ) {       /* While there are command line */
      s2 = (BYTE *)heap(); /* parameters copy them 	*/
      if ( *tail == '"' ) {
         quoteflag = !quoteflag;
      }
      while ( *tail && !quoteflag && strchr( batch_sep, *tail ) ) {
         tail = skip_char( tail );
         if ( *tail == '"' ) {
            quoteflag = !quoteflag;
         }
      }

      while ( *tail && ( quoteflag || !strchr( batch_sep, *tail ) ) ) {
         copy_char( &s2, &tail );
         if ( *tail == '"' ) {
            quoteflag = !quoteflag;
         }
      }

      *s2++ = '\0';
      heap_get( strlen( heap() ) + 1 );
   }

   *(WORD *)heap_get( 2 ) = 0; /* Double NULL is a terminator	 */
                               /* for command line params	 */

   if ( in_flag & REDIR_ACTIVE ) { /* If Input redirection has been */
      in_flag |= REDIR_BATCH;      /* enabled for this command force*/
   }
   /* it on for the complete command*/

   if ( out_flag & REDIR_ACTIVE ) { /* If Output redirection has been*/
      out_flag |= REDIR_BATCH;      /* enabled for this command force*/
   }
   /* it on for the complete command*/

   batchflg++; /* increment batch flag		*/

   crlfflg = YES; /* print CR/LF after this  */
}

GLOBAL VOID batch_endall( VOID ) /* This terminates BATCH	*/
{                                /* processing by closing ALL	*/
   while ( batchflg ) {          /* active batch files		*/
      batch_end();
   }
}

GLOBAL VOID batch_end( VOID ) /* This function is called for	*/
{                             /* both NORMAL and ABNORMAL	*/
   if ( batchflg == 0 ) {     /* termination of batch file	*/
      return;                 /* processing			*/
   }

   boot_key_scan_code = 0;

   batch_close(); /* Close the Batch file 	*/
   for_end();     /* Terminate Any FOR command	*/
   batch_old();   /* Restore the previous batch 	*/
                  /*  control structures to heap	*/
   if ( --batchflg == 0 ) {
      *batch_seg_ptr = 0;
      echoflg = echoflg_save2; /* Restore the original ECHO	*/
      crlfflg = YES;           /* flag and set CR/LF flag when */
   }                           /* returning to the keyboard.	*/
}

MLOCAL BOOLEAN batch_open( VOID )
{
   WORD h, i;
   BYTE *name;

   if ( batch->eof ) { /* If the End of the batch file */
      batch_end();     /* was discovered last time then*/
      return FALSE;    /* End Batch file input and exit*/
   }

   if ( batch->stream != CLOSED ) {
      return batch->stream;
   }

   name = heap();

   for ( i = 0; i < MAX_PATHLEN; i++ ) {
      name[i] = batch->batfile[i];
   }
   while ( ( h = ms_x_open( name, OPEN_READ ) ) < 0 ) {
      err_flag = TRUE;
      eprintf( MSG_BATMISS, name ); /* prompt for batch file    */
      heap_get( strlen( name ) + 1 );
      cmd_pause( "" );
      heap_set( name );
   }
   err_flag = FALSE;
   batch->stream = h;
   return TRUE;
}

GLOBAL VOID batch_close( VOID )
{
   if ( batchflg != 0 &&
        batch->stream != CLOSED ) { /* Check if the batch file  */
      batch_cnt = 0;                /* currently open if YES    */
      ms_x_close( batch->stream );  /* then flush the internal  */
      batch->stream = CLOSED;       /* buffer and close file.   */
   }
}

GLOBAL VOID inherit_batch_file( BCONTROL FAR *bc )
{
   WORD i;
   BYTE FAR *p_heap;
   BYTE *l_heap;

   /* inherit any parent batch file first */
   if ( bc->bcontrol ) {
      inherit_batch_file( bc->bcontrol );
   }

   /* create a new batch structure */
   batch_new();

   batch->offset = bc->offset; /* continue at same offset */
   for ( i = 0; i < 4; i++ ) {
      batch->ret_offset[i] = bc->ret_offset[i];
   }
   batch->batshift = bc->batshift;

   for ( i = 0; i < MAX_PATHLEN; i++ ) { /* get the batch pathname */
      batch->batfile[i] = bc->batfile[i];
   }
   batch->batfile[MAX_PATHLEN - 1] = 0;

   /* get command line */

   p_heap = MK_FP( *parent_psp + 16, bc->batcmd );
   l_heap = heap();

   while ( 1 ) {
      while ( *p_heap ) {
         *l_heap++ = *p_heap++;
      }
      *l_heap++ = *p_heap++;
      if ( *p_heap == 0 ) {
         *l_heap = 0;
         break;
      }
   }
   heap_get( l_heap - heap() );

   batchflg++;
}

GLOBAL VOID inherit_parent_state( VOID )
{
   UWORD FAR *p;
   BCONTROL FAR *bc;
   UWORD root_psp;

   root_psp = *parent_psp;
   while ( 1 ) {
      p = MK_FP( root_psp - 1, 8 );
      if ( p[0] == 0x4F43 && p[1] == 0x4D4D && p[2] == 0x4E41 &&
           p[3] == 0x0044 ) {
         break;
      }

      p = MK_FP( root_psp, 0x16 );
      root_psp = *p;
   }

   p = MK_FP( root_psp + 16, batch_seg_ptr );
#if 0
	printf("batch_seg_ptr = %04X:%04X\n",p);
	printf("parent batch_seg_ptr = %04X\n",*p);
#endif
   if ( *p == 0 || *p == 0xFFFF ) {
      return;
   }

   bc = MK_FP( *p, 0 );

   inherit_batch_file( bc );

   *p = 0;

   p = MK_FP( root_psp + 16, &echoflg );
   echoflg = *p;
}

GLOBAL VOID batch_new( VOID )
/* save current batch file heap contexts to high memory */
{
   BYTE *hp_start;
   WORD hp_size;
   UWORD i;
   BCONTROL FAR *bc;

   if ( batchflg != 0 ) {
      hp_start = batch->heap_start;
   }
   else {
      hp_start = heap();
   }

   hp_size = heap() - hp_start;

   i = ( sizeof( BCONTROL ) + hp_size + 15 ) / 16;
   mem_alloc( (BYTE FAR * NEAR *)&bc, &i, i,
              i ); /* allocate new batch structure */

   if ( i == 0 ) {                   /* if we can't allocate one	*/
      longjmp( break_env, IA_HEAP ); /* then pretend heap has run out*/
   }                                 /* to force termination.        */

   bc->bcontrol = batch; /* Link to Previous Structure	*/
   batch = bc;           /* make this current batch struc*/
   batch->eof = NO;      /* Have not found the EOF yet	*/
   batch->offset = 0L;   /* start at beginning of File	*/
   for ( i = 0; i < 4; i++ ) {
      batch->ret_offset[i] = 0L;
   }
   batch->batshift = 0;          /* No Shift Factor		*/
   batch->stream = CLOSED;       /* Batch file is not open	*/
   batch->fcontrol = forptr;     /* Save current FOR control	*/
   batch->heap_start = hp_start; /* Save original heap		*/
   batch->heap_size = hp_size;

   for ( i = 0; i < hp_size; i++ ) {
      batch->save_area[i] = hp_start[i];
   }

   heap_set( hp_start ); /* free up heap used by old batch */

   /* Get segment address of batch and put it where novell	*/
   /* can find it.						*/

   *batch_seg_ptr = (UWORD)( ( (ULONG)batch ) >> 16 );
}

MLOCAL VOID batch_old( VOID )
/* restore current batch file heap contents from high memory */
{
   BCONTROL FAR *bc;
   UWORD i;

   heap_set( batch->heap_start + batch->heap_size );
   for ( i = 0; i < batch->heap_size; i++ ) {
      batch->heap_start[i] = batch->save_area[i];
   }
   bc = batch;
   forptr = batch->fcontrol;           /* Restore the previous for	*/
   for_flag = (BOOLEAN)forptr;         /*  control structures 		*/
   batch = batch->bcontrol;            /* restore ptr to previous batch */
   mem_free( (BYTE FAR * NEAR *)&bc ); /* free up batch memory */
}

/*
 *	Read lines repeatedly from the batch file until a line in 
 *	the correct format is read from the batch file or the EOF
 *	has been reached.
 */
MLOCAL VOID batch_read( BYTE *line, BOOLEAN goto_flg )
/* line: Command Line Buffer		*/
/* goto_flag: Goto Command Flag	*/
{
   BYTE *l; /* we need to deblank line */
   do {
      batch_line( line, goto_flg ); /* Read the next line from  */
      l = deblank( line );          /* the batch file and return*/
      if ( *l != ';' ) {
         if ( goto_flg && *l == ':' ) { /* a line in the correct    */
            return;                     /* format.		    */
         }

         if ( !goto_flg && *l != ':' ) {
            return;
         }
      }
   } while ( !batch->eof );
}

MLOCAL VOID swallow_line( BYTE *s )
/* there is a syntax error on this line - swallow it and say so */
{
   BYTE c;

   prompt();        /* possibly echo the prompt */
   if ( echoflg ) { /* echo to screen if wanted */
      printf( "%s%c", s, PIPE_CHAR );
   }

   do {
      c = *batch_ptr();
      if ( c == 0x1a ) {
         c = '\r';         /* pretend to be end of line*/
         batch->eof = YES; /* We have come to the end  */
         break;            /* flag and mark end of line*/
      }
      if ( echoflg ) { /* echo to screen if wanted */
         putc( c );
      }
   } while ( c != '\r' && c != '\n' );
   if ( echoflg ) {
      putc( '\n' );
   }

   if ( c == '\r' && *batch_ptr() != '\n' ) { /*  skip line feed */
      batch->offset--;                        /* if present	   */
   }

   eprintf( MSG_SYNTAX ); /* report syntax error	*/
}

/*
 *	Read one line from the batch file and place the expanded data into
 *	the buffer LINE.
 */
MLOCAL VOID batch_line( BYTE *line, BOOLEAN goto_flg )
/* line: Command Line Buffer		*/
/* goto_flg: Goto Command Flag	*/
{
   REG WORD i;
   REG BYTE *s;
   WORD n, env_start;
   BYTE c, *bp;
   BYTE env_str[128];
   BOOLEAN quote = FALSE;
   LONG old_offset;
   int j;

   env_start = NULL; /* Copy the environment into a	 */

#if 0
/* 'eject any line starting with 'rem' */
	old_offset = batch->offset;
	i=0;
	do{
	 switch(c=*batch_ptr()){
	 case  0x1a: 
	            batch->eof = YES;		/* We have come to the end  */
   	            c = '\r';			/* of the batch file so set */
    	            break;			/* flag and mark end of line*/
 	 default:
    		if (i < MAX_LINE)
			line[i++] = c;
    		if (dbcs_lead(c)) {
		 if ((c = *batch_ptr()) >= ' ' && i < MAX_LINE)
	    		line[i++] = c;
		}
	 }/*switch*/
	}while(c!='\r');
	
	if (*batch_ptr() != '\n')  batch->offset--;
	 	line[i]=0;
	j=0;
	while(line[j]){
		if (line[j] != ' ')
			break;
		j++;
		}
	if (( strlwr(line[j])   == 'r') &&
    	    ( strlwr(line[j+1]) == 'e') &&
    	    ( strlwr(line[j+2]) == 'm') &&
    	    ( strlwr(line[j+3]) == ' ')){
		if (echoflg)
			printf("%s\n",line);
		line[0]='\0';  
		return;
		}

	batch->offset = old_offset;
	batch->eof    = NO;

#endif
   /*rbf-end*/

   /* process line */
   i = 0;
   do {
      switch ( c = *batch_ptr() ) {
      case '\0': /* In OS/2 install.bat file  */
#if 0
		    if (i < MAX_LINE)		/* "ECHO \0" displays blank  */
			line[i++] = '\r';	/* line - so we insert a CR  */
		    while (c != '\r') {		/* then swallow rest of line */
			c = *batch_ptr();	/* read next character - if  */
			if (c == 0x1a)		/* it's an EOF mark then use */
			    goto end_of_file;	/* end-of-file code else end */
		    }				/* up falling into '\r' code */
#else
         c = *batch_ptr();
         if ( ( c == '\r' ) && ( i < MAX_LINE ) ) {
            line[i++] = '\r';
         }
#endif

      case '\r':                       /* carriage return */
         if ( *batch_ptr() != '\n' ) { /*  skip line feed */
            batch->offset--;           /* if present	   */
         }
         break;
      case '\n': /* LF line ending */
         break;
      case '"':          /* Support Quoted strings   */
         quote = !quote; /* in batch files.	    */
         goto save_it;

      case PIPE_CHAR:               /* Handle Piped Output	    */
         if ( goto_flg || quote ) { /* Ignore this character if */
            goto save_it;           /* we are searching for a   */
         }
         /* Label or Quote.	    */
         line[i] = '\0';
         c = *deblank( line ); /* normal case we just      */
         if ( ( c != '\0' ) && ( c != ':' ) && following_command() ) {
            c = '\r';       /* simulate a CR and set    */
            pipe_out = YES; /* Pipe Output flag.	    */
         }
         else if ( c == ':' ) { /* if it's a label */
            for ( ; ( c != '\r' ) && ( c != '\n' ) && ( c != 0x1A );
                  c = *batch_ptr() ) {
               if ( c == 0x1A ) { /* eat rest of the line     */
                  batch->eof = YES;
               }
            }
            if ( ( c == '\r' ) &&
                 *batch_ptr() != '\n' ) { /*  skip line feed */
               batch->offset--;           /* if present	   */
            }
            c = '\r';
         }
         else {                   /* if it's a syntax error    */
            swallow_line( line ); /* discard the rest of line  */
            i = 0;                /* start again with new line */
         }
         break;

      case '%': /* The following code checks to see if the   */
                /* string starting at line[env_start-1] is   */
                /* define in the environment if it is then   */
                /* its definition replaces it in the input   */
                /* line. Otherwise no change is made.	     */
         if ( env_start ) {
            env_start--;
            line[i] = '\0';                      /* Terminate Input   */
            strcpy( env_str, line + env_start ); /* Copy the String   */
            strupr( env_str );                   /* and force string  */
            bp = (BYTE *)heap();                 /* into Uppercase    */
            i = env_start;
            env_start = NULL;

            strcat( env_str, "=" );
            if ( env_scan( env_str, bp ) ) {
               if ( novell_extension( env_str, bp ) ) {
                  break;
               }
            }

            while ( *bp && i < MAX_LINE - 1 ) {
               line[i++] = *bp++;
            }
            break;
         }

         c = *batch_ptr();
         if ( c == '\r' || c == '\n' ) {
            batch->offset--; /* rewind to point to '\r'   */
            break;           /* then break to normal code */
         }
         if ( c < '0' || c > '9' ) { /* if not a parameter	     */
            if ( c != '%' ) {        /* or a '%' character	     */
               env_start = i + 1;    /* save its start address in */
            }
            goto save_it; /* the string and wait for   */
         }                /* the terminating '%'	     */

         n = c - '0' + batch->batshift; /* get parameter # 0-9 and   */
         /* add in SHIFT offset	     */
         s = batch->batcmd;
         while ( n-- && strlen( s ) ) { /* skip all other parameters */
            s += strlen( s ) + 1;       /*   before the one we want  */
         }

         if ( ( strlen( s ) + i ) >=
              MAX_LINE ) { /* Break if Greater than MAX_LINE*/
            break;
         }
         strcpy( line + i, s ); /* get the substitution */
         i += strlen( s );      /* add in its size */
         break;

      case 0x1a:
         batch->eof = YES; /* We have come to the end  */
         c = '\r';         /* of the batch file so set */
         break;            /* flag and mark end of line*/

      default:
      save_it:
         if ( i < MAX_LINE ) {
            line[i++] = c;
         }
         if ( dbcs_lead( c ) ) {
            if ( ( c = *batch_ptr() ) >= ' ' && i < MAX_LINE ) {
               line[i++] = c;
            }
         }
      }
   } while ( c != '\r' && c != '\n' ); /* repeat until CR	   */

   line[i] = '\0'; /* Terminate the line and  */

   if ( batch->eof ) {
      return;
   }

#if 0      /* not DOS compatible */
	if(*batch_ptr() == 0x1A)		/* Check if the next this  */
	    batch->eof = YES;			/* the end of the file if  */
	else					/* YES then set the flag   */
	    batch->offset--;			/* force the character to  */
#endif     /* be re-read next time    */
   return; /* return to the caller    */
}

MLOCAL BOOLEAN following_command( VOID )
/* return true if we have a possible command on the rest of the line */
{
   LONG old_offset;
   BOOLEAN res = FALSE;
   BYTE *s;

   old_offset = batch->offset; /* save batch offset */
   while ( TRUE ) {
      s = batch_ptr(); /* look ahead at batch file */
      if ( *s == '\r' || *s == '\n' || *s == 0x1a ||
           ( !dbcs_lead( *s ) && *s == PIPE_CHAR ) ) {
         break;
      }
      if ( !is_blank( s ) ) {
         res = TRUE; /* possible command if we   */
         break;      /* hit non whitespace char  */
      }
      if ( dbcs_lead( *s ) ) {
         s = batch_ptr();
         if ( *s == '\r' || *s == '\n' || *s == 0x1a ) {
            break;
         }
      }
   }
   batch->offset = old_offset; /* restore batch offset */
   return res;
}

/*
 *	In order to improve performance of the batch file processing
 *	the Batch file is read in blocks of BATCH_BUF characters.
 *	and the routine BATCH_CHAR then returns a pointer to a character
 *	from the buffer (filling the buffer if required).
 */
MLOCAL BYTE *batch_ptr( VOID )
{
   BYTE FAR *buf;
   UWORD bufsize;
   UWORD i;

   if ( batch->eof ) {
      return ( batch_eof );
   }

   if ( batch->offset < batch_off ||
        batch->offset >= ( batch_off + (LONG)( batch_cnt - 1 ) ) ) {

      batch_off = batch->offset;
      ms_x_lseek( batch->stream, batch->offset, 0 );
      batch_cnt = far_read( batch->stream, gp_far_buff, sizeof( batch_buf ) );
      if ( batch_cnt <= 0 ) {
         batch->eof = YES;
         return ( batch_eof );
      }
      for ( i = 0; i < sizeof( batch_buf ); i++ ) {
         batch_buf[i] = gp_far_buff[i];
      }
   }
   return ( &batch_buf[(UWORD)( batch->offset++ - batch_off )] );
}

/*.pa*/
/*
 *	BATCH FILE COMMANDS
 *	===================
 *
 *	The following commands are used almost entirely in BATCH files and
 *	have little or no meaning outside that environment.
 */
GLOBAL VOID CDECL cmd_shift( VOID )
{
   batch->batshift++; /* Increment the Shift Offset	*/
}

MLOCAL WORD label_ignore_char( BYTE *s )
{
   if ( *s == '=' ) {
      return ( 1 );
   }
   if ( *s == ';' ) {
      return ( 1 );
   }
   if ( *s == ',' ) {
      return ( 1 );
   }
   if ( *s == ' ' ) {
      return ( 1 );
   }
   return ( 0 );
}

/*
 *	Extract the first a valid characters from the label and then
 *	zero terminate the resulting string.
 */
MLOCAL BYTE *make_label( BYTE *label )
{
   REG BYTE *bp;
   UWORD i;

   label = deblank( label ); /* remove leading white space */
   while ( label_ignore_char( label ) ) {
      label = skip_char( label );
   }

   bp = label;

   while ( is_filechar( bp ) ) { /* skip over valid chars      */
      bp = skip_char( bp );
   }

   *bp = '\0'; /* make label zero terminated */
   return label;
}

GLOBAL VOID CDECL cmd_goto( REG BYTE *label ) /* goto label in batch file */
{
   UWORD i;
   BYTE *bp, s[MAX_LINE + 2]; /* Allocate buffer for Batch Input  */

   if ( !batchflg ) { /* if not in batch mode 	    */
      return;         /* this command is ignored	    */
   }

   if ( *label == ':' ) { /* Ignore any leading ':'	    */
      label++;
   }

   label = make_label( label ); /* Convert to Label Format	    */

   batch->offset = 0L; /* rewind the batch file	    */
   batch->eof = NO;    /* So it cannot be EOF		    */

   if ( !batch_open() ) { /* Check the Batch file is open     */
      return;             /* and stop if the function fails.  */
   }

   while ( !batch->eof ) {  /* while not end of file read next  */
      batch_read( s, YES ); /* line and return the next command  */
      bp = deblank( s );
      if ( ( *bp == ':' ) &&
           !dr_strnicmp( make_label( bp + 1 ), label, 8 ) ) {
         return;
      }
   }

   batch_end();   /* Stop any further batch file	   */
   crlfflg = YES; /* processing and print the error  */
   eprintf( MSG_LABEL, label );
}

GLOBAL VOID CDECL cmd_gosub( REG BYTE *label ) /* gosub label in batch file */
{
   UWORD i;
   BYTE *bp, s[MAX_LINE + 2]; /* Allocate buffer for Batch Input  */

   if ( !batchflg ) { /* if not in batch mode 	    */
      return;         /* this command is ignored	    */
   }

   if ( batch->ret_offset[3] != 0L ) {
      batch_end();
      crlfflg = YES;
      eprintf( MSG_GOSUB );
      return;
   }

   if ( *label == ':' ) { /* Ignore any leading ':'	    */
      label++;
   }

   label = make_label( label ); /* Convert to Label Format	    */

   i = 0;
   while ( batch->ret_offset[i] != 0L ) {
      i++;
   }
   batch->ret_offset[i] = batch->offset;

   batch->offset = 0L; /* rewind the batch file	    */
   batch->eof = NO;    /* So it cannot be EOF		    */

   if ( !batch_open() ) { /* Check the Batch file is open     */
      return;             /* and stop if the function fails.  */
   }

   while ( !batch->eof ) {  /* while not end of file read next  */
      batch_read( s, YES ); /* line and return the next command  */
      bp = deblank( s );
      if ( ( *bp == ':' ) &&
           !dr_strnicmp( make_label( bp + 1 ), label, 8 ) ) {
         return;
      }
   }

   batch_end();   /* Stop any further batch file	   */
   crlfflg = YES; /* processing and print the error  */
   eprintf( MSG_LABEL, label );
}

GLOBAL VOID CDECL cmd_return( VOID )
{
   UWORD i;

   if ( !batchflg ) {
      return;
   }
   if ( batch->ret_offset[0] == 0L ) {
      batch_end();
      crlfflg = YES;
      eprintf( MSG_RETURN );
      return;
   }
   i = 0;
   while ( ( batch->ret_offset[i] != 0L ) && ( i < 4 ) ) {
      i++;
   }
   batch->offset = batch->ret_offset[i - 1];
   batch->ret_offset[i - 1] = 0L;
}

#if SWITCH_ENABLED
GLOBAL VOID CDECL cmd_switch( REG BYTE *list )
{
   BYTE *list_start;
   BYTE *label;
   WORD i, j;
   BYTE c;

   if ( !batchflg ) {
      return;
   }
   list_start = list;

switch_retry:
   list = list_start;
   i = psp_poke( STDIN, 1 );

   c = (BYTE)msdos( MS_C_RAWIN, 0 ); /* Get a character from console */
   if ( ( c == 0 ) || ( dbcs_lead( c ) ) ) {
      msdos( MS_C_RAWIN, 0 ); /* skip second byte in DBCS pair */
   }

   psp_poke( STDIN, i );

   if ( c == 0x03 ) {
      int_break(); /* check for CTRL-C */
   }
   if ( c == 0x0d ) {
      c = '1'; /* return gives default of 1 */
   }

   i = (WORD)( c - '1' );
   if ( i < 0 || i > 8 ) {
      goto switch_retry; /* ignore invalid keys */
   }

   j = 0;
   while ( j < i ) {
      while ( *list != ',' && *list != 0 ) {
         list++;
      }
      if ( *list == 0 ) {
         goto switch_retry;
      }
      j++;
      list++;
      list = deblank( list );
   }
   label = list;
   while ( *list != ',' && *list != 0 ) {
      list++;
   }
   *list = 0;
   cmd_gosub( label );
}
#endif

/*.pa*/
/*
 *	The IF command supports the following syntax:-
 *
 *	IF [NOT] string1 == string2 COMMAND
 *	IF [NOT] ERRORLEVEL n COMMAND
 *	IF [NOT] EXIST filename COMMAND
/*RG-02-
 *	IF [NOT] USERID n COMMAND
 *	IF [NOT] LOGINNAME string COMMAND
 *	IF [NOT] GROUPNAME string COMMAND
 *	IF [NOT] KEY ["string"] char COMMAND
 *
 */

MLOCAL BYTE *if_opt[] = { "exist", "direxist", "errorlevel", NULL };

/*RG-02-end*/

MLOCAL UWORD if_index( BYTE **cmd )
{
   UWORD i, j;

   for ( i = 0; if_opt[i]; i++ ) { /* Scan Through the option   */
      j = strlen( if_opt[i] );     /* list and return the index */
                                   /* of the matching option    */
      if ( dr_strnicmp( *cmd, if_opt[i],
                        j ) ) { /* and update the string     */
         continue;              /* pointer.		     */
      }
      *cmd = deblank( *cmd + j );

      while ( *( *cmd ) == '=' ) { /* Remove any "=" string     */
         ( *cmd )++;               /* present in the command    */
      }
      *cmd = deblank( *cmd ); /* Used by many install files*/
      break;
   }

   return i;
}

#define OP_EQ 0
#define OP_NE 1
#define OP_LE 2
#define OP_LT 3
#define OP_GE 4
#define OP_GT 5

MLOCAL WORD get_operator( BYTE *op )
{
   if ( op[0] == '=' ) {
      return ( OP_EQ );
   }
   if ( op[0] == '!' && op[1] == '=' ) {
      return ( OP_NE );
   }
   if ( op[0] == '<' ) {
      if ( op[1] == '>' ) {
         return ( OP_NE );
      }
      if ( op[1] == '=' ) {
         return ( OP_LE );
      }
      return ( OP_LT );
   }
   if ( op[0] == '>' ) {
      if ( op[1] == '=' ) {
         return ( OP_GE );
      }
      return ( OP_GT );
   }
   return ( -1 );
}

MLOCAL LONG get_decimal( BYTE *s )
{
   LONG total = 0;

   if ( *s == '#' ) {
      s++;
   }

   while ( *s >= '0' && *s <= '9' ) {
      total *= 10;
      total += (LONG)( *s - '0' );
      s++;
   }

   return ( total );
}

MLOCAL BOOLEAN CDECL test_cond( BYTE **cptr )
{
   BYTE *cmd, *str1, *str2, *ptr;
   DTA search;
   BOOLEAN not, cond, neg, is_user;
   BYTE level;
   BYTE c[] = " \n";
   WORD attr;
   UWORD userid;
   LONG val1, val2;
   BYTE quoteflag;

   cmd = *cptr;
   not = cond = NO; /* Initialise the Flags     */

   if ( !dr_strnicmp( cmd = deblank( cmd ), "not", 3 ) ) {
      not = YES;
      cmd = deblank( cmd + 3 );
   }

   switch ( if_index( &cmd ) ) {

   /*
	     *	EXIST Option extract the possibly ambiguous filename
	     *	and check if it exists.
	     */
   case 0:
      cmd = deblank( get_filename( heap(), cmd, YES ) );
      cond = !ms_x_first( heap(), ATTR_STD | ATTR_HID, &search );
      break;

   /*
	     * DIREXIST Option checks if the given directory exists
	     */
   case 1:
      cmd = deblank( get_filename( heap(), cmd, YES ) );
      attr = ms_x_chmod( heap(), ATTR_ALL, 0 );
      if ( attr < 0 ) {
         cond = FALSE;
      }
      else {
         cond = ( attr & 0x10 );
      }
      break;

   /*
	     *	ERRORLEVEL Option extract the decimal number from the
	     *	command line.
	     */
   case 2:
      level = 0;
      neg = FALSE;

      if ( *cmd == '-' ) {
         neg = TRUE;
         cmd++;
      }

      if ( !isdigit( *cmd ) &&
           !isalpha( *cmd ) ) { /* SYNTAX error if the	    */
         syntax();              /* first character is not a */
         return FALSE;          /* digit.		    */
      }

      if ( isdigit( *cmd ) ) {
         while ( isdigit( *cmd ) ) {
            level = level * 10 + ( *cmd++ - '0' );
         }
      }
      else {
         level = dr_tolower( *cmd++ ) - 'a' + 1;
      }

      level = level & 0x00FF;

      if ( neg ) {
         level = -level;
      }

      cond = ( level <= ( err_ret & 0x00FF ) );
      break;
   /*
	     *	String comparison option.
	     */
   default:
      str1 = cmd; /* Extract String 1	    */

      quoteflag = 0;
      while ( ( !is_blank( cmd ) || quoteflag ) && ( *cmd != '=' ) &&
              ( ( *cmd != '!' ) || ( cmd[1] != '=' ) ) && ( *cmd != '<' ) &&
              ( *cmd != '>' ) ) {
         if ( *cmd == '"' ) {
            quoteflag = !quoteflag;
         }
         cmd = skip_char( cmd );
      }

      str2 = cmd;
      cmd = deblank( cmd );

      attr = get_operator( cmd++ );

      if ( attr == -1 ) {
         syntax();
         return ( FALSE );
      }

      *str2 = 0;

      if ( *cmd == '=' || *cmd == '>' ) {
         cmd++;
      }

      cmd = deblank( cmd );
      str2 = cmd;
      quoteflag = 0;
      while ( !is_blank( cmd ) || quoteflag ) {
         if ( *cmd == '"' ) {
            quoteflag = !quoteflag;
         }
         cmd = skip_char( cmd );
      }
      *cmd++ = 0;

      if ( *str1 == '#' ) {
         val1 = get_decimal( str1 );
         val2 = get_decimal( str2 );
         switch ( attr ) {
         case OP_EQ:
            cond = ( val1 == val2 );
            break;
         case OP_NE:
            cond = ( val1 != val2 );
            break;
         case OP_LT:
            cond = ( val1 < val2 );
            break;
         case OP_LE:
            cond = ( val1 <= val2 );
            break;
         case OP_GT:
            cond = ( val1 > val2 );
            break;
         case OP_GE:
            cond = ( val1 >= val2 );
            break;
         }
      }
      else {
         switch ( attr ) {
         case OP_EQ:
            cond = ( strcmp( str1, str2 ) == 0 );
            break;
         case OP_NE:
            cond = ( strcmp( str1, str2 ) != 0 );
            break;
         case OP_LT:
            cond = ( strcmp( str1, str2 ) < 0 );
            break;
         case OP_LE:
            cond = ( strcmp( str1, str2 ) <= 0 );
            break;
         case OP_GT:
            cond = ( strcmp( str1, str2 ) > 0 );
            break;
         case OP_GE:
            cond = ( strcmp( str1, str2 ) >= 0 );
            break;
         }
      }
      break;
   }

   if ( not ) { /* if negated condition     */
      cond = !cond;
   }

   *cptr = cmd;
   return cond; /* write result back */
}

#if !defined( NOXBATCH )
BOOLEAN is_it_or( BYTE *cmd )
{
   cmd--;
   if ( ( *cmd != 0 ) && ( *cmd != '\t' ) && ( *cmd != ' ' ) ) {
      return FALSE;
   }
   cmd++;
   if ( dr_strnicmp( cmd, "or", 2 ) != 0 ) {
      return FALSE;
   }
   cmd += 2;
   if ( ( *cmd != '\t' ) && ( *cmd != ' ' ) ) {
      return FALSE;
   }
   return TRUE;
}
#endif
GLOBAL VOID CDECL cmd_if( BYTE *cmd )
{
   BOOLEAN cond;

   ifcond = cond = test_cond( &cmd );

   if ( !*deblank( cmd ) ) { /* and return a SYNTAX error*/
      syntax();              /* if it is empty.	    */
      return;
   }
   if ( !cond ) {
#if !defined( NOXBATCH )
      while ( !is_it_or( cmd ) && ( *cmd != 0 ) ) {
         if ( dr_strnicmp( cmd, "ECHO", 4 ) == 0 ) {
            return;
         }
         cmd++;
      }
      if ( *cmd == 0 ) {
         return; /* no OR's so quit now */
      }

      if_context = TRUE;

      docmd( deblank( cmd ), YES ); /* New command starts at "or" */

#endif
   }
   else {
      cmd = deblank( cmd );

      if ( dr_strnicmp( cmd, "AND", 3 ) ) {
         if ( parse( cmd ) ) {
            return; /* IF won't have been 'parsed' for */
         }
         /* > or < redirectors so do it now */
      }

      if_context = TRUE;
      /* Execute command if the    */
      docmd( cmd, YES ); /* condition flag is TRUE    */
   }
   if_context = FALSE;
}

/*RG-03*/
#if !defined( NOXBATCH )
GLOBAL VOID CDECL cmd_or( BYTE *cmd )
{
   BOOLEAN cond;
   BYTE *org_cmd;

   cond = test_cond( &cmd );
   if ( !*deblank( cmd ) ) { /* and return a SYNTAX error*/
      syntax();              /* if it is empty.	    */
      return;
   }
   if ( !cond ) {
      org_cmd = cmd; /* now look for "OR" */
      while ( !is_it_or( cmd ) && ( *cmd != 0 ) ) {
         if ( dr_strnicmp( cmd, "ECHO", 4 ) == 0 ) {
            while ( *cmd ) {
               cmd++;
            }
         }
         else {
            cmd++;
         }
      }
      if ( *cmd == 0 ) { /* oh dear, no ORs */
         if ( ifcond ) { /* but so far so good, so do command anyway */
            docmd( deblank( org_cmd ), YES );
         }
         return;
      }
      docmd( deblank( cmd ), YES ); /* New command starts at "or" */
      return;
   }
   else {
      cmd = deblank( cmd );

      if ( dr_strnicmp( cmd, "AND", 3 ) ) {
         if ( parse( cmd ) ) {
            return; /* IF won't have been 'parsed' for */
         }
         /* > or < redirectors so do it now */
      }

      ifcond = cond;     /* Execute command if the    */
      docmd( cmd, YES ); /* condition flag is TRUE    */
   }
}
#endif /*NOXBATCH*/
/*RG-03-end*/

GLOBAL VOID CDECL cmd_for( BYTE *s )
{
   FCONTROL *fc;
   BYTE *bp1;

   fc = (FCONTROL *)heap_get( sizeof( FCONTROL ) );

   /* Allocate Control Struct  */
   if ( forptr ) {    /* and prevent nesting of  */
      goto for_error; /* FOR Command. 	   */
   }

   s = deblank( s );                    /* Remove leading blanks   */
   if ( ( *s++ != '%' ) ||              /* Get the FOR variable    */
        ( fc->forvar = *s++ ) < ' ' ) { /* character and save	   */
      goto for_error;
   }

   if ( dr_strnicmp( s = deblank( s ), "in",
                     2 ) ) { /* Check for the correct   */
      goto for_error;        /* command syntax.	   */
   }

   s = deblank( s + 2 );
   if ( *s++ != '(' ) {
      goto for_error;
   }

   fc->files = (BYTE *)heap();            /* Allocate FOR parameter  */
   while ( *s && *s != ')' ) {            /* buffer and scan the	   */
      bp1 = (BYTE *)heap();               /* command line generating */
                                          /* zero terminated strings */
      while ( strchr( batch_sep, *s ) ) { /* Skip any separators	   */
         s = skip_char( s );
      }

      while ( *s != ')' &&                 /* then copy all valid	   */
              !strchr( batch_sep, *s ) ) { /* characters into buffer  */
                                           /* then zero terminate	   */
         copy_char( &bp1, &s );
      }

      *bp1++ = '\0';
      heap_get( strlen( heap() ) + 1 ); /* Preserve String	    */
   }

   *(BYTE *)heap_get( 1 ) = '\0'; /* Final String is zero     */
                                  /* bytes in length	    */

   s = deblank( s );
   if ( *s++ != ')' ) {
      goto for_error;
   }

   if ( dr_strnicmp( s = deblank( s ), "do", 2 ) ) {
      goto for_error;
   }

   if ( in_flag & REDIR_ACTIVE ) { /* If Input redirection has been */
      in_flag |= REDIR_FOR;        /* enabled for this command force*/
   }
   /* it on for the complete command*/

   if ( out_flag & REDIR_ACTIVE ) { /* If Output redirection has been*/
      out_flag |= REDIR_FOR;        /* enabled for this command force*/
   }
   /* it on for the complete command*/

   fc->cmd = (BYTE *)heap_get( strlen( s = deblank( s + 2 ) ) + 1 );
   strcpy( fc->cmd, s );

   fc->sflg = NO;  /* File matching inactive  */
   for_flag = YES; /* Turn FOR processing ON  */
   forptr = fc;    /* Save control Structure  */
   return;

for_error:                 /* When a Syntax error occurs	*/
   heap_set( (BYTE *)fc ); /* restore the heap and print	*/
   syntax();               /* an error message.		*/
   return;
}

GLOBAL VOID for_end( VOID )
{
   if ( for_flag ) {
      heap_set( (BYTE *)forptr ); /* Terminate FOR processing	*/
      forptr = (FCONTROL *)NULL;  /* restore the HEAP and reset	*/
      for_flag = NO;              /* control flags.		*/
   }
}

/*.pa*/
/*
 *	This command generates the displayed prompt based on the contents
 *	of the string PROMPT= in the environment. Otherwise the default
 *	prompt string DEFAULT_PROMPT is used.
 */

MLOCAL BOOLEAN prompt_flg = FALSE; /* Prompt Flag 			*/

MLOCAL VOID prompt( VOID ) /* display command line prompt	*/
{
   REG BYTE *cp;
   BYTE buf[MAX_PATHLEN];
   BYTE c;
#if !STACK
   BYTE cpbuf[MAX_ENVLEN];
#endif
/*rbf*/
#if 1
   BYTE prmptcpbuf[MAX_ENVLEN];
   REG BYTE *prmptcp = prmptcpbuf;
#endif

   if ( !echoflg ) { /* Return if No Echo	*/
      return;
   }

   if ( env_scan( msg_prmeq, cp = (BYTE *)heap() ) ) {
      strcpy( cp, DEFAULT_PROMPT );
   }

   if ( prompt_flg ) {      /* If the previous Prompt display   */
      strcpy( cp, "$n$g" ); /* terminated due to a Critical	    */
   }
   /* then just display the default    */
   prompt_flg = TRUE; /* drive.			    */

#if STACK
   cp = stack( strlen( cp ) + 1 );
#else
   cp = &cpbuf[0];
#endif
   strcpy( cp, heap() );

   while ( ( c = *cp++ ) != 0 ) { /* get next character */
      if ( c != '$' ) {           /* if not '$', print as is */
         putc( c );
      }
      else {
         c = *cp++;
         switch ( dr_tolower( c ) ) { /* else get next character */
         case '\0':                   /* Treat "$\0" as an invalid 	    */
            cp--;                     /* prompt command sequence	    */
            break;
         case 't': /* print current time */
            disp_systime();
            break;
         case 'd': /* print current date */
            disp_sysdate();
            break;
         case 'p': /* print current path */
            if ( ms_x_curdir( drive + 1, buf ) < 0 ) {
               printf( MSG_DRV_INVALID );
            }
            else {
               printf( "%c:%s%s", drive + 'A', pathchar, buf );
            }
            break;
         case 'v': /* print version number */
            cmd_ver( "" );
            break;
         case 'n': /* print default drive */
            putc( (BYTE)drive + 'A' );
            break;
         case 'g': /* print ">" */
            putc( '>' );
            break;
         case 'l': /* print "<" */
            putc( '<' );
            break;
         case 'b': /* print "|" */
            putc( '|' );
            break;
         case 'q': /* print "=" */
            putc( '=' );
            break;
         case '_': /* print CR,LF */
            crlf();
            break;
         case 'h': /* print backspace, space, backspace */
            printf( "\b \b" );
            break;
         case 'e': /* print ESC character */
            putc( '\33' );
            break;
         case 'u':
            if ( !env_scan( "LOGINNAME=", heap() ) ) {
               printf( "%s", heap() );
            }
            break;
         case '$':
            putc( '$' ); /* print single '$' */
            break;
         case 'x':
            if ( ( allow_pexec ) && ( !batchflg ) ) {
               prompt_exec();
            }
            break;
         default: /* Otherwise the character */
            break;
         }
      }
   }

   prompt_flg = FALSE; /* Prompt display completed OK	*/
}

/* The following functions are called by the int2e_handler function in
 * COM.C. If a program is run from a batch file and calls INT 2E to
 * execute a new batch file the original batch file must NOT be terminated.
 * Therefore batch and batchflg must be saved, set to zero, and then
 * restored when INT 2E returns. - EJH 
 */

GLOBAL VOID int2e_start( VOID )
{
   batchflg_save = batchflg;
   batchflg = 0;
   batch_save = batch;
   echoflg_save = echoflg;
   echoflg = ECHO_ON;
}

GLOBAL VOID int2e_finish( VOID )
{
   batchflg = batchflg_save;
   batch = batch_save;
   echoflg = echoflg_save;
}

EXTERN N_CMD novell_ext_list[];

EXTERN BYTE FAR *CDECL farptr( BYTE * );
EXTERN BYTE FAR *CDECL cgroupptr( BYTE * );

EXTERN BOOLEAN CDECL call_novell( BYTE *, BYTE *, WORD );
EXTERN BOOLEAN CDECL nov_station( WORD * );
EXTERN WORD CDECL nov_connection();

MLOCAL BOOLEAN novell_extension( BYTE *src, BYTE *dst )
/*
 * Check if src string is a novell string to be expanded. eg login_name.
 * if so, put expansion in dst.
 */
{
   N_CMD FAR *n_cmd_p;
   BYTE FAR *cpf;
   WORD i;

   for ( i = 0; src[i] && src[i] != '='; i++ )
      ;
   src[i] = 0;

   n_cmd_p = (N_CMD FAR *)farptr( (BYTE *)&novell_ext_list[0] );

   while ( n_cmd_p->string ) {

      /*	    cpf = cgroupptr(n_cmd_p->string);*/
      cpf = (BYTE FAR *)n_cmd_p->string;

      for ( i = 0; ( cpf[i] == src[i] ) && src[i]; i++ )
         ;

      if ( cpf[i] == src[i] ) {
         ( *n_cmd_p->func )( dst );
         return ( 0 );
      }

      n_cmd_p++;
   }
   return ( 1 );
}

GLOBAL VOID CDECL get_login_name( BYTE *dst )
{
   struct s_nov_e346_in {
      WORD len;
      BYTE code;
   } nov_e346_in;
   struct s_nov_e346_out {
      WORD len;
      BYTE level;
      LONG id;
   } nov_e346_out;
   struct s_nov_e336_in {
      WORD len;
      BYTE code;
      LONG id;
   } nov_e336_in;
   struct s_nov_e336_out {
      WORD len;
      LONG id;
      WORD type;
      BYTE name[48];
   } nov_e336_out;

   nov_e346_in.len = 1;
   nov_e346_in.code = 0x46;
   nov_e346_out.len = 5;
   nov_e346_out.id = -1L;
   call_novell( (BYTE *)&nov_e346_in, (BYTE *)&nov_e346_out, 0xE3 );

   if ( nov_e346_out.id == -1L ) {
      *dst = 0;
      return;
   }

   nov_e336_in.len = 5;
   nov_e336_in.code = 0x36;
   nov_e336_in.id = nov_e346_out.id;
   nov_e336_out.len = 54;
   call_novell( (BYTE *)&nov_e336_in, (BYTE *)&nov_e336_out, 0xE3 );

   strcpy( dst, nov_e336_out.name );
}

GLOBAL VOID CDECL get_pstation( BYTE *dst )
{
   WORD sn[3];

   if ( nov_station( sn ) ) {
      *dst = 0;
      return;
   }

   sprintf( dst, "%04X%04X%04X", sn[0], sn[1], sn[2] );
}

GLOBAL VOID CDECL get_full_name( BYTE *dst )
{
   /* scan bindery */
   struct s_nov_e337_in {
      WORD len;
      BYTE code;
      LONG last_object_id;
      WORD object_type;
      BYTE object_name_len;
      BYTE object_name[48];
   } nov_e337_in;

   struct s_nov_e337_out {
      WORD len;
      LONG object_id;
      WORD object_type;
      BYTE object_name[48];
      BYTE object_flag;
      BYTE object_security;
      BYTE object_has_properties;
   } nov_e337_out;

   /* scan property */
   struct s_nov_e33c_in {
      WORD len;
      BYTE code;
      WORD object_type;
      BYTE object_name_len;
      BYTE object_name[48];
      LONG sequence_num;
      BYTE property_name_len;
      BYTE property_name[16];
   } nov_e33c_in;

   struct s_nov_e33c_out {
      WORD len;
      BYTE property_name[16];
      BYTE property_flags;
      BYTE property_security;
      LONG sequence_num;
      BYTE property_has_value;
      BYTE more_properties;
   } nov_e33c_out;

   /* read property */
   struct s_nov_e33d_in {
      WORD len;
      BYTE code;
      WORD object_type;
      BYTE object_name_len;
      BYTE object_name[48];
      BYTE segment_num;
      BYTE property_name_len;
      BYTE property_name[16];
   } nov_e33d_in;

   struct s_nov_e33d_out {
      WORD len;
      BYTE property_value[128];
      BYTE more_segments;
      BYTE property_flags;
   } nov_e33d_out;

   int res;

   get_login_name( nov_e337_in.object_name );
   nov_e337_in.object_name_len = strlen( nov_e337_in.object_name );
   if ( !nov_e337_in.object_name_len ) {
      *dst = 0;
      return;
   }

   nov_e337_in.code = 0x37;
   nov_e337_in.len = sizeof( struct s_nov_e337_in ) - 2;
   nov_e337_out.len = sizeof( struct s_nov_e337_out ) - 2;
   nov_e337_in.last_object_id = -1L;
   nov_e337_in.object_type = 0x0100; /*user*/

   for ( ;; ) {
      res = call_novell( (BYTE *)&nov_e337_in, (BYTE *)&nov_e337_out, 0xe3 );
      if ( res == 0xfc ) {
         break;
      }
      else if ( res ) {
         *dst = 0;
         return;
      }

      if ( nov_e337_out.object_has_properties ) {
         nov_e33c_in.code = 0x3c;
         nov_e33c_in.len = sizeof( struct s_nov_e33c_in ) - 2;
         nov_e33c_out.len = sizeof( struct s_nov_e33c_out ) - 2;
         nov_e33c_in.object_type = nov_e337_out.object_type;
         nov_e33c_in.object_name_len = sizeof( nov_e33c_in.object_name );
         strcpy( nov_e33c_in.object_name, nov_e337_out.object_name );
         nov_e33c_in.sequence_num = -1L;
         nov_e33c_in.property_name_len = 1;
         nov_e33c_in.property_name[0] = '*';

         for ( ;; ) {
            res = call_novell( (BYTE *)&nov_e33c_in, (BYTE *)&nov_e33c_out,
                               0xe3 );
            if ( res == 0xfb ) {
               break;
            }
            else if ( res ) {
               *dst = 0;
               return;
            }

            if ( nov_e33c_out.property_has_value ) {
               nov_e33d_in.code = 0x3d;
               nov_e33d_in.len = sizeof( struct s_nov_e33d_in ) - 2;
               nov_e33d_out.len = sizeof( struct s_nov_e33d_out ) - 2;
               nov_e33d_in.object_type = nov_e337_out.object_type;
               nov_e33d_in.object_name_len =
                  sizeof( nov_e33d_in.object_name );
               strcpy( nov_e33d_in.object_name, nov_e337_out.object_name );
               nov_e33d_in.segment_num = 1;
               nov_e33d_in.property_name_len =
                  strlen( nov_e33c_out.property_name );
               strcpy( nov_e33d_in.property_name,
                       nov_e33c_out.property_name );
               for ( ;; ) {
                  res = call_novell( (BYTE *)&nov_e33d_in,
                                     (BYTE *)&nov_e33d_out, 0xe3 );
                  if ( res == 0xec ) {
                     break;
                  }
                  else if ( res ) {
                     *dst = 0;
                     return;
                  }

                  if ( !strcmp( nov_e33c_out.property_name,
                                "IDENTIFICATION" ) ) {
                     strcpy( dst, nov_e33d_out.property_value );
                     return;
                  }
                  nov_e33d_in.segment_num++;
               } /*for*/
            }    /*if*/
            nov_e33c_in.sequence_num = nov_e33c_out.sequence_num;
         } /*for*/
         nov_e337_in.last_object_id = nov_e337_out.object_id;
      } /*if*/
   }    /*for*/
}

GLOBAL VOID CDECL get_hour( BYTE *dst )
{
   SYSTIME time;

   ms_gettime( &time );

   if ( time.hour > 12 ) {
      time.hour -= 12;
   }
   if ( time.hour == 0 ) {
      time.hour = 12;
   }

   sprintf( dst, "%d", time.hour );
}

GLOBAL VOID CDECL get_hour24( BYTE *dst )
{
   SYSTIME time;

   ms_gettime( &time );

   sprintf( dst, "%02d", time.hour );
}

GLOBAL VOID CDECL get_hour2( BYTE *dst )
{
   SYSTIME time;

   ms_gettime( &time );

   sprintf( dst, "%d", time.hour );
}

GLOBAL VOID CDECL get_minute( BYTE *dst )
{
   SYSTIME time;

   ms_gettime( &time );

   sprintf( dst, "%02d", time.min );
}

GLOBAL VOID CDECL get_second( BYTE *dst )
{
   SYSTIME time;

   ms_gettime( &time );

   sprintf( dst, "%02d", time.sec );
}

GLOBAL VOID CDECL get_am_pm( BYTE *dst )
{
   SYSTIME time;
   BYTE FAR *p;

   ms_gettime( &time );

   if ( time.hour >= 12 ) {
      p = cgroupptr( PM_TIME );
   }
   else {
      p = cgroupptr( AM_TIME );
   }

   while ( *p ) {
      *dst++ = *p++;
   }
   *dst = 0;
}

GLOBAL VOID CDECL get_greeting( BYTE *dst )
{
   SYSTIME time;
   BYTE FAR *p;

   ms_gettime( &time );

   if ( time.hour < 12 ) {
      p = cgroupptr( GREETING_MORNING );
   }
   else if ( time.hour < 17 ) {
      p = cgroupptr( GREETING_AFTERNOON );
   }
   else {
      p = cgroupptr( GREETING_EVENING );
   }

   while ( *p ) {
      *dst++ = *p++;
   }
   *dst = 0;
}

GLOBAL VOID CDECL get_year( BYTE *dst )
{
   SYSDATE date;

   ms_getdate( &date );

   sprintf( dst, "%d", date.year );
}

GLOBAL VOID CDECL get_short_year( BYTE *dst )
{
   SYSDATE date;

   ms_getdate( &date );

   sprintf( dst, "%d", date.year % 100 );
}

GLOBAL VOID CDECL get_month( BYTE *dst )
{
   SYSDATE date;

   ms_getdate( &date );

   sprintf( dst, "%d", date.month );
}

GLOBAL VOID CDECL get_moy( BYTE *dst )
{
   SYSDATE date;

   ms_getdate( &date );

   sprintf( dst, "%02d", date.month );
}

GLOBAL VOID CDECL get_month_name( BYTE *dst )
{
   SYSDATE date;
   BYTE *m;

   ms_getdate( &date );

   switch ( date.month ) {
   case 1:
      m = JAN_M;
      break;
   case 2:
      m = FEB_M;
      break;
   case 3:
      m = MAR_M;
      break;
   case 4:
      m = APR_M;
      break;
   case 5:
      m = MAY_M;
      break;
   case 6:
      m = JUN_M;
      break;
   case 7:
      m = JUL_M;
      break;
   case 8:
      m = AUG_M;
      break;
   case 9:
      m = SEP_M;
      break;
   case 10:
      m = OCT_M;
      break;
   case 11:
      m = NOV_M;
      break;
   case 12:
      m = DEC_M;
      break;
   }

   sprintf( dst, "%s", m );
}

GLOBAL VOID CDECL get_day( BYTE *dst )
{
   SYSDATE date;

   ms_getdate( &date );

   sprintf( dst, "%d", date.day );
}

GLOBAL VOID CDECL get_dom( BYTE *dst )
{
   SYSDATE date;

   ms_getdate( &date );

   sprintf( dst, "%02d", date.day );
}

GLOBAL VOID CDECL get_nday_of_week( BYTE *dst )
{
   SYSDATE date;

   ms_getdate( &date );

   sprintf( dst, "%d", date.dow + 1 );
}

GLOBAL VOID CDECL get_day_of_week( BYTE *dst )
{
   SYSDATE date;

   ms_getdate( &date );

   sprintf( dst, "%s", day_names( date.dow ) );
}

GLOBAL VOID CDECL get_os_version( BYTE *dst ) { env_scan( "VER=", dst ); }

GLOBAL VOID CDECL get_connection( BYTE *dst )
{
   int i;

   i = nov_connection();
   if ( i == -1 ) {
      *dst = 0;
      return;
   }

   sprintf( dst, "%d", i );
}

GLOBAL VOID CDECL get_errorlevel( BYTE *dst )
{
   sprintf( dst, "%d", err_ret & 255 );
}

GLOBAL VOID CDECL get_errorlvl( BYTE *dst )
{
   sprintf( dst, "%03d", err_ret & 255 );
}

GLOBAL VOID CDECL get_codepage( BYTE *dst )
{
   UWORD currentcp, defaultcp;

   ms_x_getcp( &currentcp, &defaultcp );

   sprintf( dst, "%d", currentcp );
}

GLOBAL VOID CDECL get_country( BYTE *dst )
{
   country.code = ms_s_country( &country );

   sprintf( dst, "%d", country.code );
}

GLOBAL VOID CDECL get_rows( BYTE *dst )
{
   UWORD rows;

   rows = get_lines_page();

   sprintf( dst, "%d", rows );
}

GLOBAL VOID CDECL get_columns( BYTE *dst )
{
   UWORD columns;

   columns = get_scr_width();

   sprintf( dst, "%d", columns );
}
