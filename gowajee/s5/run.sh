#!/usr/bin/env bash

# voxforge kaldi's recipe
# Copyright 2012 Vassil Panayotov
# Apache 2.0
# Modify by Chompakorn Chaksangchaichot for Gowajee dataset

. ./path.sh || exit 1

# If you have cluster of machines running GridEngine you may want to
# change the train and decode commands in the file below
. ./cmd.sh || exit 1

# The number of parallel jobs to be started for some parts of the recipe
# Make sure you have enough resources(CPUs and RAM) to accomodate this number of jobs
njobs=2

# The number of randomly selected speakers to be put in the test set
nspk_test=20

# Test-time language model order
lm_order=2

# Word position dependent phones?
pos_dep_phones=true

# The directory below will be used to link to a subset of the user directories
# based on various criteria(currently just speaker's accent)
selected=${DATA_ROOT}/selected

# The user of this script could change some of the above parameters. Example:
# /bin/bash run.sh --pos-dep-phones false
. utils/parse_options.sh || exit 1

[[ $# -ge 1 ]] && { echo "Unexpected arguments"; exit 1; }

# TODO:
# Prepare ARPA LM and vocabulary using SRILM
# local/gowajee_prepare_lm.sh --order ${lm_order} || exit 1

# Prepare the lexicon and various phone lists
# Pronunciations for OOV words are obtained using a pre-trained Sequitur model
# local/gowajee_prepare_dict.sh || exit 1;

# Prepare data/lang and data/local/lang directories
# utils/prepare_lang.sh --position-dependent-phones $pos_dep_phones \
#    data/local/dict '!SIL' data/local/lang data/lang || exit 1

# Prepare G.fst and data/{train,test} directories
# local/gowajee_format_data.sh || exit 1

# Now make MFCC features.
mfccdir=${DATA_ROOT}/mfcc
for x in train dev; do
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $njobs \
        data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
done

# Train monophone models
steps/train_mono.sh --nj $njobs --cmd "$train_cmd" data/train data/lang exp/mono || exit 1;

# Monophone decoding
# we use the same language model for both train / dev, the same as official benchmark
utils/mkgraph.sh data/lang exp/mono exp/mono/graph || exit 1;
# note: local/decode.sh calls the command line once for each
# test, and afterwards averages the WERs into (in this case
# exp/mono/decode/
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    exp/mono/graph data/dev exp/mono/decode

# Get alignments from monophone system.
steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
    data/train data/lang exp/mono exp/mono_ali || exit 1;

# train tri1 [first triphone pass]
steps/train_deltas.sh --cmd "$train_cmd" \
    data/train data/lang exp/mono exp/mono_ali || exit 1;

# decode tri1
utils/mkgraph.sh data/lang-test exp/tri1/graph || exit 1;
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    exp/tri1/graph data/dev exp/tri1/decode

#draw-tree data/lang/phones.txt exp/tri1/tree | dot -Tps -Gsize=8,10.5 | ps2pdf - tree.pdf

# align tri1
steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
    --use-graphs true data/train data/lang exp/tri1 exp/tri1_ali || exit 1;

# train tri2a [delta+delta-deltas]
steps/train_deltas.sh --cmd "$train_cmd" 2000 11000 \
    data/train data/lang exp/tri1_ali exp/tri2a || exit 1;

# decode tri2a
# again, we use same lang for both train/dev
utils/mkgraph.sh data/lang exp/tri2a exp/tri2a/graph
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    exp/tri2a/graph data/test exp/tri2a/decode

# train and decode tri2b [LDA+MLLT]
steps/train_lda_mllt.sh --cmd "$train_cmd" 2000 11000 \
    data/train data/lang exp/tri1_ali exp/tri2b || exit 1;
utils/mkgraph.sh data/lang exp/tri2b exp/tri2b/graph
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    exp/tri2b/graph data/test exp/tri2b/decode

# Align all data with LDA+MLLT system (tri2b)
steps/align_si.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \
    data/train data/lang exp/tri2b exp/tri2b_ali || exit 1;