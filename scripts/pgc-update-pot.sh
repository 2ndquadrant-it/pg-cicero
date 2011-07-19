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

. common.sh

function usage(){
	echo "Usage:"
	echo
	echo "  $0 [OPTIONS] SRC_DIR OUTPUT_DIR"
	echo
	echo "Options:"
	echo "  -p        show a progressbar"
	echo "  -k        keep the workdir, for debug only"
	echo
    exit 1
}

if [ $# -eq 0 ]
then
	usage
fi

BASEDIR="$(cd $(dirname $0); pwd)"
PROGRESSBAR=
KEEP=

set -- `getopt -u -n"$0" pk "$@"` || usage

while [ $# -gt 0 ]
do
	case "$1" in
		-p) PROGRESSBAR=1; ;;
		-k) KEEP=1; ;;
		--) shift; break;;
		-*) usage;;
		*)  break;;
	esac
	shift;
done

if [ $# -ne 2 ]
then
	usage
fi

SRC_DIR=$1
OUT_DIR=$2

if [ ! -d $SRC_DIR ]
then
	die "Directory $SRC_DIR doesn't exist!"
fi
SRC_DIR=`echo $SRC_DIR | sed -e 's/\/$//'`

[ "$PROGRESSBAR" ] && TOTAL_STEPS=$( find $SRC_DIR -type f -name '*.xml' | wc -l )

#
# Make a temporary copy of base xml
#
WORKDIR=`mktemp -d -t cicero-XXXX`
[ "$KEEP" ] && echo "Workdir is ${WORKDIR}"
cp -r $SRC_DIR/* $WORKDIR

if [ ! -d $OUT_DIR ]
then
    mkdir -p $OUT_DIR
fi
echo "-> Generating POTs in $OUT_DIR"

#
# These files will not be generated
#
blacklist="filelist.xml ref/allfiles.xml standalone-install.xml"

declare -i ok
declare -i fail
declare -i i
i=0
ok=0
fail=0
for srcfile in $( find "$SRC_DIR" -type f -name '*.xml' | sed -e "s|$SRC_DIR/||" )
do
	grep -q "$srcfile" <<< $blacklist
	if [ $? -eq 0 ]; then
		continue
	fi

	INPUT_FILE=$srcfile
	OUTPUT_FILE=$OUT_DIR/${srcfile%.*}.po

	if [ ! -d `dirname $OUTPUT_FILE` ]; then
		mkdir -p `dirname $OUTPUT_FILE`
	fi

	if [ "$srcfile" == "postgres.xml" ]; then
		# FIXME questo rimuove le entità ma poi vanno rimesse.
		sed -i -e 's/&.*;//' $WORKDIR/$INPUT_FILE
	else
		# This hack adds a root element to the file
		sed -i -e '2s/^/<book>\n/; $s/$/\n<\/book>/' $WORKDIR/$INPUT_FILE
	fi

	xml2po -o $OUTPUT_FILE $WORKDIR/$INPUT_FILE

	if [ $? -eq 0 ]; then
		ok=$ok+1
	else
		echo "ERROR generating $OUTPUT_FILE"
		fail=$fail+1
	fi
	[ "$PROGRESSBAR" ] && echo -ne "$(progressbar_step $i)\r"

	tot=$tot+1
	i=$i+1
done

i=$i+1
[ "$PROGRESSBAR" ] && echo -ne "$(progressbar_step $i)"
i=$i-1
echo
echo "  Complete!"
echo "  Total Files : $i"
echo "  Successes   : $ok"
echo "  Fails       : $fail"
echo

[ ! "$KEEP" ] && rm -r $WORKDIR

exit 0
# vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
