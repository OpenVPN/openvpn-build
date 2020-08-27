#!/bin/sh
#
# sign-and-push.sh
#
# Add detached signatures to files that do not have them already. The first
# parameter to this command determines the directory in which to operate. Then 
# push the files to the secondary webserver (primary requires special 
# treatment).

usage() {
    echo "Usage: sign-and-push.sh <release-directory>"
    exit 1
}

SIGN_DIR="${1}/sources"

if [ "$SIGN_DIR" = "" ]; then
    usage
fi

test -d "${SIGN_DIR}"
if [ $? -ne 0 ]; then
    echo "ERROR: ${SIGN_DIR} is not a directory!"
    exit 1
fi

# Sign only files that match this pattern
MATCH="\.(exe|tar.gz|tar.xz|zip|msi)$"

. ./vars

if [ "$GPG_KEY_ID" = "" ]; then

    echo "ERROR: please define ID of the GPG key you wish to use!"
    exit 1
else
    $GPG $GPG_OPTS --list-keys $GPG_KEY_ID > /dev/null
    if [ $? -ne 0 ]; then
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

    $GPG $GPG_OPTS -v --verify ${SIGFILE} 2>&1 |grep -iE '(bad|expired)'
    if [ $? -ne 0 ]; then
        echo "Good signature: ${SIGFILE}"
        echo "Copying files to ${SECONDARY_WEBSERVER}"
        scp $FILE $SIGFILE $SECONDARY_WEBSERVER:$SECONDARY_WEBSERVER_PATH/
    fi
done

cd "${CWD}"
