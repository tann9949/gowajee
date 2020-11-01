#!/bin/bash

. path.sh || exit 1
. utils/parse_options.sh || exit 1

if [ $# -ne 0 ]; then
    echo "Usage: $0"
    exit 1
fi

if [ ! -f data/dic5k.formatted.txt ]; then
    echo "dic5k.formatted.txt not exists. Downloading..."
    wget "https://raw.githubusercontent.com/ekapolc/ASR_classproject/master/g2p/dic5k.formatted.txt" -O data/dic5k.formatted.txt
fi

mkdir -p g2p
g2p.py --train data/dic5k.formatted.txt --devel 5% --encoding UTF-8 --write-model g2p/model-1
g2p.py --model g2p/model-1 --ramp-up --train data/dic5k.formatted.txt --devel 5% --encoding UTF-8 --write-model g2p/model-2
g2p.py --model g2p/model-2 --ramp-up --train data/dic5k.formatted.txt --devel 5% --encoding UTF-8 --write-model g2p/model-3
g2p.py --model g2p/model-3 --ramp-up --train data/dic5k.formatted.txt --devel 5% --encoding UTF-8 --write-model g2p/model-4
g2p.py --model g2p/model-4 --ramp-up --train data/dic5k.formatted.txt --devel 5% --encoding UTF-8 --write-model g2p/model-5