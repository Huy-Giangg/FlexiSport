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
}
