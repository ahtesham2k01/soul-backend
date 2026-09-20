import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import 'profile_repository.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({
    super.key,
    required this.repository,
  });

  final ProfileRepository repository;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends State<NotificationCenterScreen> {
  final List<MemberNotification> _items = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  final Set<String> _busy = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.notificationFeed();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _nextCursor = page.nextCursor;
        _loading = false;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (_loadingMore || cursor == null || cursor.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.repository.notificationFeed(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _markRead(MemberNotification item) async {
    if (!item.unread || _busy.contains(item.id)) return;
    setState(() => _busy.add(item.id));
    try {
      await widget.repository.markNotificationRead(item.id);
      if (!mounted) return;
      setState(() {
        _busy.remove(item.id);
        final index = _items.indexWhere((value) => value.id == item.id);
        if (index >= 0) {
          _items[index] = MemberNotification(
            id: item.id,
            type: item.type,
            data: item.data,
            createdAt: item.createdAt,
            readAt: DateTime.now().toUtc(),
          );
        }
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy.remove(item.id);
        _error = failure.message;
      });
    }
  }

  String _title(MemberNotification item) {
    final title = item.data['title']?.toString();
    if (title != null && title.trim().isNotEmpty) return title.trim();
    return item.type.replaceAll('_', ' ');
  }

  String _body(MemberNotification item) {
    for (final key in ['message', 'body', 'text']) {
      final value = item.data[key]?.toString();
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return 'Open SOUL to view this update.';
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);
    if (difference.inMinutes < 1) return 'Now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f7f4),
        appBar: AppBar(title: const Text('Notifications')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _items.isEmpty
                ? _NotificationError(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _items.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 160),
                              Icon(
                                Icons.notifications_none_rounded,
                                size: 58,
                                color: SoulColors.muted,
                              ),
                              SizedBox(height: 14),
                              Center(child: Text('No notifications yet')),
                            ],
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.extentAfter < 350) {
                                _loadMore();
                              }
                              return false;
                            },
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 30),
                              itemCount: _items.length +
                                  (_loadingMore && _nextCursor != null ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                if (index >= _items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(18),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                final item = _items[index];
                                return Material(
                                  color: item.unread
                                      ? SoulColors.limeLight
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => _markRead(item),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: item.unread
                                                ? Colors.black
                                                : SoulColors.softSurface,
                                            foregroundColor: item.unread
                                                ? SoulColors.limeLight
                                                : SoulColors.ink,
                                            child: const Icon(
                                              Icons.notifications_rounded,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        _title(item),
                                                        style: TextStyle(
                                                          color:
                                                              SoulColors.ink,
                                                          fontWeight: item.unread
                                                              ? FontWeight.w900
                                                              : FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      _time(item.createdAt),
                                                      style: const TextStyle(
                                                        color:
                                                            SoulColors.muted,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _body(item),
                                                  style: const TextStyle(
                                                    color: SoulColors.ink,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
      );
}

class _NotificationError extends StatelessWidget {
  const _NotificationError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}
