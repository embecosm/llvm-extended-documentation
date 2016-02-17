#!/bin/sh
# Check options compile OK for LLVM and GCC

# Copyright (C) 2015 Embecosm Limited

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

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

# The ordering of tests in this file now follows the sequence in the GCC/LLVM
# user guides, for ease of translating into documentation.

LCC=clang
GCC=gcc
tmpfl=/tmp/opt-check-llvm-$$
tmpfg=/tmp/opt-check-gcc-$$
tmpf=/tmp/opt-check-file-$$
tmpd=/tmp/opt-check-dir-$$
touch ${tmpfl} ${tmpfg} ${tmpf}
rm -rf ${tmpd}
mkdir -p ${tmpd}

ALLOPTS="address-asmname-slim-raw-details-stats-blocks-graph-vops-lineno-uid-verbose-eh-scev-optimized-missed-note"

# Tidy up

# For the record, these are the files that may appear in each directory:
# - a.out
# - dummy
# - proto.dat time.dat
# - dummy-deps dummy.gkd
# - *.o* *.bc *.gch *.d *.i *.dwo
# - dummy.bc dummy.c.* dummy.d dummy.g* dummy.i dummy.s dummy.su
# - *.a *.so
# - ${tmpfl} ${tmpfg}
#
# And the following from dumps
# - address all asmname blocks debug.dump details dummy_c.ads eh graph
# - lineno missed note optall optimized raw scev slim stats uid verbose
# - vops

tidyup () {
    echo
    logcon "Cleaning up..."
    rm -rf llvm gcc
    # rm -rf ${tmpf} ${tmpd}
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
    cd llvm
    echo "${LCC} $*" >> ${llvmlog}
    if ! ${LCC} $* > ${tmpfl} 2>&1
    then
	res=l
    elif grep -q "argument unused during compilation" ${tmpfl}
    then
	res=l
    elif grep -q "optimization flag .* is not supported" ${tmpfl}
    then
	res=l
    elif grep -q "unknown warning option" ${tmpfl}
    then
	res=l
    else
	res=L
    fi
    cat ${tmpfl} >> ${llvmlog}
    echo -n ${res}
}

# Function to compiler GCC and echo a single character result: "G" for
# succcess "g" for failure.

comp_gcc () {
    cd gcc
    echo "${GCC} $*" >> ${gcclog}
    if ! ${GCC} $* > ${tmpfg} 2>&1
    then
	res=g
    elif grep -1 "warning: cannot find entry symbol" ${tmpfg}
    then
	res=g
    else
	res=G
    fi
    cat ${tmpfg} >> ${gcclog}
    echo -n ${res}
}

# Function to compile LLVM and GCC and return a two character
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

# For debugging - fixed names

gcclog=/tmp/gcclog.txt
rm -f ${gcclog}
touch ${gcclog}

llvmlog=/tmp/llvmlog.txt
rm -f ${llvmlog}
touch ${llvmlog}

# Create and populate build compiler specific directories
rm -rf llvm
mkdir llvm
rm -rf gcc
mkdir gcc

# Useful variables
gccexec=`which gcc`
gccdir=`dirname ${gccexec}`/..
clangexec=`which clang`
clangdir=`dirname ${clangexec}`/..


for d in llvm gcc
do
    cp comms dummy* libcode.c myplugin.c profile-assist.c \
       stack-protect-assist.c wrapper.sh ${d}
    cp dummy.m ${d}/dummy-rw.m
done

# Pre-compile support files

logcon "Precompiling GCC support files..."
cd gcc
${GCC} -c stack-protect-assist.c -o stack-protect-assist-gcc.o \
    >> ${logfile} 2>&1
${GCC} -fPIC -c myplugin.c
${GCC} -shared -o myplugin.so myplugin.o >> ${logfile} 2>&1
${GCC} dummy.h -o dummy.pch
${GCC} -fprofile-generate dummy.c -o dummy # To generate profile files
./dummy
# Sampling profile data is produced in advance, because it nees sudo, but in
# case you need to reproduce it manually:
#
#   $ gcc dummy.c -o dummy
#   $ sudo perf record -e cpu-cycles -b ./dummy
#   $ create_gcov --gcov_version=1 --binary=./dummy --profile=perf.data \
#                 --gcov=dummy.afdo
#
# Just make a copy to the default name
cp dummy.afdo fbdata.afdo
${GCC} -E dummy.c -o dummy-preproc.i
${GCC} -E dummy.cpp -o dummy-preproc.ii
${GCC} -E dummy.m -o dummy-preproc.mi
${GCC} -E dummy.mm -o dummy-preproc.mii
${GCC} -c libcode.c
ar rcs libcode.a libcode.o
cd ..

logit ""
logcon "Precompiling LLVM support files..."
cd llvm
${LCC} -c stack-protect-assist.c -o stack-protect-assist-llvm.o \
    >> ${logfile} 2>&1
${LCC} -fPIC -c myplugin.c
${LCC} -shared -o myplugin.so myplugin.o >> ${logfile} 2>&1
${LCC} -fprofile-generate dummy.c -o dummy # To generate profile files
./dummy
# Generate instrumentation profile data
${LCC} -fprofile-instr-generate dummy.c -o dummy
./dummy
llvm-profdata merge -o default.profdata default.profraw
cp default.profdata dummy.profdata
# Sampling data is produced in advance, because it needs sudo but in case you
# need to reproduce it manually:
#
#   ${LCC} -gline-tables-only dummy.c -o dummy
#   sudo perf record -b ./dummy
#   create_llvm_prof --binary=./dummy --out=dummy-sample.prof
${LCC} dummy.h -o dummy.pch
${LCC} -E dummy.c -o dummy-preproc.i
${LCC} -E dummy.cpp -o dummy-preproc.ii
${LCC} -E dummy.m -o dummy-preproc.mi
${LCC} -E dummy.mm -o dummy-preproc.mii
${LCC} -S -emit-llvm dummy.c
${LCC} -flto -c dummy.c -o dummy-lto.o
${LCC} -c libcode.c
ar rcs libcode.a libcode.o
cd ..


#################################################################################
#                                                                               #
#			       Overall Options                                  #
#                                                                               #
#################################################################################

logcon ""
logcon "Overall options for both LLVM and GCC"

run_both @comms
run_both -### dummy.c
run_both -c dummy.c
run_both -E dummy.c
run_only_gcc -fplugin=`pwd`/gcc/myplugin.so dummy.c
run_only_llvm -fplugin=`pwd`/llvm/myplugin.so dummy.c
run_both --help
run_both -o dummy dummy.c
run_both -pipe dummy.c
run_both -S dummy.c
run_both -v dummy.c
run_both --version
run_both -x assembler -c dummy-asm.S
run_both -x assembler-with-cpp -c dummy-asm.S
run_both -x c dummy.c
run_both -x c-header dummy.c
run_both -x cpp-output dummy-preproc.ii
run_both -x c++ dummy.cpp
run_both -x c++-header dummy.h
run_both -x c++-cpp-output dummy-preproc.ii
run_both -x none dummy.c
run_both -x objective-c -c dummy.m
run_both -x objective-c-header -c dummy.h
run_both -x objective-c-cpp-output -c dummy-preproc.mi
run_both -x objective-c++ -c dummy.mm
run_both -x objective-c++-header -c dummy.h
run_both -x objective-c++-cpp-output -c dummy-preproc.mii
logcon ""

logcon "Overall options for LLVM but not GCC"

run_llvm -fbuild-session-file=${tmpf} dummy.c
run_llvm -fbuild-session-timestamp=1000 dummy.c
run_llvm -emit-ast dummy.c
run_llvm -emit-llvm dummy.c
run_llvm --gcc-toolchain=${gccdir} dummy.c
run_llvm -help
run_llvm -ObjC -c dummy.mm
run_llvm -ObjC++ -c dummy.mm
run_llvm -Qunused-arguments dummy.c
run_llvm -working-directory `pwd`/llvm dummy.c
run_llvm -Xclang -cc1 dummy.c
logcon ""

logcon "Overall options for GCC but not LLVM"

run_gcc -fdump-ada-spec dummy.c
run_gcc -fdump-ada-spec-slim dummy.c
run_gcc -fada-spec-parent=dummy -fdump-ada-spec-slim dummy.c
run_gcc -fdump-go-spec=dummy.go dummy.c
run_gcc -fno-canonical-system-headers dummy.c
run_gcc -fplugin=`pwd`/gcc/myplugin.so -fplugin-arg-myplugin-mykey=myvalue dummy.c
run_gcc --help=optimizers
run_gcc --help=warnings
run_gcc --help=target
run_gcc --help=params
run_gcc --help=c
run_gcc --help=common
run_gcc --help=common,undocumented
run_gcc --help=common,joined
run_gcc --help=common,separate
run_gcc -pass-exit-codes dummy.c
run_gcc -specs=dummy.specs dummy.c
run_dummy --target-help # Currently broken
run_gcc -wrapper `pwd`/gcc/wrapper.sh dummy.c
logcon ""

# Overall options for the future (done as dummy, since may work sometimes now)

run_dummy -x ada dummy.adb
run_dummy -x f77 dummy.F
run_dummy -x f77-cpp-input dummy.f
run_dummy -x f95 dummy.F95
run_dummy -x f95-cpp-input dummy.f95
run_dummy -x go dummy.go
run_dummy -x java dummy.java


#################################################################################
#                                                                               #
#			      C Language Options                                #
#                                                                               #
#################################################################################

logcon ""
logcon "C language options for both LLVM and GCC"

run_both -ansi dummy.c
run_both -ffreestanding dummy.c
run_both -fgnu89-inline dummy.c
run_both -fhosted dummy.c
run_both -flax-vector-conversions dummy.c
run_both -fms-extensions dummy.c
run_both -fno-asm dummy-asm.c
run_both -fno-builtin dummy.c
run_both -fno-builtin-alloca dummy.c
run_both -fno-lax-vector-conversions dummy.c
run_both -fno-signed-char dummy.c
run_both -fopenmp dummy.c
run_both -fsigned-bitfields dummy.c
run_both -fsigned-char dummy.c
run_both -funsigned-bitfields dummy.c
run_both -funsigned-char dummy.c
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
run_both -traditional -E dummy.c
run_both -trigraphs dummy.c
logcon ""

logcon "C language options for LLVM but not GCC"

run_llvm -fblocks dummy.c
run_llvm -fborland-extensions dummy.c
run_llvm -femit-all-decls dummy.c
run_llvm -fms-compatibility dummy.c
run_llvm -fms-compatibility-version=0 dummy.c
run_llvm -fmsc-version=0 dummy.c
run_llvm -fno-gnu-inline-asm dummy.c
run_llvm -fno-spell-checking dummy.c
run_llvm -fpascal-strings dummy.c
run_llvm -funique-section-names dummy.c
run_llvm -fwritable-strings dummy.c
logcon ""

logcon "C language options for GCC but not LLVM"

run_gcc -aux-info proto.dat dummy.c
run_gcc -fallow-parameterless-variadic-functions dummy.c
run_gcc -fcilkplus dummy.c
run_gcc -fgnu-tm dummy.c
run_gcc -fcond-mismatch dummy.c
run_gcc -fno-signed-bitfields dummy.c
run_gcc -fno-unsigned-bitfields dummy.c
run_gcc -fopenacc dummy.c
run_gcc -fopenmp-simd dummy.c
run_gcc -fplan9-extensions dummy.c
run_gcc -fsso-struct=big-endian dummy.c
run_gcc -traditional-cpp dummy.c
run_gcc -Wabi=1 dummy.c  # Also C++/ObjC/ObjC++
logcon ""

# C language options that are documented, but not supported

run_dummy -fallow-single-precision dummy.c  # Is this obsolete?
run_dummy -omptargets=i686-pc-linux-gnu dummy.c # Listed for LLVM


#################################################################################
#                                                                               #
#			     C++ Language Options                               #
#                                                                               #
#################################################################################

logcon ""
logcon "C++ language options for both LLVM and GCC"

run_both -fno-access-control dummy.cpp
run_both -fcheck-new dummy.cpp
run_both -fconstexpr-depth=1024 dummy.cpp
run_both -ffor-scope dummy.cpp
run_both -ffriend-injection dummy.cpp
run_both -fgnu-keywords dummy.c
run_both -fms-extensions dummy.cpp # Also in C
run_both -fno-elide-constructors dummy.cpp
run_both -fno-gnu-keywords dummy.cpp
run_both -fno-implicit-templates dummy.cpp
run_both -fno-implement-inlines dummy.cpp
run_both -fno-operator-names dummy.cpp
run_both -fno-rtti dummy.cpp
run_both -fno-threadsafe-statics dummy.cpp
run_both -fno-use-cxa-atexit dummy.cpp
run_both -fpermissive dummy.cpp
run_both -fsized-deallocation dummy.cpp
run_both -ftemplate-backtrace-limit=5 dummy.cpp
run_both -ftemplate-depth=5 dummy.cpp
run_both -fuse-cxa-atexit dummy.cpp
run_both -fvisibility-inlines-hidden dummy.cpp
run_both -fvisibility-ms-compat dummy.cpp
run_both -nostdinc++ dummy.cpp
run_both -std=c++98 dummy.cpp
run_both -std=c++03 dummy.cpp
run_both -std=gnu++98 dummy.cpp
run_both -std=c++11 dummy.cpp
run_both -std=c++0x dummy.cpp
run_both -std=gnu++11 dummy.cpp
run_both -std=gnu++0x dummy.cpp
run_both -std=c++14 dummy.cpp
run_both -std=c++1y dummy.cpp
run_both -std=gnu++14 dummy.cpp
run_both -std=gnu++1y dummy.cpp
run_both -std=c++1z dummy.cpp
run_both -std=gnu++1z dummy.cpp
run_both -Wabi dummy.cpp
run_both -Wconversion-null dummy.cpp # Also ObjC++
run_both -Wctor-dtor-privacy dummy.cpp
run_both -Wdelete-non-virtual-dtor dummy.cpp
run_both -Weffc++ dummy.cpp
run_both -Wnarrowing dummy.cpp
run_only_llvm -Wno-conversion-null dummy.c
run_only_llvm -Wno-ctor-dtor-privacy dummy.c
run_only_llvm -Wno-delete-non-virtual-dtor dummy.c
run_only_llvm -Wno-effc++ dummy.c
run_only_llvm -Wno-narrowing dummy.c
run_only_llvm -Wno-non-virtual-dtor dummy.c
run_only_llvm -Wno-old-style-cast dummy.c
run_only_llvm -Wno-overloaded-virtual dummy.c
run_only_llvm -Wno-reorder dummy.c
run_only_llvm -Wno-sign-promo dummy.c
run_both -Wnon-virtual-dtor dummy.cpp
run_both -Wold-style-cast dummy.cpp
run_both -Woverloaded-virtual dummy.cpp
run_both -Wreorder dummy.cpp
run_both -Wsign-promo dummy.cpp
logcon ""

logcon "C++ language options for LLVM but not GCC"

run_llvm -fcxx-exceptions dummy.cpp
run_llvm -fdelayed-template-parsing dummy.cpp
run_llvm -fms-compatibility-version=0 dummy.cpp # Also in C
run_llvm -fms-compatibility dummy.cpp # Also in C
run_llvm -fmsc-version=0 dummy.cpp # Also in C
run_llvm -fno-assume-sane-operator-new dummy.cpp
run_llvm -fshow-overloads=all dummy.cpp
run_llvm -fshow-overloads=best dummy.cpp
logcon ""

logcon "C++ language options for GCC but not LLVM"

run_gcc -fabi-version=2 dummy.cpp
run_gcc -fabi-compat-version=2 -fabi-version=2 dummy.cpp
run_gcc -fdeduce-init-list dummy.cpp
run_gcc -fext-numeric-literals dummy.cpp
run_gcc -fno-enforce-eh-specs dummy.cpp
run_gcc -fno-ext-numeric-literals dummy.cpp
run_gcc -fno-for-scope dummy.cpp
run_gcc -fno-implicit-inline-templates dummy.cpp
run_gcc -fno-nonansi-builtins dummy.cpp
run_gcc -fno-optional-diags dummy.cpp
run_gcc -fno-pretty-templates dummy.c
run_gcc -fno-use-cxa-get-exception-ptr dummy.c
run_gcc -fno-weak dummy.cpp
run_gcc -fnothrow-opt dummy.cpp
run_gcc -frepo dummy.cpp
run_gcc -std=gnu++03 dummy.cpp
run_gcc -Wabi=2 dummy.cpp
run_gcc -Wabi-tag dummy.cpp # Also ObjC++
run_gcc -Wliteral-suffix dummy.cpp
run_gcc -Wmultiple-inheritance dummy.cpp
run_gcc -Wnamespaces dummy.cpp
run_gcc -Wno-literal-suffix dummy.c
run_gcc -Wno-noexcept dummy.c
run_gcc -Wno-non-template-friend dummy.c
run_gcc -Wno-pmf-conversions dummy.c
run_gcc -Wno-terminate dummy.cpp
run_gcc -Wnoexcept dummy.cpp
run_gcc -Wnon-template-friend dummy.c
run_gcc -Wpmf-conversions dummy.c
run_gcc -Wstrict-null-sentinel dummy.cpp
run_gcc -Wtemplates dummy.cpp
run_gcc -Wvirtual-inheritance dummy.cpp
run_gcc -Wterminate dummy.cpp
logcon ""


#################################################################################
#                                                                               #
#		Objective-C and Objective-C++ Language Options                  #
#                                                                               #
#################################################################################

logcon ""
logcon "ObjC and ObjC++ language options for both LLVM and GCC"

