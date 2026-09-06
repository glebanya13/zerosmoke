import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';

class ReferralInfo {
  ReferralInfo({
    required this.code,
    required this.invitedCount,
    required this.coinsEarned,
    required this.hasUsedFriendCode,
  });

  final String code;
  final int invitedCount;
  final int coinsEarned;
  final bool hasUsedFriendCode;
}

class ApplyReferralResult {
  ApplyReferralResult({required this.rewardCoins, required this.referrerName});

  final int rewardCoins;
  final String referrerName;
}

class ReferralsRepository {
  ReferralsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ReferralInfo> getMe() async {
    try {
      final response = await _apiClient.dio.get('/referrals/me');
      final data = response.data as Map<String, dynamic>;
      return ReferralInfo(
        code: data['code'] as String,
        invitedCount: data['invitedCount'] as int,
        coinsEarned: data['coinsEarned'] as int,
        hasUsedFriendCode: data['hasUsedFriendCode'] as bool,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApplyReferralResult> applyCode(String code) async {
    try {
      final response = await _apiClient.dio.post('/referrals/apply', data: {'code': code});
      final data = response.data as Map<String, dynamic>;
      return ApplyReferralResult(
        rewardCoins: data['rewardCoins'] as int,
        referrerName: data['referrerName'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
