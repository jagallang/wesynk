import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/firestore_service.dart';
import 'package:wesync_chat/wesync_chat.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/item_model.dart';
import '../../../album/presentation/pages/album_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../providers/home_providers.dart';
import '../widgets/day_tab_content.dart';
import '../widgets/monthly_calendar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabOrder.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _CalendarView(tabController: _tabController, onAdd: _onAddPressed),
          const ChatScreen(coupleId: 'default-couple', myUid: 'me'),
          const AlbumPage(),
          const SettingsPage(),
        ],
      ),
      floatingActionButton: _navIndex == 0
          ? ListenableBuilder(
              listenable: _tabController,
              builder: (context, _) {
                final currentType = tabOrder[_tabController.index];
                return FloatingActionButton.extended(
                  onPressed: () => _onAddPressed(currentType),
                  icon: const Icon(Icons.add),
                  label: Text(S.addTitle(currentType.label)),
                );
              },
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.calendar_month), label: S.navCalendar),
          NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline), label: S.navChat),
          NavigationDestination(
              icon: const Icon(Icons.photo_library), label: S.navAlbum),
          NavigationDestination(
              icon: const Icon(Icons.settings), label: S.navSettings),
        ],
        onDestinationSelected: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  void _onAddPressed(ItemType type) {
    final selectedDate = ref.read(selectedDateProvider);
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    switch (type) {
      case ItemType.event:
        _showEventForm(dateKey);
      case ItemType.note:
        _showNoteForm(dateKey);
      case ItemType.photo:
        _showPhotoPlaceholder(dateKey);
      case ItemType.date:
        _showDateForm(dateKey);
    }
  }

  void _addItem(Item item) {
    ref.read(firestoreServiceProvider).addItem(
          coupleId: FirestoreService.defaultCoupleId,
          item: item,
        );
  }

  void _showEventForm(String dateKey) {
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(S.addTitle(S.tabTravel),
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: S.fieldTitle,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationCtrl,
              decoration: InputDecoration(
                labelText: S.fieldLocation,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                _addItem(Item(
                  id: const Uuid().v4(),
                  type: ItemType.event,
                  date: dateKey,
                  createdBy: 'me',
                  createdAt: DateTime.now(),
                  payload: {
                    'title': titleCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'startAt': DateTime.now().toIso8601String(),
                    'allDay': false,
                  },
                ));
                Navigator.pop(ctx);
              },
              child: Text(S.add),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteForm(String dateKey) {
    final bodyCtrl = TextEditingController();
    String selectedMood = '😊';
    final moods = ['😊', '😍', '😢', '😡', '🥺', '🎬', '📝', '🌸'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(S.noteAdd, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: moods
                    .map((m) => GestureDetector(
                          onTap: () => setSheetState(() => selectedMood = m),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: selectedMood == m
                                  ? AppColors.primaryLight
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                Text(m, style: const TextStyle(fontSize: 24)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                decoration: InputDecoration(
                  hintText: S.noteHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (bodyCtrl.text.trim().isEmpty) return;
                  _addItem(Item(
                    id: const Uuid().v4(),
                    type: ItemType.note,
                    date: dateKey,
                    createdBy: 'me',
                    createdAt: DateTime.now(),
                    payload: {
                      'body': bodyCtrl.text.trim(),
                      'mood': selectedMood,
                    },
                  ));
                  Navigator.pop(ctx);
                },
                child: Text(S.add),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoPlaceholder(String dateKey) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.photoPlaceholder)),
    );
  }

  void _showDateForm(String dateKey) {
    final titleCtrl = TextEditingController();
    final placeCtrl = TextEditingController();
    final reviewCtrl = TextEditingController();
    int rating = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(S.dateRecord, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: S.fieldTitle,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: placeCtrl,
                decoration: InputDecoration(
                  labelText: S.fieldPlace,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(S.fieldRating),
                  ...List.generate(5, (i) {
                    return IconButton(
                      icon: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setSheetState(() => rating = i + 1),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewCtrl,
                decoration: InputDecoration(
                  hintText: S.fieldReview,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  _addItem(Item(
                    id: const Uuid().v4(),
                    type: ItemType.date,
                    date: dateKey,
                    createdBy: 'me',
                    createdAt: DateTime.now(),
                    payload: {
                      'title': titleCtrl.text.trim(),
                      'place': {'name': placeCtrl.text.trim()},
                      'rating': rating,
                      'review': reviewCtrl.text.trim(),
                    },
                  ));
                  Navigator.pop(ctx);
                },
                child: Text(S.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarView extends ConsumerWidget {
  final TabController tabController;
  final void Function(ItemType) onAdd;

  const _CalendarView({required this.tabController, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDateProvider);
    final locale = S.isKo ? 'ko_KR' : 'en_US';
    final headerFmt = S.isKo
        ? DateFormat('M월 d일 (E)', locale)
        : DateFormat('MMM d (E)', locale);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Builder(builder: (context) {
              final customization = ref.watch(appCustomizationProvider);
              return Row(
                children: [
                  Icon(customization.appIcon,
                      color: customization.themeColor, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    customization.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: customization.themeColor,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                ],
              );
            }),
          ),
          const MonthlyCalendar(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(headerFmt.format(selectedDay),
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          TabBar(
            controller: tabController,
            tabs: [
              for (final t in tabOrder)
                Tab(icon: Icon(t.icon, size: 18), text: t.label),
            ],
            labelStyle: const TextStyle(fontSize: 12),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                for (final type in tabOrder) DayTabContent(type: type),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
