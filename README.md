# Gowajee Kaldi Recipe

## Installation
**Make sure `docker` is installed on your computer**

### Clone the repository
Clone (download) this repository on your local computer
```bash
$ git clone https://github.com/tann9949/gowajee.git
$ # to update version to latest commit,
$ # run `git pull`
```

### Downloading SRILM
Register and download SRILM on the following [link](http://www.speech.sri.com/projects/srilm/download.html). Then, store it in `docker` directory. For this project, we use SRILM version 1.7.3.

```
docker
├─dockerfile
└─srilm-1.7.3.tar.gz
```

### Downloading corpus
To download the Gowajee Corpus, check the official release repository from this [link](https://github.com/ekapolc/gowajee_corpus/tree/master). Download it and place it to your preferred directory as we will use this dataset to mount to docker container.

### Building and run docker
We provide a dockerfile to build a Kaldi docker containing SRILM and sequitur G2P. We provide a shell script that will both build and run docker at the same time.

Copy downloaded directory which includes `audios`, `train`, `dev`, and `test`. `lu` set is optional as we won't use it here.

Once you finish changing the path, run `run_kaldi.sh` script to run Kaldi.

```bash
$ bash run_kaldi.sh
```

## Usage
We provide `run.sh` script that will execute the pipeline starting from preparing data up to training the model

```bash
$ bash run.sh
```

## Dataset Description
See [here](https://github.com/ekapolc/gowajee_corpus/tree/master) for more details.

## Experiment Results
We train the model using `mfcc_pitch` feats on `voxforge` recipe. The following table shows the experiment results.

|Model|dev WER|test WER|
|:----|:----:|:-----:|
|mono|%|%|
|tri1|%|%|
|tri2a|%|%|
|tri2b|%|%|
|tri2b_dentlas|%|%|
|tri2b_mmi|%|%|
|tri2b_mmi_b0.05|%|%|
|tri2b_mpe|%|%|
|tri3b|%|%|
|tri3b_dentlas|%|%|
|tri3b_fmmi_b|%|%|
|tri3b_fmmi_c|%|%|
|tri3b_fmmi_d|%|%|
|tri3b_mmi|%|%|

## Author
Chompakorn Chaksangchaichot