#!/bin/sh

set -eo pipefail

if [ "${S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi

if [ "${SCHEDULE}" = "**None**" ]; then
    sh backup.sh
else
    echo -e "${SCHEDULE} /backup.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/root
    go-crond -d
fi
