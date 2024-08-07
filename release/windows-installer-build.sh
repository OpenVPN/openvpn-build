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

cat >build-and-package-env.ps1 <<EOF
\$Env:JsignJar="$WINDOWS_MSI_WORKDIR/../jsign.jar"
\$Env:SigningStoreType="GOOGLECLOUD"
\$Env:SigningKeyStore="$GOOGLE_CLOUD_KMS_KEYRING"
\$Env:SigningStoreKeyName="$GOOGLE_CLOUD_KMS_KEY"
\$Env:SigningCertificateFile="$WINDOWS_MSI_WORKDIR/../signingCert.pem"
EOF
if [ -n "${VCPKG_CACHE:-}" ]; then
   echo "\$Env:VCPKG_BINARY_SOURCES=\"$VCPKG_CACHE\"" >>build-and-package-env.ps1
fi

ssh $WINDOWS_MSI_BUILDHOST "gcloud auth login --quiet --cred-file=$WINDOWS_MSI_WORKDIR\..\clientLibraryConfig.json"
set +x
ACCESS_TOKEN=$(ssh $WINDOWS_MSI_BUILDHOST "cd $WINDOWS_MSI_WORKDIR/windows-msi && gcloud auth print-access-token")
echo "\$Env:SigningStorePass=\"$ACCESS_TOKEN\"" >>build-and-package-env.ps1
set -x

scp build-and-package-env.ps1 "$WINDOWS_MSI_BUILDHOST":"$WINDOWS_MSI_WORKDIR/windows-msi/"

ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR" submodule update --init
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/src/openvpn" remote remove internal || true
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR/src/openvpn" remote add -f --tags internal "$INTERNAL_GIT_REPO_OPENVPN_RO"
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR" remote remove internal || true
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR" tag -d "OpenVPN-$BUILD_VERSION" || true
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR" remote add -f --tags internal "$INTERNAL_GIT_REPO_BUILD_RO"
ssh $WINDOWS_MSI_BUILDHOST git -C "$WINDOWS_MSI_WORKDIR" checkout --recurse-submodules -f "OpenVPN-$BUILD_VERSION"
ssh $WINDOWS_MSI_BUILDHOST "cd $WINDOWS_MSI_WORKDIR/windows-msi && \"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat\" x64 && powershell ./build-and-package.ps1 -sign"

mkdir -p "$OUTPUT/upload/"
scp "$WINDOWS_MSI_BUILDHOST":"$WINDOWS_MSI_WORKDIR/windows-msi/image/OpenVPN-${BUILD_VERSION}"-*.msi "$OUTPUT/upload/"
read -p "Upload MSIs to $SECONDARY_WEBSERVER?"
# upload MSIs
$SCRIPT_DIR/sign-and-push.sh
