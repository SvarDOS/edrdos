;    File              : $BIOSGRPS.ASM$
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

CGROUP	group	CODE,ENDCODE,RCODE_ALIGN,RCODE,RESUMECODE,RESBIOS,ICODE,IDATA,INITCODE,STACKS,INITDATA,INITPSP,INITENV,DATAEND

CODE		segment public para 'CODE'
CODE		ends

ENDCODE		segment public byte 'ENDCODE'
ENDCODE		ends

RCODE_ALIGN	segment public para 'RCODE'
RCODE_ALIGN	ends

RCODE		segment public word 'RCODE'
RCODE		ends

RESUMECODE	segment public para 'RESUMECODE'
RESUMECODE	ends

RESBIOS		segment public para 'RESBIOS'
RESBIOS		ends

ICODE		segment public para 'ICODE'
ICODE		ends

IDATA		segment public para 'IDATA'
IDATA		ends

INITCODE	segment public para 'INITCODE'
INITCODE	ends

STACKS		segment	public para 'STACKS'
STACKS		ends

INITDATA	segment public para 'INITDATA'
INITDATA	ends

INITPSP		segment public para 'INITDATA'
INITPSP		ends

INITENV		segment public para 'INITDATA'
INITENV		ends

DATAEND		segment public para 'INITDATA'
DATAEND		ends

		end
