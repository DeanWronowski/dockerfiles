#!/bin/bash

# Set AWS S3 signature version if specified
if [ "${S3_S3V4}" = "yes" ]; then
    aws configure set default.s3.signature_version s3v4
fi

# Check if SCHEDULE is not set
if [ -z "${SCHEDULE}" ]; then
    bash backup.sh  # Changed to bash if you want consistency with the shebang
else
    # This means SCHEDULE is set

    # Set up the cron job with the provided schedule
    echo "${SCHEDULE} /backup.sh >> /var/log/cron.log 2>&1" > /etc/cron.d/backup-cron
    chmod 0644 /etc/cron.d/backup-cron  # Ensure the correct permissions
    crontab /etc/cron.d/backup-cron  # Install the cron job
    cron -f  # Start cron in the foreground
fi