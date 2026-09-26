import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import '../safety/safety_repository.dart';
import '../safety/safety_screen.dart';
import 'chat_repository.dart';
import 'private_photo_access_screen.dart';
import 'private_photo_viewer_screen.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.match,
    required this.repository,
    required this.safetyRepository,
    required this.labels,
  });

  final ChatMatch match;
  final ChatRepository repository;
  final SafetyRepository safetyRepository;
  final BootstrapState labels;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<ChatMessage> _messages = [];

  String? _nextCursor;
  ChatPresence? _presence;
  Timer? _pollTimer;
  Timer? _typingTimer;
  Timer? _typingHeartbeatTimer;
  bool _loading = true;
  bool _loadingOlder = false;
  bool _sending = false;
  bool _typingSent = false;
  bool _refreshing = false;
  bool _showSafetyTip = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _composer.addListener(_composerChanged);
    _scroll.addListener(_scrollChanged);
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    _typingHeartbeatTimer?.cancel();
    _composer
      ..removeListener(_composerChanged)
      ..dispose();
    _scroll
      ..removeListener(_scrollChanged)
      ..dispose();
    if (_typingSent) {
      unawaited(_safeTyping(false));
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.repository.messages(widget.match.id),
        widget.repository.presence(widget.match.id),
      ]);
      final page = results[0] as ChatMessagePage;
      final presence = results[1] as ChatPresence;
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(page.items);
        _nextCursor = page.nextCursor;
        _presence = presence;
        _loading = false;
      });
      await _markReadIfNeeded();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => unawaited(_refresh()),
      );
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing || !mounted) return;
    _refreshing = true;
    try {
      final results = await Future.wait<Object>([
        widget.repository.messages(widget.match.id),
        widget.repository.presence(widget.match.id),
      ]);
      final page = results[0] as ChatMessagePage;
      final presence = results[1] as ChatPresence;
      if (!mounted) return;

      final merged = <String, ChatMessage>{
        for (final message in _messages) message.id: message,
      };
      for (final message in page.items) {
        merged[message.id] = message;
      }
      final values = merged.values.toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));

      setState(() {
        _messages
          ..clear()
          ..addAll(values);
        _presence = presence;
        _nextCursor ??= page.nextCursor;
      });
      await _markReadIfNeeded();
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      if (failure.statusCode == 404) {
        setState(() => _error = widget.labels.text(
              'chat.match_unavailable',
              'This match is no longer available.',
            ));
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _markReadIfNeeded() async {
    if (!_messages.any((message) => !message.isMine && message.readAt == null)) {
      return;
    }
    try {
      await widget.repository.markRead(widget.match.id);
    } on SoulApiFailure {
      // A later refresh retries naturally; reading the thread stays usable.
    }
  }

  void _scrollChanged() {
    if (!_scroll.hasClients || _loadingOlder || _nextCursor == null) return;
    if (_scroll.position.pixels >
        _scroll.position.maxScrollExtent - 280) {
      unawaited(_loadOlder());
    }
  }

  Future<void> _loadOlder() async {
    final cursor = _nextCursor;
    if (_loadingOlder || cursor == null || cursor.isEmpty) return;
    setState(() => _loadingOlder = true);
    try {
      final page =
          await widget.repository.messages(widget.match.id, cursor: cursor);
      if (!mounted) return;
      final known = _messages.map((item) => item.id).toSet();
      setState(() {
        _messages.addAll(
          page.items.where((item) => !known.contains(item.id)),
        );
        _nextCursor = page.nextCursor;
        _loadingOlder = false;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loadingOlder = false;
        _error = failure.message;
      });
    }
  }

  void _composerChanged() {
    final hasText = _composer.text.trim().isNotEmpty;
    if (hasText && !_typingSent) {
      _typingSent = true;
      unawaited(_safeTyping(true));
      _typingHeartbeatTimer?.cancel();
      _typingHeartbeatTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) {
          if (_typingSent) {
            unawaited(_safeTyping(true));
          }
        },
      );
    }
    if (!hasText && _typingSent) {
      _typingSent = false;
      _typingHeartbeatTimer?.cancel();
      unawaited(_safeTyping(false));
    }

    _typingTimer?.cancel();
    if (hasText) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (_typingSent) {
          _typingSent = false;
          _typingHeartbeatTimer?.cancel();
          unawaited(_safeTyping(false));
        }
      });
    }
    if (mounted) setState(() {});
  }

  Future<void> _safeTyping(bool value) async {
    try {
      await widget.repository.setTyping(widget.match.id, value);
    } on SoulApiFailure {
      // Typing is ephemeral and must never block messaging.
    }
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final message =
          await widget.repository.sendMessage(widget.match.id, body);
      if (!mounted) return;
      _composer.clear();
      _typingSent = false;
      _typingTimer?.cancel();
      _typingHeartbeatTimer?.cancel();
      unawaited(_safeTyping(false));
      setState(() {
        _messages.insert(0, message);
        _sending = false;
      });
      if (_scroll.hasClients) {
        unawaited(
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          ),
        );
      }
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = failure.message;
      });
    }
  }

  String _statusText() {
    final presence = _presence;
    if (presence?.isTyping == true) {
      return widget.labels.text('chat.typing', 'Typing...');
    }
    if (presence?.isOnline == true) {
      return widget.labels.text('chat.online', 'Online now');
    }
    final lastSeen = presence?.lastSeenAt;
    if (lastSeen == null) {
      return widget.labels.text('chat.offline', 'Offline');
    }
    final local = lastSeen.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${widget.labels.text('chat.last_seen', 'Last seen')} $hour:$minute';
  }

  Future<void> _openSafety() async {
    final blocked = await showProfileSafetyActions(
      context: context,
      repository: widget.safetyRepository,
      labels: widget.labels,
      profileId: widget.match.profileId,
      profileName: widget.match.firstName,
    );
    if (blocked && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openPrivatePhotoAccess() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PrivatePhotoAccessScreen(
          matchId: widget.match.id,
          profileName: widget.match.firstName,
          repository: widget.repository,
          labels: widget.labels,
        ),
      ),
    );
  }

  Future<void> _unmatch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.labels.text('matches.unmatch', 'Unmatch'),
        ),
        content: Text(
          widget.labels.format(
            'chat.unmatch_explainer',
            'Your conversation with {name} will be removed, and private photo access will be revoked.',
            {'name': widget.match.firstName},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.labels.text('common.cancel', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              widget.labels.text('matches.unmatch', 'Unmatch'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await widget.repository.unmatch(widget.match.id);
      if (mounted) Navigator.of(context).pop();
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }

  Future<void> _openPrivatePhotos() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PrivatePhotoViewerScreen(
          matchId: widget.match.id,
          profileName: widget.match.firstName,
          repository: widget.repository,
          labels: widget.labels,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: SoulColors.ink,
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              _ThreadAvatar(photoUrl: widget.match.photo?.url),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.match.firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _statusText(),
                      style: TextStyle(
                        color: _presence?.isOnline == true
                            ? const Color(0xff00a86b)
                            : SoulColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'private_photos') {
                  unawaited(_openPrivatePhotos());
                } else if (value == 'private_photo_access') {
                  unawaited(_openPrivatePhotoAccess());
                } else if (value == 'unmatch') {
                  unawaited(_unmatch());
                } else if (value == 'safety') {
                  unawaited(_openSafety());
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'private_photos',
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        widget.labels.text(
                          'chat.private_photos',
                          'Private photos',
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'private_photo_access',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.photo_size_select_actual_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.labels.text(
                          'chat.photo_access_requests',
                          'Photo access requests',
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'unmatch',
                  child: Row(
                    children: [
                      const Icon(Icons.link_off_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        widget.labels.text('matches.unmatch', 'Unmatch'),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'safety',
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        widget.labels.text(
                          'chat.safety_options',
                          'Safety options',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _body(),
      );

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _messages.isEmpty) {
      return _ThreadError(
        message: _error!,
        onRetry: _load,
        retryLabel: widget.labels.text('common.retry', 'Try again'),
      );
    }

    return Column(
      children: [
        if (_error != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: SoulColors.softSurface,
              borderRadius: BorderRadius.circular(11),
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
        if (_showSafetyTip)
          Semantics(
            container: true,
            label: widget.labels.text(
              'chat.safety_tip_title',
              'Stay safe while chatting',
            ),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              decoration: BoxDecoration(
                color: SoulColors.softSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SoulColors.line),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: Color(0xff008f5c),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.labels.text(
                            'chat.safety_tip_title',
                            'Stay safe while chatting',
                          ),
                          style: const TextStyle(
                            color: SoulColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.labels.text(
                            'chat.safety_tip_body',
                            'Never share OTPs, passwords or money. Use Safety options if someone pressures you to move off-platform or pay.',
                          ),
                          style: const TextStyle(
                            color: SoulColors.muted,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: widget.labels.text('common.close', 'Close'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _showSafetyTip = false),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          widget.labels.text(
                            'chat.first_message',
                            'You matched. Send the first message!',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: SoulColors.muted,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      itemCount: _messages.length,
                      itemBuilder: (_, index) =>
                          _MessageBubble(message: _messages[index]),
                    ),
              if (_loadingOlder)
                const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _composer,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText:
                        widget.labels.text('chat.message_hint', 'Write a message'),
                    fillColor: SoulColors.softSurface,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => unawaited(_send()),
                ),
              ),
              const SizedBox(width: 9),
              Material(
                color: _composer.text.trim().isEmpty
                    ? SoulColors.line
                    : SoulColors.limeLight,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _composer.text.trim().isEmpty || _sending
                      ? null
                      : _send,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: SoulColors.ink,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: SoulColors.ink,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  String _time(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment:
            message.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.76,
          ),
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.fromLTRB(14, 10, 11, 7),
          decoration: BoxDecoration(
            color:
                message.isMine ? SoulColors.limeLight : SoulColors.softSurface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(17),
              topRight: const Radius.circular(17),
              bottomLeft: Radius.circular(message.isMine ? 17 : 4),
              bottomRight: Radius.circular(message.isMine ? 4 : 17),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  message.body,
                  style: const TextStyle(
                    color: SoulColors.ink,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _time(message.sentAt),
                    style: const TextStyle(
                      color: SoulColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  if (message.isMine) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.readAt == null
                          ? Icons.check_rounded
                          : Icons.done_all_rounded,
                      size: 14,
                      color: message.readAt == null
                          ? SoulColors.muted
                          : const Color(0xff008f5c),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
}

class _ThreadAvatar extends StatelessWidget {
  const _ThreadAvatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 20,
        backgroundColor: SoulColors.softSurface,
        foregroundImage:
            photoUrl == null || photoUrl!.isEmpty ? null : NetworkImage(photoUrl!),
        child: photoUrl == null || photoUrl!.isEmpty
            ? const Icon(Icons.person_rounded, color: SoulColors.muted)
            : null,
      );
}

class _ThreadError extends StatelessWidget {
  const _ThreadError({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(retryLabel)),
            ],
          ),
        ),
      );
}
