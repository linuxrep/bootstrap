#!/data/data/com.termux/files/usr/bin/bash
#
#   git.sh - function for handling the download and "extraction" of Git sources
#
#   Copyright (c) 2015-2024 Pacman Development Team <pacman-dev@lists.archlinux.org>
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

[[ -n "$LIBMAKEPKG_SOURCE_GIT_SH" ]] && return
LIBMAKEPKG_SOURCE_GIT_SH=1


MAKEPKG_LIBRARY=${MAKEPKG_LIBRARY:-'/data/data/com.termux/files/usr/share/makepkg'}

source "$MAKEPKG_LIBRARY/util/message.sh"
source "$MAKEPKG_LIBRARY/util/pkgbuild.sh"


download_git() {
	# abort early if parent says not to fetch
	if declare -p get_vcs > /dev/null 2>&1; then
		(( get_vcs )) || return
	fi

	local netfile=$1

	local dir=$(get_filepath "$netfile")
	[[ -z "$dir" ]] && dir="$SRCDEST/$(get_filename "$netfile")"

	local repo=$(get_filename "$netfile")

	local url=$(get_url "$netfile")
	url=${url#git+}
	url=${url%%#*}
	url=${url%%\?*}

	if [[ ! -d "$dir" ]] || dir_is_empty "$dir" ; then
		msg2 "$(gettext "Cloning %s %s repo...")" "${repo}" "git"
		if ! git clone --origin=origin ${GITFLAGS:---mirror} "$url" "$dir"; then
			error "$(gettext "Failure while downloading %s %s repo")" "${repo}" "git"
			plainerr "$(gettext "Aborting...")"
			exit 1
		fi
	elif (( ! HOLDVER )); then
		cd_safe "$dir"
		# Make sure we are fetching the right repo
		local remote_url="$(git config --get remote.origin.url)"
		if [[ "${url%%.git}" != "${remote_url%%.git}" ]] ; then
			error "$(gettext "%s is not a clone of %s")" "$dir" "$url"
			plainerr "$(gettext "Aborting...")"
			exit 1
		fi
		msg2 "$(gettext "Updating %s %s repo...")" "${repo}" "git"
		if ! git fetch --all -p; then
			# only warn on failure to allow offline builds
			warning "$(gettext "Failure while updating %s %s repo")" "${repo}" "git"
		fi
	fi
}

extract_git() {
	local netfile=$1 tagname

	local fragment=$(get_uri_fragment "$netfile")
	local repo=$(get_filename "$netfile")

	local dir=$(get_filepath "$netfile")
	[[ -z "$dir" ]] && dir="$SRCDEST/$(get_filename "$netfile")"

	msg2 "$(gettext "Creating working copy of %s %s repo...")" "${repo}" "git"
	pushd "$srcdir" &>/dev/null

	local updating=0
	if [[ -d "${dir##*/}" ]]; then
		updating=1
		cd_safe "${dir##*/}"
		if ! git fetch; then
			error "$(gettext "Failure while updating working copy of %s %s repo")" "${repo}" "git"
			plainerr "$(gettext "Aborting...")"
			exit 1
		fi
		cd_safe "$srcdir"
	elif ! git clone --origin=origin -s "$dir" "${dir##*/}"; then
		error "$(gettext "Failure while creating working copy of %s %s repo")" "${repo}" "git"
		plainerr "$(gettext "Aborting...")"
		exit 1
	fi

	cd_safe "${dir##*/}"

	local ref=origin/HEAD
	if [[ -n $fragment ]]; then
		case ${fragment%%=*} in
			commit|tag)
				ref=${fragment##*=}
				;;
			branch)
				ref=origin/${fragment##*=}
				;;
			*)
				error "$(gettext "Unrecognized reference: %s")" "${fragment}"
				plainerr "$(gettext "Aborting...")"
				exit 1
		esac
	fi

	if [[ ${fragment%%=*} = tag ]]; then
		tagname="$(git tag -l --format='%(tag)' "$ref")"
		if [[ -n $tagname && $tagname != "$ref" ]]; then
			error "$(gettext "Failure while checking out version %s, the git tag has been forged")" "$ref"
			plainerr "$(gettext "Aborting...")"
			exit 1
		fi
	fi

	if [[ $ref != "origin/HEAD" ]] || (( updating )) ; then
		if ! git checkout --force --no-track -B makepkg "$ref" --; then
			error "$(gettext "Failure while creating working copy of %s %s repo")" "${repo}" "git"
			plainerr "$(gettext "Aborting...")"
			exit 1
		fi
	fi

	popd &>/dev/null
}

calc_checksum_git() {
	local netfile=$1 integ=$2 ret=0 shellopts dir url fragment sum

	# this function requires pipefail - save current status to restore later
	shellopts=$(shopt -p -o pipefail)
	shopt -s -o pipefail

	dir=$(get_filepath "$netfile")
	url=$(get_url "$netfile")
	fragment=$(get_uri_fragment "$url")

	case ${fragment%%=*} in
		tag|commit)
			fragval=${fragment##*=}
			sum=$(git -c core.abbrev=no -C "$dir" archive --format tar "$fragval" | "${integ}sum" 2>&1) || ret=1
			sum="${sum%% *}"
			;;
		*)
			sum="SKIP"
			;;
	esac

	eval "$shellopts"
	printf '%s' "$sum"
	return $ret
}
