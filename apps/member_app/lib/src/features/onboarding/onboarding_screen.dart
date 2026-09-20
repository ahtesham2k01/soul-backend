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
  static const _totalSteps = 15;
  final _name = TextEditingController();
  final _dob = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _nationality = TextEditingController();
  int _step = 0;
  bool _busy = true;
  String? _error;
  final Map<String, String?> _answers = {};
  final Set<String> _intentions = {};
  final Set<String> _languageCodes = {};
  List<SpokenLanguageChoice> _languages = const [];
  List<ReligionChoice> _religions = const [];
  final List<ReligionChoice> _religionPath = [];
  List<String> _missing = const [];

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _city.dispose();
    _country.dispose();
    _nationality.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      final results = await Future.wait<Object>([
        repository.profile(),
        repository.spokenLanguages(),
      ]);
      final profile = results[0] as Map<String, dynamic>;
      final languages = results[1] as List<SpokenLanguageChoice>;
      if (!mounted) return;
      setState(() {
        _name.text = profile['first_name']?.toString() ?? '';
        _dob.text = profile['date_of_birth']?.toString() ?? '';
        _city.text = profile['city_name']?.toString() ?? '';
        _country.text = profile['country_code']?.toString() ?? '';
        _nationality.text = profile['nationality_country_code']?.toString() ?? '';
        for (final key in ['gender', 'marital_status', 'profession_status', 'smoking', 'alcohol', 'current_children', 'future_children']) {
          _answers[key] = profile[key]?.toString();
        }
        _intentions.addAll(_stringList(profile['intentions']));
        final savedLanguages = profile['spoken_languages'];
        if (savedLanguages is List) {
          _languageCodes.addAll(savedLanguages.whereType<Map>().map((item) => item['code']?.toString() ?? '').where((code) => code.isNotEmpty));
        }
        _languages = languages;
      });
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _stringList(Object? value) => value is List ? value.map((item) => item.toString()).toList(growable: false) : const [];

  Future<void> _continue() async {
    final validation = _validation();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    final payload = _payload();
    setState(() { _busy = true; _error = null; });
    try {
      if (payload.isNotEmpty) await ref.read(onboardingRepositoryProvider).saveProfile(payload);
      if (!mounted) return;
      if (_step == 12) {
        await _loadReligion();
      } else {
        setState(() => _step++);
      }
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, Object?> _payload() => switch (_step) {
        0 => {'first_name': _name.text.trim()},
        1 => {'date_of_birth': _dob.text.trim()},
        2 => {'gender': _answers['gender']},
        3 => {'city_name': _city.text.trim(), 'country_code': _country.text.trim().toUpperCase()},
        4 => {'nationality_country_code': _nationality.text.trim().toUpperCase()},
        5 => {'marital_status': _answers['marital_status']},
        6 => {'intentions': _intentions.toList()},
        7 => {'profession_status': _answers['profession_status']},
        8 => {'spoken_language_codes': _languageCodes.toList()},
        9 => {'smoking': _answers['smoking']},
        10 => {'alcohol': _answers['alcohol']},
        11 => {'current_children': _answers['current_children']},
        12 => {'future_children': _answers['future_children']},
        _ => const {},
      };

  String? _validation() {
    if (_step == 0 && _name.text.trim().length < 2) return 'Enter your first name.';
    if (_step == 1 && !_isAdultDate(_dob.text.trim())) return 'Enter a valid date in YYYY-MM-DD format. You must be 18 or older.';
    if (_step == 2 && _answers['gender'] == null) return 'Select your gender.';
    if (_step == 3 && (_city.text.trim().isEmpty || !_countryCode(_country))) return 'Enter your real city and a two-letter country code.';
    if (_step == 4 && !_countryCode(_nationality)) return 'Enter your two-letter nationality country code.';
    if (_step == 5 && _answers['marital_status'] == null) return 'Select your marital status.';
    if (_step == 6 && _intentions.isEmpty) return 'Select at least one intention.';
    if (_step == 7 && _answers['profession_status'] == null) return 'Select your profession status.';
    if (_step == 8 && _languageCodes.isEmpty) return 'Select at least one language.';
    if (_step >= 9 && _step <= 12 && _answers[_fieldForStep(_step)] == null) return 'Select an answer to continue.';
    return null;
  }

  bool _countryCode(TextEditingController controller) => RegExp(r'^[A-Za-z]{2}$').hasMatch(controller.text.trim());

  bool _isAdultDate(String input) {
    final birthDate = DateTime.tryParse(input);
    if (birthDate == null) return false;
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
    return age >= 18 && age <= 120;
  }

  String _fieldForStep(int step) => const {9: 'smoking', 10: 'alcohol', 11: 'current_children', 12: 'future_children'}[step]!;

  Future<void> _loadReligion() async {
    final options = await ref.read(onboardingRepositoryProvider).religionOptions(country: _country.text.trim().toUpperCase());
    if (mounted) setState(() { _step = 13; _religions = options; });
  }

  Future<void> _chooseReligion(ReligionChoice choice) async {
    setState(() { _busy = true; _error = null; });
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      final next = choice.hasChildren
          ? await repository.religionOptions(parentId: choice.id, country: _country.text.trim().toUpperCase())
          : const <ReligionChoice>[];
      if (!mounted) return;
      setState(() { _religionPath.add(choice); _religions = next; });
      if (!choice.hasChildren) {
        await repository.saveReligion(selectedNodeId: choice.id, country: _country.text.trim().toUpperCase());
        if (!mounted) return;
        setState(() => _step = 14);
        await _loadReadiness();
      }
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadReadiness() async {
    final data = await ref.read(onboardingRepositoryProvider).readiness();
    final readiness = data['readiness'];
    if (!mounted || readiness is! Map) return;
    setState(() => _missing = _stringList(readiness['missing_requirements']));
  }

  void _back() {
    if (_step == 13 && _religionPath.isNotEmpty) {
      setState(() => _religionPath.removeLast());
      _reloadReligionLevel();
    } else if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _reloadReligionLevel() async {
    setState(() => _busy = true);
    try {
      final parent = _religionPath.isEmpty ? null : _religionPath.last.id;
      final options = await ref.read(onboardingRepositoryProvider).religionOptions(parentId: parent, country: _country.text.trim().toUpperCase());
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [IconButton(onPressed: _busy ? null : _back, icon: const Icon(Icons.arrow_back)), const Spacer(), const Icon(Icons.info_outline)]),
              const SizedBox(height: 14),
              LinearProgressIndicator(value: (_step + 1) / _totalSteps, minHeight: 5, borderRadius: BorderRadius.circular(99), color: SoulColors.lime, backgroundColor: SoulColors.line),
              const SizedBox(height: 30),
              Expanded(child: _busy && _step == 0 ? const Center(child: CircularProgressIndicator()) : _content()),
              if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
              if (_step < 13)
                SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                  onPressed: _busy ? null : _continue,
                  style: ElevatedButton.styleFrom(backgroundColor: SoulColors.lime, foregroundColor: SoulColors.ink),
                  child: Text(_busy ? 'Please wait…' : widget.labels.text('common.continue', 'Continue'), style: const TextStyle(fontWeight: FontWeight.w800)),
                )),
            ]),
          ),
        ),
      );

  Widget _content() => switch (_step) {
        0 => _TextStep(title: 'What should we call you?', hint: 'First name', controller: _name),
        1 => _TextStep(title: 'What’s your date of birth?', hint: 'YYYY-MM-DD', controller: _dob, keyboardType: TextInputType.datetime),
        2 => _singleChoice('Select your gender.', 'gender', const [('man', 'Man'), ('woman', 'Woman')]),
        3 => _LocationStep(city: _city, country: _country),
        4 => _TextStep(title: 'What is your nationality?', hint: 'Two-letter country code, e.g. PK', controller: _nationality),
        5 => _singleChoice('What is your marital status?', 'marital_status', const [('never_married', 'Never married'), ('married', 'Married'), ('separated', 'Separated'), ('divorced', 'Divorced'), ('widowed', 'Widowed')]),
        6 => _MultiChoiceStep(title: 'What are you looking for?', choices: const [('marriage', 'Marriage'), ('serious_relationship', 'Serious relationship'), ('casual_dating', 'Dating')], selected: _intentions, maximum: 3, onChanged: () => setState(() {})),
        7 => _singleChoice('What best describes your work?', 'profession_status', const [('employed', 'Employed'), ('self_employed', 'Self-employed'), ('student', 'Student'), ('homemaker', 'Homemaker'), ('unemployed', 'Not currently working'), ('retired', 'Retired'), ('other', 'Other')]),
        8 => _LanguageStep(languages: _languages, selected: _languageCodes, onChanged: () => setState(() {})),
        9 => _singleChoice('Do you smoke?', 'smoking', _lifestyleChoices),
        10 => _singleChoice('Do you drink alcohol?', 'alcohol', _lifestyleChoices),
        11 => _singleChoice('Do you have children?', 'current_children', const [('no', 'No'), ('yes_living_with_me', 'Yes, living with me'), ('yes_not_living_with_me', 'Yes, not living with me'), ('prefer_not_to_say', 'Prefer not to say')]),
        12 => _singleChoice('How do you feel about children in future?', 'future_children', const [('want_children', 'Want children'), ('do_not_want_children', 'Do not want children'), ('open_to_children', 'Open to children'), ('not_sure', 'Not sure'), ('prefer_not_to_say', 'Prefer not to say')]),
        13 => _ReligionStep(path: _religionPath, options: _religions, busy: _busy, onSelected: _chooseReligion, onRetry: _reloadReligionLevel),
        _ => _CompletionStep(missing: _missing),
      };

  Widget _singleChoice(String title, String field, List<(String, String)> choices) => _SingleChoiceStep(
        title: title,
        choices: choices,
        selected: _answers[field],
        onSelected: (value) => setState(() => _answers[field] = value),
      );
}

