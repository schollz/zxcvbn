#!/bin/bash
ps -ef | grep 'osccpu' | grep -v grep | grep -v run | awk '{print $2}' | xargs -r kill -9
cd "$(dirname "$0")"
nohup ./osccpu -n scsynth -d 3 >/dev/null 2>&1 &
# nohup ./osccpu -n crone -d 3 >/dev/null 2>&1 &
# sleep 1
# nohup ./osccpu -n scsynth -d 3 >/dev/null 2>&1 &
# sleep 1
# nohup ./osccpu -n scsynth -d 3 >/dev/null 2>&1 &
