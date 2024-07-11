# COMMAND.COM Makefile for Open Watcom
# Tools needed to build:
#   - JWASM assembler
#   - Open Watcom 1.9+: WCC, WLINK, EXE2BIN
#
# 2023-12-17: initial version (Boeckmann)

.ERASE

!include ../platform.mak

CFLAGS = -q -os -s -dFINAL -dPASSWORD -dWATCOMC -i=.
WASM_FLAGS = -q -c -Zm -Zg -DWATCOMC -DPASCAL -DFINAL -I./

asm_objs  = bin/message.obj bin/cstart.obj bin/csup.obj bin/dosif.obj
asm_objs += bin/crit.obj bin/resident.obj bin/txhelp.obj bin/helpstub.obj

objs  = bin/com.obj bin/comint.obj bin/support.obj bin/printf.obj
objs += bin/batch.obj bin/global.obj bin/config.obj bin/comcpy.obj
objs += bin/cmdlist.obj

bin/command.com: bin/command.exe bin/txhelp.bin
!ifdef __UNIX__
	cat bin$(SEP)command.exe bin$(SEP)txhelp.bin >bin$(SEP)command.com
!else
	$(CP) /b bin$(SEP)command.exe+bin$(SEP)txhelp.bin bin$(SEP)command.com
!endif

bin/command.exe: $(asm_objs) $(objs)
	$(WLINK) @command.lnk

bin/txhelp.bin: bin/helpstub.obj bin/txhelp.obj
	$(WLINK) @txhelp.lnk
	$(EXE2BIN) -q bin$(SEP)txhelp.exe bin$(SEP)txhelp.bin
.c: ..
.c.obj: .AUTODEPEND
	$(WCC) $(CFLAGS) -Fo$^@ $[@

.asm: ..
.asm.obj:
	$(WASM) $(WASM_FLAGS) -Fo$^@ $[@

bin/message.obj: message.asm version.inc

version.inc: ../version.inc
	$(CP) ..$(SEP)version.inc .

clean: .SYMBOLIC
	rm -f bin/*.bin
	rm -f bin/*.BIN	
	rm -f bin/*.com
	rm -f bin/*.COM
	rm -f bin/*.exe
	rm -f bin/*.EXE	
	rm -f bin/*.obj
	rm -f bin/*.OBJ
	rm -f bin/*.lst
	rm -f bin/*.LST
	rm -f bin/*.map
	rm -f bin/*.MAP
	rm -f version.inc
	rm -f VERSION.INC
