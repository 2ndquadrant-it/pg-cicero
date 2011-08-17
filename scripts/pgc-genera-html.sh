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
    echo "  $0 [OPTIONS] BASE_DIR OUT_DIR [STYLESHEET_DIR]"
    echo
	echo "Options:"
	echo "  -p                 show a progressbar"
	echo "  -k                 keep the workdir, for debug only"
	echo ""
	echo "  STYLESHEET_DIR, if omitted, is tried to be taken from the system, we do not ensure success."
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

if [ $# -lt 2 ] || [ $# -gt 3 ]
then
	usage
fi

SRC_DIR=$1
OUT_DIR=$2
if [ -n "$3" ]
then
	STYLESHEET_DIR=$3
	STYLESHEET_FILE=${STYLESHEET_DIR}/pg-chunked.xsl
else
	###########################################################
	# Determine the stylesheet directory
	###########################################################
	STYLESHEET_SYSTEM_DIR_CANDIDATES="
		/usr/share/xml/docbook/xsl-stylesheets-1.76.1/html
		/opt/local/share/xsl/docbook-xsl/html
		/usr/share/xml/docbook/stylesheet/docbook-xsl/html"
	STYLESHEET_DIR=

	for d in $STYLESHEET_SYSTEM_DIR_CANDIDATES
	do
		if [ -d $d ]
		then
			STYLESHEET_DIR=$d
			STYLESHEET_FILE=${STYLESHEET_DIR}/chunk.xsl
			break;
		fi
	done

	if [ ! -d $STYLESHEET_DIR ]
	then
		echo "Cannot find stylesheets system directory"
		exit -1
	fi
	###########################################################
fi

if [ ! -d $SRC_DIR ]
then
	die "Directory $SRC_DIR doesn't exist!"
fi
SRC_DIR=`echo $SRC_DIR | sed -e 's/\/$//'`

[ "$PROGRESSBAR" ] && TOTAL_STEPS=$( find $SRC_DIR -type f -name '*.xml' | wc -l )

xsltproc --xinclude --nonet -stringparam profile.condition html \
    -stringparam profile.value "no" \
    -stringparam use.id.as.filename "yes" \
	-stringparam base.dir $OUT_DIR \
    ${STYLESHEET_FILE} ${SRC_DIR}/postgres.xml

if [ -n "$3" ]
then
	[ -d ${OUT_DIR}/stylesheets ] || mkdir -p ${OUT_DIR}/stylesheets
	cp ${STYLESHEET_DIR}/*.css ${OUT_DIR}/stylesheets
	[ -d ${OUT_DIR}/images ] || mkdir ${OUT_DIR}/images
	cp ${STYLESHEET_DIR}/img/*.png ${OUT_DIR}/images
fi

for f in $( find $OUT_DIR -type f -name '*.html' )
do
    sed -i -e "s@../stylesheets@stylesheets@g" $f
    sed -i -e "s@../images@images@g" $f
done

