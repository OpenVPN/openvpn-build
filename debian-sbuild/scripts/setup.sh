#!/bin/bash
#
# Basic setup for sbuild_wrapper

set -eux
set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/../.."
pushd "$TOP_DIR/debian-sbuild/"

. ./config/base.conf

test -d "$DEBIAN_OUTPUT_DIR"     || mkdir -p "$DEBIAN_OUTPUT_DIR"
test -d "$BASEDIR/chroots"       || mkdir "$BASEDIR/chroots"
test -d "$BASEDIR/build"         || mkdir "$BASEDIR/build"
