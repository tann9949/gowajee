#!/bin/bash

. path.sh || exit 1

--no-phones=
. utils/parse_options.sh || exit 1

dict=g2p/dic5k.formatted.notones.txt

mkdir -p g2p
g2p.py --train $dict --devel 5% --encoding UTF-8 --write-model g2p/model-1
g2p.py --model g2p/model-1 --ramp-up --train $dict --devel 5% --encoding UTF-8 --write-model g2p/model-2
g2p.py --model g2p/model-2 --ramp-up --train $dict --devel 5% --encoding UTF-8 --write-model g2p/model-3
g2p.py --model g2p/model-3 --ramp-up --train $dict --devel 5% --encoding UTF-8 --write-model g2p/model-4
g2p.py --model g2p/model-4 --ramp-up --train $dict --devel 5% --encoding UTF-8 --write-model g2p/model-5