run_both -fconstant-string-class=main -c dummy.m
run_both -fgnu-runtime -c dummy.m
run_both -fnext-runtime -c dummy.m
run_both -fobjc-abi-version=1 -c dummy.m
run_both -fobjc-call-cxx-cdtors -c dummy.m
run_both -fobjc-exceptions -c dummy.m
run_both -fobjc-gc -c dummy.m
run_both -objcmt-atomic-property -c dummy.m
run_both -objcmt-migrate-all -c dummy.m
run_both -objcmt-migrate-annotation -c dummy.m
run_both -objcmt-migrate-designated-init -c dummy.m
run_both -objcmt-migrate-instancetype -c dummy.m
run_both -objcmt-migrate-literals -c dummy.m
run_both -objcmt-migrate-ns-macros -c dummy.m
run_both -objcmt-migrate-property-dot-syntax -c dummy.m
run_both -objcmt-migrate-property -c dummy.m
run_both -objcmt-migrate-protocol-conformance -c dummy.m
run_both -objcmt-migrate-readonly-property -c dummy.m
run_both -objcmt-migrate-readwrite-property -c dummy.m
run_both -objcmt-migrate-subscripting -c dummy.m
run_both -objcmt-ns-nonatomic-iosonly -c dummy.m
run_both -objcmt-returns-innerpointer-property -c dummy.m
run_only_llvm -Wno-protocol -c dummy.m
run_only_llvm -Wno-strict-selector-match -c dummy.m
run_only_llvm -Wno-selector -c dummy.m
run_only_llvm -Wno-undeclared-selector dummy.c
run_both -Wprotocol dummy.m
run_both -Wselector -c dummy.m
run_both -Wstrict-selector-match -c dummy.m
run_both -Wundeclared-selector -c dummy.m
logcon ""

logcon "ObjC and ObjC++ language options for LLVM but not GCC"
run_llvm -fno-constant-cfstrings -c dummy.m
run_llvm -fobjc-arc -fnext-runtime -c dummy.m
run_llvm -fobjc-arc-exceptions -fobjc-arc -fnext-runtime -c dummy.m
run_llvm -fobjc-gc-only -c dummy.m
run_llvm -fobjc-runtime=macosx -c dummy.m
run_llvm -fobjc-runtime=macosx-fragile -c dummy.m
run_llvm -fobjc-runtime=ios -c dummy.m
run_llvm -fobjc-runtime=gnustep -c dummy.m
run_llvm -fobjc-runtime=gcc -c dummy.m
run_llvm -objcmt-whitelist-dir-path=`pwd`/llvm -c dummy.m
run_llvm -rewrite-legacy-objc -c dummy-rw.m # Will generate C file
run_llvm -rewrite-objc -c dummy-rw.m
logcon ""

logcon "ObjC and ObjC++ language options for GCC but not LLVM"
run_gcc -fextern-tls-init dummy.cpp
run_gcc -fivar-visibility=public -c dummy.m
run_gcc -fivar-visibility=protected -c dummy.m
run_gcc -fivar-visibility=private -c dummy.m
run_gcc -fivar-visibility=package -c dummy.m
run_gcc -flocal-ivars -c dummy.m
run_gcc -fno-default-inline dummy.cpp
run_gcc -fno-extern-tls-init dummy.cpp
run_gcc -fno-lifetime-dse dummy.cpp
run_gcc -fno-nil-receivers -c dummy.m
run_gcc -fobjc-direct-dispatch -c dummy.m
run_gcc -fobjc-nilcheck -c dummy.m
run_gcc -fobjc-std=objc1 -c dummy.m
run_gcc -fno-local-ivars -c dummy.m
run_gcc -freplace-objc-classes -c dummy.m
run_gcc -fzero-link -c dummy.m
run_gcc -gen-decls -c dummy.m
run_gcc -print-objc-runtime-info -c dummy.m
run_gcc -Wassign-intercept -c dummy.m
run_gcc -Wno-sized-deallocation dummy.cpp C++/OjbC++ only
run_gcc -Wsized-deallocation dummy.cpp C++/OjbC++ only
logcon ""

# Don't work here

run_dummy -fno-objc-infer-related-result-type -c dummy.m # In clang --help

#################################################################################
#                                                                               #
#		    Diagnostic Message Formatting Options                       #
#                                                                               #
#################################################################################

logcon ""
logcon "Diagnostic message formatting options for both LLVM and GCC"

run_both -fdiagnostics-color dummy.c
run_both -fdiagnostics-color=always dummy.c
run_both -fdiagnostics-color=auto dummy.c
run_both -fdiagnostics-color=never dummy.c
run_both -fdiagnostics-show-location=every-line dummy.c
run_both -fdiagnostics-show-location=once dummy.c
run_both -fdiagnostics-show-option dummy.c
run_both -fmessage-length=40 dummy.c
run_both -fno-diagnostics-show-option dummy.c
logcon ""

logcon "Diagnostic message formatting options for LLVM but not GCC"

run_llvm -fansi-escape-codes dummy.c
run_llvm -fcolor-diagnostics dummy.c
run_llvm -fdiagnostics-parseable-fixits dummy.c
run_llvm -fdiagnostics-print-source-range-info dummy.c
run_llvm -fdiagnostics-show-note-include-stack dummy.c
run_llvm -fdiagnostics-show-template-tree dummy.c
run_llvm -fno-diagnostics-fixit-info dummy.c
run_llvm -fno-elide-type dummy.c
run_llvm -fno-show-source-location dummy.c
run_llvm -serialize-diagnostics ${tmpf} dummy.c
logcon ""

logcon "Diagnostic message formatting options for GCC but not LLVM"

run_gcc -fdiagnostics-show-caret dummy.c
run_gcc -fno-diagnostics-show-caret dummy.c
logcon ""


#################################################################################
#                                                                               #
#			       Warning Options                                  #
#                                                                               #
#################################################################################

logcon ""
logcon "Warning options for both LLVM and GCC"

# Generic control of warnings
run_both -fsyntax-only dummy.c
run_both -pedantic dummy.c
run_both -pedantic-errors dummy.c
run_both -w dummy.c
run_both -Wall dummy.c
run_both -Werror dummy.c
run_both -Werror=abi dummy.c
run_both -Wextra dummy.c
run_both -Wfatal-errors dummy.c
run_only_llvm -Wno-all dummy.c
run_only_llvm -Wno-error dummy.c
run_only_llvm -Wno-error=abi dummy.c
run_only_llvm -Wno-extra dummy.c
run_only_llvm -Wno-fatal-errors dummy.c
run_both -Wpedantic dummy.c
# Specific warnings
run_both -Waddress dummy.c
run_both -Waggregate-return dummy.c
run_both -Warray-bounds dummy.c
run_both -Wattributes dummy.c
run_both -Wbuiltin-macro-redefined dummy.c
run_both -Wc++-compat dummy.c
run_both -Wc++0x-compat dummy.cpp
run_both -Wc++11-compat dummy.cpp
run_both -Wc++14-compat dummy.cpp
run_both -Wcast-align dummy.c
run_both -Wcast-qual dummy.c
run_both -Wchar-subscripts dummy.c
run_both -Wcomment dummy.c
run_both -Wcomments dummy.c
run_both -Wconversion dummy.c
run_both -Wdate-time dummy.c
run_both -Wdelete-incomplete dummy.c
run_both -Wdeprecated dummy.c
run_both -Wdeprecated-declarations dummy.c
run_both -Wdisabled-optimization dummy.c
run_both -Wdiv-by-zero dummy.c
run_both -Wdouble-promotion dummy.c
run_both -Wempty-body dummy.c
run_both -Wendif-labels dummy.c
run_both -Wenum-compare dummy.c
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
run_both -Wimport -c dummy.m
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
run_both -Wmissing-field-initializers dummy.c
run_both -Wmissing-format-attribute dummy.c
run_both -Wmissing-include-dirs dummy.c
run_both -Wmissing-noreturn dummy.c # Deprecated - not documented.
run_both -Wmultichar dummy.c
# GCC will always accept negatives, so all we can check here is that LLVM
# (which is pickier) accepts them. We separately test the positives of all
# these.
run_only_llvm -Wno-address dummy.c
run_only_llvm -Wno-aggregate-return dummy.c
run_only_llvm -Wno-array-bounds dummy.c
run_only_llvm -Wno-attributes dummy.c
run_only_llvm -Wno-builtin-macro-redefined dummy.c
run_only_llvm -Wno-cast-align dummy.c
run_only_llvm -Wno-cast-qual dummy.c
run_only_llvm -Wno-char-subscripts dummy.c
run_only_llvm -Wno-comment dummy.c
run_only_llvm -Wno-conversion dummy.c
run_only_llvm -Wno-date-time dummy.c
run_only_llvm -Wno-delete-incomplete dummy.c
run_only_llvm -Wno-deprecated dummy.c
run_only_llvm -Wno-deprecated-declarations dummy.c
run_only_llvm -Wno-disabled-optimization dummy.c
run_only_llvm -Wno-div-by-zero dummy.c
run_only_llvm -Wno-double-promotion dummy.c
run_only_llvm -Wno-empty-body dummy.c
run_only_llvm -Wno-endif-labels dummy.c
run_only_llvm -Wno-enum-compare dummy.c
run_only_llvm -Wno-float-conversion dummy.c
run_only_llvm -Wno-float-equal dummy.c
run_only_llvm -Wno-format dummy.c
run_only_llvm -Wno-format-extra-args dummy.c
run_only_llvm -Wno-format-nonliteral dummy.c
run_only_llvm -Wno-format-security dummy.c
run_only_llvm -Wno-format-y2k dummy.c
run_only_llvm -Wno-format-zero-length dummy.c
run_only_llvm -Wno-ignored-qualifiers dummy.c
run_only_llvm -Wno-implicit dummy.c
run_only_llvm -Wno-implicit-function-declaration dummy.c
run_only_llvm -Wno-implicit-int dummy.c
run_only_llvm -Wno-incompatible-pointer-types dummy.c
run_only_llvm -Wno-inherited-variadic-ctor dummy.c # C++/ObjC++ only
run_only_llvm -Wno-init-self dummy.c
run_only_llvm -Wno-inline dummy.c
run_only_llvm -Wno-int-conversion dummy.c
run_only_llvm -Wno-int-to-pointer-cast dummy.c
run_only_llvm -Wno-invalid-offsetof dummy.c
run_only_llvm -Wno-invalid-pch dummy.c
run_only_llvm -Wno-logical-not-parentheses dummy.c
run_only_llvm -Wno-long-long dummy.c
run_only_llvm -Wno-main dummy.c
run_only_llvm -Wno-missing-braces dummy.c
run_only_llvm -Wno-missing-field-initializers dummy.c
run_only_llvm -Wno-missing-format-attribute dummy.c
run_only_llvm -Wno-missing-include-dirs dummy.c
run_only_llvm -Wno-multichar dummy.c
run_only_llvm -Wno-nonnull dummy.c
run_only_llvm -Wno-null-dereference dummy.c
run_only_llvm -Wno-odr dummy.c
run_only_llvm -Wno-overflow dummy.c
run_only_llvm -Wno-overlength-strings dummy.c
run_only_llvm -Wno-packed dummy.c
run_only_llvm -Wno-padded dummy.c
run_only_llvm -Wno-parentheses dummy.c
run_only_llvm -Wno-pointer-arith dummy.c
run_only_llvm -Wno-pointer-to-int-cast dummy.c
run_only_llvm -Wno-pragmas dummy.c
run_only_llvm -Wno-redundant-decls dummy.c
run_only_llvm -Wno-return-type dummy.c
run_only_llvm -Wno-sequence-point dummy.c
run_only_llvm -Wno-shadow dummy.c
run_only_llvm -Wno-shadow-ivar dummy.c
run_only_llvm -Wno-shift-count-negative dummy.c
run_only_llvm -Wno-shift-count-overflow dummy.c
run_only_llvm -Wno-sign-compare dummy.c
run_only_llvm -Wno-sign-conversion dummy.c
run_only_llvm -Wno-sizeof-array-argument dummy.c
run_only_llvm -Wno-sizeof-pointer-memaccess dummy.c
run_only_llvm -Wno-shift-negative-value dummy.c
run_only_llvm -Wno-shift-overflow dummy.c
run_only_llvm -Wno-stack-protector dummy.c
run_only_llvm -Wno-strict-aliasing dummy.c
run_only_llvm -Wno-strict-overflow dummy.c
run_only_llvm -Wno-switch dummy.c
run_only_llvm -Wno-switch-bool dummy.c
run_only_llvm -Wno-switch-default dummy.c
run_only_llvm -Wno-switch-enum dummy.c
run_only_llvm -Wno-system-headers dummy.c
run_only_llvm -Wno-tautological-compare dummy.c
run_only_llvm -Wno-trigraphs dummy.c
run_only_llvm -Wno-type-limits dummy.c
run_only_llvm -Wno-undef dummy.c
run_only_llvm -Wno-uninitialized dummy.c
run_only_llvm -Wno-unknown-pragmas dummy.c
run_only_llvm -Wno-unused dummy.c
run_only_llvm -Wno-unused-const-variable dummy.cpp
run_only_llvm -Wno-unused-function dummy.c
run_only_llvm -Wno-unused-label dummy.c
run_only_llvm -Wno-unused-parameter dummy.c
run_only_llvm -Wno-unused-result dummy.c
run_only_llvm -Wno-unused-value dummy.c
run_only_llvm -Wno-unused-variable dummy.c
run_only_llvm -Wno-varargs dummy.c
run_only_llvm -Wno-variadic-macros dummy.c
run_only_llvm -Wno-vla dummy.c
run_only_llvm -Wno-volatile-register-var dummy.c
run_only_llvm -Wno-write-strings dummy.c
# Back to positives
run_both -Wnonnull dummy.c
run_both -Wnull-dereference dummy.c
run_both -Wodr dummy.c
run_both -Woverflow dummy.c
run_both -Woverlength-strings dummy.c
run_both -Wpacked dummy.c
run_both -Wpadded dummy.c
run_both -Wparentheses dummy.c
run_both -Wpointer-arith dummy.c
run_both -Wpointer-to-int-cast dummy.c
run_both -Wpragmas dummy.c
run_both -Wredundant-decls dummy.c
run_both -Wreturn-type dummy.c
run_both -Wsequence-point dummy.c
run_both -Wshadow dummy.c
run_both -Wshadow-ivar dummy.c
run_both -Wshift-count-negative dummy.c
run_both -Wshift-overflow dummy.c
run_both -Wshift-negative-value dummy.c
run_both -Wshift-count-overflow dummy.c
run_both -Wsign-compare dummy.c
run_both -Wsign-conversion dummy.c
run_both -Wsizeof-array-argument dummy.c
run_both -Wsizeof-pointer-memaccess dummy.c
run_both -Wstack-protector dummy.c
run_both -Wstrict-aliasing dummy.c
run_both -Wstrict-aliasing=0 dummy.c
run_both -Wstrict-aliasing=1 dummy.c
run_both -Wstrict-aliasing=2 dummy.c
run_both -Wstrict-overflow dummy.c
run_both -Wstrict-overflow=0 dummy.c
run_both -Wstrict-overflow=1 dummy.c
run_both -Wstrict-overflow=2 dummy.c
run_both -Wstrict-overflow=3 dummy.c
run_both -Wstrict-overflow=4 dummy.c
run_both -Wstrict-overflow=5 dummy.c
run_both -Wswitch dummy.c
run_both -Wswitch-bool dummy.c
run_both -Wswitch-default dummy.c
run_both -Wswitch-enum dummy.c
run_both -Wsynth dummy.c
run_both -Wsystem-headers dummy.c
run_both -Wtautological-compare dummy.c
run_both -Wtrigraphs dummy.c
run_both -Wtype-limits dummy.c
run_both -Wundef dummy.c
run_both -Wuninitialized dummy.c
run_both -Wunknown-pragmas dummy.c
run_both -Wunreachable-code dummy.c
run_both -Wunused dummy.c
run_both -Wunused-argument dummy.c
run_both -Wunused-const-variable dummy.cpp
run_both -Wunused-function dummy.c
run_both -Wunused-label dummy.c
run_both -Wunused-local-typedefs dummy.c
run_both -Wunused-macros dummy.c # Pre-processor only
run_both -Wunused-parameter dummy.c
run_both -Wunused-result dummy.c
run_both -Wunused-value dummy.c
run_both -Wunused-variable dummy.c
run_both -Wvarargs dummy.c
run_both -Wvariadic-macros dummy.c
run_both -Wvla dummy.c
run_both -Wvolatile-register-var dummy.c
run_both -Wwrite-strings dummy.c
logcon ""

logcon "Warning options for LLVM but not GCC"

