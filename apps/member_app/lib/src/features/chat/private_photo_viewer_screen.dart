import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/native_security_service.dart';
import '../../core/soul_theme.dart';
import '../../core/ulid.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'chat_repository.dart';

class PrivatePhotoViewerScreen extends StatefulWidget {
  const PrivatePhotoViewerScreen({
    super.key,
    required this.matchId,
    required this.profileName,
    required this.repository,
    required this.labels,
  });

  final String matchId;
  final String profileName;
  final ChatRepository repository;
  final BootstrapState labels;

  @override
  State<PrivatePhotoViewerScreen> createState() =>
      _PrivatePhotoViewerScreenState();
}

class _PrivatePhotoViewerScreenState extends State<PrivatePhotoViewerScreen> {
  PrivatePhotoAlbum? _album;
  bool _loading = true;
  bool _requesting = false;
  bool _accessRequired = false;
  bool _requestPending = false;
  String? _error;
  final NativeSecurityService _nativeSecurity =
      const NativeSecurityService();
  StreamSubscription<NativeCaptureEvent>? _captureSubscription;
  int _photoIndex = 0;
  bool _recordingCaptured = false;

  @override
  void initState() {
    super.initState();
    _captureSubscription = _nativeSecurity.captureEvents().listen(
      (event) => unawaited(_handleCapture(event)),
    );
    _load();
  }

