#!/bin/sh
#
# verify-openvpn-release.sh
#
# This script downloads files from the webservers and verifies their GPG 
# signatures. This is done to help ensure that content delivery systems are
# not serving obsolete files and/or detached signatures.

usage() {
    echo "Usage: verify-openvpn-release.sh <release-directory>"
    exit 1
}

RELEASE_DIR=$1

if [ "${RELEASE_DIR}" = "" ]; then
    usage
fi

test -d "${RELEASE_DIR}"
if [ $? -ne 0 ]; then
    echo "ERROR: ${RELEASE_DIR} is not a directory!"
    exit 1
fi

. ./vars

CWD=`pwd`

TESTDIR="${RELEASE_DIR}/download_test"
test -d "${TESTDIR}" || mkdir "${TESTDIR}"
cd "${TESTDIR}"

echo
echo "Downloading release files from webservers"
echo
cat "../sources/urls.txt"|while read URL; do
    PREFIX=`echo $URL|cut -d "/" -f 3`
    FILENAME=`echo $URL|awk -F'/' '{print $NF}'`
    echo "Downloading ${URL}"
    mkdir -p $PREFIX
    wget --quiet $URL -O $PREFIX/$FILENAME
done

echo
echo "Verifying signatures"
echo
for DIR in `find . -mindepth 1 -type d`; do
    for SIGNATURE in `ls $DIR/*.asc`; do
        $GPG $GPG_OPTS -v --verify $SIGNATURE > /dev/null 2>&1

        # This is consider a failure even by GnuPG
        if [ $? -eq 0 ]; then
            echo "Good signature: ${SIGNATURE}"
        else
            echo "Bad signature: ${SIGNATURE}"
        fi

        # Separate check for expired private key: even though gpg returns 0 this 
        # is not ok for us
        $GPG $GPG_OPTS -v --verify $SIGNATURE 2>&1 | grep -i expire

    done
done

cd "${CWD}"
