import 'package:flutter/material.dart';
import '../../../../shared/models/item_model.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final payload = item.payload;
    return Card(
      child: switch (item.type) {
        ItemType.event => ListTile(
            leading: const Icon(Icons.event),
            title: Text(payload['title']?.toString() ?? '(제목 없음)'),
            subtitle: Text(payload['location']?.toString() ?? ''),
          ),
        ItemType.note => ListTile(
            leading: Text(
              payload['mood']?.toString() ?? '📝',
              style: const TextStyle(fontSize: 20),
            ),
            title: Text(
              payload['body']?.toString() ?? '',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ItemType.photo => ListTile(
            leading: const Icon(Icons.photo),
            title: Text(payload['caption']?.toString() ?? '(설명 없음)'),
          ),
        ItemType.date => ListTile(
            leading: const Icon(Icons.favorite, color: Colors.pink),
            title: Text(payload['title']?.toString() ?? ''),
            subtitle: Text(
              '${(payload['place'] as Map?)?['name'] ?? ''} '
              '${'★' * ((payload['rating'] as int?) ?? 0)}',
            ),
          ),
      },
    );
  }
}
