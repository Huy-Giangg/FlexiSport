-- 1. Tạo bảng court_blocks (Lưu các ô giờ bị admin khóa, ví dụ để bảo trì)
CREATE TABLE IF NOT EXISTS court_blocks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    court_id UUID REFERENCES courts(id) ON DELETE CASCADE,
    block_date DATE NOT NULL,
    slot_index INTEGER NOT NULL,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    CONSTRAINT unique_court_block_slot UNIQUE (court_id, block_date, slot_index)
);

-- 2. Tạo bảng event_slots (Lưu các ô giờ bị trưng dụng cho sự kiện/giải đấu)
CREATE TABLE IF NOT EXISTS event_slots (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    court_id UUID REFERENCES courts(id) ON DELETE CASCADE,
    event_date DATE NOT NULL,
    slot_index INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    CONSTRAINT unique_event_court_slot UNIQUE (court_id, event_date, slot_index)
);

-- Bật RLS và tạo Policy
ALTER TABLE court_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_slots ENABLE ROW LEVEL SECURITY;

-- Xóa các policy cũ nếu chạy lại script
DROP POLICY IF EXISTS "Cho phép đọc court_blocks công khai" ON court_blocks;
DROP POLICY IF EXISTS "Cho phép đọc event_slots công khai" ON event_slots;

CREATE POLICY "Cho phép đọc court_blocks công khai" ON court_blocks FOR SELECT USING (true);
CREATE POLICY "Cho phép đọc event_slots công khai" ON event_slots FOR SELECT USING (true);

-- 3. Xóa dữ liệu cũ của ngày hôm nay để tránh trùng lặp khi chạy lại
DELETE FROM court_blocks WHERE block_date = CURRENT_DATE;
DELETE FROM event_slots WHERE event_date = CURRENT_DATE;

-- 4. Chèn dữ liệu giả lập cho ngày hôm nay (CURRENT_DATE)
-- Lịch khóa (court_blocks)
INSERT INTO court_blocks (court_id, block_date, slot_index, reason) VALUES
('00000003-0000-0000-0000-000000000001', CURRENT_DATE, 0, 'Bảo trì định kỳ'),
('00000003-0000-0000-0000-000000000001', CURRENT_DATE, 1, 'Bảo trì định kỳ'),
('00000003-0000-0000-0000-000000000001', CURRENT_DATE, 2, 'Bảo trì định kỳ'),

('00000003-0000-0000-0000-000000000002', CURRENT_DATE, 0, 'Dạy học'),
('00000003-0000-0000-0000-000000000002', CURRENT_DATE, 1, 'Dạy học'),
('00000003-0000-0000-0000-000000000002', CURRENT_DATE, 2, 'Dạy học'),
('00000003-0000-0000-0000-000000000002', CURRENT_DATE, 3, 'Dạy học');

-- Đảm bảo sự kiện Giải Pickleball Hado Open 2026 tồn tại trong bảng events (nếu chưa có)
INSERT INTO events (id, venue_id, title, description, event_date, is_active)
VALUES ('d4b98109-ae0a-4df6-a416-ce8f8b46ccd5', '00000002-0000-0000-0000-000000000001', 'Giải Pickleball Hado Open 2026', 'Giải đấu mở rộng, giải thưởng 50 triệu đồng', CURRENT_DATE, true)
ON CONFLICT (id) DO UPDATE SET event_date = CURRENT_DATE;

-- Lịch sự kiện (event_slots)
INSERT INTO event_slots (event_id, court_id, event_date, slot_index) VALUES
('d4b98109-ae0a-4df6-a416-ce8f8b46ccd5', '00000003-0000-0000-0000-000000000003', CURRENT_DATE, 16),
('d4b98109-ae0a-4df6-a416-ce8f8b46ccd5', '00000003-0000-0000-0000-000000000003', CURRENT_DATE, 17),
('d4b98109-ae0a-4df6-a416-ce8f8b46ccd5', '00000003-0000-0000-0000-000000000003', CURRENT_DATE, 18),
('d4b98109-ae0a-4df6-a416-ce8f8b46ccd5', '00000003-0000-0000-0000-000000000003', CURRENT_DATE, 19);
