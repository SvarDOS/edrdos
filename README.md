# Enhanced DR-DOS Kernel fork

## Build instructions
Building the kernel is currently supported with the following tools:

- [OpenWatcom](https://github.com/open-watcom/open-watcom-v2), v1.9 or newer
  (WMAKE, WLINK and EXE2BIN)
- [JWasm assembler](https://github.com/Baron-von-Riedesel/JWasm), v2.17 or newer

I was able to successfully build the kernel and command interpreter under
DOS, Win32 and MacOS. It should also build under Linux.

To build `DRBIO.SYS`, `DRDOS.SYS` and `COMMAND.COM`, invoke
`wmake` from within their sub-directories. The output files
are written to the `BIN` directory of the component,
like `DRBIO\BIN\DRBIO.SYS`.

You may consider using [FreeCOM](https://github.com/FDOS/freecom) or another
command interpreter like 4DOS or SvarCOM instead of `COMMAND.COM`.

## Kernel installation
To install the kernel you may use a recent build of the FreeDOS SYS
command, which is part of the
[FreeDOS Kernel](https://github.com/FDOS/kernel) repository. A pre-built
binary is provided under the name `DRSYS.COM` with the binary releases on
this site, along with more detailed installation instructions.
