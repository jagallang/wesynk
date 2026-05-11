import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
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
            S.noItemForDay(type.label),
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            S.addWithButton,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
