/*
;    File              : $Workfile: CONFIG.C$
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
;  ENDLOG
*/

/*
 * 28 Oct 87 Always decrement the MEMSIZE field by 0x0A paragraphs to
 *		allow for the SAT's.
 *  9 Nov 87 Recheck the login vector after detemining the specified
 *		drive in NETDRIVE.
 *  9 Dec 87 Always display Physically Remote drives as Remote. 
 * 28 Jan 88 Support the CTTY command for DOS Plus command interpreter
 * 27 May 88  Added string undefs.
 * 15 Jun 88 DBG is now permanent.
 * 23 Jun 88 Use new ONOFF function for XXX [=] ON|OFF parsing 
 * 29 Jun 88 Check OWNER field in ?CB for valid AUX and LIST devices
 *  5 Aug 88 Let L_SET and A_SET determine the validity of a Device No.
 * 12 Aug 88 Enforce default AUX and PRINTER on COM1 and LPT1 mapping
 *  7 Feb 89 Support the CHCP command for DR DOS
 * 14 Apr 89 cmd_chcp: Print relevant msg if ED_FILE returned
 * 30 Aug 89 DR Dos idle command
 * 30 Oct 89 "DEBUG is" moved to message.c (ie. non-resident)
 * 6-Mar-90  Watcom C v 7.0
 * 20-Sep-90 is_filechar() now takes pointer instead of byte.
 * 2-Oct-90  Prevent exec of XSTOP.EXE from within STOP command
 * 3-Oct-90  remove 8087 command
 * 4-Oct-90  Netdrive goes CCB based
 * 12-Oct-90 cmd_printer/cmd_aux removed (now part of printmap)
 * 12-Oct-90 NETDRIVE now says "netdrive d: /Local" to aid Richard
 *		(You can save and restore state in batch files)
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
#else
#include	<idle.h> /*#NOIDLE#*/
#endif

#include	"command.h"		/* COMMAND Definitions */
#include	"support.h"
#include	"dosif.h"		/* DOS interface definitions	 */
#include	"toupper.h"
#include	"global.h"

/*
 *	USER BEWARE
 *
 *	A process descriptor exists in both DOS Plus and Concurrent
 *	DOS. But is an internal Structure in DOS Plus and should only
 *	be used with the upmost care.
 */
#if !defined(DOSPLUS)
EXTERN PD FAR * CDECL pd;	/* Far pointer to Current PD */
#endif

MLOCAL VOID setflag(cmd, msg, field, flag)
BYTE *cmd;		/* Pointer to the Users Command Line	*/
BYTE *msg;		/* Status Message String		*/
UWORD FAR *field;	/* FAR pointer to the Flags field	*/
UWORD flag;		/* The Flag to be updated		*/
{

	switch(onoff(cmd)) {			/* Check for "=on/off"	    */
	    case YES:				/* Turn Flag ON		    */
		*field |= flag;
		break;

	    case NO:				/* Turn Flag OFF	    */
		*field &= ~flag;
		break;

	    default:
		if(*deblank(cmd))		/* Display an error message */
		    printf(MSG_ONOFF);		/* for a non blank commnad  */
		else
	    	    printf(msg, *field & flag ? MSG_ON : MSG_OFF);
		break;
	}
}

/*.pa*/
#if defined(CDOSTMP)
/*
 *	BREAK [ON|OFF]
 */
GLOBAL VOID CDECL cmd_break(cmd)
REG BYTE    *cmd;
{
	setflag(cmd, MSG_BREAK, (UWORD FAR *) &pd->P_SFLAG, PSF_BREAK);
}

/*
 *	VERIFY [ON|OFF]
 */
GLOBAL VOID CDECL cmd_verify(cmd)
REG BYTE    *cmd;
{
	setflag(cmd, MSG_VERIFY, (UWORD FAR *) &pd->P_SFLAG, PSF_VERIFY);
}

#else
/*
 *	BREAK [ON|OFF]
 *
 *	The break flag is emulated during by the COMMAND processor and
 *	only set to the users value when a program is loaded or when
 *	leaving COMMAND.COM using the EXIT command.
 */
GLOBAL VOID CDECL cmd_break(cmd)
REG BYTE    *cmd;
{
	switch(onoff(cmd)) {			/* Check for "=on/off"	    */
	    case YES:				/* Turn Flag ON		    */
		break_flag = YES;
		break;

	    case NO:				/* Turn Flag OFF	    */
		break_flag = NO;
		break;

	    default:
		if(*deblank(cmd))		/* Display an error message */
		    printf(MSG_ONOFF);		/* for a non blank commnad  */
		else
	    	    printf(MSG_BREAK, break_flag ? MSG_ON : MSG_OFF);
		break;
	}
}

