# BÁO CÁO CÀI ĐẶT HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU MYSQL

---

## 1. GIỚI THIỆU CHUNG

### 1.1. Mô tả Hệ thống
Hệ thống này được thiết kế để quản lý thông tin về căn hộ, tòa nhà, khách hàng, hợp đồng thuê và các thiết bị liên quan trong một doanh nghiệp kinh doanh bất động sản hoặc cho thuê căn hộ. Nó hỗ trợ các hoạt động nghiệp vụ như tạo và quản lý hợp đồng, tìm kiếm căn hộ theo nhiều tiêu chí, theo dõi tình trạng căn hộ và thiết bị, cũng như cung cấp các báo cáo doanh thu và thống kê cần thiết. Mục tiêu là tự động hóa các quy trình, đảm bảo tính toàn vẹn dữ liệu và nâng cao hiệu quả quản lý.

### 1.2. Schema Cơ Sở Dữ Liệu
#### 1.2.1. Danh sách Bảng
Hệ thống quản lý căn hộ bao gồm các bảng chính:
- `user_account`: Lưu trữ thông tin tài khoản người dùng (quản trị viên, nhân viên, khách hàng).
- `customer`: Lưu trữ thông tin chi tiết của khách hàng.
- `district`: Lưu trữ thông tin về các quận/huyện, thành phố.
- `building`: Lưu trữ thông tin về các tòa nhà.
- `apartment`: Lưu trữ thông tin chi tiết về từng căn hộ trong các tòa nhà.
- `equipment`: Lưu trữ danh mục các loại thiết bị có thể có trong căn hộ.
- `apartment_equipment`: Bảng trung gian thể hiện mối quan hệ nhiều-nhiều giữa căn hộ và thiết bị.
- `contract`: Lưu trữ thông tin về các hợp đồng thuê căn hộ.

#### 1.2.2. Định nghĩa Bảng (DDL)
```sql
-- Định nghĩa Bảng (DDL)

CREATE TABLE apartment (
    id BIGINT NOT NULL AUTO_INCREMENT,
    floor_area DOUBLE PRECISION,
    min_rate DOUBLE PRECISION,
    move_in_date DATETIME,
    move_out_date DATETIME,
    name VARCHAR(255),
    number_of_bathrooms INTEGER,
    number_of_bedrooms INTEGER,
    rented BIT,
    building_id BIGINT NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE apartment_equipment (
    id BIGINT NOT NULL AUTO_INCREMENT,
    apartment_id BIGINT NOT NULL,
    equipment_id BIGINT NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE building (
    id BIGINT NOT NULL AUTO_INCREMENT,
    address VARCHAR(255),
    contact_number VARCHAR(255),
    name VARCHAR(255),
    number_of_floors INTEGER,
    total_area DOUBLE PRECISION,
    type VARCHAR(255),
    district_id BIGINT NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE contract (
    id BIGINT NOT NULL AUTO_INCREMENT,
    deposit DOUBLE PRECISION,
    end_date DATETIME,
    monthly_rent DOUBLE PRECISION,
    payment_status VARCHAR(255),
    start_date DATETIME,
    apartment_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE customer (
    id BIGINT NOT NULL AUTO_INCREMENT,
    email VARCHAR(255),
    name VARCHAR(255),
    phone_number VARCHAR(255),
    user_account_id BIGINT NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE district (
    id BIGINT NOT NULL AUTO_INCREMENT,
    city VARCHAR(255),
    code VARCHAR(255),
    name VARCHAR(255),
    region VARCHAR(255),
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE equipment (
    id BIGINT NOT NULL AUTO_INCREMENT,
    broken_fee DOUBLE PRECISION,
    name VARCHAR(255),
    status VARCHAR(255),
    type VARCHAR(255),
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE user_account (
    id BIGINT NOT NULL AUTO_INCREMENT,
    password VARCHAR(255),
    role VARCHAR(255),
    user_name VARCHAR(255),
    PRIMARY KEY (id)
) ENGINE=InnoDB;

-- Unique Constraints
ALTER TABLE user_account 
    ADD CONSTRAINT uk_user_account_username UNIQUE (user_name);

-- Foreign Key Constraints
ALTER TABLE apartment 
    ADD CONSTRAINT fk_apartment_building 
    FOREIGN KEY (building_id) 
    REFERENCES building (id);

ALTER TABLE apartment_equipment 
    ADD CONSTRAINT fk_apartment_equipment_apartment 
    FOREIGN KEY (apartment_id) 
    REFERENCES apartment (id);

ALTER TABLE apartment_equipment 
    ADD CONSTRAINT fk_apartment_equipment_equipment 
    FOREIGN KEY (equipment_id) 
    REFERENCES equipment (id);

ALTER TABLE building 
    ADD CONSTRAINT fk_building_district 
    FOREIGN KEY (district_id) 
    REFERENCES district (id);

ALTER TABLE contract 
    ADD CONSTRAINT fk_contract_apartment 
    FOREIGN KEY (apartment_id) 
    REFERENCES apartment (id);

ALTER TABLE contract 
    ADD CONSTRAINT fk_contract_customer 
    FOREIGN KEY (customer_id) 
    REFERENCES customer (id);

ALTER TABLE customer 
    ADD CONSTRAINT fk_customer_user_account 
    FOREIGN KEY (user_account_id) 
    REFERENCES user_account (id);
```

---

## 2. CÁC ĐỐI TƯỢNG CƠ SỞ DỮ LIỆU (DATABASE OBJECTS)

### 2.1. Views (Các Khung Nhìn)

#### 2.1.1. View thông tin căn hộ chi tiết (`apartment_details`)
```sql
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
```

**Ví dụ thực thi:**
```sql
-- Xem tất cả thông tin căn hộ chi tiết
SELECT * FROM apartment_details LIMIT 10;

-- Tìm căn hộ trong quận cụ thể
SELECT * FROM apartment_details WHERE district_name = 'Quận 1';

-- Tìm căn hộ theo số phòng ngủ và khoảng giá
SELECT apartment_name, building_name, min_rate, number_of_bedrooms 
FROM apartment_details 
WHERE number_of_bedrooms >= 2 AND min_rate BETWEEN 5000000 AND 15000000;

-- Thống kê căn hộ theo thành phố
SELECT city, COUNT(*) as total_apartments, AVG(min_rate) as avg_rent
FROM apartment_details 
GROUP BY city;
```

#### 2.1.2. View hợp đồng hiện tại (`active_contracts`)
```sql
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
```

**Ví dụ thực thi:**
```sql
-- Xem tất cả hợp đồng đang hoạt động
SELECT * FROM active_contracts;

-- Hợp đồng sắp hết hạn trong 30 ngày
SELECT contract_id, customer_name, apartment_name, end_date, monthly_rent
FROM active_contracts 
WHERE end_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY);

-- Tổng doanh thu từ hợp đồng đang hoạt động
SELECT 
    COUNT(*) as total_active_contracts,
    SUM(monthly_rent) as total_monthly_revenue,
    AVG(monthly_rent) as avg_monthly_rent
FROM active_contracts;

-- Hợp đồng theo trạng thái thanh toán
SELECT payment_status, COUNT(*) as count, SUM(monthly_rent) as total_rent
FROM active_contracts 
GROUP BY payment_status;
```

#### 2.1.3. View thống kê doanh thu theo tháng (`monthly_revenue`)
```sql
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
```

**Ví dụ thực thi:**
```sql
-- Xem doanh thu 12 tháng gần nhất
SELECT 
    CONCAT(month, '/', year) as period,
    total_contracts,
    FORMAT(total_monthly_rent, 0) as monthly_rent_formatted,
    FORMAT(total_deposits, 0) as deposits_formatted,
    FORMAT(avg_monthly_rent, 0) as avg_rent_formatted
FROM monthly_revenue 
LIMIT 12;

-- So sánh doanh thu năm hiện tại với năm trước
SELECT 
    year,
    SUM(total_contracts) as yearly_contracts,
    SUM(total_monthly_rent) as yearly_revenue,
    SUM(total_deposits) as yearly_deposits
FROM monthly_revenue 
WHERE year IN (2024, 2025)
GROUP BY year;

-- Tháng có doanh thu cao nhất
SELECT 
    CONCAT(month, '/', year) as best_month,
    total_monthly_rent as revenue
FROM monthly_revenue 
ORDER BY total_monthly_rent DESC 
LIMIT 5;

-- Xu hướng doanh thu 6 tháng gần nhất
SELECT 
    CONCAT(month, '/', year) as period,
    total_monthly_rent,
    LAG(total_monthly_rent) OVER (ORDER BY year, month) as prev_month_revenue,
    ROUND(((total_monthly_rent - LAG(total_monthly_rent) OVER (ORDER BY year, month)) / 
           LAG(total_monthly_rent) OVER (ORDER BY year, month)) * 100, 2) as growth_percent
FROM monthly_revenue 
ORDER BY year DESC, month DESC 
LIMIT 6;
```

#### 2.1.4. View căn hộ có sẵn (`available_apartments`)
```sql
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
```

**Ví dụ thực thi:**
```sql
-- Xem tất cả căn hộ có sẵn
SELECT * FROM available_apartments;

-- Căn hộ có sẵn theo khoảng giá
SELECT name, building_name, district_name, 
       FORMAT(min_rate, 0) as rent_formatted
FROM available_apartments 
WHERE min_rate BETWEEN 5000000 AND 15000000;

-- Căn hộ có sẵn theo số phòng ngủ
SELECT 
    number_of_bedrooms,
    COUNT(*) as available_count,
    MIN(min_rate) as min_rent,
    MAX(min_rate) as max_rent,
    AVG(min_rate) as avg_rent
FROM available_apartments 
GROUP BY number_of_bedrooms 
ORDER BY number_of_bedrooms;

-- Top 10 căn hộ rẻ nhất có sẵn
SELECT name, building_name, district_name, city,
       number_of_bedrooms, floor_area,
       FORMAT(min_rate, 0) as rent_formatted
FROM available_apartments 
ORDER BY min_rate ASC 
LIMIT 10;

-- Căn hộ có sẵn theo thành phố
SELECT city, district_name, COUNT(*) as available_count
FROM available_apartments 
GROUP BY city, district_name 
ORDER BY city, available_count DESC;
```

#### 2.1.5. View thiết bị trong căn hộ (`apartment_equipment_view`)
```sql
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
```

