-- ==============================================================================
-- SQL MIGRATION: KHẮC PHỤC 5 LỖI NGHIỆP VỤ & KIẾN TRÚC HỆ THỐNG FLEXISPORT
-- 1. Chống Race Condition đặt sân (Locking Concurrency)
-- 2. Bảo vệ khách quét QR & xử lý thanh toán trễ hạn
-- 3. Giải phóng vĩnh viễn khung giờ đã hủy (Partial Unique Index)
-- 4. Hỗ trợ khách vãng lai (lock_token cho guest_user)
-- 5. Đồng bộ cấu hình biểu giá từ Chủ sân xuống Khách hàng (Database-driven Pricing)
-- ==============================================================================

-- 1. BẢNG COURTS: BỔ SUNG CÁC CỘT BIỂU GIÁ LINH HOẠT
ALTER TABLE courts 
  ADD COLUMN IF NOT EXISTS price_per_hour DECIMAL(10, 2) DEFAULT 140000.0,
  ADD COLUMN IF NOT EXISTS peak_price DECIMAL(10, 2) DEFAULT 182000.0,
  ADD COLUMN IF NOT EXISTS apply_peak BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS weekend_surcharge DECIMAL(10, 2) DEFAULT 20000.0,
  ADD COLUMN IF NOT EXISTS apply_weekend BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'active';

-- Cập nhật giá mặc định cho các sân hiện có nếu giá đang NULL
UPDATE courts SET 
  price_per_hour = COALESCE(price_per_hour, 140000.0),
  peak_price = COALESCE(peak_price, 182000.0),
  apply_peak = COALESCE(apply_peak, true),
  weekend_surcharge = COALESCE(weekend_surcharge, 20000.0),
  apply_weekend = COALESCE(apply_weekend, true)
WHERE price_per_hour IS NULL;


-- 2. BẢNG COURT_LOCKS: HỖ TRỢ KHÁCH VÃNG LAI & GIA HẠN GIỮ CHỖ
ALTER TABLE court_locks
  ADD COLUMN IF NOT EXISTS lock_token VARCHAR(100),
  ALTER COLUMN user_id DROP NOT NULL;

-- Cập nhật RLS cho court_locks
ALTER TABLE court_locks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép đọc locks công khai" ON court_locks;
CREATE POLICY "Cho phép đọc locks công khai" ON court_locks 
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Cho phép người dùng tạo lock" ON court_locks;
CREATE POLICY "Cho phép người dùng tạo lock" ON court_locks 
    FOR INSERT WITH CHECK (
        auth.uid() = user_id 
        OR user_id IS NULL 
        OR lock_token IS NOT NULL
    );

DROP POLICY IF EXISTS "Cho phép người dùng xóa lock" ON court_locks;
CREATE POLICY "Cho phép người dùng xóa lock" ON court_locks 
    FOR DELETE USING (
        auth.uid() = user_id 
        OR user_id IS NULL 
        OR lock_token IS NOT NULL
    );

DROP POLICY IF EXISTS "Cho phép cập nhật lock" ON court_locks;
CREATE POLICY "Cho phép cập nhật lock" ON court_locks 
    FOR UPDATE USING (true) WITH CHECK (true);

-- Đảm bảo realtime cho court_locks
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'court_locks'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE court_locks;
    END IF;
END $$;


-- 3. BẢNG BOOKING_SLOTS: GIẢI QUYẾT LỖI KHUNG GIỜ ĐÃ HỦY BỊ KHÓA CHẾT
-- Thêm cột is_active vào booking_slots
ALTER TABLE booking_slots 
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true NOT NULL;

-- Xóa ràng buộc cứng unique_court_date_slot nếu tồn tại
ALTER TABLE booking_slots 
  DROP CONSTRAINT IF EXISTS unique_court_date_slot;

-- Tạo Partial Unique Index: Chỉ ngăn chặn trùng lặp với các slot ĐANG CÒN HIỆU LỰC (is_active = true)
-- Các đơn hủy (is_active = false) sẽ không bao giờ gây lỗi xung đột UNIQUE!
DROP INDEX IF EXISTS unique_court_date_slot_active;
CREATE UNIQUE INDEX unique_court_date_slot_active 
ON booking_slots (court_id, booking_date, slot_index) 
WHERE (is_active = true);

-- Đảm bảo realtime cho booking_slots
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'booking_slots'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE booking_slots;
    END IF;
END $$;


