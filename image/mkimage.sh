#!/bin/sh
# create a 1.44M floppy image containing the kernel and command interpreter
# requires Mtools

IMAGE=edrdos.img
LABEL=EDR-DOS

dd if=/dev/zero of=$IMAGE bs=512 count=2880
mformat -i $IMAGE -v $LABEL

if [ "$1" = "singlefile" ]; then
	echo "Making single-file KERNEL.SYS image."
	dd if=bootfdos.144 of=$IMAGE bs=512 count=1 conv=notrunc
	mcopy -i $IMAGE ../bin/kernel.sys ::/kernel.sys
elif [ "$1" = "singlefile-drbio" ]; then
	echo "Making single-file DRBIO.SYS image."
	dd if=bootedr.144 of=$IMAGE bs=512 count=1 conv=notrunc
	mcopy -i $IMAGE ../bin/kernel.sys ::/drbio.sys
else
	echo "Making dual-file kernel image."
	dd if=bootedr.144 of=$IMAGE bs=512 count=1 conv=notrunc
	mcopy -i $IMAGE ../bin/drbio.sys ::/
	mcopy -i $IMAGE ../bin/drdos.sys ::/
fi
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
