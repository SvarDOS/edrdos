/*   File              : $Workfile: COM.C$
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
 *   COM.C 1.2 97/03/21 14:41:21
 *   Added /n option to disable critical error handler
 *   COM.C 1.59 94/12/01 10:05:21
 *   Removed closing handles 5 and 6 in error_code() in order to be able
 *   to continue with a batch file if the user wants to. JBEULICH
 *   Enabled UNC filenames
 *   COM.C 1.58 94/08/10 14:49:22 
 *   After first run through looking for a file to execute, now strips the D:
 *   off the path, if only a drive and not a directory is specified. So, if you
 *   type D:TEST, it will look for TEST on the current directory of drive D:, then
 *   continue to search the path. It will only skip searching the path if a
 *   specific directory is specified.
 *   COM.C 1.57 94/03/29 16:12:11 
 *   docmd_int2f in CSTART.ASM returns 1 if it has been accepted.
 *   In this case, we don't want it, so docmd_offer returns TRUE.
 *   All cases of docmd_offer return if TRUE, so we don't process
 *   the line ourselves.
 *   COM.C 1.56 94/02/08 11:50:17
 *   Fixed a problem where typing COMMAND DIR A: after giving the correct error
 *   message for DIR being an incorrect loadpath, tries to access A: and crashes
 *   under /MULTI.
 *   Break added after error message to fix crashing problem.
 *   Variable lferror added so that after an incorrect loadpath, it does not use
 *   the next bit (ie. A:) as keyboard input.
 *   COM.C 1.54 93/12/09 18:07:04 
 *   Fixed a bug which screwed the upper memory link if you entered c:lh dir
 *   COM.C 1.53 93/12/01 23:14:02 
 *   Fix parsing bug "<infile >outfile command" would fail
 *   COM.C 1.49 93/12/01 11:32:08
 *   Now do a flush cache call before displaying prompt.
 *   COM.C 1.48 93/12/01 00:17:17
 *   docmd_offer() will do an int 2F/AE (2 if external) within batch files
 *   SPR: 811218, shouldn't access drive whatever the prompt
 *   COM.C 1.45 93/11/19 21:08:14
 *   Put code to report "Syntax Error" for "| command" and "command |" back to
 *   it's original state.   
 *   COM.C 1.43 93/11/08 23:59:19
 *   F8 key now only affects autoexec, not 1st batch file
 *   COM.C 1.42 93/11/05 13:03:00
 *   Fix problem with /P /MH (missing break;....)
 *   COM.C 1.41 93/11/05 00:44:07
 *   /MU option only valid with /P option. The problem is if you "exit" with upper
 *   memory unlinked the resident portion isn't freed, and you eat upper memory.
 *   COM.C 1.40 93/10/29 17:05:51
 *   Add PROMPT=$P$G and PATH=d:\NWDOS to default env
 *   COM.C 1.39 93/10/22 11:51:30
 *   Changed Beta string from 3 to 4
 *   COM.C 1.36 93/09/15 18:56:39
 *   FOR command now allows any char in brackets. eg for %%v in (+ -) do...
 *   COM.C 1.34 93/08/26 09:39:05
 *   Now use PSP for stack during func 4b exec. There's some debug
 *   code in case things screw up.
 *   COM.C 1.30 93/07/05 08:32:57 
 *   Memory allocation strategy now restored if ctrl-c pressed during a hiload.
 *   COM.C 1.25 93/05/24 11:34:43 
 *   psp now points to itself when /P isn't specified. 
 *   COM.C 1.24 93/05/17 11:22:28
 *   Added support for F5 and F8 being pressed during boot-up.  
 *   COM.C 1.23 93/04/22 14:51:10 
 *   Now close handles 5-19 after an exec.
 *   echoflg is now correctly preserved when batch files are chained. See
 *   echoflg_save2.
 *   COM.C 1.19 93/01/21 14:29:44
 *   Now do INT 21 ah=29 when changing default drive.
 *   COM.C 1.16 92/11/25 09:30:15
 *   Password support enabled/disabled by #if defined(PASSWORD) statements.
 *   HOMEDIR support disabled.
 *   COM.C 1.12 92/09/25 19:48:56
 *   Removed .cmd from search order if DOSPLUS defined.
 *   Fixed bug when ;; appears in path.
 *   COM.C 1.11 92/09/17 11:30:14 
 *   Piping a batch file through MORE no longer stops with Syntax Error
 *   displayed.
 *   COM.C 1.10 92/09/11 10:43:41
 *   COMMAND /P: disables time and date prompt and copyright message.
 *   COMMAND ? no longer hangs.
 *   ENDLOG
 */

#include "defines.h"

#if 0
#if defined(DLS)
#define	MSG_VER		111		/* required message file version No. */
#else
#define	MSG_VER		msg_ver111	/* required message file version No. */
extern char 		*MSG_VER;
#endif
#endif


#include	<setjmp.h>
#include	<string.h>

#if defined(MWC) && defined(strlen)
#undef strcmp			/* These are defined as macros in string.h */
#undef strcpy			/* which are expaneded in line under */
#undef strlen			/* Metaware C. These undefs avoid this. */
#endif

#include	<portab.h>
#include	<mserror.h>
#if !defined(DOSPLUS)
#include	<ccpm.h>
#include	<sysdat.h>
#endif

#include	"command.h"		/* Command Definitions		*/
#include	"support.h"		/* Support routines		*/
#include	"dos.h" 		/* MSDOS function definitions	*/
#include	"dosif.h"		/* DOS interface definitions	*/
#include	"toupper.h"
#include	"global.h"		/* Global Variables		*/

/* RG-00- */
#define	PATH_LEN	    65		 /* max path length (null terminated) */
#if !defined(NOSECURITY) && (defined(CDOSTMP) || defined(CDOS))
#include	<pd.h>
#include	"security.h"
#include	"login.h"
#endif
/* RG-00- end */

MLOCAL BYTE	valid_sepchar[] = ":.;,=+";


#if defined(DOSPLUS)			/* we now define initial  */
MLOCAL BYTE PATH_DIR[]  = "A:\\OPENDOS";
MLOCAL BYTE SET_PATH[]  = "PATH=%s";
MLOCAL BYTE SET_PROMPT[]  = "PROMPT=$P$G";
MLOCAL BYTE SET_OS[]   = "OS=OPENDOS";	/* environment in COMMAND */
MLOCAL BYTE SET_VER[]  = "VER=7";	/* not in BIOSINIT        */
#if !defined(FINAL)
MLOCAL BYTE SET_BETA[] = "BETA=Beta 4";
#endif
#endif

GLOBAL jmp_buf break_env;

#if defined(DOSPLUS)
EXTERN	UWORD	_psp;
EXTERN	VOID	*batchptr_off;
EXTERN	VOID	*batchflg_off;
EXTERN	VOID	*echoflg_off;
EXTERN	UWORD	FAR *batch_seg_ptr;
#endif

/*RG-03*/
EXTERN BOOLEAN  if_context;         /* BATCH.C */
/*RG-03-end*/


#if defined(DOSPLUS)
EXTERN	VOID	CDECL show_help(WORD);		/* CSTART.ASM */
EXTERN	VOID	CDECL put_resident_high(WORD);	/* CSTART.ASM */
EXTERN	BYTE FAR * CDECL get_config_env(VOID);	/* CTSART.ASM */
EXTERN	UWORD	CDECL get_original_envsize(VOID);
EXTERN	VOID	CDECL copy_crit_msgs(VOID);	/* CSUP.ASM */
EXTERN	VOID	CDECL copy_rld_msgs(VOID);	/* CSUP.ASM */
EXTERN	WORD	CDECL dos_parse_filename(BYTE *);
EXTERN	UWORD 	CDECL docmd_int2f(BYTE *, BYTE *, UWORD);
#endif
EXTERN	void	CDECL flush_cache(void);

EXTERN BYTE 	*kbdptr;
EXTERN BYTE msg_patheq[];	/* Static Environ String "PATH="	*/
EXTERN S_CMD	cmd_list[];			/* CMDLIST.C		*/

#if defined(DOSPLUS)
EXTERN VOID inherit_parent_state();
#endif

