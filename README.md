# Enhanced DR-DOS kernel and command interpreter

This project maintains the sources of _DRBIO.SYS_, _DRDOS.SYS_ and
_COMMAND.COM_ ported to

 - the [JWasm](https://github.com/Baron-von-Riedesel/JWasm) assembler,
   version 2.17 or later, and
 - the [OpenWatcom](https://github.com/open-watcom/open-watcom-v2) toolchain,
   version 1.9 or later.

## Binary snapshots
Binaries and a 1.44M floppy image are built automatically through Github
actions. To download them, go to the [actions page](https://github.com/SvarDOS/edrdos/actions),
and then click the last successful workflow build job. The files are provided
under the artifacts section.

## Kernel flavors
The EDR-DOS kernel may be built in different flavors. The historic one
consists of two files, DRBIO.SYS and DRDOS.SYS. The new one consists of
a single file KERNEL.SYS. The historic one is what gets built by default.

KERNEL.SYS is compatible with the FreeDOS load protocol. It can be used
as a drop in for the FreeDOS KERNEL.SYS by replacing it with the EDR KERNEL.SYS.
Notice that the kernels are not 100% compatible, especially regarding
the drive letter ordering and the expected format of the config.sys files.


## Build instructions
I was able to successfully build the kernel and command interpreter under
DOS, Win32, Linux and MacOS.

### Requirements
The makefiles expect the following executables to be present:
 - _jwasm_, for DOS it is _jwasmr_
 - _wmake_
 - _wlink_
 - _exe2bin_
 - and _wcl_ if building command.com.

Further, if you build under a UNIX-like operating system, make sure to build
the tools under the _ltools/unix_ directory first by invoking `make` inside
the directory.

### Running make
You may build DRBIO.SYS, DRDOS.SYS and COMMAND.COM by calling the OpenWatcom
make utility `wmake` from the project root directory. The generated binaries
will be placed under the _dist_ directory.

You may instead build the individual components by invoking `wmake` under the
directory of the components. The built binaries are then placed into the _bin_
subdirectory for the components, like _drbio/bin/drbio.sys_.

You may generate uncompressed DRBIO.SYS and DRDOS.SYS binaries by invoking
`wmake UNCOMPRESSED=1` from the main directory or the directories of the
components.

## Building single-file kernel
You may build a single file version of the kernel by calling the master
makefile via `wmake SINGLEFILE=1`. The kernel file is named KERNEL.SYS.
The single-file kernel can also be built uncompressed, but then it lacks
the ability to be used as a replacement for FreeDOS KERNEL.SYS. The reason
is that the EDR-DOS kernel lives at segment 70h, while the FreeDOS loader
loads the kernel to 60h. The compressed kernel relocates itself to the
correct segment at the uncompression stage, so the uncompressed kernel
lacks this ability.

## Installation

After building, make sure that the _dist_ directory contains

 - DRBIO.SYS and DRDOS.SYS, or KERNEL.SYS
 - COMMAND.COM
 - SYS.COM

### Using SYS under DOS
Under DOS, you may use the provided SYS command to make a bootable disk.
To make a bootable floppy, insert a freshly formatted disk into
drive A: (you may have to substitute the drive letter).

Then invoke:

    SYS A:

*from within* the directory containing the files mentioned above. The
SYS command then copies DRBIO.SYS, DRDOS.SYS and COMMAND.COM onto the
floppy and installs a boot loader to make the floppy bootable, or
KERNEL.SYS and COMMAND.COM if the single-file kernel was built.

You may also manually copy KERNEL.SYS over to the drive to be booted
from and name it DRBIO.SYS. Like so:

    SYS A: /BOOTONLY /OEM:EDR
    COPY KERNEL.SYS A:\DRBIO.SYS
    COPY COMMAND.COM A:\COMMAND.COM

The kernel than utilizes the ordinary EDR-DOS boot protocol, but with
DRBIO.SYS being a combined DRBIO / DRDOS file. This also works with
an uncompressed KERNEL.SYS.

The provided SYS command is part of the FreeDOS kernel repository
The binary was built from this specific
[commit](https://github.com/FDOS/kernel/commit/c0127001908405d30d90f1755ad10c1b59ea8c90).

FreeDOS SYS is distributed under the
[GNU public license](https://github.com/FDOS/kernel/blob/master/COPYING).


### Using mkimage.sh under UNIX-like operating systems
Under Linux and MacOS, you may invoke `sh mkimage.sh` under the _image_
directory. This generates a 1.44M floppy image `edrdos.img`. Make sure
to build the binaries prior to running this script.

To build a single-file image, invoke `sh mkimage.sh singlefile`.

The script depends on [Mtools](https://www.gnu.org/software/mtools/) and _dd_
being installed.

The [code for the installed bootsector](https://github.com/FDOS/kernel/blob/c0127001908405d30d90f1755ad10c1b59ea8c90/boot/boot.asm)
comes from FreeDOS.
