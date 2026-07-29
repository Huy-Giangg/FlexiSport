-- ==========================================
-- 1. Tạo bảng court_locks (Bảng giữ chỗ tạm thời trong 5 phút)
-- ==========================================
CREATE TABLE IF NOT EXISTS court_locks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    court_id UUID REFERENCES courts(id) ON DELETE CASCADE,
    slot_index INTEGER NOT NULL,
    booking_date DATE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- Để NULL nếu là khách vãng lai
    locked_until TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '5 minutes') NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    -- Ràng buộc UNIQUE để ngăn chặn 2 người cùng giữ chỗ một sân vào một khung giờ
    CONSTRAINT unique_court_lock UNIQUE (court_id, booking_date, slot_index)
);

-- Bật Row Level Security (RLS) cho court_locks
ALTER TABLE court_locks ENABLE ROW LEVEL SECURITY;

-- Tạo các policy cho court_locks (ép kiểu ::text để tương thích tốt nhất)
DROP POLICY IF EXISTS "Cho phép đọc locks công khai" ON court_locks;
CREATE POLICY "Cho phép đọc locks công khai" ON court_locks 
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Cho phép người dùng tạo lock" ON court_locks;
CREATE POLICY "Cho phép người dùng tạo lock" ON court_locks 
    FOR INSERT WITH CHECK (auth.uid()::text = user_id::text OR user_id IS NULL);

DROP POLICY IF EXISTS "Cho phép người dùng xóa lock" ON court_locks;
CREATE POLICY "Cho phép người dùng xóa lock" ON court_locks 
    FOR DELETE USING (auth.uid()::text = user_id::text OR user_id IS NULL);


-- ==========================================
-- 2. Cập nhật cấu trúc bảng bookings
-- ==========================================
ALTER TABLE bookings 
  ADD COLUMN IF NOT EXISTS customer_name VARCHAR(100),
  ADD COLUMN IF NOT EXISTS customer_phone VARCHAR(20),
  ADD COLUMN IF NOT EXISTS note TEXT;

-- Thay đổi giá trị mặc định của status thành pending_payment
ALTER TABLE bookings ALTER COLUMN status SET DEFAULT 'pending_payment';


-- ==========================================
-- 3. Tạo bảng payments để lưu các giao dịch thanh toán VietQR
-- ==========================================
CREATE TABLE IF NOT EXISTS payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    payment_method VARCHAR(50) DEFAULT 'VietQR' NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING' NOT NULL, -- PENDING, SUCCESS, FAILED
    payment_reference VARCHAR(50) UNIQUE NOT NULL, -- Nội dung chuyển khoản duy nhất (VD: FLEXI100045)
    transaction_code VARCHAR(100) UNIQUE,          -- Mã tham chiếu giao dịch từ phía Ngân hàng (nếu có)
    raw_callback_data JSONB,                       -- Lưu toàn bộ JSON payload từ webhook để đối soát
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Bật RLS cho payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Tạo các policy cho payments (ép kiểu ::text để tương thích tốt nhất)
DROP POLICY IF EXISTS "Cho phép đọc payments cá nhân" ON payments;
CREATE POLICY "Cho phép đọc payments cá nhân" ON payments 
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM bookings 
            WHERE bookings.id::text = payments.booking_id::text 
            AND (bookings.user_id::text = auth.uid()::text OR bookings.user_id IS NULL)
        )
    );


-- ==========================================
-- 4. Kích hoạt Realtime cho bảng bookings
-- ==========================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'bookings'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
    END IF;
END $$;


