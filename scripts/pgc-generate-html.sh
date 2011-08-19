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
    echo "  $0 ORIG_DIR BASE_DIR OUT_DIR [STYLESHEET_DIR]"
    echo
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

while [ $# -gt 0 ]
do
	case "$1" in
		--) shift; break;;
		-*) usage;;
		*)  break;;
	esac
	shift;
done

if [ $# -lt 3 ] || [ $# -gt 4 ]
then
	usage
fi

ORIG_DIR=$1
SRC_DIR=$2
OUT_DIR=$3
if [ -n "$4" ]
then
	STYLESHEET_DIR=$4
	STYLESHEET_FILE=${STYLESHEET_DIR}/pg-chunked-web.xsl
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

check_dir "$ORIG_DIR" 1
ORIG_DIR=${ORIG_DIR%\/}
check_dir "$SRC_DIR" 1
SRC_DIR=${SRC_DIR%\/}
check_dir "$OUT_DIR" 0
OUT_DIR=${OUT_DIR%\/}

WORKDIR=`mktemp -d -t cicero-XXXX`
cp -r $SRC_DIR/* $WORKDIR

for f in $BLACKLIST
do
	mkdir -p `dirname $WORKDIR/$f`
	cp $ORIG_DIR/$f $WORKDIR/$f
done

sed -i -e 's/&bookindex;/<!-- \&bookindex; -->/' $WORKDIR/postgres.xml
sed -i -e 's/\"version.xml\">$/\"version.xml\">\n\%version;/' $WORKDIR/postgres.xml
sed -i -e 's/\"filelist.xml\">$/\"filelist.xml\">\n\%filelist;/' $WORKDIR/postgres.xml
sed -i -e 's/entity/ENTITY/' $WORKDIR/filelist.xml

xsltproc --xinclude --nonet -stringparam profile.condition html \
    -stringparam profile.value "no" \
    -stringparam use.id.as.filename "yes" \
	-stringparam base.dir $OUT_DIR/ \
    ${STYLESHEET_FILE} ${WORKDIR}/postgres.xml 2>/dev/null

if [ -n "$4" ]
then
	mkdir -p $OUT_DIR/stylesheets
	mkdir -p $OUT_DIR/images
	cp $STYLESHEET_DIR/*.css $OUT_DIR/stylesheets/ 
	cp $STYLESHEET_DIR/img/*.png $OUT_DIR/images/ 
	sed -i -e "s|../stylesheets|stylesheets|g" $OUT_DIR/*.html
	sed -i -e "s|../images|images|g" $OUT_DIR/*.html
fi

