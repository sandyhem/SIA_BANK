// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      userId: (json['userId'] as num).toInt(),
      token: json['token'] as String,
      expiresIn: (json['expiresIn'] as num?)?.toInt(),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'token': instance.token,
      'expiresIn': instance.expiresIn,
      'message': instance.message,
    };

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      username: json['username'] as String,
      password: json['password'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'email': instance.email,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
    };

UserKycDTO _$UserKycDTOFromJson(Map<String, dynamic> json) => UserKycDTO(
      userId: (json['userId'] as num).toInt(),
      status: json['status'] as String,
      approvedAt: json['approvedAt'] as String?,
      verifiedBy: json['verifiedBy'] as String?,
    );

Map<String, dynamic> _$UserKycDTOToJson(UserKycDTO instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'status': instance.status,
      'approvedAt': instance.approvedAt,
      'verifiedBy': instance.verifiedBy,
    };

CustomerDTO _$CustomerDTOFromJson(Map<String, dynamic> json) => CustomerDTO(
      customerId: (json['customerId'] as num).toInt(),
      cifNumber: json['cifNumber'] as String,
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String,
      kycStatus: json['kycStatus'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$CustomerDTOToJson(CustomerDTO instance) =>
    <String, dynamic>{
      'customerId': instance.customerId,
      'cifNumber': instance.cifNumber,
      'userId': instance.userId,
      'fullName': instance.fullName,
      'kycStatus': instance.kycStatus,
      'phoneNumber': instance.phoneNumber,
      'address': instance.address,
      'createdAt': instance.createdAt,
    };

CreateCustomerRequest _$CreateCustomerRequestFromJson(
        Map<String, dynamic> json) =>
    CreateCustomerRequest(
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      address: json['address'] as String,
      dateOfBirth: json['dateOfBirth'] as String,
    );

Map<String, dynamic> _$CreateCustomerRequestToJson(
        CreateCustomerRequest instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'address': instance.address,
      'dateOfBirth': instance.dateOfBirth,
    };