-- 4. TRIGGER TỰ ĐỘNG GIẢI PHÓNG SLOT KHI ĐƠN HÀNG BỊ HỦY
CREATE OR REPLACE FUNCTION on_booking_status_change_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Nếu đơn hàng chuyển sang trạng thái 'cancelled'
    IF NEW.status = 'cancelled' AND (OLD.status IS DISTINCT FROM 'cancelled') THEN
        -- Đánh dấu vô hiệu hóa các slot để giải phóng cho người khác đặt ngay lập tức
        UPDATE booking_slots 
        SET is_active = false 
        WHERE booking_id = NEW.id;

        -- Giải phóng lock tạm thời nếu còn
        DELETE FROM court_locks 
        WHERE (court_id, booking_date, slot_index) IN (
            SELECT court_id, booking_date, slot_index 
            FROM booking_slots 
            WHERE booking_id = NEW.id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_on_booking_status_change ON bookings;
CREATE TRIGGER trg_on_booking_status_change
AFTER UPDATE OF status ON bookings
FOR EACH ROW
EXECUTE FUNCTION on_booking_status_change_trigger();


-- 5. FUNCTION GIA HẠN GIỮ CHỖ (EXTEND LOCKS) KHI TIẾN VÀO MÀN HÌNH THANH TOÁN QR
CREATE OR REPLACE FUNCTION extend_court_locks(
    p_slots JSONB,              -- [{court_id, booking_date, slot_index}]
    p_lock_token VARCHAR,       -- Mã phiên của thiết bị/khách
    p_user_id UUID DEFAULT NULL,
    p_duration_minutes INTEGER DEFAULT 10
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    slot_record RECORD;
BEGIN
    FOR slot_record IN SELECT * FROM jsonb_to_recordset(p_slots) AS x(court_id UUID, booking_date DATE, slot_index INTEGER)
    LOOP
        UPDATE court_locks
        SET locked_until = NOW() + (p_duration_minutes || ' minutes')::INTERVAL
        WHERE court_id = slot_record.court_id
          AND booking_date = slot_record.booking_date
          AND slot_index = slot_record.slot_index
          AND (
              (p_user_id IS NOT NULL AND user_id = p_user_id)
              OR (p_lock_token IS NOT NULL AND lock_token = p_lock_token)
              OR user_id IS NULL
          );
    END LOOP;

    RETURN true;
END;
$$;


-- 6. CẬP NHẬT RPC: create_booking_transaction NGUYÊN TỬ (ATOMIC & CONCURRENCY-SAFE)
CREATE OR REPLACE FUNCTION create_booking_transaction(
    p_user_id UUID,
    p_total_amount DECIMAL(10, 2),
    p_customer_name VARCHAR,
    p_customer_phone VARCHAR,
    p_note TEXT,
    p_slots JSONB, -- Mảng JSON chứa [{court_id, booking_date, slot_index}]
    p_lock_token VARCHAR DEFAULT NULL
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
    v_conflict_count INTEGER := 0;
    v_result JSONB;
BEGIN
    -- 1. Kiểm tra Concurrency Race Condition:
    -- Đảm bảo không có slot nào đã được đặt bởi đơn khác còn hiệu lực (is_active = true)
    FOR slot_record IN SELECT * FROM jsonb_to_recordset(p_slots) AS x(court_id UUID, booking_date DATE, slot_index INTEGER)
    LOOP
        SELECT COUNT(*) INTO v_conflict_count
        FROM booking_slots bs
        JOIN bookings b ON b.id = bs.booking_id
        WHERE bs.court_id = slot_record.court_id
          AND bs.booking_date = slot_record.booking_date
          AND bs.slot_index = slot_record.slot_index
          AND bs.is_active = true
          AND b.status IN ('completed', 'confirmed', 'pending_payment');

        IF v_conflict_count > 0 THEN
            RAISE EXCEPTION 'Khung giờ này vừa được người khác đặt trước. Vui lòng chọn khung giờ khác!';
        END IF;
    END LOOP;

    -- 2. Tạo bản ghi booking mới với trạng thái pending_payment
    INSERT INTO bookings (user_id, total_amount, status, customer_name, customer_phone, note)
    VALUES (p_user_id, p_total_amount, 'pending_payment', p_customer_name, p_customer_phone, p_note)
    RETURNING id INTO v_booking_id;

    -- 3. Tạo mã payment_reference duy nhất (VD: FLEXI12345678)
    v_short_id := upper(substring(v_booking_id::text from 29 for 8));
    v_payment_reference := 'FLEXI' || v_short_id;

    -- 4. Tạo bản ghi payment tương ứng
    INSERT INTO payments (booking_id, amount, status, payment_reference)
    VALUES (v_booking_id, p_total_amount, 'PENDING', v_payment_reference);

    -- 5. Thêm các slot đặt vào bảng booking_slots với is_active = true
    FOR slot_record IN SELECT * FROM jsonb_to_recordset(p_slots) AS x(court_id UUID, booking_date DATE, slot_index INTEGER)
    LOOP
        INSERT INTO booking_slots (booking_id, court_id, booking_date, slot_index, is_active)
        VALUES (v_booking_id, slot_record.court_id, slot_record.booking_date, slot_record.slot_index, true);
    END LOOP;

    -- 6. Gia hạn lock trong 10 phút để người dùng quét QR không bị cướp
    FOR slot_record IN SELECT * FROM jsonb_to_recordset(p_slots) AS x(court_id UUID, booking_date DATE, slot_index INTEGER)
    LOOP
        UPDATE court_locks
        SET locked_until = NOW() + INTERVAL '10 minutes'
        WHERE court_id = slot_record.court_id
          AND booking_date = slot_record.booking_date
          AND slot_index = slot_record.slot_index;
    END LOOP;

    -- 7. Trả về kết quả cho client
    v_result := jsonb_build_object(
        'booking_id', v_booking_id,
        'payment_reference', v_payment_reference
    );
    
    RETURN v_result;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Lỗi giao dịch đặt sân: %', SQLERRM;
END;
$$;


-- 7. CẬP NHẬT RPC HỦY BOOKING KHI HẾT HẠN HOẶC NGƯỜI DÙNG BẤM HỦY
CREATE OR REPLACE FUNCTION cancel_expired_booking(p_booking_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Cập nhật booking sang cancelled (Trigger sẽ tự động đặt booking_slots.is_active = false)
    UPDATE bookings 
    SET status = 'cancelled' 
    WHERE id = p_booking_id AND status = 'pending_payment';
    
    IF FOUND THEN
        -- Đảm bảo vô hiệu hóa slot
        UPDATE booking_slots SET is_active = false WHERE booking_id = p_booking_id;
        
        -- Cập nhật trạng thái payment thành FAILED
        UPDATE payments SET status = 'FAILED' WHERE booking_id = p_booking_id AND status = 'PENDING';
    END IF;
END;
$$;
