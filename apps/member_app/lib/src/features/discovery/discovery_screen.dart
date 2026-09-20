import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'discovery_repository.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({
    super.key,
    required this.repository,
    required this.labels,
  });

  final DiscoveryRepository repository;
  final BootstrapState labels;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  DiscoveryPreferences? _preferences;
  final List<DiscoveryCandidate> _candidates = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _savingDecision = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preferences = await widget.repository.preferences();
      CandidatePage? page;
      if (preferences != null) {
        page = await widget.repository.candidates();
      }
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _candidates
          ..clear()
          ..addAll(page?.items ?? const []);
        _nextCursor = page?.nextCursor;
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

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (_loadingMore || cursor == null || cursor.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await widget.repository.candidates(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _candidates.addAll(page.items);
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _editFilters() async {
    final initial = _preferences ??
        const DiscoveryPreferences(
          preferredGender: 'woman',
          minimumAge: 18,
          maximumAge: 45,
          sameCountryOnly: true,
          religionMode: 'my_religion',
          locationMode: 'current',
          intentions: [],
        );
    final updated = await showModalBottomSheet<DiscoveryPreferences>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (_) => _DiscoveryFilterEditor(
        initial: initial,
        labels: widget.labels,
      ),
    );
    if (updated == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final saved = await widget.repository.savePreferences(updated);
      final page = await widget.repository.candidates();
      if (!mounted) return;
      setState(() {
        _preferences = saved;
        _candidates
          ..clear()
          ..addAll(page.items);
        _nextCursor = page.nextCursor;
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

  Future<void> _decide(String decision) async {
    if (_savingDecision || _candidates.isEmpty) return;
    final candidate = _candidates.first;
    setState(() {
      _savingDecision = true;
      _error = null;
    });
    try {
      final result = await widget.repository.decide(candidate.id, decision);
      if (!mounted) return;
      setState(() {
        _candidates.removeAt(0);
        _savingDecision = false;
      });
      if (result.matched) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(widget.labels.text('matches.new_match', 'It is a match!')),
            content: Text('${candidate.firstName} and you liked each other.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(widget.labels.text('common.done', 'Done')),
              ),
            ],
          ),
        );
      }
      if (_candidates.length < 4) {
        await _loadMore();
      }
    } on SoulApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _savingDecision = false;
        _error = failure.message;
      });
    }
  }

  String _maritalLabel(String value) =>
      widget.labels.text('profile.$value', value.replaceAll('_', ' '));

  String? _distanceLabel(String? key) {
    if (key == null || key.isEmpty) return null;
    return widget.labels.text(key, key.replaceAll('distance.', '').replaceAll('_', ' '));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _preferences == null) {
      return _RetryState(message: _error!, onRetry: _load);
    }
    if (_preferences == null) {
      return _EmptyState(
        icon: Icons.tune_rounded,
        title: widget.labels.text('discovery.filters', 'Filters'),
        message: 'Choose who you would like to discover.',
        actionLabel: widget.labels.text('common.continue', 'Continue'),
        onAction: _editFilters,
      );
    }

    final candidate = _candidates.isEmpty ? null : _candidates.first;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                const Text(
                  'SOUL',
                  style: TextStyle(
                    color: SoulColors.forestDeep,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: widget.labels.text('discovery.filters', 'Filters'),
                  onPressed: _editFilters,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ),
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _error = null),
                  child: Text(widget.labels.text('common.close', 'Close')),
                ),
              ],
            ),
          Expanded(
            child: candidate == null
                ? _EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: widget.labels.text(
                      'discovery.no_profiles',
                      'No more profiles right now',
                    ),
                    message: 'Try adjusting your filters or check back later.',
                    actionLabel: widget.labels.text('common.retry', 'Try again'),
                    onAction: _load,
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: _CandidateCard(
                      candidate: candidate,
                      maritalLabel: _maritalLabel(candidate.maritalStatus),
                      distanceLabel: _distanceLabel(candidate.distanceBand),
                    ),
                  ),
          ),
          if (candidate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 2, 28, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DecisionButton(
                    icon: Icons.close_rounded,
                    label: widget.labels.text('discovery.pass', 'Pass'),
                    onPressed:
                        _savingDecision ? null : () => _decide('pass'),
                  ),
                  _DecisionButton(
                    icon: Icons.favorite_rounded,
                    label: widget.labels.text('discovery.like', 'Like'),
                    primary: true,
                    onPressed:
                        _savingDecision ? null : () => _decide('like'),
                  ),
                ],
              ),
            ),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatefulWidget {
  const _CandidateCard({
    required this.candidate,
    required this.maritalLabel,
    required this.distanceLabel,
  });

  final DiscoveryCandidate candidate;
  final String maritalLabel;
  final String? distanceLabel;

  @override
  State<_CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<_CandidateCard> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final candidate = widget.candidate;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: SoulColors.softSurface),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (candidate.photos.isEmpty)
              const _PhotoFallback()
            else
              PageView.builder(
                itemCount: candidate.photos.length,
                onPageChanged: (index) => setState(() => _photoIndex = index),
                itemBuilder: (_, index) {
                  final url = candidate.photos[index].url;
                  if (url == null || url.isEmpty) return const _PhotoFallback();
                  return Image.network(
                    url,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => const _PhotoFallback(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const _PhotoFallback(loading: true);
                    },
                  );
                },
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
            ),
            if (candidate.photos.length > 1)
              Positioned(
                top: 14,
                left: 16,
                right: 16,
                child: Row(
                  children: List.generate(
                    candidate.photos.length,
                    (index) => Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: index == _photoIndex
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${candidate.firstName}, ${candidate.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _InfoPill(
                        icon: Icons.favorite_outline_rounded,
                        text: widget.maritalLabel,
                      ),
                      if (candidate.city != null && candidate.city!.isNotEmpty)
                        _InfoPill(
                          icon: Icons.location_on_outlined,
                          text: candidate.city!,
                        ),
                      if (widget.distanceLabel != null)
                        _InfoPill(
                          icon: Icons.near_me_outlined,
                          text: widget.distanceLabel!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: SoulColors.softSurface,
        child: Center(
          child: loading
              ? const CircularProgressIndicator()
              : const Icon(
                  Icons.person_rounded,
                  size: 94,
                  color: SoulColors.muted,
                ),
        ),
      );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 5),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(132, 54),
            backgroundColor: primary ? SoulColors.forestDeep : Colors.white,
            foregroundColor: primary ? Colors.white : SoulColors.ink,
            side: primary ? BorderSide.none : const BorderSide(color: SoulColors.line),
          ),
          icon: Icon(icon),
          label: Text(label),
        ),
      );
}

