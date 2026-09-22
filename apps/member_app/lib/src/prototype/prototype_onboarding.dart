
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/soul_design.dart';
import '../core/soul_theme.dart';
import 'prototype_models.dart';

enum PrototypeOnboardingStep {
  name,
  birthday,
  gender,
  location,
  nationality,
  maritalStatus,
  intentions,
  profession,
  languages,
  smoking,
  alcohol,
  currentChildren,
  futureChildren,
  religion,
  sect,
  subSect,
  community,
  optionalProfile,
  photos,
  notifications,
  legal,
}

class PrototypeOnboardingScreen extends StatefulWidget {
  const PrototypeOnboardingScreen({
    required this.controller,
    super.key,
  });

  final PrototypeController controller;

  @override
  State<PrototypeOnboardingScreen> createState() =>
      _PrototypeOnboardingScreenState();
}

class _PrototypeOnboardingScreenState extends State<PrototypeOnboardingScreen> {
  int index = 0;
  late final TextEditingController nameController =
      TextEditingController(text: widget.controller.firstName);
  late final TextEditingController professionController =
      TextEditingController(text: widget.controller.profession);
  late final TextEditingController bioController =
      TextEditingController(text: widget.controller.bio);

  PrototypeController get c => widget.controller;

  List<PrototypeOnboardingStep> get steps {
    final value = <PrototypeOnboardingStep>[
      PrototypeOnboardingStep.name,
      PrototypeOnboardingStep.birthday,
      PrototypeOnboardingStep.gender,
      PrototypeOnboardingStep.location,
      PrototypeOnboardingStep.nationality,
      PrototypeOnboardingStep.maritalStatus,
      PrototypeOnboardingStep.intentions,
      PrototypeOnboardingStep.profession,
      PrototypeOnboardingStep.languages,
      PrototypeOnboardingStep.smoking,
      PrototypeOnboardingStep.alcohol,
      PrototypeOnboardingStep.currentChildren,
      PrototypeOnboardingStep.futureChildren,
      PrototypeOnboardingStep.religion,
    ];
    if (c.religion == 'Islam') {
      value.addAll([
        PrototypeOnboardingStep.sect,
        PrototypeOnboardingStep.subSect,
        PrototypeOnboardingStep.community,
      ]);
    } else if (c.religion == 'Christianity') {
      value.addAll([
        PrototypeOnboardingStep.sect,
        PrototypeOnboardingStep.subSect,
      ]);
    } else if (c.religion == 'Hinduism') {
      value.add(PrototypeOnboardingStep.community);
    }
    value.addAll([
      PrototypeOnboardingStep.optionalProfile,
      PrototypeOnboardingStep.photos,
      PrototypeOnboardingStep.notifications,
      PrototypeOnboardingStep.legal,
    ]);
    return value;
  }

  PrototypeOnboardingStep get step =>
      steps[index.clamp(0, steps.length - 1).toInt()];

  @override
  void dispose() {
    nameController.dispose();
    professionController.dispose();
    bioController.dispose();
    super.dispose();
  }

  void next() {
    if (!canContinue()) return;
    HapticFeedback.selectionClick();
    if (index >= steps.length - 1) {
      c.completeOnboarding();
      return;
    }
    setState(() => index += 1);
  }

  void back() {
    if (index == 0) {
      c.setStage(PrototypeStage.welcome);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => index -= 1);
  }

