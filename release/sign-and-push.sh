#!/bin/bash
#
# sign-and-push.sh
#
# Add detached signatures to files that do not have them already. The first
# parameter to this command determines the directory in which to operate. Then 
# push the files to the secondary webserver (primary requires special 
# treatment).

set -eux
# some tests depend on it not enabled
#set -o pipefail

SCRIPT_DIR="$(dirname $(readlink -e "${BASH_SOURCE[0]}"))"
TOP_DIR="$SCRIPT_DIR/.."
pushd "$TOP_DIR"

. "$SCRIPT_DIR/vars"

: ${GPG_OPTS:=}

SIGN_DIR="${OUTPUT}/upload"

if [ ! -d "${SIGN_DIR}" ]; then
    echo "ERROR: ${SIGN_DIR} is not a directory!"
    exit 1
fi

# Sign only files that match this pattern
MATCH="\.(exe|tar.gz|tar.xz|zip|msi|msm)$"

if [ "${GPG_KEY_ID:-}" = "" ]; then

    echo "ERROR: please define ID of the GPG key you wish to use!"
    exit 1
else
    if ! $GPG $GPG_OPTS --list-keys $GPG_KEY_ID > /dev/null; then
        echo "ERROR: GPG key $1 not found!"
        exit 1
    fi
fi

# Switch to the working directory
CWD=`pwd`
cd "${SIGN_DIR}"

URL_FILE="urls.txt"
rm -f "${URL_FILE}"

# Check for missing signatures
ls|grep -E "${MATCH}"|while read FILE; do

    # We want to get a list of files to purge from the CloudFlare cache.
    echo "${PRIMARY_WEBSERVER_BASEURL}/${FILE}" >> "${URL_FILE}"
    echo "${PRIMARY_WEBSERVER_BASEURL}/${FILE}.asc" >> "${URL_FILE}"

    # This server is not in CloudFlare but verifying the downloads
    # still makes sense.
    echo "${SECONDARY_WEBSERVER_BASEURL}/${FILE}" >> "${URL_FILE}"
    echo "${SECONDARY_WEBSERVER_BASEURL}/${FILE}.asc" >> "${URL_FILE}"

    SIGFILE="${FILE}.asc"
    if ! [ -r $SIGFILE ]; then
        echo "Missing signature for ${FILE}"
        $GPG $GPG_OPTS -a --default-key $GPG_KEY_ID --output $SIGFILE --detach-sig $FILE
    fi

    if ! $GPG $GPG_OPTS -v --verify ${SIGFILE} 2>&1 |grep -iE '(bad|expired)'; then
        echo "Good signature: ${SIGFILE}"
        echo "Copying files to ${SECONDARY_WEBSERVER}"
        chmod 644 $FILE $SIGFILE # ensure sane permissions
        scp -p $FILE $SIGFILE $SECONDARY_WEBSERVER:$SECONDARY_WEBSERVER_PATH/
    fi
done

cd "${CWD}"
