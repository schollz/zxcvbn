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
# install first data folder
cd ~/dust/data/
wget https://github.com/schollz/zxcvbn/releases/download/assets/zxcvbn.tar.gz
tar -xvzf zxcvbn.tar.gz
rm zxcvbn.tar.gz

