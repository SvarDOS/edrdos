/*
;    File              : $Workfile: PRINTF.C$
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

/*
 * 26 Apr 88 Modify the Long conversion routine to display all 10
 *           digits of a 32 bit integer when displayed in decimal
 * 27 May 88 Added string undefs.
 * 1? Jun 88 Support for CODE relative messages using the FARPTR routine.
 * 05 Jun 89 Add EPRINTF routine to display messages on STDERR
 * 30 Oct 89 dispense with digits & uc_digits in resident portion
 *  8 Nov 89 Replaced ASCII calculation with to_dec(), etc. as used
 *           in APPALIB printf module. Much faster (eg dir /l 10% faster).
 *  8 Jan 90 Added parameter order indexing option.
 *  6-Mar-90 Watcom C v 7.0
 * 26-Mar-90 Make _printf CDECL again, otherwise arg processing screws up
 * 23-May-90 increase printf buffers from 128 to 130
 * 02-Dec-90 Re-work, to flush buffer on \n to allow large input strings
 * 28-May-91 local buffer is now on the stack instead of static. Reduces
 *           resident size by 128 bytes.
 * 29-Jul-91 Buffer is now a far one, so output redirection to a file works
 *           on a NOVELL drive when we are in seg FFFF.
 */

#include	"defines.h"
#include	<string.h>

#if defined(MWC) && defined(strlen)
#undef strcmp			/* These are defined as macros in string.h */
#undef strcpy			/* which are expaneded in line under */
#undef strlen			/* Metaware C. These undefs avoid this. */
#endif

#include	<portab.h>
#include	"command.h"
#include	"dosif.h"
#include	"global.h"

#define     PRINTF      -1
#define     EPRINTF     -2
#define     SPRINTF     -3

EXTERN VOID		c_write		(BYTE *, WORD);	
EXTERN BYTE FAR * CDECL farptr		(BYTE *);
EXTERN BOOLEAN		isdigit		(BYTE);
EXTERN BOOLEAN		err_flag;

/* forward references */
MLOCAL UWORD CDECL 	_printf		(BYTE *, UWORD *, UWORD);
MLOCAL VOID		arg_ptrs	(BYTE FAR *, UWORD *, UWORD **);
MLOCAL BYTE FAR *	arg_siz		(BYTE FAR *, UBYTE *);
MLOCAL BYTE FAR *	arg_num		(BYTE FAR *, UWORD *);
MLOCAL BYTE * 		to_hex		(ULONG, BYTE *, BYTE);
MLOCAL BYTE *  		to_dec		(ULONG, BYTE *);
MLOCAL BYTE *  		to_udec		(ULONG, BYTE *);

#define			UPPER_CASE	('A'-10)
#define			LOWER_CASE	('a'-10)

#define			MAX_ARG_NUM	10	/* max args with order indxs */

MLOCAL  BYTE FAR	*buff 		= NULLPTR;

/*GLOBAL  BYTE		str[130];*/
MLOCAL	BYTE FAR	*str;

GLOBAL WORD CDECL printf(fmt,args)
BYTE	*fmt;
UWORD	args;
{
	UWORD	totlen,len;
	/*BYTE	local_buff[130];*/
	UWORD	bufsize;

	/*str = (BYTE FAR *) local_buff;*/
	str = gp_far_buff;

	buff = str; 			/* use local buffer for printing */
	totlen = _printf (fmt,&args,PRINTF);		/* build up output string */
        len=(UWORD) buff - (UWORD) str;
        if(len)				/* if anything in the buffer   */
	    far_write(err_flag ? STDERR:STDOUT, str, len);
	    				/* then flush it */

	return totlen+len;			/* Return the String Length	*/

}

GLOBAL WORD CDECL eprintf(fmt,args)
BYTE	*fmt;
UWORD	args;
{
	UWORD	totlen, len;
	BYTE	local_buff[130];

	str = (BYTE FAR *) local_buff;

	buff = str; 			/* use local buffer for printing */
        err_flag = TRUE;
	totlen = _printf (fmt,&args,EPRINTF);		/* build up output string */
        len = buff-str;
        if(len)	{			/* if anything in the buffer   */
            far_write(STDERR,str,len);
 	}
	err_flag = FALSE;

	return totlen+len;			/* Return the String Length	*/

}

