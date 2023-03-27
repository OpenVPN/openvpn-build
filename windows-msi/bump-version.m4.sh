#!/bin/sh
#
# Change PRODUCT_CODE and PRODUCT_VERSION in version.m4

# Get current product version
PRODUCT_FULL_VERSION=`grep -E '^define\(\[PRODUCT_VERSION' version.m4|cut -d " " -f 2|tr -d '[])'`
# Get current product code
PRODUCT_CODE=`grep -E 'define\(\[PRODUCT_CODE' version.m4|cut -d " " -f 2|tr -d '[{}])'`

# Increment product version unless specified by environment (e.g. release build)
if [ -z "${PRODUCT_VERSION_NEW:-}" ]; then
  PRODUCT_VERSION=$(echo $PRODUCT_FULL_VERSION|cut -d "." -f 1,2)
  PRODUCT_BUILD=$(echo $PRODUCT_FULL_VERSION|cut -d "." -f 3|sed s/^0*//g)
  PRODUCT_BUILD_NEW=$(expr $PRODUCT_BUILD + 1)
  PRODUCT_VERSION_NEW="$PRODUCT_VERSION.$(printf "%03d\n" $PRODUCT_BUILD_NEW)"
fi

# Create new product code
PRODUCT_CODE_NEW=`uuidgen |tr '[:lower:]' '[:upper:]'`

# Replace product code
sed -i s/"$PRODUCT_CODE"/"$PRODUCT_CODE_NEW"/1 version.m4

# Replace product version
sed -i s/"$PRODUCT_FULL_VERSION"/"$PRODUCT_VERSION_NEW"/g version.m4
