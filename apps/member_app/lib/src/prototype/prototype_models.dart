
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/soul_theme.dart';
import '../features/bootstrap/bootstrap_repository.dart';

enum PrototypeStage { launch, welcome, auth, onboarding, home }

class PrototypeProfile {
  const PrototypeProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    required this.religion,
    required this.intention,
    required this.bio,
    required this.job,
    required this.education,
    required this.height,
    required this.languages,
    required this.interests,
    required this.traits,
    required this.seed,
    this.distanceKm = 8,
    this.verified = true,
    this.mutualLike = false,
    this.privatePhotos = 1,
    this.maritalStatus = 'Never married',
    this.smoking = 'No',
    this.alcohol = 'No',
    this.children = 'No children',
    this.relocation = 'Open to relocating',
  });

  final String id;
  final String name;
  final int age;
  final String city;
  final String religion;
  final String intention;
  final String bio;
  final String job;
  final String education;
  final String height;
  final List<String> languages;
  final List<String> interests;
  final List<String> traits;
  final int seed;
  final int distanceKm;
  final bool verified;
  final bool mutualLike;
  final int privatePhotos;
  final String maritalStatus;
  final String smoking;
  final String alcohol;
  final String children;
  final String relocation;
}

class PrototypeConversation {
  PrototypeConversation({
    required this.id,
    required this.profile,
    required this.messages,
    this.unread = 0,
    this.online = false,
  });

  final String id;
  final PrototypeProfile profile;
  final List<PrototypeMessage> messages;
  int unread;
  bool online;
}

class PrototypeMessage {
  const PrototypeMessage({
    required this.id,
    required this.text,
    required this.mine,
    required this.sentAt,
    this.read = true,
  });

  final String id;
  final String text;
  final bool mine;
  final DateTime sentAt;
  final bool read;
}

class PrototypeEvent {
  PrototypeEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.when,
    required this.city,
    required this.icon,
    required this.seed,
    this.joined = false,
    this.online = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String when;
  final String city;
  final IconData icon;
  final int seed;
  bool joined;
  final bool online;
}