GLOBAL WORD CDECL fprintf(handle, fmt, args)
UWORD	handle;
BYTE	*fmt;
UWORD	args;
{
	UWORD	totlen,len;
	UWORD	bufsize;
	
	str = gp_far_buff;

	buff = str; 			/* use local buffer for printing */
	totlen =_printf (fmt,&args,handle);		/* build up output string */
        len = (UWORD) buff - (UWORD) str;
        if(len)				/* if anything in the buffer   */
	    far_write(handle, str, len);	/* then flush it */

	return totlen+len;			/* Return the String Length	*/

}

GLOBAL WORD CDECL sprintf(strg, fmt, args)
BYTE	*strg;
BYTE	*fmt;
UWORD	args;
{
	buff = (BYTE FAR *) strg;		/* Point buffer at String	*/
	return _printf (fmt,&args,SPRINTF); 	/* Generate the String		*/
}

MLOCAL UWORD CDECL 	_printf(fmt_near, args, type)
BYTE		*fmt_near;
UWORD	   	*args;
UWORD        type;
{
	BYTE FAR *fmt;
	WORD rjust;			/* if string/number is right justified */
	WORD maxwidth, width;
	BOOLEAN	long_arg;		/* true if next argument is long */
	ULONG value;
	UWORD uvalue;
	WORD i, k;
	BYTE FAR *cp;
	BYTE c, filler;
	BYTE s[40], *sp;
	LONG *lp;
	UWORD *arg_list[MAX_ARG_NUM];
	UWORD arg_idx;
        UWORD totlen=0;

	fmt = farptr(fmt_near);		/* get full address of format string */
	arg_ptrs(fmt, args, arg_list);	/* init table of argument addresses */

	while ((c = *fmt++) != 0)	/* scan format string */
	{
	    if (c == '%') {		/* formatting code found */
		    s[14] = 0;
		    rjust = YES;
		    filler = ' ';
		    maxwidth = 0x7fff;

		    fmt = arg_num(fmt, &arg_idx);	/* get argument index */
		    if (arg_idx < MAX_ARG_NUM) {	/* valid index? */
		        fmt++;			/*  yes - skip '%' */
		        args = arg_list[arg_idx];	/* lookup address of arg */
		    }

		    if ((c = *fmt) == '-') {	/* string is left justified */
		        rjust = NO;		/*   ... not right justified */
		        c = *fmt++;		/* get the next character */
		    }

		    if (c == '0')		/* if leading zeroes desired */
		        filler = '0';	/*    use '0' instead of ' ' */

		    if (*fmt == '*') {	/* if formatting width is parameter */
		            			/*    then get it from parameters */
		        width = (WORD)*args++;
		        fmt++;		/* skip the asterisk */
		        c = *fmt++;		/* get next character */
		    }
		    else			/* get full width */
		        for (width = 0; (c = *fmt++) >= '0' && c <= '9'; )
			        width = width*10 + c - '0';

		    if (c == '.') {		/* if decimal places specified */
		        if (*fmt == '*') {	/* if width is a parameter */
			        maxwidth = (WORD)*args++;
			        fmt++;		/* skip the asterisk */
			        c = *fmt++;	/* get next character */
		        }
		        else		/* get decimal places */
			        for (maxwidth = 0; (c = *fmt++) >= '0' && c <= '9' ;)
			            maxwidth = maxwidth*10 + c - '0';
		    }

			/* "%ld", "%lu", "lx" specified */
		    long_arg = (c == 'l');	/* is the argument supplied long? */
		    if (long_arg)		/* if long argument */
		        c = *fmt++;		/* then skip the 'l' character */

		    switch (c)	{
		        case 'd':		/* signed argument */
		            if (!long_arg)
			            value = (WORD) *args++;
		            else {
			            lp = (LONG *) args;
			            value = *lp++;
			            args = (UWORD *) lp;
		            }
		            break;

		    case 'u':		/* unsigned argument */
		    case 'x':
		    case 'X':
		        if (!long_arg)
			        value = (UWORD) *args++;
		        else {
			        lp = (LONG *) args;
			        value = (ULONG) *lp++;
			        args = (UWORD *) lp;
		        }
		        break;

		    default:			/* "%s", "%c" */
		        uvalue = (UWORD) *args++;	/* get string address of char */
		    }


		    switch (c) {		/* now convert to ASCII */
		        case 'd':		/* signed decimal */
		    	    sp = to_dec(value, s+14);
		    	    break;

		        case 'u':		/* unsigned decimal */
		    	    sp = to_udec(value, s+14);
		    	    break;

		        case 'x':		/* unsigned hexadecimal, lower case */
		    	    sp = to_hex(value, s+14, LOWER_CASE);
		    	    break;

		        case 'X':		/* unsigned hexadecimal, upper case */
		            sp = to_hex(value, s+14, UPPER_CASE);
		            break;

		        case 's':		/* string -- could be far */
		            cp = farptr((BYTE *)uvalue);
		            for (i=0; cp[i] != '\0'; i++)
		                ;
		            goto havelen;

		        case 'c':
		            c = uvalue;
					/* drop into "default:" */
		        default:			/* normal characters */
		            sp = s+13;
		            *sp = c;
		            break;
		    }

		    i = (s+14) - sp;	/* work out length of string */
		    cp = (BYTE FAR *) sp;	/* convert to FAR pointer */

havelen:
		    if (i > maxwidth)
		        i = maxwidth;
			
		    if (rjust) {
		        while (width-- > i)
			    *buff++ = filler;
		    }

		    for (k = 0; *cp && k < maxwidth; ++k) {
		        if (*cp == '\n')
			        *buff++ = '\r';
		        *buff++ = *cp++;
		    }

		    if (!rjust)	{	/* if right justified */
		        while (width-- > i)
			        *buff++ = ' ';
		    }
	    }
	    else if (c == '\n')	{	/* expand newline to CR,LF then flush the buffer */
		    *buff++ = '\r';
		    *buff++ = '\n';
                if (type!=SPRINTF) {
                    /* Flush the buffer */
	            *buff = '\0';		/* terminate the string	*/
                    switch (type) {
                        case PRINTF:
	                    far_write(err_flag ? STDERR:STDOUT,str,
			    		(UWORD) buff - (UWORD) str);
                            break;
                        case EPRINTF:
	                    far_write(STDERR, str, buff-str);
                            break;
                        default:
	                    far_write(type, str, buff-str);	
                            break;
                    } /*ENDSWITCH*/
                    totlen+=buff-str;
                    buff=str;
                }
	    }
	    else 
		    *buff++ = c;
	}
	*buff = '\0';		/* terminate the string	*/
        return totlen+=buff-str;
}



