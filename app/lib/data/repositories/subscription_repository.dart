import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/subscription_models.dart';

class SubscriptionRepository {
  SubscriptionRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<BackendSubscriptionPlan>> getPlans({String tier = 'child1'}) async {
    try {
      final response = await _apiClient.dio.get(
        '/subscription/plans',
        queryParameters: {'tier': tier},
      );
      return (response.data as List)
          .map((e) => BackendSubscriptionPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<SubscriptionStatus?> getMine() async {
    try {
      final response = await _apiClient.dio.get('/subscription/me');
      if (response.data == null) return null;
      return SubscriptionStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Returns the website checkout URL for the selected plan (payment is web-only).
  Future<String> getCheckoutUrl(String planId) async {
    try {
      final response = await _apiClient.dio.get(
        '/subscription/checkout-url',
        queryParameters: {'planId': planId},
      );
      return (response.data as Map<String, dynamic>)['url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
