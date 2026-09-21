import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'event_repository.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({
    super.key,
    required this.repository,
    required this.labels,
  });

  final EventRepository repository;
  final BootstrapState labels;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final List<SoulEvent> _events = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _myEvents = false;
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
      final page = await widget.repository.events();
      if (!mounted) return;
      setState(() {
        _events
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
      final page = await widget.repository.events(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _events.addAll(page.items);
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

  List<SoulEvent> get _visible => _myEvents
      ? _events.where((event) => event.isJoined).toList(growable: false)
      : _events;

  Future<void> _open(SoulEvent event) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          eventId: event.id,
          repository: widget.repository,
          labels: widget.labels,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xfff7f7f4),
        appBar: AppBar(title: Text(widget.labels.text('events.title', 'Events'))),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(widget.labels.text('events.upcoming', 'Upcoming')),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(widget.labels.text('events.my_events', 'My events')),
                        ),
                      ],
                      selected: {_myEvents},
                      onSelectionChanged: (value) =>
                          setState(() => _myEvents = value.first),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: _visible.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 150),
                                const Icon(
                                  Icons.event_available_outlined,
                                  size: 58,
                                  color: SoulColors.muted,
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: Text(
                                    _myEvents
                                        ? widget.labels.text('events.no_joined', 'You have not joined any upcoming events.')
                                        : widget.labels.text('events.no_upcoming', 'No upcoming events right now.'),
                                  ),
                                ),
                              ],
                            )
                          : NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (!_myEvents &&
                                    notification.metrics.extentAfter < 400) {
                                  _loadMore();
                                }
                                return false;
                              },
                              child: ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 4, 18, 32),
                                itemCount: _visible.length +
                                    (_loadingMore && !_myEvents ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, index) {
                                  final items = _visible;
                                  if (index >= items.length) {
                                    return const Padding(
                                      padding: EdgeInsets.all(18),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }
                                  return _EventCard(
                                    event: items[index],
                                    labels: widget.labels,
                                    onTap: () => _open(items[index]),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      );
}

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.repository,
    required this.labels,
  });

  final String eventId;
  final EventRepository repository;
  final BootstrapState labels;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  SoulEvent? _event;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final event = await widget.repository.event(widget.eventId);
      if (!mounted) return;
      setState(() {
        _event = event;
        _loading = false;
        _error = null;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _toggleJoin() async {
    final event = _event;
    if (event == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (event.isJoined) {
        await widget.repository.leave(event.id);
      } else {
        await widget.repository.join(event.id);
      }
      await _load();
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _report() async {
    String category = 'misleading';
    final details = TextEditingController();
    final result = await showDialog<(String, String?)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(widget.labels.text('events.report', 'Report event')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: category,
                  items: [
                    DropdownMenuItem(
                      value: 'misleading',
                      child: Text(widget.labels.text('events.misleading', 'Misleading')),
                    ),
                    DropdownMenuItem(value: 'unsafe', child: Text(widget.labels.text('events.unsafe', 'Unsafe'))),
                    DropdownMenuItem(value: 'spam', child: Text(widget.labels.text('events.spam', 'Spam'))),
                    DropdownMenuItem(value: 'other', child: Text(widget.labels.text('common.other', 'Other'))),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => category = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: details,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    hintText: category == 'other'
                        ? '${widget.labels.text('common.other', 'Other')}: ${widget.labels.text('common.optional_details', 'Optional details')}'
                        : widget.labels.text('common.optional_details', 'Optional details'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.labels.text('common.cancel', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                final text = details.text.trim();
                if (category == 'other' && text.isEmpty) return;
                Navigator.of(context).pop(
                  (category, text.isEmpty ? null : text),
                );
              },
              child: Text(widget.labels.text('common.report', 'Report')),
            ),
          ],
        ),
      ),
    );
    details.dispose();
    if (result == null || !mounted) return;
    try {
      await widget.repository.report(
        id: widget.eventId,
        category: result.$1,
        details: result.$2,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.labels.text('events.report_submitted', 'Event report submitted.'))),
      );
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.labels.text('events.details', 'Event details')),
          actions: [
            IconButton(
              tooltip: widget.labels.text('events.report', 'Report event'),
              onPressed: _event == null ? null : _report,
              icon: const Icon(Icons.flag_outlined),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _event == null
                ? _EventError(
                    message: _error ?? 'Event unavailable.',
                    onRetry: _load,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: SoulColors.limeLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.celebration_outlined,
                            size: 58,
                            color: SoulColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _event!.title,
                        style: const TextStyle(
                          color: SoulColors.ink,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailLine(
                        icon: Icons.schedule_rounded,
                        text: _dateText(_event!.startsAt),
                      ),
                      _DetailLine(
                        icon: _event!.type == 'online'
                            ? Icons.videocam_outlined
                            : Icons.location_on_outlined,
                        text: _locationText(_event!),
                      ),
                      if (_event!.spacesRemaining != null)
                        _DetailLine(
                          icon: Icons.people_outline_rounded,
                          text: widget.labels.format('events.spaces_remaining', '{count} spaces remaining', {'count': _event!.spacesRemaining}),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        _event!.description.isEmpty
                            ? widget.labels.text('events.description_pending', 'Event details will be shared by the organizer.')
                            : _event!.description,
                        style: const TextStyle(
                          color: SoulColors.ink,
                          height: 1.45,
                        ),
                      ),
                      if (_event!.onlineUrl != null &&
                          _event!.isJoined) ...[
                        const SizedBox(height: 18),
                        SelectableText(
                          widget.labels.format('events.online_link', 'Online event link: {url}', {'url': _event!.onlineUrl}),
                          style: const TextStyle(
                            color: SoulColors.forest,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _toggleJoin,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: _event!.isJoined
                              ? SoulColors.softSurface
                              : SoulColors.limeLight,
                          foregroundColor: SoulColors.ink,
                        ),
                        child: Text(
                          _busy
                              ? widget.labels.text('common.please_wait', 'Please wait…')
                              : _event!.isJoined
                                  ? widget.labels.text('events.leave', 'Leave event')
                                  : widget.labels.text('events.join', 'Join event'),
                        ),
                      ),
                    ],
                  ),
      );

  String _dateText(DateTime value) {
    final local = value.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} · ${local.hour}:$minute';
  }

  String _locationText(SoulEvent event) {
    if (event.type == 'online') {
      return event.isJoined && event.onlineUrl != null
          ? widget.labels.text('events.online_link_available', 'Online · link available below')
          : widget.labels.text('events.online_event', 'Online event');
    }
    return [
      if (event.city != null && event.city!.isNotEmpty) event.city!,
      if (event.countryCode != null && event.countryCode!.isNotEmpty)
        event.countryCode!,
    ].join(', ');
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.labels, required this.onTap});

  final SoulEvent event;
  final BootstrapState labels;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 82,
                  decoration: BoxDecoration(
                    color: SoulColors.limeLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: SoulColors.ink,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.spacesRemaining != null &&
                          event.spacesRemaining! <= 10)
                        Text(
                          labels.format('events.spaces_left', '{count} spaces left', {'count': event.spacesRemaining}),
                          style: const TextStyle(
                            color: SoulColors.forest,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SoulColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _shortDate(event.startsAt),
                        style: const TextStyle(color: SoulColors.muted),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        event.type == 'online'
                            ? labels.text('events.online', 'Online')
                            : [
                                if (event.city != null) event.city!,
                                if (event.countryCode != null)
                                  event.countryCode!,
                              ].join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: SoulColors.muted),
                      ),
                      if (event.isJoined) ...[
                        const SizedBox(height: 5),
                        Text(
                          labels.text('events.joined', 'Joined'),
                          style: const TextStyle(
                            color: SoulColors.forest,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      );

  String _shortDate(DateTime value) {
    final local = value.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} · ${local.hour}:$minute';
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 19, color: SoulColors.muted),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: SoulColors.muted),
              ),
            ),
          ],
        ),
      );
}

class _EventError extends StatelessWidget {
  const _EventError({required this.message, required this.onRetry});

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
