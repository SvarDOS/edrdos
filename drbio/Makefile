# DRBIO.SYS Makefile for Open Watcom
# Tools needed to build:
#   - JWASM assembler
#   - Open Watcom 1.9+: WLINK, EXE2BIN
#   - COMPBIOS from the ..\LTOOLS directory

.ERASE

!include ../platform.mak

WASM_FLAGS += -DSVARDOS

wasm_objs  = bin/initmsgs.obj bin/biosmsgs.obj bin/init.obj bin/clock.obj
wasm_objs += bin/console.obj bin/disk.obj bin/serpar.obj bin/biosgrps.obj
wasm_objs += bin/stacks.obj

rasm_objs  = bin/biosinit.obj bin/config.obj bin/bdosldr.obj bin/genercfg.obj
rasm_objs += bin/nlsfunc.obj

bin/drbio.sys : bin/drbio.bin
	$(COMPBIOS) $< $@

bin/drbio.bin : bin/bios.exe
	$(EXE2BIN) -q $< $@
		
bin/bios.exe : $(wasm_objs) $(rasm_objs) bios.lnk
	$(WLINK) @bios.lnk

bin/biosmsgs.obj: biosmsgs.asm version.inc

bin/init.obj: init.asm drmacros.equ ibmros.equ msdos.equ request.equ bpb.equ udsc.equ driver.equ keys.equ biosmsgs.def

bin/clock.obj: clock.asm drmacros.equ ibmros.equ request.equ driver.equ

bin/console.obj: console.asm drmacros.equ ibmros.equ request.equ driver.equ

bin/disk.obj: disk.asm biosgrps.asm drmacros.equ ibmros.equ request.equ bpb.equ udsc.equ driver.equ keys.equ biosmsgs.def

bin/serpar.obj: serpar.asm drmacros.equ ibmros.equ request.equ driver.equ

bin/biosgrps.obj: biosgrps.asm

bin/biosinit.obj: biosinit.asm msdos.equ psp.def f52data.def doshndl.def config.equ fdos.equ modfunc.def initmsgs.def

bin/config.obj: config.asm config.equ msdos.equ char.def request.equ driver.equ fdos.equ f52data.def doshndl.def country.def initmsgs.def biosmsgs.def

bin/bdosldr.obj: bdosldr.asm request.equ driver.equ config.equ initmsgs.def

bin/genercfg.obj: genercfg.asm config.equ msdos.equ char.def request.equ driver.equ fdos.equ f52data.def doshndl.def country.def

bin/nlsfunc.obj: nlsfunc.asm config.equ msdos.equ mserror.equ

.asm.obj:
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

version.inc: ../version.inc
	$(CP) ..$(SEP)version.inc .

clean: .SYMBOLIC
	rm -f bin/drbio.*
	rm -f bin/DRBIO.*
	rm -f bin/bios.*
	rm -f bin/BIOS.*
	rm -f bin/*.obj
	rm -f bin/*.OBJ
	rm -f bin/*.lst
	rm -f bin/*.LST
	rm -f bin/*.map
	rm -f bin/*.MAP
	rm -f version.inc
	rm -f VERSION.INC
