import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'profile_repository.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.repository,
    required this.labels,
    required this.initial,
  });

  final ProfileRepository repository;
  final BootstrapState labels;
  final Map<String, dynamic> initial;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _firstName;
  late final TextEditingController _dob;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _nationality;
  late final TextEditingController _bio;
  late final TextEditingController _height;
  late final TextEditingController _jobTitle;
  late final TextEditingController _employer;
  late final TextEditingController _education;
  late final TextEditingController _grewUpIn;
  late final TextEditingController _ethnicOrigin;
  late final TextEditingController _religiousPractice;
  late final TextEditingController _prayer;
  late final TextEditingController _diet;
  late final TextEditingController _dress;
  late final TextEditingController _relocation;
  late final TextEditingController _familyInvolvement;

  late String? _gender;
  late String? _maritalStatus;
  late String? _professionStatus;
  late String? _smoking;
  late String? _alcohol;
  late String? _currentChildren;
  late String? _futureChildren;
  late Set<String> _intentions;
  late Set<String> _interests;
  late Set<String> _traits;
  late Set<String> _languageCodes;
  late Set<String> _withheldFields;
  late bool _detailedReligionVisible;
  ProfileCatalog? _catalog;
  bool _catalogLoading = true;

  bool _dirty = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _firstName = TextEditingController(text: _string(p['first_name']));
    _dob = TextEditingController(text: _string(p['date_of_birth']));
    _city = TextEditingController(text: _string(p['city_name']));
    _country = TextEditingController(text: _string(p['country_code']));
    _nationality =
        TextEditingController(text: _string(p['nationality_country_code']));
    _bio = TextEditingController(text: _string(p['bio']));
    _height = TextEditingController(
      text: p['height_cm']?.toString() ?? '',
    );
    _jobTitle = TextEditingController(text: _string(p['job_title']));
    _employer = TextEditingController(text: _string(p['employer']));
    _education = TextEditingController(text: _string(p['education']));
    _grewUpIn = TextEditingController(text: _string(p['grew_up_in']));
    _ethnicOrigin = TextEditingController(text: _string(p['ethnic_origin']));
    _religiousPractice =
        TextEditingController(text: _string(p['religious_practice']));
    _prayer = TextEditingController(text: _string(p['prayer']));
    _diet = TextEditingController(text: _string(p['diet']));
    _dress = TextEditingController(text: _string(p['dress']));
    _relocation =
        TextEditingController(text: _string(p['relocation_preference']));
    _familyInvolvement = TextEditingController(
      text: _string(p['family_involvement_preference']),
    );
    _gender = p['gender']?.toString();
    _maritalStatus = p['marital_status']?.toString();
    _professionStatus = p['profession_status']?.toString();
    _smoking = p['smoking']?.toString();
    _alcohol = p['alcohol']?.toString();
    _currentChildren = p['current_children']?.toString();
    _futureChildren = p['future_children']?.toString();
    _intentions = _strings(p['intentions']).toSet();
    _interests = _strings(p['interests']).toSet();
    _traits = _strings(p['personality_traits']).toSet();
    _withheldFields = _strings(p['prefer_not_to_say_fields']).toSet();
    final spoken = p['spoken_languages'];
    _languageCodes = spoken is List
        ? spoken
            .whereType<Map>()
            .map((item) => item['code']?.toString() ?? '')
            .where((value) => value.isNotEmpty)
            .toSet()
        : <String>{};
    _detailedReligionVisible = p['detailed_religion_visible'] != false;

    for (final controller in [
      _firstName,
      _dob,
      _city,
      _country,
      _nationality,
    ]) {
      controller.addListener(_markDirty);
    }
    for (final entry in <String, TextEditingController>{
      'bio': _bio,
      'height_cm': _height,
      'job_title': _jobTitle,
      'employer': _employer,
      'education': _education,
      'grew_up_in': _grewUpIn,
      'ethnic_origin': _ethnicOrigin,
      'religious_practice': _religiousPractice,
      'prayer': _prayer,
      'diet': _diet,
      'dress': _dress,
      'relocation_preference': _relocation,
      'family_involvement_preference': _familyInvolvement,
    }.entries) {
      entry.value.addListener(() => _optionalChanged(entry.key));
    }
    _loadCatalog();
  }

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _dob,
      _city,
      _country,
      _nationality,
      _bio,
      _height,
      _jobTitle,
      _employer,
      _education,
      _grewUpIn,
      _ethnicOrigin,
      _religiousPractice,
      _prayer,
      _diet,
      _dress,
      _relocation,
      _familyInvolvement,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _string(Object? value) => value?.toString() ?? '';

  List<String> _strings(Object? value) => value is List
      ? value.map((item) => item.toString()).toList(growable: false)
      : const [];

  Future<void> _loadCatalog() async {
    try {
      final catalog = await widget.repository.catalog();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _catalogLoading = false;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _error ??= failure.message;
      });
    }
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  void _optionalChanged(String field) {
    final removed = _withheldFields.remove(field);
    if (mounted && (!_dirty || removed)) {
      setState(() => _dirty = true);
    }
  }

  void _setOptionalCollection(
    String field,
    Set<String> value,
    void Function(Set<String>) assign,
  ) {
    _setValue(() {
      _withheldFields.remove(field);
      assign(value);
    });
  }

  void _setWithheld(String field, bool withheld) {
    _setValue(() {
      if (withheld) {
        final controller = <String, TextEditingController>{
          'bio': _bio,
          'education': _education,
          'height_cm': _height,
          'job_title': _jobTitle,
          'employer': _employer,
          'grew_up_in': _grewUpIn,
          'ethnic_origin': _ethnicOrigin,
          'religious_practice': _religiousPractice,
          'prayer': _prayer,
          'diet': _diet,
          'dress': _dress,
          'relocation_preference': _relocation,
          'family_involvement_preference': _familyInvolvement,
        }[field];
        controller?.clear();

        if (field == 'interests') {
          _interests.clear();
        } else if (field == 'personality_traits') {
          _traits.clear();
        }
        _withheldFields.add(field);
      } else {
        _withheldFields.remove(field);
      }
    });
  }

  String _optionalFieldLabel(String field) => switch (field) {
        'bio' => widget.labels.text('profile.bio', 'About you'),
        'education' => widget.labels.text('profile.education', 'Education'),
        'height_cm' => widget.labels.text('profile.height', 'Height'),
        'job_title' => widget.labels.text('profile.job_title', 'Job title'),
        'employer' => widget.labels.text('profile.employer', 'Employer'),
        'grew_up_in' => widget.labels.text('profile.grew_up_in', 'Grew up in'),
        'ethnic_origin' => widget.labels.text('profile.ethnic_origin', 'Ethnic origin'),
        'religious_practice' => widget.labels.text('profile.religious_practice', 'Religious practice'),
        'prayer' => widget.labels.text('profile.prayer', 'Prayer'),
        'diet' => widget.labels.text('profile.diet', 'Diet'),
        'dress' => widget.labels.text('profile.dress', 'Dress'),
        'relocation_preference' => widget.labels.text('profile.relocation', 'Relocation preference'),
        'family_involvement_preference' => widget.labels.text('profile.family_involvement', 'Family involvement'),
        'interests' => widget.labels.text('profile.interests', 'Interests'),
        'personality_traits' => widget.labels.text('profile.traits', 'Personality traits'),
        _ => field,
      };

  void _setValue(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
      _error = null;
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _saving) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.labels.text('profile.discard_changes', 'Discard changes?'),
        ),
        content: const Text(
          'Your unsaved profile changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.labels.text('common.cancel', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(widget.labels.text('common.discard', 'Discard')),
          ),
        ],
      ),
    );
    return discard == true;
  }

  String? _validate() {
    if (_firstName.text.trim().length < 2) return 'Enter your first name.';
    final dob = DateTime.tryParse(_dob.text.trim());
    if (dob == null) return 'Enter your date of birth as YYYY-MM-DD.';
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    if (age < 18 || age > 120) return 'You must be 18 or older.';
    if (_gender == null || _gender!.isEmpty) return 'Select your gender.';
    if (_city.text.trim().isEmpty) return 'Enter your current city.';
    if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(_country.text.trim())) {
      return 'Use a 2-letter country code.';
    }
    if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(_nationality.text.trim())) {
      return 'Use a 2-letter nationality country code.';
    }
    final height = int.tryParse(_height.text.trim());
    if (_height.text.trim().isNotEmpty &&
        (height == null || height < 50 || height > 300)) {
      return 'Height must be between 50 and 300 cm.';
    }
    if (_maritalStatus == null || _maritalStatus!.isEmpty) {
      return 'Select your marital status.';
    }
    if (_professionStatus == null || _professionStatus!.isEmpty) {
      return 'Select your profession or status.';
    }
    if (_smoking == null || _smoking!.isEmpty) {
      return 'Answer the smoking question.';
    }
    if (_alcohol == null || _alcohol!.isEmpty) {
      return 'Answer the alcohol question.';
    }
    if (_currentChildren == null || _currentChildren!.isEmpty) {
      return 'Answer the current children question.';
    }
    if (_futureChildren == null || _futureChildren!.isEmpty) {
      return 'Answer the future children question.';
    }
    if (_intentions.isEmpty) return 'Select at least one intention.';
    if (_languageCodes.isEmpty) return 'Select at least one spoken language.';
    return null;
  }

  Map<String, Object?> _payload() => {
        'first_name': _firstName.text.trim(),
        'date_of_birth': _dob.text.trim(),
        'gender': _gender,
        'city_name': _city.text.trim(),
        'country_code': _country.text.trim().toUpperCase(),
        'nationality_country_code': _nationality.text.trim().isEmpty
            ? null
            : _nationality.text.trim().toUpperCase(),
        'marital_status': _maritalStatus,
        'profession_status': _professionStatus,
        'smoking': _smoking,
        'alcohol': _alcohol,
        'current_children': _currentChildren,
        'future_children': _futureChildren,
        'intentions': _intentions.toList(growable: false),
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'height_cm': _height.text.trim().isEmpty
            ? null
            : int.parse(_height.text.trim()),
        'job_title':
            _jobTitle.text.trim().isEmpty ? null : _jobTitle.text.trim(),
        'employer':
            _employer.text.trim().isEmpty ? null : _employer.text.trim(),
        'education':
            _education.text.trim().isEmpty ? null : _education.text.trim(),
        'grew_up_in':
            _grewUpIn.text.trim().isEmpty ? null : _grewUpIn.text.trim(),
        'ethnic_origin': _ethnicOrigin.text.trim().isEmpty
            ? null
            : _ethnicOrigin.text.trim(),
        'religious_practice': _religiousPractice.text.trim().isEmpty
            ? null
            : _religiousPractice.text.trim(),
        'prayer': _prayer.text.trim().isEmpty ? null : _prayer.text.trim(),
        'diet': _diet.text.trim().isEmpty ? null : _diet.text.trim(),
        'dress': _dress.text.trim().isEmpty ? null : _dress.text.trim(),
        'relocation_preference': _relocation.text.trim().isEmpty
            ? null
            : _relocation.text.trim(),
        'family_involvement_preference':
            _familyInvolvement.text.trim().isEmpty
                ? null
                : _familyInvolvement.text.trim(),
        'detailed_religion_visible': _detailedReligionVisible,
        'interests': _interests.toList(growable: false),
        'personality_traits': _traits.toList(growable: false),
        'prefer_not_to_say_fields':
            _withheldFields.toList(growable: false)..sort(),
        'spoken_language_codes': _languageCodes.toList(growable: false),
      };

  Future<void> _save() async {
    final validation = _validate();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveProfile(_payload());
      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
      });
      Navigator.of(context).pop(true);
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _openReligion() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReligionEditorScreen(
          repository: widget.repository,
          labels: widget.labels,
          countryCode: _country.text.trim().toUpperCase(),
        ),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _dirty = true);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_dirty || _saving,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _confirmDiscard() && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xfff7f7f4),
          appBar: AppBar(
            title: Text(widget.labels.text('common.edit', 'Edit')),
            actions: [
              TextButton(
                onPressed: _saving ? null : _save,
                child: Text(widget.labels.text('common.save', 'Save')),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
            children: [
              if (_error != null)
                _ErrorBanner(
                  message: _error!,
                  onClose: () => setState(() => _error = null),
                ),
              _Section(
                title: widget.labels.text('settings.personal_information', 'Personal information'),
                children: [
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.first_name',
                      'First name',
                    ),
                    controller: _firstName,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.date_of_birth',
                      'Date of birth',
                    ),
                    controller: _dob,
                    hint: 'YYYY-MM-DD',
                    keyboardType: TextInputType.datetime,
                  ),
                  _ChoiceRow(
                    selectLabel: widget.labels.text('common.select', 'Select'),
                    label: widget.labels.text('profile.gender', 'Gender'),
                    value: _gender,
                    choices: const {
                      'man': 'Man',
                      'woman': 'Woman',
                    },
                    onChanged: (value) => _setValue(() => _gender = value),
                  ),
                  _TextFieldRow(
                    label: widget.labels.text('profile.city', 'Current city'),
                    controller: _city,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.country',
                      'Country of residence',
                    ),
                    controller: _country,
                    hint: 'PK',
                    maxLength: 2,
                    capitalization: TextCapitalization.characters,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.nationality',
                      'Nationality',
                    ),
                    controller: _nationality,
                    hint: 'PK',
                    maxLength: 2,
                    capitalization: TextCapitalization.characters,
                  ),
                  _ChoiceRow(
                    selectLabel: widget.labels.text('common.select', 'Select'),
                    label: widget.labels.text(
                      'profile.marital_status',
                      'Marital status',
                    ),
                    value: _maritalStatus,
                    choices: const {
                      'never_married': 'Never married',
                      'married': 'Married',
                      'separated': 'Separated',
                      'divorced': 'Divorced',
                      'widowed': 'Widowed',
                    },
                    onChanged: (value) =>
                        _setValue(() => _maritalStatus = value),
                  ),
                ],
              ),
              _Section(
                title: widget.labels.text(
                  'profile.intentions',
                  'What are you looking for?',
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _intentionChip(
                          'marriage',
                          widget.labels.text(
                            'profile.intention_marriage',
                            'Marriage',
                          ),
                        ),
                        _intentionChip(
                          'serious_relationship',
                          widget.labels.text(
                            'profile.intention_serious',
                            'Serious relationship',
                          ),
                        ),
                        _intentionChip(
                          'casual_dating',
                          widget.labels.text(
                            'profile.intention_casual',
                            'Casual dating',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _Section(
                title: widget.labels.text('profile.religion', 'Religion or belief'),
                children: [
                  ListTile(
                    onTap: _openReligion,
                    title: Text(
                      widget.labels.text(
                        'profile.religion',
                        'Religion or belief',
                      ),
                    ),
                    subtitle: const Text(
                      'Update the complete religion / sect path.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              _Section(
                title: widget.labels.text('profile.bio', 'About you'),
                children: [
                  _TextFieldRow(
                    label: widget.labels.text('profile.bio', 'About you'),
                    controller: _bio,
                    maxLines: 5,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text('profile.height', 'Height'),
                    controller: _height,
                    hint: 'cm',
                    keyboardType: TextInputType.number,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.education',
                      'Education',
                    ),
                    controller: _education,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.job_title',
                      'Job title',
                    ),
                    controller: _jobTitle,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.employer',
                      'Employer',
                    ),
                    controller: _employer,
                  ),
                  _ChoiceRow(
                    selectLabel: widget.labels.text('common.select', 'Select'),
                    label: widget.labels.text(
                      'profile.profession',
                      'Profession or status',
                    ),
                    value: _professionStatus,
                    choices: const {
                      'employed': 'Employed',
                      'self_employed': 'Self-employed',
                      'student': 'Student',
                      'homemaker': 'Homemaker',
                      'unemployed': 'Not currently working',
                      'retired': 'Retired',
                      'other': 'Other',
                    },
                    onChanged: (value) =>
                        _setValue(() => _professionStatus = value),
                  ),
                ],
              ),
              _Section(
                title: widget.labels.text('profile.section_personality', 'Personality and interests'),
                children: [
                  _CatalogMultiSelect(
                    label: widget.labels.text(
                      'profile.interests',
                      'Interests',
                    ),
                    choices: _catalog?.interests ?? const [],
                    selected: _interests,
                    maximum: 15,
                    loading: _catalogLoading,
                    onChanged: (value) => _setOptionalCollection(
                      'interests',
                      value,
                      (next) => _interests = next,
                    ),
                  ),
                  _CatalogMultiSelect(
                    label: widget.labels.text(
                      'profile.traits',
                      'Personality traits',
                    ),
                    choices: _catalog?.personalityTraits ?? const [],
                    selected: _traits,
                    maximum: 5,
                    loading: _catalogLoading,
                    onChanged: (value) => _setOptionalCollection(
                      'personality_traits',
                      value,
                      (next) => _traits = next,
                    ),
                  ),
                  _CatalogMultiSelect(
                    label: widget.labels.text(
                      'profile.languages',
                      'Languages you speak',
                    ),
                    choices: _catalog?.languages ?? const [],
                    selected: _languageCodes,
                    loading: _catalogLoading,
                    onChanged: (value) => _setValue(() {
                      _languageCodes = value;
                    }),
                  ),
                ],
              ),
              _Section(
                title: widget.labels.text('profile.section_background', 'Background and faith'),
                children: [
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.grew_up_in',
                      'Grew up in',
                    ),
                    controller: _grewUpIn,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.ethnic_origin',
                      'Ethnic origin',
                    ),
                    controller: _ethnicOrigin,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.religious_practice',
                      'Religious practice',
                    ),
                    controller: _religiousPractice,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text('profile.prayer', 'Prayer'),
                    controller: _prayer,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text('profile.diet', 'Diet'),
                    controller: _diet,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text('profile.dress', 'Dress'),
                    controller: _dress,
                  ),
                  SwitchListTile(
                    title: Text(
                      widget.labels.text(
                        'profile.show_religion_details',
                        'Show detailed religion answers',
                      ),
                    ),
                    value: _detailedReligionVisible,
                    onChanged: (value) => _setValue(
                      () => _detailedReligionVisible = value,
                    ),
                  ),
                ],
              ),
              _Section(
                title: widget.labels.text('profile.section_future', 'Future plans'),
                children: [
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.relocation',
                      'Relocation preference',
                    ),
                    controller: _relocation,
                  ),
                  _TextFieldRow(
                    label: widget.labels.text(
                      'profile.family_involvement',
                      'Family involvement',
                    ),
                    controller: _familyInvolvement,
                  ),
                ],
              ),
              _Section(
                title: widget.labels.text(
                  'common.prefer_not_to_say',
                  'Prefer not to say',
                ),
                children: [
                  for (final field in const [
                    'bio',
                    'education',
                    'height_cm',
                    'job_title',
                    'employer',
                    'grew_up_in',
                    'ethnic_origin',
                    'religious_practice',
                    'prayer',
                    'diet',
                    'dress',
                    'relocation_preference',
                    'family_involvement_preference',
                    'interests',
                    'personality_traits',
                  ])
                    SwitchListTile.adaptive(
                      title: Text(_optionalFieldLabel(field)),
                      subtitle: Text(
                        _withheldFields.contains(field)
                            ? widget.labels.text(
                                'common.prefer_not_to_say',
                                'Prefer not to say',
                              )
                            : widget.labels.text(
                                'common.skip',
                                'Skip',
                              ),
                      ),
                      value: _withheldFields.contains(field),
                      onChanged: (value) => _setWithheld(field, value),
                    ),
                ],
              ),
              _Section(
                title: widget.labels.text('profile.section_lifestyle', 'Lifestyle'),
                children: [
                  _ChoiceRow(
                    selectLabel: widget.labels.text('common.select', 'Select'),
                    label: widget.labels.text(
                      'profile.smoking',
                      'Do you smoke?',
                    ),
                    value: _smoking,
                    choices: const {
                      'no': 'No',
                      'occasionally': 'Occasionally',
                      'yes': 'Yes',
                      'prefer_not_to_say': 'Prefer not to say',
                    },
                    onChanged: (value) =>
                        _setValue(() => _smoking = value),
                  ),
                  _ChoiceRow(
                    selectLabel: widget.labels.text('common.select', 'Select'),
                    label: widget.labels.text(
                      'profile.alcohol',
                      'Do you drink alcohol?',
                    ),
                    value: _alcohol,
                    choices: const {
                      'no': 'No',
                      'occasionally': 'Occasionally',
                      'yes': 'Yes',
                      'prefer_not_to_say': 'Prefer not to say',
                    },
                    onChanged: (value) =>
                        _setValue(() => _alcohol = value),
                  ),
                  _ChoiceRow(
                    selectLabel: widget.labels.text('common.select', 'Select'),
                    label: widget.labels.text(
                      'profile.children_now',
                      'Do you have children?',
                    ),
                    value: _currentChildren,
                    choices: const {
                      'no': 'No',
                      'yes_living_with_me': 'Yes, living with me',
                      'yes_not_living_with_me': 'Yes, not living with me',
                      'prefer_not_to_say': 'Prefer not to say',
                    },
                    onChanged: (value) =>
                        _setValue(() => _currentChildren = value),
                  ),
                  _ChoiceRow(
                    selectLabel: widget.labels.text('common.select', 'Select'),
                    label: widget.labels.text(
                      'profile.children_future',
                      'Do you want children?',
                    ),
                    value: _futureChildren,
                    choices: const {
                      'want_children': 'Want children',
                      'do_not_want_children': 'Do not want children',
                      'open_to_children': 'Open to children',
                      'not_sure': 'Not sure',
                      'prefer_not_to_say': 'Prefer not to say',
                    },
                    onChanged: (value) =>
                        _setValue(() => _futureChildren = value),
                  ),
                ],
              ),
              if (_saving)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      );

  Widget _intentionChip(String value, String label) => FilterChip(
        label: Text(label),
        selected: _intentions.contains(value),
        selectedColor: SoulColors.limeLight,
        checkmarkColor: SoulColors.ink,
        onSelected: (selected) {
          _setValue(() {
            if (selected) {
              if (_intentions.length < 3) _intentions.add(value);
            } else {
              _intentions.remove(value);
            }
          });
        },
      );
}

