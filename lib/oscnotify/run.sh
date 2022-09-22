#!/bin/bash
pkill -f oscnotify
nohup ./oscnotify  >/dev/null 2>&1 &
