/* Dummy profiling functions

   Copyright (C) 2015 Embecosm Limited

   Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

   This file is part of GDB.

   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3 of the License, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
   more details.

   You should have received a copy of the GNU General Public License along with
   this program.  If not, see <http://www.gnu.org/licenses/>.  */

void
__cyg_profile_func_enter (void *this_fn __attribute ((unused)),
			  void *call_site __attribute ((unused)) )
{
}

void
__cyg_profile_func_exit (void *this_fn __attribute ((unused)),
			 void *call_site __attribute ((unused)) )
{
}
