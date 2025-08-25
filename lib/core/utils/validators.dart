class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    
    if (value.length < 8) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Mật khẩu phải có ít nhất 1 chữ hoa';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Mật khẩu phải có ít nhất 1 chữ thường';
    }
    
    // Check for at least one digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Mật khẩu phải có ít nhất 1 số';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Xác nhận mật khẩu không được để trống';
    }
    
    if (value != password) {
      return 'Mật khẩu xác nhận không khớp';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tên không được để trống';
    }
    
    if (value.length < 2) {
      return 'Tên phải có ít nhất 2 ký tự';
    }
    
    if (value.length > 50) {
      return 'Tên không được quá 50 ký tự';
    }
    
    // Check for valid characters (letters, spaces, Vietnamese characters)
    if (!RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(value)) {
      return 'Tên chỉ được chứa chữ cái và khoảng trắng';
    }
    
    return null;
  }

  // Device name validation
  static String? validateDeviceName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tên thiết bị không được để trống';
    }
    
    if (value.length < 2) {
      return 'Tên thiết bị phải có ít nhất 2 ký tự';
    }
    
    if (value.length > 50) {
      return 'Tên thiết bị không được quá 50 ký tự';
    }
    
    return null;
  }

  // Location validation
  static String? validateLocation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vị trí không được để trống';
    }
    
    if (value.length < 2) {
      return 'Vị trí phải có ít nhất 2 ký tự';
    }
    
    if (value.length > 100) {
      return 'Vị trí không được quá 100 ký tự';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone number is optional
    }
    
    // Vietnamese phone number pattern
    final phoneRegex = RegExp(r'^(\+84|84|0)[1-9][0-9]{8}$');
    
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Số điện thoại không hợp lệ';
    }
    
    return null;
  }

  // Temperature threshold validation
  static String? validateTemperature(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nhiệt độ không được để trống';
    }
    
    final temperature = double.tryParse(value);
    if (temperature == null) {
      return 'Nhiệt độ phải là số';
    }
    
    if (temperature < -50 || temperature > 100) {
      return 'Nhiệt độ phải trong khoảng -50°C đến 100°C';
    }
    
    return null;
  }

  // Humidity threshold validation
  static String? validateHumidity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Độ ẩm không được để trống';
    }
    
    final humidity = double.tryParse(value);
    if (humidity == null) {
      return 'Độ ẩm phải là số';
    }
    
    if (humidity < 0 || humidity > 100) {
      return 'Độ ẩm phải trong khoảng 0% đến 100%';
    }
    
    return null;
  }

  // Device ID validation
  static String? validateDeviceId(String? value) {
    if (value == null || value.isEmpty) {
      return 'ID thiết bị không được để trống';
    }
    
    if (value.length < 8) {
      return 'ID thiết bị phải có ít nhất 8 ký tự';
    }
    
    // Check for alphanumeric characters only
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return 'ID thiết bị chỉ được chứa chữ cái và số';
    }
    
    return null;
  }

  // MQTT broker validation
  static String? validateMqttBroker(String? value) {
    if (value == null || value.isEmpty) {
      return 'MQTT broker không được để trống';
    }
    
    // Basic hostname/IP validation
    final hostRegex = RegExp(
      r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$',
    );
    
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    
    if (!hostRegex.hasMatch(value) && !ipRegex.hasMatch(value)) {
      return 'MQTT broker không hợp lệ';
    }
    
    return null;
  }

  // Port validation
  static String? validatePort(String? value) {
    if (value == null || value.isEmpty) {
      return 'Port không được để trống';
    }
    
    final port = int.tryParse(value);
    if (port == null) {
      return 'Port phải là số';
    }
    
    if (port < 1 || port > 65535) {
      return 'Port phải trong khoảng 1-65535';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL không được để trống';
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&=]*)$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'URL không hợp lệ';
    }
    
    return null;
  }
}
