-- =====================================================
-- ENHANCED TRIGGER TESTS - enhanced_trigger_tests.sql
-- Kiểm thử mở rộng và chi tiết các trigger trong apartment_db1
-- =====================================================

-- Sử dụng database apartment_db1
USE apartment_db1;

-- =====================================================
-- KHỞI TẠO: KIỂM TRA TRẠNG THÁI BAN ĐẦU
-- =====================================================

SELECT '════════════════════════════════════════════════════' as separator;
SELECT 'ENHANCED TRIGGER TESTING - apartment_db1' as title;
SELECT '════════════════════════════════════════════════════' as separator;

-- Kiểm tra số lượng dữ liệu hiện tại
SELECT 'TRẠNG THÁI DỮ LIỆU BAN ĐẦU:' as section_title;

SELECT 
    'Apartments' as table_name,
    COUNT(*) as record_count,
    SUM(rented) as rented_count,
    COUNT(*) - SUM(rented) as available_count
FROM apartment

UNION ALL

SELECT 
    'Contracts' as table_name,
    COUNT(*) as record_count,
    SUM(CASE WHEN payment_status = 'ACTIVE' THEN 1 ELSE 0 END) as active_count,
    SUM(CASE WHEN payment_status != 'ACTIVE' THEN 1 ELSE 0 END) as inactive_count
FROM contract

UNION ALL

SELECT 
    'Equipment' as table_name,
    COUNT(*) as record_count,
    SUM(CASE WHEN status = 'WORKING' THEN 1 ELSE 0 END) as working_count,
    SUM(CASE WHEN status != 'WORKING' THEN 1 ELSE 0 END) as not_working_count
FROM equipment

UNION ALL

SELECT 
    'Equipment Logs' as table_name,
    COUNT(*) as record_count,
    0 as col3,
    0 as col4
FROM equipment_status_log;

-- =====================================================
-- TEST SUITE 1: TRIGGER check_contract_dates
-- =====================================================

SELECT '' as spacer;
SELECT '████████████████████████████████████████████████████' as separator;
SELECT '   TEST SUITE 1: TRIGGER check_contract_dates' as title;
SELECT '████████████████████████████████████████████████████' as separator;

-- Test Case 1.1: Ngày kết thúc trước ngày bắt đầu
SELECT '1.1 TEST: Ngày kết thúc TRƯỚC ngày bắt đầu (phải BỊ CHẶN)' as test_case;
SELECT 'Lệnh test: INSERT với end_date < start_date' as command;

-- COPY LỆNH NÀY ĐỂ TEST (sẽ bị lỗi):
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2025-12-01', '2025-06-01', 6500000, 13000000, 'ACTIVE');
*/

-- Test Case 1.2: Ngày bắt đầu trong quá khứ
SELECT '1.2 TEST: Ngày bắt đầu trong QUÁ KHỨ (phải BỊ CHẶN)' as test_case;
SELECT 'Lệnh test: INSERT với start_date < CURDATE()' as command;

-- COPY LỆNH NÀY ĐỂ TEST (sẽ bị lỗi):
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2024-01-01', '2025-12-01', 6500000, 13000000, 'ACTIVE');
*/

-- Test Case 1.3: Ngày bắt đầu = ngày kết thúc
SELECT '1.3 TEST: Ngày bắt đầu = ngày kết thúc (phải BỊ CHẶN)' as test_case;
SELECT 'Lệnh test: INSERT với start_date = end_date' as command;

-- COPY LỆNH NÀY ĐỂ TEST (sẽ bị lỗi):
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2025-07-01', '2025-07-01', 6500000, 13000000, 'ACTIVE');
*/

-- Test Case 1.4: Contract hợp lệ - ngắn hạn (1 tháng)
SELECT '1.4 TEST: Contract hợp lệ - ngắn hạn 1 tháng (phải THÀNH CÔNG)' as test_case;
SELECT 'Lệnh test: INSERT với thời hạn 1 tháng' as command;

