-- =====================================================
-- INSERT DỮ LIỆU MẪU CHO HỆ THỐNG QUẢN LÝ CĂN HỘ
-- =====================================================

-- Sử dụng database
USE apartment_db;

-- =====================================================
-- 0. TẠO CÁC VIEWS CẦN THIẾT
-- =====================================================

-- View apartment_details: Thông tin căn hộ chi tiết
CREATE VIEW apartment_details AS
SELECT 
    a.id as apartment_id,
    a.name as apartment_name,
    a.floor_area,
    a.number_of_bedrooms,
    a.number_of_bathrooms,
    a.min_rate,
    a.rented,
    a.move_in_date,
    a.move_out_date,
    b.name as building_name,
    b.address as building_address,
    b.contact_number as building_contact,
    d.name as district_name,
    d.city,
    d.region
FROM apartment a
JOIN building b ON a.building_id = b.id
JOIN district d ON b.district_id = d.id;

-- View active_contracts: Hợp đồng đang hoạt động
CREATE VIEW active_contracts AS
SELECT 
    c.id as contract_id,
    c.start_date,
    c.end_date,
    c.monthly_rent,
    c.deposit,
    c.payment_status,
    cust.name as customer_name,
    cust.email as customer_email,
    cust.phone_number as customer_phone,
    a.name as apartment_name,
    b.name as building_name,
    b.address as building_address
FROM contract c
JOIN customer cust ON c.customer_id = cust.id
JOIN apartment a ON c.apartment_id = a.id
JOIN building b ON a.building_id = b.id
WHERE c.end_date >= CURDATE()
ORDER BY c.end_date ASC;

-- View monthly_revenue: Thống kê doanh thu theo tháng
CREATE VIEW monthly_revenue AS
SELECT 
    YEAR(c.start_date) as year,
    MONTH(c.start_date) as month,
    COUNT(c.id) as total_contracts,
    SUM(c.monthly_rent) as total_monthly_rent,
    SUM(c.deposit) as total_deposits,
    AVG(c.monthly_rent) as avg_monthly_rent
FROM contract c
WHERE c.start_date IS NOT NULL
GROUP BY YEAR(c.start_date), MONTH(c.start_date)
ORDER BY year DESC, month DESC;

-- View available_apartments: Căn hộ có sẵn
CREATE VIEW available_apartments AS
SELECT 
    a.id,
    a.name,
    a.floor_area,
    a.number_of_bedrooms,
    a.number_of_bathrooms,
    a.min_rate,
    b.name as building_name,
    b.address,
    d.name as district_name,
    d.city
FROM apartment a
JOIN building b ON a.building_id = b.id
JOIN district d ON b.district_id = d.id
WHERE a.rented = 0
ORDER BY a.min_rate ASC;

-- View apartment_equipment_view: Thiết bị trong căn hộ
CREATE VIEW apartment_equipment_view AS
SELECT 
    a.id as apartment_id,
    a.name as apartment_name,
    e.id as equipment_id,
    e.name as equipment_name,
    e.type as equipment_type,
    e.status as equipment_status,
    e.broken_fee
FROM apartment a
JOIN apartment_equipment ae ON a.id = ae.apartment_id
JOIN equipment e ON ae.equipment_id = e.id
ORDER BY a.name, e.name;

-- Kiểm tra views đã tạo
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- =====================================================
-- 0.1. TẠO CÁC STORED PROCEDURES VÀ FUNCTIONS
-- =====================================================

