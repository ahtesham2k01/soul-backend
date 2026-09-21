import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../core/soul_design.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'onboarding_repository.dart';
import 'optional_profile_details_screen.dart';
import 'notification_permission_screen.dart';
import 'location_repository.dart';
import 'legal_submission_screen.dart';
import 'photo_onboarding_screen.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(apiClientProvider)),
);

final onboardingLocationRepositoryProvider =
    Provider<OnboardingLocationRepository>(
  (ref) => OnboardingLocationRepository(ref.watch(apiClientProvider)),
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
  bool _resolvingLocation = false;
  String? _error;
  String? _locationMessage;
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
      final results = await Future.wait<Object?>([
        repository.profile(),
        repository.spokenLanguages(),
        repository.religionProfile(),
      ]);
      final profile = results[0] as Map<String, dynamic>;
      final languages = results[1] as List<SpokenLanguageChoice>;
      final religionProfile = results[2] as ReligionProfileSnapshot?;
      final country = profile['country_code']?.toString().toUpperCase() ?? '';
      final restoredReligionPath =
          religionProfile?.restoreChoices() ?? const <ReligionChoice>[];
      final resumeStep = _resumeStep(profile, religionProfile != null);

      if (!mounted) return;
      setState(() {
        _name.text = profile['first_name']?.toString() ?? '';
        _dob.text = profile['date_of_birth']?.toString() ?? '';
        _city.text = profile['city_name']?.toString() ?? '';
        _country.text = country;
        _nationality.text =
            profile['nationality_country_code']?.toString() ?? '';
        for (final key in [
          'gender',
          'marital_status',
          'profession_status',
          'smoking',
          'alcohol',
          'current_children',
          'future_children',
        ]) {
          _answers[key] = profile[key]?.toString();
        }
        _intentions
          ..clear()
          ..addAll(_stringList(profile['intentions']));
        _languageCodes.clear();
        final savedLanguages = profile['spoken_languages'];
        if (savedLanguages is List) {
          _languageCodes.addAll(
            savedLanguages
                .whereType<Map>()
                .map((item) => item['code']?.toString() ?? '')
                .where((value) => value.isNotEmpty),
          );
        }
        _languages = languages;
        _religionPath
          ..clear()
          ..addAll(restoredReligionPath);
        _step = resumeStep;
      });

      if (resumeStep == 5) {
        await _loadReligion();
      } else if (resumeStep == 14) {
        await _loadReadiness();
      }
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int _resumeStep(Map<String, dynamic> profile, bool hasReligion) {
    if ((profile['first_name']?.toString().trim().length ?? 0) < 2) return 0;
    if (!_isAdultDate(profile['date_of_birth']?.toString() ?? '')) return 1;
    if ((profile['gender']?.toString().isEmpty ?? true)) return 2;
    final city = profile['city_name']?.toString().trim() ?? '';
    final country = profile['country_code']?.toString().trim() ?? '';
    if (city.isEmpty || !_validCountryCode(country)) return 3;
    final nationality =
        profile['nationality_country_code']?.toString().trim() ?? '';
    if (!_validCountryCode(nationality)) return 4;
    if (!hasReligion) return 5;
    if ((profile['marital_status']?.toString().isEmpty ?? true)) return 6;
    if (_stringList(profile['intentions']).isEmpty) return 7;
    if ((profile['profession_status']?.toString().isEmpty ?? true)) return 8;
    final spoken = profile['spoken_languages'];
    if (spoken is! List || spoken.isEmpty) return 9;
    if ((profile['smoking']?.toString().isEmpty ?? true)) return 10;
    if ((profile['alcohol']?.toString().isEmpty ?? true)) return 11;
    if ((profile['current_children']?.toString().isEmpty ?? true)) return 12;
    if ((profile['future_children']?.toString().isEmpty ?? true)) return 13;
    return 14;
  }

  List<String> _stringList(Object? value) => value is List ? value.map((item) => item.toString()).toList(growable: false) : const [];

  Future<void> _resolveCurrentLocation() async {
    if (_resolvingLocation) return;
    setState(() {
      _resolvingLocation = true;
      _locationMessage = null;
    });
    try {
      final location =
          await ref.read(onboardingLocationRepositoryProvider).resolveCurrent();
      if (!mounted) return;
      setState(() {
        _city.text = location.city;
        _country.text = location.countryCode;
        _locationMessage = '${location.city}, ${location.countryCode}';
      });
    } on LocationResolutionFailure catch (failure) {
      if (mounted) setState(() => _locationMessage = failure.message);
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _locationMessage = failure.message);
    } finally {
      if (mounted) setState(() => _resolvingLocation = false);
    }
  }

  Future<void> _continue() async {
    final validation = _validation();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    final payload = _payload();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (payload.isNotEmpty) {
        await ref.read(onboardingRepositoryProvider).saveProfile(payload);
      }
      if (!mounted) return;
      if (_step == 4) {
        await _loadReligion();
      } else if (_step == 13) {
        setState(() => _step = 14);
        await _loadReadiness();
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
        6 => {'marital_status': _answers['marital_status']},
        7 => {'intentions': _intentions.toList()},
        8 => {'profession_status': _answers['profession_status']},
        9 => {'spoken_language_codes': _languageCodes.toList()},
        10 => {'smoking': _answers['smoking']},
        11 => {'alcohol': _answers['alcohol']},
        12 => {'current_children': _answers['current_children']},
        13 => {'future_children': _answers['future_children']},
        _ => const {},
      };

  String? _validation() {
    if (_step == 0 && _name.text.trim().length < 2) return widget.labels.text('onboarding.validation_first_name', 'Enter your first name.');
    if (_step == 1 && !_isAdultDate(_dob.text.trim())) return widget.labels.text('onboarding.validation_dob', 'Enter a valid date in YYYY-MM-DD format. You must be 18 or older.');
    if (_step == 2 && _answers['gender'] == null) return widget.labels.text('onboarding.validation_gender', 'Select your gender.');
    if (_step == 3 && (_city.text.trim().isEmpty || !_countryCode(_country))) return widget.labels.text('onboarding.validation_city_country', 'Enter your real city and a two-letter country code.');
    if (_step == 4 && !_countryCode(_nationality)) return widget.labels.text('onboarding.validation_nationality', 'Enter your two-letter nationality country code.');
    if (_step == 6 && _answers['marital_status'] == null) return widget.labels.text('onboarding.validation_marital', 'Select your marital status.');
    if (_step == 7 && _intentions.isEmpty) return widget.labels.text('onboarding.validation_intention', 'Select at least one intention.');
    if (_step == 8 && _answers['profession_status'] == null) return widget.labels.text('onboarding.validation_profession', 'Select your profession status.');
    if (_step == 9 && _languageCodes.isEmpty) return widget.labels.text('onboarding.validation_language', 'Select at least one language.');
    if (_step >= 10 && _step <= 13 && _answers[_fieldForStep(_step)] == null) return widget.labels.text('onboarding.validation_answer', 'Select an answer to continue.');
    return null;
  }

  bool _countryCode(TextEditingController controller) =>
      _validCountryCode(controller.text);

  bool _validCountryCode(String value) =>
      RegExp(r'^[A-Za-z]{2}$').hasMatch(value.trim());

  bool _isAdultDate(String input) {
    final birthDate = DateTime.tryParse(input);
    if (birthDate == null) return false;
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
    return age >= 18 && age <= 120;
  }

  String _fieldForStep(int step) => const {
        10: 'smoking',
        11: 'alcohol',
        12: 'current_children',
        13: 'future_children',
      }[step]!;

  Future<void> _loadReligion() async {
    final options = await ref
        .read(onboardingRepositoryProvider)
        .religionOptions(country: _country.text.trim().toUpperCase());
    if (!mounted) return;
    setState(() {
      _step = 5;
      _religionPath.clear();
      _religions = options;
    });
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
              country: _country.text.trim().toUpperCase(),
            )
          : const <ReligionChoice>[];
      if (!mounted) return;
      setState(() {
        _religionPath.add(choice);
        _religions = next;
      });
      if (!choice.hasChildren || next.isEmpty) {
        await repository.saveReligion(
          selectedNodeId: choice.id,
          country: _country.text.trim().toUpperCase(),
        );
        if (!mounted) return;
        setState(() => _step = 6);
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

  Future<void> _openOptionalDetails() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OptionalProfileDetailsScreen(
          repository: ref.read(onboardingRepositoryProvider),
          labels: widget.labels,
        ),
      ),
    );
    if (!mounted || changed != true) return;
    setState(() => _busy = true);
    try {
      await _loadReadiness();
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPhotos() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PhotoOnboardingScreen(labels: widget.labels),
      ),
    );
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await _loadReadiness();
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewAndSubmit() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NotificationPermissionScreen(labels: widget.labels),
      ),
    );
    if (!mounted) return;

    final outcome = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => LegalSubmissionScreen(
          repository: ref.read(onboardingRepositoryProvider),
          labels: widget.labels,
        ),
      ),
    );
    if (!mounted || outcome == null) return;
    if (outcome == 'home') {
      ref.invalidate(sessionRouteProvider);
      return;
    }
    if (outcome == 'onboarding.photos') {
      await _openPhotos();
    } else {
      setState(() => _step = 0);
    }
  }

  void _back() {
    if (_step == 5 && _religionPath.isNotEmpty) {
      setState(() => _religionPath.removeLast());
      _reloadReligionLevel();
    } else if (_step == 6 && _religionPath.isNotEmpty) {
      setState(() {
        _step = 5;
        _religionPath.removeLast();
      });
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
  Widget build(BuildContext context) => SoulStepScaffold(
        progress: (_step + 1) / _totalSteps,
        onBack: _busy ? () {} : _back,
        footer: _step < 14 && _step != 5
            ? SoulPrimaryButton(
                label: widget.labels.text('common.continue', 'Continue'),
                onPressed: _busy ? null : _continue,
                busy: _busy,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _busy && _step == 0
                  ? const Center(child: CircularProgressIndicator())
                  : _content(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      );

  Widget _content() => switch (_step) {
        0 => _TextStep(
            title: widget.labels.text('profile.first_name', 'First name'),
            hint: widget.labels.text('profile.first_name', 'First name'),
            controller: _name,
          ),
        1 => _TextStep(
            title: widget.labels.text('profile.date_of_birth', 'Date of birth'),
            hint: 'YYYY-MM-DD',
            controller: _dob,
            keyboardType: TextInputType.datetime,
          ),
        2 => _singleChoice(
            widget.labels.text('profile.gender', 'Gender'),
            'gender',
            [
              ('man', widget.labels.text('profile.man', 'Man')),
              ('woman', widget.labels.text('profile.woman', 'Woman')),
            ],
          ),
        3 => _LocationStep(
            labels: widget.labels,
            city: _city,
            country: _country,
            resolving: _resolvingLocation,
            message: _locationMessage,
            onUseCurrentLocation: _resolveCurrentLocation,
          ),
        4 => _TextStep(
            title: widget.labels.text('profile.nationality', 'Nationality'),
            hint: 'PK',
            controller: _nationality,
          ),
        5 => _ReligionStep(
            labels: widget.labels,
            path: _religionPath,
            options: _religions,
            busy: _busy,
            onSelected: _chooseReligion,
            onRetry: _reloadReligionLevel,
          ),
        6 => _singleChoice(
            widget.labels.text('profile.marital_status', 'Marital status'),
            'marital_status',
            [
              ('never_married', widget.labels.text('profile.never_married', 'Never married')),
              ('married', widget.labels.text('profile.married', 'Married')),
              ('separated', widget.labels.text('profile.separated', 'Separated')),
              ('divorced', widget.labels.text('profile.divorced', 'Divorced')),
              ('widowed', widget.labels.text('profile.widowed', 'Widowed')),
            ],
          ),
        7 => _MultiChoiceStep(
            labels: widget.labels,
            title: widget.labels.text('profile.intentions', 'What are you looking for?'),
            choices: [
              ('marriage', widget.labels.text('profile.intention_marriage', 'Marriage')),
              ('serious_relationship', widget.labels.text('profile.intention_serious', 'Serious relationship')),
              ('casual_dating', widget.labels.text('profile.intention_casual', 'Casual dating')),
            ],
            selected: _intentions,
            maximum: 3,
            onChanged: () => setState(() {}),
          ),
        8 => _singleChoice(
            widget.labels.text('profile.profession', 'Profession or status'),
            'profession_status',
            [
              ('employed', widget.labels.text('profile.employed', 'Employed')),
              ('self_employed', widget.labels.text('profile.self_employed', 'Self-employed')),
              ('student', widget.labels.text('profile.student', 'Student')),
              ('homemaker', widget.labels.text('profile.homemaker', 'Homemaker')),
              ('unemployed', widget.labels.text('profile.unemployed', 'Unemployed')),
              ('retired', widget.labels.text('profile.retired', 'Retired')),
              ('other', widget.labels.text('profile.other', 'Other')),
            ],
          ),
        9 => _LanguageStep(
            labels: widget.labels,
            languages: _languages,
            selected: _languageCodes,
            onChanged: () => setState(() {}),
          ),
        10 => _singleChoice(
            widget.labels.text('profile.smoking', 'Do you smoke?'),
            'smoking',
            _lifestyleChoices(widget.labels),
          ),
        11 => _singleChoice(
            widget.labels.text('profile.alcohol', 'Do you drink alcohol?'),
            'alcohol',
            _lifestyleChoices(widget.labels),
          ),
        12 => _singleChoice(
            widget.labels.text('profile.children_now', 'Do you have children?'),
            'current_children',
            [
              ('no', widget.labels.text('profile.answer_no', 'No')),
              ('yes_living_with_me', widget.labels.text('profile.children_living_with_me', 'Yes, living with me')),
              ('yes_not_living_with_me', widget.labels.text('profile.children_not_living_with_me', 'Yes, not living with me')),
              ('prefer_not_to_say', widget.labels.text('common.prefer_not_to_say', 'Prefer not to say')),
            ],
          ),
        13 => _singleChoice(
            widget.labels.text('profile.children_future', 'Do you want children?'),
            'future_children',
            [
              ('want_children', widget.labels.text('profile.want_children', 'Want children')),
              ('do_not_want_children', widget.labels.text('profile.do_not_want_children', 'Do not want children')),
              ('open_to_children', widget.labels.text('profile.open_to_children', 'Open to children')),
              ('not_sure', widget.labels.text('profile.not_sure', 'Not sure')),
              ('prefer_not_to_say', widget.labels.text('common.prefer_not_to_say', 'Prefer not to say')),
            ],
          ),
        _ => _CompletionStep(
            labels: widget.labels,
            missing: _missing,
            onAddDetails: _openOptionalDetails,
            onAddPhotos: _openPhotos,
            onSubmit: _reviewAndSubmit,
          ),
      };

  Widget _singleChoice(String title, String field, List<(String, String)> choices) => _SingleChoiceStep(
        title: title,
        choices: choices,
        selected: _answers[field],
        onSelected: (value) => setState(() => _answers[field] = value),
      );
}

List<(String, String)> _lifestyleChoices(BootstrapState labels) => [
      ('no', labels.text('profile.answer_no', 'No')),
      ('occasionally', labels.text('profile.answer_occasionally', 'Occasionally')),
      ('yes', labels.text('profile.answer_yes', 'Yes')),
      ('prefer_not_to_say', labels.text('common.prefer_not_to_say', 'Prefer not to say')),
    ];

class _TextStep extends StatelessWidget {
  const _TextStep({required this.title, required this.hint, required this.controller, this.keyboardType = TextInputType.text});
  final String title;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoulPageTitle(title),
          const SizedBox(height: 28),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );
}

class _LocationStep extends StatelessWidget {
  const _LocationStep({
    required this.labels,
    required this.city,
    required this.country,
    required this.resolving,
    required this.onUseCurrentLocation,
    this.message,
  });

  final BootstrapState labels;
  final TextEditingController city;
  final TextEditingController country;
  final bool resolving;
  final VoidCallback onUseCurrentLocation;
  final String? message;

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          SoulPageTitle(
            labels.text('profile.city', 'Current city'),
            subtitle:
                'Use your current city for matching. Exact coordinates are not shown publicly.',
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: resolving ? null : onUseCurrentLocation,
            icon: resolving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              resolving
                  ? labels.text('location.detecting', 'Detecting your location...')
                  : 'Use current location',
            ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(message!),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: city,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: labels.text('profile.city', 'Current city'),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: country,
            textCapitalization: TextCapitalization.characters,
            maxLength: 2,
            decoration: InputDecoration(
              labelText: labels.text('profile.country', 'Country of residence'),
              hintText: 'PK',
            ),
          ),
        ],
      );
}

