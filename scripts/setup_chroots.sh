#!/bin/bash
#
# A small script to ease creation of sbuild schroots.

# Read the configuration file
. ./config/base.conf

# This function does the actual work
function setup_sbuild_schroot {

    if [ "$1" = 'debian' ]; then
        MIRROR=$DEBIAN_MIRROR
        EXTRA_PARAMS="$EXTRA_PARAMS --components=main"
    elif [ "$1" = 'ubuntu' ]; then
        MIRROR=$UBUNTU_MIRROR
        EXTRA_PARAMS="$EXTRA_PARAMS --components=main,universe"
    fi

    SUITE=$2
    ARCH=$3
    FILE=$CHROOTDIR/$SUITE-$ARCH.tar.gz

    # Only setup the chroot if it does not exist
    test -f "$FILE" || $SBUILD_CREATECHROOT --arch=$ARCH $EXTRA_PARAMS $SBUILD_CREATECHROOT_EXTRA_PARAMS --make-sbuild-tarball=$FILE $SUITE `mktemp -d` $MIRROR
}

# Cycle through all the variants
cat $VARIANTS_FILE|grep -v "^#"|while read LINE; do
    setup_sbuild_schroot $LINE
done
