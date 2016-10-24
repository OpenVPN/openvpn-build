#!/bin/bash
#
# Basic setup for sbuild_wrapper

# Read the configuration file
. ./config/base.conf

test -d "$BASEDIR/output"        || mkdir "$BASEDIR/output"
test -d "$BASEDIR/chroots"       || mkdir "$BASEDIR/chroots"
test -d "$BASEDIR/build"         || mkdir "$BASEDIR/build"
test -d "$BASEDIR/build/precise" || mkdir "$BASEDIR/build/precise"
test -d "$BASEDIR/build/trusty"  || mkdir "$BASEDIR/build/trusty"
test -d "$BASEDIR/build/xenial"  || mkdir "$BASEDIR/build/xenial"
test -d "$BASEDIR/build/wheezy"  || mkdir "$BASEDIR/build/wheezy"
test -d "$BASEDIR/build/jessie"  || mkdir "$BASEDIR/build/jessie"
