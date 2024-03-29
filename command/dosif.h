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

#include "dos7.h"

EXTERN VOID CDECL debug( VOID );

#define EXT_SUBST 1

#if defined( MSC ) || defined( MWC ) || defined( TURBOC ) ||                 \
   defined( __WATCOMC__ )
#define bdos _BDOS
EXTERN BYTE *CDECL heap_get( WORD );
EXTERN BYTE *CDECL heap( VOID );
EXTERN VOID CDECL heap_set( BYTE * );
EXTERN UWORD CDECL heap_size( VOID );
#endif

#if !defined( MWC )
EXTERN BYTE *CDECL stack( WORD );
#endif

EXTERN VOID CDECL ms_drv_set( WORD );
EXTERN WORD CDECL ms_drv_get( VOID );
EXTERN WORD CDECL ms_drv_space( UWORD, UWORD *, UWORD *, UWORD * );
EXTERN WORD CDECL ms_x_chdir( BYTE * );
EXTERN WORD CDECL ms_x_mkdir( BYTE * );
EXTERN WORD CDECL ms_x_rmdir( BYTE * );
EXTERN WORD CDECL ms_s_country( INTERNAT * );
EXTERN BYTE CDECL dr_toupper( BYTE );
EXTERN WORD CDECL ms_x_creat( BYTE *, UWORD );
EXTERN WORD CDECL ms_x_open( BYTE *, UWORD );
EXTERN WORD CDECL ms_x_close( WORD );
EXTERN WORD CDECL ms_x_fdup( UWORD, UWORD );
EXTERN WORD CDECL ms_x_unique( BYTE *, UWORD );
EXTERN WORD CDECL far_read( UWORD, BYTE FAR *, UWORD );
EXTERN WORD CDECL far_write( UWORD, BYTE FAR *, UWORD );
EXTERN WORD CDECL ms_x_read( UWORD, BYTE *, UWORD );
EXTERN WORD CDECL ms_x_write( UWORD, BYTE *, UWORD );
EXTERN WORD CDECL ms_x_unlink( BYTE * );
EXTERN LONG CDECL ms_x_lseek( UWORD, LONG, UWORD );
EXTERN WORD CDECL ms_x_ioctl( UWORD );
EXTERN WORD CDECL ms_x_setdev( UWORD, UBYTE );
EXTERN WORD CDECL ms_x_chmod( BYTE *, UWORD, UWORD );
EXTERN WORD CDECL ms_x_curdir( UWORD, BYTE * );
EXTERN WORD CDECL ms_x_wait( VOID );
EXTERN WORD CDECL ms_x_first( BYTE *, UWORD, DTA * );
EXTERN WORD CDECL ms_x_next( DTA * );
EXTERN WORD CDECL ms_x_rename( BYTE *, BYTE * );
EXTERN WORD CDECL ms_x_datetime( BOOLEAN, UWORD, UWORD *, UWORD * );
EXTERN WORD CDECL ms_settime( SYSTIME * );
EXTERN WORD CDECL ms_setdate( SYSDATE * );
EXTERN VOID CDECL ms_gettime( SYSTIME * );
EXTERN VOID CDECL ms_getdate( SYSDATE * );
EXTERN VOID FAR *CDECL ms_idle_ptr( VOID );
EXTERN WORD CDECL ms_switchar( VOID );
EXTERN WORD CDECL ms_x_expand( BYTE *, BYTE * );

EXTERN WORD CDECL ms_edrv_space( BYTE *, BYTE *, UWORD );
EXTERN WORD CDECL ms_l_first( BYTE *, UWORD, FINDD * );
EXTERN WORD CDECL ms_l_next( UWORD, FINDD * );
EXTERN WORD CDECL ms_l_findclose( UWORD );
EXTERN WORD CDECL ms_l_unlink( BYTE *, UWORD );
EXTERN WORD CDECL ms_l_rename( BYTE *, BYTE * );
EXTERN WORD CDECL ms_l_expand( BYTE *, BYTE * );
EXTERN WORD CDECL ms_l_chdir( BYTE * );
EXTERN WORD CDECL ms_l_chmod( BYTE *, UWORD, UWORD );
EXTERN WORD CDECL ms_l_curdir( UWORD, BYTE * );
EXTERN WORD CDECL ms_l_rmdir( BYTE * );
EXTERN WORD CDECL ms_l_mkdir( BYTE * );
EXTERN WORD CDECL ms_l_creat( BYTE *, UWORD );
EXTERN WORD CDECL ms_l_open( BYTE *, UWORD );

