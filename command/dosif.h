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

EXTERN	VOID	CDECL	debug(VOID);

#define	EXT_SUBST 1

#if defined(MSC) || defined(MWC) || defined(TURBOC) || defined(__WATCOMC__)
#define 	bdos	      _BDOS
EXTERN BYTE * CDECL   heap_get(WORD);
EXTERN BYTE * CDECL   heap(VOID);
EXTERN VOID CDECL     heap_set(BYTE *);
#endif

#if !defined(MWC)
EXTERN BYTE * CDECL   stack(WORD);
#endif

#if defined(CPM)
#define     ms_drv_space         cpm_drv_space
#define     ms_x_mkdir           cpm_x_mkdir
#define     ms_x_rmdir           cpm_x_rmdir
#define     ms_x_creat           cpm_x_creat
#define     ms_x_open            cpm_x_open
#define     ms_x_close           cpm_x_close
#define     far_read             cpm_far_read
#define     far_write            cpm_far_write
#define     ms_x_read            cpm_x_read
#define     ms_x_write           cpm_x_write
#define     ms_x_unlink          cpm_x_unlink
#define     ms_x_lseek           cpm_x_lseek
#define	    ms_x_ioctl		 cpm_x_ioctl
#define     ms_x_chmod           cpm_x_chmod
#define     ms_x_curdir          cpm_x_curdir
#define     ms_x_first           cpm_x_first
#define     ms_x_next            cpm_x_next
#define     ms_x_rename          cpm_x_rename
#define     ms_x_datetime        cpm_x_datetime
#endif

EXTERN VOID CDECL     ms_drv_set(WORD);
EXTERN WORD CDECL     ms_drv_get(VOID);
EXTERN WORD CDECL     ms_drv_space(UWORD, UWORD * ,UWORD *, UWORD *);
EXTERN WORD CDECL     ms_x_chdir(BYTE *);
EXTERN WORD CDECL     ms_x_mkdir(BYTE *);
EXTERN WORD CDECL     ms_x_rmdir(BYTE *);
EXTERN WORD CDECL     ms_s_country(INTERNAT *);
EXTERN BYTE CDECL     toupper(BYTE);
EXTERN WORD CDECL     ms_x_creat(BYTE *, UWORD);
EXTERN WORD CDECL     ms_x_open(BYTE *, UWORD);
EXTERN WORD CDECL     ms_x_close(WORD);
EXTERN WORD CDECL     ms_x_fdup(UWORD, UWORD);
EXTERN WORD CDECL     ms_x_unique(BYTE *, UWORD);
EXTERN WORD CDECL     far_read(UWORD, BYTE FAR *, UWORD);
EXTERN WORD CDECL     far_write(UWORD, BYTE FAR *, UWORD);
EXTERN WORD CDECL     ms_x_read(UWORD, BYTE *, UWORD);
EXTERN WORD CDECL     ms_x_write(UWORD, BYTE *, UWORD);
EXTERN WORD CDECL     ms_x_unlink(BYTE *);
EXTERN LONG CDECL     ms_x_lseek(UWORD, LONG, UWORD);
EXTERN WORD CDECL     ms_x_ioctl(UWORD);
EXTERN WORD CDECL     ms_x_setdev(UWORD, UBYTE);
EXTERN WORD CDECL     ms_x_chmod(BYTE *, UWORD, UWORD);
EXTERN WORD CDECL     ms_x_curdir(UWORD, BYTE *);
EXTERN WORD CDECL     ms_x_wait(VOID);
EXTERN WORD CDECL     ms_x_first(BYTE *, UWORD, DTA *);
EXTERN WORD CDECL     ms_x_next(DTA *);
EXTERN WORD CDECL     ms_x_rename(BYTE *, BYTE *);
EXTERN WORD CDECL     ms_x_datetime(BOOLEAN, UWORD, UWORD *, UWORD *);
EXTERN WORD CDECL     ms_settime(SYSTIME *);
EXTERN WORD CDECL     ms_setdate(SYSDATE *);
EXTERN VOID CDECL     ms_gettime(SYSTIME *);
EXTERN VOID CDECL     ms_getdate(SYSDATE *);
EXTERN VOID FAR * CDECL ms_idle_ptr(VOID);
EXTERN WORD CDECL     ms_switchar(VOID);
EXTERN WORD CDECL     ms_x_expand(BYTE *, BYTE *);

