#!/bin/bash

#copy so file to the dst dir
function copy_so_file()
{
    local src=$1
    local dst=$2
    echo "copy so file =>"
    echo "so src dir => "$src
    echo "so dst dir => "$dst
    sudo cp $src/* $dst/
    if [ -f $dst/libleveldb.so ] && [ -f $dst/libleveldb.so.1 ];then
        sudo ln -s  $dst/libleveldb.so.1  $dst/libleveldb.so
    fi 

    if [ -f $dst/libmicrohttpd.so ] && [ -f $dst/libmicrohttpd.so.10 ];then
        sudo ln -s  $dst/libmicrohttpd.so.10  $dst/libmicrohttpd.so
    fi

    sudo ldconfig
}