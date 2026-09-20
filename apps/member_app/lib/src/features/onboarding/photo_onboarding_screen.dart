import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import 'photo_onboarding_repository.dart';

final photoOnboardingRepositoryProvider = Provider<PhotoOnboardingRepository>(
  (ref) => PhotoOnboardingRepository(ref.watch(apiClientProvider)),
);

class PhotoOnboardingScreen extends ConsumerStatefulWidget {
  const PhotoOnboardingScreen({super.key});

  @override
  ConsumerState<PhotoOnboardingScreen> createState() =>
      _PhotoOnboardingScreenState();
}

class _PhotoOnboardingScreenState
    extends ConsumerState<PhotoOnboardingScreen> {
  final _picker = ImagePicker();
  List<ProfilePhotoState> _photos = const [];
  final Map<int, String> _visibility = {2: 'private', 3: 'private'};
  int? _busyPosition;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final photos = await ref.read(photoOnboardingRepositoryProvider).list();
      if (!mounted) return;
      setState(() {
        _photos = photos;
        for (final photo in photos) {
          if (photo.position > 1) {
            _visibility[photo.position] = photo.visibility;
          }
        }
      });
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    }
  }

  Future<void> _pickAndUpload(int position) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
      maxHeight: 2400,
      requestFullMetadata: false,
    );
    if (file == null || !mounted) return;
    setState(() {
      _busyPosition = position;
      _error = null;
    });
    try {
      await ref.read(photoOnboardingRepositoryProvider).upload(
            position: position,
            visibility: position == 1
                ? 'public'
                : (_visibility[position] ?? 'private'),
            file: file,
          );
      await _load();
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busyPosition = null);
    }
  }

  Future<void> _setVisibility(
    int position,
    String visibility,
  ) async {
    final photo = _at(position);
    if (photo == null) {
      setState(() => _visibility[position] = visibility);
      return;
    }

    setState(() {
      _busyPosition = position;
      _error = null;
      _visibility[position] = visibility;
    });
    try {
      await ref
          .read(photoOnboardingRepositoryProvider)
          .updateVisibility(position, visibility);
      await _load();
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _visibility[position] = photo.visibility;
        _error = failure.message;
      });
    } finally {
      if (mounted) setState(() => _busyPosition = null);
    }
  }

  Future<void> _delete(int position) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove photo?'),
        content: const Text(
          'This removes the photo from your profile. You can upload a replacement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busyPosition = position;
      _error = null;
    });
    try {
      await ref.read(photoOnboardingRepositoryProvider).delete(position);
      await _load();
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busyPosition = null);
    }
  }

  ProfilePhotoState? _at(int position) {
    for (final photo in _photos) {
      if (photo.position == position) return photo;
    }
    return null;
  }

  bool get _requirementsMet {
    final cover = _at(1);
    final approved = _photos.where(
      (photo) => photo.moderationStatus == 'approved',
    );
    return cover?.moderationStatus == 'approved' &&
        approved.any((photo) => photo.faceDetected == true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add your photos')),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
              children: [
                Text(
                  'Show the real you',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your first photo is public and becomes your cover. At least one approved photo must clearly show your face.',
                ),
                const SizedBox(height: 24),
                for (var position = 1; position <= 3; position++) ...[
                  _PhotoSlot(
                    position: position,
                    photo: _at(position),
                    busy: _busyPosition == position,
                    visibility: position == 1
                        ? 'public'
                        : (_visibility[position] ?? 'private'),
                    onVisibilityChanged: position == 1
                        ? null
                        : (value) => _setVisibility(position, value),
                    onUpload: () => _pickAndUpload(position),
                    onDelete: _at(position) == null
                        ? null
                        : () => _delete(position),
                  ),
                  const SizedBox(height: 14),
                ],
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
                const SizedBox(height: 12),
                Card(
                  color: SoulColors.lime.withValues(alpha: .12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _requirementsMet
                              ? Icons.verified
                              : Icons.hourglass_top,
                          color: SoulColors.forest,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _requirementsMet
                                ? 'Photo requirements approved.'
                                : 'Uploaded photos may remain pending while automated safety checks finish.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _busyPosition == null
                        ? () => Navigator.pop(context, true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: SoulColors.lime,
                      foregroundColor: SoulColors.ink,
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.position,
    required this.photo,
    required this.busy,
    required this.visibility,
    required this.onVisibilityChanged,
    required this.onUpload,
    required this.onDelete,
  });

  final int position;
  final ProfilePhotoState? photo;
  final bool busy;
  final String visibility;
  final ValueChanged<String>? onVisibilityChanged;
  final VoidCallback onUpload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: SoulColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: SoulColors.lime.withValues(alpha: .18),
                  child: Text('$position'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        position == 1 ? 'Cover photo' : 'Photo $position',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(_statusText(photo)),
                    ],
                  ),
                ),
                if (busy) const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
            if (photo?.url case final url?) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: SoulColors.softSurface,
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: SoulColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (photo?.rejectionReason case final reason?) ...[
              const SizedBox(height: 10),
              Text(reason, style: const TextStyle(color: Colors.red)),
            ],
            if (position > 1) ...[
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'public', label: Text('Public')),
                  ButtonSegment(value: 'private', label: Text('Private')),
                ],
                selected: {visibility},
                onSelectionChanged: busy
                    ? null
                    : (values) => onVisibilityChanged?.call(values.first),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onUpload,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(photo == null ? 'Choose photo' : 'Replace'),
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: busy ? null : onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove photo',
                  ),
                ],
              ],
            ),
          ],
        ),
      );

  String _statusText(ProfilePhotoState? value) {
    if (value == null) return 'Not added';
    return switch (value.moderationStatus) {
      'approved' => value.faceDetected == true
          ? 'Approved · clear face detected'
          : 'Approved',
      'rejected' => 'Needs replacement',
      _ => 'Safety review pending',
    };
  }
}
