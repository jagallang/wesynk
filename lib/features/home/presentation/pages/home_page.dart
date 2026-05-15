import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_strings.dart';
import 'package:wesync_chat/wesync_chat.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/item_model.dart';
import '../../../album/presentation/pages/album_page.dart';
import '../../../security/presentation/pages/pin_screen.dart';
import '../../../security/presentation/providers/security_provider.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../providers/home_providers.dart';
import '../providers/photo_providers.dart';
import '../widgets/day_tab_content.dart';
import '../widgets/monthly_calendar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  int _navIndex = 0;
  DateTime _lastActivity = DateTime.now();
  DateTime? _chatClearBefore;

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabOrder.length, vsync: this);
    _loadChatClearedAt();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAutoLock();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lastActivity = DateTime.now();
    }
  }

  void _checkAutoLock() {
    final security = ref.read(securityProvider);
    if (!security.pinEnabled) return;
    if (security.autoLockDuration == AutoLockDuration.off) return;

    final elapsed = DateTime.now().difference(_lastActivity).inSeconds;
    if (elapsed >= security.autoLockDuration.seconds) {
      ref.read(isUnlockedProvider.notifier).state = false;
    }
  }

  void _onTabSelected(int i) async {
    final security = ref.read(securityProvider);

    if (security.pinEnabled && security.lockOnTabSwitch && i != _navIndex) {
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PinScreen(
            mode: PinMode.confirm,
            onSuccess: () {
              _lastActivity = DateTime.now();
            },
          ),
        ),
      );
      if (success == true && mounted) {
        setState(() => _navIndex = i);
      }
    } else {
      setState(() => _navIndex = i);
      _lastActivity = DateTime.now();
    }
  }

  Future<void> _loadChatClearedAt() async {
    final service = ref.read(firestoreServiceProvider);
    final cleared = await service.getChatClearedAt(
        ref.read(coupleIdProvider));
    if (cleared != null && mounted) {
      setState(() => _chatClearBefore = cleared);
    }
  }

  void _onChatCleared(DateTime clearedAt) {
    setState(() => _chatClearBefore = clearedAt);
    ref.read(firestoreServiceProvider).saveChatClearedAt(
        ref.read(coupleIdProvider), clearedAt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _CalendarView(tabController: _tabController, onAdd: _onAddPressed),
          ChatScreen(
            coupleId: ref.read(coupleIdProvider),
            myUid: _myUid,
            onPickPhoto: () => _pickPhotoForChat(),
            onOpenAppSettings: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            initialClearBefore: _chatClearBefore,
            onClearChat: _onChatCleared,
          ),
          const AlbumPage(),
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
        ],
        onDestinationSelected: _onTabSelected,
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
          coupleId: ref.read(coupleIdProvider),
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
                  createdBy: _myUid,
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

  static const _noteTags = [
    ('📚', '독서', 'Reading'),
    ('🎵', '음악', 'Music'),
    ('💡', '관심사', 'Interests'),
    ('🎬', '영화', 'Movies'),
    ('✈️', '여행', 'Travel'),
    ('💭', '일상', 'Daily'),
  ];

  void _showNoteForm(String dateKey) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String selectedMood = '😊';
    int selectedTag = 5; // 기본: 💭 일상
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
              const SizedBox(height: 12),

              // 태그 선택
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_noteTags.length, (i) {
                  final (emoji, ko, en) = _noteTags[i];
                  final selected = i == selectedTag;
                  return ChoiceChip(
                    label: Text('$emoji ${S.isKo ? ko : en}',
                        style: const TextStyle(fontSize: 13)),
                    selected: selected,
                    onSelected: (_) => setSheetState(() => selectedTag = i),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // 감정 이모지
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

              // 제목
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: S.isKo ? '제목' : 'Title',
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),

              // 본문
              TextField(
                controller: bodyCtrl,
                decoration: InputDecoration(
                  hintText: S.noteHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: null,
                minLines: 4,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final (tagEmoji, tagKo, tagEn) = _noteTags[selectedTag];
                  _addItem(Item(
                    id: const Uuid().v4(),
                    type: ItemType.note,
                    date: dateKey,
                    createdBy: _myUid,
                    createdAt: DateTime.now(),
                    payload: {
                      'title': titleCtrl.text.trim(),
                      'body': bodyCtrl.text.trim(),
                      'mood': selectedMood,
                      'tag': tagEmoji,
                      'tagName': S.isKo ? tagKo : tagEn,
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

  Future<void> _showPhotoPlaceholder(String dateKey) async {
    try {
      final service = ref.read(photoServiceProvider);
      final results = await service.pickAndUpload();
      if (results.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.isKo
                ? '${results.length}장 업로드 완료'
                : '${results.length} photos uploaded'),
          ),
        );
      }
    } catch (e) {
      debugPrint('[HomePage] photo upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// 채팅에서 사진 선택 → 앨범 업로드 → URL 반환
  Future<String?> _pickPhotoForChat() async {
    try {
      final service = ref.read(photoServiceProvider);
      final results = await service.pickAndUpload();
      if (results.isEmpty) return null;
      final photo = results.first;
      final url = await service.originalUrl(photo);
      return url;
    } catch (e) {
      debugPrint('[HomePage] chat photo error: $e');
      return null;
    }
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
                    createdBy: _myUid,
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
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsPage()),
                    ),
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
                _CountTab(type: t, dateKey: ref.watch(selectedDateKeyProvider)),
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

class _CountTab extends ConsumerWidget {
  final ItemType type;
  final String dateKey;

  const _CountTab({required this.type, required this.dateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int count = 0;

    if (type == ItemType.photo) {
      final photosAsync = ref.watch(photosByDateProvider(dateKey));
      count = photosAsync.valueOrNull?.length ?? 0;
    } else {
      final itemsAsync = ref.watch(
        itemsForDateAndTypeProvider((dateKey: dateKey, type: type)),
      );
      count = itemsAsync.valueOrNull?.length ?? 0;
    }

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 18),
          const SizedBox(width: 4),
          Text(type.label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                    fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
