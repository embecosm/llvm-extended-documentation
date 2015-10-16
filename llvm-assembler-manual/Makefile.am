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

# Eclipse help via Docbook
ECLIPSE_DIR = llvm-assember-eclipse
DOCBOOKS = llvm-assembler.docbook
MAKEINFODOCBOOK = $(MAKEINFO) --docbook
AM_MAKEINFODOCBOOKFLAGS = $(AM_MAKEINFOFLAGS)
ECLIPSE_STYLE ?= http://docbook.sourceforge.net/release/xsl/current/eclipse/eclipse.xsl

ECLIPSE_NAME     = "LLVM Assembler User Manual"
ECLIPSE_ID       = "org.fsf.help.llvm-assembler"
ECLIPSE_PROVIDER = "Free Software Foundation"

info_TEXINFOS = llvm-assembler.texi

# Included files in the texinfo source
llvm_assembler_TEXINFOS = c-aap.texi          \
                          llvm-assembler.texi \
                          llvm-vers.texi      \
                          fdl.texi

# Images
# EXTRA_DIST = images/

# llvm-vers.texi is generated from constants set when configuring
llvm-vers.texi: $(top_srcdir)/configure
	echo "@set versiondate-GCC $(GCC_VERSION_DATE)" > $@
	echo "@set version-LLVM $(LLVM_VERSION)" >> $@
	echo "@set VERSION_PACKAGE $(PKGVERSION)" >> $@
	echo "@set BUGURL $(BUGURL_TEXI)" >> $@

docbook: docbook-am

docbook-am: $(DOCBOOKS)

$(DOCBOOKS): $(info_TEXINFOS) $(llvm_assembler_TEXINFOS)
	$(AM_V_MAKEINFO)rm -rf $(@:.docbook=.dtp)
	$(AM_V_at)if $(MAKEINFODOCBOOK) $(AM_MAKEINFODOCBOOKFLAGS) $(MAKEINFOFLAGS) -I $(srcdir) \
	 -o $(@:.docbook=.dtp) $<; \
	then \
	  rm -rf $@ && mv $(@:.docbook=.dtp) $@; \
	else \
	  rm -rf $(@:.docbook=.dtp); exit 1; \
	fi

eclipse: eclipse-am

eclipse-am: $(ECLIPSE_DIR) $(ECLIPSE_DIR)/index.html

$(ECLIPSE_DIR):
	mkdir -p $(ECLIPSE_DIR)

$(ECLIPSE_DIR)/index.html: $(DOCBOOKS)
	xsltproc --stringparam base.dir                "$(ECLIPSE_DIR)/"     \
		 --stringparam eclipse.plugin.name     "$(ECLIPSE_NAME)"     \
		 --stringparam eclipse.plugin.id       "$(ECLIPSE_ID)"       \
		 --stringparam eclipse.plugin.provider "$(ECLIPSE_PROVIDER)" \
		 $(ECLIPSE_STYLE) $(DOCBOOKS)
