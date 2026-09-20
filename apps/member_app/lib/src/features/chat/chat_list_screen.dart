import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import '../safety/safety_repository.dart';
import 'chat_repository.dart';
import 'chat_thread_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({
    super.key,
    required this.repository,
    required this.safetyRepository,
    required this.labels,
  });

  final ChatRepository repository;
  final SafetyRepository safetyRepository;
  final BootstrapState labels;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _search = TextEditingController();
  final List<ChatMatch> _matches = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search.addListener(_refreshSearch);
    _load();
  }

  @override
  void dispose() {
    _search
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  void _refreshSearch() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.repository.matches();
      if (!mounted) return;
      setState(() {
        _matches
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
      final page = await widget.repository.matches(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _matches.addAll(page.items);
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

  List<ChatMatch> get _visibleMatches {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _matches;
    return _matches
        .where((item) =>
            item.firstName.toLowerCase().contains(query) ||
            (item.lastMessage?.body.toLowerCase().contains(query) ?? false))
        .toList(growable: false);
  }

  Future<void> _open(ChatMatch match) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          match: match,
          repository: widget.repository,
          safetyRepository: widget.safetyRepository,
          labels: widget.labels,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final visible = _visibleMatches;
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  widget.labels.text('nav.chat', 'Chat'),
                  style: const TextStyle(
                    color: SoulColors.ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.labels.text('common.search', 'Search'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: SoulColors.softSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_error != null)
              Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: SoulColors.softSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(_error!)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _error = null),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _matches.isEmpty
                  ? _ChatEmpty(
                      title: widget.labels.text('matches.title', 'Matches'),
                    )
                  : visible.isEmpty
                      ? Center(
                          child: Text(
                            'No results',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.extentAfter < 500) {
                                _loadMore();
                              }
                              return false;
                            },
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 126),
                              itemCount: visible.length +
                                  (_loadingMore && _nextCursor != null ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 2),
                              itemBuilder: (context, index) {
                                if (index >= visible.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                final match = visible[index];
                                return _ChatRow(
                                  match: match,
                                  newMatchLabel: widget.labels.text(
                                    'matches.new_match',
                                    'It is a match!',
                                  ),
                                  onTap: () => _open(match),
                                );
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.match,
    required this.newMatchLabel,
    required this.onTap,
  });

  final ChatMatch match;
  final String newMatchLabel;
  final VoidCallback onTap;

  String _time(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final last = match.lastMessage;
    final lastIsMine = last?.isMine == true;
    final lastReadAt = last?.readAt;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _Avatar(photoUrl: match.photo?.url, radius: 31),
                if (match.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: SoulColors.lime,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          match.firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SoulColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _time(last?.sentAt ?? match.matchedAt),
                        style: const TextStyle(
                          color: SoulColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (lastIsMine) ...[
                        Icon(
                          lastReadAt == null
                              ? Icons.check_rounded
                              : Icons.done_all_rounded,
                          size: 17,
                          color: lastReadAt == null
                              ? SoulColors.muted
                              : const Color(0xff00b978),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          last?.body ?? newMatchLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: match.unreadCount > 0
                                ? SoulColors.ink
                                : SoulColors.muted,
                            fontSize: 14,
                            fontWeight: match.unreadCount > 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (match.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 27),
                          height: 27,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          decoration: const BoxDecoration(
                            color: SoulColors.limeLight,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            match.unreadCount > 99
                                ? '99+'
                                : match.unreadCount.toString(),
                            style: const TextStyle(
                              color: SoulColors.ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.radius});

  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: SoulColors.softSurface,
        foregroundImage:
            photoUrl == null || photoUrl!.isEmpty ? null : NetworkImage(photoUrl!),
        child: photoUrl == null || photoUrl!.isEmpty
            ? const Icon(Icons.person_rounded, color: SoulColors.muted)
            : null,
      );
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 20, 30, 126),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: SoulColors.limeLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  size: 42,
                  color: SoulColors.ink,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: const TextStyle(
                  color: SoulColors.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No matches yet. Like profiles in Home to start a conversation.',
                textAlign: TextAlign.center,
                style: TextStyle(color: SoulColors.muted, fontSize: 15),
              ),
            ],
          ),
        ),
      );
}
