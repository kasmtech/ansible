#!/bin/bash
# $1 is the backup directory
# $2 is the retention period in days

set -ex



if [ -z "$1" ] ; then
    echo "FATAL: Missing output dir argument"
    exit 1
else
    OUTPUT_DIR=$1
fi

if [ ! -d $OUTPUT_DIR ]; then
    echo "FATAL: Cannot find dir $OUTPUT_DIR"
    exit 1
fi

if [ -z "$2" ] ; then
    echo "FATAL: Missing retention period argument"
    exit 1
else
    RETENTION_DAYS=$2
fi

mkdir -p $OUTPUT_DIR/$HOSTNAME

docker exec kasm_db /bin/bash -c "pg_dump -U kasmapp -w -Ft --exclude-table-data=logs kasm | gzip > /tmp/db_backup.tar.gz"

DATE=`date "+%Y%m%d_%H.%M.%S"`
OUTPUT_FILE=$OUTPUT_DIR/$HOSTNAME/kasm_db_backup_${HOSTNAME}_${DATE}.tar.gz

# Copy the backup locally
docker cp kasm_db:/tmp/db_backup.tar.gz $OUTPUT_FILE

# Delete files older than 10 days
find $OUTPUT_DIR/$HOSTNAME -name *.tar.gz -mtime +"$RETENTION_DAYS" -type f -delete

echo "Database backed up to:"
echo "$OUTPUT_FILE"
