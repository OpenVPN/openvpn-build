#!/bin/bash

set -eux
set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/../.."
pushd "$TOP_DIR/debian-sbuild/"

# This is required or Quilt will not find the patches
#export QUILT_PATCHES=debian/patches

. ./config/base.conf

# Loop through all OS/release/ARCH combinations we need to cover
cat $VARIANTS_FILE|grep -v "^#"|while read LINE; do

    # Using awk might be cleaner?
    OS=`echo $LINE|cut -d " " -f 1`
    OSRELEASE=`echo $LINE|cut -d " " -f 2`
    ARCH=`echo $LINE|cut -d " " -f 3`

    # Create a target directory for this build
    TARGET_DIR="$DEBIAN_OUTPUT_DIR"
    mkdir -p "$TARGET_DIR"

    SOURCES_DIR="$BUILD_BASEDIR/$OSRELEASE"
    DEBIAN_BASENAME="openvpn_${DEBIAN_UPSTREAM_VERSION}-${OSRELEASE}${DEBIAN_PACKAGE_VERSION}"

    # If the package exists already, skip the build
    if [ -f "${TARGET_DIR}/${DEBIAN_BASENAME}_${ARCH}.deb" ]; then
        echo "OpenVPN $DEBIAN_BASENAME for ${ARCH} has been built already"
    else
        pushd "$SOURCES_DIR"
        sbuild --verbose --no-run-lintian \
               --build-dir=$(pwd) \
               --arch="${ARCH}" --dist="${OSRELEASE}" \
               "${DEBIAN_BASENAME}.dsc"
        cp "${DEBIAN_BASENAME}_${ARCH}.deb" "${TARGET_DIR}/"
        cp "${DEBIAN_BASENAME}_${ARCH}.buildinfo" "${TARGET_DIR}/"
        popd
    fi
done

# Package all the packages into a tar.gz for transfer
cd "$OUTPUT"
tar -zcf "$DEBIAN_OUTPUT_NAME.tar.gz" "$DEBIAN_OUTPUT_NAME"