/*
 *	VERIFY [ON|OFF]
 */
GLOBAL VOID CDECL cmd_verify(cmd)
REG BYTE    *cmd;
{
	switch(onoff(cmd)) {			/* Check for "=on/off"	    */
	    case YES:				/* Turn Flag ON		    */
		ms_f_verify(YES);
		break;

	    case NO:				/* Turn Flag OFF	    */
		ms_f_verify(NO);
		break;

	    default:
		if(*deblank(cmd))		/* Display an error message */
		    printf(MSG_ONOFF);		/* for a non blank commnad  */
		else
	    	    printf(MSG_VERIFY, ms_f_getverify() ? MSG_ON : MSG_OFF);
		break;
	}
}
#endif

#if defined(DOSPLUS)
/*
 *	CHCP [CodePage]
 *
 *	CHCP displays or changes the current global codepage
 *
 */
GLOBAL VOID CDECL cmd_chcp(cmd)
REG BYTE    *cmd;
{
	UWORD	systemcp, globalcp;
	WORD	ret;

	zap_spaces(cmd);
	if(*cmd) {
	    if(check_num(cmd, 0, 999, &globalcp))
		printf(INV_NUM);
	    else {
		if((ret = ms_x_setcp(globalcp)) < 0)
		    if (ret == ED_FILE)
		        printf (MSG_CPNF);
		    else
		        printf(MSG_BADCP, globalcp);
	    }
	}
	else {
	    ms_x_getcp(&globalcp, &systemcp);
	    printf(MSG_CURCP, globalcp);
	}
}

/*
 *	CTTY Device Name
 *
 *	CTTY redirects all console output to the specified character
 *	device. Note CTTY will only allow a DEVICE to be specified.
 *
 */
GLOBAL VOID CDECL cmd_ctty(cmd)
REG BYTE    *cmd;
{
	BYTE	device[MAX_FILELEN];
	WORD	h, j;

	get_filename(device, deblank(cmd), NO);	/* Extract the Device Name */

	FOREVER {
	    if((h = ms_x_open(device, OPEN_RW)) < 0)
	        break;

	    j = ms_x_ioctl(h);		/* Check the user specified a	*/
	    if((j & 0x0080) == 0) {	/* device or not. If a file was	*/
		ms_x_close(h);		/* Close the handle and quit	*/
		break;
	    }
	    
	    j |= 0x03;
	    ms_x_setdev(h,j);

	    ms_x_fdup(STDIN, h);	/* Force duplicate this handle	*/
	    ms_x_fdup(STDOUT, h);	/* onto STDIN, STDOUT and 	*/
	    ms_x_fdup(STDERR, h);	/* STDERR.			*/

	    /*
	     *	Update the internal variables which contain the handle
	     *	table index to be updated with the new values. So that
	     *	all the Command Processor error messages go to the right
	     *	device.
	     */
	    in_handle = out_handle = psp_poke(h, 0xFF);
	    psp_poke(h, in_handle);

	    ms_x_close(h);		/* Finally close the handle and	*/
	    return;			/* return to the caller.	*/
	}

	crlfflg = YES;			/* Display the Device Name	*/
	printf(MSG_NEEDDEV);		/* required error message and	*/
	return;				/* Terminate.			*/
}

/*#if 0	#NOIDLE#*/
/*
 *	IDLE [ON|OFF]
 */
GLOBAL VOID CDECL cmd_idle(cmd)
REG BYTE    *cmd;
{
IDLE_STATE FAR *idle;

	idle = ms_idle_ptr ();

	if (idle->flags & IDLE_ENABLE) {
	    printf(MSG_DISABLED);		/* say if idle is installed */
	    return;
	}

	switch(onoff(cmd)) {			/* Check for "=on/off"	    */
	    case YES:				/* Reset flag		    */
		idle->flags &= ~IDLE_ON;
		break;

	    case NO:				/* Set flag		*/
		idle->flags |= IDLE_ON;
		break;

	    default:
		if(*deblank(cmd))		/* Display an error message */
		    printf(MSG_ONOFF);		/* for a non blank commnad  */
		else
	    	    printf(MSG_IDLE, idle->flags & IDLE_ON ? MSG_OFF : MSG_ON);
		break;
	}
}
/*#endif #NOIDLE#*/
#endif

#if defined(CDOSTMP) || defined(CDOS)
/*
 *	Enforce the current PRINTER and AUX mapping for LPT1 and COM1.
 *	Using the console number and the number of devices supported
 *	update the correct mapping byte in the table.
 */

