#!/bin/bash

sudo apt update
sudo apt-get install -y --no-install-recommends libavcodec-dev libavformat-dev
wget -q https://github.com/schollz/zxcvbn/releases/download/assets/release.tar.gz
tar -xzf release.tar.gz
rm -f release.tar.gz
chmod +x aubiogo/aubiogo
chmod +x oscconnect/oscconnect
chmod +x oscnotify/oscnotify
chmod +x acrostic/acrostic

## install audiowaveform
wget https://github.com/schollz/zxcvbn/releases/download/assets/audiowaveform.tar.gz
tar -xvzf audiowaveform.tar.gz 
rm audiowaveform.tar.gz

## install aubio
wget https://github.com/schollz/zxcvbn/releases/download/assets/aubio.tar.gz
tar -xvzf aubio.tar.gz
sudo cp aubio/libaubio.a /usr/local/lib/
sudo cp aubio/libaubio.so /usr/local/lib/
sudo ln -s /usr/local/lib/libaubio.so /usr/local/lib/libaubio.so.5
sudo ln -s /usr/local/lib/libaubio.so /usr/local/lib/libaubio.so.5.4.8
sudo cp aubio/aubioonset /usr/local/bin/
sudo ldconfig
rm -rf aubio
rm -rf aubio.tar.gz

# install first data folder
cd ~/dust/data/
wget https://github.com/schollz/zxcvbn/releases/download/assets/zxcvbn.tar.gz
tar -xvzf zxcvbn.tar.gz
rm zxcvbn.tar.gz

