#!/usr/bin/bash

. path.sh || exit 1
. utils/parse_options.sh || exit 1

if [ ! -f data/train/text ]; then
    echo "data/train/text not found. Exitting..."
    exit 1
fi

