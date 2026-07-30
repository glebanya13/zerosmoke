import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/backend_user.dart';

class InviteCodeResult {
  InviteCodeResult({required this.inviteCode, required this.expiresAt});

  final String inviteCode;
  final DateTime expiresAt;
}

class LinkInfo {
  LinkInfo({required this.linkId, required this.status, required this.counterpart});

  final String linkId;
  final String status;
  final BackendUser counterpart;
}

class LinksRepository {
  LinksRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<InviteCodeResult> createInviteCode() async {
    try {
      final response = await _apiClient.dio.post('/links/invite-code');
      final data = response.data as Map<String, dynamic>;
      return InviteCodeResult(
        inviteCode: data['inviteCode'] as String,
        expiresAt: DateTime.parse(data['expiresAt'] as String),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Redeems an invite code. The caller becomes the link's counterpart, so
  /// the other party (from the caller's perspective) is always the `owner`
  /// in the raw response.
  Future<LinkInfo> redeemCode(String code) async {
    try {
      final response = await _apiClient.dio.post('/links/redeem', data: {'code': code});
      final data = response.data as Map<String, dynamic>;
      return LinkInfo(
        linkId: data['id'] as String,
        status: data['status'] as String,
        counterpart: BackendUser.fromJson(data['owner'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<LinkInfo?> getMyLink() async {
    try {
      final response = await _apiClient.dio.get('/links/me');
      final data = response.data;
      if (data == null) return null;
      return LinkInfo(
        linkId: data['linkId'] as String,
        status: data['status'] as String,
        counterpart: BackendUser.fromJson(data['counterpart'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<BackendUser>> getChildren() async {
    try {
      final response = await _apiClient.dio.get('/links/children');
      return (response.data as List)
          .map((e) => BackendUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> unlink(String linkId) async {
    try {
      await _apiClient.dio.delete('/links/$linkId');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
