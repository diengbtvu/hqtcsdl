-- =====================================================
-- QUICK TRIGGER TEST SUMMARY - quick_trigger_summary.sql
-- Tóm tắt nhanh các test trigger có sẵn
-- =====================================================

USE apartment_db1;

SELECT '════════════════════════════════════════════════════' as line;
SELECT 'TỔNG QUAN CÁC FILE TEST TRIGGER TRONG WORKSPACE' as title;
SELECT '════════════════════════════════════════════════════' as line;

-- File 1: testtrigger.sql (Basic)
SELECT '
📁 FILE: testtrigger.sql (CƠ BẢN)
   ├── Test check_contract_dates (3 test cases)
   ├── Test log_equipment_status_change (3 test cases)  
   ├── Test update_apartment_rented_status (2 test cases)
   ├── Tổng kết dữ liệu
   └── Lệnh reset đơn giản

   🎯 MỤC ĐÍCH: Kiểm thử cơ bản, dễ hiểu
   📝 ĐỘ PHỨC TẠP: Đơn giản
   ⏱️ THỜI GIAN: 5-10 phút
' as file_1_info;

-- File 2: enhanced_trigger_tests.sql (Advanced)  
SELECT '
📁 FILE: enhanced_trigger_tests.sql (NÂNG CAO)
   ├── Test Suite 1: check_contract_dates (6 test cases)
   │   ├── Ngày kết thúc trước ngày bắt đầu
   │   ├── Ngày bắt đầu trong quá khứ
   │   ├── Ngày bắt đầu = ngày kết thúc
   │   ├── Contract ngắn hạn (1 tháng)
   │   ├── Contract dài hạn (2 năm)
   │   └── UPDATE contract không hợp lệ
   │
   ├── Test Suite 2: log_equipment_status_change (6 test cases)
   │   ├── WORKING → MAINTENANCE
   │   ├── MAINTENANCE → BROKEN  
   │   ├── BROKEN → WORKING
   │   ├── Đổi thuộc tính khác (không tạo log)
   │   ├── Đổi status + thuộc tính khác
   │   └── Đổi nhiều equipment cùng lúc
   │
   ├── Test Suite 3: update_apartment_rented_status (3 test cases)
   │   ├── Tạo contract đơn lẻ
   │   ├── Tạo contract cho apartment khác
   │   └── Tạo nhiều contract cùng lúc
   │
   ├── Test Suite 4: Stress Test & Edge Cases (4 test cases)
   │   ├── Contract thời hạn rất ngắn (1 ngày)
   │   ├── Contract thời hạn rất dài (10 năm)
   │   ├── UPDATE nhiều equipment cùng lúc
   │   └── Kiểm tra với giá trị đặc biệt
   │
   ├── Báo cáo chi tiết (contracts, equipment logs, apartments)
   └── Lệnh reset đầy đủ

   🎯 MỤC ĐÍCH: Kiểm thử toàn diện, stress test
   📝 ĐỘ PHỨC TẠP: Nâng cao
   ⏱️ THỜI GIAN: 15-30 phút
' as file_2_info;

-- File 3: simple_trigger_test.sql (Quick)
SELECT '
📁 FILE: simple_trigger_test.sql (NHANH)
   ├── Test nhanh từng trigger riêng lẻ
   ├── Lệnh copy-paste đơn giản
   └── Ít comment, tập trung vào code

   🎯 MỤC ĐÍCH: Test nhanh, debug
   📝 ĐỘ PHỨC TẠP: Tối thiểu  
   ⏱️ THỜI GIAN: 2-5 phút
' as file_3_info;

SELECT '════════════════════════════════════════════════════' as line;
SELECT 'HƯỚNG DẪN CHỌN FILE TEST PHÙ HỢP' as guide_title;
SELECT '════════════════════════════════════════════════════' as line;

SELECT '
🚀 NGƯỜI MỚI BẮT ĐẦU:
   → Dùng testtrigger.sql
   → Đọc comment chi tiết
   → Làm quen với cách trigger hoạt động

