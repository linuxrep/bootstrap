#!/data/data/com.termux/files/usr/bin/bash
#
#   config.sh - functions for handling makepkg config files
#
#   Copyright (c) 2006-2024 Pacman Development Team <pacman-dev@lists.archlinux.org>
#   Copyright (c) 2002-2006 by Judd Vinet <jvinet@zeroflux.org>
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

[[ -n "$LIBMAKEPKG_UTIL_CONFIG_SH" ]] && return
LIBMAKEPKG_UTIL_CONFIG_SH=1

MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/data/data/com.termux/files/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/util/error.sh"
source "$MAKEPKG_LIBRARY/util/message.sh"
source "$MAKEPKG_LIBRARY/util/util.sh"

# correctly source makepkg.conf, respecting user precedence and the system conf
source_makepkg_config() {
	# $1: override system config file

	local MAKEPKG_CONF=${1:-${MAKEPKG_CONF:-/data/data/com.termux/files/usr/etc/makepkg.conf}}

	# Source the config file; fail if it is not found
	if [[ -r $MAKEPKG_CONF ]]; then
		source_safe "$MAKEPKG_CONF"
		if [[ -d "$MAKEPKG_CONF.d" ]]; then
			for c in "$MAKEPKG_CONF.d"/*.conf; do
				source_safe $c
			done
		fi
	else
		error "$(gettext "%s not found.")" "$MAKEPKG_CONF"
		plainerr "$(gettext "Aborting...")"
		exit $E_CONFIG_ERROR
	fi

	# Source user-specific makepkg.conf overrides, but only if no override config
	# file was specified
	XDG_PACMAN_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pacman"
	if [[ $MAKEPKG_CONF = "/data/data/com.termux/files/usr/etc/makepkg.conf" ]]; then
		if [[ -r $XDG_PACMAN_DIR/makepkg.conf ]]; then
			source_safe "$XDG_PACMAN_DIR/makepkg.conf"
		elif [[ -r $HOME/.makepkg.conf ]]; then
			source_safe "$HOME/.makepkg.conf"
		fi
	fi
}

# load makepkg.conf by sourcing the configuration files, and preserving
# existing environment settings
load_makepkg_config() {
	# $1: override system config file

	local MAKEPKG_CONF=${1:-${MAKEPKG_CONF:-/data/data/com.termux/files/usr/etc/makepkg.conf}}

	# preserve environment variables to override makepkg.conf
	local restore_envvars=$(
		for var in PKGDEST SRCDEST SRCPKGDEST LOGDEST BUILDDIR PKGEXT SRCEXT GPGKEY PACKAGER CARCH; do
			# the output of 'declare -p' results in locally scoped values when used within a function
			[[ -v $var ]] && printf '%s=%s\n' "$var" "${!var@Q}"
		done
	)

	source_makepkg_config "$MAKEPKG_CONF"

	eval "$restore_envvars"
}
