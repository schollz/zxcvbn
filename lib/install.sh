#!/bin/bash

wget -q https://github.com/schollz/zxcvbn/releases/download/assets/release.tar.gz
tar -xzf release.tar.gz
rm -f release.tar.gz
chmod +x aubiogo/aubiogo
chmod +x oscconnect/oscconnect
chmod +x oscnotify/oscnotify
cd aubio && sudo ./waf install --destdir=/
sudo ldconfig
cd .. && rm -rf aubio
# apply patch automatically
cp /home/we/dust/code/zxcvbn/lib/keyboard.patch /home/we/dust/norns/
cd /home/we/dust/norns && git apply keyboard.patch