-- Procedure: CreateContract
DELIMITER //
CREATE PROCEDURE CreateContract(
    IN p_apartment_id BIGINT,
    IN p_customer_id BIGINT,
    IN p_start_date DATETIME,
    IN p_end_date DATETIME,
    IN p_monthly_rent DOUBLE,
    IN p_deposit DOUBLE,
    OUT p_contract_id BIGINT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_apartment_exists INT DEFAULT 0;
    DECLARE v_customer_exists INT DEFAULT 0;
    DECLARE v_apartment_available INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_message = MESSAGE_TEXT;
        SET p_contract_id = -1;
    END;
    
    START TRANSACTION;
    
    SELECT COUNT(*) INTO v_apartment_exists FROM apartment WHERE id = p_apartment_id;
    SELECT COUNT(*) INTO v_customer_exists FROM customer WHERE id = p_customer_id;
    SELECT COUNT(*) INTO v_apartment_available FROM apartment WHERE id = p_apartment_id AND rented = 0;
    
    IF v_apartment_exists = 0 THEN
        SET p_message = 'Apartment không tồn tại';
        SET p_contract_id = -1;
        ROLLBACK;
    ELSEIF v_customer_exists = 0 THEN
        SET p_message = 'Customer không tồn tại';
        SET p_contract_id = -1;
        ROLLBACK;
    ELSEIF v_apartment_available = 0 THEN
        SET p_message = 'Apartment đã được thuê';
        SET p_contract_id = -1;
        ROLLBACK;
    ELSE
        INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
        VALUES (p_apartment_id, p_customer_id, p_start_date, p_end_date, p_monthly_rent, p_deposit, 'ACTIVE');
        
        UPDATE apartment SET rented = 1 WHERE id = p_apartment_id;
        
        SET p_contract_id = LAST_INSERT_ID();
        SET p_message = 'Tạo hợp đồng thành công';
        COMMIT;
    END IF;
END//
DELIMITER ;

-- Procedure: SearchApartments
DELIMITER //
CREATE PROCEDURE SearchApartments(
    IN p_min_bedrooms INTEGER,
    IN p_max_rent DOUBLE,
    IN p_district_id BIGINT,
    IN p_min_area DOUBLE
)
BEGIN
    SELECT 
        a.id,
        a.name,
        a.floor_area,
        a.number_of_bedrooms,
        a.number_of_bathrooms,
        a.min_rate,
        a.rented,
        b.name as building_name,
        b.address as building_address,
        d.name as district_name
    FROM apartment a
    JOIN building b ON a.building_id = b.id
    JOIN district d ON b.district_id = d.id
    WHERE a.rented = 0
        AND (p_min_bedrooms IS NULL OR a.number_of_bedrooms >= p_min_bedrooms)
        AND (p_max_rent IS NULL OR a.min_rate <= p_max_rent)
        AND (p_district_id IS NULL OR d.id = p_district_id)
        AND (p_min_area IS NULL OR a.floor_area >= p_min_area)
    ORDER BY a.min_rate ASC;
END//
DELIMITER ;

-- Procedure: ManageApartmentEquipment
DELIMITER //
CREATE PROCEDURE ManageApartmentEquipment(
    IN p_action VARCHAR(10),
    IN p_apartment_id BIGINT,
    IN p_equipment_id BIGINT,
    OUT p_result VARCHAR(255)
)
BEGIN
    DECLARE v_apartment_exists INT DEFAULT 0;
    DECLARE v_equipment_exists INT DEFAULT 0;
    DECLARE v_association_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_apartment_exists FROM apartment WHERE id = p_apartment_id;
    SELECT COUNT(*) INTO v_equipment_exists FROM equipment WHERE id = p_equipment_id;
    SELECT COUNT(*) INTO v_association_exists FROM apartment_equipment 
    WHERE apartment_id = p_apartment_id AND equipment_id = p_equipment_id;
    
    IF v_apartment_exists = 0 THEN
        SET p_result = 'Apartment không tồn tại';
    ELSEIF v_equipment_exists = 0 THEN
        SET p_result = 'Equipment không tồn tại';
    ELSEIF p_action = 'ADD' THEN
        IF v_association_exists > 0 THEN
            SET p_result = 'Equipment đã có trong apartment này';
        ELSE
            INSERT INTO apartment_equipment (apartment_id, equipment_id) 
            VALUES (p_apartment_id, p_equipment_id);
            SET p_result = 'Thêm equipment thành công';
        END IF;
    ELSEIF p_action = 'REMOVE' THEN
        IF v_association_exists = 0 THEN
            SET p_result = 'Equipment không có trong apartment này';
        ELSE
            DELETE FROM apartment_equipment 
            WHERE apartment_id = p_apartment_id AND equipment_id = p_equipment_id;
            SET p_result = 'Xóa equipment thành công';
        END IF;
    ELSE
        SET p_result = 'Action không hợp lệ. Sử dụng ADD hoặc REMOVE';
    END IF;
END//
DELIMITER ;

-- Function: CalculateTotalRent
DELIMITER //
CREATE FUNCTION CalculateTotalRent(p_contract_id BIGINT) 
RETURNS DOUBLE
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_monthly_rent DOUBLE DEFAULT 0;
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    DECLARE v_months INT DEFAULT 0;
    
    SELECT monthly_rent, start_date, end_date 
    INTO v_monthly_rent, v_start_date, v_end_date
    FROM contract 
    WHERE id = p_contract_id;
    
    IF v_start_date IS NULL OR v_end_date IS NULL THEN
        RETURN 0;
    END IF;
    
    SET v_months = TIMESTAMPDIFF(MONTH, v_start_date, v_end_date);
    
    RETURN v_monthly_rent * v_months;
END//
DELIMITER ;

-- Function: GetApartmentStatus
DELIMITER //
CREATE FUNCTION GetApartmentStatus(p_apartment_id BIGINT)
RETURNS VARCHAR(50)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_rented BIT DEFAULT 0;
    DECLARE v_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_exists FROM apartment WHERE id = p_apartment_id;
    
    IF v_exists = 0 THEN
        RETURN 'KHÔNG TỒN TẠI';
    END IF;
    
    SELECT rented INTO v_rented FROM apartment WHERE id = p_apartment_id;
    
    IF v_rented = 1 THEN
        RETURN 'ĐÃ THUÊ';
    ELSE
        RETURN 'CÒN TRỐNG';
    END IF;
END//
DELIMITER ;

-- Kiểm tra procedures và functions đã tạo
SHOW PROCEDURE STATUS WHERE Db = DATABASE();
SHOW FUNCTION STATUS WHERE Db = DATABASE();

-- =====================================================
-- 0.2. TẠO CÁC TRIGGERS
-- =====================================================

-- Trigger: check_contract_dates
DELIMITER //
CREATE TRIGGER check_contract_dates
BEFORE INSERT ON contract
FOR EACH ROW
BEGIN
    IF NEW.end_date <= NEW.start_date THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngày kết thúc phải sau ngày bắt đầu';
    END IF;
    
    IF NEW.start_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngày bắt đầu không thể trong quá khứ';
    END IF;
END//
DELIMITER ;

-- Tạo bảng log cho equipment status changes
CREATE TABLE IF NOT EXISTS equipment_status_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    equipment_id BIGINT,
    old_status VARCHAR(255),
    new_status VARCHAR(255),
    change_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(255) DEFAULT USER()
);

