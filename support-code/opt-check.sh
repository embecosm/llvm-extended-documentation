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
    # from dumps
    rm -f address all asmname blocks debug.dump details dummy_c.ads eh graph \
          lineno missed note optall optimized raw scev slim stats uid verbose \
          vops
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

# Function to compile LLVM and echo a single character result: "L" for
# succcess "l" for failure.

comp_llvm () {
    if ! ${LCC} $* > ${tmpf} 2>&1
    then
	echo -n l
    elif grep -q "argument unused during compilation" ${tmpf}
    then
	echo -n l
    elif grep -q "optimization flag .* is not supported" ${tmpf}
    then
	echo -n l
    elif grep -q "unknown warning option" ${tmpf}
    then
	echo -n l
    else
	echo -n L
    fi
}

# Function to compiler GCC and echo a single character result: "G" for
# succcess "g" for failure.

comp_gcc () {
    if ${GCC} $* > /dev/null 2>&1
    then
	echo -n "G"
    else
	echo -n "g"
    fi
}

# Function to compile LLVM and GCC in parallel and return a two character
# result.

comp_both () {
    ( comp_llvm $* & comp_gcc $* )
}

# Check works with both LLVM and GCC

run_both () {
    case `comp_both $*` in
	lg | gl)
	    logerr "  $*: LLVM & GCC failed"
	    ;;

	lG | Gl)
	    logerr "  $*: LLVM failed"
	    ;;

	Lg | gL)
	    logerr "  $*: GCC failed"
	    ;;

	LG | GL)
	    logok
	    ;;
    esac
}

# Check works with LLVM and not with GCC

run_llvm () {
    case `comp_both $*` in
	lg | gl)
	    logerr "  $*: LLVM failed"
	    ;;

	lG | Gl)
	    logerr "  $*: LLVM failed & GCC OK"
	    ;;

	Lg | gL)
	    logok
	    ;;

	LG | GL)
	    logerr "  $*: GCC OK"
	    ;;
    esac
}

# Check works with only LLVM (don't test GCC)

run_only_llvm () {
    case `comp_llvm $*` in
	l)
	    logerr "  $*: LLVM failed"
	    ;;

	L)
	    logok
	    ;;
    esac
}

# Check works with GCC and not with LLVM

run_gcc () {
    case `comp_both $*` in
	lg | gl)
	    logerr "  $*: GCC failed"
	    ;;

	lG | Gl)
	    logok
	    ;;

	Lg | gL)
	    logerr "  $*: LLVM OK & GCC failed"
	    ;;

	LG | GL)
	    logerr "  $*: LLVM OK"
	    ;;
    esac
}

# Check works with only GCC (don't test LLVM)

run_only_gcc () {
    case `comp_gcc $*` in
	g)
	    logerr "  $*: GCC failed"
	    ;;

	G)
	    logok
	    ;;
    esac
}

# Check explicitly works with neither LLVM nor GCC

run_neither () {
    case `comp_both $*` in
	lg | gl)
	    logok
	    ;;

	lG | Gl)
	    logerr "  $*: GCC OK"
	    ;;

	Lg | gL)
	    logerr "  $*: LLVM OK"
	    ;;

	LG | GL)
	    logerr "  $*: LLVM & GCC OK"
	    ;;
    esac
}

# Do nothing

