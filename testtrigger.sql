-- =====================================================
-- FILE TEST TRIGGER ĐỚN GIẢN - testtrigger.sql
-- Kiểm thử các trigger trong apartment_db1
-- =====================================================

-- Sử dụng database apartment_db1
USE apartment_db1;

-- =====================================================
-- PHẦN 1: TEST TRIGGER check_contract_dates
-- =====================================================

SELECT '=== TESTING TRIGGER: check_contract_dates ===' as test_section;

-- Test 1: Thử tạo contract với ngày kết thúc TRƯỚC ngày bắt đầu (sẽ bị lỗi)
SELECT '1. Test ngày kết thúc trước ngày bắt đầu (phải BỊ CHẶN):' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST (sẽ bị lỗi):
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2025-12-01', '2025-06-01', 6500000, 13000000, 'ACTIVE');
*/

-- Test 2: Thử tạo contract với ngày bắt đầu TRONG QUÁ KHỨ (sẽ bị lỗi)
SELECT '2. Test ngày bắt đầu trong quá khứ (phải BỊ CHẶN):' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST (sẽ bị lỗi):
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2024-01-01', '2025-12-01', 6500000, 13000000, 'ACTIVE');
*/

-- Test 3: Tạo contract ĐÚNG (sẽ thành công)
SELECT '3. Test tạo contract đúng định dạng (phải THÀNH CÔNG):' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST (sẽ thành công):
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2025-07-01', '2026-07-01', 6500000, 13000000, 'ACTIVE');
*/

-- Kiểm tra kết quả test 3:
SELECT 'Kiểm tra contract vừa tạo:' as check_result;
SELECT id, apartment_id, customer_id, start_date, end_date, payment_status 
FROM contract 
WHERE apartment_id = 1 AND customer_id = 1
ORDER BY id DESC LIMIT 1;

-- =====================================================
-- PHẦN 2: TEST TRIGGER log_equipment_status_change
-- =====================================================

SELECT '=== TESTING TRIGGER: log_equipment_status_change ===' as test_section;

-- Xem log trước khi test
SELECT 'Log equipment status TRƯỚC khi test:' as before_test;
SELECT * FROM equipment_status_log ORDER BY change_timestamp DESC LIMIT 5;

-- Test 1: Thay đổi status của equipment (sẽ tạo log)
SELECT '1. Test thay đổi status equipment (phải TẠO LOG):' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
UPDATE equipment 
SET status = 'MAINTENANCE' 
WHERE id = 1;
*/

-- Kiểm tra log sau khi update
SELECT 'Log equipment status SAU khi test:' as after_test;
SELECT * FROM equipment_status_log ORDER BY change_timestamp DESC LIMIT 3;

-- Test 2: Thay đổi thuộc tính khác (không tạo log)
SELECT '2. Test thay đổi thuộc tính khác - không tạo log:' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
UPDATE equipment 
SET broken_fee = 2600000 
WHERE id = 1;
*/

-- Test 3: Thay đổi lại status về WORKING
SELECT '3. Test đổi status về WORKING:' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
UPDATE equipment 
SET status = 'WORKING' 
WHERE id = 1;
*/

-- =====================================================
-- PHẦN 3: TEST TRIGGER update_apartment_rented_status
-- =====================================================

SELECT '=== TESTING TRIGGER: update_apartment_rented_status ===' as test_section;

-- Kiểm tra status apartment trước test
SELECT 'Status apartment TRƯỚC khi test:' as before_test;
SELECT id, name, rented FROM apartment WHERE id IN (3, 5) ORDER BY id;

-- Test 1: Tạo contract mới (sẽ tự động update apartment.rented = 1)
SELECT '1. Test tạo contract mới cho apartment 3:' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (3, 2, '2025-08-01', '2026-08-01', 15000000, 30000000, 'ACTIVE');
*/

-- Kiểm tra status apartment sau test
SELECT 'Status apartment SAU khi test:' as after_test;
SELECT id, name, rented FROM apartment WHERE id = 3;

-- Test 2: Tạo contract cho apartment khác
SELECT '2. Test tạo contract mới cho apartment 5:' as test_case;

-- COPY LỆNH NÀY ĐỂ TEST:
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (5, 3, '2025-09-15', '2026-03-15', 12500000, 25000000, 'ACTIVE');
*/

-- Kiểm tra tất cả apartments
SELECT 'Tất cả apartments và status:' as all_apartments;
SELECT id, name, rented, 
       CASE WHEN rented = 1 THEN 'ĐÃ THUÊ' ELSE 'CÒN TRỐNG' END as status_text
FROM apartment ORDER BY id;

-- =====================================================
-- PHẦN 4: XEM TẤT CẢ CONTRACTS ĐÃ TẠO
-- =====================================================

SELECT '=== TỔNG KẾT: TẤT CẢ CONTRACTS ĐÃ TẠO ===' as summary_section;

SELECT 
    c.id as contract_id,
    a.name as apartment_name,
    cust.name as customer_name,
    c.start_date,
    c.end_date,
    FORMAT(c.monthly_rent, 0) as rent_formatted,
    c.payment_status
FROM contract c
JOIN apartment a ON c.apartment_id = a.id
JOIN customer cust ON c.customer_id = cust.id
ORDER BY c.id;

-- =====================================================
-- PHẦN 5: XEM TẤT CẢ EQUIPMENT STATUS LOGS
-- =====================================================

SELECT '=== TỔNG KẾT: TẤT CẢ EQUIPMENT STATUS LOGS ===' as logs_section;

SELECT 
    esl.id,
    e.name as equipment_name,
    esl.old_status,
    esl.new_status,
    esl.change_timestamp
FROM equipment_status_log esl
JOIN equipment e ON esl.equipment_id = e.id
ORDER BY esl.change_timestamp DESC;

-- =====================================================
-- PHẦN 6: RESET DATA (NẾU MUỐN CHẠY LẠI TEST)
-- =====================================================

SELECT '=== LỆNH RESET DATA (CHẠY NẾU MUỐN TEST LẠI) ===' as reset_section;

-- COPY CÁC LỆNH NÀY ĐỂ RESET:
/*
-- Xóa contracts test
DELETE FROM contract WHERE id > 3;

-- Reset apartment status
UPDATE apartment SET rented = 0 WHERE id IN (1, 3, 5);
UPDATE apartment SET rented = 1 WHERE id IN (2, 4, 7);

-- Xóa equipment logs test
DELETE FROM equipment_status_log WHERE id > 0;

-- Reset equipment status về ban đầu
UPDATE equipment SET status = 'WORKING' WHERE id = 1;
UPDATE equipment SET status = 'MAINTENANCE' WHERE id = 5;
UPDATE equipment SET status = 'BROKEN' WHERE id = 10;
*/

-- =====================================================
-- HƯỚNG DẪN SỬ DỤNG:
-- 
-- 1. Chạy file này để xem structure test
-- 2. Copy từng lệnh trong /* */ để test riêng lẻ
-- 3. Quan sát kết quả và lỗi trigger
-- 4. Dùng phần RESET để chạy lại test
-- 
-- CÁC TRIGGER ĐƯỢC TEST:
-- - check_contract_dates: Kiểm tra ngày tháng hợp lệ
-- - log_equipment_status_change: Ghi log khi đổi status
-- - update_apartment_rented_status: Tự động cập nhật thuê
-- =====================================================

SELECT 'TEST TRIGGER HOÀN TẤT - CHẠY CÁC LỆNH TRONG COMMENT ĐỂ KIỂM THỬ!' as final_message;
