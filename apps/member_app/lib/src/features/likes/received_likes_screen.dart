import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import '../discovery/discovery_repository.dart';

class ReceivedLikesScreen extends StatefulWidget {
  const ReceivedLikesScreen({
    super.key,
    required this.repository,
    required this.labels,
    this.onStartDiscovering,
  });

  final DiscoveryRepository repository;
  final BootstrapState labels;
  final VoidCallback? onStartDiscovering;

  @override
  State<ReceivedLikesScreen> createState() => _ReceivedLikesScreenState();
}

class _ReceivedLikesScreenState extends State<ReceivedLikesScreen> {
  final List<IncomingLike> _likes = [];
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
      final page = await widget.repository.receivedLikes();
      if (!mounted) return;
      setState(() {
        _likes
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
      final page = await widget.repository.receivedLikes(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _likes.addAll(page.items);
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

  Future<void> _respond(IncomingLike item, String decision) async {
    if (_busy.contains(item.profileId)) return;
    setState(() {
      _busy.add(item.profileId);
      _error = null;
    });

    try {
      final result =
          await widget.repository.respondToLike(item.profileId, decision);
      if (!mounted) return;
      setState(() {
        _likes.removeWhere((like) => like.profileId == item.profileId);
        _busy.remove(item.profileId);
      });

      if (result.matched) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              widget.labels.text('matches.new_match', 'It is a match!'),
            ),
            content: Text('${item.firstName} is now in your matches.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.labels.text('common.done', 'Done')),
              ),
            ],
          ),
        );
      }
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy.remove(item.profileId);
        _error = failure.message;
      });
    }
  }

  bool _isRecent(IncomingLike item) {
    final received = item.receivedAt;
    if (received == null) return false;
    return DateTime.now().toUtc().difference(received.toUtc()).inHours < 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _likes.isEmpty) {
      return _LikesError(
        message: _error!,
        label: widget.labels.text('common.retry', 'Try again'),
        onRetry: _load,
      );
    }

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.labels.text('nav.explore', 'Explore'),
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(
                      side: BorderSide(color: SoulColors.line),
                    ),
                    child: IconButton(
                      tooltip: widget.labels.text('common.retry', 'Try again'),
                      onPressed: _load,
                      icon: const Icon(Icons.tune_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                children: [
                  _ExploreTab(
                    label: widget.labels.text('likes.received', 'Likes received'),
                    selected: true,
                  ),
                ],
              ),
            ),
            if (_error != null)
              Container(
                margin: const EdgeInsets.fromLTRB(18, 4, 18, 8),
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
              child: _likes.isEmpty
                  ? _ExploreEmpty(
                      title:
                          widget.labels.text('likes.received', 'Likes received'),
                      onStart: widget.onStartDiscovering,
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
                        child: GridView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(24, 8, 24, 126),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 9,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: _likes.length +
                              (_loadingMore && _nextCursor != null ? 2 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _likes.length) {
                              return const _LikeSkeleton();
                            }
                            final item = _likes[index];
                            return _LikeGridCard(
                              item: item,
                              recent: _isRecent(item),
                              busy: _busy.contains(item.profileId),
                              acceptLabel: widget.labels.text(
                                'likes.accept',
                                'Accept like',
                              ),
                              declineLabel: widget.labels.text(
                                'likes.decline',
                                'Decline like',
                              ),
                              onAccept: () => _respond(item, 'accept'),
                              onDecline: () => _respond(item, 'decline'),
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

class _ExploreTab extends StatelessWidget {
  const _ExploreTab({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Align(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? SoulColors.limeLight : SoulColors.softSurface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            child: Text(
              label,
              style: const TextStyle(
                color: SoulColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
}

class _LikeGridCard extends StatelessWidget {
  const _LikeGridCard({
    required this.item,
    required this.recent,
    required this.busy,
    required this.acceptLabel,
    required this.declineLabel,
    required this.onAccept,
    required this.onDecline,
  });

  final IncomingLike item;
  final bool recent;
  final bool busy;
  final String acceptLabel;
  final String declineLabel;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  String get _name {
    final age = item.age;
    return age == null ? item.firstName : '${item.firstName}, $age';
  }

  String get _location {
    final values = <String>[
      if (item.city != null && item.city!.trim().isNotEmpty) item.city!.trim(),
      if (item.country != null && item.country!.trim().isNotEmpty)
        item.country!.trim(),
    ];
    return values.join(', ');
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.photoUrl == null || item.photoUrl!.isEmpty)
              const ColoredBox(
                color: SoulColors.softSurface,
                child: Icon(
                  Icons.person_rounded,
                  size: 72,
                  color: SoulColors.muted,
                ),
              )
            else
              Image.network(
                item.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: SoulColors.softSurface,
                  child: Icon(
                    Icons.person_rounded,
                    size: 72,
                    color: SoulColors.muted,
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xdd000000),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
            if (recent)
              Positioned(
                right: 9,
                top: 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: SoulColors.limeLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      'Just now',
                      style: TextStyle(
                        color: SoulColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_location.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: _MiniAction(
                      icon: Icons.close_rounded,
                      label: declineLabel,
                      busy: busy,
                      onTap: onDecline,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _MiniAction(
                      icon: Icons.favorite_rounded,
                      label: acceptLabel,
                      busy: busy,
                      primary: true,
                      onTap: onAccept,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.busy,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final bool busy;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: primary ? SoulColors.limeLight : const Color(0xddffffff),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: busy ? null : onTap,
            child: SizedBox(
              height: 36,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        icon,
                        size: 20,
                        color: SoulColors.ink,
                      ),
              ),
            ),
          ),
        ),
      );
}

class _ExploreEmpty extends StatelessWidget {
  const _ExploreEmpty({required this.title, this.onStart});

  final String title;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 24, 30, 126),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    decoration: const BoxDecoration(
                      color: SoulColors.softSurface,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: SoulColors.limeLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 4),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 45,
                      color: SoulColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: SoulColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'People who like you will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: SoulColors.muted, fontSize: 15),
              ),
              if (onStart != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: SoulColors.limeLight,
                    foregroundColor: SoulColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start discovering',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class _LikeSkeleton extends StatelessWidget {
  const _LikeSkeleton();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: SoulColors.softSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
}

class _LikesError extends StatelessWidget {
  const _LikesError({
    required this.message,
    required this.label,
    required this.onRetry,
  });

  final String message;
  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: Text(label)),
              ],
            ),
          ),
        ),
      );
}