EXTERN VOID CDECL mem_alloc( BYTE FAR *NEAR *, UWORD *, UWORD, UWORD );
EXTERN VOID CDECL mem_free( BYTE FAR *NEAR * );

EXTERN UWORD CDECL psp_poke( UWORD, UWORD ); /* Poke Handle Table	    */

EXTERN BOOLEAN CDECL dbcs_expected( VOID );
EXTERN BOOLEAN CDECL dbcs_lead( BYTE );

EXTERN UWORD CDECL ioctl_ver( VOID );
EXTERN VOID CDECL ms_x_exit();
EXTERN VOID CDECL ms_f_verify( BOOLEAN );
EXTERN BOOLEAN CDECL ms_set_break( BOOLEAN );
EXTERN WORD CDECL ms_f_getverify( VOID );
EXTERN WORD CDECL ms_f_parse( BYTE *, BYTE *, UBYTE );
EXTERN WORD CDECL ms_f_delete( BYTE * );
EXTERN VOID CDECL restore_term_addr();

EXTERN UWORD CDECL get_lastdrive( VOID );
EXTERN UWORD CDECL get_driveflags( UWORD );
EXTERN UWORD CDECL conv64( ULONG *, ULONG * );

EXTERN WORD CDECL ms_x_getcp( UWORD *, UWORD * );
EXTERN WORD CDECL ms_x_setcp( UWORD );
/*EXTERN VOID CDECL     hiload_set(BOOLEAN);*/
EXTERN WORD CDECL get_upper_memory_link( VOID );
EXTERN VOID CDECL set_upper_memory_link( WORD );
EXTERN WORD CDECL get_alloc_strategy( VOID );
EXTERN VOID CDECL set_alloc_strategy( WORD );
EXTERN WORD CDECL alloc_region();
EXTERN VOID CDECL free_region( WORD );

EXTERN BOOLEAN CDECL env_entry( BYTE *, UWORD ); /* CSUP.ASM	*/
EXTERN BOOLEAN CDECL env_scan( BYTE *, BYTE * ); /* CSUP.ASM	*/
EXTERN BOOLEAN CDECL env_del( BYTE * );          /* CSUP.ASM	*/
EXTERN BOOLEAN CDECL env_ins( BYTE * );          /* CSUP.ASM	*/

EXTERN BOOLEAN CDECL get_cmdname( BYTE * ); /* CSUP.ASM	*/

#define system msdos /* Call the MSDOS Function for Common routines	*/
EXTERN WORD CDECL msdos();
EXTERN WORD CDECL readline( BYTE * );

#if !defined( EXT_SUBST )
EXTERN ULONG CDECL logical_drvs( VOID );
EXTERN UWORD CDECL pdrive( UWORD );
#endif
EXTERN UWORD CDECL exec( BYTE *, UWORD, BYTE *, BOOLEAN );

EXTERN BOOLEAN CDECL physical_drive( WORD );
EXTERN BOOLEAN CDECL logical_drive( WORD );
EXTERN BOOLEAN CDECL network_drive( WORD );
EXTERN BOOLEAN CDECL extended_error( VOID );
EXTERN WORD CDECL get_lines_page( VOID );
EXTERN WORD CDECL get_scr_width( VOID );
EXTERN WORD CDECL novell_copy( WORD, WORD, ULONG );

#define COLDATA struct coldata
COLDATA
{
   BYTE flags;
   BYTE fgbg;
   BYTE border;
};

EXTERN VOID CDECL get_colour( COLDATA * );
EXTERN VOID CDECL set_colour( COLDATA * );
