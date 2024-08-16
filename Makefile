
# Enhanced DR-DOS master Makefile for OpenWatcom WMAKE
# to build DRBIO.SYS, DRDOS.SYS and COMMAND.COM
#
# (c)opyright 2024 Bernd Boeckmann
#
# This makefile runs the make scripts of the individual components and
# puts the generated binaries into the bin directory

!include platform.mak

!ifeq SINGLEFILE 1
WMAKE_FLAGS += SINGLEFILE=1
!endif

!ifeq COMPRESSED 0
WMAKE_FLAGS += COMPRESSED=0
COMPKERN_FLAGS += uncompressed
!endif

FILES += bin/country.sys bin/command.com

!ifdef SINGLEFILE
all: bin/kernel.sys $(FILES) .SYMBOLIC
!else
all: bin/drbio.sys bin/drdos.sys $(FILES) .SYMBOLIC
!endif

WMAKE_FLAGS += VERSION=$(VERSION) GIT_REV=$(GIT_REV)

image: all .SYMBOLIC
	cd image
	sh mkimage.sh singlefile
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
	$(WMAKE) $(WMAKE_FLAGS) $(BIO_FLAGS)
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
	$(WMAKE) $(WMAKE_FLAGS) $(BIO_FLAGS) bin/drbio.bin
	cd ..

drdos/bin/drdos.bin: .ALWAYS .RECHECK
	cd drdos
	$(WMAKE) $(WMAKE_FLAGS) bin/drdos.bin
	cd ..

command/bin/command.com: .ALWAYS .RECHECK
	cd command
	$(WMAKE)
	cd ..

# SvarDOS .svp package
kernledr.svp: pkg/kernel.sys pkg/bin/country.sys pkg/doc/license.htm pkg/appinfo/kernledr.lsm
	cd pkg
	zip -9rkDX ..$(SEP)$@ *
	cd ..

pkg/kernel.sys: pkg bin/kernel.sys
	$(CP) $]@ $@

pkg:
	mkdir $@

pkg/bin: pkg
	mkdir $@

pkg/bin/country.sys: pkg/bin bin/country.sys
	$(CP) $]@ $@

pkg/appinfo: pkg
	mkdir $@

pkg/appinfo/kernledr.lsm: pkg/appinfo .ALWAYS
	%create $@
	%append $@ version: $(VERSION)
	%append $@ description: Enhanced DR-DOS kernel
	%append $@ warn: EDR kernel installed. Please reboot to activate it.

pkg/doc:
	mkdir $@

pkg/doc/license.htm: pkg/doc license.htm
	$(CP) $]@ $@



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
	# SvarDOS package
	@rm -f pkg/kernel.sys
	@rm -f pkg/bin/country.sys
	@rm -f pkg/doc/license.htm
	@rm -f pkg/appinfo/kernledr.lsm
	@rm -f kernledr.svp

