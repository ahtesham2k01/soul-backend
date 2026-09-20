import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(apiClientProvider)),
);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({required this.labels, super.key});

  final BootstrapState labels;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _dob = TextEditingController();
  int _step = 0;
  String? _gender;
  String? _error;
  bool _busy = true;
  List<ReligionChoice> _religions = const [];
  final List<ReligionChoice> _religionPath = [];
  String? _countryCode;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final profile = await ref.read(onboardingRepositoryProvider).profile();
      if (!mounted) return;
      setState(() {
        _name.text = profile['first_name']?.toString() ?? '';
        _dob.text = profile['date_of_birth']?.toString() ?? '';
        _gender = profile['gender']?.toString();
        _countryCode = profile['country_code']?.toString();
      });
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continue() async {
    final validation = _validateStep();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      if (_step == 0) {
        await repository.saveProfile({'first_name': _name.text.trim()});
      } else if (_step == 1) {
        await repository.saveProfile({'date_of_birth': _dob.text.trim()});
      } else if (_step == 2) {
        await repository.saveProfile({'gender': _gender});
      }
      if (!mounted) return;
      if (_step < 2) {
        setState(() => _step++);
      } else {
        final options = await repository.religionOptions(country: _countryCode);
        if (!mounted) return;
        setState(() {
          _step = 3;
          _religions = options;
        });
      }
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateStep() {
    if (_step == 0 && _name.text.trim().length < 2) {
      return 'Enter your first name.';
    }
    if (_step == 1 && !_isAdultDate(_dob.text.trim())) {
      return 'Enter a valid date in YYYY-MM-DD format. You must be 18 or older.';
    }
    if (_step == 2 && _gender == null) return 'Select your gender.';
    return null;
  }

  bool _isAdultDate(String input) {
    final birthDate = DateTime.tryParse(input);
    if (birthDate == null) return false;
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age >= 18 && age <= 120;
  }

  Future<void> _chooseReligion(ReligionChoice choice) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      final next = choice.hasChildren
          ? await repository.religionOptions(
              parentId: choice.id,
              country: _countryCode,
            )
          : const <ReligionChoice>[];
      if (!mounted) return;
      setState(() {
        _religionPath.add(choice);
        _religions = next;
      });
      if (!choice.hasChildren) {
        await repository.saveReligion(
          selectedNodeId: choice.id,
          country: _countryCode,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Religion preferences saved.')),
        );
      }
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() {
    if (_step == 3 && _religionPath.isNotEmpty) {
      setState(() {
        _religionPath.removeLast();
        _religions = const [];
      });
      _reloadReligionLevel();
      return;
    }
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _reloadReligionLevel() async {
    setState(() => _busy = true);
    try {
      final parent = _religionPath.isEmpty ? null : _religionPath.last.id;
      final options = await ref.read(onboardingRepositoryProvider).religionOptions(
            parentId: parent,
            country: _countryCode,
          );
      if (mounted) setState(() => _religions = options);
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(onPressed: _busy ? null : _back, icon: const Icon(Icons.arrow_back)),
                    const Spacer(),
                    const Icon(Icons.info_outline),
                  ],
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: (_step + 1) / 4,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(99),
                  color: SoulColors.lime,
                  backgroundColor: SoulColors.line,
                ),
                const SizedBox(height: 30),
                Expanded(child: _busy && _step == 0 ? const Center(child: CircularProgressIndicator()) : _content()),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                if (_step < 3)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SoulColors.lime,
                        foregroundColor: SoulColors.ink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        _busy
                            ? 'Please wait…'
                            : widget.labels.text('common.continue', 'Continue'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _content() => switch (_step) {
        0 => _TextStep(
            title: 'What should we call you?',
            hint: 'First name',
            controller: _name,
            keyboardType: TextInputType.name,
          ),
        1 => _TextStep(
            title: 'What’s your date of birth?',
            hint: 'YYYY-MM-DD',
            controller: _dob,
            keyboardType: TextInputType.datetime,
          ),
        2 => _GenderStep(
            selected: _gender,
            onSelected: (value) => setState(() => _gender = value),
          ),
        _ => _ReligionStep(
            path: _religionPath,
            options: _religions,
            busy: _busy,
            onSelected: _chooseReligion,
            onRetry: _reloadReligionLevel,
          ),
      };
}

class _TextStep extends StatelessWidget {
  const _TextStep({
    required this.title,
    required this.hint,
    required this.controller,
    required this.keyboardType,
  });

  final String title;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Each answer is saved so you can safely continue later.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );
}

class _GenderStep extends StatelessWidget {
  const _GenderStep({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select your gender.', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          for (final item in const [('man', 'Man'), ('woman', 'Woman')])
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ChoiceTile(
                label: item.$2,
                selected: selected == item.$1,
                onTap: () => onSelected(item.$1),
              ),
            ),
        ],
      );
}

class _ReligionStep extends StatelessWidget {
  const _ReligionStep({
    required this.path,
    required this.options,
    required this.busy,
    required this.onSelected,
    required this.onRetry,
  });

  final List<ReligionChoice> path;
  final List<ReligionChoice> options;
  final bool busy;
  final ValueChanged<ReligionChoice> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            path.isEmpty
                ? 'Select your religion.'
                : 'Select the next relevant detail.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          if (path.isNotEmpty)
            Text(
              path.map((item) => item.label).join(' / '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 20),
          if (busy)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (options.isEmpty)
            Expanded(
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry options'),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final item = options[index];
                  return _ChoiceTile(
                    label: item.label,
                    selected: false,
                    onTap: () => onSelected(item),
                  );
                },
              ),
            ),
        ],
      );
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? SoulColors.lime : SoulColors.line,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: SoulColors.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.chevron_right,
                  color: selected ? SoulColors.lime : SoulColors.muted,
                ),
              ],
            ),
          ),
        ),
      );
}
