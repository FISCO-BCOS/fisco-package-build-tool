#!/bin/bash
dirpath="$(cd "$(dirname "$0")" && pwd)"

# log清理, 会删除一天之前的生产的log文件。
for dir in `ls $dirpath | egrep "node[0-9]+"`
do
        if [ ! -d $dirpath/$dir/log ];then
                continue
        fi
        find  $dirpath/$dir/log -mtime +24 -type f -name "*log*log*" | xargs rm -rf
done
