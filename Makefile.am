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

# Set up Java and Ant
if HAVE_JAVALIBDIR
  JAVALIBDIR ::= $(JAVALIBDIR_ARG)
else
  JAVALIBDIR ::= /usr/share/java
endif

if HAVE_DITA18DIR
  export DITA18DIR ::= $(DITA18DIR_ARG)
else
  export DITA18DIR ::= $(abs_top_srcdir)/DITA-OT1.8
endif

if HAVE_FOPCONF
  export FOPCONF ::= $(FOPCONF_ARG)
else
  export FOPCONF ::= $(abs_top_srcdir)/local-fonts/fop.xconf
endif

ANT_OPTS ::= -Xmx512m $(ANT_OPTS)
ANT_OPTS ::= $(ANT_OPTS) -Djava.awt.headless=true
ANT_OPTS ::= $(ANT_OPTS) -Djavax.xml.transform.TransformerFactory=net.sf.saxon.TransformerFactoryImpl
export ANT_OPTS

export ANT_HOME ::= $(DITA18DIR)/tools/ant
export ANT_BIN  ::= $(DITA18DIR)/tools/ant/bin

new_classpath ::= "$(DITA18DIR)/lib/dost.jar"
new_classpath ::= "$(DITA18DIR)/lib:$(new_classpath)"
new_classpath ::= "$(DITA18DIR)/lib/commons-codec-1.4.jar:$(new_classpath)"
new_classpath ::= "$(DITA18DIR)/lib/resolver.jar:$(new_classpath)"
new_classpath ::= "$(DITA18DIR)/lib/icu4j.jar:$(new_classpath)"
new_classpath ::= "$(DITA18DIR)/lib/xercesImpl.jar:$(new_classpath)"
new_classpath ::= "$(DITA18DIR)/lib/xml-apis.jar:$(new_classpath)"
new_classpath ::= "$(DITA18DIR)/lib/saxon/saxon9.jar:$(new_classpath)"
new_classpath ::= "$(DITA18DIR)/lib/saxon/saxon9-dom.jar:$(new_classpath)"

new_classpath ::= "$(JAVALIBDIR)/ant-contrib/ant-contrib.jar":$(new_classpath)
new_classpath ::= "$(JAVALIBDIR)/fop.jar":$(new_classpath)
new_classpath ::= "$(JAVALIBDIR)/commons-logging.jar":$(new_classpath)
new_classpath ::= "$(JAVALIBDIR)/xmlgraphics-commons.jar":$(new_classpath)
new_classpath ::= "$(JAVALIBDIR)/xml-commons-apis-ext.jar":$(new_classpath)
new_classpath ::= "$(JAVALIBDIR)/commons-io.jar":$(new_classpath)
new_classpath ::= "$(JAVALIBDIR)/avalon-framework-api.jar":$(new_classpath)
new_classpath ::= "$(JAVALIBDIR)/avalon-framework.jar":$(new_classpath)
new_classpath ::= "$(JAVALIBDIR)/batik-all.jar":$(new_classpath)

new_classpath ::= "$(DITA18DIR)/plugins/org.dita.pdf2/lib/fo.jar":$(new_classpath)

if HAVE_CLASSPATH
  export CLASSPATH ::= "$(new_classpath)":"$CLASSPATH"
else
  export CLASSPATH ::= "$(new_classpath)"
endif

# Targets to generate docbook and html

am__extra_recursive_targets = install-docbook-recursive docbook-recursive \
                             install-eclipse-recursive eclipse-recursive

install-docbook: install-docbook-recursive

install-eclipse: install-eclipse-recursive

docbook: docbook-recursive

eclipse: eclipse-recursive
