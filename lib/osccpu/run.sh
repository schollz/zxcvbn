#!/bin/bash
ps -ef | grep 'osccpu' | grep -v grep | grep -v run | awk '{print $2}' | xargs -r kill -9
cd "$(dirname "$0")"
nohup ./osccpu -n scsynth -d 2 >/dev/null 2>&1 &
