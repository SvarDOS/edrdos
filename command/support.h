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

EXTERN VOID      disp_filetime(UWORD);
EXTERN VOID      disp_filedate(UWORD);
EXTERN VOID      disp_systime(VOID);
EXTERN VOID      disp_sysdate(VOID);
EXTERN VOID      revon(VOID);
EXTERN VOID      revoff(VOID);
EXTERN VOID CDECL cmd_cls(VOID);
EXTERN BYTE      tolower(BYTE);
EXTERN BOOLEAN   isdigit(BYTE);
EXTERN BYTE *    skip_char (BYTE *);
EXTERN BYTE *    copy_char (BYTE **, BYTE **);
EXTERN WORD      is_blank (BYTE *);
EXTERN BYTE *    deblank (BYTE *);
EXTERN BOOLEAN   iswild (BYTE *);
EXTERN VOID      zap_spaces(BYTE *);
EXTERN VOID      strip_path(BYTE *, BYTE *);
EXTERN BOOLEAN   getdigit(WORD *, BYTE **);
EXTERN BOOLEAN   check_num(BYTE *, UWORD, UWORD, UWORD *);
EXTERN BOOLEAN   is_filechar(BYTE *);
EXTERN BOOLEAN   is_pathchar(BYTE *);
EXTERN BYTE *    get_filename(BYTE *, BYTE *, BOOLEAN);
EXTERN BYTE *    fptr(BYTE *);
EXTERN VOID      repwild(BYTE *, BYTE *);
EXTERN BOOLEAN   yes(BOOLEAN ,BOOLEAN);
EXTERN WORD      onoff(BYTE *);
EXTERN VOID      syntax (VOID);
EXTERN VOID      crlf (VOID);
EXTERN VOID      putc (BYTE);
EXTERN VOID      puts(BYTE *);
EXTERN BOOLEAN   isdigit(BYTE);
	
EXTERN BYTE *	strlwr(BYTE *);
EXTERN BYTE *	strupr(BYTE *);
EXTERN WORD	strnicmp(const BYTE *, const BYTE *, UWORD);

EXTERN WORD      e_check(WORD);
EXTERN BYTE *    d_check(BYTE *);
EXTERN BOOLEAN   f_check(BYTE *, BYTE *, UWORD *, BOOLEAN);
EXTERN BOOLEAN   nofiles(BYTE *, WORD, BOOLEAN, BOOLEAN);
EXTERN BOOLEAN   file_exist(BYTE *);
EXTERN BOOLEAN   isdev(UWORD);

EXTERN VOID CDECL printf(BYTE *, ...);
EXTERN VOID CDECL eprintf(BYTE *, ...);
EXTERN VOID CDECL sprintf(BYTE *, BYTE *, ...);

EXTERN UWORD CDECL findeof(BYTE FAR *, UWORD);

EXTERN VOID	append_slash(BYTE *);
EXTERN VOID	prompt_exec(VOID);
EXTERN VOID	optional_line(BYTE *);
EXTERN BYTE	*day_names(UWORD);
