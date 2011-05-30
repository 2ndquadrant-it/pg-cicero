#!/bin/bash

function usage(){
    echo "Usage:"
    echo 
    echo "  $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -b BASE_DIR        path of postgres xml files"
    echo "  -s STYLESHEET_DIR  path of postgres stylesheets directory"
    echo "  -o OUTPUT_DIR      where generated html files will be placed"
    echo
}

if [ $# -eq 0 ]
then
    usage
    exit 65
fi

while getopts ":b:s:o:" opt; do
    case $opt in
         b)
             SRCDIR=$OPTARG
             ;;
         s)
             STYLESHEETDIR=$OPTARG
             ;;
         o)
             DSTDIR=$OPTARG
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
if [ ! -n "$SRCDIR" ]; then
    echo
    echo "ERROR: you must specify a directory where original DocBook xml files are located (-b option)."
    usage
    exit 1
fi
if [ ! -n "$DSTDIR" ]; then
    echo 
    echo "ERROR: you must specify a destination directory for HTML files (-o option) "
    usage
    exit 1
fi
if [ ! -n "$STYLESHEETDIR" ]; then
    echo 
    echo "ERROR: you must specify a directory with stylesheet files (-s option) "
    usage
    exit 1
fi

if [ ! -d "$DSTDIR" ]
then
     mkdir -p $DSTDIR
fi

xsltproc --xinclude --nonet -stringparam profile.condition html \
    -stringparam profile.value "no" \
    -stringparam use.id.as.filename "yes" \
    -stringparam base.dir ${DSTDIR}/ \
    ${STYLESHEETDIR}/pg-chunked.xsl ${SRCDIR}/postgres.xml

for filename in $( find $DSTDIR -name '*.html' )
do
    sed -i -e "s@text/html@application/xhtml+xml@g" $filename; 
done

mkdir -p ${DSTDIR}/stylesheets
cp ${STYLESHEETDIR}/*.css ${DSTDIR}/stylesheets

mkdir ${DSTDIR}/images 
cp ${STYLESHEETDIR}/img/*.png ${DSTDIR}/images

for f in $( find $DSTDIR -type f -name '*.html' )
do
    sed -i -e "s@../stylesheets@stylesheets@g" $f
    sed -i -e "s@../images@images@g" $f
done

