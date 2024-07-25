
# Enhanced DR-DOS master Makefile for OpenWatcom WMAKE
# to build DRBIO.SYS, DRDOS.SYS and COMMAND.COM
#
# (c)opyright 2024 Bernd Boeckmann
#
# This makefile runs the make scripts of the individual components and
# puts the generated binaries into the dist directory

!include platform.mak

!ifdef SINGLEFILE
WMAKE_FLAGS += SINGLEFILE=1
!endif

!ifdef UNCOMPRESSED
WMAKE_FLAGS += UNCOMPRESSED=1
COMPKERN_FLAGS += uncompressed
!endif

FILES += dist/country.sys dist/command.com

!ifdef SINGLEFILE
all: dist/kernel.sys $(FILES) .SYMBOLIC
!else
all: dist/drbio.sys dist/drdos.sys $(FILES) .SYMBOLIC
!endif


image: all .SYMBOLIC
	cd image
	sh mkimage.sh
	cd ..

dist/kernel.sys: drbio/bin/drbio.bin drdos/bin/drdos.bin
	$(COMPKERN) drbio$(SEP)bin$(SEP)drbio.bin drdos$(SEP)bin$(SEP)drdos.bin dist$(SEP)kernel.sys $(COMPKERN_FLAGS)

dist/drbio.sys: drbio/bin/drbio.sys
	$(CP) drbio$(SEP)bin$(SEP)drbio.sys dist$(SEP)drbio.sys

dist/drdos.sys: drdos/bin/drdos.sys
	$(CP) drdos$(SEP)bin$(SEP)drdos.sys dist$(SEP)drdos.sys

dist/country.sys: drdos/bin/country.sys
	$(CP) drdos$(SEP)bin$(SEP)country.sys dist$(SEP)country.sys

dist/command.com: command/bin/command.com
	$(CP) command$(SEP)bin$(SEP)command.com dist$(SEP)command.com

dist/license:
	mkdir dist$(SEP)license

dist/license/license.htm: dist/license license.htm
	$(CP) license.htm dist$(SEP)license$(SEP)license.htm

drbio/bin/drbio.sys: .ALWAYS .RECHECK
	cd drbio
	$(WMAKE) $(WMAKE_FLAGS)
	cd ..

drdos/bin/drdos.sys: .ALWAYS .RECHECK
	cd drdos
	$(WMAKE) $(WMAKE_FLAGS)
	cd ..

drdos/bin/country.sys: .ALWAYS .RECHECK
	cd drdos
	@$(WMAKE) $(WMAKE_FLAGS) bin/country.sys
	cd ..

drbio/bin/drbio.bin: .ALWAYS .RECHECK
	cd drbio
	$(WMAKE) $(WMAKE_FLAGS) bin/drbio.bin
	cd ..

drdos/bin/drdos.bin: .ALWAYS .RECHECK
	cd drdos
	$(WMAKE) $(WMAKE_FLAGS) bin/drdos.bin
	cd ..

command/bin/command.com: .ALWAYS .RECHECK
	cd command
	$(WMAKE)
	cd ..

clean: .SYMBOLIC
	@cd drbio
	@$(WMAKE) clean
	@cd ..
	@cd drdos
	@$(WMAKE) clean
	@cd ..
	@cd command
	@$(WMAKE) clean
	@cd ..
	@rm -f dist/drbio.sys
	@rm -f dist/DRBIO.SYS
	@rm -f dist/drdos.sys
	@rm -f dist/DRDOS.SYS
	@rm -f dist/drkernel.sys
	@rm -f dist/DRKERNEL.SYS
	@rm -f dist/country.sys
	@rm -f dist/COUNTRY.SYS
	@rm -f dist/command.com
	@rm -f dist/COMMAND.COM
	@rm -f dist/license/license.htm
	@rm -f image/edrdos.img

