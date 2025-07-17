#!/bin/env bash

TESTDIR=$HOME/build/test/links

file_name=("one two tree")
if [ -d "$TESTDIR" ]; then
  mkdir -p "$TESTDIR"
else
  for file in $file_name; do
    mkdir -p "$TESTDIR"/"$file"
  done
fi
