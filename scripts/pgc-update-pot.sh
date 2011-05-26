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
    echo "Usage:"
    echo 
    echo "  $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -b BASE_DIR    where original XML files in DocBook format are"
    echo "  -o OUTPUT_DIR  where translated .po files will be placed"
    echo
}

if [ $# -eq 0 ]
then
    usage
    exit 65
fi

while getopts ":b:o:" opt; do
    case $opt in
         b)
             BASEDIR=$OPTARG
             ;;
         o)
             POTDIR=$OPTARG
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
if [ ! -n "$POTDIR" ]; then
    echo 
    echo "ERROR: you must specify a destination directory for the translated PO files (-o option) "
    usage
    exit 1
fi

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


#
# Make a temporary copy of base xml
#
#WORKDIR=`mktemp -d -t cicero-XXXX`
#cp -r $BASEDIR $WORKDIR/base

declare -i tot 
declare -i ok
declare -i fail
declare -i i
i=0
tot=0
ok=0
fail=0
echo "-> Generating POTs in "$POTDIR

for srcfile in $( find $BASEDIR -type f -name '*.xml' | sed -e "s|$BASEDIR/||" ) 
do
     INPUT_FILE=$srcfile
     OUTPUT_FILE=$POTDIR/$( echo $srcfile | sed -e 's/\.xml/\.po/' )
    
     #sed -i -e 's/&mdash;/-/g' $INPUT_FILE
     if [ ! -d `dirname $OUTPUT_FILE` ]; then
         mkdir -p `dirname $OUTPUT_FILE`
     fi
     xml2po -o $OUTPUT_FILE $INPUT_FILE
     
     if [ $? -eq 0 ]; then
        ok=$ok+1
     else
        echo "ERROR generating " $OUTPUT_FILE
        fail=$fail+1
     fi
     echo -ne "$(progressbar_step $i)\r"
     tot=$tot+1 
     i=$i+1
done

echo -ne "$(progressbar_step $i)\r"
echo 
echo "  Complete!"
echo "  Total Files : " $tot 
echo "  Successes   : " $ok
echo "  Fails       : " $fail
echo 
