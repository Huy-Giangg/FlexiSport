# FlexiSport 🏅

**FlexiSport** là một ứng dụng di động hiện đại được phát triển trên nền tảng Flutter, giúp kết nối người chơi thể thao với các khu phức hợp, sân tập (bóng đá, cầu lông, tennis, bóng rổ,...). Ứng dụng cung cấp giải pháp đặt sân trực tuyến thời gian thực nhanh chóng, tiện lợi và trực quan.

Dự án được xây dựng theo kiến trúc hướng tính năng (Feature-First) gọn gàng, có tính mở rộng cao và dễ bảo trì.

---

## 🚀 Các tính năng nổi bật

### 1. Xác thực người dùng (Authentication)
*   Đăng ký và đăng nhập tài khoản bằng Email & Mật khẩu.
*   Hỗ trợ đăng nhập nhanh bằng tài khoản Google (Google Sign-In).
*   Khôi phục mật khẩu thông qua Email gửi từ Firebase.

### 2. Tìm kiếm & Bản đồ (Sports Complex Map)
*   Tích hợp bản đồ trực quan (Google Maps) hiển thị danh sách các cụm sân thể thao quanh vị trí người dùng.
*   Hiển thị thông tin nhanh của sân (ảnh, khoảng cách, loại hình thể thao) ngay trên bản đồ.
*   Lọc sân theo các bộ môn thể thao khác nhau.

### 3. Xem chi tiết khu phức hợp thể thao (Sports Complex Details)
*   Thư viện hình ảnh thực tế của cụm sân.
*   Danh sách dịch vụ đi kèm (bãi đỗ xe, nước uống, thuê vợt/áo bib, phòng tắm,...).
*   Quy định & Nội quy hoạt động của sân.
*   Xem và gửi đánh giá từ những người chơi khác.

### 4. Đặt sân thời gian thực (Real-time Booking System)
*   Chọn ngày, khung giờ chơi trực quan dạng lưới (Grid).
*   Cơ chế **khóa giờ tạm thời (Slot Hold/Lock)** thời gian thực tránh tình trạng nhiều người đặt trùng giờ.
*   Đồng bộ dữ liệu đặt sân tức thì (Real-time sync) qua Supabase.

---

## 🛠️ Công nghệ sử dụng (Tech Stack)

*   **Framework chính:** [Flutter](https://flutter.dev/) (Dart)
*   **Quản lý trạng thái (State Management):** `Provider`
*   **Điều hướng (Routing):** `GoRouter`
*   **Cơ sở dữ liệu & Đồng bộ thời gian thực:** [Supabase](https://supabase.com/) (Dùng cho thông tin sân, đặt sân và khóa giờ tạm thời)
*   **Xác thực người dùng:** [Firebase Authentication](https://firebase.google.com/)
*   **Bản đồ hiển thị:** [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
*   **Giao thức kết nối HTTP:** `Dio`

---

## 📂 Cấu trúc thư mục dự án

Thư mục `lib/` được thiết kế theo cấu trúc Feature-First kết hợp Clean Architecture thu gọn:

```text
lib/
├── core/                   # Cấu hình chung cho toàn bộ dự án
│   ├── config/             # Cấu hình tệp môi trường / API Keys cục bộ
│   ├── router/             # Định tuyến GoRouter
│   └── theme/              # Định nghĩa màu sắc, phông chữ (App Theme)
├── features/               # Các chức năng chính của ứng dụng
│   ├── auth/               # Tính năng Đăng nhập, Đăng ký, Google Sign-in
│   ├── booking/            # Tính năng Đặt sân & Khóa slot thời gian thực
│   ├── home/               # Trang chủ & Bản đồ Google Maps hiển thị sân
│   └── sports_complex/     # Chi tiết cụm sân, hình ảnh, đánh giá, dịch vụ
└── main.dart               # Tệp khởi chạy ứng dụng
```

---

## ⚙️ Hướng dẫn cài đặt & Thiết lập cục bộ (Local Setup)

Do các thông tin cấu hình nhạy cảm đã được ẩn khỏi GitHub để bảo mật, bạn cần thực hiện các bước sau để chạy dự án dưới local:

### 1. Cấu hình Supabase Keys
*   Tạo file `app_config.dart` tại thư mục `lib/core/config/` dựa trên file mẫu `app_config.dart.example`.
*   Điền URL và Anon Key dự án Supabase của bạn:
    ```dart
    class AppConfig {
      static const String supabaseUrl = 'YOUR_SUPABASE_URL';
      static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
    }
    ```

### 2. Cấu hình Firebase
*   Tạo dự án mới trên Firebase Console.
*   Tải file cấu hình và đặt đúng vị trí:
    *   **Android:** Đặt tệp `google-services.json` vào thư mục `android/app/`.
    *   **iOS:** Đặt tệp `GoogleService-Info.plist` vào thư mục `ios/Runner/`.

### 3. Cấu hình Google Maps API Key
*   Mở tệp `android/local.properties` và thêm dòng sau:
    ```properties
    maps.api.key=YOUR_GOOGLE_MAPS_API_KEY_HERE
    ```

### 4. Khởi chạy ứng dụng
Chạy các lệnh sau trong terminal để tải thư viện và chạy ứng dụng:
```bash
flutter pub get
flutter run
```

---

## 📄 Giấy phép (License)
Dự án được bảo lưu quyền sở hữu bởi nhóm tác giả đồ án tốt nghiệp FlexiSport. Vui lòng không sao chép khi chưa được sự đồng ý.
