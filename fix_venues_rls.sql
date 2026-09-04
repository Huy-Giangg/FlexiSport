-- ==============================================================================
-- SQL MIGRATION: CẤP QUYỀN GHI (INSERT, UPDATE, DELETE) CHO BẢNG VENUES
-- Hãy mở Supabase Dashboard -> Chọn SQL Editor -> Dán đoạn mã này và bấm RUN
-- ==============================================================================

-- 1. Bật Row Level Security cho bảng venues nếu chưa có
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;

-- 2. Thêm cột owner_id vào bảng venues nếu chưa tồn tại
ALTER TABLE venues ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id);

-- 3. Cấp quyền Đọc (SELECT) công khai
DROP POLICY IF EXISTS "Cho phép đọc venues công khai" ON venues;
CREATE POLICY "Cho phép đọc venues công khai" ON venues 
    FOR SELECT USING (true);

-- 4. Cấp quyền Thêm mới (INSERT) cho bảng venues
DROP POLICY IF EXISTS "Cho phép insert venues" ON venues;
CREATE POLICY "Cho phép insert venues" ON venues 
    FOR INSERT WITH CHECK (true);

-- 5. Cấp quyền Cập nhật (UPDATE) cho bảng venues
DROP POLICY IF EXISTS "Cho phép update venues" ON venues;
CREATE POLICY "Cho phép update venues" ON venues 
    FOR UPDATE USING (true);

-- 6. Cấp quyền Xóa (DELETE) cho bảng venues
DROP POLICY IF EXISTS "Cho phép delete venues" ON venues;
CREATE POLICY "Cho phép delete venues" ON venues 
    FOR DELETE USING (true);


-- 7. Cấp quyền UPDATE và DELETE cho bảng bookings (Duyệt, Hủy đơn đặt sân, Hoàn tiền)
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép update bookings" ON bookings;
DROP POLICY IF EXISTS "Cho phép delete bookings" ON bookings;

CREATE POLICY "Cho phép update bookings" ON bookings 
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Cho phép delete bookings" ON bookings 
    FOR DELETE USING (true);


-- 8. Cấp quyền UPDATE và DELETE cho bảng booking_slots
ALTER TABLE booking_slots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép update booking_slots" ON booking_slots;
DROP POLICY IF EXISTS "Cho phép delete booking_slots" ON booking_slots;

CREATE POLICY "Cho phép update booking_slots" ON booking_slots 
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Cho phép delete booking_slots" ON booking_slots 
    FOR DELETE USING (true);


-- 9. Tạo bảng và cấp quyền cho bảng notifications (Thông báo hệ thống cho Khách & Chủ sân)
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


