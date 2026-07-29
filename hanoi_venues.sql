-- Tự động thêm cột sports_type vào bảng venues nếu chưa tồn tại
ALTER TABLE venues ADD COLUMN IF NOT EXISTS sports_type VARCHAR(50);

-- Đảm bảo định dạng cột open_time và close_time là VARCHAR(5) để lưu giờ:phút (không có giây)
ALTER TABLE venues ALTER COLUMN open_time TYPE VARCHAR(5) USING NULL;
ALTER TABLE venues ALTER COLUMN close_time TYPE VARCHAR(5) USING NULL;

-- Xóa dữ liệu cũ trong bảng venues (Tùy chọn, nếu bạn muốn làm sạch bảng trước)
-- TRUNCATE TABLE venues CASCADE;

-- 1. Môn Pickleball (10 bản ghi)
INSERT INTO venues (id, name, address, rating, open_time, close_time, latitude, longitude, sports_type) VALUES
('10000000-0000-0000-0000-000000000001', 'Sân Pickleball Ba Đình', '15 Hoàng Hoa Thám, Phường Thụy Khuê, Quận Ba Đình, Hà Nội', 4.8, '05:00', '22:00', 21.0415, 105.8285, 'Pickleball'),
('10000000-0000-0000-0000-000000000002', 'Sân Pickleball Cầu Giấy', '26 Trần Thái Tông, Phường Dịch Vọng, Quận Cầu Giấy, Hà Nội', 4.6, '06:00', '22:00', 21.0285, 105.7820, 'Pickleball'),
('10000000-0000-0000-0000-000000000003', 'Sân Pickleball Tây Hồ', '68 Võ Chí Công, Phường Xuân La, Quận Tây Hồ, Hà Nội', 4.7, '05:00', '23:00', 21.0720, 105.8030, 'Pickleball'),
('10000000-0000-0000-0000-000000000004', 'Sân Pickleball Đống Đa', '12 Chùa Bộc, Phường Quang Trung, Quận Đống Đa, Hà Nội', 4.5, '06:00', '22:30', 21.0080, 105.8285, 'Pickleball'),
('10000000-0000-0000-0000-000000000005', 'Sân Pickleball Thanh Xuân', '156 Nguyễn Tuân, Phường Nhân Chính, Quận Thanh Xuân, Hà Nội', 4.4, '05:30', '22:00', 20.9972, 105.8015, 'Pickleball'),
('10000000-0000-0000-0000-000000000006', 'Sân Pickleball Hà Đông', 'Khu Đô Thị Mộ Lao, Quận Hà Đông, Hà Nội', 4.3, '06:00', '22:00', 20.9815, 105.7860, 'Pickleball'),
('10000000-0000-0000-0000-000000000007', 'Sân Pickleball Long Biên', 'Ngõ 124 Vũ Xuân Thiều, Phường Sài Đồng, Quận Long Biên, Hà Nội', 4.5, '05:00', '22:00', 21.0315, 105.9080, 'Pickleball'),
('10000000-0000-0000-0000-000000000008', 'Sân Pickleball Hai Bà Trưng', '8 Hàng Chuối, Phường Phạm Đình Hổ, Quận Hai Bà Trưng, Hà Nội', 4.6, '06:00', '23:00', 21.0185, 105.8580, 'Pickleball'),
('10000000-0000-0000-0000-000000000009', 'Sân Pickleball Nam Từ Liêm', 'KĐT Mỹ Đình 2, Phường Mỹ Đình, Quận Nam Từ Liêm, Hà Nội', 4.7, '05:00', '22:00', 21.0295, 105.7690, 'Pickleball'),
('10000000-0000-0000-0000-000000000010', 'Sân Pickleball Hoàn Kiếm', '4 Dã Tượng, Phường Trần Hưng Đạo, Quận Hoàn Kiếm, Hà Nội', 4.9, '06:00', '22:00', 21.0235, 105.8480, 'Pickleball')
ON CONFLICT (id) DO UPDATE SET 
  latitude = EXCLUDED.latitude, 
  longitude = EXCLUDED.longitude, 
  sports_type = EXCLUDED.sports_type;

