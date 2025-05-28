#!/bin/bash

set -eux
set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/../.."
pushd "$TOP_DIR/debian-sbuild/"

. "./config/base.conf"

orig_source() {
    local pkg_name=$1
    local pkg_orig_name=$2
    local pkg_orig_version=$3
    local pkg_deb_version=$4

    if [ "${USE_LOCAL_SOURCE:-0}" -eq 1 ]; then
        cp -v "$OUTPUT/upload/${pkg_orig_name}-${pkg_orig_version}.tar.gz" \
           "${pkg_name}_${pkg_deb_version}.orig.tar.gz"
        return
    fi

    curl -fsSL -o "${pkg_name}_${pkg_deb_version}.orig.tar.gz" \
         "$SECONDARY_WEBSERVER_BASEURL/${pkg_orig_name}-${pkg_orig_version}.tar.gz"
    curl -fsSL -o "${pkg_name}_${pkg_deb_version}.orig.tar.gz.asc" \
         "$SECONDARY_WEBSERVER_BASEURL/${pkg_orig_name}-${pkg_orig_version}.tar.gz.asc"
    # same as dpkg-source --require-valid-signature but accept SHA1 self-signature
    # until we have fixed our primary key
    GPG_TMP_HOME=$(mktemp -d)
    GPG_TMP_KEYRING=$(mktemp)
    GPG_TMP_OPTS="--homedir $GPG_TMP_HOME --keyring $GPG_TMP_KEYRING"
    gpg $GPG_TMP_OPTS --no-options --no-default-keyring -q \
        --import "$BASEDIR/$pkg_name/$OSRELEASE/debian/upstream/signing-key.asc"
    gpgv $GPG_TMP_OPTS "${pkg_name}_${pkg_deb_version}.orig.tar.gz.asc" \
         "${pkg_name}_${pkg_deb_version}.orig.tar.gz"
    rm -rf "$GPG_TMP_HOME" "$GPG_TMP_KEYRING"
}

prepare_package() {
    local pkg_name=$1
    local pkg_orig_name=$2
    local pkg_orig_version=$3
    local pkg_deb_version=$4

    local changelog="$BASEDIR/$pkg_name/changelog-$pkg_deb_version"

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
        orig_source "$@"
        tar -xf "${pkg_name}_${pkg_deb_version}.orig.tar.gz"
        pushd "${pkg_orig_name}-${pkg_orig_version}"
        cp -a "$BASEDIR/$pkg_name/$OSRELEASE/debian" .

        # Generate changelog from the template using sed with regular expression
        # capture groups.
        # The purpose is to ensure that "debian" in the version numbers are converted
        # into real distribution codenames (e.g. "jessie")
        cat $changelog | \
            sed -E s/"^(${pkg_name} \([[:alnum:].~-]+)-debian([[:digit:]])"/"\1-$OSRELEASE\2"/g \
                > debian/changelog

        dpkg-buildpackage -d -S -uc -us

        popd
        popd
    done # while variant
}

prepare_package openvpn openvpn $OPENVPN_CURRENT_VERSION $DEBIAN_UPSTREAM_VERSION
if $BUILD_ARCH_ALL; then
    prepare_package ovpn-backports ovpn-backports $OPENVPN_DCO_CURRENT_VERSION $OPENVPN_DCO_CURRENT_VERSION
fi

cd $BASEDIR