-- COPY LỆNH NÀY ĐỂ TEST (sẽ thành công):
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2025-07-01', '2025-08-01', 6500000, 13000000, 'ACTIVE');
*/

-- Test Case 1.5: Contract hợp lệ - dài hạn (2 năm)
SELECT '1.5 TEST: Contract hợp lệ - dài hạn 2 năm (phải THÀNH CÔNG)' as test_case;
SELECT 'Lệnh test: INSERT với thời hạn 2 năm' as command;

-- COPY LỆNH NÀY ĐỂ TEST (sẽ thành công):
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (3, 2, '2025-08-01', '2027-08-01', 15000000, 30000000, 'ACTIVE');
*/

-- Test Case 1.6: UPDATE contract với ngày không hợp lệ
SELECT '1.6 TEST: UPDATE contract với ngày không hợp lệ (phải BỊ CHẶN)' as test_case;
SELECT 'Lệnh test: UPDATE để đổi end_date < start_date' as command;

-- COPY LỆNH NÀY ĐỂ TEST (sẽ bị lỗi):
/*
UPDATE contract SET end_date = '2025-01-01' WHERE id = 1;
*/

-- Kiểm tra kết quả Test Suite 1
SELECT '═══ KIỂM TRA KẾT QUẢ TEST SUITE 1 ═══' as check_title;
SELECT 
    id, 
    apartment_id, 
    customer_id, 
    start_date, 
    end_date,
    DATEDIFF(end_date, start_date) as duration_days,
    payment_status
FROM contract 
WHERE id > 3
ORDER BY id;

-- =====================================================
-- TEST SUITE 2: TRIGGER log_equipment_status_change
-- =====================================================

SELECT '' as spacer;
SELECT '████████████████████████████████████████████████████' as separator;
SELECT '   TEST SUITE 2: TRIGGER log_equipment_status_change' as title;
SELECT '████████████████████████████████████████████████████' as separator;

-- Kiểm tra equipment hiện tại
SELECT '2.0 TRẠNG THÁI EQUIPMENT BAN ĐẦU:' as initial_state;
SELECT id, name, status, apartment_id FROM equipment ORDER BY id LIMIT 5;

-- Kiểm tra log hiện tại
SELECT '2.0 LOG EQUIPMENT BAN ĐẦU:' as initial_log;
SELECT COUNT(*) as log_count FROM equipment_status_log;

-- Test Case 2.1: Đổi từ WORKING sang MAINTENANCE
SELECT '2.1 TEST: Đổi WORKING → MAINTENANCE (phải TẠO LOG)' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
UPDATE equipment SET status = 'MAINTENANCE' WHERE id = 1;
*/

-- Kiểm tra log sau test 2.1
SELECT '2.1 KIỂM TRA LOG SAU TEST:' as check_log;
SELECT 
    esl.id,
    e.name as equipment_name,
    esl.old_status,
    esl.new_status,
    esl.change_timestamp
FROM equipment_status_log esl
JOIN equipment e ON esl.equipment_id = e.id
ORDER BY esl.change_timestamp DESC LIMIT 3;

-- Test Case 2.2: Đổi từ MAINTENANCE sang BROKEN
SELECT '2.2 TEST: Đổi MAINTENANCE → BROKEN (phải TẠO LOG)' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
UPDATE equipment SET status = 'BROKEN' WHERE id = 1;
*/

-- Test Case 2.3: Đổi từ BROKEN sang WORKING
SELECT '2.3 TEST: Đổi BROKEN → WORKING (phải TẠO LOG)' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
UPDATE equipment SET status = 'WORKING' WHERE id = 1;
*/

-- Test Case 2.4: Đổi thuộc tính khác (không tạo log)
SELECT '2.4 TEST: Đổi thuộc tính KHÁC - không tạo log' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
UPDATE equipment SET broken_fee = 2700000 WHERE id = 1;
*/

