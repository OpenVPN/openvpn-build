#!/bin/bash
#
# source-build.sh
# Build source tarballs, create tags
# Used by full-release-build.sh

# BEFORE starting this script:
# - make sure openvpn tag is available in src/openvpn
# - update src/openvpn-gui
# - update src/vcpkg
# - check vars
# - check vars.infrastructure (needs completed terraform apply!)

set -eux
set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/.."
pushd "$TOP_DIR"

. "$SCRIPT_DIR/vars"
. "$SCRIPT_DIR/vars.infrastructure"

$SCRIPT_DIR/version-and-tags.sh
read -p "push OpenVPN-$BUILD_VERSION in openvpn-gui?"
git -C $TOP_DIR/src/openvpn-gui push "$INTERNAL_GIT_REPO_GUI_RW" \
    HEAD:master \
    "v$OPENVPN_GUI_CURRENT_FULL_VERSION" \
    "OpenVPN-$BUILD_VERSION"
# make sure git knows we pushed this
git -C $TOP_DIR/src/openvpn-gui remote update
#TODO: make idempotent
if ! [[ "$MSI_BUILD_ONLY" == "YES" ]]; then
    $SCRIPT_DIR/create-release-files.sh
    read -p "Upload tarballs to $SECONDARY_WEBSERVER?"
    # uploads tarballs, required by some build steps
    $SCRIPT_DIR/sign-and-push.sh
fi

# git push tag to github, but not official repo!
git push "$INTERNAL_GIT_REPO_BUILD_RW" "OpenVPN-$BUILD_VERSION"
git remote update
