# 🏢 APARTMENT DATABASE - TRIGGER TESTING DOCUMENTATION

## 📋 Tổng quan

Workspace này chứa hệ thống cơ sở dữ liệu quản lý căn hộ MySQL hoàn chỉnh với các file test trigger đa dạng để kiểm thử chức năng.

## 📁 Cấu trúc File

### 🗄️ File Database Chính
- **`complete_apartment_database.sql`** - File database chính, đã sắp xếp logic, có thể chạy một lần từ đầu
- **`apartment_extensions.sql`** - File mở rộng với các tính năng nâng cao
- **`INSERT_DATA_COMMANDS.sql`** - Lệnh chèn dữ liệu mẫu

### 🧪 File Test Trigger

| File | Độ phức tạp | Thời gian | Mục đích |
|------|-------------|-----------|----------|
| `testtrigger.sql` | ⭐ Cơ bản | 5-10 phút | Kiểm thử cơ bản, dễ hiểu |
| `enhanced_trigger_tests.sql` | ⭐⭐⭐ Nâng cao | 15-30 phút | Kiểm thử toàn diện, stress test |
| `simple_trigger_test.sql` | ⭐ Tối thiểu | 2-5 phút | Test nhanh, debug |
| `quick_trigger_summary.sql` | - | 1 phút | Tổng quan và hướng dẫn |

### 🛠️ File Tiện ích
- **`apartment_db_backup.sh`** - Script backup database
- **`validate_backup.sh`** - Script kiểm tra backup

## 🎯 Các Trigger Được Test

### 1. `check_contract_dates`
**Mục đích:** Kiểm tra tính hợp lệ của ngày trong hợp đồng

**Quy tắc kiểm tra:**
- Ngày kết thúc phải sau ngày bắt đầu
- Ngày bắt đầu không được trong quá khứ
- Ngày bắt đầu không được bằng ngày kết thúc

**Test cases:**
- ❌ Ngày kết thúc trước ngày bắt đầu
- ❌ Ngày bắt đầu trong quá khứ  
- ❌ Ngày bắt đầu = ngày kết thúc
- ✅ Contract hợp lệ ngắn hạn
- ✅ Contract hợp lệ dài hạn
- ❌ UPDATE contract không hợp lệ

### 2. `log_equipment_status_change`
**Mục đích:** Ghi log mỗi khi status thiết bị thay đổi

**Hoạt động:**
- Tự động tạo record trong `equipment_status_log`
- Lưu trữ old_status, new_status, timestamp
- Chỉ kích hoạt khi thay đổi status, không phải thuộc tính khác

**Test cases:**
- ✅ WORKING → MAINTENANCE
- ✅ MAINTENANCE → BROKEN
- ✅ BROKEN → WORKING
- ➖ Đổi thuộc tính khác (không tạo log)
- ✅ Đổi status + thuộc tính khác
- ✅ Đổi nhiều equipment cùng lúc

### 3. `update_apartment_rented_status`
**Mục đích:** Tự động cập nhật trạng thái thuê căn hộ

**Hoạt động:**
- Khi tạo contract mới → apartment.rented = 1
- Tự động đồng bộ trạng thái thuê

**Test cases:**
- ✅ Tạo contract đơn lẻ
- ✅ Tạo contract cho apartment khác
- ✅ Tạo nhiều contract cùng lúc

## 🚀 Hướng dẫn sử dụng

### Bước 1: Setup Database
```bash
# Chạy file database chính
mysql -u root -p < complete_apartment_database.sql

# Hoặc trong MySQL CLI:
mysql> source /path/to/complete_apartment_database.sql;
```

### Bước 2: Chọn file test phù hợp

#### 🔰 Người mới bắt đầu
```bash
mysql -u root -p apartment_db1 < testtrigger.sql
```
- Test cơ bản với hướng dẫn chi tiết
- Comment giải thích rõ ràng
- Dễ hiểu cách trigger hoạt động

#### 🔬 Kiểm thử chuyên sâu
```bash
mysql -u root -p apartment_db1 < enhanced_trigger_tests.sql
```
- 19 test cases toàn diện
- Stress test và edge cases
- Báo cáo chi tiết kết quả

#### ⚡ Debug nhanh
```bash
mysql -u root -p apartment_db1 < simple_trigger_test.sql
```
- Lệnh test ngắn gọn
- Ít comment, tập trung code
- Phù hợp debug nhanh

#### 📊 Xem tổng quan
```bash
mysql -u root -p apartment_db1 < quick_trigger_summary.sql
```
- Thông tin về các file test
- Trạng thái hiện tại database
- Hướng dẫn chọn file phù hợp

### Bước 3: Thực hiện test thủ công