-- Trigger: log_equipment_status_change
DELIMITER //
CREATE TRIGGER log_equipment_status_change
AFTER UPDATE ON equipment
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO equipment_status_log (equipment_id, old_status, new_status)
        VALUES (NEW.id, OLD.status, NEW.status);
    END IF;
END//
DELIMITER ;

-- Trigger: update_apartment_rented_status
DELIMITER //
CREATE TRIGGER update_apartment_rented_status
AFTER INSERT ON contract
FOR EACH ROW
BEGIN
    UPDATE apartment SET rented = 1 WHERE id = NEW.apartment_id;
END//
DELIMITER ;

-- Kiểm tra triggers đã tạo
SHOW TRIGGERS;

-- =====================================================
-- 1. INSERT DỮ LIỆU BẢNG USER_ACCOUNT
-- =====================================================
INSERT INTO user_account (user_name, password, role) VALUES
('admin', 'admin123', 'ADMIN'),
('manager1', 'manager123', 'MANAGER'),
('staff1', 'staff123', 'STAFF'),
('customer1', 'customer123', 'CUSTOMER'),
('customer2', 'customer456', 'CUSTOMER'),
('customer3', 'customer789', 'CUSTOMER');

-- Kiểm tra dữ liệu đã insert
SELECT id, user_name, role FROM user_account;

-- =====================================================
-- 2. INSERT DỮ LIỆU BẢNG CUSTOMER
-- =====================================================
INSERT INTO customer (name, email, phone_number, user_account_id) VALUES
('Nguyễn Văn A', 'nguyenvana@email.com', '0901234567', 4),
('Trần Thị B', 'tranthib@email.com', '0987654321', 5),
('Lê Văn C', 'levanc@email.com', '0123456789', 6);

