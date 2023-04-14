#!/bin/bash

set -eux
set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/../.."
pushd "$TOP_DIR/debian-sbuild/"

# This is required or Quilt will not find the patches
#export QUILT_PATCHES=debian/patches

. ./config/base.conf

# Create a target directory for this build
TARGET_DIR="$DEBIAN_OUTPUT_DIR"
mkdir -p "$TARGET_DIR"

build_package() {
    local pkg_name=$1
    local pkg_deb_version=$2
    local pkg_deb_build=$3

    # Loop through all OS/release/ARCH combinations we need to cover
    cat $VARIANTS_FILE|grep -v "^#"|while read LINE; do

        # Using awk might be cleaner?
        OS=`echo $LINE|cut -d " " -f 1`
        OSRELEASE=`echo $LINE|cut -d " " -f 2`
        ARCH=`echo $LINE|cut -d " " -f 3`

        SOURCES_DIR="$BUILD_BASEDIR/$pkg_name/$OSRELEASE"
        DEBIAN_BASENAME="${pkg_name}_${pkg_deb_version}-${OSRELEASE}${pkg_deb_build}"

        # If the package exists already, skip the build
        if [ -f "${TARGET_DIR}/${DEBIAN_BASENAME}_${ARCH}.deb" ]; then
            echo "$DEBIAN_BASENAME for ${ARCH} has been built already"
            continue
        fi
        pushd "$SOURCES_DIR"
        sbuild --verbose --no-run-lintian \
               --build-dir=$(pwd) \
               --arch="${ARCH}" --dist="${OSRELEASE}" \
               "${DEBIAN_BASENAME}.dsc"
        cp "${DEBIAN_BASENAME}_${ARCH}.deb" "${TARGET_DIR}/"
        cp "${DEBIAN_BASENAME}_${ARCH}.buildinfo" "${TARGET_DIR}/"
        popd
    done
}

build_package openvpn "$DEBIAN_UPSTREAM_VERSION" "$DEBIAN_PACKAGE_VERSION"

# Package all the packages into a tar.gz for transfer
cd "$OUTPUT"
tar -zcf "$DEBIAN_OUTPUT_NAME.tar.gz" "$DEBIAN_OUTPUT_NAME"
