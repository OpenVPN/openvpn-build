#!/bin/bash
#
# windows-installer-build.sh
# Build new MSIs for release
# Used as part of full-release-build.sh

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

ssh $WINDOWS_MSI_BUILDHOST "net.exe stop AWSCloudHSMClient" || true
ssh $WINDOWS_MSI_BUILDHOST "\"C:\Program Files\Amazon\CloudHSM\configure.exe\" -a $HSM_IP && net.exe start AWSCloudHSMClient"
ssh $WINDOWS_MSI_BUILDHOST "env n3fips_password=${HSM_USER:-cuuser}:$HSM_PASSWORD \"C:\Program Files\Amazon\CloudHSM\import_key.exe\" -from HSM -privateKeyHandle $HSM_PRIV_KEY_HANDLE -publicKeyHandle $HSM_PUB_KEY_HANDLE"
ssh $WINDOWS_MSI_BUILDHOST "env n3fips_password=${HSM_USER:-cuuser}:$HSM_PASSWORD certutil -f -csp \"Cavium Key Storage Provider\" -user -repairstore my $WINDOWS_SIGNING_KEY_FP"
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/openvpn-build" remote remove internal || true
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/openvpn-build" tag -d "OpenVPN-$BUILD_VERSION" || true
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/openvpn-build" remote add -f --tags internal "$INTERNAL_GIT_REPO_BUILD_RO"
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/openvpn-build" checkout -f "OpenVPN-$BUILD_VERSION"
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/openvpn-gui" tag -d "OpenVPN-$BUILD_VERSION" || true
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/openvpn-gui" remote update
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/openvpn-gui" checkout -f "OpenVPN-$BUILD_VERSION"
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/openvpn" remote remove internal || true
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/openvpn" tag -d "$OPENVPN_CURRENT_TAG" || true
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/openvpn" remote add -f --tags internal "$INTERNAL_GIT_REPO_OPENVPN_RO"
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/openvpn" checkout -f "$OPENVPN_CURRENT_TAG"
ssh $WINDOWS_MSI_BUILDHOST "cd $WINDOWS_MSI_WORKDIR/openvpn-build/windows-msi && echo \$Env:ManifestCertificateThumbprint = \"$WINDOWS_SIGNING_KEY_FP\" >build-and-package-env.ps1"
ssh $WINDOWS_MSI_BUILDHOST "cd $WINDOWS_MSI_WORKDIR/openvpn-build/windows-msi && \"C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat\" x64 && env n3fips_password=${HSM_USER:-cuuser}:$HSM_PASSWORD powershell ./build-and-package.ps1 -basedir ../.."

mkdir -p "$OUTPUT/upload/"
scp "$WINDOWS_MSI_BUILDHOST":"$WINDOWS_MSI_WORKDIR/openvpn-build/windows-msi/image/OpenVPN-${BUILD_VERSION}"-*.msi "$OUTPUT/upload/"
read -p "Upload MSIs to $SECONDARY_WEBSERVER?"
# upload MSIs
$SCRIPT_DIR/sign-and-push.sh
