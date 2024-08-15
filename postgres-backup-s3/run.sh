#!/bin/sh

if [ "${S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi

if [ "${SCHEDULE}" = "**None**" ]; then
    sh backup.sh
else
    # Debian uses /etc/cron.d for cron jobs instead of /etc/crontabs/root
    echo -e "${SCHEDULE} /backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/backup-cron
    chmod 0644 /etc/cron.d/backup-cron  # Ensure the correct permissions
    crontab /etc/cron.d/backup-cron  # Install the cron job
    cron -f  # Start cron in the foreground
fi
