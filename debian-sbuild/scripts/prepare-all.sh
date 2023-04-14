#!/bin/bash

set -eux
set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/../.."
pushd "$TOP_DIR/debian-sbuild/"

. "./config/base.conf"

CHANGELOG="$BASEDIR/openvpn/changelog-$OPENVPN_CURRENT_VERSION"

if ! [ -r "${CHANGELOG}" ]; then
    echo "ERROR: changelog file ${CHANGELOG} not found!"
    exit 1
fi

test -d $BUILD_BASEDIR || mkdir -p $BUILD_BASEDIR
cd $BUILD_BASEDIR

# Prepare all builds given in variants.conf
cat $VARIANTS_FILE|grep -v "^#"|while read LINE; do
    OSRELEASE=`echo $LINE|cut -d " " -f 2`
    DIR=$OSRELEASE

    # Only build in directories which are _not_ symbolic links
    if ! [ -L $DIR ]; then
        test -d "$DIR" || mkdir "$DIR"
        pushd "$DIR"
        rm -rf openvpn*
        curl -o "openvpn_$DEBIAN_UPSTREAM_VERSION.orig.tar.gz" \
             "$SECONDARY_WEBSERVER_BASEURL/openvpn-$OPENVPN_CURRENT_VERSION.tar.gz"
        tar -xf "openvpn_$DEBIAN_UPSTREAM_VERSION.orig.tar.gz"
        pushd "openvpn-$OPENVPN_CURRENT_VERSION"
        cp -a "$BASEDIR/openvpn/$OSRELEASE/debian" .

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

        popd
        popd
    fi

done

cd $BASEDIR
