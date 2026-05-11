import 'package:flutter/material.dart';

enum ItemType { event, note, photo, date }

extension ItemTypeExt on ItemType {
  String get label => switch (this) {
        ItemType.event => '일정',
        ItemType.note => '메모',
        ItemType.photo => '사진',
        ItemType.date => '데이트',
      };

  IconData get icon => switch (this) {
        ItemType.event => Icons.event,
        ItemType.note => Icons.note_alt_outlined,
        ItemType.photo => Icons.photo_outlined,
        ItemType.date => Icons.favorite_outline,
      };
}

const tabOrder = [
  ItemType.event,
  ItemType.date,
  ItemType.note,
  ItemType.photo,
];

class Item {
  final String id;
  final ItemType type;
  final String date; // "YYYY-MM-DD"
  final String createdBy;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  const Item({
    required this.id,
    required this.type,
    required this.date,
    required this.createdBy,
    required this.createdAt,
    required this.payload,
  });
}
