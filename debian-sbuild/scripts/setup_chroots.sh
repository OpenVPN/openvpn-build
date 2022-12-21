#!/bin/bash
#
# A small script to ease creation of sbuild schroots.

set -eux
set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/../.."
pushd "$TOP_DIR/debian-sbuild/"

# Read the configuration file
. ./config/base.conf

CHROOT_TEMP=$(mktemp -d)

# This function does the actual work
function setup_sbuild_schroot {

    if [ "$1" = 'debian' ]; then
        MIRROR=$DEBIAN_MIRROR
        EXTRA_PARAMS="--components=main"
    elif [ "$1" = 'ubuntu' ]; then
        MIRROR=$UBUNTU_MIRROR
        EXTRA_PARAMS="--components=main,universe"
    fi

    SUITE=$2
    ARCH=$3
    FILE=$CHROOTDIR/$SUITE-$ARCH.tar.gz

    # Only setup the chroot if it does not exist
    if [ ! -f "$FILE" ]; then
        mkdir -m755 "$CHROOT_TEMP/$SUITE-$ARCH"
        $SBUILD_CREATECHROOT $EXTRA_PARAMS $SBUILD_CREATECHROOT_EXTRA_PARAMS \
                             --make-sbuild-tarball=$FILE --arch=$ARCH \
                             $SUITE "$CHROOT_TEMP/$SUITE-$ARCH" $MIRROR
    fi
}

# Cycle through all the variants
cat $VARIANTS_FILE|grep -v "^#"|while read LINE; do
    setup_sbuild_schroot $LINE
done

rm -rf "$CHROOT_TEMP"