# Generic control of warnings
run_llvm -Weverything dummy.c
# Specific warnings
run_llvm -Wabstract-final-class dummy.cpp # Default.
run_llvm -Wabstract-vbase-init dummy.cpp
run_llvm -Waddress-of-array-temporary dummy.c
run_llvm -Waddress-of-temporary dummy.c
run_llvm -Wambiguous-macro dummy.c
run_llvm -Wambiguous-member-template dummy.c
run_llvm -Wanalyzer-incompatible-plugin dummy.c
run_llvm -Wanonymous-pack-parens dummy.c
run_llvm -Warc-bridge-casts-disallowed-in-nonarc -c dummy.m
run_llvm -Warc -c dummy.m
run_llvm -Warc-maybe-repeated-use-of-weak -c dummy.m
run_llvm -Warc-non-pod-memaccess -c dummy.m
run_llvm -Warc-performSelector-leaks -c dummy.m
run_llvm -Warc-repeated-use-of-weak -c dummy.m
run_llvm -Warc-retain-cycles -c dummy.m
run_llvm -Warc-unsafe-retained-assign -c dummy.m
run_llvm -Warray-bounds-pointer-arithmetic dummy.c
run_llvm -Wasm dummy.c
run_llvm -Wasm-operand-widths dummy.c
run_llvm -Wassign-enum dummy.c # Default
run_llvm -Watomic-properties dummy.c
run_llvm -Watomic-property-with-user-defined-accessor dummy.c
run_llvm -Wauto-import dummy.c # The default
run_llvm -Wauto-storage-class dummy.c # Default
run_llvm -Wauto-var-id dummy.c
run_llvm -Wavailability dummy.c
run_llvm -Wbackslash-newline-escape dummy.c
run_llvm -Wbad-array-new-length dummy.c
run_llvm -Wbind-to-temporary-copy dummy.c
run_llvm -Wbitfield-constant-conversion dummy.c
run_llvm -Wbitwise-op-parentheses dummy.c
run_llvm -Wbool-conversion dummy.c
run_llvm -Wbool-conversions dummy.c
run_llvm -Wbridge-cast dummy.c
run_llvm -Wbuiltin-requires-header dummy.c
run_llvm -Wc++0x-extensions dummy.cpp
run_llvm -Wc++0x-narrowing dummy.cpp
run_llvm -Wc++11-compat-pedantic dummy.cpp
run_llvm -Wc++11-compat-reserved-user-defined-literal dummy.cpp
run_llvm -Wc11-extensions dummy.c
run_llvm -Wc++11-extensions dummy.cpp
run_llvm -Wc++11-extra-semi dummy.cpp
run_llvm -Wc++11-long-long dummy.cpp
run_llvm -Wc++11-narrowing dummy.cpp
run_llvm -Wc++1y-extensions dummy.cpp
run_llvm -Wc++98-c++11-compat dummy.cpp
run_llvm -Wc++98-c++11-compat-pedantic dummy.cpp
run_llvm -Wc++98-compat-bind-to-temporary-copy dummy.cpp
run_llvm -Wc++98-compat dummy.cpp
run_llvm -Wc++98-compat-local-type-template-args dummy.cpp
run_llvm -Wc++98-compat-pedantic dummy.cpp
run_llvm -Wc++98-compat-unnamed-type-template-args dummy.cpp
run_llvm -Wc99-compat dummy.c
run_llvm -Wc99-extensions dummy.c # Default
run_llvm -Wcast-of-sel-type dummy.c
run_llvm -WCFString-literal dummy.c
run_llvm -Wchar-align dummy.c
run_llvm -Wcompare-distinct-pointer-types dummy.c
run_llvm -Wcomplex-component-init dummy.c
run_llvm -Wconditional-type-mismatch dummy.c
run_llvm -Wconditional-uninitialized dummy.c
run_llvm -Wconfig-macros dummy.c
run_llvm -Wconstant-conversion dummy.c
run_llvm -Wconstant-logical-operand dummy.c
run_llvm -Wconstexpr-not-const dummy.c
run_llvm -Wconsumed dummy.c
run_llvm -Wcovered-switch-default dummy.c
run_llvm -Wcustom-atomic-properties dummy.c
run_llvm -Wdangling-else dummy.c
run_llvm -Wdangling-field dummy.c
run_llvm -Wdangling-initializer-list dummy.c
run_llvm -Wdelegating-ctor-cycles dummy.c
run_llvm -Wdeprecated-increment-bool dummy.c
run_llvm -Wdeprecated-implementations dummy.c
run_llvm -Wdeprecated-objc-isa-usage -c dummy.m
run_llvm -Wdeprecated-objc-pointer-introspection -c dummy.m
run_llvm -Wdeprecated-objc-pointer-introspection-performSelector -c dummy.m
run_llvm -Wdeprecated-register dummy.c
run_llvm -Wdeprecated-writable-strings dummy.c
run_llvm -Wdirect-ivar-access dummy.c
run_llvm -Wdisabled-macro-expansion dummy.c
run_llvm -Wdiscard-qual dummy.c
run_llvm -Wdistributed-object-modifiers dummy.cpp
run_llvm -Wdivision-by-zero dummy.c
run_llvm -Wdocumentation-deprecated-sync dummy.c
run_llvm -Wdocumentation dummy.c
run_llvm -Wdocumentation-html dummy.c
run_llvm -Wdocumentation-pedantic dummy.c
run_llvm -Wdocumentation-unknown-command dummy.c
run_llvm -Wdollar-in-identifier-extension dummy.c
run_llvm -Wduplicate-decl-specifier dummy.c
run_llvm -Wduplicate-enum dummy.c
run_llvm -Wduplicate-method-arg dummy.c
run_llvm -Wduplicate-method-match dummy.c
run_llvm -Wdynamic-class-memaccess dummy.c
run_llvm -Wembedded-directive dummy.c
run_llvm -Wempty-translation-unit dummy.c
run_llvm -Wenum-conversion dummy.c
run_llvm -Wexit-time-destructors dummy.c
run_llvm -Wexplicit-ownership-type dummy.c
run_llvm -Wextended-offsetof dummy.c
run_llvm -Wextern-c-compat dummy.c
run_llvm -Wextern-initializer dummy.c
run_llvm -Wextra-qualification dummy.c # Default
run_llvm -Wextra-semi dummy.c
run_llvm -Wextra-tokens dummy.c
run_llvm -Wflexible-array-extensions dummy.c
run_llvm -Wformat-invalid-specifier dummy.c
run_llvm -Wformat-non-iso dummy.c
run_llvm -Wformat-pedantic dummy.c
run_llvm -Wfour-char-constants dummy.c
run_llvm -Wgcc-compat dummy.c
run_llvm -Wglobal-constructors dummy.c
run_llvm -Wgnu-array-member-paren-init dummy.c
run_llvm -Wgnu-conditional-omitted-operand dummy.c
run_llvm -Wgnu-designator dummy.c
run_llvm -Wgnu dummy.c
run_llvm -Wgnu-static-float-init dummy.c
run_llvm -Wheader-guard dummy.c
run_llvm -Wheader-hygiene dummy.c
run_llvm -Widiomatic-parentheses dummy.c
run_llvm -Wignored-attributes dummy.c
run_llvm -Wimplicit-atomic-properties dummy.c
run_llvm -Wimplicit-conversion-floating-point-to-bool dummy.c
run_llvm -Wimplicit-exception-spec-mismatch dummy.c
run_llvm -Wimplicit-fallthrough dummy.c
run_llvm -Wimplicit-fallthrough-per-function dummy.c
run_llvm -Wimplicit-retain-self dummy.c
run_llvm -Wimport-preprocessor-directive-pedantic dummy.c
run_llvm -Wincompatible-library-redeclaration dummy.c
run_llvm -Wincompatible-pointer-types-discards-qualifiers dummy.c
run_llvm -Wincomplete-implementation dummy.c
run_llvm -Wincomplete-module dummy.c # Default
run_llvm -Wincomplete-umbrella dummy.c
run_llvm -Winitializer-overrides dummy.c
run_llvm -Wint-conversions dummy.c
run_llvm -Winteger-overflow dummy.c
run_llvm -Wint-to-void-pointer-cast dummy.c # Default
run_llvm -Winvalid-constexpr dummy.c
run_llvm -Winvalid-iboutlet dummy.c
run_llvm -Winvalid-noreturn dummy.c
run_llvm -Winvalid-pp-token dummy.c
run_llvm -Winvalid-source-encoding dummy.c
run_llvm -Winvalid-token-paste dummy.c
run_llvm -Wkeyword-compat dummy.c # Default
run_llvm -Wknr-promoted-parameter dummy.c
run_llvm -Wlanguage-extension-token dummy.c
run_llvm -Wlarge-by-value-copy dummy.c
run_llvm -Wliblto dummy.c # Default
run_llvm -Wliteral-conversion dummy.c # Default
run_llvm -Wliteral-range dummy.c # Default
run_llvm -Wlocal-type-template-args dummy.c
run_llvm -Wlogical-op-parentheses dummy.c
run_llvm -Wloop-analysis dummy.c
run_llvm -Wmain-return-type dummy.c
run_llvm -Wmalformed-warning-check dummy.c
run_llvm -Wmethod-signatures dummy.c
run_llvm -Wmicrosoft dummy.c
run_llvm -Wmicrosoft-exists dummy.c
run_llvm -Wmismatched-parameter-types dummy.c
run_llvm -Wmismatched-return-types dummy.c
run_llvm -Wmismatched-tags dummy.c
run_llvm -Wmissing-method-return-type dummy.c
run_llvm -Wmissing-selector-name dummy.c
run_llvm -Wmissing-sysroot dummy.c
run_llvm -Wmissing-variable-declarations dummy.c
run_llvm -Wmodule-conflict dummy.c
run_llvm -Wmost dummy.c
run_llvm -Wmultiple-move-vbase dummy.c
run_llvm -Wnested-anon-types dummy.c
run_llvm -Wnewline-eof dummy.c
# GCC will always accept any option begining -Wno-
run_only_llvm -Wno-abstract-final-class dummy.c
run_only_llvm -Wno-auto-import dummy.c
run_only_llvm -Wno-assign-enum dummy.c
run_only_llvm -Wno-auto-storage-class dummy.c
run_only_llvm -Wno-c99-compat dummy.c # Default
run_only_llvm -Wno-c99-extensions dummy.c
run_only_llvm -Wno-consumed dummy.c # Default
run_only_llvm -Wno-extra-qualification dummy.c
run_only_llvm -Wno-incomplete-module dummy.c
run_only_llvm -Wno-int-conversions dummy.c # Default
run_only_llvm -Wno-int-to-void-pointer-cast dummy.c
run_only_llvm -Wno-keyword-compat dummy.c
run_only_llvm -Wno-liblto dummy.c
run_only_llvm -Wno-literal-conversion dummy.c
run_only_llvm -Wno-literal-range dummy.c
run_only_llvm -Wno-NSObject-attribute dummy.c # Default
run_only_llvm -Wno-out-of-line-declaration dummy.c
run_only_llvm -Wno-override-module dummy.c
run_only_llvm -Wno-pointer-type-mismatch dummy.c
run_only_llvm -Wno-property-attribute-mismatch dummy.c # Default
run_only_llvm -Wno-return-stack-address dummy.c
run_only_llvm -Wno-unavailable-declarations dummy.c
run_only_llvm -Wno-unsupported-friend dummy.c
# Back to positives
run_llvm -Wnon-gcc dummy.c
run_llvm -Wnon-literal-null-conversion dummy.c
run_llvm -Wnon-pod-varargs dummy.c
run_llvm -Wnonportable-cfstrings dummy.c
run_llvm -WNSObject-attribute dummy.c
run_llvm -Wnull-arithmetic dummy.c
run_llvm -Wnull-character dummy.c
run_llvm -Wnull-conversion dummy.c
run_llvm -Wobjc-autosynthesis-property-ivar-name-match -c dummy.m
run_llvm -Wobjc-cocoa-api -c dummy.m
run_llvm -Wobjc-forward-class-redefinition -c dummy.m
run_llvm -Wobjc-interface-ivars -c dummy.m
run_llvm -Wobjc-literal-compare -c dummy.m
run_llvm -Wobjc-method-access -c dummy.m
run_llvm -Wobjc-missing-property-synthesis -c dummy.m
run_llvm -Wobjc-missing-super-calls -c dummy.m
run_llvm -Wobjc-noncopy-retain-block-property -c dummy.m
run_llvm -Wobjc-nonunified-exceptions -c dummy.m
run_llvm -Wobjc-property-implementation -c dummy.m
run_llvm -Wobjc-property-implicit-mismatch -c dummy.m
run_llvm -Wobjc-property-matches-cocoa-ownership-rule -c dummy.m
run_llvm -Wobjc-property-no-attribute -c dummy.m
run_llvm -Wobjc-string-concatenation -c dummy.m
run_llvm -Wobjc-property-synthesis -c dummy.m
run_llvm -Wobjc-protocol-method-implementation -c dummy.m
run_llvm -Wobjc-protocol-property-synthesis -c dummy.m
run_llvm -Wobjc-readonly-with-setter-property -c dummy.m
run_llvm -Wobjc-redundant-api-use -c dummy.m
run_llvm -Wobjc-redundant-literal-use -c dummy.m
run_llvm -Wobjc-root-class -c dummy.m
run_llvm -Wobjc-string-compare -c dummy.m
run_llvm -Wopenmp-clauses -fopenmp dummy.c
run_llvm -Wout-of-line-declaration dummy.c # Default
run_llvm -Wover-aligned dummy.c
run_llvm -Woverloaded-shift-op-parentheses dummy.c
run_llvm -Woverride-module dummy.c # Default
run_llvm -Woverriding-method-mismatch dummy.c
run_llvm -Wparentheses-equality dummy.c
run_llvm -Wpointer-type-mismatch dummy.c # Default
run_llvm -W\#pragma-messages dummy.c
run_llvm -Wpredefined-identifier-outside-function dummy.c
run_llvm -Wprivate-extern dummy.c
run_llvm -Wproperty-attribute-mismatch dummy.c
run_llvm -Wprotocol-property-synthesis-ambiguity dummy.c
run_llvm -Wreadonly-iboutlet-property dummy.c
run_llvm -Wreceiver-expr -c dummy.m
run_llvm -Wreceiver-forward-class -c dummy.m
run_llvm -Wreceiver-is-weak -c dummy.m
run_llvm -Wreinterpret-base-class dummy.c
run_llvm -Wrequires-super-attribute dummy.c
run_llvm -Wreserved-user-defined-literal dummy.c
run_llvm -Wreturn-stack-address dummy.c # Default
run_llvm -Wreturn-type-c-linkage dummy.c
run_llvm -Wsection dummy.c
run_llvm -Wselector-type-mismatch -c dummy.m
run_llvm -Wself-assign dummy.c
run_llvm -Wself-assign-field dummy.c
run_llvm -Wsemicolon-before-method-body dummy.cpp
run_llvm -Wsentinel dummy.c
run_llvm -Wserialized-diagnostics dummy.c
run_llvm -Wshift-op-parentheses dummy.c
run_llvm -Wshift-sign-overflow dummy.c
run_llvm -Wshorten-64-to-32 dummy.c
run_llvm -Wsizeof-array-decay dummy.c
run_llvm -Wsometimes-uninitialized dummy.c
run_llvm -Wsource-uses-openmp dummy.c
run_llvm -Wstatic-float-init dummy.c
run_llvm -Wstatic-in-inline dummy.c
run_llvm -Wstatic-inline-explicit-instantiation dummy.c
run_llvm -Wstatic-local-in-inline dummy.c
run_llvm -Wstatic-self-init dummy.c
run_llvm -Wstring-compare dummy.c
run_llvm -Wstring-conversion dummy.c
run_llvm -Wstring-plus-char dummy.c
run_llvm -Wstring-plus-int dummy.c
run_llvm -Wstrlcpy-strlcat-size dummy.c
run_llvm -Wstrncat-size dummy.c
run_llvm -Wsuper-class-method-mismatch dummy.c
run_llvm -Wtautological-constant-out-of-range-compare dummy.c
run_llvm -Wtentative-definition-incomplete-type dummy.c
run_llvm -Wthread-safety-analysis dummy.c
run_llvm -Wthread-safety-attributes dummy.c
run_llvm -Wthread-safety-beta dummy.c
run_llvm -Wthread-safety dummy.c
run_llvm -Wthread-safety-precise dummy.c
run_llvm -Wtypedef-redefinition dummy.c
run_llvm -Wtypename-missing dummy.c
run_llvm -Wtype-safety dummy.c
run_llvm -Wunavailable-declarations dummy.c # Default
run_llvm -Wundefined-inline dummy.c
run_llvm -Wundefined-internal dummy.c
run_llvm -Wundefined-reinterpret-cast dummy.c
run_llvm -Wunicode dummy.c
run_llvm -Wunicode-whitespace dummy.c
run_llvm -Wunknown-warning-option dummy.c
run_llvm -Wunnamed-type-template-args dummy.c
run_llvm -Wunneeded-internal-declaration dummy.c
run_llvm -Wunneeded-member-function dummy.c
run_llvm -Wunsequenced dummy.c
run_llvm -Wunsupported-friend dummy.cpp # Default
run_llvm -Wunsupported-visibility dummy.c
run_llvm -Wunused-command-line-argument dummy.c
run_llvm -Wunused-comparison dummy.c
run_llvm -Wunused-exception-parameter dummy.c
run_llvm -Wunused-member-function dummy.c
run_llvm -Wunused-private-field dummy.c
run_llvm -Wunused-property-ivar dummy.cpp
run_llvm -Wunused-volatile-lvalue dummy.c
run_llvm -Wused-but-marked-unused dummy.c
run_llvm -Wuser-defined-literals dummy.c
run_llvm -Wvector-conversion dummy.c
run_llvm -Wvector-conversions dummy.c
run_llvm -Wvexing-parse dummy.c
run_llvm -Wvisibility dummy.cpp
run_llvm -Wvla-extension dummy.c
run_llvm -W\#warnings dummy.c
run_llvm -Wweak-template-vtables dummy.cpp
run_llvm -Wweak-vtables dummy.cpp
run_llvm -Wzero-length-array dummy.c
logcon ""

logcon "Warning options for GCC but not LLVM"

