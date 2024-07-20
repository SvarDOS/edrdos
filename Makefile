
# Enhanced DR-DOS master Makefile for OpenWatcom WMAKE
# to build DRBIO.SYS, DRDOS.SYS and COMMAND.COM
#
# (c)opyright 2024 Bernd Boeckmann
#
# This makefile runs the make scripts of the individual components and
# puts the generated binaries into the dist directory

!include platform.mak

all: dist/drbio.sys dist/drdos.sys dist/country.sys dist/command.com dist/license/edrdos.htm .SYMBOLIC

dist/drbio.sys: drbio/bin/drbio.sys
	$(CP) drbio$(SEP)bin$(SEP)drbio.sys dist$(SEP)drbio.sys

dist/drdos.sys: drdos/bin/drdos.sys
	$(CP) drdos$(SEP)bin$(SEP)drdos.sys dist$(SEP)drdos.sys

dist/country.sys: drdos/bin/country.sys
	$(CP) drdos$(SEP)bin$(SEP)country.sys dist$(SEP)country.sys

dist/command.com: command/bin/command.com
	$(CP) command$(SEP)bin$(SEP)command.com dist$(SEP)command.com

dist/license:
	mkdir dist/license

dist/license/edrdos.htm: dist/license
	$(CP) license.htm dist/license/edrdos.htm

drbio/bin/drbio.sys: .ALWAYS
	cd drbio
	$(WMAKE)
	cd ..

drdos/bin/drdos.sys: .ALWAYS
	cd drdos
	$(WMAKE)
	cd ..

command/bin/command.com: .ALWAYS
	cd command
	$(WMAKE)
	cd ..

clean: .SYMBOLIC
	cd drbio
	$(WMAKE) clean
	cd ..
	cd drdos
	$(WMAKE) clean
	cd ..
	cd command
	$(WMAKE) clean
	cd ..
	rm -f dist/drbio.sys
	rm -f dist/DRBIO.SYS
	rm -f dist/drdos.sys
	rm -f dist/DRDOS.SYS
	rm -f dist/country.sys
	rm -f dist/COUNTRY.SYS
	rm -f dist/command.com
	rm -f dist/COMMAND.COM
	rm -f image/edrdos.img