const _lifestyleChoices = [('no', 'No'), ('occasionally', 'Occasionally'), ('yes', 'Yes'), ('prefer_not_to_say', 'Prefer not to say')];

class _TextStep extends StatelessWidget {
  const _TextStep({required this.title, required this.hint, required this.controller, this.keyboardType = TextInputType.text});
  final String title;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Your answer is saved, so you can safely continue later.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 28),
        TextField(controller: controller, keyboardType: keyboardType, decoration: InputDecoration(hintText: hint)),
      ]);
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({required this.city, required this.country});
  final TextEditingController city;
  final TextEditingController country;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Where do you live?', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Use your real current city. Precise coordinates are never shown publicly.'),
        const SizedBox(height: 24),
        TextField(controller: city, decoration: const InputDecoration(hintText: 'City')),
        const SizedBox(height: 14),
        TextField(controller: country, textCapitalization: TextCapitalization.characters, maxLength: 2, decoration: const InputDecoration(hintText: 'Country code, e.g. PK')),
      ]);
}

class _SingleChoiceStep extends StatelessWidget {
  const _SingleChoiceStep({required this.title, required this.choices, required this.selected, required this.onSelected});
  final String title;
  final List<(String, String)> choices;
  final String? selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 22),
        Expanded(child: ListView.separated(itemCount: choices.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, index) {
          final choice = choices[index];
          return _ChoiceTile(label: choice.$2, selected: selected == choice.$1, onTap: () => onSelected(choice.$1));
        })),
      ]);
}

