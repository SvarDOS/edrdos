# Enhanced DR-DOS kernel and command interpreter

This project maintains the sources of the Enhanced DR-DOS (EDR) kernel
and command interpreter ported to

 - the [JWasm](https://github.com/Baron-von-Riedesel/JWasm) assembler,
   version 2.17 or later, and
 - the [OpenWatcom](https://github.com/open-watcom/open-watcom-v2) toolchain,
   version 1.9 or later.


## Kernel flavors
The EDR kernel may be built in different flavors. The historic one
consists of two files, _DRBIO.SYS_ and _DRDOS.SYS_. The new one consists of
a single file _KERNEL.SYS_. The historic one is what gets built by default.

The kernel is compatible with the FreeDOS load protocol. It can be used
as a drop in for the FreeDOS KERNEL.SYS by replacing it with the EDR KERNEL.SYS.

Notice that the EDR and FreeDOS kernels are not 100% compatible,
especially regarding the drive letter ordering and the expected format
of the config.sys files.


## Binary snapshots
Binaries and a 1.44M floppy image are built automatically through Github
actions. To download them, go to the [actions page](https://github.com/SvarDOS/edrdos/actions),
and then click the last successful workflow build job. The files are provided
under the artifacts section.


## Build instructions
I was able to successfully build the kernel and command interpreter under
DOS, Win32, Linux and MacOS.

### Requirements
The makefiles expect the following executables to be present:
 - _jwasm_, for DOS it is _jwasmd_
 - _wmake_
 - _wlink_
 - _exe2bin_
 - and _wcl_ if building command.com.

Further, if you build under a UNIX-like operating system, make sure to build
the tools under the _ltools/unix_ directory first by invoking `make` inside
the directory.

### Building single-file kernel
You may build the single-file version of the kernel and the command interpreter
by calling the OpenWatcom wmake utility via `wmake SINGLEFILE=1` from
the project root directory. The kernel file is named _KERNEL.SYS_, and the
command interpreter is named _COMMAND.COM_. Both files are placed under the
_bin_ directory.

### Building dual-file kernel
You may build the historic dual-file version of the kernel consisting of
DRBIO.SYS and DRDOS.SYS by invoking `wmake` from the project root directory.
The generated kernel binaries and COMMAND.COM will be placed under the _bin_
directory.

### Building an uncompressed kernel
You may generate uncompressed kernel binaries by giving 
`COMPRESSED=0` to the wmake calls above.

### Version and Git revision
Version and revision information may be given to wmake via
`VERSION=<YYYYMMDD>` and / or `GIT_REV=<8-digit commit hash>`. This info
is shown upon kernel boot. If this information is not provided, `?`
is displayed instead.

The helper script _build.sh_ can be used under Unix like operating systems
to call wmake with VERSION set to the current date and GIT_REV to the
current Git revision.

### Cleaning the tree
Run `wmake clean` in the project root directory to remove the files
created during build.


## Installation

After building, make sure that the _bin_ directory contains

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

You may also manually copy the kernel and command interpreter over to
the drive to be booted, like so for the single-file version:

    SYS A: /BOOTONLY
    COPY KERNEL.SYS A:\
    COPY COMMAND.COM A:\

SYS is then only used to install a proper bootloader. If it is already
installed, you may skip the first step. But you then have to make sure
that the boot loader already installed "speaks" the right protocol.
This is the FreeDOS boot protocol for KERNEL.SYS, and the EDR boot
protocol for DRBIO.SYS and DRDOS.SYS.

Technically, you can also use
DRBIO.SYS with the FreeDOS boot prococol, but then you have to rename
it to KERNEL.SYS. Otherwise, the bootloader will not find its kernel.

### Using mkimage.sh under UNIX-like operating systems
Under Linux and MacOS, you may invoke `sh mkimage.sh` under the _image_
directory. This generates a 1.44M floppy image `edrdos.img`. Make sure
to build the binaries prior to running this script.

To build a single-file image, invoke `sh mkimage.sh singlefile`. To
build a dual-file image, simply invoke `sh mkimage.sh`.

The script depends on [Mtools](https://www.gnu.org/software/mtools/) and _dd_
being installed.


## Components provided by the FreeDOS project
The provided SYS command is part of the FreeDOS kernel repository
The binary was built from this specific
[commit](https://github.com/FDOS/kernel/commit/c0127001908405d30d90f1755ad10c1b59ea8c90).

FreeDOS SYS is distributed under the
[GNU General Public License](https://github.com/FDOS/kernel/blob/c0127001908405d30d90f1755ad10c1b59ea8c90/sys/sys.c#L14),
v2 or any later version.

The [code for the installed bootsector](https://github.com/FDOS/kernel/blob/c0127001908405d30d90f1755ad10c1b59ea8c90/boot/boot.asm)
comes from FreeDOS.

