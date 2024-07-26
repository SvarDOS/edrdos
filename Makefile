
# Enhanced DR-DOS master Makefile for OpenWatcom WMAKE
# to build DRBIO.SYS, DRDOS.SYS and COMMAND.COM
#
# (c)opyright 2024 Bernd Boeckmann
#
# This makefile runs the make scripts of the individual components and
# puts the generated binaries into the bin directory

!include platform.mak

!ifdef SINGLEFILE
WMAKE_FLAGS += SINGLEFILE=1
!endif

!ifdef UNCOMPRESSED
WMAKE_FLAGS += UNCOMPRESSED=1
COMPKERN_FLAGS += uncompressed
!endif

FILES += bin/country.sys bin/command.com

!ifdef SINGLEFILE
all: bin/kernel.sys $(FILES) .SYMBOLIC
!else
all: bin/drbio.sys bin/drdos.sys $(FILES) .SYMBOLIC
!endif


image: all .SYMBOLIC
	cd image
	sh mkimage.sh
	cd ..

bin/kernel.sys: drbio/bin/drbio.bin drdos/bin/drdos.bin
	$(COMPKERN) drbio$(SEP)bin$(SEP)drbio.bin drdos$(SEP)bin$(SEP)drdos.bin bin$(SEP)kernel.sys $(COMPKERN_FLAGS)

bin/drbio.sys: drbio/bin/drbio.sys
	$(CP) drbio$(SEP)bin$(SEP)drbio.sys bin$(SEP)drbio.sys

bin/drdos.sys: drdos/bin/drdos.sys
	$(CP) drdos$(SEP)bin$(SEP)drdos.sys bin$(SEP)drdos.sys

bin/country.sys: drdos/bin/country.sys
	$(CP) drdos$(SEP)bin$(SEP)country.sys bin$(SEP)country.sys

bin/command.com: command/bin/command.com
	$(CP) command$(SEP)bin$(SEP)command.com bin$(SEP)command.com

bin/license:
	mkdir bin$(SEP)license

bin/license/license.htm: bin/license license.htm
	$(CP) license.htm bin$(SEP)license$(SEP)license.htm

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
	@rm -f bin/drbio.sys
	@rm -f bin/DRBIO.SYS
	@rm -f bin/drdos.sys
	@rm -f bin/DRDOS.SYS
	@rm -f bin/kernel.sys
	@rm -f bin/KERNEL.SYS
	@rm -f bin/country.sys
	@rm -f bin/COUNTRY.SYS
	@rm -f bin/command.com
	@rm -f bin/COMMAND.COM
	@rm -f bin/license/license.htm
	@rm -f image/edrdos.img

