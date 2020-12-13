# build docker
docker build -t chompk/kaldi docker || exit 1;
# run docker
docker run -it --rm \
-v "$PWD/gowajee/:/opt/kaldi/egs/gowajee" \
-e KALDI_ROOT="/opt/kaldi" \
-w "/opt/kaldi/egs/gowajee/s5" \
chompk/kaldi:latest bash;
