@ECHO off
SET TOOLS=C:\TOOLS

SET MASM=%TOOLS%\MASM.EXE
SET LINK=%TOOLS%\LINK.EXE
SET LIBR=%TOOLS%\LIB.EXE

REM 
REM YOU SHOULD NOT HAVE TO CHANGE ANYTHING BELOW THIS LINE.
REM 

REM Define local Caldera tools
SET LOCTOOLS=..\LTOOLS

IF NOT EXIST BIN\*.* MD BIN

REM Check if tools exist

ECHO Checking for %MASM%
if not exist %MASM% goto badtool
ECHO Checking for %LINK%
if not exist %LINK% goto badtool
ECHO Checking for %LIBR%
if not exist %LIBR% goto badtool


REM *************************************
REM Build .ASM files first, get the obj's
REM *************************************

%MASM% /t initmsgs,.\BIN\initmsgs;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /t biosmsgs,.\BIN\biosmsgs;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /t init,.\BIN\init;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /t clock,.\BIN\clock;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /t console,.\BIN\console;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /t disk,.\BIN\disk;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /t serpar,.\BIN\serpar;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /t biosgrps,.\BIN\biosgrps;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /t stacks,.\BIN\stacks;
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
%LIBR% .\BIN\biosstub.LIB -+ .\BIN\bdosstub.obj -+ .\BIN\confstub.obj;
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
REM and then use EXE2BIN to create the IBMBIO.COM file.
REM ***************************************************
%LINK% @bios.lnk
IF ERRORLEVEL 1 GOTO FAILED
%LOCTOOLS%\exe2bin.exe .\bin\bios.exe .\bin\ibmbio.com
IF ERRORLEVEL 1 GOTO FAILED
del .\bin\bios.exe
%LOCTOOLS%\compbios .\bin\ibmbio.com
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
SET LOCTOOLS=
SET MASM=
SET TASM=
SET LINK=
SET LIBR=