/* Initialise the table of pointers to all arguments (ptr_list).
   The ptr_list table will not be filled in unless the format
   string (fmt) contains parameter order indexes. */

MLOCAL VOID arg_ptrs(fmt, args, ptr_list)
REG BYTE FAR	*fmt;			/* ASCIIZ format string */
UWORD		*args;			/* pointer to first argument */
UWORD	   	*ptr_list[];		/* list of pointers to all arguments */
{
UWORD		arg_cnt;		/* running count of parameters found */
UWORD		num;
UBYTE		size_list[MAX_ARG_NUM];	/* number bytes in each argument */
UWORD		i;


    /* Read through format string to determine the size of each argument. */
    for (arg_cnt = 0; ; )
    {
    	while (*fmt && *fmt != '%')	/* find the next parameter */
	    fmt++;

	if (!*fmt)			/* patameter found? */
	    break;			/*  no - exit loop */
	fmt++;				/* skip '%' */

	if (*fmt == '%')		/* "%%" escape for percent? */
	{
	    fmt++;			/*  yes - skip second '%' */
	    continue;			/*  and look for next parameter */
	}

	fmt = arg_num(fmt, &num);	/* get this argument's index */
	if (num >= MAX_ARG_NUM)		/* arg index present and valid? */
	    break;			/*  no - go no further */

					/* record this argument's size */
	fmt = arg_siz(fmt, &size_list[num]);
	arg_cnt++;			/* one more argument found */
    }


    /* Loop once for each argument found in format string, filling in
       the offset for that argument in the size_list table. */
    for (i = 0; i < arg_cnt; i++)
    {
    	ptr_list[i] = args;			/* record the address of arg */
	args += (UWORD)(size_list[i]);		/* update ptr by size of arg */
    }
}



