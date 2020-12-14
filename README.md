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
We train the model using `mfcc_pitch` feats on `voxforge` recipe. The following table shows the experiment results where LMWT were set to 17 for all models since it yields the best WER so far.

|Model|dev WER|test WER|
|:----|:----:|:-----:|
|mono|40.98%|22.71%|
|tri1|33.95%|19.71%|
|tri2a|33.76%|19.71%|
|tri2b|31.26%|19.87%|
|tri2b_mmi (it3)|32.21%|-|
|tri2b_mmi_b0.05 (it3)|31.89%|-|
|tri2b_mpe|31.67%|19.83%|
|tri3b (si)|31.42%|17.08%|
|tri3b_mmi (si)|31.42%|17.08%|
|tri3b*|21.30%|10.52%|
|tri3b_fmmi_b (iter3)*|19.70%|-|
|tri3b_fmmi_c (iter4)*|20.41%|-|
|tri3b_fmmi_d (iter4)*|20.62%|10.27%|
|tri3b_mmi*|22.09%|11.36%|
|tri3b_mmi (decode2)*|21.55%|11.36%|

*denotes speaker dependent training

## References
>Ekapol Chuangsuwanich, Atiwong Suchato, Korrawe Karunratanakul, Burin Naowarat, Chompakorn CChaichot,and Penpicha Sangsa-nga. Gowajee Corpus. Technical report, Chulalongkorn University, Faculty of Engineering,Computer Engineering Department, 12 2020

## Author
Chompakorn Chaksangchaichot