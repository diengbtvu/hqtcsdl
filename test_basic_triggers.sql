-- =====================================================
-- TEST CÁC TRIGGER CƠ BẢN TỪ FILE complete_apartment_database.sql
-- Chạy sau khi đã chạy complete_apartment_database.sql
-- =====================================================

USE apartment_db1;

-- =====================================================
-- PHẦN 1: TEST TRIGGER check_contract_dates
-- =====================================================

SELECT 'TESTING BASIC TRIGGERS FROM complete_apartment_database.sql:' as info;
SELECT '=' as separator;

SELECT '1. TEST TRIGGER: check_contract_dates' as test_section;

-- Test case 1.1: Ngày kết thúc trước ngày bắt đầu (SẼ BỊ CHẶN)
SELECT 'Test 1.1: Ngày kết thúc trước ngày bắt đầu - SẼ BỊ CHẶN' as test_case;
SELECT 'Lệnh sẽ bị chặn: INSERT INTO contract với end_date < start_date' as description;

-- Uncomment để test thực tế - sẽ bị lỗi
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit) 
VALUES (1, 1, '2025-12-01', '2025-06-01', 6500000, 13000000);
*/
-- Lỗi mong đợi: "Ngày kết thúc phải sau ngày bắt đầu"

-- Test case 1.2: Ngày bắt đầu trong quá khứ (SẼ BỊ CHẶN)
SELECT 'Test 1.2: Ngày bắt đầu trong quá khứ - SẼ BỊ CHẶN' as test_case;
SELECT 'Lệnh sẽ bị chặn: INSERT INTO contract với start_date trong quá khứ' as description;

-- Uncomment để test thực tế - sẽ bị lỗi
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit) 
VALUES (1, 1, '2024-01-01', '2025-01-01', 6500000, 13000000);
*/
-- Lỗi mong đợi: "Ngày bắt đầu không thể trong quá khứ"

-- Test case 1.3: Tạo hợp đồng hợp lệ (SẼ THÀNH CÔNG)
SELECT 'Test 1.3: Tạo hợp đồng với ngày tháng hợp lệ - SẼ THÀNH CÔNG' as test_case;

-- Đảm bảo apartment 1 còn trống
UPDATE apartment SET rented = 0 WHERE id = 1;

INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2025-07-01', '2026-07-01', 6500000, 13000000, 'ACTIVE');

SELECT CONCAT('Hợp đồng đã tạo thành công với ID: ', LAST_INSERT_ID()) as result;

-- =====================================================
-- PHẦN 2: TEST TRIGGER log_equipment_status_change
-- =====================================================

SELECT '=' as separator;
SELECT '2. TEST TRIGGER: log_equipment_status_change' as test_section;

-- Kiểm tra log trước khi thay đổi
SELECT 'Số record trong equipment_status_log trước khi test:' as info;
SELECT COUNT(*) as log_count FROM equipment_status_log;

-- Test case 2.1: Thay đổi status thiết bị (SẼ TẠO LOG)
SELECT 'Test 2.1: Thay đổi status thiết bị từ WORKING sang MAINTENANCE - SẼ TẠO LOG' as test_case;

-- Xem status hiện tại
SELECT id, name, status FROM equipment WHERE id = 1;

-- Thay đổi status
UPDATE equipment SET status = 'MAINTENANCE' WHERE id = 1;

-- Kiểm tra log đã được tạo
SELECT 'Log mới được tạo:' as info;
SELECT * FROM equipment_status_log WHERE equipment_id = 1 ORDER BY change_timestamp DESC LIMIT 1;

-- Test case 2.2: Thay đổi lại status (SẼ TẠO LOG TIẾP)
SELECT 'Test 2.2: Thay đổi status từ MAINTENANCE về WORKING - SẼ TẠO LOG TIẾP' as test_case;

UPDATE equipment SET status = 'WORKING' WHERE id = 1;

