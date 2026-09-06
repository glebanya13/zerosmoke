import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_icon_button.dart';
import '../../core/widgets/step_dots.dart';

/// «О приложении» 1/2 — по макету: синий заголовок, белая карточка
/// с синей рамкой r=20, дробь страницы внутри карточки.
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
      backgroundColor: Colors.white,
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
                  StepDots(
                    total: 6,
                    activeStep: _page + 3,
                    currentCompleted: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const SizedBox(
                width: double.infinity,
                child: Text(
                  'О приложении',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headerTitle,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.textHeading),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              _pages[i],
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 22 / 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${i + 1}/${_pages.length}',
                          style: AppTextStyles.link.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Далее',
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