-- 2. Môn Cầu lông (10 bản ghi)
INSERT INTO venues (id, name, address, rating, open_time, close_time, latitude, longitude, sports_type) VALUES
('20000000-0000-0000-0000-000000000001', 'Sân Cầu Lông Ba Đình', 'Nhà thi đấu Quần Ngựa, Đường Liễu Giai, Quận Ba Đình, Hà Nội', 4.5, '05:00', '22:00', 21.0385, 105.8150, 'Cầu lông'),
('20000000-0000-0000-0000-000000000002', 'Sân Cầu Lông Cầu Giấy', '35 Nguyễn Phong Sắc, Phường Dịch Vọng, Quận Cầu Giấy, Hà Nội', 4.4, '05:30', '22:00', 21.0345, 105.7895, 'Cầu lông'),
('20000000-0000-0000-0000-000000000003', 'Sân Cầu Lông Đống Đa', 'CLB Thể thao Hoàng Cầu, Phường Ô Chợ Dừa, Quận Đống Đa, Hà Nội', 4.3, '06:00', '22:30', 21.0175, 105.8205, 'Cầu lông'),
('20000000-0000-0000-0000-000000000004', 'Sân Cầu Lông Tây Hồ', 'CLB Thể thao Xuân La, Đường Xuân La, Quận Tây Hồ, Hà Nội', 4.2, '05:00', '22:00', 21.0675, 105.8080, 'Cầu lông'),
('20000000-0000-0000-0000-000000000005', 'Sân Cầu Lông Thanh Xuân', '9 Khuất Duy Tiến, Phường Thanh Xuân Bắc, Quận Thanh Xuân, Hà Nội', 4.5, '05:30', '23:00', 20.9930, 105.7980, 'Cầu lông'),
('20000000-0000-0000-0000-000000000006', 'Sân Cầu Lông Hà Đông', 'Nhà thi đấu Hà Đông, 182 Quang Trung, Quận Hà Đông, Hà Nội', 4.4, '06:00', '22:00', 20.9705, 105.7760, 'Cầu lông'),
('20000000-0000-0000-0000-000000000007', 'Sân Cầu Lông Long Biên', '12 Đàm Quang Trung, Phường Long Biên, Quận Long Biên, Hà Nội', 4.1, '05:00', '22:00', 21.0255, 105.8920, 'Cầu lông'),
('20000000-0000-0000-0000-000000000008', 'Sân Cầu Lông Hai Bà Trưng', 'CLB Thể thao Bách Khoa, Đường Tạ Quang Bửu, Quận Hai Bà Trưng, Hà Nội', 4.6, '06:00', '22:00', 21.0055, 105.8450, 'Cầu lông'),
('20000000-0000-0000-0000-000000000009', 'Sân Cầu Lông Nam Từ Liêm', 'Cung điền kinh Mỹ Đình, Phường Mỹ Đình, Quận Nam Từ Liêm, Hà Nội', 4.7, '05:00', '22:00', 21.0210, 105.7605, 'Cầu lông'),
('20000000-0000-0000-0000-000000000010', 'Sân Cầu Lông Hoàn Kiếm', 'Nhà thi đấu Phúc Tân, Đường Phúc Tân, Quận Hoàn Kiếm, Hà Nội', 4.3, '06:00', '21:30', 21.0335, 105.8610, 'Cầu lông')
ON CONFLICT (id) DO UPDATE SET 
  latitude = EXCLUDED.latitude, 
  longitude = EXCLUDED.longitude, 
  sports_type = EXCLUDED.sports_type;

