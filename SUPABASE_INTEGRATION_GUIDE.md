# Hướng dẫn Tích hợp và Triển khai Thanh toán Tự động VietQR

Tài liệu này hướng dẫn bạn từng bước cấu hình Database, triển khai Supabase Edge Function và thiết lập Webhook biến động số dư để hoàn thành hệ thống thanh toán tự động.

---

## Bước 1: Cấu hình Cơ sở dữ liệu Supabase

1. Truy cập vào [Supabase Dashboard](https://supabase.com/dashboard) và chọn dự án của bạn.
2. Điều hướng đến mục **SQL Editor** ở thanh menu bên trái.
3. Nhấp vào **New Query** để tạo một trang soạn thảo mới.
4. Mở file [supabase_vietqr_payment.sql](./supabase_vietqr_payment.sql) vừa được tạo trong dự án của bạn.
5. Copy toàn bộ nội dung của file SQL và paste vào trang soạn thảo trên Supabase Dashboard.
6. Nhấn nút **Run** ở góc dưới cùng bên phải để thực thi câu lệnh.
   * *Kết quả mong đợi*: Lệnh thực thi thành công, bảng `payments` được tạo, bảng `bookings` được cấu hình, và các hàm RPC `create_booking_transaction`, `cancel_expired_booking` đã sẵn sàng.

---

## Bước 2: Thiết lập Biến môi trường trên Supabase (Secrets)

Edge Function cần khóa bảo mật để xác thực các cuộc gọi webhook từ các bên thứ ba gửi tới. Bạn cần đặt biến môi trường này trước khi deploy:

1. Mở Terminal (Command Prompt hoặc PowerShell trên Windows) ngay tại thư mục dự án của bạn (`flexisport_app`).
2. Chạy lệnh sau để cấu hình Token bảo mật cho Webhook (thay đổi `my_secret_token_123` bằng một chuỗi ký tự khó đoán bất kỳ của bạn):

   ```bash
   supabase secrets set WEBHOOK_SECRET_TOKEN=my_secret_token_123
   ```

   *Lưu ý: Nếu bạn chưa đăng nhập CLI, hãy chạy `supabase login` và `supabase link --project-ref <your-project-id>` trước.*

---

## Bước 3: Triển khai Supabase Edge Function (`vietqr-webhook`)

1. Trên Terminal tại thư mục dự án, chạy lệnh sau để deploy Edge Function lên cloud và tắt xác thực JWT mặc định (để nhận webhook công khai):

   ```bash
   supabase functions deploy vietqr-webhook --no-verify-jwt
   ```

2. Sau khi deploy thành công, terminal sẽ trả về URL của Edge Function có dạng:
   `https://[PROJECT_ID].supabase.co/functions/v1/vietqr-webhook`
   Hãy lưu lại URL này để cấu hình trên cổng thanh toán (SePay/Casso).

---

## Bước 4: Cấu hình Webhook trên Cổng biến động số dư (SePay / Casso)

### A. Nếu sử dụng SePay.vn (Khuyên dùng cho tài khoản cá nhân):
1. Đăng nhập vào tài khoản SePay của bạn.
2. Thêm Ngân hàng thụ hưởng trùng khớp với thông tin thụ hưởng trong app Flutter (`Vietcombank - 1022190144`).
3. Đi đến mục **Webhooks** -> Chọn **Thêm mới Webhook**:
   * **URL nhận Webhook**: Dán URL Edge Function đã lưu ở Bước 3.
   * **Phương thức**: Chọn `POST`.
   * **Kiểu dữ liệu**: Chọn `JSON`.
   * **Headers**: Thêm dòng header xác thực:
     * Key: `x-api-key`
     * Value: Giá trị token bạn đã đặt ở Bước 2 (Ví dụ: `my_secret_token_123`).
4. Nhấn **Lưu cấu hình**.

### B. Nếu sử dụng Casso.vn:
1. Đăng nhập vào tài khoản Casso.
2. Liên kết tài khoản Ngân hàng thụ hưởng.
3. Đi đến cấu hình **Webhook** -> Tạo mới webhook:
   * **URL nhận webhook**: Dán URL Edge Function của bạn.
   * **Secure Token**: Nhập giá trị token trùng với token đã cấu hình ở Bước 2 (`my_secret_token_123`).
4. Nhấn **Lưu**.

---

## Bước 5: Kiểm thử Sandbox (Giả lập thanh toán)

Để kiểm tra xem hệ thống có tự động nhận diện thanh toán và chuyển trang trên ứng dụng Flutter hay không:

1. Khởi động ứng dụng Flutter và tiến hành đặt sân.
2. Trên màn hình thanh toán, ứng dụng sẽ tự tạo một Booking mới và in mã giao dịch chuyển khoản trên màn hình (Ví dụ: `FLEXI8B9C123D`).
3. Lúc này, không cần quét mã chuyển tiền thật. Bạn mở Terminal hoặc công cụ gọi API (như Postman) và giả lập một webhook của ngân hàng gửi tới Edge Function bằng lệnh cURL sau:

   ```bash
   curl -X POST https://[PROJECT_ID].supabase.co/functions/v1/vietqr-webhook \
     -H "Content-Type: application/json" \
     -H "x-api-key: my_secret_token_123" \
     -d "{
       \"id\": 12345678,
       \"gateway\": \"MBBank\",
       \"transferType\": \"in\",
       \"transferAmount\": 150000.00,
       \"code\": \"FLEXI8B9C123D\",
       \"referenceCode\": \"FT2618029301293\",
       \"description\": \"FLEXI8B9C123D chuyen khoan dat san\"
     }"
   ```

   *Thay thế:*
   * `[PROJECT_ID]` thành ID dự án Supabase thực tế của bạn.
   * `my_secret_token_123` bằng token bạn tự đặt ở Bước 2.
   * `FLEXI8B9C123D` bằng mã chuyển khoản thực tế hiển thị trên app Flutter của bạn.
   * `150000.00` bằng đúng số tiền tổng hóa đơn đặt sân.

4. **Kiểm tra phản hồi**:
   * Response nhận về sẽ có dạng: `{"success":true,"message":"Payment processed successfully"}`.
   * Ứng dụng Flutter của bạn đang hiển thị mã QR sẽ nhận được tín hiệu realtime tức thì, tự động tắt màn hình chờ và điều hướng thẳng sang trang **Đặt lịch thành công** (`PaymentSuccessPage`).

---

## Bước 6: Giám sát và Vận hành (Production Best Practices)

1. **Kiểm tra Logs Edge Function**:
   Nếu có lỗi xảy ra hoặc người dùng báo đã chuyển tiền nhưng app không phản hồi, truy cập vào **Supabase Dashboard** -> **Edge Functions** -> Chọn **vietqr-webhook** -> Chọn tab **Logs** để kiểm tra dữ liệu webhook thực tế gửi đến ngân hàng và các cảnh báo lỗi.
2. **Quản lý Hóa đơn quá hạn**:
   Dự án đã thiết lập RPC `cancel_expired_booking` để dọn dẹp các booking quá thời gian giữ chỗ 5 phút nếu người dùng thoát ứng dụng hoặc không chuyển khoản. Bạn có thể thiết lập thêm công cụ cron-job (như GitHub Actions hoặc Scheduler trong Supabase Dashboard) để tự động gọi hàm này định kỳ.