# Generic control of warnings
run_gcc -fmax-errors=3 dummy.c
# Specific warnings
run_gcc -Waggressive-loop-optimizations dummy.c
run_gcc -Warray-bounds=2 dummy.c
run_gcc -Wbool-compare dummy.c
run_gcc -Wc90-c99-compat dummy.c
run_gcc -Wc99-c11-compat dummy.c
run_gcc -Wclobbered dummy.c
run_gcc -Wconditionally-supported dummy.c
run_gcc -Wcoverage-mismatch dummy.c
run_gcc -Wcpp dummy.c
run_gcc -Wdesignated-init dummy.m
run_gcc -Wdiscarded-array-qualifiers dummy.c
run_gcc -Wdiscarded-qualifiers dummy.c
run_gcc -Wduplicated-cond dummy.c
run_gcc -Wformat=1 dummy.c
run_gcc -Wformat-contains-nul dummy.c
run_gcc -Wformat-signedness dummy.c
run_gcc -Wframe-address dummy.c
run_gcc -Wfree-nonheap-object dummy.c
run_gcc -Whsa -fopenmp dummy.c
run_gcc -Winvalid-memory-model dummy.c
run_gcc -Wjump-misses-init dummy.c
run_gcc -Wlogical-op dummy.c
run_gcc -Wlto-type-mismatch -flto dummy.c
run_gcc -Wmaybe-uninitialized dummy.c
run_gcc -Wmemset-transposed-args dummy.c
run_gcc -Wmisleading-indentation dummy.c
# GCC will always accept negatives, so these tests will always pass. We
# separately test the positives of all these.
run_gcc -Wno-aggressive-loop-optimizations dummy.c
run_gcc -Wno-assign-intercept dummy.c
run_gcc -Wno-bool-compare dummy.c
run_gcc -Wno-c90-c99-compat dummy.c
run_gcc -Wno-c99-c11-compat dummy.c
run_gcc -Wno-clobbered dummy.c
run_gcc -Wno-conditionally-supported dummy.c
run_gcc -Wno-coverage-mismatch dummy.c
run_gcc -Wno-cpp dummy.c
run_gcc -Wno-designated-init dummy.m
run_gcc -Wno-discarded-array-qualifiers dummy.c
run_gcc -Wno-discarded-qualifiers dummy.c
run_gcc -Wno-duplicated-cond dummy.c
run_gcc -Wno-format-contains-nul dummy.c
run_gcc -Wno-format-signedness dummy.c
run_gcc -Wno-frame-address dummy.c
run_gcc -Wno-free-nonheap-object dummy.c
run_gcc -Wno-invalid-memory-model dummy.c
run_gcc -Wno-jump-misses-init dummy.c
run_gcc -Wno-logical-op dummy.c
run_gcc -Wno-lto-type-mismatch -flto dummy.c
run_gcc -Wno-maybe-uninitialized dummy.c
run_gcc -Wno-memset-transposed-args dummy.c
run_gcc -Wno-misleading-indentation dummy.c
run_gcc -Wno-normalized dummy.c
run_gcc -Wno-override-init dummy.c
run_gcc -Wno-override-init-side-effects dummy.c
run_gcc -Wno-packed-bitfield-compat dummy.c
run_gcc -Wno-pedantic-ms-format dummy.c
run_gcc -Wno-placement-new dummy.cpp
run_gcc -Wno-return-local-addr dummy.c
run_gcc -Wno-scalar-storage-order dummy.c
run_gcc -Wno-strict-null-sentinel dummy.c
run_gcc -Wno-subobject-linkage dummy.cpp
run_gcc -Wno-suggest-attribute=const dummy.c
run_gcc -Wno-suggest-attribute=format dummy.c
run_gcc -Wno-suggest-attribute=noreturn dummy.c
run_gcc -Wno-suggest-attribute=pure dummy.c
run_gcc -Wno-suggest-final-methods dummy.c
run_gcc -Wno-suggest-final-types dummy.c
run_gcc -Wno-sync-nand dummy.c
run_gcc -Wno-trampolines dummy.c
run_gcc -Wno-unsafe-loop-optimizations dummy.c
run_gcc -Wno-unused-but-set-parameter dummy.c
run_gcc -Wno-unused-but-set-variable dummy.c
run_gcc -Wno-useless-cast dummy.c
run_gcc -Wno-vector-operation-performance dummy.c
run_gcc -Wno-virtual-move-assign dummy.c
run_gcc -Wno-zero-as-null-pointer-constant dummy.c
# Back to positives
run_gcc -Wnormalized dummy.c
run_gcc -Wnormalized=none dummy.c
run_gcc -Wnormalized=id dummy.c
run_gcc -Wnormalized=nfc dummy.c
run_gcc -Wnormalized=nfkc dummy.c
run_gcc -Wopenmp-simd dummy.c
run_gcc -Woverride-init dummy.c
run_gcc -Woverride-init-side-effects dummy.c
run_gcc -Wpacked-bitfield-compat dummy.c
run_gcc -Wplacement-new dummy.cpp
run_gcc -Wreturn-local-addr dummy.c
run_gcc -Wscalar-storage-order dummy.c
run_gcc -Wshift-overflow=1 dummy.c
run_gcc -Wshift-overflow=2 dummy.c
run_gcc -Wstack-usage=128 dummy.c
run_gcc -Wstrict-aliasing=3 dummy.c
run_gcc -Wsubobject-linkage dummy.cpp
run_gcc -Wsuggest-attribute=const dummy.c
run_gcc -Wsuggest-attribute=format dummy.c
run_gcc -Wsuggest-attribute=noreturn dummy.c
run_gcc -Wsuggest-attribute=pure dummy.c
run_gcc -Wsuggest-final-methods dummy.c
run_gcc -Wsuggest-final-types dummy.c
run_gcc -Wsuggest-override dummy.cpp
run_gcc -Wsync-nand dummy.c
run_gcc -Wtrampolines dummy.c
run_gcc -Wunsafe-loop-optimizations dummy.c
run_gcc -Wunsuffixed-float-constants dummy.c
run_gcc -Wunused-but-set-parameter dummy.c
run_gcc -Wunused-but-set-variable dummy.c
run_gcc -Wuseless-cast dummy.c
run_gcc -Wvector-operation-performance dummy.c
run_gcc -Wvirtual-move-assign dummy.c
run_gcc -Wzero-as-null-pointer-constant dummy.c
logcon ""

# Options that are target specific and won't generally run here

run_dummy -Waddr-space-convert dummy.c
run_dummy -Wmismatched-method-attributes -c dummy.m # Darwin only?
run_dummy -Wobjc-literal-missing-atsign -c dummy.m # Darwin only?
run_dummy -Wpedantic-ms-format dummy.c
run_dummy -Wreadonly-setter-attrs -c dummy.m # Darwin only?


#################################################################################
#                                                                               #
#		      C and Objective C Warning Options                         #
#                                                                               #
#################################################################################

logcon ""
logcon "C and ObjC warning options for both LLVM and GCC"

run_both -Wbad-function-cast dummy.c
run_both -Wdeclaration-after-statement dummy.c
run_both -Wmissing-declarations dummy.c
run_both -Wmissing-prototypes dummy.c
run_both -Wnested-externs dummy.c
# GCC will always accept negatives, so all we can check here is that LLVM
# (which is pickier) accepts them. We separately test the positives of all
# these.
run_only_llvm -Wno-bad-function-cast dummy.c
run_only_llvm -Wno-declaration-after-statement dummy.c
run_only_llvm -Wno-missing-declarations dummy.c
run_only_llvm -Wno-missing-prototypes dummy.c
run_only_llvm -Wno-nested-externs dummy.c
run_only_llvm -Wno-old-style-definition dummy.c
run_only_llvm -Wno-pointer-sign dummy.c
run_only_llvm -Wno-strict-prototypes dummy.c
# Back to positives
run_both -Wold-style-definition dummy.c
run_both -Wpointer-sign dummy.c
run_both -Wstrict-prototypes dummy.c
logcon ""

logcon "C and ObjC warning options for LLVM but not GCC"

logcon "C and ObjC warning options for GCC but not LLVM"
run_gcc -Wmissing-parameter-type dummy.c
# GCC will always accept negatives, so these tests will always pass. We
# separately test the positives of all these.
run_gcc -Wno-missing-parameter-type dummy.c
run_gcc -Wno-old-style-declaration dummy.c
run_gcc -Wno-traditional dummy.c
run_gcc -Wno-traditional-conversion dummy.c
# Back to positives
run_gcc -Wold-style-declaration dummy.c
run_gcc -Wtraditional dummy.c
run_gcc -Wtraditional-conversion dummy.c
logcon ""


#################################################################################
#                                                                               #
#			      Debugging Options                                 #
#                                                                               #
#################################################################################

logcon ""
logcon "Debugging options for both LLVM and GCC"

run_both -fdebug-prefix-map=`pwd`=`pwd`/.. dummy.c
run_both -fdebug-types-section dummy.c
run_both -fdwarf2-cfi-asm dummy.c
run_both -feliminate-unused-debug-types dummy.c
run_only_llvm -fno-debug-types-section dummy.c
run_only_llvm -fno-dwarf2-cfi-asm dummy.c
run_only_llvm -fno-eliminate-unused-debug-types dummy.c
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
run_both -gdwarf dummy.c
run_both -gdwarf-2 dummy.c
run_both -gdwarf-3 dummy.c
run_both -gdwarf-4 dummy.c
run_both -gdwarf-5 dummy.c
run_both -ggnu-pubnames dummy.c
run_both -gno-record-gcc-switches dummy.c
run_both -gno-strict-dwarf dummy.c
run_both -grecord-gcc-switches dummy.c
run_both -gsplit-dwarf dummy.c
run_both -gstrict-dwarf dummy.c
logcon ""

logcon "Debugging options for LLVM but not GCC"

run_llvm -fno-standalone-debug dummy.c
run_llvm -fstandalone-debug dummy.c
run_llvm -gcodeview dummy.c
run_llvm -gfull dummy.c
run_llvm -gline-tables-only dummy.c
run_llvm -gmodules -c dummy.m
run_llvm -gused dummy.c
logcon ""

logcon "Debugging options for GCC but not LLVM"

run_gcc -feliminate-dwarf2-dups dummy.c
run_gcc -feliminate-unused-debug-symbols dummy.c
run_gcc -femit-class-debug-always dummy.cpp
run_gcc -femit-struct-debug-baseonly dummy.c
run_gcc -femit-struct-debug-detailed=dir:any dummy.c
run_gcc -femit-struct-debug-reduced dummy.c
run_gcc -fmerge-debug-strings dummy.c
run_gcc -fno-merge-debug-strings dummy.c
run_gcc -fno-var-tracking-assignments dummy.c
run_gcc -fvar-tracking dummy.c
run_gcc -fvar-tracking-assignments dummy.c
run_gcc -gcoff0 dummy.c
run_gcc -gpubnames dummy.c
run_gcc -gstabs dummy.c
run_gcc -gstabs0 dummy.c
run_gcc -gstabs1 dummy.c
run_gcc -gstabs2 dummy.c
run_gcc -gstabs3 dummy.c
run_gcc -gstabs+ dummy.c
run_gcc -gtoggle dummy.c
run_gcc -gvms0 dummy.c
run_gcc -gxcoff0 dummy.c
run_gcc -gz dummy.c
logcon ""

# Not supported at all for this architecture

run_dummy -gcoff dummy.c
run_dummy -gcoff1 dummy.c
run_dummy -gcoff2 dummy.c
run_dummy -gcoff3 dummy.c
run_dummy -gvms dummy.c
run_dummy -gvms1 dummy.c
run_dummy -gvms2 dummy.c
run_dummy -gvms3 dummy.c
run_dummy -gxcoff dummy.c
run_dummy -gxcoff1 dummy.c
run_dummy -gxcoff2 dummy.c
run_dummy -gxcoff3 dummy.c
run_dummy -gxcoff+ dummy.c
run_dummy -gz=none dummy.c
run_dummy -gz=zlib dummy.c
run_dummy -gz=zlib-gnu dummy.c


#################################################################################
#                                                                               #
#			     Optimization Options                               #
#                                                                               #
#################################################################################

logcon ""
logcon "Optimization options for both LLVM and GCC"

run_both -fassociative-math dummy.c
run_both -fdata-sections dummy.c
run_both -ffast-math dummy.c
run_both -ffinite-math-only dummy.c
run_both -ffp-contract=off dummy.c
run_both -ffp-contract=fast dummy.c
run_both -ffp-contract=on dummy.c
run_both -ffunction-sections dummy.c
run_both -flto dummy.c
run_both -flto=full dummy.c
run_both -flto=thin dummy.c
run_both -fmath-errno dummy.c # Default
run_both -fmerge-all-constants dummy.c
run_both -fno-inline dummy.c
run_both -fno-lto dummy.c
run_both -fno-math-errno dummy.c
run_both -fno-merge-all-constants dummy.c
run_both -fno-signed-zeros dummy.c
run_both -fno-trapping-math dummy.c
run_both -fno-unroll-loops dummy.c
run_both -fno-zero-initialized-in-bss dummy.c
run_both -fomit-frame-pointer dummy.c
run_both -foptimize-sibling-calls dummy.c
run_both -fprofile-use dummy.c
run_only_gcc -fprofile-use=`pwd`/gcc dummy.c
run_only_llvm -fprofile-use=`pwd`/llvm dummy.c
run_both -freciprocal-math dummy.c
run_both -fstrict-aliasing dummy.c
run_both -fstrict-enums dummy.c
run_both -fstrict-overflow dummy.c
run_both -ftree-slp-vectorize dummy.c
run_both -funit-at-a-time dummy.c
run_both -funroll-loops dummy.c
run_both -funsafe-math-optimizations dummy.c
run_both -ftree-vectorize dummy.c
run_both -O dummy.c
run_both -O0 dummy.c
run_both -O1 dummy.c
run_both -O2 dummy.c
run_both -O3 dummy.c
run_both -Ofast dummy.c
run_both -Os dummy.c
run_both --param ssp-buffer-size=4 dummy.c
logcon ""

logcon "Optimization options for LLVM but not GCC"

run_llvm -fno-reroll-loops dummy.c
run_llvm -freroll-loops dummy.c
run_llvm -fslp-vectorize-aggressive dummy.c
run_llvm -fslp-vectorize dummy.c
run_llvm -fstrict-vtable-pointers dummy.cpp
run_llvm -c -fthinlto-index=dummy-lto.o dummy.ll
run_llvm -fvectorize dummy.c
run_llvm -mllvm -enable-andcmp-sinking dummy.c # One example from opt
run_llvm -mrelax-all dummy.c # Assembler, not linker relaxation
run_llvm -O4 dummy.c
run_llvm -Oz dummy.c
logcon ""

logcon "Optimization options for GCC but not LLVM"

