# COMMAND.COM Makefile for Open Watcom
# Tools needed to build:
#   - JWASM assembler
#   - Open Watcom 1.9+: WCC, WLINK, EXE2BIN
#
# 2023-12-17: initial version (Boeckmann)

.ERASE

WCC = wcc
CFLAGS = -q -os -s -dFINAL -dWATCOMC -i=.
WASM = jwasm
WASM_FLAGS = -q -c -Zm -Zg -DWATCOMC -DPASCAL -DFINAL -I./
WLINK = wlink
EXE2BIN = exe2bin


asm_objs  = bin/message.obj bin/cstart.obj bin/csup.obj bin/dosif.obj
asm_objs += bin/crit.obj bin/resident.obj bin/txhelp.obj bin/helpstub.obj

objs  = bin/com.obj bin/comint.obj bin/support.obj bin/printf.obj
objs += bin/batch.obj bin/global.obj bin/config.obj bin/comcpy.obj
objs += bin/cmdlist.obj

bin/command.com: bin/command.exe bin/txhelp.bin
	copy /b bin\command.exe+bin\txhelp.bin bin\command.com

bin/command.exe: $(asm_objs) $(objs)
	$(WLINK) @command.lnk

bin/txhelp.bin: bin/helpstub.obj bin/txhelp.obj
	wlink @txhelp.lnk
	exe2bin bin/txhelp.exe bin/txhelp.bin
.c: ..
.c.obj: .AUTODEPEND
	$(WCC) $(CFLAGS) -Fo$^@ $[@

.asm: ..
.asm.obj:
	$(WASM) $(WASM_FLAGS) -Fo$^@ $[@

bin/message.obj: version.inc

version.inc: ../version.inc
	copy ..\version.inc .

clean: .SYMBOLIC
	rm -f bin/*.bin
	rm -f bin/*.com
	rm -f bin/*.exe
	rm -f bin/*.obj
	rm -f bin/*.lst
	rm -f bin/*.map
	rm -f version.inc
