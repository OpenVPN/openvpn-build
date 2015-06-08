#!/bin/bash

. ./config/base.conf

# Determine the release and build numbers
. $VERSION_FILE

cd $BUILD_BASEDIR

# Find out which operating system versions we are supposed to build.
ls|while read DIR; do

    OLD_DIR=`pwd`
    OSRELEASE=$DIR
    VER=$PROGRAM_VERSION

    # Only build in directories which are _not_ symbolic links
    if ! [ -L $DIR ] && [ -d $DIR ]; then
        cd $DIR
        wget $BASEURL/openvpn-$VER.tar.gz
        mv openvpn-$VER.tar.gz openvpn_$VER.orig.tar.gz
        tar -zxf openvpn_$VER.orig.tar.gz
        cd openvpn-$VER
        cp -a $BASEDIR/packaging/$OSRELEASE/debian .
        dpkg-buildpackage -S -uc -us
    fi

    cd $OLD_DIR

done

cd $BASEDIR