-- Kiểm tra dữ liệu customers với JOIN
SELECT c.id, c.name, c.email, c.phone_number, u.user_name 
FROM customer c JOIN user_account u ON c.user_account_id = u.id;

-- =====================================================
-- 3. INSERT DỮ LIỆU BẢNG DISTRICT
-- =====================================================
INSERT INTO district (name, code, city, region) VALUES
('Quận 1', 'Q1', 'Hồ Chí Minh', 'Miền Nam'),
('Quận 3', 'Q3', 'Hồ Chí Minh', 'Miền Nam'),
('Quận Ba Đình', 'BD', 'Hà Nội', 'Miền Bắc'),
('Quận Hoàn Kiếm', 'HK', 'Hà Nội', 'Miền Bắc'),
('Quận Hải Châu', 'HC', 'Đà Nẵng', 'Miền Trung');

-- Kiểm tra dữ liệu districts
SELECT * FROM district;

-- =====================================================
-- 4. INSERT DỮ LIỆU BẢNG BUILDING
-- =====================================================
INSERT INTO building (name, address, contact_number, number_of_floors, total_area, type, district_id) VALUES
('Vinhomes Central Park', '208 Nguyễn Hữu Cảnh', '02839101010', 45, 15000.0, 'APARTMENT', 1),
('Bitexco Financial Tower', '2 Hải Triều', '02838234567', 68, 12000.0, 'OFFICE', 1),
('Saigon Pearl', '92 Nguyễn Hữu Cảnh', '02839102020', 40, 18000.0, 'APARTMENT', 1),
('Lotte Center Hanoi', '54 Liễu Giai', '02438315000', 65, 20000.0, 'MIXED', 3),
('Hanoi Towers', '49 Hai Bà Trưng', '02439364636', 25, 8000.0, 'APARTMENT', 4);

-- Kiểm tra dữ liệu buildings với district
SELECT b.id, b.name, b.address, b.number_of_floors, b.type, d.name as district_name 
FROM building b JOIN district d ON b.district_id = d.id;

-- =====================================================
-- 5. INSERT DỮ LIỆU BẢNG APARTMENT
-- =====================================================
INSERT INTO apartment (name, floor_area, number_of_bedrooms, number_of_bathrooms, min_rate, rented, building_id) VALUES
('A01-101', 45.5, 1, 1, 6500000, 0, 1),
('A02-205', 68.0, 2, 2, 9500000, 1, 1),
('A03-1501', 95.5, 3, 2, 15000000, 0, 1),
('P01-301', 55.0, 1, 1, 7200000, 1, 3),
('P02-1205', 85.0, 2, 2, 12500000, 0, 3),
('VIP-4501', 120.0, 3, 3, 20000000, 0, 3),
('L01-1001', 65.0, 2, 1, 11000000, 1, 4),
('L02-2015', 90.0, 3, 2, 16500000, 0, 4),
('H01-501', 50.0, 1, 1, 8500000, 0, 5),
('H02-1201', 75.0, 2, 2, 13000000, 0, 5);

-- Kiểm tra dữ liệu apartments với building
SELECT a.id, a.name, a.floor_area, a.number_of_bedrooms, a.min_rate, a.rented, b.name as building_name
FROM apartment a JOIN building b ON a.building_id = b.id;

-- =====================================================
-- 6. INSERT DỮ LIỆU BẢNG EQUIPMENT
-- =====================================================
INSERT INTO equipment (name, type, status, broken_fee) VALUES
('Tủ lạnh Samsung 400L', 'APPLIANCE', 'WORKING', 2500000),
('Smart TV 55 inch', 'ELECTRONICS', 'WORKING', 3000000),
('Sofa da 3 chỗ ngồi', 'FURNITURE', 'WORKING', 1500000),
('Điều hòa Daikin 2HP', 'APPLIANCE', 'WORKING', 4000000),
('Máy giặt LG 9kg', 'APPLIANCE', 'MAINTENANCE', 2000000),
('Bàn làm việc gỗ', 'FURNITURE', 'WORKING', 1200000),
('Máy nước nóng', 'APPLIANCE', 'WORKING', 1800000),
('Camera an ninh IP', 'SECURITY', 'WORKING', 800000),
('Tủ quần áo 3 cánh', 'FURNITURE', 'WORKING', 2200000),
('Bếp từ đôi', 'APPLIANCE', 'BROKEN', 1500000);

