#!/bin/bash

sudo apt update
sudo apt-get install -y --no-install-recommends libavcodec-dev libavformat-dev
wget -q https://github.com/schollz/zxcvbn/releases/download/assets/release.tar.gz
tar -xzf release.tar.gz
rm -f release.tar.gz
chmod +x aubiogo/aubiogo
chmod +x oscconnect/oscconnect
chmod +x oscnotify/oscnotify
## install aubio
cd aubio && sudo ./waf install --destdir=/
sudo ldconfig
cd .. && rm -rf aubio
## install demo into data folder
mkdir -p ~/dust/data/zxcvbn
rsync -avrP zxcvbn/ ~/dust/data/zxcvbn/
# install samples
cd ~/dust/data/zxcvbn
wget https://github.com/schollz/zxcvbn/releases/download/assets/samples.tar.gz
tar -xvzf samples.tar.gz
rm samples.tar.gz

