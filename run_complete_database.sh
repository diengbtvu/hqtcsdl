#!/bin/bash

# Script để chạy toàn bộ database SQL
# Sử dụng: ./run_complete_database.sh

echo "========================================"
echo "CHẠY TOÀN BỘ APARTMENT DATABASE SETUP"
echo "========================================"

# Kiểm tra MySQL có được cài đặt không
if ! command -v mysql &> /dev/null; then
    echo "❌ MySQL chưa được cài đặt!"
    echo "Vui lòng cài đặt MySQL trước khi chạy script này."
    echo ""
    echo "Cài đặt MySQL:"
    echo "Ubuntu/Debian: sudo apt update && sudo apt install mysql-server"
    echo "CentOS/RHEL: sudo yum install mysql-server"
    echo "macOS: brew install mysql"
    exit 1
fi

# Kiểm tra file SQL có tồn tại không
SQL_FILE="complete_apartment_database.sql"
if [ ! -f "$SQL_FILE" ]; then
    echo "❌ Không tìm thấy file $SQL_FILE"
    exit 1
fi

echo "✅ Tìm thấy file SQL: $SQL_FILE"
echo ""

# Nhập thông tin kết nối
read -p "Nhập MySQL username (mặc định: root): " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-root}

read -s -p "Nhập MySQL password: " MYSQL_PASS
echo ""

read -p "Nhập MySQL host (mặc định: localhost): " MYSQL_HOST
MYSQL_HOST=${MYSQL_HOST:-localhost}

read -p "Nhập MySQL port (mặc định: 3306): " MYSQL_PORT
MYSQL_PORT=${MYSQL_PORT:-3306}

echo ""
echo "🚀 Bắt đầu chạy database setup..."
echo ""

# Chạy file SQL
if mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" < "$SQL_FILE"; then
    echo ""
    echo "✅ ĐÃ CHẠY THÀNH CÔNG TOÀN BỘ DATABASE!"
    echo ""
    echo "📊 Kiểm tra kết quả:"
    echo "-------------------"
    
    # Kiểm tra database đã được tạo
    mysql -h"$MYSQL_HOST" -P"$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASS" -e "
    USE apartment_db;
    SELECT 'TABLES' as object_type, COUNT(*) as count FROM information_schema.tables WHERE table_schema = 'apartment_db' AND table_type = 'BASE TABLE'
    UNION ALL
    SELECT 'VIEWS' as object_type, COUNT(*) as count FROM information_schema.tables WHERE table_schema = 'apartment_db' AND table_type = 'VIEW'
    UNION ALL
    SELECT 'PROCEDURES' as object_type, COUNT(*) as count FROM information_schema.routines WHERE routine_schema = 'apartment_db' AND routine_type = 'PROCEDURE'
    UNION ALL
    SELECT 'FUNCTIONS' as object_type, COUNT(*) as count FROM information_schema.routines WHERE routine_schema = 'apartment_db' AND routine_type = 'FUNCTION'
    UNION ALL
    SELECT 'TRIGGERS' as object_type, COUNT(*) as count FROM information_schema.triggers WHERE trigger_schema = 'apartment_db';
    "
    
    echo ""
    echo "🎉 HỆ THỐNG APARTMENT DATABASE ĐÃ SẴN SÀNG SỬ DỤNG!"
    echo ""
    echo "📝 Để truy cập database:"
    echo "   mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p apartment_db"
    echo ""
    
else
    echo ""
    echo "❌ CÓ LỖI XẢY RA KHI CHẠY DATABASE SETUP!"
    echo "Vui lòng kiểm tra:"
    echo "- Thông tin kết nối MySQL"
    echo "- Quyền user MySQL"
    echo "- MySQL service đang chạy"
    exit 1
fi