run_gcc -faggressive-loop-optimizations dummy.c
run_gcc -falign-functions dummy.c
run_gcc -falign-functions=32 dummy.c
run_gcc -falign-jumps dummy.c
run_gcc -falign-jumps=32 dummy.c
run_gcc -falign-labels dummy.c
run_gcc -falign-labels=32 dummy.c
run_gcc -falign-loops dummy.c
run_gcc -falign-loops=32 dummy.c
run_gcc -fauto-inc-dec dummy.c
run_gcc -fauto-profile -c dummy.c
run_gcc -fauto-profile=`pwd`/gcc/fbdata.afdo -c dummy.c
run_gcc -fbranch-probabilities dummy.c
run_gcc -fbranch-target-load-optimize dummy.c
run_gcc -fbranch-target-load-optimize2 dummy.c
run_gcc -fbtr-bb-exclusive dummy.c
run_gcc -fcaller-saves dummy.c
run_gcc -fcombine-stack-adjustments dummy.c
run_gcc -fcompare-elim dummy.c
run_gcc -fconserve-stack dummy.c
run_gcc -fcprop-registers dummy.c
run_gcc -fcrossjumping dummy.c
run_gcc -fcse-follow-jumps dummy.c
run_gcc -fcse-skip-blocks dummy.c
run_gcc -fcx-fortran-rules dummy.c
run_gcc -fcx-limited-range dummy.c
run_gcc -fdce dummy.c
run_gcc -fdeclone-ctor-dtor dummy.cpp
run_gcc -fdelayed-branch dummy.c
run_gcc -fdelete-null-pointer-checks dummy.c
run_gcc -fdevirtualize dummy.cpp
run_gcc -fdevirtualize-at-ltrans dummy.cpp
run_gcc -fdevirtualize-speculatively dummy.cpp
run_gcc -fdse dummy.c
run_gcc -fearly-inlining dummy.c
run_gcc -fexcess-precision=fast dummy.c
run_gcc -fexcess-precision=standard dummy.c
run_gcc -fexpensive-optimizations dummy.c
run_gcc -ffat-lto-objects dummy.c
run_gcc -fipa-sra dummy.c
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
run_gcc -finline-functions dummy.c
run_gcc -finline-functions-called-once dummy.c
run_gcc -finline-limit=10 dummy.c
run_gcc -finline-small-functions dummy.c
run_gcc -fipa-cp dummy.c
run_gcc -fipa-cp-alignment -fipa-cp dummy.c
run_gcc -fipa-cp-clone dummy.c
run_gcc -fipa-icf dummy.c
run_gcc -fipa-profile dummy.c
run_gcc -fipa-pta dummy.c
run_gcc -fipa-pure-const dummy.c
run_gcc -fipa-ra dummy.c
run_gcc -fipa-reference dummy.c
run_gcc -fira-algorithm=CB dummy.c
run_gcc -fira-algorithm=priority dummy.c
run_gcc -fira-hoist-pressure dummy.c
run_gcc -fira-loop-pressure dummy.c
run_gcc -fira-region=all dummy.c
run_gcc -fira-region=mixed dummy.c
run_gcc -fira-region=one dummy.c
run_gcc -fisolate-erroneous-paths-attribute dummy.c
run_gcc -fisolate-erroneous-paths-dereference dummy.c
run_gcc -fivopts dummy.c
run_gcc -fkeep-inline-functions dummy.c
run_gcc -fkeep-static-consts dummy.c
run_gcc -fkeep-static-functions dummy.c
run_gcc -flive-range-shrinkage dummy.c
run_gcc -floop-block dummy.c
run_gcc -floop-interchange dummy.c
run_gcc -floop-nest-optimize dummy.c
run_gcc -floop-parallelize-all dummy.c
run_gcc -floop-strip-mine dummy.c
run_gcc -floop-unroll-and-jam dummy.c
run_gcc -flra-remat dummy.c
run_gcc -flto-compression-level=5 dummy.c
run_gcc -flto-partition=1to1 dummy.c
run_gcc -flto-partition=balanced dummy.c
run_gcc -flto-partition=max dummy.c
run_gcc -flto-partition=none dummy.c
run_gcc -flto-partition=one dummy.c
run_gcc -flto-odr-type-merging -flto dummy.cpp
run_gcc -fmerge-constants dummy.c
run_gcc -fmodulo-sched dummy.c
run_gcc -fmodulo-sched-allow-regmoves dummy.c
run_gcc -fmove-loop-invariants dummy.c
run_gcc -fno-branch-count-reg dummy.c
run_gcc -fno-defer-pop dummy.c
run_gcc -fno-function-cse dummy.c
run_gcc -fno-guess-branch-probability dummy.c
run_gcc -fno-ira-share-save-slots dummy.c
run_gcc -fno-ira-share-spill-slots dummy.c
run_gcc -fno-peephole dummy.c
run_gcc -fno-peephole2 dummy.c
run_gcc -fno-sched-interblock dummy.c
run_gcc -fno-sched-spec dummy.c
run_gcc -fno-sched-stalled-insns dummy.c
run_gcc -fno-sched-stalled-insns-dep dummy.c
run_gcc -fno-toplevel-reorder dummy.c
run_gcc -foptimize-strlen dummy.c
run_gcc -fpartial-inlining dummy.c
run_gcc -fpeel-loops dummy.c
run_gcc -fpredictive-commoning dummy.c
run_gcc -fprefetch-loop-arrays dummy.c
run_gcc -fprofile-correction dummy.c
run_gcc -fprofile-reorder-functions dummy.c
run_gcc -fprofile-values dummy.c
run_gcc -free dummy.c
run_gcc -frename-registers dummy.c
run_gcc -freorder-blocks dummy.c
run_gcc -freorder-blocks-algorithm=simple dummy.c
run_gcc -freorder-blocks-algorithm=stc dummy.c
run_gcc -freorder-blocks-and-partition dummy.c
run_gcc -freorder-functions dummy.c
run_gcc -frerun-cse-after-loop dummy.c
run_gcc -freschedule-modulo-scheduled-loops dummy.c
run_gcc -frounding-math dummy.c
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
run_gcc -fsched-stalled-insns=0 dummy.c
run_gcc -fsched-stalled-insns=1 dummy.c
run_gcc -fsched-stalled-insns-dep dummy.c
run_gcc -fsched-stalled-insns-dep=0 dummy.c
run_gcc -fsched-stalled-insns-dep=1 dummy.c
run_gcc -fsched2-use-superblocks dummy.c
run_gcc -fschedule-fusion dummy.c
run_gcc -fschedule-insns dummy.c
run_gcc -fschedule-insns2 dummy.c
run_gcc -fsection-anchors dummy.c
run_gcc -fsel-sched-pipelining dummy.c
run_gcc -fsel-sched-pipelining-outer-loops dummy.c
run_gcc -fselective-scheduling dummy.c
run_gcc -fselective-scheduling2 dummy.c
run_gcc -fsemantic-interposition dummy.c
run_gcc -fshrink-wrap dummy.c
run_gcc -fsignaling-nans dummy.c
run_gcc -fsimd-cost-model=cheap dummy.c
run_gcc -fsimd-cost-model=dynamic dummy.c
run_gcc -fsimd-cost-model=unlimited dummy.c
run_gcc -fsingle-precision-constant dummy.c
run_gcc -fsplit-ivs-in-unroller dummy.c
run_gcc -fsplit-paths dummy.c
run_gcc -fsplit-wide-types dummy.c
run_gcc -fssa-backprop dummy.c
run_gcc -fssa-phiopt dummy.c
run_gcc -fstdarg-opt dummy.c
run_gcc -fthread-jumps dummy.c
run_gcc -ftracer dummy.c
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
run_gcc -fvect-cost-model dummy.c
run_gcc -fvpt dummy.c
run_gcc -fweb dummy.c
run_gcc -fwhole-program dummy.c
run_gcc -Og dummy.c
run_gcc --param align-loop-iterations=20 dummy.c
run_gcc --param align-threshold=50 dummy.c
run_gcc --param allow-store-data-races=1 dummy.c
run_gcc --param asan-globals=1 dummy.c
run_gcc --param asan-instrument-reads=1 dummy.c
run_gcc --param asan-instrument-writes=1 dummy.c
run_gcc --param asan-instrumentation-with-call-threshold=10 dummy.c
run_gcc --param asan-memintrin=1 dummy.c
run_gcc --param asan-stack=1 dummy.c
run_gcc --param asan-use-after-return=1 dummy.c
run_gcc --param builtin-expect-probability=80 dummy.c
run_gcc --param case-values-threshold=3 dummy.c
run_gcc --param chkp-max-ctor-size=4000 dummy.c
run_gcc --param comdat-sharing-probability=20 dummy.c
run_gcc --param cxx-max-namespaces-for-diagnostic-help=900 dummy.c
run_gcc --param early-inlining-insns=12 dummy.c
run_gcc --param gcse-cost-distance-ratio=12 dummy.c
run_gcc --param gcse-unrestricted-cost=4 dummy.c
run_gcc --param ggc-min-expand=25 dummy.c
run_gcc --param ggc-min-heapsize=65536 dummy.c
run_gcc --param graphite-max-bbs-per-function=200 dummy.c
run_gcc --param graphite-max-nb-scop-params=12 dummy.c
run_gcc --param hot-bb-count-ws-permille=500 dummy.c
run_gcc --param hot-bb-frequency-fraction=50 dummy.c
run_gcc --param inline-min-speedup=30 dummy.c
run_gcc --param inline-unit-growth=30 dummy.c
run_gcc --param integer-share-limit=256 dummy.c
run_gcc --param ipa-cp-array-index-hint-bonus=10 dummy.c
run_gcc --param ipa-cp-eval-threshold=10 dummy.c
run_gcc --param ipa-cp-loop-hint-bonus=10 dummy.c
run_gcc --param ipa-cp-recursion-penalty=10 dummy.c
run_gcc --param ipa-cp-single-call-penalty=10 dummy.c
run_gcc --param ipa-cp-value-list-size=10 dummy.c
run_gcc --param ipa-max-aa-steps=100 dummy.c
run_gcc --param ipa-max-agg-items=10 dummy.c
run_gcc --param ipa-sra-ptr-growth-factor=4 dummy.c
run_gcc --param ipcp-unit-growth=12 dummy.c
run_gcc --param ira-loop-reserved-regs=3 dummy.c
run_gcc --param ira-max-conflict-table-size=1500 dummy.c
run_gcc --param ira-max-loops-num=90 dummy.c
run_gcc --param iv-always-prune-cand-set-bound=10 dummy.c
run_gcc --param iv-consider-all-candidates-bound=10 dummy.c
run_gcc --param iv-max-considered-uses=10 dummy.c
run_gcc --param l1-cache-line-size=32 dummy.c
run_gcc --param l1-cache-size=32 dummy.c
run_gcc --param l2-cache-size=128 dummy.c
run_gcc --param large-function-growth=90 dummy.c
run_gcc --param large-function-insns=3000 dummy.c
run_gcc --param large-stack-frame-growth=90 dummy.c
run_gcc --param large-stack-frame=378 dummy.c
run_gcc --param large-unit-insns=15000 dummy.c
run_gcc --param lim-expensive=30 dummy.c
run_gcc --param loop-block-tile-size=60 dummy.c
run_gcc --param loop-invariant-max-bbs-in-loop=9000 dummy.c
run_gcc --param loop-max-datarefs-for-datadeps=900 dummy.c
run_gcc --param lra-inheritance-ebb-probability-cutoff=30 dummy.c
run_gcc --param lto-min-partition=16 -flto dummy.c
run_gcc --param lto-partitions=64 -flto dummy.c
run_gcc --param max-average-unrolled-insns=400 dummy.c
run_gcc --param max-combine-insns=3 dummy.c
run_gcc --param max-completely-peel-loop-nest-depth=4 dummy.c
run_gcc --param max-completely-peel-times=30 dummy.c
run_gcc --param max-completely-peeled-insns=30 dummy.c
run_gcc --param max-crossjump-edges=6 dummy.c
run_gcc --param max-cse-insns=900 dummy.c
run_gcc --param max-cse-path-length=9 dummy.c
run_gcc --param max-cselib-memory-locations=450 dummy.c
run_gcc --param max-delay-slot-insn-search=3 dummy.c
run_gcc --param max-delay-slot-live-search=3 dummy.c
run_gcc --param max-early-inliner-iterations=40 dummy.c
run_gcc --param max-fields-for-field-sensitive=150 dummy.c
run_gcc --param max-fsm-thread-length=12 dummy.c
run_gcc --param max-fsm-thread-path-insns=150 dummy.c
run_gcc --param max-fsm-thread-paths=60 dummy.c
run_gcc --param max-gcse-insertion-ratio=30 dummy.c
run_gcc --param max-gcse-memory=100000 dummy.c
run_gcc --param max-goto-duplication-insns=10 dummy.c
run_gcc --param max-grow-copy-bb-insns=10 dummy.c
run_gcc --param max-hoist-depth=40 dummy.c
run_gcc --param max-inline-insns-auto=50 dummy.c
run_gcc --param max-inline-insns-recursive-auto=400 dummy.c
run_gcc --param max-inline-insns-recursive=400 dummy.c
run_gcc --param max-inline-insns-single=500 dummy.c
run_gcc --param max-inline-recursive-depth-auto=13 dummy.c
run_gcc --param max-inline-recursive-depth=9 dummy.c
run_gcc --param max-iterations-to-track=10 dummy.c
run_gcc --param max-jump-thread-duplication-stmts=10 dummy.c
run_gcc --param max-last-value-rtl=9000 dummy.c
run_gcc --param max-modulo-backtrack-attempts=5 dummy.c
run_gcc --param max-partial-antic-length=100 dummy.c
run_gcc --param max-peel-branches=20 dummy.c
run_gcc --param max-peel-times=40 dummy.c
run_gcc --param max-peeled-insns=40 dummy.c
run_gcc --param max-pending-list-length=100 dummy.c
run_gcc --param max-pipeline-region-blocks=14 dummy.c
run_gcc --param max-pipeline-region-insns=200 dummy.c
run_gcc --param max-predicted-iterations=9 dummy.c
run_gcc --param max-reload-search-insns=90 dummy.c
run_gcc --param max-sched-extend-regions-iters=3 dummy.c
run_gcc --param max-sched-insn-conflict-delay=4 dummy.c
run_gcc --param max-sched-ready-insns=90 dummy.c
run_gcc --param max-sched-region-blocks=9 dummy.c
run_gcc --param max-sched-region-insns=90 dummy.c
run_gcc --param max-slsr-cand-scan=5 dummy.c
run_gcc --param max-ssa-name-query-depth=5 dummy.c
run_gcc --param max-stores-to-sink=3 dummy.c
run_gcc --param max-tail-merge-comparisons=10 dummy.c
run_gcc --param max-tail-merge-iterations=3 dummy.c
run_gcc --param max-unroll-times=10 dummy.c
run_gcc --param max-unrolled-insns=500 dummy.c
run_gcc --param max-unswitch-insns=40 dummy.c
run_gcc --param max-unswitch-level=5 dummy.c
run_gcc --param max-vartrack-expr-depth=10 dummy.c
run_gcc --param max-vartrack-size=100 dummy.c
run_gcc --param min-crossjump-insns=6 dummy.c
run_gcc --param min-inline-recursive-probability=9 dummy.c
run_gcc --param min-insn-to-prefetch-ratio=3 dummy.c
run_gcc --param min-nondebug-insn-uid=100 dummy.c
run_gcc --param min-size-for-stack-sharing=64 dummy.c
run_gcc --param min-spec-prob=40 dummy.c
run_gcc --param min-vect-loop-bound=1 dummy.c
run_gcc --param parloops-chunk-size=1 dummy.c
run_gcc --param parloops-schedule=auto dummy.c
run_gcc --param parloops-schedule=dynamic dummy.c
run_gcc --param parloops-schedule=guided dummy.c
run_gcc --param parloops-schedule=runtime dummy.c
run_gcc --param parloops-schedule=static dummy.c
run_gcc --param predictable-branch-outcome=8 dummy.c
run_gcc --param prefetch-latency=3 dummy.c
run_gcc --param prefetch-min-insn-to-mem-ratio=3 dummy.c
run_gcc --param profile-func-internal-id=1 dummy.c
run_gcc --param sccvn-max-alias-queries-per-access=900 dummy.c
run_gcc --param sccvn-max-scc-size=9000 dummy.c
run_gcc --param scev-max-expr-complexity=100 dummy.c
run_gcc --param scev-max-expr-size=100 dummy.c
run_gcc --param sched-mem-true-dep-cost=2 dummy.c
run_gcc --param sched-pressure-algorithm=2 dummy.c
run_gcc --param sched-spec-prob-cutoff=50 dummy.c
run_gcc --param sched-state-edge-prob-cutoff=12 dummy.c
run_gcc --param selsched-max-lookahead=40 dummy.c
run_gcc --param selsched-max-sched-times=3 dummy.c
run_gcc --param selsched-insns-to-rename=3 dummy.c
run_gcc --param simultaneous-prefetches=3 dummy.c
run_gcc --param sink-frequency-threshold=80 dummy.c
run_gcc --param sms-min-sc=3 dummy.c
run_gcc --param sra-max-scalarization-size-Osize=64 dummy.c
run_gcc --param sra-max-scalarization-size-Ospeed=32 dummy.c
run_gcc --param switch-conversion-max-branch-ratio=2 dummy.c
run_gcc --param tm-max-aggregate-size=16 dummy.c
run_gcc --param tracer-dynamic-coverage-feedback=80 dummy.c
run_gcc --param tracer-dynamic-coverage=50 dummy.c
run_gcc --param tracer-max-code-growth=90 dummy.c
run_gcc --param tracer-min-branch-probability-feedback=10 dummy.c # Typo in manual
run_gcc --param tracer-min-branch-probability=5 dummy.c # Typo in manual
run_gcc --param tracer-min-branch-ratio=10 dummy.c
run_gcc --param tree-reassoc-width=3 dummy.c
run_gcc --param use-canonical-types=0 dummy.c
run_gcc --param vect-max-peeling-for-alignment=10 dummy.c
run_gcc --param vect-max-version-for-alias-checks=128 dummy.c
run_gcc --param vect-max-version-for-alignment-checks=256 dummy.c
logcon ""

# These are only in the internals manual. For now we don't check them.
run_dummy -fltrans -flto dummy.c
run_dummy -fltrans-output-list=${tmpf} -flto dummy.c
run_dummy -fresolution=${tmpf} -flto dummy.c
run_dummy -fwpa -flto dummy.c

# These options don't work because the AutoFDO tool is broken for newer kernels.
# Documented, but not implemented


#################################################################################
#                                                                               #
#		       Program Instrumentation Options                          #
#                                                                               #
#################################################################################

logcon ""
logcon "Program instrumentation options for both LLVM and GCC"

run_both --coverage dummy.c
run_both -finstrument-functions dummy.c profile-assist.c
run_both -fno-sanitize=all dummy.c
run_both -fno-sanitize-recover dummy.c # Deprecated
run_both -fno-sanitize-recover=address dummy.c
run_both -fno-sanitize-recover=alignment dummy.c
run_both -fno-sanitize-recover=bool dummy.c
run_both -fno-sanitize-recover=bounds dummy.c
run_both -fno-sanitize-recover=enum dummy.c
run_both -fno-sanitize-recover=float-cast-overflow dummy.c
run_both -fno-sanitize-recover=float-divide-by-zero dummy.c
run_both -fno-sanitize-recover=integer-divide-by-zero dummy.c
run_both -fno-sanitize-recover=kernel-address dummy.c
run_both -fno-sanitize-recover=nonnull-attribute dummy.c
run_both -fno-sanitize-recover=null dummy.c
run_both -fno-sanitize-recover=object-size dummy.c
run_both -fno-sanitize-recover=returns-nonnull-attribute dummy.c
run_both -fno-sanitize-recover=shift dummy.c
run_both -fno-sanitize-recover=signed-integer-overflow dummy.c
run_both -fno-sanitize-recover=undefined dummy.c
run_both -fno-sanitize-recover=vla-bound dummy.c
run_both -fno-sanitize-recover=vptr dummy.c
run_both -fno-stack-protector dummy.c
run_both -fprofile-arcs dummy.c
run_both -fprofile-generate dummy.c
run_only_llvm -fprofile-generate=`pwd`/llvm dummy.c
run_only_gcc -fprofile-generate=`pwd`/gcc dummy.c
run_both -fsanitize=address dummy.c
run_both -fsanitize=alignment dummy.c
run_both -fsanitize=bool dummy.c
run_both -fsanitize=bounds dummy.c
run_both -fsanitize=enum dummy.c
run_both -fsanitize=float-cast-overflow dummy.c
run_both -fsanitize=float-divide-by-zero dummy.c
run_both -fsanitize=integer-divide-by-zero dummy.c
run_both -fsanitize=kernel-address dummy.c
run_both -fsanitize=leak dummy.c
run_both -fsanitize=nonnull-attribute dummy.c
run_both -fsanitize=null dummy.c
run_both -fsanitize=object-size dummy.c
run_both -fsanitize=return dummy.c
run_both -fsanitize=returns-nonnull-attribute dummy.c
run_both -fsanitize=shift dummy.c
run_both -fsanitize=signed-integer-overflow dummy.c
run_both -fsanitize=thread dummy.c
run_both -fsanitize=undefined dummy.c
run_both -fsanitize=unreachable dummy.c
run_both -fsanitize=vla-bound dummy.c
run_both -fsanitize=vptr dummy.c
run_both -fsanitize-recover dummy.c
run_both -fsanitize-recover=address dummy.c
run_both -fsanitize-recover=alignment dummy.c
run_both -fsanitize-recover=bool dummy.c
run_both -fsanitize-recover=bounds dummy.c
run_both -fsanitize-recover=enum dummy.c
run_both -fsanitize-recover=float-cast-overflow dummy.c
run_both -fsanitize-recover=float-divide-by-zero dummy.c
run_both -fsanitize-recover=integer-divide-by-zero dummy.c
run_both -fsanitize-recover=kernel-address dummy.c
run_both -fsanitize-recover=nonnull-attribute dummy.c
run_both -fsanitize-recover=null dummy.c
run_both -fsanitize-recover=object-size dummy.c
run_both -fsanitize-recover=returns-nonnull-attribute dummy.c
run_both -fsanitize-recover=shift dummy.c
run_both -fsanitize-recover=signed-integer-overflow dummy.c
run_both -fsanitize-recover=undefined dummy.c
run_both -fsanitize-recover=vla-bound dummy.c
run_both -fsanitize-recover=vptr dummy.c
run_both -fsanitize-undefined-trap-on-error dummy.c
run_both -fsplit-stack dummy.c
run_both -fstack-check dummy.c
run_both -fstack-protector dummy.c
run_both -fstack-protector-all -c dummy.c
run_both -fstack-protector-strong dummy.c
run_both -ftest-coverage dummy.c
run_both -pg dummy.c
logcon ""

logcon "Program instrumentation options for LLVM but not GCC"

