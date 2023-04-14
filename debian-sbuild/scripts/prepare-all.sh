#!/bin/bash

set -eux
set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/../.."
pushd "$TOP_DIR/debian-sbuild/"

. "./config/base.conf"

prepare_package() {
    local pkg_name=$1
    local pkg_orig_name=$2
    local pkg_orig_version=$3
    local pkg_deb_version=$4

    local changelog="$BASEDIR/$pkg_name/changelog-$pkg_orig_version"

    if ! [ -r "${changelog}" ]; then
        echo "ERROR: changelog file ${changelog} not found!"
        exit 1
    fi

    local build_dir="$BUILD_BASEDIR/$pkg_name"
    test -d $build_dir || mkdir -p $build_dir
    cd $build_dir

    # Prepare all builds given in variants.conf
    cat $VARIANTS_FILE|grep -v "^#"|while read LINE; do
        OSRELEASE=`echo $LINE|cut -d " " -f 2`
        DIR=$OSRELEASE

        # Only build in directories which are _not_ symbolic links
        if [ -L $DIR ]; then
            continue
        fi

        test -d "$DIR" || mkdir "$DIR"
        pushd "$DIR"
        rm -rf "$pkg_name"*
        curl -o "${pkg_name}_${pkg_deb_version}.orig.tar.gz" \
             "$SECONDARY_WEBSERVER_BASEURL/${pkg_orig_name}-${pkg_orig_version}.tar.gz"
        tar -xf "${pkg_name}_${pkg_deb_version}.orig.tar.gz"
        pushd "${pkg_orig_name}-${pkg_orig_version}"
        cp -a "$BASEDIR/$pkg_name/$OSRELEASE/debian" .

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
        cat $changelog|\
            sed -E s/"^(${pkg_name} \([[:digit:]]\.[[:digit:]])_([[:alnum:]]+)-debian([[:digit:]])"/"\1-\2-$OSRELEASE\3"/g|\
            sed -E s/"^(${pkg_name} \([[:digit:]]\.[[:digit:]]\.[[:digit:]]+)-debian([[:digit:]])"/"\1-$OSRELEASE\2"/g > debian/changelog

        dpkg-buildpackage -d -S -uc -us

        popd
        popd
    done # while variant
}

prepare_package openvpn openvpn $OPENVPN_CURRENT_VERSION $DEBIAN_UPSTREAM_VERSION
prepare_package openvpn-dco-dkms ovpn-dco $OPENVPN_DCO_CURRENT_VERSION $OPENVPN_DCO_CURRENT_VERSION

cd $BASEDIR
