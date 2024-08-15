#! /bin/sh

# exit if a command fails
set -eo pipefail

apk update

wget https://github.com/webdevops/go-crond/releases/download/23.12.0/go-crond.linux.arm64
tar -xzvf go-crond.linux.arm64
sudo mv go-crond /usr/local/bin/


# Cleanup
rm -rf /var/cache/apk/*
T