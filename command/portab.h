/****************************************************************************
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
*
*	  C P / M   C   R U N   T I M E   L I B   H E A D E R   F I L E
*	  -------------------------------------------------------------
*
*	This is an include file for assisting the user to write portable
*	programs for C.  All processor dependencies should be located here.
*
****************************************************************************/

#ifdef drc
#define DRC
#endif

/*
 *	Standard type definitions
 */
#define	BYTE	char				/* Signed byte		   */
#ifdef DRC
#define UBYTE	char				/* Unsigned byte 	   */
#else
#define UBYTE	unsigned char			/* Unsigned byte 	   */
#endif
#define BOOLEAN	int				/* 2 valued (true/false)   */
#define	WORD	int  				/* Signed word (16 bits)   */
#define	UWORD	unsigned int			/* unsigned word	   */

#define	LONG	long				/* signed long (32 bits)   */
#ifdef DRC
#define	ULONG	long				/* Unsigned long	   */
#else
#define	ULONG	unsigned long			/* Unsigned long	   */
#endif

#define	REG	register			/* register variable	   */
#define	LOCAL	auto				/* Local var on 68000	   */
#define	EXTERN	extern				/* External variable	   */
#define	MLOCAL	static				/* Local to module	   */
#define	GLOBAL	/**/				/* Global variable	   */
#define VOID	void
#define	DEFAULT	int				/* Default size		   */
#define FLOAT	float				/* Floating Point	   */
#define DOUBLE	double				/* Double precision	   */

#ifdef __WATCOMC__				/* Watcom C Version 7.00     */
/* define pragma for 'cdecl' keyword to match Microsoft conventions */
#pragma aux cdecl "_*" parm caller []\
   value struct float struct routine [ax]  modify [ax bx cx dx es];

#pragma aux pascal "*" parm routine reverse []\
   value struct float struct routine [ax]  modify [ax bx cx dx es];
/*#define WATCOMC 1				/* Watcom C v7.0	     */
#define	CDECL	cdecl				/* C calling convention	     */
#define	PASCAL	pascal				/* Pascal Calling Convention */
#define FAR	far				/* FAR pointer or Function   */
#define NEAR	near				/* NEAR pointer or Function  */
#define	CONST	/**/				/* CONSTANT Value	     */
#define	VOLATILE /**/				/* VOLATILE must Always Read */

#else
#ifdef MSC                  
#define	CDECL	cdecl				/* C calling convention	     */
#define	PASCAL	pascal				/* Pascal Calling Convention */
#define FAR	far				/* FAR pointer or Function   */
#define NEAR	near				/* NEAR pointer or Function  */
#define	CONST	/**/				/* CONSTANT Value	     */
#define	VOLATILE /**/				/* VOLATILE must Always Read */

#else
#ifdef MSC5                
#define	CDECL	cdecl				/* C calling convention	     */
#define	PASCAL	pascal				/* Pascal Calling Convention */
#define FAR	far				/* FAR pointer or Function   */
#define NEAR	near				/* NEAR pointer or Function  */
#define	CONST	const				/* CONSTANT value -- R/O     */
#define	VOLATILE volatile			/* VOLATILE must always read */

#else
#ifdef __TURBOC__				/* Borland TurboC Ver 1.50   */
#define	TURBOC	1				/* Define TURBOC	     */
#define	CDECL	cdecl				/* C calling convention	     */
#define	PASCAL	pascal				/* Pascal Calling Convention */
#define FAR	far				/* FAR pointer or Function   */
#define NEAR	near				/* NEAR pointer or Function  */
#define	CONST	const				/* CONSTANT value -- R/O     */
#define	VOLATILE volatile			/* VOLATILE must always read */

#else
#ifdef __HIGHC__			/* MetaWare High C	     */
#define METAWARE 1			/* High C version 1.4		*/

#define	_PASCAL_CONV _CALLEE_POPS_STACK|_SAVE_REGS
#define	_C_CONV _REVERSE_PARMS
#define	FIXFUNC	pragma Global_aliasing_convention("%C%r");
#define	VARFUNC	pragma Global_aliasing_convention("_%a%r");
					/********************************/