-- 3. Môn Bóng đá (10 bản ghi)
INSERT INTO venues (id, name, address, rating, open_time, close_time, latitude, longitude, sports_type) VALUES
('30000000-0000-0000-0000-000000000001', 'Sân Bóng Đá Ba Đình', 'Sân bóng Phúc Xá, Phường Phúc Xá, Quận Ba Đình, Hà Nội', 4.3, '05:00', '23:00', 21.0465, 105.8460, 'Bóng đá'),
('30000000-0000-0000-0000-000000000002', 'Sân Bóng Đá Cầu Giấy', 'Sân bóng Nghĩa Tân, Đường Tô Hiệu, Quận Cầu Giấy, Hà Nội', 4.4, '05:00', '23:00', 21.0395, 105.7955, 'Bóng đá'),
('30000000-0000-0000-0000-000000000003', 'Sân Bóng Đá Đống Đa', 'Sân bóng Đại học Thủy Lợi, Đường Chùa Bộc, Quận Đống Đa, Hà Nội', 4.6, '06:00', '23:30', 21.0070, 105.8245, 'Bóng đá'),
('30000000-0000-0000-0000-000000000004', 'Sân Bóng Đá Tây Hồ', 'Sân bóng An Dương, Phường Yên Phụ, Quận Tây Hồ, Hà Nội', 4.2, '05:30', '22:30', 21.0485, 105.8390, 'Bóng đá'),
('30000000-0000-0000-0000-000000000005', 'Sân Bóng Đá Thanh Xuân', 'Sân bóng Viettel, Đường Nguyễn Trãi, Quận Thanh Xuân, Hà Nội', 4.5, '05:00', '23:00', 20.9995, 105.8150, 'Bóng đá'),
('30000000-0000-0000-0000-000000000006', 'Sân Bóng Đá Hà Đông', 'Sân bóng Cường Quốc, Phường Kiến Hưng, Quận Hà Đông, Hà Nội', 4.3, '06:00', '22:30', 20.9575, 105.7845, 'Bóng đá'),
('30000000-0000-0000-0000-000000000007', 'Sân Bóng Đá Long Biên', 'Sân bóng Gia Lâm, Đường Nguyễn Sơn, Quận Long Biên, Hà Nội', 4.4, '05:00', '22:00', 21.0460, 105.8770, 'Bóng đá'),
('30000000-0000-0000-0000-000000000008', 'Sân Bóng Đá Hai Bà Trưng', 'Sân bóng Bách Khoa, Đường Tạ Quang Bửu, Quận Hai Bà Trưng, Hà Nội', 4.5, '05:30', '23:00', 21.0040, 105.8430, 'Bóng đá'),
('30000000-0000-0000-0000-000000000009', 'Sân Bóng Đá Nam Từ Liêm', 'Sân bóng Mỹ Đình, Đường Lê Đức Thọ, Quận Nam Từ Liêm, Hà Nội', 4.8, '05:00', '23:00', 21.0195, 105.7640, 'Bóng đá'),
('30000000-0000-0000-0000-000000000010', 'Sân Bóng Đá Hoàng Mai', 'Sân bóng Đền Lừ, Phường Hoàng Văn Thụ, Quận Hoàng Mai, Hà Nội', 4.2, '06:00', '22:30', 20.9905, 105.8565, 'Bóng đá')
ON CONFLICT (id) DO UPDATE SET 
  latitude = EXCLUDED.latitude, 
  longitude = EXCLUDED.longitude, 
  sports_type = EXCLUDED.sports_type;

