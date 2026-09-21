import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/api_client.dart';
import '../../core/soul_design.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'legal_submission_screen.dart';
import 'onboarding_repository.dart';
import 'photo_onboarding_screen.dart';

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
  static const _steps = <String>[
    'name',
    'dob',
    'gender',
    'location',
    'religion',
    'profession',
    'education',
    'photos',
    'intentions',
    'nationality',
    'grew_up',
    'height',
    'marital_status',
    'religious_practice',
    'prayer',
    'diet',
    'smoking',
    'alcohol',
    'current_children',
    'future_children',
    'relocation',
    'family_involvement',
    'languages',
    'interests',
    'traits',
    'bio',
    'complete',
  ];

  final _name = TextEditingController();
  final _dob = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _nationality = TextEditingController();
  final _grewUpIn = TextEditingController();
  final _bio = TextEditingController();

  final Map<String, String?> _answers = {};
  final Set<String> _intentions = {};
  final Set<String> _languageCodes = {};
  final Set<String> _interests = {};
  final Set<String> _traits = {};

  List<SpokenLanguageChoice> _languages = const [];
  List<ProfileChoice> _interestOptions = const [];
  List<ProfileChoice> _traitOptions = const [];
  List<ReligionChoice> _religions = const [];
  final List<ReligionChoice> _religionPath = [];
  List<String> _missing = const [];

  int _step = 0;
  int _heightCm = 173;
  bool _busy = true;
  bool _photosReviewed = false;
  String? _error;

  String get _key => _steps[_step];
  double get _progress => (_step + 1) / _steps.length;

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
    _grewUpIn.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      final values = await Future.wait<Object>([
        repository.profile(),
        repository.catalog(),
      ]);

      final profile = values[0] as Map<String, dynamic>;
      final catalog = values[1] as OnboardingCatalog;

      _name.text = profile['first_name']?.toString() ?? '';
      _dob.text = profile['date_of_birth']?.toString() ?? '';
      _city.text = profile['city_name']?.toString() ?? '';
      _country.text = profile['country_code']?.toString() ?? '';
      _nationality.text =
          profile['nationality_country_code']?.toString() ?? '';
      _grewUpIn.text = profile['grew_up_in']?.toString() ?? '';
      _bio.text = profile['bio']?.toString() ?? '';
      _heightCm = (profile['height_cm'] as num?)?.toInt() ?? 173;

      for (final field in [
        'gender',
        'marital_status',
        'profession_status',
        'smoking',
        'alcohol',
        'current_children',
        'future_children',
        'education',
        'religious_practice',
        'prayer',
        'diet',
        'relocation_preference',
        'family_involvement_preference',
      ]) {
        _answers[field] = profile[field]?.toString();
      }

      _intentions.addAll(_stringList(profile['intentions']));
      _interests.addAll(_stringList(profile['interests']));
      _traits.addAll(_stringList(profile['personality_traits']));

      final savedLanguages = profile['spoken_languages'];
      if (savedLanguages is List) {
        _languageCodes.addAll(
          savedLanguages
              .whereType<Map>()
              .map((item) => item['code']?.toString() ?? '')
              .where((value) => value.isNotEmpty),
        );
      }

      if (!mounted) return;
      setState(() {
        _languages = catalog.languages;
        _interestOptions = catalog.interests;
        _traitOptions = catalog.personalityTraits;
      });
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _stringList(Object? value) => value is List
      ? value.map((item) => item.toString()).toList(growable: false)
      : const [];

  Future<void> _continue() async {
    if (_key == 'photos') {
      await _finishPhotoStep();
      return;
    }
    if (_key == 'complete') {
      await _reviewAndSubmit();
      return;
    }
    if (_key == 'religion') {
      if (_religions.isEmpty && _religionPath.isEmpty) {
        await _loadReligion();
      }
      return;
    }

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
      await _advance();
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _advance() async {
    if (_step >= _steps.length - 1) return;
    setState(() {
      _step++;
      _error = null;
    });

    if (_key == 'religion') {
      await _loadReligion();
    } else if (_key == 'complete') {
      await _loadReadiness();
    }
  }

  Map<String, Object?> _payload() => switch (_key) {
        'name' => {'first_name': _name.text.trim()},
        'dob' => {'date_of_birth': _dob.text.trim()},
        'gender' => {'gender': _answers['gender']},
        'location' => {
            'city_name': _city.text.trim(),
            'country_code': _country.text.trim().toUpperCase(),
          },
        'profession' => {'profession_status': _answers['profession_status']},
        'education' => {'education': _answers['education']},
        'intentions' => {'intentions': _intentions.toList(growable: false)},
        'nationality' => {
            'nationality_country_code':
                _nationality.text.trim().toUpperCase(),
          },
        'grew_up' => {'grew_up_in': _grewUpIn.text.trim()},
        'height' => {'height_cm': _heightCm},
        'marital_status' => {'marital_status': _answers['marital_status']},
        'religious_practice' => {
            'religious_practice': _answers['religious_practice'],
          },
        'prayer' => {'prayer': _answers['prayer']},
        'diet' => {'diet': _answers['diet']},
        'smoking' => {'smoking': _answers['smoking']},
        'alcohol' => {'alcohol': _answers['alcohol']},
        'current_children' => {
            'current_children': _answers['current_children'],
          },
        'future_children' => {
            'future_children': _answers['future_children'],
          },
        'relocation' => {
            'relocation_preference': _answers['relocation_preference'],
          },
        'family_involvement' => {
            'family_involvement_preference':
                _answers['family_involvement_preference'],
          },
        'languages' => {
            'spoken_language_codes': _languageCodes.toList(growable: false),
          },
        'interests' => {
            'interests': _interests.toList(growable: false),
          },
        'traits' => {
            'personality_traits': _traits.toList(growable: false),
          },
        'bio' => {
            'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
          },
        _ => const {},
      };

  String? _validation() {
    switch (_key) {
      case 'name':
        return _name.text.trim().length < 2
            ? 'Enter your first name.'
            : null;
      case 'dob':
        return !_isAdultDate(_dob.text.trim())
            ? 'Choose a valid date of birth. You must be 18 or older.'
            : null;
      case 'gender':
        return _answers['gender'] == null ? 'Select your gender.' : null;
      case 'location':
        return _city.text.trim().isEmpty || !_countryCode(_country)
            ? 'Enter your current city and a two-letter country code.'
            : null;
      case 'profession':
        return _answers['profession_status'] == null
            ? 'Select your profession status.'
            : null;
      case 'education':
        return _answers['education'] == null
            ? 'Select your education.'
            : null;
      case 'intentions':
        return _intentions.isEmpty
            ? 'Select at least one intention.'
            : null;
      case 'nationality':
        return !_countryCode(_nationality)
            ? 'Enter your two-letter nationality country code.'
            : null;
      case 'grew_up':
        return _grewUpIn.text.trim().isEmpty
            ? 'Tell us where you grew up.'
            : null;
      case 'marital_status':
        return _answers['marital_status'] == null
            ? 'Select your marital status.'
            : null;
      case 'religious_practice':
        return _answers['religious_practice'] == null
            ? 'Select an answer.'
            : null;
      case 'prayer':
        return _answers['prayer'] == null ? 'Select an answer.' : null;
      case 'diet':
        return _answers['diet'] == null ? 'Select an answer.' : null;
      case 'smoking':
        return _answers['smoking'] == null ? 'Select an answer.' : null;
      case 'alcohol':
        return _answers['alcohol'] == null ? 'Select an answer.' : null;
      case 'current_children':
        return _answers['current_children'] == null
            ? 'Select an answer.'
            : null;
      case 'future_children':
        return _answers['future_children'] == null
            ? 'Select an answer.'
            : null;
      case 'relocation':
        return _answers['relocation_preference'] == null
            ? 'Select an answer.'
            : null;
      case 'family_involvement':
        return _answers['family_involvement_preference'] == null
            ? 'Select an answer.'
            : null;
      case 'languages':
        return _languageCodes.isEmpty
            ? 'Select at least one language.'
            : null;
      default:
        return null;
    }
  }

  bool _countryCode(TextEditingController controller) =>
      RegExp(r'^[A-Za-z]{2}$').hasMatch(controller.text.trim());

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

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dob.text) ??
        DateTime(now.year - 24, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked == null) return;
    setState(() {
      _dob.text =
          picked.toIso8601String().substring(0, 10);
    });
  }

  Future<void> _loadReligion() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final parent =
          _religionPath.isEmpty ? null : _religionPath.last.id;
      final options =
          await ref.read(onboardingRepositoryProvider).religionOptions(
                parentId: parent,
                country: _country.text.trim().toUpperCase(),
              );
      if (!mounted) return;
      setState(() => _religions = options);
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseReligion(ReligionChoice choice) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      if (choice.hasChildren) {
        final next = await repository.religionOptions(
          parentId: choice.id,
          country: _country.text.trim().toUpperCase(),
        );
        if (!mounted) return;
        setState(() {
          _religionPath.add(choice);
          _religions = next;
        });
      } else {
        _religionPath.add(choice);
        await repository.saveReligion(
          selectedNodeId: choice.id,
          country: _country.text.trim().toUpperCase(),
        );
        if (!mounted) return;
        await _advance();
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
    setState(() {
      _missing = _stringList(readiness['missing_requirements']);
      _photosReviewed = !_missing.contains('cover_photo') &&
          !_missing.contains('clear_face_photo');
    });
  }

  Future<void> _openPhotos() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const PhotoOnboardingScreen(),
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

  Future<void> _finishPhotoStep() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _loadReadiness();
      if (!_photosReviewed) {
        if (mounted) {
          setState(() {
            _error =
                'Add an approved public cover photo and a clear-face photo to continue.';
          });
        }
        return;
      }
      await _advance();
    } on SoulApiFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewAndSubmit() async {
    final correction = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => LegalSubmissionScreen(
          repository: ref.read(onboardingRepositoryProvider),
          labels: widget.labels,
        ),
      ),
    );
    if (!mounted || correction == null) return;
    if (correction == 'onboarding.photos') {
      await _openPhotos();
    } else {
      setState(() => _step = 0);
    }
  }

  void _back() {
    if (_key == 'religion' && _religionPath.isNotEmpty) {
      setState(() => _religionPath.removeLast());
      _loadReligion();
      return;
    }
    if (_step > 0) {
      setState(() {
        _step--;
        _error = null;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFooter = _key != 'religion' && _key != 'complete';

    return SoulStepScaffold(
      progress: _progress,
      onBack: _busy ? () {} : _back,
      onInfo: _showInfo,
      footer: showFooter
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_key == 'photos') ...[
                  SoulPrimaryButton(
                    label: _photosReviewed
                        ? 'Continue'
                        : 'Upload photos',
                    busy: _busy,
                    icon: _photosReviewed
                        ? null
                        : Icons.add_photo_alternate_outlined,
                    onPressed:
                        _photosReviewed ? _continue : _openPhotos,
                  ),
                  if (!_photosReviewed) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : _finishPhotoStep,
                      child: const Text('I already uploaded them'),
                    ),
                  ],
                ] else
                  SoulPrimaryButton(
                    label:
                        widget.labels.text('common.continue', 'Continue'),
                    busy: _busy,
                    onPressed: _continue,
                  ),
              ],
            )
          : _key == 'complete'
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_missing.isEmpty)
                      SoulPrimaryButton(
                        label: 'Review & Finish',
                        busy: _busy,
                        onPressed: _reviewAndSubmit,
                      )
                    else
                      SoulPrimaryButton(
                        label: 'Review missing details',
                        busy: _busy,
                        onPressed: () => setState(() => _step = 0),
                      ),
                  ],
                )
              : _error == null
                  ? null
                  : Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
      child: _busy && _step == 0
          ? const Center(child: CircularProgressIndicator())
          : _content(),
    );
  }

  Widget _content() => switch (_key) {
        'name' => _textStep(
            title: 'What should we call you?',
            subtitle: 'Tell us the name you want people to see on SOUL.',
            label: 'Full Name',
            hint: 'Your name',
            controller: _name,
          ),
        'dob' => _dobStep(),
        'gender' => _singleChoice(
            'Select your gender.',
            'gender',
            const [('man', 'Men'), ('woman', 'Women')],
            iconFor: (value) => value == 'man'
                ? Icons.man_rounded
                : Icons.woman_rounded,
          ),
        'location' => _locationStep(),
        'religion' => _religionStep(),
        'profession' => _singleChoice(
            'Select your profession.',
            'profession_status',
            const [
              ('employed', 'Employed'),
              ('self_employed', 'Self-employed'),
              ('student', 'Student'),
              ('homemaker', 'Homemaker'),
              ('unemployed', 'Not currently working'),
              ('retired', 'Retired'),
              ('other', 'Other'),
            ],
            searchable: true,
          ),
        'education' => _singleChoice(
            'Select your education.',
            'education',
            const [
              ('High school', 'High school'),
              ('Non-degree qualification', 'Non-degree qualification'),
              ('Undergraduate degree', 'Undergraduate degree'),
              ('Postgraduate degree', 'Postgraduate degree'),
              ('Doctorate', 'Doctorate'),
              ('Other education level', 'Other education level'),
            ],
          ),
        'photos' => _photoStep(),
        'intentions' => _multiChoice(
            title: "What's your intentions?",
            subtitle:
                'Choose what best describes what you want from SOUL.',
            choices: const [
              ('marriage', 'Marriage'),
              ('serious_relationship', 'Serious relationship'),
              ('casual_dating', 'Dating'),
            ],
            selected: _intentions,
            maximum: 3,
          ),
        'nationality' => _textStep(
            title: "What's your nationality?",
            subtitle:
                'Enter the two-letter country code for your nationality.',
            label: 'Nationality',
            hint: 'PK',
            controller: _nationality,
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
          ),
        'grew_up' => _textStep(
            title: 'Where did you grow up?',
            subtitle: 'This helps people understand your background.',
            label: 'Grew up in',
            hint: 'Pakistan',
            controller: _grewUpIn,
          ),
        'height' => _heightStep(),
        'marital_status' => _singleChoice(
            "What's your marital status?",
            'marital_status',
            const [
              ('never_married', 'Never married'),
              ('divorced', 'Divorced'),
              ('separated', 'Separated'),
              ('widowed', 'Widowed'),
              ('married', 'Married'),
            ],
          ),
        'religious_practice' => _singleChoice(
            'How religious are you?',
            'religious_practice',
            const [
              ('very_practising', 'Very practising'),
              ('practising', 'Practising'),
              ('moderately_practising', 'Moderately practising'),
              ('not_practising', 'Not practising'),
              ('prefer_not_to_say', 'Prefer not to say'),
            ],
          ),
        'prayer' => _singleChoice(
            'How often do you pray?',
            'prayer',
            const [
              ('always', 'Always'),
              ('usually', 'Usually'),
              ('sometimes', 'Sometimes'),
              ('never', 'Never'),
              ('prefer_not_to_say', 'Prefer not to say'),
            ],
          ),
        'diet' => _singleChoice(
            'Tell us about your diet.',
            'diet',
            const [
              ('faith_aligned', 'I follow my faith-based diet'),
              ('flexible', 'I am flexible'),
              ('no_preference', 'No preference'),
              ('prefer_not_to_say', 'Prefer not to say'),
            ],
          ),
        'smoking' => _singleChoice(
            'Do you smoke?',
            'smoking',
            const [
              ('no', 'No'),
              ('occasionally', 'Occasionally'),
              ('yes', 'Yes'),
              ('prefer_not_to_say', 'Prefer not to say'),
            ],
          ),
        'alcohol' => _singleChoice(
            'Do you drink alcohol?',
            'alcohol',
            const [
              ('no', 'No'),
              ('occasionally', 'Occasionally'),
              ('yes', 'Yes'),
              ('prefer_not_to_say', 'Prefer not to say'),
            ],
          ),
        'current_children' => _singleChoice(
            'Do you have children?',
            'current_children',
            const [
              ('no', 'No'),
              ('yes_living_with_me', 'Yes, living with me'),
              ('yes_not_living_with_me', 'Yes, not living with me'),
              ('prefer_not_to_say', 'Prefer not to say'),
            ],
          ),
        'future_children' => _singleChoice(
            'What are your family plans?',
            'future_children',
            const [
              ('want_children', 'Wants children'),
              ('open_to_children', 'Open to having children'),
              ('do_not_want_children', "Doesn't want children"),
              ('not_sure', 'Not sure'),
              ('prefer_not_to_say', 'Prefer not to say'),
            ],
          ),
        'relocation' => _singleChoice(
            'Would you relocate for marriage?',
            'relocation_preference',
            const [
              ('open_to_relocation', 'Open to relocation'),
              ('not_open_to_relocation', 'Not open to relocation'),
              ('agree_together', 'Agree together'),
              ('prefer_not_to_say', 'Prefer not to say'),
            ],
          ),
        'family_involvement' => _singleChoice(
            'When would you like to involve family?',
            'family_involvement_preference',
            const [
              ('immediately', 'Immediately'),
              ('agree_together', 'Agree together'),
              ('later', 'Later down the line'),
              ('prefer_not_to_say', 'Prefer not to say'),
            ],
          ),
        'languages' => _languageStep(),
        'interests' => _catalogStep(
            title: 'What are your interests?',
            subtitle:
                'Select up to 15 interests to make your profile stand out.',
            options: _interestOptions,
            selected: _interests,
            maximum: 15,
          ),
        'traits' => _catalogStep(
            title: 'Describe your personality!',
            subtitle: 'Select up to 5 characteristics.',
            options: _traitOptions,
            selected: _traits,
            maximum: 5,
          ),
        'bio' => _bioStep(),
        _ => _completionStep(),
      };

  Widget _textStep({
    required String title,
    required String subtitle,
    required String label,
    required String hint,
    required TextEditingController controller,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) =>
      ListView(
        padding: EdgeInsets.zero,
        children: [
          SoulPageTitle(title, subtitle: subtitle),
          const SizedBox(height: 26),
          Text(
            label,
            style: const TextStyle(
              color: SoulColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLength: maxLength,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
            ),
          ),
        ],
      );

  Widget _dobStep() => ListView(
        padding: EdgeInsets.zero,
        children: [
          const SoulPageTitle(
            "What's your DOB?",
            subtitle:
                'Your age helps SOUL show you age-appropriate matches.',
          ),
          const SizedBox(height: 26),
          const Text(
            'DOB',
            style: TextStyle(
              color: SoulColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _dob,
            readOnly: true,
            onTap: _pickDob,
            decoration: const InputDecoration(
              hintText: 'YYYY-MM-DD',
              suffixIcon: Icon(Icons.calendar_month_outlined),
            ),
          ),
        ],
      );

  Widget _locationStep() => ListView(
        padding: EdgeInsets.zero,
        children: [
          const SoulPageTitle(
            'Where do you live?',
            subtitle:
                'Your current city is used for distance matching. Your exact location is never shown publicly.',
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _city,
            decoration: const InputDecoration(
              labelText: 'Current city',
              hintText: 'Karachi',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _country,
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Country code',
              hintText: 'PK',
              counterText: '',
              prefixIcon: Icon(Icons.public_rounded),
            ),
          ),
        ],
      );

  Widget _singleChoice(
    String title,
    String field,
    List<(String, String)> choices, {
    IconData Function(String)? iconFor,
    bool searchable = false,
  }) {
    final search = TextEditingController();
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final query = search.text.trim().toLowerCase();
        final visible = query.isEmpty
            ? choices
            : choices
                .where((item) => item.$2.toLowerCase().contains(query))
                .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SoulPageTitle(title),
            if (searchable) ...[
              const SizedBox(height: 18),
              SoulSearchField(
                controller: search,
                hint: 'Search here...',
                onChanged: (_) => setLocalState(() {}),
              ),
            ],
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 9),
                itemBuilder: (_, index) {
                  final choice = visible[index];
                  final icon = iconFor?.call(choice.$1);
                  return SoulChoiceTile(
                    label: choice.$2,
                    selected: _answers[field] == choice.$1,
                    leading: icon == null
                        ? null
                        : CircleAvatar(
                            radius: 17,
                            backgroundColor: SoulColors.softSurface,
                            child: Icon(
                              icon,
                              color: SoulColors.ink,
                              size: 21,
                            ),
                          ),
                    onTap: () =>
                        setState(() => _answers[field] = choice.$1),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _multiChoice({
    required String title,
    required String subtitle,
    required List<(String, String)> choices,
    required Set<String> selected,
    required int maximum,
  }) =>
      ListView(
        padding: EdgeInsets.zero,
        children: [
          SoulPageTitle(title, subtitle: subtitle),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: choices.map((choice) {
              final active = selected.contains(choice.$1);
              return FilterChip(
                label: Text(choice.$2),
                selected: active,
                selectedColor: SoulColors.limeLight,
                backgroundColor: SoulColors.softSurface,
                checkmarkColor: SoulColors.ink,
                side: BorderSide(
                  color: active
                      ? SoulColors.limeLight
                      : SoulColors.line,
                ),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      if (selected.length < maximum) {
                        selected.add(choice.$1);
                      }
                    } else {
                      selected.remove(choice.$1);
                    }
                  });
                },
              );
            }).toList(growable: false),
          ),
        ],
      );

  Widget _religionStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoulPageTitle(
            _religionPath.isEmpty
                ? 'Select your religion.'
                : 'Select the next relevant detail.',
            subtitle: _religionPath.isEmpty
                ? 'SOUL adapts the next steps to your selected religion and region.'
                : _religionPath.map((item) => item.label).join('  /  '),
          ),
          const SizedBox(height: 18),
          if (_busy)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_religions.isEmpty)
            Expanded(
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: _loadReligion,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry options'),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _religions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 9),
                itemBuilder: (_, index) {
                  final item = _religions[index];
                  return SoulChoiceTile(
                    label: item.label,
                    selected: false,
                    trailingChevron: item.hasChildren,
                    onTap: () => _chooseReligion(item),
                  );
                },
              ),
            ),
        ],
      );

  Widget _photoStep() => ListView(
        padding: EdgeInsets.zero,
        children: [
          const SoulPageTitle(
            'Upload your photos.',
            subtitle:
                'Add a clear main profile photo. You can add private photos too.',
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _PhotoPlaceholder(
                  height: 235,
                  label: _photosReviewed
                      ? 'Photos added'
                      : 'Main profile photo',
                  large: true,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  children: [
                    _PhotoPlaceholder(height: 112, label: 'Photo 2'),
                    SizedBox(height: 10),
                    _PhotoPlaceholder(height: 112, label: 'Photo 3'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: SoulColors.softSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 21,
                  color: SoulColors.ink,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Screenshot protection is used for protected private-photo viewing where the device supports it.',
                    style: TextStyle(
                      color: SoulColors.muted,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _heightStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SoulPageTitle(
            'How tall are you?',
            subtitle: 'Select your height.',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListWheelScrollView.useDelegate(
              itemExtent: 48,
              diameterRatio: 1.7,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(
                initialItem: (_heightCm - 122).clamp(0, 98),
              ),
              onSelectedItemChanged: (index) =>
                  setState(() => _heightCm = 122 + index),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: 99,
                builder: (context, index) {
                  final cm = 122 + index;
                  final inches = (cm / 2.54).round();
                  final feet = inches ~/ 12;
                  final remaining = inches % 12;
                  final active = cm == _heightCm;
                  return Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 120),
                      style: TextStyle(
                        color: active
                            ? SoulColors.ink
                            : SoulColors.muted,
                        fontSize: active ? 20 : 15,
                        fontWeight:
                            active ? FontWeight.w800 : FontWeight.w500,
                      ),
                      child: Text(
                        "${cm}cm   $feet'${remaining}\"",
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );

  Widget _languageStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SoulPageTitle(
            'Select language',
            subtitle: 'Choose the languages you speak.',
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _languages.isEmpty
                ? const Center(
                    child: Text('Languages are unavailable right now.'),
                  )
                : ListView.separated(
                    itemCount: _languages.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final language = _languages[index];
                      return SoulChoiceTile(
                        label: language.label,
                        selected:
                            _languageCodes.contains(language.code),
                        onTap: () {
                          setState(() {
                            if (_languageCodes.contains(language.code)) {
                              _languageCodes.remove(language.code);
                            } else {
                              _languageCodes.add(language.code);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      );

  Widget _catalogStep({
    required String title,
    required String subtitle,
    required List<ProfileChoice> options,
    required Set<String> selected,
    required int maximum,
  }) =>
      ListView(
        padding: EdgeInsets.zero,
        children: [
          SoulPageTitle(title, subtitle: subtitle),
          const SizedBox(height: 18),
          if (options.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 50),
              child: Center(
                child: Text('Options are unavailable right now.'),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((choice) {
                final active = selected.contains(choice.value);
                return FilterChip(
                  label: Text(choice.label),
                  selected: active,
                  selectedColor: SoulColors.limeLight,
                  backgroundColor: SoulColors.softSurface,
                  checkmarkColor: SoulColors.ink,
                  side: BorderSide(
                    color: active
                        ? SoulColors.limeLight
                        : SoulColors.line,
                  ),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        if (selected.length < maximum) {
                          selected.add(choice.value);
                        }
                      } else {
                        selected.remove(choice.value);
                      }
                    });
                  },
                );
              }).toList(growable: false),
            ),
        ],
      );

  Widget _bioStep() => ListView(
        padding: EdgeInsets.zero,
        children: [
          const SoulPageTitle(
            'Bio',
            subtitle:
                'A short, sincere introduction helps people understand you better.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _bio,
            minLines: 5,
            maxLines: 9,
            maxLength: 2000,
            decoration: const InputDecoration(
              hintText: 'Tell people a little about yourself...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      );

  Widget _completionStep() {
    final profileMissing = _missing
        .where(
          (item) =>
              item != 'cover_photo' && item != 'clear_face_photo',
        )
        .toList(growable: false);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 28),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: SoulColors.limeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 43,
              color: SoulColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          _missing.isEmpty
              ? 'Your profile is ready to review'
              : 'Almost there',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SoulColors.ink,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          _missing.isEmpty
              ? 'Review the community commitments before submitting your profile.'
              : profileMissing.isNotEmpty
                  ? 'Some required profile details still need attention.'
                  : 'Your required photos still need approval.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SoulColors.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        if (_missing.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SoulColors.softSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _missing.join('  •  ').replaceAll('_', ' '),
              style: const TextStyle(
                color: SoulColors.ink,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Text(
            'Your answers build your SOUL profile. Optional faith and lifestyle details can be edited later, and privacy controls determine what other members can see.',
            style: TextStyle(
              color: SoulColors.ink,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({
    required this.height,
    required this.label,
    this.large = false,
  });

  final double height;
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xfffbfcf8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: SoulColors.limeLight,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  large
                      ? Icons.add_photo_alternate_outlined
                      : Icons.add_rounded,
                  color: SoulColors.lime,
                  size: large ? 34 : 26,
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SoulColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
