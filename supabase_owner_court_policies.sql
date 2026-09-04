-- ==============================================================================
-- SQL MIGRATION: CẤP QUYỀN RLS CHO CHỦ SÂN QUẢN LÝ SÂN VÀ KHÓA BẢO TRÌ
-- Hãy sao chép toàn bộ nội dung file này và chạy trong SQL Editor của Supabase
-- ==============================================================================

-- 1. Cấp quyền INSERT, UPDATE, DELETE cho bảng court_blocks (Khóa / Mở khóa khung giờ & Bảo trì)
ALTER TABLE court_blocks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép đọc court_blocks công khai" ON court_blocks;
DROP POLICY IF EXISTS "Cho phép insert court_blocks" ON court_blocks;
DROP POLICY IF EXISTS "Cho phép update court_blocks" ON court_blocks;
DROP POLICY IF EXISTS "Cho phép delete court_blocks" ON court_blocks;

CREATE POLICY "Cho phép đọc court_blocks công khai" ON court_blocks 
    FOR SELECT USING (true);

CREATE POLICY "Cho phép insert court_blocks" ON court_blocks 
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Cho phép update court_blocks" ON court_blocks 
    FOR UPDATE USING (true);

CREATE POLICY "Cho phép delete court_blocks" ON court_blocks 
    FOR DELETE USING (true);


-- 2. Cấp quyền INSERT, UPDATE, DELETE cho bảng courts (Thêm / Sửa / Xóa sân con)
ALTER TABLE courts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép đọc courts công khai" ON courts;
DROP POLICY IF EXISTS "Cho phép insert courts" ON courts;
DROP POLICY IF EXISTS "Cho phép update courts" ON courts;
DROP POLICY IF EXISTS "Cho phép delete courts" ON courts;

CREATE POLICY "Cho phép đọc courts công khai" ON courts 
    FOR SELECT USING (true);

CREATE POLICY "Cho phép insert courts" ON courts 
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Cho phép update courts" ON courts 
    FOR UPDATE USING (true);

CREATE POLICY "Cho phép delete courts" ON courts 
    FOR DELETE USING (true);


-- 3. Cấp quyền UPDATE cho bảng venues (Chỉnh sửa thông tin cơ sở)
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép đọc venues công khai" ON venues;
DROP POLICY IF EXISTS "Cho phép update venues" ON venues;

CREATE POLICY "Cho phép đọc venues công khai" ON venues 
    FOR SELECT USING (true);

CREATE POLICY "Cho phép update venues" ON venues 
    FOR UPDATE USING (true);


-- 4. Cấp quyền UPDATE và DELETE cho bảng bookings (Để chủ sân và khách hàng có thể duyệt, hủy đơn, hoàn tiền)
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép update bookings" ON bookings;
DROP POLICY IF EXISTS "Cho phép delete bookings" ON bookings;

CREATE POLICY "Cho phép update bookings" ON bookings 
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Cho phép delete bookings" ON bookings 
    FOR DELETE USING (true);


-- 5. Cấp quyền UPDATE và DELETE cho bảng booking_slots
ALTER TABLE booking_slots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép update booking_slots" ON booking_slots;
DROP POLICY IF EXISTS "Cho phép delete booking_slots" ON booking_slots;

CREATE POLICY "Cho phép update booking_slots" ON booking_slots 
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Cho phép delete booking_slots" ON booking_slots 
    FOR DELETE USING (true);


-- 6. Tạo bảng và cấp quyền cho bảng notifications (Thông báo hệ thống cho Khách & Chủ sân)
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'general',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép đọc notifications" ON notifications;
DROP POLICY IF EXISTS "Cho phép tạo notifications" ON notifications;
DROP POLICY IF EXISTS "Cho phép update notifications" ON notifications;

CREATE POLICY "Cho phép đọc notifications" ON notifications 
    FOR SELECT USING (true);

CREATE POLICY "Cho phép tạo notifications" ON notifications 
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Cho phép update notifications" ON notifications 
    FOR UPDATE USING (true);