#define	INT17_PTR	0x0C46		/* List Mapping Table		*/
#define	INT14_PTR	0x0C48		/* Aux Mapping Table		*/

MLOCAL VOID map_device(tbl, dev)
UWORD	tbl;
UWORD	dev;
{
UBYTE	console;

	tbl = *SYSDATW(tbl);
	console = (UBYTE) bdos(C_GET, 0);
	*SYSDATB(tbl + (*SYSDATB(tbl) * console) +1) = (BYTE) dev;	
}

GLOBAL VOID CDECL cmd_stop(cmd)
REG BYTE    *cmd;
{
UWORD	vc_base, vc_num, pc_num, i;
struct {
	UWORD	pd;			/* PD address			*/
	UWORD	term;			/* Process termination Code	*/
	UWORD	cns;			/* Console Number and Zero field*/
	BYTE	name[8];		/* Process Name 		*/
	} apb;

	cmd = deblank(cmd);		/* Get the Process Name ABORT	*/

	if(!*cmd) {			/* If no command line options	*/
	    printf(MSG_BADSTOP);	/* return with syntax error	*/
	    return;			/* disk based version of STOP.	*/
	}

	memset(apb.name, ' ', 8);	/* Blank fill the Name Buffer	*/
	
	for(i=0; i < 8 && is_filechar(cmd); cmd++, i++)
	    apb.name[i] = toupper(*cmd);

	if(i == 0) {			/* If no valid process name was */
	    printf(MSG_BADSTOP);	/* given then return with a	*/
	    return;			/* syntax error.		*/
	}	    
	
	vc_data(&vc_base, &vc_num, &pc_num);

	if(check_num(cmd, 1, vc_num, &apb.cns)) {
	    printf(MSG_BADSTOP);
	    return;
	}
		    
	apb.pd = 0;			/* Zero Process Descriptor Field */
	apb.term = 0;			/* Only Abort User Process's     */
	apb.cns += vc_base - 1;		/* Force console number base 0	 */
	if(bdos(P_ABORT, &apb)) 	/* Abort the Process		 */
	    printf(MSG_BADSTOP);
}


/*
 *	BANK [ON|OFF]
 */
GLOBAL VOID CDECL cmd_bank(cmd)
REG BYTE    *cmd;
{
	setflag(cmd, MSG_BANK, (UWORD FAR *) &pd->P_PCMFLAG, PIDF_BANK);
}

/*
 *	SUSPEND [ON|OFF]
 */
GLOBAL VOID CDECL cmd_suspend(cmd)
REG BYTE    *cmd;
{
	setflag(cmd, MSG_SUSPEND, (UWORD FAR *) &pd->P_PCMFLAG, PIDF_SUSPEND);
}

/*
 *	IDLE [ON|OFF]
 */
GLOBAL VOID CDECL cmd_idle(cmd)
REG BYTE    *cmd;
{
	setflag(cmd, MSG_IDLE, (UWORD FAR *) &pd->P_PCMFLAG, PIDF_IDLE);
}


/*
 *	MEMSIZE [Memory Size (Kb)]
 */
GLOBAL VOID CDECL cmd_memsize(cmd)
REG BYTE    *cmd;
{
	UWORD	 kb, mmp;		/* number in kilobytes */

	mmp = *SYSDATW(MMP)/64;		/* Per Process Maximum in Kb	*/
	kb = (pd->P_PCMMEM + 0x0A)/64;	/* Convert to number of Kb	*/

	zap_spaces(cmd);
	if(*cmd) {
	    if(check_num(cmd, 0, MAX_MEMSIZE, &kb))
		printf (INV_NUM);
	    else {
	        if(kb == 0 || kb > mmp)		/* If MEMSIZE specified was */
		    kb = mmp;			/* out of range or was Zero */
		pd->P_PCMMEM = kb * 64 - 0x0A;	/* then use the MMP	    */
	    }
	}
	else
	    printf (MSG_MEMSIZE, kb);	     
}

/*
 *	LIMSIZE [Memory Size (Kb)]
 *
 *	This command sets the Maximum number of blocks to be allocated
 *	to a process using the LIM memory. The maximum field is fixed for
 *	Concurrent DOS XM to MAX_LIMSIZE but for Concurrent DOS 386 the
 *	LIMMAX field in the 386 data area is used.
 */
