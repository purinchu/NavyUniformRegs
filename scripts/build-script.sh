#!/bin/sh

# Intended to be run from within the directory containing the spidered HTML
# files to be converted to a smaller format for the mobile app.
# The read-file.pl script will by default write the result in a sibling
# compiled-regs directory so that xargs can just pass the one argument and be
# done with it.

# i.e. once you've spidered the Navy Uniform website by using spider-script.sh,
# cd to the www.public.navy.mil/bupers-npc/support/uniforms/uniformregulations/
# folder, and run *this* script from *that* folder.
#
# The output will go to
# www.public.navy.mil/bupers-npc/support/uniforms/compiled-regs
# and that whole compiled-regs folder should be copied under the app's assets
# folder.
# i.e. (from www.public.navy.mil/bupers-npc/support/uniforms)
# cp -af compiled-regs /path/to/src/app/src/main/assets

BASE_DIR=$(dirname $0)
echo "Base dir is $BASE_DIR"

find . -name '*.html' -print0 | xargs -0 -P 16 -n 1 -l "$BASE_DIR/read-file.pl"