-- ==========================================
-- 5. Viết Stored Procedure (RPC) tạo Booking và Payment nguyên tử
-- ==========================================
CREATE OR REPLACE FUNCTION create_booking_transaction(
    p_user_id UUID,
    p_total_amount DECIMAL(10, 2),
    p_customer_name VARCHAR,
    p_customer_phone VARCHAR,
    p_note TEXT,
    p_slots JSONB -- Mảng JSON chứa [{court_id, booking_date, slot_index}]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_booking_id UUID;
    v_payment_reference VARCHAR;
    v_short_id VARCHAR;
    slot_record RECORD;
    v_result JSONB;
BEGIN
    -- 1. Tạo bản ghi booking mới với trạng thái pending_payment (chữ thường)
    INSERT INTO bookings (user_id, total_amount, status, customer_name, customer_phone, note)
    VALUES (p_user_id, p_total_amount, 'pending_payment', p_customer_name, p_customer_phone, p_note)
    RETURNING id INTO v_booking_id;

    -- 2. Tạo mã payment_reference duy nhất dựa trên booking_id ngắn gọn
    -- Lấy 8 ký tự cuối của UUID booking_id để tạo mã nội dung CK
    v_short_id := upper(substring(v_booking_id::text from 29 for 8));
    v_payment_reference := 'FLEXI' || v_short_id;

    -- 3. Tạo bản ghi payment tương ứng
    INSERT INTO payments (booking_id, amount, status, payment_reference)
    VALUES (v_booking_id, p_total_amount, 'PENDING', v_payment_reference);

    -- 4. Thêm các slot đặt vào bảng booking_slots
    FOR slot_record IN SELECT * FROM jsonb_to_recordset(p_slots) AS x(court_id UUID, booking_date DATE, slot_index INTEGER)
    LOOP
        INSERT INTO booking_slots (booking_id, court_id, booking_date, slot_index)
        VALUES (v_booking_id, slot_record.court_id, slot_record.booking_date, slot_record.slot_index);
    END LOOP;

    -- 5. Trả về kết quả cho client
    v_result := jsonb_build_object(
        'booking_id', v_booking_id,
        'payment_reference', v_payment_reference
    );
    
    RETURN v_result;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Lỗi giao dịch đặt sân: %', SQLERRM;
END;
$$;


-- ==========================================
-- 6. Viết Stored Procedure (RPC) hủy Booking khi hết giờ thanh toán
-- ==========================================
CREATE OR REPLACE FUNCTION cancel_expired_booking(p_booking_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Chỉ cho phép hủy nếu booking đang ở trạng thái pending_payment
    UPDATE bookings 
    SET status = 'cancelled' 
    WHERE id::text = p_booking_id::text AND status = 'pending_payment';
    
    IF FOUND THEN
        -- Xóa các slot đặt tương ứng trong booking_slots để giải phóng sân
        DELETE FROM booking_slots WHERE booking_id::text = p_booking_id::text;
        
        -- Cập nhật trạng thái payment thành FAILED
        UPDATE payments SET status = 'FAILED' WHERE booking_id::text = p_booking_id::text AND status = 'PENDING';
    END IF;
END;
$$;


-- ==========================================
-- 7. Trigger tự động dọn dẹp các booking quá hạn (Tránh rác khi tắt App đột ngột)
-- ==========================================
CREATE OR REPLACE FUNCTION cleanup_expired_bookings_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Tìm và cập nhật các booking ở trạng thái 'pending_payment' quá 5 phút thành 'cancelled'
    UPDATE bookings 
    SET status = 'cancelled' 
    WHERE status = 'pending_payment' 
      AND created_at < NOW() - INTERVAL '5 minutes';

    -- Xóa các slot đặt tương ứng của các booking đã bị hủy để giải phóng sân trống
    DELETE FROM booking_slots 
    WHERE booking_id IN (
        SELECT id FROM bookings WHERE status = 'cancelled'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger trên bảng court_locks (chạy trước khi có người giữ chỗ mới để giải phóng sân quá hạn)
DROP TRIGGER IF EXISTS trg_cleanup_expired_bookings ON court_locks;
CREATE TRIGGER trg_cleanup_expired_bookings
BEFORE INSERT ON court_locks
FOR EACH ROW
EXECUTE FUNCTION cleanup_expired_bookings_trigger();