run_llvm --analyze dummy.c
run_llvm -fcoverage-mapping -fprofile-instr-generate dummy.c
run_llvm -fno-coverage-mapping -fprofile-instr-generate dummy.c
run_llvm -fno-profile-instr-generate dummy.c
run_llvm -fno-profile-instr-use dummy.c
run_llvm -fprofile-instr-generate dummy.c
run_llvm -fprofile-instr-generate=`pwd`/llvm/dummy.profdata dummy.c
run_llvm -fprofile-instr-use dummy.c
run_llvm -fprofile-instr-use=`pwd`/llvm/dummy.profdata dummy.c
run_llvm -fprofile-sample-use=dummy-sample.prof dummy.c
run_llvm -fno-sanitize-blacklist dummy.c
run_llvm -fno-sanitize=cfi -flto dummy.c
run_llvm -fno-sanitize-cfi-cross-dso -fsanitize=cfi -flto dummy.c
run_llvm -fno-sanitize-coverage=bb -fsanitize=address dummy.c
run_llvm -fno-sanitize-coverage=edge -fsanitize=address dummy.c
run_llvm -fno-sanitize-coverage=func -fsanitize=address dummy.c
run_llvm -fno-sanitize-coverage=indirect-calls -fsanitize=address dummy.c
run_llvm -fno-sanitize-memory-track-origins -fsanitize=memory dummy.c
run_only_llvm -fno-sanitize-recover=leak dummy.c
run_only_llvm -fno-sanitize-recover=thread dummy.c
run_llvm -fno-sanitize-stats -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=alignment -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=bool -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=bounds -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=cfi-derived-cast -fsanitize=cfi -flto dummy.c
run_llvm -fno-sanitize-trap=cfi-icall -fsanitize=cfi -flto dummy.c
run_llvm -fno-sanitize-trap=cfi-nvcall -fsanitize=cfi -flto dummy.c
run_llvm -fno-sanitize-trap=cfi-unrelated-cast -fsanitize=cfi -flto dummy.c
run_llvm -fno-sanitize-trap=cfi-vcall -fsanitize=cfi -flto dummy.c
run_llvm -fno-sanitize-trap=enum -fno-sanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=float-cast-overflow -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=float-divide-by-zero -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=integer -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=integer-divide-by-zero -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=nonnull-attribute -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=null -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=object-size -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=return -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=returns-nonnull-attribute -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=shift -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=signed-integer-overflow -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=undefined -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=unreachable -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=unsigned-integer-overflow -fsanitize=undefined dummy.c
run_llvm -fno-sanitize-trap=vla-bound -fsanitize=undefined dummy.c
run_dummy -fno-sanitize-trap=vptr -fsanitize=undefined dummy.cpp # Broken
run_llvm -fsanitize-address-field-padding=2 -fsanitize=address dummy.c
run_llvm -fsanitize-blacklist=dummy-blacklist.txt dummy.c
run_llvm -fsanitize=cfi -flto dummy.c
run_llvm -fsanitize-cfi-cross-dso -fsanitize=cfi -flto dummy.c
run_llvm -fsanitize-coverage=bb -fsanitize=address dummy.c
run_llvm -fsanitize-coverage=edge -fsanitize=address dummy.c
run_llvm -fsanitize-coverage=func -fsanitize=address dummy.c
run_llvm -fsanitize-coverage=indirect-calls -fsanitize=address dummy.c
run_llvm -fsanitize-memory-track-origins -fsanitize=memory dummy.c
run_llvm -fsanitize-memory-track-origins=1 -fsanitize=memory dummy.c
run_llvm -fsanitize-memory-track-origins=2 -fsanitize=memory dummy.c
run_llvm -fsanitize-memory-use-after-dtor -fsanitize=memory dummy.c
run_llvm -fsanitize-recover=leak dummy.c
run_llvm -fsanitize-recover=thread dummy.c
run_llvm -fsanitize-stats dummy.c
run_llvm -fsanitize-trap=alignment -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=bool -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=bounds -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=cfi-derived-cast -fsanitize=cfi -flto dummy.c
run_llvm -fsanitize-trap=cfi-icall -fsanitize=cfi -flto dummy.c
run_llvm -fsanitize-trap=cfi-nvcall -fsanitize=cfi -flto dummy.c
run_llvm -fsanitize-trap=cfi-unrelated-cast -fsanitize=cfi -flto dummy.c
run_llvm -fsanitize-trap=cfi-vcall -fsanitize=cfi -flto dummy.c
run_llvm -fsanitize-trap=enum -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=float-cast-overflow -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=float-divide-by-zero -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=integer -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=integer-divide-by-zero -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=nonnull-attribute -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=null -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=object-size -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=return -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=returns-nonnull-attribute -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=shift -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=signed-integer-overflow -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=undefined -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=unreachable -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=unsigned-integer-overflow -fsanitize=undefined dummy.c
run_llvm -fsanitize-trap=vla-bound -fsanitize=undefined dummy.c
run_dummy -fsanitize-trap=vptr -fsanitize=undefined dummy.cpp # Broken

logcon ""

logcon "Program instrumentation options for GCC but not LLVM"

run_gcc -fasan-shadow-offset=32 -fsanitize=kernel-address dummy.c
run_gcc -fbounds-check dummy.c
run_gcc -fcheck-data-deps dummy.c
run_gcc -finstrument-functions-exclude-file-list=dummy.c dummy.c
run_gcc -finstrument-functions-exclude-function-list=main dummy.c
run_gcc -fno-sanitize-coverage=trace-pc -fsanitize=address -c dummy.c
run_gcc -fno-stack-limit dummy.c
run_gcc -fprofile-dir=`pwd`/gcc dummy.c
run_gcc -fsanitize=bounds-strict dummy.c
run_gcc -fsanitize-coverage=trace-pc -fsanitize=address -c dummy.c
run_gcc -fsanitize-recover=bounds-strict dummy.c
run_gcc -fsanitize-recover=return dummy.c
run_gcc -fsanitize-recover=unreachable dummy.c
run_gcc -fsanitize-sections=.text dummy.c
run_gcc -fstack-limit-register=rax dummy.c
run_gcc -fstack-limit-symbol=__sl -Wl,--defsym,__sl=0x7ffe000 dummy.c
run_gcc -fstack-protector-explicit dummy.c
run_gcc -fvtable-verify=none dummy.cpp
run_gcc -fvtable-verify=preinit -c dummy.cpp
run_gcc -fvtable-verify=std -c dummy.cpp
run_gcc -fvtv-counts -fvtable-verify=std -c dummy.cpp
run_gcc -fvtv-debug -fvtable-verify=std -c dummy.cpp
run_gcc -p dummy.c
logcon ""

# Not supported at all for this architecture

run_dummy -fcheck-pointer-bounds dummy.c # x86 -mmpx
run_dummy -fchkp-check-incomplete-type dummy.c # x86 -mmpx
run_dummy -fchkp-check-read dummy.c # x86 -mmpx
run_dummy -fchkp-check-write dummy.c # x86 -mmpx
run_dummy -fchkp-first-field-has-own-bounds dummy.c # x86 -mmpx
run_dummy -fchkp-instrument-calls dummy.c # x86 -mmpx
run_dummy -fchkp-instrument-marked-only dummy.c # x86 -mmpx
run_dummy -fchkp-narrow-bounds dummy.c # x86 -mmpx
run_dummy -fchkp-narrow-to-innermost-array dummy.c
run_dummy -fchkp-optimize dummy.c # x86 -mmpx
run_dummy -fchkp-store-bounds dummy.c # x86 -mmpx
run_dummy -fchkp-treat-zero-dynamic-size-as-infinite dummy.c # x86 -mmpx
run_dummy -fchkp-use-fast-string-functions dummy.c # x86 -mmpx
run_dummy -fchkp-use-nochk-string-functions dummy.c # x86 -mmpx
run_dummy -fchkp-use-static-bounds dummy.c # x86 -mmpx
run_dummy -fchkp-use-static-const-bounds dummy.c # x86 -mmpx
run_dummy -fchkp-use-wrappers dummy.c # x86 -mmpx
run_dummy -fno-check-pointer-bounds dummy.c # x86 -mmpx
run_dummy -fno-chkp-check-incomplete-type dummy.c # x86 -mmpx
run_dummy -fno-chkp-check-read dummy.c # x86 -mmpx
run_dummy -fno-chkp-check-write dummy.c # x86 -mmpx
run_dummy -fno-chkp-first-field-has-own-bounds dummy.c # x86 -mmpx
run_dummy -fno-chkp-instrument-calls dummy.c # x86 -mmpx
run_dummy -fno-chkp-instrument-marked-only dummy.c # x86 -mmpx
run_dummy -fno-chkp-narrow-bounds dummy.c # x86 -mmpx
run_dummy -fno-chkp-narrow-to-innermost-array dummy.c
run_dummy -fno-chkp-optimize dummy.c # x86 -mmpx
run_dummy -fno-chkp-store-bounds dummy.c # x86 -mmpx
run_dummy -fno-chkp-treat-zero-dynamic-size-as-infinite dummy.c # x86 -mmpx
run_dummy -fno-chkp-use-fast-string-functions dummy.c # x86 -mmpx
run_dummy -fno-chkp-use-nochk-string-functions dummy.c # x86 -mmpx
run_dummy -fno-chkp-use-static-bounds dummy.c # x86 -mmpx
run_dummy -fno-chkp-use-static-const-bounds dummy.c # x86 -mmpx
run_dummy -fno-chkp-use-wrappers dummy.c # x86 -mmpx

run_dummy -fsanitize-trap=cast-strict dummy.c # LLVM bug


#################################################################################
#                                                                               #
#			     Preprocessor Options                               #
#                                                                               #
#################################################################################

logcon ""
logcon "Preprocessor options for both LLVM and GCC"

run_both -C -E dummy.c
run_both -DCARMICHAEL_PSEUDO_PRIME dummy.c
run_both -DFIRST_CARMICHAEL_PSEUDO_PRIME=561 dummy.c
run_both -dD -E dummy.c
run_both -dM -E dummy.c
run_both -fdollars-in-identifiers dummy-dollar.c
run_both -fexec-charset=UTF-8 dummy.c
run_both -fextended-identifiers dummy.c
run_both -finput-charset=UTF-8 dummy.c
run_both -fno-dollars-in-identifiers dummy.c
run_both -fno-show-column dummy.c
run_both -fpch-preprocess dummy.c
run_both -ftabstop=2 dummy.c
run_both -H dummy.c
run_both -idirafter . dummy.c
run_both -imacros dummy.h dummy.c
run_only_gcc -include `pwd`/dummy.h dummy.c # Currently broken on LLVM
run_both -iprefix ./ dummy.c
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
run_both -no-integrated-cpp dummy.c
run_both -nostdinc dummy.c
run_both -P dummy.c
run_both -trigraphs dummy.c # Also in C
run_both -U FORTY_TWO dummy.c
run_both -undef dummy.c
run_both -Wp,-v dummy.c
run_both -Xpreprocessor -I. dummy.c
logcon ""

logcon "Preprocessor options for LLVM but not GCC"

run_llvm -cxx-isystem `pwd`/llvm dummy.cpp
run_llvm -fcomment-block-commands="@param" dummy.cpp
run_llvm -fdeclspec dummy.c
run_llvm -fno-declspec dummy.c
run_llvm -fno-trigraphs dummy.c
run_llvm -ftrigraphs dummy.c
run_llvm -iframework`pwd`/llvm dummy.c
run_llvm -include-pch `pwd`/llvm/dummy.pch dummy.c
run_llvm -index-header-map dummy.c
run_llvm -iwithsysroot `pwd`/llvm dummy.c
run_llvm --migrate dummy.c
run_llvm -MV dummy.c
run_llvm --no-system-header-prefix=dummy dummy.c
run_llvm -nobuiltininc dummy.c
run_llvm -relocatable-pch dummy.c
run_llvm --system-header-prefix=dummy dummy.c
run_llvm -verify-pch dummy.pch
logcon ""

logcon "Preprocessor options for GCC but not LLVM"

run_gcc -A myassert=myval dummy-assert.c
run_gcc -A -myassert=myval dummy-noassert.c
run_gcc -dI dummy.c
run_gcc -dN dummy.c
run_gcc -fdebug-cpp -E dummy.c
run_gcc -fdirectives-only dummy.c
run_gcc -fno-working-directory dummy.c
run_gcc -fpch-deps dummy.c
run_gcc -fpreprocessed dummy-preproc.i
run_gcc -ftrack-macro-expansion dummy.c
run_gcc -fwide-exec-charset=UTF-8 dummy.c
run_gcc -fworking-directory dummy.c
run_gcc -imultilib . -c dummy.cpp # LLVM has this, but it affects linker as well
run_gcc -remap dummy.c
logcon ""

# Preprocessor options which appear not to work

run_dummy -version dummy.c # GCC only should work.


#################################################################################
#                                                                               #
#			      Assembler Options                                 #
#                                                                               #
#################################################################################

logcon ""
logcon "Assembler options for both LLVM and GCC"

run_both -Wa,-gdwarf-3 dummy.c
run_both -Xassembler -compress-debug-sections dummy.c
logcon ""

logcon "Assembler options for LLVM but not GCC"

run_llvm -fintegrated-as dummy.c
run_llvm -fno-integrated-as dummy.c
logcon ""

logcon "Assembler options for GCC but not LLVM"


#################################################################################
#                                                                               #
#				Linker Options                                  #
#                                                                               #
#################################################################################

logcon ""
logcon "Linker options for both LLVM and GCC"

run_both -fuse-ld=bfd dummy.c
run_both -fuse-ld=gold dummy.c
run_only_gcc  -lcode -L`pwd`/gcc dummy.c
run_only_llvm -lcode -L`pwd`/llvm dummy.c
run_only_gcc  -l code -L`pwd`/gcc dummy.c
run_only_llvm -l code -L`pwd`/llvm dummy.c
run_only_gcc -lobjc dummy.m  # LLVM bug - needs to be told where to look
run_both -nodefaultlibs -c dummy.c
run_both -nostartfiles dummy.c
run_both -nostdlib dummy.c
run_only_llvm -pie -fPIC dummy.c
run_only_gcc -pie dummy.c
run_both -rdynamic dummy.c
run_both -s dummy.c
run_both -shared -fpic dummy.c
run_both -static dummy.c
run_both -static-libgcc dummy.c
run_both -Wl,-relax dummy.c
run_both -Xlinker -M dummy.c
run_both -u var dummy.c
run_both -z defs dummy.c
logcon ""

logcon "Linker options for LLVM but not GCC"

run_llvm -fno-autolink dummy.c
run_llvm -fno-use-init-array dummy.c
run_llvm -fuse-init-array dummy.c
run_llvm -fveclib=Accelerate dummy.c
run_llvm -mincremental-linker-compatible dummy.c
run_llvm -mno-incremental-linker-compatible dummy.c
run_llvm -stdlib=libc++ dummy.cpp
logcon ""

logcon "Linker options for GCC but not LLVM"

run_gcc -shared-libgcc dummy.c
run_gcc -static-libasan dummy.c
run_gcc -static-liblsan dummy.c
run_gcc -static-libmpx dummy.c
run_gcc -static-libmpxwrappers dummy.c
run_gcc -static-libstdc++ dummy.c
run_gcc -static-libtsan dummy.c
run_gcc -static-libubsan dummy.c
run_gcc -T dummy.script -c dummy.c
logcon ""

# Not supported at all for this architecture

run_dummy -symbolic dummy.c


#################################################################################
#                                                                               #
#			      Directory Options                                 #
#                                                                               #
#################################################################################

logcon ""
logcon "Directory options for both LLVM and GCC"

run_both -I . dummy.c
run_both -iquote . dummy.c
run_both -iquote. dummy.c
run_only_gcc  -L`pwd`/gcc -lcode dummy.c  # Also in preproc
run_only_llvm -L`pwd`/llvm -lcode dummy.c
run_both --sysroot=`pwd` -c dummy.c
logcon ""

logcon "Directory options for LLVM but not GCC"

logcon ""

logcon "Directory options for GCC but not LLVM"

run_gcc -B`pwd` -E dummy-error.c
run_gcc -I- -I . dummy.c
run_gcc -iplugindir=`pwd`/gcc -fplugin=`pwd`/gcc/myplugin.so dummy.c
run_gcc -no-canonical-prefixes dummy.c
run_gcc --no-sysroot-suffix dummy.c
logcon ""


#################################################################################
#                                                                               #
#			   Code Generation Options                              #
#                                                                               #
#################################################################################

logcon ""
logcon "Code gen options for both LLVM and GCC"

run_both -fasynchronous-unwind-tables dummy.c
run_both -fcommon dummy.c # Default
run_both -fexceptions dummy.c
run_both -fno-common dummy.c
run_both -fno-ident dummy.c
run_both -fno-short-wchar dummy.c # Default
run_both -fnon-call-exceptions dummy.c
run_both -fpack-struct dummy.c
run_both -fpack-struct=4 dummy.c
run_both -fPIC dummy.c
run_both -fpic dummy.c
run_both -fPIE dummy.c
run_both -fpie dummy.c
run_both -fshort-enums dummy.c
run_both -fshort-wchar dummy.c
run_both -ftls-model=initial-exec dummy.c
run_both -ftls-model=global-dynamic dummy.c
run_both -ftls-model=local-dynamic dummy.c
run_both -ftls-model=local-exec dummy.c
run_both -ftrapv dummy.c
run_both -funwind-tables dummy.c
run_both -fverbose-asm dummy.c
run_both -fvisibility=default dummy.c
run_both -fvisibility=hidden dummy.c
run_both -fvisibility=internal dummy.c
run_both -fvisibility=protected dummy.c
run_both -fwrapv dummy.c
run_both --target=i686-pc-linux-gnu -c dummy.c
logcon ""

logcon "Code gen options for LLVM but not GCC"

run_llvm -fapple-kext dummy.c
run_llvm -fapple-pragma-pack dummy.c
run_llvm -fapplication-extension dummy.c
run_llvm -fmax-type-align=2 dummy.c
run_llvm -ftrap-function=main dummy.c
run_llvm -ftrapv-handler=main dummy.c
run_llvm -mllvm -addr-sink-using-gep dummy.c # One example from cc1
run_llvm -mstack-alignment=2 dummy.c
run_llvm -mstack-probe-size=2 dummy.c
run_llvm -mthread-model posix dummy.c
run_llvm -resource-dir=${clangdir} dummy.c
run_llvm -target i686-pc-linux-gnu -c dummy.c
logcon ""

logcon "Code gen options for GCC but not LLVM"

run_gcc -fcall-saved-rax dummy.c
run_gcc -fcall-used-rax dummy.c
run_gcc -fdelete-dead-exceptions dummy.c
run_gcc -ffixed-rax dummy.c
run_gcc -finhibit-size-directive dummy.c
run_gcc -fleading-underscore -c dummy.c
run_gcc -fno-gnu-unique dummy.c
run_gcc -fno-jump-tables dummy.c
run_gcc -fno-plt dummy.cpp
run_gcc -fpcc-struct-return dummy.c
run_gcc -frecord-gcc-switches dummy.c
run_gcc -freg-struct-return dummy.c
run_gcc -fshort-double -E dummy.c # GCC only, but causes ICE
run_gcc -fstack-reuse=all dummy.c
run_gcc -fstack-reuse=named_vars dummy.c
run_gcc -fstack-reuse=none dummy.c
run_gcc -fstrict-volatile-bitfields dummy.c
run_gcc -fsync-libcalls dummy.c
logcon ""

# Options which currently do not run

