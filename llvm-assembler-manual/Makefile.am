# Makefile.am -- Documentation automake configuration file
#
# Copyright (C) 2009, 2013 Embecosm Limited
#
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
#
# This file is part of the LLVM Assembler Manual based on GAS
#
# This file is distributed under the University of Illinois Open Source
# License. See COPYING for details.

TEXINFO_TEX = $(top_srcdir)/texinfo/texinfo.tex
AM_MAKEINFOFLAGS = -I . -I $(srcdir) -I $(srcdir)/include

info_TEXINFOS = llvm-assembler.texi

# Included files in the texinfo source
llvm_assembler_TEXINFOS = llvm-assembler.texi \
                          llvm-vers.texi         \
                          fdl.texi

# Images
# EXTRA_DIST = images/

# llvm-vers.texi is generated from constants set when configuring
llvm-vers.texi: $(top_srcdir)/configure
	echo "@set versiondate-GCC $(GCC_VERSION_DATE)" > $@
	echo "@set version-LLVM $(LLVM_VERSION)" >> $@
	echo "@set VERSION_PACKAGE $(PKGVERSION)" >> $@
	echo "@set BUGURL $(BUGURL_TEXI)" >> $@
