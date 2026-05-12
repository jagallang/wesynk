import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;

// ─── CalendarEvent 모델 ───

class CalendarEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
  });
}

// ─── GoogleCalendarService ───

class GoogleCalendarService {
  final Map<String, String> _authHeaders;

  GoogleCalendarService(this._authHeaders);

  /// 특정 기간의 Google Calendar 이벤트 조회
  Future<List<CalendarEvent>> fetchEvents(DateTime start, DateTime end) async {
    try {
      final client = _AuthenticatedClient(_authHeaders);
      final calApi = gcal.CalendarApi(client);

      final events = await calApi.events.list(
        'primary',
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 100,
      );

      final results = <CalendarEvent>[];
      for (final event in events.items ?? []) {
        final title = event.summary ?? '(제목 없음)';
        final isAllDay = event.start?.date != null;

        DateTime startTime;
        DateTime endTime;

        if (isAllDay) {
          startTime = event.start!.date!;
          endTime = event.end?.date ?? startTime;
        } else {
          startTime = event.start?.dateTime?.toLocal() ?? start;
          endTime = event.end?.dateTime?.toLocal() ?? startTime;
        }

        results.add(CalendarEvent(
          id: event.id ?? '',
          title: title,
          startTime: startTime,
          endTime: endTime,
          isAllDay: isAllDay,
        ));
      }

      debugPrint('[GoogleCalendar] fetched ${results.length} events');
      return results;
    } catch (e) {
      debugPrint('[GoogleCalendar] fetch error: $e');
      return [];
    }
  }

  /// 특정 날짜의 이벤트만
  Future<List<CalendarEvent>> eventsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return fetchEvents(start, end);
  }

  /// 월간 이벤트 수 (캘린더 dot용)
  Future<Map<String, int>> monthlyEventCounts(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    final events = await fetchEvents(start, end);

    final counts = <String, int>{};
    for (final e in events) {
      final key =
          '${e.startTime.year}-${e.startTime.month.toString().padLeft(2, '0')}-${e.startTime.day.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}

/// Google auth headers를 사용하는 HTTP 클라이언트
class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
