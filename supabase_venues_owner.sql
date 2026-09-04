-- ==============================================================================
-- SQL MIGRATION: CẤP QUYỀN VÀ THÊM CỘT OWNER_ID CHO BẢNG VENUES
-- Sao chép và chạy file này trong Supabase SQL Editor
-- ==============================================================================

-- 1. Thêm cột owner_id vào bảng venues nếu chưa tồn tại
ALTER TABLE venues ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id);

-- 2. Thêm cột ngân hàng nếu chưa có
ALTER TABLE venues ADD COLUMN IF NOT EXISTS bank_name VARCHAR(100);
ALTER TABLE venues ADD COLUMN IF NOT EXISTS account_number VARCHAR(50);

-- 3. Tạo index tìm kiếm nhanh venues theo owner_id
CREATE INDEX IF NOT EXISTS idx_venues_owner_id ON venues(owner_id);

-- 4. Cấu hình RLS cho bảng venues
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Cho phép đọc venues công khai" ON venues;
CREATE POLICY "Cho phép đọc venues công khai" ON venues 
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Cho phép insert venues" ON venues;
CREATE POLICY "Cho phép insert venues" ON venues 
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Cho phép update venues" ON venues;
CREATE POLICY "Cho phép update venues" ON venues 
    FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Cho phép delete venues" ON venues;
CREATE POLICY "Cho phép delete venues" ON venues 
    FOR DELETE USING (true);
