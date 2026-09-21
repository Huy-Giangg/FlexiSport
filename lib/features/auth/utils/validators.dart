class MyValidators {
  // Validator cho Email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập Email';
    }

    // Sử dụng Regex để kiểm tra định dạng email chuẩn
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(value)) {
      return 'Email không đúng định dạng (ví dụ: abc@gmail.com)';
    }

    return null; // Trả về null nếu hợp lệ
  }

  // Validator cho Password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
    return 'Vui lòng nhập mật khẩu';
  }

  // 1. Kiểm tra độ dài tối thiểu
  if (value.length < 8) {
    return 'Mật khẩu phải có ít nhất 8 ký tự';
  }

  // 2. Kiểm tra ít nhất 1 chữ cái viết hoa
  if (!value.contains(RegExp(r'[A-Z]'))) {
    return 'Mật khẩu phải chứa ít nhất 1 chữ cái viết hoa';
  }

  // 3. Kiểm tra ít nhất 1 chữ cái viết thường
  if (!value.contains(RegExp(r'[a-z]'))) {
    return 'Mật khẩu phải chứa ít nhất 1 chữ cái viết thường';
  }

  // 4. Kiểm tra ít nhất 1 chữ số
  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'Mật khẩu phải chứa ít nhất 1 chữ số';
  }

  // 5. Kiểm tra ít nhất 1 ký tự đặc biệt
  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_]'))) {
    return 'Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt';
  }
    return null;
  }

  static String? validatePasswordConfirm(String? value, String password) {
    if (value == null || value.isEmpty) {
    return 'Vui lòng nhập mật khẩu';
  }

  // 1. Kiểm tra độ dài tối thiểu
  if (value.length < 8) {
    return 'Mật khẩu phải có ít nhất 8 ký tự';
  }

  // 2. Kiểm tra ít nhất 1 chữ cái viết hoa
  if (!value.contains(RegExp(r'[A-Z]'))) {
    return 'Mật khẩu phải chứa ít nhất 1 chữ cái viết hoa';
  }

  // 3. Kiểm tra ít nhất 1 chữ cái viết thường
  if (!value.contains(RegExp(r'[a-z]'))) {
    return 'Mật khẩu phải chứa ít nhất 1 chữ cái viết thường';
  }

  // 4. Kiểm tra ít nhất 1 chữ số
  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'Mật khẩu phải chứa ít nhất 1 chữ số';
  }

  // 5. Kiểm tra ít nhất 1 ký tự đặc biệt
  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_]'))) {
    return 'Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt';
  }

    if (value != password) {
      return 'Mật khẩu không khớp';
    }

    return null;
  }

  static String? validateFullName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Vui lòng nhập họ và tên';
  }

  // Loại bỏ khoảng trắng thừa ở đầu và cuối
  final name = value.trim();

  // 1. Kiểm tra độ dài (Tên người thường từ 2 từ trở lên và ít nhất 2 ký tự)
  if (name.length < 2) {
    return 'Tên quá ngắn';
  }
  
  if (!name.contains(' ')) {
    return 'Vui lòng nhập đầy đủ cả họ và tên';
  }

  // 2. Regex kiểm tra: Chỉ chứa chữ cái và khoảng trắng
  // Hỗ trợ đầy đủ tiếng Việt có dấu
  final nameRegExp = RegExp(
    r"^[a-zA-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠàáâãèéêìíòóôõùúăđĩũơƯĂẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỀỂưăạảấầẩẫậắằẳẵặẹẻẽềềểỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪỬỮỰỲỴÝỶỸửữựỳỵýỷỹ\s]+$"
  );

  if (!nameRegExp.hasMatch(name)) {
    return 'Họ tên chỉ được chứa chữ cái, không bao gồm số hay ký tự đặc biệt';
  }

  return null;
}

  // Validator cho Số điện thoại Việt Nam
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final phone = value.trim();
    
    // Regex cho SĐT Việt Nam: bắt đầu bằng 03, 05, 07, 08, 09 và theo sau bởi 8 chữ số
    // Hoặc 9 chữ số nếu người dùng bỏ số 0 ở đầu do có mã quốc gia (+84)
    final phoneRegExp = RegExp(r'^(0[35789]|3[5789])[0-9]{8}$');
    if (!phoneRegExp.hasMatch(phone)) {
      return 'Số điện thoại không hợp lệ (ví dụ: 0987654321 hoặc 987654321)';
    }
    return null;
  }

  // Validator cho Chiều cao (cm) - Không bắt buộc nhưng nếu nhập thì phải hợp lệ
  static String? validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Không bắt buộc
    }
    final height = double.tryParse(value.trim());
    if (height == null) {
      return 'Số không hợp lệ';
    }
    if (height < 50 || height > 250) {
      return 'Từ 50 đến 250 cm';
    }
    return null;
  }

  // Validator cho Cân nặng (kg) - Không bắt buộc nhưng nếu nhập thì phải hợp lệ
  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Không bắt buộc
    }
    final weight = double.tryParse(value.trim());
    if (weight == null) {
      return 'Số không hợp lệ';
    }
    if (weight < 20 || weight > 200) {
      return 'Từ 20 đến 200 kg';
    }
    return null;
  }

  // Helper format định dạng tiền tệ VND (ví dụ: 100000 -> "100.000")
  static String formatCurrency(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  // Validator cho Giá tiền / Chi phí (VND)
  static String? validatePrice(
    String? value, {
    double max = 10000000,
    double? maxAllowed,
    String? maxAllowedMessage,
    bool allowZero = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return allowZero
          ? 'Vui lòng nhập số tiền (hoặc ghi 0 nếu miễn phí)'
          : 'Vui lòng nhập số tiền';
    }

    final cleanValue = value.replaceAll('.', '').replaceAll(',', '').trim();
    final parsed = double.tryParse(cleanValue);

    if (parsed == null) {
      return 'Vui lòng nhập số tiền hợp lệ';
    }

    if (parsed < 0) {
      return 'Chi phí không được là số âm';
    }

    if (!allowZero && parsed == 0) {
      return 'Số tiền phải lớn hơn 0';
    }

    if (parsed > 0 && parsed < 1000) {
      return 'Chi phí tối thiểu từ 1.000đ (hoặc 0 nếu miễn phí)';
    }

    if (maxAllowed != null && parsed > maxAllowed) {
      return maxAllowedMessage ??
          'Số tiền không được vượt quá ${formatCurrency(maxAllowed)}đ';
    }

    if (parsed > max) {
      return 'Số tiền không được vượt quá ${formatCurrency(max)}đ';
    }

    return null;
  }
}

