-- =====================================================
-- HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU MYSQL - CĂN HỘ APARTMENT
-- File SQL Hoàn Chỉnh - Chạy Lần Lượt Theo Thứ Tự
-- =====================================================

-- =====================================================
-- BƯỚC 1: TẠO VÀ SỬ DỤNG DATABASE
-- =====================================================

-- Tạo database
CREATE DATABASE IF NOT EXISTS apartment_db1 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

-- Sử dụng database
USE apartment_db1;

-- =====================================================
-- BƯỚC 2: TẠO CÁC BẢNG CHÍNH (TABLES)
-- =====================================================

-- Bảng user_account (bảng gốc, không phụ thuộc bảng nào)
CREATE TABLE user_account (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_name VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_user_account_username (user_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng district (bảng gốc, không phụ thuộc bảng nào)
CREATE TABLE district (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(255),
    city VARCHAR(255),
    region VARCHAR(255),
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng equipment (bảng gốc, không phụ thuộc bảng nào)
CREATE TABLE equipment (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(255),
    status VARCHAR(255),
    broken_fee DOUBLE PRECISION,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng customer (phụ thuộc user_account)
CREATE TABLE customer (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone_number VARCHAR(255),
    user_account_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_customer_user_account 
        FOREIGN KEY (user_account_id) 
        REFERENCES user_account (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng building (phụ thuộc district)
CREATE TABLE building (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255),
    contact_number VARCHAR(255),
    number_of_floors INTEGER,
    total_area DOUBLE PRECISION,
    type VARCHAR(255),
    district_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_building_district 
        FOREIGN KEY (district_id) 
        REFERENCES district (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng apartment (phụ thuộc building)
CREATE TABLE apartment (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    floor_area DOUBLE PRECISION,
    number_of_bedrooms INTEGER,
    number_of_bathrooms INTEGER,
    min_rate DOUBLE PRECISION,
    rented BIT DEFAULT 0,
    move_in_date DATETIME,
    move_out_date DATETIME,
    building_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_apartment_building 
        FOREIGN KEY (building_id) 
        REFERENCES building (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng apartment_equipment (bảng trung gian, phụ thuộc apartment và equipment)
CREATE TABLE apartment_equipment (
    id BIGINT NOT NULL AUTO_INCREMENT,
    apartment_id BIGINT NOT NULL,
    equipment_id BIGINT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_apartment_equipment (apartment_id, equipment_id),
    CONSTRAINT fk_apartment_equipment_apartment 
        FOREIGN KEY (apartment_id) 
        REFERENCES apartment (id),
    CONSTRAINT fk_apartment_equipment_equipment 
        FOREIGN KEY (equipment_id) 
        REFERENCES equipment (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng contract (phụ thuộc apartment và customer)
CREATE TABLE contract (
    id BIGINT NOT NULL AUTO_INCREMENT,
    apartment_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    monthly_rent DOUBLE PRECISION NOT NULL,
    deposit DOUBLE PRECISION,
    payment_status VARCHAR(255) DEFAULT 'ACTIVE',
    PRIMARY KEY (id),
    CONSTRAINT fk_contract_apartment 
        FOREIGN KEY (apartment_id) 
        REFERENCES apartment (id),
    CONSTRAINT fk_contract_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customer (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng log cho equipment status changes (bảng phụ trợ)
CREATE TABLE equipment_status_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    equipment_id BIGINT,
    old_status VARCHAR(255),
    new_status VARCHAR(255),
    change_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(255),
    CONSTRAINT fk_equipment_status_log_equipment 
        FOREIGN KEY (equipment_id) 
        REFERENCES equipment (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng backup log (bảng phụ trợ)
CREATE TABLE backup_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    backup_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    backup_file VARCHAR(255),
    backup_size_mb DECIMAL(10,2),
    backup_status ENUM('SUCCESS', 'FAILED'),
    validation_status ENUM('VALID', 'INVALID', 'NOT_TESTED'),
    notes TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- BƯỚC 3: TẠO CÁC VIEWS
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

-- =====================================================
-- BƯỚC 4: TẠO CÁC STORED PROCEDURES
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

-- =====================================================
-- BƯỚC 5: TẠO CÁC FUNCTIONS
-- =====================================================

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

-- =====================================================
-- BƯỚC 6: TẠO CÁC TRIGGERS
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

-- =====================================================
-- BƯỚC 7: INSERT DỮ LIỆU MẪU
-- =====================================================

-- 7.1. INSERT DỮ LIỆU BẢNG USER_ACCOUNT
INSERT INTO user_account (user_name, password, role) VALUES
('admin', 'admin123', 'ADMIN'),
('manager1', 'manager123', 'MANAGER'),
('staff1', 'staff123', 'STAFF'),
('customer1', 'customer123', 'CUSTOMER'),
('customer2', 'customer456', 'CUSTOMER'),
('customer3', 'customer789', 'CUSTOMER');

-- 7.2. INSERT DỮ LIỆU BẢNG CUSTOMER
INSERT INTO customer (name, email, phone_number, user_account_id) VALUES
('Nguyễn Văn A', 'nguyenvana@email.com', '0901234567', 4),
('Trần Thị B', 'tranthib@email.com', '0987654321', 5),
('Lê Văn C', 'levanc@email.com', '0123456789', 6);

-- 7.3. INSERT DỮ LIỆU BẢNG DISTRICT
INSERT INTO district (name, code, city, region) VALUES
('Quận 1', 'Q1', 'Hồ Chí Minh', 'Miền Nam'),
('Quận 3', 'Q3', 'Hồ Chí Minh', 'Miền Nam'),
('Quận Ba Đình', 'BD', 'Hà Nội', 'Miền Bắc'),
('Quận Hoàn Kiếm', 'HK', 'Hà Nội', 'Miền Bắc'),
('Quận Hải Châu', 'HC', 'Đà Nẵng', 'Miền Trung');

-- 7.4. INSERT DỮ LIỆU BẢNG BUILDING
INSERT INTO building (name, address, contact_number, number_of_floors, total_area, type, district_id) VALUES
('Vinhomes Central Park', '208 Nguyễn Hữu Cảnh', '02839101010', 45, 15000.0, 'APARTMENT', 1),
('Bitexco Financial Tower', '2 Hải Triều', '02838234567', 68, 12000.0, 'OFFICE', 1),
('Saigon Pearl', '92 Nguyễn Hữu Cảnh', '02839102020', 40, 18000.0, 'APARTMENT', 1),
('Lotte Center Hanoi', '54 Liễu Giai', '02438315000', 65, 20000.0, 'MIXED', 3),
('Hanoi Towers', '49 Hai Bà Trưng', '02439364636', 25, 8000.0, 'APARTMENT', 4);

-- 7.5. INSERT DỮ LIỆU BẢNG APARTMENT
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

-- 7.6. INSERT DỮ LIỆU BẢNG EQUIPMENT
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

-- 7.7. INSERT DỮ LIỆU BẢNG APARTMENT_EQUIPMENT
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

-- 7.8. INSERT DỮ LIỆU BẢNG CONTRACT
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) VALUES
(2, 1, '2025-01-15', '2026-01-15', 9500000, 19000000, 'ACTIVE'),
(4, 2, '2025-03-01', '2025-09-01', 7200000, 14400000, 'COMPLETED'),
(7, 3, '2025-05-10', '2026-05-10', 11000000, 22000000, 'ACTIVE');

-- =====================================================
-- BƯỚC 8: TẠO USER BACKUP VÀ PHÂN QUYỀN
-- =====================================================

-- Tạo backup user
CREATE USER IF NOT EXISTS 'apt_backup'@'localhost' IDENTIFIED BY 'BackupPass123!@#';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON apartment_db.* TO 'apt_backup'@'localhost';
GRANT RELOAD, PROCESS ON *.* TO 'apt_backup'@'localhost';
FLUSH PRIVILEGES;

-- Insert sample backup log
INSERT INTO backup_log (backup_file, backup_size_mb, backup_status, validation_status, notes) 
VALUES ('apartment_db_backup_20250625_103045.sql.gz', 156.5, 'SUCCESS', 'VALID', 'Full backup completed successfully');

-- =====================================================
-- BƯỚC 9: QUERIES KIỂM TRA VÀ THỐNG KÊ
-- =====================================================

-- 9.1. Kiểm tra số lượng records trong từng bảng
SELECT 'SYSTEM OVERVIEW - Records Count:' as info;
SELECT 
    'user_account' as table_name, COUNT(*) as record_count FROM user_account
UNION ALL SELECT 'customer', COUNT(*) FROM customer
UNION ALL SELECT 'district', COUNT(*) FROM district
UNION ALL SELECT 'building', COUNT(*) FROM building
UNION ALL SELECT 'apartment', COUNT(*) FROM apartment
UNION ALL SELECT 'equipment', COUNT(*) FROM equipment
UNION ALL SELECT 'apartment_equipment', COUNT(*) FROM apartment_equipment
UNION ALL SELECT 'contract', COUNT(*) FROM contract;

-- 9.2. Kiểm tra views đã tạo
SELECT 'Database Views:' as info;
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- 9.3. Kiểm tra procedures và functions
SELECT 'Stored Procedures:' as info;
SHOW PROCEDURE STATUS WHERE Db = DATABASE();

SELECT 'Functions:' as info;
SHOW FUNCTION STATUS WHERE Db = DATABASE();

-- 9.4. Kiểm tra triggers
SELECT 'Triggers:' as info;
SHOW TRIGGERS;

-- 9.5. Xem tất cả căn hộ với thông tin chi tiết
SELECT 'All Apartments Overview:' as info;
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

-- 9.6. Thống kê căn hộ theo thành phố
SELECT 'Apartments Statistics by City:' as info;
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

-- 9.7. Kiểm tra contracts với thông tin đầy đủ
SELECT 'Active Contracts:' as info;
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

-- 9.8. Test các views
SELECT 'Testing Views:' as info;

-- Test view apartment_details
SELECT 'apartment_details view sample:' as view_name;
SELECT apartment_name, building_name, district_name, city, number_of_bedrooms, min_rate
FROM apartment_details LIMIT 3;

-- Test view available_apartments
SELECT 'available_apartments view:' as view_name;
SELECT name, building_name, district_name, number_of_bedrooms, FORMAT(min_rate, 0) as rent_formatted
FROM available_apartments ORDER BY min_rate ASC LIMIT 5;

-- =====================================================
-- BƯỚC 10: FINAL VALIDATION VÀ SUMMARY
-- =====================================================

-- 10.1. Data integrity checks
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
WHERE a.id IS NULL OR cust.id IS NULL;

-- 10.2. Business metrics
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

-- 10.3. Database objects summary
SELECT 'DATABASE OBJECTS SUMMARY:' as info;
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

-- =====================================================
-- KẾT THÚC: HỆ THỐNG ĐÃ ĐƯỢC THIẾT LẬP HOÀN CHỈNH
-- 
-- HỆ THỐNG BAO GỒM:
-- - 10 Tables (8 chính + 2 phụ trợ)
-- - 5 Views
-- - 3 Stored Procedures
-- - 2 Functions  
-- - 3 Triggers
-- - 62 records dữ liệu mẫu
-- - User backup với phân quyền
-- - Kiểm tra tính toàn vẹn dữ liệu
-- =====================================================

-- mysql -u root -p -e "SOURCE /workspaces/hqtcsdl/complete_apartment_database.sql;"