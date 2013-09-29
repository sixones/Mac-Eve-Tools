#! /bin/bash
# This is intended to be used to run an automated build to make it easier to push
# dev/test updates to people who want to help find bugs.

BUILD_DIR=../build
DATE=`date +"%Y%m%d_%H%M"`
BUILD_LOG=build_${DATE}.log


if [ ! -d ${BUILD_DIR} ]; then
    mkdir ${BUILD_DIR}
fi

cd ${BUILD_DIR}

touch ${BUILD_LOG}
if [ -d vitality ]; then
    rm -rf vitality
fi
git clone https://github.com/sixones/vitality.git >> ${BUILD_LOG}

cd vitality/src
xcodebuild >> ../../${BUILD_LOG}

SUCC=`tail ../../${BUILD_LOG} | grep -c " BUILD SUCCEEDED "`
if [ ${SUCC} -eq 1 ]; then
    APP=`tail ../../${BUILD_LOG} | grep "^Touch " | sed -e 's/Touch //'`
    cd ../..
    rm -f vitality.zip
    zip -q -r vitality.zip "${APP}"
# Sign the zip file
# Build the database
# Push everything to a server somewhere
fi