**Ví dụ thực thi:**
```sql
-- Xem tất cả thiết bị trong căn hộ
SELECT * FROM apartment_equipment_view;

-- Thiết bị trong căn hộ cụ thể
SELECT equipment_name, equipment_type, equipment_status, 
       FORMAT(broken_fee, 0) as broken_fee_formatted
FROM apartment_equipment_view 
WHERE apartment_id = 1;

-- Thống kê thiết bị theo trạng thái
SELECT 
    equipment_status,
    COUNT(*) as equipment_count,
    AVG(broken_fee) as avg_broken_fee
FROM apartment_equipment_view 
GROUP BY equipment_status;

-- Căn hộ có thiết bị hỏng
SELECT DISTINCT apartment_name, apartment_id
FROM apartment_equipment_view 
WHERE equipment_status = 'BROKEN';

-- Top thiết bị có phí sửa chữa cao nhất
SELECT apartment_name, equipment_name, equipment_type,
       FORMAT(broken_fee, 0) as broken_fee_formatted
FROM apartment_equipment_view 
WHERE equipment_status = 'BROKEN'
ORDER BY broken_fee DESC 
LIMIT 10;

-- Thống kê thiết bị theo loại
SELECT 
    equipment_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN equipment_status = 'WORKING' THEN 1 END) as working_count,
    COUNT(CASE WHEN equipment_status = 'BROKEN' THEN 1 END) as broken_count,
    COUNT(CASE WHEN equipment_status = 'MAINTENANCE' THEN 1 END) as maintenance_count
FROM apartment_equipment_view 
GROUP BY equipment_type;
```

### 2.2. Indexes (Chỉ Mục)
```sql
-- Index cho tìm kiếm căn hộ
CREATE INDEX idx_apartment_search ON apartment(rented, number_of_bedrooms, min_rate);
CREATE INDEX idx_apartment_building ON apartment(building_id);
CREATE INDEX idx_apartment_dates ON apartment(move_in_date, move_out_date);

-- Index cho hợp đồng
CREATE INDEX idx_contract_dates ON contract(start_date, end_date);
CREATE INDEX idx_contract_apartment ON contract(apartment_id);
CREATE INDEX idx_contract_customer ON contract(customer_id);
CREATE INDEX idx_contract_status ON contract(payment_status);

-- Index cho thiết bị
CREATE INDEX idx_equipment_status ON equipment(status);
CREATE INDEX idx_equipment_type ON equipment(type);

-- Index cho tòa nhà
CREATE INDEX idx_building_district ON building(district_id);
CREATE INDEX idx_building_type ON building(type);

-- Index cho địa chỉ
CREATE INDEX idx_district_city ON district(city, region);
```

### 2.3. Lệnh CRUD Cơ Bản (Create, Read, Update, Delete)

#### 2.3.1. Quản lý User Account (API: /api/users)

##### Tạo mới User Account (POST /api/users)
```sql
-- Tạo tài khoản người dùng mới
INSERT INTO user_account (user_name, password, role) 
VALUES ('new_user', 'password123', 'CUSTOMER');

-- Hoặc với stored procedure
DELIMITER //
CREATE PROCEDURE CreateUserAccount(
    IN p_user_name VARCHAR(255),
    IN p_password VARCHAR(255),
    IN p_role VARCHAR(255),
    OUT p_user_id BIGINT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_message = MESSAGE_TEXT;
        SET p_user_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Kiểm tra username đã tồn tại
    SELECT COUNT(*) INTO v_exists FROM user_account WHERE user_name = p_user_name;
    
    IF v_exists > 0 THEN
        SET p_message = 'Username đã tồn tại';
        SET p_user_id = -1;
        ROLLBACK;
    ELSE
        INSERT INTO user_account (user_name, password, role) 
        VALUES (p_user_name, p_password, p_role);
        
        SET p_user_id = LAST_INSERT_ID();
        SET p_message = 'Tạo tài khoản thành công';
        COMMIT;
    END IF;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Tạo tài khoản admin mới
CALL CreateUserAccount('admin_new', 'secure_password123', 'ADMIN', @user_id, @message);
SELECT @user_id as user_id, @message as result_message;

-- Tạo tài khoản customer
CALL CreateUserAccount('customer_john', 'password456', 'CUSTOMER', @user_id, @message);
SELECT @user_id as user_id, @message as result_message;

-- Thử tạo tài khoản với username đã tồn tại (sẽ thất bại)
CALL CreateUserAccount('admin_new', 'another_password', 'MANAGER', @user_id, @message);
SELECT @user_id as user_id, @message as result_message;

-- Tạo nhiều tài khoản cùng lúc
CALL CreateUserAccount('manager_1', 'pass123', 'MANAGER', @user_id_1, @msg_1);
CALL CreateUserAccount('staff_1', 'pass456', 'STAFF', @user_id_2, @msg_2);
CALL CreateUserAccount('staff_2', 'pass789', 'STAFF', @user_id_3, @msg_3);
SELECT @user_id_1, @msg_1, @user_id_2, @msg_2, @user_id_3, @msg_3;
```
```

##### Lấy thông tin User Account (GET /api/users/{id}, GET /api/users/username/{username})
```sql
-- Lấy user theo ID
SELECT * FROM user_account WHERE id = 1;

-- Lấy user theo username
SELECT * FROM user_account WHERE user_name = 'admin';

-- Lấy tất cả users
SELECT * FROM user_account ORDER BY id;

-- Lấy users theo role
SELECT * FROM user_account WHERE role = 'CUSTOMER';
```

##### Cập nhật User Account (PUT /api/users/{id})
```sql
-- Cập nhật thông tin user
UPDATE user_account 
SET password = 'new_password', role = 'MANAGER' 
WHERE id = 1;

-- Cập nhật chỉ password
UPDATE user_account 
SET password = 'new_password123' 
WHERE user_name = 'admin';

