/*    File              : $Workfile: MSERROR.H$
 *
 *    Description      : Part of APPSLIB.
 * 
 *    Original Author   : DIGITAL RESEARCH
 *
 *    Last Edited By    : $CALDERA$
 *
 *-----------------------------------------------------------------------;
 *    Copyright Work of Caldera, Inc. All Rights Reserved.
 *      
 *    THIS WORK IS A COPYRIGHT WORK AND CONTAINS CONFIDENTIAL,
 *    PROPRIETARY AND TRADE SECRET INFORMATION OF CALDERA, INC.
 *    ACCESS TO THIS WORK IS RESTRICTED TO (I) CALDERA, INC. EMPLOYEES
 *    WHO HAVE A NEED TO KNOW TO PERFORM TASKS WITHIN THE SCOPE OF
 *    THEIR ASSIGNMENTS AND (II) ENTITIES OTHER THAN CALDERA, INC. WHO
 *    HAVE ACCEPTED THE CALDERA OPENDOS SOURCE LICENSE OR OTHER CALDERA LICENSE
 *    AGREEMENTS. EXCEPT UNDER THE EXPRESS TERMS OF THE CALDERA LICENSE
 *    AGREEMENT NO PART OF THIS WORK MAY BE USED, PRACTICED, PERFORMED,
 *    COPIED, DISTRIBUTED, REVISED, MODIFIED, TRANSLATED, ABRIDGED,
 *    CONDENSED, EXPANDED, COLLECTED, COMPILED, LINKED, RECAST,
 *    TRANSFORMED OR ADAPTED WITHOUT THE PRIOR WRITTEN CONSENT OF
 *    CALDERA, INC. ANY USE OR EXPLOITATION OF THIS WORK WITHOUT
 *    AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND
 *    CIVIL LIABILITY.
 * ----------------------------------------------------------------------;
 *
 *    *** Current Edit History ***
 *    *** End of Current Edit History ***
 *
 *    $Log$
 *
 *   MSERROR.H 1.1 92/11/09 13:39:14 AHAY
 *   Converted to new build environment and version control system.
 *   
 *
 *   ENDLOG
 */

#define	ED_OK		   0		/* no error occured */
#define	ED_FUNCTION	(-1)		/* invalid function number */
#define	ED_FILE		(-2)		/* file not found */
#define	ED_PATH		(-3)		/* path not found */
#define	ED_HANDLE	(-4)		/* too many open files */
#define	ED_ACCESS	(-5)		/* file access denied */
#define	ED_H_MATCH	(-6)		/* invalid handle number */
#define	ED_DMD		(-7)		/* memory descriptor destroyed */
#define	ED_MEMORY	(-8)		/* insufficient memory */
#define	ED_BLOCK	(-9)		/* invalid memory block addr */
#define	ED_ENVIRON	(-10)		/* invalid environment */
#define	ED_FORMAT	(-11)		/* invalid format */
#define	ED_ACC_CODE	(-12)		/* invalid access code */
#define	ED_DATA		(-13)		/* invalid data */
#define	ED_DRIVE	(-15)		/* invalid drive specified */
#define	ED_DIR		(-16)		/* can't remove current dir */
#define	ED_DEVICE	(-17)		/* not same device */
#define	ED_ROOM		(-18)		/* no more files */

#define	ED_PROTECT	(-19)		/* disk write protected */
#define	ED_BADUNIT	(-20)		/* invalid drive specified */
#define	ED_NOTREADY	(-21)		/* drive doesn't respond */
#define	ED_BADCMD	(-22)		/* invalid command to driver */
#define	ED_BADDATA	(-23)		/* data CRC error */
#define	ED_BADSEEK	(-25)		/* can't seek to track */
#define	ED_BADMEDIA	(-26)		/* unrecognizable medium */
#define	ED_RNF		(-27)		/* record/sector not found */
#define	ED_NOPAPER	(-28)		/* printer error */
#define	ED_WRFAIL	(-29)		/* write failed */
#define	ED_RDFAIL	(-30)		/* read failed */
#define	ED_GENFAIL	(-31)		/* anything failed */
#define	ED_SHAREFAIL	(-32)		/* sharing conflict */
#define	ED_LOCKFAIL	(-33)		/* locking conflict */
#define	ED_DISKCHG	(-34)		/* invalid disk change */
#define	ED_NOFCBS	(-35)		/* FCB table exhausted */
#define	ED_NOLOCKS	(-36)		/* lock list items exhausted */

#define ED_NET		(-50)		/* Network request not supported */

#define ED_NETACCESS	(-65)		/* file access denied */

#define	ED_NETPWD	(-73)		/* Server Password Error */
#define	ED_NETVER	(-74)		/* Incorrect Server version */
#define	ED_NETREQ	(-75)		/* No Local Network Resources */
#define	ED_NETTIME	(-76)		/* Network Time Out Error */
#define	ED_NETCOMM	(-77)		/* Network Communications Error */
#define	ED_NETSRVR	(-78)		/* No Server Network Resources  */
#define	ED_NETLOG	(-79)		/* Server Not Logged In */

#define	ED_EXISTS	(-80)		/* file already exists */
#define	ED_MAKE		(-82)		/* cannot make (files ??) */
#define	ED_FAIL		(-83)		/* FAIL code returned from INT 24 */
#define	ED_STRUCT	(-84)		/* out of structures */
#define	ED_ASSIGN	(-85)		/* already assigned */
#define	ED_PASSWORD	(-86)		/* invalid password */
#define	ED_PARAM	(-87)		/* invalid parameter */
#define ED_NETWRITE	(-88)		/* network write fault */
#define ED_NETFUNC	(-89)		/* function not supported on network */
#define ED_COMPONENT	(-90)		/* component not installed */
#define	ED_LASTERROR	(-90)		/* last error number used */

#define	ACTION_USER	3		/* ask user to reenter input */
#define	ACTION_USER_INT	7		/* user intervention required */
