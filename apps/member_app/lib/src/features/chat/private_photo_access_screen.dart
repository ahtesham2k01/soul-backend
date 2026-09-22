import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'chat_repository.dart';

class PrivatePhotoAccessScreen extends StatefulWidget {
  const PrivatePhotoAccessScreen({
    required this.matchId,
    required this.profileName,
    required this.repository,
    required this.labels,
    super.key,
  });

  final String matchId;
  final String profileName;
  final ChatRepository repository;
  final BootstrapState labels;

  @override
  State<PrivatePhotoAccessScreen> createState() =>
      _PrivatePhotoAccessScreenState();
}

class _PrivatePhotoAccessScreenState extends State<PrivatePhotoAccessScreen> {
  final List<PrivatePhotoAccessItem> _items = [];
  bool _loading = true;
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
      final page = await widget.repository.privatePhotoAccessRequests();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(
            page.items.where((item) => item.matchId == widget.matchId),
          );
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

  Future<void> _decide(
    PrivatePhotoAccessItem item,
    String decision,
  ) async {
    if (_busy.contains(item.id)) return;
    setState(() {
      _busy.add(item.id);
      _error = null;
    });
    try {
      final updated = await widget.repository.decidePrivatePhotoAccess(
        item.id,
        decision,
      );
      if (!mounted) return;
      _replace(updated);
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy.remove(item.id);
        _error = failure.message;
      });
    }
  }

  Future<void> _revoke(PrivatePhotoAccessItem item) async {
    if (_busy.contains(item.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.labels.text('private_photos.revoke_confirm', 'Revoke private photo access?')),
        content: Text(
          widget.labels.format(
            'private_photos.revoke_explainer',
            '{name} will no longer be able to view your current private photos.',
            {
              'name': item.firstName.isEmpty
                  ? widget.profileName
                  : item.firstName,
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.labels.text('common.cancel', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.labels.text('common.revoke', 'Revoke')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy.add(item.id);
      _error = null;
    });
    try {
      final updated =
          await widget.repository.revokePrivatePhotoAccess(item.id);
      if (!mounted) return;
      _replace(updated);
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy.remove(item.id);
        _error = failure.message;
      });
    }
  }

  void _replace(PrivatePhotoAccessItem updated) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == updated.id);
      if (index >= 0) {
        _items[index] = updated;
      } else {
        _items.insert(0, updated);
      }
      _busy.remove(updated.id);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(widget.labels.text('private_photos.access_title', 'Private photo access')),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                  children: [
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: Text(
                            widget.labels.text('private_photos.no_requests', 'No private photo requests for this match.'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      for (final item in _items) ...[
                        _RequestCard(
                          item: item,
                          labels: widget.labels,
                          busy: _busy.contains(item.id),
                          onApprove: item.incoming && item.pending
                              ? () => _decide(item, 'approve')
                              : null,
                          onReject: item.incoming && item.pending
                              ? () => _decide(item, 'reject')
                              : null,
                          onRevoke: item.incoming && item.approved
                              ? () => _revoke(item)
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
      );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.item,
    required this.labels,
    required this.busy,
    this.onApprove,
    this.onReject,
    this.onRevoke,
  });

  final PrivatePhotoAccessItem item;
  final BootstrapState labels;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final name = item.firstName.isEmpty
        ? widget.labels.text('matches.match', 'Match')
        : item.firstName;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoulColors.softSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: SoulColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.incoming
                          ? labels.text('private_photos.incoming_request', 'Incoming request')
                          : labels.text('private_photos.your_request', 'Your request'),
                      style: const TextStyle(color: SoulColors.muted),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: item.status),
            ],
          ),
          if (onApprove != null || onReject != null || onRevoke != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onReject,
                      child: Text(labels.text('common.reject', 'Reject')),
                    ),
                  ),
                if (onReject != null && onApprove != null)
                  const SizedBox(width: 8),
                if (onApprove != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: busy ? null : onApprove,
                      child: busy
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(labels.text('common.approve', 'Approve')),
                    ),
                  ),
                if (onRevoke != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onRevoke,
                      child: Text(labels.text('private_photos.revoke_access', 'Revoke access')),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            status.replaceAll('_', ' '),
            style: const TextStyle(
              color: SoulColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      );
}