  bool canContinue() => switch (step) {
        PrototypeOnboardingStep.name => c.firstName.trim().length >= 2,
        PrototypeOnboardingStep.birthday => c.birthday != null,
        PrototypeOnboardingStep.gender => c.gender.isNotEmpty,
        PrototypeOnboardingStep.location => c.city.isNotEmpty,
        PrototypeOnboardingStep.nationality => c.nationality.isNotEmpty,
        PrototypeOnboardingStep.maritalStatus => c.maritalStatus.isNotEmpty,
        PrototypeOnboardingStep.intentions => c.intentions.isNotEmpty,
        PrototypeOnboardingStep.profession => c.profession.isNotEmpty,
        PrototypeOnboardingStep.languages => c.languages.isNotEmpty,
        PrototypeOnboardingStep.smoking => c.smoking.isNotEmpty,
        PrototypeOnboardingStep.alcohol => c.alcohol.isNotEmpty,
        PrototypeOnboardingStep.currentChildren =>
          c.currentChildren.isNotEmpty,
        PrototypeOnboardingStep.futureChildren =>
          c.futureChildren.isNotEmpty,
        PrototypeOnboardingStep.religion => c.religion.isNotEmpty,
        PrototypeOnboardingStep.sect => c.sect.isNotEmpty,
        PrototypeOnboardingStep.subSect => c.subSect.isNotEmpty,
        PrototypeOnboardingStep.community => true,
        PrototypeOnboardingStep.optionalProfile => true,
        PrototypeOnboardingStep.photos => c.photoCount >= 1,
        PrototypeOnboardingStep.notifications => true,
        PrototypeOnboardingStep.legal => c.legalAccepted,
      };

