-- =====================================================
-- SIMPLE TRIGGER TEST - simple_trigger_test.sql
-- Test trigger nhanh, ít comment, tập trung code
-- =====================================================

USE apartment_db1;

-- =====================================================
-- TRIGGER 1: check_contract_dates
-- =====================================================

-- Test fail: end_date < start_date
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2025-12-01', '2025-06-01', 6500000, 13000000, 'ACTIVE');
*/

-- Test fail: start_date in past  
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2024-01-01', '2025-12-01', 6500000, 13000000, 'ACTIVE');
*/

-- Test success: valid dates
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2025-07-01', '2026-07-01', 6500000, 13000000, 'ACTIVE');
*/

-- Check result
/*
SELECT * FROM contract WHERE apartment_id = 1 AND customer_id = 1 ORDER BY id DESC LIMIT 1;
*/

-- =====================================================
-- TRIGGER 2: log_equipment_status_change
-- =====================================================

-- Check log before
/*
SELECT * FROM equipment_status_log ORDER BY change_timestamp DESC LIMIT 3;
*/

-- Test: change status (will create log)
/*
UPDATE equipment SET status = 'MAINTENANCE' WHERE id = 1;
*/

-- Check log after
/*
SELECT * FROM equipment_status_log ORDER BY change_timestamp DESC LIMIT 3;
*/

-- Test: change other field (no log)
/*
UPDATE equipment SET broken_fee = 2600000 WHERE id = 1;
*/

-- Test: change status back
/*
UPDATE equipment SET status = 'WORKING' WHERE id = 1;
*/

-- =====================================================
-- TRIGGER 3: update_apartment_rented_status
-- =====================================================

-- Check apartment status before
/*
SELECT id, name, rented FROM apartment WHERE id = 3;
*/

-- Test: create contract (auto update rented = 1)
/*
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (3, 2, '2025-08-01', '2026-08-01', 15000000, 30000000, 'ACTIVE');
*/

-- Check apartment status after
/*
SELECT id, name, rented FROM apartment WHERE id = 3;
*/

-- =====================================================
-- RESET
-- =====================================================

/*
DELETE FROM contract WHERE id > 3;
UPDATE apartment SET rented = 0 WHERE id NOT IN (2, 4, 7);
UPDATE apartment SET rented = 1 WHERE id IN (2, 4, 7);
DELETE FROM equipment_status_log;
UPDATE equipment SET status = 'WORKING' WHERE id = 1;
UPDATE equipment SET broken_fee = 2500000 WHERE id = 1;
*/
