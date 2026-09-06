import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/achievement_model.dart';

class AchievementsRepository {
  AchievementsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AchievementModel>> getAll() async {
    try {
      final response = await _apiClient.dio.get('/achievements');
      return (response.data as List)
          .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