-- Test Case 2.5: Đổi status cùng lúc với thuộc tính khác
SELECT '2.5 TEST: Đổi STATUS + thuộc tính khác (phải TẠO LOG)' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
UPDATE equipment SET status = 'MAINTENANCE', broken_fee = 2800000 WHERE id = 1;
*/

-- Test Case 2.6: Đổi status cho nhiều equipment cùng lúc
SELECT '2.6 TEST: Đổi status NHIỀU equipment (phải TẠO NHIỀU LOG)' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
UPDATE equipment SET status = 'MAINTENANCE' WHERE id IN (2, 3, 4);
*/

-- Kiểm tra tổng kết log
SELECT '═══ KIỂM TRA TỔNG KẾT LOG EQUIPMENT ═══' as log_summary;
SELECT 
    equipment_id,
    COUNT(*) as change_count,
    MIN(change_timestamp) as first_change,
    MAX(change_timestamp) as last_change
FROM equipment_status_log
GROUP BY equipment_id
ORDER BY equipment_id;

-- =====================================================
-- TEST SUITE 3: TRIGGER update_apartment_rented_status
-- =====================================================

SELECT '' as spacer;
SELECT '████████████████████████████████████████████████████' as separator;
SELECT '   TEST SUITE 3: TRIGGER update_apartment_rented_status' as title;
SELECT '████████████████████████████████████████████████████' as separator;

-- Kiểm tra trạng thái apartment ban đầu
SELECT '3.0 TRẠNG THÁI APARTMENT BAN ĐẦU:' as initial_apartment;
SELECT 
    id, 
    name, 
    rented,
    CASE WHEN rented = 1 THEN 'ĐÃ THUÊ' ELSE 'CÒN TRỐNG' END as status_text
FROM apartment 
WHERE id IN (5, 6, 8, 9, 10)
ORDER BY id;

-- Test Case 3.1: Tạo contract mới (auto update rented = 1)
SELECT '3.1 TEST: Tạo contract mới cho apartment 5 (phải AUTO UPDATE rented=1)' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (5, 3, '2025-09-01', '2026-09-01', 12500000, 25000000, 'ACTIVE');
*/

-- Kiểm tra sau test 3.1
SELECT '3.1 KIỂM TRA APARTMENT SAU TEST:' as check_3_1;
SELECT id, name, rented FROM apartment WHERE id = 5;

-- Test Case 3.2: Tạo contract cho apartment khác
SELECT '3.2 TEST: Tạo contract mới cho apartment 6' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (6, 1, '2025-10-15', '2026-04-15', 8500000, 17000000, 'ACTIVE');
*/

-- Test Case 3.3: Tạo nhiều contract cùng lúc
SELECT '3.3 TEST: Tạo NHIỀU contract cùng lúc' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES 
(8, 2, '2025-11-01', '2026-11-01', 14000000, 28000000, 'ACTIVE'),
(9, 3, '2025-11-15', '2026-05-15', 11000000, 22000000, 'ACTIVE'),
(10, 1, '2025-12-01', '2026-12-01', 16000000, 32000000, 'ACTIVE');
*/

-- Kiểm tra tổng kết apartment status
SELECT '═══ KIỂM TRA TỔNG KẾT APARTMENT STATUS ═══' as apartment_summary;
SELECT 
    a.id,
    a.name,
    a.rented,
    CASE WHEN a.rented = 1 THEN 'ĐÃ THUÊ' ELSE 'CÒN TRỐNG' END as status_text,
    COUNT(c.id) as contract_count,
    MAX(c.end_date) as latest_contract_end
FROM apartment a
LEFT JOIN contract c ON a.id = c.apartment_id
GROUP BY a.id, a.name, a.rented
ORDER BY a.id;

-- =====================================================
-- TEST SUITE 4: STRESS TEST & EDGE CASES
-- =====================================================

SELECT '' as spacer;
SELECT '████████████████████████████████████████████████████' as separator;
SELECT '   TEST SUITE 4: STRESS TEST & EDGE CASES' as title;
SELECT '████████████████████████████████████████████████████' as separator;

