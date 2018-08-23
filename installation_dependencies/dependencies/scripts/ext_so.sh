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
}