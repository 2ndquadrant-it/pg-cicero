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

function usage(){
    echo 
    echo "Usage:"
    echo 
    echo -e "\t$0 [OPTIONS]"
    echo
    echo "Options:"
    echo " -b BASE_DIR    where original XML files in DocBook format are"
    echo " -p PO_DIR      where translated po files are located"
    echo " -o OUTPUT_DIR  where generated .xml files will be placed"
    echo " -l LANGUAGE    translation language"
    echo
}

if [ $# -eq 0 ]
then
    usage
    exit 65
fi

while getopts ":b:p:o:l:" opt; do
    case $opt in
         b)
             BASEDIR=$OPTARG
             ;;
         p)
             PODIR=$OPTARG
             ;;
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

#
# Check for mandatory options
#
if [ ! -n "$BASEDIR" ]; then
    echo
    echo "ERROR: you must specify a directory where original DocBook xml files are located (-b option)."
    usage
    exit 1
fi
if [ ! -n "$PODIR" ]; then
    echo 
    echo "ERROR: you must specify a directory where translated DocBook po files are located (-f option)"
    usage
    exit 1
fi
if [ ! -n "$OUTPUTDIR" ]; then
    echo 
    echo "ERROR: you must specify a destination directory for the generated XML files (-t option) "
    usage
    exit 1
fi
if [ -n "$LANGUAGE" ]; then
    LANGOPT="--language="$LANGUAGE
else
    LANGOPT="--mark-untranslated"
    echo "WARNING: Language not specified"
    LANGUAGE="untranslated"
fi

#
# Creates PO files 
#

# determine terminal columns
MAX_COLS=$(stty -a | tr -s ';' '\n' | grep "column" | sed s/'[^[:digit:]]'//g)
TOTAL_STEPS=$( find $BASEDIR -type f -name '*.xml' | wc -l )  
PB_CHAR="#" 
PB_OFFSET=7 
PB_REAL_COLS=$(($MAX_COLS-$PB_OFFSET))     
function progressbar_step()
{
    PB_VALUE=$1 
    V=$((($PB_VALUE*100)/$TOTAL_STEPS))
    NCHAR=$((($V*$PB_REAL_COLS)/100))
    for((j=0; j<$NCHAR; j++)); do
        PB_BAR="$PB_BAR$PB_CHAR"
    done
    PB_PERC=$(printf "[%3d%%] " $V)
    echo -ne "$PB_PERC$PB_BAR\r"
}

declare -i tot 
declare -i ok
declare -i fail
declare -i i
i=0
tot=0
ok=0
fail=0

WORKDIR=`mktemp -d -t cicero-XXXX`
cp -r $BASEDIR $WORKDIR/base

#
# These POTs simply doesn't exists
#
blacklist="filelist.xml ref/allfiles.xml standalone-install.xml"

if [ ! -d $OUTPUTDIR ]; then
    mkdir -p $OUTPUTDIR
fi
echo "-> Creating XMLs in '$OUTPUTDIR'"
for srcfile in $( find $BASEDIR -type f -name '*.xml' | sed -e "s|$BASEDIR/||" ) 
do

    grep -q "$srcfile" <<< $blacklist
    if [ $? -eq 0 ]; then
        continue
    fi
    
    INPUT_FILE=$srcfile
    OUTPUT_FILE=$OUTPUTDIR/$srcfile
    PO_FILE=$PODIR/${srcfile%.*}.po 
   
    #echo "INPUT  FILE: ${WORKDIR}/base/${INPUT_FILE}"
    #echo "OUTPUT FILE: ${OUTPUT_FILE}"
    #echo "PO     FILE: ${PO_FILE}"

    if [ ! -d `dirname ${OUTPUT_FILE}` ]; then
        mkdir -p `dirname ${OUTPUT_FILE}`
    fi

    # Ugly hack
    if [ "$srcfile" = "postgres.xml" ]; then
         START=2
         END=`grep -n '.\<book id="postgres">' ${WORKDIR}/base/${srcfile} | cut -d ':' -f 1`
         let "END -= 1"
         #remove entities
         sed -i -e "$START,${END}d" -e '/&.*;/d' ${WORKDIR}/base/${srcfile} 
         diff -burN ${WORKDIR}/base/${srcfile} ${BASEDIR}/${srcfile} > .uglyhack.patch
         exit 1
    else
         sed -i -e '2s/^/<book>\n/; $s/$/\n<\/book>/' $WORKDIR/base/$INPUT_FILE
    fi  
     
    xml2po $LANGOPT --po-file=$PO_FILE --output=$OUTPUT_FILE $WORKDIR/base/$INPUT_FILE
    if [ "$srcfile" = "postgres.xml" ]; then
        patch $OUTPUT_FILE < .uglyhack.patch 
    else
        sed -i -e '2s/<book*//; $d' $OUTPUT_FILE
    fi

    if [ $? -eq 0 ]; then
        ok=$ok+1
    else
        echo "ERROR generating $OUTPUT_FILE"
        fail=$fail+1
    fi
    echo -ne "$(progressbar_step $i)\r"
    tot=$tot+1 
    i=$i+1

done

echo -e "$(progressbar_step $i)"
echo 
echo "  Complete!"
echo "  Total Files : ${tot}"
echo "  Successes   : ${ok}"
echo "  Fails       : ${fail}"
echo "  Files are in: ${WORKDIR}"
echo 

#rm -r $WORKDIR