EXTERN WORD echoflg_save2;
EXTERN VOID batch_start(BYTE *, BYTE *, BYTE *);
EXTERN VOID batch_end(VOID);		/* BATCH.C		*/
EXTERN VOID batch_endall(VOID);		/* BATCH.C		*/
EXTERN VOID batch_close(VOID);		/* BATCH.C		*/
EXTERN VOID for_end(VOID);		/* BATCH.C		*/
EXTERN BOOLEAN getcmd(BYTE *);		/* BATCH.C		*/
#if !defined(CDOSTMP)
EXTERN VOID int2e_start();		/* BATCH.C		*/
EXTERN VOID int2e_finish();		/* BATCH.C		*/
#endif

EXTERN VOID CDECL cmd_cd(BYTE *);	/* COMINT.C		*/     
EXTERN VOID CDECL cmd_ver();		/* COMINT.C		*/
EXTERN VOID CDECL cmd_set(BYTE *);	/* COMINT.C		*/

GLOBAL VOID docmd(BYTE *, BOOLEAN);		/* COM.C		*/
MLOCAL VOID cmd_loop (BYTE *);			/* COM.C		*/
MLOCAL VOID error_code(UWORD);			/* COM.C		*/

MLOCAL VOID cmd_cleantp(VOID);			/* COM.C		*/
GLOBAL BOOLEAN parse(BYTE *);			/* COM.C		*/
MLOCAL VOID init(BYTE *);			/* COM.C		*/
MLOCAL BOOLEAN doexec(BYTE *, BYTE *, UWORD, BYTE *);

#if !defined(CDOSTMP)
MLOCAL BYTE msg_comspec[] = "COMSPEC=";
/*EXTERN BYTE *reload_file;			   CSTART.ASM	 */

EXTERN VOID CDECL get_reload_file(VOID);	/* CSUP.ASM */
EXTERN VOID CDECL set_reload_file(VOID);	/* CSUP.ASM */
EXTERN VOID CDECL get_out_pipe(VOID);		/* CSUP.ASM */

EXTERN VOID CDECL install_perm(VOID);		   /* CSTART.ASM	 */ 
EXTERN VOID CDECL master_env(UWORD);		   /* CSTART.ASM	 */ 
GLOBAL WORD CDECL findfile(BYTE *, UWORD *);	   /* COM.C for MS-DOS	 */
MLOCAL WORD checkfile(BYTE *, UWORD *, BYTE *, BYTE *, BYTE *, BYTE *);
EXTERN BYTE cbreak_ok;		/* control break handler initialised */
#else
EXTERN WORD CDECL findfile(BYTE *, UWORD *);	    /* DOSIF.A86 (P_PATH) */
EXTERN VOID network_init(VOID);			    /* NETWORK.C	  */
EXTERN PD FAR * CDECL pd;			/* Far pointer to Current PD */
MLOCAL BOOLEAN system_init = TRUE;
#endif
EXTERN BYTE FAR * CDECL farptr(BYTE *);
EXTERN BYTE FAR * CDECL cgroupptr(BYTE *);

#if defined(CPM)
EXTERN UWORD CDECL cpm_init(VOID);		/* CP/M Init Routine	*/
#endif

#if !defined(NOSECURITY) && (defined(CDOSTMP) || defined(CDOS))
/* global VC data */
UWORD   vc_base;    /* first vc number for this station */
UWORD   num_of_vcs; /* number of vcs on this station */
#endif

#if !defined(CDOSTMP)
BYTE	autoexec_name[13] = "autoexec.bat";
#endif

#if defined(DOSPLUS)
UWORD	boot_key_scan_code = 0;
#endif

#if !defined(FINAL)
void	save_psp(void);
void	check_psp(void);
WORD	psp_xsum;
#endif

VOID FAR CDECL _main(cmd)
BYTE	*cmd;
{
	BYTE    cmd_buf[128];

#if defined(CDOSTMP)				/* Insure the NETWORK_INIT   */
	network_init();				/* function is called before */
#endif						/* any disk activity so that */
						/* Diskless DRNET systems can*/
						/* be generated.	     */

#if !defined(NOSECURITY) && (defined(CDOSTMP) || defined(CDOS))
        /* get the VC data and make global */
        vc_data(&vc_base, &num_of_vcs, &station);
#endif

#if defined(DOSPLUS) && defined(DLS)
	copy_crit_msgs();
	copy_rld_msgs();
#endif

 	init(cmd);				/* Initialize COMMAND.???    */

#if defined(CPM)
	if(cpm_init()) {			/* If this is the CP/M Media */
	    eprintf(MSG_SINGLECPM);		/* Access program then call  */
	    ms_x_exit(1);			/* the CPM_INIT function     */
}
#endif

	ms_drv_set(drive); 			/* try to set default drive  */

	FOREVER {

            error_code(setjmp(break_env));	/* Initialize Error Handler */
#if !defined(CDOSTMP)
	    cbreak_ok = TRUE;			/* we can handle break now */
#endif
#if !defined(NOSECURITY) && (defined(CDOSTMP) || defined(CDOS))
#if defined(CDOSTMP)
	
	    ms_drv_set(drive);	 		/* try to set default drive  */

            /* Ensure we are the foreground process on the Virtual Console */
            /* before displaying login prompt. */
            if(login_enabled()) {
                disable_vc_switch(); /* stop user switching to another console */

                /* if 1st time through on VC 0 then run system autoexec */
		if (system_init) {
		    login_save_initial_state();
		    if (pd->P_CNS==0) {
                    /* log this event */
                    logevent("",LOG_POWERON);
			/* process system Autoexec.bat */
		        while (*kbdptr || batchflg)
			        cmd_loop (cmd_buf);
                }
		    system_init = FALSE;
		}
                if(waiting_on_login() && !background_proc())
                    login_station();	/* login station */
	        login_consoles();	/* initialise all VCs */
                enable_vc_switch();
            }
#endif
            FOREVER {
       	        error_code(setjmp(break_env));	/* Initialize Error Handler */

		    if (login_enabled()) {
                    if(!logged_in()) 	/* keep going until logged out */
			        break;
		    }
#endif
       	        cmd_loop (cmd_buf);

#if !defined(NOSECURITY) && (defined(CDOSTMP) || defined(CDOS))
	    }
            if(login_enabled()) {
		/* kill off any remaining batch processes still running */
                while (batchflg)
		        cmd_exit("");
#if defined(CDOSTMP)	
		/* the logout event */
                if(!background_proc())
			    logout();
#else
		return;	/* CDOS.COM just dies when logout happens */
#endif
	    }
#endif
        } 
}

/*MLOCAL*/ VOID cmd_loop (cmd)
BYTE	*cmd;
{
WORD	echoing;	    
REG BYTE *cmdline;
BYTE	first_ch;
	  
	cmd_cleanup();				/* Cleanup after the command */
	cmdline = cmd;
	
	if (!batchflg) flush_cache();
	echoing = getcmd(cmdline);		/* do not echo Labels	     */

	first_ch = *deblank(cmdline);

	if((pipe_out && !batchflg && !*deblank(kbdptr)) ||
						/* if "|<nul command>"	*/
	   (pipe_in && (first_ch == 0 || first_ch == ':'))) {
	   					/* or "<null command>|"	*/
	    eprintf(MSG_SYNTAX);		/* report syntax error	*/
	    pipe_out = NO;			/* forget about pipes	*/
	    pipe_in  = NO;
	    if (!batchflg)
		*kbdptr = '\0';			/* discard rest of line	*/
	    crlfflg = YES;			/* remember to do a LF	*/
	    return;				/* stop now before echo	*/
	}

	if(echoing && first_ch != ':') {
						/* Echo command line if ECHO */
	    puts(cmdline);			/* ON and source not keyboard*/
	    crlf();				/* and not a label	     */
	}

	crlfflg = NO;				/* NO CR/LF req'd           */
	cmdline = deblank(cmdline); 		/* remove leading spaces    */
 
	if(*cmdline && *cmdline != ':')		/* Check for a command	    */
	{					/* not a LABEL		    */

	    if (!strnicmp(cmdline,"IF",2)) docmd(cmdline,YES);
	    else {
	        if(!parse(cmdline))	{	/* If the Parse succeeds then*/
		    docmd(cmdline, YES);	/* execute the command.	     */
                }
	    }
	}
}

