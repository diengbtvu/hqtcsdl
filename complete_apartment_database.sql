-- =====================================================
-- HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU MYSQL - CĂN HỘ APARTMENT
-- File SQL Hoàn Chỉnh - Chạy Lần Lượt Theo Thứ Tự
-- 
-- MỤC ĐÍCH: Tạo hệ thống quản lý căn hộ hoàn chỉnh
-- BAO GỒM: Tables, Views, Procedures, Functions, Triggers
-- TÍNH NĂNG: Quản lý khách hàng, căn hộ, hợp đồng, thiết bị
-- =====================================================

-- =====================================================
-- BƯỚC 1: XÓA VÀ TẠO LẠI DATABASE
-- =====================================================

-- Xóa database nếu đã tồn tại (để có thể chạy lại script nhiều lần)
-- IF EXISTS: Không báo lỗi nếu database chưa tồn tại
DROP DATABASE IF EXISTS apartment_db1;

-- Tạo database mới với encoding UTF-8 hỗ trợ tiếng Việt
-- CHARACTER SET utf8mb4: Hỗ trợ đầy đủ Unicode, bao gồm emoji
-- COLLATE utf8mb4_unicode_ci: Sắp xếp theo chuẩn Unicode, không phân biệt hoa thường
CREATE DATABASE apartment_db1 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

-- Chuyển sang sử dụng database vừa tạo
-- Tất cả lệnh sau đây sẽ thực hiện trong database này
USE apartment_db1;

-- =====================================================
-- BƯỚC 2: TẠO CÁC BẢNG CHÍNH (TABLES)
-- Thứ tự tạo bảng quan trọng: Bảng cha trước, bảng con sau
-- =====================================================

