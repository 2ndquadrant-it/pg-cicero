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

source common.sh

function usage(){
    echo 
    echo "Usage:"
    echo 
    echo -e "\t$0 [OPTIONS] <BASE_DIR> <PO_DIR>"
    echo
    echo "Options:"
    echo "    -o OUTPUT_DIR  where generated .xml files will be placed"
    echo "    -l LANGUAGE    translation language"
    echo
}

while getopts ":o:l:" opt; do
    case $opt in
         o)
             OUTPUTDIR=$OPTARG
             ;;
         l)
             LANGUAGE=$OPTARG
             ;;
         \?)
             echo "Invalid option: -$OPTARG" >&2
             echo
             usage
             exit 1
             ;;
         :)
             echo "Option -$OPTARG requires an argument." >&2
             echo
             usage
             exit 1
             ;;
    esac
done
# Set default options

if [ ! -n "$OUTPUTDIR" ]; then
    OUTPUTDIR=$PWD
    echo "fadffdsfadsfafdafds"
    exit 1
fi
if [ -n "$LANGUAGE" ]; then
    LANGOPT="--language="$LANGUAGE
else
    LANGOPT="--mark-untranslated"
    echo "WARNING: Language not specified."
    LANGUAGE="untranslated"
fi

shift $((OPTIND-1))

if [ $# -ne 2 ]
then
    usage
    exit 65
fi

BASEDIR=$1
PODIR=$2

# Creates PO files 

TOTAL_STEPS=$( find $BASEDIR -type f -name '*.xml' | wc -l )  

declare -i ok
declare -i fail
declare -i i
ok=0
fail=0
i=0

WORKDIR=`mktemp -d -t pgcicero-XXXX`
cp -r $BASEDIR $WORKDIR/base

# These POTs simply doesn't exists

blacklist="filelist.xml ref/allfiles.xml standalone-install.xml postgres.xml"

# TODO avoid to do this manually
mkdir -p $OUTPUTDIR/ref

OUTPUTDIR=`echo ${OUTPUTDIR/%\//}`
PODIR=`echo ${PODIR/%\//}`

echo "-> Creating XMLs in '$OUTPUTDIR'"
for srcfile in $( find $BASEDIR -type f -name '*.xml' | sed -e "s|$BASEDIR||" ) 
do
    srcfile=`echo ${srcfile/#\//}`
    grep -q "$srcfile" <<< $blacklist
    if [ $? -eq 0 ]; then
        continue
    fi
    
    INPUT_FILE=$srcfile
    OUTPUT_FILE=$OUTPUTDIR/$srcfile
    PO_FILE=$PODIR/${srcfile%.*}.po 
    
    # Ugly hack
    #if [ "$srcfile" = "postgres.xml" ]; then
    #     START=2
    #     END=`grep -n '.\<book id="postgres">' ${WORKDIR}/base/${srcfile} | cut -d ':' -f 1`
    #     let "END -= 1"
    #     #remove entities
    #     sed -i -e "$START,${END}d" -e '/&.*;/d' ${WORKDIR}/base/${srcfile} 
    #     diff -burN ${WORKDIR}/base/${srcfile} ${BASEDIR}/${srcfile} > .uglyhack.patch
    #else
    #     sed -i -e '2s/^/<book>\n/; $s/$/\n<\/book>/' $WORKDIR/base/$INPUT_FILE
    #fi  
    
    # This one puts a root element in every xml
    sed -i -e '2s/^/<book>\n/; $s/$/\n<\/book>/' $WORKDIR/base/$INPUT_FILE
     
    xml2po $LANGOPT --po-file=$PO_FILE --output=$OUTPUT_FILE $WORKDIR/base/$INPUT_FILE

    # Delete the root element 
    sed -i -e '2s/<book*//; $d' $OUTPUT_FILE

    if [ $? -eq 0 ]; then
        ok=$ok+1
    else
        echo "ERROR generating $OUTPUT_FILE"
        fail=$fail+1
    fi
    echo -ne "$(progressbar_step $i)\r"
    i=$i+1

done

echo -e "$(progressbar_step $i)"
echo 
echo "  Complete!"
echo "  Total Files : ${i}"
echo "  Successes   : ${ok}"
echo "  Fails       : ${fail}"
#echo "  Files are in: ${WORKDIR}"
echo 

rm -r $WORKDIR
