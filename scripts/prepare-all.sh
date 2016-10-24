#!/bin/bash

. ./config/base.conf

# Determine the release and build numbers
. $VERSION_FILE

CHANGELOG="$BASEDIR/packaging/changelog-$PROGRAM_VERSION"

if ! [ -r "${CHANGELOG}" ]; then
    echo "ERROR: changelog file ${CHANGELOG} not found!"
    exit 1
fi

cd $BUILD_BASEDIR

# Find out which operating system versions we are supposed to build.
ls|while read DIR; do

    OLD_DIR=`pwd`
    OSRELEASE=$DIR

    # Only build in directories which are _not_ symbolic links
    if ! [ -L $DIR ] && [ -d $DIR ]; then
        cd $DIR
        wget $BASEURL/openvpn-$PROGRAM_VERSION.tar.gz
        mv openvpn-$PROGRAM_VERSION.tar.gz openvpn_$PROGRAM_VERSION_CLEAN.orig.tar.gz
        tar -zxf openvpn_$PROGRAM_VERSION.orig.tar.gz
        cd openvpn-$PROGRAM_VERSION
        cp -a $BASEDIR/packaging/$OSRELEASE/debian .
        # Generate changelog from the template
        sed s/"($PROGRAM_VERSION-debian$PACKAGE_VERSION)"/"($PROGRAM_VERSION_CLEAN-$OSRELEASE$PACKAGE_VERSION)"/g $CHANGELOG > debian/changelog
        dpkg-buildpackage -S -uc -us
    fi

    cd $OLD_DIR

done

cd $BASEDIR
