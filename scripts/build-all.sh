#!/bin/bash

# This is required or Quilt will not find the patches
export QUILT_PATCHES=debian/patches

. ./config/base.conf

# Determine the release and build numbers
. $VERSION_FILE

# Loop through all OS/release/ARCH combinations we need to cover
cat $VARIANTS_FILE|grep -v "^#"|while read LINE; do

    # Using awk might be cleaner?
    OS=`echo $LINE|cut -d " " -f 1`
    OSRELEASE=`echo $LINE|cut -d " " -f 2`
    ARCH=`echo $LINE|cut -d " " -f 3`

    # Create a target directory for this build
    TARGET_DIR=$OUTPUT_DIR
    mkdir -p $TARGET_DIR

    SOURCES_DIR="$BUILD_BASEDIR/$OSRELEASE"

    # Build
    OLD_DIR=`pwd`

    # If the package exists already, skip the build
    if [ -f "${TARGET_DIR}/openvpn_${PROGRAM_VERSION_CLEAN}-${OSRELEASE}${PACKAGE_VERSION}_${ARCH}.deb" ]; then
        echo "OpenVPN $PROGRAM_VERSION for $OS $OSRELEASE $ARCH has been built already"
    else
        cd $SOURCES_DIR
        sbuild --verbose --arch=${ARCH} --dist=${OSRELEASE} openvpn_${PROGRAM_VERSION_CLEAN}-${OSRELEASE}${PACKAGE_VERSION}.dsc && cp openvpn_${PROGRAM_VERSION_CLEAN}-${OSRELEASE}${PACKAGE_VERSION}_${ARCH}.deb ${TARGET_DIR}/
        cd $OLD_DIR
    fi

done

# Package all the packages into a tar.gz for transfer
cd $BASEDIR
tar -zcf output.tar.gz output
