import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';

class AlbumPage extends StatelessWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Text(
                  S.albumTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(S.albumEmpty,
                      style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
