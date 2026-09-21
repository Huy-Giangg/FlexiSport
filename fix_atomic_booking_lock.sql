-- ==============================================================================
-- SQL MIGRATION: ATOMIC LOCKING & FAIL-EARLY CONCURRENCY SYSTEM CHO FLEXISPORT
-- Giải quyết triệt để lỗi 2 người cùng chọn slot và điền thông tin đến bước thanh toán mới báo lỗi
-- ==============================================================================

-- 1. Đảm bảo cấu trúc bảng court_locks và Unique Index an toàn
ALTER TABLE court_locks
  ADD COLUMN IF NOT EXISTS lock_token VARCHAR(100),
  ALTER COLUMN user_id DROP NOT NULL;

-- Đảm bảo chỉ có 1 lock duy nhất cho mỗi slot tại một thời điểm
-- (Xóa các bản ghi trùng lặp cũ nếu có trước khi tạo index)
DELETE FROM court_locks a USING court_locks b
WHERE a.id < b.id
  AND a.court_id = b.court_id
  AND a.booking_date = b.booking_date
  AND a.slot_index = b.slot_index;

-- Tạo Unique Constraint an toàn nếu chưa có
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


-- ==============================================================================
-- 2. FUNCTION NGUYÊN TỬ: acquire_court_lock
-- Chặn ngay lập tức tại bước người dùng bấm chọn ô trên lưới
-- ==============================================================================
CREATE OR REPLACE FUNCTION acquire_court_lock(
    p_court_id UUID,
    p_slot_index INTEGER,
    p_booking_date DATE,
    p_user_id UUID DEFAULT NULL,
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
    -- Bước 1: Dọn dẹp lock đã hết hạn của slot này để nhường chỗ cho người mới
    DELETE FROM court_locks 
    WHERE court_id = p_court_id 
      AND slot_index = p_slot_index 
      AND booking_date = p_booking_date 
      AND locked_until < v_now;

    -- Bước 2: Kiểm tra xem slot này đã bị ai đặt thành công trong booking_slots chưa
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

    -- Bước 3: Kiểm tra xem hiện có ai đang giữ chỗ còn hiệu lực không
    SELECT * INTO v_existing_lock
    FROM court_locks
    WHERE court_id = p_court_id
      AND slot_index = p_slot_index
      AND booking_date = p_booking_date
      AND locked_until >= v_now
    LIMIT 1;

    IF v_existing_lock.id IS NOT NULL THEN
        -- Kiểm tra xem lock này có phải của chính người này không (cùng user_id hoặc cùng lock_token)
        IF (p_user_id IS NOT NULL AND v_existing_lock.user_id = p_user_id)
           OR (p_lock_token IS NOT NULL AND v_existing_lock.lock_token = p_lock_token) THEN
            -- Gia hạn thời gian cho chính người này
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
            -- Slot đang bị NGƯỜI KHÁC giữ chỗ còn hiệu lực -> CHẶN NGAY!
            RETURN jsonb_build_object(
                'success', false,
                'error_code', 'SLOT_HELD_BY_OTHER',
                'message', 'Khung giờ này đang có người khác giữ chỗ!'
            );
        END IF;
    END IF;

    -- Bước 4: Slot hoàn toàn trống -> Tạo hoặc cập nhật lock
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


-- ==============================================================================
-- 3. FUNCTION NGUYÊN TỬ: verify_and_hold_slots_batch
-- Chặn ngay tại nút "TIẾP THEO" ở VisualBookingPage
-- Đảm bảo trước khi vào điền thông tin, toàn bộ slot đều thuộc về người này và được gia hạn 10 phút
-- ==============================================================================
CREATE OR REPLACE FUNCTION verify_and_hold_slots_batch(
    p_slots JSONB, -- Mảng [{court_id, slot_index, booking_date}]
    p_user_id UUID DEFAULT NULL,
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
    -- Nếu danh sách rỗng
    IF p_slots IS NULL OR jsonb_array_length(p_slots) = 0 THEN
        RETURN jsonb_build_object('success', false, 'message', 'Danh sách khung giờ rỗng');
    END IF;

    -- Bước 1: Duyệt kiểm tra toàn bộ danh sách để phát hiện xung đột
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_slots)
    LOOP
        v_court_id := (v_item->>'court_id')::UUID;
        v_slot_index := (v_item->>'slot_index')::INTEGER;
        v_booking_date := (v_item->>'booking_date')::DATE;

        -- 1.1 Kiểm tra đã bị đặt trong booking_slots chưa
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

        -- 1.2 Kiểm tra có bị người khác giữ chỗ còn hiệu lực không
        SELECT * INTO v_existing_lock
        FROM court_locks
        WHERE court_id = v_court_id
          AND slot_index = v_slot_index
          AND booking_date = v_booking_date
          AND locked_until >= v_now
        LIMIT 1;

        IF v_existing_lock.id IS NOT NULL THEN
            -- Nếu lock thuộc về người khác
            IF NOT ((p_user_id IS NOT NULL AND v_existing_lock.user_id = p_user_id)
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

    -- Bước 2: Khi tất cả đều hợp lệ, thực hiện gia hạn / tạo khóa độc quyền 10 phút cho toàn bộ slot
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


-- ==============================================================================
-- 4. FUNCTION: release_court_lock
-- Giải phóng slot khi người dùng bấm bỏ chọn
-- ==============================================================================
CREATE OR REPLACE FUNCTION release_court_lock(
    p_court_id UUID,
    p_slot_index INTEGER,
    p_booking_date DATE,
    p_user_id UUID DEFAULT NULL,
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
          (p_user_id IS NOT NULL AND user_id = p_user_id)
          OR (p_lock_token IS NOT NULL AND lock_token = p_lock_token)
          OR (user_id IS NULL AND lock_token IS NULL)
      );
END;
$$;
