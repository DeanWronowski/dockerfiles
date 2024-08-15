#! /bin/sh

# exit if a command fails
set -eo pipefail

apk update

wget https://github.com/webdevops/go-crond/releases/download/vx.x.x/go-crond_linux_amd64.tar.gz
tar -xzvf go-crond_linux_amd64.tar.gz
sudo mv go-crond /usr/local/bin/


# Cleanup
rm -rf /var/cache/apk/*
