# DRDOS.SYS Makefile for Open Watcom
# currently only for DOS because of proprietary Digital Research tools
# Tools needed to build:
#   - JWASM assembler
#   - Open Watcom 1.9+: WLINK, EXE2BIN
#   - RASM_SH, RASM86, FIXUPP, ROUND and COMPBDOS from the ..\LTOOLS directory

.EXTENSIONS: .a86
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
	$(WASM) -bin -Fo=$^@ $[@

version.inc: ../version.inc
	$(CP) ..$(SEP)version.inc .

bin/dosgrps.obj: dosgrps.asm
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/buffers.obj: buffers.asm fdos.equ bdos.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/dirs.obj: dirs.asm bdos.equ mserror.equ fdos.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/fdos.obj: fdos.asm version.inc pspw.def modfunc.def fdos.equ request.equ msdos.equ mserror.equ doshndl.def driverw.equ f52dataw.def  bdos.equ funcs.fdo utils.fdo
	$(WASM) $(WASM_FLAGS) -Dshortversion -Fo$^@ -Fl$^*.lst $[@

bin/fcbs.obj: fcbs.asm fdos.equ msdos.equ mserror.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/bdevio.obj: bdevio.asm driverw.equ fdos.equ mserror.equ doshndl.def bdos.equ request.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/cdevio.obj: cdevio.asm pspw.def modfunc.def fdos.equ mserror.equ doshndl.def driverw.equ request.equ cmdlinew.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/fioctl.obj: fioctl.asm fdos.equ request.equ msdos.equ mserror.equ doshndl.def driverw.equ f52dataw.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@
	
bin/redir.obj: redir.asm pspw.def fdos.equ msdos.equ mserror.equ doshndl.def f52dataw.def redir.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@
	
bin/header.obj: header.asm pcmodew.equ vectors.def cmdlinew.equ doshndl.def driverw.equ exe.def f52dataw.def fdos.equ mserror.equ psp.def request.equ country.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/pcmif.obj: pcmif.asm pcmodew.equ fdos.def vectors.def msdos.equ mserror.equ pspw.def fdos.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/cio.obj: cio.asm pcmodew.equ driverw.equ request.equ msdos.equ fdos.equ pspw.def mserror.equ char.def redir.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/disk.obj: disk.asm pcmodew.equ fdos.def doshndl.def fdos.equ pspw.def msdos.equ mserror.equ redir.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/ioctl.obj: ioctl.asm pcmodew.equ fdos.def msdos.equ mserror.equ cmdlinew.equ driverw.equ request.equ pspw.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/misc.obj: misc.asm version.inc pcmodew.equ msdos.equ mserror.equ pspw.def driverw.equ char.def country.def doshndl.def redir.equ fdos.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/support.obj: support.asm pcmodew.equ fdos.def mserror.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/dosmem.obj: dosmem.asm pcmodew.equ msdos.equ mserror.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/error.obj: error.asm pcmodew.equ fdos.def msdos.equ mserror.equ pspw.def char.def request.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/process.obj: process.asm pcmodew.equ fdos.def pspw.def mserror.equ vectors.def msdos.equ exe.def char.def redir.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/network.obj: network.asm pcmodew.equ mserror.equ redir.equ doshndl.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/int2f.obj: int2f.asm pcmodew.equ msdos.equ mserror.equ driverw.equ pspw.def doshndl.def redir.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/history.obj: history.asm pcmodew.equ msdos.equ char.def cmdlinew.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/cmdline.obj: cmdline.asm pcmodew.equ msdos.equ char.def cmdlinew.equ request.equ driverw.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/dos7.obj: dos7.asm pcmodew.equ fdos.equ fdos.def dos7.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/lfn.obj: lfn.asm bdos.equ fdos.equ pcmodew.equ doshndl.def lfn.equ fdos.def mserror.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@


clean: .SYMBOLIC
	rm -f bin/drdos.sys
	rm -f bin/drdos.exe
	rm -f bin/country.sys	
	rm -f bin/*.obj
	rm -f bin/*.o86
	rm -f bin/*.lst
	rm -f bin/*.sym
	rm -f bin/*.tmp
	rm -f bin/*.map
	rm -f bin/*.inp
	rm -f version.inc
