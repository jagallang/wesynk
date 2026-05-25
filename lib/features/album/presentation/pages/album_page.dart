import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/photo_service.dart';
import '../../../home/presentation/providers/photo_providers.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../widgets/video_player_factory.dart';

class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({super.key});

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  bool _selectMode = false;
  final Set<String> _selected = {};

  void _toggleSelect(String photoId) {
    setState(() {
      if (_selected.contains(photoId)) {
        _selected.remove(photoId);
        if (_selected.isEmpty) _selectMode = false;
      } else {
        _selected.add(photoId);
      }
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  void _enterSelectMode() {
    setState(() => _selectMode = true);
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.delete),
        content: Text(S.isKo
            ? '$count장을 삭제하시겠습니까?'
            : 'Delete $count photos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(S.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final service = ref.read(photoServiceProvider);
    for (final id in _selected) {
      await service.moveToTrash(id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.isKo
              ? '$count장 삭제됨'
              : '$count photos deleted'),
        ),
      );
    }
    _exitSelectMode();
  }

  Future<void> _uploadPhotos() async {
    try {
      final service = ref.read(photoServiceProvider);
      debugPrint('[Album] starting pickAndUpload...');
      final results = await service.pickAndUpload(
        onProgress: (done, total) {
          debugPrint('[Album] uploading $done/$total');
        },
      );
      debugPrint('[Album] upload done: ${results.length} photos');
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
      debugPrint('[Album] upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(allPhotosProvider);
    final photoService = ref.read(photoServiceProvider);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                if (_selectMode) ...[
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _exitSelectMode,
                  ),
                  Text(
                    S.isKo
                        ? '${_selected.length}장 선택'
                        : '${_selected.length} selected',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _selected.isEmpty ? null : _deleteSelected,
                  ),
                ] else ...[
                  Text(S.albumTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _enterSelectMode,
                    tooltip: S.isKo ? '사진 삭제' : 'Delete photos',
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    onPressed: _uploadPhotos,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SettingsPage()),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: photosAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('${S.error}: $e',
                    style: const TextStyle(color: Colors.grey)),
              ),
              data: (photos) {
                if (photos.isEmpty) {
                  return _EmptyAlbum(onUpload: _uploadPhotos);
                }
                return _GroupedPhotoGrid(
                  photos: photos,
                  photoService: photoService,
                  selectMode: _selectMode,
                  selected: _selected,
                  onToggleSelect: _toggleSelect,
                  onEnterSelectMode: _enterSelectMode,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 빈 앨범 ───

class _EmptyAlbum extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyAlbum({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(S.albumEmpty,
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(S.isKo ? '사진 추가' : 'Add Photos'),
          ),
        ],
      ),
    );
  }
}

// ─── 날짜별 그룹화 그리드 ───

class _GroupedPhotoGrid extends StatelessWidget {
  final List<PhotoItem> photos;
  final PhotoService photoService;
  final bool selectMode;
  final Set<String> selected;
  final ValueChanged<String> onToggleSelect;
  final VoidCallback onEnterSelectMode;

  const _GroupedPhotoGrid({
    required this.photos,
    required this.photoService,
    required this.selectMode,
    required this.selected,
    required this.onToggleSelect,
    required this.onEnterSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...photos]
      ..sort((a, b) => b.displayDate.compareTo(a.displayDate));

    final grouped = <DateTime, List<PhotoItem>>{};
    for (final p in sorted) {
      final key = p.displayDateKey;
      grouped.putIfAbsent(key, () => []).add(p);
    }

    return CustomScrollView(
      slivers: [
        for (final entry in grouped.entries) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                _formatDateHeader(entry.key),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final photo = entry.value[index];
                  final isSelected = selected.contains(photo.id);
                  return GestureDetector(
                    onTap: () {
                      if (selectMode) {
                        onToggleSelect(photo.id);
                      } else {
                        _showDetail(context, photo);
                      }
                    },
                    onLongPress: () {
                      if (!selectMode) {
                        onEnterSelectMode();
                        onToggleSelect(photo.id);
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _PhotoThumb(
                            photo: photo, photoService: photoService),
                        if (photo.isVideo)
                          const Center(
                            child: Icon(Icons.play_circle_fill,
                                size: 36, color: Colors.white70),
                          ),
                        if (selectMode)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.black38,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : null,
                            ),
                          ),
                        if (isSelected)
                          Container(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                      ],
                    ),
                  );
                },
                childCount: entry.value.length,
              ),
            ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return S.isKo ? '오늘' : 'Today';
    if (date == yesterday) return S.isKo ? '어제' : 'Yesterday';

    final locale = S.isKo ? 'ko_KR' : 'en_US';
    final isThisYear = date.year == now.year;
    final fmt = S.isKo
        ? (isThisYear
            ? DateFormat('M월 d일 (E)', locale)
            : DateFormat('yyyy년 M월 d일 (E)', locale))
        : (isThisYear
            ? DateFormat('MMM d (E)', locale)
            : DateFormat('MMM d, yyyy (E)', locale));
    return fmt.format(date);
  }

  void _showDetail(BuildContext context, PhotoItem photo) {
    final startIndex = photos.indexWhere((p) => p.id == photo.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(
          photos: photos,
          initialIndex: startIndex >= 0 ? startIndex : 0,
          photoService: photoService,
        ),
      ),
    );
  }
}

