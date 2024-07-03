# DRDOS.SYS Makefile for Open Watcom
# currently only for DOS because of proprietary Digital Research tools
# Tools needed to build:
#   - JWASM assembler
#   - Open Watcom 1.9+: WLINK, EXE2BIN
#   - RASM_SH, RASM86, FIXUPP, ROUND and COMPBDOS from the ..\LTOOLS directory

.EXTENSIONS: .a86
.ERASE

!include ../platform.mak

WASM_FLAGS += -DDELWATCH -DKANJI -DJOIN

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

bin/dirs.obj: dirs.a86 bdos.equ mserror.equ fdos.equ
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS) /DDELWATCH
	$(FIXUPP) $^*.o86 $^@

bin/fdos.obj: fdos.a86 version.inc psp.def modfunc.def fdos.equ rh.equ msdos.equ mserror.equ doshndl.def driver.equ f52data.def  bdos.equ funcs.fdo utils.fdo
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS) /DDELWATCH /DKANJI /DDOS5 /DPASSWORD /DJOIN /DUNDELETE /Dshortversion
	$(FIXUPP) $^*.o86 $^@

bin/fcbs.obj: fcbs.a86 mserror.equ fdos.equ driver.equ doshndl.def
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@

bin/bdevio.obj: bdevio.asm driverw.equ fdos.equ mserror.equ doshndl.def bdos.equ request.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/cdevio.obj: cdevio.a86 psp.def modfunc.def fdos.equ mserror.equ doshndl.def driver.equ rh.equ cmdline.equ
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS) /DDOS5
	$(FIXUPP) $^*.o86 $^@

bin/fioctl.obj: fioctl.a86 fdos.equ rh.equ msdos.equ mserror.equ doshndl.def driver.equ f52data.def
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS) /DPASSWORD /DJOIN /DDOS5
	$(FIXUPP) $^*.o86 $^@
	
bin/redir.obj: redir.asm pspw.def fdos.equ msdos.equ mserror.equ doshndl.def f52dataw.def redir.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@
	
bin/header.obj: header.asm pcmodew.equ vectors.def cmdlinew.equ doshndl.def driverw.equ exe.def f52dataw.def fdos.equ mserror.equ psp.def request.equ country.def
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/pcmif.obj: pcmif.asm pcmodew.equ fdos.def vectors.def msdos.equ mserror.equ pspw.def fdos.equ
	$(WASM) $(WASM_FLAGS) -Fo$^@ -Fl$^*.lst $[@

bin/cio.obj: cio.a86 pcmode.equ driver.equ reqhdr.equ msdos.equ fdos.equ psp.def mserror.equ char.def redir.equ doshndl.def
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@

bin/disk.obj: disk.a86 pcmode.equ fdos.def doshndl.def fdos.equ psp.def msdos.equ mserror.equ redir.equ
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS) /DDELWATCH
	$(FIXUPP) $^*.o86 $^@

bin/ioctl.obj: ioctl.a86 pcmode.equ fdos.def msdos.equ mserror.equ cmdline.equ driver.equ reqhdr.equ psp.def
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS) /DPASSWORD /DDOS5
	$(FIXUPP) $^*.o86 $^@

bin/misc.obj: misc.a86 version.inc pcmode.equ msdos.equ mserror.equ psp.def driver.equ char.def country.def doshndl.def redir.equ fdos.equ
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS) /DDOS5
	$(FIXUPP) $^*.o86 $^@

bin/support.obj: support.a86 pcmode.equ fdos.def mserror.equ doshndl.def
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@

bin/dosmem.obj: dosmem.a86 pcmode.equ msdos.equ mserror.equ
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@

bin/error.obj: error.a86 pcmode.equ fdos.def msdos.equ mserror.equ psp.def char.def reqhdr.equ
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@

bin/process.obj: process.a86 pcmode.equ fdos.def psp.def mserror.equ vectors.def msdos.equ exe.def char.def redir.equ doshndl.def
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS) /DDOS5
	$(FIXUPP) $^*.o86 $^@

bin/network.obj: network.a86 pcmode.equ mserror.equ redir.equ doshndl.def
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@

bin/int2f.obj: int2f.a86 pcmode.equ msdos.equ mserror.equ driver.equ psp.def doshndl.def redir.equ
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS) /DDOS5 /DDELWATCH
	$(FIXUPP) $^*.o86 $^@

bin/history.obj: history.a86 pcmode.equ msdos.equ char.def cmdline.equ
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@

bin/cmdline.obj: cmdline.a86 pcmode.equ msdos.equ char.def cmdline.equ reqhdr.equ driver.equ
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@

bin/dos7.obj: dos7.asm pcmode.equ fdos.equ fdos.def dos7.equ
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@

bin/lfn.obj: lfn.asm bdos.equ fdos.equ pcmode.equ doshndl.def lfn.equ fdos.def mserror.equ
	$(RASM_SH) $(RASM) . .\$[. .\$^*.o86 $(RASM_FLAGS)
	$(FIXUPP) $^*.o86 $^@


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