  @override
  void dispose() {
    _captureSubscription?.cancel();
    unawaited(_nativeSecurity.setPrivateScreenProtected(false));
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _accessRequired = false;
    });
    try {
      final album = await widget.repository.privatePhotos(widget.matchId);
      if (!mounted) return;
      final captured = album.protection.enabled
          ? await _nativeSecurity.setPrivateScreenProtected(true)
          : await _nativeSecurity.setPrivateScreenProtected(false);
      if (!mounted) return;
      setState(() {
        _album = album;
        _loading = false;
        _requestPending = false;
        _recordingCaptured =
            album.protection.iosRecordingMaskRequired && captured;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      if (failure.statusCode == 403 ||
          failure.code == 'PRIVATE_PHOTO_ACCESS_REQUIRED') {
        setState(() {
          _loading = false;
          _accessRequired = true;
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _handleCapture(NativeCaptureEvent event) async {
    final album = _album;
    if (album == null || !album.protection.enabled) return;

    if (event.type == 'screen_recording' &&
        album.protection.iosRecordingMaskRequired &&
        mounted) {
      setState(() => _recordingCaptured = event.active);
    }

    if (!event.active) return;
    if (event.type == 'screenshot' &&
        !album.protection.iosCaptureDetectionRequired) {
      return;
    }
    if (event.type == 'screen_recording' &&
        !album.protection.iosRecordingMaskRequired) {
      return;
    }
    if (_photoIndex < 0 || _photoIndex >= album.photos.length) return;

    try {
      await widget.repository.recordPrivatePhotoCapture(
        photoId: album.photos[_photoIndex].id,
        clientEventId: SoulUlid.generate(),
        eventType:
            event.type == 'screenshot' ? 'screenshot' : 'screen_recording',
      );
    } on SoulApiFailure {
      // Best effort by contract; protected content stays usable/offline-safe.
    }
  }

  Future<void> _requestAccess() async {
    if (_requesting) return;
    setState(() {
      _requesting = true;
      _error = null;
    });
    try {
      final result =
          await widget.repository.requestPrivatePhotos(widget.matchId);
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _requestPending = result.status == 'pending';
        _accessRequired = result.status != 'approved';
      });
      if (result.status == 'approved') {
        await _load();
      }
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.profileName),
          actions: [
            if (_album?.protection.enabled == true)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.shield_outlined),
              ),
          ],
        ),
        body: _body(),
      );

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: SoulColors.limeLight),
      );
    }
    if (_error != null) {
      return _ViewerState(
        icon: Icons.error_outline_rounded,
        title: widget.labels.text('private_photos.unable_to_load', 'Unable to load private photos'),
        message: _error!,
        action: widget.labels.text('common.retry', 'Try again'),
        onAction: _load,
      );
    }
    if (_accessRequired || _requestPending) {
      return _ViewerState(
        icon: _requestPending
            ? Icons.schedule_rounded
            : Icons.lock_outline_rounded,
        title: _requestPending
            ? widget.labels.text('private_photos.request_sent', 'Request sent')
            : widget.labels.text(
                'private_photos.access_required',
                'Private photo access required',
              ),
        message: _requestPending
            ? widget.labels.format(
                'private_photos.pending_access_message',
                'You can view these photos after {name} approves your request.',
                {'name': widget.profileName},
              )
            : widget.labels.format(
                'private_photos.request_access_message',
                'Ask {name} for permission to view private photos.',
                {'name': widget.profileName},
              ),
        action: _requestPending
            ? widget.labels.text('common.retry', 'Try again')
            : widget.labels.text(
                'private_photos.request_access',
                'Request access',
              ),
        onAction: _requestPending ? _load : _requestAccess,
        loading: _requesting,
      );
    }

    final album = _album;
    if (album == null || album.photos.isEmpty) {
      return _ViewerState(
        icon: Icons.photo_outlined,
        title: widget.labels.text('private_photos.no_photos', 'No private photos'),
        message: widget.labels.format(
          'private_photos.no_approved',
          '{name} has no approved private photos to show.',
          {'name': widget.profileName},
        ),
        action: widget.labels.text('common.done', 'Done'),
        onAction: () => Navigator.of(context).pop(),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: album.photos.length,
          onPageChanged: (index) => _photoIndex = index,
          itemBuilder: (_, index) => _ProtectedPhotoPage(
            photo: album.photos[index],
            repository: widget.repository,
            protection: album.protection,
            labels: widget.labels,
          ),
        ),
        if (_recordingCaptured)
          ColoredBox(
            color: Colors.black,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      color: SoulColors.limeLight,
                      size: 54,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.labels.text(
                        'private_photos.recording_hidden',
                        'Private photos are hidden while screen recording is active.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 22,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xaa000000),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: SoulColors.limeLight,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.labels.text(
                        'private_photos.protected_notice',
                        'Protected photos are shown only inside SOUL and are not saved to your device.',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProtectedPhotoPage extends StatefulWidget {
  const _ProtectedPhotoPage({
    required this.photo,
    required this.repository,
    required this.protection,
    required this.labels,
  });

  final PrivateChatPhoto photo;
  final ChatRepository repository;
  final PrivatePhotoProtection protection;
  final BootstrapState labels;

  @override
  State<_ProtectedPhotoPage> createState() => _ProtectedPhotoPageState();
}

class _ProtectedPhotoPageState extends State<_ProtectedPhotoPage> {
  late Future<Uint8List> _content;

  @override
  void initState() {
    super.initState();
    _content = widget.repository.privatePhotoContent(widget.photo.contentPath);
  }

  void _retry() {
    setState(() {
      _content = widget.repository.privatePhotoContent(widget.photo.contentPath);
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
        future: _content,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: SoulColors.limeLight),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: TextButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(widget.labels.text('common.retry', 'Try again')),
              ),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
              if (widget.protection.enabled &&
                  widget.protection.viewerWatermark != null)
                IgnorePointer(
                  child: _Watermark(
                    value: widget.protection.viewerWatermark!,
                  ),
                ),
            ],
          );
        },
      );
}

class _Watermark extends StatelessWidget {
  const _Watermark({required this.value});

  final String value;

  String get _shortValue =>
      value.length <= 12 ? value : value.substring(value.length - 12);

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          for (final alignment in const [
            Alignment(-0.72, -0.55),
            Alignment(0.7, -0.18),
            Alignment(-0.45, 0.42),
            Alignment(0.6, 0.72),
          ])
            Align(
              alignment: alignment,
              child: Transform.rotate(
                angle: -0.35,
                child: Text(
                  'SOUL · $_shortValue',
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
        ],
      );
}

class _ViewerState extends StatelessWidget {
  const _ViewerState({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
    required this.onAction,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String action;
  final VoidCallback onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: SoulColors.limeLight, size: 58),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: loading ? null : onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: SoulColors.limeLight,
                  foregroundColor: SoulColors.ink,
                ),
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(action),
              ),
            ],
          ),
        ),
      );
}
