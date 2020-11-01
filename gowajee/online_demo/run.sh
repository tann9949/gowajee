#!/usr/bin/env bash

# Copyright 2012 Vassil Panayotov
# Apache 2.0

# Note: you have to do 'make ext' in ../../../src/ before running this.

# Set the paths to the binaries and scripts needed
KALDI_ROOT=`pwd`/../../..
export PATH=$PWD/../s5/utils/:$KALDI_ROOT/src/onlinebin:$KALDI_ROOT/src/bin:$PATH


ac_model_type=tri3b

# Alignments and decoding results are saved in this directory(simulated decoding only)
decode_dir="./work"

. parse_options.sh

ac_model=models/$ac_model_type
trans_matrix=""

if [ -s $ac_model/matrix ]; then
    trans_matrix=$ac_model/matrix
fi

online-gmm-decode-faster --rt-min=0.5 --rt-max=0.7 --max-active=4000 \
    --beam=12.0 --acoustic-scale=0.0769 $ac_model/model $ac_model/HCLG.fst \
    $ac_model/words.txt '1:2:3:4:5' $trans_matrix;