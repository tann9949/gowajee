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

However, your path to Gowajee Dataset (which you downloaded from last section) should be different from mine configuration, so **MAKE SURE YOU CHANGE A PATH OF THE DATASET IN `run_kaldi.sh`**.

```bash
# build docker
docker build -t chompk/kaldi docker;
# run docker
docker run -it \
-v "$PWD/../../dataset/gowajee/:/mnt/gowajee" \
-v "<path-to-gowajee>:/opt/kaldi/egs/gowajee" \   # <- Make sure you change path to Gowajee Dataset
-e KALDI_ROOT="/opt/kaldi" \
-e GOWAJEE_ROOT="/mnt/gowajee" \
-w "/opt/kaldi/egs/gowajee/s5" \
chompk/kaldi:latest bash;

```

Once you finish changing the path, run `run_kaldi.sh` script to run Kaldi.

```bash
$ bash run_kaldi.sh
```

## Usage
Once you enter Kaldi, 

## Dataset Description
*TODO:*

## Experiment Results
*TODO:*

## Author
Chompakorn Chaksangchaichot