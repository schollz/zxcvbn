#!/bin/bash

wget https://github.com/schollz/zxcvbn/releases/download/assets/release.tar.gz
tar -xvzf release.tar.gz
rm -f release.tar.gz
chmod +x aubiogo/aubiogo
chmod +x oscconnect/oscconnect
chmod +x oscnotify/oscnotify
cd aubio && sudo ./waf install --destdir=/
sudo ldconfig
cd .. && rm -rf aubio

