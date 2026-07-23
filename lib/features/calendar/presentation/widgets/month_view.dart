import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/date_x.dart';
import '../../../../core/utils/haptics.dart';
import '../../domain/calendar_event.dart';
import '../../domain/month_grid.dart';
import '../providers/calendar_providers.dart';

/// A swipeable month grid with its own header. Swiping horizontally pages
/// between months; tapping a day selects it. Kept light: each page is a plain
/// [GridView] of cheap cells.
class MonthView extends ConsumerStatefulWidget {
  const MonthView({super.key, required this.system});

  final CalendarSystem system;

  @override
  ConsumerState<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<MonthView> {
  static const int _initialPage = 1200;
  late final DateTime _base = DateX.dayOnly(DateTime.now());
  final PageController _controller = PageController(initialPage: _initialPage);
  int _page = _initialPage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _anchorFor(int page) =>
      stepMonths(_base, page - _initialPage, widget.system);

  void _goToday() {
    Haptics.light();
    ref.read(selectedDayProvider.notifier).state = _base;
    _controller.animateToPage(_initialPage,
        duration: AppMotion.medium, curve: AppMotion.enter);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime selected = ref.watch(selectedDayProvider);
    final Map<int, List<CalendarEvent>> byDay = ref.watch(monthEventsProvider).maybeWhen(
        data: (Map<int, List<CalendarEvent>> d) => d,
        orElse: () => const <int, List<CalendarEvent>>{});

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.sm, AppSpacing.xs),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DateX.monthTitle(_anchorFor(_page), widget.system),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton(onPressed: _goToday, child: const Text('Today')),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _controller.previousPage(
                    duration: AppMotion.medium, curve: AppMotion.enter),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _controller.nextPage(
                    duration: AppMotion.medium, curve: AppMotion.enter),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (int page) {
              Haptics.selection();
              setState(() => _page = page);
              ref.read(focusedMonthProvider.notifier).state = _anchorFor(page);
            },
            itemBuilder: (BuildContext context, int page) {
              final MonthGrid grid =
                  buildMonthGrid(_anchorFor(page), widget.system);
              return _MonthPage(
                grid: grid,
                selected: selected,
                eventsByDay: byDay,
                onSelect: (DateTime day) {
                  Haptics.selection();
                  ref.read(selectedDayProvider.notifier).state = day;
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthPage extends StatelessWidget {
  const _MonthPage({
    required this.grid,
    required this.selected,
    required this.eventsByDay,
    required this.onSelect,
  });

  final MonthGrid grid;
  final DateTime selected;
  final Map<int, List<CalendarEvent>> eventsByDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              for (final String label in grid.weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.82,
              ),
              itemCount: grid.cells.length,
              itemBuilder: (BuildContext context, int i) {
                final DateTime? day = grid.cells[i];
                if (day == null) return const SizedBox.shrink();
                final List<CalendarEvent> dayEvents =
                    eventsByDay[DateX.dayKey(day)] ?? const <CalendarEvent>[];
                return _DayCell(
                  label: grid.dayLabel(day),
                  isToday: DateX.isToday(day),
                  isSelected: DateX.isSameDay(day, selected),
                  events: dayEvents,
                  onTap: () => onSelect(day),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.isToday,
    required this.isSelected,
    required this.events,
    required this.onTap,
  });

  final String label;
  final bool isToday;
  final bool isSelected;
  final List<CalendarEvent> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color? fill = isSelected ? theme.colorScheme.primary : null;
    final Color textColor = isSelected
        ? theme.colorScheme.onPrimary
        : isToday
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: isToday && !isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 1.4)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight:
                      isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              _Dots(events: events, selected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.events, required this.selected});
  final List<CalendarEvent> events;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox(height: 6);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int count = events.length.clamp(0, 3);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? scheme.onPrimary
                  : (events[i].color != null
                      ? Color(events[i].color!)
                      : scheme.primary),
            ),
          ),
      ],
    );
  }
}
