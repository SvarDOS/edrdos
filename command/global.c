/*
;    File              : $Workfile: GLOBAL.C$
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
*/

/*
   Date     Comments
 ---------  ------------------------------------------------------------
 21 Mar 88  Modify IN_PIPE and OUT_PIPE to be compatible with NOVELL 2.1
 21 Sep 88  Change the default ECHO state to be ON.
*/

#include	"defines.h"
#include	<portab.h>
#include	<command.h>		/* Command Definitions */
/*.pa*/
/*	General Purpose Variables	*/
GLOBAL BOOLEAN	initflg = FALSE;	/* Initial Load Flag		     */
GLOBAL WORD	drive = 0;		/* Current default Drive	     */
GLOBAL UWORD	echoflg = ECHO_ON;	/* Current Echo Status		     */
GLOBAL BOOLEAN	crlfflg = FALSE; 	/* No CR/LF Required before prompt   */

/*	Batch File Processing Variables */
GLOBAL UWORD	batchflg = 0;		/* Currently processing Batch File   */

/*	FOR Sub-Command Variables	*/
GLOBAL BOOLEAN	for_flag = NO;		/* FOR Sub-command Active	*/

/*	I/O Redirection Control 	*/
GLOBAL WORD	in_flag = NULL;
GLOBAL WORD	out_flag = NULL;
GLOBAL UWORD	in_handle = NULL;
GLOBAL UWORD	out_handle = NULL;

/*	Pipe Control Data		*/
GLOBAL BOOLEAN	pipe_out = NO;		/* Activate Pipe output 	       */
GLOBAL BOOLEAN	pipe_in = NO;		/* Activate Pipe Input		       */
GLOBAL BOOLEAN	preserve_pipe = NO;

/*
 *	The following two structures are patched by NOVELL Version 2.1
 *	to force the creation of the PIPE files in the current sub-directory
 *	rather than the root. The '/' is patched to a '.' by the NET3.COM
 *	program.
 */

GLOBAL BYTE out_pipe[64] = "_:/\0_______.___";	/* Output Pipe Name "x:\filename.ext"  */

GLOBAL BYTE *old_pipe;			/* old pipe file name */


GLOBAL BYTE	pathchar[] = "\\";	/* The current path character. This */
					/* can be accessed as a byte using  */
					/* "*pathchar" or as a string using */
					/* "pathchar".			    */
#if defined(PASSWORD)
GLOBAL BYTE	pwdchar[] = ";";	/* The Password delimiter. Which can*/
					/* be accessed in the same way as   */
					/* pathchar.			    */
#endif

GLOBAL BYTE	switchar[] = "/";	/* Switch Character		    */

GLOBAL BYTE	dotdot[] = "..";
GLOBAL BYTE	d_slash_stardotstar[] = "x:\\*.*";

GLOBAL BOOLEAN	back_flag = FALSE;	/* Execute a BackGround Task*/
GLOBAL BOOLEAN  execed;   
GLOBAL WORD	page_len = 24;		/* Screen Length	    */
GLOBAL WORD	page_wid = 80;		/* Screen Width 	    */

GLOBAL BOOLEAN	break_flag;

GLOBAL BOOLEAN	err_flag;
GLOBAL UWORD	err_ret;

GLOBAL WORD	ddrive;
GLOBAL BYTE FAR	*bufaddr;		/* External Copy Buffer Address	*/
GLOBAL UWORD	bufsize; 		/* External Copy Buffer Size	*/

GLOBAL INTERNAT country;	/* country data structure	     */

#if defined(DOSPLUS)
GLOBAL BYTE	*ftypes[] = { "com", "exe", "bat", NULL};
#else
GLOBAL BYTE	*ftypes[] = { "cmd", "com", "exe", "bat", NULL};
#endif

/* This pointer is initialized by the Startup routine and   */
/* would be defined there if I could persuade the compiler  */
/* to reference it correctly.				    */

#if !defined(DOSPLUS)
#include	<pd.h>		/* PD Structure Declaration */

GLOBAL	PD FAR * CDECL pd = (PD FAR *) 1234L;	/* FAR pointer to our PD    */
GLOBAL WORD CDECL sysdat_seg = 0;		/* Segment address of SYSDAT */
#endif

GLOBAL	BOOLEAN	c_option = FALSE;
GLOBAL	BOOLEAN k_option = FALSE;
GLOBAL	BOOLEAN n_option = FALSE;
GLOBAL	BOOLEAN allow_pexec = FALSE;

GLOBAL	BYTE	FAR *gp_far_buff = 0L;
GLOBAL	BYTE	FAR *show_file_buf = 0L;

GLOBAL	UWORD	FAR *parent_psp;
GLOBAL	UWORD	save_parent;

#define FCONTROL struct fcc
MLOCAL FCONTROL {
	BOOLEAN  sflg;			/* FOR File Search Flag 	*/
	DTA	 search;		/* FOR Search structure 	*/
	BYTE	 *files;		/* FOR File list		*/
	BYTE	 *cmd;			/* FOR Command Line		*/
	BYTE	 forvar;		/* FOR variable char		*/
};

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
} FAR *batch, FAR *batch_save;		/* Master Batch Control Stucture     */

WORD	global_link;
WORD	global_strat;
WORD	global_in_hiload = 0;
WORD	hidden_umb[10];
