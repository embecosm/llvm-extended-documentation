#!/bin/sh
# Check options compile OK for LLVM and GCC

# Copyright (C) 2015 Embecosm Limited

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# This file is part of GDB.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.  */

LCC=clang
GCC=gcc

# Check works with both LLVM and GCC

run_both () {
    lcc_res="ok"
    gcc_res="ok"

    if ! ${LCC} $* > /dev/null 2>&1
    then
	lcc_res="fail";
    fi

    if ! ${GCC} $* > /dev/null 2>&1
    then
	gcc_res="fail";
    fi

    if [ "fail" = ${lcc_res} ]
    then
	if  [ "fail" = ${gcc_res} ]
	then
	    echo "  $*: LLVM & GCC failed"
	else
	    echo "  $*: LLVM failed"
	fi
    elif  [ "fail" = ${gcc_res} ]
    then
	echo "  $*: GCC failed"
    fi
}

# Check works with LLVM

run_llvm () {
    lcc_res="ok"

    if ! ${LCC} $* > /dev/null 2>&1
    then
	lcc_res="fail";
    fi

    if [ "fail" = ${lcc_res} ]
    then
	echo "  $*: LLVM failed"
    fi
}

# Check works with GCC

run_gcc () {
    gcc_res="ok"

    if ! ${GCC} $* > /dev/null 2>&1
    then
	gcc_res="fail";
    fi

    if  [ "fail" = ${gcc_res} ]
    then
	echo "  $*: GCC failed"
    fi
}

# Won't work with either compiler

run_dummy () {
    continue
}

# Pre-compile support files

${LCC} -c stack-protect-assist.c -o stack-protect-assist-llvm.o
${GCC} -c stack-protect-assist.c -o stack-protect-assist-gcc.o

# Options for both compilers

echo "Testing options for both LLVM and GCC..."

run_both -### dummy.c
run_both -c dummy.c
run_both -dD dummy.c
run_both -dM dummy.c
run_both -E dummy.c
run_both -fdata-sections dummy.c
run_both -fdebug-types-section dummy.c
run_both -fdollars-in-identifiers dummy-dollar.c
run_both -fexceptions dummy.c
run_both -ffast-math dummy.c
run_both -ffreestanding dummy.c
run_both -ffunction-sections dummy.c
run_both -fgnu89-inline dummy.c
run_both -fgnu-runtime dummy.c
run_both -finstrument-functions dummy.c profile-assist.c
run_both -fms-extensions dummy.c
run_both -fno-access-control dummy.c
run_both -fno-builtin dummy.c
run_both -fno-common dummy.c
run_both -fno-elide-constructors dummy.c
run_both -fno-operator-names dummy.c
run_both -fno-rtti dummy.c
run_both -fno-show-column dummy.c
run_both -fno-signed-zeros dummy.c
run_both -fno-threadsafe-statics dummy.c
run_both -fobjc-exceptions dummy.c
run_both -fobjc-gc dummy.c
run_both -fshort-enums dummy.c
run_both -fshort-wchar dummy.c
run_both -fstack-protector dummy.c
run_llvm -fstack-protector-all dummy.c stack-protect-assist-llvm.o
run_gcc -fstack-protector-all dummy.c stack-protect-assist-gcc.o
run_both -fstack-protector-strong dummy.c
run_both -fstrict-enums dummy.c
run_both -ftrapv dummy.c
run_both -funroll-loops dummy.c
run_both -fvisibility-inlines-hidden dummy.c
run_both -fvisibility-ms-compat dummy.c
run_both -fwrapv dummy.c
run_both -g dummy.c
run_both -g0 dummy.c
run_both -g1 dummy.c
run_both -g2 dummy.c
run_both -g3 dummy.c
run_both -ggdb dummy.c
run_both -ggdb0 dummy.c
run_both -ggdb1 dummy.c
run_both -ggdb2 dummy.c
run_both -ggdb3 dummy.c
run_both -gdwarf-2 dummy.c
run_both -gdwarf-3 dummy.c
run_both -gdwarf-4 dummy.c
run_both -gstrict-dwarf dummy.c
run_both -H dummy.c
run_both -I . dummy.c
run_both -idirafter . dummy.c
run_both -imacros dummy.h dummy.c
run_both -include dummy.h dummy.c
run_both -iprefix ./ dummy.c
run_both -iquote . dummy.c
run_both -isysroot . dummy.c
run_both -isystem . dummy.c
run_both -iwithprefix ./ dummy.c
run_both -iwithprefixbefore ./ dummy.c
run_both -M dummy.c
run_both -MD dummy.c
run_both -M -MF dummy-deps dummy.c
run_both -MG -M dummy.c
run_both -MM dummy.c
run_both -MMD dummy.c
run_both -M -MP dummy.c
run_both -M -MQ dummy.o dummy.c
run_both -M -MT dummy.o dummy.c
run_both -nostdinc++ dummy.c
run_both -o dummy dummy.c
run_both -P dummy.c
run_both -pg dummy.c
run_both -pipe dummy.c
run_both -print-libgcc-file-name dummy.c
run_both -print-search-dirs dummy.c
run_both -S dummy.c
run_both -save-temps dummy.c
run_both -time dummy.c
run_both -trigraphs dummy.c
run_both -undef dummy.c
run_both -v dummy.c
run_both -w dummy.c
run_both -x c dummy.c
run_both -x c-header dummy.c
run_both -c -x assembler dummy-asm.S
run_both -c -x assembler-with-cpp dummy-asm.S
run_both -x none dummy.c
run_both -Xassembler -compress-debug-sections dummy.c
run_both -Xlinker -M dummy.c
run_both -Xpreprocessor -I. dummy.c
run_both -z defs dummy.c

# Options for both compilers for some targets

run_dummy -fpcc-struct-return dummy.c
run_dummy -freg-struct-return dummy.c

# Options for LLVM but not GCC

echo "Testing options for LLVM but not GCC..."

# Options for GCC but not LLVM

echo "Testing options for GCC but not LLVM..."

run_gcc -gstabs dummy.c
run_gcc -gstabs0 dummy.c
run_gcc -gstabs1 dummy.c
run_gcc -gstabs2 dummy.c
run_gcc -gstabs3 dummy.c
run_gcc -gstabs+ dummy.c
run_gcc -gtoggle dummy.c
run_gcc -I- -I . dummy.c
run_gcc -time=time.dat dummy.c

# Options for the future

run_dummy -x cpp-output dummy-preproc.i
run_dummy -x c++ dummy.c
run_dummy -x c++-header dummy.c
run_dummy -x c++-cpp-output dummy-preproc.i
run_dummy -x objective-c dummy.c
run_dummy -x objective-c-header dummy.c
run_dummy -x objective-c-cpp-output dummy-preproc.i
run_dummy -x objective-c++ dummy.c
run_dummy -x objective-c++-header dummy.c
run_dummy -x objective-c++-cpp-output dummy-preproc.i
run_dummy -x ada dummy.c
run_dummy -x f77 dummy.c
run_dummy -x f77-cpp-input dummy.c
run_dummy -x f95 dummy.c
run_dummy -x f95-cpp-input dummy.c
run_dummy -x go dummy.c
run_dummy -x java dummy.c

# Tidy up
rm a.out
rm dummy
rm time.dat
rm dummy-deps
rm *.o *.bc *.gch *.d
rm dummy.i dummy.s
