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
    echo
    echo "Usage:"
    echo
    echo "    $0 [OPTIONS] SRC_DIR PO_DIR OUT_DIR"
    echo
    echo "Options:"
	echo "  -p        show a progressbar"
    echo
	exit 1
}

if [ $# -eq 0 ]
then
	usage
fi

BASEDIR="$(cd $(dirname $0); pwd)"
PROGRESSBAR=

set -- `getopt -u -n"$0" pk "$@"` || usage

while [ $# -gt 0 ]
do
	case "$1" in
		-p) PROGRESSBAR=1; ;;
		--) shift; break;;
		-*) usage;;
		*)  break;;
	esac
	shift;
done

if [ $# -ne 3 ]
then
	usage
fi

SRC_DIR=$1
PO_DIR=$2
OUT_DIR=$3

check_dir "$SRC_DIR" 1
SRC_DIR=${SRC_DIR%\/}
check_dir "$PO_DIR" 1
PO_DIR=${PO_DIR%\/}

[ "$PROGRESSBAR" ] && TOTAL_STEPS=$( find $SRC_DIR -type f -name '*.xml' | wc -l )

WORKDIR=`mktemp -d -t cicero-XXXX`
[ "$KEEP" ] && echo "Workdir is ${WORKDIR}"

check_dir "$OUT_DIR" 0
OUT_DIR=${OUT_DIR%\/}

declare -i ok
declare -i fail
declare -i i
ok=0
fail=0
i=0
echo "-> Creating XMLs in '$OUT_DIR'"
for srcfile in $( find "$SRC_DIR" -type f -name '*.xml' | sed -e "s|$SRC_DIR/||" )
do
	grep -q "$srcfile" <<< $BLACKLIST
	if [ $? -eq 0 ]; then
		continue
	fi

    INPUT_FILE=$srcfile
    OUTPUT_FILE=$OUT_DIR/$srcfile
    PO_FILE=$PO_DIR/${srcfile%.*}.po

	mkdir -p `dirname $OUTPUT_FILE`
	mkdir -p `dirname $WORKDIR/$INPUT_FILE`
	
	cp $SRC_DIR/$INPUT_FILE $WORKDIR/$INPUT_FILE	

	xml2po --po-file=$PO_FILE --output=$OUTPUT_FILE $WORKDIR/$INPUT_FILE

	if [ $? -eq 0 ]; then
		ok=$ok+1
	else
		echo "ERROR generating $OUTPUT_FILE"
		fail=$fail+1
	fi
	[ "$PROGRESSBAR" ] && echo -ne "$(progressbar_step $i)\r"

	rm $WORKDIR/$INPUT_FILE

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

exit 0

# vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab
