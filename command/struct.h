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

/* FCB defines */

#define	FCB_NAME	1
#define	FCB_SIZE	32
#define	FCB_NAME_SIZE	11
#define	FCB_EXTENT	12
#define FCB_CS		13
#define FCB_RC		15
#define FCB_ALUS	16


struct	xios_iopb {
	UBYTE	drv;
	UBYTE	mcnt;
	UWORD	track;
	UWORD	sector;
	UBYTE	FAR *dma_buffer;
	};

struct	xios_dpb {
	UWORD	spt;			/* defined as per system guide */
	UBYTE	bsh;			/* This Structure forces the use of */
	UBYTE	blm;			/* the '/Zp' option on the compiler */
	UBYTE	exm;			/* for Packed structures.	*/
	UWORD	dsm;
	UWORD	drm;
	UBYTE	al0;
	UBYTE	al1;
	UWORD	cks;
	UWORD	off;
	UBYTE	psh;
	UBYTE	prm;
	};

struct	segoff {
	UWORD	off;
	UWORD	seg;
	};

struct	f_data {
	UBYTE	srch_attrib;			/* size 1 */
	UBYTE	cur_drive;			/* size 1 */
	UBYTE	media;				/* size 1 */
	UBYTE	pattern[FCB_NAME_SIZE];		/* size 11 */
	UWORD	cur_alu;			/* size 2 */
	UWORD	cur_index;			/* size 2 */
	UBYTE	filler[3];			/* size 3 */
	UBYTE	fnd_attrib;			/* size 1 */
	UWORD	time;				/* size 2 */
	UWORD	date;				/* size 2 */
	LONG	file_size;			/* size 4 */
	UBYTE	file_name[63];			/* size ? */
	};
