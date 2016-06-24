#!/usr/bin/make -f
#
# Makefile for NES game
# Copyright 2011-2015 Damian Yerrick
#
# Copying and distribution of this file, with or without
# modification, are permitted in any medium without royalty
# provided the copyright notice and this notice are preserved.
# This file is offered as-is, without any warranty.
#

# These are used in the title of the NES program and the zip file.
title = snrom-template
titlealt = uorom-template
version = 0.6

# Space-separated list of assembly language files that make up the
# PRG ROM.  If it gets too long for one line, you can add a backslash
# (the \ character) at the end of the line and continue on the next.
objlist = main init bg player pads ppuclear mmc1 chrram bankcalltable
objlistalt = main init bg player pads ppuclear unrom chrram bankcalltable

AS65 = ca65
LD65 = ld65
CFLAGS65 =
objdir = object/nes
srcdir = source
imgdir = tilesets
outdir = target

#EMU := "/C/Program Files/Nintendulator/Nintendulator.exe"
# other options for EMU are start (Windows) or gnome-open (GNOME)
EMU := start

# Occasionally, you need to make "build tools", or programs that run
# on a PC that convert, compress, or otherwise translate PC data
# files into the format that the NES program expects.  Some people
# write their build tools in C or C++; others prefer to write them in
# Perl, PHP, or Python.  This program doesn't use any C build tools,
# but if yours does, it might include definitions of variables that
# Make uses to call a C compiler.
CC = gcc
CFLAGS = -std=gnu99 -Wall -DNDEBUG -O

# Windows needs .exe suffixed to the names of executables; UNIX does
# not.  COMSPEC will be set to the name of the shell on Windows and
# not defined on UNIX.
ifdef COMSPEC
DOTEXE=.exe
else
DOTEXE=
endif

.PHONY: runalt dist zip clean

run: $(outdir)/$(title).nes
	$(EMU) $<

runalt: $(outdir)/$(titlealt).nes
	$(EMU) $<

clean:
	-rm -f $(outdir)/*.nes
	-rm -f $(outdir)/*.txt
	-rm -f $(objdir)/*.o $(objdir)/*.s $(objdir)/*.chr
	-@rmdir --ignore-fail-on-non-empty $(outdir) 2>/dev/null || true
	-@rmdir --ignore-fail-on-non-empty $(objdir) 2>/dev/null || true
	-@rmdir --ignore-fail-on-non-empty object    2>/dev/null || true

# Rules for PRG ROM
objlisto = $(foreach o,$(objlist),$(objdir)/$(o).o)
objlistalto = $(foreach o,$(objlistalt),$(objdir)/$(o).o)

$(outdir)/map.txt $(outdir)/$(title).nes: config/snrom2mbit.cfg $(objlisto)
	-mkdir -p $(outdir)
	$(LD65) -o $(outdir)/$(title).nes -m $(outdir)/map.txt -C $^

$(outdir)/mapalt.txt $(outdir)/$(titlealt).nes: config/uorom2mbit.cfg $(objlistalto)
	-mkdir -p $(outdir)
	$(LD65) -o $(outdir)/$(titlealt).nes -m $(outdir)/mapalt.txt -C $^

$(objdir)/%.o: $(srcdir)/%.s $(srcdir)/nes.inc $(srcdir)/global.inc $(srcdir)/mmc1.inc
	-mkdir -p $(objdir)
	$(AS65) $(CFLAGS65) $< -o $@

$(objdir)/%.o: $(objdir)/%.s
	-mkdir -p $(objdir)
	$(AS65) $(CFLAGS65) $< -o $@

# Files that depend on .incbin'd files
$(objdir)/chrram.o: $(objdir)/bggfx.chr $(objdir)/spritegfx.chr

# This is an example of how to call a lookup table generator at
# build time.  mktables.py itself is not included because the demo
# has no music engine, but it's available online at
# http://wiki.nesdev.com/w/index.php/APU_period_table
$(objdir)/ntscPeriods.s: tools/mktables.py
	$< period $@

# Rules for CHR ROM
$(objdir)/%.chr: $(imgdir)/%.png
	tools/pilbmp2nes.py $< $@

$(objdir)/%16.chr: $(imgdir)/%.png
	tools/pilbmp2nes.py -H 16 $< $@
