-- Bổ sung cột min_tickets (Số lượng vé tối thiểu để tổ chức sự kiện)
ALTER TABLE events ADD COLUMN IF NOT EXISTS min_tickets INTEGER DEFAULT 2;

ALTER TABLE events ADD COLUMN IF NOT EXISTS ticket_price DECIMAL(10, 2) DEFAULT 0.0;
ALTER TABLE events ADD COLUMN IF NOT EXISTS max_tickets INTEGER DEFAULT 10;
ALTER TABLE events ADD COLUMN IF NOT EXISTS sport_type VARCHAR(50) DEFAULT 'Pickleball';
ALTER TABLE events ADD COLUMN IF NOT EXISTS level VARCHAR(50) DEFAULT 'Mọi trình độ';
ALTER TABLE events ADD COLUMN IF NOT EXISTS start_time VARCHAR(10) DEFAULT '15:00';
ALTER TABLE events ADD COLUMN IF NOT EXISTS end_time VARCHAR(10) DEFAULT '18:00';
ALTER TABLE events ADD COLUMN IF NOT EXISTS court_name VARCHAR(100) DEFAULT 'Sân 1';

-- 2. Tạo bảng event_bookings (Lưu lượt đặt vé sự kiện của người chơi)
CREATE TABLE IF NOT EXISTS event_bookings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Liên kết với tài khoản người dùng của Supabase Auth nếu có
    ticket_count INTEGER NOT NULL DEFAULT 1,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- 'pending' (Chờ thanh toán/xác nhận), 'completed' (Đã thanh toán), 'cancelled' (Đã hủy), 'used' (Đã check-in/xé vé)
    customer_name VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(50) NOT NULL,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Bật tính năng Row Level Security (RLS) để bảo mật
ALTER TABLE event_bookings ENABLE ROW LEVEL SECURITY;

-- Tạo các policy cơ bản cho phép đọc và thêm mới
DROP POLICY IF EXISTS "Cho phép đọc event_bookings công khai" ON event_bookings;
DROP POLICY IF EXISTS "Cho phép tạo event_bookings công khai" ON event_bookings;
DROP POLICY IF EXISTS "Cho phép cập nhật event_bookings công khai" ON event_bookings;

CREATE POLICY "Cho phép đọc event_bookings công khai" ON event_bookings 
    FOR SELECT USING (true);

CREATE POLICY "Cho phép tạo event_bookings công khai" ON event_bookings 
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Cho phép cập nhật event_bookings công khai" ON event_bookings 
    FOR UPDATE USING (true);


-- 3. Tạo dữ liệu sự kiện giả lập cho ngày hôm nay và ngày mai (để hiển thị trên app)
-- Xóa các event slots cũ và sự kiện cũ để tránh trùng lặp khi chạy lại
DELETE FROM event_slots WHERE event_id IN (
    'e0000000-0000-0000-0000-000000000001', 
    'e0000000-0000-0000-0000-000000000002',
    'e0000000-0000-0000-0000-000000000003'
);
DELETE FROM events WHERE id IN (
    'e0000000-0000-0000-0000-000000000001', 
    'e0000000-0000-0000-0000-000000000002',
    'e0000000-0000-0000-0000-000000000003'
);

-- Tạo 3 sự kiện mẫu liên kết với cơ sở "Sân Pickleball Ba Đình" (ID: 10000000-0000-0000-0000-000000000001) 
-- và "Sân Pickleball Cầu Giấy" (ID: 10000000-0000-0000-0000-000000000002)
INSERT INTO events (
    id, venue_id, title, description, event_date, is_active, 
    ticket_price, max_tickets, sport_type, level, start_time, end_time, court_name
) VALUES
(
    'e0000000-0000-0000-0000-000000000001', 
    '10000000-0000-0000-0000-000000000001', 
    '[Xé vé] - Giao lưu Trình hỗn hợp 1.0 - 2.5', 
    'Sự kiện giao lưu cuối tuần dành cho các vợt thủ trình độ mới chơi và trung bình. Có nước uống miễn phí và hỗ trợ ghép đôi chơi cùng người lạ.', 
    CURRENT_DATE, 
    true, 
    40000.00, 
    8, 
    'Pickleball', 
    '1.0 -> 2.5', 
    '15:00', 
    '18:00', 
    'Sân Pickleball 1'
),
(
    'e0000000-0000-0000-0000-000000000002', 
    '10000000-0000-0000-0000-000000000001', 
    '[Giao lưu] - Thách đấu trình 3.0+ Cọ xát nâng trình', 
    'Hội tụ các tay vợt cứng trình 3.0 trở lên. Thi đấu tính điểm vòng tròn chọn ra đôi vô địch nhận quà lưu niệm của CLB.', 
    CURRENT_DATE, 
    true, 
    60000.00, 
    12, 
    'Pickleball', 
    '3.0 -> 4.5', 
    '18:00', 
    '21:00', 
    'Sân Pickleball 2'
),
(
    'e0000000-0000-0000-0000-000000000003', 
    '10000000-0000-0000-0000-000000000002', 
    '[Giao lưu] - Badminton Saturday Cup', 
    'Giao lưu cầu lông đôi nam nữ và đôi nam cuối tuần. Chi phí đã bao gồm tiền thuê sân và cầu thi đấu.', 
    CURRENT_DATE + 1, 
    true, 
    50000.00, 
    16, 
    'Cầu lông', 
    'Mọi trình độ', 
    '08:00', 
    '11:00', 
    'Sân Cầu Lông 1'
);

-- Khóa các ô giờ tương ứng trên lưới đặt sân trực quan bằng cách chèn vào event_slots
-- Việc này giúp ngăn chặn người đặt lịch ngày trực quan đặt trùng vào sân & khung giờ đã tổ chức sự kiện
-- Lấy ví dụ Sân 1 Ba Đình là: 00000003-0000-0000-0000-000000000001
-- Slot index cho 15h - 18h (mỗi slot 30 phút, từ slot index 20 đến 25 tương đương 15h - 18h nếu sân mở từ 5h sáng)
-- Dưới đây ta giả định các slot index tương ứng với khung giờ:
INSERT INTO event_slots (event_id, court_id, event_date, slot_index) VALUES
-- Sự kiện 1: Sân Pickleball 1 Ba Đình, 15h00 - 18h00 (Slot index 20, 21, 22, 23, 24, 25)
('e0000000-0000-0000-0000-000000000001', '00000003-0000-0000-0000-000000000001', CURRENT_DATE, 20),
('e0000000-0000-0000-0000-000000000001', '00000003-0000-0000-0000-000000000001', CURRENT_DATE, 21),
('e0000000-0000-0000-0000-000000000001', '00000003-0000-0000-0000-000000000001', CURRENT_DATE, 22),
('e0000000-0000-0000-0000-000000000001', '00000003-0000-0000-0000-000000000001', CURRENT_DATE, 23),
('e0000000-0000-0000-0000-000000000001', '00000003-0000-0000-0000-000000000001', CURRENT_DATE, 24),
('e0000000-0000-0000-0000-000000000001', '00000003-0000-0000-0000-000000000001', CURRENT_DATE, 25);
