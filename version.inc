ifidn VERSION, <>
VERSION	    textequ <?>
endif

SYSNAME     textequ <"SvarDOS">
LONGSYSNAME textequ <"SvarDOS Enhanced DR-DOS based on Caldera OpenDOS 7.01">

BUILDDATE   catstr <">, @date, < >, @time , <">

ifidn GIT_REV, <>
COMMIT   textequ <"?">
else
COMMIT   catstr <">, GIT_REV, <"> 
endif

VERSIONSTR  catstr <">, VERSION, <">

KERNELNAME  textequ <"SvarDOS Enhanced DR-DOS Kernel">
KERNELMSG   textequ <13, 10, 13, 10, KERNELNAME, "                https://github.com/SvarDOS/edrdos", 13, 10, \
		    "ver ", VERSIONSTR, " / rev ", COMMIT, " / built ", BUILDDATE , 13, 10>

COPYRIGHT   textequ <"based on Caldera OpenDOS 7.01 sources, patches (c)opyright 2002-2011 Udo Kuhnt", 13, 10, \
		    "distributed and used under license agreement by DRDOS, Inc. on 2022-07-07", 13, 10>