🔬 KIỂM THỬ CHUYÊN SÂU:
   → Dùng enhanced_trigger_tests.sql
   → Test nhiều trường hợp edge case
   → Xem báo cáo chi tiết

⚡ DEBUG NHANH:
   → Dùng simple_trigger_test.sql
   → Copy lệnh test ngay lập tức
   → Ít bị phân tâm bởi comment

📊 KIỂM TRA TỔNG QUAN:
   → Chạy file này (quick_trigger_summary.sql)
   → Xem trạng thái hiện tại
   → Quyết định cần test gì
' as selection_guide;

SELECT '════════════════════════════════════════════════════' as line;
SELECT 'TRẠNG THÁI HIỆN TẠI CỦA DATABASE' as current_status;
SELECT '════════════════════════════════════════════════════' as line;

-- Kiểm tra trigger có tồn tại không
SELECT 'TRIGGERS HIỆN TẠI TRONG DATABASE:' as trigger_check;

SHOW TRIGGERS LIKE 'apartment%';

-- Thống kê dữ liệu hiện tại
SELECT '
📊 THỐNG KÊ DỮ LIỆU HIỆN TẠI:
' as stats_title;

SELECT 
    'Apartments' as table_name,
    COUNT(*) as total_records,
    SUM(rented) as rented_count,
    COUNT(*) - SUM(rented) as available_count,
    CONCAT(ROUND(SUM(rented) * 100.0 / COUNT(*), 1), '%') as occupancy_rate
FROM apartment

UNION ALL

SELECT 
    'Contracts' as table_name,
    COUNT(*) as total_records,
    SUM(CASE WHEN payment_status = 'ACTIVE' THEN 1 ELSE 0 END) as active_count,
    SUM(CASE WHEN start_date > CURDATE() THEN 1 ELSE 0 END) as future_count,
    CONCAT(COUNT(*), ' total') as extra_info
FROM contract

UNION ALL

SELECT 
    'Equipment' as table_name,
    COUNT(*) as total_records,
    SUM(CASE WHEN status = 'WORKING' THEN 1 ELSE 0 END) as working_count,
    SUM(CASE WHEN status = 'MAINTENANCE' THEN 1 ELSE 0 END) as maintenance_count,
    SUM(CASE WHEN status = 'BROKEN' THEN 1 ELSE 0 END) as broken_count
FROM equipment

UNION ALL

SELECT 
    'Equipment Logs' as table_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT equipment_id) as unique_equipment,
    0 as col4,
    CASE WHEN COUNT(*) > 0 THEN 'Has logs' ELSE 'No logs yet' END as extra_info
FROM equipment_status_log;

SELECT '════════════════════════════════════════════════════' as line;
SELECT 'LỆNH CHẠY CÁC FILE TEST' as commands_title;
SELECT '════════════════════════════════════════════════════' as line;

SELECT '
💻 LỆNH TERMINAL ĐỂ CHẠY CÁC FILE:

1. File tóm tắt này:
   mysql -u root -p apartment_db1 < quick_trigger_summary.sql

2. Test cơ bản:
   mysql -u root -p apartment_db1 < testtrigger.sql

3. Test nâng cao:  
   mysql -u root -p apartment_db1 < enhanced_trigger_tests.sql

4. Test nhanh:
   mysql -u root -p apartment_db1 < simple_trigger_test.sql

📝 SAU KHI CHẠY FILE:
   - Copy các lệnh trong /* */ 
   - Paste vào MySQL CLI hoặc Workbench
   - Quan sát kết quả và lỗi trigger
   - Sử dụng lệnh reset để test lại

🎯 MỤC TIÊU TEST:
   ✓ Đảm bảo trigger chặn dữ liệu sai
   ✓ Đảm bảo trigger tạo log đúng
   ✓ Đảm bảo trigger update status tự động
   ✓ Kiểm tra performance với nhiều dữ liệu
' as command_info;

SELECT '════════════════════════════════════════════════════' as line;
SELECT '✅ QUICK TRIGGER SUMMARY COMPLETE!' as final_message;
SELECT 'Chọn file test phù hợp và bắt đầu kiểm thử!' as instruction;
SELECT '════════════════════════════════════════════════════' as line;