class PrototypeController extends ChangeNotifier {
  PrototypeController() {
    incomingLikes = <PrototypeProfile>[
      profiles[1],
      profiles[3],
      profiles[0],
    ];
    conversations = <PrototypeConversation>[
      PrototypeConversation(
        id: 'c1',
        profile: profiles[1],
        online: true,
        unread: 2,
        messages: [
          PrototypeMessage(
            id: 'm1',
            text: 'Hey, your profile felt really thoughtful 🙂',
            mine: false,
            sentAt: DateTime.now().subtract(const Duration(minutes: 18)),
          ),
          PrototypeMessage(
            id: 'm2',
            text: 'Thank you — yours did too. How has your week been?',
            mine: true,
            sentAt: DateTime.now().subtract(const Duration(minutes: 14)),
          ),
          PrototypeMessage(
            id: 'm3',
            text: 'Busy, but good. I finally have a quiet evening.',
            mine: false,
            sentAt: DateTime.now().subtract(const Duration(minutes: 4)),
          ),
        ],
      ),
      PrototypeConversation(
        id: 'c2',
        profile: profiles[2],
        messages: [
          PrototypeMessage(
            id: 'm4',
            text: 'That road-trip answer made me laugh 😄',
            mine: false,
            sentAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ],
      ),
    ];
  }

  PrototypeStage stage = PrototypeStage.launch;
  String locale = 'en';
  bool registration = true;
  bool onboardingComplete = false;
  bool incognito = false;
  bool paused = false;
  bool hideContacts = true;
  bool pushMatches = true;
  bool pushMessages = true;
  bool marketing = false;
  bool quietHours = false;
  bool emailVerified = true;
  bool phoneVerified = true;
  bool selfieVerified = false;
  bool idVerified = false;
  String? plan;
  final Set<String> passedIds = <String>{};
  final Set<String> likedIds = <String>{};
  final Set<String> declinedIncomingIds = <String>{};
  final Set<String> blockedIds = <String>{};

  String firstName = '';
  DateTime? birthday;
  String gender = '';
  String city = '';
  String nationality = '';
  String maritalStatus = '';
  final Set<String> intentions = <String>{};
  String profession = '';
  final Set<String> languages = <String>{};
  String smoking = '';
  String alcohol = '';
  String currentChildren = '';
  String futureChildren = '';
  String religion = '';
  String sect = '';
  String subSect = '';
  String community = '';
  String bio = '';
  String education = '';
  String height = '';
  String relocation = '';
  final Set<String> interests = <String>{};
  final Set<String> traits = <String>{};
  int photoCount = 0;
  bool notificationsAllowed = true;
  bool legalAccepted = false;

  final List<PrototypeProfile> profiles = const [
    PrototypeProfile(
      id: 'p1',
      name: 'Ayla',
      age: 27,
      city: 'Central District',
      religion: 'Muslim',
      intention: 'Marriage',
      bio: 'Product designer, big on family dinners, calm weekends and building a meaningful life with the right person.',
      job: 'Product Designer',
      education: 'Bachelors in Design',
      height: '5′5″',
      languages: ['English', 'Urdu'],
      interests: ['Coffee', 'Travel', 'Architecture', 'Family'],
      traits: ['Thoughtful', 'Warm', 'Curious'],
      seed: 4,
      distanceKm: 6,
      privatePhotos: 1,
    ),
    PrototypeProfile(
      id: 'p2',
      name: 'Mariam',
      age: 26,
      city: 'Nearby',
      religion: 'Muslim',
      intention: 'Marriage',
      bio: 'Doctor by profession, book lover by habit. Looking for someone grounded, kind and serious about building a partnership.',
      job: 'Doctor',
      education: 'MBBS',
      height: '5′4″',
      languages: ['English', 'Urdu', 'Punjabi'],
      interests: ['Books', 'Fitness', 'Food', 'Nature'],
      traits: ['Empathetic', 'Driven', 'Playful'],
      seed: 8,
      distanceKm: 11,
      mutualLike: true,
      privatePhotos: 2,
    ),
    PrototypeProfile(
      id: 'p3',
      name: 'Zoya',
      age: 28,
      city: 'Metro Area',
      religion: 'Muslim',
      intention: 'Serious relationship',
      bio: 'Software engineer who likes long drives, good playlists and people who can communicate clearly.',
      job: 'Software Engineer',
      education: 'BS Computer Science',
      height: '5′6″',
      languages: ['English', 'Roman Urdu'],
      interests: ['Tech', 'Music', 'Road trips', 'Photography'],
      traits: ['Direct', 'Loyal', 'Independent'],
      seed: 12,
      distanceKm: 17,
      privatePhotos: 1,
    ),
    PrototypeProfile(
      id: 'p4',
      name: 'Maya',
      age: 25,
      city: 'City Centre',
      religion: 'Christian',
      intention: 'Serious relationship',
      bio: 'Marketing strategist, Sunday brunch enthusiast and always planning the next little adventure.',
      job: 'Brand Strategist',
      education: 'MBA',
      height: '5′3″',
      languages: ['English'],
      interests: ['Brunch', 'Art', 'Travel', 'Dogs'],
      traits: ['Social', 'Optimistic', 'Creative'],
      seed: 15,
      distanceKm: 21,
      mutualLike: true,
      privatePhotos: 1,
    ),
  ];

  late final List<PrototypeProfile> incomingLikes;
  late final List<PrototypeConversation> conversations;

  final List<PrototypeEvent> events = <PrototypeEvent>[
    PrototypeEvent(
      id: 'e1',
      title: 'Coffee & Conversations',
      subtitle: 'Small-group social for people looking for serious connections.',
      when: 'Saturday · 6:30 PM',
      city: 'City Centre',
      icon: Icons.local_cafe_rounded,
      seed: 1,
    ),
    PrototypeEvent(
      id: 'e2',
      title: 'Values Before Vibes',
      subtitle: 'Guided online conversation about compatibility and long-term goals.',
      when: 'Sunday · 8:00 PM',
      city: 'Online',
      icon: Icons.favorite_outline_rounded,
      seed: 2,
      online: true,
    ),
    PrototypeEvent(
      id: 'e3',
      title: 'Walk & Talk',
      subtitle: 'A relaxed daytime meetup with host-led introductions.',
      when: 'Next Friday · 5:00 PM',
      city: 'Riverside Park',
      icon: Icons.park_rounded,
      seed: 3,
    ),
  ];

  BootstrapState get bootstrap => BootstrapState(
        direction: 'ltr',
        locale: locale,
        translations: {
          'onboarding.headline_highlight': t('headline.highlight'),
          'onboarding.headline_rest': t('headline.rest'),
          'common.skip': t('common.skip'),
        },
        legalVersions: const {},
        commitmentKeys: const [],
        supportedLanguages: const [
          SupportedLanguage(
            code: 'en',
            name: 'English',
            nativeName: 'English',
            direction: 'ltr',
            isLaunchReady: true,
          ),
          SupportedLanguage(
            code: 'en-GB',
            name: 'English (UK)',
            nativeName: 'English (UK)',
            direction: 'ltr',
            isLaunchReady: true,
          ),
          SupportedLanguage(
            code: 'ur',
            name: 'Roman Urdu',
            nativeName: 'Roman Urdu',
            direction: 'ltr',
            isLaunchReady: true,
          ),
        ],
        locationStatus: 'prototype',
        location: BootstrapLocation(
          city: t('location.preview'),
          countryCode: '',
          isApproximate: true,
        ),
      );

  String t(String key) {
    final active = locale == 'ur' ? _romanUrdu : _english;
    return active[key] ?? _english[key] ?? key;
  }

  void setStage(PrototypeStage next) {
    stage = next;
    notifyListeners();
  }

  void chooseLocale(String value) {
    locale = value;
    notifyListeners();
  }

  void beginRegistration() {
    registration = true;
    stage = PrototypeStage.auth;
    notifyListeners();
  }

  void beginLogin() {
    registration = false;
    stage = PrototypeStage.auth;
    notifyListeners();
  }

  void continueFromAuth() {
    stage = registration ? PrototypeStage.onboarding : PrototypeStage.home;
    notifyListeners();
  }

  void completeOnboarding() {
    onboardingComplete = true;
    stage = PrototypeStage.home;
    notifyListeners();
  }

  PrototypeProfile? get currentProfile {
    final visible = profiles
        .where(
          (profile) =>
              !passedIds.contains(profile.id) &&
              !likedIds.contains(profile.id) &&
              !blockedIds.contains(profile.id),
        )
        .toList(growable: false);
    if (visible.isEmpty) return null;
    return visible.first;
  }

  bool like(PrototypeProfile profile) {
    likedIds.add(profile.id);
    if (profile.mutualLike &&
        !conversations.any((conversation) => conversation.profile.id == profile.id)) {
      conversations.insert(
        0,
        PrototypeConversation(
          id: 'match-${profile.id}',
          profile: profile,
          online: true,
          messages: [],
        ),
      );
    }
    notifyListeners();
    return profile.mutualLike;
  }

  void pass(PrototypeProfile profile) {
    passedIds.add(profile.id);
    notifyListeners();
  }

  void resetDiscovery() {
    passedIds.clear();
    likedIds.clear();
    notifyListeners();
  }

  void acceptIncoming(PrototypeProfile profile) {
    incomingLikes.removeWhere((item) => item.id == profile.id);
    if (!conversations.any((conversation) => conversation.profile.id == profile.id)) {
      conversations.insert(
        0,
        PrototypeConversation(
          id: 'incoming-${profile.id}',
          profile: profile,
          online: true,
          messages: [],
        ),
      );
    }
    notifyListeners();
  }

  void declineIncoming(PrototypeProfile profile) {
    incomingLikes.removeWhere((item) => item.id == profile.id);
    declinedIncomingIds.add(profile.id);
    notifyListeners();
  }

  void sendMessage(PrototypeConversation conversation, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    conversation.messages.add(
      PrototypeMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        text: trimmed,
        mine: true,
        sentAt: DateTime.now(),
        read: true,
      ),
    );
    conversation.unread = 0;
    notifyListeners();
  }