class _DiscoveryFilterEditor extends StatefulWidget {
  const _DiscoveryFilterEditor({
    required this.initial,
    required this.labels,
  });

  final DiscoveryPreferences initial;
  final BootstrapState labels;

  @override
  State<_DiscoveryFilterEditor> createState() => _DiscoveryFilterEditorState();
}

class _DiscoveryFilterEditorState extends State<_DiscoveryFilterEditor> {
  late String _gender;
  late RangeValues _ages;
  late bool _sameCountry;
  late String _religionMode;
  late String _locationMode;
  late int? _radiusKm;
  late Set<String> _intentions;
  late final TextEditingController _country;
  late final TextEditingController _city;
  String? _validation;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    _gender = value.preferredGender;
    _ages = RangeValues(value.minimumAge.toDouble(), value.maximumAge.toDouble());
    _sameCountry = value.sameCountryOnly;
    _religionMode = value.religionMode;
    _locationMode = value.locationMode;
    _radiusKm = value.radiusKm;
    _intentions = value.intentions.toSet();
    final selected =
        value.selectedLocations.isEmpty ? null : value.selectedLocations.first;
    _country = TextEditingController(text: selected?.countryCode ?? '');
    _city = TextEditingController(text: selected?.cityName ?? '');
  }

  @override
  void dispose() {
    _country.dispose();
    _city.dispose();
    super.dispose();
  }

  void _submit() {
    SelectedDiscoveryLocation? selected;
    if (_locationMode == 'selected') {
      final country = _country.text.trim().toUpperCase();
      if (!RegExp(r'^[A-Z]{2}$').hasMatch(country)) {
        setState(() => _validation = 'Use a 2-letter country code.');
        return;
      }
      selected = SelectedDiscoveryLocation(
        countryCode: country,
        cityName: _city.text.trim().isEmpty ? null : _city.text.trim(),
      );
    }
    Navigator.of(context).pop(
      DiscoveryPreferences(
        preferredGender: _gender,
        minimumAge: _ages.start.round(),
        maximumAge: _ages.end.round(),
        sameCountryOnly: _sameCountry,
        religionMode: _religionMode,
        locationMode: _locationMode,
        radiusKm: _locationMode == 'current' ? _radiusKm : null,
        selectedLocations: selected == null ? const [] : [selected],
        intentions: _intentions.toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  labels.text('discovery.filters', 'Filters'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'man',
                  label: Text(labels.text('profile.man', 'Man')),
                ),
                ButtonSegment(
                  value: 'woman',
                  label: Text(labels.text('profile.woman', 'Woman')),
                ),
              ],
              selected: {_gender},
              onSelectionChanged: (value) =>
                  setState(() => _gender = value.first),
            ),
            const SizedBox(height: 22),
            Text(
              '${_ages.start.round()} – ${_ages.end.round()}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            RangeSlider(
              values: _ages,
              min: 18,
              max: 100,
              divisions: 82,
              labels: RangeLabels(
                _ages.start.round().toString(),
                _ages.end.round().toString(),
              ),
              onChanged: (value) => setState(() => _ages = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(labels.text('profile.country', 'Country of residence')),
              value: _sameCountry,
              onChanged: (value) => setState(() => _sameCountry = value),
            ),
            const SizedBox(height: 12),
            Text(labels.text('profile.religion', 'Religion or belief')),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'my_religion',
                  label: Text(
                    labels.text('discovery.my_religion', 'My Religion'),
                  ),
                ),
                ButtonSegment(
                  value: 'all_religions',
                  label: Text(
                    labels.text('discovery.all_religions', 'All Religions'),
                  ),
                ),
              ],
              selected: {_religionMode},
              onSelectionChanged: (value) =>
                  setState(() => _religionMode = value.first),
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _locationMode,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: 'current',
                  child: Text(labels.text('profile.city', 'Current city')),
                ),
                DropdownMenuItem(
                  value: 'selected',
                  child: Text(labels.text('profile.country', 'Country')),
                ),
                DropdownMenuItem(
                  value: 'anywhere',
                  child: Text(labels.text('discovery.anywhere', 'Anywhere')),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _locationMode = value);
              },
            ),
            if (_locationMode == 'current') ...[
              const SizedBox(height: 12),
              DropdownButton<int?>(
                value: _radiusKm,
                isExpanded: true,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(labels.text('discovery.anywhere', 'Anywhere')),
                  ),
                  for (final value in const [10, 25, 50, 100, 250, 500])
                    DropdownMenuItem<int?>(
                      value: value,
                      child: Text('$value km'),
                    ),
                ],
                onChanged: (value) => setState(() => _radiusKm = value),
              ),
            ],
            if (_locationMode == 'selected') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _country,
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: labels.text('profile.country', 'Country'),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _city,
                decoration: InputDecoration(
                  labelText: labels.text('profile.city', 'Current city'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(labels.text('profile.intentions', 'What are you looking for?')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _intentionChip(
                  'marriage',
                  labels.text('profile.intention_marriage', 'Marriage'),
                ),
                _intentionChip(
                  'serious_relationship',
                  labels.text('profile.intention_serious', 'Serious relationship'),
                ),
                _intentionChip(
                  'casual_dating',
                  labels.text('profile.intention_casual', 'Casual dating'),
                ),
              ],
            ),
            if (_validation != null) ...[
              const SizedBox(height: 12),
              Text(
                _validation!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: SoulColors.forestDeep,
                foregroundColor: Colors.white,
              ),
              child: Text(labels.text('common.save', 'Save')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intentionChip(String value, String label) => FilterChip(
        label: Text(label),
        selected: _intentions.contains(value),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              if (_intentions.length < 3) _intentions.add(value);
            } else {
              _intentions.remove(value);
            }
          });
        },
      );
}

class _RetryState extends StatelessWidget {
  const _RetryState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: SoulColors.forest),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      );
}
