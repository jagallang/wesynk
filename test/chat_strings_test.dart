import 'package:flutter_test/flutter_test.dart';
import 'package:wesync_chat/wesync_chat.dart';

void main() {
  group('CS (ChatStrings)', () {
    group('Korean mode', () {
      setUp(() => CS.isKo = true);

      test('chatTitle returns 우리', () {
        expect(CS.chatTitle, '우리');
      });

      test('chatEmpty returns Korean', () {
        expect(CS.chatEmpty, '아직 대화가 없어요');
      });

      test('chatInput returns Korean', () {
        expect(CS.chatInput, '메시지 입력...');
      });

      test('settings returns Korean', () {
        expect(CS.settings, '채팅 설정');
      });

      test('daysAfter formats correctly', () {
        expect(CS.daysAfter(3), '3일 후');
      });

      test('hoursAfter formats correctly', () {
        expect(CS.hoursAfter(2), '2시간 후');
      });

      test('minutesAfter formats correctly', () {
        expect(CS.minutesAfter(10), '10분 후');
      });

      test('lifetimeLabels has 8 items in Korean', () {
        expect(CS.lifetimeLabels.length, 8);
        expect(CS.lifetimeLabels.first, '1분');
      });

      test('fontSizeLabels has 3 items in Korean', () {
        expect(CS.fontSizeLabels.length, 3);
        expect(CS.fontSizeLabels, ['작게', '보통', '크게']);
      });
    });

    group('English mode', () {
      setUp(() => CS.isKo = false);
      tearDown(() => CS.isKo = true);

      test('chatTitle returns Us', () {
        expect(CS.chatTitle, 'Us');
      });

      test('chatEmpty returns English', () {
        expect(CS.chatEmpty, 'No messages yet');
      });

      test('chatInput returns English', () {
        expect(CS.chatInput, 'Type a message...');
      });

      test('settings returns English', () {
        expect(CS.settings, 'Chat Settings');
      });

      test('daysAfter formats correctly', () {
        expect(CS.daysAfter(3), 'in 3d');
      });

      test('hoursAfter formats correctly', () {
        expect(CS.hoursAfter(2), 'in 2h');
      });

      test('lifetimeLabels has 8 items in English', () {
        expect(CS.lifetimeLabels.length, 8);
        expect(CS.lifetimeLabels.first, '1m');
      });

      test('fontSizeLabels has 3 items in English', () {
        expect(CS.fontSizeLabels, ['Small', 'Medium', 'Large']);
      });
    });

    group('ephemeral strings', () {
      setUp(() => CS.isKo = true);

      test('ephemeralHint includes time', () {
        expect(CS.ephemeralHint('5분'), '5분 후 사라질 메시지');
      });

      test('ephemeralTooltip includes time', () {
        expect(CS.ephemeralTooltip('10분'), '10분 휘발 (탭하면 해제)');
      });

      test('defaultEphemeralOn includes time', () {
        expect(CS.defaultEphemeralOn('1시간'), '모든 메시지가 1시간 후 사라짐');
      });
    });
  });
}