-- Kiểm tra dữ liệu equipment
SELECT * FROM equipment;

-- =====================================================
-- 7. INSERT DỮ LIỆU BẢNG APARTMENT_EQUIPMENT
-- =====================================================
INSERT INTO apartment_equipment (apartment_id, equipment_id) VALUES
-- Căn hộ A01-101: Tủ lạnh, TV, Sofa
(1, 1), (1, 2), (1, 3),
-- Căn hộ A02-205: Tủ lạnh, Điều hòa, Bàn làm việc
(2, 1), (2, 4), (2, 6),
-- Căn hộ A03-1501: Tủ lạnh, TV, Điều hòa, Tủ quần áo
(3, 1), (3, 2), (3, 4), (3, 9),
-- Căn hộ P01-301: Máy giặt, Máy nước nóng, Camera
(4, 5), (4, 7), (4, 8),
-- Căn hộ P02-1205: Tủ lạnh, TV, Điều hòa, Bàn
(5, 1), (5, 2), (5, 4), (5, 6),
-- VIP-4501: Full equipment
(6, 1), (6, 2), (6, 3), (6, 4), (6, 9),
-- L01-1001: Tủ lạnh, Điều hòa, Bếp từ
(7, 1), (7, 4), (7, 10),
-- L02-2015: Cao cấp
(8, 1), (8, 2), (8, 4), (8, 6), (8, 9),
-- H01-501: Basic
(9, 1), (9, 7),
-- H02-1201: Standard
(10, 1), (10, 2), (10, 4);

-- Kiểm tra associations cho một số căn hộ
SELECT a.name as apartment_name, e.name as equipment_name, e.type, e.status
FROM apartment_equipment ae
JOIN apartment a ON ae.apartment_id = a.id
JOIN equipment e ON ae.equipment_id = e.id
WHERE a.id IN (1, 3, 6)
ORDER BY a.name, e.name;

-- =====================================================
-- 8. INSERT DỮ LIỆU BẢNG CONTRACT
-- =====================================================
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) VALUES
(2, 1, '2025-01-15', '2026-01-15', 9500000, 19000000, 'ACTIVE'),
(4, 2, '2025-03-01', '2025-09-01', 7200000, 14400000, 'COMPLETED'),
(7, 3, '2025-05-10', '2026-05-10', 11000000, 22000000, 'ACTIVE');

-- Kiểm tra contracts với thông tin đầy đủ
SELECT 
    c.id as contract_id,
    cust.name as customer_name,
    a.name as apartment_name,
    b.name as building_name,
    c.start_date,
    c.end_date,
    FORMAT(c.monthly_rent, 0) as monthly_rent,
    c.payment_status
FROM contract c
JOIN customer cust ON c.customer_id = cust.id
JOIN apartment a ON c.apartment_id = a.id
JOIN building b ON a.building_id = b.id;

-- =====================================================
-- 9. THỐNG KÊ TỔNG KẾT
-- =====================================================

-- Thống kê số lượng records trong từng bảng
SELECT 
    'user_account' as table_name, COUNT(*) as record_count FROM user_account
UNION ALL SELECT 'customer', COUNT(*) FROM customer
UNION ALL SELECT 'district', COUNT(*) FROM district
UNION ALL SELECT 'building', COUNT(*) FROM building
UNION ALL SELECT 'apartment', COUNT(*) FROM apartment
UNION ALL SELECT 'equipment', COUNT(*) FROM equipment
UNION ALL SELECT 'apartment_equipment', COUNT(*) FROM apartment_equipment
UNION ALL SELECT 'contract', COUNT(*) FROM contract;

-- Kiểm tra apartments có sẵn và đã thuê
SELECT 
    'Available apartments' as status, COUNT(*) as count FROM apartment WHERE rented = 0
UNION ALL
SELECT 'Rented apartments' as status, COUNT(*) as count FROM apartment WHERE rented = 1;

-- Kiểm tra integrity constraints
SELECT 'All apartments have valid building_id' as constraint_check
WHERE NOT EXISTS (
    SELECT 1 FROM apartment a 
    LEFT JOIN building b ON a.building_id = b.id 
    WHERE b.id IS NULL
);

