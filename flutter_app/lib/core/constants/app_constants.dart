class AppConstants {
  // API Configuration
    static const String authBaseUrl = 'http://localhost:8083/auth';
  static const String accountBaseUrl = 'http://localhost:8081';
  static const String transactionBaseUrl = 'http://localhost:8082';

  // Secure Storage Keys
  static const String jwtTokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String customerIdKey = 'customer_id';
  static const String cifNumberKey = 'cif_number';

  // App Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration tokenValidationTimeout = Duration(minutes: 5);

  // Transaction Limits
  static const double dailyTransferLimit = 1000000; // ₹10,00,000
  static const double singleTransferLimit = 100000; // ₹1,00,000

  // UI Constants
  static const double defaultPadding = 24.0;
  static const double defaultBorderRadius = 12.0;

  // Error Messages
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String authenticationFailedMessage =
      'Authentication failed. Please login again.';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registrationSuccessMessage =
      'Registration successful! Please login.';
  static const String transferSuccessMessage = 'Transfer completed successfully!';
  static const String accountCreatedSuccessMessage =
      'Account created successfully!';

  // HTTP Status Codes
  static const int httpStatusOk = 200;
  static const int httpStatusCreated = 201;
  static const int httpStatusBadRequest = 400;
  static const int httpStatusUnauthorized = 401;
  static const int httpStatusForbidden = 403;
  static const int httpStatusNotFound = 404;
  static const int httpStatusServerError = 500;
}
