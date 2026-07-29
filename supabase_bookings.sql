-- 1. Xóa bảng cũ nếu tồn tại (Xóa booking_slots trước vì nó tham chiếu đến bookings)
DROP TABLE IF EXISTS booking_slots CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;

-- 2. Tạo bảng bookings (Lưu hóa đơn thanh toán của người dùng)
CREATE TABLE bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Liên kết với tài khoản người dùng của Supabase Auth
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'completed', -- 'completed', 'pending', 'cancelled'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. Tạo bảng booking_slots (Lưu chi tiết các ô giờ cụ thể đã được đặt thành công)
CREATE TABLE booking_slots (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    court_id UUID REFERENCES courts(id) ON DELETE CASCADE,
    booking_date DATE NOT NULL, -- Định dạng: YYYY-MM-DD
    slot_index INTEGER NOT NULL, -- Vị trí ô giờ trên lưới (0, 1, 2, 3...)
    
    -- Ràng buộc UNIQUE để ngăn chặn trùng lặp đặt chỗ cho cùng một sân, cùng một ngày, cùng một slot
    CONSTRAINT unique_court_date_slot UNIQUE (court_id, booking_date, slot_index)
);

-- Bật tính năng Row Level Security (RLS) để bảo mật
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_slots ENABLE ROW LEVEL SECURITY;

-- Tạo các policy cơ bản cho phép đọc dữ liệu công khai và người dùng được phép chỉnh sửa đơn của mình
CREATE POLICY "Cho phép đọc bookings công khai" ON bookings 
    FOR SELECT USING (true);

CREATE POLICY "Cho phép người dùng tạo booking" ON bookings 
    FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Cho phép liên kết booking vãng lai" ON bookings 
    FOR UPDATE TO authenticated USING (user_id IS NULL) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Cho phép đọc booking_slots công khai" ON booking_slots 
    FOR SELECT USING (true);

CREATE POLICY "Cho phép người dùng tạo booking_slots" ON booking_slots 
    FOR INSERT WITH CHECK (true);

-- 4. Chèn dữ liệu giả lập (Mock Data)
-- Ngày đặt mặc định trong thiết kế visual_booking_page hiện tại là '2026-05-21'
-- Sử dụng các ID sân thực tế thuộc cơ sở "Hado Charm Sports" đã được truy vấn từ Database:
--   + Pickleball 1: 00000003-0000-0000-0000-000000000001
--   + Pickleball 2: 00000003-0000-0000-0000-000000000002

-- Tạo 2 hóa đơn (bookings) giả lập
INSERT INTO bookings (id, total_amount, status) VALUES
('b0000000-0000-0000-0000-000000000001', 150000.00, 'completed'),
('b0000000-0000-0000-0000-000000000002', 200000.00, 'completed');

-- Thêm các slot cụ thể đã đặt (booking_slots):
INSERT INTO booking_slots (booking_id, court_id, booking_date, slot_index) VALUES
-- Sân Pickleball 1 (00000003-0000-0000-0000-000000000001) đặt các slot 4, 5, 6
('b0000000-0000-0000-0000-000000000001', '00000003-0000-0000-0000-000000000001', CURRENT_DATE, 4),
('b0000000-0000-0000-0000-000000000001', '00000003-0000-0000-0000-000000000001', CURRENT_DATE, 5),
('b0000000-0000-0000-0000-000000000001', '00000003-0000-0000-0000-000000000001', CURRENT_DATE, 6),

-- Sân Pickleball 2 (00000003-0000-0000-0000-000000000002) đặt các slot 22, 23, 24, 25
('b0000000-0000-0000-0000-000000000002', '00000003-0000-0000-0000-000000000002', CURRENT_DATE, 22),
('b0000000-0000-0000-0000-000000000002', '00000003-0000-0000-0000-000000000002', CURRENT_DATE, 23),
('b0000000-0000-0000-0000-000000000002', '00000003-0000-0000-0000-000000000002', CURRENT_DATE, 24),
('b0000000-0000-0000-0000-000000000002', '00000003-0000-0000-0000-000000000002', CURRENT_DATE, 25);
