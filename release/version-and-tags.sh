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

###########
# OpenVPN #
###########

# We assume openvpn is already tagged
git -C "$OPENVPN" checkout -f "$OPENVPN_CURRENT_TAG"
git add "$OPENVPN"

# Create changelog for Debian packages
COMMIT_DATE=$(git -C "$OPENVPN" log --no-show-signature -n1 --format="%cD")
DEBIAN_CHANGELOG="$DEBIAN/packaging/changelog-$OPENVPN_CURRENT_VERSION"
echo "openvpn (${OPENVPN_CURRENT_VERSION}-debian0) stable; urgency=medium" > "$DEBIAN_CHANGELOG"
echo >> "$DEBIAN_CHANGELOG"
git -C "$OPENVPN" log --pretty=short --abbrev-commit --format="  * %s (%an, %h)" \
    "refs/tags/$OPENVPN_PREVIOUS_TAG..refs/tags/$OPENVPN_CURRENT_TAG" >> "$DEBIAN_CHANGELOG"
echo >> "$DEBIAN_CHANGELOG"
echo " -- $GIT_AUTHOR  $COMMIT_DATE" >> "$DEBIAN_CHANGELOG"

git add "$DEBIAN_CHANGELOG"

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
    ./bump-version.m4.sh
    git add ./version.m4
fi

popd

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
