#!/bin/bash

usage() {
cat << EOF
usage: $0 options

Automate the branch merge-forward process for SaltStack/salt-bootstrap.git

There are only two branches in the salt-bootstrap repository: "develop" and "stable".
The "develop" branch should always be merged into the "stable" branch, therefore,
there are not script options in this file.

OPTIONS:
   -h      Show this help message.
   -r      Repo you want to clone (REQUIRED)
   -c     Specify the sync command you want to use to sync the build (REQUIRED)
   -b      Build Directory (REQUIRED)
   -s      Deploy to staging if -s is set
   -v      Server to deploy staging to
   -x      Command to run on deployment server
example: ${0} -r 'git@github.com:saltstack/docs.git' -c 'upload-docs.sh' -b doc-landing  -s -v hostname -x "bash deploy_staging.sh"
EOF
exit 1
}

STAGING=False
while getopts "hr:c:b:sv:x:" OPTION
do
    case ${OPTION} in
        h)
            usage
            exit 1
            ;;
        r)
            REPO=${OPTARG}
            ;;
        c)
            SYNC_CMD=${OPTARG}
            ;;

        b)
            BUILD_DIR=${OPTARG}
            ;;
        s)
            STAGING=True
            ;;
        v)
            SERVER=${OPTARG}
            ;;
        x)
            STAGING_CMD=${OPTARG}
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

[[ -z ${REPO} ]] && usage
[[ -z ${BUILD_DIR} ]] && usage
[[ -z ${SYNC_CMD} ]] && usage

REPO_NAME=$(echo ${REPO} | awk -F '/' {'print $2'} | sed 's/.git//')
REPO_DIR="/tmp/${REPO_NAME}"
BUILD_DIR="${REPO_DIR}/${BUILD_DIR}"

clone_repo() {
    if [ -d ${REPO_DIR} ]; then
       echo "Removing ${REPO_DIR}"
       rm -rf ${REPO_DIR}
    fi

    echo "Cloneing ${REPO} into ${REPO_DIR}"
    git clone ${REPO} ${REPO_DIR}

    if [ ! -d ${REPO_DIR} ]; then
       echo "${REPO_DIR} does not exist. Exiting"
       exit 1
    fi
}

build_docs() {
    cd ${BUILD_DIR}
    acrylamid co
}

sync_docs() {
    echo "Checking if ${SYNC_CMD} exists"
    which ${SYNC_CMD} || exit 1
    ${SYNC_CMD}
}

sync_staging() {
    ssh root@${SERVER} ${STAGING_CMD}
}

clone_repo
build_docs
sync_docs

if [ "${STAGING}" = True ]; then
    [[ -z ${STAGING_CMD} ]] && usage
    [[ -z ${SERVER} ]] && usage
    echo "Deploying to staging"
    sync_staging
fi
