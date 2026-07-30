import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/token_storage.dart';
import '../../models/models.dart';
import '../models/backend_user.dart';

enum OtpPurpose { register, login }

extension OtpPurposeApi on OtpPurpose {
  String get apiValue => this == OtpPurpose.register ? 'REGISTER' : 'LOGIN';
}

sealed class OtpVerifyResult {}

class OtpVerifyRegisterResult extends OtpVerifyResult {
  OtpVerifyRegisterResult(this.registrationToken);
  final String registrationToken;
}

class OtpVerifyLoginResult extends OtpVerifyResult {
  OtpVerifyLoginResult(this.user);
  final BackendUser user;
}

class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<void> requestOtp(String email, OtpPurpose purpose) async {
    try {
      await _apiClient.dio.post(
        '/auth/otp/request',
        data: {'email': email, 'purpose': purpose.apiValue},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<OtpVerifyResult> verifyOtp(String email, String code, OtpPurpose purpose) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/otp/verify',
        data: {'email': email, 'code': code, 'purpose': purpose.apiValue},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['purpose'] == 'LOGIN') {
        await _tokenStorage.save(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        return OtpVerifyLoginResult(BackendUser.fromJson(data['user'] as Map<String, dynamic>));
      }
      return OtpVerifyRegisterResult(data['registrationToken'] as String);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<BackendUser> completeRegistration({
    required String registrationToken,
    required UserRole role,
    required String name,
    required int age,
    required bool isFemale,
    required int avatarIndex,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register/complete',
        data: {
          'registrationToken': registrationToken,
          'role': userRoleToString(role),
          'name': name,
          'age': age,
          'isFemale': isFemale,
          'avatarIndex': avatarIndex,
          if (phone != null) 'phone': phone,
        },
      );
      final data = response.data as Map<String, dynamic>;
      await _tokenStorage.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return BackendUser.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    final refreshToken = _tokenStorage.refreshToken;
    if (refreshToken != null) {
      try {
        await _apiClient.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {
        // best-effort; local tokens are cleared regardless
      }
    }
    await _tokenStorage.clear();
  }
}
