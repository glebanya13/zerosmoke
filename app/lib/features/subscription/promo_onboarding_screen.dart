import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_icon_button.dart';
import '../../core/widgets/step_dots.dart';
import 'subscription_paywall_modal.dart';

class _PromoFeature {
  const _PromoFeature({
    required this.title,
    required this.subtitle,
    this.iconAsset,
    this.icon,
    this.color,
  });

  final String? iconAsset;
  final IconData? icon;
  final Color? color;
  final String title;
  final String subtitle;
}

class _DetailPage {
  const _DetailPage({
    required this.title,
    required this.body,
    required this.previewAsset,
    required this.infoIconAsset,
    this.infoIconSize = 40,
  });

  final String title;
  final String body;
  final String previewAsset;
  final String infoIconAsset;
  final double infoIconSize;
}

const _features = [
  _PromoFeature(
    iconAsset: 'assets/images/icons/icon_graph.png',
    title: 'Все ответы ребёнка',
    subtitle: 'Видны правильные и неправильные ответы по каждому тесту.',
  ),
  _PromoFeature(
    icon: Icons.access_time,
    color: Color(0xFFFF9F0A),
    title: 'Подробный разбор',
    subtitle: 'Время прохождения каждого вопроса и анализ ошибок по каждому тесту.',
  ),
  _PromoFeature(
    iconAsset: 'assets/images/icons/icon_send.png',
    title: 'Отправка тестов',
    subtitle: 'Возможность отправлять новые и повторные тесты напрямую ребёнку.',
  ),
];

const _detailPages = [
  _DetailPage(
    title: 'Все ответы ребёнка',
    body:
        'С подпиской вы увидите все результаты, ошибки и правильные ответы ребёнка по каждому тесту.',
    previewAsset: 'assets/images/illustrations/promo_answers_preview.png',
    infoIconAsset: 'assets/images/icons/icon_graph.png',
  ),
  _DetailPage(
    title: 'Подробный разбор тестов',
    body:
        'Аналитика помогает вам лучше понимать прогресс и темп ребёнка, и вовремя помогать ему в усвоении информации.',
    previewAsset: 'assets/images/illustrations/promo_analytics_preview.png',
    infoIconAsset: 'assets/images/icons/icon_clock.png',
  ),
  _DetailPage(
    title: 'Отправляйте задания',
    body:
        'Вы можете самостоятельно выбирать и отправлять тесты ребёнку, а он их будет выполнять в удобное время.',
    previewAsset: 'assets/images/illustrations/promo_send_preview.png',
    infoIconAsset: 'assets/images/icons/icon_send.png',
  ),
];

/// Финальный шаг регистрации: экран поддержки + детальные слайды подписки.
class PromoOnboardingScreen extends StatefulWidget {
  const PromoOnboardingScreen({super.key});

  @override
  State<PromoOnboardingScreen> createState() => _PromoOnboardingScreenState();
}

class _PromoOnboardingScreenState extends State<PromoOnboardingScreen> {
  bool _showDetails = false;
  bool _showSubscription = false;
  final _detailController = PageController();
  int _detailIndex = 0;

  void _finish() {
    if (_showDetails || _showSubscription) {
      setState(() {
        _showDetails = false;
        _showSubscription = false;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(AppRoutes.root);
    });
  }

  void _openDetails() {
    setState(() {
      _showDetails = true;
      _detailIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_detailController.hasClients) {
        _detailController.jumpToPage(0);
      }
    });
  }

  void _openSubscription() {
    setState(() {
      _showDetails = false;
      _showSubscription = true;
    });
  }

