#! /bin/bash
# This is intended to be used to run an automated build to make it easier to push
# dev/test updates to people who want to help find bugs.

SRC_DIR=`pwd`
BUILD_DIR=${SRC_DIR}/../build
DATE=`date +"%Y%m%d_%H%M"`
DATE_FMT="%Y%m%d_%H%M%S"

if [ "$#" -gt 0 ]; then
    BUILD_DIR="$1"
fi
if [ "$#" -gt 1 ]; then
    SRC_DIR="$2"
fi

BUILD_LOG=${BUILD_DIR}/build_${DATE}.log
echo "====> Starting build: `date +\"${DATE_FMT}\"`" >> ${BUILD_LOG}

if [ ! -d ${BUILD_DIR} ]; then
    mkdir -p ${BUILD_DIR}
fi

cd ${BUILD_DIR}

rm -rf ${BUILD_DIR}/vitality
rm -f vitality.zip
touch ${BUILD_LOG}

echo "====> Cloning from git: `date +\"${DATE_FMT}\"`" >> ${BUILD_LOG}
git clone --quiet https://github.com/sixones/vitality.git >> ${BUILD_LOG}

echo "====> Building app: `date +\"${DATE_FMT}\"`" >> ${BUILD_LOG}
(cd vitality/src ; xcodebuild -target Vitality -configuration Release >> ${BUILD_LOG})

SUCC=`tail ${BUILD_LOG} | grep -c " BUILD SUCCEEDED "`
if [ ${SUCC} -eq 1 ]; then
    APP=`tail ${BUILD_LOG} | grep "^Touch " | sed -e 's/Touch //'`
# handle cases where BUILD_DIR is absolute and where it's relative
    case ${APP} in
        /*) ;;
        *) APP="${BUILD_DIR}/vitality/src/${APP}" ;;
    esac
    echo "====> Zipping app: `date +\"${DATE_FMT}\"`" >> ${BUILD_LOG}
    zip -q -r vitality.zip "${APP}"
# Sign the zip file

# Build the database
    echo "====> Building Database: `date +\"${DATE_FMT}\"`" >> ${BUILD_LOG}
    cp ${SRC_DIR}/dbscripts/db_config.py ${BUILD_DIR}/vitality/dbscripts/
    (cd ${BUILD_DIR}/vitality/dbscripts ; bash ./build_dbexport.sh >> ${BUILD_LOG})

# Push everything to a server somewhere
# vitality.zip
# vitality/dbscripts/database.sql.bz2
# vitality/dbscripts/database.xml
fi

echo "====> Ending build: `date +\"${DATE_FMT}\"`" >> ${BUILD_LOG}
