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

# Usage:

#     ./opt-check.sh <logfile>

LCC=clang
GCC=gcc
tmpf=/tmp/opt-check-$$

ALLOPTS="address-asmname-slim-raw-details-stats-blocks-graph-vops-lineno-uid-verbose-eh-scev-optimized-missed-note"

# Tidy up
tidyup () {
    echo
    logcon "Cleaning up..."
    rm -f a.out
    rm -f dummy
    rm -f proto.dat time.dat
    rm -f dummy-deps dummy.gkd
    rm -f *.o* *.bc *.gch *.d *.i *.dwo
    rm -f dummy.bc dummy.c.* dummy.d dummy.g* dummy.i dummy.s dummy.su
    rm -f *.a *.so
    rm -f ${tmpf}
}

# Write to the log and console
logcon () {
    echo $* >> ${logfile} 2>&1
    echo $*
}

# Write to a log file

logit () {
    echo $* >> ${logfile} 2>&1
}

# Log an error
logerr () {
    echo $* >> ${logfile} 2>&1
    echo -n "!"
}

# Log success
logok () {
    echo -n "."
}

# Check works with both LLVM and GCC

run_both () {
    lcc_res="ok"
    gcc_res="ok"

    if ! ${LCC} $* > ${tmpf} 2>&1
    then
	lcc_res="fail";
    elif grep -q "argument unused during compilation" ${tmpf}
    then
	lcc_res="fail";
    elif grep -q "optimization flag .* is not supported" ${tmpf}
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
	    logerr "  $*: LLVM & GCC failed"
	else
	    logerr "  $*: LLVM failed"
	fi
    elif  [ "fail" = ${gcc_res} ]
    then
	logerr "  $*: GCC failed"
    else
	logok
    fi
}

# Check works with LLVM and not with GCC

run_llvm () {
    lcc_res="ok"
    gcc_res="ok"

    if ! ${LCC} $* > ${tmpf} 2>&1
    then
	lcc_res="fail";
    elif grep -q "argument unused during compilation" ${tmpf}
    then
	lcc_res="fail";
    elif grep -q "optimization flag .* is not supported" ${tmpf}
    then
	lcc_res="fail";
    fi

    if ! ${GCC} $* > /dev/null 2>&1
    then
	gcc_res="fail";
    fi

    if [ "ok" = ${gcc_res} ]
    then
	if  [ "fail" = ${lcc_res} ]
	then
	    logerr "  $*: LLVM failed & GCC OK"
	else
	    logerr "  $*: GCC OK"
	fi
    elif  [ "fail" = ${lcc_res} ]
    then
	logerr "  $*: LLVM failed"
    else
	logok
    fi
}

# Check works with only LLVM

run_only_llvm () {
    lcc_res="ok"

    if ! ${LCC} $* > ${tmpf} 2>&1
    then
	lcc_res="fail";
    elif grep -q "argument unused during compilation" ${tmpf}
    then
	lcc_res="fail";
    elif grep -q "optimization flag .* is not supported" ${tmpf}
    then
	lcc_res="fail";
    fi

    if [ "fail" = ${lcc_res} ]
    then
	logerr "  $*: LLVM failed"
    else
	logok
    fi
}

# Check works with GCC and not with LLVM

run_gcc () {
    lcc_res="ok"
    gcc_res="ok"

    if ! ${LCC} $* > ${tmpf} 2>&1
    then
	lcc_res="fail";
    elif grep -q "argument unused during compilation" ${tmpf}
    then
	lcc_res="fail";
    elif grep -q "optimization flag .* is not supported" ${tmpf}
    then
	lcc_res="fail";
    fi

    if ! ${GCC} $* > /dev/null 2>&1
    then
	gcc_res="fail";
    fi

    if [ "ok" = ${lcc_res} ]
    then
	if  [ "fail" = ${gcc_res} ]
	then
	    logerr "  $*: LLVM OK & GCC failed"
	else
	    logerr "  $*: LLVM OK"
	fi
    elif  [ "fail" = ${gcc_res} ]
    then
	logerr "  $*: GCC failed"
    else
	logok
    fi
}

# Check works with only GCC

run_only_gcc () {
    gcc_res="ok"

    if ! ${GCC} $* > /dev/null 2>&1
    then
	gcc_res="fail";
    fi

    if [ "fail" = ${gcc_res} ]
    then
	logerr "  $*: GCC failed"
    else
	logok
    fi
}

# Check explicitly works with neither LLVM nor GCC

run_neither () {
    lcc_res="ok"
    gcc_res="ok"

    if ! ${LCC} $* > ${tmpf} 2>&1
    then
	lcc_res="fail";
    elif grep -q "argument unused during compilation" ${tmpf}
    then
	lcc_res="fail";
    elif grep -q "optimization flag .* is not supported" ${tmpf}
    then
	lcc_res="fail";
    fi

    if ! ${GCC} $* > /dev/null 2>&1
    then
	gcc_res="fail";
    fi

    if [ "ok" = ${lcc_res} ]
    then
	if  [ "ok" = ${gcc_res} ]
	then
	    logerr "  $*: LLVM & GCC OK"
	else
	    logerr "  $*: LLVM OK"
	fi
    elif  [ "ok" = ${gcc_res} ]
    then
	logerr "  $*: GCC OK"
    else
	logok
    fi
}

# Do nothing

run_neither () {
    continue
}

