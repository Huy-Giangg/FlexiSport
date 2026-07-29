-- Hướng dẫn: Sao chép toàn bộ mã SQL dưới đây và chạy trong mục "SQL Editor" trên Supabase Dashboard của bạn.
-- Mục tiêu: Tạo các index trên khóa ngoại (foreign keys) và các cột được truy vấn thường xuyên để tăng tốc độ load danh sách đặt lịch sân, vé sự kiện, kèo ghép, v.v.

-- 1. Index cho bảng bookings (Tăng tốc độ truy vấn đặt sân của user)
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);

-- 2. Index cho bảng booking_slots (Tăng tốc độ kết nối/join giữa bookings và slots)
CREATE INDEX IF NOT EXISTS idx_booking_slots_booking_id ON booking_slots(booking_id);
CREATE INDEX IF NOT EXISTS idx_booking_slots_court_id ON booking_slots(court_id);
CREATE INDEX IF NOT EXISTS idx_booking_slots_date ON booking_slots(booking_date);

-- 3. Index cho bảng courts và venues (Tăng tốc độ kết nối sân và cơ sở)
CREATE INDEX IF NOT EXISTS idx_courts_venue_id ON courts(venue_id);

-- 4. Index cho bảng venue_reviews (Tăng tốc độ tải đánh giá của sân)
-- Lưu ý: booking_id đã được đánh index tự động vì có ràng buộc UNIQUE.
CREATE INDEX IF NOT EXISTS idx_venue_reviews_venue_id ON venue_reviews(venue_id);
CREATE INDEX IF NOT EXISTS idx_venue_reviews_user_id ON venue_reviews(user_id);

-- 5. Index cho bảng matchmaking_posts (Tăng tốc độ load kèo ghép theo booking/chủ kèo)
CREATE INDEX IF NOT EXISTS idx_matchmaking_posts_booking_id ON matchmaking_posts(booking_id);
CREATE INDEX IF NOT EXISTS idx_matchmaking_posts_host_id ON matchmaking_posts(host_id);

-- 6. Index cho bảng matchmaking_requests (Tăng tốc độ truy vấn yêu cầu ghép)
CREATE INDEX IF NOT EXISTS idx_matchmaking_requests_post_id ON matchmaking_requests(post_id);
CREATE INDEX IF NOT EXISTS idx_matchmaking_requests_user_id ON matchmaking_requests(user_id);

-- 7. Index cho bảng event_bookings và events (Tăng tốc độ load vé sự kiện)
CREATE INDEX IF NOT EXISTS idx_event_bookings_event_id ON event_bookings(event_id);
CREATE INDEX IF NOT EXISTS idx_event_bookings_user_id ON event_bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_events_venue_id ON events(venue_id);
