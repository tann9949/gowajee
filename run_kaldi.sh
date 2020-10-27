# build docker
docker build -t chompk/kaldi docker;
# run docker
docker run -it \
-v "$PWD/../../dataset/gowajee/:/mnt/gowajee" \
-v "$PWD/../../dataset/lotus/:/mnt/lotus" \
-v "$PWD/gowajee/:/opt/kaldi/egs/gowajee" \
-e KALDI_ROOT="/opt/kaldi" \
-e GOWAJEE_ROOT="/mnt/gowajee" \
-e LOTUS_ROOT="/mnt/lotus" \
-w "/opt/kaldi/egs/gowajee/s5" \
chompk/kaldi:latest bash;