# Get the argument
if [ $# = 1 ]
then
    logfile=$1
else
    echo "ERROR: No logfile provided"
    exit 1
fi

rm -f ${logfile}
touch ${logfile}

if [ ! -w ${logfile} ]
then
    echo "ERROR: Cannot write to log file ${logfile}"
    exit 1
fi

# Pre-compile support files

logcon "Precompiling support files..."
${LCC} -c stack-protect-assist.c -o stack-protect-assist-llvm.o \
    >> ${logfile} 2>&1
${GCC} -c stack-protect-assist.c -o stack-protect-assist-gcc.o \
    >> ${logfile} 2>&1
${GCC} -fPIC -c myplugin.c
${GCC} -shared -o myplugin.so myplugin.o >> ${logfile} 2>&1
${GCC} -E dummy.c -o dummy-preproc.i
${GCC} -c libcode.c
ar rcs libcode.a libcode.o

# Options for both compilers

logcon "Testing options for both LLVM and GCC..."

run_both -### dummy.c
run_both -c dummy.c
run_both -E -dD dummy.c
run_both -E -dM dummy.c
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
run_both -fobjc-gc dummy.c
run_both -fshort-enums dummy.c
run_both -fshort-wchar dummy.c
run_both -fstack-protector dummy.c
run_only_llvm -fstack-protector-all dummy.c stack-protect-assist-llvm.o
run_only_gcc -fstack-protector-all dummy.c stack-protect-assist-gcc.o
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

# Options for both compilers not reported by llvm --help. I really don't
# believe some of these actually do anything!

run_both -ansi dummy.c
run_both -C -E dummy.c
run_both -DCARMICHAEL_PSEUDO_PRIME dummy.c
run_both -DFIRST_CARMICHAEL_PSEUDO_PRIME=561 dummy.c
run_both -dumpmachine dummy.c
run_both -dumpversion dummy.c
run_both -fassociative-math dummy.c
run_both -fasynchronous-unwind-tables dummy.c
run_both -fconstexpr-depth=1024 dummy.c
run_both -fdebug-prefix-map=`pwd`=`pwd`/.. dummy.c
run_both -fdiagnostics-color dummy.c
run_both -fdiagnostics-color=never dummy.c
run_both -fdiagnostics-show-location=every-line dummy.c
run_both -fdiagnostics-show-location=once dummy.c
run_both -feliminate-unused-debug-types dummy.c
run_both -fexec-charset=UTF-8 dummy.c
run_both -fextended-identifiers dummy.c
run_both -ffinite-math-only dummy.c
run_both -ffp-contract=off dummy.c
run_both -fhosted dummy.c
run_both -finput-charset=UTF-8 dummy.c
run_both -flax-vector-conversions dummy.c
run_both -fmerge-all-constants dummy.c
run_both -fmessage-length=40 dummy.c
run_both -fno-asm dummy-asm.c
run_both -fno-common dummy.c
run_both -fno-debug-types-section dummy.c
run_both -fno-diagnostics-show-option dummy.c
run_both -fno-dwarf2-cfi-asm dummy.c
run_both -fno-eliminate-unused-debug-types dummy.c
run_both -fno-gnu-keywords dummy.c
run_both -fno-ident dummy.c
run_both -fno-implement-inlines dummy.c
run_both -fno-implicit-templates dummy.c
run_both -fno-inline dummy.c
run_both -fno-math-errno dummy.c
run_both -fnon-call-exceptions dummy.c
run_both -fno-sanitize=all dummy.c
run_both -fno-signed-zeros dummy.c
run_both -fno-threadsafe-statics dummy.c
run_both -fno-trapping-math dummy.c
run_both -fno-zero-initialized-in-bss dummy.c
run_both -fomit-frame-pointer dummy.c
run_both -fopenmp dummy.c
run_both -foptimize-sibling-calls dummy.c
run_both -fpack-struct dummy.c
run_both -fpack-struct=4 dummy.c
run_both -fpch-preprocess dummy.c
run_both -fpermissive dummy.c
run_both -fpic dummy.c
run_both -fPIC dummy.c
run_both -fpie dummy.c
run_both -fPIE dummy.c
run_both -fplugin=myplugin.so dummy.c
run_both -frandom-seed=561 dummy.c
run_both -freciprocal-math dummy.c
run_both -fsanitize=kernel-address dummy.c
run_both -fsanitize-recover dummy.c
run_both -fsanitize-undefined-trap-on-error dummy.c
run_both -fsigned-bitfields dummy.c
run_both -fsigned-char dummy.c
run_both -fsplit-stack dummy.c
run_both -fstack-check dummy.c
run_both -fstrict-aliasing dummy.c
run_both -fstrict-overflow dummy.c
run_both -fsyntax-only dummy.c
run_both -ftabstop=2 dummy.c
run_both -ftest-coverage dummy.c
run_both -ftime-report dummy.c
run_both -ftls-model=local-dynamic dummy.c
run_both -ftrapv dummy.c
run_both -ftree-slp-vectorize dummy.c
run_both -ftree-vectorize dummy.c
run_both -funit-at-a-time dummy.c
run_both -funsafe-math-optimizations dummy.c
run_both -funsigned-char dummy.c
run_both -funwind-tables dummy.c
run_both -fuse-cxa-atexit dummy.c
run_both -fuse-ld=bfd dummy.c
run_both -fuse-ld=gold dummy.c
run_both -fverbose-asm dummy.c
run_both -fvisibility=default dummy.c
run_both -fvisibility=internal dummy.c
run_both -fvisibility=hidden dummy.c
run_both -fvisibility=protected dummy.c
run_both -fvisibility-inlines-hidden dummy.c
run_both -fvisibility-ms-compat dummy.c
run_both -grecord-gcc-switches dummy.c
run_both -gsplit-dwarf dummy.c
run_both --help dummy.c
run_both -lcode -L`pwd` dummy.c
run_both -l code -L`pwd` dummy.c
run_both -L`pwd` -lcode dummy.c
run_both -nodefaultlibs -c dummy.c
run_both -no-integrated-cpp dummy.c
run_both -nostartfiles dummy.c
run_both -nostdinc dummy.c
run_both -nostdlib dummy.c
run_both -O dummy.c
run_both -O0 dummy.c
run_both -O1 dummy.c
run_both -O2 dummy.c
run_both -O3 dummy.c
run_both -Ofast dummy.c
run_both -Os dummy.c
run_both --param ssp-buffer-size=4 dummy.c
run_both -pedantic dummy.c
run_both -pedantic-errors dummy.c
run_both -print-file-name=code -L`pwd` dummy.c
run_both -print-multi-directory dummy.c
run_both -print-multi-lib dummy.c
run_both -print-prog-name=cpp dummy.c
run_both -pthread dummy.c
run_both -rdynamic dummy.c

# Options for both compilers for some targets

run_neither -fpcc-struct-return dummy.c
run_neither -freg-struct-return dummy.c

# Options for LLVM but not GCC

echo
logcon "Testing options for LLVM but not GCC..."
run_llvm -Oz dummy.c

# Options for GCC but not LLVM

echo
logcon "Testing options for GCC but not LLVM..."

run_gcc -A myassert=myval dummy-assert.c
run_gcc -aux-info proto.dat dummy.c
run_gcc -B`pwd` -E dummy-error.c
run_gcc -da dummy.c
run_gcc -dA dummy.c
run_gcc -dH dummy.c
run_gcc -dp dummy.c
run_gcc -dP dummy.c
run_gcc -c -dx dummy.c
run_gcc -dI dummy.c
run_gcc -dN dummy.c
run_gcc -dU dummy.c
run_gcc -dumpspecs dummy.c
run_gcc -faggressive-loop-optimizations dummy.c
run_gcc -falign-functions dummy.c
run_gcc -falign-functions=32 dummy.c
run_gcc -falign-jumps dummy.c
run_gcc -falign-jumps=32 dummy.c
run_gcc -falign-labels dummy.c
run_gcc -falign-labels=32 dummy.c
run_gcc -falign-loops dummy.c
run_gcc -falign-loops=32 dummy.c
run_gcc -fasan-shadow-offset=32 -fsanitize=kernel-address dummy.c
run_gcc -fauto-inc-dec dummy.c
run_gcc -fbounds-check dummy.c
run_gcc -fbranch-probabilities dummy.c
run_gcc -fbranch-target-load-optimize dummy.c
run_gcc -fbranch-target-load-optimize2 dummy.c
run_gcc -fbtr-bb-exclusive dummy.c
run_gcc -fcaller-saves dummy.c
run_gcc -fcall-saved-r1 dummy.c
run_gcc -fcall-used-r1 dummy.c
run_gcc -fcheck-data-deps dummy.c
run_gcc -fcombine-stack-adjustments dummy.c
run_gcc -fcompare-debug dummy.c
run_gcc -fcompare-debug-second dummy.c
run_gcc -fcompare-elim dummy.c
run_gcc -fcond-mismatch dummy.c
run_gcc -fconserve-stack dummy.c
run_gcc -fcprop-registers dummy.c
run_gcc -fcrossjumping dummy.c
run_gcc -fcse-follow-jumps dummy.c
run_gcc -fcse-skip-blocks dummy.c
run_gcc -fcx-fortran-rules dummy.c
run_gcc -fcx-limited-range dummy.c
run_gcc -fdbg-cnt=dce:10,tail_call:0 dummy.c
run_gcc -fdbg-cnt-list dummy.c
run_gcc -fdce dummy.c
run_gcc -fdebug-cpp -E dummy.c
run_gcc -fdelayed-branch dummy.c
run_gcc -fdelete-dead-exceptions dummy.c
run_gcc -fdelete-null-pointer-checks dummy.c
run_gcc -fdirectives-only dummy.c
run_gcc -fdisable-ipa-inline dummy.c
run_gcc -fdisable-rtl-gcse2=foo,foo2 dummy.c
run_gcc -fdisable-tree-cunroll=1 dummy.c
run_gcc -fdse dummy.c
run_gcc -fdump-final-insns=dummy.gkd dummy.c
run_gcc -fdump-ipa-all dummy.c
run_gcc -fdump-ipa-cgraph dummy.c
run_gcc -fdump-ipa-inline dummy.c
run_gcc -fdump-noaddr dummy.c
run_gcc -fdump-passes dummy.c
run_gcc -fdump-statistics dummy.c
run_gcc -fdump-statistics-stats dummy.c
run_gcc -fdump-statistics-details dummy.c
run_gcc -fdump-tree-alias dummy.c
run_gcc -fdump-tree-alias-${ALLOPTS} dummy.c
run_gcc -fdump-tree-alias-${ALLOPTS}=debug.dump dummy.c
run_gcc -fdump-tree-alias-all dummy.c
run_gcc -fdump-tree-alias-optall dummy.c
run_gcc -fdump-tree-all dummy.c
run_gcc -fdump-tree-ccp dummy.c
run_gcc -fdump-tree-cfg dummy.c
run_gcc -fdump-tree-ch dummy.c
run_gcc -fdump-tree-copyrename dummy.c
run_gcc -fdump-tree-dce dummy.c
run_gcc -fdump-tree-dom dummy.c
run_gcc -fdump-tree-dse dummy.c
run_gcc -fdump-tree-forwprop dummy.c
run_gcc -fdump-tree-fre dummy.c
run_gcc -fdump-tree-gimple dummy.c
run_gcc -fdump-tree-nrv dummy.c
run_gcc -fdump-tree-optimized dummy.c
run_gcc -fdump-tree-original dummy.c
run_gcc -fdump-tree-phiopt dummy.c
run_gcc -fdump-tree-phiprop dummy.c
run_gcc -fdump-tree-pre dummy.c
run_gcc -fdump-tree-sink dummy.c
run_gcc -fdump-tree-sra dummy.c
run_gcc -fdump-tree-ssa dummy.c
run_gcc -fdump-tree-vect dummy.c
run_gcc -fdump-tree-vrp dummy.c
run_gcc -fdump-tree-vtable-verify dummy.c
run_gcc -fdump-unnumbered dummy.c
run_gcc -fdump-unnumbered-links dummy.c
run_gcc -fearly-inlining dummy.c
run_gcc -feliminate-dwarf2-dups dummy.c
run_gcc -feliminate-unused-debug-symbols dummy.c
run_gcc -femit-struct-debug-baseonly dummy.c
run_gcc -femit-struct-debug-detailed=dir:any dummy.c
run_gcc -femit-struct-debug-reduced dummy.c
run_gcc -fenable-ipa-inline dummy.c
run_gcc -fenable-rtl-gcse2=foo,foo2 dummy.c
run_gcc -fenable-tree-cunroll=1 dummy.c
run_gcc -fexcess-precision=standard dummy.c
run_gcc -fexpensive-optimizations dummy.c
run_gcc -ffat-lto-objects dummy.c
run_gcc -ffixed-rax dummy.c
run_gcc -ffloat-store dummy.c
run_gcc -fforward-propagate dummy.c
run_gcc -fgcse dummy.c
run_gcc -fgcse-after-reload dummy.c
run_gcc -fgcse-las dummy.c
run_gcc -fgcse-lm dummy.c
run_gcc -fgcse-sm dummy.c
run_gcc -fgraphite-identity dummy.c
run_gcc -fhoist-adjacent-loads dummy.c
run_gcc -fif-conversion dummy.c
run_gcc -fif-conversion2 dummy.c
run_gcc -findirect-inlining dummy.c
run_gcc -finhibit-size-directive dummy.c
run_gcc -finline-functions dummy.c
run_gcc -finline-functions-called-once dummy.c
run_gcc -finline-limit=10 dummy.c
run_gcc -finline-small-functions dummy.c
run_gcc -finstrument-functions-exclude-file-list=dummy.c dummy.c
run_gcc -finstrument-functions-exclude-function-list=main dummy.c
run_gcc -fipa-cp dummy.c
run_gcc -fipa-cp-alignment -fipa-cp dummy.c
run_gcc -fipa-cp-clone dummy.c
run_gcc -fipa-icf dummy.c
run_gcc -fipa-profile dummy.c
run_gcc -fipa-pta dummy.c
run_gcc -fipa-pure-const dummy.c
run_gcc -fipa-ra dummy.c
run_gcc -fipa-reference dummy.c
run_gcc -fipa-sra dummy.c
run_gcc -fira-algorithm=priority dummy.c
run_gcc -fira-hoist-pressure dummy.c
run_gcc -fira-loop-pressure dummy.c
run_gcc -fira-region=one dummy.c
run_gcc -fira-verbose=15 dummy.c
run_gcc -fisolate-erroneous-paths-attribute dummy.c
run_gcc -fisolate-erroneous-paths-dereference dummy.c
run_gcc -fivopts dummy.c
run_gcc -fkeep-inline-functions dummy.c
run_gcc -fkeep-static-consts dummy.c
run_gcc -fleading-underscore -c dummy.c
run_gcc -flive-range-shrinkage dummy.c
run_gcc -floop-block dummy.c
run_gcc -floop-interchange dummy.c
run_gcc -floop-nest-optimize dummy.c
run_gcc -floop-parallelize-all dummy.c
run_gcc -floop-strip-mine dummy.c
run_gcc -floop-unroll-and-jam dummy.c
run_gcc -flra-remat dummy.c
run_gcc -flto dummy.c
run_gcc -flto-compression-level=5 dummy.c
run_gcc -flto-partition=1to1 dummy.c
run_gcc -flto-report dummy.c
run_gcc -flto-report-wpa dummy.c
run_gcc -fmax-errors=3 dummy.c
run_gcc -fmem-report dummy.c
run_gcc -fmem-report-wpa dummy.c
run_gcc -fmerge-constants dummy.c
run_gcc -fmodulo-sched dummy.c
run_gcc -fmodulo-sched-allow-regmoves dummy.c
run_gcc -fmove-loop-invariants dummy.c
run_gcc -fno-branch-count-reg dummy.c
run_gcc -fno-canonical-system-headers dummy.c
run_gcc -fno-defer-pop dummy.c
run_gcc -fno-diagnostics-show-caret dummy.c
run_gcc -fno-for-scope dummy.c
run_gcc -fno-function-cse dummy.c
run_gcc -fno-gnu-unique dummy.c
run_gcc -fno-guess-branch-probability dummy.c
run_gcc -fno-ira-share-save-slots dummy.c
run_gcc -fno-ira-share-spill-slots dummy.c
run_gcc -fno-jump-tables dummy.c
run_gcc -fno-merge-debug-strings dummy.c
run_gcc -fno-nonansi-builtins dummy.c
run_gcc -fno-optional-diags dummy.c
run_gcc -fno-peephole dummy.c
run_gcc -fno-peephole2 dummy.c
run_gcc -fno-pretty-templates dummy.c
run_gcc -fno-sched-interblock dummy.c
run_gcc -fno-sched-spec dummy.c
run_gcc -fno-signed-bitfields dummy.c
run_gcc -fno-stack-limit dummy.c
run_gcc -fno-toplevel-reorder dummy.c
run_gcc -fno-unsigned-bitfields dummy.c
run_gcc -fno-use-cxa-get-exception-ptr dummy.c
run_gcc -fno-var-tracking-assignments dummy.c
run_gcc -fno-var-tracking-assignments-toggle dummy.c
run_gcc -fno-weak dummy.c
run_gcc -fno-working-directory dummy.c
run_gcc -fnothrow-opt dummy.c
run_gcc -fopenacc dummy.c
run_gcc -fopenmp-simd dummy.c
run_gcc -foptimize-strlen dummy.c
run_gcc -fopt-info dummy.c
run_gcc -fpartial-inlining dummy.c
run_gcc -fpcc-struct-return dummy.c
run_gcc -fpch-deps dummy.c
run_gcc -fpeel-loops dummy.c
run_gcc -fplan9-extensions dummy.c
run_gcc -fplugin=myplugin.so -fplugin-arg-myplugin-mykey=myvalue dummy.c
run_gcc -fpost-ipa-mem-report dummy.c
run_gcc -fpredictive-commoning dummy.c
run_gcc -fprefetch-loop-arrays dummy.c
run_gcc -fpre-ipa-mem-report dummy.c
run_gcc -fpredictive-commoning dummy.c
run_gcc -fprefetch-loop-arrays dummy.c
run_gcc -fpreprocessed dummy-preproc.i
run_gcc -fprofile-arcs dummy.c
run_gcc -fprofile-correction dummy.c
run_gcc -fprofile-dir=`pwd` dummy.c
run_gcc -fprofile-generate dummy.c
run_gcc -fprofile-reorder-functions dummy.c
run_gcc -fprofile-report dummy.c
run_gcc -fprofile-use dummy.c
run_gcc -fprofile-values dummy.c
run_gcc -frecord-gcc-switches dummy.c
run_gcc -free dummy.c
run_gcc -freg-struct-return dummy.c
run_gcc -frename-registers dummy.c
run_gcc -freorder-blocks dummy.c
run_gcc -freorder-blocks-and-partition dummy.c
run_gcc -freorder-functions dummy.c
run_gcc -frepo dummy.c
run_gcc -freport-bug dummy.c
run_gcc -frerun-cse-after-loop dummy.c
run_gcc -freschedule-modulo-scheduled-loops dummy.c
run_gcc -frounding-math dummy.c
run_gcc -fsanitize=address dummy.c
run_gcc -fsanitize=alignment dummy.c
run_gcc -fsanitize=bool dummy.c
run_gcc -fsanitize=bounds dummy.c
run_gcc -fsanitize=enum dummy.c
run_gcc -fsanitize=float-cast-overflow dummy.c
run_gcc -fsanitize=float-divide-by-zero dummy.c
run_gcc -fsanitize=integer-divide-by-zero dummy.c
run_gcc -fsanitize=leak dummy.c
run_gcc -fsanitize=nonnull-attribute dummy.c
run_gcc -fsanitize=null dummy.c
run_gcc -fsanitize=object-size dummy.c
run_gcc -fsanitize=return dummy.c
run_gcc -fsanitize=returns-nonnull-attribute dummy.c
run_gcc -fsanitize=shift dummy.c
run_gcc -fsanitize=signed-integer-overflow dummy.c
run_gcc -fsanitize=thread dummy.c
run_gcc -fsanitize=undefined dummy.c
run_gcc -fsanitize=unreachable dummy.c
run_gcc -fsanitize=vla-bound dummy.c
run_gcc -fsanitize=vptr dummy.c
run_gcc -fsched2-use-superblocks dummy.c
run_gcc -fsched-critical-path-heuristic dummy.c
run_gcc -fsched-dep-count-heuristic dummy.c
run_gcc -fsched-group-heuristic dummy.c
run_gcc -fsched-last-insn-heuristic dummy.c
run_gcc -fsched-pressure dummy.c
run_gcc -fsched-rank-heuristic dummy.c
run_gcc -fsched-spec-insn-heuristic dummy.c
run_gcc -fsched-spec-load dummy.c
run_gcc -fsched-spec-load-dangerous dummy.c
run_gcc -fsched-stalled-insns dummy.c
run_gcc -fsched-stalled-insns-dep dummy.c
run_gcc -fschedule-fusion dummy.c
run_gcc -fschedule-insns dummy.c
run_gcc -fschedule-insns2 dummy.c
run_gcc -fsched-verbose=4 dummy.c
run_gcc -fsection-anchors dummy.c
run_gcc -fselective-scheduling dummy.c
run_gcc -fselective-scheduling2 dummy.c
run_gcc -fsel-sched-pipelining dummy.c
run_gcc -fsel-sched-pipelining-outer-loops dummy.c
run_gcc -fsemantic-interposition dummy.c
run_gcc -fshrink-wrap dummy.c
run_gcc -fsignaling-nans dummy.c
run_gcc -fsingle-precision-constant dummy.c
run_gcc -fsplit-ivs-in-unroller dummy.c
run_gcc -fsplit-wide-types dummy.c
run_gcc -fssa-phiopt dummy.c
run_gcc -fstack-limit-register=rax dummy.c
run_gcc -fstack-limit-symbol=__sl -Wl,--defsym,__sl=0x7ffe000 dummy.c
run_gcc -fstack-protector-explicit dummy.c
run_gcc -fstack-reuse=all dummy.c
run_gcc -fstack-reuse=named_vars dummy.c
run_gcc -fstack-reuse=none dummy.c
run_gcc -fstack-usage dummy.c
run_gcc -fstats dummy.c
run_gcc -fstdarg-opt dummy.c
run_gcc -fstrict-volatile-bitfields dummy.c
run_gcc -fsync-libcalls dummy.c
run_gcc -fthread-jumps dummy.c
run_gcc -ftracer dummy.c
run_gcc -ftrack-macro-expansion dummy.c
run_gcc -ftree-bit-ccp dummy.c
run_gcc -ftree-builtin-call-dce dummy.c
run_gcc -ftree-ccp dummy.c
run_gcc -ftree-ch dummy.c
run_gcc -ftree-coalesce-inlined-vars dummy.c
run_gcc -ftree-coalesce-vars dummy.c
run_gcc -ftree-copy-prop dummy.c
run_gcc -ftree-dce dummy.c
run_gcc -ftree-dominator-opts dummy.c
run_gcc -ftree-dse dummy.c
run_gcc -ftree-forwprop dummy.c
run_gcc -ftree-fre dummy.c
run_gcc -ftree-loop-distribute-patterns dummy.c
run_gcc -ftree-loop-distribution dummy.c
run_gcc -ftree-loop-if-convert dummy.c
run_gcc -ftree-loop-if-convert-stores dummy.c
run_gcc -ftree-loop-im dummy.c
run_gcc -ftree-loop-ivcanon dummy.c
run_gcc -ftree-loop-linear dummy.c
run_gcc -ftree-loop-optimize dummy.c
run_gcc -ftree-loop-vectorize dummy.c
run_gcc -ftree-parallelize-loops=5 dummy.c
run_gcc -ftree-partial-pre dummy.c
run_gcc -ftree-phiprop dummy.c
run_gcc -ftree-pre dummy.c
run_gcc -ftree-pta dummy.c
run_gcc -ftree-reassoc dummy.c
run_gcc -ftree-sink dummy.c
run_gcc -ftree-slsr dummy.c
run_gcc -ftree-sra dummy.c
run_gcc -ftree-switch-conversion dummy.c
run_gcc -ftree-tail-merge dummy.c
run_gcc -ftree-ter dummy.c
run_gcc -ftree-vrp dummy.c
run_gcc -funroll-all-loops dummy.c
run_gcc -funsafe-loop-optimizations dummy.c
run_gcc -funswitch-loops dummy.c
run_gcc -fuse-linker-plugin dummy.c
run_gcc -fvariable-expansion-in-unroller dummy.c
run_gcc -fvar-tracking dummy.c
run_gcc -fvar-tracking-assignments dummy.c
run_gcc -fvar-tracking-assignments-toggle dummy.c
run_gcc -fvect-cost-model dummy.c
run_gcc -fvpt dummy.c
run_gcc -fweb dummy.c
run_gcc -fwhole-program dummy.c
run_gcc -fwide-exec-charset=UTF-8 dummy.c
run_gcc -fworking-directory dummy.c
run_gcc -fzero-link dummy.c
run_gcc -gpubnames dummy.c
run_gcc -gstabs dummy.c
run_gcc -gstabs0 dummy.c
run_gcc -gstabs1 dummy.c
run_gcc -gstabs2 dummy.c
run_gcc -gstabs3 dummy.c
run_gcc -gstabs+ dummy.c
run_gcc -gtoggle dummy.c
run_gcc -I- -I . dummy.c
run_gcc -iplugindir=`pwd` -fplugin=myplugin.so dummy.c
run_gcc -no-canonical-prefixes dummy.c
run_gcc --no-sysroot-suffix dummy.c
run_gcc -Og dummy.c
run_gcc -p dummy.c
run_gcc --param predictable-branch-outcome=8 dummy.c
run_gcc --param max-crossjump-edges=6 dummy.c
run_gcc --param min-crossjump-insns=6 dummy.c
run_gcc --param max-grow-copy-bb-insns=10 dummy.c
run_gcc --param max-goto-duplication-insns=10 dummy.c
run_gcc --param max-delay-slot-insn-search=3 dummy.c
run_gcc --param max-delay-slot-live-search=3 dummy.c
run_gcc --param max-gcse-memory=100000 dummy.c
run_gcc --param max-gcse-insertion-ratio=30 dummy.c
run_gcc --param max-pending-list-length=100 dummy.c
run_gcc --param max-modulo-backtrack-attempts=5 dummy.c
run_gcc --param max-inline-insns-single=500 dummy.c
run_gcc --param max-inline-insns-auto=50 dummy.c
run_gcc --param inline-min-speedup=30 dummy.c
run_gcc --param large-function-insns=3000 dummy.c
run_gcc --param large-function-growth=90 dummy.c
run_gcc --param large-unit-insns=15000 dummy.c
run_gcc --param inline-unit-growth=30 dummy.c
run_gcc --param ipcp-unit-growth=12 dummy.c
run_gcc --param large-stack-frame=378 dummy.c
run_gcc --param large-stack-frame-growth=90 dummy.c
run_gcc --param max-inline-insns-recursive=400 dummy.c
run_gcc --param max-inline-insns-recursive-auto=400 dummy.c
run_gcc --param max-inline-recursive-depth=9 dummy.c
run_gcc --param max-inline-recursive-depth-auto=13 dummy.c
run_gcc --param min-inline-recursive-probability=9 dummy.c
run_gcc --param early-inlining-insns=12 dummy.c
run_gcc --param max-early-inliner-iterations=40 dummy.c
run_gcc --param comdat-sharing-probability=20 dummy.c
run_gcc --param profile-func-internal-id=1 dummy.c
run_gcc --param min-vect-loop-bound=1 dummy.c
run_gcc --param gcse-cost-distance-ratio=12 dummy.c
run_gcc --param gcse-unrestricted-cost=4 dummy.c
run_gcc --param max-hoist-depth=40 dummy.c
run_gcc --param max-tail-merge-comparisons=10 dummy.c
run_gcc --param max-tail-merge-iterations=3 dummy.c
run_gcc --param max-unrolled-insns=500 dummy.c
run_gcc --param max-average-unrolled-insns=400 dummy.c
run_gcc --param max-unroll-times=10 dummy.c
run_gcc --param max-peeled-insns=40 dummy.c
run_gcc --param max-peel-times=40 dummy.c
run_gcc --param max-peel-branches=20 dummy.c
run_gcc --param max-completely-peeled-insns=30 dummy.c
run_gcc --param max-completely-peel-times=30 dummy.c
run_gcc --param max-completely-peel-loop-nest-depth=4 dummy.c
run_gcc --param max-unswitch-insns=40 dummy.c
run_gcc --param max-unswitch-level=5 dummy.c
run_gcc --param lim-expensive=30 dummy.c
run_gcc --param iv-consider-all-candidates-bound=10 dummy.c
run_gcc --param iv-max-considered-uses=10 dummy.c
run_gcc --param iv-always-prune-cand-set-bound=10 dummy.c
run_gcc --param scev-max-expr-size=100 dummy.c
run_gcc --param scev-max-expr-complexity=100 dummy.c
run_gcc --param vect-max-version-for-alignment-checks=256 dummy.c
run_gcc --param vect-max-version-for-alias-checks=128 dummy.c
run_gcc --param vect-max-peeling-for-alignment=10 dummy.c
run_gcc --param max-iterations-to-track=10 dummy.c
run_gcc --param hot-bb-count-ws-permille=500 dummy.c
run_gcc --param hot-bb-frequency-fraction=50 dummy.c
run_gcc --param max-predicted-iterations=9 dummy.c
run_gcc --param builtin-expect-probability=80 dummy.c
run_gcc --param align-threshold=50 dummy.c
run_gcc --param align-loop-iterations=20 dummy.c
run_gcc --param tracer-dynamic-coverage=50 dummy.c
run_gcc --param tracer-dynamic-coverage-feedback=80 dummy.c
run_gcc --param tracer-max-code-growth=90 dummy.c
run_gcc --param tracer-min-branch-ratio=10 dummy.c
run_gcc --param max-cse-path-length=9 dummy.c
run_gcc --param max-cse-insns=900 dummy.c
run_gcc --param ggc-min-expand=25 dummy.c
run_gcc --param ggc-min-heapsize=65536 dummy.c
run_gcc --param max-reload-search-insns=90 dummy.c
run_gcc --param max-cselib-memory-locations=450 dummy.c
run_gcc --param max-sched-ready-insns=90 dummy.c
run_gcc --param max-sched-region-blocks=9 dummy.c
run_gcc --param max-pipeline-region-blocks=14 dummy.c
run_gcc --param max-sched-region-insns=90 dummy.c
run_gcc --param max-pipeline-region-insns=200 dummy.c
run_gcc --param min-spec-prob=40 dummy.c
run_gcc --param max-sched-extend-regions-iters=3 dummy.c
run_gcc --param max-sched-insn-conflict-delay=4 dummy.c
run_gcc --param sched-spec-prob-cutoff=50 dummy.c
run_gcc --param sched-mem-true-dep-cost=2 dummy.c
run_gcc --param selsched-max-lookahead=40 dummy.c
run_gcc --param selsched-max-sched-times=3 dummy.c
run_gcc --param sms-min-sc=3 dummy.c
run_gcc --param max-last-value-rtl=9000 dummy.c
run_gcc --param max-combine-insns=3 dummy.c
run_gcc --param integer-share-limit=256 dummy.c
run_gcc --param min-size-for-stack-sharing=64 dummy.c
run_gcc --param max-jump-thread-duplication-stmts=10 dummy.c
run_gcc --param max-fields-for-field-sensitive=150 dummy.c
run_gcc --param prefetch-latency=3 dummy.c
run_gcc --param simultaneous-prefetches=3 dummy.c
run_gcc --param l1-cache-line-size=32 dummy.c
run_gcc --param l1-cache-size=32 dummy.c
run_gcc --param l2-cache-size=128 dummy.c
run_gcc --param min-insn-to-prefetch-ratio=3 dummy.c
run_gcc --param prefetch-min-insn-to-mem-ratio=3 dummy.c
run_gcc --param use-canonical-types=0 dummy.c
run_gcc --param switch-conversion-max-branch-ratio=2 dummy.c
run_gcc --param max-partial-antic-length=100 dummy.c
run_gcc --param sccvn-max-scc-size=9000 dummy.c
run_gcc --param sccvn-max-alias-queries-per-access=900 dummy.c
run_gcc --param ira-max-loops-num=90 dummy.c
run_gcc --param ira-max-conflict-table-size=1500 dummy.c
run_gcc --param ira-loop-reserved-regs=3 dummy.c
run_gcc --param lra-inheritance-ebb-probability-cutoff=30 dummy.c
run_gcc --param loop-invariant-max-bbs-in-loop=9000 dummy.c
run_gcc --param loop-max-datarefs-for-datadeps=900 dummy.c
run_gcc --param max-vartrack-size=100 dummy.c
run_gcc --param max-vartrack-expr-depth=10 dummy.c
run_gcc --param min-nondebug-insn-uid=100 dummy.c
run_gcc --param ipa-sra-ptr-growth-factor=4 dummy.c
run_gcc --param sra-max-scalarization-size-Ospeed=32 dummy.c
run_gcc --param sra-max-scalarization-size-Osize=64 dummy.c
run_gcc --param tm-max-aggregate-size=16 dummy.c
run_gcc --param graphite-max-nb-scop-params=12 dummy.c
run_gcc --param graphite-max-bbs-per-function=200 dummy.c
run_gcc --param loop-block-tile-size=60 dummy.c
run_gcc --param loop-unroll-jam-size=5 dummy.c
run_gcc --param loop-unroll-jam-depth=3 dummy.c
run_gcc --param ipa-cp-value-list-size=10 dummy.c
run_gcc --param ipa-cp-eval-threshold=10 dummy.c
run_gcc --param ipa-cp-recursion-penalty=10 dummy.c
run_gcc --param ipa-cp-single-call-penalty=10 dummy.c
run_gcc --param ipa-max-agg-items=10 dummy.c
run_gcc --param ipa-cp-loop-hint-bonus=10 dummy.c
run_gcc --param ipa-cp-array-index-hint-bonus=10 dummy.c
run_gcc --param ipa-max-aa-steps=100 dummy.c
run_gcc --param lto-partitions=64 dummy.c
run_gcc --param cxx-max-namespaces-for-diagnostic-help=900 dummy.c
run_gcc --param sink-frequency-threshold=80 dummy.c
run_gcc --param max-stores-to-sink=3 dummy.c
run_gcc --param allow-store-data-races=1 dummy.c
run_gcc --param case-values-threshold=3 dummy.c
run_gcc --param tree-reassoc-width=3 dummy.c
run_gcc --param sched-pressure-algorithm=2 dummy.c
run_gcc --param max-slsr-cand-scan=5 dummy.c
run_gcc --param asan-globals=1 dummy.c
run_gcc --param asan-stack=1 dummy.c
run_gcc --param asan-instrument-reads=1 dummy.c
run_gcc --param asan-instrument-writes=1 dummy.c
run_gcc --param asan-memintrin=1 dummy.c
run_gcc --param asan-use-after-return=1 dummy.c
run_gcc --param asan-instrumentation-with-call-threshold=10 dummy.c
run_gcc --param chkp-max-ctor-size=4000 dummy.c
run_gcc --param max-fsm-thread-path-insns=150 dummy.c
run_gcc --param max-fsm-thread-length=12 dummy.c
run_gcc --param max-fsm-thread-paths=60 dummy.c
run_gcc -pass-exit-codes dummy.c
run_gcc -print-multiarch dummy.c
run_gcc -print-multi-os-directory dummy.c
run_gcc -print-sysroot dummy.c
run_gcc -Q dummy.c
run_gcc -remap dummy.c

# Stop for now
tidyup
exit 0

run_gcc -s dummy.c
run_gcc -shared dummy.c
run_gcc -shared-libgcc dummy.c
run_gcc -specs dummy.c
run_gcc -static dummy.c
run_gcc -static-libasan dummy.c
run_gcc -static-libgcc dummy.c
run_gcc -static-liblsan dummy.c
run_gcc -static-libmpx dummy.c
run_gcc -static-libmpxwrappers dummy.c
run_gcc -static-libstdc++ dummy.c
run_gcc -static-libtsan dummy.c
run_gcc -static-libubsan dummy.c
run_gcc -std dummy.c
run_gcc -symbolic dummy.c
run_gcc --sysroot dummy.c
run_gcc -T dummy.c
run_gcc -time=time.dat dummy.c
run_gcc -u dummy.c
run_gcc -U dummy.c
run_gcc --version dummy.c
run_gcc -W dummy.c
run_gcc -Wa, dummy.c
run_gcc -Waddress dummy.c
run_gcc -Waggregate-return dummy.c
run_gcc -Wall dummy.c
run_gcc -Warray-bounds dummy.c
run_gcc -Wbad-function-cast dummy.c
run_gcc -Wc++11-compat dummy.c
run_gcc -Wcast-align dummy.c
run_gcc -Wcast-qual dummy.c
run_gcc -Wc++-compat dummy.c
run_gcc -Wchar-subscripts dummy.c
run_gcc -Wclobbered dummy.c
run_gcc -Wcomment dummy.c
run_gcc -Wcomments dummy.c
run_gcc -Wconversion dummy.c
run_gcc -Wctor-dtor-privacy dummy.c
run_gcc -Wdeclaration-after-statement dummy.c
run_gcc -Wdelete-incomplete dummy.c
run_gcc -Wdelete-non-virtual-dtor dummy.c
run_gcc -Wdisabled-optimization dummy.c
run_gcc -Weffc++ dummy.c
run_gcc -Wempty-body dummy.c
run_gcc -Wenum-compare dummy.c
run_gcc -Werror dummy.c
run_gcc -Wextra dummy.c
run_gcc -Wfatal-errors dummy.c
run_gcc -Wfloat-equal dummy.c
run_gcc -Wformat dummy.c
run_gcc -Wformat-nonliteral dummy.c
run_gcc -Wformat-security dummy.c
run_gcc -Wformat-y2k dummy.c
run_gcc -Wframe-larger-than dummy.c
run_gcc -Wignored-qualifiers dummy.c
run_gcc -Wimplicit dummy.c
run_gcc -Wimplicit-function-declaration dummy.c
run_gcc -Wimplicit-int dummy.c
run_gcc -Winit-self dummy.c
run_gcc -Winline dummy.c
run_gcc -Winvalid-pch dummy.c
run_gcc -Wl, dummy.c
run_gcc -Wlarger-than dummy.c
run_gcc -Wlogical-not-parentheses dummy.c
run_gcc -Wlong-long dummy.c
run_gcc -Wmain dummy.c
run_gcc -Wmissing-braces dummy.c
run_gcc -Wmissing-declarations dummy.c
run_gcc -Wmissing-field-initializers dummy.c
run_gcc -Wmissing-format-attribute dummy.c
run_gcc -Wmissing-include-dirs dummy.c
run_gcc -Wmissing-prototypes dummy.c
run_gcc -Wnarrowing dummy.c
run_gcc -Wnested-externs dummy.c
run_gcc -Wno-attributes dummy.c
run_gcc -Wno-builtin-macro-redefined dummy.c
run_gcc -Wno-conversion-null dummy.c
run_gcc -Wno-deprecated dummy.c
run_gcc -Wno-deprecated-declarations dummy.c
run_gcc -Wno-div-by-zero dummy.c
run_gcc -Wno-endif-labels dummy.c
run_gcc -Wnoexcept dummy.c
run_gcc -Wno-format-extra-args dummy.c
run_gcc -Wno-format-zero-length dummy.c
run_gcc -Wno-incompatible-pointer-types dummy.c
run_gcc -Wno-inherited-variadic-ctor dummy.c
run_gcc -Wno-int-conversion dummy.c
run_gcc -Wno-int-to-pointer-cast dummy.c
run_gcc -Wno-multichar dummy.c
run_gcc -Wnonnull dummy.c
run_gcc -Wnon-virtual-dtor dummy.c
run_gcc -Wno-overflow dummy.c
run_gcc -Wno-pointer-to-int-cast dummy.c
run_gcc -Wno-protocol dummy.c
run_gcc -Wno-shadow-ivar dummy.c
run_gcc -Wno-unused-result dummy.c
run_gcc -Wodr dummy.c
run_gcc -Wold-style-cast dummy.c
run_gcc -Woverlength-strings dummy.c
run_gcc -Woverloaded-virtual dummy.c
run_gcc -Wp, dummy.c
run_gcc -Wpacked dummy.c
run_gcc -Wpadded dummy.c
run_gcc -Wparentheses dummy.c
run_gcc -Wpedantic dummy.c
run_gcc -Wpointer-arith dummy.c
run_gcc -Wpointer-sign dummy.c
run_gcc -Wredundant-decls dummy.c
run_gcc -Wreorder dummy.c
run_gcc -Wreturn-type dummy.c
run_gcc -Wselector dummy.c
run_gcc -Wsequence-point dummy.c
run_gcc -Wshadow dummy.c
run_gcc -Wshift-count-negative dummy.c
run_gcc -Wshift-count-overflow dummy.c
run_gcc -Wsign-compare dummy.c
run_gcc -Wsign-conversion dummy.c
run_gcc -Wsign-promo dummy.c
run_gcc -Wsizeof-array-argument dummy.c
run_gcc -Wsizeof-pointer-memaccess dummy.c
run_gcc -Wstack-protector dummy.c
run_gcc -Wstrict-aliasing dummy.c
run_gcc -Wstrict-overflow dummy.c
run_gcc -Wstrict-prototypes dummy.c
run_gcc -Wstrict-selector-match dummy.c
run_gcc -Wswitch dummy.c
run_gcc -Wswitch-default dummy.c
run_gcc -Wswitch-enum dummy.c
run_gcc -Wsystem-headers dummy.c
run_gcc -Wtrigraphs dummy.c
run_gcc -Wtype-limits dummy.c
run_gcc -Wundeclared-selector dummy.c
run_gcc -Wundef dummy.c
run_gcc -Wuninitialized dummy.c
run_gcc -Wunknown-pragmas dummy.c
run_gcc -Wunused dummy.c
run_gcc -Wunused-function dummy.c
run_gcc -Wunused-label dummy.c
run_gcc -Wunused-macros dummy.c
run_gcc -Wunused-parameter dummy.c
run_gcc -Wunused-value dummy.c
run_gcc -Wunused-variable dummy.c
run_gcc -Wuseless-cast dummy.c
run_gcc -Wvarargs dummy.c
run_gcc -Wvariadic-macros dummy.c
run_gcc -Wvla dummy.c
run_gcc -Wvolatile-register-var dummy.c
run_gcc -Wwrite-strings

# Options which are only for specific targets or systems
run_neither -F`pwd` dummy.c # Darwin
run_neither -fauto-profile dummy.c
run_neither -fcheck-pointer-bounds dummy.c
run_neither -fchkp-check-incomplete-type dummy.c
run_neither -fchkp-check-read dummy.c
run_neither -fchkp-check-write dummy.c
run_neither -fchkp-first-field-has-own-bounds dummy.c
run_neither -fchkp-instrument-calls dummy.c
run_neither -fchkp-instrument-marked-only dummy.c
run_neither -fchkp-narrow-bounds dummy.c
run_neither -fchkp-narrow-to-innermost-array dummy.c
run_neither -fchkp-optimize dummy.c
run_neither -fchkp-store-bounds dummy.c
run_neither -fchkp-treat-zero-dynamic-size-as-infinite dummy.c
run_neither -fchkp-use-fast-string-functions dummy.c
run_neither -fchkp-use-nochk-string-functions dummy.c
run_neither -fchkp-use-static-bounds dummy.c
run_neither -fchkp-use-static-const-bounds dummy.c
run_neither -fchkp-use-wrappers dummy.c
run_neither -ffix-and-continue dummy.c
run_neither -findirect-data dummy.c
run_neither -fno-keep-inline-dllexport dummy.c
run_neither -gcoff dummy.c
run_neither -gcoff0 dummy.c
run_neither -gcoff1 dummy.c
run_neither -gcoff2 dummy.c
run_neither -gcoff3 dummy.c
run_neither -gfull dummy.c # Darwin
run_neither -gused dummy.c # Darwin
run_neither -gvms dummy.c
run_neither -gvms0 dummy.c
run_neither -gvms1 dummy.c
run_neither -gvms2 dummy.c
run_neither -gvms3 dummy.c
run_neither -gxcoff dummy.c
run_neither -gxcoff0 dummy.c
run_neither -gxcoff1 dummy.c
run_neither -gxcoff2 dummy.c
run_neither -gxcoff3 dummy.c
run_neither -gxcoff+ dummy.c
run_neither -gz dummy.c
run_neither -gz=none dummy.c
run_neither -gz=zlib dummy.c
run_neither -gz=zlib-gnu dummy.c
run_neither -iframework`pwd` dummy.c # Darwin
run_neither -image_base dummy.c # Darwin
run_neither -init dummy.c # Darwin
run_neither -install_name dummy.c # Darwin
run_neither -keep_private_externs dummy.c # Darwin
run_neither -no_dead_strip_inits_and_terms dummy.c # Darwin
run_neither -noall_load dummy.c # Darwin
run_neither -nofixprebinding dummy.c # Darwin
run_neither -nomultidefs dummy.c # Darwin
run_neither -noprefind dummy.c # Darwin
run_neither -noseglinkedit dummy.c # Darwin
run_neither -pagezero_size dummy.c # Darwin
run_neither -print-sysroot-headers-suffix dummy.c
run_neither -private_bundle dummy.c # Darwin
run_neither -pthreads dummy.c
run_neither -read_only_relocs dummy.c # Darwin

# Options claimed by clang --help, but which in fact are not supported.
run_gcc -time dummy.c

# Options which do not appear in the summary
run_gcc -fdump-rtl-alignments dummy.c
run_gcc -fdump-rtl-all dummy.c
run_gcc -fdump-rtl-asmcons. dummy.c
run_gcc -fdump-rtl-auto_inc_dec dummy.c
run_gcc -fdump-rtl-barriers dummy.c
run_gcc -fdump-rtl-bbpart dummy.c
run_gcc -fdump-rtl-bbro dummy.c
run_gcc -fdump-rtl-btl2 dummy.c
run_gcc -fdump-rtl-bypass dummy.c
run_gcc -fdump-rtl-ce1 dummy.c
run_gcc -fdump-rtl-ce2 dummy.c
run_gcc -fdump-rtl-ce3 dummy.c
run_gcc -fdump-rtl-combine. dummy.c
run_gcc -fdump-rtl-compgotos dummy.c
run_gcc -fdump-rtl-cprop_hardreg dummy.c
run_gcc -fdump-rtl-csa dummy.c
run_gcc -fdump-rtl-cse1 dummy.c
run_gcc -fdump-rtl-cse2 dummy.c
run_gcc -fdump-rtl-dbr dummy.c
run_gcc -fdump-rtl-dce dummy.c
run_gcc -fdump-rtl-dce1 dummy.c
run_gcc -fdump-rtl-dce2 dummy.c
run_gcc -fdump-rtl-dfinish dummy.c
run_gcc -fdump-rtl-dfinit. dummy.c
run_gcc -fdump-rtl-eh dummy.c
run_gcc -fdump-rtl-eh_ranges dummy.c
run_gcc -fdump-rtl-expand dummy.c
run_gcc -fdump-rtl-fwprop1. dummy.c
run_gcc -fdump-rtl-fwprop2. dummy.c
run_gcc -fdump-rtl-gcse1 dummy.c
run_gcc -fdump-rtl-gcse2 dummy.c
run_gcc -fdump-rtl-init-regs dummy.c
run_gcc -fdump-rtl-initvals dummy.c
run_gcc -fdump-rtl-into_cfglayout dummy.c
run_gcc -fdump-rtl-ira dummy.c
run_gcc -fdump-rtl-jump dummy.c
run_gcc -fdump-rtl-loop2 dummy.c
run_gcc -fdump-rtl-mach dummy.c
run_gcc -fdump-rtl-mode_sw. dummy.c
run_gcc -fdump-rtl-outof_cfglayout dummy.c
run_gcc -fdump-rtl-pass dummy.c
run_gcc -fdump-rtl-peephole2 dummy.c
run_gcc -fdump-rtl-postreload dummy.c
run_gcc -fdump-rtl-pro_and_epilogue dummy.c
run_gcc -fdump-rtl-ree dummy.c
run_gcc -fdump-rtl-regclass dummy.c
run_gcc -fdump-rtl-rnreg dummy.c
run_gcc -fdump-rtl-sched1 dummy.c
run_gcc -fdump-rtl-sched2 dummy.c
run_gcc -fdump-rtl-seqabstr dummy.c
run_gcc -fdump-rtl-shorten dummy.c
run_gcc -fdump-rtl-sibling dummy.c
run_gcc -fdump-rtl-sms dummy.c
run_gcc -fdump-rtl-split1 dummy.c
run_gcc -fdump-rtl-split2 dummy.c
run_gcc -fdump-rtl-split3 dummy.c
run_gcc -fdump-rtl-split4 dummy.c
run_gcc -fdump-rtl-split5 dummy.c
run_gcc -fdump-rtl-stack dummy.c
run_gcc -fdump-rtl-subreg1 dummy.c
run_gcc -fdump-rtl-subreg2 dummy.c
run_gcc -fdump-rtl-subregs_of_mode_finish dummy.c
run_gcc -fdump-rtl-subregs_of_mode_init dummy.c
run_gcc -fdump-rtl-unshare dummy.c
run_gcc -fdump-rtl-vartrack dummy.c
run_gcc -fdump-rtl-vregs dummy.c
run_gcc -fdump-rtl-web dummy.c

# Options for the future
run_neither -x cpp-output dummy-preproc.i
run_neither -x c++ dummy.c
run_neither -x c++-header dummy.c
run_neither -x c++-cpp-output dummy-preproc.i
run_neither -x ada dummy.c
run_neither -x f77 dummy.c
run_neither -x f77-cpp-input dummy.c
run_neither -x f95 dummy.c
run_neither -x f95-cpp-input dummy.c
run_neither -x go dummy.c
run_neither -x java dummy.c

# Options which are in the manual, but which appear not to work.
run_neither -fdump-tree-storeccp dummy.c
run_neither -femit-struct-debug-detailed dummy.c # Needs arg
run_neither -fsel-sched-dump-cfg dummy.c # In summary only
run_neither -fsel-sched-pipelining-verbose dummy.c # In summary only
run_neither -fsel-sched-verbose dummy.c # In summary only
run_neither -fshort-double dummy.c # ICE
run_neither -ftree-copyrename. dummy.c
run_neither -fwpa dummy.c # For LTO only, not documented.
run_neither --param tracer-min-branch-ratio-feedback=5 dummy.c
run_neither --param reorder-blocks-duplicate=3 dummy.c
run_neither --param reorder-blocks-duplicate-feedback=5 dummy.c
run_neither --param sched-spec-state-edge-prob-cutoff=12 dummy.c
run_neither --param selsched-max-insns-to-rename=3 dummy.c
run_neither --param lto-minpartition=16 dummy.c
run_neither --param parloops-chunk-size=1 dummy.c # In top-of-tree?
run_neither --param parloops-schedule=static dummy.c # In top-of-tree?
run_neither --param parloops-schedule=dynamic dummy.c # In top-of-tree?
run_neither --param parloops-schedule=guided dummy.c # In top-of-tree?
run_neither --param parloops-schedule=auto dummy.c # In top-of-tree?
run_neither --param parloops-schedule=runtime dummy.c # In top-of-tree?
run_neither --param max-ssa-name-query-depth=5 # In top-of-tree?

# C++ specific
run_neither -fdeclone-ctor-dtor dummy.c
run_neither -fdeduce-init-list dummy.c
run_neither -fdevirtualize dummy.c
run_neither -fdevirtualize-at-ltrans dummy.c
run_neither -fdevirtualize-speculatively dummy.c
run_neither -fdump-class-hierarchy dummy.c
run_neither -fdump-class-hierarchy=address dummy.c
run_neither -fdump-class-hierarchy=asmname dummy.c
run_neither -fdump-class-hierarchy=slim dummy.c
run_neither -fdump-class-hierarchy=raw dummy.c
run_neither -fdump-class-hierarchy=details dummy.c
run_neither -fdump-class-hierarchy=stats dummy.c
run_neither -fdump-class-hierarchy=blocks dummy.c
run_neither -fdump-class-hierarchy=graph dummy.c
run_neither -fdump-class-hierarchy=vops dummy.c
run_neither -fdump-class-hierarchy=lineno dummy.c
run_neither -fdump-class-hierarchy=uid dummy.c
run_neither -fdump-class-hierarchy=verbose dummy.c
run_neither -fdump-class-hierarchy=eh dummy.c
run_neither -fdump-class-hierarchy=scev dummy.c
run_neither -fdump-class-hierarchy=optimized dummy.c
run_neither -fdump-class-hierarchy=missed dummy.c
run_neither -fdump-class-hierarchy=note dummy.c
run_neither -fdump-class-hierarchy=debug.dump dummy.c
run_neither -fdump-class-hierarchy=all dummy.c
run_neither -fdump-class-hierarchy=optall dummy.c
run_neither -fdump-translation-unit dummy.c
run_neither -fdump-translation-unit=all dummy.c
run_neither -femit-class-debug-always dummy.c
run_neither -fextern-tls-init dummy.c
run_neither -ffor-scope dummy.c
run_neither -ffriend-injection dummy.c
run_neither -fno-default-inline dummy.c
run_neither -fno-enforce-eh-specs dummy.c
run_neither -fno-ext-numeric-literals dummy.c
run_neither -fno-lifetime-dse dummy.c
run_neither -fno-rtti dummy.c
run_neither -fsized-deallocation dummy.c
run_neither -ftemplate-backtrace-limit=5 dummy.c
run_neither -ftemplate-depth=5 dummy.c
run_neither -fvtable-verify=preinit dummy.c
run_neither -fvtv-counts dummy.c
run_neither -fvtv-debug dummy.c
run_neither -imultilib custom dummy.c

# Objective C specific
run_neither -fconstant-string-class dummy.c
run_neither -fnext-runtime dummy.c
run_neither -fno-local-ivars dummy.c
run_neither -fno-nil-receivers dummy.c
run_neither -fobjc-abi-version dummy.c
run_neither -fobjc-call-cxx-cdtors dummy.c
run_neither -fobjc-direct-dispatch dummy.c
run_neither -fobjc-exceptions dummy.c
run_neither -fobjc-gc dummy.c
run_neither -fobjc-nilcheck dummy.c
run_neither -fobjc-std=objc1 dummy.c
run_neither -gen-decls dummy.c
run_neither -lobjc dummy.c
run_neither -print-objc-runtime-info dummy.c
run_neither -x objective-c dummy.c
run_neither -x objective-c-header dummy.c
run_neither -x objective-c-cpp-output dummy-preproc.i
run_neither -x objective-c++ dummy.c
run_neither -x objective-c++-header dummy.c
run_neither -x objective-c++-cpp-output dummy-preproc.i

# Ada specific
run_neither -fdump-ada-spec dummy.c

# Go specific
run_neither -fdump-go-spec dummy.c

# Tidy up
tidyup
