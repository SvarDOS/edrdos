@ECHO off
SET TOOLS=C:\MASM\BINB

SET MASM=C:\MASM\BIN\ML.EXE /c /Zm
SET WATCOM=C:\WATCOM
SET WATCOMH=%WATCOM%\H
IF EXIST %WATCOM%\BIN\WCGL.EXE SET WCG=%WATCOM%\BIN\WCGL.EXE
IF EXIST %WATCOM%\BINB\WCC.EXE SET WC=%WATCOM%\BINB\WCC.EXE
IF EXIST %WATCOM%\BINW\WCGL.EXE SET WCG=%WATCOM%\BINW\WCGL.EXE
IF EXIST %WATCOM%\BINW\WCC.EXE SET WC=%WATCOM%\BINW\WCC.EXE
SET LINK510=%TOOLS%\LINK.EXE
SET BCC20=%TOOLS%\BCC.EXE
SET BCC20H=%TOOLS%\BCC20\H

REM
REM YOU SHOULD NOT HAVE TO CHANGE ANYTHING BELOW THIS LINE.
REM 

REM Define local Caldera tools
SET LOCTOOLS=..\LTOOLS

IF NOT EXIST BIN\*.* MD BIN

REM Check if tools exist

ECHO Checking for %MASM%
if not exist %MASM% goto badtool
ECHO Checking for %WC%
if not exist %WC% goto badtool
ECHO Checking for %LINK510%
if not exist %LINK510% goto badtool

rem %MASM% /Fo.\bin\message message
rem IF ERRORLEVEL 1 GOTO FAILED
%MASM% /Fo.\bin\resident resident
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /Fo.\bin\txhelp txhelp
IF ERRORLEVEL 1 GOTO FAILED

%MASM% /DDOSPLUS /DWATCOMC /DPASCAL /DFINAL /I.\ /Fo.\bin\message.obj .\message.asm
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /DDOSPLUS /DWATCOMC /DPASCAL /DFINAL /I.\ /Fo.\bin\cstart.obj .\cstart.asm
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /DDOSPLUS /DWATCOMC /DPASCAL /DFINAL /I.\ /Fo.\bin\csup.obj .\csup.asm
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /DDOSPLUS /DWATCOMC /DPASCAL /DFINAL /I.\ /Fo.\bin\dosif.obj .\dosif.asm
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /DDOSPLUS /DWATCOMC /DPASCAL /DFINAL /I.\ /Fo.\bin\crit.obj .\crit.asm
IF ERRORLEVEL 1 GOTO FAILED

%WC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\com.obj .\com.c
IF ERRORLEVEL 1 GOTO FAILED
%WC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\comint.obj .\comint.c
IF ERRORLEVEL 1 GOTO FAILED
%WC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\support.obj .\support.c
IF ERRORLEVEL 1 GOTO FAILED

%WC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\printf.obj .\printf.c
IF ERRORLEVEL 1 GOTO FAILED
%WC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\batch.obj .\batch.c
IF ERRORLEVEL 1 GOTO FAILED
%WC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\global.obj .\global.c
IF ERRORLEVEL 1 GOTO FAILED
%WC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\config.obj .\config.c
IF ERRORLEVEL 1 GOTO FAILED
%WC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\comcpy.obj .\comcpy.c
IF ERRORLEVEL 1 GOTO FAILED
%WC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\cmdlist.obj .\cmdlist.c
IF ERRORLEVEL 1 GOTO FAILED

ECHO -w -d -f- -K -O -X -Z -c -ms -I%BCC20H% -DMESSAGE -DDOSPLUS -zSCGROUP -zTCODE -zR_MSG > RESP1
ECHO -I.\ >> RESP1
ECHO -o.\bin\cmdlist.obj .\cmdlist.c >> RESP1
%BCC20% @resp1
IF ERRORLEVEL 1 GOTO FAILED

ECHO .\bin\cstart.obj .\bin\com.obj .\bin\csup.obj +> RESP2
ECHO .\bin\dosif.obj .\bin\comint.obj .\bin\support.obj+>> RESP2
ECHO .\bin\cmdlist.obj .\bin\printf.obj+>> RESP2
ECHO .\bin\message.obj +>> RESP2
ECHO .\bin\batch.obj .\bin\global.obj .\bin\config.obj+>> RESP2
ECHO .\bin\comcpy.obj .\bin\crit.obj +>> RESP2
ECHO +>> RESP2
ECHO .\bin\resident.obj>> RESP2
ECHO .\bin\command.exe>> RESP2
ECHO .\command.map>> RESP2
ECHO %WATCOM%\LIB286\DOS\CLIBs>> RESP2
%LINK510% /MAP @resp2;
IF ERRORLEVEL 1 GOTO FAILED

%MASM% /DDOSPLUS /DWATCOMC /DPASCAL /DFINAL /I.\ /Fo.\bin\helpstub.obj .\helpstub.asm
IF ERRORLEVEL 1 GOTO FAILED
ECHO .\bin\helpstub.obj+> RESP3
ECHO .\bin\txhelp.obj>> RESP3
ECHO .\bin\txhelp.exe>> RESP3
%LINK510% @resp3;
IF ERRORLEVEL 1 GOTO FAILED

%LOCTOOLS%\exe2bin /S0000 .\bin\txhelp.exe .\bin\txhelp.bin
IF ERRORLEVEL 1 GOTO FAILED

copy /b .\bin\command.exe+.\bin\txhelp.bin .\bin\command.com
goto exit

:failed
ECHO Error in Build!
goto exit

:badtool
ECHO Can't find that tool!

:exit
REM **********************
REM CLEAN UP THE AREA
REM **********************
rem SET TOOLS=
rem SET MASM=
rem SET WC=
rem SET LINK510=
rem SET BCC20=
rem SET WATCOMH=
rem SET BCC20H=
rem SET LOCTOOLS=

