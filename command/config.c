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

#include <string.h>

#if defined( MWC ) && defined( strlen )
#undef strcmp /* These are defined as macros in string.h */
#undef strcpy /* which are expaneded in line under */
#undef strlen /* Metaware C. These undefs avoid this. */
#endif

#include <idle.h> /*#NOIDLE#*/
#include <mserror.h>
#include <portab.h>

#include "command.h" /* COMMAND Definitions */
#include "dosif.h"   /* DOS interface definitions	 */
#include "global.h"
#include "support.h"
#include "toupper.h"

MLOCAL VOID setflag( BYTE *cmd, BYTE *msg, UWORD FAR *field, UWORD flag )
/* cmd: Pointer to the Users Command Line	*/
/* msg: Status Message String		*/
/* field: FAR pointer to the Flags field	*/
/* flag: The Flag to be updated		*/
{

   switch ( onoff( cmd ) ) { /* Check for "=on/off"	    */
   case YES:                 /* Turn Flag ON		    */
      *field |= flag;
      break;

   case NO: /* Turn Flag OFF	    */
      *field &= ~flag;
      break;

   default:
      if ( *deblank( cmd ) ) { /* Display an error message */
         printf( MSG_ONOFF );  /* for a non blank commnad  */
      }
      else {
         printf( msg, *field & flag ? MSG_ON : MSG_OFF );
      }
      break;
   }
}

/*
 *	BREAK [ON|OFF]
 *
 *	The break flag is emulated during by the COMMAND processor and
 *	only set to the users value when a program is loaded or when
 *	leaving COMMAND.COM using the EXIT command.
 */
GLOBAL VOID CDECL cmd_break( REG BYTE *cmd )
{
   switch ( onoff( cmd ) ) { /* Check for "=on/off"	    */
   case YES:                 /* Turn Flag ON		    */
      break_flag = YES;
      break;

   case NO: /* Turn Flag OFF	    */
      break_flag = NO;
      break;

   default:
      if ( *deblank( cmd ) ) { /* Display an error message */
         printf( MSG_ONOFF );  /* for a non blank commnad  */
      }
      else {
         printf( MSG_BREAK, break_flag ? MSG_ON : MSG_OFF );
      }
      break;
   }
}

/*
 *	VERIFY [ON|OFF]
 */
GLOBAL VOID CDECL cmd_verify( REG BYTE *cmd )
{
   switch ( onoff( cmd ) ) { /* Check for "=on/off"	    */
   case YES:                 /* Turn Flag ON		    */
      ms_f_verify( YES );
      break;

   case NO: /* Turn Flag OFF	    */
      ms_f_verify( NO );
      break;

   default:
      if ( *deblank( cmd ) ) { /* Display an error message */
         printf( MSG_ONOFF );  /* for a non blank commnad  */
      }
      else {
         printf( MSG_VERIFY, ms_f_getverify() ? MSG_ON : MSG_OFF );
      }
      break;
   }
}

/*
 *	CHCP [CodePage]
 *
 *	CHCP displays or changes the current global codepage
 *
 */
GLOBAL VOID CDECL cmd_chcp( REG BYTE *cmd )
{
   UWORD systemcp, globalcp;
   WORD ret;

   zap_spaces( cmd );
   if ( *cmd ) {
      if ( check_num( cmd, 0, 999, &globalcp ) ) {
         printf( INV_NUM );
      }
      else {
         if ( ( ret = ms_x_setcp( globalcp ) ) < 0 ) {
            if ( ret == ED_FILE ) {
               printf( MSG_CPNF );
            }
            else {
               printf( MSG_BADCP, globalcp );
            }
         }
      }
   }
   else {
      ms_x_getcp( &globalcp, &systemcp );
      printf( MSG_CURCP, globalcp );
   }
}

/*
 *	CTTY Device Name
 *
 *	CTTY redirects all console output to the specified character
 *	device. Note CTTY will only allow a DEVICE to be specified.
 *
 */
GLOBAL VOID CDECL cmd_ctty( REG BYTE *cmd )
{
   BYTE device[MAX_FILELEN];
   WORD h, j;

   get_filename( device, deblank( cmd ), NO ); /* Extract the Device Name */

   FOREVER
   {
      if ( ( h = ms_x_open( device, OPEN_RW ) ) < 0 ) {
         break;
      }

      j = ms_x_ioctl( h );         /* Check the user specified a	*/
      if ( ( j & 0x0080 ) == 0 ) { /* device or not. If a file was	*/
         ms_x_close( h );          /* Close the handle and quit	*/
         break;
      }

      j |= 0x03;
      ms_x_setdev( h, j );

      ms_x_fdup( STDIN, h );  /* Force duplicate this handle	*/
      ms_x_fdup( STDOUT, h ); /* onto STDIN, STDOUT and 	*/
      ms_x_fdup( STDERR, h ); /* STDERR.			*/

      /*
	     *	Update the internal variables which contain the handle
	     *	table index to be updated with the new values. So that
	     *	all the Command Processor error messages go to the right
	     *	device.
	     */
      in_handle = out_handle = psp_poke( h, 0xFF );
      psp_poke( h, in_handle );

      ms_x_close( h ); /* Finally close the handle and	*/
      return;          /* return to the caller.	*/
   }

   crlfflg = YES;         /* Display the Device Name	*/
   printf( MSG_NEEDDEV ); /* required error message and	*/
   return;                /* Terminate.			*/
}

/*#if 0	#NOIDLE#*/
/*
 *	IDLE [ON|OFF]
 */
GLOBAL VOID CDECL cmd_idle( REG BYTE *cmd )
{
   IDLE_STATE FAR *idle;

   idle = ms_idle_ptr();

   if ( idle->flags & IDLE_ENABLE ) {
      printf( MSG_DISABLED ); /* say if idle is installed */
      return;
   }

   switch ( onoff( cmd ) ) { /* Check for "=on/off"	    */
   case YES:                 /* Reset flag		    */
      idle->flags &= ~IDLE_ON;
      break;

   case NO: /* Set flag		*/
      idle->flags |= IDLE_ON;
      break;

   default:
      if ( *deblank( cmd ) ) { /* Display an error message */
         printf( MSG_ONOFF );  /* for a non blank commnad  */
      }
      else {
         printf( MSG_IDLE, idle->flags & IDLE_ON ? MSG_OFF : MSG_ON );
      }
      break;
   }
}

