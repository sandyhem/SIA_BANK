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

  @JsonKey(name: 'username')
  final String? username;

  @JsonKey(name: 'role')
  final String? role;

  @JsonKey(name: 'kycStatus')
  final String? kycStatus;

  AuthResponse({
    required this.userId,
    required this.token,
    this.expiresIn,
    this.message,
    this.username,
    this.role,
    this.kycStatus,
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

  @JsonKey(name: 'kycStatus')
  final String status; // PENDING, UNDER_REVIEW, VERIFIED, REJECTED

  @JsonKey(name: 'kycVerifiedAt')
  final String? approvedAt;

  @JsonKey(name: 'kycVerifiedBy')
  final String? verifiedBy;

  @JsonKey(name: 'username')
  final String? username;

  @JsonKey(name: 'customerId')
  final String? customerId;

  UserKycDTO({
    required this.userId,
    required this.status,
    this.approvedAt,
    this.verifiedBy,
    this.username,
    this.customerId,
  });

  factory UserKycDTO.fromJson(Map<String, dynamic> json) {
    final dynamic userIdValue = json['userId'];
    return UserKycDTO(
      userId: userIdValue is num
          ? userIdValue.toInt()
          : int.tryParse(userIdValue?.toString() ?? '') ?? 0,
      status: (json['kycStatus'] ?? json['status'] ?? 'PENDING').toString(),
      approvedAt: (json['kycVerifiedAt'] ?? json['approvedAt'])?.toString(),
      verifiedBy: (json['kycVerifiedBy'] ?? json['verifiedBy'])?.toString(),
      username: json['username']?.toString(),
      customerId: json['customerId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$UserKycDTOToJson(this);
}

@JsonSerializable()
class CustomerDTO {
  final int customerId;

  @JsonKey(name: 'cifNumber')
  final String cifNumber;

  @JsonKey(name: 'userId')
  final int userId;

  @JsonKey(name: 'fullName')
  final String fullName;

  @JsonKey(name: 'kycStatus')
  final String kycStatus;

  @JsonKey(name: 'phone')
  final String? phoneNumber;

  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'createdAt')
  final String? createdAt;

  @JsonKey(name: 'customerStatus')
  final String? customerStatus;

  @JsonKey(name: 'kycVerifiedAt')
  final String? kycVerifiedAt;

  @JsonKey(name: 'kycVerifiedBy')
  final String? kycVerifiedBy;

  @JsonKey(name: 'panNumber')
  final String? panNumber;

  @JsonKey(name: 'aadhaarNumber')
  final String? aadhaarNumber;

  CustomerDTO({
    required this.customerId,
    required this.cifNumber,
    required this.userId,
    required this.fullName,
    required this.kycStatus,
    this.phoneNumber,
    this.address,
    this.createdAt,
    this.customerStatus,
    this.kycVerifiedAt,
    this.kycVerifiedBy,
    this.panNumber,
    this.aadhaarNumber,
  });

  factory CustomerDTO.fromJson(Map<String, dynamic> json) {
    final dynamic customerIdValue = json['customerId'] ?? json['id'];
    final dynamic userIdValue = json['userId'];
    return CustomerDTO(
      customerId: customerIdValue is num
          ? customerIdValue.toInt()
          : int.tryParse(customerIdValue?.toString() ?? '') ?? 0,
      cifNumber: (json['cifNumber'] ?? '').toString(),
      userId: userIdValue is num
          ? userIdValue.toInt()
          : int.tryParse(userIdValue?.toString() ?? '') ?? 0,
      fullName: (json['fullName'] ?? '').toString(),
      kycStatus: (json['kycStatus'] ?? 'PENDING').toString(),
      phoneNumber: (json['phone'] ?? json['phoneNumber'])?.toString(),
      address: json['address']?.toString(),
      createdAt: (json['createdAt'] ?? json['updatedAt'])?.toString(),
      customerStatus: json['customerStatus']?.toString(),
      kycVerifiedAt: json['kycVerifiedAt']?.toString(),
      kycVerifiedBy: json['kycVerifiedBy']?.toString(),
      panNumber: json['panNumber']?.toString(),
      aadhaarNumber: json['aadhaarNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => _$CustomerDTOToJson(this);
}

@JsonSerializable()
class CreateCustomerRequest {
  @JsonKey(name: 'fullName')
  final String fullName;

  @JsonKey(name: 'phone')
  final String phoneNumber;

  @JsonKey(name: 'address')
  final String address;

  @JsonKey(name: 'city')
  final String? city;

  @JsonKey(name: 'state')
  final String? state;

  @JsonKey(name: 'postalCode')
  final String? postalCode;

  @JsonKey(name: 'country')
  final String? country;

  @JsonKey(name: 'dateOfBirth')
  final String dateOfBirth;

  @JsonKey(name: 'panNumber')
  final String panNumber;

  @JsonKey(name: 'aadhaarNumber')
  final String aadhaarNumber;

  CreateCustomerRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    required this.dateOfBirth,
    required this.panNumber,
    required this.aadhaarNumber,
  });

  factory CreateCustomerRequest.fromJson(Map<String, dynamic> json) {
    return CreateCustomerRequest(
      fullName: (json['fullName'] ?? '').toString(),
      phoneNumber: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      postalCode: json['postalCode']?.toString(),
      country: json['country']?.toString(),
      dateOfBirth: (json['dateOfBirth'] ?? '').toString(),
      panNumber: (json['panNumber'] ?? '').toString(),
      aadhaarNumber: (json['aadhaarNumber'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phoneNumber,
        'address': address,
        if (city != null && city!.trim().isNotEmpty) 'city': city,
        if (state != null && state!.trim().isNotEmpty) 'state': state,
        if (postalCode != null && postalCode!.trim().isNotEmpty)
          'postalCode': postalCode,
        if (country != null && country!.trim().isNotEmpty) 'country': country,
        'dateOfBirth': dateOfBirth,
        'panNumber': panNumber,
        'aadhaarNumber': aadhaarNumber,
      };
}

class UpdateKycStatusRequest {
  @JsonKey(name: 'kycStatus')
  final String kycStatus;

  @JsonKey(name: 'remarks')
  final String? remarks;

  @JsonKey(name: 'verifiedBy')
  final String? verifiedBy;

  UpdateKycStatusRequest({
    required this.kycStatus,
    this.remarks,
    this.verifiedBy,
  });

  Map<String, dynamic> toJson() => {
        'kycStatus': kycStatus,
        'remarks': remarks,
        'verifiedBy': verifiedBy,
      };
}
