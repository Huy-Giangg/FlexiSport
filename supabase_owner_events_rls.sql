-- ==============================================================================
-- SQL MIGRATION: CẤP QUYỀN ROW LEVEL SECURITY (RLS) CHO QUẢN LÝ SỰ KIỆN (EVENTS)
-- Hãy sao chép toàn bộ nội dung file này và dán vào mục SQL Editor trong Supabase Dashboard rồi nhấn RUN
-- ==============================================================================

-- 1. Cập nhật các cột cấu hình chi tiết cho bảng events (nếu chưa có)
ALTER TABLE events ADD COLUMN IF NOT EXISTS ticket_price DECIMAL(10, 2) DEFAULT 0.0;
ALTER TABLE events ADD COLUMN IF NOT EXISTS max_tickets INTEGER DEFAULT 10;
ALTER TABLE events ADD COLUMN IF NOT EXISTS sport_type VARCHAR(50) DEFAULT 'Pickleball';
ALTER TABLE events ADD COLUMN IF NOT EXISTS level VARCHAR(50) DEFAULT 'Mọi trình độ';
ALTER TABLE events ADD COLUMN IF NOT EXISTS start_time VARCHAR(10) DEFAULT '15:00';
ALTER TABLE events ADD COLUMN IF NOT EXISTS end_time VARCHAR(10) DEFAULT '18:00';
ALTER TABLE events ADD COLUMN IF NOT EXISTS court_name VARCHAR(100) DEFAULT 'Sân 1';

-- 2. Cấp đầy đủ quyền INSERT, UPDATE, DELETE cho bảng events
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép đọc events công khai" ON events;
DROP POLICY IF EXISTS "Cho phép insert events" ON events;
DROP POLICY IF EXISTS "Cho phép update events" ON events;
DROP POLICY IF EXISTS "Cho phép delete events" ON events;

CREATE POLICY "Cho phép đọc events công khai" ON events 
    FOR SELECT USING (true);

CREATE POLICY "Cho phép insert events" ON events 
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Cho phép update events" ON events 
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Cho phép delete events" ON events 
    FOR DELETE USING (true);


-- 3. Cấp đầy đủ quyền cho bảng event_slots
ALTER TABLE event_slots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép đọc event_slots công khai" ON event_slots;
DROP POLICY IF EXISTS "Cho phép insert event_slots" ON event_slots;
DROP POLICY IF EXISTS "Cho phép update event_slots" ON event_slots;
DROP POLICY IF EXISTS "Cho phép delete event_slots" ON event_slots;

CREATE POLICY "Cho phép đọc event_slots công khai" ON event_slots 
    FOR SELECT USING (true);

CREATE POLICY "Cho phép insert event_slots" ON event_slots 
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Cho phép update event_slots" ON event_slots 
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Cho phép delete event_slots" ON event_slots 
    FOR DELETE USING (true);


-- 4. Cấp đầy đủ quyền cho bảng event_bookings
ALTER TABLE event_bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép đọc event_bookings công khai" ON event_bookings;
DROP POLICY IF EXISTS "Cho phép tạo event_bookings công khai" ON event_bookings;
DROP POLICY IF EXISTS "Cho phép cập nhật event_bookings công khai" ON event_bookings;
DROP POLICY IF EXISTS "Cho phép xóa event_bookings công khai" ON event_bookings;

CREATE POLICY "Cho phép đọc event_bookings công khai" ON event_bookings 
    FOR SELECT USING (true);

CREATE POLICY "Cho phép tạo event_bookings công khai" ON event_bookings 
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Cho phép cập nhật event_bookings công khai" ON event_bookings 
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Cho phép xóa event_bookings công khai" ON event_bookings 
    FOR DELETE USING (true);
