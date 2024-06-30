# Watcom Makefile for DOS EDR build tools

CL = wcl

CFLAGS = -q -bt=dos -ml -os

all: compbios.exe compbdos.exe fixupp.exe round.exe

compbios.exe: ../compbios.c Makefile
	$(CL) $(CFLAGS) $[@
	rm -f $^*.obj

compbdos.exe: ../compbdos.c Makefile
	$(CL) $(CFLAGS) $[@
	rm -f $^*.obj

fixupp.exe: ../fixupp.c Makefile
	$(CL) $(CFLAGS) $[@
	rm -f $^*.obj

round.exe: ../round.c Makefile
	$(CL) $(CFLAGS) $[@
	rm -f $^*.obj


clean: .SYMBOLIC
	rm -f compbios.exe
	rm -f compbios.obj
	rm -f compbdos.exe
	rm -f compbdos.obj
	rm -f fixupp.exe
	rm -f fixupp.obj
	rm -f round.exe
	rm -f round.obj
