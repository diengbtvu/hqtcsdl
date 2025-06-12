#!/bin/bash

BACKUP_FILE="$1"
TEMP_DB="apartment_db_validation_$(date +%s)"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 apartment_db_backup_20250612_103045.sql"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found"
    exit 1
fi

echo "Validating backup: $BACKUP_FILE"

# Tạo temporary database
echo "Creating temporary validation database..."
mysql -u root -p -e "CREATE DATABASE $TEMP_DB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Failed to create validation database"
    exit 1
fi

# Restore backup
echo "Restoring backup to validation database..."
if mysql -u root -p $TEMP_DB < $BACKUP_FILE 2>/dev/null; then
    echo "✅ Backup file is valid and restorable"
    
    # Check table counts
    TABLES=$(mysql -u root -p -N -e "USE $TEMP_DB; SHOW TABLES;" 2>/dev/null | wc -l)
    echo "✅ Found $TABLES tables"
    
    # Check data integrity
    RECORDS=$(mysql -u root -p -N -e "
        USE $TEMP_DB; 
        SELECT COALESCE(SUM(table_rows), 0) FROM information_schema.tables 
        WHERE table_schema = '$TEMP_DB' AND table_type = 'BASE TABLE';" 2>/dev/null)
    echo "✅ Found $RECORDS total records"
    
    # Check views
    VIEWS=$(mysql -u root -p -N -e "
        USE $TEMP_DB;
        SHOW FULL TABLES WHERE Table_type = 'VIEW';" 2>/dev/null | wc -l)
    echo "✅ Found $VIEWS views"
    
    # Check procedures and functions
    PROCEDURES=$(mysql -u root -p -N -e "
        SELECT COUNT(*) FROM information_schema.routines 
        WHERE routine_schema = '$TEMP_DB';" 2>/dev/null)
    echo "✅ Found $PROCEDURES stored procedures/functions"
    
    # Check triggers
    TRIGGERS=$(mysql -u root -p -N -e "
        SELECT COUNT(*) FROM information_schema.triggers 
        WHERE trigger_schema = '$TEMP_DB';" 2>/dev/null)
    echo "✅ Found $TRIGGERS triggers"
    
    echo "✅ Backup validation completed successfully"
    VALIDATION_RESULT="VALID"
    
else
    echo "❌ Backup validation failed - restore unsuccessful"
    VALIDATION_RESULT="INVALID"
fi

# Cleanup
echo "🧹 Cleaning up validation database..."
mysql -u root -p -e "DROP DATABASE IF EXISTS $TEMP_DB;" 2>/dev/null

# Update backup log if original database exists
mysql -u root -p apartment_db -e "
    UPDATE backup_log 
    SET validation_status = '$VALIDATION_RESULT', 
        notes = CONCAT(notes, ' - Validation: $VALIDATION_RESULT')
    WHERE backup_file LIKE '%$(basename $BACKUP_FILE)%' 
    ORDER BY backup_date DESC LIMIT 1;" 2>/dev/null

echo "🎯 Validation completed"
