import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/content_models.dart';

class ContentRepository {
  ContentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ContentSectionModel>> getSections() async {
    try {
      final response = await _apiClient.dio.get('/content/sections');
      return (response.data as List)
          .map((e) => ContentSectionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ContentTest>> getTests() async {
    try {
      final response = await _apiClient.dio.get('/content/tests');
      return (response.data as List)
          .map((e) => ContentTest.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ContentTestDetail> getTest(String testId) async {
    try {
      final response = await _apiClient.dio.get('/content/tests/$testId');
      return ContentTestDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<GuideModel> getGuide() async {
    try {
      final response = await _apiClient.dio.get('/content/guide');
      return GuideModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<TestAssignment>> getAssignments() async {
    try {
      final response = await _apiClient.dio.get('/content/assignments');
      return (response.data as List)
          .map((e) => TestAssignment.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TestAssignment> assignTest({
    required String testId,
    required String assignedToId,
    String? message,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/content/assignments',
        data: {
          'testId': testId,
          'assignedToId': assignedToId,
          if (message != null) 'message': message,
        },
      );
      return TestAssignment.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TestAttempt> startAttempt(String testId) async {
    try {
      final response = await _apiClient.dio.post('/content/tests/$testId/attempt');
      return TestAttempt.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AnswerResult> answer({
    required String attemptId,
    required String questionId,
    required int selectedOption,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/content/attempts/$attemptId/answer',
        data: {'questionId': questionId, 'selectedOption': selectedOption},
      );
      return AnswerResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TestAttempt> completeAttempt(String attemptId) async {
    try {
      final response = await _apiClient.dio.post('/content/attempts/$attemptId/complete');
      return TestAttempt.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