-- 4. Môn Tennis (10 bản ghi)
INSERT INTO venues (id, name, address, rating, open_time, close_time, latitude, longitude, sports_type) VALUES
('40000000-0000-0000-0000-000000000001', 'Sân Tennis Ba Đình', 'Khách sạn Daewoo, 360 Kim Mã, Quận Ba Đình, Hà Nội', 4.6, '05:00', '22:00', 21.0325, 105.8115, 'Tennis'),
('40000000-0000-0000-0000-000000000002', 'Sân Tennis Cầu Giấy', 'Công viên Yên Hòa, Phường Yên Hòa, Quận Cầu Giấy, Hà Nội', 4.5, '06:00', '22:00', 21.0225, 105.7905, 'Tennis'),
('40000000-0000-0000-0000-000000000003', 'Sân Tennis Đống Đa', 'CLB Tennis Hoàng Cầu, Đường Mai Anh Tuấn, Quận Đống Đa, Hà Nội', 4.4, '05:30', '22:30', 21.0180, 105.8210, 'Tennis'),
('40000000-0000-0000-0000-000000000004', 'Sân Tennis Tây Hồ', 'CLB Tennis Quảng An, Đường Đặng Thai Mai, Quận Tây Hồ, Hà Nội', 4.7, '05:00', '23:00', 21.0690, 105.8240, 'Tennis'),
('40000000-0000-0000-0000-000000000005', 'Sân Tennis Thanh Xuân', 'Sân Tennis Bộ Công An, Đường Nguyễn Xiển, Quận Thanh Xuân, Hà Nội', 4.3, '05:30', '22:00', 20.9850, 105.8080, 'Tennis'),
('40000000-0000-0000-0000-000000000006', 'Sân Tennis Hà Đông', 'Khu Đô Thị Văn Quán, Quận Hà Đông, Hà Nội', 4.2, '06:00', '22:00', 20.9785, 105.7890, 'Tennis'),
('40000000-0000-0000-0000-000000000007', 'Sân Tennis Long Biên', 'Khu đô thị Việt Hưng, Quận Long Biên, Hà Nội', 4.4, '05:00', '22:00', 21.0620, 105.8990, 'Tennis'),
('40000000-0000-0000-0000-000000000008', 'Sân Tennis Hai Bà Trưng', 'Công viên Thống Nhất, Đường Trần Nhân Tông, Quận Hai Bà Trưng, Hà Nội', 4.6, '06:00', '22:30', 21.0140, 105.8425, 'Tennis'),
('40000000-0000-0000-0000-000000000009', 'Sân Tennis Nam Từ Liêm', 'Khu liên hợp thể thao Mỹ Đình, Quận Nam Từ Liêm, Hà Nội', 4.7, '05:00', '22:00', 21.0175, 105.7595, 'Tennis'),
('40000000-0000-0000-0000-000000000010', 'Sân Tennis Hoàn Kiếm', 'CLB Tennis Tao Đàn, Đường Lý Thường Kiệt, Quận Hoàn Kiếm, Hà Nội', 4.8, '06:00', '22:00', 21.0220, 105.8505, 'Tennis')
ON CONFLICT (id) DO UPDATE SET 
  latitude = EXCLUDED.latitude, 
  longitude = EXCLUDED.longitude, 
  sports_type = EXCLUDED.sports_type;

-- 5. Môn Bóng chuyền (10 bản ghi)
INSERT INTO venues (id, name, address, rating, open_time, close_time, latitude, longitude, sports_type) VALUES
('50000000-0000-0000-0000-000000000001', 'Sân Bóng Chuyền Ba Đình', 'Trung tâm TDTT Ba Đình, 115 Hoàng Diệu, Quận Ba Đình, Hà Nội', 4.4, '05:00', '21:00', 21.0375, 105.8395, 'B.chuyền'),
('50000000-0000-0000-0000-000000000002', 'Sân Bóng Chuyền Cầu Giấy', 'Nhà thi đấu Cầu Giấy, 35 Trần Quý Kiên, Quận Cầu Giấy, Hà Nội', 4.5, '06:00', '22:00', 21.0360, 105.7925, 'B.chuyền'),
('50000000-0000-0000-0000-000000000003', 'Sân Bóng Chuyền Đống Đa', 'CLB Bóng Chuyền Kim Liên, Đường Phạm Ngọc Thạch, Quận Đống Đa, Hà Nội', 4.2, '05:30', '21:30', 21.0090, 105.8360, 'B.chuyền'),
('50000000-0000-0000-0000-000000000004', 'Sân Bóng Chuyền Tây Hồ', 'Sân thể thao Nhật Tân, Đường Âu Cơ, Quận Tây Hồ, Hà Nội', 4.1, '05:00', '22:00', 21.0790, 105.8190, 'B.chuyền'),
('50000000-0000-0000-0000-000000000005', 'Sân Bóng Chuyền Thanh Xuân', 'Trung tâm Thanh Thiếu Niên Thanh Xuân, Nguyễn Quý Đức, Quận Thanh Xuân, Hà Nội', 4.3, '05:30', '22:00', 20.9950, 105.8030, 'B.chuyền'),
('50000000-0000-0000-0000-000000000006', 'Sân Bóng Chuyền Hà Đông', 'Trung tâm TDTT Hà Đông, Phường Nguyễn Trãi, Quận Hà Đông, Hà Nội', 4.2, '06:00', '21:30', 20.9630, 105.7795, 'B.chuyền'),
('50000000-0000-0000-0000-000000000007', 'Sân Bóng Chuyền Long Biên', 'CLB Bóng Chuyền Sài Đồng, Phường Sài Đồng, Quận Long Biên, Hà Nội', 4.0, '05:00', '21:00', 21.0350, 105.9010, 'B.chuyền'),
('50000000-0000-0000-0000-000000000008', 'Sân Bóng Chuyền Hai Bà Trưng', 'Sân thể thao Đại học Kinh Tế Quốc Dân, Quận Hai Bà Trưng, Hà Nội', 4.6, '06:00', '22:00', 21.0020, 105.8420, 'B.chuyền'),
('50000000-0000-0000-0000-000000000009', 'Sân Bóng Chuyền Nam Từ Liêm', 'CLB Thể thao Mỹ Đình, Đường Nguyễn Hoàng, Quận Nam Từ Liêm, Hà Nội', 4.4, '05:00', '22:00', 21.0145, 105.7710, 'B.chuyền'),
('50000000-0000-0000-0000-000000000010', 'Sân Bóng Chuyền Hoàng Mai', 'Khu thể thao Đền Lừ, Quận Hoàng Mai, Hà Nội', 4.1, '06:00', '21:30', 20.9890, 105.8550, 'B.chuyền')
ON CONFLICT (id) DO UPDATE SET 
  latitude = EXCLUDED.latitude, 
  longitude = EXCLUDED.longitude, 
  sports_type = EXCLUDED.sports_type;

