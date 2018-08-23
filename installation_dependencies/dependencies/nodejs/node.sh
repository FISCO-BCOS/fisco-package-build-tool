# Expand the $PATH to include /nodejs/bin
# use
export NODE_HOME=$PWD/build/nodejs
export PATH=$PATH:$NODE_HOME/bin
export NODE_PATH=$NODE_HOME/lib/node_modules:$NODE_HOME/lib/nodejs
