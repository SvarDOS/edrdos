# Enhanced DR-DOS kernel and command interpreter

This project maintains the sources of _DRBIO.SYS_, _DRDOS.SYS_ and
_COMMAND.COM_ ported to

 - the [JWasm](https://github.com/Baron-von-Riedesel/JWasm) assembler,
   version 2.17 or later, and
 - the [OpenWatcom](https://github.com/open-watcom/open-watcom-v2) toolchain,
   version 1.9 or later.

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
the tools under the `ltools/unix` directory first by invoking `make` inside
the directory.

### Running make
You may build DRBIO.SYS, DRDOS.SYS and COMMAND.COM by calling the OpenWatcom
make utility `wmake` from the project root directory. The generated binaries
will be placed under the _dist_ directory.

You may instead build the individual components by invoking `wmake` under the
directory of the components. The built binaries are then placed into the _bin_
subdirectory for the components, like _drbio/bin/drbio.sys_.


## Installation

After building, make sure that the _dist_ directory contains DRBIO.SYS,
DRDOS.SYS, COMMAND.COM and SYS.COM.

### Using SYS under DOS
Under DOS, you may use the provided SYS command to make a bootable disk.
To make a bootable floppy disk, insert a freshly formatted
floppy disk into drive A: (you may substitute the drive letter).

Then invoke:

    SYS A:

*from within* the directory containing the files mentioned above. The
SYS command then copies DRBIO.SYS, DRDOS.SYS and COMMAND.COM onto the
floppy and installs a boot loader to make the floppy bootable.

The provided SYS command is part of the FreeDOS kernel repository
The binary was built from this specific
[commit](https://github.com/FDOS/kernel/commit/c0127001908405d30d90f1755ad10c1b59ea8c90).

FreeDOS SYS is distributed under the
[GNU public license](https://github.com/FDOS/kernel/blob/master/COPYING).


### Using mkimage.sh under UNIX-like operating systems
Under Linux and MacOS, you may invoke `sh mkimage.sh` under the _image_
directory. This generates a 1.44M floppy image `edrdos.img`. Make sure
to build the binaries prior to running this script.

The script depends on [Mtools](https://www.gnu.org/software/mtools/) and _dd_
to be installed.

The [code for the installed bootsector](https://github.com/FDOS/kernel/blob/c0127001908405d30d90f1755ad10c1b59ea8c90/boot/boot.asm)
comes from FreeDOS.
