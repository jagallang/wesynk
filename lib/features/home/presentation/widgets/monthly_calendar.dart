import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/home_providers.dart';

class MonthlyCalendar extends ConsumerStatefulWidget {
  const MonthlyCalendar({super.key});

  @override
  ConsumerState<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends ConsumerState<MonthlyCalendar> {
  DateTime _focusedMonth = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDateProvider);
    final eventCountsAsync = ref.watch(eventCountByDateProvider(_focusedMonth));
    final eventCounts = eventCountsAsync.valueOrNull ?? {};

    return Column(
      children: [
        TableCalendar(
          locale: S.isKo ? 'ko_KR' : 'en_US',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focusedMonth,
          selectedDayPredicate: (d) => isSameDay(d, selectedDay),
          calendarFormat: _calendarFormat,
          availableCalendarFormats: {
            CalendarFormat.month: S.calendarMonth,
            CalendarFormat.week: S.calendarWeek,
          },
          startingDayOfWeek: StartingDayOfWeek.sunday,
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
          ),
          eventLoader: (day) {
            final cnt = eventCounts[_dateKey(day)] ?? 0;
            return List.filled(cnt.clamp(0, 3), 'event');
          },
          onDaySelected: (selected, focused) {
            ref.read(selectedDateProvider.notifier).state = selected;
            setState(() => _focusedMonth = focused);
          },
          onPageChanged: (focused) {
            setState(() => _focusedMonth = focused);
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            markerSize: 5,
            markersMaxCount: 3,
            markerDecoration: const BoxDecoration(
              color: AppColors.marker,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.today.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(
              color: AppColors.today,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppColors.selected,
              shape: BoxShape.circle,
            ),
          ),
        ),

        // 접기/펼치기 핸들
        GestureDetector(
          onTap: () {
            setState(() {
              _calendarFormat = _calendarFormat == CalendarFormat.month
                  ? CalendarFormat.week
                  : CalendarFormat.month;
            });
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            setState(() {
              if (details.primaryVelocity! < 0) {
                _calendarFormat = CalendarFormat.week;
              } else {
                _calendarFormat = CalendarFormat.month;
              }
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.transparent,
            child: Center(
              child: AnimatedRotation(
                turns: _calendarFormat == CalendarFormat.month ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  size: 20,
                  color: AppColors.textHint,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
