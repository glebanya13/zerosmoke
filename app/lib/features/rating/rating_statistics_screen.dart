import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/rating_models.dart';
import '../../data/repositories/rating_repository.dart';

/// Статистика: список разделов с прогрессом по каждому.
class RatingStatisticsScreen extends StatefulWidget {
  const RatingStatisticsScreen({super.key});

  @override
  State<RatingStatisticsScreen> createState() => _RatingStatisticsScreenState();
}

class _RatingStatisticsScreenState extends State<RatingStatisticsScreen> {
  bool _loading = true;
  String? _error;
  List<RatingSectionStat> _sections = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await context.read<RatingRepository>().getMe();
      if (!mounted) return;
      setState(() {
        _sections = me.sections;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: AppTextStyles.body))
          : ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                MediaQuery.of(context).padding.top + 16,
                AppSpacing.md,
                AppSpacing.md,
              ),
              children: [
                const ScreenHeader(title: 'Статистика'),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < _sections.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 17, thickness: 1, color: AppColors.divider),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _sections[i].title,
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.interFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${_sections[i].progress}',
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dangerLight,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/${_sections[i].total}',
                                    style: const TextStyle(
                                      fontFamily: AppTextStyles.fontFamily,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHeading,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
