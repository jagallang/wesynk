import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/item_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../providers/home_providers.dart';
import 'item_card.dart';

class DayTabContent extends ConsumerWidget {
  final ItemType type;
  const DayTabContent({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateKey = ref.watch(selectedDateKeyProvider);
    final items = ref.watch(
      itemsForDateAndTypeProvider((dateKey: dateKey, type: type)),
    );

    if (items.isEmpty) return EmptyState(type: type);

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => ItemCard(item: items[i]),
    );
  }
}