class _SingleChoiceStep extends StatelessWidget {
  const _SingleChoiceStep({required this.title, required this.choices, required this.selected, required this.onSelected});
  final String title;
  final List<(String, String)> choices;
  final String? selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SoulPageTitle(title),
        const SizedBox(height: 22),
        Expanded(child: ListView.separated(itemCount: choices.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, index) {
          final choice = choices[index];
          return _ChoiceTile(label: choice.$2, selected: selected == choice.$1, onTap: () => onSelected(choice.$1));
        })),
      ]);
}

class _MultiChoiceStep extends StatelessWidget {
  const _MultiChoiceStep({
    required this.labels,
    required this.title,
    required this.choices,
    required this.selected,
    required this.maximum,
    required this.onChanged,
  });

  final BootstrapState labels;
  final String title;
  final List<(String, String)> choices;
  final Set<String> selected;
  final int maximum;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SoulPageTitle(title, subtitle: labels.format('common.choose_up_to', 'Choose up to {count}.', {'count': maximum.toString()})),
        const SizedBox(height: 20),
        for (final choice in choices) Padding(padding: const EdgeInsets.only(bottom: 10), child: _ChoiceTile(label: choice.$2, selected: selected.contains(choice.$1), onTap: () {
          if (selected.contains(choice.$1)) { selected.remove(choice.$1); } else if (selected.length < maximum) { selected.add(choice.$1); }
          onChanged();
        })),
      ]);
}

