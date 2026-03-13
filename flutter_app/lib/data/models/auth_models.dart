import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'userId')
  final int userId;
  
  @JsonKey(name: 'token')
  final String token;
  
  @JsonKey(name: 'expiresIn')
  final int? expiresIn;
  
  @JsonKey(name: 'message')
  final String? message;

  AuthResponse({
    required this.userId,
    required this.token,
    this.expiresIn,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class LoginRequest {
  @JsonKey(name: 'username')
  final String username;

  @JsonKey(name: 'password')
  final String password;

  LoginRequest({
    required this.username,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  @JsonKey(name: 'username')
  final String username;

  @JsonKey(name: 'password')
  final String password;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'firstName')
  final String firstName;

  @JsonKey(name: 'lastName')
  final String lastName;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class UserKycDTO {
  @JsonKey(name: 'userId')
  final int userId;

  @JsonKey(name: 'status')
  final String status; // PENDING, VERIFIED, REJECTED

  @JsonKey(name: 'approvedAt')
  final String? approvedAt;

  @JsonKey(name: 'verifiedBy')
  final String? verifiedBy;

  UserKycDTO({
    required this.userId,
    required this.status,
    this.approvedAt,
    this.verifiedBy,
  });

  factory UserKycDTO.fromJson(Map<String, dynamic> json) =>
      _$UserKycDTOFromJson(json);

  Map<String, dynamic> toJson() => _$UserKycDTOToJson(this);
}

@JsonSerializable()
class CustomerDTO {
  @JsonKey(name: 'customerId')
  final int customerId;

  @JsonKey(name: 'cifNumber')
  final String cifNumber;

  @JsonKey(name: 'userId')
  final int userId;

  @JsonKey(name: 'fullName')
  final String fullName;

  @JsonKey(name: 'kycStatus')
  final String kycStatus;

  @JsonKey(name: 'phoneNumber')
  final String? phoneNumber;

  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  CustomerDTO({
    required this.customerId,
    required this.cifNumber,
    required this.userId,
    required this.fullName,
    required this.kycStatus,
    this.phoneNumber,
    this.address,
    this.createdAt,
  });

  factory CustomerDTO.fromJson(Map<String, dynamic> json) =>
      _$CustomerDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDTOToJson(this);
}

@JsonSerializable()
class CreateCustomerRequest {
  @JsonKey(name: 'fullName')
  final String fullName;

  @JsonKey(name: 'phoneNumber')
  final String phoneNumber;

  @JsonKey(name: 'address')
  final String address;

  @JsonKey(name: 'dateOfBirth')
  final String dateOfBirth;

  CreateCustomerRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.dateOfBirth,
  });

  factory CreateCustomerRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCustomerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCustomerRequestToJson(this);
}
