/*
; DOS7.h - Definitions for DOS 7 data structures
;
; This file is part of
; The DR-DOS/OpenDOS Enhancement Project - http://www.drdosprojects.de
; Copyright (c) 2002-2004 Udo Kuhnt
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
