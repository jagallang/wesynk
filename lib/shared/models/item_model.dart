import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';

enum ItemType { event, note, photo, date }

extension ItemTypeExt on ItemType {
  String get label => switch (this) {
        ItemType.event => S.tabTravel,
        ItemType.note => S.tabNote,
        ItemType.photo => S.tabPhoto,
        ItemType.date => S.tabFood,
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
  final String date;
  final String createdBy;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final bool checked;
  final DateTime? deletedAt;

  const Item({
    required this.id,
    required this.type,
    required this.date,
    required this.createdBy,
    required this.createdAt,
    required this.payload,
    this.checked = false,
    this.deletedAt,
  });

  factory Item.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Item(
      id: doc.id,
      type: ItemType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => ItemType.note,
      ),
      date: d['date'] as String? ?? '',
      createdBy: d['createdBy'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      payload: Map<String, dynamic>.from(d['payload'] as Map? ?? {}),
      checked: d['checked'] as bool? ?? false,
      deletedAt: (d['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'date': date,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'payload': payload,
      'deletedAt': null,
    };
  }
}
