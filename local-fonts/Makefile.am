# Makefile.am -- automake configuration file for local fonts
#
# Copyright (C) 2015 Embecosm Limited
# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
#
# This file is part of the LLVM extended documentation
#
# This file is distributed under the University of Illinois Open Source
# License. See COPYING for details.

all: fop.xconf arial.xml arial-bold.xml arial-italic.xml arial-bold-italic.xml \
     courier.xml courier-bold.xml courier-italic.xml courier-bold-italic.xml

install:

fop.xconf: fop.xconf.in
	sed -e "s|SRC_DIR|$(abs_srcdir)|g" \
	    -e "s|BUILD_DIR|$(abs_builddir)|g" < $< > $@

arial.xml: fonts/arial.ttf
	echo $$CLASSPATH
	java org.apache.fop.fonts.apps.TTFReader -cp $(CLASSPATH) $< $@

arial-bold.xml: fonts/arialbd.ttf
	java org.apache.fop.fonts.apps.TTFReader -cp $(CLASSPATH) $< $@

arial-italic.xml: fonts/ariali.ttf
	java org.apache.fop.fonts.apps.TTFReader -cp $(CLASSPATH) $< $@

arial-bold-italic.xml: fonts/arialbi.ttf
	java org.apache.fop.fonts.apps.TTFReader -cp $(CLASSPATH) $< $@

courier.xml: fonts/cour.ttf
	java org.apache.fop.fonts.apps.TTFReader -cp $(CLASSPATH) $< $@

courier-bold.xml: fonts/courbd.ttf
	java org.apache.fop.fonts.apps.TTFReader -cp $(CLASSPATH) $< $@

courier-italic.xml: fonts/couri.ttf
	java org.apache.fop.fonts.apps.TTFReader -cp $(CLASSPATH) $< $@

courier-bold-italic.xml: fonts/courbi.ttf
	java org.apache.fop.fonts.apps.TTFReader -cp $(CLASSPATH) $< $@

mostlyclean:
	rm -f *.xml fop.xconf

# Other targets we must provide for automake, but which do nothing.

dvi:
html:
info:
pdf:
ps:

install-data:
install-exec:

uninstall:

install-dvi:
install-html:
install-info:
install-pdf:
install-ps:

installdirs:

check:
installcheck:

clean:
distclean:
maintainer-clean:

dvi:
ps:
info:

tags:
ctags:
