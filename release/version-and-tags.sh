#!/bin/bash
#
# version-and-tags.sh
# Bump required versions and create git tags.
# Creates a defined state which can then be used for
# building the release.

set -eux
set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/.."
pushd "$TOP_DIR"

. "$SCRIPT_DIR/vars"

# Setting the language is needed for Debian changelog generation
LANG=en_us.UTF-8

if ! [[ "$MSI_BUILD_ONLY" == "YES" ]]; then
    ###########
    # OpenVPN #
    ###########

    # We assume openvpn is already tagged
    git -C "$OPENVPN" checkout -f "$OPENVPN_CURRENT_TAG"
    git add "$OPENVPN"
    # We assume ovpn-dco is already tagged
    git -C "$OPENVPN_DCO" checkout -f "$OPENVPN_DCO_CURRENT_TAG"
    git add "$OPENVPN_DCO"

    create_debian_changelog() {
        local pkg_name=$1
        local pkg_version=$2
        local git_dir=$3
        local git_log=$4
        local changelog_file="$DEBIAN/$pkg_name/changelog-${pkg_version}"
        echo "$pkg_name (${pkg_version}-debian0) stable; urgency=medium" > "$changelog_file"
        echo >> "$changelog_file"
        git -C "$git_dir" log --pretty=short --abbrev-commit --format="  * %s (%an, %h)" \
            "$git_log" >> "$changelog_file"
        echo >> "$changelog_file"
        local commit_date=$(git -C "$git_dir" log --no-show-signature -n1 --format="%cD")
        echo " -- $GIT_AUTHOR  $commit_date" >> "$changelog_file"

        git add "$changelog_file"
    }

    # Create changelog for openvpn Debian packages
    create_debian_changelog openvpn "$DEBIAN_UPSTREAM_VERSION" "$OPENVPN" \
                            "$OPENVPN_PREVIOUS_TAG..$OPENVPN_CURRENT_TAG"
    # Create changelog for openvpn-dco-dkms Debian packages
    create_debian_changelog openvpn-dco-dkms "$OPENVPN_DCO_CURRENT_VERSION" "$OPENVPN_DCO" \
                            "$OPENVPN_DCO_PREVIOUS_TAG..$OPENVPN_DCO_CURRENT_TAG"
fi

###############
# OpenVPN GUI #
###############

pushd "$OPENVPN_GUI"
# We do not update the git checkout here, we trust the submodule to be the state you want.

# openvpn-gui is not usually tagged already
# Update minor version in configure.ac
sed -E -i s/"define\(\[_GUI_VERSION_MINOR\], \[([[:digit:]]+)\]\)"/"define\(\[_GUI_VERSION_MINOR\], \[$OPENVPN_GUI_CURRENT_MIN_VERSION\]\)"/1 configure.ac
# if configure.ac was already updated, assume everything is fine as is
if ! git diff --exit-code; then
    git add configure.ac
    git commit --author="$GIT_AUTHOR" -s -m "Bump version to $OPENVPN_GUI_CURRENT_FULL_VERSION" configure.ac
    git tag -a "v$OPENVPN_GUI_CURRENT_FULL_VERSION" -m "Version $OPENVPN_GUI_CURRENT_FULL_VERSION"
    git tag -a "OpenVPN-$BUILD_VERSION" -m "OpenVPN-$BUILD_VERSION"
    git -C "$TOP_DIR" add "$OPENVPN_GUI"
else
    # If GUI_CURRENT_FULL_VERSION is the same we still want to try to tag OpenVPN build version
    # assuming it might be different and not tagged yet
    git remote update
    if ! git tag |grep -q "OpenVPN-$BUILD_VERSION" ; then
        git tag -a "OpenVPN-$BUILD_VERSION" -m "OpenVPN-$BUILD_VERSION"
    fi
fi

popd

###############
# OpenVPN MSI #
###############

pushd "$MSI"
# Update user-visible version
sed -E -i s/"define\(\[PACKAGE_VERSION\], \[(.+)\]\)"/"define\(\[PACKAGE_VERSION\], \[$BUILD_VERSION\]\)"/1 version.m4
# if version.m4 was already updated, assume everything is fine as is
if ! git diff --exit-code; then
    PRODUCT_VERSION_NEW="$PRODUCT_VERSION" ./bump-version.m4.sh
    git add ./version.m4
fi

popd

if [ "${USE_LOCAL_SOURCE:-0}" -eq 1 ]; then
    : skip tagging
    git reset
    exit
fi

# did we prepare any changes?
if ! git diff --cached --exit-code; then
    git commit -a -s -m "Prepare release of $BUILD_VERSION"
    git tag -a "OpenVPN-$BUILD_VERSION" -m "OpenVPN-$BUILD_VERSION"
fi

# sanity check
if ! git diff --exit-code "refs/tags/OpenVPN-$BUILD_VERSION"; then
    : version-and-tags.sh called without proper version bump!
    exit 1
fi
