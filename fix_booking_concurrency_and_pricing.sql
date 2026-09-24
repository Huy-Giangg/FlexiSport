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

-- Đảm bảo không có dòng trùng lặp trước khi tạo Unique Constraint
DELETE FROM court_locks a USING court_locks b
WHERE a.id < b.id
  AND a.court_id = b.court_id
  AND a.booking_date = b.booking_date
  AND a.slot_index = b.slot_index;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'unique_court_lock'
    ) THEN
        ALTER TABLE court_locks ADD CONSTRAINT unique_court_lock UNIQUE (court_id, booking_date, slot_index);
    END IF;
EXCEPTION
    WHEN duplicate_table OR duplicate_object THEN NULL;
END $$;

-- Cập nhật RLS cho court_locks
ALTER TABLE court_locks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép đọc locks công khai" ON court_locks;
CREATE POLICY "Cho phép đọc locks công khai" ON court_locks 
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Cho phép người dùng tạo lock" ON court_locks;
CREATE POLICY "Cho phép người dùng tạo lock" ON court_locks 
    FOR INSERT WITH CHECK (
        auth.uid()::text = user_id::text 
        OR user_id IS NULL 
        OR lock_token IS NOT NULL
    );

DROP POLICY IF EXISTS "Cho phép người dùng xóa lock" ON court_locks;
CREATE POLICY "Cho phép người dùng xóa lock" ON court_locks 
    FOR DELETE USING (
        auth.uid()::text = user_id::text 
        OR user_id IS NULL 
        OR lock_token IS NOT NULL
    );

DROP POLICY IF EXISTS "Cho phép cập nhật lock" ON court_locks;
CREATE POLICY "Cho phép cập nhật lock" ON court_locks 
    FOR UPDATE USING (true) WITH CHECK (true);

-- 2.1 FUNCTION NGUYÊN TỬ: acquire_court_lock (Chống cướp slot ngay khi chạm ô giờ)
CREATE OR REPLACE FUNCTION acquire_court_lock(
    p_court_id UUID,
    p_slot_index INTEGER,
    p_booking_date DATE,
    p_user_id VARCHAR DEFAULT NULL,
    p_lock_token VARCHAR DEFAULT NULL,
    p_duration_minutes INTEGER DEFAULT 5
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_now TIMESTAMP WITH TIME ZONE := NOW();
    v_new_expiry TIMESTAMP WITH TIME ZONE := NOW() + (p_duration_minutes || ' minutes')::INTERVAL;
    v_existing_lock RECORD;
    v_existing_booking RECORD;
BEGIN
    DELETE FROM court_locks 
    WHERE court_id = p_court_id 
      AND slot_index = p_slot_index 
      AND booking_date = p_booking_date 
      AND locked_until < v_now;

    SELECT bs.id, b.status INTO v_existing_booking
    FROM booking_slots bs
    JOIN bookings b ON bs.booking_id = b.id
    WHERE bs.court_id = p_court_id
      AND bs.slot_index = p_slot_index
      AND bs.booking_date = p_booking_date
      AND (bs.is_active = true OR bs.is_active IS NULL)
      AND b.status NOT IN ('cancelled', 'refunded', 'payment_failed')
    LIMIT 1;

    IF v_existing_booking.id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error_code', 'SLOT_ALREADY_BOOKED',
            'message', 'Khung giờ này đã có người đặt trước!'
        );
    END IF;

    SELECT * INTO v_existing_lock
    FROM court_locks
    WHERE court_id = p_court_id
      AND slot_index = p_slot_index
      AND booking_date = p_booking_date
      AND locked_until >= v_now
    LIMIT 1;

    IF v_existing_lock.id IS NOT NULL THEN
        IF (p_user_id IS NOT NULL AND v_existing_lock.user_id::text = p_user_id::text)
           OR (p_lock_token IS NOT NULL AND v_existing_lock.lock_token = p_lock_token) THEN
            UPDATE court_locks
            SET locked_until = v_new_expiry,
                user_id = COALESCE(p_user_id, user_id),
                lock_token = COALESCE(p_lock_token, lock_token)
            WHERE id = v_existing_lock.id;

            RETURN jsonb_build_object(
                'success', true,
                'message', 'Gia hạn giữ chỗ thành công',
                'locked_until', v_new_expiry
            );
        ELSE
            RETURN jsonb_build_object(
                'success', false,
                'error_code', 'SLOT_HELD_BY_OTHER',
                'message', 'Khung giờ này đang có người khác giữ chỗ!'
            );
        END IF;
    END IF;

    INSERT INTO court_locks (
        court_id,
        slot_index,
        booking_date,
        user_id,
        lock_token,
        locked_until
    ) VALUES (
        p_court_id,
        p_slot_index,
        p_booking_date,
        p_user_id,
        p_lock_token,
        v_new_expiry
    )
    ON CONFLICT (court_id, booking_date, slot_index) 
    DO UPDATE SET 
        locked_until = EXCLUDED.locked_until,
        user_id = EXCLUDED.user_id,
        lock_token = EXCLUDED.lock_token;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Giữ chỗ thành công',
        'locked_until', v_new_expiry
    );
