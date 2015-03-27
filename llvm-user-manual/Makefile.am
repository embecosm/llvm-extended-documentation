# Makefile.am -- Documentation automake configuration file
#
# Copyright (C) 2009, 2013 Embecosm Limited
#
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
#
# This file is part of the LLVM User Manual based on GCC
#
# This file is distributed under the University of Illinois Open Source
# License. See COPYING for details.

TEXINFO_TEX = ./include/texinfo.tex
AM_MAKEINFOFLAGS = -I . -I $(srcdir) -I $(srcdir)/include

info_TEXINFOS = llvm.texi

# Included files in the texinfo source
llvm_TEXINFOS = include/gcc-common.texi \
                llvm-vers.texi          \
                frontends.texi          \
                standards.texi          \
                invoke.texi             \
                extend.texi             \
                md.texi                 \
                objc.texi               \
                trouble.texi            \
                bugreport.texi          \
                service.texi            \
                contribute.texi         \
                compat.texi             \
                include/funding.texi    \
                gnu.texi                \
                include/gpl_v3.texi     \
                include/fdl.texi        \
                contrib.texi            \
                avr-mmcu.texi           \
                implement-c.texi        \
                implement-cxx.texi

# Images
# EXTRA_DIST = images/

# llvm-vers.texi is generated from constants set when configuring
llvm-vers.texi: $(top_srcdir)/configure
	echo "@set versiondate-GCC $(GCC_VERSION_DATE)" > $@
	echo "@set version-LLVM $(LLVM_VERSION)" >> $@
	echo "@set VERSION_PACKAGE $(PKGVERSION)" >> $@
	echo "@set BUGURL $(BUGURL_TEXI)" >> $@
