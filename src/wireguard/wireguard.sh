#!/bin/sh
#
set -ex

# wg-quick up wg0
wg-quick up "$@"

# Keep the script running to keep the container alive
# tail -f /dev/null
# sleep infinity
read