END;
$$;

-- 2.2 FUNCTION BATCH: verify_and_hold_slots_batch (Chặn tại nút TIẾP THEO)
CREATE OR REPLACE FUNCTION verify_and_hold_slots_batch(
    p_slots JSONB,
    p_user_id VARCHAR DEFAULT NULL,
    p_lock_token VARCHAR DEFAULT NULL,
    p_duration_minutes INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_now TIMESTAMP WITH TIME ZONE := NOW();
    v_new_expiry TIMESTAMP WITH TIME ZONE := NOW() + (p_duration_minutes || ' minutes')::INTERVAL;
    v_item JSONB;
    v_court_id UUID;
    v_slot_index INTEGER;
    v_booking_date DATE;
    v_existing_booking RECORD;
    v_existing_lock RECORD;
    v_court_name TEXT;
BEGIN
    IF p_slots IS NULL OR jsonb_array_length(p_slots) = 0 THEN
        RETURN jsonb_build_object('success', false, 'message', 'Danh sách khung giờ rỗng');
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_slots)
    LOOP
        v_court_id := (v_item->>'court_id')::UUID;
        v_slot_index := (v_item->>'slot_index')::INTEGER;
        v_booking_date := (v_item->>'booking_date')::DATE;

        SELECT bs.id, c.name INTO v_existing_booking
        FROM booking_slots bs
        JOIN bookings b ON bs.booking_id = b.id
        LEFT JOIN courts c ON c.id = bs.court_id
        WHERE bs.court_id = v_court_id
          AND bs.slot_index = v_slot_index
          AND bs.booking_date = v_booking_date
          AND (bs.is_active = true OR bs.is_active IS NULL)
          AND b.status NOT IN ('cancelled', 'refunded', 'payment_failed')
        LIMIT 1;

        IF v_existing_booking.id IS NOT NULL THEN
            RETURN jsonb_build_object(
                'success', false,
                'error_code', 'SLOT_ALREADY_BOOKED',
                'conflict_slot', v_item,
                'court_name', COALESCE(v_existing_booking.name, 'Sân'),
                'message', 'Khung giờ bạn chọn đã có người hoàn tất đặt trước!'
            );
        END IF;

        SELECT * INTO v_existing_lock
        FROM court_locks
        WHERE court_id = v_court_id
          AND slot_index = v_slot_index
          AND booking_date = v_booking_date
          AND locked_until >= v_now
        LIMIT 1;

        IF v_existing_lock.id IS NOT NULL THEN
            IF NOT ((p_user_id IS NOT NULL AND v_existing_lock.user_id::text = p_user_id::text)
                 OR (p_lock_token IS NOT NULL AND v_existing_lock.lock_token = p_lock_token)) THEN
                
                SELECT name INTO v_court_name FROM courts WHERE id = v_court_id;
                RETURN jsonb_build_object(
                    'success', false,
                    'error_code', 'SLOT_HELD_BY_OTHER',
                    'conflict_slot', v_item,
                    'court_name', COALESCE(v_court_name, 'Sân'),
                    'message', 'Một trong các khung giờ bạn chọn vừa có người khác giữ chỗ!'
                );
            END IF;
        END IF;
    END LOOP;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_slots)
    LOOP
        v_court_id := (v_item->>'court_id')::UUID;
        v_slot_index := (v_item->>'slot_index')::INTEGER;
        v_booking_date := (v_item->>'booking_date')::DATE;

        INSERT INTO court_locks (
            court_id,
            slot_index,
            booking_date,
            user_id,
            lock_token,
            locked_until
        ) VALUES (
            v_court_id,
            v_slot_index,
            v_booking_date,
            p_user_id,
            p_lock_token,
            v_new_expiry
        )
        ON CONFLICT (court_id, booking_date, slot_index) 
        DO UPDATE SET 
            locked_until = EXCLUDED.locked_until,
            user_id = EXCLUDED.user_id,
            lock_token = EXCLUDED.lock_token;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Xác thực và gia hạn giữ chỗ 10 phút thành công',
        'locked_until', v_new_expiry
    );
END;
$$;

