import 'package:flutter_test/flutter_test.dart';
import 'package:wesynk/core/services/photo_service.dart';

void main() {
  group('PhotoItem', () {
    test('isVideo returns true for video mimeType', () {
      final photo = PhotoItem(
        id: '1',
        storagePath: 'couples/c1/photos/original/vid.mp4',
        mimeType: 'video/mp4',
        uploadedAt: DateTime.now(),
        byteSize: 1000,
        date: '2026-05-17',
      );
      expect(photo.isVideo, isTrue);
    });

    test('isVideo returns false for image mimeType', () {
      final photo = PhotoItem(
        id: '2',
        storagePath: 'couples/c1/photos/original/pic.jpg',
        mimeType: 'image/jpeg',
        uploadedAt: DateTime.now(),
        byteSize: 500,
        date: '2026-05-17',
      );
      expect(photo.isVideo, isFalse);
    });

    test('thumbnailPath generates correct path', () {
      final photo = PhotoItem(
        id: '3',
        storagePath: 'couples/c1/photos/original/abc.jpg',
        mimeType: 'image/jpeg',
        uploadedAt: DateTime.now(),
        byteSize: 100,
        date: '2026-05-17',
      );
      expect(
        photo.thumbnailPath(400),
        'couples/c1/photos/thumb_400/abc_400x400.jpg',
      );
    });

    test('thumbnailPath works for video', () {
      final photo = PhotoItem(
        id: '4',
        storagePath: 'couples/c1/photos/original/vid.mp4',
        mimeType: 'video/mp4',
        uploadedAt: DateTime.now(),
        byteSize: 5000,
        date: '2026-05-17',
      );
      expect(
        photo.thumbnailPath(400),
        'couples/c1/photos/thumb_400/vid_400x400.mp4',
      );
    });
  });

  group('PhotoItemDisplay extension', () {
    test('displayDate returns takenAt if available', () {
      final takenAt = DateTime(2025, 12, 25);
      final photo = PhotoItem(
        id: '5',
        storagePath: 'path',
        mimeType: 'image/jpeg',
        takenAt: takenAt,
        uploadedAt: DateTime(2026, 1, 1),
        byteSize: 100,
        date: '2026-01-01',
      );
      expect(photo.displayDate, takenAt);
    });

    test('displayDate falls back to uploadedAt if takenAt is null', () {
      final uploadedAt = DateTime(2026, 3, 15);
      final photo = PhotoItem(
        id: '6',
        storagePath: 'path',
        mimeType: 'image/jpeg',
        uploadedAt: uploadedAt,
        byteSize: 100,
        date: '2026-03-15',
      );
      expect(photo.displayDate, uploadedAt);
    });

    test('displayDateKey strips time component', () {
      final photo = PhotoItem(
        id: '7',
        storagePath: 'path',
        mimeType: 'image/jpeg',
        uploadedAt: DateTime(2026, 5, 17, 14, 30, 45),
        byteSize: 100,
        date: '2026-05-17',
      );
      expect(photo.displayDateKey, DateTime(2026, 5, 17));
    });
  });
}
