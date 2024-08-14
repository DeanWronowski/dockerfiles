#! /bin/sh

set -eo pipefail

# Check required environment variables
if [ "${S3_ACCESS_KEY_ID}" = "**None**" ]; then
  echo "You need to set the S3_ACCESS_KEY_ID environment variable."
  exit 1
fi

if [ "${S3_SECRET_ACCESS_KEY}" = "**None**" ]; then
  echo "You need to set the S3_SECRET_ACCESS_KEY environment variable."
  exit 1
fi

if [ "${S3_BUCKET}" = "**None**" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${POSTGRES_DATABASE}" = "**None**" -a "${POSTGRES_BACKUP_ALL}" != "true" ]; then
  echo "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable."
  exit 1
fi

# Configure AWS CLI options
if [ "${S3_ENDPOINT}" == "**None**" ]; then
  AWS_ARGS=""
else
  AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi

# Set AWS environment variables
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

# Set Postgres environment variables
export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

# Handle S3 prefix
if [ -z ${S3_PREFIX+x} ]; then
  S3_PREFIX="/"
else
  S3_PREFIX="/${S3_PREFIX}/"
fi

# Backup all databases or specific ones
if [ "${POSTGRES_BACKUP_ALL}" == "true" ]; then
  SRC_FILE=dump.sql.gz
  DEST_FILE=all_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz
  
  if [ "${S3_FILE_NAME}" != "**None**" ]; then
    DEST_FILE=${S3_FILE_NAME}.sql.gz
  fi

  echo "Creating dump of all databases from ${POSTGRES_HOST}..."
  if pg_dumpall -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER | gzip > $SRC_FILE; then
    echo "Database dump successful."
  else
    echo "Database dump failed." >&2
    exit 2
  fi

  if [ "${ENCRYPTION_PASSWORD}" != "**None**" ]; then
    echo "Encrypting ${SRC_FILE}"
    if openssl enc -aes-256-cbc -in $SRC_FILE -out ${SRC_FILE}.enc -k $ENCRYPTION_PASSWORD; then
      echo "Encryption successful."
      rm $SRC_FILE
      SRC_FILE="${SRC_FILE}.enc"
      DEST_FILE="${DEST_FILE}.enc"
    else
      echo "Error encrypting ${SRC_FILE}" >&2
      exit 2
    fi
  fi

  echo "Uploading dump to $S3_BUCKET"
  if cat $SRC_FILE | aws $AWS_ARGS s3 cp - "s3://${S3_BUCKET}${S3_PREFIX}${DEST_FILE}"; then
    echo "SQL backup uploaded successfully"
  else
    echo "Error uploading to S3" >&2
    exit 2
  fi

  rm -rf $SRC_FILE
else
  OIFS="$IFS"
  IFS=','
  for DB in $POSTGRES_DATABASE
  do
    IFS="$OIFS"

    SRC_FILE=dump.sql.gz
    DEST_FILE=${DB}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz

    if [ "${S3_FILE_NAME}" != "**None**" ]; then
      DEST_FILE=${S3_FILE_NAME}_${DB}.sql.gz
    fi
    
    echo "Creating dump of ${DB} database from ${POSTGRES_HOST}..."
    if pg_dump $POSTGRES_HOST_OPTS $DB | gzip > $SRC_FILE; then
      echo "Database dump successful."
    else
      echo "Database dump failed." >&2
      exit 2
    fi
    
    if [ "${ENCRYPTION_PASSWORD}" != "**None**" ]; then
      echo "Encrypting ${SRC_FILE}"
      if openssl enc -aes-256-cbc -in $SRC_FILE -out ${SRC_FILE}.enc -k $ENCRYPTION_PASSWORD; then
        echo "Encryption successful."
        rm $SRC_FILE
        SRC_FILE="${SRC_FILE}.enc"
        DEST_FILE="${DEST_FILE}.enc"
      else
        echo "Error encrypting ${SRC_FILE}" >&2
        exit 2
      fi
    fi

    echo "Uploading dump to $S3_BUCKET"
    if cat $SRC_FILE | aws $AWS_ARGS s3 cp - "s3://${S3_BUCKET}${S3_PREFIX}${DEST_FILE}"; then
      echo "SQL backup uploaded successfully"
    else
      echo "Error uploading to S3" >&2
      exit 2
    fi

    rm -rf $SRC_FILE
  done
fi
