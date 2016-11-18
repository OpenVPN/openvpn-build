#!/bin/sh
#
# A convenience wrapper used to update packages on schroots.

. ./config/base.conf

# Only update variants that are defined in variants.conf
cat $VARIANTS_FILE|grep -v "^#"|while read LINE; do
    OSRELEASE=`echo $LINE|cut -d " " -f 2`
    ARCH=`echo $LINE|cut -d " " -f 3`
    sbuild-update -udcar "$OSRELEASE-$ARCH-sbuild"
done
