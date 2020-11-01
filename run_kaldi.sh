# build docker
docker build -t chompk/kaldi docker || exit 1;
# run docker
docker run -it --rm \
-v "$PWD/../../../dataset/gowajee/:/mnt/gowajee" \
-v "$PWD/gowajee/:/opt/kaldi/egs/gowajee" \
-e KALDI_ROOT="/opt/kaldi" \
-e GOWAJEE_ROOT="/mnt/gowajee" \
-w "/opt/kaldi/egs/gowajee/s5" \
--device /dev/snd:/dev/snd \
--privileged \
chompk/kaldi:latest bash;