#define	CDECL	_cc (_C_CONV|_SAVE_REGS)/* MS C conventions		*/
#define	PASCAL	_cc (_PASCAL_CONV)	/* MS Pascal conventions	*/
#define	FAR	_far			/* FAR pointer or function	*/
#define NEAR	_near			/* NEAR pointer or function 	*/
#define	CONST	const			/* CONSTANT value -- R/O	*/
#define	VOLATILE volatile		/* VOLATILE must always read	*/
					/********************************/
pragma Calling_convention (_C_CONV,_DEFAULT);
VARFUNC					/* set default to C		*/
					/********************************/
pragma On (Optimize_for_space);		/* space, not speed		*/
pragma On (Quiet);			/* don't be too verbose		*/
pragma Off (Public_var_warnings);	/* referenced before set	*/
pragma Code ("_TEXT");			/* MSC compatible		*/
pragma Static_segment ("_DATA");	/* MSC compatible		*/
pragma Literals ("_DATA");		/* put constants into _DATA	*/
pragma On (Char_default_unsigned);	/* unsigned is safer		*/
pragma Off (Push_regsize);		/* push [mem] is safe		*/
					/********************************/
#ifdef QUIET				/********************************/
pragma On (PCC_msgs);			/* don't talk too much -	*/
#endif					/*   UNIX PCC errors only...	*/
					/********************************/
#ifdef REG				/* if register defined already	*/
#undef REG				/* redefine register variables	*/
#endif					/*				*/
#define	REG /**/			/* make it ignore register vars	*/
pragma Off (Use_reg_vars);		/* allocate vars to SI, DI	*/
pragma Off (Auto_reg_alloc);		/* HC figures out SI,DI		*/
					/*				*/
#ifndef	NOPROTO				/*				*/
pragma Off (Prototype_override_warnings);
#define LINT_ARGS	YES		/* ANSI prototype checking	*/
#endif					/*				*/
					/********************************/
#else					/* all other compilers		*/
					/* (might not support ANSI)	*/
#define	CDECL	/**/			/* C calling convention		*/
#define	PASCAL	/**/			/* Pascal calling convention	*/
#define FAR	/**/			/* FAR pointer or function	*/
#define NEAR	/**/			/* NEAR pointer or function	*/
#define	CONST	/**/			/* CONSTANT value		*/
#define	VOLATILE /**/			/* VOLATILE must always read	*/
					/********************************/
#ifndef DRC				/* If DRC not specified,	*/
#define DRC				/*   assume it's it anyway	*/
#endif					/*				*/
					/********************************/
#endif					/* MetaWare C			*/
#endif					/* Borland TurboC		*/
#endif					/* MicroSoft C Version 5.00	*/
#endif					/* MicroSoft C Version 4.00	*/
#endif					/* Watcom C Version 7.00	*/

#ifndef FIXFUNC
#define	FIXFUNC /* Nothing */
#define	VARFUNC /* Nothing */
#endif

/****************************************************************************/
/*	Miscellaneous Definitions:					    */
/****************************************************************************/
#define	FAILURE	(-1)			/*	Function failure return val */
#define SUCCESS	(0)			/*	Function success return val */
#define	YES	1			/*	"TRUE"			    */
#define	NO	0			/*	"FALSE"			    */
#define	FOREVER	for(;;)			/*	Infinite loop declaration   */
#undef	NULL				/* 	Remove previous definition  */
#define	NULL	0			/*	Null character value	    */
#ifdef DRC				/************************************/
#define NULLPTR (BYTE *) 0		/*	Null pointer value	    */
#else					/************************************/
#define NULLPTR (VOID *) 0		/*	Null pointer value	    */
#endif					/************************************/
#define	EOF	(-1)			/*	EOF Value		    */
#define	TRUE	(1)			/*	Function TRUE  value	    */
#define	FALSE	(0)			/*	Function FALSE value	    */

/****************************************************************************/
/****************************************************************************/
