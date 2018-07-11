#!/bin/bash

openssl x509  -text -in node.crt | sed -n '16,20p' |  sed 's/://g' | tr "\n" " " | sed 's/ //g' | sed 's/[a-z]/\u&/g' | cut -c 3-130 | cat >node.nodeid