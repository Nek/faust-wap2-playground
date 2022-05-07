#! /bin/bash

find ../dist -type f -print0 | sort -z | xargs -P $(nproc --all) -0 sha1sum | tqdm --unit file --total $(find . -type f | wc -l) | sort | awk '{ print $1 }' | sha1sum | head -c 40 |  xargs -I {} echo "Content hash: " {}