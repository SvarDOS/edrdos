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


#define 	MS_P_TERMCPM		0x00
#define 	MS_C_READ		0x01
#define 	MS_C_WRITE		0x02
#define 	MS_A_READ		0x03
#define 	MS_A_WRITE		0x04
#define 	MS_L_WRITE		0x05
#define 	MS_C_RAWIO		0x06
#define 	MS_C_RAWIN		0x07
#define 	MS_C_NOECHO		0x08
#define 	MS_C_WRITESTR		0x09
#define 	MS_C_READSTR		0x0a
#define 	MS_C_STAT		0x0b
#define 	MS_C_FLUSH		0x0c
#define 	MS_DRV_ALLRESET 	0x0d
#define 	MS_DRV_SET		0x0e
#define 	MS_F_OPEN		0x0f
#define 	MS_F_CLOSE		0x10
#define 	MS_F_SFIRST		0x11
#define 	MS_F_SNEXT		0x12
#define 	MS_F_DELETE		0x13
#define 	MS_F_READ		0x14
#define 	MS_F_WRITE		0x15
#define 	MS_F_MAKE		0x16
#define 	MS_F_RENAME		0x17
#define 	MS_DRV_GET		0x19
#define 	MS_F_DMAOFF		0x1a
#define 	MS_DRV_ALLOC		0x1b
#define 	MS_DRV_ALLOCSPEC	0x1c
#define 	MS_F_READRAND		0x21
#define 	MS_F_WRITERAND		0x22
#define 	MS_F_SIZE		0x23
#define 	MS_F_RANDREC		0x24
#define 	MS_S_SETINT		0x25
#define 	MS_P_MKPSP		0x26
#define 	MS_F_READBLK		0x27
#define 	MS_F_WRITEBLK		0x28
#define 	MS_F_PARSE		0x29
#define 	MS_T_GETDATE		0x2a
#define 	MS_T_SETDATE		0x2b
#define 	MS_T_GETTIME		0x2c
#define 	MS_T_SETTIME		0x2d
#define 	MS_F_VERIFY		0x2e
#define 	MS_F_DMAGET		0x2f
#define 	MS_S_BDOSVER		0x30
#define 	MS_P_TERMKEEP		0x31
#define 	MS_S_BREAK		0x33
#define 	MS_S_GETINT		0x35
#define 	MS_DRV_SPACE		0x36
#define 	MS_S_COUNTRY		0x38
#define 	MS_X_MKDIR		0x39
#define 	MS_X_RMDIR		0x3a
#define 	MS_X_CHDIR		0x3b
#define 	MS_X_CREAT		0x3c
#define 	MS_X_OPEN		0x3d
#define 	MS_X_CLOSE		0x3e
#define 	MS_X_READ		0x3f
#define 	MS_X_WRITE		0x40
#define 	MS_X_UNLINK		0x41
#define 	MS_X_LSEEK		0x42
#define 	MS_X_CHMOD		0x43
#define 	MS_X_IOCTL		0x44
#define 	MS_X_DUP		0x45
#define 	MS_X_DUP2		0x46
#define 	MS_X_CURDIR		0x47
#define 	MS_M_ALLOC		0x48
#define 	MS_M_FREE		0x49
#define 	MS_M_SETBLOCK		0x4a
#define 	MS_X_EXEC		0x4b
#define 	MS_X_EXIT		0x4c
#define 	MS_X_WAIT		0x4d
#define 	MS_X_FIRST		0x4e
#define 	MS_X_NEXT		0x4f
#define 	MS_F_GETVERIFY		0x54
#define 	MS_F_DATETIME		0x56
#define 	MS_F_ERROR		0x59
#define 	MS_X_MKTEMP		0x5a
#define 	MS_X_MKNEW		0x5b
#define 	MS_F_LOCK		0x5c
#define 	MS_P_GETPSP		0x62