  void addAutoReply(PrototypeConversation conversation) {
    const replies = [
      'That makes sense. I like how clearly you put that.',
      'Haha, fair 😄 Tell me more.',
      'That sounds like a good weekend honestly.',
      'I agree — values matter more than people admit.',
    ];
    conversation.messages.add(
      PrototypeMessage(
        id: 'reply-${DateTime.now().microsecondsSinceEpoch}',
        text: replies[conversation.messages.length % replies.length],
        mine: false,
        sentAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void block(PrototypeProfile profile) {
    blockedIds.add(profile.id);
    incomingLikes.removeWhere((item) => item.id == profile.id);
    conversations.removeWhere((conversation) => conversation.profile.id == profile.id);
    notifyListeners();
  }

  void toggleEvent(PrototypeEvent event) {
    event.joined = !event.joined;
    notifyListeners();
  }

  void setPlan(String value) {
    plan = value;
    notifyListeners();
  }

  void setSelfieVerified() {
    selfieVerified = true;
    notifyListeners();
  }

  void setIdVerified() {
    idVerified = true;
    notifyListeners();
  }

  void changed() {
    notifyListeners();
  }

  static const Map<String, String> _english = {
    'headline.highlight': 'Swipe to Your',
    'headline.rest': 'Happily Ever After',
    'location.preview': 'Your city',
    'common.skip': 'Skip',
    'welcome.subtitle': 'Meaningful connections, built around who you really are.',
    'welcome.create': 'Create Account',
    'welcome.email': 'Continue with Email',
    'welcome.google': 'Continue with Google',
    'welcome.apple': 'Continue with Apple',
    'nav.home': 'Home',
    'nav.explore': 'Explore',
    'nav.chat': 'Chat',
    'nav.profile': 'Profile',
    'discovery.title': 'Discover',
    'likes.title': 'Likes you',
    'chat.title': 'Messages',
    'profile.title': 'Your profile',
    'common.continue': 'Continue',
    'common.back': 'Back',
    'common.done': 'Done',
    'common.save': 'Save',
    'common.cancel': 'Cancel',
    'common.close': 'Close',
  };

  static const Map<String, String> _romanUrdu = {
    'headline.highlight': 'Apni',
    'headline.rest': 'Khushgawar Kahani Dhoondhein',
    'location.preview': 'Aap ka shehar',
    'common.skip': 'Skip karein',
    'welcome.subtitle': 'Aisi meaningful connections jo aap ki asal personality aur values par based hon.',
    'welcome.create': 'Account Banayein',
    'welcome.email': 'Email se Continue karein',
    'welcome.google': 'Google se Continue karein',
    'welcome.apple': 'Apple se Continue karein',
    'nav.home': 'Home',
    'nav.explore': 'Explore',
    'nav.chat': 'Chat',
    'nav.profile': 'Profile',
    'discovery.title': 'Discover',
    'likes.title': 'Aap ko Like kiya',
    'chat.title': 'Messages',
    'profile.title': 'Aap ki Profile',
    'common.continue': 'Continue karein',
    'common.back': 'Wapas',
    'common.done': 'Ho gaya',
    'common.save': 'Save karein',
    'common.cancel': 'Cancel',
    'common.close': 'Band karein',
  };
}

class PrototypePortrait extends StatelessWidget {
  const PrototypePortrait({
    required this.seed,
    required this.name,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.dim = false,
  });

  final int seed;
  final String name;
  final BorderRadius borderRadius;
  final bool dim;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          painter: _PortraitPainter(seed),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _portraitPalette(seed),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: const Alignment(0, .2),
                  child: Icon(
                    Icons.person_rounded,
                    size: 152,
                    color: Colors.white.withValues(alpha: .72),
                  ),
                ),
                if (dim)
                  ColoredBox(
                    color: SoulColors.forestDeep.withValues(alpha: .42),
                  ),
                Positioned(
                  left: 14,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _PortraitPainter extends CustomPainter {
  const _PortraitPainter(this.seed);
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 6; i++) {
      paint.color = Colors.white.withValues(alpha: .035 + rng.nextDouble() * .05);
      final radius = size.shortestSide * (.08 + rng.nextDouble() * .18);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        radius,
        paint,
      );
    }
    paint
      ..color = Colors.black.withValues(alpha: .06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(
      Rect.fromLTWH(
        -size.width * .1,
        size.height * .1,
        size.width * 1.2,
        size.height * .9,
      ),
      .4,
      2.3,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PortraitPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

List<Color> _portraitPalette(int seed) {
  const palettes = <List<Color>>[
    [Color(0xff9c6f75), Color(0xff3f586b)],
    [Color(0xff87765f), Color(0xffa94f66)],
    [Color(0xff4d6c6d), Color(0xff8f6d96)],
    [Color(0xff86615b), Color(0xff47647c)],
    [Color(0xff6c5b7b), Color(0xff355c7d)],
    [Color(0xff8b6f47), Color(0xff4a766e)],
  ];
  return palettes[seed.abs() % palettes.length];
}

class PrototypeSectionCard extends StatelessWidget {
  const PrototypeSectionCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: SoulColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .035),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: child,
      );
}

class PrototypePill extends StatelessWidget {
  const PrototypePill(
    this.label, {
    super.key,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? SoulColors.limeLight : SoulColors.softSurface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: selected ? SoulColors.lime : SoulColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: SoulColors.ink),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: SoulColors.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}

class PrototypeHeader extends StatelessWidget {
  const PrototypeHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null) ...[
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SoulColors.ink,
                    fontSize: 25,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.45,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: SoulColors.muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}
