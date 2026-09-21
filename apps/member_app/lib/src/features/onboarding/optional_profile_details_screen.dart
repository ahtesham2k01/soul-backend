import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_design.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'onboarding_repository.dart';

class OptionalProfileDetailsScreen extends StatefulWidget {
  const OptionalProfileDetailsScreen({
    super.key,
    required this.repository,
    required this.labels,
  });

  final OnboardingRepository repository;
  final BootstrapState labels;

  @override
  State<OptionalProfileDetailsScreen> createState() =>
      _OptionalProfileDetailsScreenState();
}

class _OptionalProfileDetailsScreenState
    extends State<OptionalProfileDetailsScreen> {
  static const _scalarFields = <String>[
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
  ];

  late final Map<String, TextEditingController> _controllers = {
    for (final field in _scalarFields) field: TextEditingController(),
  };

  final Set<String> _withheld = {};
  final Set<String> _interests = {};
  final Set<String> _traits = {};
  OnboardingProfileCatalog _catalog = const OnboardingProfileCatalog(
    interests: [],
    personalityTraits: [],
  );
  bool _detailedReligionVisible = true;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<Object>([
        widget.repository.profile(),
        widget.repository.profileCatalog(),
      ]);
      final profile = results[0] as Map<String, dynamic>;
      final catalog = results[1] as OnboardingProfileCatalog;

      for (final field in _scalarFields) {
        final value = profile[field];
        _controllers[field]!.text = value?.toString() ?? '';
      }
      _withheld
        ..clear()
        ..addAll(_strings(profile['prefer_not_to_say_fields']));
      _interests
        ..clear()
        ..addAll(_strings(profile['interests']));
      _traits
        ..clear()
        ..addAll(_strings(profile['personality_traits']));

      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _detailedReligionVisible =
            profile['detailed_religion_visible'] != false;
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

  List<String> _strings(Object? value) => value is List
      ? value.map((item) => item.toString()).toList(growable: false)
      : const [];

  void _answerField(String field) {
    if (_withheld.remove(field)) setState(() {});
  }

  void _skipField(String field) {
    setState(() {
      _controllers[field]?.clear();
      _withheld.remove(field);
    });
  }

  void _withholdField(String field) {
    setState(() {
      _controllers[field]?.clear();
      _withheld.add(field);
    });
  }

  void _skipCollection(String field, Set<String> values) {
    setState(() {
      values.clear();
      _withheld.remove(field);
    });
  }

  void _withholdCollection(String field, Set<String> values) {
    setState(() {
      values.clear();
      _withheld.add(field);
    });
  }

  Map<String, Object?> _payload() {
    Object? scalar(String field) {
      final text = _controllers[field]!.text.trim();
      if (text.isEmpty || _withheld.contains(field)) return null;
      if (field == 'height_cm') return int.tryParse(text);
      return text;
    }

    return {
      for (final field in _scalarFields) field: scalar(field),
      'interests':
          _withheld.contains('interests') ? <String>[] : _interests.toList(),
      'personality_traits': _withheld.contains('personality_traits')
          ? <String>[]
          : _traits.toList(),
      'prefer_not_to_say_fields': _withheld.toList()..sort(),
      'detailed_religion_visible': _detailedReligionVisible,
    };
  }

  String? _validate() {
    final rawHeight = _controllers['height_cm']!.text.trim();
    if (rawHeight.isNotEmpty && !_withheld.contains('height_cm')) {
      final height = int.tryParse(rawHeight);
      if (height == null || height < 50 || height > 300) {
        return widget.labels.text('profile.validation_height', 'Height must be between 50 and 300 cm.');
      }
    }
    if (_interests.length > 15) return widget.labels.format('common.choose_up_to', 'Choose up to {count}.', {'count': '15'});
    if (_traits.length > 5) return widget.labels.format('common.choose_up_to', 'Choose up to {count}.', {'count': '5'});
    return null;
  }

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
      Navigator.of(context).pop(true);
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            widget.labels.text('onboarding.review', 'Review your profile'),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: Text(widget.labels.text('common.save', 'Save')),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                children: [
                  SoulPageTitle(
                    widget.labels.text(
                      'onboarding.review',
                      'Review your profile',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBanner(message: _error!),
                  ],
                  const SizedBox(height: 24),
                  _sectionTitle(widget.labels.text('profile.profession', 'Profession or status')),
                  _optionalText('job_title', widget.labels.text('profile.job_title', 'Job title')),
                  _optionalText('employer', widget.labels.text('profile.employer', 'Employer')),
                  _optionalText('education', widget.labels.text('profile.education', 'Education')),
                  const SizedBox(height: 26),
                  _sectionTitle(widget.labels.text('profile.bio', 'About you')),
                  _optionalText(
                    'bio',
                    widget.labels.text('profile.bio', 'About you'),
                    maxLines: 4,
                    maxLength: 2000,
                  ),
                  _optionalText(
                    'height_cm',
                    widget.labels.text('profile.height', 'Height'),
                    keyboardType: TextInputType.number,
                  ),
                  _optionalText('grew_up_in', widget.labels.text('profile.grew_up_in', 'Grew up in')),
                  _optionalText('ethnic_origin', widget.labels.text('profile.ethnic_origin', 'Ethnic origin')),
                  _optionalText(
                    'relocation_preference',
                    widget.labels.text('profile.relocation', 'Relocation preference'),
                  ),
                  _optionalText(
                    'family_involvement_preference',
                    widget.labels.text('profile.family_involvement', 'Family involvement'),
                  ),
                  const SizedBox(height: 26),
                  _sectionTitle(widget.labels.text('profile.religion', 'Religion or belief')),
                  _optionalText(
                    'religious_practice',
                    widget.labels.text('profile.religious_practice', 'Religious practice'),
                  ),
                  _optionalText('prayer', widget.labels.text('profile.prayer', 'Prayer')),
                  _optionalText('diet', widget.labels.text('profile.diet', 'Diet')),
                  _optionalText('dress', widget.labels.text('profile.dress', 'Dress')),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(widget.labels.text('profile.show_religion_details', 'Show detailed religion answers')),
                    subtitle: null,
                    value: _detailedReligionVisible,
                    onChanged: (value) =>
                        setState(() => _detailedReligionVisible = value),
                  ),
                  const SizedBox(height: 26),
                  _catalogSection(
                    title: widget.labels.text('profile.interests', 'Interests'),
                    field: 'interests',
                    maximum: 15,
                    choices: _catalog.interests,
                    selected: _interests,
                  ),
                  const SizedBox(height: 26),
                  _catalogSection(
                    title: widget.labels.text('profile.traits', 'Personality traits'),
                    field: 'personality_traits',
                    maximum: 5,
                    choices: _catalog.personalityTraits,
                    selected: _traits,
                  ),
                  const SizedBox(height: 30),
                  SoulPrimaryButton(
                    label: widget.labels.text('common.save', 'Save'),
                    onPressed: _saving ? null : _save,
                    busy: _saving,
                  ),
                ],
              ),
      );

  Widget _sectionTitle(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          value,
          style: const TextStyle(
            color: SoulColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _optionalText(
    String field,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
  }) {
    final withheld = _withheld.contains(field);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
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
          const SizedBox(height: 7),
          TextField(
            controller: _controllers[field],
            enabled: !withheld,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: (_) => _answerField(field),
            decoration: InputDecoration(
              hintText: withheld
                  ? widget.labels.text(
                      'common.prefer_not_to_say',
                      'Prefer not to say',
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 7),
          _AnswerStateActions(
            labels: widget.labels,
            withheld: withheld,
            onSkip: () => _skipField(field),
            onPreferNotToSay: () => _withholdField(field),
          ),
        ],
      ),
    );
  }

  Widget _catalogSection({
    required String title,
    required String field,
    required int maximum,
    required List<OnboardingCatalogChoice> choices,
    required Set<String> selected,
  }) {
    final withheld = _withheld.contains(field);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: SoulColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const SizedBox(height: 12),
        if (withheld)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              widget.labels.text(
                'common.prefer_not_to_say',
                'Prefer not to say',
              ),
              style: const TextStyle(
                color: SoulColors.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else if (choices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              widget.labels.text(
                'common.options_unavailable',
                'Options are unavailable right now.',
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: choices.map((choice) {
              final active = selected.contains(choice.value);
              return FilterChip(
                label: Text(choice.label),
                selected: active,
                onSelected: (value) {
                  setState(() {
                    _withheld.remove(field);
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
        const SizedBox(height: 10),
        _AnswerStateActions(
          labels: widget.labels,
          withheld: withheld,
          onSkip: () => _skipCollection(field, selected),
          onPreferNotToSay: () => _withholdCollection(field, selected),
        ),
      ],
    );
  }
}

class _AnswerStateActions extends StatelessWidget {
  const _AnswerStateActions({
    required this.labels,
    required this.withheld,
    required this.onSkip,
    required this.onPreferNotToSay,
  });

  final BootstrapState labels;
  final bool withheld;
  final VoidCallback onSkip;
  final VoidCallback onPreferNotToSay;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        children: [
          TextButton(
            onPressed: onSkip,
            child: Text(labels.text('common.skip', 'Skip')),
          ),
          TextButton(
            onPressed: onPreferNotToSay,
            child: Text(
              labels.text('common.prefer_not_to_say', 'Prefer not to say'),
              style: TextStyle(
                fontWeight: withheld ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      );
}