class _MultiChoiceStep extends StatelessWidget {
  const _MultiChoiceStep({required this.title, required this.choices, required this.selected, required this.maximum, required this.onChanged});
  final String title;
  final List<(String, String)> choices;
  final Set<String> selected;
  final int maximum;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Choose up to $maximum.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        for (final choice in choices) Padding(padding: const EdgeInsets.only(bottom: 10), child: _ChoiceTile(label: choice.$2, selected: selected.contains(choice.$1), onTap: () {
          if (selected.contains(choice.$1)) { selected.remove(choice.$1); } else if (selected.length < maximum) { selected.add(choice.$1); }
          onChanged();
        })),
      ]);
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({required this.languages, required this.selected, required this.onChanged});
  final List<SpokenLanguageChoice> languages;
  final Set<String> selected;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Which languages do you speak?', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Select at least one. You can add more later.'),
        const SizedBox(height: 18),
        Expanded(child: languages.isEmpty ? const Center(child: Text('Languages are unavailable. Try again shortly.')) : ListView.separated(itemCount: languages.length, separatorBuilder: (_, __) => const SizedBox(height: 9), itemBuilder: (_, index) {
          final language = languages[index];
          return _ChoiceTile(label: language.label, selected: selected.contains(language.code), onTap: () { selected.contains(language.code) ? selected.remove(language.code) : selected.add(language.code); onChanged(); });
        })),
      ]);
}

class _ReligionStep extends StatelessWidget {
  const _ReligionStep({required this.path, required this.options, required this.busy, required this.onSelected, required this.onRetry});
  final List<ReligionChoice> path;
  final List<ReligionChoice> options;
  final bool busy;
  final ValueChanged<ReligionChoice> onSelected;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(path.isEmpty ? 'Select your religion or belief.' : 'Select the next relevant detail.', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        if (path.isNotEmpty) Text(path.map((item) => item.label).join(' / ')),
        const SizedBox(height: 20),
        if (busy) const Expanded(child: Center(child: CircularProgressIndicator())) else if (options.isEmpty) Expanded(child: Center(child: OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry options')))) else Expanded(child: ListView.separated(itemCount: options.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, index) {
          final item = options[index];
          return _ChoiceTile(label: item.label, selected: false, onTap: () => onSelected(item));
        })),
      ]);
}

class _CompletionStep extends StatelessWidget {
  const _CompletionStep({required this.missing});
  final List<String> missing;
  @override
  Widget build(BuildContext context) {
    final profileMissing = missing.where((item) => item != 'cover_photo' && item != 'clear_face_photo').toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.check_circle, color: SoulColors.lime, size: 54),
      const SizedBox(height: 18),
      Text(profileMissing.isEmpty ? 'Core profile complete' : 'Almost there', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Text(profileMissing.isEmpty ? 'Your answers and religion path are saved. Add your public cover and clear-face photos next.' : 'These required answers still need attention: ${profileMissing.join(', ')}.'),
      const SizedBox(height: 24),
      const Card(child: Padding(padding: EdgeInsets.all(18), child: Row(children: [Icon(Icons.lock_outline), SizedBox(width: 12), Expanded(child: Text('Exact location and detailed religion answers follow your privacy settings and are never used as hard-coded assumptions.'))]))),
    ]);
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(color: Colors.white, borderRadius: BorderRadius.circular(11), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(11), child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        decoration: BoxDecoration(border: Border.all(color: selected ? SoulColors.lime : SoulColors.line, width: selected ? 1.5 : 1), borderRadius: BorderRadius.circular(11)),
        child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: SoulColors.ink, fontWeight: FontWeight.w600, fontSize: 16))), Icon(selected ? Icons.check_circle : Icons.chevron_right, color: selected ? SoulColors.lime : SoulColors.muted)]),
      )));
}
