import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../core/soul_design.dart';
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

  Future<void> _setVisibility(int position, String visibility) async {
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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
                child: SoulTopBar(
                  onBack: () => Navigator.of(context).maybePop(),
                  onInfo: _showGuideline,
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 7, 24, 0),
                child: SoulProgressLine(value: .46),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                    children: [
                      const SoulPageTitle(
                        'Upload your photos.',
                        subtitle:
                            'Please upload a clear main profile photo. You can keep extra photos private.',
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _showGuideline,
                            icon: const Icon(
                              Icons.info_outline_rounded,
                              size: 17,
                            ),
                            label: const Text('Photo guideline'),
                            style: TextButton.styleFrom(
                              foregroundColor: SoulColors.ink,
                              textStyle: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _PhotoTile(
                              position: 1,
                              photo: _at(1),
                              busy: _busyPosition == 1,
                              height: 262,
                              label: 'Main profile photo',
                              onUpload: () => _pickAndUpload(1),
                              onDelete: _at(1) == null
                                  ? null
                                  : () => _delete(1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              children: [
                                _PhotoTile(
                                  position: 2,
                                  photo: _at(2),
                                  busy: _busyPosition == 2,
                                  height: 126,
                                  label: 'Photo 2',
                                  onUpload: () => _pickAndUpload(2),
                                  onDelete: _at(2) == null
                                      ? null
                                      : () => _delete(2),
                                ),
                                const SizedBox(height: 10),
                                _PhotoTile(
                                  position: 3,
                                  photo: _at(3),
                                  busy: _busyPosition == 3,
                                  height: 126,
                                  label: 'Photo 3',
                                  onUpload: () => _pickAndUpload(3),
                                  onDelete: _at(3) == null
                                      ? null
                                      : () => _delete(3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _VisibilityRow(
                        title: 'Photo 2',
                        value: _visibility[2] ?? 'private',
                        enabled: _busyPosition == null,
                        onChanged: (value) => _setVisibility(2, value),
                      ),
                      const SizedBox(height: 8),
                      _VisibilityRow(
                        title: 'Photo 3',
                        value: _visibility[3] ?? 'private',
                        enabled: _busyPosition == null,
                        onChanged: (value) => _setVisibility(3, value),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: SoulColors.softSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              color: SoulColors.ink,
                              size: 22,
                            ),
                            const SizedBox(width: 11),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Screenshot protection',
                                    style: TextStyle(
                                      color: SoulColors.ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'SOUL protects supported private-photo viewing with native screen-capture controls.',
                                    style: TextStyle(
                                      color: SoulColors.muted,
                                      fontSize: 10.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Switch(
                              value: true,
                              onChanged: null,
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            _requirementsMet
                                ? Icons.verified_rounded
                                : Icons.hourglass_top_rounded,
                            size: 18,
                            color: _requirementsMet
                                ? SoulColors.forest
                                : SoulColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _requirementsMet
                                  ? 'Photo requirements approved.'
                                  : 'Photos can remain pending while safety checks finish.',
                              style: const TextStyle(
                                color: SoulColors.muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  10,
                  24,
                  18 + MediaQuery.paddingOf(context).bottom * .35,
                ),
                child: SoulPrimaryButton(
                  label: 'Continue',
                  busy: _busyPosition != null,
                  onPressed: _busyPosition == null
                      ? () => Navigator.pop(context, true)
                      : null,
                ),
              ),
            ],
          ),
        ),
      );

  void _showGuideline() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 2, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Upload Your Photos',
                style: TextStyle(
                  color: SoulColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 18),
              _GuidelineRow(
                icon: Icons.face_rounded,
                title: 'Clear face',
                body:
                    'Your main photo should clearly show your face without heavy filters.',
              ),
              SizedBox(height: 12),
              _GuidelineRow(
                icon: Icons.person_rounded,
                title: 'Only show yourself',
                body:
                    'Avoid group photos, misleading images, screenshots and copied profile photos.',
              ),
              SizedBox(height: 12),
              _GuidelineRow(
                icon: Icons.visibility_outlined,
                title: 'Keep it respectful',
                body:
                    'Use recent, appropriate photos that accurately represent you.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.position,
    required this.photo,
    required this.busy,
    required this.height,
    required this.label,
    required this.onUpload,
    required this.onDelete,
  });

  final int position;
  final ProfilePhotoState? photo;
  final bool busy;
  final double height;
  final String label;
  final VoidCallback onUpload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final url = photo?.url;
    return Semantics(
      button: true,
      label: url == null ? 'Add $label' : 'Replace $label',
      child: Material(
        color: const Color(0xfffbfcf8),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: busy ? null : onUpload,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SoulColors.limeLight,
                width: 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url == null || url.isEmpty)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        position == 1
                            ? Icons.add_photo_alternate_outlined
                            : Icons.add_rounded,
                        color: SoulColors.lime,
                        size: position == 1 ? 34 : 28,
                      ),
                      const SizedBox(height: 7),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: SoulColors.muted,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: SoulColors.muted,
                        ),
                      ),
                    ),
                  ),
                if (photo != null)
                  Positioned(
                    left: 7,
                    top: 7,
                    child: _StatusBadge(photo: photo!),
                  ),
                if (onDelete != null)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Material(
                      color: const Color(0xbb000000),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: busy ? null : onDelete,
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (busy)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0x88ffffff),
                      borderRadius: BorderRadius.all(Radius.circular(11)),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SoulColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.photo});

  final ProfilePhotoState photo;

  @override
  Widget build(BuildContext context) {
    final approved = photo.moderationStatus == 'approved';
    final rejected = photo.moderationStatus == 'rejected';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: approved
            ? SoulColors.limeLight
            : rejected
                ? const Color(0xfff4b2b2)
                : const Color(0xddffffff),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        approved
            ? 'Approved'
            : rejected
                ? 'Replace'
                : 'Reviewing',
        style: const TextStyle(
          color: SoulColors.ink,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _VisibilityRow extends StatelessWidget {
  const _VisibilityRow({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title + ' visibility',
              style: const TextStyle(
                color: SoulColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'public', label: Text('Public')),
              ButtonSegment(value: 'private', label: Text('Private')),
            ],
            selected: {value},
            onSelectionChanged: enabled
                ? (values) => onChanged(values.first)
                : null,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      );
}

class _GuidelineRow extends StatelessWidget {
  const _GuidelineRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: SoulColors.limeLight,
            child: Icon(icon, color: SoulColors.ink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SoulColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    color: SoulColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
