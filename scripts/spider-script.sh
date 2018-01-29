#!/bin/sh

# TODO: It would probably be better to have wget use --cut-dirs=3 to make this
# script collection less annoying to use, but I haven't tried it yet so haven't
# turned it on.

# TODO: Also, might be prudent to have a second pass to make the spidered
# files read-only that way you only have to download once if the read-file.pl
# script goes rogue somehow.  I'm sure the NPC sysadmins would appreciate your
# care at least.
BASE_PATH="bupers-npc/support/uniforms/uniformregulations"
BASE_URL="http://www.public.navy.mil/$BASE_PATH"
WGET_FLAGS="--no-verbose --mirror --convert-links --adjust-extension --page-requisites -I $BASE_PATH"

URL="$BASE_URL/Pages/default.aspx"

wget $WGET_FLAGS $URL

if [ $? = 6 ]; then
    # NPC website has CAC-protected areas that wget will trip against and fail to download from,
    # and wget duly gives an error which we will promptly ignore
    exit 0
fi
