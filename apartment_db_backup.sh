#!/bin/bash

# Apartment Database Backup Script
BACKUP_DIR="/home/gb/backups"
DB_NAME="apartment_db"
DB_USER="apt_backup"
DB_PASS="BackupPass123!@#"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${DATE}.sql"

# Tạo thư mục backup nếu chưa có
mkdir -p ${BACKUP_DIR}

# Thực hiện backup
echo "Starting backup at $(date)"
mysqldump -u${DB_USER} -p${DB_PASS} \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  ${DB_NAME} > ${BACKUP_FILE}

if [ $? -eq 0 ]; then
    echo "Backup completed successfully: ${BACKUP_FILE}"
    # Compress backup file
    gzip ${BACKUP_FILE}
    echo "Backup compressed: ${BACKUP_FILE}.gz"
    
    # Delete backups older than 7 days
    find ${BACKUP_DIR} -name "${DB_NAME}_backup_*.sql.gz" -mtime +7 -delete
    echo "Old backups cleaned up"
    
    # Log backup to database
    mysql -u root -p${DB_PASS} ${DB_NAME} -e "
        INSERT INTO backup_log (backup_file, backup_size_mb, backup_status, validation_status, notes) 
        VALUES ('${BACKUP_FILE}.gz', $(du -m ${BACKUP_FILE}.gz | cut -f1), 'SUCCESS', 'NOT_TESTED', 'Automated backup completed');
    " 2>/dev/null
    
else
    echo "Backup failed!"
    # Log failure to database
    mysql -u root -p${DB_PASS} ${DB_NAME} -e "
        INSERT INTO backup_log (backup_file, backup_status, notes) 
        VALUES ('${BACKUP_FILE}', 'FAILED', 'Automated backup failed');
    " 2>/dev/null
    exit 1
fi
