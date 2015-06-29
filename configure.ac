# Top level autoconf configuration file
#
# Copyright (C) 2009, 2013 Embecosm Limited
#
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
#
# This file is part of the extended LLVM documentation
#
# This file is distributed under the University of Illinois Open Source
# License. See COPYING for details.

# Process this file with autoconf to produce a configure script.

AC_INIT([llvm-documentation], [0.01], [support@embecosm.com])
AC_CONFIG_MACRO_DIR([m4])
# Default tar only allows 21-bit UIDs.
AM_INIT_AUTOMAKE([tar-pax])

AC_COPYRIGHT(Copyright (C) 2015 Embecosm Limited)
AC_REVISION([$Id$ using automake version] AC_ACVERSION)

# Make sure we are using a reasonably recent autoconf version
AC_PREREQ(2.69)

# Set some variables.  We'll think about a better way to do this.
GCC_VERSION_DATE="16 Mar 2015, commit ID 9dbe51a"
LLVM_VERSION="3.5"
PKGVERSION="3.5"
BUGURL_TEXI="www.embecosm.com"
AC_SUBST(GCC_VERSION_DATE)
AC_SUBST(LLVM_VERSION)
AC_SUBST(PKGVERSION)
AC_SUBST(BUGURL_TEXI)

# We want to create a Makefile
AC_CONFIG_FILES([Makefile                       \
	         llvm-assembler-manual/Makefile \
	         llvm-user-manual/Makefile])

# Put it all out.
AC_OUTPUT