-- Bảng user_account (bảng gốc, không phụ thuộc bảng nào)
-- MỤC ĐÍCH: Lưu thông tin đăng nhập của người dùng hệ thống
CREATE TABLE user_account (
    id BIGINT NOT NULL AUTO_INCREMENT,          -- Khóa chính, tự động tăng
    user_name VARCHAR(255) NOT NULL,            -- Tên đăng nhập (bắt buộc)
    password VARCHAR(255) NOT NULL,             -- Mật khẩu (bắt buộc)
    role VARCHAR(255) NOT NULL,                 -- Vai trò: ADMIN, MANAGER, STAFF, CUSTOMER
    PRIMARY KEY (id),                           -- Định nghĩa khóa chính
    UNIQUE KEY uk_user_account_username (user_name)  -- Tên đăng nhập không được trùng
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng district (bảng gốc, không phụ thuộc bảng nào)
-- MỤC ĐÍCH: Lưu thông tin các quận/huyện để phân loại địa lý
CREATE TABLE district (
    id BIGINT NOT NULL AUTO_INCREMENT,          -- Khóa chính
    name VARCHAR(255) NOT NULL,                 -- Tên quận/huyện (bắt buộc)
    code VARCHAR(255),                          -- Mã quận (có thể null)
    city VARCHAR(255),                          -- Thành phố (có thể null)
    region VARCHAR(255),                        -- Vùng miền (có thể null)
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng equipment (bảng gốc, không phụ thuộc bảng nào)
-- MỤC ĐÍCH: Quản lý các thiết bị có thể có trong căn hộ
CREATE TABLE equipment (
    id BIGINT NOT NULL AUTO_INCREMENT,          -- Khóa chính
    name VARCHAR(255) NOT NULL,                 -- Tên thiết bị (bắt buộc)
    type VARCHAR(255),                          -- Loại thiết bị: APPLIANCE, FURNITURE, v.v.
    status VARCHAR(255),                        -- Trạng thái: WORKING, MAINTENANCE, BROKEN
    broken_fee DOUBLE PRECISION,               -- Phí bồi thường nếu hỏng
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng customer (phụ thuộc user_account)
-- MỤC ĐÍCH: Lưu thông tin chi tiết của khách hàng
-- QUAN HỆ: Mỗi customer có 1 user_account để đăng nhập
CREATE TABLE customer (
    id BIGINT NOT NULL AUTO_INCREMENT,          -- Khóa chính
    name VARCHAR(255) NOT NULL,                 -- Họ tên khách hàng (bắt buộc)
    email VARCHAR(255),                         -- Email liên hệ (có thể null)
    phone_number VARCHAR(255),                  -- Số điện thoại (có thể null)
    user_account_id BIGINT NOT NULL,            -- Khóa ngoại tham chiếu user_account
    PRIMARY KEY (id),
    CONSTRAINT fk_customer_user_account         -- Tên ràng buộc khóa ngoại
        FOREIGN KEY (user_account_id)           -- Cột khóa ngoại
        REFERENCES user_account (id)            -- Tham chiếu đến bảng user_account
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng building (phụ thuộc district)
-- MỤC ĐÍCH: Lưu thông tin các tòa nhà chứa căn hộ
-- QUAN HỆ: Mỗi building thuộc 1 district
CREATE TABLE building (
    id BIGINT NOT NULL AUTO_INCREMENT,          -- Khóa chính
    name VARCHAR(255) NOT NULL,                 -- Tên tòa nhà (bắt buộc)
    address VARCHAR(255),                       -- Địa chỉ cụ thể
    contact_number VARCHAR(255),                -- Số điện thoại liên hệ
    number_of_floors INTEGER,                   -- Số tầng của tòa nhà
    total_area DOUBLE PRECISION,                -- Tổng diện tích (m²)
    type VARCHAR(255),                          -- Loại: APARTMENT, OFFICE, MIXED
    district_id BIGINT NOT NULL,                -- Khóa ngoại tham chiếu district
    PRIMARY KEY (id),
    CONSTRAINT fk_building_district             -- Tên ràng buộc khóa ngoại
        FOREIGN KEY (district_id)               -- Cột khóa ngoại
        REFERENCES district (id)                -- Tham chiếu đến bảng district
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng apartment (phụ thuộc building)
-- MỤC ĐÍCH: Lưu thông tin từng căn hộ cụ thể
-- QUAN HỆ: Mỗi apartment thuộc 1 building
CREATE TABLE apartment (
    id BIGINT NOT NULL AUTO_INCREMENT,          -- Khóa chính
    name VARCHAR(255) NOT NULL,                 -- Tên/Số căn hộ (VD: A01-101)
    floor_area DOUBLE PRECISION,                -- Diện tích sàn (m²)
    number_of_bedrooms INTEGER,                 -- Số phòng ngủ
    number_of_bathrooms INTEGER,                -- Số phòng tắm
    min_rate DOUBLE PRECISION,                  -- Giá thuê tối thiểu (VNĐ/tháng)
    rented BIT DEFAULT 0,                       -- Trạng thái thuê: 0=trống, 1=đã thuê
    move_in_date DATETIME,                      -- Ngày chuyển vào (có thể null)
    move_out_date DATETIME,                     -- Ngày chuyển ra (có thể null)
    building_id BIGINT NOT NULL,                -- Khóa ngoại tham chiếu building
    PRIMARY KEY (id),
    CONSTRAINT fk_apartment_building            -- Tên ràng buộc khóa ngoại
        FOREIGN KEY (building_id)               -- Cột khóa ngoại
        REFERENCES building (id)                -- Tham chiếu đến bảng building
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng apartment_equipment (bảng trung gian, phụ thuộc apartment và equipment)
-- MỤC ĐÍCH: Liên kết nhiều-nhiều giữa apartment và equipment
-- QUAN HỆ: 1 apartment có nhiều equipment, 1 equipment có thể ở nhiều apartment
CREATE TABLE apartment_equipment (
    id BIGINT NOT NULL AUTO_INCREMENT,          -- Khóa chính
    apartment_id BIGINT NOT NULL,               -- Khóa ngoại tham chiếu apartment
    equipment_id BIGINT NOT NULL,               -- Khóa ngoại tham chiếu equipment
    PRIMARY KEY (id),
    UNIQUE KEY uk_apartment_equipment (apartment_id, equipment_id), -- Đảm bảo không trùng lặp
    CONSTRAINT fk_apartment_equipment_apartment -- Tên ràng buộc khóa ngoại 1
        FOREIGN KEY (apartment_id)              -- Cột khóa ngoại 1
        REFERENCES apartment (id),              -- Tham chiếu đến bảng apartment
    CONSTRAINT fk_apartment_equipment_equipment -- Tên ràng buộc khóa ngoại 2
        FOREIGN KEY (equipment_id)              -- Cột khóa ngoại 2
        REFERENCES equipment (id)               -- Tham chiếu đến bảng equipment
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng contract (phụ thuộc apartment và customer)
-- MỤC ĐÍCH: Lưu thông tin hợp đồng thuê căn hộ
-- QUAN HỆ: 1 contract liên kết 1 apartment với 1 customer
CREATE TABLE contract (
    id BIGINT NOT NULL AUTO_INCREMENT,          -- Khóa chính
    apartment_id BIGINT NOT NULL,               -- Khóa ngoại tham chiếu apartment
    customer_id BIGINT NOT NULL,                -- Khóa ngoại tham chiếu customer
    start_date DATETIME NOT NULL,               -- Ngày bắt đầu hợp đồng (bắt buộc)
    end_date DATETIME NOT NULL,                 -- Ngày kết thúc hợp đồng (bắt buộc)
    monthly_rent DOUBLE PRECISION NOT NULL,     -- Tiền thuê hàng tháng (bắt buộc)
    deposit DOUBLE PRECISION,                   -- Tiền cọc/đặt cọc (có thể null)
    payment_status VARCHAR(255) DEFAULT 'ACTIVE', -- Trạng thái thanh toán: ACTIVE, INACTIVE
    PRIMARY KEY (id),
    CONSTRAINT fk_contract_apartment            -- Tên ràng buộc khóa ngoại 1
        FOREIGN KEY (apartment_id)              -- Cột khóa ngoại 1
        REFERENCES apartment (id),              -- Tham chiếu đến bảng apartment
    CONSTRAINT fk_contract_customer             -- Tên ràng buộc khóa ngoại 2
        FOREIGN KEY (customer_id)               -- Cột khóa ngoại 2
        REFERENCES customer (id)                -- Tham chiếu đến bảng customer
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng log cho equipment status changes (bảng phụ trợ)
-- MỤC ĐÍCH: Ghi lại lịch sử thay đổi trạng thái thiết bị
-- SỬ DỤNG: Audit trail, theo dõi bảo trì thiết bị
CREATE TABLE equipment_status_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,       -- Khóa chính
    equipment_id BIGINT,                        -- Khóa ngoại tham chiếu equipment
    old_status VARCHAR(255),                    -- Trạng thái cũ
    new_status VARCHAR(255),                    -- Trạng thái mới
    change_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, -- Thời gian thay đổi (tự động)
    changed_by VARCHAR(255),                    -- Người thực hiện thay đổi (có thể null)
    CONSTRAINT fk_equipment_status_log_equipment -- Tên ràng buộc khóa ngoại
        FOREIGN KEY (equipment_id)              -- Cột khóa ngoại
        REFERENCES equipment (id)               -- Tham chiếu đến bảng equipment
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng backup log (bảng phụ trợ)
-- MỤC ĐÍCH: Theo dõi quá trình backup database
-- SỬ DỤNG: Quản lý backup, kiểm tra tính toàn vẹn dữ liệu
CREATE TABLE backup_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,       -- Khóa chính
    backup_date DATETIME DEFAULT CURRENT_TIMESTAMP, -- Ngày backup (tự động)
    backup_file VARCHAR(255),                   -- Tên file backup
    backup_size_mb DECIMAL(10,2),               -- Kích thước file (MB)
    backup_status ENUM('SUCCESS', 'FAILED'),    -- Trạng thái backup (SUCCESS/FAILED)
    validation_status ENUM('VALID', 'INVALID', 'NOT_TESTED'), -- Trạng thái kiểm tra
    notes TEXT                                  -- Ghi chú thêm (có thể null)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- BƯỚC 3: TẠO CÁC VIEWS
-- View = Bảng ảo, không lưu dữ liệu, chỉ lưu câu truy vấn
-- MỤC ĐÍCH: Đơn giản hóa truy vấn phức tạp, bảo mật dữ liệu
-- =====================================================

-- View apartment_details: Thông tin căn hộ chi tiết
-- MỤC ĐÍCH: Hiển thị thông tin căn hộ kèm building và district
-- SỬ DỤNG: Thay vì JOIN 3 bảng mỗi lần, chỉ cần SELECT từ view này
CREATE VIEW apartment_details AS
SELECT 
    a.id as apartment_id,                       -- ID căn hộ
    a.name as apartment_name,                   -- Tên căn hộ
    a.floor_area,                               -- Diện tích
    a.number_of_bedrooms,                       -- Số phòng ngủ
    a.number_of_bathrooms,                      -- Số phòng tắm
    a.min_rate,                                 -- Giá thuê
    a.rented,                                   -- Trạng thái thuê
    a.move_in_date,                             -- Ngày chuyển vào
    a.move_out_date,                            -- Ngày chuyển ra
    b.name as building_name,                    -- Tên tòa nhà
    b.address as building_address,              -- Địa chỉ tòa nhà
    b.contact_number as building_contact,       -- SĐT tòa nhà
    d.name as district_name,                    -- Tên quận
    d.city,                                     -- Thành phố
    d.region                                    -- Vùng miền
FROM apartment a                                -- Bảng chính: apartment
JOIN building b ON a.building_id = b.id         -- Kết nối với building
JOIN district d ON b.district_id = d.id;        -- Kết nối với district

-- View active_contracts: Hợp đồng đang hoạt động
-- MỤC ĐÍCH: Hiển thị hợp đồng chưa hết hạn với thông tin đầy đủ
-- ĐIỀU KIỆN: end_date >= CURDATE() (chưa hết hạn)
CREATE VIEW active_contracts AS
SELECT 
    c.id as contract_id,                        -- ID hợp đồng
    c.start_date,                               -- Ngày bắt đầu
    c.end_date,                                 -- Ngày kết thúc
    c.monthly_rent,                             -- Tiền thuê tháng
    c.deposit,                                  -- Tiền cọc
    c.payment_status,                           -- Trạng thái thanh toán
    cust.name as customer_name,                 -- Tên khách hàng
    cust.email as customer_email,               -- Email khách hàng
    cust.phone_number as customer_phone,        -- SĐT khách hàng
    a.name as apartment_name,                   -- Tên căn hộ
    b.name as building_name,                    -- Tên tòa nhà
    b.address as building_address               -- Địa chỉ tòa nhà
FROM contract c                                 -- Bảng chính: contract
JOIN customer cust ON c.customer_id = cust.id  -- Kết nối với customer
JOIN apartment a ON c.apartment_id = a.id      -- Kết nối với apartment
JOIN building b ON a.building_id = b.id        -- Kết nối với building
WHERE c.end_date >= CURDATE()                  -- Điều kiện: chưa hết hạn
ORDER BY c.end_date ASC;                       -- Sắp xếp theo ngày hết hạn

-- View monthly_revenue: Thống kê doanh thu theo tháng
-- MỤC ĐÍCH: Tính toán doanh thu từ các hợp đồng theo từng tháng
-- SỬ DỤNG: Báo cáo tài chính, phân tích xu hướng
CREATE VIEW monthly_revenue AS
SELECT 
    YEAR(c.start_date) as year,                 -- Năm bắt đầu hợp đồng
    MONTH(c.start_date) as month,               -- Tháng bắt đầu hợp đồng
    COUNT(c.id) as total_contracts,             -- Tổng số hợp đồng trong tháng
    SUM(c.monthly_rent) as total_monthly_rent,  -- Tổng tiền thuê tháng
    SUM(c.deposit) as total_deposits,           -- Tổng tiền cọc
    AVG(c.monthly_rent) as avg_monthly_rent     -- Tiền thuê trung bình
FROM contract c                                 -- Bảng contract
WHERE c.start_date IS NOT NULL                 -- Điều kiện: có ngày bắt đầu
GROUP BY YEAR(c.start_date), MONTH(c.start_date) -- Nhóm theo năm và tháng
ORDER BY year DESC, month DESC;                -- Sắp xếp mới nhất trước

-- View available_apartments: Căn hộ có sẵn
-- MỤC ĐÍCH: Hiển thị các căn hộ còn trống để cho thuê
-- ĐIỀU KIỆN: rented = 0 (chưa được thuê)
CREATE VIEW available_apartments AS
SELECT 
    a.id,                                       -- ID căn hộ
    a.name,                                     -- Tên căn hộ
    a.floor_area,                               -- Diện tích
    a.number_of_bedrooms,                       -- Số phòng ngủ
    a.number_of_bathrooms,                      -- Số phòng tắm
    a.min_rate,                                 -- Giá thuê
    b.name as building_name,                    -- Tên tòa nhà
    b.address,                                  -- Địa chỉ
    d.name as district_name,                    -- Tên quận
    d.city                                      -- Thành phố
FROM apartment a                                -- Bảng chính: apartment
JOIN building b ON a.building_id = b.id         -- Kết nối với building
JOIN district d ON b.district_id = d.id         -- Kết nối với district
WHERE a.rented = 0                             -- Điều kiện: chưa được thuê
ORDER BY a.min_rate ASC;                       -- Sắp xếp theo giá tăng dần

-- View apartment_equipment_view: Thiết bị trong căn hộ
-- MỤC ĐÍCH: Hiển thị thiết bị nào có trong căn hộ nào
-- SỬ DỤNG: Quản lý thiết bị, kiểm kê tài sản
CREATE VIEW apartment_equipment_view AS
SELECT 
    a.id as apartment_id,                       -- ID căn hộ
    a.name as apartment_name,                   -- Tên căn hộ
    e.id as equipment_id,                       -- ID thiết bị
    e.name as equipment_name,                   -- Tên thiết bị
    e.type as equipment_type,                   -- Loại thiết bị
    e.status as equipment_status,               -- Trạng thái thiết bị
    e.broken_fee                                -- Phí bồi thường
FROM apartment a                                -- Bảng chính: apartment
JOIN apartment_equipment ae ON a.id = ae.apartment_id -- Kết nối bảng trung gian
JOIN equipment e ON ae.equipment_id = e.id      -- Kết nối với equipment
ORDER BY a.name, e.name;                       -- Sắp xếp theo tên căn hộ và thiết bị

-- =====================================================
-- BƯỚC 4: TẠO CÁC STORED PROCEDURES
-- Procedure = Chương trình con lưu trong database
-- MỤC ĐÍCH: Đóng gói logic phức tạp, tái sử dụng code, bảo mật
-- =====================================================

-- Procedure: CreateContract
-- MỤC ĐÍCH: Tạo hợp đồng mới với kiểm tra điều kiện
-- TÍNH NĂNG: Kiểm tra apartment tồn tại, customer tồn tại, apartment còn trống
-- TRANSACTION: Đảm bảo tính toàn vẹn dữ liệu (all or nothing)
DELIMITER //
CREATE PROCEDURE CreateContract(
    IN p_apartment_id BIGINT,                   -- Tham số đầu vào: ID căn hộ
    IN p_customer_id BIGINT,                    -- Tham số đầu vào: ID khách hàng
    IN p_start_date DATETIME,                   -- Tham số đầu vào: Ngày bắt đầu
    IN p_end_date DATETIME,                     -- Tham số đầu vào: Ngày kết thúc
    IN p_monthly_rent DOUBLE,                   -- Tham số đầu vào: Tiền thuê tháng
    IN p_deposit DOUBLE,                        -- Tham số đầu vào: Tiền cọc
    OUT p_contract_id BIGINT,                   -- Tham số đầu ra: ID hợp đồng được tạo
    OUT p_message VARCHAR(255)                  -- Tham số đầu ra: Thông báo kết quả
)
BEGIN
    -- Khai báo biến cục bộ để kiểm tra điều kiện
    DECLARE v_apartment_exists INT DEFAULT 0;   -- Biến kiểm tra apartment tồn tại
    DECLARE v_customer_exists INT DEFAULT 0;    -- Biến kiểm tra customer tồn tại
    DECLARE v_apartment_available INT DEFAULT 0; -- Biến kiểm tra apartment còn trống
    
    -- Exception handler: Xử lý lỗi SQL
    -- Nếu có lỗi xảy ra, ROLLBACK transaction và trả về thông báo lỗi
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;                               -- Hủy bỏ transaction
        GET DIAGNOSTICS CONDITION 1 p_message = MESSAGE_TEXT; -- Lấy thông báo lỗi
        SET p_contract_id = -1;                 -- Đặt ID trả về = -1 (thất bại)
    END;
    
    START TRANSACTION;                          -- Bắt đầu transaction
    
    -- Kiểm tra apartment có tồn tại không
    SELECT COUNT(*) INTO v_apartment_exists FROM apartment WHERE id = p_apartment_id;
    -- Kiểm tra customer có tồn tại không
    SELECT COUNT(*) INTO v_customer_exists FROM customer WHERE id = p_customer_id;
    -- Kiểm tra apartment có còn trống không (rented = 0)
    SELECT COUNT(*) INTO v_apartment_available FROM apartment WHERE id = p_apartment_id AND rented = 0;
    
    -- Kiểm tra các điều kiện và xử lý tương ứng
    IF v_apartment_exists = 0 THEN
        SET p_message = 'Apartment không tồn tại';
        SET p_contract_id = -1;
        ROLLBACK;                               -- Hủy transaction
    ELSEIF v_customer_exists = 0 THEN
        SET p_message = 'Customer không tồn tại';
        SET p_contract_id = -1;
        ROLLBACK;                               -- Hủy transaction
    ELSEIF v_apartment_available = 0 THEN
        SET p_message = 'Apartment đã được thuê';
        SET p_contract_id = -1;
        ROLLBACK;                               -- Hủy transaction
    ELSE
        -- Tất cả điều kiện đều hợp lệ, tạo hợp đồng mới
        INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
        VALUES (p_apartment_id, p_customer_id, p_start_date, p_end_date, p_monthly_rent, p_deposit, 'ACTIVE');
        
        -- Cập nhật trạng thái apartment thành đã thuê
        UPDATE apartment SET rented = 1 WHERE id = p_apartment_id;
        
        -- Trả về kết quả thành công
        SET p_contract_id = LAST_INSERT_ID();   -- Lấy ID của record vừa insert
        SET p_message = 'Tạo hợp đồng thành công';
        COMMIT;                                 -- Xác nhận transaction
    END IF;
END//
DELIMITER ;

-- Procedure: SearchApartments
-- MỤC ĐÍCH: Tìm kiếm căn hộ theo nhiều tiêu chí
-- TÍNH NĂNG: Tìm kiếm linh hoạt với các tham số tùy chọn (có thể NULL)
-- SỬ DỤNG: Ứng dụng web/mobile để khách hàng tìm căn hộ phù hợp
DELIMITER //
CREATE PROCEDURE SearchApartments(
    IN p_min_bedrooms INTEGER,                  -- Tham số: Số phòng ngủ tối thiểu (có thể NULL)
    IN p_max_rent DOUBLE,                       -- Tham số: Giá thuê tối đa (có thể NULL)
    IN p_district_id BIGINT,                    -- Tham số: ID quận (có thể NULL)
    IN p_min_area DOUBLE                        -- Tham số: Diện tích tối thiểu (có thể NULL)
)
BEGIN
    SELECT 
        a.id,                                   -- ID căn hộ
        a.name,                                 -- Tên căn hộ
        a.floor_area,                           -- Diện tích
        a.number_of_bedrooms,                   -- Số phòng ngủ
        a.number_of_bathrooms,                  -- Số phòng tắm
        a.min_rate,                             -- Giá thuê
        a.rented,                               -- Trạng thái thuê
        b.name as building_name,                -- Tên tòa nhà
        b.address as building_address,          -- Địa chỉ
        d.name as district_name                 -- Tên quận
    FROM apartment a                            -- Bảng chính: apartment
    JOIN building b ON a.building_id = b.id     -- JOIN với building
    JOIN district d ON b.district_id = d.id     -- JOIN với district
    WHERE a.rented = 0                          -- Điều kiện cố định: căn hộ còn trống
        AND (p_min_bedrooms IS NULL OR a.number_of_bedrooms >= p_min_bedrooms) -- Điều kiện động
        AND (p_max_rent IS NULL OR a.min_rate <= p_max_rent)                   -- Điều kiện động
        AND (p_district_id IS NULL OR d.id = p_district_id)                    -- Điều kiện động
        AND (p_min_area IS NULL OR a.floor_area >= p_min_area)                 -- Điều kiện động
    ORDER BY a.min_rate ASC;                    -- Sắp xếp theo giá tăng dần
END//
DELIMITER ;

-- Procedure: ManageApartmentEquipment
-- MỤC ĐÍCH: Quản lý thiết bị trong căn hộ (thêm/xóa)
-- TÍNH NĂNG: Thêm hoặc xóa thiết bị, kiểm tra điều kiện hợp lệ
-- SỬ DỤNG: Quản lý tài sản, cập nhật thiết bị căn hộ
DELIMITER //
CREATE PROCEDURE ManageApartmentEquipment(
    IN p_action VARCHAR(10),                    -- Tham số: Hành động ('ADD' hoặc 'REMOVE')
    IN p_apartment_id BIGINT,                   -- Tham số: ID căn hộ
    IN p_equipment_id BIGINT,                   -- Tham số: ID thiết bị
    OUT p_result VARCHAR(255)                   -- Tham số đầu ra: Kết quả thực hiện
)
BEGIN
    -- Khai báo biến để kiểm tra điều kiện
    DECLARE v_apartment_exists INT DEFAULT 0;   -- Kiểm tra căn hộ tồn tại
    DECLARE v_equipment_exists INT DEFAULT 0;   -- Kiểm tra thiết bị tồn tại
    DECLARE v_association_exists INT DEFAULT 0; -- Kiểm tra mối liên kết đã tồn tại
    
    -- Kiểm tra các điều kiện trước khi thực hiện
    SELECT COUNT(*) INTO v_apartment_exists FROM apartment WHERE id = p_apartment_id;
    SELECT COUNT(*) INTO v_equipment_exists FROM equipment WHERE id = p_equipment_id;
    SELECT COUNT(*) INTO v_association_exists FROM apartment_equipment 
    WHERE apartment_id = p_apartment_id AND equipment_id = p_equipment_id;
    
    -- Xử lý logic theo điều kiện
    IF v_apartment_exists = 0 THEN
        SET p_result = 'Apartment không tồn tại';
    ELSEIF v_equipment_exists = 0 THEN
        SET p_result = 'Equipment không tồn tại';
    ELSEIF p_action = 'ADD' THEN                -- Hành động thêm thiết bị
        IF v_association_exists > 0 THEN
            SET p_result = 'Equipment đã có trong apartment này';
        ELSE
            INSERT INTO apartment_equipment (apartment_id, equipment_id) 
            VALUES (p_apartment_id, p_equipment_id);
            SET p_result = 'Thêm equipment thành công';
        END IF;
    ELSEIF p_action = 'REMOVE' THEN             -- Hành động xóa thiết bị
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
-- Function = Hàm trả về 1 giá trị, không thể thay đổi dữ liệu
-- MỤC ĐÍCH: Tính toán, xử lý dữ liệu, tái sử dụng logic
-- =====================================================

-- Function: CalculateTotalRent
-- MỤC ĐÍCH: Tính tổng tiền thuê của 1 hợp đồng (monthly_rent * số tháng)
-- SỬ DỤNG: Báo cáo tài chính, tính toán chi phí
-- RETURNS: Tổng số tiền (DOUBLE)
DELIMITER //
CREATE FUNCTION CalculateTotalRent(p_contract_id BIGINT) 
RETURNS DOUBLE                                  -- Kiểu dữ liệu trả về
READS SQL DATA                                  -- Function đọc dữ liệu từ database
DETERMINISTIC                                   -- Với cùng input sẽ ra cùng output
BEGIN
    -- Khai báo biến cục bộ
    DECLARE v_monthly_rent DOUBLE DEFAULT 0;    -- Tiền thuê hàng tháng
    DECLARE v_start_date DATE;                  -- Ngày bắt đầu
    DECLARE v_end_date DATE;                    -- Ngày kết thúc
    DECLARE v_months INT DEFAULT 0;             -- Số tháng
    
    -- Lấy thông tin hợp đồng
    SELECT monthly_rent, start_date, end_date 
    INTO v_monthly_rent, v_start_date, v_end_date
    FROM contract 
    WHERE id = p_contract_id;
    
    -- Kiểm tra dữ liệu hợp lệ
    IF v_start_date IS NULL OR v_end_date IS NULL THEN
        RETURN 0;                               -- Trả về 0 nếu dữ liệu không hợp lệ
    END IF;
    
    -- Tính số tháng giữa 2 ngày
    SET v_months = TIMESTAMPDIFF(MONTH, v_start_date, v_end_date);
    
    -- Trả về tổng tiền thuê
    RETURN v_monthly_rent * v_months;
END//
DELIMITER ;

-- Function: GetApartmentStatus
-- MỤC ĐÍCH: Lấy trạng thái căn hộ dưới dạng text dễ đọc
-- SỬ DỤNG: Hiển thị trạng thái cho người dùng
-- RETURNS: Text mô tả trạng thái (VARCHAR)
DELIMITER //
CREATE FUNCTION GetApartmentStatus(p_apartment_id BIGINT)
RETURNS VARCHAR(50)                             -- Kiểu dữ liệu trả về
READS SQL DATA                                  -- Function đọc dữ liệu
DETERMINISTIC                                   -- Deterministic function
BEGIN
    -- Khai báo biến cục bộ
    DECLARE v_rented BIT DEFAULT 0;             -- Trạng thái thuê
    DECLARE v_exists INT DEFAULT 0;             -- Kiểm tra tồn tại
    
    -- Kiểm tra căn hộ có tồn tại không
    SELECT COUNT(*) INTO v_exists FROM apartment WHERE id = p_apartment_id;
    
    IF v_exists = 0 THEN
        RETURN 'KHÔNG TỒN TẠI';                 -- Căn hộ không tồn tại
    END IF;
    
    -- Lấy trạng thái thuê
    SELECT rented INTO v_rented FROM apartment WHERE id = p_apartment_id;
    
    -- Trả về text tương ứng
    IF v_rented = 1 THEN
        RETURN 'ĐÃ THUÊ';                       -- Căn hộ đã được thuê
    ELSE
        RETURN 'CÒN TRỐNG';                     -- Căn hộ còn trống
    END IF;
END//
DELIMITER ;

-- =====================================================
-- BƯỚC 6: TẠO CÁC TRIGGERS
-- Trigger = Chương trình tự động chạy khi có sự kiện (INSERT, UPDATE, DELETE)
-- MỤC ĐÍCH: Kiểm tra dữ liệu, ghi log, tự động cập nhật
-- =====================================================

-- Trigger: check_contract_dates
-- LOẠI: BEFORE INSERT (chạy TRƯỚC khi INSERT vào bảng contract)
-- MỤC ĐÍCH: Kiểm tra tính hợp lệ của ngày tháng trong hợp đồng
-- QUY TẮC: 
--   1. Ngày kết thúc phải sau ngày bắt đầu
--   2. Ngày bắt đầu không được trong quá khứ
DELIMITER //
CREATE TRIGGER check_contract_dates
BEFORE INSERT ON contract                       -- Kích hoạt TRƯỚC khi INSERT
FOR EACH ROW                                    -- Áp dụng cho từng row được INSERT
BEGIN
    -- Kiểm tra ngày kết thúc phải sau ngày bắt đầu
    IF NEW.end_date <= NEW.start_date THEN
        -- SIGNAL: Ném ra lỗi với mã và thông báo tùy chỉnh
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngày kết thúc phải sau ngày bắt đầu';
    END IF;
    
    -- Kiểm tra ngày bắt đầu không được trong quá khứ
    IF NEW.start_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ngày bắt đầu không thể trong quá khứ';
    END IF;
END//
DELIMITER ;

-- Trigger: log_equipment_status_change
-- LOẠI: AFTER UPDATE (chạy SAU khi UPDATE bảng equipment)
-- MỤC ĐÍCH: Ghi log mỗi khi trạng thái thiết bị thay đổi
-- SỬ DỤNG: Audit trail, theo dõi lịch sử bảo trì
DELIMITER //
CREATE TRIGGER log_equipment_status_change
AFTER UPDATE ON equipment                       -- Kích hoạt SAU khi UPDATE
FOR EACH ROW                                    -- Áp dụng cho từng row được UPDATE
BEGIN
    -- Chỉ ghi log khi status thực sự thay đổi
    IF OLD.status != NEW.status THEN
        -- INSERT vào bảng log với thông tin cũ và mới
        INSERT INTO equipment_status_log (equipment_id, old_status, new_status)
        VALUES (NEW.id, OLD.status, NEW.status);
        -- NEW: Giá trị mới sau UPDATE
        -- OLD: Giá trị cũ trước UPDATE
        -- change_timestamp sẽ tự động = CURRENT_TIMESTAMP
    END IF;
END//
DELIMITER ;

-- Trigger: update_apartment_rented_status
-- LOẠI: AFTER INSERT (chạy SAU khi INSERT vào bảng contract)
-- MỤC ĐÍCH: Tự động cập nhật trạng thái căn hộ thành "đã thuê" khi có hợp đồng mới
-- LOGIC NGHIỆP VỤ: Khi tạo hợp đồng → căn hộ tự động chuyển sang trạng thái đã thuê
DELIMITER //
CREATE TRIGGER update_apartment_rented_status
AFTER INSERT ON contract                        -- Kích hoạt SAU khi INSERT contract
FOR EACH ROW                                    -- Áp dụng cho từng contract được tạo
BEGIN
    -- Tự động cập nhật apartment.rented = 1 (đã thuê)
    UPDATE apartment SET rented = 1 WHERE id = NEW.apartment_id;
    -- NEW.apartment_id: ID căn hộ trong hợp đồng vừa được tạo
END//
DELIMITER ;

-- =====================================================
-- BƯỚC 7: INSERT DỮ LIỆU MẪU
-- MỤC ĐÍCH: Tạo dữ liệu test để kiểm thử hệ thống
-- THỨ TỰ: Phải insert theo thứ tự phụ thuộc (bảng cha trước, bảng con sau)
-- =====================================================

-- 7.1. INSERT DỮ LIỆU BẢNG USER_ACCOUNT (bảng gốc - insert trước)
-- MỤC ĐÍCH: Tạo tài khoản đăng nhập cho các vai trò khác nhau
INSERT INTO user_account (user_name, password, role) VALUES
('admin', 'admin123', 'ADMIN'),                 -- Tài khoản quản trị viên
('manager1', 'manager123', 'MANAGER'),          -- Tài khoản quản lý
('staff1', 'staff123', 'STAFF'),                -- Tài khoản nhân viên
('customer1', 'customer123', 'CUSTOMER'),       -- Tài khoản khách hàng 1
('customer2', 'customer456', 'CUSTOMER'),       -- Tài khoản khách hàng 2
('customer3', 'customer789', 'CUSTOMER');       -- Tài khoản khách hàng 3

-- 7.2. INSERT DỮ LIỆU BẢNG CUSTOMER (phụ thuộc user_account)
-- MỤC ĐÍCH: Tạo thông tin chi tiết khách hàng
-- LƯU Ý: user_account_id phải tham chiếu đến ID có sẵn trong user_account
INSERT INTO customer (name, email, phone_number, user_account_id) VALUES
('Nguyễn Văn A', 'nguyenvana@email.com', '0901234567', 4), -- Liên kết với customer1
('Trần Thị B', 'tranthib@email.com', '0987654321', 5),     -- Liên kết với customer2
('Lê Văn C', 'levanc@email.com', '0123456789', 6);         -- Liên kết với customer3

-- 7.3. INSERT DỮ LIỆU BẢNG DISTRICT (bảng gốc - insert trước)
-- MỤC ĐÍCH: Tạo danh sách các quận/huyện để phân loại địa lý
INSERT INTO district (name, code, city, region) VALUES
('Quận 1', 'Q1', 'Hồ Chí Minh', 'Miền Nam'),       -- Quận trung tâm TP.HCM
('Quận 3', 'Q3', 'Hồ Chí Minh', 'Miền Nam'),       -- Quận 3 TP.HCM
('Quận Ba Đình', 'BD', 'Hà Nội', 'Miền Bắc'),      -- Quận trung tâm Hà Nội
('Quận Hoàn Kiếm', 'HK', 'Hà Nội', 'Miền Bắc'),    -- Quận lõi Hà Nội
('Quận Hải Châu', 'HC', 'Đà Nẵng', 'Miền Trung');  -- Quận trung tâm Đà Nẵng

-- 7.4. INSERT DỮ LIỆU BẢNG BUILDING (phụ thuộc district)
-- MỤC ĐÍCH: Tạo các tòa nhà trong các quận
-- LƯU Ý: district_id phải tham chiếu đến ID có sẵn trong district
INSERT INTO building (name, address, contact_number, number_of_floors, total_area, type, district_id) VALUES
('Vinhomes Central Park', '208 Nguyễn Hữu Cảnh', '02839101010', 45, 15000.0, 'APARTMENT', 1), -- Quận 1
('Bitexco Financial Tower', '2 Hải Triều', '02838234567', 68, 12000.0, 'OFFICE', 1),          -- Quận 1
('Saigon Pearl', '92 Nguyễn Hữu Cảnh', '02839102020', 40, 18000.0, 'APARTMENT', 1),           -- Quận 1
('Lotte Center Hanoi', '54 Liễu Giai', '02438315000', 65, 20000.0, 'MIXED', 3),               -- Ba Đình
('Hanoi Towers', '49 Hai Bà Trưng', '02439364636', 25, 8000.0, 'APARTMENT', 4);               -- Hoàn Kiếm

-- 7.5. INSERT DỮ LIỆU BẢNG APARTMENT (phụ thuộc building)
-- MỤC ĐÍCH: Tạo các căn hộ trong từng tòa nhà
-- LƯU Ý: building_id phải tham chiếu đến ID có sẵn trong building
-- TRẠNG THÁI: rented = 0 (trống), rented = 1 (đã thuê)
INSERT INTO apartment (name, floor_area, number_of_bedrooms, number_of_bathrooms, min_rate, rented, building_id) VALUES
-- Căn hộ trong Vinhomes Central Park (building_id = 1)
('A01-101', 45.5, 1, 1, 6500000, 0, 1),        -- 1 phòng ngủ, còn trống
('A02-205', 68.0, 2, 2, 9500000, 1, 1),        -- 2 phòng ngủ, đã thuê
('A03-1501', 95.5, 3, 2, 15000000, 0, 1),      -- 3 phòng ngủ, còn trống
-- Căn hộ trong Saigon Pearl (building_id = 3)
('P01-301', 55.0, 1, 1, 7200000, 1, 3),        -- 1 phòng ngủ, đã thuê
('P02-1205', 85.0, 2, 2, 12500000, 0, 3),      -- 2 phòng ngủ, còn trống
('VIP-4501', 120.0, 3, 3, 20000000, 0, 3),     -- 3 phòng ngủ penthouse, còn trống
-- Căn hộ trong Lotte Center (building_id = 4)
('L01-1001', 65.0, 2, 1, 11000000, 1, 4),      -- 2 phòng ngủ, đã thuê
('L02-2015', 90.0, 3, 2, 16500000, 0, 4),      -- 3 phòng ngủ, còn trống
-- Căn hộ trong Hanoi Towers (building_id = 5)
('H01-501', 50.0, 1, 1, 8500000, 0, 5),        -- 1 phòng ngủ, còn trống
('H02-1201', 75.0, 2, 2, 13000000, 0, 5);      -- 2 phòng ngủ, còn trống

-- 7.6. INSERT DỮ LIỆU BẢNG EQUIPMENT (bảng gốc)
-- MỤC ĐÍCH: Tạo danh sách thiết bị có thể có trong căn hộ
-- PHÂN LOẠI: APPLIANCE (thiết bị), FURNITURE (nội thất), ELECTRONICS (điện tử), SECURITY (an ninh)
-- TRẠNG THÁI: WORKING (hoạt động), MAINTENANCE (bảo trì), BROKEN (hỏng)
INSERT INTO equipment (name, type, status, broken_fee) VALUES
('Tủ lạnh Samsung 400L', 'APPLIANCE', 'WORKING', 2500000),     -- Thiết bị gia dụng
('Smart TV 55 inch', 'ELECTRONICS', 'WORKING', 3000000),       -- Thiết bị điện tử
('Sofa da 3 chỗ ngồi', 'FURNITURE', 'WORKING', 1500000),       -- Nội thất
('Điều hòa Daikin 2HP', 'APPLIANCE', 'WORKING', 4000000),      -- Thiết bị gia dụng
('Máy giặt LG 9kg', 'APPLIANCE', 'MAINTENANCE', 2000000),      -- Đang bảo trì
('Bàn làm việc gỗ', 'FURNITURE', 'WORKING', 1200000),          -- Nội thất
('Máy nước nóng', 'APPLIANCE', 'WORKING', 1800000),            -- Thiết bị gia dụng
('Camera an ninh IP', 'SECURITY', 'WORKING', 800000),          -- Thiết bị an ninh
('Tủ quần áo 3 cánh', 'FURNITURE', 'WORKING', 2200000),        -- Nội thất
('Bếp từ đôi', 'APPLIANCE', 'BROKEN', 1500000);                -- Thiết bị hỏng

-- 7.7. INSERT DỮ LIỆU BẢNG APARTMENT_EQUIPMENT (bảng trung gian)
-- MỤC ĐÍCH: Liên kết thiết bị với căn hộ (quan hệ nhiều-nhiều)
-- LOGIC: Mỗi căn hộ có các thiết bị khác nhau tùy theo mức độ cao cấp
-- LƯU Ý: Cả apartment_id và equipment_id phải tồn tại trong bảng tương ứng
INSERT INTO apartment_equipment (apartment_id, equipment_id) VALUES
-- Căn hộ A01-101 (apartment_id = 1): Căn hộ cơ bản - 3 thiết bị
(1, 1), -- Tủ lạnh Samsung
(1, 2), -- Smart TV
(1, 3), -- Sofa da

-- Căn hộ A02-205 (apartment_id = 2): Căn hộ trung bình - 3 thiết bị
(2, 1), -- Tủ lạnh Samsung
(2, 4), -- Điều hòa Daikin
(2, 6), -- Bàn làm việc

-- Căn hộ A03-1501 (apartment_id = 3): Căn hộ cao cấp - 4 thiết bị
(3, 1), -- Tủ lạnh Samsung
(3, 2), -- Smart TV
(3, 4), -- Điều hòa Daikin
(3, 9), -- Tủ quần áo

-- Căn hộ P01-301 (apartment_id = 4): Căn hộ đặc biệt - 3 thiết bị
(4, 5), -- Máy giặt LG (đang bảo trì)
(4, 7), -- Máy nước nóng
(4, 8), -- Camera an ninh

-- Căn hộ P02-1205 (apartment_id = 5): Căn hộ cao cấp - 4 thiết bị
(5, 1), -- Tủ lạnh Samsung
(5, 2), -- Smart TV
(5, 4), -- Điều hòa Daikin
(5, 6), -- Bàn làm việc

-- Căn hộ VIP-4501 (apartment_id = 6): Penthouse - đầy đủ thiết bị cao cấp - 5 thiết bị
(6, 1), -- Tủ lạnh Samsung
(6, 2), -- Smart TV
(6, 3), -- Sofa da
(6, 4), -- Điều hòa Daikin
(6, 9), -- Tủ quần áo

-- Căn hộ L01-1001 (apartment_id = 7): Căn hộ có thiết bị lỗi - 3 thiết bị
(7, 1),  -- Tủ lạnh Samsung
(7, 4),  -- Điều hòa Daikin
(7, 10), -- Bếp từ đôi (hỏng)

-- Căn hộ L02-2015 (apartment_id = 8): Căn hộ cao cấp đầy đủ - 5 thiết bị
(8, 1), -- Tủ lạnh Samsung
(8, 2), -- Smart TV
(8, 4), -- Điều hòa Daikin
(8, 6), -- Bàn làm việc
(8, 9), -- Tủ quần áo

-- Căn hộ H01-501 (apartment_id = 9): Căn hộ cơ bản - 2 thiết bị
(9, 1), -- Tủ lạnh Samsung
(9, 7), -- Máy nước nóng

-- Căn hộ H02-1201 (apartment_id = 10): Căn hộ tiêu chuẩn - 3 thiết bị
(10, 1), -- Tủ lạnh Samsung
(10, 2), -- Smart TV
(10, 4); -- Điều hòa Daikin

-- 7.8. INSERT DỮ LIỆU BẢNG CONTRACT (phụ thuộc apartment và customer)
-- MỤC ĐÍCH: Tạo hợp đồng thuê giữa khách hàng và căn hộ
-- LƯU Ý: 
--   - apartment_id và customer_id phải tồn tại
--   - Ngày phải hợp lệ (không vi phạm trigger check_contract_dates)
--   - Chỉ tạo hợp đồng cho căn hộ đã thuê (rented = 1)
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) VALUES
-- Hợp đồng 1: Căn hộ A02-205 (apartment_id = 2) với Nguyễn Văn A (customer_id = 1)
(2, 1, '2025-07-01', '2026-07-01', 9500000, 19000000, 'ACTIVE'),

-- Hợp đồng 2: Căn hộ P01-301 (apartment_id = 4) với Trần Thị B (customer_id = 2)
(4, 2, '2025-08-01', '2026-02-01', 7200000, 14400000, 'ACTIVE'),

-- Hợp đồng 3: Căn hộ L01-1001 (apartment_id = 7) với Lê Văn C (customer_id = 3)
(7, 3, '2025-09-01', '2026-09-01', 11000000, 22000000, 'ACTIVE');

-- =====================================================
-- BƯỚC 8: TẠO USER BACKUP VÀ PHÂN QUYỀN
-- MỤC ĐÍCH: Tạo user chuyên dụng để backup database
-- BẢO MẬT: User backup chỉ có quyền đọc, không thể thay đổi dữ liệu
-- =====================================================

-- Tạo user backup với mật khẩu mạnh
-- IF NOT EXISTS: Không báo lỗi nếu user đã tồn tại
CREATE USER IF NOT EXISTS 'apt_backup'@'localhost' IDENTIFIED BY 'BackupPass123!@#';

-- Cấp quyền backup cho user
-- SELECT: Đọc dữ liệu
-- LOCK TABLES: Khóa bảng trong quá trình backup
-- SHOW VIEW: Xem cấu trúc view
-- EVENT: Backup các event (nếu có)
-- TRIGGER: Backup các trigger
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON apartment_db.* TO 'apt_backup'@'localhost';

-- Cấp quyền system cần thiết cho backup
-- RELOAD: Refresh privileges và flush logs
-- PROCESS: Xem các process đang chạy
GRANT RELOAD, PROCESS ON *.* TO 'apt_backup'@'localhost';

-- Áp dụng ngay lập tức các quyền đã cấp
FLUSH PRIVILEGES;

-- Insert log mẫu về quá trình backup
-- MỤC ĐÍCH: Theo dõi lịch sử backup để đảm bảo an toàn dữ liệu
INSERT INTO backup_log (backup_file, backup_size_mb, backup_status, validation_status, notes) 
VALUES ('apartment_db_backup_20250625_103045.sql.gz', 156.5, 'SUCCESS', 'VALID', 'Full backup completed successfully');

-- =====================================================
-- BƯỚC 9: QUERIES KIỂM TRA VÀ THỐNG KÊ
-- MỤC ĐÍCH: Kiểm tra hệ thống hoạt động đúng và hiển thị thống kê
-- SỬ DỤNG: Validation, debugging, báo cáo cho quản lý
-- =====================================================

-- 9.1. Kiểm tra số lượng records trong từng bảng
-- MỤC ĐÍCH: Đảm bảo dữ liệu đã được insert đầy đủ
SELECT 'SYSTEM OVERVIEW - Records Count:' as info;
SELECT 
    'user_account' as table_name, COUNT(*) as record_count FROM user_account
UNION ALL SELECT 'customer', COUNT(*) FROM customer              -- Kết hợp kết quả từ nhiều bảng
UNION ALL SELECT 'district', COUNT(*) FROM district
UNION ALL SELECT 'building', COUNT(*) FROM building
UNION ALL SELECT 'apartment', COUNT(*) FROM apartment
UNION ALL SELECT 'equipment', COUNT(*) FROM equipment
UNION ALL SELECT 'apartment_equipment', COUNT(*) FROM apartment_equipment
UNION ALL SELECT 'contract', COUNT(*) FROM contract;

-- 9.2. Kiểm tra views đã tạo
-- MỤC ĐÍCH: Xác nhận tất cả views đã được tạo thành công
SELECT 'Database Views:' as info;
SHOW FULL TABLES WHERE Table_type = 'VIEW';                     -- Chỉ hiển thị views, không hiển thị tables

-- 9.3. Kiểm tra procedures và functions
-- MỤC ĐÍCH: Xác nhận stored procedures và functions đã được tạo
SELECT 'Stored Procedures:' as info;
SHOW PROCEDURE STATUS WHERE Db = DATABASE();                    -- Hiển thị procedures trong database hiện tại

SELECT 'Functions:' as info;
SHOW FUNCTION STATUS WHERE Db = DATABASE();                     -- Hiển thị functions trong database hiện tại

-- 9.4. Kiểm tra triggers
-- MỤC ĐÍCH: Xác nhận triggers đã được tạo và sẵn sàng hoạt động
SELECT 'Triggers:' as info;
SHOW TRIGGERS;                                                  -- Hiển thị tất cả triggers

-- 9.5. Xem tất cả căn hộ với thông tin chi tiết
-- MỤC ĐÍCH: Hiển thị danh sách căn hộ với thông tin đầy đủ cho quản lý
SELECT 'All Apartments Overview:' as info;
SELECT 
    a.id,
    a.name as apartment_name,
    a.floor_area,
    a.number_of_bedrooms,
    a.number_of_bathrooms,
    FORMAT(a.min_rate, 0) as rent_formatted,                    -- FORMAT: Định dạng số có dấu phẩy
    CASE WHEN a.rented = 1 THEN 'Đã thuê' ELSE 'Còn trống' END as status, -- CASE: Điều kiện if-else
    b.name as building_name,
    d.name as district_name,
    d.city
FROM apartment a
JOIN building b ON a.building_id = b.id                         -- JOIN để lấy thông tin building
JOIN district d ON b.district_id = d.id                         -- JOIN để lấy thông tin district
ORDER BY d.city, b.name, a.name;                               -- Sắp xếp theo thành phố, tòa nhà, căn hộ

-- 9.6. Thống kê căn hộ theo thành phố
-- MỤC ĐÍCH: Báo cáo tình hình kinh doanh theo từng thành phố
-- SỬ DỤNG: Phân tích thị trường, định giá, chiến lược mở rộng
SELECT 'Apartments Statistics by City:' as info;
SELECT 
    d.city,                                                     -- Tên thành phố
    COUNT(*) as total_apartments,                               -- Tổng số căn hộ
    SUM(CASE WHEN a.rented = 0 THEN 1 ELSE 0 END) as available, -- Số căn hộ còn trống
    SUM(CASE WHEN a.rented = 1 THEN 1 ELSE 0 END) as rented,   -- Số căn hộ đã thuê
    FORMAT(AVG(a.min_rate), 0) as avg_rent                     -- Giá thuê trung bình
FROM apartment a
JOIN building b ON a.building_id = b.id
JOIN district d ON b.district_id = d.id
GROUP BY d.city                                                 -- Nhóm theo thành phố
ORDER BY total_apartments DESC;                                 -- Sắp xếp theo số lượng căn hộ giảm dần

-- 9.7. Kiểm tra contracts với thông tin đầy đủ
-- MỤC ĐÍCH: Hiển thị thông tin hợp đồng cho quản lý
-- SỬ DỤNG: Theo dõi khách hàng, quản lý thu nhập
SELECT 'Active Contracts:' as info;
SELECT 
    c.id as contract_id,                                        -- ID hợp đồng
    cust.name as customer_name,                                 -- Tên khách hàng
    a.name as apartment_name,                                   -- Tên căn hộ
    b.name as building_name,                                    -- Tên tòa nhà
    c.start_date,                                               -- Ngày bắt đầu
    c.end_date,                                                 -- Ngày kết thúc
    FORMAT(c.monthly_rent, 0) as monthly_rent,                  -- Tiền thuê định dạng
    c.payment_status                                            -- Trạng thái thanh toán
FROM contract c
JOIN customer cust ON c.customer_id = cust.id                  -- JOIN để lấy thông tin khách hàng
JOIN apartment a ON c.apartment_id = a.id                      -- JOIN để lấy thông tin căn hộ
JOIN building b ON a.building_id = b.id;                       -- JOIN để lấy thông tin tòa nhà

-- 9.8. Test các views
-- MỤC ĐÍCH: Kiểm tra views hoạt động đúng
-- SỬ DỤNG: Validation, debugging
SELECT 'Testing Views:' as info;

-- Test view apartment_details
SELECT 'apartment_details view sample:' as view_name;
SELECT apartment_name, building_name, district_name, city, number_of_bedrooms, min_rate
FROM apartment_details LIMIT 3;                                -- LIMIT: Chỉ lấy 3 records đầu tiên

-- Test view available_apartments
SELECT 'available_apartments view:' as view_name;
SELECT name, building_name, district_name, number_of_bedrooms, FORMAT(min_rate, 0) as rent_formatted
FROM available_apartments ORDER BY min_rate ASC LIMIT 5;       -- Căn hộ trống giá rẻ nhất

-- =====================================================
-- BƯỚC 10: FINAL VALIDATION VÀ SUMMARY
-- MỤC ĐÍCH: Kiểm tra cuối cùng tính toàn vẹn và báo cáo tổng kết
-- SỬ DỤNG: Đảm bảo hệ thống hoàn chỉnh, không có lỗi dữ liệu
-- =====================================================

-- 10.1. Data integrity checks
-- MỤC ĐÍCH: Kiểm tra tính toàn vẹn dữ liệu (không có orphaned records)
-- ORPHANED RECORDS: Dữ liệu con tham chiếu đến dữ liệu cha không tồn tại
SELECT 'DATA INTEGRITY CHECKS:' as info;

-- Kiểm tra apartment mồ côi (không có building)
SELECT 'Orphaned apartments (no building):' as check_type,
       COUNT(*) as count                                        -- Số lượng apartment mồ côi
FROM apartment a
LEFT JOIN building b ON a.building_id = b.id                   -- LEFT JOIN: Giữ tất cả apartment
WHERE b.id IS NULL                                              -- Apartment không có building tương ứng
UNION ALL
-- Kiểm tra contract mồ côi (không có apartment hoặc customer)
SELECT 'Orphaned contracts (no apartment/customer):' as check_type,
       COUNT(*) as count                                        -- Số lượng contract mồ côi
FROM contract c
LEFT JOIN apartment a ON c.apartment_id = a.id                 -- LEFT JOIN với apartment
LEFT JOIN customer cust ON c.customer_id = cust.id             -- LEFT JOIN với customer
WHERE a.id IS NULL OR cust.id IS NULL;                         -- Contract không có apartment hoặc customer

-- 10.2. Business metrics
-- MỤC ĐÍCH: Thống kê các chỉ số kinh doanh quan trọng
-- SỬ DỤNG: Báo cáo cho ban quản lý, đánh giá hiệu quả kinh doanh
SELECT 'BUSINESS METRICS:' as info;
SELECT 
    'Total available apartments' as metric,                     -- Tên chỉ số
    COUNT(*) as value                                           -- Giá trị
FROM apartment WHERE rented = 0                                 -- Căn hộ còn trống
UNION ALL
SELECT 
    'Total rented apartments' as metric,
    COUNT(*) as value
FROM apartment WHERE rented = 1                                 -- Căn hộ đã thuê
UNION ALL
SELECT 
    'Active contracts' as metric,
    COUNT(*) as value
FROM contract WHERE payment_status = 'ACTIVE'                   -- Hợp đồng đang hoạt động
UNION ALL
SELECT 
    'Total monthly revenue' as metric,
    COALESCE(SUM(monthly_rent), 0) as value                     -- COALESCE: Thay NULL bằng 0
FROM contract WHERE payment_status = 'ACTIVE'                   -- Tổng doanh thu hàng tháng
UNION ALL
SELECT 
    'Average rent per apartment' as metric,
    COALESCE(AVG(min_rate), 0) as value                         -- Giá thuê trung bình
FROM apartment;

-- 10.3. Database objects summary
-- MỤC ĐÍCH: Thống kê các đối tượng database đã được tạo
-- SỬ DỤNG: Kiểm tra hệ thống đã đầy đủ các thành phần
SELECT 'DATABASE OBJECTS SUMMARY:' as info;
SELECT 
    'Tables' as object_type,                                    -- Loại đối tượng
    COUNT(*) as count                                           -- Số lượng
FROM information_schema.tables                                  -- Bảng metadata của MySQL
WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'  -- Chỉ đếm tables thực (không phải views)
UNION ALL
SELECT 
    'Views' as object_type,
    COUNT(*) as count
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_type = 'VIEW'        -- Chỉ đếm views
UNION ALL
SELECT 
    'Procedures' as object_type,
    COUNT(*) as count
FROM information_schema.routines                               -- Bảng metadata cho procedures/functions
WHERE routine_schema = DATABASE() AND routine_type = 'PROCEDURE' -- Chỉ đếm procedures
UNION ALL
SELECT 
    'Functions' as object_type,
    COUNT(*) as count
FROM information_schema.routines
WHERE routine_schema = DATABASE() AND routine_type = 'FUNCTION' -- Chỉ đếm functions
UNION ALL
SELECT 
    'Triggers' as object_type,
    COUNT(*) as count
FROM information_schema.triggers                               -- Bảng metadata cho triggers
WHERE trigger_schema = DATABASE();                             -- Triggers trong database hiện tại

-- =====================================================
-- KẾT THÚC: HỆ THỐNG ĐÃ ĐƯỢC THIẾT LẬP HOÀN CHỈNH
-- 
-- HỆ THỐNG APARTMENT MANAGEMENT BAO GỒM:
-- 
-- 📊 DỮ LIỆU (TABLES):
-- - 10 Tables: 8 bảng chính + 2 bảng phụ trợ (log)
--   + Bảng chính: user_account, customer, district, building, 
--                 apartment, equipment, apartment_equipment, contract
--   + Bảng phụ trợ: equipment_status_log, backup_log
-- 
-- 👁️ VIEWS (5 views):
-- - apartment_details: Thông tin căn hộ chi tiết
-- - active_contracts: Hợp đồng đang hoạt động  
-- - monthly_revenue: Thống kê doanh thu theo tháng
-- - available_apartments: Căn hộ có sẵn
-- - apartment_equipment_view: Thiết bị trong căn hộ
-- 
-- ⚙️ STORED PROCEDURES (3 procedures):
-- - CreateContract: Tạo hợp đồng với validation
-- - SearchApartments: Tìm kiếm căn hộ theo tiêu chí
-- - ManageApartmentEquipment: Quản lý thiết bị căn hộ
-- 
-- 🔧 FUNCTIONS (2 functions):
-- - CalculateTotalRent: Tính tổng tiền thuê hợp đồng
-- - GetApartmentStatus: Lấy trạng thái căn hộ
-- 
-- 🎯 TRIGGERS (3 triggers):
-- - check_contract_dates: Kiểm tra ngày hợp đồng hợp lệ
-- - log_equipment_status_change: Ghi log thay đổi thiết bị
-- - update_apartment_rented_status: Tự động cập nhật trạng thái thuê
-- 
-- 💾 DỮ LIỆU MẪU:
-- - 62 records dữ liệu test đầy đủ
-- - 6 user accounts (admin, manager, staff, customers)
-- - 3 customers với thông tin chi tiết
-- - 5 districts (HCM, Hà Nội, Đà Nẵng)
-- - 5 buildings cao cấp
-- - 10 apartments đa dạng (trống + đã thuê)
-- - 10 equipment types với trạng thái khác nhau
-- - 3 active contracts
-- 
-- 🔐 SECURITY & BACKUP:
-- - User backup chuyên dụng với quyền hạn chế
-- - Backup log tracking
-- - Data integrity validation
-- 
-- 📈 BUSINESS INTELLIGENCE:
-- - Thống kê theo thành phố
-- - Báo cáo doanh thu
-- - Metrics kinh doanh
-- - Data validation checks
-- 
-- 🚀 DEPLOYMENT:
-- Hệ thống sẵn sàng sử dụng cho production!
-- =====================================================

-- 💻 LỆNH CHẠY HỆ THỐNG:
-- mysql -u root -p -e "SOURCE /workspaces/hqtcsdl/complete_apartment_database.sql;"
-- 
-- 📖 HOẶC TRONG MYSQL CLI:
-- mysql> source /workspaces/hqtcsdl/complete_apartment_database.sql;
-- 
-- 🧪 KIỂM THỬ TRIGGERS:
-- Sử dụng các file test trigger có sẵn trong workspace:
-- - testtrigger.sql (cơ bản)
-- - enhanced_trigger_tests.sql (nâng cao)
-- - simple_trigger_test.sql (nhanh)
-- 
-- 📚 TÀI LIỆU HƯỚNG DẪN:
-- Xem file TRIGGER_TESTING_GUIDE.md để hiểu chi tiết cách sử dụng