-- ==============================================================================
-- FIX LỖI PGRST203: FUNCTION OVERLOADING CHO create_booking_transaction
-- Nguyên nhân: Trong Supabase đang tồn tại 2 hàm trùng tên với chữ ký tham số khác nhau:
-- 1) create_booking_transaction(p_user_id uuid, ...) (Hàm cũ)
-- 2) create_booking_transaction(p_user_id character varying, ..., p_lock_token ...) (Hàm mới)
-- ==============================================================================

-- 1. XÓA BỎ TẤT CẢ CÁC PHIÊN BẢN CŨ GÂY XUNG ĐỘT
DROP FUNCTION IF EXISTS public.create_booking_transaction(uuid, numeric, character varying, character varying, text, jsonb);
DROP FUNCTION IF EXISTS public.create_booking_transaction(varchar, numeric, varchar, varchar, text, jsonb);
DROP FUNCTION IF EXISTS public.create_booking_transaction(varchar, numeric, varchar, varchar, text, jsonb, varchar);

-- 2. TẠO LẠI PHIÊN BẢN CHUẨN DUY NHẤT HỖ TRỢ ĐẦY ĐỦ (GUEST USER + KHÓA ATOMIC + ĐỐI SOÁT GIÁ)
CREATE OR REPLACE FUNCTION public.create_booking_transaction(
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

-- 3. XÓA BỎ VÀ TẠO LẠI RPC: cancel_expired_booking (GIẢI PHÓNG TOÀN DIỆN LOCK VÀ SLOT KHI HỦY HOẶC THOÁT THANH TOÁN)
DROP FUNCTION IF EXISTS public.cancel_expired_booking(uuid);
DROP FUNCTION IF EXISTS public.cancel_expired_booking(varchar);

CREATE OR REPLACE FUNCTION public.cancel_expired_booking(p_booking_id VARCHAR)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_b_id UUID;
BEGIN
    BEGIN
        v_b_id := p_booking_id::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_b_id := NULL;
    END;

    -- 1. Giải phóng ngay các ô khóa court_locks tương ứng với các slot của đơn này
    DELETE FROM court_locks 
    WHERE (court_id, booking_date, slot_index) IN (
        SELECT court_id, booking_date, slot_index 
        FROM booking_slots 
        WHERE booking_id::text = p_booking_id::text OR (v_b_id IS NOT NULL AND booking_id = v_b_id)
    );

    -- 2. Xóa các slot đặt khỏi booking_slots để giải phóng lưới trực quan ngay lập tức
    DELETE FROM booking_slots 
    WHERE booking_id::text = p_booking_id::text OR (v_b_id IS NOT NULL AND booking_id = v_b_id);

    -- 3. Cập nhật trạng thái booking sang cancelled
    UPDATE bookings 
    SET status = 'cancelled' 
    WHERE (id::text = p_booking_id::text OR (v_b_id IS NOT NULL AND id = v_b_id)) 
      AND status = 'pending_payment';

    -- 4. Cập nhật trạng thái thanh toán sang FAILED
    UPDATE payments 
    SET status = 'FAILED' 
    WHERE (booking_id::text = p_booking_id::text OR (v_b_id IS NOT NULL AND booking_id = v_b_id)) 
      AND status = 'PENDING';
END;
$$;

