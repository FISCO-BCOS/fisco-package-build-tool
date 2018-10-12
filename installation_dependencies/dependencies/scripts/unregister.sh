index=$1

dirpath="$(cd "$(dirname "$0")" && pwd)"
cd $dirpath

if [ -d node$index ] && [ -f node$index/data/node.json ];then
    bash node_manager.sh cancelNode `pwd`/node$index/data/node.json
else
    echo "node$index/node.json is node exist."
fi
# update version 1.0.2