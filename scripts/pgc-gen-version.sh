#!/bin/bash

POSTGRESQL_GIT_DIR=$1
BRANCH_REF=$2

VERSION=$(git --git-dir="$POSTGRESQL_GIT_DIR" cat-file blob $BRANCH_REF:configure.in | \
awk -F ',' '/AC_INIT/{gsub("[][ ]","",$2); print $2}')
MAJORVERSION=$(expr "$VERSION" : "\([0-9][0-9]*\.[0-9][0-9]*\)")

echo "<!ENTITY version \"${VERSION}\">"
echo "<!ENTITY majorversion \"${MAJORVERSION}\">"
