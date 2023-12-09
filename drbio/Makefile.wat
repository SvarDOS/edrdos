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
WASM_FLAGS = -q -Zm -Zg -DSVARDOS
WLINK = wlink
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
	
bin/bios.exe : $(wasm_objs) $(rasm_objs) bios.lnk
	$(WLINK) @bios.lnk

bin/biosmsgs.obj: biosmsgs.asm biosgrps.equ version.inc

bin/init.obj: init.asm biosgrps.equ drmacros.equ ibmros.equ msdos.equ request.equ bpb.equ udsc.equ driver.equ keys.equ biosmsgs.def

bin/clock.obj: clock.asm biosgrps.equ drmacros.equ ibmros.equ request.equ driver.equ

bin/console.obj: console.asm biosgrps.equ drmacros.equ ibmros.equ request.equ driver.equ

bin/disk.obj: biosgrps.asm biosgrps.equ drmacros.equ ibmros.equ request.equ bpb.equ udsc.equ driver.equ keys.equ biosmsgs.def

bin/serpar.obj: serpar.asm biosgrps.equ drmacros.equ ibmros.equ request.equ driver.equ

bin/biosgrps.obj: biosgrps.asm biosgrps.equ

bin/biosinit.obj: biosinit.a86 msdos.equ psp.def f52data.def doshndl.def config.equ fdos.equ modfunc.def patch.cod initmsgs.def

bin/config.obj: config.a86 config.equ msdos.equ char.def reqhdr.equ driver.equ fdos.equ f52data.def doshndl.def country.def initmsgs.def biosmsgs.def

bin/bdosldr.obj: bdosldr.a86 reqhdr.equ driver.equ config.equ initmsgs.def

bin/genercfg.obj: genercfg.a86 config.equ msdos.equ char.def reqhdr.equ driver.equ fdos.equ f52data.def doshndl.def country.def

bin/nlsfunc.obj: nlsfunc.a86 config.equ msdos.equ mserror.equ

.asm.obj:
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

.a86.obj:
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@

version.inc: ../version.inc
	copy ..\version.inc .

clean: .SYMBOLIC
	rm -f bin/drbio.sys
	rm -f bin/bios.exe
	rm -f bin/*.obj
	rm -f bin/*.o86
	rm -f bin/*.lst
	rm -f bin/*.map
	rm -f version.inc
