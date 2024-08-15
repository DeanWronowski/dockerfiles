# Use Debian Bullseye as the base image
FROM debian:bullseye

# Update the package list and install required packages
RUN apt-get update && apt-get install -y \
    cron \
    bash \
    curl \
    ca-certificates \
    postgresql-client \
    awscli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables with default values
ENV POSTGRES_DATABASE=""
ENV POSTGRES_BACKUP_ALL="false"
ENV POSTGRES_HOST=""
ENV POSTGRES_PORT=5432
ENV POSTGRES_USER=""
ENV POSTGRES_PASSWORD=""
ENV POSTGRES_EXTRA_OPTS=""
ENV S3_BUCKET=""
ENV S3_FILE_NAME=""
ENV S3_ENDPOINT="https://eu-west-2.amazonaws.com"
ENV S3_REGION="eu-west-2"
ENV S3_S3V4="no"
ENV SCHEDULE=""
ENV ENCRYPTION_PASSWORD=""
ENV AWS_ACCESS_KEY_ID=""
ENV AWS_SECRET_ACCESS_KEY=""

# Copy scripts into the image
COPY run.sh /run.sh
COPY backup.sh /backup.sh

# Ensure scripts have executable permissions
RUN chmod +x /run.sh /backup.sh

# Set the default command to run the run.sh script
CMD ["bash", "/run.sh"]

# Optional: Add a health check to ensure the container is running properly
# HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD pgrep cron || exit 1
