# DRDOS.SYS Makefile for Open Watcom
# Tools needed to build:
#   - JWASM assembler
#   - Open Watcom 1.9+: WLINK, EXE2BIN
#   - COMPBDOS from the ..\LTOOLS directory

.ERASE

!include ../platform.mak

WASM_FLAGS += -DDELWATCH -DJOIN -DKANJI -DPASSWORD -DUNDELETE

objs  = bin/buffers.obj bin/dirs.obj bin/fdos.obj bin/fcbs.obj bin/bdevio.obj
objs += bin/cdevio.obj bin/fioctl.obj bin/redir.obj bin/header.obj
objs += bin/pcmif.obj bin/cio.obj bin/disk.obj bin/ioctl.obj bin/misc.obj
objs += bin/support.obj bin/dosmem.obj bin/error.obj bin/process.obj
objs += bin/network.obj bin/int2f.obj bin/history.obj bin/cmdline.obj
objs += bin/dos7.obj bin/lfn.obj bin/dosgrps.obj

all: bin/drdos.sys bin/country.sys .SYMBOLIC

bin/drdos.sys : bin/drdos.exe
	$(EXE2BIN) -q $< bin$(SEP)drdos.bin
	$(COMPBDOS) bin$(SEP)drdos.bin $@

bin/drdos.exe: version.inc $(objs) drdos.lnk
	$(WLINK) @drdos.lnk

bin/country.sys: country.asm country.def
	$(WASM) $(WASM_FLAGS) -bin -Fo=$^@ $[@

version.inc: ../version.inc
	$(CP) ..$(SEP)version.inc .

bin/dosgrps.obj: dosgrps.asm
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/buffers.obj: buffers.asm fdos.equ bdos.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/dirs.obj: dirs.asm bdos.equ mserror.equ fdos.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/fdos.obj: fdos.asm version.inc psp.def modfunc.def fdos.equ request.equ msdos.equ mserror.equ doshndl.def driver.equ f52data.def  bdos.equ funcs.fdo utils.fdo
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/fcbs.obj: fcbs.asm fdos.equ msdos.equ mserror.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/bdevio.obj: bdevio.asm driver.equ fdos.equ mserror.equ doshndl.def bdos.equ request.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/cdevio.obj: cdevio.asm psp.def modfunc.def fdos.equ mserror.equ doshndl.def driver.equ request.equ cmdline.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/fioctl.obj: fioctl.asm fdos.equ request.equ msdos.equ mserror.equ doshndl.def driver.equ f52data.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@
	
bin/redir.obj: redir.asm psp.def fdos.equ msdos.equ mserror.equ doshndl.def f52data.def redir.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@
	
bin/header.obj: header.asm pcmode.equ vectors.def cmdline.equ doshndl.def driver.equ exe.def f52data.def fdos.equ mserror.equ psp.def request.equ country.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/pcmif.obj: pcmif.asm pcmode.equ fdos.def vectors.def msdos.equ mserror.equ psp.def fdos.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/cio.obj: cio.asm pcmode.equ driver.equ request.equ msdos.equ fdos.equ psp.def mserror.equ char.def redir.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/disk.obj: disk.asm pcmode.equ fdos.def doshndl.def fdos.equ psp.def msdos.equ mserror.equ redir.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/ioctl.obj: ioctl.asm pcmode.equ fdos.def msdos.equ mserror.equ cmdline.equ driver.equ request.equ psp.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/misc.obj: misc.asm version.inc pcmode.equ msdos.equ mserror.equ psp.def driver.equ char.def country.def doshndl.def redir.equ fdos.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/support.obj: support.asm pcmode.equ fdos.def mserror.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/dosmem.obj: dosmem.asm pcmode.equ msdos.equ mserror.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/error.obj: error.asm pcmode.equ fdos.def msdos.equ mserror.equ psp.def char.def request.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/process.obj: process.asm pcmode.equ fdos.def psp.def mserror.equ vectors.def msdos.equ exe.def char.def redir.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/network.obj: network.asm pcmode.equ mserror.equ redir.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/int2f.obj: int2f.asm pcmode.equ msdos.equ mserror.equ driver.equ psp.def doshndl.def redir.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/history.obj: history.asm pcmode.equ msdos.equ char.def cmdline.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/cmdline.obj: cmdline.asm pcmode.equ msdos.equ char.def cmdline.equ request.equ driver.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/dos7.obj: dos7.asm pcmode.equ fdos.equ fdos.def dos7.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/lfn.obj: lfn.asm bdos.equ fdos.equ pcmode.equ doshndl.def lfn.equ fdos.def mserror.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@


clean: .SYMBOLIC
	rm -f bin/drdos.*
	rm -f bin/DRDOS.*	
	rm -f bin/country.sys	
	rm -f bin/COUNTRY.SYS	
	rm -f bin/*.obj
	rm -f bin/*.OBJ
	rm -f bin/*.lst
	rm -f bin/*.LST
	rm -f bin/*.sym
	rm -f bin/*.SYM
	rm -f bin/*.tmp
	rm -f bin/*.TMP
	rm -f bin/*.map
	rm -f bin/*.MAP
	rm -f bin/*.inp
	rm -f version.inc
	rm -f VERSION.INC
