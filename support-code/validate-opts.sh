#!/bin/sh
# Check options are tested for LLVM and/or GCC

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

#     ./validate-opts.sh <file>

# where <file> is a list of options which are checked, to see they are
# included in the main check-opts.sh script.

optfile="$1"
list="`cat ${optfile}`"

for rawopt in $list
do
    # Turn leading '-' into a char range to avoid confusing grep that it is an
    # option.
    opt=`echo ${rawopt} | sed -e 's/^-*//'`
    if ! grep -q " [-]-*${opt}" opt-check.sh
    then
	echo "${rawopt}"
    fi
done
