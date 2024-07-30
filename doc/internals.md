# EDR-DOS Kernel Internals


## Config Environment
EDR-DOS spawns the first process with an empty environment. The environment segment in the PSP is set to zero.

However, when processing `config.sys`, the kernel does this under a _config environment_. This config environment is passed to every process spawned while processing `config.sys`. Environment variables may be set via the `SET` command from within `CONFIG.SYS`. The environment is appended `1AH` character, followed by a boot key scan code. This records a F5 or F8 key pressed while booting.

When the root process is launched, despite given an empty environment, it may query the config environment by getting a pointer to the kernel private data and inspecting offset 12h to get the segment of the environment. To query the private data segment, use `INT 21,4458`. On return, `ES:BX` contains a pointer to the private data.

The root process may build a new environment from the config environment by copying data from it. EDR COMMAND.COM copies all environment variables from the config environment to its newly created environment.




## CONFIG.SYS Commands

    COUNTRY=nnn,nnn,country
    SHELL=filename
    LASTDRIVE=d:
    HILASTDRIVE=d:
    BREAK=ON/OFF
    BUFFERS=nn
    HIBUFFERS=nn
    FCBS=nn
    HIFCBS=nn
    FILES=nn
    HIFILES=nn
    STACKS=nn
    HISTACKS=nn
    FASTOPEN=nnn
    DRIVPARM=/d:nn ...
    HISTORY=ON|OFF,NNN
    HIINSTALLLAST=cmdstring
    HIINSTALL=cmdstring
    INSTALLHIGH=cmdstring
    INSTALLLAST=cmdstring
    INSTALL=cmdstring
    HIDOS=ON/OFF
    DOSDATA=UMB
    DDSCS=HIGH,UMB
    XBDA=LOW,UMB
    DOS=HIGH
    SET envar=string
    SWITCHES=...
    HIDEVICE=filename
    DEVICEHIGH=filename
    DEVICE=filename
    REM Comment
    ; Comment
    :label
    CHAIN=filename
    GOTO=label
    GOSUB=label
    RETURN (from GOSUB)
    Clear Screen
    CPOS=row,col            Set Cursor Position
    COLOUR=[fg][,[bg][,bc]] Set Fore-/Background/Border Colour
    TIMEOUT=n               set ? 	TIMEOUT
    SWITCH=n
    ONERROR='n'             optional command
    ?                       optional command
    ECHO=string
    EXIT
    ERROR='n'
    GETKEY
    YESCHAR=
    DEBLOCK=xxxx
    NUMLOCK=ON/OFF
    VERSION=x.xx