-- Test Case 4.1: Contract với thời hạn rất ngắn (1 ngày)
SELECT '4.1 TEST: Contract thời hạn RẤT NGẮN (1 ngày)' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 2, DATE_ADD(CURDATE(), INTERVAL 1 DAY), DATE_ADD(CURDATE(), INTERVAL 2 DAY), 6500000, 13000000, 'ACTIVE');
*/

-- Test Case 4.2: Contract với thời hạn rất dài (10 năm)
SELECT '4.2 TEST: Contract thời hạn RẤT DÀI (10 năm)' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (3, 1, '2025-07-01', '2035-07-01', 15000000, 30000000, 'ACTIVE');
*/

-- Test Case 4.3: Cập nhật nhiều equipment status cùng lúc
SELECT '4.3 TEST: UPDATE NHIỀU equipment status cùng lúc' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
UPDATE equipment 
SET status = CASE 
    WHEN id % 2 = 0 THEN 'MAINTENANCE'
    ELSE 'WORKING'
END
WHERE id BETWEEN 1 AND 10;
*/

-- Test Case 4.4: Kiểm tra trigger với giá trị NULL
SELECT '4.4 TEST: Kiểm tra trigger với giá trị có thể NULL' as test_case;
SELECT 'Lưu ý: Các trường date không cho phép NULL trong schema' as note;

-- =====================================================
-- TỔNG KẾT VÀ BÁO CÁO
-- =====================================================

SELECT '' as spacer;
SELECT '████████████████████████████████████████████████████' as separator;
SELECT '   TỔNG KẾT VÀ BÁO CÁO CUỐI CÙNG' as title;
SELECT '████████████████████████████████████████████████████' as separator;

-- Báo cáo contracts
SELECT '═══ BÁO CÁO CONTRACTS ═══' as contracts_report;
SELECT 
    'Tổng số contracts' as metric,
    COUNT(*) as value,
    '' as detail
FROM contract

UNION ALL

SELECT 
    'Contracts ACTIVE' as metric,
    COUNT(*) as value,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM contract), 1), '%') as detail
FROM contract WHERE payment_status = 'ACTIVE'

UNION ALL

SELECT 
    'Contracts trong tương lai' as metric,
    COUNT(*) as value,
    CONCAT(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM contract), 1), '%') as detail
FROM contract WHERE start_date > CURDATE()

UNION ALL

SELECT 
    'Thời hạn trung bình (ngày)' as metric,
    ROUND(AVG(DATEDIFF(end_date, start_date))) as value,
    'ngày' as detail
FROM contract;

-- Báo cáo equipment logs
SELECT '═══ BÁO CÁO EQUIPMENT LOGS ═══' as logs_report;
SELECT 
    'Tổng số log entries' as metric,
    COUNT(*) as value,
    '' as detail
FROM equipment_status_log

UNION ALL

SELECT 
    'Equipment có thay đổi' as metric,
    COUNT(DISTINCT equipment_id) as value,
    CONCAT('/', (SELECT COUNT(*) FROM equipment), ' total') as detail
FROM equipment_status_log

UNION ALL

SELECT 
    'Thay đổi trung bình/equipment' as metric,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT equipment_id), 1) as value,
    'lần' as detail
FROM equipment_status_log;

-- Báo cáo apartments
SELECT '═══ BÁO CÁO APARTMENTS ═══' as apartments_report;
SELECT 
    'Tổng số apartments' as metric,
    COUNT(*) as value,
    '' as detail
FROM apartment

UNION ALL

SELECT 
    'Apartments đã thuê' as metric,
    SUM(rented) as value,
    CONCAT(ROUND(SUM(rented) * 100.0 / COUNT(*), 1), '%') as detail
FROM apartment

UNION ALL

SELECT 
    'Apartments còn trống' as metric,
    COUNT(*) - SUM(rented) as value,
    CONCAT(ROUND((COUNT(*) - SUM(rented)) * 100.0 / COUNT(*), 1), '%') as detail
