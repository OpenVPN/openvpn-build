#!/bin/bash
#
# full-release-build.sh
# Orchestrate a full release build of OpenVPN.
# Note that this is highly dependent on exact infrastructure
# setup. This is not currently intended to be portable or
# at all usable outside of the actual OpenVPN community
# infrastructure.

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
    master \
    "v$OPENVPN_GUI_CURRENT_FULL_VERSION" \
    "OpenVPN-$BUILD_VERSION"
# make sure git knows we pushed this
git -C $TOP_DIR/src/openvpn-gui remote update
#TODO: make idempotent
#$SCRIPT_DIR/create-release-files.sh
read -p "Upload tarballs to $SECONDARY_WEBSERVER?"
# uploads tarballs, required by some build steps
$SCRIPT_DIR/sign-and-push.sh

# git push tag to github, but not official repo!
git push "$INTERNAL_GIT_REPO_BUILD_RW" "OpenVPN-$BUILD_VERSION"
git remote update

# Build Debian packages
ssh "$DEBIAN_SBUILD_BUILDHOST" cloud-init status --wait
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR" submodule update --init
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR/src/openvpn" remote remove internal || true
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR/src/openvpn" remote add -f --tags internal "$INTERNAL_GIT_REPO_OPENVPN_RO"
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR" remote remove internal || true
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR" tag -d "OpenVPN-$BUILD_VERSION"
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR" remote add -f --tags internal "$INTERNAL_GIT_REPO_BUILD_RO"
ssh "$DEBIAN_SBUILD_BUILDHOST" sudo git -C "$DEBIAN_SBUILD_WORKDIR" checkout --recurse-submodules -f "OpenVPN-$BUILD_VERSION"
ssh "$DEBIAN_SBUILD_BUILDHOST" "cd $DEBIAN_SBUILD_WORKDIR/debian-sbuild && sudo ./scripts/setup_chroots.sh"
#TODO: make idempotent
#ssh "$DEBIAN_SBUILD_BUILDHOST" "cd $DEBIAN_SBUILD_WORKDIR/debian-sbuild && sudo ./scripts/prepare-all.sh"
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

#TODO: make idempotent, check whether password is required
#ssh $WINDOWS_MSI_BUILDHOST "\"C:\Program Files\Amazon\CloudHSM\configure.exe\" -a $HSM_IP && net.exe start AWSCloudHSMClient"
ssh $WINDOWS_MSI_BUILDHOST "env n3fips_password=${HSM_USER:-cuuser}:$HSM_PASSWORD \"C:\Program Files\Amazon\CloudHSM\import_key.exe\" -from HSM -privateKeyHandle $HSM_PRIV_KEY_HANDLE -publicKeyHandle $HSM_PUB_KEY_HANDLE"
ssh $WINDOWS_MSI_BUILDHOST "env n3fips_password=${HSM_USER:-cuuser}:$HSM_PASSWORD certutil -f -csp \"Cavium Key Storage Provider\" -user -repairstore my $WINDOWS_SIGNING_KEY_FP"
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR" submodule update --init
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/src/openvpn" remote remove internal || true
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/src/openvpn" remote add -f --tags internal "$INTERNAL_GIT_REPO_OPENVPN_RO"
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR" remote remove internal || true
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR" tag -d "OpenVPN-$BUILD_VERSION"
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR" remote add -f --tags internal "$INTERNAL_GIT_REPO_BUILD_RO"
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR" checkout --recurse-submodules -f "OpenVPN-$BUILD_VERSION"
ssh $WINDOWS_MSI_BUILDHOST "cd $WINDOWS_MSI_WORKDIR/windows-msi && echo \$Env:ManifestCertificateThumbprint = \"$WINDOWS_SIGNING_KEY_FP\" >build-and-package-env.ps1"
ssh $WINDOWS_MSI_BUILDHOST "cd $WINDOWS_MSI_WORKDIR/windows-msi && \"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat\" x64 && env n3fips_password=${HSM_USER:-cuuser}:$HSM_PASSWORD powershell ./build-and-package.ps1 -sign"

scp "$WINDOWS_MSI_BUILDHOST":$WINDOWS_MSI_WORKDIR/windows-msi/image/*.msi "$OUTPUT/upload/"
read -p "Upload MSIs to $SECONDARY_WEBSERVER?"
# upload MSIs
$SCRIPT_DIR/sign-and-push.sh
