#!/data/data/com.termux/files/usr/bin/bash
#
#   libtool.sh - Remove libtool files from the package
#
#   Copyright (c) 2013-2024 Pacman Development Team <pacman-dev@lists.archlinux.org>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

[[ -n "$LIBMAKEPKG_TIDY_LIBTOOL_SH" ]] && return
LIBMAKEPKG_TIDY_LIBTOOL_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/data/data/com.termux/files/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/util/message.sh"
source "$MAKEPKG_LIBRARY/util/option.sh"


packaging_options+=('libtool')
tidy_remove+=('tidy_libtool')

tidy_libtool() {
	if check_option "libtool" "n"; then
		msg2 "$(gettext "Removing "%s" files...")" "libtool"
		find . ! -type d -name "*.la" -exec rm -f -- '{}' +
	fi
}
