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

# Allow the user to override defaults
AC_ARG_WITH([javalibdir],
    AS_HELP_STRING([--with-javalibdir=dir],
	           [absolute location of external Java libraries]),
    [javalibdir=$withval],
    [javalibdir=""])

if test x"$javalibdir" = x
then
    JAVALIBDIR=/usr/share/java
else
    JAVALIBDIR=$javalibdir
fi

AC_ARG_WITH([ditadir],
    AS_HELP_STRING([--with-dita18dir=dir],
	           [absolute location of DITA Open Toolkit version 1.8]),
    [DITA18DIR=$withval],
    [DITA18DIR="$abs_top_srcdir/DITA-OT1.8"])

# Set up Java and Ant
ANT_OPTS="-Xmx512m $ANT_OPTS"
ANT_OPTS="$ANT_OPTS -Djava.awt.headless=true"
ANT_OPTS="$ANT_OPTS -Djavax.xml.transform.TransformerFactory=net.sf.saxon.TransformerFactoryImpl"

ANT_HOME="$DITA18DIR"/tools/ant
PATH="$DITA18DIR"/tools/ant/bin:"$PATH"

new_classpath="$DITA18DIR/lib/dost.jar"
new_classpath="$DITA18DIR/lib:$new_classpath"
new_classpath="$DITA18DIR/lib/commons-codec-1.4.jar:$new_classpath"
new_classpath="$DITA18DIR/lib/resolver.jar:$new_classpath"
new_classpath="$DITA18DIR/lib/icu4j.jar:$new_classpath"
new_classpath="$DITA18DIR/lib/xercesImpl.jar:$new_classpath"
new_classpath="$DITA18DIR/lib/xml-apis.jar:$new_classpath"
new_classpath="$DITA18DIR/lib/saxon/saxon9.jar:$new_classpath"
new_classpath="$DITA18DIR/lib/saxon/saxon9-dom.jar:$new_classpath"

new_classpath="$JAVALIBDIR/ant-contrib/ant-contrib.jar":$new_classpath
new_classpath="$JAVALIBDIR/fop.jar":$new_classpath
new_classpath="$JAVALIBDIR/commons-logging.jar":$new_classpath
new_classpath="$JAVALIBDIR/xmlgraphics-commons.jar":$new_classpath
new_classpath="$JAVALIBDIR/xml-commons-apis-ext.jar":$new_classpath
new_classpath="$JAVALIBDIR/commons-io.jar":$new_classpath
new_classpath="$JAVALIBDIR/avalon-framework-api.jar":$new_classpath
new_classpath="$JAVALIBDIR/avalon-framework.jar":$new_classpath
new_classpath="$JAVALIBDIR/batik-all.jar":$new_classpath
new_classpath="$DITA18DIR/plugins/org.dita.pdf2/lib/fo.jar":$new_classpath

if test -n "$CLASSPATH"; then
  CLASSPATH="$new_classpath":"$CLASSPATH"
else
  CLASSPATH="$new_classpath"
fi

AC_SUBST(DITA18DIR)
AC_SUBST(ANT_OPTS)
AC_SUBST(ANT_HOME)
AC_SUBST(PATH)
AC_SUBST(CLASSPATH)

# Set some TexInfo variables.  We'll think about a better way to do this.
GCC_VERSION_DATE="16 Mar 2015, commit ID 9dbe51a"
LLVM_VERSION="3.7"
PKGVERSION="3.7"
BUGURL="www.embecosm.com"
BUGURL_TEXI="@uref{mailto:support@@embecosm.com,support@@embecosm.com}"
AC_SUBST(GCC_VERSION_DATE)
AC_SUBST(LLVM_VERSION)
AC_SUBST(PKGVERSION)
AC_SUBST(BUGURL)
AC_SUBST(BUGURL_TEXI)

# We want to create a Makefile
AC_CONFIG_FILES([Makefile                       \
	         llvm-assembler-manual/Makefile \
	         llvm-user-manual/Makefile])

# Put it all out.
AC_OUTPUT