  @override
  Widget build(BuildContext context) {
    final currentSteps = steps;
    final progress = (index + 1) / currentSteps.length;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: c.t('common.back'),
                    onPressed: back,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: const Color(0xffedf0e8),
                        color: SoulColors.limeLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    (index + 1).toString() +
                        '/' +
                        currentSteps.length.toString(),
                    style: const TextStyle(
                      color: SoulColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: buildStep(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                10,
                24,
                18 + MediaQuery.paddingOf(context).bottom * .25,
              ),
              child: SoulPrimaryButton(
                label: step == PrototypeOnboardingStep.legal
                    ? 'Enter SOUL'
                    : c.t('common.continue'),
                onPressed: canContinue() ? next : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStep() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: switch (step) {
          PrototypeOnboardingStep.name => textStep(
              title: 'What should we call you?',
              subtitle: 'Your first name is shown on your profile.',
              controller: nameController,
              hint: 'First name',
              onChanged: (value) {
                c.firstName = value.trim();
                setState(() {});
              },
            ),
          PrototypeOnboardingStep.birthday => birthdayStep(),
          PrototypeOnboardingStep.gender => choiceStep(
              title: 'How do you identify?',
              subtitle: 'This is used for your profile and discovery.',
              options: const ['Man', 'Woman'],
              selected: {c.gender},
              onTap: (value) => setState(() => c.gender = value),
            ),
          PrototypeOnboardingStep.location => locationStep(),
          PrototypeOnboardingStep.nationality => choiceStep(
              title: 'What is your nationality?',
              subtitle: 'You can update this later.',
              options: const [
                'Pakistani',
                'British',
                'Emirati',
                'American',
                'Canadian',
                'Other',
              ],
              selected: {c.nationality},
              onTap: (value) => setState(() => c.nationality = value),
            ),
          PrototypeOnboardingStep.maritalStatus => choiceStep(
              title: 'Marital status',
              subtitle: 'Choose the option that best describes you.',
              options: const [
                'Never married',
                'Divorced',
                'Widowed',
                'Separated',
              ],
              selected: {c.maritalStatus},
              onTap: (value) => setState(() => c.maritalStatus = value),
            ),
          PrototypeOnboardingStep.intentions => multiChoiceStep(
              title: 'What are you looking for?',
              subtitle: 'Choose up to three. These stay visible on your profile.',
              options: const [
                'Marriage',
                'Serious relationship',
                'Casual dating',
              ],
              selected: c.intentions,
              max: 3,
            ),
          PrototypeOnboardingStep.profession => textStep(
              title: 'What do you do?',
              subtitle: 'A simple profession or current status is enough.',
              controller: professionController,
              hint: 'e.g. Software Engineer',
              onChanged: (value) {
                c.profession = value.trim();
                setState(() {});
              },
            ),
          PrototypeOnboardingStep.languages => multiChoiceStep(
              title: 'Languages you speak',
              subtitle: 'Pick at least one. You can choose multiple.',
              options: const [
                'English',
                'Roman Urdu',
                'Urdu',
                'Punjabi',
                'Pashto',
                'Arabic',
                'Hindi',
              ],
              selected: c.languages,
              max: 5,
            ),
          PrototypeOnboardingStep.smoking => choiceStep(
              title: 'Do you smoke?',
              subtitle: 'Being clear helps create better matches.',
              options: const [
                'No',
                'Occasionally',
                'Yes',
                'Prefer not to say',
              ],
              selected: {c.smoking},
              onTap: (value) => setState(() => c.smoking = value),
            ),
          PrototypeOnboardingStep.alcohol => choiceStep(
              title: 'Do you drink alcohol?',
              subtitle: 'Choose what feels accurate for you.',
              options: const [
                'No',
                'Occasionally',
                'Yes',
                'Prefer not to say',
              ],
              selected: {c.alcohol},
              onTap: (value) => setState(() => c.alcohol = value),
            ),
          PrototypeOnboardingStep.currentChildren => choiceStep(
              title: 'Do you have children?',
              subtitle: 'This remains part of your compatibility profile.',
              options: const [
                'No children',
                'Yes, live with me',
                'Yes, do not live with me',
                'Prefer not to say',
              ],
              selected: {c.currentChildren},
              onTap: (value) =>
                  setState(() => c.currentChildren = value),
            ),
          PrototypeOnboardingStep.futureChildren => choiceStep(
              title: 'Would you like children in the future?',
              subtitle: 'There is no right answer — just your answer.',
              options: const [
                'Yes',
                'No',
                'Open to it',
                'Not sure',
                'Prefer not to say',
              ],
              selected: {c.futureChildren},
              onTap: (value) => setState(() => c.futureChildren = value),
            ),
          PrototypeOnboardingStep.religion => choiceStep(
              title: 'Religion or belief',
              subtitle:
                  'SOUL only shows the next level when your selected path has one.',
              options: const [
                'Islam',
                'Christianity',
                'Hinduism',
                'Sikhism',
                'No religion',
                'Other',
              ],
              selected: {c.religion},
              onTap: (value) {
                setState(() {
                  c.religion = value;
                  c.sect = '';
                  c.subSect = '';
                  c.community = '';
                });
              },
            ),
          PrototypeOnboardingStep.sect => choiceStep(
              title: c.religion == 'Christianity'
                  ? 'Tradition'
                  : 'Sect or tradition',
              subtitle: 'This screen exists because this path has another level.',
              options: c.religion == 'Christianity'
                  ? const ['Catholic', 'Protestant', 'Orthodox', 'Other']
                  : const ['Sunni', 'Shia', 'Ibadi', 'Other'],
              selected: {c.sect},
              onTap: (value) => setState(() {
                c.sect = value;
                c.subSect = '';
              }),
            ),
          PrototypeOnboardingStep.subSect => choiceStep(
              title: c.religion == 'Christianity'
                  ? 'Denomination'
                  : 'School or movement',
              subtitle:
                  'The hierarchy can go deeper without hard-coding the flow.',
              options: c.religion == 'Christianity'
                  ? const ['Anglican', 'Evangelical', 'Methodist', 'Other']
                  : const ['Hanafi', 'Shafi’i', 'Maliki', 'Hanbali', 'Other'],
              selected: {c.subSect},
              onTap: (value) => setState(() => c.subSect = value),
            ),
          PrototypeOnboardingStep.community => choiceStep(
              title: 'Community or caste',
              subtitle:
                  'Optional. You can skip this and still continue your profile.',
              options: const [
                'Prefer not to say',
                'Community A',
                'Community B',
                'Community C',
                'Other',
              ],
              selected: {c.community},
              onTap: (value) => setState(() => c.community = value),
              allowSkip: true,
            ),
          PrototypeOnboardingStep.optionalProfile => optionalProfileStep(),
          PrototypeOnboardingStep.photos => photoStep(),
          PrototypeOnboardingStep.notifications => notificationStep(),
          PrototypeOnboardingStep.legal => legalStep(),
        },
      );

  Widget titleBlock(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: SoulColors.ink,
              fontSize: 29,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: SoulColors.muted,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
        ],
      );

  Widget textStep({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock(title, subtitle),
          TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: onChanged,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );

  Widget birthdayStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock(
            'When is your birthday?',
            'Your exact date stays private. Members only see your age.',
          ),
          PrototypeSectionCard(
            child: Row(
              children: [
                const Icon(
                  Icons.cake_outlined,
                  color: SoulColors.forest,
                  size: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    c.birthday == null
                        ? 'Choose your date of birth'
                        : c.birthday!.day.toString() +
                            '/' +
                            c.birthday!.month.toString() +
                            '/' +
                            c.birthday!.year.toString(),
                    style: const TextStyle(
                      color: SoulColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: DateTime(now.year - 27, 1, 1),
                      firstDate: DateTime(now.year - 80),
                      lastDate: DateTime(now.year - 18, now.month, now.day),
                    );
                    if (selected != null && mounted) {
                      setState(() => c.birthday = selected);
                    }
                  },
                  child: const Text('Choose'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _TrustNote(
            icon: Icons.lock_outline_rounded,
            text:
                'SOUL never displays your exact birthday on your public profile.',
          ),
        ],
      );

  Widget locationStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock(
            'Where are you based?',
            'Location powers nearby discovery. Exact coordinates are never shown to other members.',
          ),
          PrototypeSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.my_location_rounded, color: SoulColors.forest),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Use current location',
                        style: TextStyle(
                          color: SoulColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'For this backend-free preview, pick a city below. Production resolves the real device city or offers manual selection.',
                  style: TextStyle(
                    color: SoulColors.muted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final city in const [
                'Karachi',
                'Lahore',
                'Islamabad',
                'Dubai',
                'London',
              ])
                PrototypePill(
                  city,
                  icon: Icons.location_on_outlined,
                  selected: c.city == city,
                  onTap: () => setState(() => c.city = city),
                ),
            ],
          ),
        ],
      );

