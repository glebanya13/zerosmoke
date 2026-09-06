import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/backend_user.dart';

class UsersRepository {
  UsersRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<BackendUser> getMe() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      return BackendUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<BackendUser> updateMe({
    String? name,
    int? age,
    bool? isFemale,
    int? avatarIndex,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/users/me',
        data: {
          if (name != null) 'name': name,
          if (age != null) 'age': age,
          if (isFemale != null) 'isFemale': isFemale,
          if (avatarIndex != null) 'avatarIndex': avatarIndex,
          if (phone != null) 'phone': phone,
        },
      );
      return BackendUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