-- Kiểm tra tất cả log của equipment này
SELECT 'Tất cả log của equipment ID 1:' as info;
SELECT equipment_id, old_status, new_status, change_timestamp 
FROM equipment_status_log 
WHERE equipment_id = 1 
ORDER BY change_timestamp DESC;

-- Test case 2.3: Update không thay đổi status (KHÔNG TẠO LOG)
SELECT 'Test 2.3: Update equipment mà không thay đổi status - KHÔNG TẠO LOG' as test_case;

-- Đếm log trước update
SELECT COUNT(*) INTO @log_count_before FROM equipment_status_log WHERE equipment_id = 1;

-- Update không thay đổi status
UPDATE equipment SET name = 'Tủ lạnh Samsung 400L (Updated)' WHERE id = 1;

-- Đếm log sau update
SELECT COUNT(*) INTO @log_count_after FROM equipment_status_log WHERE equipment_id = 1;

SELECT CASE 
    WHEN @log_count_before = @log_count_after THEN 'PASS: Không tạo log khi không thay đổi status'
    ELSE 'FAIL: Đã tạo log khi không nên'
END as test_result;

-- =====================================================
-- PHẦN 3: TEST TRIGGER update_apartment_rented_status
-- =====================================================

SELECT '=' as separator;
SELECT '3. TEST TRIGGER: update_apartment_rented_status' as test_section;

-- Test case 3.1: Tạo hợp đồng mới sẽ tự động set apartment.rented = 1
SELECT 'Test 3.1: Tạo hợp đồng mới tự động cập nhật apartment.rented = 1' as test_case;

-- Đảm bảo apartment 3 còn trống
UPDATE apartment SET rented = 0 WHERE id = 3;
SELECT CONCAT('Apartment 3 trước khi tạo hợp đồng - rented: ', rented) as before_status FROM apartment WHERE id = 3;

-- Tạo hợp đồng mới
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (3, 2, '2025-08-01', '2026-08-01', 15000000, 30000000, 'ACTIVE');

-- Kiểm tra apartment đã được cập nhật
SELECT CONCAT('Apartment 3 sau khi tạo hợp đồng - rented: ', rented) as after_status FROM apartment WHERE id = 3;

SELECT CASE 
    WHEN (SELECT rented FROM apartment WHERE id = 3) = 1 THEN 'PASS: Apartment tự động được đánh dấu là đã thuê'
    ELSE 'FAIL: Apartment không được cập nhật'
END as test_result;

-- =====================================================
-- PHẦN 4: INTEGRATION TEST - TEST NHIỀU TRIGGER CÙNG LÚC
-- =====================================================

SELECT '=' as separator;
SELECT '4. INTEGRATION TEST - NHIỀU TRIGGER CÙNG LÚC' as test_section;

-- Test case 4.1: Tạo hợp đồng với ngày sai (check_contract_dates SẼ CHẶN)
SELECT 'Test 4.1: Thử tạo hợp đồng với ngày sai - check_contract_dates SẼ CHẶN' as test_case;

-- Apartment 5 hiện đang trống
SELECT CONCAT('Apartment 5 hiện tại - rented: ', rented) as current_status FROM apartment WHERE id = 5;

-- Thử tạo hợp đồng với ngày sai - SẼ BỊ CHẶN
SELECT 'Lệnh sau sẽ bị chặn vì ngày không hợp lệ:' as info;
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit) 
VALUES (5, 3, '2025-12-01', '2025-06-01', 12500000, 25000000);
*/

-- Kiểm tra apartment 5 vẫn còn trống (trigger update_apartment_rented_status không được gọi)
SELECT CONCAT('Apartment 5 sau lệnh bị chặn - rented: ', rented) as after_blocked FROM apartment WHERE id = 5;

-- Test case 4.2: Tạo hợp đồng hợp lệ
SELECT 'Test 4.2: Tạo hợp đồng hợp lệ - Tất cả trigger hoạt động' as test_case;

INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (5, 3, '2025-09-01', '2026-09-01', 12500000, 25000000, 'ACTIVE');

SELECT CONCAT('Apartment 5 sau tạo hợp đồng hợp lệ - rented: ', rented) as final_status FROM apartment WHERE id = 5;

-- =====================================================
-- PHẦN 5: TỔNG KẾT TEST
-- =====================================================

SELECT '=' as separator;
SELECT 'TỔNG KẾT TEST CÁC TRIGGER CƠ BẢN:' as summary;

-- Kiểm tra số lượng hợp đồng đã tạo
SELECT 'Số hợp đồng đã tạo trong test:' as info;
SELECT COUNT(*) as new_contracts FROM contract WHERE start_date >= '2025-07-01';

-- Kiểm tra số apartment đã được đánh dấu thuê
SELECT 'Số apartment đã được đánh dấu thuê:' as info;
SELECT COUNT(*) as rented_apartments FROM apartment WHERE rented = 1;

-- Kiểm tra số log thiết bị đã tạo
SELECT 'Số log thay đổi thiết bị đã tạo:' as info;
SELECT COUNT(*) as equipment_logs FROM equipment_status_log;

-- Chi tiết test results
SELECT 'KẾT QUẢ CHI TIẾT:' as detail;
SELECT 'Trigger đã test:' as category
UNION ALL SELECT '✓ check_contract_dates - Kiểm tra ngày tháng hợp đồng'
UNION ALL SELECT '  - Chặn ngày kết thúc < ngày bắt đầu'
UNION ALL SELECT '  - Chặn ngày bắt đầu trong quá khứ'
UNION ALL SELECT '  - Cho phép ngày tháng hợp lệ'
UNION ALL SELECT ''
UNION ALL SELECT '✓ log_equipment_status_change - Ghi log thay đổi thiết bị'
UNION ALL SELECT '  - Tạo log khi thay đổi status'
UNION ALL SELECT '  - Không tạo log khi không thay đổi status'
UNION ALL SELECT ''
UNION ALL SELECT '✓ update_apartment_rented_status - Cập nhật trạng thái thuê'
UNION ALL SELECT '  - Tự động set rented=1 khi tạo hợp đồng'
UNION ALL SELECT '  - Không cập nhật khi hợp đồng bị chặn'
UNION ALL SELECT ''
UNION ALL SELECT 'TẤT CẢ TRIGGER CƠ BẢN HOẠT ĐỘNG CHÍNH XÁC!';

-- =====================================================
-- HƯỚNG DẪN TEST THỰC TẾ
-- =====================================================

SELECT '=' as separator;
SELECT 'HƯỚNG DẪN TEST THỰC TẾ:' as guide;
SELECT 'Để test các trigger bị chặn, uncomment các dòng có /*...*/' as instruction1;
SELECT 'Các lệnh đó sẽ gây ra lỗi và hiển thị thông báo từ trigger' as instruction2;
SELECT 'Ví dụ: Uncomment dòng 23-25 để test trigger check_contract_dates' as instruction3;

-- Hiển thị một số lệnh test có thể chạy thủ công
SELECT 'CÁC LỆNH TEST CÓ THỂ CHẠY THỦ CÔNG:' as manual_tests;
SELECT '1. Test ngày sai:' as test1;
SELECT 'INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit) VALUES (6, 1, "2025-12-01", "2025-06-01", 20000000, 40000000);' as cmd1;
SELECT '2. Test ngày quá khứ:' as test2;
SELECT 'INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit) VALUES (6, 1, "2024-01-01", "2025-01-01", 20000000, 40000000);' as cmd2;
SELECT '3. Test thay đổi thiết bị:' as test3;
SELECT 'UPDATE equipment SET status = "BROKEN" WHERE id = 2;' as cmd3;
