#!/bin/bash
#
# Basic setup for sbuild_wrapper

# Read the configuration file
. ./config/base.conf

test -d "$BASEDIR/output" || mkdir "$BASEDIR/output"
test -d "$BASEDIR/chroots" || mkdir "$BASEDIR/chroots"
test -d "$BASEDIR/build" || mkdir "$BASEDIR/build"
test -d "$BASEDIR/build/openvpn-with-openssl-0.9.8" || mkdir "$BASEDIR/build/openvpn-with-openssl-0.9.8"
test -d "$BASEDIR/build/openvpn-with-openssl-1.0.0" || mkdir "$BASEDIR/build/openvpn-with-openssl-1.0.0"
