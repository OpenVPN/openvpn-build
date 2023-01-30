#!/bin/bash
#
# debian-package-build.sh
# Build and publish Debian packages.
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

ssh "$DEBIAN_SBUILD_BUILDHOST" cloud-init status --wait
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR" submodule update --init
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR/src/openvpn" remote remove internal || true
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR/src/openvpn" remote add -f --tags internal "$INTERNAL_GIT_REPO_OPENVPN_RO"
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR" remote remove internal || true
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR" tag -d "OpenVPN-$BUILD_VERSION" || true
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR" remote add -f --tags internal "$INTERNAL_GIT_REPO_BUILD_RO"
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR" checkout --recurse-submodules -f "OpenVPN-$BUILD_VERSION"
ssh "$DEBIAN_SBUILD_BUILDHOST" "cd $DEBIAN_SBUILD_WORKDIR/debian-sbuild && sudo ./scripts/setup_chroots.sh"
#TODO: make idempotent
ssh "$DEBIAN_SBUILD_BUILDHOST" "cd $DEBIAN_SBUILD_WORKDIR/debian-sbuild && sudo ./scripts/prepare-all.sh"
ssh "$DEBIAN_SBUILD_BUILDHOST" "cd $DEBIAN_SBUILD_WORKDIR/debian-sbuild && sudo ./scripts/build-all.sh"

# upload and publish Debian packages
DEBIAN_OUTPUT_NAME="output-${DEBIAN_UPSTREAM_VERSION}-debian${DEBIAN_PACKAGE_VERSION}"
scp "$DEBIAN_SBUILD_BUILDHOST:$DEBIAN_SBUILD_WORKDIR/output/$BUILD_VERSION/${DEBIAN_OUTPUT_NAME}.tar.gz" "$OUTPUT/"
scp "${OUTPUT}/${DEBIAN_OUTPUT_NAME}.tar.gz" "$SECONDARY_WEBSERVER:"
ssh "$SECONDARY_WEBSERVER" tar xf "${DEBIAN_OUTPUT_NAME}.tar.gz"
for freight_repo in $FREIGHT_REPOS; do
    ssh $SECONDARY_WEBSERVER ./openvpn-build/debian-sbuild/scripts/freight-add-many.py \
        -p "${DEBIAN_UPSTREAM_VERSION}" \
        -c "/etc/freight-openvpn_${freight_repo}.conf" \
        -d "./${DEBIAN_OUTPUT_NAME}"
done

