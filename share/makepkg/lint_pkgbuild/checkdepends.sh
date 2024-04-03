#!/data/data/com.termux/files/usr/bin/bash
#
#   checkdepends.sh - Check the 'checkdepends' array conforms to requirements.
#
#   Copyright (c) 2014-2024 Pacman Development Team <pacman-dev@lists.archlinux.org>
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

[[ -n "$LIBMAKEPKG_LINT_PKGBUILD_CHECKDEPENDS_SH" ]] && return
LIBMAKEPKG_LINT_PKGBUILD_CHECKDEPENDS_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/data/data/com.termux/files/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/lint_pkgbuild/fullpkgver.sh"
source "$MAKEPKG_LIBRARY/lint_pkgbuild/pkgname.sh"
source "$MAKEPKG_LIBRARY/util/message.sh"
source "$MAKEPKG_LIBRARY/util/pkgbuild.sh"


lint_pkgbuild_functions+=('lint_checkdepends')


lint_checkdepends() {
	local checkdepends_list checkdepend name ver ret=0

	get_pkgbuild_all_split_attributes checkdepends checkdepends_list

	# this function requires extglob - save current status to restore later
	local shellopts=$(shopt -p extglob)
	shopt -s extglob

	for checkdepend in "${checkdepends_list[@]}"; do
		name=${checkdepend%%@(<|>|=|>=|<=)*}
		lint_one_pkgname checkdepends "$name" || ret=1
		if [[ $name != "$checkdepend" ]]; then
			ver=${checkdepend##$name@(<|>|=|>=|<=)}
			check_fullpkgver "$ver" checkdepends || ret=1
		fi
	done

	eval "$shellopts"

	return $ret
}