-- 2.3 FUNCTION: release_court_lock
CREATE OR REPLACE FUNCTION release_court_lock(
    p_court_id UUID,
    p_slot_index INTEGER,
    p_booking_date DATE,
    p_user_id VARCHAR DEFAULT NULL,
    p_lock_token VARCHAR DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM court_locks
    WHERE court_id = p_court_id
      AND slot_index = p_slot_index
      AND booking_date = p_booking_date
      AND (
          (p_user_id IS NOT NULL AND user_id::text = p_user_id::text)
          OR (p_lock_token IS NOT NULL AND lock_token = p_lock_token)
          OR (user_id IS NULL AND lock_token IS NULL)
      );
END;
$$;


-- Đảm bảo realtime cho court_locks và courts
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'court_locks'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE court_locks;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'courts'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE courts;
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
    p_user_id VARCHAR DEFAULT NULL,
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
              (p_user_id IS NOT NULL AND user_id::text = p_user_id::text)
              OR (p_lock_token IS NOT NULL AND lock_token = p_lock_token)
              OR user_id IS NULL
          );
    END LOOP;

    RETURN true;
END;
$$;


-- 6. CẬP NHẬT RPC: create_booking_transaction NGUYÊN TỬ & ĐỐI SOÁT GIÁ SERVER-SIDE (ATOMIC & CONCURRENCY & PRICING-SAFE)
CREATE OR REPLACE FUNCTION create_booking_transaction(
    p_user_id VARCHAR DEFAULT NULL,
    p_total_amount DECIMAL(10, 2) DEFAULT 0,
    p_customer_name VARCHAR DEFAULT '',
    p_customer_phone VARCHAR DEFAULT '',
    p_note TEXT DEFAULT '',
    p_slots JSONB DEFAULT '[]'::JSONB, -- Mảng JSON chứa [{court_id, booking_date, slot_index}]
    p_lock_token VARCHAR DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_uuid UUID := NULL;
    v_booking_id UUID;
    v_payment_reference VARCHAR;
    v_short_id VARCHAR;
    slot_record RECORD;
    v_conflict_count INTEGER := 0;
    v_result JSONB;
    v_court_rec RECORD;
    v_base_minutes INTEGER;
    v_slot_start_minutes INTEGER;
    v_is_peak BOOLEAN;
    v_is_weekend BOOLEAN;
    v_hour_price DECIMAL(10, 2);
    v_expected_total DECIMAL(10, 2) := 0.0;
    v_final_amount DECIMAL(10, 2);
BEGIN
    -- Chuyển đổi user_id sang UUID an toàn nếu là tài khoản đăng nhập
    IF p_user_id IS NOT NULL AND p_user_id != '' AND p_user_id != 'guest_user' THEN
        BEGIN
            v_user_uuid := p_user_id::UUID;
        EXCEPTION WHEN OTHERS THEN
            v_user_uuid := NULL;
        END;
    END IF;
    -- 1. Kiểm tra Concurrency Race Condition & Tính toán / Đối soát giá Server-side
    FOR slot_record IN SELECT * FROM jsonb_to_recordset(p_slots) AS x(court_id UUID, booking_date DATE, slot_index INTEGER)
    LOOP
        -- a. Kiểm tra xung đột slot
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

        -- b. Lấy thông tin biểu giá từ bảng courts và giờ mở cửa cơ sở
        SELECT c.price_per_hour, c.peak_price, c.apply_peak, c.weekend_surcharge, c.apply_weekend, v.open_time
        INTO v_court_rec
        FROM courts c
        LEFT JOIN venues v ON v.id = c.venue_id
        WHERE c.id = slot_record.court_id;

        IF FOUND THEN
            -- Tính phút bắt đầu của slot
            IF v_court_rec.open_time IS NOT NULL AND v_court_rec.open_time != '' THEN
                BEGIN
                    v_base_minutes := EXTRACT(HOUR FROM v_court_rec.open_time::time) * 60 + EXTRACT(MINUTE FROM v_court_rec.open_time::time);
                EXCEPTION WHEN OTHERS THEN
                    v_base_minutes := 6 * 60;
                END;
            ELSE
                v_base_minutes := 6 * 60;
            END IF;

            v_slot_start_minutes := v_base_minutes + slot_record.slot_index * 30;

            -- Giờ cao điểm (16:00 - 22:00, tức 960 phút đến 1320 phút)
            v_is_peak := (v_slot_start_minutes >= 960 AND v_slot_start_minutes < 1320);

            -- Giá cơ sở theo giờ
            v_hour_price := COALESCE(v_court_rec.price_per_hour, 140000.0);
            IF v_is_peak AND COALESCE(v_court_rec.apply_peak, true) THEN
                v_hour_price := COALESCE(v_court_rec.peak_price, ROUND(v_hour_price * 1.3));
            END IF;

            -- Kiểm tra ngày cuối tuần (Thứ 7 = 6, Chủ nhật = 7)
            v_is_weekend := EXTRACT(ISODOW FROM slot_record.booking_date) IN (6, 7);
            IF v_is_weekend AND COALESCE(v_court_rec.apply_weekend, true) THEN
                v_hour_price := v_hour_price + COALESCE(v_court_rec.weekend_surcharge, 20000.0);
            END IF;

            -- Mỗi slot 30 phút = 0.5 giờ
            v_expected_total := v_expected_total + (v_hour_price * 0.5);
        ELSE
            -- Dự phòng nếu không tìm thấy bản ghi sân
            v_expected_total := v_expected_total + 70000.0;
        END IF;
    END LOOP;

    -- 2. Đối soát giá Server-side với số tiền do Client gửi lên
    IF v_expected_total > 0 THEN
        IF p_total_amount IS NULL OR p_total_amount <= 0 THEN
            v_final_amount := v_expected_total;
        ELSIF ABS(p_total_amount - v_expected_total) > 1000.0 THEN
            RAISE EXCEPTION 'PRICE_MISMATCH: Biểu giá sân đã được cập nhật mới (%đ thay vì %đ). Vui lòng quay lại màn hình đặt sân để cập nhật giá mới!', v_expected_total, p_total_amount;
        ELSE
            v_final_amount := p_total_amount;
        END IF;
    ELSE
        v_final_amount := COALESCE(p_total_amount, 0.0);
    END IF;

    -- 3. Tạo bản ghi booking mới với trạng thái pending_payment
    INSERT INTO bookings (user_id, total_amount, status, customer_name, customer_phone, note)
    VALUES (v_user_uuid, v_final_amount, 'pending_payment', p_customer_name, p_customer_phone, p_note)
    RETURNING id INTO v_booking_id;

    -- 4. Tạo mã payment_reference duy nhất (VD: FLEXI12345678)
    v_short_id := upper(substring(v_booking_id::text from 29 for 8));
    v_payment_reference := 'FLEXI' || v_short_id;

    -- 5. Tạo bản ghi payment tương ứng
    INSERT INTO payments (booking_id, amount, status, payment_reference)
    VALUES (v_booking_id, v_final_amount, 'PENDING', v_payment_reference);

    -- 6. Thêm các slot đặt vào bảng booking_slots với is_active = true
    FOR slot_record IN SELECT * FROM jsonb_to_recordset(p_slots) AS x(court_id UUID, booking_date DATE, slot_index INTEGER)
    LOOP
        INSERT INTO booking_slots (booking_id, court_id, booking_date, slot_index, is_active)
        VALUES (v_booking_id, slot_record.court_id, slot_record.booking_date, slot_record.slot_index, true);
    END LOOP;

    -- 7. Gia hạn lock trong 10 phút để người dùng quét QR không bị cướp
    FOR slot_record IN SELECT * FROM jsonb_to_recordset(p_slots) AS x(court_id UUID, booking_date DATE, slot_index INTEGER)
    LOOP
        UPDATE court_locks
        SET locked_until = NOW() + INTERVAL '10 minutes'
        WHERE court_id = slot_record.court_id
          AND booking_date = slot_record.booking_date
          AND slot_index = slot_record.slot_index;
    END LOOP;

    -- 8. Trả về kết quả cho client
    v_result := jsonb_build_object(
        'booking_id', v_booking_id,
        'payment_reference', v_payment_reference,
        'verified_total_amount', v_final_amount
    );
    
    RETURN v_result;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Lỗi giao dịch đặt sân: %', SQLERRM;
END;
$$;


-- 7. CẬP NHẬT RPC HỦY BOOKING KHI HẾT HẠN HOẶC NGƯỜI DÙNG BẤM HỦY
CREATE OR REPLACE FUNCTION cancel_expired_booking(p_booking_id VARCHAR)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Cập nhật booking sang cancelled (Trigger sẽ tự động đặt booking_slots.is_active = false)
    UPDATE bookings 
    SET status = 'cancelled' 
    WHERE id::text = p_booking_id::text AND status = 'pending_payment';
    
    IF FOUND THEN
        -- Đảm bảo vô hiệu hóa slot
        UPDATE booking_slots SET is_active = false WHERE booking_id::text = p_booking_id::text;
        
        -- Cập nhật trạng thái payment thành FAILED
        UPDATE payments SET status = 'FAILED' WHERE booking_id::text = p_booking_id::text AND status = 'PENDING';
    END IF;
END;
$$;
