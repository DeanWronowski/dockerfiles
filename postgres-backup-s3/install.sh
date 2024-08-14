#! /bin/sh

# exit if a command fails
set -eo pipefail

apk update

# Install necessary packages
apk add --no-cache openssl aws-cli postgresql-client --repository=https://dl-cdn.alpinelinux.org/alpine/v3.18/main

# Install dcron or busybox-cron for cron functionality
apk add --no-cache dcron  # Alternatively, use busybox-cron

# Cleanup
rm -rf /var/cache/apk/*
