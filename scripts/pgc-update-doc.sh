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
    echo "  -b BRANCH      the PostgreSQL version to clone"
    echo "  -o OUTPUT_DIR  where is the PostgreSQL repository"
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
             BRANCH=$OPTARG
             ;;
         o)
             OUTPUT_DIR=$OPTARG
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
if [ ! -n "$BRANCH" ]; then
    echo
    echo "ERROR: " 
    usage
    exit 1
fi
if [ ! -n "$OUTPUT_DIR" ]; then
    echo 
    echo "ERROR: "
    usage
    exit 1
fi

if [ -d "$OUTPUT_DIR" ]; then
    if [ "$(ls -A $DIR)" ]; then
         if [ -d "$OUTPUT_DIR/.git" ]; then
             grep -q "git://git.postgresql.org/git/postgresql.git" ${OUTPUT_DIR}/.git/config
             if [ $? -eq 0 ]; then
                  echo "Postgres repoisitory found."
                  cd $OUTPUT_DIR
                  git checkout $BRANCH
                  git pull
                  cd -
                  echo "Repository updated."
                  exit 0 
             else
                  echo "Non-PostgreSQL repository found. Exiting." 
                  exit 65
             fi
         else
             echo "Directory $OUPUT_DIR exists and is not empty. Exiting."
             exit 65
         fi
   else
       git clone --branch ${BRANCH} --depth 1 git://git.postgresql.org/git/postgresql.git $OUTPUT_DIR
   fi
else
    git clone --branch ${BRANCH} --depth 1 git://git.postgresql.org/git/postgresql.git $OUTPUT_DIR
fi


