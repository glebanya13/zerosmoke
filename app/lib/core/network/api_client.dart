import 'package:dio/dio.dart';
import 'token_storage.dart';

typedef SessionExpiredCallback = void Function();

/// Shared Dio instance: attaches the bearer token to every request and
/// transparently refreshes + retries once on a 401.
class ApiClient {
  ApiClient(this.tokenStorage, {this.onSessionExpired})
      : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = tokenStorage.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isRefreshCall = error.requestOptions.path == '/auth/refresh';
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (error.response?.statusCode == 401 &&
              !isRefreshCall &&
              !alreadyRetried &&
              tokenStorage.refreshToken != null) {
            final refreshed = await _refresh();
            if (refreshed) {
              final retryOptions = error.requestOptions;
              retryOptions.extra['retried'] = true;
              retryOptions.headers['Authorization'] = 'Bearer ${tokenStorage.accessToken}';
              try {
                final response = await dio.fetch(retryOptions);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }
            await _expireSession();
          } else if (error.response?.statusCode == 401 &&
              !isRefreshCall &&
              tokenStorage.accessToken != null) {
            await _expireSession();
          }
          handler.next(error);
        },
      ),
    );
  }

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://zerosmoker.ru/api',
  );

  final TokenStorage tokenStorage;
  final SessionExpiredCallback? onSessionExpired;
  final Dio dio;
  Future<bool>? _refreshing;

  Future<void> _expireSession() async {
    await tokenStorage.clear();
    onSessionExpired?.call();
  }

  Future<bool> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = tokenStorage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await Dio(BaseOptions(baseUrl: baseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      await tokenStorage.save(
        accessToken: response.data['accessToken'] as String,
        refreshToken: response.data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