FROM apartment;

-- =====================================================
-- LỆNH RESET ĐẦY ĐỦ
-- =====================================================

SELECT '████████████████████████████████████████████████████' as separator;
SELECT '   LỆNH RESET ĐẦY ĐỦ (CHẠY NẾU MUỐN TEST LẠI)' as reset_title;
SELECT '████████████████████████████████████████████████████' as separator;

-- COPY TOÀN BỘ BLOCK NÀY ĐỂ RESET:
/*
-- 1. Xóa tất cả contracts test (giữ lại 3 contracts gốc)
DELETE FROM contract WHERE id > 3;

-- 2. Reset apartment status về trạng thái ban đầu
UPDATE apartment SET rented = 0 WHERE id NOT IN (2, 4, 7);
UPDATE apartment SET rented = 1 WHERE id IN (2, 4, 7);

-- 3. Xóa tất cả equipment logs
DELETE FROM equipment_status_log;

-- 4. Reset equipment status về trạng thái ban đầu
UPDATE equipment SET status = 'WORKING' WHERE id NOT IN (5, 10);
UPDATE equipment SET status = 'MAINTENANCE' WHERE id = 5;
UPDATE equipment SET status = 'BROKEN' WHERE id = 10;

-- 5. Reset equipment fees về ban đầu
UPDATE equipment SET broken_fee = 2500000 WHERE id = 1;

-- 6. Kiểm tra reset thành công
SELECT 'RESET HOÀN TẤT!' as status;
SELECT COUNT(*) as contracts_count FROM contract;
SELECT SUM(rented) as rented_apartments FROM apartment;
SELECT COUNT(*) as equipment_logs FROM equipment_status_log;
*/

-- =====================================================
-- HƯỚNG DẪN SỬ DỤNG CHI TIẾT
-- =====================================================

SELECT '════════════════════════════════════════════════════' as separator;
SELECT 'HƯỚNG DẪN SỬ DỤNG ENHANCED TRIGGER TESTS' as guide_title;
SELECT '════════════════════════════════════════════════════' as separator;

SELECT '
CÁCH SỬ DỤNG:

1. CHẠY FILE NÀY ĐỂ XEM CẤU TRÚC TEST:
   mysql -u root -p apartment_db1 < enhanced_trigger_tests.sql

2. COPY TỪNG LỆNH TRONG /* */ ĐỂ TEST RIÊNG LẺ:
   - Mở MySQL CLI hoặc Workbench
   - Copy lệnh từ comment
   - Paste và chạy
   - Quan sát kết quả hoặc lỗi

3. CÁC TEST SUITE:
   - Suite 1: check_contract_dates (6 test cases)
   - Suite 2: log_equipment_status_change (6 test cases) 
   - Suite 3: update_apartment_rented_status (3 test cases)
   - Suite 4: Stress tests & Edge cases (4 test cases)

4. RESET DỮ LIỆU:
   - Copy toàn bộ block RESET
   - Chạy để về trạng thái ban đầu
   - Có thể test lại từ đầu

5. KIỂM TRA KẾT QUẢ:
   - Mỗi test có lệnh kiểm tra kèm theo
   - Xem báo cáo tổng kết ở cuối
   - So sánh với trạng thái ban đầu

CÁC TRIGGER ĐƯỢC TEST:
✓ check_contract_dates: Kiểm tra ngày tháng hợp lệ
✓ log_equipment_status_change: Ghi log khi đổi status
✓ update_apartment_rented_status: Tự động cập nhật thuê

CHÚ Ý:
- Một số test SẼ BỊ LỖI (đây là mục đích để test trigger)
- Kiểm tra message lỗi để đảm bảo trigger hoạt động đúng
- Chạy reset trước khi test lại từ đầu
' as usage_guide;

SELECT 'ENHANCED TRIGGER TESTING READY!' as final_status;
SELECT 'Copy các lệnh trong /* */ để bắt đầu kiểm thử!' as instruction;
