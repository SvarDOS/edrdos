# UNIX Makefile for EDR build tools

CFLAGS=-Wall -pedantic

all: compbios compbdos

compbios: ../compbios.c Makefile
	$(CC) $(CFLAGS) $< -o $@

compbdos: ../compbdos.c Makefile
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f compbios
	rm -f compbdos
