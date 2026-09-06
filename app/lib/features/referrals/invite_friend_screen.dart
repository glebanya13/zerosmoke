import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/code_input_boxes.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/repositories/referrals_repository.dart';

/// Пригласить друга: свой код + шаринг, статистика и поле для чужого кода.
/// Награда — по REFERRAL_REWARD_COINS монет каждой стороне (см. бэкенд).
class InviteFriendScreen extends StatefulWidget {
  const InviteFriendScreen({super.key});

  @override
  State<InviteFriendScreen> createState() => _InviteFriendScreenState();
}

class _InviteFriendScreenState extends State<InviteFriendScreen> {
  bool _loading = true;
  String? _loadError;
  ReferralInfo? _info;
  bool _applying = false;
  String? _applyError;
  String? _applySuccess;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await context.read<ReferralsRepository>().getMe();
      if (!mounted) return;
      setState(() {
        _info = info;
        _loadError = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _share() async {
    final code = _info?.code;
    if (code == null) return;
    await SharePlus.instance.share(
      ShareParams(
        text: 'Привет! Я в ZeroSmoke — лиге здоровья. Присоединяйся по моему коду '
            '$code и мы оба получим монеты!',
        subject: 'Приглашение в ZeroSmoke',
      ),
    );
  }

  Future<void> _applyCode(String code) async {
    setState(() {
      _applying = true;
      _applyError = null;
      _applySuccess = null;
    });
    try {
      final result = await context.read<ReferralsRepository>().applyCode(code);
      if (!mounted) return;
      setState(() {
        _applySuccess = 'Готово! Вы и ${result.referrerName} получили по '
            '${result.rewardCoins} монет.';
      });
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _applyError = e.message);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const ScreenHeader(title: 'Пригласить друга'),
              const SizedBox(height: 20),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _loadError!,
                              style: AppTextStyles.body,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            AppButton(label: 'Повторить', onPressed: _load),
                          ],
                        ),
                      )
                    : _content(_info!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(ReferralInfo info) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Приглашай друзей — за каждого, кто присоединится по твоему коду, '
            'вы оба получите монеты.',
            style: AppTextStyles.bodySecondary.copyWith(
              fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            color: AppColors.skyBackgroundTop,
            shadow: false,
            child: Column(
              children: [
                const Text('Твой код:', style: AppTextStyles.bodySecondary),
                Text(
                  info.code,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: info.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Код скопирован')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Скопировать'),
                    ),
                    TextButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Поделиться'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    children: [
                      Text('${info.invitedCount}', style: AppTextStyles.screenTitle),
                      const SizedBox(height: 4),
                      Text(
                        'приглашено друзей',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppCard(
                  child: Column(
                    children: [
                      Text('${info.coinsEarned}', style: AppTextStyles.screenTitle),
                      const SizedBox(height: 4),
                      Text(
                        'монет заработано',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (info.hasUsedFriendCode)
            AppCard(
              child: Text(
                'Вы уже использовали код приглашения друга.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                children: [
                  const Text(
                    'Есть код от друга?',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Введи код друга в поле ниже, чтобы вы оба получили монеты',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  CodeInputBoxes(
                    length: 8,
                    boxSize: 34,
                    radius: 10,
                    gap: 8,
                    alwaysActiveBorder: true,
                    onCompleted: _applying ? null : _applyCode,
                  ),
                  if (_applyError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _applyError!,
                      style: AppTextStyles.caption.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_applySuccess != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _applySuccess!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.success),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
