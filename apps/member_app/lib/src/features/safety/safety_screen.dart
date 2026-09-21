import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'safety_repository.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.repository,
    required this.labels,
  });

  final SafetyRepository repository;
  final BootstrapState labels;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  VerificationSummaryState? _summary;
  List<VerificationCaseState> _cases = const [];
  bool _loading = true;
  final Set<String> _busyTypes = {};
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
      final values = await Future.wait<Object>([
        widget.repository.verificationSummary(),
        widget.repository.verificationCases(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = values[0] as VerificationSummaryState;
        _cases = values[1] as List<VerificationCaseState>;
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

  Future<void> _start(String type) async {
    if (_busyTypes.contains(type)) return;
    setState(() {
      _busyTypes.add(type);
      _error = null;
    });
    try {
      await widget.repository.requestVerification(type);
      await _load();
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busyTypes.remove(type);
        _error = failure.message;
      });
    } finally {
      if (mounted) setState(() => _busyTypes.remove(type));
    }
  }

  VerificationCaseState? _latestCase(String type) {
    for (final item in _cases) {
      if (item.type == type) return item;
    }
    return null;
  }

  Future<void> _appeal(VerificationCaseState item) async {
    final controller = TextEditingController();
    final statement = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.labels.text('verification.appeal_decision', 'Appeal verification decision')),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 7,
          maxLength: 1500,
          decoration: InputDecoration(
            hintText: widget.labels.text('verification.appeal_hint', 'Explain why this decision should be reviewed.'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.labels.text('common.cancel', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              Navigator.of(context).pop(value.length >= 20 ? value : null);
            },
            child: Text(widget.labels.text('verification.submit_appeal', 'Submit appeal')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (statement == null || !mounted) return;

    try {
      await widget.repository.appealVerification(item.id, statement);
      await _load();
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_summary == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.labels.text('verification.title', 'Verification'))),
        body: _VerificationError(
          labels: widget.labels,
          message: _error ?? widget.labels.text('verification.unavailable', 'Verification is unavailable.'),
          onRetry: _load,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff7f7f4),
      appBar: AppBar(title: Text(widget.labels.text('verification.title', 'Verification'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SoulColors.limeLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.black,
                    foregroundColor: SoulColors.limeLight,
                    child: Icon(Icons.verified_user_outlined, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.labels.text(
                            'verification.build_trust',
                            'Build trust with verification',
                          ),
                          style: const TextStyle(
                            color: SoulColors.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.labels.text(
                            'verification.build_trust_subtitle',
                            'SOUL starts only the verification checks supported by the server.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            _VerificationTile(
              labels: widget.labels,
              title: widget.labels.text('verification.email', 'Email'),
              state: _summary!.email,
              action: null,
            ),
            _VerificationTile(
              labels: widget.labels,
              title: widget.labels.text('verification.phone', 'Phone'),
              state: _summary!.phone,
              action: null,
            ),
            _VerificationTile(
              labels: widget.labels,
              title: widget.labels.text('verification.selfie', 'Selfie / photo'),
              state: _summary!.selfie,
              action: () => _start('selfie_review'),
              busy: _busyTypes.contains('selfie_review'),
              appeal: _latestCase('selfie_review')?.status ==
                      'appeal_available'
                  ? () => _appeal(_latestCase('selfie_review')!)
                  : null,
            ),
            _VerificationTile(
              labels: widget.labels,
              title: widget.labels.text('verification.identity_age', 'Identity and age'),
              state: _summary!.identityAge,
              action: () => _start('identity'),
              busy: _busyTypes.contains('identity'),
              appeal: _latestCase('identity')?.status == 'appeal_available'
                  ? () => _appeal(_latestCase('identity')!)
                  : null,
            ),
            if (_cases.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                widget.labels.text('verification.history', 'Verification history'),
                style: const TextStyle(
                  color: SoulColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              for (final item in _cases)
                Card(
                  child: ListTile(
                    leading: Icon(
                      item.status == 'approved'
                          ? Icons.verified_rounded
                          : item.status.contains('pending') ||
                                  item.status == 'under_review'
                              ? Icons.schedule_rounded
                              : Icons.info_outline_rounded,
                      color: item.status == 'approved'
                          ? SoulColors.forest
                          : SoulColors.muted,
                    ),
                    title: Text(
                      item.type == 'identity'
                          ? widget.labels.text('verification.identity_age', 'Identity and age')
                          : widget.labels.text('verification.selfie', 'Selfie / photo'),
                    ),
                    subtitle: Text(
                      [
                        item.status.replaceAll('_', ' '),
                        if (item.reason != null && item.reason!.isNotEmpty)
                          item.reason!,
                      ].join(' · '),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({
    required this.labels,
    required this.title,
    required this.state,
    required this.action,
    this.busy = false,
    this.appeal,
  });

  final BootstrapState labels;
  final String title;
  final VerificationState state;
  final VoidCallback? action;
  final bool busy;
  final VoidCallback? appeal;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: state.verified
                    ? SoulColors.limeLight
                    : SoulColors.softSurface,
                child: Icon(
                  state.verified
                      ? Icons.check_rounded
                      : state.blocksProfile
                          ? Icons.priority_high_rounded
                          : Icons.shield_outlined,
                  color: SoulColors.ink,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: SoulColors.ink,
                      ),
                    ),
                    Text(
                      state.status.replaceAll('_', ' '),
                      style: const TextStyle(color: SoulColors.muted),
                    ),
                  ],
                ),
              ),
              if (appeal != null)
                TextButton(
                  onPressed: appeal,
                  child: Text(labels.text('verification.appeal', 'Appeal')),
                )
              else if (action != null && !state.verified)
                TextButton(
                  onPressed: busy ? null : action,
                  child: Text(
                    busy
                        ? labels.text('verification.starting', 'Starting…')
                        : labels.text('verification.verify', 'Verify'),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _VerificationError extends StatelessWidget {
  const _VerificationError({
    required this.labels,
    required this.message,
    required this.onRetry,
  });

  final BootstrapState labels;
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
              FilledButton(
                onPressed: onRetry,
                child: Text(labels.text('common.retry', 'Try again')),
              ),
            ],
          ),
        ),
      );
}

Future<bool> showProfileSafetyActions({
  required BuildContext context,
  required SafetyRepository repository,
  required BootstrapState labels,
  required String profileId,
  required String profileName,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    backgroundColor: Colors.white,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: SoulColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(
              '${labels.text('safety.report', 'Report')} $profileName',
            ),
            onTap: () => Navigator.of(context).pop('report'),
          ),
          ListTile(
            leading: Icon(
              Icons.block_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              '${labels.text('safety.block', 'Block')} $profileName',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.of(context).pop('block'),
          ),
        ],
      ),
    ),
  );

  if (action == null || !context.mounted) return false;

  if (action == 'block') {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${labels.text('safety.block', 'Block')} $profileName?',
        ),
        content: const Text(
          'This closes active interaction and prevents discovery between both profiles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(labels.text('common.cancel', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(labels.text('safety.block', 'Block')),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    try {
      await repository.blockProfile(profileId);
      return true;
    } on SoulApiFailure catch (failure) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      return false;
    }
  }

  final report = await showDialog<_ReportDraft>(
    context: context,
    builder: (context) => _ReportDialog(
      profileName: profileName,
      labels: labels,
    ),
  );
  if (report == null) return false;
  try {
    await repository.reportProfile(
      profileId: profileId,
      category: report.category,
      details: report.details,
      block: report.block,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            labels.text('safety.report_sent', 'Your report has been sent'),
          ),
        ),
      );
    }
    return report.block;
  } on SoulApiFailure catch (failure) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    }
    return false;
  }
}