SELECT 'All customers have valid user_account_id' as constraint_check
WHERE NOT EXISTS (
    SELECT 1 FROM customer c 
    LEFT JOIN user_account u ON c.user_account_id = u.id 
    WHERE u.id IS NULL
);

SELECT 'All contracts have valid apartment_id and customer_id' as constraint_check
WHERE NOT EXISTS (
    SELECT 1 FROM contract ct
    LEFT JOIN apartment a ON ct.apartment_id = a.id 
    LEFT JOIN customer c ON ct.customer_id = c.id
    WHERE a.id IS NULL OR c.id IS NULL
);

-- =====================================================
-- 10. QUERIES KIỂM TRA TỔNG QUAN
-- =====================================================

-- Xem tất cả căn hộ với thông tin chi tiết
SELECT 
    a.id,
    a.name as apartment_name,
    a.floor_area,
    a.number_of_bedrooms,
    a.number_of_bathrooms,
    FORMAT(a.min_rate, 0) as rent_formatted,
    CASE WHEN a.rented = 1 THEN 'Đã thuê' ELSE 'Còn trống' END as status,
    b.name as building_name,
    d.name as district_name,
    d.city
FROM apartment a
JOIN building b ON a.building_id = b.id
JOIN district d ON b.district_id = d.id
ORDER BY d.city, b.name, a.name;

-- Thống kê căn hộ theo thành phố và trạng thái
SELECT 
    d.city,
    COUNT(*) as total_apartments,
    SUM(CASE WHEN a.rented = 0 THEN 1 ELSE 0 END) as available,
    SUM(CASE WHEN a.rented = 1 THEN 1 ELSE 0 END) as rented,
    FORMAT(AVG(a.min_rate), 0) as avg_rent
FROM apartment a
JOIN building b ON a.building_id = b.id
JOIN district d ON b.district_id = d.id
GROUP BY d.city
ORDER BY total_apartments DESC;

-- Thống kê thiết bị theo trạng thái
SELECT 
    status,
    COUNT(*) as equipment_count,
    FORMAT(AVG(broken_fee), 0) as avg_broken_fee
FROM equipment
GROUP BY status;

-- Xem các hợp đồng đang hoạt động
SELECT 
    c.id as contract_id,
    cust.name as customer_name,
    a.name as apartment_name,
    FORMAT(c.monthly_rent, 0) as monthly_rent,
    c.start_date,
    c.end_date,
    DATEDIFF(c.end_date, CURDATE()) as days_remaining
FROM contract c
JOIN customer cust ON c.customer_id = cust.id
JOIN apartment a ON c.apartment_id = a.id
WHERE c.payment_status = 'ACTIVE' AND c.end_date >= CURDATE()
ORDER BY c.end_date;

-- =====================================================
-- 11. TEST CÁC VIEWS ĐÃ TẠO
-- =====================================================

-- Test view apartment_details
SELECT 'Testing apartment_details view:' as test_info;
SELECT * FROM apartment_details LIMIT 3;

-- Test view active_contracts
SELECT 'Testing active_contracts view:' as test_info;
SELECT contract_id, customer_name, apartment_name, monthly_rent, end_date 
FROM active_contracts;

-- Test view monthly_revenue
SELECT 'Testing monthly_revenue view:' as test_info;
SELECT year, month, total_contracts, total_monthly_rent, avg_monthly_rent 
FROM monthly_revenue LIMIT 5;

-- Test view available_apartments
SELECT 'Testing available_apartments view:' as test_info;
SELECT name, building_name, district_name, number_of_bedrooms, 
       FORMAT(min_rate, 0) as rent_formatted
FROM available_apartments 
ORDER BY min_rate ASC 
LIMIT 5;

-- Test view apartment_equipment_view
SELECT 'Testing apartment_equipment_view:' as test_info;
SELECT apartment_name, equipment_name, equipment_type, equipment_status 
FROM apartment_equipment_view 
WHERE apartment_id IN (1, 3, 6)
ORDER BY apartment_name, equipment_name;

-- Thống kê số lượng records trong views
SELECT 'View statistics:' as info;
SELECT 
    'apartment_details' as view_name, COUNT(*) as record_count FROM apartment_details
