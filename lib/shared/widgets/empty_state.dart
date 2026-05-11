import 'package:flutter/material.dart';
import '../models/item_model.dart';

class EmptyState extends StatelessWidget {
  final ItemType type;
  const EmptyState({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type.icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            '이 날 ${type.label} 없음',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            '아래 + 버튼으로 추가',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
