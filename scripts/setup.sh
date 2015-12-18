#!/bin/bash
#
# Basic setup for sbuild_wrapper

# Read the configuration file
. ./config/base.conf

test -d "$BASEDIR/output"        || mkdir "$BASEDIR/output"
test -d "$BASEDIR/chroots"       || mkdir "$BASEDIR/chroots"
test -d "$BASEDIR/build"         || mkdir "$BASEDIR/build"
test -d "$BASEDIR/build/lucid"   || mkdir "$BASEDIR/build/lucid"
test -d "$BASEDIR/build/precise" || mkdir "$BASEDIR/build/precise"
test -d "$BASEDIR/build/trusty"  || mkdir "$BASEDIR/build/trusty"
test -h "$BASEDIR/build/squeeze" || ln -s "$BASEDIR/build/lucid $BASEDIR/build/squeeze"
test -h "$BASEDIR/build/wheezy"  || ln -s "$BASEDIR/build/precise $BASEDIR/build/wheezy"
test -d "$BASEDIR/build/jessie"  || mkdir "$BASEDIR/build/jessie"
