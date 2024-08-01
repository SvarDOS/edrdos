ifidn VERSION, <>
VERSION	    textequ <?>
endif

ifidn GIT_REV, <>
COMMIT   textequ <?>
else
COMMIT   textequ GIT_REV
endif

KERNEL_VER_STR	textequ <13, 10, "Enhanced DR-DOS kernel >, VERSION, < (git rev >, COMMIT, <) [built >, @date, < >, @time , <]", 13, 10>
REPOSITORY_STR	textequ <"source and licensing conditions available at https://github.com/SvarDOS/edrdos", 13, 10>

; used by command.com
SYSNAME_STR textequ <'Enhanced DR-DOS based on Caldera OpenDOS 7.01'>

; embedded in DRBIO.SYS
COPYRIGHT_STR   textequ <"Copyright (c) 1983,1996 Caldera, Inc. All Rights Reserved>, \
< Patches to original OpenDOS source code Copyright (c) 2002-2011 Udo Kuhnt>, \
< distributed and used under license agreement by DRDOS, Inc. on 2022-07-07">