run_dummy () {
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

logcon "Testing options for both LLVM and GCC"

run_both -### dummy.c
run_both -c dummy.c
run_both -dD -E dummy.c
run_both -dM -E dummy.c
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
run_both -save-temps=obj dummy.c
run_both -trigraphs dummy.c
run_both -undef dummy.c
run_both -v dummy.c
run_both -w dummy.c
run_both -x c dummy.c
run_both -x c-header dummy.c
run_both -x assembler -c dummy-asm.S
run_both -x assembler-with-cpp -c dummy-asm.S
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
run_both -F`pwd` dummy.c
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
run_both -s dummy.c
run_both -shared -fpic dummy.c
run_both -static dummy.c
run_both -static-libgcc dummy.c
run_both -std=c90 dummy.c
run_both -std=c89 dummy.c
run_both -std=iso9899:1990 dummy.c
run_both -std=iso9899:199409 dummy.c
run_both -std=c99 dummy.c
run_both -std=c9x dummy.c
run_both -std=iso9899:1999 dummy.c
run_both -std=iso9899:199x dummy.c
run_both -std=c11 dummy.c
run_both -std=c1x dummy.c
run_both -std=iso9899:2011 dummy.c
run_both -std=gnu90 dummy.c
run_both -std=gnu89 dummy.c
run_both -std=gnu99 dummy.c
run_both -std=gnu9x dummy.c
run_both -std=gnu11 dummy.c
run_both -std=gnu1x dummy.c
run_both --sysroot=`pwd` -c dummy.c
run_both -traditional -E dummy.c
run_both -u var dummy.c
run_both -U FORTY_TWO dummy.c
run_both --version dummy.c
run_both -Wa,-gdwarf-3 dummy.c
run_both -Wl,-relax dummy.c
run_both -Wp,-v dummy.c
run_both -Wabi dummy.c
run_both -Waddress dummy.c
run_both -Waggregate-return dummy.c
run_both -Wall dummy.c
run_both -Warray-bounds dummy.c
run_both -Wattributes dummy.c
run_both -Wbad-function-cast dummy.c
run_both -Wbuiltin-macro-redefined dummy.c
run_both -Wc++-compat dummy.c
run_both -Wc++11-compat dummy.c
run_both -Wc++14-compat dummy.c
run_both -Wcast-align dummy.c
run_both -Wcast-qual dummy.c
run_both -Wchar-subscripts dummy.c
run_both -Wcomment dummy.c
run_both -Wcomments dummy.c
run_both -Wconversion-null dummy.c
run_both -Wconversion dummy.c
run_both -Wctor-dtor-privacy dummy.c
run_both -Wdate-time dummy.c
run_both -Wdeclaration-after-statement dummy.c
run_both -Wdelete-incomplete dummy.c
run_both -Wdelete-non-virtual-dtor dummy.c
run_both -Wdeprecated dummy.c
run_both -Wdeprecated-declarations dummy.c
run_both -Wdisabled-optimization dummy.c
run_both -Wdiv-by-zero dummy.c
run_both -Wdouble-promotion dummy.c
run_both -Weffc++ dummy.c
run_both -Wempty-body dummy.c
run_both -Wendif-labels dummy.c
run_both -Wenum-compare dummy.c
run_both -Werror dummy.c
run_both -Werror=abi dummy.c
run_both -Wextra dummy.c
run_both -Wfatal-errors dummy.c
run_both -Wfloat-conversion dummy.c
run_both -Wfloat-equal dummy.c
run_both -Wformat dummy.c
run_both -Wformat=0 dummy.c
run_both -Wformat=2 dummy.c
run_both -Wformat-extra-args dummy.c
run_both -Wformat-nonliteral dummy.c
run_both -Wformat-security dummy.c
run_both -Wformat-y2k dummy.c
run_both -Wformat-zero-length dummy.c
run_both -Wframe-larger-than=128 dummy.c
run_both -Wignored-qualifiers dummy.c
run_both -Wimplicit dummy.c
run_both -Wimplicit-function-declaration dummy.c
run_both -Wimplicit-int dummy.c
run_both -Wincompatible-pointer-types dummy.c
run_both -Winherited-variadic-ctor dummy.c
run_both -Winit-self dummy.c
run_both -Winline dummy.c
run_both -Wint-conversion dummy.c
run_both -Wint-to-pointer-cast dummy.c
run_both -Winvalid-offsetof dummy.c
run_both -Winvalid-pch dummy.c
run_both -Wlarger-than-10 dummy.c
run_both -Wlarger-than=10 dummy.c
run_both -Wlogical-not-parentheses dummy.c
run_both -Wlong-long dummy.c
run_both -Wmain dummy.c
run_both -Wmissing-braces dummy.c
run_both -Wmissing-declarations dummy.c
run_both -Wmissing-field-initializers dummy.c
run_both -Wmissing-format-attribute dummy.c
run_both -Wmissing-include-dirs dummy.c
run_both -Wmissing-prototypes dummy.c
run_both -Wmultichar dummy.c
run_both -Wnarrowing dummy.c
run_both -Wnested-externs dummy.c
run_both -Wno-abi dummy.c
run_both -Wno-address dummy.c
run_both -Wno-aggregate-return dummy.c
run_both -Wno-all dummy.c
run_both -Wno-array-bounds dummy.c
run_both -Wno-attributes dummy.c
run_both -Wno-bad-function-cast dummy.c
run_both -Wno-builtin-macro-redefined dummy.c
run_both -Wno-cast-align dummy.c
run_both -Wno-cast-qual dummy.c
run_both -Wno-char-subscripts dummy.c
run_both -Wno-comment dummy.c
run_both -Wno-conversion dummy.c
run_both -Wno-conversion-null dummy.c
run_both -Wno-ctor-dtor-privacy dummy.c
run_both -Wno-date-time dummy.c
run_both -Wno-declaration-after-statement dummy.c
run_both -Wno-delete-incomplete dummy.c
run_both -Wno-delete-non-virtual-dtor dummy.c
run_both -Wno-deprecated dummy.c
run_both -Wno-deprecated-declarations dummy.c
run_both -Wno-disabled-optimization dummy.c
run_both -Wno-div-by-zero dummy.c
run_both -Wno-double-promotion dummy.c
run_both -Wno-effc++ dummy.c
run_both -Wno-empty-body dummy.c
run_both -Wno-endif-labels dummy.c
run_both -Wno-enum-compare dummy.c
run_both -Wno-error dummy.c
run_both -Wno-error=abi dummy.c
run_both -Wno-extra dummy.c
run_both -Wno-fatal-errors dummy.c
run_both -Wno-float-conversion dummy.c
run_both -Wno-float-equal dummy.c
run_both -Wno-format dummy.c
run_both -Wno-format-extra-args dummy.c
run_both -Wno-format-nonliteral dummy.c
run_both -Wno-format-security dummy.c
run_both -Wno-format-y2k dummy.c
run_both -Wno-format-zero-length dummy.c
run_both -Wno-ignored-qualifiers dummy.c
run_both -Wno-implicit dummy.c
run_both -Wno-implicit-function-declaration dummy.c
run_both -Wno-implicit-int dummy.c
run_both -Wno-incompatible-pointer-types dummy.c
run_both -Wno-inherited-variadic-ctor dummy.c
run_both -Wno-init-self dummy.c
run_both -Wno-inline dummy.c
run_both -Wno-int-conversion dummy.c
run_both -Wno-int-to-pointer-cast dummy.c
run_both -Wno-invalid-offsetof dummy.c
run_both -Wno-invalid-pch dummy.c
run_both -Wno-logical-not-parentheses dummy.c
run_both -Wno-long-long dummy.c
run_both -Wno-main dummy.c
run_both -Wno-missing-braces dummy.c
run_both -Wno-missing-declarations dummy.c
run_both -Wno-missing-field-initializers dummy.c
run_both -Wno-missing-format-attribute dummy.c
run_both -Wno-missing-include-dirs dummy.c
run_both -Wno-missing-prototypes dummy.c
run_both -Wno-multichar dummy.c
run_both -Wno-narrowing dummy.c
run_both -Wno-nested-externs dummy.c
run_both -Wno-nonnull dummy.c
run_both -Wno-non-virtual-dtor dummy.c
run_both -Wno-odr dummy.c
run_both -Wno-old-style-cast dummy.c
run_both -Wno-old-style-definition dummy.c
run_both -Wno-overflow dummy.c
run_both -Wno-overlength-strings dummy.c
run_both -Wno-overloaded-virtual dummy.c
run_both -Wno-packed dummy.c
run_both -Wno-padded dummy.c
run_both -Wno-parentheses dummy.c
run_both -Wno-pointer-arith dummy.c
run_both -Wno-pointer-sign dummy.c
run_both -Wno-pointer-to-int-cast dummy.c
run_both -Wno-pragmas dummy.c
run_both -Wno-protocol dummy.c
run_both -Wno-redundant-decls dummy.c
run_both -Wno-reorder dummy.c
run_both -Wno-return-type dummy.c
run_both -Wno-selector dummy.c
run_both -Wno-sequence-point dummy.c
run_both -Wno-shadow dummy.c
run_both -Wno-shadow-ivar dummy.c
run_both -Wno-shift-count-negative dummy.c
run_both -Wno-shift-count-overflow dummy.c
run_both -Wno-sign-compare dummy.c
run_both -Wno-sign-conversion dummy.c
run_both -Wno-sign-promo dummy.c
run_both -Wno-sizeof-array-argument dummy.c
run_both -Wno-sizeof-pointer-memaccess dummy.c
run_both -Wno-stack-protector dummy.c
run_both -Wno-strict-aliasing dummy.c
run_both -Wno-strict-overflow dummy.c
run_both -Wno-strict-prototypes dummy.c
run_both -Wno-strict-selector-match dummy.c
run_both -Wno-switch dummy.c
run_both -Wno-switch-bool dummy.c
run_both -Wno-switch-default dummy.c
run_both -Wno-switch-enum dummy.c
run_both -Wno-system-headers dummy.c
run_both -Wno-trigraphs dummy.c
run_both -Wno-type-limits dummy.c
run_both -Wno-undeclared-selector dummy.c
run_both -Wno-undef dummy.c
run_both -Wno-uninitialized dummy.c
run_both -Wno-unknown-pragmas dummy.c
run_both -Wno-unused dummy.c
run_both -Wno-unused-function dummy.c
run_both -Wno-unused-label dummy.c
run_both -Wno-unused-parameter dummy.c
run_both -Wno-unused-result dummy.c
run_both -Wno-unused-value dummy.c
run_both -Wno-unused-variable dummy.c
run_both -Wno-varargs dummy.c
run_both -Wno-variadic-macros dummy.c
run_both -Wno-vla dummy.c
run_both -Wno-volatile-register-var dummy.c
run_both -Wno-write-strings dummy.c
run_both -Wnon-virtual-dtor dummy.c
run_both -Wnonnull dummy.c
run_both -Wodr dummy.c
run_both -Wold-style-cast dummy.c
run_both -Wold-style-definition dummy.c
run_both -Woverflow dummy.c
run_both -Woverlength-strings dummy.c
run_both -Woverloaded-virtual dummy.c
run_both -Wpacked dummy.c
run_both -Wpadded dummy.c
run_both -Wparentheses dummy.c
run_both -Wpedantic dummy.c
run_both -Wpointer-arith dummy.c
run_both -Wpointer-sign dummy.c
run_both -Wpointer-to-int-cast dummy.c
run_both -Wpragmas dummy.c
run_both -Wprotocol dummy.c
run_both -Wredundant-decls dummy.c
run_both -Wreorder dummy.c
run_both -Wreturn-type dummy.c
run_both -Wselector dummy.c
run_both -Wsequence-point dummy.c
run_both -Wshadow dummy.c
run_both -Wshadow-ivar dummy.c
run_both -Wshift-count-negative dummy.c
run_both -Wshift-count-overflow dummy.c
run_both -Wsign-compare dummy.c
run_both -Wsign-conversion dummy.c
run_both -Wsign-promo dummy.c
run_both -Wsizeof-array-argument dummy.c
run_both -Wsizeof-pointer-memaccess dummy.c
run_both -Wstack-protector dummy.c
run_both -Wstrict-aliasing dummy.c
run_both -Wstrict-aliasing=0 dummy.c
run_both -Wstrict-aliasing=1 dummy.c
run_both -Wstrict-aliasing=2 dummy.c
run_both -Wstrict-overflow dummy.c
run_both -Wstrict-prototypes dummy.c
run_both -Wstrict-selector-match dummy.c
run_both -Wswitch dummy.c
run_both -Wswitch-bool dummy.c
run_both -Wswitch-default dummy.c
run_both -Wswitch-enum dummy.c
run_both -Wsystem-headers dummy.c
run_both -Wtrigraphs dummy.c
run_both -Wtype-limits dummy.c
run_both -Wundeclared-selector dummy.c
run_both -Wundef dummy.c
run_both -Wuninitialized dummy.c
run_both -Wunknown-pragmas dummy.c
run_both -Wunused dummy.c
run_both -Wunused-function dummy.c
run_both -Wunused-label dummy.c
run_both -Wunused-local-typedefs dummy.c
run_both -Wunused-macros dummy.c
run_both -Wunused-parameter dummy.c
run_both -Wunused-result dummy.c
run_both -Wunused-value dummy.c
run_both -Wunused-variable dummy.c
run_both -Wvarargs dummy.c
run_both -Wvariadic-macros dummy.c
run_both -Wvla dummy.c
run_both -Wvolatile-register-var dummy.c
run_both -Wwrite-strings dummy.c

# Options for LLVM but not GCC

echo
logcon "Testing options for LLVM but not GCC"
run_llvm -Oz dummy.c
run_llvm -gfull dummy.c
run_llvm -gused dummy.c
run_llvm --analyze dummy.c
run_llvm -dependency-dot dummy.c
run_llvm -dependency-file dummy.c
run_llvm -emit-ast dummy.c
run_llvm -faltivec dummy.c
run_llvm -fapple-kext dummy.c
run_llvm -fapple-pragma-pack dummy.c
run_llvm -fapplication-extension dummy.c
run_llvm -fblocks dummy.c
run_llvm -fborland-extensions dummy.c
run_llvm -fcolor-diagnostics dummy.c
run_llvm -fcoverage-mapping dummy.c
run_llvm -fcxx-exceptions dummy.c
run_llvm -fdefault-addrspace dummy.c
run_llvm -fdelayed-template-parsing dummy.c
run_llvm -fdiagnostics-parseable-fixits dummy.c
run_llvm -femit-all-decls dummy.c
run_llvm -ffixed-r9 dummy.c
run_llvm -fgnu-keywords dummy.c
run_llvm -fintegrated-as dummy.c
run_llvm -fmath-errno dummy.c
run_llvm -fmax-type-align dummy.c
run_llvm -fmodule-file dummy.c
run_llvm -fmodule-map-file dummy.c
run_llvm -fmodule-maps dummy.c
run_llvm -fmodule-name dummy.c
run_llvm -fmodules dummy.c
run_llvm -fmodules-decluse dummy.c
run_llvm -fmodules-ignore-macro dummy.c
run_llvm -fmodules-prune-after dummy.c
run_llvm -fmodules-prune-interval dummy.c
run_llvm -fno-autolink dummy.c
run_llvm -fno-diagnostics-fixit-info dummy.c
run_llvm -fno-dollars-in-identifiers dummy.c
run_llvm -fno-elide-type dummy.c
run_llvm -fno-integrated-as dummy.c
run_llvm -fno-math-builtin dummy.c
run_llvm -fobjc-arc dummy.c
run_llvm -fobjc-arc-exceptions dummy.c
run_llvm -fobjc-exceptions dummy.c
run_llvm -fobjc-runtime dummy.c
run_llvm -fsized-deallocation dummy.c
run_llvm -fstandalone-debug dummy.c
run_llvm -ftrap-function dummy.c
run_llvm -ftrigraphs dummy.c
run_llvm -fuse-init-array dummy.c
run_llvm -fveclib dummy.c
run_llvm -fvectorize dummy.c
run_llvm -help
run_llvm -iframework`pwd` dummy.c
run_llvm -index-header-map dummy.c
run_llvm -ivfsoverlay dummy.c
run_llvm -iwithsysroot dummy.c
run_llvm -nobuiltininc
run_llvm -pthreads dummy.c
run_llvm -Qunused-arguments dummy.c
run_llvm -relocatable-pch dummy.c
run_llvm -Rpass-analysis dummy.c
run_llvm -Rpass-missed dummy.c
run_llvm -Rpass dummy.c
run_llvm -R dummy.c
run_llvm -target dummy.c
run_llvm -time dummy.c
run_llvm -Weverything dummy.c
run_llvm -Xanalyzer dummy.c
run_llvm -Xclang dummy.c

# Options from llvm -help which appear not to work
run_dummy -arcmt-migrate-emit-errors dummy.c

# LLVM target specific options from -help
run_dummy -mabicalls dummy.c
run_dummy -mcrc dummy.c
run_dummy -mfp32 dummy.c
run_dummy -mfp64 dummy.c
run_dummy --migrate dummy.c
run_dummy -mllvm dummy.c
run_dummy -mmsa dummy.c
run_dummy -mms-bitfields dummy.c
run_dummy -mno-abicalls dummy.c
run_dummy -mnocrc dummy.c
run_dummy -mno-implicit-float dummy.c
run_dummy -mno-msa dummy.c
run_dummy -mno-restrict-it dummy.c
run_dummy -module-dependency-dir dummy.c
run_dummy -mrelax-all dummy.c
run_dummy -mrestrict-it dummy.c
run_dummy -mrtd dummy.c
run_dummy -msoft-float dummy.c
run_dummy -mstack-alignment dummy.c
run_dummy -mstackrealign dummy.c
run_dummy -mthread-model dummy.c
run_dummy -munaligned-access dummy.c

# Options for GCC but not LLVM

echo
logcon "Testing options for GCC but not LLVM"

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
run_gcc -fcall-saved-rax dummy.c
run_gcc -fcall-used-rax dummy.c
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
run_gcc -fdump-rtl-alignments dummy.c
run_gcc -fdump-rtl-all dummy.c
run_gcc -fdump-rtl-asmcons dummy.c
run_gcc -fdump-rtl-auto_inc_dec dummy.c
run_gcc -fdump-rtl-barriers dummy.c
run_gcc -fdump-rtl-bbpart dummy.c
run_gcc -fdump-rtl-bbro dummy.c
run_gcc -fdump-rtl-btl2 dummy.c
run_gcc -fdump-rtl-ce1 dummy.c
run_gcc -fdump-rtl-ce2 dummy.c
run_gcc -fdump-rtl-ce3 dummy.c
run_gcc -fdump-rtl-combine dummy.c
run_gcc -fdump-rtl-compgotos dummy.c
run_gcc -fdump-rtl-cprop_hardreg dummy.c
run_gcc -fdump-rtl-csa dummy.c
run_gcc -fdump-rtl-cse1 dummy.c
run_gcc -fdump-rtl-cse2 dummy.c
run_gcc -fdump-rtl-dbr dummy.c
run_gcc -fdump-rtl-dfinish dummy.c
run_gcc -fdump-rtl-dfinit dummy.c
run_gcc -fdump-rtl-eh_ranges dummy.c
run_gcc -fdump-rtl-expand dummy.c
run_gcc -fdump-rtl-fwprop1 dummy.c
run_gcc -fdump-rtl-fwprop2 dummy.c
run_gcc -fdump-rtl-gcse2 dummy.c
run_gcc -fdump-rtl-init-regs dummy.c
run_gcc -fdump-rtl-into_cfglayout dummy.c
run_gcc -fdump-rtl-ira dummy.c
run_gcc -fdump-rtl-jump dummy.c
run_gcc -fdump-rtl-loop2 dummy.c
run_gcc -fdump-rtl-mach dummy.c
run_gcc -fdump-rtl-mode_sw dummy.c
run_gcc -fdump-rtl-outof_cfglayout dummy.c
run_gcc -fdump-rtl-peephole2 dummy.c
run_gcc -fdump-rtl-postreload dummy.c
run_gcc -fdump-rtl-pro_and_epilogue dummy.c
run_gcc -fdump-rtl-ree dummy.c
run_gcc -fdump-rtl-rnreg dummy.c
run_gcc -fdump-rtl-sched1 dummy.c
run_gcc -fdump-rtl-sched2 dummy.c
run_gcc -fdump-rtl-shorten dummy.c
run_gcc -fdump-rtl-sms dummy.c
run_gcc -fdump-rtl-split1 dummy.c
run_gcc -fdump-rtl-split2 dummy.c
run_gcc -fdump-rtl-split3 dummy.c
run_gcc -fdump-rtl-split4 dummy.c
run_gcc -fdump-rtl-split5 dummy.c
run_gcc -fdump-rtl-stack dummy.c
run_gcc -fdump-rtl-subreg1 dummy.c
run_gcc -fdump-rtl-subreg2 dummy.c
run_gcc -fdump-rtl-vartrack dummy.c
run_gcc -fdump-rtl-vregs dummy.c
run_gcc -fdump-rtl-web dummy.c
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
run_gcc -ftree-copyrename dummy.c
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
run_gcc -gcoff0 dummy.c
run_gcc -gstabs dummy.c
run_gcc -gstabs0 dummy.c
run_gcc -gstabs1 dummy.c
run_gcc -gstabs2 dummy.c
run_gcc -gstabs3 dummy.c
run_gcc -gstabs+ dummy.c
run_gcc -gtoggle dummy.c
run_gcc -gvms0 dummy.c
run_gcc -gxcoff0 dummy.c
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
run_gcc -shared-libgcc dummy.c
run_gcc -specs=dummy.specs dummy.c
run_gcc -static-libasan dummy.c
run_gcc -static-liblsan dummy.c
run_gcc -static-libmpx dummy.c
run_gcc -static-libmpxwrappers dummy.c
run_gcc -static-libstdc++ dummy.c
run_gcc -static-libtsan dummy.c
run_gcc -static-libubsan dummy.c
run_gcc -T dummy.script -c dummy.c
run_gcc -time=time.dat dummy.c
run_gcc -traditional-cpp dummy.c
run_gcc -umbrella dummy.c
run_gcc -undefined dummy.c
run_gcc -unexported_symbols_list dummy.c
run_gcc -Wabi-tag dummy.c
run_gcc -Waggressive-loop-optimizations dummy.c
run_gcc -Wassign-intercept dummy.c
run_gcc -Wbool-compare dummy.c
run_gcc -Wc90-c99-compat dummy.c
run_gcc -Wc99-c11-compat dummy.c
run_gcc -Wclobbered dummy.c
run_gcc -Wconditionally-supported dummy.c
run_gcc -Wdiscarded-array-qualifiers dummy.c
run_gcc -Wdiscarded-qualifiers dummy.c
run_gcc -Wformat=1 dummy.c
run_gcc -Wformat-contains-nul dummy.c
run_gcc -Wformat-signedness dummy.c
run_gcc -Wfree-nonheap-object dummy.c
run_gcc -Wjump-misses-init dummy.c
run_gcc -Wliteral-suffix dummy.c
run_gcc -Wlogical-op dummy.c
run_gcc -Wmaybe-uninitialized dummy.c
run_gcc -Wmemset-transposed-args dummy.c
run_gcc -Wmissing-parameter-type dummy.c
run_gcc -Wno-aggressive-loop-optimizations dummy.c
run_gcc -Wno-assign-intercept dummy.c
run_gcc -Wno-bool-compare dummy.c
run_gcc -Wno-c90-c99-compat dummy.c
run_gcc -Wno-c99-c11-compat dummy.c
run_gcc -Wno-clobbered dummy.c
run_gcc -Wno-conditionally-supported dummy.c
run_gcc -Wno-coverage-mismatch dummy.c
run_gcc -Wno-discarded-array-qualifiers dummy.c
run_gcc -Wno-discarded-qualifiers dummy.c
run_gcc -Wno-format-contains-nul dummy.c
run_gcc -Wno-format-signedness dummy.c
run_gcc -Wno-free-nonheap-object dummy.c
run_gcc -Wno-jump-misses-init dummy.c
run_gcc -Wno-literal-suffix dummy.c
run_gcc -Wno-logical-op dummy.c
run_gcc -Wno-maybe-uninitialized dummy.c
run_gcc -Wno-memset-transposed-args dummy.c
run_gcc -Wno-missing-parameter-type dummy.c
run_gcc -Wno-noexcept dummy.c
run_gcc -Wno-non-template-friend dummy.c
run_gcc -Wno-normalized dummy.c
run_gcc -Wno-old-style-declaration dummy.c
run_gcc -Wno-override-init dummy.c
run_gcc -Wno-packed-bitfield-compat dummy.c
run_gcc -Wno-pedantic-ms-format dummy.c
run_gcc -Wno-pmf-conversions dummy.c
run_gcc -Wno-return-local-addr dummy.c
run_gcc -Wno-sized-deallocation dummy.c
run_gcc -Wno-strict-null-sentinel dummy.c
run_gcc -Wno-suggest-attribute=const dummy.c
run_gcc -Wno-suggest-attribute=format dummy.c
run_gcc -Wno-suggest-attribute=noreturn dummy.c
run_gcc -Wno-suggest-attribute=pure dummy.c
run_gcc -Wno-suggest-final-methods dummy.c
run_gcc -Wno-suggest-final-types dummy.c
run_gcc -Wno-sync-nand dummy.c
run_gcc -Wno-traditional dummy.c
run_gcc -Wno-traditional-conversion dummy.c
run_gcc -Wno-trampolines dummy.c
run_gcc -Wno-unsafe-loop-optimizations dummy.c
run_gcc -Wno-unused-but-set-parameter dummy.c
run_gcc -Wno-unused-but-set-variable dummy.c
run_gcc -Wno-useless-cast dummy.c
run_gcc -Wno-vector-operation-performance dummy.c
run_gcc -Wno-virtual-move-assign dummy.c
run_gcc -Wno-zero-as-null-pointer-constant dummy.c
run_gcc -Wnoexcept dummy.c
run_gcc -Wnon-template-friend dummy.c
run_gcc -Wnormalized dummy.c
run_gcc -Wnormalized=none dummy.c
run_gcc -Wnormalized=id dummy.c
run_gcc -Wnormalized=nfc dummy.c
run_gcc -Wnormalized=nfkc dummy.c
run_gcc -Wold-style-declaration dummy.c
run_gcc -Wopenmp-simd dummy.c
run_gcc -Woverride-init dummy.c
run_gcc -Wpacked-bitfield-compat dummy.c
run_gcc -Wpmf-conversions dummy.c
run_gcc -Wreturn-local-addr dummy.c
run_gcc -Wsized-deallocation dummy.c
run_gcc -Wstack-usage=128 dummy.c
run_gcc -Wstrict-aliasing=3 dummy.c
run_gcc -Wstrict-null-sentinel dummy.c
run_gcc -Wsuggest-attribute=const dummy.c
run_gcc -Wsuggest-attribute=format dummy.c
run_gcc -Wsuggest-attribute=noreturn dummy.c
run_gcc -Wsuggest-attribute=pure dummy.c
run_gcc -Wsuggest-final-methods dummy.c
run_gcc -Wsuggest-final-types dummy.c
run_gcc -Wsync-nand dummy.c
run_gcc -Wtraditional dummy.c
run_gcc -Wtraditional-conversion dummy.c
run_gcc -Wtrampolines dummy.c
run_gcc -Wunsafe-loop-optimizations dummy.c
run_gcc -Wunsuffixed-float-constants dummy.c
run_gcc -Wunused-but-set-parameter dummy.c
run_gcc -Wunused-but-set-variable dummy.c
run_gcc -Wuseless-cast dummy.c
run_gcc -Wvector-operation-performance dummy.c
run_gcc -Wvirtual-move-assign dummy.c
run_gcc -Wzero-as-null-pointer-constant dummy.c

# Options claimed by clang --help, but which in fact are not supported.
run_gcc -time dummy.c

# Options which should not work on either compiler

echo
logcon "Testing options for neither GCC nor LLVM"

# Options for both compilers for some targets

# Options which are only for specific targets or systems
run_neither -fauto-profile dummy.c
run_neither -fcheck-pointer-bounds dummy.c
run_dummy -fchkp-check-incomplete-type dummy.c # Meaningless
run_dummy -fchkp-check-read dummy.c # Meaningless
run_dummy -fchkp-check-write dummy.c # Meaningless
run_dummy -fchkp-first-field-has-own-bounds dummy.c # Meaningless
run_dummy -fchkp-instrument-calls dummy.c # Meaningless
run_dummy -fchkp-instrument-marked-only dummy.c # Meaningless
run_dummy -fchkp-narrow-bounds dummy.c # Meaningless
run_dummy -fchkp-narrow-to-innermost-array dummy.c
run_dummy -fchkp-optimize dummy.c # Meaningless
run_dummy -fchkp-store-bounds dummy.c # Meaningless
run_dummy -fchkp-treat-zero-dynamic-size-as-infinite dummy.c # Meaningless
run_dummy -fchkp-use-fast-string-functions dummy.c # Meaningless
run_dummy -fchkp-use-nochk-string-functions dummy.c # Meaningless
run_dummy -fchkp-use-static-bounds dummy.c # Meaningless
run_dummy -fchkp-use-static-const-bounds dummy.c # Meaningless
run_dummy -fchkp-use-wrappers dummy.c # Meaningless
run_neither -ffix-and-continue dummy.c
run_neither -findirect-data dummy.c
run_neither -fno-keep-inline-dllexport dummy.c
run_neither -gcoff dummy.c
run_neither -gcoff1 dummy.c
run_neither -gcoff2 dummy.c
run_neither -gcoff3 dummy.c
run_neither -gvms dummy.c
run_neither -gvms1 dummy.c
run_neither -gvms2 dummy.c
run_neither -gvms3 dummy.c
run_neither -gxcoff dummy.c
run_neither -gxcoff1 dummy.c
run_neither -gxcoff2 dummy.c
run_neither -gxcoff3 dummy.c
run_neither -gxcoff+ dummy.c
run_neither -gz dummy.c
run_neither -gz=none dummy.c
run_neither -gz=zlib dummy.c
run_neither -gz=zlib-gnu dummy.c
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
run_neither -read_only_relocs dummy.c # Darwin
run_neither -sectalign dummy.c # Darwin
run_neither -sectcreate dummy.c # Darwin
run_neither -sectobjectsymbols dummy.c # Darwin
run_neither -sectorder dummy.c # Darwin
run_neither -seg_addr_table dummy.c # Darwin
run_neither -seg_addr_table_filename dummy.c # Darwin
run_neither -seg1addr dummy.c # Darwin
run_neither -segaddr dummy.c # Darwin
run_neither -seglinkedit dummy.c # Darwin
run_neither -segprot dummy.c # Darwin
run_neither -segs_read_only_addr dummy.c # Darwin
run_neither -segs_read_write_addr dummy.c # Darwin
run_neither -single_module dummy.c # Darwin
run_neither -sub_library dummy.c # Darwin
run_neither -sub_umbrella dummy.c # Darwin
run_neither -symbolic dummy.c
run_neither -twolevel_namespace dummy.c # Darwin
run_neither -Waddr-space-convert dummy.c
run_neither -weak_reference_mismatches dummy.c # Darwin
run_neither -whatsloaded dummy.c # Darwin
run_neither -whyload dummy.c # Darwin
run_neither -Wpedantic-ms-format dummy.c
run_neither wrapper dummy.c # Darwin

# Options for the future (done as dummy, since may work sometimes now)
run_dummy -x cpp-output dummy-preproc.i
run_dummy -x c++ dummy.c
run_dummy -x c++-header dummy.c
run_dummy -x c++-cpp-output dummy-preproc.i
run_dummy -x ada dummy.c
run_dummy -x f77 dummy.c
run_dummy -x f77-cpp-input dummy.c
run_dummy -x f95 dummy.c
run_dummy -x f95-cpp-input dummy.c
run_dummy -x go dummy.c
run_dummy -x java dummy.c

# Options which are in the manual, but which appear not to work.
run_neither -fdump-rtl-bypass dummy.c
run_neither -fdump-rtl-dce dummy.c
run_neither -fdump-rtl-dce1 dummy.c
run_neither -fdump-rtl-dce2 dummy.c
run_neither -fdump-rtl-eh dummy.c
run_neither -fdump-rtl-gcse1 dummy.c
run_neither -fdump-rtl-initvals dummy.c
run_neither -fdump-rtl-pass dummy.c
run_neither -fdump-rtl-regclass dummy.c
run_neither -fdump-rtl-seqabstr dummy.c
run_neither -fdump-rtl-sibling dummy.c
run_neither -fdump-rtl-subregs_of_mode_finish dummy.c
run_neither -fdump-rtl-subregs_of_mode_init dummy.c
run_neither -fdump-rtl-unshare dummy.c
run_neither -fdump-tree-storeccp dummy.c
run_neither -femit-struct-debug-detailed dummy.c # Needs arg
run_neither -fsel-sched-dump-cfg dummy.c # In summary only
run_neither -fsel-sched-pipelining-verbose dummy.c # In summary only
run_neither -fsel-sched-verbose dummy.c # In summary only
run_neither -fshort-double dummy.c # ICE
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
run_neither -version dummy.c

# C++ specific. Done as dummy, since some may silently work with C
run_dummy -fdeclone-ctor-dtor dummy.c
run_dummy -fdeduce-init-list dummy.c
run_dummy -fdevirtualize dummy.c
run_dummy -fdevirtualize-at-ltrans dummy.c
run_dummy -fdevirtualize-speculatively dummy.c
run_dummy -fdump-class-hierarchy dummy.c
run_dummy -fdump-class-hierarchy=address dummy.c
run_dummy -fdump-class-hierarchy=asmname dummy.c
run_dummy -fdump-class-hierarchy=slim dummy.c
run_dummy -fdump-class-hierarchy=raw dummy.c
run_dummy -fdump-class-hierarchy=details dummy.c
run_dummy -fdump-class-hierarchy=stats dummy.c
run_dummy -fdump-class-hierarchy=blocks dummy.c
run_dummy -fdump-class-hierarchy=graph dummy.c
run_dummy -fdump-class-hierarchy=vops dummy.c
run_dummy -fdump-class-hierarchy=lineno dummy.c
run_dummy -fdump-class-hierarchy=uid dummy.c
run_dummy -fdump-class-hierarchy=verbose dummy.c
run_dummy -fdump-class-hierarchy=eh dummy.c
run_dummy -fdump-class-hierarchy=scev dummy.c
run_dummy -fdump-class-hierarchy=optimized dummy.c
run_dummy -fdump-class-hierarchy=missed dummy.c
run_dummy -fdump-class-hierarchy=note dummy.c
run_dummy -fdump-class-hierarchy=debug.dump dummy.c
run_dummy -fdump-class-hierarchy=all dummy.c
run_dummy -fdump-class-hierarchy=optall dummy.c
run_dummy -fdump-translation-unit dummy.c
run_dummy -fdump-translation-unit=all dummy.c
run_dummy -femit-class-debug-always dummy.c
run_dummy -fextern-tls-init dummy.c
run_dummy -ffor-scope dummy.c
run_dummy -ffriend-injection dummy.c
run_dummy -fno-default-inline dummy.c
run_dummy -fno-enforce-eh-specs dummy.c
run_dummy -fno-ext-numeric-literals dummy.c
run_dummy -fno-lifetime-dse dummy.c
run_dummy -fno-rtti dummy.c
run_dummy -fsized-deallocation dummy.c
run_dummy -ftemplate-backtrace-limit=5 dummy.c
run_dummy -ftemplate-depth=5 dummy.c
run_dummy -fvtable-verify=preinit dummy.c
run_dummy -fvtv-counts dummy.c
run_dummy -fvtv-debug dummy.c
run_dummy -imultilib custom dummy.c
run_dummy -std=c++98 dummy.c
run_dummy -std=c++03 dummy.c
run_dummy -std=gnu++98 dummy.c
run_dummy -std=gnu++03 dummy.c
run_dummy -std=c++11 dummy.c
run_dummy -std=c++0x dummy.c
run_dummy -std=gnu++11 dummy.c
run_dummy -std=gnu++0x dummy.c
run_dummy -std=c++14 dummy.c
run_dummy -std=c++1y dummy.c
run_dummy -std=gnu++14 dummy.c
run_dummy -std=gnu++1y dummy.c
run_dummy -std=c++1z dummy.c
run_dummy -std=gnu++1z dummy.c

# Objective C specific
run_dummy -fconstant-string-class dummy.c
run_dummy -fnext-runtime dummy.c
run_dummy -fno-local-ivars dummy.c
run_dummy -fno-nil-receivers dummy.c
run_dummy -fobjc-abi-version dummy.c
run_dummy -fobjc-call-cxx-cdtors dummy.c
run_dummy -fobjc-direct-dispatch dummy.c
run_dummy -fobjc-exceptions dummy.c
run_dummy -fobjc-gc dummy.c
run_dummy -fobjc-nilcheck dummy.c
run_dummy -fobjc-std=objc1 dummy.c
run_dummy -gen-decls dummy.c
run_dummy -lobjc dummy.c
run_dummy -print-objc-runtime-info dummy.c
run_dummy -x objective-c dummy.c
run_dummy -x objective-c-header dummy.c
run_dummy -x objective-c-cpp-output dummy-preproc.i
run_dummy -x objective-c++ dummy.c
run_dummy -x objective-c++-header dummy.c
run_dummy -x objective-c++-cpp-output dummy-preproc.i

# Ada specific
run_dummy -fdump-ada-spec dummy.c

# Go specific
run_dummy -fdump-go-spec dummy.c

# Tidy up
tidyup
