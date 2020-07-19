#!/bin/bash

[[ "$SYSTEM_DEBUG" == "true" ]] && set -x

# shellcheck disable=SC1091
source utils.sh

wait() {
    echo start wait
    sleep 1
    echo end wait
    return 0
}

echo "start"


stat -s wait 1
stat wait
stat wait

echo "end"