/* Determine the size in bytes (siz) of the argument that corresponds to the 
   given format string (fmt). Return a pointer to the character following
   the last in the format string. For example...

	fmt	       siz
   	%d		2
	%ld		4
	%*d		4
*/

MLOCAL BYTE FAR * arg_siz(fmt, siz)
REG BYTE FAR	*fmt;			/* printf argument format string */
UBYTE		*siz;			/* returned argument size, in bytes */
{

    *siz = 0;				/* argument size not yet known */

    if (*fmt != '%')
    	return fmt;			/* format string must begin with '%' */
    fmt++;				/* skip '%' */

    if (*fmt == '#')			/* ignore various formatting ctrls */
	fmt++;
    if (*fmt == '-')
	fmt++;
    if (*fmt == '0')
	fmt++;

    if (*fmt == '*')
    {					/* width argument also on stack */
	*siz += sizeof(WORD);		/* width argument is a WORD */
	fmt++;
    }
    else				/* ignore any static width control */
	while (*fmt >= '0' && *fmt <= '9')
	    fmt++;

    if (*fmt == '.')
    {
	fmt++;
	if (*fmt == '*')
	{				/* 2nd width argument on stack */
	    *siz += sizeof(WORD);
	    fmt++;
	}
	else				/* ignore any static width control */
	    while (*fmt >= '0' && *fmt <= '9')
	    	fmt++;
    }

    if (*fmt == 'l')
    {
    	*siz += sizeof(LONG);
	fmt++;
    }
    else
	*siz += sizeof(WORD);		/* assume sizeof(WORD)==sizeof(BYTE *) */

    return ++fmt;			/* skip final char: 'd', 's', etc. */
}



/* Determine the index number (num) of the argument given by the format
   string (fmt). If the format string does not have a valid index number
   num is set to MAX_ARG_NUM. Return a pointer to the character following
   the last in the index number. For example...

	fmt		num		returned pointer to...
	3%4d		3		'%'
	4d		MAX_ARG_NUM	'4'
	%		MAX_ARG_NUM	'%'
*/

MLOCAL BYTE FAR * arg_num(fmt, num)
BYTE FAR	*fmt;
UWORD	   	*num;
{
REG BYTE FAR	*cp;
REG UWORD	n;


    *num = MAX_ARG_NUM;			/* argument index not yet known */

    cp = fmt;
    if (!isdigit(*cp))			/* at least one digit expected */
	return fmt;
					/* extract index number */
    for (n = 0; *cp >= '0' && *cp <= '9'; cp++)
	n = n * 10 + *cp - '0';

    if (*cp != '%')
    	return fmt;			/* number must be terminated by '%' */

    *num = n;				/* record the index number */
    return cp;				/* return pointer to last '%' */
}



MLOCAL BYTE * to_hex(n, s, hex_base)
ULONG  		n;
BYTE   		*s;
BYTE		hex_base;	/* 'a'-10 for lowercase, 'A'-10 uppercase */
{
REG UBYTE	i;

    do
    {
	i = (UBYTE)n & 0x0F;
	*--s = (i > 9) ? (hex_base + i) : ('0' + i);
	n >>= 4;
    }
    while (n != 0);

    return s;
}



MLOCAL BYTE * to_dec(n, s)
ULONG  		n;
BYTE   		*s;
{
    if ((LONG)n < 0)
    {
	s = to_udec(0 - (LONG)n, s);
	*--s = '-';			/* preceed number with sign */
	return s;
    }
    else
	return to_udec(n, s);
}



MLOCAL BYTE * to_udec(n, s)
ULONG  		n;
BYTE   		*s;
{
    do
    {
	*--s = '0' + (n % 10);
	n /= 10;
    } 
    while (n != 0);

    return s;
}



