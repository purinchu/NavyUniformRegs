#!/usr/bin/env bash

# So, in theory you should be able to run this script, from whatever directory,
# and it runs the other scripts that you need in order to get the right HTML
# and image files installed to where they need to go so that you can just
# run "build" in Android Studio.

# die if a command fails unexpectedly
set -o errexit
# die on undecl vars
set -o nounset
set -o pipefail

HTML_PATH="www.public.navy.mil/bupers-npc/support/uniforms"
BASEDIR=$(dirname $0)
cd "$BASEDIR"
cd .. # Should be package root
ROOT="$PWD"

# Try to avoid being obnoxious if script is run multiple times
if [ ! -e "$HTML_PATH" ]; then
    # Download the HTML and images
    ./scripts/spider-script.sh

    cd "$HTML_PATH"

    # setup images (and HTML, but those will go away shortly)
    cp -a uniformregulations compiled-regs

    # make downloaded files read-only for safety
    find uniformregulations -type f -exec chmod -w '{}' \;
else
    echo "Using already-downloaded HTML"
    cd "$HTML_PATH"
fi

cd uniformregulations

# Run the Perl script that will clean up the HTML
"$ROOT/scripts/build-script.sh"

# Copy the compiled files into the assets dir

cd .. # Now in .../support/uniforms

# Install the files in place
cp -a compiled-regs "$ROOT/app/src/main/assets"

# Should be ready
echo "Files installed into the Java source directory, the Android app should"
echo "be ready to build now in Android Studio."
