#!/bin/bash

# Script to automate the creation of the AUTHORS.rst file in the bootstrap script. Still more to do but this is a start

AUTHOR_FILE='AUTHORS.rst'
function usage()
{
    echo "=========USAGE========="
    echo "-d <diff> (required)"
    echo "    For example: -d 'v2017.01.10..HEAD'"
    echo "-r <bootstrap repo location> (required)"
    echo "    For example: -r '/home/ch3ll/git/salt-bootstrap"
    echo "Full Example usage: $0 -r '/home/ch3ll/git/salt-bootstrap' -d 'v2017.01.10..HEAD'"
    exit 1
}

while getopts "d:r:h" opt; do
  case $opt in
    d)
      DIFF=${OPTARG}
      ;;
    r)
      REPO=${OPTARG}
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

[[ ! -z ${DIFF} ]] || usage
[[ ! -z ${REPO} ]] || usage

cd ${REPO}

authors=$(git rev-list ${DIFF} --format='%aN' | sort -u | grep -v commit |  sed -e 's/^[[:space:]]*//' | tail -n +2 |  tr '\n' ':')

IFS=":"
for author in ${authors[@]};do
    grep -qi ${author} AUTHORS.rst || echo "$author" >> $AUTHOR_FILE
    #TODO: Add it to to the file alphabetically
    #TODO: also grab the email for the user
done
