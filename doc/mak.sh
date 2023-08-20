#! /bin/bash

# Public Domain

echo -ne "\\U Source Control Revision ID\n\nhg $(hg id -i), from commit on at $(hg log -r . --template="{date|isodatesec}\n")\n\nIf this is in ecm's repository, you can find it at \\W{https://hg.pushbx.org/ecm/edrdos/rev/$(hg log -r . --template "{node|short}")}{https://hg.pushbx.org/ecm/edrdos/rev/$(hg log -r . --template "{node|short}")}\n" > screvid.but
halibut --precise build.but screvid.but --html --text --pdf 2>&1
#  | grep -Ev 'warning\: code paragraph line is [0-9]+ chars wide, wider than body width [0-9]+'
unix2dos build.txt