/*.pa*/
/*
 *
 */
#define	COMMAND_P	(cflag & 1)	/* Permanent Flag		*/
#define	COMMAND_C	(cflag & 2)	/* One Command Option		*/
#define	COMMAND_T	(cflag & 4)	/* CDOS TSR option		*/


MLOCAL VOID init(cmd)
BYTE *cmd;
{
	UBYTE	console = 1;			/* Concurrent Console No. +1 */
	SYSDATE date;				/* System Date Structure     */
	WORD	ret;				/* General Variable	     */
	UWORD	cflag;
	BYTE	*s;
#if defined(CDOSTMP)
	UWORD	vc_base, vc_num, pc_num;	/* Virtual Console Data	     */
#else
	BYTE	buf[MAX_ENVLEN], c;
	UWORD	envsize = 256;
#endif
#if defined(DOSPLUS)
	BOOLEAN	no_timedate = FALSE;
	WORD  prh_function = 0;
	UWORD	FAR *p_batch_seg;
#endif
	BYTE	lferror = 0;
	strcpy(kbdptr, "");			/* start with no commands */

#if 0
#if defined(DLS)
	dls_msg_ver(MSG_VER);			/* check message file version*/
#else
	s = MSG_VER;				/* ensure label is referenced */
#endif
#endif

#if defined(CDOS)
	ret = ioctl_ver();
	if(ret < 0x1450 || ret > 0x1499) {	/* Get the CDOS BDOS Version */
	    eprintf(MSG_BADOS);			/* and quit if it is not 5.0 */
	    ms_x_exit(-1);			/* or Above		     */
	}
#endif

#if defined(DOSPLUS)

	batchptr_off = (VOID *) &batch;
	batchflg_off = (VOID *) &batchflg;
	echoflg_off  = (VOID *) &echoflg;

	envsize = get_original_envsize();	/* BAP - sets envsize to */
						/* same as original COMMAND */
	if ((envsize < 128) || (envsize > 32752)) envsize = 256; /* shouldn't really need this */

	parent_psp = MK_FP(_psp, 0x16);		/* our parental PSP is here  */
	ret = ioctl_ver();			/* Get the BDOS Version No.  */

	if(ret < 0x1071) {			/* Abort if this is not DOS  */
	    eprintf(MSG_BADOS);			/* PLUS with a BDOS version  */
	    if ((*parent_psp) && (*parent_psp != _psp))
		ms_x_exit(-1);			/* abort unless root process */
	    while(1){};
	}

#if 0
#if defined(DLS)
	dls_msg_crit();				/* init crit error messages  */
#endif
#endif

#endif

#if defined(CDOSTMP)
	console = (UBYTE) bdos(C_GET, 0) + 1;	/* CDOS Console No. + 1	    */
	execed = NO;				/* COMMAND.RSP not EXECED    */
	err_ret = 0;				/* Initial Error Code 0000   */

#else
	execed = YES;				/* Assume we have been loaded*/
						/* from the command line     */
	break_flag = ms_set_break(NO);		/* Get the Current Break Flag*/
	err_ret = ms_x_wait();			/* Get the completion code   */
						/* for process's that cause  */
						/* COMMAND.COM to be reloaded*/

	init_switchar();			/* initialise switchar and   */
						/* pathchar		     */
#endif

	drive = ms_drv_get();	 		/* get default drive.	     */
	country.code = ms_s_country(&country);	/* Initialise the Country data*/
	in_handle = psp_poke(STDIN, 0xFF);	/* Get the standard input    */
	psp_poke(STDIN, in_handle);		/* and save internally	     */

	out_handle = psp_poke(STDOUT, 0xFF);	/* Get the standard Output   */
	psp_poke(STDOUT, out_handle);		/* and save internally	     */

	for(ret=5;ret<20;ms_x_close(ret++));	/* close handles 5-20	     */

	if(initflg)				/* is this a warm boot?	     */
	    return;				/* Yes then QUIT	     */

	initflg = YES;				/* there's only one 1st time */
	cflag = 0;				/* Clear the switch variable */

#if !defined(CDOSTMP)
	/*
	 *
	 *	COMMAND.COM
	 *	The following command line formats must be supported for
	 *	applications that exec the command processor.
	 *
	 *	COMMAND /CCOPY filex filey	FrameWork Install
	 *	COMMAND /C DIR *.* /P		Procomm directory option
	 *	COMMAND /C=DIR *.*
	 *
	 *	These varients prevent support for multiple options and
	 *	force the option scanning to be halted at the first command
	 *
	 *	COMMAND /T - TSR support for CDOS
	 *
	 *	We are auto-invoking COMMAND after detecting a TSR, so
	 *	try and inherit any open batch files.
	 *
	 */

	s = (BYTE *) heap_get(128); /* allocate some heap memory */

	FOREVER {
	    cmd = deblank(cmd);			/* Deblank the command line  */
	    if((*cmd == '\0') || (*cmd == *switchar))
		break;				/* stop at option or end     */

	    cmd = get_filename(s, cmd, NO);

	    if(strlen(s)) {			/* look for Loadpath/STDIO */
		if((ret = ms_x_open(s, OPEN_RW)) >= 0) {
		    if(isdev(ret)) {
			strcat(kbdptr,"ctty ");	/* if its a R/W device put */
			strcat(kbdptr, s);	/* CTTY <dev> into buffer  */
			strcat(kbdptr,"!");
		    }
		    else			/* otherwise its an error  */
			eprintf(MSG_LOADPATH);	/*  an invalid loadpath    */
		    ms_x_close(ret);		/* Close the handle */
		}
		else {
		    append_slash(s);		/* user specified loadpath   */
		    get_reload_file();		/* get reload_file on heap   */
		    strcat(s, fptr(heap()));
		    if(file_exist(s)) {		/* append existing load file */
		    	ms_x_expand(heap(), s);
		    	set_reload_file();	/* copy heap to reload_file  */
		    }
		    else {			/* Print an error message if */
			eprintf(MSG_LOADPATH);	/* an invalid path used.     */
			lferror = 1;
			break;
		    }
		}
	    }
	    else {
	        eprintf(MSG_LOADPATH);
		break;
	    }
	}

	heap_set(s);	/* free up heap memory */

	c_option = FALSE;
	k_option = FALSE;
	FOREVER {
	    cmd = deblank(cmd);			/* Deblank the command line  */
	    if(*cmd != *switchar)		/* Stop the option check if  */
		break;				/* the next character is not */
	    cmd++;				/* a switch character.	     */
	    c = toupper(*cmd++);
	    switch(c) {
/*RG-05-*/
#if (defined(CDOS)||defined(DOSPLUS)) && !defined(NOHELP)
  		case 'H':			/* Support /H Help Option	     */
		case '?':			/* Support /? Help Option	     */
		    cflag |= 2;
                    cmd_ver();
                    crlf();
                    printf(HELP_COM);
		    ms_x_exit(0);
		    break;
#endif
/*RG-05-end*/
		case 'C':			/* Support /C Option	     */
		    echoflg  = ECHO_OFF;	/* Don't issue CR LF	     */
		    c_option = TRUE;
		case 'K':
		    k_option = TRUE;
		    cmd = deblank(cmd);
		    if (*cmd == '=') {
		    	cmd++;			/* Skip optional '='         */
		        cmd = deblank(cmd);
		    }
		    
		    cflag |= 2;
		    break;

		case 'N':
			n_option = TRUE;
			break;

		case 'P':			/* Support /P Option	     */
		    cflag |= 1;
		    if (*cmd == ':') {		/* See if a different fname  */
		    	cmd++;			/* has been specified for    */
			ret = 0;		/* AUTOEXEC.BAT.             */
		    	while ((*cmd > 32) && (ret < 12))
				autoexec_name[ret++] = *cmd++;
		    	autoexec_name[ret] = 0;
			while (*cmd > 32) cmd++;
		    }
		    break;

		case 'E':			/* Environment Option */
		    if(*cmd != ':')		/* Check for /E:nnn   */
		        break;
		    cmd++;	
		    if(getdigit(&ret, &cmd) && ret > 128 && ret < 32752)
		        envsize = ret;
		    break;

#if defined(CDOS)
		case 'T':			/* TSR support */
		    cflag |= 5;
		    inherit_TMP_state();	/* inherit batch files etc */
		    break;
#endif

#if defined(DOSPLUS)
		case 'T':
		    inherit_parent_state();
		    break;
#endif


#if defined(DOSPLUS)
		case 'M':			/* relocate resident portion */
		    c = toupper(*cmd++);
		    if (c == 'H') prh_function = 1;
		    if (c == 'U') prh_function = 2;
		    if (c == 'L') prh_function = -1;
		    break;

		case 'D':
		    no_timedate = TRUE;
		    break;
#endif

		case '\0':			/* Treat the NULL character */
		    cmd--;			/* specially in case some of*/
		    break;			/* the following command "/"*/

		default:			/* Skip invalid options.    */
		    break;
	    }
	}
#if defined(DOSPLUS)
/* We cannot allow COMMAND to go into upper memory unless "/P" has also */
/* been given. If we do the memory won't be freed up on exit */

	switch(prh_function) {
  		case 0:	/* try high, upper, then low */
			if(COMMAND_P)
				put_resident_high(0);
			else
				put_resident_high(1);
			break;
		case 1:	/* try high, then low */
			put_resident_high(1);
			break;
		case 2:	/* try upper, then low */
			if(COMMAND_P)
				put_resident_high(2);
			break;
		default:/* try low */
			break;
	}
#endif

	master_env(envsize);			/* Allocate the master 	     */
						/* environment of ENVSIZE    */
						/* bytes in length	     */
#if 0
	/*
	 *	If no COMSPEC has been defined or it is different from
	 *	the RELOAD_FILE specification then update COMSPEC.
	 */
	if(env_scan(msg_comspec, heap()) || stricmp(heap(), reload_file)) {
	    sprintf(buf, "%s%s", msg_comspec, reload_file);
	    cmd_set(buf);
	}
#else
	/* BAP changed this */
	get_reload_file();
	if(env_scan(msg_comspec,heap())) {
	    sprintf(buf,"%s%s",msg_comspec,heap());
	    cmd_set(buf);
	}
#endif

#if defined(DOSPLUS)
	save_parent = *parent_psp;
	*parent_psp = _psp;			/* Always do this */

	    if(COMMAND_P) {			/* Action the /P flag for   */
		execed = NO;			/* DOSPLUS.COM		    */

		PATH_DIR[0] = drive + 'A';	/* if DRDOS directory exists */
		ret = ms_x_chmod(PATH_DIR, ATTR_ALL, 0);
		if ((ret > 0) && (ret & 0x10)) {/* point the path at it */
			sprintf(buf, SET_PATH, PATH_DIR);
			cmd_set(buf);
		}
		cmd_set(SET_PROMPT);
		cmd_set(SET_OS);
		cmd_set(SET_VER);
#if !defined(FINAL)
		cmd_set(SET_BETA);
#endif
	        install_perm();			/* Install Backdoor entry    */
	    }

	/* process the environment created by config.sys */
	process_config_env();
#endif

#endif

	FOREVER {
	    if(execed) {	/* If this is a transient  */
		if (!lferror)
		    strcat(kbdptr, cmd);	/* command processor then  */
		ret = FALSE;			/* get the command line and*/
		break;				/* ignore AUTOEXEC.BAT.	   */
	    }

	    /* Check for the presence of STARTnnn.BAT in the root   */
	    /* of the boot disk if not found check for AUTOEXEC	    */
	    /* if neither are present then if this is console 0	    */
	    /* and this is < 1987 ask for the date. 		    */

#if defined(CDOSTMP) 
            vc_data(&vc_base, &vc_num, &pc_num);	/* Get VC Data	    */
	    vc_num = console - vc_base;			/* Relative VC Num  */
	    sprintf(heap(), "!start%02d%1d.bat", pc_num, vc_num);
	    if((ret = file_exist(heap()+1)) == 0) {
	        strcpy(heap(), "!autoexec.bat");
		ret = file_exist(heap()+1);
	    }

	    if(ret != 0) { 	
		strcat(kbdptr, heap());
		sprintf(heap(), " %d %d %d", console, pc_num, vc_num);
		strcat(kbdptr, heap());
		break;
	    }

#else
	    strcpy(heap(), "!");
	    strcat(heap(), autoexec_name);
	    if((ret = file_exist(heap()+1)) != 0) {
		if (boot_key_scan_code != 0x3f00 /*F5*/)
		    strcat(kbdptr,heap());
		break;
	    } else {
		boot_key_scan_code = 0;
	    }
#endif	

#if defined(DOSPLUS)
	    if (!no_timedate && *autoexec_name!=0)
	        strcat(kbdptr, "!date!time");
#else
	    ms_getdate(&date);
	    if(console == 1 && date.year < 1987)
		strcat(kbdptr, "!date!time");
#endif
	    break;
	}
#if defined(CDOS) && !defined(CPM)
	    if(COMMAND_P)			/* Action the /P flag for   */
		execed = NO;			/* CDOS.COM to disable EXIT */
#endif

#if 0
	if(COMMAND_C) {				/* Append EXIT if COMMAND.COM*/
	    strcat(kbdptr, "!exit 0");		/* is just used to execute a */
	}					/* a command.		     */
#endif

#if !defined(CDOSTMP)
#if 0
	else { 
#else
	if(!COMMAND_C) {
#endif
#if defined(DOSPLUS)
	    if (*autoexec_name != 0) {
	        cmd_ver();			/* display the signon	     */
		
 	        printf(MSG_OEMCPYRT);
	        crlf();
		    }
#else
	    if(!COMMAND_T) {			/* if it's CDOS TSR support  */
		cmd_ver();			/* don't display signon      */
		crlf();
	    }
#endif

	}
#endif
}

/*
 *	The following function is called to clean up COMMAND.COM after 
 *	an internal or external command has been executed. The major areas
 *	to be handled by this function are:-
 *
 *	1)	Control-C termination for Batch file termination
 *	2)	I/O Redirection
 *	3)	Hiloading off
 */
MLOCAL VOID cmd_cleanup()
{
BYTE	cmdbuf[128];
#if 0
	hiload_set(NO);				/* HILOADing off now */
#endif
	
	if(err_ret == BREAK_EXIT ||		/* Check for Control-C	     */
	    err_ret == ERROR_EXIT) {		/* or Critical Error Exit    */

	    if(pipe_out) {			/* If a Pipe'ed command is   */	
		pipe_out = NO;			/* is aborted then absorb    */
		getcmd(cmdbuf);			/* the second command.	     */
		crlf();
	    }

	    if(batchflg) {
		eprintf(MSG_BATTERM);		/* Processing a BATCH file   */
		err_flag = TRUE;		/* ask if the uses wishes to */
		if(yes(NO, YES))		/* to abort this batch job   */
		    batch_endall();		/* Close ALL batch files     */
		err_flag = FALSE;
	    }
	    else if(for_flag)			/* If processing a FOR	     */
		for_end();			/* command outside a batch   */
	}					/* file then abort it.	     */

	err_ret &= 0x00FF;			/* Mask the Termination      */
						/* condition this should only*/
						/* be tested once.	     */

		/*
		 * After the termination of a Batch file or a Program then
		 * the relevant redirection is removed. If the redirection
		 * was instigated because of the PIPE facility then the
		 * correct clean up code is executed.
		 */

	while(in_flag & REDIR_ACTIVE) { /* Is Redirection Active     */
	    if((in_flag & REDIR_BATCH) && batchflg)
		break;

	    if((in_flag & REDIR_FOR) && for_flag)
		break;

	    ms_x_close(STDIN); 			/* Close the Redirected File */
	    psp_poke(STDIN, in_handle);		/* Restore original Handle   */
	    
	    if(pipe_in) {
		pipe_in = NO;
		ms_x_unlink(old_pipe);
		heap_set(old_pipe);
	    }

	    in_flag = NULL;
	}

	while(out_flag & REDIR_ACTIVE) {	/* Is Redirection Active     */
	    if((out_flag & REDIR_BATCH) && batchflg)
		break;

	    if((out_flag & REDIR_FOR) && for_flag)
		break;

	    ms_x_close(STDOUT);			/* Close the Redirected File */
	    psp_poke(STDOUT, out_handle);	/* Restore original Handle   */

	    if(pipe_out) {
		pipe_in = YES; pipe_out = NO;
		old_pipe = heap_get(strlen(out_pipe)+1);
		strcpy(old_pipe,out_pipe);
	    }

	    out_flag = NULL;
	}

	country.code = ms_s_country(&country);	/* re-init the Country data  */
#if 0
#if defined(DLS)
	dls_msg_crit();				/* re-init crit error msgs   */
#endif
#endif
}

/*.pa*/
/*
 *	ERROR_INIT is the "CRITICAL" error handler which will initialize
 *	the error handling code, displays error messages and clean-up the
 *	environment after an error has occurred.
 */
/*RG-00*/
/*MLOCAL VOID error_code(error)*/
VOID error_code(error)
/*RG-00-end*/
UWORD error;
{
	switch(error) {
	    case 0:				/* Setting JMPBUF. Enable    */
#if !defined(CDOSTMP)				/* break checking in case    */
		ms_set_break(YES);		/* this is the first time    */
#endif						/* through the command proc. */
 		return;

	    case IA_BREAK:
		putc('\r');			/* A CR here makes SideKick+ */
						/* look good when it	     */
						/* deinstalls itself	     */
/* The following two function calls close the batch file during an INT 23
   thus disallowing to continue with a batch file if the user chooses to
   do so after being prompted. However, there migh have been a reason why
   this has been inserted before which I don't know of. JBM */
/*		ms_x_close(5);			 ##jc## Close Unused Handles*/
/*		ms_x_close(6);			 ##jc## Close Unused Handles*/
		mem_free(&bufaddr);		/* Free External Copy Buffer */
#if defined(CDOSTMP)				/* On Concurrent DOS and     */
		bdos(DRV_RESET, 0xFFFF);	/* DOSPLUS reset the disk    */
		crlf();				/* when we get a Control-C.  */
#endif
		break;

	    case IA_STACK:			/* Stack Overflow Error      */
	    case IA_HEAP:			/* Heap Overflow Error	     */
		batch_endall(); 		/* Out of memory error	     */
		eprintf(MSG_BATNEST);		/* probably caused by nesting*/
		break;				/* batch files TOO deep.     */
		
	    case IA_FILENAME:			/* FileName Error	     */
		eprintf(ERR_FILE);		/* display an error message  */
		break;				/* and terminate the command */

	    default:
		eprintf(MSG_LONGJMP, error);
		break;
	}

	crlfflg = NO;				/* Reset CR/LF Flag	    */
}

/*
 *	This function is invoked after a CONTROL-BREAK or Critical Error
 *	during the execution of an internal function. Any BREAK specific
 *	cleanup is executed here. The break handler then restarts normal
 *	code execution by executing a LONGJMP.
 */
GLOBAL VOID CDECL int_break()
{
int	i;

	if (show_file_buf) mem_free(&show_file_buf);

	if (global_in_hiload) {
	    /* if ctrl-c pressed during a hiload, restore memory */
	    /* allocation strategy.				 */

	    for(i=1;i<10;i++) {		/* free up any UMB's we have */
		if (hidden_umb[i]) {
		    free_region(hidden_umb[i]);
		    hidden_umb[i] = 0;
		}
	    }
	    set_upper_memory_link(global_link);
	    set_alloc_strategy(global_strat);
	    global_in_hiload = 0;
	}

	err_ret = BREAK_EXIT;		/* Update the Global Error Return */
	longjmp(break_env, IA_BREAK);	/* Either Control-C or Critical   */
					/* Error Process Termination.	  */
}

/*.pa*/
/*
 *	This function parses the command line and extracts all unquoted
 *	>>, > and < character sequences and their corresponding filenames.
 *	The last redirection specification of the same type is used all
 *	previous references will be removed. Redirection will only be 
 *	enabled if no redirection of the same type is already active.
 *	ie. If redirection is enabled on a batch file all redirection
 *	commands of the same type inside the file are ignored.
 */
GLOBAL BOOLEAN parse(s)		   	/* Parse the command line looking    */
BYTE *s;				/* for Redirection commands	     */
{
REG BYTE *bps;
BYTE *bpi, *bpo;
BYTE infile[MAX_FILELEN];		/* Input Redirection FileName	    */
BYTE outfile[MAX_FILELEN];		/* Output Redirection FileName	    */
BYTE cmdbuf[128];			/* Command buffer for Aborted Pipe  */
WORD h;
BOOLEAN quote = NO;			/* Check for Quoted Statements	     */
BOOLEAN append; 			/* Out Redirection Append	     */

	crlfflg = YES;			/* Force a CRLF in case an error     */
					/* occurs in the command line parsing*/

	for(bpi = NULL, bpo = NULL; *s; s++) {

	    if(*s == '"') {			/* Maintain the correct    */
		quote = !quote; 		/* Status of the QUOTE flag*/
		continue;
	    }

	    if(quote)				/* If the QUOTE flag is     */
		continue;			/* then skip the following  */

	    if(*s == '>') {			/* Found Output redirection  */
		bpo = outfile;			/* Character extract the Path*/
		bps = s+1; append = FALSE;	/*  and save locally	     */

		if(*(bps) == '>') {		/* Check for append mode     */
		    append = TRUE;
		    bps++;
		}

		bps = get_filename(bpo, deblank(bps), NO);
						/* Extract the FileName	     */
		bps = deblank(bps);
		strcpy(s--, bps);		/* Then remove data from Line*/
		continue;			/* S decrement to force new  */
	    }					/* next character to be read */

	    if(*s == '<') {			/* Found Input redirection   */
		bpi = infile;			/* Character extract the Path*/
		bps = get_filename(bpi, deblank(s+1), NO);
						/* Extract the FileName	     */
		bps = deblank(bps);
		strcpy(s--, bps);		/* Then remove data from Line*/
	    }					/* S decrement to force new  */
	}					/* next character to be read */


#if defined(DOSPLUS)
	/* only redirect if not already redirected */
	if ((pipe_in || bpi) && (!(in_flag & REDIR_ACTIVE))) {
#else
	if(pipe_in || bpi) {			/* Check for any redirection */
	    if(in_flag & REDIR_ACTIVE) {	/* If Standard Input has been*/
		eprintf(MSG_INACTIVE);		/* redirected then fail      */
		return FAILURE;
	    }
#endif

	    bpi = pipe_in ? out_pipe : infile;	/* BPI points to the filename*/

	    h = ms_x_open(bpi, OPEN_READ);
	    if(h < 0) {
						/* Attempt to Open the file  */
		e_check(h);			/* || device specified and   */
		return FAILURE; 		/* print an error message if */
	    }					/* we fail.		     */
		
	    psp_poke(STDIN, psp_poke(h, 0xFF));	/* Force New input file onto */
	    					/* Standard Input and close  */
	    in_flag = REDIR_ACTIVE;		/* the returned handle	     */
	}
		
#if defined(DOSPLUS)
	/* only redirect if not already redirected */
	if ((pipe_out || bpo) && (!(out_flag & REDIR_ACTIVE))) {
#else
	if(pipe_out || bpo) {			/* Check for any redirection */
	    if(out_flag & REDIR_ACTIVE) {	/* If Standard Output has been*/
		eprintf(MSG_OUTACTIVE);		/* redirected then fail      */
		return FAILURE;
	    }
#endif

	    if(pipe_out) {
#if defined(CDOSTMP)
		out_pipe[0] = *SYSDATB(TEMPDISK)+'A';	/* Initialise the DRIVE */
		out_pipe[3] = '\0';			/* Terminate String	*/
#else
		if (!env_scan("TEMP=",out_pipe)) {
		    
		    /* if TEMP != "d:\" check its a valid directory */
		    if ((strlen(out_pipe) > 3) || (out_pipe[1] !=':')) {

		    	h = ms_x_chmod(out_pipe,ATTR_ALL,0);
			if ((h<0) || !(h&0x10)) goto assume_root;	
		    }
		    append_slash(out_pipe);
		}
		else {
assume_root:
		    get_out_pipe();		/* get string from low_seg */
		    out_pipe[0] = drive+'A';	/* Initialise the DRIVE */
		    out_pipe[3] = '\0';		/* Terminate String	*/
		}
#endif
		bpo = out_pipe;
		h = ms_x_unique(out_pipe, ATTR_SYS);

	    }
	    else {				/* Create the output file if */
		bpo = outfile;			/* not Appending or the OPEN */
						/* on the file fails.	     */
		if(!append || (h = ms_x_open(bpo, OPEN_WRITE)) < 0)
		    h = ms_x_creat(bpo, 0);
	    }

	    if(e_check(h) < 0) {		/* Display any error message */
	    	if(pipe_out) {			/* Pipe'ed command then     */
		    pipe_out = NO;		/* absorb the second command*/
		    getcmd(cmdbuf); 		/* return FAILURE on error   */
		    crlfflg = YES;
		}
		return FAILURE;
	    }

	    if(append)				/* If in APPEND mode then    */
		ms_x_lseek(h, 0L, 2);		/* seek to the end.	     */

	    psp_poke(STDOUT, psp_poke(h, 0xFF));/* Force New input file onto */
	    					/* Standard Ouput and close  */
	    out_flag = REDIR_ACTIVE;		/* the returned handle	     */

	    if(pipe_out)
		out_flag |= REDIR_PIPE;
	}

	crlfflg = NO;
	return SUCCESS;
}


MLOCAL	BOOLEAN docmd_offer(BYTE *cp, BYTE *command, UWORD internal_flag)
{
BYTE	*lcp;
int	i;
UWORD	int2f_gotit = 0;

	lcp = heap();

	lcp[0] = 0x80;		/* copy command line to buffer	*/
	lcp[1] = strlen(cp);	/*   with "readline" format	*/
	for (i=0;i<lcp[1];i++)
	    lcp[i+2]=cp[i];
	lcp[i+2] = '\r';

				/* offer command line to interested parties */
	if(int2f_gotit = docmd_int2f(lcp,command,internal_flag))
	    return 1;		/* if they want it, docmd_offer = TRUE 	    */
				

	for(i=command[0];i<8;command[1+(i++)]=' ');
				/* if length is altered, space fill */

	for(i=0;i<lcp[1];i++)
	    cp[i] = lcp[i+2];	/* copy it back in case it was changed */
	cp[i] = 0;		/* null terminate it */
	return 0;		/* docmd_offer = FALSE, cos the int2f didn't want it */
}

GLOBAL VOID docmd(cp, internal)
REG BYTE  *cp;			/* Command Line To be Parsed	*/
BOOLEAN   internal;		/* Search for INTERNAL Commands */
{
	REG S_CMD FAR *s_cmd_p;
	WORD	  i;
	BYTE FAR  *cpf;
	BYTE 	  loadfile[MAX_FILELEN];
	BYTE	  *cp1, *lcp;
	UWORD	  loadtype;
	BYTE	  argv0[MAX_FILELEN];

	heap_get(0);				/* check for stack overflow */
	lcp = cp;				/* in case 1st parse fails.. */
        crlfflg = YES;

	for(i=0;i<12;loadfile[i++]=' ');	/* initialise with blanks */
	ms_f_parse(loadfile, cp, 1);		/* parse for internal cmd */
	for(i=7;(i>=0) && (loadfile[i+1] == ' '); i--);
	loadfile[0] = i+1;			/* set length of cmd */
	
	for(;strchr(valid_sepchar,*cp);cp++);	/* ignore leading separators */
	for(;is_filechar(cp);cp++);		/* skip the command itself */
						/* offer command line to */
						/* interested parties */
	if(docmd_offer(lcp,loadfile,0xFF00+strlen(cp)))	/* If they want it */
		return;					/* we don't */
	
	cp = lcp;
	if ((cp[0] != 0) && (cp[1] == ':')) cp+=2;
	for(;strchr(valid_sepchar,*cp);cp++);
	for(;is_filechar(cp);cp++);		/* skip the command itself */

	cp1 = cp;
	i = 0;
	while (*cp1 != '\0') {
	    if (*cp1 == '"')
		i ^= 1;
	    if (is_blank(cp1) == 2 && !i)	/* replace each KANJI space */
		*cp1 = *(cp1 + 1) = ' ';	/* with one ASCII space */
	    cp1 = skip_char(cp1);
	}

	s_cmd_p = (S_CMD FAR *)farptr((BYTE *)&cmd_list[0]);
	while(internal && s_cmd_p->cmnd) {	/* while more builtins	*/
	    cpf = cgroupptr(s_cmd_p->cmnd);
	    for(i=0;cpf[i];i++)			/* make upper case copy */
	    	argv0[i]=toupper(cpf[i]);
	    for(;i<8;argv0[i++]=' ');		/* space fill it to 8 */

	    if(!strncmp(argv0,loadfile+1,8)) {	/* Is this a match ? */

#if !defined(NOHELP)
		/* Handle  /H or /? in command */
		strcpy(heap(),deblank(cp));
		if(!strnicmp(heap(),"/h",2)||!strnicmp(heap(),"/?",2)) {
		    if (s_cmd_p->help_index != -1)
		    	show_help(s_cmd_p->help_index);
		    crlf();
		    return;
		}
#endif

		/* check for embedded commands in IF that only have meaning in
                		that context */
		if(s_cmd_p->needparm==PARAM_IFCONTEXT) {
		    if(if_context==FALSE) break;
		}

		cp1 = deblank(cp);		/* Remove Blanks from Options*/

		if(s_cmd_p->needparm!=PARAM_NONE /* if a parameter is needed */
		   && !*cp1) {			/* but none is supplied      */

		    switch ((UWORD)s_cmd_p->needparm)	/* display an error message  */
		    {
		    case PARAM_NEEDFILE: eprintf(MSG_NEEDFILE); break;
		    case PARAM_NEEDPATH: eprintf(MSG_NEEDPATH); break;
		    case PARAM_NEEDDEV:	 eprintf(MSG_NEEDDEV);  break;
		    default:		 eprintf(MSG_SYNTAX);   break;
		    }
		    eprintf("\n");
		    return;			/* ignore the command	     */
		}
		
		page_len = get_lines_page();    /* so /P works in 43 and 50 */
						/* line modes */
		(*s_cmd_p->func)(cp1, cp);	/* Just Invoke builtin	     */
		return;
	    }
	    s_cmd_p ++; 			/* compare with next command */
	}

	/* it's not an internal command - could it be help ? */
        if ((!strnicmp(lcp,"/h",2))||(!strncmp(lcp,"/?",2))) {
            show_help(0);
	    s_cmd_p = (S_CMD FAR *)farptr((BYTE *)&cmd_list[0]);
	    while(s_cmd_p->cmnd) {
	        cpf = cgroupptr(s_cmd_p->cmnd);
                printf("%s\t",cpf);
	        s_cmd_p++;
	    }
	    crlf();
	    return;
	}

	/* command is not builtin, must be disk based so determine path ... */
	if(docmd_offer(lcp,loadfile,strlen(cp)))	/* offer command line to */
		return;				/* interested parties */
		/* If they want it, we don't */

	cp = get_filename(loadfile, lcp, NO);
	strcpy(argv0, loadfile);		/* the original command name */
	strlwr(loadfile);

	if((loadfile[strlen(loadfile)-1] == '\\') ||
	   ((strlen(loadfile) == 2) && (loadfile[1] == ':'))) {
	    if(!dos_parse_filename(loadfile) && d_check(loadfile)) {
		if (ddrive != -1)
		{
		    ms_drv_set(ddrive);		/* then check the requested */
		    drive = ddrive;		/* drive and make it the    */
		    crlfflg = NO;		/* default if OK.	    */
		}
	    }
	    else {
		eprintf(ERR15);
		crlf();
	    }
	    return;
	}

	if (strcmp(loadfile,"________") == 0) {
		ms_x_first("________.???",ATTR_HID+ATTR_STD,(DTA *) heap());
		strcpy(loadfile,"C:\\________.COM");
	}
	else if((i = findfile(loadfile, &loadtype)) < 0) {
	    if(i == ED_FILE ||		/* Determine the full	*/
	       i == ED_ROOM || 		/* path and type of the */
	       i == ED_PATH)	{	/* command and return if*/
		    eprintf(MSG_BADCMD); /* file or command cannot be located */
	    }
	    else {
		e_check(i);
	    }
	    return;
	}


	if(!env_scan(msg_comspec, heap()))	/* If COMSPEC is defined   */
	    set_reload_file();			/* then update RELOAD_FILE */

	doexec(argv0, loadfile, loadtype, cp);	/* Load the file	*/
	allow_pexec = TRUE;
}


/*
 *	FindFile searches the file system copying the actions of the 
 *	Concurrent DOS P_PATH function. If this is TMP for Concurrent 
 *	DOS then use the system call otherwise use the C function.
 *
 *	If no extension is specified then check the file types in
 *	the following order .CMD, .COM, .EXE, .BAT
 *
 *	If a Path is specified then just check that location otherwise
 *	check the current directory and then all entries in the path.
 */
#if !defined(CDOSTMP)
GLOBAL WORD CDECL findfile(loadpath, loadtype)
BYTE	*loadpath;		/* Command Name expanded to full path	*/
UWORD	*loadtype;		/* Command file Type			*/
{
	REG BYTE *s;
	BYTE	sppath[MAX_PATHLEN];		/* Buffer for the optional  */
						/* load path.		    */
	BYTE	fname[8+1+3+1+8+1];		/* Buffer for the filename */
						/* optional extension and   */
						/* password		    */
	BYTE	*path;				/* Environment Load path    */
	BYTE	*ftype; 			/* Optional file type	    */
	BYTE	*pwd;				/* Optional Password	    */
	BYTE	*envpath;			/* current PATH= in env     */
	WORD	i, ret;
#if !STACK
	BYTE	pathbuf[MAX_ENVLEN];		/* temporary path buffer    */
#endif

	strip_path(loadpath, sppath);		/* isolate the optional path*/
	ftype = loadpath+strlen(sppath);	/* get the Filename Address */

	if(strlen(ftype) < sizeof(fname))	/* If the filename is not   */
	    strcpy(fname, ftype);		/* too long then copy to an */
	else					/* internal buffer otherwise*/
	    longjmp(break_env, IA_FILENAME);	/* break with FILENAME error*/

	if((ftype = strchr(fname, '.')) != 0) {	/* then extract the optional*/
	    *ftype++ = '\0';			/* file type from the name  */
	    pwd = ftype;
	}
	else {					/* If no type has been	    */
	    ftype = NULLPTR;			/* specified then make it   */
	    pwd = fname;			/* file type a NULL pointer */
	}

	if ((ret = ms_x_open (fname, 0)) > 0) {	/* don't exec a device in   */
	    i = isdev (ret);			/* any shape or form	    */
	    ms_x_close (ret);
	    if (i)
		return (ED_FILE);
	}

#if defined(PASSWORD)
	if((pwd = strchr(pwd, *pwdchar)) != 0)  /* Finally extract the      */
	    *pwd++ = '\0';			/* optional password if none*/
	else					/* exists then default to a */
	    pwd = NULLPTR;			/* NULL pointer.	    */
#endif

	if(ftype) {				/* If a file type has been  */
	    for(i=0; ftypes[i]; i++)		/* specified then check that*/
		if(!strcmp(ftype, ftypes[i]))	/* is legal and return an   */
		    break;			/* error if not.	    */

	    if(!ftypes[i])			/* If an illegal filetype   */
		return ED_FILE; 		/* has been given then	    */
	}					/* return FAILURE	    */

	*loadtype = i;				/* Save the Load File Type  */

	/*
	 *	Check if a path is currently defined if YES then get
	 *	a copy of the path and save locally on the heap. Protecting
	 *	it against being overwritten.
	 */

	if(!env_scan(msg_patheq, heap())) {
	    envpath = heap();
	    while (*envpath) {			/* process path in env	 */
		if(dbcs_lead(*envpath))		/* so delimiters are the */
		    envpath++;			/* pathchar we expect	 */
		else
		    if((*envpath == '/') || (*envpath == '\\'))
			*envpath = *pathchar;
		envpath++;
	    }
#if STACK
	    envpath = stack(strlen(heap()) + 1);
#else
	    envpath = &pathbuf[0];
#endif
	    strcpy(envpath, heap());
	}
	else
	    envpath = "";

	/*
	 *	First attempt to load the file from the default/specified
	 *	path and then if no path was specified attempt to load the
	 *	file from all the entries in the search path defined in the
	 *	environment.
	 */

	if(*sppath)
	    path = sppath;
	else
	    path = "";

	do {
	    i = checkfile(loadpath, loadtype, path, fname, ftype, pwd);

	    switch (i)
	    {
	      case SUCCESS:
		strupr(loadpath);
		return SUCCESS;
	      case ED_FAIL:
	      case ED_DRIVE:			/* if bad drive in search  */
		if ((!*sppath) && (*path))	/* path, print msg & carry on*/
		{
		    eprintf(MSG_PATHDRV);
		    i = ED_FILE;
		    break;
		}
	      default:
		break;				/* get next search path	   */
	    }

	    path = envpath;			/* Set PATH to the next     */
	    if((s=strchr(envpath, ';')) != 0) {	/* element in the search path*/
		while (*s == ';') {		/* Skip over extra semicolons*/
		    *s = 0;
		    s++;
		}
		envpath = s;
	    }
	    else
		envpath = "";			/* path exhausted, -> null */

	    /* If you type FILENAME.EXE, it will search the current drive then */
	    /* the path. If you type C:\DIR\FILENAME.EXE, it will search */
	    /* C:\DIR. Now, if you type C:FILENAME.EXE, it will search the */
	    /* current directory on C:, then path. This is done by resetting */
	    /* sppath after the first run through, if it is just D:	*/
	    if((strlen(sppath) == 2) && (sppath[1] == ':'))
		sppath[0] = '\0';

	} while(!*sppath && *path);

	return i;
}

/*
 *	CHECKFILE generates the full path of the load file and
 *	attempts to open the file. If the file is located and
 *	can successfully be opened return SUCCESS with the full
 *	path in LOADPATH and the LOADTYPE initialised.
 *
 *	If no file extension has been specified then use the standard
 *	search order.
 *
 *	ATTR_SEARCH specifies the attributes used to locate the file
 *	to be loaded.
 */

#define	ATTR_SEARCH ATTR_STD + ATTR_HID

MLOCAL WORD checkfile(loadpath, loadtype, path, fname, ftype, pwd)
BYTE	*loadpath;
UWORD	*loadtype;
BYTE	*path, *fname, *ftype, *pwd;
{
	UWORD	type;
	WORD	ret;
	DTA	search;
	BYTE	curpath[MAX_PATHLEN+1];

	if((path = d_check(path)) == NULL)	/* Remove the drive specifier*/
	    return ED_DRIVE;			/* and return on Error.	     */
/*	get path starting from root. n.b. don't use ms_x_expand (func 60h)   */
/*	as it upsets Novell						     */

	if (ddrive != -1)
	{
	    sprintf(loadpath, "%c:%c", ddrive + 'A', *pathchar);
	    if((*path == '\\') || (*path == '/'))  /* If path is absolute then */
		strcpy(loadpath+2, path);	   /* just append to drive	    */
	    else {				   /* Otherwise append the     */
		ms_x_curdir(ddrive+1, loadpath+3); /* path to the drive and    */
		if(*fptr(loadpath))		   /* current subdirectory.    */
		    append_slash(loadpath);
		strcat(loadpath, path);
	    }
	}
	else
	    ms_x_expand(loadpath,path);


	if(*fptr(loadpath))
	    append_slash(loadpath);

	strcat(loadpath, fname);		/* Add the FileName	     */
	strcat(loadpath, ".");
	path = loadpath + strlen(loadpath);	/* Save the Extension Offset */

#if defined(PCDOS)
/*
 *	If running under PCDOS the check if any extension has been specified
 *	if not then search first for filename.* and return if no match occurs
 *	This will be quicker than opening each file in turn.
 */
	if(!ftype) {
	    strcat(path, "*");
	    if((ret = ms_x_first(loadpath, ATTR_SEARCH, &search)) < 0) {
		if( ret == ED_FILE ||	    /* Abort if an error occurs     */
		    ret == ED_ROOM ||	    /* but ignore File not Found    */
		    ret == ED_PATH)	    /* and invalid path errors	    */
		    return ED_FILE;
		else
		    return e_check(ret);
	    }
	}
#endif

	if (ftype == 0)
	    type = COM_FILETYPE;	/* Initialize the Type Index	*/
	else				/* correctly depending on the	*/
	    type = *loadtype;		/* initial file type.		*/

	do {
	    strcpy(path, ftypes[type]);	/* Add the first file type  */

#if defined(PASSWORD)
	    if(pwd) {			/* followed by the optional */
		strcat(path, pwdchar);	/* password and attempt to  */
		strcat(path, pwd);	/* open the file.	    */
	    }
#endif

	    if((ret = ms_x_first(loadpath, ATTR_SEARCH, &search)) < 0) {
		if(ret == ED_PATH)	/* Stop scanning this	   */
		    return ED_FILE;	/* element of the path if  */
					/* it is invalid.	   */
#if 0
		if(ret != ED_FILE && ret != ED_ROOM)
		    return ret;
#endif
	    }
	    else {
		*loadtype = type;	/* Set the correct loadtype */
		return SUCCESS;		/* and return SUCCESS	    */
	    }
	    if (++type > BAT_FILETYPE)
#if defined(DOSPLUS) || defined(NETWARE)
		type = COM_FILETYPE;
#else
		type = CMD_FILETYPE;
#endif
	} while(!ftype && (type != COM_FILETYPE));
	return ED_FILE;
}
#endif

MLOCAL BOOLEAN doexec(argv0, loadpath, loadtype, tail)
BYTE	*argv0;			/* Invoking Command		*/
BYTE	*loadpath;		/* Fully expanded filename	*/
UWORD	loadtype;		/* File Type .BAT, .EXE etc.	*/
BYTE	*tail;			/* Command line options		*/
{
	WORD	ret;
	WORD	i;
	BYTE	*s;
#if !STACK
	BYTE	tailbuf[128];
#endif

#if 0
printf("DOEXEC Load File \"%s\" Command Line \"%s\"\n",
				loadpath, (tail ? tail : ""));
#endif


	if(loadtype == BAT_FILETYPE) {	    /* if Batch file then:-	     */
	    
	    if (batchflg == 0) echoflg_save2 = echoflg;
	    
	    ret = echoflg;		    /* Save the Current ECHO State   */
	    batch_end();		    /* Close any Existing Batch file */
	    echoflg = ret;		    /* restore the ECHO status	     */
	    batch_start(argv0, loadpath, tail); /* and initialize the new batch  */
	    return YES; 		    /* use "CALL" to nest batches.   */
	}
					/* if CMD, COM or EXE		     */
	if(batchflg)			/* close the BATCH file if OPEN cos  */
	    batch_close();		/* some programs update the running  */
					/* batch file.			     */

	s = deblank(tail);		/* No SPACE before options   */
	if(!*s)				/* if this is a blank line   */
	    tail = s;

#if defined(CDOSTMP)
	ret = exec(loadpath, loadtype, tail, back_flag);
#else
	ms_set_break(break_flag);
#if STACK
	s = stack(strlen(tail)+2)+1;
#else
	s = &tailbuf[1];
#endif
	tail = strcpy(s, tail) - 1;
	*tail = (UBYTE) strlen(tail+1);
	strcat(tail+1, "\r");
#if !defined(FINAL)
	save_psp();
#endif
	ret = exec(loadpath, loadtype, tail, back_flag);
#if !defined(FINAL)
	check_psp();
#endif
	init_switchar();		/* switch character may have changed */
	break_flag = ms_set_break(YES);
#endif

	/*
	 *	Novell use the MS_DRV_GET function to detect abnormal
	 *	program termination. They assume this function is only
	 *	called by the command processor when a child has terminated.
	 *	They close all Remote Handles when the parent command
	 *	processor calls this function.
	 */
	drive = ms_drv_get();	 		/* get default drive.	     */

	for (i=5;i<20;i++) ms_x_close(i);	/* Close all handles */

	if(ret < 0) {			/* Get the returned Error Code	*/
#if defined(CDOS) || defined(CDOSTMP)
	    if(ret == ED_ENVIRON)	/* Check for an Environment	*/
		ret = (-255);		/* error this is really 	*/
#endif					/* a resource unavailable.	*/

					/* Print a message if the exec	*/
	    e_check(ret);		/* went wrong otherwise get the */
					/* completion status and return */
	    return FAILURE;
	}

	err_ret = ms_x_wait();
	return YES;
}

#if !defined(CDOSTMP)
VOID	FAR CDECL	int2e_handler (cmd)
BYTE	*cmd;
{
BYTE	*p;
jmp_buf save_jmpbuf;

/*	save the normal setjmp environment and reset it to ourselves	*/
/*	so that the int2e caller does not get aborted on criterr or	*/
/*	Control break							*/

    memmove (&save_jmpbuf, &break_env, sizeof (jmp_buf));

    if (setjmp (break_env) == 0) {

	if ((p = strchr (cmd, 0xd)) != NULL)
	    *p = '\0'; 

	int2e_start();
	
	docmd (deblank (cmd), TRUE);

/*	if int2e is executing a batch file, do not return until all	*/
/*	batch file commands have been processed. Loop round as in main	*/
/*	loop								*/

	while (batchflg > 0)
	{
	    cmd_loop (cmd);
	}
	
	int2e_finish();
    }
    memmove (&break_env, &save_jmpbuf, sizeof (jmp_buf));
}


MLOCAL VOID init_switchar()
{
	*switchar = ms_switchar();		/* get switch character      */
	if (*switchar == '/')			/* if not UNIX path char     */
	    *pathchar = '\\';			/*   then be compatible      */
	else
	    *pathchar = '/';
}

#endif

#if defined(DOSPLUS)

GLOBAL VOID process_config_env()
{
	BYTE FAR *config_env;
	WORD i;
	BYTE buff[128];
	BYTE *s;

	config_env = get_config_env();
	if (config_env) {
		FOREVER {		
			i = 0;
			while ((*config_env) && (*config_env!=0x1A) && 
			       (i < 127)) {
				
				buff[i++] = *config_env++;
			}
			if (i == 0) {
			   while (*config_env != 0x1A) config_env++;
			   config_env++;
			   boot_key_scan_code = * ((UWORD far *) config_env);
			   break;
			}
			buff[i] = 0;
			cmd_set(buff);    
		    	while (*config_env) config_env++;
			config_env++;
		}
#if 0
		s = heap();
		if (!env_scan("HOMEDIR=",s)) {
			if (s[1] == ':') ms_drv_set(toupper(*s)-'A');
			ms_x_chdir(s);
		}
#endif
	}
}
#endif

#if !defined(FINAL)
void	save_psp()
{
	BYTE far *fp;
	WORD	i;
	
	fp = MK_FP(_psp,0);

	psp_xsum = 0;
	for  (i=64;i<128;i++) psp_xsum += fp[i];
}

void	check_psp()
{
	BYTE far *fp;
	WORD	xsum;
	WORD	i;

	fp = MK_FP(_psp,0);
	
	xsum = 0;
	for (i=64;i<128;i++) xsum += fp[i];
	
	if (xsum != psp_xsum) {
	    printf("BETA DEBUG ERROR: Need more stack!\n");
	    printf("Press a key to continue.\n");
	    getch();
	}
}
#endif

