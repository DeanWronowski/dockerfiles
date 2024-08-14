FROM alpine:latest

LABEL maintainer="Johannes Schickling <schickling.j@gmail.com>"

# Install necessary packages including dcron and AWS CLI
RUN apk add --no-cache bash curl ca-certificates \
    && apk add --no-cache postgresql-client \
    && apk add --no-cache aws-cli \
    && apk add --no-cache busybox-suid \
    && apk add --no-cache dcron

# Add the install script
ADD install.sh install.sh
RUN sh install.sh && rm install.sh

# Set environment variables
ENV POSTGRES_DATABASE **None**
ENV POSTGRES_BACKUP_ALL **None**
ENV POSTGRES_HOST **None**
ENV POSTGRES_PORT 5432
ENV POSTGRES_USER **None**
ENV POSTGRES_PASSWORD **None**
ENV POSTGRES_EXTRA_OPTS ''
ENV S3_ACCESS_KEY_ID **None**
ENV S3_SECRET_ACCESS_KEY **None**
ENV S3_BUCKET **None**
ENV S3_FILE_NAME **None**
ENV S3_REGION us-west-1
ENV S3_ENDPOINT **None**
ENV S3_S3V4 no
ENV SCHEDULE **None**
ENV ENCRYPTION_PASSWORD **None**

# Add scripts
ADD run.sh run.sh
ADD backup.sh backup.sh

# Run the run.sh script
CMD ["sh", "run.sh"]
