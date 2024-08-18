#!/bin/sh

# Check required environment variables
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "You need to set the AWS_ACCESS_KEY_ID environment variable."
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "You need to set the AWS_SECRET_ACCESS_KEY environment variable."
  exit 1
fi

if [ -z "$S3_BUCKET" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ -z "$POSTGRES_DATABASE" ] && [ "$POSTGRES_BACKUP_ALL" != "true" ]; then
  echo "You need to set the POSTGRES_DATABASE environment variable or enable POSTGRES_BACKUP_ALL."
  exit 1
fi

if [ -z "$POSTGRES_HOST" ]; then
  if [ -n "$POSTGRES_PORT_5432_TCP_ADDR" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

POSTGRES_PORT=${POSTGRES_PORT:-5432}

if [ -z "$POSTGRES_USER" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable."
  exit 1
fi

# Configure AWS CLI options
AWS_ARGS=""
if [ -n "$S3_ENDPOINT" ]; then
  AWS_ARGS="--endpoint-url $S3_ENDPOINT"
fi

export PGPASSWORD="$POSTGRES_PASSWORD"

# Ensure clean-up of temporary files
trap "rm -f dump.sql.gz dump.sql.gz.enc" EXIT

# Backup all databases or specific ones
if [ "$POSTGRES_BACKUP_ALL" = "true" ]; then
  SRC_FILE="dump.sql.gz"
  DEST_FILE="all_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz"
  
  [ -n "$S3_FILE_NAME" ] && DEST_FILE="${S3_FILE_NAME}.sql.gz"

  echo "Creating dump of all databases from $POSTGRES_HOST..."
  if pg_dumpall -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" | gzip > "$SRC_FILE"; then
    echo "Database dump successful."
  else
    echo "Database dump failed." >&2
    exit 2
  fi

  if [ -n "$ENCRYPTION_PASSWORD" ]; then
    echo "Encrypting $SRC_FILE"
    if openssl enc -aes-256-cbc -in "$SRC_FILE" -out "${SRC_FILE}.enc" -k "$ENCRYPTION_PASSWORD"; then
      echo "Encryption successful."
      rm "$SRC_FILE"
      SRC_FILE="${SRC_FILE}.enc"
      DEST_FILE="${DEST_FILE}.enc"
    else
      echo "Error encrypting $SRC_FILE" >&2
      exit 2
    fi
  fi

  echo "Uploading dump to $S3_BUCKET"
  echo "Running command: aws $AWS_ARGS s3 cp \"$SRC_FILE\" \"s3://${S3_BUCKET}/${DEST_FILE}\" --region \"$S3_REGION\""
  if aws $AWS_ARGS s3 cp "$SRC_FILE" "s3://${S3_BUCKET}/${DEST_FILE}" --region "$S3_REGION"; then
    echo "SQL backup uploaded successfully"
  else
    echo "Error uploading to S3" >&2
    exit 3
  fi

else
  OLD_IFS="$IFS"
  IFS=','
  for DB in $POSTGRES_DATABASE; do
    SRC_FILE="dump.sql.gz"
    DEST_FILE="${DB}_$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz"

    [ -n "$S3_FILE_NAME" ] && DEST_FILE="${S3_FILE_NAME}_${DB}.sql.gz"
    
    echo "Creating dump of $DB database from $POSTGRES_HOST..."
    if pg_dump -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" "$DB" | gzip > "$SRC_FILE"; then
      echo "Database dump successful."
    else
      echo "Database dump failed." >&2
      exit 2
    fi
    
    if [ -n "$ENCRYPTION_PASSWORD" ]; then
      echo "Encrypting $SRC_FILE"
      if openssl enc -aes-256-cbc -in "$SRC_FILE" -out "${SRC_FILE}.enc" -k "$ENCRYPTION_PASSWORD"; then
        echo "Encryption successful."
        rm "$SRC_FILE"
        SRC_FILE="${SRC_FILE}.enc"
        DEST_FILE="${DEST_FILE}.enc"
      else
        echo "Error encrypting $SRC_FILE" >&2
        exit 2
      fi
    fi

    echo "Uploading dump to $S3_BUCKET"
    if aws $AWS_ARGS s3 cp "$SRC_FILE" "s3://${S3_BUCKET}/${DEST_FILE}" --region "$S3_REGION"; then
      echo "SQL backup uploaded successfully"
    else
      echo "Error uploading to S3" >&2
      exit 3
    fi

  done
  IFS="$OLD_IFS"
fi
