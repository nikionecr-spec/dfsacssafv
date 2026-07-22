import 'dart:ui';

import 'package:flutter/material.dart';

import '../../features/calendar/presentation/calendar_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/notes/presentation/notes_page.dart';
import '../../features/pomodoro/presentation/pomodoro_page.dart';
import '../../features/tasks/presentation/tasks_page.dart';
import '../theme/app_dimens.dart';
import '../utils/haptics.dart';

/// The primary navigation shell.
///
/// Uses an [IndexedStack] so each tab keeps its state (scroll position, an
/// in-progress note, the running timer) instead of being rebuilt from scratch
/// on every switch — which also avoids janky re-layouts.
class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  static const List<_Destination> _destinations = <_Destination>[
    _Destination(Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home'),
    _Destination(Icons.sticky_note_2_rounded, Icons.sticky_note_2_outlined, 'Notes'),
    _Destination(Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Calendar'),
    _Destination(Icons.checklist_rounded, Icons.checklist_outlined, 'Tasks'),
    _Destination(Icons.timer_rounded, Icons.timer_outlined, 'Focus'),
  ];

  final List<Widget> _pages = const <Widget>[
    DashboardPage(),
    NotesPage(),
    CalendarPage(),
    TasksPage(),
    PomodoroPage(),
  ];

  void _select(int i) {
    if (i == _index) return;
    Haptics.selection();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _GlassNavBar(
        index: _index,
        destinations: _destinations,
        onSelected: _select,
      ),
    );
  }
}

class _Destination {
  const _Destination(this.selectedIcon, this.icon, this.label);
  final IconData selectedIcon;
  final IconData icon;
  final String label;
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.index,
    required this.destinations,
    required this.onSelected,
  });

  final int index;
  final List<_Destination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh
                    .withValues(alpha: isDark ? 0.55 : 0.75),
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.5),
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    for (int i = 0; i < destinations.length; i++)
                      _NavItem(
                        destination: destinations[i],
                        selected: i == index,
                        onTap: () => onSelected(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 24,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              if (selected) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  destination.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