UNION ALL SELECT 'active_contracts', COUNT(*) FROM active_contracts
UNION ALL SELECT 'monthly_revenue', COUNT(*) FROM monthly_revenue
UNION ALL SELECT 'available_apartments', COUNT(*) FROM available_apartments
UNION ALL SELECT 'apartment_equipment_view', COUNT(*) FROM apartment_equipment_view;

-- =====================================================
-- 12. TEST CÁC STORED PROCEDURES VÀ FUNCTIONS
-- =====================================================

-- Test SearchApartments procedure
SELECT 'Testing SearchApartments procedure:' as test_info;
CALL SearchApartments(2, 15000000, 1, 60.0);

-- Test ManageApartmentEquipment procedure
SELECT 'Testing ManageApartmentEquipment procedure:' as test_info;
-- Thêm thiết bị vào căn hộ
CALL ManageApartmentEquipment('ADD', 1, 5, @result);
SELECT @result as add_result;

-- Xóa thiết bị khỏi căn hộ  
CALL ManageApartmentEquipment('REMOVE', 1, 5, @result);
SELECT @result as remove_result;

-- Test CreateContract procedure với căn hộ có sẵn
SELECT 'Testing CreateContract procedure:' as test_info;
CALL CreateContract(3, 1, '2025-08-01', '2026-08-01', 15000000, 30000000, @contract_id, @message);
SELECT @contract_id as new_contract_id, @message as result_message;

-- Test CalculateTotalRent function
SELECT 'Testing CalculateTotalRent function:' as test_info;
SELECT 
    c.id as contract_id,
    c.monthly_rent,
    c.start_date,
    c.end_date,
    CalculateTotalRent(c.id) as total_rent
FROM contract c
LIMIT 3;

-- Test GetApartmentStatus function
SELECT 'Testing GetApartmentStatus function:' as test_info;
SELECT 
    a.id,
    a.name,
    a.rented,
    GetApartmentStatus(a.id) as status_text
FROM apartment a
LIMIT 5;

-- =====================================================
-- 13. TEST CÁC TRIGGERS
-- =====================================================

-- Test trigger check_contract_dates với ngày không hợp lệ
SELECT 'Testing check_contract_dates trigger (should fail):' as test_info;
-- Lệnh này sẽ thất bại do trigger
-- INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit) 
-- VALUES (5, 1, '2025-12-01', '2025-06-01', 5000000, 10000000);

-- Test trigger log_equipment_status_change
SELECT 'Testing log_equipment_status_change trigger:' as test_info;
-- Thay đổi status của equipment
UPDATE equipment SET status = 'MAINTENANCE' WHERE id = 1;
UPDATE equipment SET status = 'WORKING' WHERE id = 1;

-- Kiểm tra log
SELECT * FROM equipment_status_log ORDER BY change_timestamp DESC LIMIT 3;

-- Test trigger update_apartment_rented_status
SELECT id, name, rented FROM apartment WHERE id = 5;
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit) 
VALUES (5, 3, '2025-08-01', '2026-08-01', 12000000, 24000000);
SELECT id, name, rented FROM apartment WHERE id = 5;

-- =====================================================
-- 14. STATISTICS VÀ FINAL VALIDATION
-- =====================================================

-- Thống kê toàn bộ hệ thống
SELECT 'FINAL SYSTEM STATISTICS:' as info;

-- Database objects count
SELECT 
    'Tables' as object_type, 
    COUNT(*) as count 
FROM information_schema.tables 
WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
UNION ALL
SELECT 
    'Views' as object_type, 
    COUNT(*) as count 
FROM information_schema.tables 
WHERE table_schema = DATABASE() AND table_type = 'VIEW'
UNION ALL
SELECT 
    'Procedures' as object_type, 
    COUNT(*) as count 
FROM information_schema.routines 
WHERE routine_schema = DATABASE() AND routine_type = 'PROCEDURE'
UNION ALL
SELECT 
    'Functions' as object_type, 
    COUNT(*) as count 
FROM information_schema.routines 
WHERE routine_schema = DATABASE() AND routine_type = 'FUNCTION'
UNION ALL
SELECT 
    'Triggers' as object_type, 
    COUNT(*) as count 
