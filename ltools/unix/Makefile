# UNIX Makefile for EDR build tools

CFLAGS=-Wall -pedantic

all: compkern compbios compbdos fixupp

.PHONY: all clean

compkern: ../compkern.c ../zerocomp.h Makefile
	$(CC) $(CFLAGS) $< -o $@

compbios: ../compbios.c ../zerocomp.h Makefile
	$(CC) $(CFLAGS) $< -o $@

compbdos: ../compbdos.c ../zerocomp.h Makefile
	$(CC) $(CFLAGS) $< -o $@

fixupp: ../fixupp.c Makefile
	$(CC) $(CFLAGS) $< -o $@


clean:
	rm -f compkern
	rm -f compbios
	rm -f compbdos
	rm -f fixupp
