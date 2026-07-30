import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/app_card.dart';
import '../../data/app_state.dart';
import '../../data/models/subscription_models.dart';
import '../../data/repositories/subscription_repository.dart';

/// Экран «Подписка» из профиля — полноэкранный paywall по макету.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with WidgetsBindingObserver {
  int _selectedPlan = 3;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  List<BackendSubscriptionPlan> _plans = [];

  static const _benefits = [
    _Benefit(
      iconAsset: 'assets/images/icons/icon_graph.png',
      title: 'Все ответы ребёнка',
      subtitle: 'Видны правильные и неправильные ответы по каждому тесту.',
    ),
    _Benefit(
      iconAsset: 'assets/images/icons/icon_clock.png',
      title: 'Подробный разбор',
      subtitle: 'Время прохождения каждого вопроса и анализ ошибок по каждому тесту.',
    ),
    _Benefit(
      iconAsset: 'assets/images/icons/icon_send.png',
      title: 'Отправка тестов',
      subtitle: 'Возможность отправлять новые и повторные тесты напрямую ребёнку.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    await context.read<AppState>().refreshSubscriptionStatus(
          context.read<SubscriptionRepository>(),
        );
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final hasSub = context.read<AppState>().hasSubscription;
    try {
      final plans = await context.read<SubscriptionRepository>().getPlans(
            tier: hasSub ? 'child2' : 'child1',
          );
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _loading = false;
        if (_selectedPlan >= plans.length) {
          _selectedPlan = plans.isEmpty ? 0 : plans.length - 1;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openCheckout() async {
    if (_selectedPlan >= _plans.length) return;
    setState(() => _purchasing = true);
    try {
      final url = await context.read<SubscriptionRepository>().getCheckoutUrl(
            _plans[_selectedPlan].id,
          );
      if (!mounted) return;
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() => _purchasing = false);
      if (!ok) {
        setState(() => _error = 'Не удалось открыть страницу оплаты');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _purchasing = false;
        _error = e.message;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final hasSub = state.hasSubscription;

    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                MediaQuery.of(context).padding.top + 16,
                AppSpacing.md,
                AppSpacing.md,
              ),
              children: [
                const ScreenHeader(title: 'Подписка'),
                const SizedBox(height: 20),
                if (hasSub)
                  AppCard(
                    color: AppColors.primary,
                    shadow: false,
                    child: const Text(
                      'Подписка активна',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  )
                else ...[
                  const Text(
                    'Хотите видеть больше?',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Подключите подписку и получите расширенную статистику прогресса вашего ребёнка.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        for (final benefit in _benefits)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(benefit.iconAsset, width: 36, height: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        benefit.title,
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.interFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        benefit.subtitle,
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.interFamily,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                          height: 1.35,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.promoOnboarding),
                          child: const Text('Подробнее', style: AppTextStyles.link),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hasSub) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Обновите подписку для второго ребёнка',
                    style: AppTextStyles.sectionTitle,
                  ),
                  const Text(
                    'с 50% скидкой',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  hasSub ? 'Тарифы для 2-го ребёнка' : 'Тарифы для 1-го ребёнка',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (int i = 0; i < _plans.length; i++) _planTile(_plans[i], i),
                const SizedBox(height: AppSpacing.md),
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.danger),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppButton(
                  expand: true,
                  label: _purchasing ? 'Открываем сайт…' : 'К оплате',
                  enabled: !_purchasing && _plans.isNotEmpty,
                  onPressed: _openCheckout,
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      height: 1.35,
                      color: AppColors.textGrey,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Нажимая «К оплате», вы соглашаетесь с условиями пользовательского соглашения и политикой конфиденциальности.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: [
                    TextButton(
                      onPressed: () => _openUrl('https://zerosmoker.ru'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Пользовательское соглашение',
                        style: AppTextStyles.link.copyWith(fontSize: 11),
                      ),
                    ),
                    Text(
                      'и',
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                    TextButton(
                      onPressed: () => _openUrl('https://zerosmoker.ru'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'политика конфиденциальности',
                        style: AppTextStyles.link.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/icons/icon_heart_support.png',
                        width: 37,
                        height: 34,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Поддержите развитие приложения',
                              style: TextStyle(
                                fontFamily: AppTextStyles.interFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ваша подписка помогает развивать приложение, создавать новые тесты, улучшать аналитику и делать процесс обучения ещё более полезным и интересным.',
                              style: TextStyle(
                                fontFamily: AppTextStyles.interFamily,
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                height: 1.35,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _planTile(BackendSubscriptionPlan plan, int index) {
    final selected = index == _selectedPlan;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlan = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderLight,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.toggleOff,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                    if (plan.discountLabel != null)
                      Text(
                        plan.discountLabel!,
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.price,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.interFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.pricePurple,
                    ),
                  ),
                  if (plan.perMonth != null)
                    Text(
                      plan.perMonth!,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.interFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGrey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit {
  const _Benefit({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
}
