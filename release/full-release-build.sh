#!/bin/bash
#
# full-release-build.sh
# Orchestrate a full release build of OpenVPN.
# Note that this is highly dependent on exact infrastructure
# setup. This is not currently intended to be portable or
# at all usable outside of the actual OpenVPN community
# infrastructure.

# BEFORE starting this script:
# - make sure openvpn tag is available in src/openvpn
# - update src/openvpn-gui
# - update src/vcpkg
# - check vars
# - check vars.infrastructure (needs completed terraform apply!)

set -eux
set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/.."
pushd "$TOP_DIR"

$SCRIPT_DIR/source-build.sh
$SCRIPT_DIR/debian-package-build.sh
$SCRIPT_DIR/windows-installer-build.sh