GLOBAL VOID CDECL cmd_limsize(cmd)
REG BYTE    *cmd;
{
	UWORD	 kb, limmax;		/* number in kilobytes */

	kb = pd->P_LIMMEM * 16;		/* get number of kilobytes */

	if(*SYSDATW(V386_PTR)) {		/* If this is Concurrent DOS 386 */
            if (*SYSDATW(*SYSDATW(V386_PTR) + 15)!=0xff) {
	        printf (MSG_LIMOFF);
                return;
            }
            else
                limmax = *SYSDATW(*SYSDATW(V386_PTR) + 18) * 16;
        }        
	else
	    limmax = MAX_LIMSIZE;

	zap_spaces(cmd);
	if(*cmd) {
	    if(check_num(cmd, 0, limmax, &kb))
		printf (INV_NUM);
	    else 
		pd->P_LIMMEM = (kb+15)/16;
	}
	else
	    printf (MSG_LIMSIZE, kb);	     
}

/*
 *	NETDRIVE d: [/A|/R|/L]
 *
 *	This command displays and modifies the current "network" status 
 *	of all physical drives currently logged in.
 *
 *	NETDRIVE d: /R		Treat as Networked Media
 *	NETDRIVE d: /L		Treat as Local Media
 *	NETDRIVE [d:|/A]	Display Network Status
 */

#define	NETDRIVE_ALL	(flags == 1)	/* Display ALL		*/
#define	NETDRIVE_LOCAL	(flags & 2)	/* Treat as LOCAL media	*/
#define	NETDRIVE_REMOTE	(flags & 4)	/* Treat as REMOTE media*/
#define	CCBLIST		0x0c3e
#define	CCB_NETVEC	0x0010

GLOBAL VOID CDECL cmd_netdrive(s)
REG BYTE    *s;
{
	BYTE	*cp;
	UWORD	login, network;		/* Login Vector 		*/
	WORD    ret;			/* General purpose variable	*/
	UWORD	flags;			/* Command Flags		*/
	UWORD	ccbptr;			/* address of CCB		*/
	UWORD	netvec;			/* address pseudo-net drive vec */


	/* We bodge flags to all "/Local" and "/Remote" by making "emotc" */
	/* into flags as well - we are only interested in the "alr" flags */

	f_check (s, "alremotc", &flags, YES);
	s = deblank(s);			    /* Deblank after the Flag Check */


	ccbptr = *SYSDATW(CCBLIST) + 2*pd->P_CNS;
	netvec = *SYSDATW(ccbptr) + CCB_NETVEC;

	login = network = (UWORD) network_drvs();
	login |= (UWORD) physical_drvs(); /* Physical Drive Vector	*/
	network |= *SYSDATW(netvec);	  /* Logically Remote Drives	*/

/*
 *	if NETDRIVE_ALL then display the network status of all the currently
 *	logged in physical drives.
 */
	if(NETDRIVE_ALL || !*s) {
	    for(ret = 0; ret < 16; ret++, login >>= 1, network >>=1)
		if(login & 1L) {
		    printf("Netdrive %c: %s\n", ret + 'A',
		    		       network & 1 ? MSG_REMOTE : MSG_LOCAL);
		}
	    return;
	}
	
	if(nofiles(s, ATTR_ALL, NO, NO))/* Abort if an illegal drive is   */
	    return; 			/* selected.			  */

	login &= ~((UWORD) network_drvs()); /* Invalidate Remote Drives	  */
	ret = 1 << ddrive;		/* Generate Bit vector and then	  */
	if((login & ret) == 0) {	/* check that this is a logged in */
	    e_check(ED_DRIVE);		/* physical drive		  */
	    return;
	}

	
	if(NETDRIVE_LOCAL) {
	    *SYSDATW(netvec) &= ~ret;		/* Local Drive		  */
	}
	else if(NETDRIVE_REMOTE) {
	    *SYSDATW(netvec) |= ret;		/* Remote Drive		  */
	}
	else {
	    printf("Netdrive %c: %s\n",  ddrive + 'A',
	    			network & ret ? MSG_REMOTE : MSG_LOCAL);
	}
}
#endif

#if !defined(FINAL) && !defined(DOSPLUS)
/*
 *	DBG [ON|OFF]
 */
GLOBAL VOID CDECL cmd_dbg(cmd)
REG BYTE    *cmd;
{
	setflag(cmd, MSG_DEBUG, (UWORD FAR *) &pd->P_SFLAG, PSF_DEBUG);
}
#endif

#if defined(CPM)
/*.pa*/
/*
 *
 */
EXTERN UWORD user;		/* Current User area */

GLOBAL VOID CDECL cmd_user(s)
REG BYTE *s;
{
        if(*s && check_num(s, 0, 15, &user))    /* If command line and its not */
            printf(INV_USER);                   /* a valid user area then invalid user */

        printf(CUR_USER, user); 
}
#endif
