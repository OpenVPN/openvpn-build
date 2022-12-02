#!/bin/bash
#
# create-release-files.sh

. ./vars

set -eux
set -o pipefail

# Setting the language is needed for Debian changelog generation
LANG=en_us.UTF-8
CWD=`pwd`

# Remove old release directory to prevent various warnigs and errors
if ! [ "$BASEDIR" = "" ]; then
    [ ! -d "$BASEDIR" ] || rm -ri "$BASEDIR"
    mkdir "$BASEDIR"
else
    echo "ERROR: \$BASEDIR not defined in vars!"
    exit 1
fi

cd "$BASEDIR"

# Generate release and changelog directories
for DIR in sources changelog man; do
    if ! [ -d "$DIR" ]; then
        mkdir -v $DIR
    fi
done

# Clone Git repositories if necessary
if ! [ -d "openvpn" ]; then
    git clone $OPENVPN_REPO
fi

if ! [ -d "openvpn-gui" ]; then
    git clone $OPENVPN_GUI_REPO
fi

cd "$BASEDIR"

# Generate OpenVPN tarballs
cd openvpn
git checkout -B "$OPENVPN_CURRENT_TAG" "$OPENVPN_CURRENT_TAG"
git pull --rebase origin "$OPENVPN_CURRENT_TAG"

COMMIT_DATE=$(git log --no-show-signature -n1 --format="%cD")
TAR_REP="tar --sort=name --owner=root:0 --group=root:0"

echo "Creating OpenVPN source packages"
autoreconf -vi > /dev/null 2>&1
./configure > /dev/null
make distdir > /dev/null
$TAR_REP --mtime="$COMMIT_DATE" -chf - "openvpn-$OPENVPN_CURRENT_VERSION" \
    | gzip -c > "openvpn-$OPENVPN_CURRENT_VERSION.tar.gz"
rm -fr "openvpn-$OPENVPN_CURRENT_VERSION"

# Generate changelog for Trac
git shortlog "$OPENVPN_PREVIOUS_TAG...refs/tags/$OPENVPN_CURRENT_TAG" \
    > "$BASEDIR/changelog/openvpn-$OPENVPN_CURRENT_VERSION-changelog"

# Create changelog for Debian packages
DEBIAN_CHANGELOG="$BASEDIR/changelog/openvpn-$OPENVPN_CURRENT_VERSION-changelog-debian"
echo "openvpn (${OPENVPN_CURRENT_VERSION}-debian0) stable; urgency=medium" > "$DEBIAN_CHANGELOG"
echo >> "$DEBIAN_CHANGELOG"
git log --pretty=short --abbrev-commit --format="  * %s (%an, %h)" \
    "$OPENVPN_PREVIOUS_TAG...refs/tags/$OPENVPN_CURRENT_TAG" >> "$DEBIAN_CHANGELOG"
echo >> "$DEBIAN_CHANGELOG"
echo " -- $GIT_AUTHOR  $COMMIT_DATE" >> "$DEBIAN_CHANGELOG"

# Copy the man-page and tarballs
cp -v doc/openvpn.8.html "$BASEDIR/man/"
cp -v openvpn-"$OPENVPN_CURRENT_VERSION"* "$SOURCES"

cd "$BASEDIR"

# Generate OpenVPN-GUI tarball from the correct tag/branch
cd openvpn-gui
git checkout -B "$OPENVPN_GUI_BRANCH" "$OPENVPN_GUI_BRANCH"
git pull --rebase origin "$OPENVPN_GUI_BRANCH"

# Update minor version in configure.ac
sed -E -i s/"define\(\[_GUI_VERSION_MINOR\], \[([[:digit:]]+)\]\)"/"define\(\[_GUI_VERSION_MINOR\], \[$OPENVPN_GUI_CURRENT_MIN_VERSION\]\)"/1 configure.ac
# if configure.ac was already updated, assume everything is fine as is
if ! git diff --exit-code; then
    git add configure.ac
    git commit --author="$GIT_AUTHOR" -s -m "Bump version to $OPENVPN_GUI_CURRENT_FULL_VERSION" configure.ac
    git tag -a "v$OPENVPN_GUI_CURRENT_FULL_VERSION" -m "Version $OPENVPN_GUI_CURRENT_FULL_VERSION"
    git tag -a "OpenVPN-$OPENVPN_CURRENT_VERSION-$INSTALLER_VERSION" -m "OpenVPN-$OPENVPN_CURRENT_VERSION-$INSTALLER_VERSION"
fi

COMMIT_DATE_GUI=$(git log --no-show-signature -n1 --format="%cD")

echo "Creating OpenVPN-GUI source package"
autoreconf -vi > /dev/null 2>&1
./configure --enable-distonly > /dev/null
make distdir > /dev/null
$TAR_REP --mtime="$COMMIT_DATE_GUI" -chf - "openvpn-gui-$OPENVPN_GUI_CURRENT_MAJ_VERSION" \
    | gzip -c > "openvpn-gui-$OPENVPN_GUI_CURRENT_MAJ_VERSION.tar.gz"
cp -v "openvpn-gui-$OPENVPN_GUI_CURRENT_MAJ_VERSION.tar.gz" "$SOURCES"
cd "$BASEDIR"

cd "$SOURCES"
