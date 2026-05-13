import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_strings.dart';
import 'package:wesync_chat/wesync_chat.dart';
import '../../../../shared/models/item_model.dart';
import '../../../album/presentation/pages/album_page.dart';
import '../../../security/presentation/pages/pin_screen.dart';
import '../../../security/presentation/providers/security_provider.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../providers/home_providers.dart';
import '../providers/photo_providers.dart';
import '../widgets/day_tab_content.dart';
import '../widgets/item_form_sheets.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabOrder.length, vsync: this);
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

  void _onTabSelected(int i) {
    final security = ref.read(securityProvider);

    if (security.pinEnabled && security.lockOnTabSwitch && i != _navIndex) {
      Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PinScreen(
            mode: PinMode.confirm,
            onSuccess: () {
              Navigator.of(context).pop();
              setState(() => _navIndex = i);
              _lastActivity = DateTime.now();
            },
          ),
        ),
      );
    } else {
      setState(() => _navIndex = i);
      _lastActivity = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupleId = ref.watch(coupleIdProvider);

    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _CalendarView(tabController: _tabController, onAdd: _onAddPressed),
          _ChatTab(
            coupleId: coupleId,
            onPickPhoto: () => _pickPhotoForChat(),
          ),
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
        onDestinationSelected: _onTabSelected,
      ),
    );
  }

  void _onAddPressed(ItemType type) {
    final selectedDate = ref.read(selectedDateProvider);
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);

    switch (type) {
      case ItemType.event:
        showEventForm(context, dateKey, _addItem);
      case ItemType.note:
        showNoteForm(context, dateKey, _addItem);
      case ItemType.photo:
        _uploadPhoto();
      case ItemType.date:
        showDateForm(context, dateKey, _addItem);
    }
  }

  void _addItem(Item item) {
    final coupleId = ref.read(coupleIdProvider);
    if (coupleId.isEmpty) return;
    ref.read(firestoreServiceProvider).addItem(
          coupleId: coupleId,
          item: item,
        );
  }

  Future<void> _uploadPhoto() async {
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

/// coupleId가 비어있으면 로딩, 있으면 ChatScreen 표시
class _ChatTab extends StatelessWidget {
  final String coupleId;
  final Future<String?> Function() onPickPhoto;

  const _ChatTab({required this.coupleId, required this.onPickPhoto});

  @override
  Widget build(BuildContext context) {
    if (coupleId.isEmpty) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    return ChatScreen(
      coupleId: coupleId,
      myUid: FirebaseAuth.instance.currentUser?.uid ?? '',
      onPickPhoto: onPickPhoto,
    );
  }
}
