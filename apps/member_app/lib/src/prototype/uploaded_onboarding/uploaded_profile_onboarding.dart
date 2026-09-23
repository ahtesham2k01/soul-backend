// ignore_for_file: prefer_interpolation_to_compose_strings, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'uploaded_onboarding_app.dart';

const _assetRoot = 'assets/uploaded_onboarding';

enum _Step {
  name,
  birthday,
  gender,
  location,
  nationality,
  religion,
  sect,
  subSect,
  community,
  maritalStatus,
  intentions,
  profession,
  languages,
  smoking,
  alcohol,
  currentChildren,
  futureChildren,
  faithDetails,
  optionalProfile,
  photos,
  notifications,
  verification,
  legal,
}

class UploadedProfileOnboardingScreen extends StatefulWidget {
  const UploadedProfileOnboardingScreen({
    required this.selectedLanguage,
    super.key,
  });

  final String selectedLanguage;

  @override
  State<UploadedProfileOnboardingScreen> createState() =>
      _UploadedProfileOnboardingScreenState();
}

class _UploadedProfileOnboardingScreenState
    extends State<UploadedProfileOnboardingScreen> {
  int _index = 0;

  final _name = TextEditingController();
  final _profession = TextEditingController();
  final _bio = TextEditingController();
  final _grewUp = TextEditingController();
  final _ethnicOrigin = TextEditingController();

  DateTime? _birthday;
  String _gender = '';
  String _city = '';
  String _country = '';
  String _nationality = '';
  String _religion = '';
  String _sect = '';
  String _subSect = '';
  String _community = '';
  String _maritalStatus = '';
  final Set<String> _intentions = <String>{};
  final Set<String> _languages = <String>{};
  String _smoking = '';
  String _alcohol = '';
  String _currentChildren = '';
  String _futureChildren = '';
  String _faithPractice = '';
  String _diet = '';
  String _dress = '';
  String _education = '';
  String _height = '';
  String _relocation = '';
  String _familyInvolvement = '';
  final Set<String> _interests = <String>{};
  final Set<String> _traits = <String>{};
  int _photoCount = 0;
  bool _notifications = true;
  bool _marketing = false;
  bool _selfieVerified = false;
  bool _legalAccepted = false;
  bool _truthAccepted = false;
  bool _respectAccepted = false;

  @override
  void dispose() {
    _name.dispose();
    _profession.dispose();
    _bio.dispose();
    _grewUp.dispose();
    _ethnicOrigin.dispose();
    super.dispose();
  }

  List<_Step> get _steps {
    final value = <_Step>[
      _Step.name,
      _Step.birthday,
      _Step.gender,
      _Step.location,
      _Step.nationality,
      _Step.religion,
    ];

    if (_religion == 'Islam') {
      value.addAll([_Step.sect, _Step.subSect, _Step.community]);
    } else if (_religion == 'Christianity') {
      value.addAll([_Step.sect, _Step.subSect]);
    } else if (_religion == 'Hinduism') {
      value.add(_Step.community);
    }

    value.addAll([
      _Step.maritalStatus,
      _Step.intentions,
      _Step.profession,
      _Step.languages,
      _Step.smoking,
      _Step.alcohol,
      _Step.currentChildren,
      _Step.futureChildren,
    ]);

    if (_religion == 'Islam' ||
        _religion == 'Christianity' ||
        _religion == 'Hinduism' ||
        _religion == 'Sikhism') {
      value.add(_Step.faithDetails);
    }

    value.addAll([
      _Step.optionalProfile,
      _Step.photos,
      _Step.notifications,
      _Step.verification,
      _Step.legal,
    ]);
    return value;
  }

  _Step get _step => _steps[_index.clamp(0, _steps.length - 1).toInt()];

  bool get _romanUrdu => widget.selectedLanguage == 'Roman Urdu';

  String _copy(String english, String romanUrdu) =>
      _romanUrdu ? romanUrdu : english;

  void _next() {
    if (!_canContinue()) return;
    HapticFeedback.selectionClick();
    if (_index >= _steps.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => UploadedOnboardingCompleteScreen(
            name: _name.text.trim(),
            city: _city,
            religion: _religion,
            selfieVerified: _selfieVerified,
          ),
        ),
      );
      return;
    }
    setState(() => _index += 1);
  }

  void _back() {
    HapticFeedback.selectionClick();
    if (_index == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index -= 1);
  }

  bool _canContinue() => switch (_step) {
        _Step.name => _name.text.trim().length >= 2,
        _Step.birthday => _birthday != null,
        _Step.gender => _gender.isNotEmpty,
        _Step.location => _city.isNotEmpty && _country.isNotEmpty,
        _Step.nationality => _nationality.isNotEmpty,
        _Step.religion => _religion.isNotEmpty,
        _Step.sect => _sect.isNotEmpty,
        _Step.subSect => _subSect.isNotEmpty,
        _Step.community => true,
        _Step.maritalStatus => _maritalStatus.isNotEmpty,
        _Step.intentions => _intentions.isNotEmpty,
        _Step.profession => _profession.text.trim().isNotEmpty,
        _Step.languages => _languages.isNotEmpty,
        _Step.smoking => _smoking.isNotEmpty,
        _Step.alcohol => _alcohol.isNotEmpty,
        _Step.currentChildren => _currentChildren.isNotEmpty,
        _Step.futureChildren => _futureChildren.isNotEmpty,
        _Step.faithDetails => true,
        _Step.optionalProfile => true,
        _Step.photos => _photoCount >= 2,
        _Step.notifications => true,
        _Step.verification => true,
        _Step.legal => _legalAccepted && _truthAccepted && _respectAccepted,
      };

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final progress = (_index + 1) / steps.length;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 5, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: _copy('Back', 'Wapas'),
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFF0F2ED),
                        color: soulLime,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_index + 1}/${steps.length}',
                    style: const TextStyle(
                      color: soulMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 230),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.025, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildStep(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                14 + MediaQuery.paddingOf(context).bottom * 0.25,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('onboarding-continue'),
                  onPressed: _canContinue() ? _next : null,
                  child: Text(
                    _step == _Step.legal
                        ? _copy('Finish onboarding', 'Onboarding mukammal karein')
                        : _copy('Continue', 'Continue karein'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: switch (_step) {
          _Step.name => _nameStep(),
          _Step.birthday => _birthdayStep(),
          _Step.gender => _choiceStep(
              title: _copy('How do you identify?', 'Aap apni gender kaise batana chahein ge?'),
              subtitle: _copy(
                'This appears on your profile and shapes discovery.',
                'Ye aap ki profile par nazar ayega aur discovery ko shape karega.',
              ),
              options: const ['Man', 'Woman'],
              selected: _gender,
              onTap: (value) => setState(() => _gender = value),
            ),
          _Step.location => _locationStep(),
          _Step.nationality => _choiceStep(
              title: _copy('Your nationality', 'Aap ki nationality'),
              subtitle: _copy(
                'Choose the option that best describes you.',
                'Jo option aap ko best describe kare wo select karein.',
              ),
              options: const [
                'Pakistani',
                'British',
                'Emirati',
                'American',
                'Canadian',
                'Indian',
                'Other',
              ],
              selected: _nationality,
              onTap: (value) => setState(() => _nationality = value),
            ),
          _Step.religion => _religionStep(),
          _Step.sect => _sectStep(),
          _Step.subSect => _subSectStep(),
          _Step.community => _communityStep(),
          _Step.maritalStatus => _choiceStep(
              title: _copy('Marital status', 'Marital status'),
              subtitle: _copy(
                'Be clear so expectations start honestly.',
                'Clear jawab dein taake expectations honest rahen.',
              ),
              options: const [
                'Never married',
                'Divorced',
                'Widowed',
                'Separated',
              ],
              selected: _maritalStatus,
              onTap: (value) => setState(() => _maritalStatus = value),
            ),
          _Step.intentions => _intentionsStep(),
          _Step.profession => _professionStep(),
          _Step.languages => _languagesStep(),
          _Step.smoking => _choiceStep(
              title: _copy('Do you smoke?', 'Kya aap smoke karte hain?'),
              subtitle: _copy('Choose what is accurate today.', 'Jo aaj accurate hai wo choose karein.'),
              options: const ['No', 'Occasionally', 'Yes', 'Prefer not to say'],
              selected: _smoking,
              onTap: (value) => setState(() => _smoking = value),
            ),
          _Step.alcohol => _choiceStep(
              title: _copy('Do you drink alcohol?', 'Kya aap alcohol lete hain?'),
              subtitle: _copy('Choose what is accurate today.', 'Jo aaj accurate hai wo choose karein.'),
              options: const ['No', 'Occasionally', 'Yes', 'Prefer not to say'],
              selected: _alcohol,
              onTap: (value) => setState(() => _alcohol = value),
            ),
          _Step.currentChildren => _choiceStep(
              title: _copy('Do you have children?', 'Kya aap ke bachay hain?'),
              subtitle: _copy(
                'This helps people understand your current family situation.',
                'Is se log aap ki current family situation samajh sakte hain.',
              ),
              options: const [
                'No children',
                'Yes, live with me',
                'Yes, do not live with me',
                'Prefer not to say',
              ],
              selected: _currentChildren,
              onTap: (value) => setState(() => _currentChildren = value),
            ),
          _Step.futureChildren => _choiceStep(
              title: _copy(
                'Would you like children in the future?',
                'Kya aap future mein bachay chahte hain?',
              ),
              subtitle: _copy('There is no right answer — only your answer.', 'Koi right answer nahi — sirf aap ka answer.'),
              options: const ['Yes', 'No', 'Open to it', 'Not sure', 'Prefer not to say'],
              selected: _futureChildren,
              onTap: (value) => setState(() => _futureChildren = value),
            ),
          _Step.faithDetails => _faithDetailsStep(),
          _Step.optionalProfile => _optionalProfileStep(),
          _Step.photos => _photosStep(),
          _Step.notifications => _notificationsStep(),
          _Step.verification => _verificationStep(),
          _Step.legal => _legalStep(),
        },
      );

  Widget _heading(String title, String subtitle, {String? eyebrow}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF628118),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
            const SizedBox(height: 9),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 9),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 26),
        ],
      );

  Widget _nameStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('What should we call you?', 'Hum aap ko kis naam se bulayen?'),
            _copy(
              'Your first name is visible on your profile. Keep it real and simple.',
              'Aap ka first name profile par visible hoga. Real aur simple rakhein.',
            ),
            eyebrow: 'Profile',
          ),
          TextField(
            key: const ValueKey('onboarding-name'),
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _copy('First name', 'First name'),
              hintText: 'Ahtesham',
              prefixIcon: const Icon(Icons.person_outline_rounded, color: soulMuted),
            ),
          ),
        ],
      );

  Widget _birthdayStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('When is your birthday?', 'Aap ki date of birth kya hai?'),
            _copy(
              'You must be 18+. Members only see your age, not your exact date.',
              'Aap ka 18+ hona zaroori hai. Members ko sirf age nazar ayegi, exact date nahi.',
            ),
            eyebrow: 'Age',
          ),
          _Card(
            child: Row(
              children: [
                const _IconBox(icon: Icons.cake_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _birthday == null
                        ? _copy('Choose your date of birth', 'Date of birth choose karein')
                        : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
                    style: const TextStyle(color: soulInk, fontWeight: FontWeight.w700),
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
                    if (selected != null && mounted) setState(() => _birthday = selected);
                  },
                  child: Text(_copy('Choose', 'Choose')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _TrustNote(
            icon: Icons.lock_outline_rounded,
            text: 'Your exact birthday is private and is not shown on your public profile.',
          ),
        ],
      );

  Widget _locationStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('Where are you based?', 'Aap kahan based hain?'),
            _copy(
              'Production will resolve your real city. For this backend-free APK, choose a preview city and country.',
              'Production mein real city resolve hogi. Is backend-free APK mein preview city aur country choose karein.',
            ),
            eyebrow: 'Location',
          ),
          const _TrustNote(
            icon: Icons.my_location_rounded,
            text: 'Exact coordinates are never shown to other members.',
          ),
          const SizedBox(height: 18),
          _label('City'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final city in const ['Karachi', 'Lahore', 'Islamabad', 'Dubai', 'London'])
                _Pill(
                  label: city,
                  selected: _city == city,
                  icon: Icons.location_on_outlined,
                  onTap: () => setState(() {
                    _city = city;
                    _country = switch (city) {
                      'Dubai' => 'United Arab Emirates',
                      'London' => 'United Kingdom',
                      _ => 'Pakistan',
                    };
                  }),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _label('Country'),
          _Card(
            child: Row(
              children: [
                const Icon(Icons.public_rounded, color: soulMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _country.isEmpty ? 'Select a city first' : _country,
                    style: TextStyle(
                      color: _country.isEmpty ? soulMuted : soulInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _religionStep() => _choiceStep(
        title: _copy('Religion or belief', 'Religion ya belief'),
        subtitle: _copy(
          'SOUL only shows deeper levels when the selected religion has them.',
          'SOUL deeper levels sirf tab dikhayega jab selected religion mein wo available hon.',
        ),
        options: const ['Islam', 'Christianity', 'Hinduism', 'Sikhism', 'No religion', 'Other'],
        selected: _religion,
        eyebrow: 'Beliefs',
        onTap: (value) => setState(() {
          _religion = value;
          _sect = '';
          _subSect = '';
          _community = '';
        }),
      );

  Widget _sectStep() {
    final christian = _religion == 'Christianity';
    return _choiceStep(
      title: christian ? 'Tradition' : _copy('Sect or tradition', 'Sect ya tradition'),
      subtitle: _copy(
        'This step appears because your selected religion has another level.',
        'Ye step is liye aya hai kyun ke selected religion mein next level available hai.',
      ),
      options: christian
          ? const ['Catholic', 'Protestant', 'Orthodox', 'Other']
          : const ['Sunni', 'Shia', 'Ibadi', 'Other'],
      selected: _sect,
      onTap: (value) => setState(() {
        _sect = value;
        _subSect = '';
      }),
    );
  }

  Widget _subSectStep() {
    final christian = _religion == 'Christianity';
    return _choiceStep(
      title: christian ? 'Denomination' : _copy('School or movement', 'School ya movement'),
      subtitle: _copy(
        'Taxonomy can go deeper without forcing every religion through the same screens.',
        'Har religion ko same screens se force kiye baghair taxonomy deeper ja sakti hai.',
      ),
      options: christian
          ? const ['Anglican', 'Evangelical', 'Methodist', 'Other']
          : const ['Hanafi', 'Shafi’i', 'Maliki', 'Hanbali', 'Other'],
      selected: _subSect,
      onTap: (value) => setState(() => _subSect = value),
    );
  }

  Widget _communityStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('Community or caste', 'Community ya caste'),
            _copy(
              'Optional. Skip this if it is not relevant to you.',
              'Optional hai. Agar relevant nahi to skip kar dein.',
            ),
          ),
          for (final option in const [
            'Prefer not to say',
            'Community A',
            'Community B',
            'Community C',
            'Other',
          ]) ...[
            _ChoiceTile(
              label: option,
              selected: _community == option,
              onTap: () => setState(() => _community = option),
            ),
            const SizedBox(height: 9),
          ],
          TextButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.skip_next_rounded),
            label: Text(_copy('Skip optional step', 'Optional step skip karein')),
          ),
        ],
      );

  Widget _intentionsStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('What are you looking for?', 'Aap kya dhoond rahe hain?'),
            _copy(
              'Choose up to three. Your intentions stay visible on your profile.',
              '3 tak choose karein. Aap ki intentions profile par visible rahengi.',
            ),
            eyebrow: 'Intentions',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in const ['Marriage', 'Serious relationship', 'Casual dating'])
                _Pill(
                  label: option,
                  selected: _intentions.contains(option),
                  onTap: () => setState(() {
                    if (!_intentions.remove(option) && _intentions.length < 3) {
                      _intentions.add(option);
                    }
                  }),
                ),
            ],
          ),
        ],
      );

  Widget _professionStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('What do you do?', 'Aap kya karte hain?'),
            _copy(
              'A profession, business or current status is enough.',
              'Profession, business ya current status kafi hai.',
            ),
            eyebrow: 'Work',
          ),
          TextField(
            controller: _profession,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Profession or status',
              hintText: 'e.g. Software Engineer',
              prefixIcon: Icon(Icons.work_outline_rounded, color: soulMuted),
            ),
          ),
        ],
      );

  Widget _languagesStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('Languages you speak', 'Aap kaun si languages bolte hain?'),
            _copy('Pick at least one. Multiple are welcome.', 'Kam az kam ek choose karein. Multiple bhi choose kar sakte hain.'),
            eyebrow: 'Languages',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in const [
                'English',
                'Roman Urdu',
                'Urdu',
                'Punjabi',
                'Pashto',
                'Arabic',
                'Hindi',
              ])
                _Pill(
                  label: option,
                  selected: _languages.contains(option),
                  onTap: () => setState(() {
                    if (!_languages.remove(option) && _languages.length < 5) {
                      _languages.add(option);
                    }
                  }),
                ),
            ],
          ),
        ],
      );

  Widget _faithDetailsStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('Faith details', 'Faith details'),
            _copy(
              'Optional details can improve compatibility without forcing you to disclose more than you want.',
              'Optional details compatibility improve kar sakte hain, lekin aap ko extra disclose karne par force nahi kiya jayega.',
            ),
            eyebrow: 'Optional',
          ),
          _label('Practice'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const ['Practising', 'Somewhat practising', 'Cultural', 'Prefer not to say'])
                _Pill(
                  label: item,
                  selected: _faithPractice == item,
                  onTap: () => setState(() => _faithPractice = item),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _label('Diet'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const ['No preference', 'Faith-guided diet', 'Vegetarian', 'Prefer not to say'])
                _Pill(
                  label: item,
                  selected: _diet == item,
                  onTap: () => setState(() => _diet = item),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _label('Dress / observance'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const ['No preference', 'Modest dress', 'Traditional', 'Prefer not to say'])
                _Pill(
                  label: item,
                  selected: _dress == item,
                  onTap: () => setState(() => _dress = item),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.skip_next_rounded),
            label: Text(_copy('Skip optional details', 'Optional details skip karein')),
          ),
        ],
      );

  Widget _optionalProfileStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('Add more personality', 'Apni profile mein personality add karein'),
            _copy(
              'Everything here is optional. Skip what you do not want to share.',
              'Yahan sab optional hai. Jo share nahi karna chahte usay skip karein.',
            ),
            eyebrow: 'Optional profile',
          ),
          TextField(
            controller: _bio,
            minLines: 4,
            maxLines: 6,
            maxLength: 320,
            decoration: const InputDecoration(
              labelText: 'About you',
              hintText: 'A short, natural bio…',
            ),
          ),
          const SizedBox(height: 14),
          _Dropdown(
            label: 'Education',
            value: _education,
            options: const ['High school', 'Bachelors', 'Masters', 'Doctorate', 'Other'],
            onChanged: (value) => setState(() => _education = value),
          ),
          const SizedBox(height: 14),
          _Dropdown(
            label: 'Height',
            value: _height,
            options: const ['5′2″', '5′4″', '5′6″', '5′8″', '5′10″', '6′0″'],
            onChanged: (value) => setState(() => _height = value),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _grewUp,
            decoration: const InputDecoration(labelText: 'Grew up in'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ethnicOrigin,
            decoration: const InputDecoration(labelText: 'Ethnic origin'),
          ),
          const SizedBox(height: 14),
          _Dropdown(
            label: 'Relocation',
            value: _relocation,
            options: const [
              'Open to relocating',
              'Maybe for the right person',
              'Prefer to stay where I am',
            ],
            onChanged: (value) => setState(() => _relocation = value),
          ),
          const SizedBox(height: 14),
          _Dropdown(
            label: 'Family involvement',
            value: _familyInvolvement,
            options: const ['Private for now', 'Open to family involvement later', 'Family involved early'],
            onChanged: (value) => setState(() => _familyInvolvement = value),
          ),
          const SizedBox(height: 22),
          _label('Interests'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const ['Fitness', 'Travel', 'Family', 'Books', 'Food', 'Tech', 'Music', 'Nature'])
                _Pill(
                  label: item,
                  selected: _interests.contains(item),
                  onTap: () => setState(() {
                    if (!_interests.remove(item) && _interests.length < 15) {
                      _interests.add(item);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 22),
          _label('Personality'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in const ['Calm', 'Ambitious', 'Funny', 'Family-oriented', 'Curious', 'Independent'])
                _Pill(
                  label: item,
                  selected: _traits.contains(item),
                  onTap: () => setState(() {
                    if (!_traits.remove(item) && _traits.length < 5) {
                      _traits.add(item);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.skip_next_rounded),
            label: Text(_copy('Skip optional details', 'Optional details skip karein')),
          ),
        ],
      );

  Widget _photosStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('Add your photos', 'Apni photos add karein'),
            _copy(
              'A public cover and a clear-face photo are required. You can add one extra private photo.',
              'Public cover aur clear-face photo required hain. Ek extra private photo bhi add kar sakte hain.',
            ),
            eyebrow: 'Photos',
          ),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 0.76,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          if (i < _photoCount) {
                            _photoCount = i;
                          } else if (_photoCount < 3) {
                            _photoCount += 1;
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: i < _photoCount ? const Color(0xFFF1F8D9) : const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: i < _photoCount ? soulLime : soulLine,
                            width: i < _photoCount ? 1.5 : 1,
                          ),
                        ),
                        child: i < _photoCount
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(17),
                                    child: Image.asset(
                                      '$_assetRoot/onboarding/avatar${(i % 4) + 1}.webp',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    left: 7,
                                    top: 7,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.62),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        i == 0 ? 'Cover' : i == 1 ? 'Clear face' : 'Private',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_outlined, color: soulMuted, size: 30),
                                  const SizedBox(height: 8),
                                  Text(
                                    i == 0 ? 'Cover' : i == 1 ? 'Clear face' : 'Private',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: soulMuted, fontSize: 10.5),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 9),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _TrustNote(
            icon: Icons.photo_camera_front_outlined,
            text: _photoCount < 2
                ? 'Tap the first two slots to simulate adding your required cover and clear-face photos.'
                : 'Required photo slots are ready. Private photos only unlock after a mutual match and approval.',
          ),
        ],
      );

  Widget _notificationsStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('Stay close to what matters', 'Jo important hai us se connected rahen'),
            _copy(
              'Matches and messages are useful. Marketing stays separate and off by default.',
              'Matches aur messages useful hain. Marketing separate hai aur default mein off rahegi.',
            ),
            eyebrow: 'Notifications',
          ),
          _Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _notifications,
                  title: const Text('Matches & messages', style: TextStyle(color: soulInk, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Know when someone matches or replies.'),
                  onChanged: (value) => setState(() => _notifications = value),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _marketing,
                  title: const Text('Marketing', style: TextStyle(color: soulInk, fontWeight: FontWeight.w700)),
                  subtitle: const Text('Offers and product news. Optional.'),
                  onChanged: (value) => setState(() => _marketing = value),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _verificationStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('Add a trust signal', 'Trust signal add karein'),
            _copy(
              'Selfie verification is optional in the current product rule unless safety requires it.',
              'Current product rule mein selfie verification optional hai, jab tak safety ko zaroorat na ho.',
            ),
            eyebrow: 'Verification',
          ),
          _Card(
            child: Column(
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _IconBox(icon: Icons.mail_outline_rounded),
                  title: Text('Email', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Verified in this preview'),
                  trailing: Icon(Icons.verified_rounded, color: Color(0xFF4D7A14)),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _IconBox(icon: Icons.face_retouching_natural_outlined),
                  title: const Text('Selfie / face', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(_selfieVerified ? 'Verified' : 'Optional / recommended'),
                  trailing: _selfieVerified
                      ? const Icon(Icons.verified_rounded, color: Color(0xFF4D7A14))
                      : TextButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            setState(() => _selfieVerified = true);
                          },
                          child: const Text('Preview verify'),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _TrustNote(
            icon: Icons.shield_outlined,
            text: 'Email, phone, selfie and ID/age remain separate verification states. One check does not silently replace another.',
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.skip_next_rounded),
            label: Text(_copy('Skip optional selfie verification', 'Optional selfie verification skip karein')),
          ),
        ],
      );

  Widget _legalStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            _copy('Your commitment to SOUL', 'Aap ka SOUL ke sath commitment'),
            _copy(
              'A safer community starts with clear expectations before your profile goes live.',
              'Safer community clear expectations se start hoti hai, profile live hone se pehle.',
            ),
            eyebrow: 'Final step',
          ),
          _Card(
            child: Column(
              children: [
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _truthAccepted,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I am 18+ and the information on my profile is truthful.',
                    style: TextStyle(color: soulInk, fontWeight: FontWeight.w600),
                  ),
                  onChanged: (value) => setState(() => _truthAccepted = value == true),
                ),
                const Divider(height: 1),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _respectAccepted,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I will treat other members with respect and will not scam, harass or impersonate anyone.',
                    style: TextStyle(color: soulInk, fontWeight: FontWeight.w600),
                  ),
                  onChanged: (value) => setState(() => _respectAccepted = value == true),
                ),
                const Divider(height: 1),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _legalAccepted,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I agree to the Terms, Privacy Policy and Community Guidelines.',
                    style: TextStyle(color: soulInk, fontWeight: FontWeight.w600),
                  ),
                  onChanged: (value) => setState(() => _legalAccepted = value == true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _TrustNote(
            icon: Icons.lock_outline_rounded,
            text: 'Safety actions such as blocking, reporting and account security are never paywalled.',
          ),
        ],
      );

  Widget _choiceStep({
    required String title,
    required String subtitle,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onTap,
    String? eyebrow,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(title, subtitle, eyebrow: eyebrow),
          for (final option in options) ...[
            _ChoiceTile(
              label: option,
              selected: selected == option,
              onTap: () => onTap(option),
            ),
            const SizedBox(height: 9),
          ],
        ],
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Text(
          text,
          style: const TextStyle(color: soulInk, fontWeight: FontWeight.w700),
        ),
      );
}

