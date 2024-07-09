#!/bin/sh
# create a 1.44M floppy image containing the kernel and command interpreter
# requires Mtools

IMAGE=edrdos.img
LABEL=EDR-DOS

dd if=/dev/zero of=$IMAGE bs=512 count=2880
mformat -i $IMAGE -v $LABEL
dd if=bootsect.144 of=$IMAGE bs=512 count=1 conv=notrunc
mcopy -i $IMAGE ../dist/drbio.sys ::/
mcopy -i $IMAGE ../dist/drdos.sys ::/
mcopy -i $IMAGE ../dist/command.com ::/
mcopy -i $IMAGE ../dist/sys.com ::/
