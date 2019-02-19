#!/bin/bash

. ./config/base.conf

# Determine the release and build numbers
. $VERSION_FILE

# The series file to use. Required because a single patch (series) may not work 
# on all OpenVPN versions we're building (e.g. due to the "Great Reformatting").
PATCH_SERIES="${PATCH_SERIES:-series}"

CHANGELOG="$BASEDIR/packaging/changelog-$PROGRAM_VERSION"

if ! [ -r "${CHANGELOG}" ]; then
    echo "ERROR: changelog file ${CHANGELOG} not found!"
    exit 1
fi

cd $BUILD_BASEDIR

# Prepare all builds given in variants.conf
cat $VARIANTS_FILE|grep -v "^#"|while read LINE; do
    OSRELEASE=`echo $LINE|cut -d " " -f 2`
    DIR=$OSRELEASE
    OLD_DIR=`pwd`

    # Only build in directories which are _not_ symbolic links
    if ! [ -L $DIR ]; then
        test -d "$DIR" || mkdir "$DIR"
        cd $DIR
        rm -rf openvpn*
        wget $BASEURL/openvpn-$PROGRAM_VERSION.tar.gz
        mv openvpn-$PROGRAM_VERSION.tar.gz openvpn_$PROGRAM_VERSION_CLEAN.orig.tar.gz
        tar -zxf openvpn_$PROGRAM_VERSION_CLEAN.orig.tar.gz
        cd openvpn-$PROGRAM_VERSION
        cp -a $BASEDIR/packaging/$OSRELEASE/debian .

        # Make sure the correct patch series is used
        PATCHESDIR="debian/patches"
        cp -a $PATCHESDIR/$PATCH_SERIES $PATCHESDIR/series

        # Generate changelog from the template using sed with regular expression
        # capture groups. The purpose is twofold:
        #
        # - Ensure that "debian" in the version numbers are converted into real distribution codenames (e.g. "jessie")
        # - Get rid off underscores in version names (e.g. 2.4_beta1 -> 2.4-beta1)
        #
        # The latter has to be done for all version definitions in the changelog
        # or the Debian packaging tools will explode.
        #
        # Trying to manage versions like 2.3.14 and 2.4_rc2 with one regular 
        # expression gets very tricky, becomes hard to read easily and is 
        # fragile. Therefore we have two sed "profiles" depending on the version 
        # number type we're given.
        #
        # First sed is for openvpn-2.4_rc2-debian0-style and the second for openvpn-2.3.14-debian0-style entries
        cat $CHANGELOG|\
        sed -E s/'^(openvpn \([[:digit:]]\.[[:digit:]])_([[:alnum:]]+)-debian([[:digit:]])'/"\1-\2-$OSRELEASE\3"/g|\
        sed -E s/'^(openvpn \([[:digit:]]\.[[:digit:]]\.[[:digit:]]+)-debian([[:digit:]])'/"\1-$OSRELEASE\2"/g > debian/changelog

        dpkg-buildpackage -d -S -uc -us
    fi

    cd $OLD_DIR

done

cd $BASEDIR