// ─── 썸네일 타일 ───

class _PhotoThumb extends StatefulWidget {
  final PhotoItem photo;
  final PhotoService photoService;

  const _PhotoThumb({required this.photo, required this.photoService});

  @override
  State<_PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends State<_PhotoThumb> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = _loadUrl();
  }

  @override
  void didUpdateWidget(_PhotoThumb old) {
    super.didUpdateWidget(old);
    if (old.photo.id != widget.photo.id) {
      _urlFuture = _loadUrl();
    }
  }

  /// 썸네일 URL 로드, 실패 시 원본 URL로 폴백
  Future<String> _loadUrl() async {
    try {
      return await widget.photoService.thumbnailUrl(widget.photo, size: 400);
    } catch (_) {
      return await widget.photoService.originalUrl(widget.photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photo.uploading) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    // 영상: 재생 아이콘 + 파일명 표시
    if (widget.photo.isVideo) {
      final fileName = widget.photo.storagePath.split('/').last;
      final title = fileName.length > 15
          ? '${fileName.substring(0, 12)}...'
          : fileName;
      return Container(
        color: Colors.grey.shade800,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_outline,
                  size: 36, color: Colors.white70),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snap) {
        if (snap.hasError) {
          return Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey));
        }
        if (!snap.hasData) {
          return Container(color: Colors.grey.shade200);
        }
        return CachedNetworkImage(
          imageUrl: snap.data!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.grey.shade200),
          errorWidget: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image)),
        );
      },
    );
  }
}

// ─── 풀스크린 사진 뷰어 ───

enum _MediaFilter { all, photo, video }

class _PhotoViewer extends StatefulWidget {
  final List<PhotoItem> photos;
  final int initialIndex;
  final PhotoService photoService;

  const _PhotoViewer({
    required this.photos,
    required this.initialIndex,
    required this.photoService,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late PageController _pageController;
  late List<PhotoItem> _filtered;
  _MediaFilter _filter = _MediaFilter.all;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _applyFilter(_MediaFilter.all, widget.initialIndex);
  }

  void _applyFilter(_MediaFilter filter, [int? jumpToOriginalIndex]) {
    final original = jumpToOriginalIndex != null
        ? widget.photos[jumpToOriginalIndex]
        : _filtered[_currentIndex];

    setState(() {
      _filter = filter;
      switch (filter) {
        case _MediaFilter.all:
          _filtered = widget.photos;
        case _MediaFilter.photo:
          _filtered = widget.photos.where((p) => !p.isVideo).toList();
        case _MediaFilter.video:
          _filtered = widget.photos.where((p) => p.isVideo).toList();
      }
      // 현재 보던 사진의 위치를 필터된 목록에서 찾기
      var idx = _filtered.indexWhere((p) => p.id == original.id);
      if (idx < 0) idx = 0;
      _currentIndex = idx;
      _pageController = PageController(initialPage: idx);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${_filtered.length}',
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          // 필터 버튼
          PopupMenuButton<_MediaFilter>(
            icon: Icon(
              _filter == _MediaFilter.all
                  ? Icons.filter_list
                  : (_filter == _MediaFilter.photo
                      ? Icons.photo
                      : Icons.videocam),
              color: Colors.white,
            ),
            onSelected: (f) => _applyFilter(f),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MediaFilter.all,
                child: Row(
                  children: [
                    Icon(Icons.photo_library,
                        color: _filter == _MediaFilter.all
                            ? theme.colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text(S.isKo ? '전체' : 'All'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _MediaFilter.photo,
                child: Row(
                  children: [
                    Icon(Icons.photo,
                        color: _filter == _MediaFilter.photo
                            ? theme.colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text(S.isKo ? '사진만' : 'Photos'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _MediaFilter.video,
                child: Row(
                  children: [
                    Icon(Icons.videocam,
                        color: _filter == _MediaFilter.video
                            ? theme.colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text(S.isKo ? '영상만' : 'Videos'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _filtered.isEmpty
          ? Center(
              child: Text(
                S.isKo ? '항목이 없습니다' : 'No items',
                style: const TextStyle(color: Colors.white54),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _filtered.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (context, index) {
                      final photo = _filtered[index];
                      return _MediaPage(
                        photo: photo,
                        photoService: widget.photoService,
                      );
                    },
                  ),
                ),
                // 하단 정보
                _buildBottomInfo(),
              ],
            ),
    );
  }

  Widget _buildBottomInfo() {
    if (_currentIndex >= _filtered.length) return const SizedBox.shrink();
    final photo = _filtered[_currentIndex];
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (photo.caption != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(photo.caption!,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          Text(
            photo.date,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MediaPage extends StatefulWidget {
  final PhotoItem photo;
  final PhotoService photoService;

  const _MediaPage({required this.photo, required this.photoService});

  @override
  State<_MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<_MediaPage> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = widget.photoService.originalUrl(widget.photo);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (widget.photo.isVideo) {
          return Center(child: buildVideoPlayer(snap.data!));
        }
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: snap.data!,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white54, size: 48),
            ),
          ),
        );
      },
    );
  }
}

