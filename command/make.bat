@ECHO off
SET TOOLS=C:\TOOLS

SET MASM=%TOOLS%\MASM.EXE
SET WATCOM=%TOOLS%\WATCOMC
SET WATCOMH=%TOOLS%\WATCOMC\H
SET WCG=%WATCOM%\BIN\WCGL.EXE
SET WCC=%WATCOM%\BIN\WCC.EXE
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
ECHO Checking for %WCC%
if not exist %WCC% goto badtool
ECHO Checking for %LINK510%
if not exist %LINK510% goto badtool
ECHO Checking for %BCC20%
if not exist %BCC20% goto badtool


%MASM% message,.\bin\message;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% resident,.\bin\resident;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% txhelp,.\bin\txhelp;
IF ERRORLEVEL 1 GOTO FAILED

%MASM% /DDOSPLUS /DWATCOMC /DPASCAL /DFINAL /MX /I.\ .\cstart.asm,.\bin\cstart.obj;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /DDOSPLUS /DWATCOMC /DPASCAL /DFINAL /MX /I.\ .\csup.asm,.\bin\csup.obj;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /DDOSPLUS /DWATCOMC /DPASCAL /DFINAL /MX /I.\ .\dosif.asm,.\bin\dosif.obj;
IF ERRORLEVEL 1 GOTO FAILED
%MASM% /DDOSPLUS /DWATCOMC /DPASCAL /DFINAL /MX /I.\ .\crit.asm,.\bin\crit.obj;
IF ERRORLEVEL 1 GOTO FAILED

%WCC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\com.obj .\com.c
IF ERRORLEVEL 1 GOTO FAILED
%WCC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\comint.obj .\comint.c
IF ERRORLEVEL 1 GOTO FAILED
%WCC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\support.obj .\support.c
IF ERRORLEVEL 1 GOTO FAILED

%WCC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\printf.obj .\printf.c
IF ERRORLEVEL 1 GOTO FAILED
%WCC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\batch.obj .\batch.c
IF ERRORLEVEL 1 GOTO FAILED
%WCC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\global.obj .\global.c
IF ERRORLEVEL 1 GOTO FAILED
%WCC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\config.obj .\config.c
IF ERRORLEVEL 1 GOTO FAILED
%WCC% /s /DFINAL /i=. /ms /os /dWATCOMC /i=%WATCOMH% /fo.\bin\comcpy.obj .\comcpy.c
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
ECHO %WATCOM%\LIB\CLIBs>> RESP2
%LINK510% /MAP @resp2;
IF ERRORLEVEL 1 GOTO FAILED

%MASM% /DDOSPLUS /DWATCOMC /DPASCAL /DFINAL /MX /I.\ .\helpstub.asm,.\bin\helpstub.obj;
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
SET TOOLS=
SET MASM=
SET WCC=
SET LINK510=
SET BCC20=
SET WATCOMH=
SET BCC20H=
SET LOCTOOLS=

