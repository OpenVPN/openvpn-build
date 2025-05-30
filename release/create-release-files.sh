#!/bin/bash
#
# create-release-files.sh
# This script assumes that the current git commit
# of openvpn-build exactly describes the build you
# want to do.

set -eux
set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/.."
pushd "$TOP_DIR"

. "$SCRIPT_DIR/vars"

# Setting the language is needed for Debian changelog generation
LANG=en_us.UTF-8

# Remove old release directory to prevent various warnigs and errors
if ! [ "$OUTPUT" = "" ]; then
    [ ! -d "$OUTPUT" ] || rm -ri "$OUTPUT"
    mkdir "$OUTPUT"
else
    echo "ERROR: \$OUTPUT not defined in vars!"
    exit 1
fi

# Generate release and changelog directories
for DIR in upload changelog man; do
    if ! [ -d "$OUTPUT/$DIR" ]; then
        mkdir -pv "$OUTPUT/$DIR"
    fi
done

UPLOAD="$OUTPUT/upload"

# Generate OpenVPN tarballs
pushd "$OPENVPN"

COMMIT_DATE=$(git log --no-show-signature -n1 --format="%cD")
TAR_REP="tar --sort=name --owner=root:0 --group=root:0"

: "Creating OpenVPN source packages"
autoreconf -vi > /dev/null 2>&1
./configure --disable-dco --disable-lzo --disable-lz4 --disable-plugin-auth-pam > /dev/null
make distdir > /dev/null
$TAR_REP --mtime="$COMMIT_DATE" -chf - "openvpn-$OPENVPN_CURRENT_VERSION" \
    | gzip -c > "$UPLOAD/openvpn-$OPENVPN_CURRENT_VERSION.tar.gz"
rm -fr "openvpn-$OPENVPN_CURRENT_VERSION"

# Generate changelog for Trac
git shortlog "$OPENVPN_PREVIOUS_TAG...$OPENVPN_CURRENT_TAG" \
    > "$OUTPUT/changelog/openvpn-$OPENVPN_CURRENT_VERSION-changelog"

# Copy the man-page and tarballs
cp -v doc/openvpn.8.html "$OUTPUT/man/"

popd

# Generate OpenVPN-GUI tarball
pushd "$OPENVPN_GUI"

COMMIT_DATE_GUI=$(git log --no-show-signature -n1 --format="%cD")

: "Creating OpenVPN-GUI source package"
autoreconf -vi > /dev/null 2>&1
./configure --enable-distonly > /dev/null
make distdir > /dev/null
$TAR_REP --mtime="$COMMIT_DATE_GUI" -chf - "openvpn-gui-$OPENVPN_GUI_CURRENT_MAJ_VERSION" \
    | gzip -c > "$UPLOAD/openvpn-gui-$OPENVPN_GUI_CURRENT_MAJ_VERSION.tar.gz"
rm -fr "openvpn-gui-$OPENVPN_GUI_CURRENT_MAJ_VERSION"

# Generate OpenVPN-DCO tarball
pushd "$OPENVPN_DCO"

COMMIT_DATE_DCO=$(git log --no-show-signature -n1 --format="%cD")

: "Creating ovpn (DCO) source package"
git archive --prefix=ovpn-backports-$OPENVPN_DCO_CURRENT_VERSION/ --format=tar $OPENVPN_DCO_CURRENT_TAG \
    | gzip -c > "$UPLOAD/ovpn-backports-$OPENVPN_DCO_CURRENT_VERSION.tar.gz"

popd
