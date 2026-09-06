import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../core/widgets/app_button.dart';
import '../../data/app_state.dart';
import '../../data/models/content_models.dart';
import '../../data/repositories/content_repository.dart';

/// Прохождение теста — единый флоу для бесплатной/платной версии,
/// данные (вопросы, попытка) приходят с бэкенда.
class TestFlowScreen extends StatefulWidget {
  const TestFlowScreen({super.key, required this.args});

  final TestFlowArgs args;

  @override
  State<TestFlowScreen> createState() => _TestFlowScreenState();
}

class _TestFlowScreenState extends State<TestFlowScreen> {
  bool _loading = true;
  String? _error;
  ContentTestDetail? _test;
  String? _attemptId;

  int _index = 0;
  int? _selected;
  bool _revealed = false;
  bool _submitting = false;
  bool _completing = false;
  int? _correctOption;
  bool? _isCorrect;
  String? _answerError;

  TestQuestionModel get _question => _test!.questions[_index];
  bool get paid => widget.args.paid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<ContentRepository>();
    try {
      final test = await repo.getTest(widget.args.testId);
      final attempt = await repo.startAttempt(widget.args.testId);
      if (!mounted) return;
      setState(() {
        _test = test;
        _attemptId = attempt.id;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _selectOption(int i) async {
    if (_revealed || _submitting) return;
    setState(() {
      _selected = i;
      _submitting = true;
    });
    try {
      final result = await context.read<ContentRepository>().answer(
        attemptId: _attemptId!,
        questionId: _question.id,
        selectedOption: i,
      );
      if (!mounted) return;
      final appState = context.read<AppState>();
      if (appState.vibrationEnabled) {
        HapticFeedback.lightImpact();
      }
      if (appState.soundEnabled) {
        SystemSound.play(SystemSoundType.click);
      }
      setState(() {
        _correctOption = result.correctOption;
        _isCorrect = result.isCorrect;
        _revealed = true;
        _submitting = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _selected = null;
        _submitting = false;
        _answerError = e.message;
      });
    }
  }

  void _showMaterial(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          _question.material ?? '',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            height: 22 / 16,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _selected = null;
      _revealed = false;
      _correctOption = null;
      _isCorrect = null;
      _answerError = null;
    });
  }

  Future<void> _next() async {
    if (_index >= _test!.questions.length - 1) {
      setState(() => _completing = true);
      try {
        final result = await context.read<ContentRepository>().completeAttempt(_attemptId!);
        if (!mounted) return;
        context.pushReplacement(
          AppRoutes.testResult,
          extra: TestResultArgs(
            testTitle: _test!.title,
            correctCount: result.correctCount,
            totalCount: result.totalCount,
            paid: paid,
          ),
        );
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() => _completing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _revealed = false;
      _correctOption = null;
      _isCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: AppTextStyles.body, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                AppButton(label: 'Повторить', onPressed: _load),
              ],
            ),
          ),
        ),
      );
    }

    final total = _test!.questions.length;
    final isCorrect = _isCorrect ?? false;
    final showHint = paid || context.watch<AppState>().hintsEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: const [
                        Icon(Icons.chevron_left, size: 24, color: AppColors.textPrimary),
                        Text(
                          'назад',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1} из $total',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + 1) / total,
                  minHeight: 8,
                  backgroundColor: AppColors.primaryDeep,
                  valueColor: const AlwaysStoppedAnimation(AppColors.textHeading),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                _test!.title,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 28 / 24,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 200),
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: !_revealed
                                  ? Text(
                                      _question.text,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        height: 24 / 20,
                                        color: AppColors.textPrimary,
                                      ),
                                    )
                                  : !paid
                                  ? Text(
                                      _question.material?.isNotEmpty == true
                                          ? _question.material!
                                          : _question.text,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        height: 22 / 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    )
                                  : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isCorrect
                                          ? 'Отлично!\nЭто правильный ответ.\nДавай продолжим!'
                                          : 'Ой, неправильно..\nПопробуй еще раз - у тебя всё получится!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.fontFamily,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        height: 28 / 24,
                                        color: isCorrect ? AppColors.success : AppColors.dangerLight,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isCorrect ? '+1' : '-1',
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.fontFamily,
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: isCorrect ? AppColors.success : AppColors.dangerLight,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Image.asset(
                                          'assets/images/icons/icon_coin.png',
                                          width: 28,
                                          height: 28,
                                        ),
                                      ],
                                    ),
                                    if (_revealed &&
                                        !isCorrect &&
                                        showHint &&
                                        (_question.material?.isNotEmpty ?? false)) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        _question.material!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 14,
                                          height: 18 / 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                            ),
                          ),
                          if (!_revealed && (_question.material?.isNotEmpty ?? false))
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => _showMaterial(context),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.selectedAnswerFill,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    size: 18,
                                    color: AppColors.textHeading,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      for (int i = 0; i < _question.options.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OptionTile(
                            index: i,
                            text: _question.options[i],
                            selected: _selected == i,
                            revealed: _revealed,
                            correctIndex: _correctOption,
                            paid: paid,
                            onTap: () => _selectOption(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_answerError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _answerError!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary.copyWith(color: Colors.red),
                  ),
                ),
              if (_revealed && !isCorrect)
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        style: AppButtonStyle.white,
                        expand: true,
                        label: 'Повторить',
                        onPressed: _retry,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: AppButton(
                        expand: true,
                        label: _index >= total - 1 ? 'Завершить' : 'Продолжить',
                        onPressed: _completing ? null : _next,
                      ),
                    ),
                  ],
                )
              else
                AppButton(
                  label: _completing
                      ? 'Сохранение...'
                      : (_index >= total - 1 ? 'Завершить' : 'Далее'),
                  enabled: _revealed && !_completing,
                  onPressed: _revealed && !_completing ? _next : null,
                ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.index,
    required this.text,
    required this.selected,
    required this.revealed,
    required this.correctIndex,
    required this.paid,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool selected;
  final bool revealed;
  final int? correctIndex;
  final bool paid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color borderColor = AppColors.borderLight;
    Color textColor = AppColors.textGrey;
    if (revealed) {
      if (paid && correctIndex != null && index == correctIndex) {
        bg = AppColors.successLight;
        borderColor = AppColors.success;
        textColor = AppColors.textPrimary;
      } else if (paid && selected && correctIndex != null && index != correctIndex) {
        bg = const Color(0xFFFFEBEE);
        borderColor = AppColors.dangerLight;
        textColor = AppColors.textPrimary;
      } else if (selected) {
        bg = AppColors.selectedAnswerFill;
        borderColor = AppColors.textHeading;
        textColor = AppColors.textHeading;
      }
    } else if (selected) {
      bg = AppColors.selectedAnswerFill;
      borderColor = AppColors.textHeading;
      textColor = AppColors.textHeading;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${index + 1}',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 20 / 16,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
