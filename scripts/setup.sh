#!/bin/bash
#
# Basic setup for sbuild_wrapper

# Read the configuration file
. ./config/base.conf

test -d "$BASEDIR/output"        || mkdir "$BASEDIR/output"
test -d "$BASEDIR/chroots"       || mkdir "$BASEDIR/chroots"
test -d "$BASEDIR/build"         || mkdir "$BASEDIR/build"
