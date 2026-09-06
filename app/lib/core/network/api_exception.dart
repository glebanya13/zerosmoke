import 'package:dio/dio.dart';

/// Wraps a backend error response `{statusCode, message, error}` for display.
class ApiException implements Exception {
  ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  factory ApiException.fromDioError(DioException error) {
    final data = error.response?.data;
    final statusCode = error.response?.statusCode ?? 0;
    if (data is Map && data['message'] != null) {
      final rawMessage = data['message'];
      final message = rawMessage is List ? rawMessage.join(', ') : rawMessage.toString();
      return ApiException(statusCode: statusCode, message: message);
    }

    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          statusCode: statusCode,
          message: 'Нет связи с сервером. Проверьте интернет и попробуйте снова.',
        );
      case DioExceptionType.badResponse:
        return ApiException(
          statusCode: statusCode,
          message: 'Сервер временно недоступен. Попробуйте позже.',
        );
      case DioExceptionType.cancel:
        return ApiException(statusCode: statusCode, message: 'Запрос отменён');
      case DioExceptionType.badCertificate:
        return ApiException(statusCode: statusCode, message: 'Ошибка защищённого соединения');
      case DioExceptionType.unknown:
      default:
        final raw = error.message ?? '';
        if (raw.toLowerCase().contains('connection refused') ||
            raw.toLowerCase().contains('failed host lookup') ||
            raw.toLowerCase().contains('network is unreachable')) {
          return ApiException(
            statusCode: statusCode,
            message: 'Нет связи с сервером. Проверьте интернет и попробуйте снова.',
          );
        }
        return ApiException(
          statusCode: statusCode,
          message: 'Не удалось выполнить запрос',
        );
    }
  }

  @override
  String toString() => message;
}
