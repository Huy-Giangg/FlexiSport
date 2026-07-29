-- 1. Xóa bảng cũ nếu tồn tại
DROP TABLE IF EXISTS venue_reviews CASCADE;

-- 2. Đảm bảo tất cả tài khoản auth.users đã có thông tin trong profiles
-- (Ngăn chặn lỗi vi phạm khóa ngoại REFERENCES profiles(id) đối với các tài khoản test cũ)
INSERT INTO public.profiles (id, name, email, phone, birth_year, gender, height, weight)
SELECT 
    id,
    COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', 'Người dùng FlexiSport'),
    COALESCE(email, ''),
    COALESCE(phone, ''),
    0,
    '',
    0.0,
    0.0
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 3. Tạo Trigger tự động đồng bộ tài khoản auth.users sang profiles khi đăng ký mới
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, phone, birth_year, gender, height, weight)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Người dùng FlexiSport'),
    COALESCE(new.email, ''),
    COALESCE(new.phone, ''),
    0,
    '',
    0.0,
    0.0
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Xóa trigger cũ nếu tồn tại trước khi tạo mới
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Tạo bảng venue_reviews
CREATE TABLE venue_reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    venue_id UUID REFERENCES venues(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    rating DOUBLE PRECISION CHECK (rating >= 1.0 AND rating <= 5.0) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    
    -- Đảm bảo mỗi đơn đặt sân chỉ được đánh giá 1 lần duy nhất
    CONSTRAINT unique_booking_review UNIQUE (booking_id)
);

-- 5. Bật Row Level Security (RLS) để bảo mật
ALTER TABLE venue_reviews ENABLE ROW LEVEL SECURITY;

-- 6. Tạo các Policy bảo mật (Cho phép Insert và Select rộng rãi hơn cho mục đích test)
CREATE POLICY "Allow public select reviews" ON venue_reviews 
    FOR SELECT USING (true);

CREATE POLICY "Allow authenticated insert reviews" ON venue_reviews 
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow user update own review" ON venue_reviews 
    FOR UPDATE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Allow user delete own review" ON venue_reviews 
    FOR DELETE TO authenticated USING (auth.uid() = user_id);
