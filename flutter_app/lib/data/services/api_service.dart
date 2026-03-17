import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _jwtTokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _roleKey = 'role';
  static const String _kycStatusKey = 'kyc_status';
  static const String _mpinKeyPrefix = 'mpin_user_';
  static const String _beneficiariesKeyPrefix = 'beneficiaries_user_';
  static final Map<String, String> _memorySession = <String, String>{};
  static SharedPreferences? _prefs;

  int? _sessionUserId;
  String? _sessionUsername;
  String? _sessionRole;
  String? _sessionKycStatus;

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

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String?> _readSessionValue(String key) async {
    // 1. In-memory (fastest, works within the same app session)
    final inMemory = _memorySession[key];
    if (inMemory != null && inMemory.trim().isNotEmpty) {
      return inMemory;
    }

    // 2. FlutterSecureStorage (encrypted, may be unavailable on Linux without keyring)
    try {
      final stored = await _secureStorage.read(key: key);
      if (stored != null && stored.trim().isNotEmpty) {
        _memorySession[key] = stored;
        return stored;
      }
    } catch (e) {
      _logger.w('Secure storage read failed for $key: $e');
    }

    // 3. SharedPreferences (file-based, always works on Linux desktop)
    try {
      final prefs = await _getPrefs();
      final stored = prefs.getString('_siab_$key');
      if (stored != null && stored.trim().isNotEmpty) {
        _memorySession[key] = stored;
        return stored;
      }
    } catch (e) {
      _logger.w('SharedPreferences read failed for $key: $e');
    }

    return null;
  }

  Future<void> _writeSessionValue(String key, String? value) async {
    if (value == null || value.trim().isEmpty) {
      _memorySession.remove(key);
      try {
        await _secureStorage.delete(key: key);
      } catch (e) {
        _logger.w('Secure storage delete failed for $key: $e');
      }
      try {
        final prefs = await _getPrefs();
        await prefs.remove('_siab_$key');
      } catch (e) {
        _logger.w('SharedPreferences delete failed for $key: $e');
      }
      return;
    }

    _memorySession[key] = value;
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      _logger.w('Secure storage write failed for $key: $e');
    }
    try {
      final prefs = await _getPrefs();
      await prefs.setString('_siab_$key', value);
    } catch (e) {
      _logger.w('SharedPreferences write failed for $key: $e');
    }
  }

  void _setupInterceptors() {
    // Auth service interceptor
    _authDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _readSessionValue(_jwtTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logger.d('Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
              'Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          if (_isExpectedMissingCustomerProfile(error)) {
            _logger.d(
              'No customer profile yet: '
              '${error.requestOptions.method} ${error.requestOptions.path}',
            );
          } else {
            _logger.e('Error: ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );

    // Account service interceptor
    _accountDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _readSessionValue(_jwtTokenKey);
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
          final token = await _readSessionValue(_jwtTokenKey);
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
        return Exception(
            'Unable to reach the server. Check that backend services are running.');
      default:
        return Exception(fallbackMessage);
    }
  }

  bool _isExpectedMissingCustomerProfile(DioException error) {
    final statusCode = error.response?.statusCode;
    final path = error.requestOptions.path;
    final uriPath = error.requestOptions.uri.path;
    const expectedSegment = '/api/customers/user/';

    return statusCode == 404 &&
        (path.startsWith(expectedSegment) ||
            path.contains(expectedSegment) ||
            uriPath.startsWith(expectedSegment) ||
            uriPath.contains(expectedSegment));
  }

  String _extractMessage(dynamic responseData, String fallback) {
    if (responseData is String && responseData.trim().isNotEmpty) {
      return responseData.trim();
    }
    if (responseData is Map) {
      final message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return fallback;
  }

  Future<void> _persistSession(
    AuthResponse authResponse, {
    required String fallbackUsername,
  }) async {
    // Keep an in-memory session for immediate reads after auth.
    _sessionUserId = authResponse.userId;
    _sessionUsername = (authResponse.username ?? fallbackUsername).trim();
    _sessionRole = (authResponse.role ?? 'USER').toUpperCase();
    _sessionKycStatus = (authResponse.kycStatus ?? 'PENDING').toUpperCase();

    await _writeSessionValue(_jwtTokenKey, authResponse.token);
    await _writeSessionValue(_userIdKey, authResponse.userId.toString());
    await _writeSessionValue(_usernameKey, _sessionUsername);
    await _writeSessionValue(_roleKey, _sessionRole);
    await _writeSessionValue(_kycStatusKey, _sessionKycStatus);
  }

  // ==================== AUTH ENDPOINTS ====================

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _authDio.post(
        '/api/auth/register',
        data: request.toJson(),
      );
      final authResponse = AuthResponse.fromJson(response.data);
      await _persistSession(
        authResponse,
        fallbackUsername: request.username,
      );
      return authResponse;
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
      await _persistSession(
        authResponse,
        fallbackUsername: request.username,
      );

      return authResponse;
    } on DioException catch (e) {
      _logger.e('Login error: ${e.message}');
      throw _buildAuthException(e, 'Invalid username or password');
    }
  }

  Future<bool> validateToken() async {
    // JWT validation is intentionally disabled for desktop session stability.
    return true;
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
      return data
          .map((e) => CustomerDTO.fromJson(e as Map<String, dynamic>))
          .toList();
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
      if (_isExpectedMissingCustomerProfile(e)) {
        _logger.d('Customer profile not found yet for userId=$userId');
      } else {
        _logger.e('Get customer by user ID error: ${e.message}');
      }
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

  Future<CustomerDTO> updateCustomerKycStatus({
    required String cifNumber,
    required UpdateKycStatusRequest request,
    String? adminUsername,
  }) async {
    try {
      final response = await _authDio.put(
        '/api/customers/cif/$cifNumber/kyc',
        data: request.toJson(),
        queryParameters: {
          if (adminUsername != null && adminUsername.trim().isNotEmpty)
            'adminUsername': adminUsername.trim(),
        },
      );
      return CustomerDTO.fromJson(response.data);
    } on DioException catch (e) {
      _logger.e('Update customer KYC status error: ${e.message}');
      rethrow;
    }
  }

  Future<int?> getCurrentUserId() async {
    if (_sessionUserId != null) {
      return _sessionUserId;
    }
    final raw = await _readSessionValue(_userIdKey);
    final parsed = int.tryParse(raw ?? '');
    if (parsed != null) {
      _sessionUserId = parsed;
      return parsed;
    }

    // Admin fallback: allow admin-only app sections even when JWT cannot be
    // revalidated on desktop restarts. -1 is reserved as a virtual admin id.
    final role = await getCurrentRole();
    if ((role ?? '').toUpperCase().contains('ADMIN')) {
      _sessionUserId = -1;
      return _sessionUserId;
    }

    return null;
  }

  Future<String?> getCurrentUsername() async {
    if (_sessionUsername != null && _sessionUsername!.isNotEmpty) {
      return _sessionUsername;
    }
    final value = await _readSessionValue(_usernameKey);
    if (value != null && value.trim().isNotEmpty) {
      _sessionUsername = value.trim();
      return _sessionUsername;
    }

    return null;
  }

  Future<String?> getCurrentRole() async {
    if (_sessionRole != null && _sessionRole!.isNotEmpty) {
      return _sessionRole;
    }
    final value = await _readSessionValue(_roleKey);
    if (value != null && value.trim().isNotEmpty) {
      _sessionRole = value.toUpperCase();
      return _sessionRole;
    }

    return null;
  }

  Future<String?> getCachedKycStatus() async {
    if (_sessionKycStatus != null && _sessionKycStatus!.isNotEmpty) {
      return _sessionKycStatus;
    }
    final value = await _readSessionValue(_kycStatusKey);
    _sessionKycStatus = value?.toUpperCase();
    return _sessionKycStatus;
  }

  Future<void> setCachedKycStatus(String status) async {
    _sessionKycStatus = status.toUpperCase();
    await _writeSessionValue(_kycStatusKey, status);
  }

  String _mpinKeyForUser(int userId) => '$_mpinKeyPrefix$userId';
  String _beneficiariesKeyForUser(int userId) =>
      '$_beneficiariesKeyPrefix$userId';

  String _hashMpin(String mpin) => sha256.convert(utf8.encode(mpin)).toString();

  Future<void> setMpinForUser({
    required int userId,
    required String mpin,
  }) async {
    await _writeSessionValue(_mpinKeyForUser(userId), _hashMpin(mpin));
  }

  Future<bool> hasMpinForCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) {
      return false;
    }
    final value = await _readSessionValue(_mpinKeyForUser(userId));
    return value != null && value.trim().isNotEmpty;
  }

  Future<bool> verifyMpinForCurrentUser(String mpin) async {
    final userId = await getCurrentUserId();
    if (userId == null) {
      return false;
    }
    final stored = await _readSessionValue(_mpinKeyForUser(userId));
    if (stored == null || stored.trim().isEmpty) {
      return false;
    }
    return stored == _hashMpin(mpin);
  }

  Future<List<String>> getSavedBeneficiariesForCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null || userId <= 0) {
      return const <String>[];
    }

    final raw = await _readSessionValue(_beneficiariesKeyForUser(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <String>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <String>[];
      }

      return decoded
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return const <String>[];
    }
  }

  Future<void> saveBeneficiaryForCurrentUser(String accountNumber) async {
    final userId = await getCurrentUserId();
    final normalized = accountNumber.trim();

    if (userId == null || userId <= 0 || normalized.isEmpty) {
      return;
    }

    final existing = await getSavedBeneficiariesForCurrentUser();
    final updated = <String>[];

    // Keep most recent first, no duplicates, top 8 entries.
    updated.add(normalized);
    for (final item in existing) {
      if (item != normalized) {
        updated.add(item);
      }
      if (updated.length >= 8) {
        break;
      }
    }

    await _writeSessionValue(
      _beneficiariesKeyForUser(userId),
      jsonEncode(updated),
    );
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
      return data
          .map((e) => AccountDTO.fromJson(e as Map<String, dynamic>))
          .toList();
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
      return data
          .map((e) => AccountDTO.fromJson(e as Map<String, dynamic>))
          .toList();
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
      return _extractMessage(response.data, 'Debit successful');
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
      return _extractMessage(response.data, 'Credit successful');
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
      return _extractMessage(response.data, 'Transfer successful');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final responseBody = e.response?.data;
      _logger.e(
        'Transfer funds error: ${e.message}. '
        'statusCode=$status, response=$responseBody, '
        'request=${request.toJson()}',
      );
      rethrow;
    }
  }

  Future<List<TransactionDTO>> getTransactionHistory(
      String accountNumber) async {
    try {
      final response = await _transactionDio.get(
        '/api/transactions/account/$accountNumber',
      );
      final List<dynamic> data = response.data;
      final transactions = <TransactionDTO>[];
      for (final item in data) {
        if (item is! Map) {
          continue;
        }
        try {
          final normalized = item.map(
            (key, value) => MapEntry('$key', value),
          );
          transactions.add(TransactionDTO.fromJson(normalized));
        } catch (e) {
          _logger.w('Skipped malformed transaction item: $e');
        }
      }
      return transactions;
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
    _sessionUserId = null;
    _sessionUsername = null;
    _sessionRole = null;
    _sessionKycStatus = null;
    _memorySession.clear();

    // Clear all secure storage keys
    for (final key in [
      _jwtTokenKey,
      _userIdKey,
      _usernameKey,
      _roleKey,
      _kycStatusKey,
    ]) {
      try {
        await _secureStorage.delete(key: key);
      } catch (_) {}
    }

    // Clear all SharedPreferences session keys
    try {
      final prefs = await _getPrefs();
      final allKeys =
          prefs.getKeys().where((k) => k.startsWith('_siab_')).toList();
      for (final k in allKeys) {
        await prefs.remove(k);
      }
    } catch (e) {
      _logger.w('SharedPreferences clear failed during logout: $e');
    }
  }
}
