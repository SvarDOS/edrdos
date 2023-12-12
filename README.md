# Enhanced DR-DOS Kernel fork

## Build instructions
Building the kernel is currently supported under a MS-DOS compatible
operating system. The following tools are required:

- [OpenWatcom](https://github.com/open-watcom/open-watcom-v2), v1.9 or newer
  (wmake and exe2bin)
- [JWasm assembler](https://github.com/Baron-von-Riedesel/JWasm)

To build `DRBIO.SYS`, invoke `wmake -f makefile.wat` inside the `DRBIO`
directory. The output file is `DRBIO\BIN\DRBIO.SYS`.

To build `DRDOS.SYS`, invoke `wmake -f makefile.wat` inside the `DRDOS`
directory. The output file is `DRDOS\BIN\DRDOS.SYS`.


## Kernel installation
To install the kernel you may use a custom build of the FreeDOS SYS
command, which is part of the
[FreeDOS Kernel](https://github.com/FDOS/kernel) repository. A pre-built
binary is provided under the name `DRSYS.COM` with the binary releases on
this site, along with more detailed installation instructions.
