#!/bin/sh
# create a 1.44M floppy image containing the kernel and command interpreter
# requires Mtools

IMAGE=edrdos.img
LABEL=EDR-DOS

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
if ! command -v mdir --help >/dev/null 2>&1; then
	echo "error: Mtools needed"
	exit 1
fi

# create a blank, formatted 1.44M image
dd if=/dev/zero of=$IMAGE bs=512 count=2880
mformat -i $IMAGE -v $LABEL

# copy kernel to image
case $MODE in
singlefile)
	dd if=bootfdos.144 of=$IMAGE bs=512 count=1 conv=notrunc
	mcopy -i $IMAGE ../bin/kernel.sys ::/kernel.sys
	;;
dualfile)
	dd if=bootedr.144 of=$IMAGE bs=512 count=1 conv=notrunc
	mcopy -i $IMAGE ../bin/drbio.sys ::/
	mcopy -i $IMAGE ../bin/drdos.sys ::/
	;;
singlefile-drbio)
	dd if=bootedr.144 of=$IMAGE bs=512 count=1 conv=notrunc
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
