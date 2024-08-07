# Platform specific definitions for Makefiles

!ifdef __UNIX__
SEP=/
CP = cp
!else
SEP=\
CP = copy
!endif

!ifdef __MSDOS__
LTOOLS = ltools$(SEP)dos
WASM = jwasmd
!else ifdef __NT__
LTOOLS = ltools$(SEP)win32
WASM = jwasm
!else ifdef __UNIX__
LTOOLS = ltools$(SEP)unix
WASM = jwasm
!else
!error Unsupported host operating system.
!endif

WASM_FLAGS = -q
WLINK = wlink
EXE2BIN = exe2bin

WCC = wcc
WMAKE = wmake -h

COMPKERN = $(LTOOLS)$(SEP)compkern
COMPBIOS = ..$(SEP)$(LTOOLS)$(SEP)compbios
COMPBDOS = ..$(SEP)$(LTOOLS)$(SEP)compbdos
ROUND = ..$(SEP)$(LTOOLS)$(SEP)round
