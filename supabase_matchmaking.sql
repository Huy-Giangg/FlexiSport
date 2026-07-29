-- 1. Xóa bảng cũ nếu tồn tại (để dễ dàng rebuild database sạch)
DROP TABLE IF EXISTS matchmaking_requests CASCADE;
DROP TABLE IF EXISTS matchmaking_posts CASCADE;

-- 2. Tạo bảng matchmaking_posts
CREATE TABLE matchmaking_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  host_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  slots_needed INT NOT NULL CHECK (slots_needed > 0 AND slots_needed <= 30),
  slots_available INT NOT NULL CHECK (slots_available >= 0),
  target_level VARCHAR(50) NOT NULL, -- 'Mới chơi', 'Trung bình', 'Khá', 'Chuyên nghiệp'
  estimated_cost_per_person NUMERIC(10, 2) DEFAULT 0,
  message TEXT,
  status VARCHAR(20) DEFAULT 'open', -- 'open' (đang tuyển), 'full' (đầy), 'completed' (đã xong), 'cancelled'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. Tạo bảng matchmaking_requests
CREATE TABLE matchmaking_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES matchmaking_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message TEXT, -- Lời nhắn giới thiệu khi xin ghép
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected', 'cancelled'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  
  -- Ràng buộc không cho đăng ký trùng lặp một kèo
  UNIQUE (post_id, user_id)
);

-- 4. Bật Row Level Security (RLS) để bảo mật
ALTER TABLE matchmaking_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE matchmaking_requests ENABLE ROW LEVEL SECURITY;

-- 5. Tạo Policies cho matchmaking_posts
CREATE POLICY "Cho phép đọc matchmaking_posts công khai" 
  ON matchmaking_posts FOR SELECT USING (true);

CREATE POLICY "Cho phép người dùng tạo matchmaking_posts" 
  ON matchmaking_posts FOR INSERT WITH CHECK (auth.uid() = host_id);

CREATE POLICY "Cho phép chủ kèo cập nhật matchmaking_posts" 
  ON matchmaking_posts FOR UPDATE USING (auth.uid() = host_id);

CREATE POLICY "Cho phép chủ kèo xóa matchmaking_posts" 
  ON matchmaking_posts FOR DELETE USING (auth.uid() = host_id);

-- 6. Tạo Policies cho matchmaking_requests
CREATE POLICY "Cho phép đọc matchmaking_requests công khai" 
  ON matchmaking_requests FOR SELECT USING (true);

CREATE POLICY "Cho phép người dùng gửi matchmaking_requests" 
  ON matchmaking_requests FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Cho phép người gửi tự hủy yêu cầu" 
  ON matchmaking_requests FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = (SELECT host_id FROM matchmaking_posts WHERE id = post_id));

-- 7. Tạo Trigger tự động cập nhật slots_available khi có request được Approved hoặc Cancelled
CREATE OR REPLACE FUNCTION update_matchmaking_slots()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status = 'pending' THEN
    UPDATE matchmaking_posts
    SET slots_available = slots_available - 1,
        status = CASE WHEN slots_available - 1 = 0 THEN 'full' ELSE 'open' END
    WHERE id = NEW.post_id;
  ELSIF NEW.status = 'cancelled' AND OLD.status = 'approved' THEN
    UPDATE matchmaking_posts
    SET slots_available = slots_available + 1,
        status = 'open'
    WHERE id = NEW.post_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_matchmaking_slots
AFTER UPDATE ON matchmaking_requests
FOR EACH ROW
EXECUTE FUNCTION update_matchmaking_slots();

-- 8. Chèn dữ liệu giả lập (Mock Data) để giao diện hiển thị đẹp ngay lập tức
-- Giả sử đã có các booking ID từ bảng bookings. 
-- Chúng ta sẽ lấy ID booking giả lập từ bảng bookings và profile để làm mẫu.
-- Nếu bảng bookings có dữ liệu: 'b0000000-0000-0000-0000-000000000001'
-- Hãy chạy lệnh này nếu đã có ID thực tế. Để an toàn, chúng tôi tạo sẵn 1 mẫu:
DO $$
DECLARE
  v_booking_id UUID;
  v_host_id UUID;
BEGIN
  -- Lấy thử một booking có sẵn
  SELECT id INTO v_booking_id FROM bookings LIMIT 1;
  -- Lấy thử một profile có sẵn làm host
  SELECT id INTO v_host_id FROM profiles LIMIT 1;
  
  -- Nếu có đủ thông tin, chèn 2 kèo ghép mẫu
  IF v_booking_id IS NOT NULL AND v_host_id IS NOT NULL THEN
    INSERT INTO matchmaking_posts (booking_id, host_id, slots_needed, slots_available, target_level, estimated_cost_per_person, message, status)
    VALUES 
    (v_booking_id, v_host_id, 2, 2, 'Trung bình', 50000.00, 'Cần tuyển thêm 2 bạn đánh đôi cầu lông vui vẻ, có trà đá miễn phí.', 'open'),
    (v_booking_id, v_host_id, 1, 1, 'Khá', 60000.00, 'Kèo Pickleball chất lượng cao, giao lưu cọ xát nâng trình.', 'open')
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- 9. Kích hoạt tính năng Realtime cho bảng matchmaking_requests
ALTER TABLE matchmaking_requests REPLICA IDENTITY FULL;
alter publication supabase_realtime add table matchmaking_requests;