class _LanguageStep extends StatelessWidget {
  const _LanguageStep({
    required this.labels,
    required this.languages,
    required this.selected,
    required this.onChanged,
  });
  final BootstrapState labels;
  final List<SpokenLanguageChoice> languages;
  final Set<String> selected;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SoulPageTitle(
          labels.text('profile.languages', 'Languages you speak'),
          subtitle: labels.text('onboarding.language_helper', 'Select at least one. You can add more later.'),
        ),
        const SizedBox(height: 18),
        Expanded(child: languages.isEmpty ? Center(child: Text(labels.text('onboarding.languages_unavailable', 'Languages are unavailable. Try again shortly.'))) : ListView.separated(itemCount: languages.length, separatorBuilder: (_, __) => const SizedBox(height: 9), itemBuilder: (_, index) {
          final language = languages[index];
          return _ChoiceTile(label: language.label, selected: selected.contains(language.code), onTap: () { selected.contains(language.code) ? selected.remove(language.code) : selected.add(language.code); onChanged(); });
        })),
      ]);
}

class _ReligionStep extends StatelessWidget {
  const _ReligionStep({
    required this.labels,
    required this.path,
    required this.options,
    required this.busy,
    required this.onSelected,
    required this.onRetry,
  });
  final BootstrapState labels;
  final List<ReligionChoice> path;
  final List<ReligionChoice> options;
  final bool busy;
  final ValueChanged<ReligionChoice> onSelected;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SoulPageTitle(
          path.isEmpty
              ? labels.text('profile.religion', 'Religion or belief')
              : path.last.label,
        ),
        if (path.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: path
                .map((item) => Chip(
                      label: Text(item.label),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 20),
        if (busy)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (options.isEmpty)
          Expanded(
            child: Center(
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(labels.text('common.retry', 'Try again')),
              ),
            ),
          )
        else
          Expanded(child: ListView.separated(itemCount: options.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, index) {
          final item = options[index];
          return _ChoiceTile(label: item.label, selected: false, onTap: () => onSelected(item));
        })),
      ]);
}

