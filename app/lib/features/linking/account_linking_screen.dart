import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/code_input_boxes.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/router/app_router.dart';
import '../../data/app_state.dart';
import '../../data/repositories/links_repository.dart';

/// Связка аккаунтов, shown from both child and parent perspectives.
class AccountLinkingScreen extends StatefulWidget {
  const AccountLinkingScreen({super.key});

  @override
  State<AccountLinkingScreen> createState() => _AccountLinkingScreenState();
}

class _AccountLinkingScreenState extends State<AccountLinkingScreen> {
  bool _isLoadingInitial = true;
  bool _isBusy = false;
  LinkInfo? _link;
  InviteCodeResult? _inviteCode;
  String? _loadError;
  String? _redeemError;
  String _enteredCode = '';

  @override
  void initState() {
    super.initState();
    _loadLink();
  }

  Future<void> _loadLink() async {
    if (mounted && !_isLoadingInitial) {
      setState(() {
        _isLoadingInitial = true;
        _loadError = null;
      });
    }
    try {
      final link = await context.read<LinksRepository>().getMyLink();
      if (!mounted) return;
      setState(() {
        _link = link;
        _loadError = null;
        _isLoadingInitial = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _isLoadingInitial = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Не удалось загрузить связку аккаунтов';
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _generateCode() async {
    setState(() => _isBusy = true);
    try {
      final result = await context.read<LinksRepository>().createInviteCode();
      if (!mounted) return;
      setState(() => _inviteCode = result);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _redeem(String code) async {
    setState(() {
      _isBusy = true;
      _redeemError = null;
    });
    try {
      final link = await context.read<LinksRepository>().redeemCode(code);
      if (!mounted) return;
      setState(() => _link = link);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _redeemError = e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _unlink() async {
    final link = _link;
    if (link == null) return;
    setState(() => _isBusy = true);
    try {
      await context.read<LinksRepository>().unlink(link.linkId);
      if (!mounted) return;
      setState(() => _link = null);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _formatExpiry(DateTime expiresAt) {
    final local = expiresAt.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')} $hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final isParent = context.watch<AppState>().isParent;
    final otherRoleLabel = isParent ? 'Ребёнок' : 'Наставник';

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          MediaQuery.of(context).padding.top + 16,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: _isLoadingInitial
            ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenHeader(title: 'Связка аккаунтов'),
                  Expanded(child: Center(child: CircularProgressIndicator())),
                ],
              )
            : _loadError != null
            ? Column(
                children: [
                  const ScreenHeader(title: 'Связка аккаунтов'),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _loadError!,
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        AppButton(label: 'Повторить', onPressed: _loadLink),
                      ],
                    ),
                  ),
                ],
              )
            : _link != null
            ? _connectedView(otherRoleLabel, _link!)
            : _disconnectedView(isParent),
      ),
    );
  }

  Widget _connectedView(String otherRoleLabel, LinkInfo link) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenHeader(title: 'Связка аккаунтов'),
        const SizedBox(height: 20),
        Text('$otherRoleLabel подключен',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Row(
            children: [
              AppAvatar(index: link.counterpart.avatarIndex, size: 44),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(link.counterpart.name, style: AppTextStyles.cardTitle),
                  if (link.counterpart.phone != null)
                    Text(link.counterpart.phone!, style: AppTextStyles.caption),
                  Text(link.counterpart.email, style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _isBusy ? null : _unlink,
          child: const Text('Отключить', style: AppTextStyles.link),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'На главную', onPressed: () => context.go(AppRoutes.root)),
      ],
    );
  }

  Widget _disconnectedView(bool isParent) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeader(title: 'Связка аккаунтов'),
          const SizedBox(height: 20),
          Text(
            '${isParent ? 'Ребёнок' : 'Наставник'} отсутствует',
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isParent
                ? 'Свяжите свой аккаунт с аккаунтом ребёнка, чтобы следить за его прогрессом, отправлять новые тесты и помогать усваивать материалы.'
                : 'Пригласи родителя, чтобы он мог отправлять тебе тесты, отслеживать успехи и помогать усваивать материалы.',
            style: AppTextStyles.bodySecondary.copyWith(
              fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Image.asset(
                'assets/images/illustrations/family_link.png',
                width: 250,
                height: 164,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_inviteCode != null)
            AppCard(
              color: AppColors.skyBackgroundTop,
              shadow: false,
              child: Column(
                children: [
                  Text(
                    isParent ? 'Ваш код:' : 'Твой код:',
                    style: AppTextStyles.bodySecondary,
                  ),
                  Text(
                    _inviteCode!.inviteCode,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: AppColors.textHeading,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _inviteCode!.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Код скопирован')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Скопировать'),
                  ),
                  Text(
                    'Покажите или отправьте этот код ${isParent ? 'ребёнку' : 'родителю'}',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Действует до ${_formatExpiry(_inviteCode!.expiresAt)}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            AppButton(
              style: AppButtonStyle.success,
              expand: true,
              label: 'Получить код приглашения',
              onPressed: _isBusy ? null : _generateCode,
            ),
          const SizedBox(height: AppSpacing.lg),
          // Карточка «Есть код?» с шестью боксами 40×40 из фигмы.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Text(
                  'Есть код от ${isParent ? 'ребёнка' : 'родителя'}?',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Введи код от ${isParent ? 'ребёнка' : 'родителя'} в поле ниже, чтобы установить связь',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                CodeInputBoxes(
                  length: 6,
                  boxSize: 40,
                  radius: 12,
                  gap: 12,
                  submitOnComplete: false,
                  onChanged: (code) => setState(() {
                    _enteredCode = code;
                    _redeemError = null;
                  }),
                ),
                if (_redeemError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _redeemError!,
                    style: AppTextStyles.caption.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                AppButton(
                  label: 'Подключиться',
                  expand: true,
                  enabled: _enteredCode.length == 6 && !_isBusy,
                  onPressed: _enteredCode.length == 6 && !_isBusy
                      ? () => _redeem(_enteredCode)
                      : null,
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
