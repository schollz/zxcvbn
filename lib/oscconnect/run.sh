#!/bin/bash
ps -ef | grep 'oscconnect' | grep -v grep | grep -v run | awk '{print $2}' | xargs -r kill -9
cd "$(dirname "$0")"
nohup ./oscconnect >/dev/null 2>&1 &
