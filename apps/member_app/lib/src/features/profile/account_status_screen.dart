import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'profile_repository.dart';

class RestrictedAccountScreen extends StatefulWidget {
  const RestrictedAccountScreen({
    super.key,
    required this.mode,
    required this.repository,
    required this.labels,
    required this.onAccountRestored,
    required this.onSignedOut,
  });

  final String mode;
  final ProfileRepository repository;
  final BootstrapState labels;
  final VoidCallback onAccountRestored;
  final VoidCallback onSignedOut;

  @override
  State<RestrictedAccountScreen> createState() =>
      _RestrictedAccountScreenState();
}

class _RestrictedAccountScreenState extends State<RestrictedAccountScreen> {
  final _statement = TextEditingController();
  Map<String, dynamic>? _appeal;
  Map<String, dynamic>? _deletion;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _statement.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.mode == 'appeal') {
        _appeal = await widget.repository.accountAppeal();
      } else if (widget.mode == 'deletion') {
        _deletion = await widget.repository.deletionStatus();
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _submitAppeal() async {
    final statement = _statement.text.trim();
    if (statement.length < 20) {
      setState(() => _error = widget.labels.text(
            'account.appeal_min_chars',
            'Please add at least 20 characters.',
          ));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final appeal =
          await widget.repository.submitAccountAppeal(statement);
      if (!mounted) return;
      setState(() {
        _appeal = appeal;
        _busy = false;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _cancelDeletion() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.cancelDeletion();
      if (!mounted) return;
      widget.onAccountRestored();
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await widget.repository.logout();
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _error = failure.message);
      return;
    }
    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SOUL',
                        style: TextStyle(
                          color: SoulColors.ink,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: SoulColors.limeLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.mode == 'deletion'
                                ? Icons.schedule_rounded
                                : widget.mode == 'appeal'
                                    ? Icons.gavel_outlined
                                    : Icons.lock_outline_rounded,
                            size: 44,
                            color: SoulColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        _title(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SoulColors.ink,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _message(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SoulColors.muted,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      if (widget.mode == 'appeal' && _appeal == null) ...[
                        const SizedBox(height: 22),
                        TextField(
                          controller: _statement,
                          minLines: 4,
                          maxLines: 8,
                          maxLength: 2000,
                          decoration: InputDecoration(
                            hintText: widget.labels.text(
                              'verification.appeal_hint',
                              'Explain why this decision should be reviewed.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _busy ? null : _submitAppeal,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: SoulColors.limeLight,
                            foregroundColor: SoulColors.ink,
                          ),
                          child: Text(
                            _busy
                                ? widget.labels.text(
                                    'common.please_wait',
                                    'Please wait…',
                                  )
                                : widget.labels.text(
                                    'verification.submit_appeal',
                                    'Submit appeal',
                                  ),
                          ),
                        ),
                      ],
                      if (widget.mode == 'deletion') ...[
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _busy ? null : _cancelDeletion,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: SoulColors.limeLight,
                            foregroundColor: SoulColors.ink,
                          ),
                          child: Text(
                            _busy
                                ? widget.labels.text(
                                    'common.restoring',
                                    'Restoring…',
                                  )
                                : widget.labels.text(
                                    'account.keep_account',
                                    'Keep my SOUL account',
                                  ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Center(
                        child: TextButton(
                          onPressed: _busy ? null : _signOut,
                          child: Text(
                            widget.labels.text('auth.log_out', 'Log out'),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );

  String _title() {
    if (widget.mode == 'deletion') {
      return widget.labels.text(
        'settings.deletion_scheduled',
        'Account deletion scheduled',
      );
    }
    if (widget.mode == 'appeal') {
      final status = _appeal?['status']?.toString();
      return status == null
          ? widget.labels.text('account.review', 'Account review')
          : widget.labels.format(
              'account.appeal_status',
              'Appeal {status}',
              {'status': status},
            );
    }
    return widget.labels.text(
      'auth.error.account_unavailable',
      'Account unavailable',
    );
  }

  String _message() {
    if (widget.mode == 'deletion') {
      final when = _deletion?['scheduled_for']?.toString();
      return when == null
          ? widget.labels.text(
              'account.deletion_hidden',
              'Your account is hidden and scheduled for deletion. You can restore it during the recovery period.',
            )
          : widget.labels.format(
              'account.deletion_hidden_until',
              'Your account is hidden and scheduled for deletion on {date}. You can restore it before then.',
              {'date': when},
            );
    }
    if (widget.mode == 'appeal') {
      final status = _appeal?['status']?.toString();
      if (status == 'pending') {
        return widget.labels.text(
          'account.appeal_pending',
          'Your appeal has been submitted and is waiting for review.',
        );
      }
      if (status != null) {
        return widget.labels.format(
          'account.appeal_latest_status',
          'Your latest appeal status is {status}.',
          {'status': status},
        );
      }
      return widget.labels.text(
        'account.blocked_appeal',
        'This account is blocked. You can submit one appeal for review.',
      );
    }
    return widget.labels.text(
      'account.unavailable_help',
      'This account is currently unavailable. Sign out or contact SOUL support if you need help.',
    );
  }
}
