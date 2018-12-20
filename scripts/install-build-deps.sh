#!/bin/bash
#
# Install build dependencies for OpenVPN

# Read the configuration file
. ./config/base.conf

install_build_deps() {
    SUITE=$2
    ARCH=$3
    sbuild-apt $SUITE-$ARCH apt-get build-dep openvpn
    # Install extra dependencies on systemd distros
    schroot -c $SUITE-$ARCH-sbuild -d /tmp -- file /sbin/init|grep -E "/systemd$"
    if [ $? -eq 0 ]; then
        sbuild-apt $SUITE-$ARCH apt-get install $SYSTEMD_BUILD_DEPS
    fi
}

# Cycle through all the variants
cat $VARIANTS_FILE|grep -v "^#"|while read LINE; do
    install_build_deps $LINE
done
