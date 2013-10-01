#! /bin/bash
# This is intended to be used to run an automated build to make it easier to push
# dev/test updates to people who want to help find bugs.

SRC_DIR=`pwd`
BUILD_DIR=${SRC_DIR}/../build
DATE=`date +"%Y%m%d_%H%M"`
BUILD_LOG=${BUILD_DIR}/build_${DATE}.log

if [ "$#" -gt 0 ]; then
    BUILD_DIR="$1"
fi
if [ "$#" -gt 1 ]; then
    SRC_DIR="$2"
fi

if [ ! -d ${BUILD_DIR} ]; then
    mkdir -p ${BUILD_DIR}
fi

cd ${BUILD_DIR}

touch ${BUILD_LOG}
if [ -d ${BUILD_DIR}/vitality ]; then
    rm -rf ${BUILD_DIR}/vitality
fi
git clone https://github.com/sixones/vitality.git >> ${BUILD_LOG}

(cd vitality/src ; xcodebuild >> ${BUILD_LOG})

SUCC=`tail ${BUILD_LOG} | grep -c " BUILD SUCCEEDED "`
if [ ${SUCC} -eq 1 ]; then
    APP=`tail ${BUILD_LOG} | grep "^Touch " | sed -e 's/Touch //'`
    rm -f vitality.zip
# handle cases where BUILD_DIR is absolute and where it's relative
    case $1 in
        /*) ;;
        *) APP="${BUILD_DIR}/vitality/src/${APP}" ;;
    esac
    zip -q -r vitality.zip "${APP}"
# Sign the zip file

# Build the database
    cp ${SRC_DIR}/dbscripts/db_config.py ${BUILD_DIR}/vitality/dbscripts/
    (cd ${BUILD_DIR}/vitality/dbscripts ; make ; bash ./build_dbexport.sh)

# Push everything to a server somewhere
# vitality.zip
# vitality/dbscripts/database.sql.bz2
# vitality/dbscripts/database.xml
fi