EXTERN VOID CDECL     mem_alloc(BYTE FAR * NEAR *, UWORD *, UWORD, UWORD);
EXTERN VOID CDECL     mem_free (BYTE FAR * NEAR *);

EXTERN UWORD  CDECL psp_poke(UWORD, UWORD);	/* Poke Handle Table	    */

EXTERN BOOLEAN	CDECL	dbcs_expected(VOID);
EXTERN BOOLEAN	CDECL	dbcs_lead(BYTE);

#if !defined(CDOSTMP)
EXTERN UWORD CDECL    ioctl_ver(VOID);
EXTERN VOID CDECL     ms_x_exit();
EXTERN VOID CDECL     ms_f_verify(BOOLEAN);
EXTERN BOOLEAN CDECL  ms_set_break(BOOLEAN);
EXTERN WORD CDECL     ms_f_getverify(VOID);
EXTERN WORD CDECL     ms_f_parse (BYTE *, BYTE *, UBYTE);
EXTERN WORD CDECL     ms_f_delete (BYTE *);
EXTERN VOID CDECL     restore_term_addr();
#endif

#if defined(DOSPLUS)
EXTERN WORD CDECL     ms_x_getcp(UWORD *, UWORD *);
EXTERN WORD CDECL     ms_x_setcp(UWORD);
/*EXTERN VOID CDECL     hiload_set(BOOLEAN);*/
EXTERN WORD CDECL     get_upper_memory_link(VOID);
EXTERN VOID CDECL     set_upper_memory_link(WORD);
EXTERN WORD CDECL     get_alloc_strategy(VOID);
EXTERN VOID CDECL     set_alloc_strategy(WORD);
EXTERN WORD CDECL     alloc_region();
EXTERN VOID CDECL     free_region(WORD);
#endif

EXTERN BOOLEAN CDECL  env_entry(BYTE *, UWORD); 	/* CSUP.ASM	*/
EXTERN BOOLEAN CDECL  env_scan(BYTE *, BYTE *); 	/* CSUP.ASM	*/
EXTERN BOOLEAN CDECL  env_del(BYTE *);			/* CSUP.ASM	*/
EXTERN BOOLEAN CDECL  env_ins(BYTE *);			/* CSUP.ASM	*/

#if defined(CDOSTMP)
#define	system	bdos	/* Call the BDOS Function for Common routines	*/
#else
#define	system	msdos	/* Call the MSDOS Function for Common routines	*/
EXTERN WORD CDECL     msdos();
EXTERN WORD CDECL     readline(BYTE *);
#endif

#if defined(CDOSTMP) || defined(CDOS)
EXTERN VOID CDECL     vc_data(UWORD *, UWORD *, UWORD *);
EXTERN WORD CDECL     bdos(WORD,...);
#endif

#if !defined(DOSPLUS) || !defined(EXT_SUBST)
EXTERN ULONG CDECL    physical_drvs(VOID);
EXTERN ULONG CDECL    network_drvs(VOID);
#endif
#if !defined(EXT_SUBST)
EXTERN ULONG CDECL    logical_drvs(VOID);
EXTERN UWORD CDECL    pdrive(UWORD);
#endif
EXTERN UWORD CDECL    exec(BYTE *, UWORD, BYTE *, BOOLEAN);

#if !defined(DOSPLUS)
EXTERN UWORD FAR * CDECL sysdat(UWORD);	
#define SYSDATW(x)	sysdat(x)
#define SYSDATB(x)	((UBYTE FAR *) sysdat(x))
#endif

EXTERN	BOOLEAN	CDECL	physical_drive(WORD);
EXTERN	BOOLEAN	CDECL	logical_drive(WORD);
EXTERN	BOOLEAN	CDECL	network_drive(WORD);
EXTERN	BOOLEAN CDECL	extended_error(VOID);
EXTERN	WORD	CDECL	get_lines_page(VOID);
EXTERN	WORD	CDECL	get_scr_width(VOID);
EXTERN	WORD	CDECL	novell_copy(WORD,WORD,ULONG);
