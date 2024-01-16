@ECHO off

SET JWASMEXE=C:\BIN\JWASM.EXE

REM 
REM YOU SHOULD NOT HAVE TO CHANGE ANYTHING BELOW THIS LINE.
REM 

REM Define local Caldera tools
SET LOCTOOLS=..\LTOOLS

IF NOT EXIST BIN\*.* MD BIN

ECHO Checking for %JWASMEXE%
if not exist %JWASMEXE% goto badtool

copy ..\version.inc . /y

REM ******************************************
REM Build the .A86 files next, get the obj's
REM ******************************************

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\buffers.a86 .\bin\buffers.o86 $szpz  /DDELWATCH /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\dirs.a86 .\bin\dirs.o86 $szpz /DDELWATCH
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\fdos.a86 .\bin\fdos.o86 $szpz /DDELWATCH /DKANJI /DDOS5 /DPASSWORD /DJOIN /DUNDELETE /Dshortversion
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\fcbs.a86 .\bin\fcbs.o86
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\bdevio.a86 .\bin\bdevio.o86 $szpz /DDELWATCH /DDOS5 /DJOIN
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\cdevio.a86 .\bin\cdevio.o86 $szpz /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\fioctl.a86 .\bin\fioctl.o86 $szpz /DPASSWORD /DJOIN /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\redir.a86 .\bin\redir.o86 $szpz /DKANJI /DDOS5 /DJOIN
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\header.a86 .\bin\header.o86 $szpz /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\pcmif.a86 .\bin\pcmif.o86 $szpz /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\cio.a86 .\bin\cio.o86
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\disk.a86 .\bin\disk.o86 $szpz /DDELWATCH
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\ioctl.a86 .\bin\ioctl.o86 $szpz /DPASSWORD /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\misc.a86 .\bin\misc.o86 $szpz /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\support.a86 .\bin\support.o86
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\dosmem.a86 .\bin\dosmem.o86
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\error.a86 .\bin\error.o86
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\process.a86 .\bin\process.o86 $szpz /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\network.a86 .\bin\network.o86
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\int2f.a86 .\bin\int2f.o86 $szpz /DDOS5 /DDELWATCH
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\history.a86 .\bin\history.o86
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\cmdline.a86 .\bin\cmdline.o86
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\dos7.asm .\bin\dos7.o86
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\lfn.asm .\bin\lfn.o86
IF ERRORLEVEL 1 GOTO FAILED

%JWASMEXE% -c -Zm -Zg -Fo.\BIN\dosgrps dosgrps.asm
IF ERRORLEVEL 1 GOTO FAILED

for %f in (buffers dirs fdos fcbs) do %LOCTOOLS%\fixupp bin\%f.o86 bin\%f.obj
for %f in (bdevio cdevio fioctl redir) do %LOCTOOLS%\fixupp bin\%f.o86 bin\%f.obj
for %f in (header pcmif cio disk ioctl) do %LOCTOOLS%\fixupp bin\%f.o86 bin\%f.obj
for %f in (misc support dosmem error) do %LOCTOOLS%\fixupp bin\%f.o86 bin\%f.obj
for %f in (process network int2f history) do %LOCTOOLS%\fixupp bin\%f.o86 bin\%f.obj
for %f in (cmdline dos7 lfn) do %LOCTOOLS%\fixupp bin\%f.o86 bin\%f.obj

warplink @wldrdos.lnk
IF ERRORLEVEL 1 GOTO FAILED
echo.
x2b2 .\bin\drdos.exe .\bin\drdos.bin
IF ERRORLEVEL 1 GOTO FAILED
del .\bin\drdos.exe
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\round .\bin\drdos.bin .\bin\drdos.sys 128
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\compbdos .\BIN\drdos.sys
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
