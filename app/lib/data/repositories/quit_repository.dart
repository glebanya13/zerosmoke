import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/quit_models.dart';

class QuitRepository {
  QuitRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<QuitProfile> getMe() async {
    try {
      final response = await _apiClient.dio.get('/quit/me');
      return QuitProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<QuitProfile> updateMe({
    String? quitDate,
    int? cigarettesPerDay,
    int? packPriceCents,
    int? cigarettesPerPack,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/quit/me',
        data: {
          if (quitDate != null) 'quitDate': quitDate,
          if (cigarettesPerDay != null) 'cigarettesPerDay': cigarettesPerDay,
          if (packPriceCents != null) 'packPriceCents': packPriceCents,
          if (cigarettesPerPack != null) 'cigarettesPerPack': cigarettesPerPack,
        },
      );
      return QuitProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CravingLog> logCraving({required int intensity, String? note}) async {
    try {
      final response = await _apiClient.dio.post(
        '/quit/cravings',
        data: {
          'intensity': intensity,
          if (note != null) 'note': note,
        },
      );
      return CravingLog.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
