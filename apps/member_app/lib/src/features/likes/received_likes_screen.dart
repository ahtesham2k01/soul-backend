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
  });

  final DiscoveryRepository repository;
  final BootstrapState labels;

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
            title: Text(widget.labels.text('matches.new_match', 'It is a match!')),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _likes.isEmpty) {
      return _LikesError(
        message: _error!,
        label: widget.labels.text('common.retry', 'Try again'),
        onRetry: _load,
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                widget.labels.text('likes.received', 'Likes received'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _error = null),
                  child: Text(widget.labels.text('common.close', 'Close')),
                ),
              ],
            ),
          Expanded(
            child: _likes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite_border_rounded,
                            size: 56,
                            color: SoulColors.forest,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.labels.text('likes.received', 'Likes received'),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'New likes will appear here.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount:
                          _likes.length + (_nextCursor == null ? 0 : 1),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == _likes.length) {
                          return Center(
                            child: TextButton(
                              onPressed: _loadingMore ? null : _loadMore,
                              child: _loadingMore
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      widget.labels.text(
                                        'common.continue',
                                        'Continue',
                                      ),
                                    ),
                            ),
                          );
                        }
                        final item = _likes[index];
                        final busy = _busy.contains(item.profileId);
                        return _LikeCard(
                          item: item,
                          busy: busy,
                          acceptLabel:
                              widget.labels.text('likes.accept', 'Accept like'),
                          declineLabel:
                              widget.labels.text('likes.decline', 'Decline like'),
                          onAccept: () => _respond(item, 'accept'),
                          onDecline: () => _respond(item, 'decline'),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LikeCard extends StatelessWidget {
  const _LikeCard({
    required this.item,
    required this.busy,
    required this.acceptLabel,
    required this.declineLabel,
    required this.onAccept,
    required this.onDecline,
  });

  final IncomingLike item;
  final bool busy;
  final String acceptLabel;
  final String declineLabel;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) => Material(
        color: SoulColors.softSurface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 88,
                  height: 106,
                  child: item.photoUrl == null || item.photoUrl!.isEmpty
                      ? const ColoredBox(
                          color: Colors.white,
                          child: Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: SoulColors.muted,
                          ),
                        )
                      : Image.network(
                          item.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Colors.white,
                            child: Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: SoulColors.muted,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.firstName,
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: busy ? null : onDecline,
                            child: Text(declineLabel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: busy ? null : onAccept,
                            style: FilledButton.styleFrom(
                              backgroundColor: SoulColors.forestDeep,
                              foregroundColor: Colors.white,
                            ),
                            child: busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(acceptLabel),
                          ),
                        ),
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
  Widget build(BuildContext context) => Center(
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
      );
}
