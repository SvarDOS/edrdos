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

EXTERN BOOLEAN	initflg;		/* Initial Load Flag		     */
EXTERN WORD	drive;			/* Current default Drive	     */
EXTERN UWORD	echoflg;		/* Current Echo Status		     */
EXTERN BOOLEAN	crlfflg;		/* CR/LF Required before prompt      */

/*	Batch File Processing Variables */
EXTERN UWORD	batchflg;		/* Currently processing Batch File   */

/*	FOR Sub-Command Variables	*/
EXTERN BOOLEAN	for_flag;		/* FOR Sub-command Active	*/

/*	I/O Redirection Control 	*/
EXTERN WORD	in_flag;
EXTERN WORD	out_flag;
EXTERN WORD	in_handle;
EXTERN WORD	out_handle;

/*	Pipe Control Data		*/
EXTERN BOOLEAN	pipe_out;		/* Activate Pipe output 	       */
EXTERN BOOLEAN	pipe_in;		/* Activate Pipe Input		       */
EXTERN BOOLEAN  preserve_pipe;
EXTERN BYTE	out_pipe[];		/* Output Pipe Name "x:\filename.ext"  */
EXTERN BYTE	*old_pipe;

EXTERN BYTE	pathchar[];		/* The current path character. This */
					/* can be accessed as a byte using  */
					/* "*pathchar" or as a string using */
					/* "pathchar".			    */
#if defined(PASSWORD)
EXTERN BYTE	pwdchar[];		/* The Password delimiter. Which can*/
					/* be accessed in the same way as   */
					/* pathchar.			    */
#endif

EXTERN BYTE	switchar[];		/* Switch Character		    */

EXTERN BYTE	dotdot[];
EXTERN BYTE	d_slash_stardotstar[];

EXTERN BOOLEAN	back_flag;		/* Execute a BackGround Task*/
EXTERN BOOLEAN	execed; 		/* were we execed from DOS? */
EXTERN WORD	page_len;		/* Screen Length	    */
EXTERN WORD	page_wid;		/* Screen Width 	    */

EXTERN BOOLEAN	break_flag;
EXTERN BOOLEAN	err_flag;
EXTERN UWORD	err_ret;

EXTERN WORD	ddrive;
EXTERN BYTE FAR	*bufaddr;		/* External Copy Buffer Address	*/
EXTERN UWORD	bufsize; 		/* External Copy Buffer Size	*/

EXTERN INTERNAT country;		/* country data structure	*/
#define	JAPAN		81		/* country.code for Japan       */

EXTERN BYTE	*ftypes[];

EXTERN BOOLEAN	c_option;
EXTERN BOOLEAN	k_option;
EXTERN BOOLEAN	n_option;
EXTERN BOOLEAN	allow_pexec;

EXTERN BYTE FAR *gp_far_buff;
EXTERN BYTE FAR *show_file_buf;
EXTERN UWORD FAR *parent_psp;
EXTERN UWORD save_parent;

#define FCONTROL struct fcc
FCONTROL {
	BOOLEAN  sflg;			/* FOR File Search Flag 	*/
	DTA	 search;		/* FOR Search structure 	*/
	BYTE	 *files;		/* FOR File list		*/
	BYTE	 *cmd;			/* FOR Command Line		*/
	BYTE	 forvar;		/* FOR variable char		*/
};

#define BCONTROL struct bcc
BCONTROL {
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
}; 
EXTERN BCONTROL FAR *batch;
EXTERN BCONTROL FAR *batch_save;


EXTERN	WORD	global_link;
EXTERN	WORD	global_strat;
EXTERN	WORD	global_in_hiload;
EXTERN	WORD	hidden_umb[10];

/*
 *	File type index's returned by the Concurrent DOS P_PATH function
 *	and emulated in the findfile function. DOSPLUS does not search
 *	for the ".CMD" and therefore uses a modified index.
 *
 */ 
#if defined(DOSPLUS) || defined(NETWARE) 
#define COM_FILETYPE	0		/* MicroSoft .COM	*/
#define EXE_FILETYPE	1		/* MicroSoft .EXE	*/
#define BAT_FILETYPE	2		/* Batch File		*/
#else
#define CMD_FILETYPE	0		/* Digital Reseach .CMD */
#define COM_FILETYPE	1		/* MicroSoft .COM	*/
#define EXE_FILETYPE	2		/* MicroSoft .EXE	*/
#define BAT_FILETYPE	3		/* Batch File		*/
#endif

#define ERROR_EXIT	0x0200		/* Exit because of a Critical Error */
#define BREAK_EXIT	0x0100		/* Exit because of a Control-Break  */
