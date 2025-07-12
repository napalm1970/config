#!/bin/env bash

# if [ -d "$HOME"/build/test ]; then
#   echo -n "Yes"
# else
#   echo -n "NO"
# fi
TESTDIR=$HOME/build/test/

file_name=("one two tree")

for file in $file_name; do
  mkdir -p "$TESTDIR"/"$file"
done
