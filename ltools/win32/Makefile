# Watcom Makefile for DOS EDR build tools

CL = wcl386

CFLAGS = -q -l=nt -bt=nt

all: compkern.exe compbios.exe compbdos.exe fixupp.exe round.exe

compkern.exe: ../compkern.c ../zerocomp.h Makefile
	$(CL) $(CFLAGS) $[@
	rm -f $^*.obj

compbios.exe: ../compbios.c ../zerocomp.h Makefile
	$(CL) $(CFLAGS) $[@
	rm -f $^*.obj

compbdos.exe: ../compbdos.c ../zerocomp.h Makefile
	$(CL) $(CFLAGS) $[@
	rm -f $^*.obj

fixupp.exe: ../fixupp.c Makefile
	$(CL) $(CFLAGS) $[@
	rm -f $^*.obj

round.exe: ../round.c Makefile
	$(CL) $(CFLAGS) $[@
	rm -f $^*.obj


clean: .SYMBOLIC
	rm -f compkern.exe
	rm -f compbios.exe
	rm -f compbdos.exe
	rm -f fixupp.exe
	rm -f round.exe
	rm -f *.obj
	rm -f *.o
