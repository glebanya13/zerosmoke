import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/app_button.dart';
import '../../data/app_state.dart';
import '../../data/models/subscription_models.dart';
import '../../data/repositories/subscription_repository.dart';

/// Paywall-модалка «Оформить подписку» из макета онбординга.
class SubscriptionPaywallOverlay extends StatefulWidget {
  const SubscriptionPaywallOverlay({
    super.key,
    required this.onClose,
    required this.onGoHome,
    this.tier = 'child1',
  });

  final VoidCallback onClose;
  final VoidCallback onGoHome;
  final String tier;

  @override
  State<SubscriptionPaywallOverlay> createState() => _SubscriptionPaywallOverlayState();
}

class _SubscriptionPaywallOverlayState extends State<SubscriptionPaywallOverlay>
    with WidgetsBindingObserver {
  int _selectedPlan = 3;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  List<BackendSubscriptionPlan> _plans = [];

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
    try {
      final plans = await context.read<SubscriptionRepository>().getPlans(
            tier: widget.tier,
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

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Material(
      color: const Color(0x66000000),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
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
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
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
                                            'Оформить подписку',
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.screenTitle.copyWith(
                                              fontSize: 22,
                                              height: 1.15,
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: IconButton(
                                            onPressed: widget.onClose,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                            icon: const Icon(
                                              Icons.close,
                                              color: AppColors.primary,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Благодаря вашей поддержке мы можем регулярно добавлять новый контент и совершенствовать функционал для всех пользователей.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            height: 1.35,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: AppColors.borderLight),
                                          ),
                                          child: Row(
                                            children: const [
                                              Expanded(
                                                child: _BenefitChip(
                                                  iconAsset: 'assets/images/icons/icon_graph.png',
                                                  label: 'Все ответы',
                                                ),
                                              ),
                                              Expanded(
                                                child: _BenefitChip(
                                                  iconAsset: 'assets/images/icons/icon_clock.png',
                                                  label: 'Аналитика',
                                                ),
                                              ),
                                              Expanded(
                                                child: _BenefitChip(
                                                  iconAsset: 'assets/images/icons/icon_send.png',
                                                  label: 'Новые тесты',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            widget.tier == 'child2'
                                                ? 'Тарифы для 2-го ребёнка'
                                                : 'Тарифы для 1-го ребёнка',
                                            style: AppTextStyles.sectionTitle,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        for (int i = 0; i < _plans.length; i++)
                                          _PlanTile(
                                            plan: _plans[i],
                                            selected: i == _selectedPlan,
                                            onTap: () => setState(() => _selectedPlan = i),
                                          ),
                                        if (_error != null) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            _error!,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.body.copyWith(
                                              color: AppColors.danger,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                  child: AppButton(
                                    style: AppButtonStyle.gradient,
                                    expand: true,
                                    label: _purchasing ? 'Открываем сайт…' : 'Оформить подписку',
                                    enabled: !_purchasing && _plans.isNotEmpty,
                                    onPressed: _openCheckout,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: TextButton(
                onPressed: widget.onGoHome,
                child: const Text('На главную', style: AppTextStyles.link),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.iconAsset, required this.label});

  final String iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(iconAsset, width: 36, height: 36),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final BackendSubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
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