  Widget choiceStep({
    required String title,
    required String subtitle,
    required List<String> options,
    required Set<String> selected,
    required ValueChanged<String> onTap,
    bool allowSkip = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock(title, subtitle),
          for (final option in options) ...[
            SoulChoiceTile(
              label: option,
              selected: selected.contains(option),
              onTap: () => onTap(option),
            ),
            const SizedBox(height: 10),
          ],
          if (allowSkip)
            TextButton.icon(
              onPressed: next,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Skip this optional step'),
            ),
        ],
      );

  Widget multiChoiceStep({
    required String title,
    required String subtitle,
    required List<String> options,
    required Set<String> selected,
    required int max,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock(title, subtitle),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final option in options)
                PrototypePill(
                  option,
                  selected: selected.contains(option),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (selected.contains(option)) {
                        selected.remove(option);
                      } else if (selected.length < max) {
                        selected.add(option);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      );

  Widget optionalProfileStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock(
            'Add a little more depth',
            'Optional details help people understand who you are before they decide.',
          ),
          TextField(
            controller: bioController,
            minLines: 4,
            maxLines: 6,
            maxLength: 320,
            onChanged: (value) => c.bio = value.trim(),
            decoration: const InputDecoration(
              hintText: 'A short, natural bio about you…',
            ),
          ),
          const SizedBox(height: 14),
          _LabeledDropdown(
            label: 'Education',
            value: c.education.isEmpty ? null : c.education,
            options: const [
              'High school',
              'Bachelors',
              'Masters',
              'Doctorate',
              'Other',
            ],
            onChanged: (value) => setState(() => c.education = value ?? ''),
          ),
          const SizedBox(height: 14),
          _LabeledDropdown(
            label: 'Height',
            value: c.height.isEmpty ? null : c.height,
            options: const ['5′2″', '5′4″', '5′6″', '5′8″', '5′10″', '6′0″'],
            onChanged: (value) => setState(() => c.height = value ?? ''),
          ),
          const SizedBox(height: 14),
          _LabeledDropdown(
            label: 'Relocation',
            value: c.relocation.isEmpty ? null : c.relocation,
            options: const [
              'Open to relocating',
              'Maybe for the right person',
              'Prefer to stay where I am',
            ],
            onChanged: (value) => setState(() => c.relocation = value ?? ''),
          ),
          const SizedBox(height: 22),
          const Text(
            'Interests',
            style: TextStyle(
              color: SoulColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const [
                'Fitness',
                'Travel',
                'Family',
                'Books',
                'Food',
                'Tech',
                'Music',
                'Nature',
              ])
                PrototypePill(
                  item,
                  selected: c.interests.contains(item),
                  onTap: () => setState(() {
                    if (!c.interests.remove(item) && c.interests.length < 15) {
                      c.interests.add(item);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Personality',
            style: TextStyle(
              color: SoulColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const [
                'Calm',
                'Ambitious',
                'Funny',
                'Family-oriented',
                'Curious',
                'Independent',
              ])
                PrototypePill(
                  item,
                  selected: c.traits.contains(item),
                  onTap: () => setState(() {
                    if (!c.traits.remove(item) && c.traits.length < 5) {
                      c.traits.add(item);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: next,
            child: const Text('Skip optional details for now'),
          ),
        ],
      );

  Widget photoStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock(
            'Show the real you',
            'Add a public cover and at least one clear-face photo. You control which extra photos stay private.',
          ),
          Row(
            children: [
              for (var photoIndex = 0; photoIndex < 3; photoIndex++) ...[
                Expanded(
                  child: AspectRatio(
                    aspectRatio: .78,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          if (photoIndex < c.photoCount) {
                            c.photoCount = photoIndex;
                          } else if (c.photoCount < 3) {
                            c.photoCount += 1;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: photoIndex < c.photoCount
                              ? SoulColors.limeLight
                              : SoulColors.softSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: photoIndex < c.photoCount
                                ? SoulColors.lime
                                : SoulColors.line,
                          ),
                        ),
                        child: photoIndex < c.photoCount
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  PrototypePortrait(
                                    seed: 20 + photoIndex,
                                    name:
                                        c.firstName.isEmpty ? 'You' : c.firstName,
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        photoIndex == 0 ? 'Cover' : 'Private',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Center(
                                child: Icon(
                                  Icons.add_a_photo_outlined,
                                  color: SoulColors.muted,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                if (photoIndex < 2) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const _TrustNote(
            icon: Icons.verified_user_outlined,
            text:
                'Photo moderation, rejected-photo guidance and private-photo states are part of the complete design flow.',
          ),
        ],
      );

  Widget notificationStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock(
            'Stay close to what matters',
            'Get useful updates for matches and messages. Marketing stays separate.',
          ),
          PrototypeSectionCard(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: c.notificationsAllowed,
              title: const Text(
                'Matches & messages',
                style: TextStyle(
                  color: SoulColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Know when someone matches or replies.',
                style: TextStyle(color: SoulColors.muted),
              ),
              onChanged: (value) =>
                  setState(() => c.notificationsAllowed = value),
            ),
          ),
          const SizedBox(height: 12),
          const _TrustNote(
            icon: Icons.notifications_none_rounded,
            text:
                'You can change categories anytime. Marketing is off by default.',
          ),
        ],
      );

  Widget legalStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock(
            'One last thing',
            'A safe community works when everyone agrees to the same baseline.',
          ),
          PrototypeSectionCard(
            color: SoulColors.softSurface,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegalLine(
                  icon: Icons.shield_outlined,
                  text:
                      'I am 18 or older and my profile information is truthful.',
                ),
                _LegalLine(
                  icon: Icons.favorite_border_rounded,
                  text:
                      'I will treat other members with respect and not harass or scam anyone.',
                ),
                _LegalLine(
                  icon: Icons.lock_outline_rounded,
                  text:
                      'I understand SOUL protects private information and safety actions are never paywalled.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          CheckboxListTile(
            value: c.legalAccepted,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'I agree to the Terms, Privacy Policy and Community Guidelines.',
              style: TextStyle(
                color: SoulColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            onChanged: (value) =>
                setState(() => c.legalAccepted = value == true),
          ),
        ],
      );
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: onChanged,
      );
}

class _TrustNote extends StatelessWidget {
  const _TrustNote({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SoulColors.limeLight.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: SoulColors.forest),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: SoulColors.forest,
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _LegalLine extends StatelessWidget {
  const _LegalLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: SoulColors.forest),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: SoulColors.ink,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
}
