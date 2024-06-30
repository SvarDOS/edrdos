# Platform specific definitions for Makefiles

!ifdef __UNIX__
SEP=/
CP = cp
!else
SEP=\
CP = copy
!endif