-- Stored procedure cập nhật user
DELIMITER //
CREATE PROCEDURE UpdateUserAccount(
    IN p_user_id BIGINT,
    IN p_password VARCHAR(255),
    IN p_role VARCHAR(255),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_exists FROM user_account WHERE id = p_user_id;
    
    IF v_exists = 0 THEN
        SET p_message = 'User không tồn tại';
    ELSE
        UPDATE user_account 
        SET password = COALESCE(p_password, password),
            role = COALESCE(p_role, role)
        WHERE id = p_user_id;
        
        SET p_message = 'Cập nhật thành công';
    END IF;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Cập nhật password cho user ID 1
CALL UpdateUserAccount(1, 'new_secure_password', NULL, @message);
SELECT @message as result;

-- Cập nhật role cho user ID 2
CALL UpdateUserAccount(2, NULL, 'MANAGER', @message);
SELECT @message as result;

-- Cập nhật cả password và role
CALL UpdateUserAccount(3, 'updated_password', 'ADMIN', @message);
SELECT @message as result;

-- Thử cập nhật user không tồn tại
CALL UpdateUserAccount(999, 'password', 'STAFF', @message);
SELECT @message as result;
```
```

##### Xóa User Account (DELETE /api/users/{id})
```sql
-- Xóa user (cần kiểm tra ràng buộc khóa ngoại trước)
DELETE FROM user_account WHERE id = 1;

-- Stored procedure xóa user an toàn
DELIMITER //
CREATE PROCEDURE DeleteUserAccount(
    IN p_user_id BIGINT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_customer_count INT DEFAULT 0;
    DECLARE v_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_exists FROM user_account WHERE id = p_user_id;
    
    IF v_exists = 0 THEN
        SET p_message = 'User không tồn tại';
    ELSE
        -- Kiểm tra user có được sử dụng bởi customer không
        SELECT COUNT(*) INTO v_customer_count FROM customer WHERE user_account_id = p_user_id;
        
        IF v_customer_count > 0 THEN
            SET p_message = 'Không thể xóa user đang được sử dụng bởi customer';
        ELSE
            DELETE FROM user_account WHERE id = p_user_id;
            SET p_message = 'Xóa user thành công';
        END IF;
    END IF;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Xóa user không có customer liên kết
CALL DeleteUserAccount(5, @message);
SELECT @message as result;

-- Thử xóa user có customer liên kết (sẽ thất bại)
CALL DeleteUserAccount(1, @message);
SELECT @message as result;

-- Thử xóa user không tồn tại
CALL DeleteUserAccount(999, @message);
SELECT @message as result;

-- Kiểm tra user có customer liên kết trước khi xóa
SELECT 
    u.id,
    u.user_name,
    COUNT(c.id) as customer_count
FROM user_account u
LEFT JOIN customer c ON u.id = c.user_account_id
WHERE u.id = 3
GROUP BY u.id, u.user_name;
```
```

#### 2.3.2. Quản lý Customer (API: /api/customers)

##### Tạo mới Customer (POST /api/customers)
```sql
-- Tạo customer mới
INSERT INTO customer (name, email, phone_number, user_account_id) 
VALUES ('Nguyễn Văn A', 'a@email.com', '0901234567', 1);

-- Stored procedure tạo customer
DELIMITER //
CREATE PROCEDURE CreateCustomer(
    IN p_name VARCHAR(255),
    IN p_email VARCHAR(255),
    IN p_phone_number VARCHAR(255),
    IN p_user_account_id BIGINT,
    OUT p_customer_id BIGINT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_user_exists INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_message = MESSAGE_TEXT;
        SET p_customer_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Kiểm tra user_account_id có tồn tại
    SELECT COUNT(*) INTO v_user_exists FROM user_account WHERE id = p_user_account_id;
    
    IF v_user_exists = 0 THEN
        SET p_message = 'User account không tồn tại';
        SET p_customer_id = -1;
        ROLLBACK;
    ELSE
        INSERT INTO customer (name, email, phone_number, user_account_id) 
        VALUES (p_name, p_email, p_phone_number, p_user_account_id);
        
        SET p_customer_id = LAST_INSERT_ID();
        SET p_message = 'Tạo customer thành công';
        COMMIT;
    END IF;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Tạo customer mới với user account có sẵn
CALL CreateCustomer('Nguyễn Văn A', 'nguyenvana@email.com', '0901234567', 1, @customer_id, @message);
SELECT @customer_id as customer_id, @message as result;

-- Tạo customer khác
CALL CreateCustomer('Trần Thị B', 'tranthib@email.com', '0987654321', 2, @customer_id, @message);
SELECT @customer_id as customer_id, @message as result;

-- Thử tạo customer với user account không tồn tại (sẽ thất bại)
CALL CreateCustomer('Lê Văn C', 'levanc@email.com', '0123456789', 999, @customer_id, @message);
SELECT @customer_id as customer_id, @message as result;

-- Tạo customer với thông tin đầy đủ
CALL CreateCustomer('Phạm Minh D', 'phamminhd@gmail.com', '0912345678', 3, @customer_id, @message);
SELECT @customer_id as customer_id, @message as result;
-- Sau đó kiểm tra thông tin vừa tạo
SELECT * FROM customer WHERE id = @customer_id;
```
```

##### Lấy thông tin Customer (GET /api/customers/{id}, GET /api/customers)
```sql
-- Lấy customer theo ID
SELECT * FROM customer WHERE id = 1;

-- Lấy tất cả customers
SELECT 
    c.*,
    u.user_name,
    u.role
FROM customer c
JOIN user_account u ON c.user_account_id = u.id
ORDER BY c.id;

-- Lấy customer theo email
SELECT * FROM customer WHERE email = 'a@email.com';

-- Lấy customer với thông tin user account
SELECT 
    c.id,
    c.name,
    c.email,
    c.phone_number,
    u.user_name,
    u.role
FROM customer c
JOIN user_account u ON c.user_account_id = u.id
WHERE c.id = 1;
```

##### Cập nhật Customer (PUT /api/customers/{id})
```sql
-- Cập nhật thông tin customer
UPDATE customer 
SET name = 'Nguyễn Văn B', 
    email = 'b@email.com', 
    phone_number = '0901234568'
WHERE id = 1;

-- Stored procedure cập nhật customer
DELIMITER //
CREATE PROCEDURE UpdateCustomer(
    IN p_customer_id BIGINT,
    IN p_name VARCHAR(255),
    IN p_email VARCHAR(255),
    IN p_phone_number VARCHAR(255),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_exists FROM customer WHERE id = p_customer_id;
    
    IF v_exists = 0 THEN
        SET p_message = 'Customer không tồn tại';
    ELSE
        UPDATE customer 
        SET name = COALESCE(p_name, name),
            email = COALESCE(p_email, email),
            phone_number = COALESCE(p_phone_number, phone_number)
        WHERE id = p_customer_id;
        
        SET p_message = 'Cập nhật customer thành công';
    END IF;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Cập nhật tên customer
CALL UpdateCustomer(1, 'Nguyễn Văn A - Updated', NULL, NULL, @message);
SELECT @message as result;

-- Cập nhật email và số điện thoại
CALL UpdateCustomer(2, NULL, 'new_email@domain.com', '0999888777', @message);
SELECT @message as result;

-- Cập nhật tất cả thông tin
CALL UpdateCustomer(3, 'Lê Thị C', 'lethic_new@email.com', '0876543210', @message);
SELECT @message as result;

-- Thử cập nhật customer không tồn tại
CALL UpdateCustomer(999, 'Test Name', 'test@email.com', '0123456789', @message);
SELECT @message as result;

-- Kiểm tra thông tin sau khi cập nhật
SELECT * FROM customer WHERE id = 1;
```
```

##### Xóa Customer (DELETE /api/customers/{id})
```sql
-- Xóa customer
DELETE FROM customer WHERE id = 1;

-- Stored procedure xóa customer an toàn
DELIMITER //
CREATE PROCEDURE DeleteCustomer(
    IN p_customer_id BIGINT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_contract_count INT DEFAULT 0;
    DECLARE v_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_exists FROM customer WHERE id = p_customer_id;
    
    IF v_exists = 0 THEN
        SET p_message = 'Customer không tồn tại';
    ELSE
        -- Kiểm tra customer có hợp đồng không
        SELECT COUNT(*) INTO v_contract_count FROM contract WHERE customer_id = p_customer_id;
        
        IF v_contract_count > 0 THEN
            SET p_message = 'Không thể xóa customer đang có hợp đồng';
        ELSE
            DELETE FROM customer WHERE id = p_customer_id;
            SET p_message = 'Xóa customer thành công';
        END IF;
    END IF;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Xóa customer không có hợp đồng
CALL DeleteCustomer(5, @message);
SELECT @message as result;

-- Thử xóa customer có hợp đồng (sẽ thất bại)
CALL DeleteCustomer(1, @message);
SELECT @message as result;

-- Thử xóa customer không tồn tại
CALL DeleteCustomer(999, @message);
SELECT @message as result;

-- Kiểm tra customer có hợp đồng trước khi xóa
SELECT 
    c.id,
    c.name,
    COUNT(ct.id) as contract_count
FROM customer c
LEFT JOIN contract ct ON c.id = ct.customer_id
WHERE c.id = 3
GROUP BY c.id, c.name;
```
```

#### 2.3.3. Quản lý District (API: /api/districts)

##### Tạo mới District (POST /api/districts)
```sql
-- Tạo district mới
INSERT INTO district (name, code, city, region) 
VALUES ('Quận 1', 'Q1', 'Hồ Chí Minh', 'Miền Nam');

-- Stored procedure tạo district
DELIMITER //
CREATE PROCEDURE CreateDistrict(
    IN p_name VARCHAR(255),
    IN p_code VARCHAR(255),
    IN p_city VARCHAR(255),
    IN p_region VARCHAR(255),
    OUT p_district_id BIGINT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_message = MESSAGE_TEXT;
        SET p_district_id = -1;
    END;
    
    START TRANSACTION;
    
    INSERT INTO district (name, code, city, region) 
    VALUES (p_name, p_code, p_city, p_region);
    
    SET p_district_id = LAST_INSERT_ID();
    SET p_message = 'Tạo district thành công';
    COMMIT;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Tạo quận mới ở Hồ Chí Minh
CALL CreateDistrict('Quận 1', 'Q1', 'Hồ Chí Minh', 'Miền Nam', @district_id, @message);
SELECT @district_id as district_id, @message as result;

-- Tạo quận ở Hà Nội
CALL CreateDistrict('Quận Ba Đình', 'BD', 'Hà Nội', 'Miền Bắc', @district_id, @message);
SELECT @district_id as district_id, @message as result;

-- Tạo huyện ở Đà Nẵng
CALL CreateDistrict('Quận Hải Châu', 'HC', 'Đà Nẵng', 'Miền Trung', @district_id, @message);
SELECT @district_id as district_id, @message as result;

-- Tạo nhiều district cùng lúc
CALL CreateDistrict('Quận 3', 'Q3', 'Hồ Chí Minh', 'Miền Nam', @id1, @msg1);
CALL CreateDistrict('Quận Hoàn Kiếm', 'HK', 'Hà Nội', 'Miền Bắc', @id2, @msg2);
SELECT @id1, @msg1, @id2, @msg2;
```
```

##### Lấy thông tin District
```sql
-- Lấy tất cả districts
SELECT * FROM district ORDER BY region, city, name;

-- Lấy district theo ID
SELECT * FROM district WHERE id = 1;

-- Lấy districts theo thành phố
SELECT * FROM district WHERE city = 'Hà Nội';

-- Lấy districts theo vùng miền
SELECT * FROM district WHERE region = 'Miền Bắc';
```

##### Cập nhật District
```sql
-- Cập nhật district
UPDATE district 
SET name = 'Quận Ba Đình', code = 'BD' 
WHERE id = 1;
```

##### Xóa District
```sql
-- Xóa district (cần kiểm tra buildings trước)
DELETE FROM district WHERE id = 1;
```

#### 2.3.4. Quản lý Building (API: /api/buildings)

##### Tạo mới Building (POST /api/buildings)
```sql
-- Tạo building mới
INSERT INTO building (name, address, contact_number, number_of_floors, total_area, type, district_id) 
VALUES ('Tòa nhà ABC', '123 Đường ABC', '0281234567', 20, 5000.0, 'APARTMENT', 1);

-- Stored procedure tạo building
DELIMITER //
CREATE PROCEDURE CreateBuilding(
    IN p_name VARCHAR(255),
    IN p_address VARCHAR(255),
    IN p_contact_number VARCHAR(255),
    IN p_number_of_floors INTEGER,
    IN p_total_area DOUBLE,
    IN p_type VARCHAR(255),
    IN p_district_id BIGINT,
    OUT p_building_id BIGINT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_district_exists INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_message = MESSAGE_TEXT;
        SET p_building_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Kiểm tra district có tồn tại
    SELECT COUNT(*) INTO v_district_exists FROM district WHERE id = p_district_id;
    
    IF v_district_exists = 0 THEN
        SET p_message = 'District không tồn tại';
        SET p_building_id = -1;
        ROLLBACK;
    ELSE
        INSERT INTO building (name, address, contact_number, number_of_floors, total_area, type, district_id) 
        VALUES (p_name, p_address, p_contact_number, p_number_of_floors, p_total_area, p_type, p_district_id);
        
        SET p_building_id = LAST_INSERT_ID();
        SET p_message = 'Tạo building thành công';
        COMMIT;
    END IF;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Tạo tòa nhà chung cư
CALL CreateBuilding('Vinhomes Central Park', '208 Nguyễn Hữu Cảnh', '02839101010', 45, 15000.0, 'APARTMENT', 1, @building_id, @message);
SELECT @building_id as building_id, @message as result;

-- Tạo tòa văn phòng
CALL CreateBuilding('Bitexco Financial Tower', '2 Hải Triều', '02838234567', 68, 12000.0, 'OFFICE', 1, @building_id, @message);
SELECT @building_id as building_id, @message as result;

-- Thử tạo building với district không tồn tại (sẽ thất bại)
CALL CreateBuilding('Test Building', 'Test Address', '0123456789', 10, 1000.0, 'APARTMENT', 999, @building_id, @message);
SELECT @building_id as building_id, @message as result;

-- Tạo building nhỏ
CALL CreateBuilding('Mini Apartment', '123 Test Street', '0987654321', 5, 800.0, 'APARTMENT', 2, @building_id, @message);
SELECT @building_id as building_id, @message as result;
-- Kiểm tra thông tin building vừa tạo
SELECT b.*, d.name as district_name FROM building b 
JOIN district d ON b.district_id = d.id 
WHERE b.id = @building_id;
```
```

##### Lấy thông tin Building (GET /api/buildings/{id}, GET /api/buildings/apartments/{districtId}, GET /api/buildings/analytics)
```sql
-- Lấy building theo ID
SELECT 
    b.*,
    d.name as district_name,
    d.city,
    d.region
FROM building b
JOIN district d ON b.district_id = d.id
WHERE b.id = 1;

-- Lấy tất cả buildings
SELECT 
    b.*,
    d.name as district_name,
    d.city
FROM building b
JOIN district d ON b.district_id = d.id
ORDER BY d.city, b.name;

-- Lấy buildings theo district (apartments by district)
SELECT 
    b.*,
    COUNT(a.id) as apartment_count,
    COUNT(CASE WHEN a.rented = 0 THEN 1 END) as available_apartments
FROM building b
JOIN district d ON b.district_id = d.id
LEFT JOIN apartment a ON b.id = a.building_id
WHERE d.id = 1
GROUP BY b.id
ORDER BY b.name;

-- Building analytics
SELECT 
    d.name as district_name,
    COUNT(b.id) as total_buildings,
    SUM(b.total_area) as total_area,
    COUNT(a.id) as total_apartments,
    COUNT(CASE WHEN a.rented = 1 THEN 1 END) as rented_apartments,
    COUNT(CASE WHEN a.rented = 0 THEN 1 END) as available_apartments,
    AVG(a.min_rate) as avg_rent
FROM district d
LEFT JOIN building b ON d.id = b.district_id
LEFT JOIN apartment a ON b.id = a.building_id
GROUP BY d.id, d.name
ORDER BY total_buildings DESC;
```

##### Cập nhật Building (PUT /api/buildings/{id})
```sql
-- Cập nhật building
UPDATE building 
SET name = 'Tòa nhà XYZ Updated',
    address = '456 Đường XYZ',
    contact_number = '0281234999',
    number_of_floors = 25
WHERE id = 1;

-- Stored procedure cập nhật building
DELIMITER //
CREATE PROCEDURE UpdateBuilding(
    IN p_building_id BIGINT,
    IN p_name VARCHAR(255),
    IN p_address VARCHAR(255),
    IN p_contact_number VARCHAR(255),
    IN p_number_of_floors INTEGER,
    IN p_total_area DOUBLE,
    IN p_type VARCHAR(255),
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_exists FROM building WHERE id = p_building_id;
    
    IF v_exists = 0 THEN
        SET p_message = 'Building không tồn tại';
    ELSE
        UPDATE building 
        SET name = COALESCE(p_name, name),
            address = COALESCE(p_address, address),
            contact_number = COALESCE(p_contact_number, contact_number),
            number_of_floors = COALESCE(p_number_of_floors, number_of_floors),
            total_area = COALESCE(p_total_area, total_area),
            type = COALESCE(p_type, type)
        WHERE id = p_building_id;
        
        SET p_message = 'Cập nhật building thành công';
    END IF;
END//
DELIMITER ;
```

##### Xóa Building (DELETE /api/buildings/{id})
```sql
-- Xóa building
DELETE FROM building WHERE id = 1;

-- Stored procedure xóa building an toàn
DELIMITER //
CREATE PROCEDURE DeleteBuilding(
    IN p_building_id BIGINT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_apartment_count INT DEFAULT 0;
    DECLARE v_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_exists FROM building WHERE id = p_building_id;
    
    IF v_exists = 0 THEN
        SET p_message = 'Building không tồn tại';
    ELSE
        -- Kiểm tra building có apartments không
        SELECT COUNT(*) INTO v_apartment_count FROM apartment WHERE building_id = p_building_id;
        
        IF v_apartment_count > 0 THEN
            SET p_message = 'Không thể xóa building đang có apartments';
        ELSE
            DELETE FROM building WHERE id = p_building_id;
            SET p_message = 'Xóa building thành công';
        END IF;
    END IF;
END//
DELIMITER ;
```

#### 2.3.5. Quản lý Apartment (API: /api/apartments, /fe/apartments)

##### Tạo mới Apartment (POST /api/apartments, POST /fe/apartments)
```sql
-- Tạo apartment mới
INSERT INTO apartment (name, floor_area, number_of_bedrooms, number_of_bathrooms, min_rate, rented, building_id) 
VALUES ('A1-101', 65.5, 2, 1, 8500000, 0, 1);

-- Stored procedure tạo apartment
DELIMITER //
CREATE PROCEDURE CreateApartment(
    IN p_name VARCHAR(255),
    IN p_floor_area DOUBLE,
    IN p_number_of_bedrooms INTEGER,
    IN p_number_of_bathrooms INTEGER,
    IN p_min_rate DOUBLE,
    IN p_building_id BIGINT,
    OUT p_apartment_id BIGINT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_building_exists INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_message = MESSAGE_TEXT;
        SET p_apartment_id = -1;
    END;
    
    START TRANSACTION;
    
    -- Kiểm tra building có tồn tại
    SELECT COUNT(*) INTO v_building_exists FROM building WHERE id = p_building_id;
    
    IF v_building_exists = 0 THEN
        SET p_message = 'Building không tồn tại';
        SET p_apartment_id = -1;
        ROLLBACK;
    ELSE
        INSERT INTO apartment (name, floor_area, number_of_bedrooms, number_of_bathrooms, min_rate, rented, building_id) 
        VALUES (p_name, p_floor_area, p_number_of_bedrooms, p_number_of_bathrooms, p_min_rate, 0, p_building_id);
        
        SET p_apartment_id = LAST_INSERT_ID();
        SET p_message = 'Tạo apartment thành công';
        COMMIT;
    END IF;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Tạo căn hộ 1 phòng ngủ
CALL CreateApartment('A01-101', 45.5, 1, 1, 6500000, 1, @apartment_id, @message);
SELECT @apartment_id as apartment_id, @message as result;

-- Tạo căn hộ 2 phòng ngủ
CALL CreateApartment('A02-205', 68.0, 2, 2, 9500000, 1, @apartment_id, @message);
SELECT @apartment_id as apartment_id, @message as result;

-- Tạo căn hộ cao cấp 3 phòng ngủ
CALL CreateApartment('A03-1501', 95.5, 3, 2, 15000000, 1, @apartment_id, @message);
SELECT @apartment_id as apartment_id, @message as result;

-- Thử tạo apartment với building không tồn tại (sẽ thất bại)
CALL CreateApartment('Test-001', 50.0, 1, 1, 5000000, 999, @apartment_id, @message);
SELECT @apartment_id as apartment_id, @message as result;

-- Tạo studio apartment
CALL CreateApartment('Studio-301', 35.0, 0, 1, 4500000, 2, @apartment_id, @message);
SELECT @apartment_id as apartment_id, @message as result;
-- Kiểm tra apartment vừa tạo
SELECT a.*, b.name as building_name FROM apartment a 
JOIN building b ON a.building_id = b.id 
WHERE a.id = @apartment_id;
```
```

##### Lấy thông tin Apartment (GET /api/apartments/{id}, GET /fe/apartments/{id}, GET /fe/apartments/search)
```sql
-- Lấy apartment theo ID
SELECT 
    a.*,
    b.name as building_name,
    b.address as building_address,
    d.name as district_name,
    d.city
FROM apartment a
JOIN building b ON a.building_id = b.id
JOIN district d ON b.district_id = d.id
WHERE a.id = 1;

-- Lấy tất cả apartments
SELECT 
    a.*,
    b.name as building_name,
    d.name as district_name
FROM apartment a
JOIN building b ON a.building_id = b.id
JOIN district d ON b.district_id = d.id
ORDER BY b.name, a.name;

-- Tìm kiếm apartments (search with filters)
SELECT 
    a.*,
    b.name as building_name,
    b.address,
    d.name as district_name
FROM apartment a
JOIN building b ON a.building_id = b.id
JOIN district d ON b.district_id = d.id
WHERE a.rented = 0
    AND (2 IS NULL OR a.number_of_bedrooms >= 2)  -- min bedrooms
    AND (15000000 IS NULL OR a.min_rate <= 15000000)  -- max rent
    AND (1 IS NULL OR d.id = 1)  -- district filter
    AND (70.0 IS NULL OR a.floor_area >= 70.0)  -- min area
ORDER BY a.min_rate ASC;

-- Apartment với equipment
SELECT 
    a.*,
    GROUP_CONCAT(e.name SEPARATOR ', ') as equipment_list
FROM apartment a
LEFT JOIN apartment_equipment ae ON a.id = ae.apartment_id
LEFT JOIN equipment e ON ae.equipment_id = e.id
WHERE a.id = 1
GROUP BY a.id;
```

##### Cập nhật Apartment (PUT /api/apartments/{id}, PUT /fe/apartments/{id})
```sql
-- Cập nhật apartment
UPDATE apartment 
SET name = 'A1-101-Updated',
    floor_area = 70.0,
    min_rate = 9000000,
    number_of_bedrooms = 3
WHERE id = 1;

-- Stored procedure cập nhật apartment
DELIMITER //
CREATE PROCEDURE UpdateApartment(
    IN p_apartment_id BIGINT,
    IN p_name VARCHAR(255),
    IN p_floor_area DOUBLE,
    IN p_number_of_bedrooms INTEGER,
    IN p_number_of_bathrooms INTEGER,
    IN p_min_rate DOUBLE,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_exists FROM apartment WHERE id = p_apartment_id;
    
    IF v_exists = 0 THEN
        SET p_message = 'Apartment không tồn tại';
    ELSE
        UPDATE apartment 
        SET name = COALESCE(p_name, name),
            floor_area = COALESCE(p_floor_area, floor_area),
            number_of_bedrooms = COALESCE(p_number_of_bedrooms, number_of_bedrooms),
            number_of_bathrooms = COALESCE(p_number_of_bathrooms, number_of_bathrooms),
            min_rate = COALESCE(p_min_rate, min_rate)
        WHERE id = p_apartment_id;
        
        SET p_message = 'Cập nhật apartment thành công';
    END IF;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Cập nhật tên căn hộ
CALL UpdateApartment(1, 'A01-101-Premium', NULL, NULL, NULL, NULL, @message);
SELECT @message as result;

-- Cập nhật diện tích và giá thuê
CALL UpdateApartment(2, NULL, 75.5, NULL, NULL, 11000000, @message);
SELECT @message as result;

-- Nâng cấp căn hộ (thêm phòng)
CALL UpdateApartment(3, NULL, 85.0, 3, 2, 13500000, @message);
SELECT @message as result;

-- Điều chỉnh giá thuê theo thị trường
CALL UpdateApartment(1, NULL, NULL, NULL, NULL, 9500000, @message);
SELECT @message as result;

-- Thử cập nhật căn hộ không tồn tại
CALL UpdateApartment(999, 'Test-001', 50.0, 1, 1, 5000000, @message);
SELECT @message as result;

-- Cập nhật toàn bộ thông tin căn hộ
CALL UpdateApartment(4, 'VIP-Penthouse', 120.0, 4, 3, 25000000, @message);
SELECT @message as result;

-- Kiểm tra thông tin căn hộ sau khi cập nhật
SELECT * FROM apartment WHERE id = 1;
```
```

##### Xóa Apartment (DELETE /api/apartments/{id}, DELETE /fe/apartments/{id})
```sql
-- Xóa apartment
DELETE FROM apartment WHERE id = 1;

-- Stored procedure xóa apartment an toàn
DELIMITER //
CREATE PROCEDURE DeleteApartment(
    IN p_apartment_id BIGINT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_contract_count INT DEFAULT 0;
    DECLARE v_equipment_count INT DEFAULT 0;
    DECLARE v_exists INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_message = MESSAGE_TEXT;
    END;
    
    START TRANSACTION;
    
    SELECT COUNT(*) INTO v_exists FROM apartment WHERE id = p_apartment_id;
    
    IF v_exists = 0 THEN
        SET p_message = 'Apartment không tồn tại';
        ROLLBACK;
    ELSE
        -- Kiểm tra apartment có hợp đồng không
        SELECT COUNT(*) INTO v_contract_count FROM contract WHERE apartment_id = p_apartment_id;
        
        IF v_contract_count > 0 THEN
            SET p_message = 'Không thể xóa apartment đang có hợp đồng';
            ROLLBACK;
        ELSE
            -- Xóa equipment associations trước
            DELETE FROM apartment_equipment WHERE apartment_id = p_apartment_id;
            
            -- Xóa apartment
            DELETE FROM apartment WHERE id = p_apartment_id;
            
            SET p_message = 'Xóa apartment thành công';
            COMMIT;
        END IF;
    END IF;
END//
DELIMITER ;
```

#### 2.3.6. Quản lý Contract (API: /api/contracts)

##### Tạo mới Contract (POST /api/contracts)
```sql
-- Tạo contract mới
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2025-06-10 00:00:00', '2026-06-10 00:00:00', 8500000, 17000000, 'ACTIVE');

-- Sử dụng stored procedure có sẵn
CALL CreateContract(1, 1, '2025-06-10 00:00:00', '2026-06-10 00:00:00', 8500000, 17000000, @contract_id, @message);
SELECT @contract_id, @message;

**Ví dụ thực thi:**
```sql
-- Tạo hợp đồng thuê 1 năm
CALL CreateContract(1, 1, '2025-07-01', '2026-07-01', 8500000, 17000000, @contract_id, @message);
SELECT @contract_id as contract_id, @message as result;

-- Tạo hợp đồng thuê 6 tháng
CALL CreateContract(2, 2, '2025-06-15', '2025-12-15', 12000000, 24000000, @contract_id, @message);
SELECT @contract_id as contract_id, @message as result;

-- Tạo hợp đồng thuê dài hạn 2 năm
CALL CreateContract(3, 3, '2025-08-01', '2027-08-01', 15000000, 30000000, @contract_id, @message);
SELECT @contract_id as contract_id, @message as result;

-- Thử tạo hợp đồng với apartment không tồn tại (sẽ thất bại)
CALL CreateContract(999, 1, '2025-07-01', '2026-07-01', 5000000, 10000000, @contract_id, @message);
SELECT @contract_id as contract_id, @message as result;

-- Thử tạo hợp đồng với customer không tồn tại (sẽ thất bại)
CALL CreateContract(1, 999, '2025-07-01', '2026-07-01', 5000000, 10000000, @contract_id, @message);
SELECT @contract_id as contract_id, @message as result;

-- Kiểm tra hợp đồng vừa tạo
SELECT c.*, cust.name as customer_name, a.name as apartment_name
FROM contract c
JOIN customer cust ON c.customer_id = cust.id
JOIN apartment a ON c.apartment_id = a.id
WHERE c.id = @contract_id;
```
```

##### Lấy thông tin Contract (GET /api/contracts/{id}, GET /api/contracts)
```sql
-- Lấy contract theo ID
SELECT 
    c.*,
    cust.name as customer_name,
    cust.email as customer_email,
    a.name as apartment_name,
    b.name as building_name
FROM contract c
JOIN customer cust ON c.customer_id = cust.id
JOIN apartment a ON c.apartment_id = a.id
JOIN building b ON a.building_id = b.id
WHERE c.id = 1;

-- Lấy tất cả contracts
SELECT 
    c.*,
    cust.name as customer_name,
    a.name as apartment_name,
    b.name as building_name
FROM contract c
JOIN customer cust ON c.customer_id = cust.id
JOIN apartment a ON c.apartment_id = a.id
JOIN building b ON a.building_id = b.id
ORDER BY c.start_date DESC;

-- Lấy contracts active
SELECT * FROM active_contracts;

-- Lấy contracts theo customer
SELECT 
    c.*,
    a.name as apartment_name,
    b.name as building_name
FROM contract c
JOIN apartment a ON c.apartment_id = a.id
JOIN building b ON a.building_id = b.id
WHERE c.customer_id = 1
ORDER BY c.start_date DESC;
```

##### Cập nhật Contract (PUT /api/contracts/{id})
```sql
-- Cập nhật contract
UPDATE contract 
SET monthly_rent = 9000000,
    payment_status = 'COMPLETED',
    end_date = '2025-12-31 00:00:00'
WHERE id = 1;

-- Stored procedure cập nhật contract
DELIMITER //
CREATE PROCEDURE UpdateContract(
    IN p_contract_id BIGINT,
    IN p_monthly_rent DOUBLE,
    IN p_deposit DOUBLE,
    IN p_payment_status VARCHAR(255),
    IN p_end_date DATETIME,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_exists FROM contract WHERE id = p_contract_id;
    
    IF v_exists = 0 THEN
        SET p_message = 'Contract không tồn tại';
    ELSE
        UPDATE contract 
        SET monthly_rent = COALESCE(p_monthly_rent, monthly_rent),
            deposit = COALESCE(p_deposit, deposit),
            payment_status = COALESCE(p_payment_status, payment_status),
            end_date = COALESCE(p_end_date, end_date)
        WHERE id = p_contract_id;
        
        SET p_message = 'Cập nhật contract thành công';
    END IF;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Cập nhật giá thuê hằng tháng
CALL UpdateContract(1, 9500000, NULL, NULL, NULL, @message);
SELECT @message as result;

-- Cập nhật trạng thái thanh toán
CALL UpdateContract(2, NULL, NULL, 'PAID', NULL, @message);
SELECT @message as result;

-- Gia hạn hợp đồng
CALL UpdateContract(3, NULL, NULL, NULL, '2026-12-31', @message);
SELECT @message as result;

-- Cập nhật cả giá thuê và deposit
CALL UpdateContract(1, 10000000, 20000000, NULL, NULL, @message);
SELECT @message as result;

-- Thử cập nhật hợp đồng không tồn tại
CALL UpdateContract(999, 5000000, NULL, NULL, NULL, @message);
SELECT @message as result;

-- Cập nhật trạng thái hoàn thành hợp đồng
CALL UpdateContract(4, NULL, NULL, 'COMPLETED', '2025-06-30', @message);
SELECT @message as result;

-- Kiểm tra thông tin hợp đồng sau khi cập nhật
SELECT * FROM contract WHERE id = 1;
```
```

##### Xóa Contract (DELETE /api/contracts/{id})
```sql
-- Xóa contract
DELETE FROM contract WHERE id = 1;

-- Sử dụng stored procedure kết thúc hợp đồng
CALL EndContract(1, '2025-12-31 00:00:00', @result);
SELECT @result;
```

#### 2.3.7. Quản lý Equipment

##### Tạo mới Equipment
```sql
-- Tạo equipment mới
INSERT INTO equipment (name, type, status, broken_fee) 
VALUES ('Tủ lạnh Samsung 400L', 'APPLIANCE', 'WORKING', 2500000);

-- Stored procedure tạo equipment
DELIMITER //
CREATE PROCEDURE CreateEquipment(
    IN p_name VARCHAR(255),
    IN p_type VARCHAR(255),
    IN p_status VARCHAR(255),
    IN p_broken_fee DOUBLE,
    OUT p_equipment_id BIGINT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_message = MESSAGE_TEXT;
        SET p_equipment_id = -1;
    END;
    
    START TRANSACTION;
    
    INSERT INTO equipment (name, type, status, broken_fee) 
    VALUES (p_name, p_type, p_status, p_broken_fee);
    
    SET p_equipment_id = LAST_INSERT_ID();
    SET p_message = 'Tạo equipment thành công';
    COMMIT;
END//
DELIMITER ;

**Ví dụ thực thi:**
```sql
-- Tạo thiết bị gia dụng
CALL CreateEquipment('Tủ lạnh Samsung 400L', 'APPLIANCE', 'WORKING', 2500000, @equipment_id, @message);
SELECT @equipment_id as equipment_id, @message as result;

-- Tạo nội thất
CALL CreateEquipment('Sofa da 3 chỗ ngồi', 'FURNITURE', 'WORKING', 1500000, @equipment_id, @message);
SELECT @equipment_id as equipment_id, @message as result;

-- Tạo thiết bị điện tử
CALL CreateEquipment('Smart TV 55 inch', 'ELECTRONICS', 'WORKING', 3000000, @equipment_id, @message);
SELECT @equipment_id as equipment_id, @message as result;

-- Tạo thiết bị an ninh
CALL CreateEquipment('Camera an ninh IP', 'SECURITY', 'WORKING', 800000, @equipment_id, @message);
SELECT @equipment_id as equipment_id, @message as result;

-- Tạo thiết bị bị hỏng
CALL CreateEquipment('Máy giặt cũ', 'APPLIANCE', 'BROKEN', 2000000, @equipment_id, @message);
SELECT @equipment_id as equipment_id, @message as result;

-- Tạo nhiều thiết bị cùng lúc
CALL CreateEquipment('Điều hòa Daikin 2HP', 'APPLIANCE', 'WORKING', 4000000, @id1, @msg1);
CALL CreateEquipment('Bàn làm việc gỗ', 'FURNITURE', 'WORKING', 1200000, @id2, @msg2);
CALL CreateEquipment('Máy nước nóng', 'APPLIANCE', 'MAINTENANCE', 1800000, @id3, @msg3);
SELECT @id1, @msg1, @id2, @msg2, @id3, @msg3;
```
```

##### Lấy thông tin Equipment
```sql
-- Lấy tất cả equipment
SELECT * FROM equipment ORDER BY type, name;

-- Lấy equipment theo ID
SELECT * FROM equipment WHERE id = 1;

-- Lấy equipment theo type
SELECT * FROM equipment WHERE type = 'APPLIANCE';

-- Lấy equipment theo status
SELECT * FROM equipment WHERE status = 'WORKING';

-- Lấy equipment trong apartment
SELECT * FROM apartment_equipment_view WHERE apartment_id = 1;
```

##### Cập nhật Equipment
```sql
-- Cập nhật equipment
UPDATE equipment 
SET status = 'MAINTENANCE', broken_fee = 3000000 
WHERE id = 1;

-- Cập nhật status (sẽ trigger log)
UPDATE equipment SET status = 'BROKEN' WHERE id = 1;
UPDATE equipment SET status = 'WORKING' WHERE id = 1;
```

##### Xóa Equipment
```sql
-- Xóa equipment (cần xóa associations trước)
DELETE FROM apartment_equipment WHERE equipment_id = 1;
DELETE FROM equipment WHERE id = 1;
```

#### 2.3.8. Quản lý Equipment trong Apartment

##### Thêm Equipment vào Apartment
```sql
-- Thêm equipment vào apartment
INSERT INTO apartment_equipment (apartment_id, equipment_id) VALUES (1, 1);

-- Sử dụng stored procedure
CALL ManageApartmentEquipment('ADD', 1, 1, @result);
SELECT @result;

**Ví dụ thực thi:**
```sql
-- Thêm tủ lạnh vào căn hộ 1
CALL ManageApartmentEquipment('ADD', 1, 1, @result);
SELECT @result as result_message;

-- Thêm TV vào căn hộ 1
CALL ManageApartmentEquipment('ADD', 1, 2, @result);
SELECT @result as result_message;

-- Thêm nhiều thiết bị vào căn hộ
CALL ManageApartmentEquipment('ADD', 1, 3, @result1); -- Sofa
CALL ManageApartmentEquipment('ADD', 1, 4, @result2); -- Điều hòa
CALL ManageApartmentEquipment('ADD', 1, 5, @result3); -- Máy giặt
SELECT @result1, @result2, @result3;

-- Thử thêm thiết bị đã có trong căn hộ (sẽ thất bại)
CALL ManageApartmentEquipment('ADD', 1, 1, @result);
SELECT @result as result_message;

-- Thêm thiết bị vào căn hộ khác
CALL ManageApartmentEquipment('ADD', 2, 1, @result);
SELECT @result as result_message;

-- Kiểm tra danh sách thiết bị trong căn hộ sau khi thêm
SELECT * FROM apartment_equipment_view WHERE apartment_id = 1;
```
```

##### Lấy danh sách Equipment trong Apartment
```sql
-- Lấy equipment của apartment
SELECT 
    e.*,
    ae.id as association_id
FROM apartment_equipment ae
JOIN equipment e ON ae.equipment_id = e.id
WHERE ae.apartment_id = 1;

-- Sử dụng view
SELECT * FROM apartment_equipment_view WHERE apartment_id = 1;
```

##### Xóa Equipment khỏi Apartment
```sql
-- Xóa equipment khỏi apartment
DELETE FROM apartment_equipment WHERE apartment_id = 1 AND equipment_id = 1;

-- Sử dụng stored procedure
CALL ManageApartmentEquipment('REMOVE', 1, 1, @result);
SELECT @result;

**Ví dụ thực thi:**
```sql
-- Xóa tủ lạnh khỏi căn hộ 1
CALL ManageApartmentEquipment('REMOVE', 1, 1, @result);
SELECT @result as result_message;

-- Xóa TV khỏi căn hộ 1
CALL ManageApartmentEquipment('REMOVE', 1, 2, @result);
SELECT @result as result_message;

-- Thử xóa thiết bị không có trong căn hộ (sẽ thất bại)
CALL ManageApartmentEquipment('REMOVE', 1, 999, @result);
SELECT @result as result_message;

-- Xóa nhiều thiết bị cùng lúc
CALL ManageApartmentEquipment('REMOVE', 1, 3, @result1);
CALL ManageApartmentEquipment('REMOVE', 1, 4, @result2);
SELECT @result1, @result2;

-- Thử thao tác không hợp lệ
CALL ManageApartmentEquipment('INVALID_ACTION', 1, 1, @result);
SELECT @result as result_message;

-- Kiểm tra danh sách thiết bị còn lại trong căn hộ
SELECT * FROM apartment_equipment_view WHERE apartment_id = 1;
```
```

#### 2.3.9. Authentication (API: /api/auth)

##### Đăng ký (POST /api/auth/register)
```sql
-- Thường được xử lý ở application layer, nhưng có thể sử dụng:
CALL CreateUserAccount('new_user', 'hashed_password', 'CUSTOMER', @user_id, @message);

-- Sau đó tạo customer profile nếu cần
CALL CreateCustomer('Tên khách hàng', 'email@domain.com', '0901234567', @user_id, @customer_id, @message);
```

##### Đăng nhập (POST /api/auth/login)
```sql
-- Xác thực user
SELECT 
    u.id,
    u.user_name,
    u.password,
    u.role,
    c.id as customer_id,
    c.name as customer_name
FROM user_account u
LEFT JOIN customer c ON u.id = c.user_account_id
WHERE u.user_name = 'username' AND u.password = 'hashed_password';
```

#### 2.3.10. Lệnh Utility và Quản lý Views

##### Quản lý Views
```sql
-- Tạo view mới
CREATE VIEW custom_view AS
SELECT a.id, a.name, b.name as building_name
FROM apartment a
JOIN building b ON a.building_id = b.id
WHERE a.rented = 0;

-- Xem danh sách views
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- Xem cấu trúc view
DESCRIBE apartment_details;
SHOW CREATE VIEW apartment_details;

-- Sửa view
ALTER VIEW apartment_details AS
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
    d.region,
    CASE WHEN a.rented = 1 THEN 'Đã thuê' ELSE 'Còn trống' END as status_text
FROM apartment a
JOIN building b ON a.building_id = b.id
JOIN district d ON b.district_id = d.id;

-- Xóa view
DROP VIEW IF EXISTS custom_view;
```

##### Quản lý Indexes
```sql
-- Tạo index mới
CREATE INDEX idx_custom ON table_name(column1, column2);

-- Xem danh sách indexes
SHOW INDEXES FROM apartment;
SHOW INDEXES FROM contract;

-- Xóa index
DROP INDEX idx_custom ON table_name;

-- Analyze index usage
EXPLAIN SELECT * FROM apartment WHERE rented = 0 AND number_of_bedrooms = 2;
```

##### Quản lý Stored Procedures và Functions
```sql
-- Xem danh sách procedures
SHOW PROCEDURE STATUS WHERE Db = DATABASE();

-- Xem danh sách functions
SHOW FUNCTION STATUS WHERE Db = DATABASE();

-- Xem code của procedure/function
SHOW CREATE PROCEDURE CreateContract;
SHOW CREATE FUNCTION CalculateTotalRent;

-- Xóa procedure/function
DROP PROCEDURE IF EXISTS CreateContract;
DROP FUNCTION IF EXISTS CalculateTotalRent;
```

##### Quản lý Triggers
```sql
-- Xem danh sách triggers
SHOW TRIGGERS;

-- Xem triggers của bảng cụ thể
SHOW TRIGGERS LIKE 'contract';

-- Xóa trigger
DROP TRIGGER IF EXISTS check_contract_dates;

-- Tạm thời disable trigger (MySQL không hỗ trợ trực tiếp)
-- Cần drop và recreate
```

### 2.4. Quản lý User và Phân Quyền trong MySQL

#### 2.4.1. Tạo User và Quản lý Authentication

##### Tạo User mới
```sql
-- Tạo user với password
CREATE USER 'apartment_admin'@'localhost' IDENTIFIED BY 'StrongPassword123!';
CREATE USER 'apartment_manager'@'localhost' IDENTIFIED BY 'ManagerPass456!';
CREATE USER 'apartment_staff'@'localhost' IDENTIFIED BY 'StaffPass789!';
CREATE USER 'apartment_readonly'@'localhost' IDENTIFIED BY 'ReadOnly321!';

-- Tạo user có thể kết nối từ bất kỳ host nào
CREATE USER 'apartment_app'@'%' IDENTIFIED BY 'AppPassword999!';

-- Tạo user với plugin authentication cụ thể
CREATE USER 'apartment_secure'@'localhost' IDENTIFIED WITH mysql_native_password BY 'SecurePass000!';
```

##### Xem danh sách Users
```sql
-- Xem tất cả users
SELECT User, Host, authentication_string, account_locked, password_expired 
FROM mysql.user;

-- Xem users của database hiện tại
SELECT DISTINCT User, Host 
FROM mysql.user 
WHERE User NOT IN ('mysql.session', 'mysql.sys', 'root');

-- Xem thông tin chi tiết user
SHOW GRANTS FOR 'apartment_admin'@'localhost';
```

##### Thay đổi mật khẩu User
```sql
-- Thay đổi password cho user
ALTER USER 'apartment_admin'@'localhost' IDENTIFIED BY 'NewStrongPassword456!';

-- Đặt password expire
ALTER USER 'apartment_staff'@'localhost' PASSWORD EXPIRE;

-- Đặt password không bao giờ expire
ALTER USER 'apartment_manager'@'localhost' PASSWORD EXPIRE NEVER;

-- Khóa/mở khóa account
ALTER USER 'apartment_readonly'@'localhost' ACCOUNT LOCK;
ALTER USER 'apartment_readonly'@'localhost' ACCOUNT UNLOCK;
```

##### Xóa User
```sql
-- Xóa user
DROP USER 'apartment_staff'@'localhost';
DROP USER IF EXISTS 'old_user'@'localhost';

-- Xóa nhiều users cùng lúc
DROP USER 'user1'@'localhost', 'user2'@'localhost';
```

#### 2.4.2. Phân Quyền Database và Table Level

##### Cấp quyền Database Level
```sql
-- Cấp toàn quyền database cho admin
GRANT ALL PRIVILEGES ON apartment_db.* TO 'apartment_admin'@'localhost';

-- Cấp quyền đọc toàn bộ database
GRANT SELECT ON apartment_db.* TO 'apartment_readonly'@'localhost';

-- Cấp quyền SELECT, INSERT, UPDATE cho manager
GRANT SELECT, INSERT, UPDATE ON apartment_db.* TO 'apartment_manager'@'localhost';

-- Cấp quyền CREATE, DROP cho admin
GRANT CREATE, DROP, ALTER ON apartment_db.* TO 'apartment_admin'@'localhost';
```

##### Cấp quyền Table Level
```sql
-- Cấp quyền trên bảng cụ thể
GRANT SELECT, INSERT, UPDATE ON apartment_db.apartment TO 'apartment_staff'@'localhost';
GRANT SELECT, INSERT, UPDATE ON apartment_db.contract TO 'apartment_staff'@'localhost';
GRANT SELECT ON apartment_db.customer TO 'apartment_staff'@'localhost';

-- Cấp quyền DELETE có điều kiện (thực tế cần implement ở application level)
GRANT SELECT, INSERT, UPDATE, DELETE ON apartment_db.equipment TO 'apartment_manager'@'localhost';

-- Cấp quyền chỉ đọc cho một số bảng
GRANT SELECT ON apartment_db.district TO 'apartment_readonly'@'localhost';
GRANT SELECT ON apartment_db.building TO 'apartment_readonly'@'localhost';
```

##### Cấp quyền Column Level
```sql
-- Cấp quyền trên cột cụ thể
GRANT SELECT (id, name, email, phone_number) ON apartment_db.customer TO 'apartment_staff'@'localhost';
GRANT UPDATE (payment_status) ON apartment_db.contract TO 'apartment_staff'@'localhost';

-- Cấp quyền INSERT với cột cụ thể
GRANT INSERT (name, email, phone_number, user_account_id) ON apartment_db.customer TO 'apartment_staff'@'localhost';
```

#### 2.4.3. Phân Quyền trên Views, Procedures và Functions

##### Cấp quyền trên Views
```sql
-- Cấp quyền SELECT trên views
GRANT SELECT ON apartment_db.apartment_details TO 'apartment_readonly'@'localhost';
GRANT SELECT ON apartment_db.active_contracts TO 'apartment_staff'@'localhost';
GRANT SELECT ON apartment_db.available_apartments TO 'apartment_staff'@'localhost';

-- Cấp quyền trên view báo cáo cho manager
GRANT SELECT ON apartment_db.monthly_revenue TO 'apartment_manager'@'localhost';
GRANT SELECT ON apartment_db.apartment_equipment_view TO 'apartment_manager'@'localhost';
```

##### Cấp quyền EXECUTE trên Stored Procedures
```sql
-- Cấp quyền thực thi procedures cho roles khác nhau
GRANT EXECUTE ON PROCEDURE apartment_db.CreateContract TO 'apartment_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE apartment_db.SearchApartments TO 'apartment_staff'@'localhost';
GRANT EXECUTE ON PROCEDURE apartment_db.ManageApartmentEquipment TO 'apartment_staff'@'localhost';

-- Procedures chỉ admin mới được thực thi
GRANT EXECUTE ON PROCEDURE apartment_db.CreateUserAccount TO 'apartment_admin'@'localhost';
GRANT EXECUTE ON PROCEDURE apartment_db.DeleteUserAccount TO 'apartment_admin'@'localhost';

-- Procedures báo cáo cho manager
GRANT EXECUTE ON PROCEDURE apartment_db.RevenueReport TO 'apartment_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE apartment_db.EndContract TO 'apartment_manager'@'localhost';
```

##### Cấp quyền EXECUTE trên Functions
```sql
-- Cấp quyền sử dụng functions
GRANT EXECUTE ON FUNCTION apartment_db.CalculateTotalRent TO 'apartment_staff'@'localhost';
GRANT EXECUTE ON FUNCTION apartment_db.GetApartmentStatus TO 'apartment_staff'@'localhost';

-- Functions chỉ manager trở lên mới được dùng
GRANT EXECUTE ON FUNCTION apartment_db.CalculateTotalRent TO 'apartment_manager'@'localhost';
```

#### 2.4.4. Tạo Roles và Quản lý Role-based Access

##### Tạo Roles (MySQL 8.0+)
```sql
-- Tạo các roles
CREATE ROLE 'apartment_admin_role';
CREATE ROLE 'apartment_manager_role';
CREATE ROLE 'apartment_staff_role';
CREATE ROLE 'apartment_readonly_role';
```

##### Cấp quyền cho Roles
```sql
-- Admin role
GRANT ALL PRIVILEGES ON apartment_db.* TO 'apartment_admin_role' WITH GRANT OPTION;

-- Manager role
GRANT SELECT, INSERT, UPDATE ON apartment_db.* TO 'apartment_manager_role';
GRANT DELETE ON apartment_db.equipment TO 'apartment_manager_role';
GRANT DELETE ON apartment_db.apartment_equipment TO 'apartment_manager_role';

-- Staff role
GRANT SELECT ON apartment_db.* TO 'apartment_staff_role';
GRANT INSERT, UPDATE ON apartment_db.customer TO 'apartment_staff_role';
GRANT INSERT, UPDATE ON apartment_db.contract TO 'apartment_staff_role';
GRANT INSERT, UPDATE, DELETE ON apartment_db.apartment_equipment TO 'apartment_staff_role';

-- Readonly role
GRANT SELECT ON apartment_db.apartment_details TO 'apartment_readonly_role';
GRANT SELECT ON apartment_db.available_apartments TO 'apartment_readonly_role';
GRANT SELECT ON apartment_db.apartment_equipment_view TO 'apartment_readonly_role';
```

##### Gán Roles cho Users
```sql
-- Gán roles cho users
GRANT 'apartment_admin_role' TO 'apartment_admin'@'localhost';
GRANT 'apartment_manager_role' TO 'apartment_manager'@'localhost';
GRANT 'apartment_staff_role' TO 'apartment_staff'@'localhost';
GRANT 'apartment_readonly_role' TO 'apartment_readonly'@'localhost';

-- Đặt default role
SET DEFAULT ROLE 'apartment_admin_role' TO 'apartment_admin'@'localhost';
SET DEFAULT ROLE 'apartment_manager_role' TO 'apartment_manager'@'localhost';
SET DEFAULT ROLE 'apartment_staff_role' TO 'apartment_staff'@'localhost';
SET DEFAULT ROLE 'apartment_readonly_role' TO 'apartment_readonly'@'localhost';
```

#### 2.4.5. Phân Quyền theo Nghiệp vụ Cụ thể

##### Quyền Admin (Quản trị viên hệ thống)
```sql
-- Admin có toàn quyền
GRANT ALL PRIVILEGES ON apartment_db.* TO 'apartment_admin'@'localhost' WITH GRANT OPTION;

-- Quyền quản lý user
GRANT CREATE USER, RELOAD, PROCESS, SHOW DATABASES ON *.* TO 'apartment_admin'@'localhost';

-- Quyền backup và restore
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON apartment_db.* TO 'backup_user'@'localhost';
```

##### Quyền Manager (Quản lý kinh doanh)
```sql
-- Manager có quyền quản lý hợp đồng và báo cáo
GRANT SELECT, INSERT, UPDATE ON apartment_db.contract TO 'apartment_manager'@'localhost';
GRANT SELECT, INSERT, UPDATE ON apartment_db.customer TO 'apartment_manager'@'localhost';
GRANT SELECT ON apartment_db.* TO 'apartment_manager'@'localhost';

-- Quyền thực thi các procedure quan trọng
GRANT EXECUTE ON PROCEDURE apartment_db.CreateContract TO 'apartment_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE apartment_db.EndContract TO 'apartment_manager'@'localhost';
GRANT EXECUTE ON PROCEDURE apartment_db.RevenueReport TO 'apartment_manager'@'localhost';

-- Quyền truy cập views báo cáo
GRANT SELECT ON apartment_db.monthly_revenue TO 'apartment_manager'@'localhost';
GRANT SELECT ON apartment_db.active_contracts TO 'apartment_manager'@'localhost';
```

##### Quyền Staff (Nhân viên)
```sql
-- Staff chỉ có quyền xem và cập nhật thông tin cơ bản
GRANT SELECT ON apartment_db.apartment TO 'apartment_staff'@'localhost';
GRANT SELECT ON apartment_db.building TO 'apartment_staff'@'localhost';
GRANT SELECT ON apartment_db.district TO 'apartment_staff'@'localhost';
GRANT SELECT, INSERT, UPDATE ON apartment_db.customer TO 'apartment_staff'@'localhost';

-- Quyền quản lý equipment
GRANT SELECT, INSERT, UPDATE ON apartment_db.equipment TO 'apartment_staff'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON apartment_db.apartment_equipment TO 'apartment_staff'@'localhost';

-- Quyền sử dụng procedure tìm kiếm
GRANT EXECUTE ON PROCEDURE apartment_db.SearchApartments TO 'apartment_staff'@'localhost';
GRANT EXECUTE ON PROCEDURE apartment_db.ManageApartmentEquipment TO 'apartment_staff'@'localhost';
```

##### Quyền Application User (Ứng dụng)
```sql
-- User cho ứng dụng web/mobile
CREATE USER 'apartment_app'@'%' IDENTIFIED BY 'SecureAppPassword123!';

-- Cấp quyền cần thiết cho application
GRANT SELECT, INSERT, UPDATE ON apartment_db.user_account TO 'apartment_app'@'%';
GRANT SELECT, INSERT, UPDATE ON apartment_db.customer TO 'apartment_app'@'%';
GRANT SELECT ON apartment_db.apartment TO 'apartment_app'@'%';
GRANT SELECT ON apartment_db.building TO 'apartment_app'@'%';
GRANT SELECT ON apartment_db.district TO 'apartment_app'@'%';
GRANT SELECT, INSERT, UPDATE ON apartment_db.contract TO 'apartment_app'@'%';
GRANT EXECUTE ON apartment_db.* TO 'apartment_app'@'%';

-- Quyền truy cập views
GRANT SELECT ON apartment_db.apartment_details TO 'apartment_app'@'%';
GRANT SELECT ON apartment_db.available_apartments TO 'apartment_app'@'%';
GRANT SELECT ON apartment_db.active_contracts TO 'apartment_app'@'%';
```

#### 2.4.6. Quản lý và Kiểm tra Quyền

##### Xem quyền của User
```sql
-- Xem tất cả quyền của user
SHOW GRANTS FOR 'apartment_manager'@'localhost';

-- Xem quyền hiện tại của session
SHOW GRANTS;
SHOW GRANTS FOR CURRENT_USER;

-- Xem quyền trên database cụ thể
SELECT * FROM information_schema.user_privileges WHERE grantee = "'apartment_staff'@'localhost'";

-- Xem quyền trên table cụ thể
SELECT * FROM information_schema.table_privileges 
WHERE grantee = "'apartment_staff'@'localhost'" 
AND table_schema = 'apartment_db';

-- Xem quyền trên column cụ thể
SELECT * FROM information_schema.column_privileges 
WHERE grantee = "'apartment_staff'@'localhost'" 
AND table_schema = 'apartment_db';
```

##### Thu hồi quyền (REVOKE)
```sql
-- Thu hồi quyền từ user
REVOKE DELETE ON apartment_db.customer FROM 'apartment_staff'@'localhost';
REVOKE ALL PRIVILEGES ON apartment_db.equipment FROM 'apartment_staff'@'localhost';

-- Thu hồi quyền EXECUTE
REVOKE EXECUTE ON PROCEDURE apartment_db.CreateContract FROM 'apartment_staff'@'localhost';

-- Thu hồi quyền GRANT OPTION
REVOKE GRANT OPTION ON apartment_db.* FROM 'apartment_manager'@'localhost';

-- Thu hồi role từ user
REVOKE 'apartment_staff_role' FROM 'apartment_staff'@'localhost';
```

#### 2.4.7. Security Best Practices

##### Tạo Connection Limits
```sql
-- Giới hạn số connection cho user
ALTER USER 'apartment_app'@'%' WITH MAX_CONNECTIONS_PER_HOUR 1000;
ALTER USER 'apartment_app'@'%' WITH MAX_QUERIES_PER_HOUR 10000;
ALTER USER 'apartment_app'@'%' WITH MAX_USER_CONNECTIONS 50;
```

##### SSL/TLS Requirements
```sql
-- Bắt buộc sử dụng SSL
ALTER USER 'apartment_app'@'%' REQUIRE SSL;
ALTER USER 'apartment_manager'@'localhost' REQUIRE X509;

-- Bắt buộc certificate cụ thể
ALTER USER 'apartment_admin'@'localhost' 
REQUIRE ISSUER '/C=US/ST=California/L=San Francisco/O=MyOrg/CN=MyCA'
AND SUBJECT '/C=US/ST=California/L=San Francisco/O=MyOrg/CN=apartment_admin';
```

##### Audit và Logging
```sql
-- Tạo bảng audit log
CREATE TABLE user_activity_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_name VARCHAR(255),
    action_type VARCHAR(100),
    table_name VARCHAR(255),
    record_id BIGINT,
    old_values JSON,
    new_values JSON,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45)
);

-- Trigger để log các thao tác quan trọng
DELIMITER //
CREATE TRIGGER audit_contract_changes
AFTER UPDATE ON contract
FOR EACH ROW
BEGIN
    INSERT INTO user_activity_log (user_name, action_type, table_name, record_id, old_values, new_values)
    VALUES (
        USER(),
        'UPDATE',
        'contract',
        NEW.id,
        JSON_OBJECT(
            'monthly_rent', OLD.monthly_rent,
            'payment_status', OLD.payment_status,
            'end_date', OLD.end_date
        ),
        JSON_OBJECT(
            'monthly_rent', NEW.monthly_rent,
            'payment_status', NEW.payment_status,
            'end_date', NEW.end_date
        )
    );
END//
DELIMITER ;
```

#### 2.4.8. Backup và Recovery Permissions

##### User cho Backup
```sql
-- Tạo user chuyên cho backup
CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'BackupSecure789!';

-- Cấp quyền backup
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON apartment_db.* TO 'backup_user'@'localhost';
GRANT RELOAD, PROCESS ON *.* TO 'backup_user'@'localhost';

-- Script backup
-- mysqldump -u backup_user -p apartment_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

##### User cho Monitoring
```sql
-- Tạo user cho monitoring tools
CREATE USER 'monitor_user'@'localhost' IDENTIFIED BY 'MonitorPass456!';

-- Cấp quyền monitoring
GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'monitor_user'@'localhost';
GRANT SELECT ON performance_schema.* TO 'monitor_user'@'localhost';
GRANT SELECT ON information_schema.* TO 'monitor_user'@'localhost';
```

#### 2.4.9. Ví dụ Scripts Tạo Complete User Setup

##### Script Setup cho Production Environment
```sql
-- ====================================
-- APARTMENT MANAGEMENT SYSTEM - USER SETUP
-- ====================================

-- 1. Tạo database
CREATE DATABASE IF NOT EXISTS apartment_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE apartment_db;

-- 2. Tạo users
CREATE USER 'apt_admin'@'localhost' IDENTIFIED BY 'AdminPass123!@#';
CREATE USER 'apt_manager'@'%' IDENTIFIED BY 'ManagerPass456!@#';
CREATE USER 'apt_staff'@'%' IDENTIFIED BY 'StaffPass789!@#';
CREATE USER 'apt_app'@'%' IDENTIFIED BY 'AppPass000!@#';
CREATE USER 'apt_readonly'@'%' IDENTIFIED BY 'ReadPass111!@#';
CREATE USER 'apt_backup'@'localhost' IDENTIFIED BY 'BackupPass222!@#';

-- 3. Tạo roles (MySQL 8.0+)
CREATE ROLE IF NOT EXISTS 'apartment_admin_role';
CREATE ROLE IF NOT EXISTS 'apartment_manager_role';
CREATE ROLE IF NOT EXISTS 'apartment_staff_role';
CREATE ROLE IF NOT EXISTS 'apartment_readonly_role';

-- 4. Cấp quyền cho roles
-- Admin role
GRANT ALL PRIVILEGES ON apartment_db.* TO 'apartment_admin_role' WITH GRANT OPTION;

-- Manager role
GRANT SELECT, INSERT, UPDATE ON apartment_db.* TO 'apartment_manager_role';
GRANT DELETE ON apartment_db.equipment TO 'apartment_manager_role';
GRANT DELETE ON apartment_db.apartment_equipment TO 'apartment_manager_role';

-- Staff role
GRANT SELECT ON apartment_db.* TO 'apartment_staff_role';
GRANT INSERT, UPDATE ON apartment_db.customer TO 'apartment_staff_role';
GRANT INSERT, UPDATE ON apartment_db.contract TO 'apartment_staff_role';
GRANT INSERT, UPDATE, DELETE ON apartment_db.apartment_equipment TO 'apartment_staff_role';

-- Readonly role
GRANT SELECT ON apartment_db.apartment_details TO 'apartment_readonly_role';
GRANT SELECT ON apartment_db.available_apartments TO 'apartment_readonly_role';
GRANT SELECT ON apartment_db.apartment_equipment_view TO 'apartment_readonly_role';

-- 5. Gán roles cho users
GRANT 'apartment_admin_role' TO 'apt_admin'@'localhost';
GRANT 'apartment_manager_role' TO 'apt_manager'@'%';
GRANT 'apartment_staff_role' TO 'apt_staff'@'%';
GRANT 'apartment_readonly_role' TO 'apt_readonly'@'%';

-- 6. Set default roles
SET DEFAULT ROLE 'apartment_admin_role' TO 'apt_admin'@'localhost';
SET DEFAULT ROLE 'apartment_manager_role' TO 'apt_manager'@'%';
SET DEFAULT ROLE 'apartment_staff_role' TO 'apt_staff'@'%';
SET DEFAULT ROLE 'apartment_readonly_role' TO 'apt_readonly'@'%';

-- 7. Application user permissions
GRANT SELECT, INSERT, UPDATE ON apartment_db.user_account TO 'apt_app'@'%';
GRANT SELECT, INSERT, UPDATE ON apartment_db.customer TO 'apt_app'@'%';
GRANT SELECT ON apartment_db.apartment TO 'apt_app'@'%';
GRANT SELECT ON apartment_db.building TO 'apt_app'@'%';
GRANT SELECT ON apartment_db.district TO 'apt_app'@'%';
GRANT SELECT, INSERT, UPDATE ON apartment_db.contract TO 'apt_app'@'%';
GRANT EXECUTE ON apartment_db.* TO 'apt_app'@'%';

-- 8. Backup user permissions
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON apartment_db.* TO 'apt_backup'@'localhost';
GRANT RELOAD, PROCESS ON *.* TO 'apt_backup'@'localhost';

-- 9. Security settings
ALTER USER 'apt_app'@'%' WITH MAX_CONNECTIONS_PER_HOUR 1000;
ALTER USER 'apt_app'@'%' WITH MAX_QUERIES_PER_HOUR 10000;
ALTER USER 'apt_app'@'%' WITH MAX_USER_CONNECTIONS 50;

-- Require SSL for remote connections
ALTER USER 'apt_manager'@'%' REQUIRE SSL;
ALTER USER 'apt_staff'@'%' REQUIRE SSL;
ALTER USER 'apt_app'@'%' REQUIRE SSL;

-- 10. Apply all changes
FLUSH PRIVILEGES;

-- ====================================
-- Verification Commands
-- ====================================
-- SHOW GRANTS FOR 'apt_admin'@'localhost';
-- SHOW GRANTS FOR 'apt_manager'@'%';
-- SHOW GRANTS FOR 'apt_staff'@'%';
-- SHOW GRANTS FOR 'apt_app'@'%';
-- SELECT User, Host FROM mysql.user WHERE User LIKE 'apt_%';

**Ví dụ thực thi:**
```sql
-- Kiểm tra users đã được tạo
SELECT User, Host, account_locked, password_expired 
FROM mysql.user 
WHERE User LIKE 'apt_%';

-- Kiểm tra quyền của từng user
SHOW GRANTS FOR 'apt_admin'@'localhost';
SHOW GRANTS FOR 'apt_manager'@'%';
SHOW GRANTS FOR 'apt_staff'@'%';
SHOW GRANTS FOR 'apt_app'@'%';
SHOW GRANTS FOR 'apt_readonly'@'%';
SHOW GRANTS FOR 'apt_backup'@'localhost';

-- Kiểm tra roles (MySQL 8.0+)
SELECT * FROM mysql.role_edges WHERE TO_USER LIKE 'apt_%';

-- Kiểm tra connection limits
SELECT User, Host, max_connections, max_user_connections 
FROM mysql.user 
WHERE User LIKE 'apt_%';

-- Test kết nối database
USE apartment_db;
SHOW TABLES;
```
```

#### 2.4.10. Testing và Validation

##### Test Connection và Permissions
```sql
-- Test script để kiểm tra permissions
-- Chạy với từng user để verify permissions

-- Test as apt_staff user:
-- mysql -u apt_staff -p -h hostname apartment_db

-- Test basic permissions
SELECT COUNT(*) FROM apartment;  -- Should work
SELECT COUNT(*) FROM customer;   -- Should work
INSERT INTO customer (name, email, phone_number, user_account_id) 
VALUES ('Test Customer', 'test@test.com', '0123456789', 1);  -- Should work
DELETE FROM customer WHERE name = 'Test Customer';  -- Should fail for staff

-- Test procedure execution
CALL SearchApartments(2, 10000000, NULL, NULL);  -- Should work for staff
CALL CreateContract(1, 1, NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR), 5000000, 10000000, @id, @msg);  -- Should fail for staff

-- Test views
SELECT * FROM apartment_details LIMIT 5;  -- Should work
SELECT * FROM monthly_revenue;  -- Should fail for staff
```

**Ví dụ thực thi chi tiết:**
```sql
-- ========================================
-- TEST SUITE CHO PHÂN QUYỀN HỆ THỐNG
-- ========================================

-- Test 1: Kiểm tra quyền của apt_admin
-- mysql -u apt_admin -p apartment_db
SELECT 'Testing apt_admin permissions' as test_name;
SELECT COUNT(*) as total_users FROM user_account;
CALL CreateUserAccount('test_admin', 'pass123', 'CUSTOMER', @id, @msg);
SELECT @id, @msg;
-- Cleanup
DELETE FROM user_account WHERE user_name = 'test_admin';

-- Test 2: Kiểm tra quyền của apt_manager
-- mysql -u apt_manager -p apartment_db
SELECT 'Testing apt_manager permissions' as test_name;
SELECT COUNT(*) as total_contracts FROM contract;
-- Should work: create contract
CALL CreateContract(1, 1, '2025-07-01', '2026-07-01', 8000000, 16000000, @contract_id, @msg);
SELECT @contract_id, @msg;
-- Should work: view revenue
SELECT * FROM monthly_revenue LIMIT 3;
-- Should fail: create user account
-- CALL CreateUserAccount('test_manager', 'pass123', 'CUSTOMER', @id, @msg); -- Will fail

-- Test 3: Kiểm tra quyền của apt_staff
-- mysql -u apt_staff -p apartment_db
SELECT 'Testing apt_staff permissions' as test_name;
-- Should work: view apartments
SELECT COUNT(*) as available_apartments FROM available_apartments;
-- Should work: manage equipment
CALL ManageApartmentEquipment('ADD', 1, 1, @result);
SELECT @result;
-- Should fail: delete contracts
-- DELETE FROM contract WHERE id = 1; -- Will fail

-- Test 4: Kiểm tra quyền của apt_readonly
-- mysql -u apt_readonly -p apartment_db
SELECT 'Testing apt_readonly permissions' as test_name;
-- Should work: view data
SELECT COUNT(*) FROM apartment_details;
SELECT * FROM available_apartments LIMIT 5;
-- Should fail: insert data
-- INSERT INTO customer (name, email) VALUES ('Test', 'test@test.com'); -- Will fail

-- Test 5: Kiểm tra Connection Limits
SHOW PROCESSLIST;
SELECT 
    USER,
    HOST,
    COMMAND,
    TIME,
    STATE 
FROM information_schema.PROCESSLIST 
WHERE USER LIKE 'apt_%';

-- Test 6: Kiểm tra SSL Requirements
SHOW STATUS LIKE 'Ssl_cipher';
SELECT 
    connection_id,
    user,
    host,
    ssl_cipher
FROM performance_schema.session_status 
WHERE VARIABLE_NAME = 'Ssl_cipher';
```

## 3. KẾT LUẬN

Hệ thống quản lý căn hộ đã được thiết kế và triển khai hoàn chỉnh với đầy đủ các chức năng cần thiết:

### 3.1. Tổng Kết Chức Năng
- **Views**: 5 views chính cung cấp khung nhìn tổng hợp về dữ liệu
- **Stored Procedures**: 15+ procedures xử lý logic nghiệp vụ phức tạp
- **Phân Quyền**: Hệ thống role-based access control chi tiết
- **API Endpoints**: Đầy đủ CRUD operations cho tất cả entities
- **Security**: Audit logging, SSL requirements, connection limits

### 3.2. Ưu Điểm Hệ Thống
- **Tính Toàn Vẹn**: Foreign key constraints đảm bảo data integrity
- **Hiệu Suất**: Indexes được tối ưu cho các truy vấn thường xuyên  
- **Bảo Mật**: Multi-layer security với user roles và permissions
- **Mở Rộng**: Dễ dàng thêm features mới qua stored procedures
- **Audit Trail**: Tracking đầy đủ các thay đổi quan trọng

### 3.3. Khuyến Nghị Triển Khai
- Sử dụng connection pooling cho production
- Backup database hàng ngày với user backup chuyên dụng
- Monitor performance qua performance_schema
- Implement application-level caching cho views
- Regular security audits cho user permissions