1. **Chạy file test để xem cấu trúc**
2. **Copy lệnh trong `/* */` comments**
3. **Paste vào MySQL CLI hoặc Workbench**
4. **Quan sát kết quả:**
   - ✅ Lệnh thành công → Trigger cho phép
   - ❌ Lệnh bị lỗi → Trigger chặn (đúng mục đích)
5. **Sử dụng lệnh reset để test lại**

## 📝 Ví dụ Test Thực tế

### Test Trigger check_contract_dates

```sql
-- Lệnh này SẼ BỊ LỖI (ngày kết thúc trước ngày bắt đầu)
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2025-12-01', '2025-06-01', 6500000, 13000000, 'ACTIVE');

-- Kết quả mong đợi: ERROR 1644 (45000): End date must be after start date
```

```sql
-- Lệnh này SẼ THÀNH CÔNG (ngày hợp lệ)
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (1, 1, '2025-07-01', '2026-07-01', 6500000, 13000000, 'ACTIVE');

-- Kết quả mong đợi: Query OK, 1 row affected
```

### Test Trigger log_equipment_status_change

```sql
-- Kiểm tra log trước khi test
SELECT * FROM equipment_status_log ORDER BY change_timestamp DESC LIMIT 3;

-- Thay đổi status (sẽ tạo log)
UPDATE equipment SET status = 'MAINTENANCE' WHERE id = 1;

-- Kiểm tra log sau khi test (sẽ có record mới)
SELECT * FROM equipment_status_log ORDER BY change_timestamp DESC LIMIT 3;
```

### Test Trigger update_apartment_rented_status

```sql
-- Kiểm tra trạng thái apartment trước test
SELECT id, name, rented FROM apartment WHERE id = 5;

-- Tạo contract mới (sẽ tự động update rented = 1)
INSERT INTO contract (apartment_id, customer_id, start_date, end_date, monthly_rent, deposit, payment_status) 
VALUES (5, 3, '2025-09-01', '2026-09-01', 12500000, 25000000, 'ACTIVE');

-- Kiểm tra trạng thái sau test (rented sẽ = 1)
SELECT id, name, rented FROM apartment WHERE id = 5;
```

## 🔄 Reset Data để Test Lại

Mỗi file test đều có phần **RESET** ở cuối. Copy toàn bộ block reset để về trạng thái ban đầu:

```sql
-- Xóa contracts test (giữ lại 3 contracts gốc)
DELETE FROM contract WHERE id > 3;

-- Reset apartment status
UPDATE apartment SET rented = 0 WHERE id NOT IN (2, 4, 7);
UPDATE apartment SET rented = 1 WHERE id IN (2, 4, 7);

-- Xóa equipment logs test
DELETE FROM equipment_status_log;

-- Reset equipment status
UPDATE equipment SET status = 'WORKING' WHERE id NOT IN (5, 10);
UPDATE equipment SET status = 'MAINTENANCE' WHERE id = 5;
UPDATE equipment SET status = 'BROKEN' WHERE id = 10;
```

## ⚠️ Lưu ý Quan trọng

### Kết quả Mong đợi
- **Một số test SẼ BỊ LỖI** - đây là mục đích để kiểm tra trigger chặn dữ liệu sai
- **Kiểm tra message lỗi** để đảm bảo trigger hoạt động đúng
- **Chỉ các test hợp lệ mới thành công**

### Best Practices
1. **Luôn chạy reset trước khi test lại**
2. **Đọc kỹ comment để hiểu mục đích test**
3. **So sánh kết quả với mong đợi**
4. **Test từng lệnh riêng lẻ thay vì chạy hàng loạt**

### Troubleshooting
- Nếu trigger không hoạt động → Kiểm tra `SHOW TRIGGERS`
- Nếu lỗi syntax → Kiểm tra MySQL version compatibility
- Nếu không thể reset → Chạy lại `complete_apartment_database.sql`

## 📊 Báo cáo Test

File `enhanced_trigger_tests.sql` cung cấp báo cáo chi tiết:

- **Contracts Report:** Tổng số, tỷ lệ active, thời hạn trung bình
- **Equipment Logs Report:** Số lượng log, equipment có thay đổi
- **Apartments Report:** Tỷ lệ ocupancy, số lượng trống/thuê

## 🎯 Kết luận

Hệ thống test trigger này cung cấp:

✅ **Kiểm thử toàn diện** - 19+ test cases covering edge cases  
✅ **Dễ sử dụng** - Copy-paste commands với hướng dẫn chi tiết  
✅ **Linh hoạt** - Nhiều mức độ phức tạp phù hợp mọi nhu cầu  
✅ **Reset dễ dàng** - Có thể test lại nhiều lần  
✅ **Báo cáo chi tiết** - Phân tích kết quả test  

Bắt đầu với `testtrigger.sql` nếu bạn mới làm quen, hoặc `enhanced_trigger_tests.sql` để kiểm thử chuyên sâu!
