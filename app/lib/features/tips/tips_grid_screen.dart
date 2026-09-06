import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_dimens.dart';
import '../../core/design_system/app_text_styles.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_router.dart';
import '../../core/router/route_args.dart';
import '../../data/models/content_models.dart';
import '../../data/repositories/content_repository.dart';
import '../home/home_parent_screen.dart' show MoreChip;
import 'tip_colors.dart';

/// Советы (Родитель): сетка карточек по секциям памятки, загруженной с бэкенда.
class TipsGridScreen extends StatefulWidget {
  const TipsGridScreen({super.key});

  @override
  State<TipsGridScreen> createState() => _TipsGridScreenState();
}

class _TipsGridScreenState extends State<TipsGridScreen> {
  bool _loading = true;
  String? _error;
  List<GuideSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final guide = await context.read<ContentRepository>().getGuide();
      if (!mounted) return;
      setState(() {
        _sections = guide.sections;
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
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.parentHomeGradient),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white)))
          : Column(
              children: [
                SizedBox(
                  height: topPad + 52,
                  child: const Center(child: Text('Советы', style: AppTextStyles.pageTitle)),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 130),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 174 / 274,
              ),
              itemCount: _sections.length,
              itemBuilder: (context, i) {
                final section = _sections[i];
                return GestureDetector(
                  onTap: () => context.push(
                    AppRoutes.tipDetail,
                    extra: TipDetailArgs(section: section, colorIndex: i % tipColors.length),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: tipColors[i % tipColors.length],
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(section.title, style: AppTextStyles.cardTitle, maxLines: 2),
                        const SizedBox(height: 6),
                        Text(
                          section.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const MoreChip(),
                      ],
                    ),
                  ),
                );
              },
            ),
                ),
              ],
            ),
    );
  }
}
