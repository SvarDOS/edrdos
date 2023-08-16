@ECHO off

SET JWASMEXE=C:\BIN\JWASM.EXE

REM 
REM YOU SHOULD NOT HAVE TO CHANGE ANYTHING BELOW THIS LINE.
REM 

REM Define local Caldera tools
SET LOCTOOLS=..\LTOOLS

IF NOT EXIST BIN\*.* MD BIN

REM Check if tools exist

ECHO Checking for %JWASMEXE%
if not exist %JWASMEXE% goto badtool

copy ..\version.inc . /y

REM *************************************
REM Build .ASM files first, get the obj's
REM *************************************

%JWASMEXE% -c -Zm -Zg -Fo.\BIN\initmsgs initmsgs.asm
IF ERRORLEVEL 1 GOTO FAILED
%JWASMEXE% -c -Zm -Zg -Fo.\BIN\biosmsgs biosmsgs.asm
IF ERRORLEVEL 1 GOTO FAILED
%JWASMEXE% -c -Zm -Zg -Fl.\BIN\init.lst -Fo.\BIN\init init.asm
IF ERRORLEVEL 1 GOTO FAILED
%JWASMEXE% -c -Zm -Zg -Fo.\BIN\clock clock.asm
IF ERRORLEVEL 1 GOTO FAILED
%JWASMEXE% -c -Zm -Zg -Fo.\BIN\console console.asm
IF ERRORLEVEL 1 GOTO FAILED
%JWASMEXE% -c -Zm -Zg -Fo.\BIN\disk disk.asm
IF ERRORLEVEL 1 GOTO FAILED
%JWASMEXE% -c -Zm -Zg -Fo.\BIN\serpar serpar.asm
IF ERRORLEVEL 1 GOTO FAILED
%JWASMEXE% -c -Zm -Zg -Fo.\BIN\biosgrps biosgrps.asm
IF ERRORLEVEL 1 GOTO FAILED
%JWASMEXE% -c -Zm -Zg -Fo.\BIN\stacks stacks.asm
IF ERRORLEVEL 1 GOTO FAILED

REM ******************************************
REM Build the library so that we can link into
REM ******************************************
%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\confstub.a86 .\BIN\confstub.obj $szpz /DDRDOS35=0 /DADDDRV=0
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\fixupp .\BIN\confstub.obj
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\bdosstub.a86 .\BIN\bdosstub.obj $szpz /DDRDOS35=0 /DADDDRV=0
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\fixupp .\BIN\bdosstub.obj
IF ERRORLEVEL 1 GOTO FAILED

REM ******************************************
REM Build the .A86 files next, get the obj's
REM ******************************************
%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\biosinit.a86 .\BIN\biosinit.obj $szpz /DDRDOS35=0 /DADDDRV=0
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\fixupp .\BIN\biosinit.obj
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\config.a86 .\BIN\config.obj $szpz /DDRDOS35=0 /DADDDRV=0
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\fixupp .\BIN\config.obj
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\bdosldr.a86 .\BIN\bdosldr.obj $szpz /DDRDOS35=0 /DADDDRV=0
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\fixupp .\BIN\bdosldr.obj
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\genercfg.a86 .\BIN\genercfg.obj $szpz /DDRDOS35=0 /DADDDRV=0
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\fixupp .\BIN\genercfg.obj
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\nlsfunc.a86 .\BIN\nlsfunc.obj $szpz /DDRDOS35=0 /DADDDRV=0
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\fixupp .\BIN\nlsfunc.obj
IF ERRORLEVEL 1 GOTO FAILED

REM ***************************************************
REM Link the OBJ's and LIBR file to create the BIOS.EXE
REM and then use EXE2BIN to create the DRBIO.SYS file.
REM ***************************************************
warplink @wlbios.lnk
IF ERRORLEVEL 1 GOTO FAILED
echo.
x2b2 .\bin\bios.exe .\bin\drbio.sys
IF ERRORLEVEL 1 GOTO FAILED
del .\bin\bios.exe
%LOCTOOLS%\compbios .\bin\drbio.sys
IF ERRORLEVEL 1 GOTO FAILED
goto exit

:failed
ECHO Error in Build!
goto exit

:badtool
ECHO Can't find that tool!

:exit
REM *********
REM CLEANUP
REM *********

SET LOCTOOLS=
