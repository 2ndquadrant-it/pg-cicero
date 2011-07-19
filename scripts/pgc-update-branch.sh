#!/bin/bash
#
#   pg-cicero - PostgreSQL Documentation Translation Project
#   Copyright (C) 2011  2ndQuadrant Italy <info@2ndquadrant.it>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -e

function usage(){
	echo "Usage:"
	echo
	echo "  $0 [OPTIONS] POSTGRESQL_GIT_DIR [PGCICERO_GIT_DIR]"
	echo
	echo "Options:"
	echo "  -b BRANCH    the PostgreSQL branch to clone (Default: master)"
	echo "  -v           verbose"
	echo "  -q           quiet"
	echo
	echo "PGCICERO_GIT_DIR is assumed the parent directory of the one containing the script if not passed"
	exit 1
}

function die () {
	echo $@
	exit 128
}

BASE="$(cd $(dirname $0); pwd)"
DOCDIR="doc/src/sgml"
sgml2xml="$BASE/pgc-sgml2xml -i"

# default options
BRANCH="master"
VERBOSE=
QUIET=

set -- `getopt -u -n"$0" b:vq "$@"` || usage

while [ $# -gt 0 ]
do
	case "$1" in
		-b) BRANCH="$2"; shift;;
		-v) VERBOSE=1; QUIET=; sgml2xml="$sgml2xml -v";;
		-q) QUIET=1;VERBOSE=;;
		--) shift; break;;
		-*) usage;;
		*)  break;;
	esac
	shift;
done

if [ $# -lt 1 ] || [ $# -gt 2 ]
then
	usage
	exit -1
fi

POSTGRESQL_GIT_DIR=$1
PGCICERO_GIT_DIR=${2:-$(cd $BASE/..; pwd)}

# want to make sure that POSTGRESQL_GIT_DIR what is pointed to has a .git directory ...
git_dir="$(cd "$POSTGRESQL_GIT_DIR" 2>/dev/null && git rev-parse --git-dir 2>/dev/null)" ||
	die "ERROR: POSTGRESQL_GIT_DIR is not a git repository: \"$POSTGRESQL_GIT_DIR\""

if [ "$git_dir" = ".git" ];
then
	POSTGRESQL_GIT_DIR="$(cd $POSTGRESQL_GIT_DIR/.git; pwd)"
else
	POSTGRESQL_GIT_DIR="$(cd $POSTGRESQL_GIT_DIR; pwd)"
fi

# want to make sure that PGCICERO_GIT_DIR what is pointed to has a .git directory ...
git_dir="$(cd "$PGCICERO_GIT_DIR" 2>/dev/null && git rev-parse --git-dir 2>/dev/null)" ||
	die "ERROR: PGCICERO_GIT_DIR is not a git repository: \"$PGCICERO_GIT_DIR\""

if [ "$git_dir" = ".git" ];
then
	PGCICERO_GIT_DIR="$(cd $PGCICERO_GIT_DIR/.git; pwd)"
else
	PGCICERO_GIT_DIR="$(cd $PGCICERO_GIT_DIR; pwd)"
fi

# make sure that the requested branch exists in source repository
BRANCH_REF="$(git --git-dir="$POSTGRESQL_GIT_DIR" show-ref "$BRANCH" | head -n 1 | awk '{print $2}')"

if [ -z "$BRANCH_REF" ]
then
    die "ERROR: the branch \"$BRANCH\" does not exists in the source repository."
fi

# does it look like a postgresql repository?
if [ "$(git --git-dir="$POSTGRESQL_GIT_DIR" cat-file -t "$BRANCH":"$DOCDIR")" != "tree" ]
then
    die "ERROR: the branch \"$BRANCH\" does not look like a PostgreSQL one."
fi

[ "$QUIET" ] || echo "Updating documentation from the branch \"$BRANCH\"..."

WORKDIR=$(mktemp -d -t pgctmp-XXXX)
trap "rm -fr '$WORKDIR'" EXIT

[ "$VERBOSE" ] && echo "[v] Using workdir \"$WORKDIR\""

# extract the documentation from the source branch
[ "$VERBOSE" ] && echo "[v] Extract the documentation from the PostgreSQL git repository from branch \"$BRANCH\""
git --git-dir="$POSTGRESQL_GIT_DIR" archive --format=tar "$BRANCH_REF" "$DOCDIR"  | tar x -C "$WORKDIR"

[ "$VERBOSE" ] && echo "[v] Convert the documentation from sgml to xml"
$sgml2xml "$WORKDIR/$DOCDIR" "$WORKDIR/xml"

[ "$VERBOSE" ] && echo "[v] Commit the result to pg-cicero repository"

# git black magic
export GIT_INDEX_FILE="$WORKDIR/index"
export GIT_DIR="$PGCICERO_GIT_DIR"
cd $WORKDIR

DEST_BRANCH="postgresql/$BRANCH"
DEST_REF="$(git show-ref "$DEST_BRANCH" | head -n 1 | awk '{print $2}')"
# if it's only remote, track it locally
if [ -n "$DEST_REF" ] && [ "$DEST_REF" != "refs/heads/$DEST_BRANCH" ]
then
    [ "$VERBOSE" ] && echo "[v] Setup a local branch \"$DEST_BRANCH\" tracking \"$DEST_REF\""
    git branch --track "$DEST_BRANCH" "$DEST_REF"
fi
# if it exists, update the index
COMMITOPT=
if git show-ref --quiet --verify "refs/heads/$DEST_BRANCH"
then
    git ls-tree -r --full-name "$DEST_BRANCH" | git update-index --index-info
    COMMITOPT="-p \"$DEST_BRANCH\""
else
    [ "$VERBOSE" ] && echo "[v] Create new empty branch \"$DEST_BRANCH\""
fi
[ "$VERBOSE" ] && echo "[v] Add updated files"
find xml -type f | git update-index --add --stdin
SHA=$(git write-tree)
if [ $? -gt 0 ] || [ -z "$SHA" ]
then
    die "git write-tree failed"
fi
if git show-ref --quiet --verify "refs/heads/$DEST_BRANCH" && git diff-index --cached --quiet "$DEST_BRANCH" --ignore-submodules --
then
    echo "No changes to commit"
    exit 1
fi
[ "$VERBOSE" ] && echo "[v] Commit updates"
COMMITSHA=$(echo "pgc-update-branch $DEST_BRANCH" | git commit-tree "$SHA" $COMMITOPT)
if [ $? -gt 0 ] || [ -z "$COMMITSHA" ]
then
    die "git commit-tree failed"
fi
git update-ref "refs/heads/$DEST_BRANCH" "$COMMITSHA"

[ "$QUIET" ] || {
    echo "Update completed."
    echo "The result is in branch \"$DEST_BRANCH\" into the \"${PGCICERO_GIT_DIR}\" repository."
    echo "Please check content then merge it to branch \"$BRANCH\""
}
exit 0
