/*
; DOS7.h - Definitions for DOS 7 data structures
;
; This file is part of
; The DR-DOS/OpenDOS Enhancement Project - http://www.drdosprojects.de
; Copyright (c) 2002-2008 Udo Kuhnt
*/

typedef struct {
	UWORD	size;		// size of structure
	UWORD	ver;		// version of structure
	ULONG	secpclus;	// sectors per cluster
	ULONG	bytepsec;	// bytes per sector
	ULONG	freecl;		// available clusters
	ULONG	ncluster;	// number of clusters on drive
	ULONG	freesec;	// number of physical sectors available on drive
	ULONG	nsecs;		// number of physical sectors on drive
	ULONG	freepcl;	// available physical allocation units
	ULONG	npclus;		// number of physical allocation units
/*reserved	equ	24h	; reserved bytes*/
} FREED;

typedef struct {
	ULONG	fattr;		// file attributes
	ULONG	ctime;
	ULONG	ctimeh;
	ULONG	atime;
	ULONG	atimeh;
	UWORD	ftime;		// file time
	UWORD	fdate;		// file date
	ULONG	ftimeh;
	ULONG	fsizeh;		// file size high DWORD
	ULONG	fsize;		// file size low DWORD
	UWORD	handle;		// search handle
	BYTE	resvd[6];
	BYTE	lname[260];	// long file name
	BYTE	sname[14];	// short file name
} FINDD;