  void _nextDetail() {
    if (_detailIndex >= _detailPages.length - 1) {
      _openSubscription();
      return;
    }
    _detailController.nextPage(
      duration: AppDurations.normal,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: Stack(
        children: [
          IgnorePointer(
            ignoring: _showDetails || _showSubscription,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BackIconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        const StepDots(total: 6, activeStep: 5),
                      ],
                    ),
                  ),
                  const Expanded(child: _SupportSlide()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Column(
                      children: [
                        AppButton(
                          style: AppButtonStyle.gradient,
                          expand: true,
                          label: 'Подробнее',
                          onPressed: _openDetails,
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _finish,
                          child: const Text('На главную', style: AppTextStyles.link),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showDetails)
            _DetailsFlow(
              controller: _detailController,
              index: _detailIndex,
              onIndexChanged: (i) => setState(() => _detailIndex = i),
              onClose: _finish,
              onNext: _nextDetail,
              onSkip: _finish,
            ),
          if (_showSubscription)
            SubscriptionPaywallOverlay(
              onClose: _finish,
              onGoHome: _finish,
            ),
        ],
      ),
    );
  }
}

class _SupportSlide extends StatelessWidget {
  const _SupportSlide();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth.clamp(0.0, 360.0);
        final imageHeight = imageWidth * (280 / 361);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(
            children: [
              Text(
                'Поддержите наше приложение',
                style: AppTextStyles.screenTitle.copyWith(height: 1.1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Ваша подписка помогает развивать приложение, создавать новые тесты, улучшать аналитику и делать процесс обучения ещё более полезным и интересным.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: imageWidth,
                height: imageHeight,
                child: Image.asset(
                  'assets/images/illustrations/support_mascot.png',
                  fit: BoxFit.contain,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    for (final feature in _features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FeatureIcon(feature: feature),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    feature.title,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.interFamily,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    feature.subtitle,
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.interFamily,
                                      fontSize: 12,
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
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailsFlow extends StatelessWidget {
  const _DetailsFlow({
    required this.controller,
    required this.index,
    required this.onIndexChanged,
    required this.onClose,
    required this.onNext,
    required this.onSkip,
  });

  final PageController controller;
  final int index;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onClose;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x66000000),
      child: SafeArea(
        child: PageView.builder(
          controller: controller,
          itemCount: _detailPages.length,
          onPageChanged: onIndexChanged,
          itemBuilder: (context, i) {
            final page = _detailPages[i];
            return _DetailSlide(
              page: page,
              onClose: onClose,
              primaryLabel:
                  i == _detailPages.length - 1 ? 'Оформить подписку' : 'Далее',
              onPrimary: onNext,
              onSkip: onSkip,
            );
          },
        ),
      ),
    );
  }
}

class _DetailSlide extends StatelessWidget {
  const _DetailSlide({
    required this.page,
    required this.onClose,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onSkip,
  });

  final _DetailPage page;
  final VoidCallback onClose;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: maxHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.none,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 18, 8, 0),
                  child: SizedBox(
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 28),
                          child: Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: onClose,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            icon: const Icon(Icons.close, color: AppColors.primary, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final height = (width * 1.22).clamp(280.0, 440.0);
                            return SizedBox(
                              width: width,
                              height: height,
                              child: Image.asset(
                                page.previewAsset,
                                fit: BoxFit.contain,
                                alignment: Alignment.topCenter,
                              ),
                            );
                          },
                        ),
                        Transform.translate(
                          offset: const Offset(0, -36),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1F000000),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Color(0x0D000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    page.infoIconAsset,
                                    width: page.infoIconSize,
                                    height: page.infoIconSize,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      page.body,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 1.25,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      AppButton(
                        style: AppButtonStyle.gradient,
                        expand: true,
                        label: primaryLabel,
                        onPressed: onPrimary,
                      ),
                      const SizedBox(height: 2),
                      TextButton(
                        onPressed: onSkip,
                        child: Text(
                          'Пропустить',
                          style: AppTextStyles.link.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({required this.feature});

  final _PromoFeature feature;

  @override
  Widget build(BuildContext context) {
    if (feature.iconAsset != null) {
      return Image.asset(feature.iconAsset!, width: 36, height: 36);
    }
    return Icon(feature.icon, size: 36, color: feature.color ?? AppColors.primary);
  }
}