-- 6. Môn Bóng rổ (10 bản ghi)
INSERT INTO venues (id, name, address, rating, open_time, close_time, latitude, longitude, sports_type) VALUES
('60000000-0000-0000-0000-000000000001', 'Sân Bóng Rổ Ba Đình', 'CLB Bóng Rổ Phan Đình Phùng, Đường Cửa Bắc, Quận Ba Đình, Hà Nội', 4.5, '06:00', '22:00', 21.0420, 105.8340, 'Bóng rổ'),
('60000000-0000-0000-0000-000000000002', 'Sân Bóng Rổ Cầu Giấy', 'Sân bóng rổ Nghĩa Tân, Đường Tô Hiệu, Quận Cầu Giấy, Hà Nội', 4.4, '05:30', '22:00', 21.0400, 105.7940, 'Bóng rổ'),
('60000000-0000-0000-0000-000000000003', 'Sân Bóng Rổ Đống Đa', 'Sân Đại học Y Hà Nội, Số 1 Tôn Thất Tùng, Quận Đống Đa, Hà Nội', 4.7, '06:00', '22:30', 21.0035, 105.8290, 'Bóng rổ'),
('60000000-0000-0000-0000-000000000004', 'Sân Bóng Rổ Tây Hồ', 'CLB Thể thao Xuân La, Quận Tây Hồ, Hà Nội', 4.3, '05:00', '22:00', 21.0660, 105.8055, 'Bóng rổ'),
('60000000-0000-0000-0000-000000000005', 'Sân Bóng Rổ Thanh Xuân', 'Trường THPT chuyên Hà Nội - Amsterdam, Quận Thanh Xuân, Hà Nội', 4.6, '06:00', '21:30', 21.0100, 105.7985, 'Bóng rổ'),
('60000000-0000-0000-0000-000000000006', 'Sân Bóng Rổ Hà Đông', 'Sân bóng rổ khu đô thị Văn Quán, Quận Hà Đông, Hà Nội', 4.2, '06:00', '22:00', 20.9760, 105.7870, 'Bóng rổ'),
('60000000-0000-0000-0000-000000000007', 'Sân Bóng Rổ Long Biên', 'Sân bóng rổ Ngọc Lâm, Quận Long Biên, Hà Nội', 4.1, '05:00', '22:00', 21.0490, 105.8730, 'Bóng rổ'),
('60000000-0000-0000-0000-000000000008', 'Sân Bóng Rổ Hai Bà Trưng', 'Nhà thi đấu Bách Khoa, Đường Tạ Quang Bửu, Quận Hai Bà Trưng, Hà Nội', 4.7, '06:00', '22:00', 21.0065, 105.8440, 'Bóng rổ'),
('60000000-0000-0000-0000-000000000009', 'Sân Bóng Rổ Nam Từ Liêm', 'Sân bóng rổ Đại học Ngoại Ngữ, Quận Cầu Giấy, Hà Nội', 4.5, '05:00', '22:00', 21.0370, 105.7825, 'Bóng rổ'),
('60000000-0000-0000-0000-000000000010', 'Sân Bóng Rổ Hoàng Mai', 'CLB Bóng Rổ bán đảo Linh Đàm, Quận Hoàng Mai, Hà Nội', 4.3, '06:00', '22:00', 20.9665, 105.8285, 'Bóng rổ')
ON CONFLICT (id) DO UPDATE SET 
  latitude = EXCLUDED.latitude, 
  longitude = EXCLUDED.longitude, 
  sports_type = EXCLUDED.sports_type;