class _CompletionStep extends StatelessWidget {
  const _CompletionStep({
    required this.labels,
    required this.missing,
    required this.onAddDetails,
    required this.onAddPhotos,
    required this.onSubmit,
  });

  final BootstrapState labels;
  final List<String> missing;
  final VoidCallback onAddDetails;
  final VoidCallback onAddPhotos;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final profileMissing = missing
        .where((item) => item != 'cover_photo' && item != 'clear_face_photo')
        .toList();
    return ListView(
      children: [
        const Icon(Icons.check_circle, color: SoulColors.lime, size: 54),
        const SizedBox(height: 18),
        Text(
          profileMissing.isEmpty
              ? labels.text('onboarding.review', 'Review your profile')
              : labels.text('onboarding.changes_required', 'Changes are required'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: onAddDetails,
          icon: const Icon(Icons.tune_rounded),
          label: Text(labels.text('onboarding.optional_profile_details', 'Optional profile details')),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onAddPhotos,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(labels.text('photos.title', 'Add your photos')),
        ),
        if (missing.isEmpty) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(labels.text('onboarding.submit', 'Submit profile')),
          ),
        ],
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final genderChoice = label == 'Men' || label == 'Women';
    return SoulChoiceTile(
      label: label,
      selected: selected,
      onTap: onTap,
      leading: genderChoice
          ? CircleAvatar(
              radius: 20,
              backgroundColor: SoulColors.softSurface,
              child: Icon(
                label == 'Men'
                    ? Icons.person_rounded
                    : Icons.person_2_rounded,
                color: SoulColors.forest,
              ),
            )
          : null,
    );
  }
}