#!/bin/bash

# Modified from Voxforge
# by Chompakorn Chaksangchaichot

. path.sh || exit 1
. utils/parse_options.sh || exit 1

if [ ! -f data/train/text ]; then
    echo "data/train/text not found. Exitting..."
    exit 1
fi

locdata=data/local
locdict=$locdata/dict
mkdir -p $locdict
g2p_model=g2p/model-5

echo "--- Loading a Sequitur G2P model ..."

if [ ! -f g2p/model-5 ]; then
    echo "g2p model does not exists, creating one..."
    # FIXME:
    bash local/prep_g2p.sh
fi

echo "--- Prepare lexicon for vocabulary ..."
cat $locdata/vocab-full.txt |\
    sed -e 's:^\([^\s(]\+\)([0-9]\+)\(\s\+\)\(.*\):\1\2\3:' |\
    egrep -v '<.?s>' > $locdict/vocab-plain.txt
g2p.py --encoding UTF-8 --model=g2p/model-5 --apply $locdict/vocab-plain.txt |\
    sort -u > $locdict/lexicon.txt

echo "--- Prepare phone lists ..."
echo SIL > $locdict/silence_phones.txt
echo SIL > $locdict/optional_silence.txt
grep -v -w sil data/local/dict/lexicon.txt |\
    awk '{for(n=2;n<=NF;n++) { p[$n]=1; }} END{for(x in p) {print x}}' |\
    sort > $locdict/nonsilence_phones.txt

echo "--- Adding SIL to the lexicon ..."
echo -e "!SIL\tSIL" >> $locdict/lexicon.txt

echo "*** Dictionary preparation finished!"