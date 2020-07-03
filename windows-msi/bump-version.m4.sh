#!/bin/sh
#
# Change PRODUCT_CODE and PRODUCT_VERSION in version.m4. Primarily intended to
# be used within a CI system, not for release builds.

# Get current product version
PRODUCT_FULL_VERSION=`grep -E '^define\(\[PRODUCT_VERSION' version.m4|cut -d " " -f 2|tr -d '[])'`
PRODUCT_VERSION=`echo $PRODUCT_FULL_VERSION|cut -d "." -f 1,2`
PACKAGE_VERSION=`echo $PRODUCT_FULL_VERSION|cut -d "." -f 3|sed s/^0*//g`

# Get current product code
PRODUCT_CODE=`grep -E 'define\(\[PRODUCT_CODE' version.m4|cut -d " " -f 2|tr -d '[{}])'`
PRODUCT_CODE_FIRST_SECTION=`echo $PRODUCT_CODE|cut -d "-" -f 1-4`

# Create new product code
PRODUCT_CODE_LAST_SECTION_NEW=`openssl rand -hex 6|tr -s '[:lower:]' '[:upper:]'`
PRODUCT_CODE_NEW="${PRODUCT_CODE_FIRST_SECTION}-${PRODUCT_CODE_LAST_SECTION_NEW}"

# Increment product version
PACKAGE_VERSION_NEW=$(expr $PACKAGE_VERSION + 1)
PACKAGE_VERSION_NEW=`printf "%03d\n" $PACKAGE_VERSION_NEW`

# Replace product code
sed -i s/"$PRODUCT_CODE"/"$PRODUCT_CODE_NEW"/1 version.m4

# Replace product version
sed -i s/"$PRODUCT_FULL_VERSION"/"$PRODUCT_VERSION.$PACKAGE_VERSION_NEW"/g version.m4
