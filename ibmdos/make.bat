@ECHO off

SET TOOLS=C:\TOOLS

REM 
REM YOU SHOULD NOT HAVE TO CHANGE ANYTHING BELOW THIS LINE.
REM 

REM Define local Caldera tools
SET LOCTOOLS=..\LTOOLS

IF NOT EXIST BIN\*.* MD BIN

REM ******************************************
REM Build the .A86 files next, get the obj's
REM ******************************************

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\buffers.a86 .\bin\buffers.obj $szpz  /DDELWATCH /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\dirs.a86 .\bin\dirs.obj $szpz /DDELWATCH
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\fdos.a86 .\bin\fdos.obj $szpz /DDELWATCH /DKANJI /DDOS5 /DPASSWORD /DJOIN /DUNDELETE
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\fcbs.a86 .\bin\fcbs.obj
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\bdevio.a86 .\bin\bdevio.obj $szpz /DDELWATCH /DDOS5 /DJOIN
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\cdevio.a86 .\bin\cdevio.obj $szpz /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\fioctl.a86 .\bin\fioctl.obj $szpz /DPASSWORD /DJOIN /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\redir.a86 .\bin\redir.obj $szpz /DKANJI /DDOS5 /DJOIN
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\header.a86 .\bin\header.obj $szpz /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\pcmif.a86 .\bin\pcmif.obj $szpz /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\cio.a86 .\bin\cio.obj
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\disk.a86 .\bin\disk.obj $szpz /DDELWATCH
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\ioctl.a86 .\bin\ioctl.obj $szpz /DPASSWORD /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\misc.a86 .\bin\misc.obj $szpz /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\support.a86 .\bin\support.obj
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\dosmem.a86 .\bin\dosmem.obj
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\error.a86 .\bin\error.obj
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\process.a86 .\bin\process.obj $szpz /DDOS5
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\network.a86 .\bin\network.obj
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\int2f.a86 .\bin\int2f.obj $szpz /DDOS5 /DDELWATCH
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\history.a86 .\bin\history.obj
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\rasm_sh %LOCTOOLS%\rasm86.exe . .\cmdline.a86 .\bin\cmdline.obj
IF ERRORLEVEL 1 GOTO FAILED

copy ibmdos.inp .\BIN
CD .\BIN
..\%LOCTOOLS%\linkcmd.exe ibmdos[i]
IF ERRORLEVEL 1 GOTO FAILED
CD ..
%LOCTOOLS%\bin2asc -ob -s128 .\BIN\ibmdos.tmp .\BIN\ibmdos.com
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\compbdos .\BIN\ibmdos.com
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

SET TOOLS=
SET LTOOLS=
