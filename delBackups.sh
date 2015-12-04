#! /bin/bash

dirs=$( find $1 -name '.backup' -type d )

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

for dir in $dirs
do
    rm -r "$dir"
done