run_dummy -faltivec dummy.c # PPC only
run_dummy -fno-math-builtin dummy.c # Bug in LLVM, not passed from driver
run_dummy -module-dependency-dir `pwd`/llvm dummy.c # Ditto


#################################################################################
#                                                                               #
#			      Developer Options                                 #
#                                                                               #
#################################################################################

logcon ""
logcon "Developer options for both LLVM and GCC"

run_both -dumpmachine dummy.c
run_both -dumpversion dummy.c
run_both -frandom-seed=561 dummy.c
run_both -ftime-report dummy.c
run_both -print-file-name=code -L`pwd` dummy.c
run_both -print-libgcc-file-name dummy.c
run_both -print-multi-directory dummy.c
run_both -print-multi-lib dummy.c
run_both -print-prog-name=cpp dummy.c
run_both -print-search-dirs dummy.c
run_both -save-temps dummy.c
run_both -save-temps=cwd dummy.c
run_both -save-temps=obj dummy.c
logcon ""

logcon "Developer options for LLVM but not GCC"

run_llvm -ccc-arcmt-check dummy.m
run_llvm -ccc-arcmt-migrate /tmp dummy.m
run_llvm -ccc-arcmt-modify dummy.m
run_llvm -ccc-gcc-name ${gccexec} dummy.c
run_llvm -ccc-install-dir /tmp dummy.c
run_llvm -ccc-objcmt-migrate /tmp dummy.m
run_llvm -ccc-pch-is-pch dummy.c
run_llvm -ccc-pch-is-pth dummy.c
run_llvm -ccc-print-bindings dummy.c
run_llvm -ccc-print-phases dummy.c
run_llvm --driver-mode=cpp dummy.c
run_llvm --driver-mode=g++ dummy.c
run_llvm --driver-mode=gcc dummy.c
run_llvm -print-ivar-layout -c dummy.m
run_llvm -Reverything dummy.c
run_llvm -Rpass=aa-eval dummy.c # Analysis passes
run_llvm -Rpass=basicaa dummy.c
run_llvm -Rpass=basiccg dummy.c
run_llvm -Rpass=count-aa dummy.c
run_llvm -Rpass=da dummy.c
run_llvm -Rpass=debug-aa dummy.c
run_llvm -Rpass=domfrontier dummy.c
run_llvm -Rpass=domtree dummy.c
run_llvm -Rpass=dot-callgraph dummy.c
run_llvm -Rpass=dot-cfg dummy.c
run_llvm -Rpass=dot-cfg-only dummy.c
run_llvm -Rpass=dot-dom dummy.c
run_llvm -Rpass=dot-dom-only dummy.c
run_llvm -Rpass=dot-postdom dummy.c
run_llvm -Rpass=dot-postdom-only dummy.c
run_llvm -Rpass=globalsmodref-aa dummy.c
run_llvm -Rpass=instcount dummy.c
run_llvm -Rpass=intervals dummy.c
run_llvm -Rpass=iv-users dummy.c
run_llvm -Rpass=lazy-value-info dummy.c
run_llvm -Rpass=libcall-aa dummy.c
run_llvm -Rpass=lint dummy.c
run_llvm -Rpass=loops dummy.c
run_llvm -Rpass=memdep dummy.c
run_llvm -Rpass=module-debuginfo dummy.c
run_llvm -Rpass=no-aa dummy.c
run_llvm -Rpass=postdomfrontier dummy.c
run_llvm -Rpass=postdomtree dummy.c
run_llvm -Rpass=print-alias-sets dummy.c
run_llvm -Rpass=print-callgraph dummy.c
run_llvm -Rpass=print-callgraph-sccs dummy.c
run_llvm -Rpass=print-cfg-sccs dummy.c
run_llvm -Rpass=print-dom-info dummy.c
run_llvm -Rpass=print-externalfnconstants dummy.c
run_llvm -Rpass=print-function dummy.c
run_llvm -Rpass=print-module dummy.c
run_llvm -Rpass=print-used-types dummy.c
run_llvm -Rpass=regions dummy.c
run_llvm -Rpass=scalar-evolution dummy.c
run_llvm -Rpass=scev-aa dummy.c
run_llvm -Rpass=targetdata dummy.c
run_llvm -Rpass=adce dummy.c # Transform Passes
run_llvm -Rpass=always-inline dummy.c
run_llvm -Rpass=argpromotion dummy.c
run_llvm -Rpass=bb-vectorize dummy.c
run_llvm -Rpass=block-placement dummy.c
run_llvm -Rpass=break-crit-edges dummy.c
run_llvm -Rpass=codegenprepare dummy.c
run_llvm -Rpass=constmerge dummy.c
run_llvm -Rpass=constprop dummy.c
run_llvm -Rpass=dce dummy.c
run_llvm -Rpass=deadargelim dummy.c
run_llvm -Rpass=deadtypeelim dummy.c
run_llvm -Rpass=die dummy.c
run_llvm -Rpass=dse dummy.c
run_llvm -Rpass=functionattrs dummy.c
run_llvm -Rpass=globaldce dummy.c
run_llvm -Rpass=globalopt dummy.c
run_llvm -Rpass=gvn dummy.c
run_llvm -Rpass=indvars dummy.c
run_llvm -Rpass=inline dummy.c
run_llvm -Rpass=instcombine dummy.c
run_llvm -Rpass=internalize dummy.c
run_llvm -Rpass=ipconstprop dummy.c
run_llvm -Rpass=ipsccp dummy.c
run_llvm -Rpass=jump-threading dummy.c
run_llvm -Rpass=lcssa dummy.c
run_llvm -Rpass=licm dummy.c
run_llvm -Rpass=loop-deletion dummy.c
run_llvm -Rpass=loop-extract dummy.c
run_llvm -Rpass=loop-extract-single dummy.c
run_llvm -Rpass=loop-reduce dummy.c
run_llvm -Rpass=loop-rotate dummy.c
run_llvm -Rpass=loop-simplify dummy.c
run_llvm -Rpass=loop-unroll dummy.c
run_llvm -Rpass=loop-unswitch dummy.c
run_llvm -Rpass=loweratomic dummy.c
run_llvm -Rpass=lowerinvoke dummy.c
run_llvm -Rpass=lowerswitch dummy.c
run_llvm -Rpass=mem2reg dummy.c
run_llvm -Rpass=memcpyopt dummy.c
run_llvm -Rpass=mergefunc dummy.c
run_llvm -Rpass=mergereturn dummy.c
run_llvm -Rpass=partial-inliner dummy.c
run_llvm -Rpass=prune-eh dummy.c
run_llvm -Rpass=reassociate dummy.c
run_llvm -Rpass=reg2mem dummy.c
run_llvm -Rpass=scalarrepl dummy.c
run_llvm -Rpass=sccp dummy.c
run_llvm -Rpass=simplifycfg dummy.c
run_llvm -Rpass=sink dummy.c
run_llvm -Rpass=strip dummy.c
run_llvm -Rpass=strip-dead-debug-info dummy.c
run_llvm -Rpass=strip-dead-prototypes dummy.c
run_llvm -Rpass=strip-debug-declare dummy.c
run_llvm -Rpass=strip-nondebug dummy.c
run_llvm -Rpass=tailcallelim dummy.c
run_llvm -Rpass=deadarghaX0r dummy.c # Utility Passes
run_llvm -Rpass=extract-blocks dummy.c
run_llvm -Rpass=instnamer dummy.c
run_llvm -Rpass=verify dummy.c
run_llvm -Rpass=view-cfg dummy.c
run_llvm -Rpass=view-cfg-only dummy.c
run_llvm -Rpass=view-dom dummy.c
run_llvm -Rpass=view-dom-only dummy.c
run_llvm -Rpass=view-postdom dummy.c
run_llvm -Rpass=view-postdom-only dummy.c
run_llvm -Rpass-analysis=aa-eval dummy.c # Analysis passes
run_llvm -Rpass-analysis=basicaa dummy.c
run_llvm -Rpass-analysis=basiccg dummy.c
run_llvm -Rpass-analysis=count-aa dummy.c
run_llvm -Rpass-analysis=da dummy.c
run_llvm -Rpass-analysis=debug-aa dummy.c
run_llvm -Rpass-analysis=domfrontier dummy.c
run_llvm -Rpass-analysis=domtree dummy.c
run_llvm -Rpass-analysis=dot-callgraph dummy.c
run_llvm -Rpass-analysis=dot-cfg dummy.c
run_llvm -Rpass-analysis=dot-cfg-only dummy.c
run_llvm -Rpass-analysis=dot-dom dummy.c
run_llvm -Rpass-analysis=dot-dom-only dummy.c
run_llvm -Rpass-analysis=dot-postdom dummy.c
run_llvm -Rpass-analysis=dot-postdom-only dummy.c
run_llvm -Rpass-analysis=globalsmodref-aa dummy.c
run_llvm -Rpass-analysis=instcount dummy.c
run_llvm -Rpass-analysis=intervals dummy.c
run_llvm -Rpass-analysis=iv-users dummy.c
run_llvm -Rpass-analysis=lazy-value-info dummy.c
run_llvm -Rpass-analysis=libcall-aa dummy.c
run_llvm -Rpass-analysis=lint dummy.c
run_llvm -Rpass-analysis=loops dummy.c
run_llvm -Rpass-analysis=memdep dummy.c
run_llvm -Rpass-analysis=module-debuginfo dummy.c
run_llvm -Rpass-analysis=no-aa dummy.c
run_llvm -Rpass-analysis=postdomfrontier dummy.c
run_llvm -Rpass-analysis=postdomtree dummy.c
run_llvm -Rpass-analysis=print-alias-sets dummy.c
run_llvm -Rpass-analysis=print-callgraph dummy.c
run_llvm -Rpass-analysis=print-callgraph-sccs dummy.c
run_llvm -Rpass-analysis=print-cfg-sccs dummy.c
run_llvm -Rpass-analysis=print-dom-info dummy.c
run_llvm -Rpass-analysis=print-externalfnconstants dummy.c
run_llvm -Rpass-analysis=print-function dummy.c
run_llvm -Rpass-analysis=print-module dummy.c
run_llvm -Rpass-analysis=print-used-types dummy.c
run_llvm -Rpass-analysis=regions dummy.c
run_llvm -Rpass-analysis=scalar-evolution dummy.c
run_llvm -Rpass-analysis=scev-aa dummy.c
run_llvm -Rpass-analysis=targetdata dummy.c
run_llvm -Rpass-analysis=adce dummy.c # Transform Passes
run_llvm -Rpass-analysis=always-inline dummy.c
run_llvm -Rpass-analysis=argpromotion dummy.c
run_llvm -Rpass-analysis=bb-vectorize dummy.c
run_llvm -Rpass-analysis=block-placement dummy.c
run_llvm -Rpass-analysis=break-crit-edges dummy.c
run_llvm -Rpass-analysis=codegenprepare dummy.c
run_llvm -Rpass-analysis=constmerge dummy.c
run_llvm -Rpass-analysis=constprop dummy.c
run_llvm -Rpass-analysis=dce dummy.c
run_llvm -Rpass-analysis=deadargelim dummy.c
run_llvm -Rpass-analysis=deadtypeelim dummy.c
run_llvm -Rpass-analysis=die dummy.c
run_llvm -Rpass-analysis=dse dummy.c
run_llvm -Rpass-analysis=functionattrs dummy.c
run_llvm -Rpass-analysis=globaldce dummy.c
run_llvm -Rpass-analysis=globalopt dummy.c
run_llvm -Rpass-analysis=gvn dummy.c
run_llvm -Rpass-analysis=indvars dummy.c
run_llvm -Rpass-analysis=inline dummy.c
run_llvm -Rpass-analysis=instcombine dummy.c
run_llvm -Rpass-analysis=internalize dummy.c
run_llvm -Rpass-analysis=ipconstprop dummy.c
run_llvm -Rpass-analysis=ipsccp dummy.c
run_llvm -Rpass-analysis=jump-threading dummy.c
run_llvm -Rpass-analysis=lcssa dummy.c
run_llvm -Rpass-analysis=licm dummy.c
run_llvm -Rpass-analysis=loop-deletion dummy.c
run_llvm -Rpass-analysis=loop-extract dummy.c
run_llvm -Rpass-analysis=loop-extract-single dummy.c
run_llvm -Rpass-analysis=loop-reduce dummy.c
run_llvm -Rpass-analysis=loop-rotate dummy.c
run_llvm -Rpass-analysis=loop-simplify dummy.c
run_llvm -Rpass-analysis=loop-unroll dummy.c
run_llvm -Rpass-analysis=loop-unswitch dummy.c
run_llvm -Rpass-analysis=loweratomic dummy.c
run_llvm -Rpass-analysis=lowerinvoke dummy.c
run_llvm -Rpass-analysis=lowerswitch dummy.c
run_llvm -Rpass-analysis=mem2reg dummy.c
run_llvm -Rpass-analysis=memcpyopt dummy.c
run_llvm -Rpass-analysis=mergefunc dummy.c
run_llvm -Rpass-analysis=mergereturn dummy.c
run_llvm -Rpass-analysis=partial-inliner dummy.c
run_llvm -Rpass-analysis=prune-eh dummy.c
run_llvm -Rpass-analysis=reassociate dummy.c
run_llvm -Rpass-analysis=reg2mem dummy.c
run_llvm -Rpass-analysis=scalarrepl dummy.c
run_llvm -Rpass-analysis=sccp dummy.c
run_llvm -Rpass-analysis=simplifycfg dummy.c
run_llvm -Rpass-analysis=sink dummy.c
run_llvm -Rpass-analysis=strip dummy.c
run_llvm -Rpass-analysis=strip-dead-debug-info dummy.c
run_llvm -Rpass-analysis=strip-dead-prototypes dummy.c
run_llvm -Rpass-analysis=strip-debug-declare dummy.c
run_llvm -Rpass-analysis=strip-nondebug dummy.c
run_llvm -Rpass-analysis=tailcallelim dummy.c
run_llvm -Rpass-analysis=deadarghaX0r dummy.c # Utility Passes
run_llvm -Rpass-analysis=extract-blocks dummy.c
run_llvm -Rpass-analysis=instnamer dummy.c
run_llvm -Rpass-analysis=verify dummy.c
run_llvm -Rpass-analysis=view-cfg dummy.c
run_llvm -Rpass-analysis=view-cfg-only dummy.c
run_llvm -Rpass-analysis=view-dom dummy.c
run_llvm -Rpass-analysis=view-dom-only dummy.c
run_llvm -Rpass-analysis=view-postdom dummy.c
run_llvm -Rpass-analysis=view-postdom-only dummy.c
run_llvm -Rpass-missed=aa-eval dummy.c # Analysis passes
run_llvm -Rpass-missed=basicaa dummy.c
run_llvm -Rpass-missed=basiccg dummy.c
run_llvm -Rpass-missed=count-aa dummy.c
run_llvm -Rpass-missed=da dummy.c
run_llvm -Rpass-missed=debug-aa dummy.c
run_llvm -Rpass-missed=domfrontier dummy.c
run_llvm -Rpass-missed=domtree dummy.c
run_llvm -Rpass-missed=dot-callgraph dummy.c
run_llvm -Rpass-missed=dot-cfg dummy.c
run_llvm -Rpass-missed=dot-cfg-only dummy.c
run_llvm -Rpass-missed=dot-dom dummy.c
run_llvm -Rpass-missed=dot-dom-only dummy.c
run_llvm -Rpass-missed=dot-postdom dummy.c
run_llvm -Rpass-missed=dot-postdom-only dummy.c
run_llvm -Rpass-missed=globalsmodref-aa dummy.c
run_llvm -Rpass-missed=instcount dummy.c
run_llvm -Rpass-missed=intervals dummy.c
run_llvm -Rpass-missed=iv-users dummy.c
run_llvm -Rpass-missed=lazy-value-info dummy.c
run_llvm -Rpass-missed=libcall-aa dummy.c
run_llvm -Rpass-missed=lint dummy.c
run_llvm -Rpass-missed=loops dummy.c
run_llvm -Rpass-missed=memdep dummy.c
run_llvm -Rpass-missed=module-debuginfo dummy.c
run_llvm -Rpass-missed=no-aa dummy.c
run_llvm -Rpass-missed=postdomfrontier dummy.c
run_llvm -Rpass-missed=postdomtree dummy.c
run_llvm -Rpass-missed=print-alias-sets dummy.c
run_llvm -Rpass-missed=print-callgraph dummy.c
run_llvm -Rpass-missed=print-callgraph-sccs dummy.c
run_llvm -Rpass-missed=print-cfg-sccs dummy.c
run_llvm -Rpass-missed=print-dom-info dummy.c
run_llvm -Rpass-missed=print-externalfnconstants dummy.c
run_llvm -Rpass-missed=print-function dummy.c
run_llvm -Rpass-missed=print-module dummy.c
run_llvm -Rpass-missed=print-used-types dummy.c
run_llvm -Rpass-missed=regions dummy.c
run_llvm -Rpass-missed=scalar-evolution dummy.c
run_llvm -Rpass-missed=scev-aa dummy.c
run_llvm -Rpass-missed=targetdata dummy.c
run_llvm -Rpass-missed=adce dummy.c # Transform Passes
run_llvm -Rpass-missed=always-inline dummy.c
run_llvm -Rpass-missed=argpromotion dummy.c
run_llvm -Rpass-missed=bb-vectorize dummy.c
run_llvm -Rpass-missed=block-placement dummy.c
run_llvm -Rpass-missed=break-crit-edges dummy.c
run_llvm -Rpass-missed=codegenprepare dummy.c
run_llvm -Rpass-missed=constmerge dummy.c
run_llvm -Rpass-missed=constprop dummy.c
run_llvm -Rpass-missed=dce dummy.c
run_llvm -Rpass-missed=deadargelim dummy.c
run_llvm -Rpass-missed=deadtypeelim dummy.c
run_llvm -Rpass-missed=die dummy.c
run_llvm -Rpass-missed=dse dummy.c
run_llvm -Rpass-missed=functionattrs dummy.c
run_llvm -Rpass-missed=globaldce dummy.c
run_llvm -Rpass-missed=globalopt dummy.c
run_llvm -Rpass-missed=gvn dummy.c
run_llvm -Rpass-missed=indvars dummy.c
run_llvm -Rpass-missed=inline dummy.c
run_llvm -Rpass-missed=instcombine dummy.c
run_llvm -Rpass-missed=internalize dummy.c
run_llvm -Rpass-missed=ipconstprop dummy.c
run_llvm -Rpass-missed=ipsccp dummy.c
run_llvm -Rpass-missed=jump-threading dummy.c
run_llvm -Rpass-missed=lcssa dummy.c
run_llvm -Rpass-missed=licm dummy.c
run_llvm -Rpass-missed=loop-deletion dummy.c
run_llvm -Rpass-missed=loop-extract dummy.c
run_llvm -Rpass-missed=loop-extract-single dummy.c
run_llvm -Rpass-missed=loop-reduce dummy.c
run_llvm -Rpass-missed=loop-rotate dummy.c
run_llvm -Rpass-missed=loop-simplify dummy.c
run_llvm -Rpass-missed=loop-unroll dummy.c
run_llvm -Rpass-missed=loop-unswitch dummy.c
run_llvm -Rpass-missed=loweratomic dummy.c
run_llvm -Rpass-missed=lowerinvoke dummy.c
run_llvm -Rpass-missed=lowerswitch dummy.c
run_llvm -Rpass-missed=mem2reg dummy.c
run_llvm -Rpass-missed=memcpyopt dummy.c
run_llvm -Rpass-missed=mergefunc dummy.c
run_llvm -Rpass-missed=mergereturn dummy.c
run_llvm -Rpass-missed=partial-inliner dummy.c
run_llvm -Rpass-missed=prune-eh dummy.c
run_llvm -Rpass-missed=reassociate dummy.c
run_llvm -Rpass-missed=reg2mem dummy.c
run_llvm -Rpass-missed=scalarrepl dummy.c
run_llvm -Rpass-missed=sccp dummy.c
run_llvm -Rpass-missed=simplifycfg dummy.c
run_llvm -Rpass-missed=sink dummy.c
run_llvm -Rpass-missed=strip dummy.c
run_llvm -Rpass-missed=strip-dead-debug-info dummy.c
run_llvm -Rpass-missed=strip-dead-prototypes dummy.c
run_llvm -Rpass-missed=strip-debug-declare dummy.c
run_llvm -Rpass-missed=strip-nondebug dummy.c
run_llvm -Rpass-missed=tailcallelim dummy.c
run_llvm -Rpass-missed=deadarghaX0r dummy.c # Utility Passes
run_llvm -Rpass-missed=extract-blocks dummy.c
run_llvm -Rpass-missed=instnamer dummy.c
run_llvm -Rpass-missed=verify dummy.c
run_llvm -Rpass-missed=view-cfg dummy.c
run_llvm -Rpass-missed=view-cfg-only dummy.c
run_llvm -Rpass-missed=view-dom dummy.c
run_llvm -Rpass-missed=view-dom-only dummy.c
run_llvm -Rpass-missed=view-postdom dummy.c
run_llvm -Rpass-missed=view-postdom-only dummy.c
run_llvm -Xanalyzer -v --analyze dummy.c
run_llvm -via-file-asm dummy.c
logcon ""

