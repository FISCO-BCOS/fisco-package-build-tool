#!/bin/bash
dirpath="$(cd "$(dirname "$0")" && pwd)"

# log清理, 会删除三个小时以前生成的log文件。
for dir in `ls $dirpath | egrep "node[0-9]+"`
do
        if [ ! -d $dirpath/$dir/log ];then
                continue
        fi
        find  $dirpath/$dir/log -mmin +180 -type f -name "*log*log*" | xargs rm -rf
done
