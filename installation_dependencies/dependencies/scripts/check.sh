#!/bin/bash

# bash check.sh      =>    check all node 
# bash check.sh IDX  =>    check the IDX node

dirpath="$(cd "$(dirname "$0")" && pwd)"
cd $dirpath

index=$1;

if [ -z $index ];then
	echo "check all node status ... "
	for checkfile in `ls $dirpath/node*/check.sh`
    do
        bash $checkfile
    done
else
	echo "check node$index status ... "
	if [ -d node$index ];then
		bash node$index/check.sh $index
	else
		echo "node$index is not exist."
	fi
fi