-- 7. Môn Golf (10 bản ghi)
INSERT INTO venues (id, name, address, rating, open_time, close_time, latitude, longitude, sports_type) VALUES
('70000000-0000-0000-0000-000000000001', 'Sân Tập Golf Ciputra', 'Khu đô thị Nam Thăng Long - Ciputra, Đường Xuân Đỉnh, Quận Bắc Từ Liêm, Hà Nội', 4.8, '06:00', '22:00', 21.0820, 105.7980, 'Golf'),
('70000000-0000-0000-0000-000000000002', 'Sân Tập Golf Mipec', 'Số 8 Lê Trọng Tấn, Phường Khương Mai, Quận Thanh Xuân, Hà Nội', 4.6, '05:30', '22:00', 21.0005, 105.8295, 'Golf'),
('70000000-0000-0000-0000-000000000003', 'Sân Tập Golf Phương Đông', 'Phố Tân Mỹ, Phường Mỹ Đình, Quận Nam Từ Liêm, Hà Nội', 4.7, '06:00', '22:30', 21.0250, 105.7670, 'Golf'),
('70000000-0000-0000-0000-000000000004', 'Sân Tập Golf Đảo Sen', '125 Nguyễn Sơn, Phường Gia Thụy, Quận Long Biên, Hà Nội', 4.5, '06:00', '22:00', 21.0425, 105.8820, 'Golf'),
('70000000-0000-0000-0000-000000000005', 'Sân Tập Golf BRG', 'Khách sạn Victory, Tây Hồ, Hà Nội', 4.5, '05:30', '22:00', 21.0585, 105.8345, 'Golf'),
('70000000-0000-0000-0000-000000000006', 'Sân Tập Golf Long Biên', 'Khu trung tâm thương mại Him Lam, Quận Long Biên, Hà Nội', 4.7, '06:00', '23:00', 21.0410, 105.8970, 'Golf'),
('70000000-0000-0000-0000-000000000007', 'Sân Golf Vân Trì', 'Xã Kim Nỗ, Huyện Đông Anh, Hà Nội', 4.9, '05:30', '21:00', 21.1620, 105.8110, 'Golf'),
('70000000-0000-0000-0000-000000000008', 'Sân Golf Legend Hill', 'Xã Hồng Kỳ, Huyện Sóc Sơn, Hà Nội', 4.8, '05:30', '22:00', 21.2720, 105.8450, 'Golf'),
('70000000-0000-0000-0000-000000000009', 'Sân Golf Đồng Mô', 'Kings Island Golf Resort, Thị xã Sơn Tây, Hà Nội', 4.9, '05:00', '22:00', 21.0950, 105.4650, 'Golf'),
('70000000-0000-0000-0000-000000000010', 'Sân Golf Minh Trí', 'Hanoi Golf Club, Xã Minh Trí, Huyện Sóc Sơn, Hà Nội', 4.7, '06:00', '22:00', 21.2480, 105.7720, 'Golf')
ON CONFLICT (id) DO UPDATE SET 
  latitude = EXCLUDED.latitude, 
  longitude = EXCLUDED.longitude, 
  sports_type = EXCLUDED.sports_type;
