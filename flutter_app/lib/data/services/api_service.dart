import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../models/auth_models.dart';
import '../models/account_models.dart';
import '../models/transaction_models.dart';

class ApiService {
  static const String authBaseUrl = 'http://localhost:8083/auth';
  static const String accountBaseUrl = 'http://localhost:8081';
  static const String transactionBaseUrl = 'http://localhost:8082';

  final Dio _authDio;
  final Dio _accountDio;
  final Dio _transactionDio;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();

  ApiService({
    FlutterSecureStorage? secureStorage,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _authDio = Dio(BaseOptions(
          baseUrl: authBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          contentType: 'application/json',
        )),
        _accountDio = Dio(BaseOptions(
          baseUrl: accountBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          contentType: 'application/json',
        )),
        _transactionDio = Dio(BaseOptions(
          baseUrl: transactionBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          contentType: 'application/json',
        )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Auth service interceptor
    _authDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logger.d('Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );

    // Account service interceptor
    _accountDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );

    // Transaction service interceptor
    _transactionDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Exception _buildAuthException(DioException error, String fallbackMessage) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return Exception(message.trim());
      }

      final messages = responseData.entries
          .where((entry) => entry.value is String)
          .map((entry) => (entry.value as String).trim())
          .where((message) => message.isNotEmpty)
          .toList();
      if (messages.isNotEmpty) {
        return Exception(messages.join('\n'));
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Unable to reach the server. Check that backend services are running.');
      default:
        return Exception(fallbackMessage);
    }
  }

  // ==================== AUTH ENDPOINTS ====================

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _authDio.post(
        '/api/auth/register',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      _logger.e('Register error: ${e.message}');
      throw _buildAuthException(e, 'Registration failed');
    }
  }

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _authDio.post(
        '/api/auth/login',
        data: request.toJson(),
      );
      final authResponse = AuthResponse.fromJson(response.data);
      
      // Save token to secure storage
      await _secureStorage.write(
        key: 'jwt_token',
        value: authResponse.token,
      );
      
      return authResponse;
    } on DioException catch (e) {
      _logger.e('Login error: ${e.message}');
      throw _buildAuthException(e, 'Invalid username or password');
    }
  }

  Future<bool> validateToken() async {
    try {
      final response = await _authDio.get('/api/auth/validate');
      return response.data['valid'] == true;
    } on DioException catch (e) {
      _logger.e('Token validation error: ${e.message}');
      return false;
    }
  }

  Future<UserKycDTO> getUserKycStatus(int userId) async {
    try {
      final response = await _authDio.get('/api/auth/user/$userId/kyc-status');
      return UserKycDTO.fromJson(response.data);
    } on DioException catch (e) {
      _logger.e('Get KYC status error: ${e.message}');
      rethrow;
    }
  }

  // ==================== CUSTOMER ENDPOINTS ====================

  Future<List<CustomerDTO>> getAllCustomers() async {
    try {
      final response = await _authDio.get('/api/customers');
      final List<dynamic> data = response.data;
      return data.map((e) => CustomerDTO.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _logger.e('Get all customers error: ${e.message}');
      rethrow;
    }
  }

  Future<CustomerDTO> createCustomer(
    int userId,
    CreateCustomerRequest request,
  ) async {
    try {
      final response = await _authDio.post(
        '/api/customers',
        data: request.toJson(),
        queryParameters: {'userId': userId},
      );
      return CustomerDTO.fromJson(response.data);
    } on DioException catch (e) {
      _logger.e('Create customer error: ${e.message}');
      rethrow;
    }
  }

  Future<CustomerDTO> getCustomerByUserId(int userId) async {
    try {
      final response = await _authDio.get('/api/customers/user/$userId');
      return CustomerDTO.fromJson(response.data);
    } on DioException catch (e) {
      _logger.e('Get customer by user ID error: ${e.message}');
      rethrow;
    }
  }

  Future<bool> isCustomerActive(int userId) async {
    try {
      final response = await _authDio.get('/api/customers/user/$userId/active');
      return response.data['active'] == true;
    } on DioException catch (e) {
      _logger.e('Check customer active error: ${e.message}');
      return false;
    }
  }

  // ==================== ACCOUNT ENDPOINTS ====================

  Future<AccountDTO> getAccount(String accountNumber) async {
    try {
      final response = await _accountDio.get('/api/accounts/$accountNumber');
      return AccountDTO.fromJson(response.data);
    } on DioException catch (e) {
      _logger.e('Get account error: ${e.message}');
      rethrow;
    }
  }

  Future<List<AccountDTO>> getAllAccounts() async {
    try {
      final response = await _accountDio.get('/api/accounts');
      final List<dynamic> data = response.data;
      return data.map((e) => AccountDTO.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _logger.e('Get all accounts error: ${e.message}');
      rethrow;
    }
  }

  Future<List<AccountDTO>> getAccountsByCustomer(int customerId) async {
    try {
      final response = await _accountDio.get(
        '/api/accounts/customer/$customerId',
      );
      final List<dynamic> data = response.data;
      return data.map((e) => AccountDTO.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _logger.e('Get accounts by customer error: ${e.message}');
      rethrow;
    }
  }

  Future<AccountDTO> createAccount(CreateAccountRequest request) async {
    try {
      final response = await _accountDio.post(
        '/api/accounts',
        data: request.toJson(),
      );
      return AccountDTO.fromJson(response.data);
    } on DioException catch (e) {
      _logger.e('Create account error: ${e.message}');
      rethrow;
    }
  }

  Future<String> debitAccount(
    String accountNumber,
    DebitRequestDTO request,
  ) async {
    try {
      final response = await _accountDio.put(
        '/api/accounts/$accountNumber/debit',
        data: request.toJson(),
      );
      return response.data['message'] ?? 'Debit successful';
    } on DioException catch (e) {
      _logger.e('Debit account error: ${e.message}');
      rethrow;
    }
  }

  Future<String> creditAccount(
    String accountNumber,
    CreditRequestDTO request,
  ) async {
    try {
      final response = await _accountDio.put(
        '/api/accounts/$accountNumber/credit',
        data: request.toJson(),
      );
      return response.data['message'] ?? 'Credit successful';
    } on DioException catch (e) {
      _logger.e('Credit account error: ${e.message}');
      rethrow;
    }
  }

  // ==================== TRANSACTION ENDPOINTS ====================

  Future<String> transferFunds(TransferRequestDTO request) async {
    try {
      final response = await _transactionDio.post(
        '/api/transactions/transfer',
        data: request.toJson(),
      );
      return response.data['message'] ?? 'Transfer successful';
    } on DioException catch (e) {
      _logger.e('Transfer funds error: ${e.message}');
      rethrow;
    }
  }

  Future<List<TransactionDTO>> getTransactionHistory(String accountNumber) async {
    try {
      final response = await _transactionDio.get(
        '/api/transactions/account/$accountNumber',
      );
      final List<dynamic> data = response.data;
      return data.map((e) => TransactionDTO.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _logger.e('Get transaction history error: ${e.message}');
      rethrow;
    }
  }

  // ==================== HEALTH CHECKS ====================

  Future<bool> checkAuthServiceHealth() async {
    try {
      await _authDio.get('/api/auth/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkAccountServiceHealth() async {
    try {
      await _accountDio.get('/api/accounts/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkTransactionServiceHealth() async {
    try {
      await _transactionDio.get('/health');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==================== LOGOUT ====================

  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
  }
}
