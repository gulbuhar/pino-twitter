# Copyright (C) 2009-2010 troorl <troorl@gmail.com>
# Distributed under the same license terms of the program itself (see COPYING).

#!/bin/sh

#creating template
xgettext  src/*.vala --from-code=utf-8 -k_

#updating translations
for p in $(ls po/ | grep ".po"); do
	msgmerge po/$p messages.po -o po/$p
done

rm po/pino.pot
mv messages.po po/pino.pot