FROM information_schema.triggers 
WHERE trigger_schema = DATABASE();

-- Data integrity checks
SELECT 'DATA INTEGRITY CHECKS:' as info;

-- Check orphaned records
SELECT 'Orphaned apartments (no building):' as check_type,
       COUNT(*) as count
FROM apartment a
LEFT JOIN building b ON a.building_id = b.id
WHERE b.id IS NULL
UNION ALL
SELECT 'Orphaned contracts (no apartment/customer):' as check_type,
       COUNT(*) as count
FROM contract c
LEFT JOIN apartment a ON c.apartment_id = a.id
LEFT JOIN customer cust ON c.customer_id = cust.id
WHERE a.id IS NULL OR cust.id IS NULL
UNION ALL
SELECT 'Inconsistent apartment rented status:' as check_type,
       COUNT(*) as count
FROM apartment a
LEFT JOIN contract c ON a.id = c.apartment_id AND c.payment_status = 'ACTIVE'
WHERE (a.rented = 1 AND c.id IS NULL) OR (a.rented = 0 AND c.id IS NOT NULL);

-- Business metrics
SELECT 'BUSINESS METRICS:' as info;
SELECT 
    'Total available apartments' as metric,
    COUNT(*) as value
FROM apartment WHERE rented = 0
UNION ALL
SELECT 
    'Total rented apartments' as metric,
    COUNT(*) as value
FROM apartment WHERE rented = 1
UNION ALL
SELECT 
    'Active contracts' as metric,
    COUNT(*) as value
FROM contract WHERE payment_status = 'ACTIVE'
UNION ALL
SELECT 
    'Total monthly revenue' as metric,
    COALESCE(SUM(monthly_rent), 0) as value
FROM contract WHERE payment_status = 'ACTIVE'
UNION ALL
SELECT 
    'Average rent per apartment' as metric,
    COALESCE(AVG(min_rate), 0) as value
FROM apartment;

-- =====================================================
-- BACKUP AND RECOVERY SETUP
-- =====================================================

-- Create backup user
CREATE USER 'apt_backup'@'localhost' IDENTIFIED BY 'BackupPass123!@#';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON apartment_db.* TO 'apt_backup'@'localhost';
GRANT RELOAD, PROCESS ON *.* TO 'apt_backup'@'localhost';
FLUSH PRIVILEGES;

-- Create backup log table
CREATE TABLE backup_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    backup_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    backup_file VARCHAR(255),
    backup_size_mb DECIMAL(10,2),
    backup_status ENUM('SUCCESS', 'FAILED'),
    validation_status ENUM('VALID', 'INVALID', 'NOT_TESTED'),
    notes TEXT
);

-- Insert sample backup log
INSERT INTO backup_log (backup_file, backup_size_mb, backup_status, validation_status, notes) 
VALUES ('apartment_db_backup_20250612_103045.sql.gz', 156.5, 'SUCCESS', 'VALID', 'Full backup completed successfully');

-- =====================================================
-- BACKUP COMMANDS (Run in terminal)
-- =====================================================

/*
-- Full backup command (run in terminal):
mysqldump -u apt_backup -p --single-transaction --routines --triggers --events apartment_db > apartment_db_full_backup.sql

-- Schema only backup:
mysqldump -u apt_backup -p --no-data --routines --triggers apartment_db > apartment_db_schema_only.sql

-- Data only backup:
mysqldump -u apt_backup -p --no-create-info --skip-triggers apartment_db > apartment_db_data_only.sql

-- Restore command:
mysql -u root -p apartment_db_test < apartment_db_full_backup.sql

-- Backup validation:
mysql -u root -p -e "CREATE DATABASE apartment_db_validation"
mysql -u root -p apartment_db_validation < apartment_db_full_backup.sql
mysql -u root -p -e "DROP DATABASE apartment_db_validation"
*/

-- Check backup grants
SHOW GRANTS FOR 'apt_backup'@'localhost';

-- =====================================================
-- KẾT QUẢ: HỆ THỐNG HOÀN CHỈNH
-- - 62 records trong 8 bảng chính
-- - 5 views
-- - 3 stored procedures  
-- - 2 functions
-- - 3 triggers
-- - 1 log table
-- =====================================================
