#!/bin/sh
# create a 1.44M floppy image containing the kernel and command interpreter
# requires Mtools

IMAGE=edrdos.img
LABEL=EDR-DOS
SIZE=1440
SERIAL=0x306de779

# determine operating mode
if [ "$1" = "singlefile" -o "$1" = "" ]; then
	MODE=singlefile
	echo "Making single-file KERNEL.SYS image."
elif [ "$1" = "dualfile" ]; then
	MODE=dualfile
	echo "Making dual-file kernel image."
elif [ "$1" = "singlefile-drbio" ]; then
	MODE=singlefile-drbio
	echo "Making single-file DRBIO.SYS image."
else
	echo "Usage: mkimage [singlefile|dualfile|singlefile-drbio]"
	exit 1
fi

# check for tools
if ! command -v mdir > /dev/null 2>&1; then
	echo "error: Mtools needed"
	exit 1
fi

# create a blank, formatted image and copy kernel to image
case $MODE in
singlefile)
	mformat -i $IMAGE -B bootfdos.144 -k -v $LABEL -f $SIZE -N $SERIAL -C
	mcopy -i $IMAGE ../bin/kernel.sys ::/kernel.sys
	;;
dualfile)
	mformat -i $IMAGE -B bootedr.144 -k -v $LABEL -f $SIZE -N $SERIAL -C
	mcopy -i $IMAGE ../bin/drbio.sys ::/
	mcopy -i $IMAGE ../bin/drdos.sys ::/
	;;
singlefile-drbio)
	mformat -i $IMAGE -B bootedr.144 -k -v $LABEL -f $SIZE -N $SERIAL -C
	mcopy -i $IMAGE ../bin/kernel.sys ::/drbio.sys
	;;
esac

# copy command interpreter and support files to image
mmd -i $IMAGE ::/license
mcopy -i $IMAGE ../bin/command.com ::/
mcopy -i $IMAGE ../bin/country.sys ::/
mcopy -i $IMAGE ../bin/sys.com ::/
mcopy -i $IMAGE ../license/gpl.txt ::/license/
mcopy -i $IMAGE ../license.htm ::/license/
mcopy -i $IMAGE dconfig.sys ::/
mcopy -i $IMAGE dauto.bat ::/

# copy additional files from the files subdirectory
if [ -d files ]; then
	mcopy -i $IMAGE -s -o files/* ::/
fi
