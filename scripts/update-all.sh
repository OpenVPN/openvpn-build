#!/bin/sh
#
# A convenience wrapper used to update packages on all schroots.
schroot -l|grep sbuild|cut -d ":" -f 2|sort|uniq|while read CHROOT; do
    sbuild-update -udcar $CHROOT
done
