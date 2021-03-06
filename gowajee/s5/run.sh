#!/bin/bash

# voxforge kaldi's recipe
# Copyright 2012 Vassil Panayotov
# Apache 2.0
# Modify by Chompakorn Chaksangchaichot for Gowajee dataset

. ./path.sh || exit 1;

# If you have cluster of machines running GridEngine you may want to
# change the train and decode commands in the file below
. ./cmd.sh || exit 1;

# The number of parallel jobs to be started for some parts of the recipe
# Make sure you have enough resources(CPUs and RAM) to accomodate this number of jobs
njobs=$(nproc)

# language model order
lm_order=2

# Word position dependent phones?
pos_dep_phones=true

# The user of this script could change some of the above parameters. Example:
# /bin/bash run.sh --pos-dep-phones false
. utils/parse_options.sh || exit 1

[[ $# -ge 1 ]] && { echo "Unexpected arguments"; exit 1; }

# Prepare ARPA LM and vocabulary using SRILM
local/gowajee_prepare_lm.sh --order ${lm_order} || exit 1;

# Prepare the lexicon and various phone lists
# Pronunciations for OOV words are obtained using a pre-trained Sequitur model
local/gowajee_prepare_dict.sh || exit 1;

# Prepare data/lang and data/local/lang directories
utils/prepare_lang.sh --position-dependent-phones $pos_dep_phones \
   data/local/dict '!SIL' data/local/lang data/lang || exit 1;

# Prepare G.fst and data/{train,dev} directories
local/gowajee_format_data.sh || exit 1

# Now make MFCC features.
mfccdir=mfcc
for x in train dev test; do
    steps/make_mfcc_pitch.sh --cmd "$train_cmd" --nj $njobs \
        data/$x exp/make_mfcc/$x $mfccdir || exit 1;
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir || exit 1;
done

# Train monophone models
echo "\n--- Training mono ..."
steps/train_mono.sh --nj $njobs --cmd "$train_cmd" data/train data/lang exp/mono || exit 1;

# Monophone decoding
# we use the same language model for both train / dev, the same as official benchmark
echo -ne "\n--- Making mono graph ..."
utils/mkgraph.sh data/lang exp/mono exp/mono/graph || exit 1;
# note: local/decode.sh calls the command line once for each
# test, and afterwards averages the WERs into (in this case
# exp/mono/decode/
echo -ne "\n--- Decoding mono ..."
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    exp/mono/graph data/dev exp/mono/decode

steps/decode.sh --config conf/decode.config --nj $njobs --cmd "decode_cmd" \
    exp/mono/graph data/test exp/mono/decode_test

echo -ne "\n--- Aligning mono ..."
# Get alignments from monophone system.
steps/align_si.sh --nj $njobs --cmd "$train_cmd" \
    data/train data/lang exp/mono exp/mono_ali || exit 1;

# train tri1 [first triphone pass]
echo -ne "\n--- Making tri1 ..."
steps/train_deltas.sh --cmd "$train_cmd" \
    2000 11000 data/train data/lang exp/mono_ali exp/tri1 || exit 1;

# decode tri1
echo -ne "\n--- Decoding tri1 ..."
utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || exit 1;
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    exp/tri1/graph data/dev exp/tri1/decode

steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    exp/tri1/graph data/test exp/tri1/decode_test

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
    exp/tri2a/graph data/dev exp/tri2a/decode

# train and decode tri2b [LDA+MLLT]
steps/train_lda_mllt.sh --cmd "$train_cmd" 2000 11000 \
    data/train data/lang exp/tri1_ali exp/tri2b || exit 1;
utils/mkgraph.sh data/lang exp/tri2b exp/tri2b/graph
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    exp/tri2b/graph data/dev exp/tri2b/decode
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    exp/tri2b/graph data/test exp/tri2b/decode_test

# Align all data with LDA+MLLT system (tri2b)
steps/align_si.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \
    data/train data/lang exp/tri2b exp/tri2b_ali || exit 1;

# Do MMI on top of LDA+MLLT.
steps/make_denlats.sh --nj $njobs --cmd "$train_cmd" \
    data/train data/lang exp/tri2b exp/tri2b_denlats || exit 1;
steps/train_mmi.sh data/train data/lang exp/tri2b_ali exp/tri2b_denlats exp/tri2b_mmi || exit 1;
steps/decode.sh --config conf/decode.config --iter 4 --nj $njobs --cmd "$decode_cmd" \
    exp/tri2b/graph data/dev exp/tri2b_mmi/decode_it4
steps/decode.sh --config conf/decode.config --iter 3 --nj $njobs --cmd "$decode_cmd" \
    exp/tri2b/graph data/dev exp/tri2b_mmi/decode_it3

# Do the same with boosting.
steps/train_mmi.sh --boost 0.05 data/train data/lang \
    exp/tri2b_ali exp/tri2b_denlats exp/tri2b_mmi_b0.05 || exit 1;
steps/decode.sh --config conf/decode.config --iter 4 --nj $njobs --cmd "$decode_cmd" \
    exp/tri2b/graph data/dev exp/tri2b_mmi_b0.05/decode_it4 || exit 1;
steps/decode.sh --config conf/decode.config --iter 3 --nj $njobs --cmd "$decode_cmd" \
    exp/tri2b/graph data/dev exp/tri2b_mmi_b0.05/decode_it3 || exit 1;

# Do MPE.
steps/train_mpe.sh data/train data/lang exp/tri2b_ali exp/tri2b_denlats exp/tri2b_mpe || exit 1;
steps/decode.sh --config conf/decode.config --iter 4 --nj $njobs --cmd "$decode_cmd" \
    exp/tri2b/graph data/dev exp/tri2b_mpe/decode_it4 || exit 1;
steps/decode.sh --config conf/decode.config --iter 3 --nj $njobs --cmd "$decode_cmd" \
    exp/tri2b/graph data/dev exp/tri2b_mpe/decode_it3 || exit 1;

## Do LDA+MLLT+SAT, and decode.
steps/train_sat.sh 2000 11000 data/train data/lang exp/tri2b_ali exp/tri3b || exit 1;
utils/mkgraph.sh data/lang exp/tri3b exp/tri3b/graph || exit 1;
steps/decode_fmllr.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    exp/tri3b/graph data/dev exp/tri3b/decode || exit 1;

# Align all data with LDA+MLLT+SAT system (tri3b)
steps/align_fmllr.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \
    data/train data/lang exp/tri3b exp/tri3b_ali || exit 1;

## MMI on top of tri3b (i.e. LDA+MLLT+SAT+MMI)
steps/make_denlats.sh --config conf/decode.config \
    --nj $njobs --cmd "$train_cmd" --transform-dir exp/tri3b_ali \
    data/train data/lang exp/tri3b exp/tri3b_denlats || exit 1;
steps/train_mmi.sh data/train data/lang exp/tri3b_ali exp/tri3b_denlats exp/tri3b_mmi || exit 1;

steps/decode_fmllr.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    --alignment-model exp/tri3b/final.alimdl --adapt-model exp/tri3b/final.mdl \
    exp/tri3b/graph data/dev exp/tri3b_mmi/decode || exit 1;

# Do a decoding that uses the exp/tri3b/decode directory to get transforms from.
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \
    --transform-dir exp/tri3b/decode  exp/tri3b/graph data/dev exp/tri3b_mmi/decode2 || exit 1;

#first, train UBM for fMMI experiments.
steps/train_diag_ubm.sh --silence-weight 0.5 --nj $njobs --cmd "$train_cmd" \
    250 data/train data/lang exp/tri3b_ali exp/dubm3b

# Next, various fMMI+MMI configurations.
steps/train_mmi_fmmi.sh --learning-rate 0.0025 \
    --boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri3b_ali exp/dubm3b exp/tri3b_denlats \
    exp/tri3b_fmmi_b || exit 1;

for iter in 3 4 5 6 7 8; do
    steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" --iter $iter \
        --transform-dir exp/tri3b/decode  exp/tri3b/graph data/dev exp/tri3b_fmmi_b/decode_it$iter &
done

steps/train_mmi_fmmi.sh --learning-rate 0.001 \
    --boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri3b_ali exp/dubm3b exp/tri3b_denlats \
    exp/tri3b_fmmi_c || exit 1;

for iter in 3 4 5 6 7 8; do
    steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" --iter $iter \
        --transform-dir exp/tri3b/decode  exp/tri3b/graph data/dev exp/tri3b_fmmi_c/decode_it$iter &
done

# for indirect one, use twice the learning rate.
steps/train_mmi_fmmi_indirect.sh --learning-rate 0.002 --schedule "fmmi fmmi fmmi fmmi mmi mmi mmi mmi" \
    --boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri3b_ali exp/dubm3b exp/tri3b_denlats \
    exp/tri3b_fmmi_d || exit 1;

for iter in 3 4 5 6 7 8; do
    steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" --iter $iter \
        --transform-dir exp/tri3b/decode  exp/tri3b/graph data/dev exp/tri3b_fmmi_d/decode_it$iter &
done

local/run_sgmm2.sh --nj $njobs