class ReligionEditorScreen extends StatefulWidget {
  const ReligionEditorScreen({
    super.key,
    required this.repository,
    required this.labels,
    required this.countryCode,
  });

  final ProfileRepository repository;
  final BootstrapState labels;
  final String countryCode;

  @override
  State<ReligionEditorScreen> createState() => _ReligionEditorScreenState();
}

class _ReligionEditorScreenState extends State<ReligionEditorScreen> {
  final List<ReligionOption> _path = [];
  List<ReligionOption> _options = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? parentId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final options = await widget.repository.religionOptions(
        parentId: parentId,
        country: widget.countryCode.isEmpty ? null : widget.countryCode,
      );
      if (!mounted) return;
      setState(() {
        _options = options;
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

  Future<void> _select(ReligionOption option) async {
    if (option.hasChildren) {
      setState(() => _path.add(option));
      await _load(parentId: option.id);
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.repository.saveReligion(
        selectedNodeId: option.id,
        country: widget.countryCode.isEmpty ? null : widget.countryCode,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _backLevel() async {
    if (_path.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _path.removeLast());
    await _load(parentId: _path.isEmpty ? null : _path.last.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _loading ? null : _backLevel,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            widget.labels.text('profile.religion', 'Religion or belief'),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_path.isNotEmpty) ...[
                  Text(
                    _path.map((item) => item.label).join(' / '),
                    style: const TextStyle(color: SoulColors.muted),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_error != null)
                  _ErrorBanner(
                    message: _error!,
                    onClose: () => setState(() => _error = null),
                  ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _options.isEmpty
                          ? Center(
                              child: OutlinedButton.icon(
                                onPressed: () => _load(
                                  parentId:
                                      _path.isEmpty ? null : _path.last.id,
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(
                                  widget.labels.text(
                                    'common.retry',
                                    'Try again',
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _options.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final option = _options[index];
                                return Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListTile(
                                    onTap: () => _select(option),
                                    title: Text(option.label),
                                    trailing: Icon(
                                      option.hasChildren
                                          ? Icons.chevron_right_rounded
                                          : Icons.check_circle_outline_rounded,
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _CatalogMultiSelect extends StatelessWidget {
  const _CatalogMultiSelect({
    required this.label,
    required this.choices,
    required this.selected,
    required this.loading,
    required this.onChanged,
    this.maximum,
  });

  final String label;
  final List<CatalogChoice> choices;
  final Set<String> selected;
  final bool loading;
  final int? maximum;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: SoulColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (maximum != null) ...[
              const SizedBox(height: 3),
              Text(
                'Choose up to $maximum',
                style: const TextStyle(
                  color: SoulColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (loading)
              const LinearProgressIndicator(minHeight: 2)
            else if (choices.isEmpty)
              const Text(
                'Options are temporarily unavailable.',
                style: TextStyle(color: SoulColors.muted),
              )
            else
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: choices.map((choice) {
                  final active = selected.contains(choice.value);
                  return FilterChip(
                    label: Text(choice.label),
                    selected: active,
                    selectedColor: SoulColors.limeLight,
                    checkmarkColor: SoulColors.ink,
                    onSelected: (next) {
                      final updated = Set<String>.from(selected);
                      if (next) {
                        if (maximum != null &&
                            updated.length >= maximum!) {
                          return;
                        }
                        updated.add(choice.value);
                      } else {
                        updated.remove(choice.value);
                      }
                      onChanged(updated);
                    },
                  );
                }).toList(growable: false),
              ),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                title,
                style: const TextStyle(
                  color: SoulColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1)
                      const Divider(height: 1, indent: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _TextFieldRow extends StatelessWidget {
  const _TextFieldRow({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.capitalization = TextCapitalization.sentences,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int maxLines;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          maxLines: maxLines,
          textCapitalization: capitalization,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: const UnderlineInputBorder(),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.selectLabel,
    required this.label,
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final String selectLabel;
  final String label;
  final String? value;
  final Map<String, String> choices;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: SoulColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: value != null && choices.containsKey(value) ? value : null,
              hint: Text(selectLabel),
              underline: const SizedBox.shrink(),
              items: choices.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(growable: false),
              onChanged: onChanged,
            ),
          ],
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: const Color(0xffffeeee),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(child: Text(message)),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      );
}
