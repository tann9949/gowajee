# build docker
docker build -t chompk/kaldi docker || exit 1;
# run docker
docker run -it --rm \
-v "$PWD/../../../dataset/gowajee/:/mnt/gowajee" \
-v "$PWD/gowajee/:/opt/kaldi/egs/gowajee" \
-e KALDI_ROOT="/opt/kaldi" \
-e GOWAJEE_ROOT="/mnt/gowajee" \
-w "/opt/kaldi/egs/gowajee/s5" \
-e PULSE_SERVER=host.docker.internal \
-v /Users/chompk/.config/pulse:/home/pulseaudio/.config/pulse \
chompk/kaldi:latest bash;
