# DRBIO Makefile for Open Watcom
# currently only for DOS because of proprietary Digital Research tools
# Tools needed to build:
#   - JWASM assembler
#   - Open Watcom 1.9+: WLINK, EXE2BIN
#   - RASM_SH, RASM86, FIXUPP and COMPBIOS from the ..\LTOOLS directory
#
# 2023-11-26: initial version (Boeckmann)

.EXTENSIONS: .a86
.ERASE

WASM = jwasm
WASM_FLAGS = -q -Zm -Zg
EXE2BIN = exe2bin

LTOOLS = ..\ltools
RASM = $(LTOOLS)\rasm86.exe
RASM_SH = $(LTOOLS)\rasm_sh.exe
RASM_FLAGS = $$szpz /DDRDOS35=0 /DADDDRV=0

FIXUPP = $(LTOOLS)\fixupp.exe
COMPBIOS = $(LTOOLS)\compbios.exe

wasm_objs  = bin/initmsgs.obj bin/biosmsgs.obj bin/init.obj bin/clock.obj
wasm_objs += bin/console.obj bin/disk.obj bin/serpar.obj bin/biosgrps.obj
wasm_objs += bin/stacks.obj

rasm_objs  = bin/biosinit.obj bin/config.obj bin/bdosldr.obj bin/genercfg.obj
rasm_objs += bin/nlsfunc.obj

bin/drbio.sys : bin/bios.exe
	$(EXE2BIN) -q $< $@
	$(COMPBIOS) $@
	
bin/bios.exe : version.inc $(wasm_objs) $(rasm_objs)
	wlink @bios.lnk

.asm.obj:
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $<

.a86.obj:
	$(RASM_SH) $(RASM) . .\$< .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@

version.inc:
	copy ..\version.inc .

clean: .SYMBOLIC
	rm -f bin/drbio.sys
	rm -f bin/bios.exe
	rm -f bin/*.o86
	rm -f version.inc
	@for %f in ($(wasm_objs)) do rm -f %f
	@for %f in ($(rasm_objs)) do rm -f %f
