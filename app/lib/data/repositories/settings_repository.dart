import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  SettingsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserSettingsModel> getMine() async {
    try {
      final response = await _apiClient.dio.get('/settings/me');
      return UserSettingsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserSettingsModel> updateMine(Map<String, bool> changes) async {
    try {
      final response = await _apiClient.dio.put('/settings/me', data: changes);
      return UserSettingsModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
