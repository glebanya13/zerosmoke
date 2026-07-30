import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_icon_button.dart';
import '../../core/widgets/step_dots.dart';

class WelcomeOnboardingScreen extends StatefulWidget {
  const WelcomeOnboardingScreen({super.key});

  @override
  State<WelcomeOnboardingScreen> createState() => _WelcomeOnboardingScreenState();
}

class _WelcomeOnboardingScreenState extends State<WelcomeOnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    'Это приложение создано для того, чтобы сформировать у ребёнка или взрослого человека осознанное понимание вреда, который курение наносит организму, и закрепить эту информацию в памяти.',
    'Чтобы в следующий раз, когда ребёнку или взрослому предложат закурить или появится мысль сделать это, в памяти возникло понимание, основанное на фактах из этого приложения, о том, какой реальный вред курение наносит физическому и ментальному здоровью.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackIconButton(onPressed: () => Navigator.of(context).maybePop()),
                  ),
                  StepDots(total: 6, activeStep: _page + 3),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const SizedBox(
                width: double.infinity,
                child: Text(
                  'О приложении',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.screenTitle,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => AppCard(
                    child: Center(
                      child: Text(
                        _pages[i],
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(fontSize: 18, height: 1.4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text('${_page + 1}/${_pages.length}', style: AppTextStyles.link),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: _page == _pages.length - 1 ? 'Начать' : 'Далее',
                onPressed: () {
                  if (_page == _pages.length - 1) {
                    context.push(AppRoutes.promoOnboarding);
                  } else {
                    _controller.nextPage(
                      duration: AppDurations.normal,
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
