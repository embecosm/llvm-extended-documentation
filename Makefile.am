# Makefile.am -- Top level automake configuration file
#
# Copyright (C) 2015 Embecosm Limited
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
#
# This file is part of the LLVM extended documentation
#
# This file is distributed under the University of Illinois Open Source
# License. See COPYING for details.

# Local macros
ACLOCAL_AMFLAGS = -I m4

# Common flags for all programs
SUBDIRS = llvm-assembler-manual llvm-user-manual

# Targets to generate docbook and html

am__extra_recursive_targets = install-docbook-recursive docbook-recursive \
                             install-eclipse-recursive eclipse-recursive

install-docbook: install-docbook-recursive

install-eclipse: install-eclipse-recursive

docbook: docbook-recursive

eclipse: eclipse-recursive