logcon "Developer options for GCC but not LLVM"

run_gcc -da dummy.c
run_gcc -dA dummy.c
run_gcc -dH dummy.c
run_gcc -dp dummy.c
run_gcc -dP dummy.c
run_gcc -dU dummy.c
run_gcc -dx -c dummy.c
run_gcc -dumpspecs dummy.c
run_gcc -fchecking dummy.c
run_gcc -fcompare-debug dummy.c
run_gcc -fcompare-debug= dummy.c
run_gcc -fcompare-debug=-gtoggle dummy.c
run_gcc -fcompare-debug-second dummy.c
run_gcc -fdbg-cnt=dce:10,tail_call:0 dummy.c
run_gcc -fdbg-cnt-list -c dummy.c
run_gcc -fdisable-ipa-inline dummy.c
run_gcc -fdisable-rtl-gcse2 dummy.c
run_gcc -fdisable-rtl-gcse2=foo,foo2 dummy.c
run_gcc -fdisable-tree-cunroll dummy.c
run_gcc -fdisable-tree-cunroll=1 dummy.c
run_gcc -fdump-class-hierarchy dummy.cpp
run_gcc -fdump-class-hierarchy=address dummy.cpp
run_gcc -fdump-class-hierarchy=asmname dummy.cpp
run_gcc -fdump-class-hierarchy=slim dummy.cpp
run_gcc -fdump-class-hierarchy=raw dummy.cpp
run_gcc -fdump-class-hierarchy=details dummy.cpp
run_gcc -fdump-class-hierarchy=stats dummy.cpp
run_gcc -fdump-class-hierarchy=blocks dummy.cpp
run_gcc -fdump-class-hierarchy=graph dummy.cpp
run_gcc -fdump-class-hierarchy=vops dummy.cpp
run_gcc -fdump-class-hierarchy=lineno dummy.cpp
run_gcc -fdump-class-hierarchy=uid dummy.cpp
run_gcc -fdump-class-hierarchy=verbose dummy.cpp
run_gcc -fdump-class-hierarchy=eh dummy.cpp
run_gcc -fdump-class-hierarchy=scev dummy.cpp
run_gcc -fdump-class-hierarchy=optimized dummy.cpp
run_gcc -fdump-class-hierarchy=missed dummy.cpp
run_gcc -fdump-class-hierarchy=note dummy.cpp
run_gcc -fdump-class-hierarchy=debug.dump dummy.cpp
run_gcc -fdump-class-hierarchy=all dummy.cpp
run_gcc -fdump-class-hierarchy=optall dummy.cpp
run_gcc -fdump-final-insns=dummy.gkd dummy.c
run_gcc -fdump-ipa-all dummy.c
run_gcc -fdump-ipa-cgraph dummy.c
run_gcc -fdump-ipa-inline dummy.c
run_gcc -fdump-noaddr dummy.c
run_gcc -fdump-passes dummy.c
run_gcc -fdump-rtl-alignments dummy.c
run_gcc -fdump-rtl-alignments=dummy.out dummy.c
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
run_gcc -fdump-tree-backprop dummy.c
run_gcc -fdump-tree-ccp-all dummy.c
run_gcc -fdump-tree-ccp-all=dummy.out dummy.c
run_gcc -fdump-tree-cfg dummy.c
run_gcc -fdump-tree-ch dummy.c
run_gcc -fdump-tree-copyprop dummy.c
run_gcc -fdump-tree-dce dummy.c
run_gcc -fdump-tree-dom dummy.c
run_gcc -fdump-tree-dse dummy.c
run_gcc -fdump-tree-forwprop dummy.c
run_gcc -fdump-tree-fre dummy.c
run_gcc -fdump-tree-gimple dummy.c
run_gcc -fdump-tree-nrv dummy.c
run_gcc -fdump-tree-oaccdevlow dummy.c
run_gcc -fdump-tree-optimized dummy.c
run_gcc -fdump-tree-original dummy.c
run_gcc -fdump-tree-phiopt dummy.c
run_gcc -fdump-tree-phiprop dummy.c
run_gcc -fdump-tree-pre dummy.c
run_gcc -fdump-tree-sink dummy.c
run_gcc -fdump-tree-slp dummy.c
run_gcc -fdump-tree-split-paths dummy.c
run_gcc -fdump-tree-sra dummy.c
run_gcc -fdump-tree-ssa dummy.c
run_dummy -fdump-tree-store_copyprop dummy.c # Documented, but not implemeted
run_gcc -fdump-tree-vect dummy.c
run_gcc -fdump-tree-vrp dummy.c
run_gcc -fdump-tree-vtable-verify dummy.c
run_gcc -fdump-unnumbered dummy.c
run_gcc -fdump-unnumbered-links dummy.c
run_gcc -fdump-translation-unit dummy.cpp
run_gcc -fdump-translation-unit=all dummy.cpp
run_gcc -fenable-ipa-inline dummy.c
run_gcc -fenable-rtl-gcse2=foo,foo2 dummy.c
run_gcc -fenable-tree-cunroll=1 dummy.c
run_gcc -fira-verbose=15 dummy.c
run_gcc -flto-report dummy.c
run_gcc -flto-report-wpa dummy.c
run_gcc -fmem-report dummy.c
run_gcc -fmem-report-wpa dummy.c
run_gcc -fno-checking dummy.c # Default
run_gcc -fno-compare-debug dummy.cpp # Default
run_gcc -fno-var-tracking-assignments-toggle dummy.c # Default
run_gcc -fopt-info dummy.c
run_gcc -fopt-info-all dummy.c
run_gcc -fopt-info-all=dummy.out dummy.c
run_gcc -fpost-ipa-mem-report dummy.c
run_gcc -fpre-ipa-mem-report dummy.c
run_gcc -fprofile-report dummy.c
run_gcc -freport-bug dummy.c
run_gcc -fsched-verbose=4 dummy.c
run_gcc -fstack-usage dummy.c
run_gcc -fstats dummy.c
run_gcc -fvar-tracking-assignments-toggle dummy.c
run_gcc -gtoggle dummy.c # Also in Debugging Options
run_gcc -print-multi-os-directory dummy.c
run_gcc -print-multiarch dummy.c
run_gcc -print-sysroot dummy.c
run_gcc -Q --help=target dummy.c
run_gcc -time dummy.c # LLVM --help claims this works
run_gcc -time=time.dat dummy.c
logcon ""

# GCC documented but not actually implemented.

run_dummy -fdump-rtl-bypass dummy.c
run_dummy -fdump-rtl-dce dummy.c
run_dummy -fdump-rtl-dce1 dummy.c
run_dummy -fdump-rtl-dce2 dummy.c
run_dummy -fdump-rtl-eh dummy.c
run_dummy -fdump-rtl-gcse1 dummy.c
run_dummy -fdump-rtl-initvals dummy.c
run_dummy -fdump-rtl-regclass dummy.c
run_dummy -fdump-rtl-seqabstr dummy.c
run_dummy -fdump-rtl-sibling dummy.c
run_dummy -fdump-rtl-subregs_of_mode_finish dummy.c
run_dummy -fdump-rtl-subregs_of_mode_init dummy.c
run_dummy -fdump-rtl-unshare dummy.c
run_dummy -fdump-tree-storeccp dummy.c


# Not supported at all for this architecture

run_dummy --driver-mode=cl dummy.c # MS LLVM only
run_dummy -print-sysroot-headers-suffix dummy.c # Not configured for x86_64


#################################################################################
#                                                                               #
#				Other Options                                   #
#                                                                               #
#################################################################################


# Options that will not run for various reasons


# LLVM target specific options from -help

run_dummy -arcmt-migrate-emit-errors -c dummy.m # Darwin only
run_dummy -arcmt-migrate-report-output ${tmpf} -c dummy.m # Darwin only
run_dummy --cuda-device-only dummy.c
run_dummy --cuda-gpu-arch=hexagon dummy.c
run_dummy --cuda-host-only dummy.c
run_dummy --cuda-path=${tmpd} dummy.c
run_dummy -F`pwd` dummy.c # Darwin only
run_dummy -femulated-tls dummy.c # Target specific for LLVM
run_dummy -ffix-and-continue dummy.c # Darwin
run_dummy -ffixed-r9 dummy.c # ARM specific
run_dummy -ffixed-x18 dummy.c # AArch64 only
run_dummy -findirect-data dummy.c # Darwin
run_dummy -fmax-type-align dummy.c # Darwin
run_dummy -fno-keep-inline-dllexport dummy.c # MSVC only?
run_dummy -fobjc-weak dummy.m # Target specific (Darwin?)
run_dummy -fzvector dummy.c # System/Z only
run_dummy -image_base dummy.c # Darwin
run_dummy -init dummy.c # Darwin
run_dummy -install_name dummy.c # Darwin
run_dummy -keep_private_externs dummy.c # Darwin
run_dummy -mabicalls dummy.c # MIPS only
run_dummy -mcrc dummy.c # ARM only
run_dummy -meabi gnu dummy.c # ARM only
run_dummy -mfix-cortex-a53-835769 # AArch64 only
run_dummy -mfp32 dummy.c # MIPS only
run_dummy -mfp64 dummy.c # MIPS only
run_dummy -mfpmath dummy.c # x86 only
run_dummy -mfpxx dummy.c # MIPS only
run_dummy -mgeneral-regs-only dummy.c # AArch64 only
run_dummy -mglobal-merge dummy.c # ARM only
run_dummy -mhvx dummy.c # Hexagon only
run_dummy -mhvx-double dummy.c # Hexagon only
run_dummy -mno-implicit-float dummy.c
run_dummy -mios-version-min=10 dummy.c # Darwin only
run_dummy -mips1 dummy.c # MIPS only
run_dummy -mips2 dummy.c # MIPS only
run_dummy -mips32r2 dummy.c # MIPS only
run_dummy -mips32r3 dummy.c # MIPS only
run_dummy -mips32r5 dummy.c # MIPS only
run_dummy -mips32r6 dummy.c # MIPS only
run_dummy -mips32 dummy.c # MIPS only
run_dummy -mips3 dummy.c # MIPS only
run_dummy -mips4 dummy.c # MIPS only
run_dummy -mips5 dummy.c # MIPS only
run_dummy -mips64r2 dummy.c # MIPS only
run_dummy -mips64r3 dummy.c # MIPS only
run_dummy -mips64r5 dummy.c # MIPS only
run_dummy -mips64r6 dummy.c # MIPS only
run_dummy -mips64 dummy.c # MIPS only
run_dummy -mlong-calls dummy.c # ARM only
run_dummy -mmacosx-version-min=10 dummy.c # Darwin only
run_dummy -mms-bitfields dummy.c # x86 only
run_dummy -mmsa dummy.c # MIPS only
run_dummy -mno-abicalls dummy.c # MIPS only
run_dummy -mno-global-merge dummy.c # ARM only
run_dummy -mno-hvx dummy.c # Hexagon only
run_dummy -mno-hvx-double dummy.c # Hexagon only
run_dummy -mno-long-calls dummy.c # ARM only
run_dummy -mno-movt dummy.c # ARM only
run_dummy -mno-ms-bitfields dummy.c # x86 only
run_dummy -mno-msa dummy.c # MIPS only
run_dummy -mno-odd-spreg dummy.c # MIPS only
run_dummy -mno-restrict-it dummy.c # ARM8 only
run_dummy -mno-unaligned-access dummy.c # AArch32/AArch64 only
run_dummy -mnocrc dummy.c # ARM only
run_dummy -modd-spreg dummy.c # MIPS only
run_dummy -momit-leaf-frame-pointer dummy.c # x86 only
run_dummy -mqdsp6-compat dummy.c # Hexagon only
run_dummy -mrestrict-it dummy.c # ARM8 only
run_dummy -mrtd dummy.c # x86 only
run_dummy -msoft-float dummy.c # x86 only
run_dummy -mstackrealign dummy.c # x86 only
run_dummy -mstrict-align dummy.c # AArch32/AArch64 only
run_dummy -munaligned-access dummy.c # AArch32/AArch64 only
run_dummy -mno-fix-cortex-a53-835769 # AArch64 only
run_dummy -no_dead_strip_inits_and_terms dummy.c # Darwin
run_dummy -noall_load dummy.c # Darwin
run_dummy -nofixprebinding dummy.c # Darwin
run_dummy -nomultidefs dummy.c # Darwin
run_dummy -noprefind dummy.c # Darwin
run_dummy -noseglinkedit dummy.c # Darwin
run_dummy -pagezero_size dummy.c # Darwin
run_dummy -private_bundle dummy.c # Darwin
run_dummy -pthread dummy.c # Target specific for GCC and LLVM
run_dummy -pthreads dummy.c # Target specific for LLVM
run_dummy -read_only_relocs dummy.c # Darwin
run_dummy -sectalign dummy.c # Darwin
run_dummy -sectcreate dummy.c # Darwin
run_dummy -sectobjectsymbols dummy.c # Darwin
run_dummy -sectorder dummy.c # Darwin
run_dummy -seg1addr dummy.c # Darwin
run_dummy -seg_addr_table dummy.c # Darwin
run_dummy -seg_addr_table_filename dummy.c # Darwin
run_dummy -segaddr dummy.c # Darwin
run_dummy -seglinkedit dummy.c # Darwin
run_dummy -segprot dummy.c # Darwin
run_dummy -segs_read_only_addr dummy.c # Darwin
run_dummy -segs_read_write_addr dummy.c # Darwin
run_dummy -single_module dummy.c # Darwin
run_dummy -sub_library dummy.c # Darwin
run_dummy -sub_umbrella dummy.c # Darwin
run_dummy -twolevel_namespace dummy.c # Darwin
run_dummy -umbrella dummy.c # Darwin
run_dummy -undefined dummy.c # Darwin
run_dummy -unexported_symbols_list dummy.c # Darwin
run_dummy --verify-debug-info dummy.c # In clang --help-hidden Darwin?
run_dummy -weak_reference_mismatches dummy.c # Darwin
run_dummy -whatsloaded dummy.c # Darwin
run_dummy -whyload dummy.c # Darwin
run_dummy wrapper dummy.c # Darwin
run_dummy -Xcuda-fatbinary dummy dummy.c # CUDA
run_dummy -Xcuda-ptxas dummy dummy.c # CUDA

# LLVM CC1 only

run_dummy -dependency-dot dummy.dot dummy.c
run_dummy -MT -dependency-file dummy.deps dummy.c

# We need to understand the module mechanism before we can check the options.

run_dummy -fimplicit-module-maps dummy.c
run_dummy -fmodule-file=${tmpf} dummy.c
run_dummy -fmodule-map-file=${tmpf} dummy.c-verify-pch
run_dummy -fmodule-maps dummy.c
run_dummy -fmodule-name=main dummy.c
run_dummy -fmodules dummy.c
run_dummy -fmodules-cache-path=${tmpd} dummy.c
run_dummy -fmodules-decluse dummy.c
run_dummy -fmodules-ignore-macro=FORTY_TWO dummy.c
run_dummy -fmodules-prune-after=5 dummy.c
run_dummy -fmodules-prune-interval=5 dummy.c
run_dummy -fmodules-search-all dummy.c
run_dummy -fmodules-strict-decluse dummy.c
run_dummy -fmodules-user-build-path ${tmpd} dummy.c
run_dummy -fmodules-validate-once-per-build-session dummy.c
run_dummy -fmodules-validate-system-headers dummy.c
run_dummy -ivfsoverlay dummy.overlay dummy.c

# Tidy up
tidyup
