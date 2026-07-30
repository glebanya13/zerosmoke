import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/bottom_nav_shell.dart';
import '../../data/app_state.dart';
import '../../data/repositories/content_repository.dart';
import '../rating/rating_screen.dart';
import '../tests/tests_list_screen.dart';
import '../tips/tips_grid_screen.dart';
import '../profile/profile_screen.dart';
import 'home_child_screen.dart';
import 'home_parent_screen.dart';

/// Hosts the four bottom-nav tabs; tab 1 switches between Тесты (child) and
/// Советы (parent) depending on the active role.
class RootShell extends StatefulWidget {
  const RootShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  late int _index;
  int _refreshKey = 0;
  int _testsBadgeCount = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab;
    WidgetsBinding.instance.addObserver(this);
    _loadTestsBadge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(RootShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() {
        _index = widget.initialTab;
        _refreshKey++;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _refreshKey++);
      _loadTestsBadge();
    }
  }

  Future<void> _loadTestsBadge() async {
    final appState = context.read<AppState>();
    if (appState.isParent) return;
    try {
      final assignments = await context.read<ContentRepository>().getAssignments();
      final count = assignments.where((a) => a.isIncomplete).length;
      if (mounted) setState(() => _testsBadgeCount = count);
    } catch (_) {
      // Badge is optional.
    }
  }

  void _onTabTap(int index) {
    setState(() {
      _index = index;
      _refreshKey++;
    });
    if (index == 1) _loadTestsBadge();
  }

  @override
  Widget build(BuildContext context) {
    final isParent = context.watch<AppState>().isParent;
    final refreshKey = ValueKey(_refreshKey);

    final screens = [
      isParent
          ? HomeParentScreen(key: refreshKey)
          : HomeChildScreen(key: refreshKey),
      isParent
          ? TipsGridScreen(key: refreshKey)
          : TestsListScreen(key: refreshKey),
      RatingScreen(key: refreshKey),
      ProfileScreen(key: refreshKey),
    ];

    return BottomNavShell(
      currentIndex: _index,
      onTap: _onTabTap,
      testsBadgeCount: isParent ? 0 : _testsBadgeCount,
      child: screens[_index],
    );
  }
}