class _ReportDraft {
  const _ReportDraft({
    required this.category,
    required this.block,
    this.details,
  });

  final String category;
  final bool block;
  final String? details;
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({
    required this.profileName,
    required this.labels,
  });

  final String profileName;
  final BootstrapState labels;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String _category = 'fake_profile';
  bool _block = true;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
          '${widget.labels.text('safety.report', 'Report')} ${widget.profileName}',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: [
                  DropdownMenuItem(
                    value: 'fake_profile',
                    child: Text(widget.labels.text('safety.reason.fake_profile', 'Fake profile')),
                  ),
                  DropdownMenuItem(
                    value: 'scam',
                    child: Text(widget.labels.text('safety.reason.scam', 'Scam')),
                  ),
                  DropdownMenuItem(
                    value: 'harassment',
                    child: Text(
                      widget.labels.text(
                        'safety.reason.harassment',
                        'Harassment',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'nudity_sexual_content',
                    child: Text(
                      widget.labels.text(
                        'safety.reason.sexual_content',
                        'Sexual content',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'underage',
                    child: Text(
                      widget.labels.text(
                        'safety.reason.underage',
                        'Underage concern',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'false_marital_status',
                    child: Text(
                      widget.labels.text(
                        'safety.reason.false_marital_status',
                        'False marital status',
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text(widget.labels.text('common.other', 'Other')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _details,
                minLines: 3,
                maxLines: 6,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: widget.labels.text(
                    'common.optional_details',
                    'Optional details',
                  ),
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _block,
                onChanged: (value) =>
                    setState(() => _block = value ?? true),
                title: Text(
                  widget.labels.text(
                    'safety.block_too',
                    'Block this profile too',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              widget.labels.text('common.cancel', 'Cancel'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(
              _ReportDraft(
                category: _category,
                block: _block,
                details: _details.text.trim().isEmpty
                    ? null
                    : _details.text.trim(),
              ),
            ),
            child: Text(
              widget.labels.text('safety.report', 'Report'),
            ),
          ),
        ],
      );
}
