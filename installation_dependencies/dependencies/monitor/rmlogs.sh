#!/bin/bash
dirpath="$(cd "$(dirname "$0")" && pwd)"

day=30
if [ ! -z "$1" ] && [ $1 -gt 0 ];then
   day=$1
fi

# log remove , remove log file created day before。
for dir in `ls $dirpath | egrep "node*"`
do
        if [ ! -d $dirpath/$dir/log ];then
                continue
        fi
        find  $dirpath/$dir/log -mtime +$day -type f -name "*log*log*" | xargs rm -rf
done
