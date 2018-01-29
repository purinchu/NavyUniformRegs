#!/bin/sh

# This is basically exactly the same as build-script.sh but includes a wee tiny
# " | head -3 " so that the script is run on no more than 3 files, so that you
# can rapidly test changes to read-file.pl
#
# I also didn't use the -print0 / xargs -0 magic to handle every file name
# perfectly since I didn't feel like making that work with head(1), so be
# careful of filenames with extremly unusual characters (there aren't any from
# NPC website).
BASE_DIR=$(dirname $0)
echo "Base dir is $BASE_DIR"

find . -name '*.html'  |  head -3 | xargs -P 16 -n 1 -l  "$BASE_DIR/read-file.pl"
