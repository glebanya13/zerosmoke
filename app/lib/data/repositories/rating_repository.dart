import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/rating_models.dart';

class RatingRepository {
  RatingRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final response = await _apiClient.dio.get('/rating/leaderboard');
      return (response.data as List)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<RatingMe> getMe() async {
    try {
      final response = await _apiClient.dio.get('/rating/me');
      return RatingMe.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
