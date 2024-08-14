#! /bin/sh

# exit if a command fails
set -eo pipefail

apk update

# Cleanup
rm -rf /var/cache/apk/*