class UploadedOnboardingCompleteScreen extends StatelessWidget {
  const UploadedOnboardingCompleteScreen({
    required this.name,
    required this.city,
    required this.religion,
    required this.selfieVerified,
    super.key,
  });

  final String name;
  final String city;
  final String religion;
  final bool selfieVerified;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: soulDeepGreen,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: const BoxDecoration(color: soulLime, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 46, color: Colors.black),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    name.isEmpty ? 'Onboarding complete' : 'You’re ready, $name',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'This onboarding preview is complete. The next APK phase can start from Discovery without adding backend yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        _summary('Location', city.isEmpty ? 'Preview city' : city),
                        _summary('Religion', religion.isEmpty ? 'Not specified' : religion),
                        _summary('Email', 'Verified'),
                        _summary('Selfie', selfieVerified ? 'Verified' : 'Skipped / optional'),
                        _summary('Photos', 'Cover + clear-face ready'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: const Text('Review onboarding again'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  static Widget _summary(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ],
        ),
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
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minHeight: 54),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF1F8D9) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? soulLime : soulLine, width: selected ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: const TextStyle(color: soulInk, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? soulLime : Colors.transparent,
                      border: Border.all(color: selected ? soulLime : const Color(0xFFC9CED5), width: 1.5),
                    ),
                    child: selected ? const Icon(Icons.check_rounded, size: 15, color: Colors.black) : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF1F8D9) : const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: selected ? soulLime : soulLine),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: soulInk),
                  const SizedBox(width: 6),
                ],
                Text(label, style: const TextStyle(color: soulInk, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: soulLine),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: child,
      );
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8D9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF4D7111)),
      );
}

class _TrustNote extends StatelessWidget {
  const _TrustNote({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F9E9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: const Color(0xFF4D7111)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFF4D7111), fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: value.isEmpty ? null : value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final option in options)
            DropdownMenuItem<String>(value: option, child: Text(option)),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      );
}