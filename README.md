# Enhanced DR-DOS Kernel fork

## Build instructions
Building the kernel is currently supported under a MS-DOS compatible
operating system. The following tools are required:

- [OpenWatcom](https://github.com/open-watcom/open-watcom-v2), v1.9 or newer
  (wmake and exe2bin)
- [JWasm assembler](https://github.com/Baron-von-Riedesel/JWasm)

To build `DRBIO.SYS`, `DRDOS.SYS` and `COMMAND.COM`, invoke
`wmake` from within their sub-directories. The output files
are written to the `BIN` directory of the component,
like `DRBIO\BIN\DRBIO.SYS`.

You may consider using [FreeCOM](https://github.com/FDOS/freecom) or another
command interpreter like 4DOS or SvarCOM instead of `COMMAND.COM`.

## Kernel installation
To install the kernel you may use a custom build of the FreeDOS SYS
command, which is part of the
[FreeDOS Kernel](https://github.com/FDOS/kernel) repository. A pre-built
binary is provided under the name `DRSYS.COM` with the binary releases on
this site, along with more detailed installation instructions.
