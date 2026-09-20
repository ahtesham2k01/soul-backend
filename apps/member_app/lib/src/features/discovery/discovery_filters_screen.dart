import 'package:flutter/material.dart';

import '../../core/soul_theme.dart';
import '../bootstrap/bootstrap_repository.dart';
import 'discovery_repository.dart';

class DiscoveryFiltersScreen extends StatefulWidget {
  const DiscoveryFiltersScreen({
    super.key,
    required this.initial,
    required this.labels,
  });

  final DiscoveryPreferences initial;
  final BootstrapState labels;

  @override
  State<DiscoveryFiltersScreen> createState() => _DiscoveryFiltersScreenState();
}

class _DiscoveryFiltersScreenState extends State<DiscoveryFiltersScreen> {
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
    _restore(widget.initial);
    final selected = widget.initial.selectedLocations.isEmpty
        ? null
        : widget.initial.selectedLocations.first;
    _country = TextEditingController(text: selected?.countryCode ?? '');
    _city = TextEditingController(text: selected?.cityName ?? '');
  }

  void _restore(DiscoveryPreferences value) {
    _gender = value.preferredGender;
    _ages = RangeValues(
      value.minimumAge.toDouble(),
      value.maximumAge.toDouble(),
    );
    _sameCountry = value.sameCountryOnly;
    _religionMode = value.religionMode;
    _locationMode = value.locationMode;
    _radiusKm = value.radiusKm;
    _intentions = value.intentions.toSet();
  }

  @override
  void dispose() {
    _country.dispose();
    _city.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _ages = const RangeValues(18, 100);
      _sameCountry = false;
      _religionMode = 'all_religions';
      _locationMode = 'anywhere';
      _radiusKm = null;
      _intentions.clear();
      _country.clear();
      _city.clear();
      _validation = null;
    });
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
        sameCountryOnly: _locationMode == 'current' && _sameCountry,
        religionMode: _religionMode,
        locationMode: _locationMode,
        radiusKm: _locationMode == 'current' ? _radiusKm : null,
        selectedLocations: selected == null ? const [] : [selected],
        intentions: _intentions.toList(growable: false),
      ),
    );
  }

  String _ageSummary() {
    if (_ages.start.round() == 18 && _ages.end.round() == 100) {
      return '18 - 100';
    }
    return '${_ages.start.round()} - ${_ages.end.round()}';
  }

  String _locationSummary() {
    if (_locationMode == 'anywhere') {
      return widget.labels.text('discovery.anywhere', 'Anywhere');
    }
    if (_locationMode == 'selected') {
      final city = _city.text.trim();
      final country = _country.text.trim().toUpperCase();
      if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
      if (country.isNotEmpty) return country;
      return widget.labels.text('profile.country', 'Country');
    }
    if (_radiusKm == null) {
      return widget.labels.text('profile.city', 'Current city');
    }
    return '${_radiusKm} km';
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 14, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: labels.text('common.close', 'Close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      labels.text('discovery.filters', 'Filters'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clear,
                    style: TextButton.styleFrom(
                      foregroundColor: SoulColors.ink,
                      backgroundColor: SoulColors.limeLight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Clear all',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
                children: [
                  const _SectionTitle('Basic information'),
                  _FilterCard(
                    children: [
                      _InlineField(
                        label: labels.text('profile.gender', 'Gender'),
                        value: _gender == 'man'
                            ? labels.text('profile.man', 'Man')
                            : labels.text('profile.woman', 'Woman'),
                        trailing: SegmentedButton<String>(
                          showSelectedIcon: false,
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
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 13, 16, 4),
                        child: Row(
                          children: [
                            const Text(
                              'Age',
                              style: TextStyle(
                                color: SoulColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _ageSummary(),
                              style: const TextStyle(
                                color: SoulColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RangeSlider(
                        min: 18,
                        max: 100,
                        divisions: 82,
                        values: _ages,
                        labels: RangeLabels(
                          _ages.start.round().toString(),
                          _ages.end.round().toString(),
                        ),
                        onChanged: (value) => setState(() => _ages = value),
                      ),
                      const Divider(height: 1),
                      _TapField(
                        label: labels.text('profile.city', 'Location'),
                        value: _locationSummary(),
                        onTap: _showLocationOptions,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(labels.text('profile.religion', 'Religion or belief')),
                  _FilterCard(
                    children: [
                      _SelectRow(
                        label: labels.text(
                          'discovery.my_religion',
                          'My Religion',
                        ),
                        selected: _religionMode == 'my_religion',
                        onTap: () =>
                            setState(() => _religionMode = 'my_religion'),
                      ),
                      const Divider(height: 1),
                      _SelectRow(
                        label: labels.text(
                          'discovery.all_religions',
                          'All Religions',
                        ),
                        selected: _religionMode == 'all_religions',
                        onTap: () =>
                            setState(() => _religionMode = 'all_religions'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    labels.text(
                      'profile.intentions',
                      'What are you looking for?',
                    ),
                  ),
                  _FilterCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _intentionChip(
                              'marriage',
                              labels.text(
                                'profile.intention_marriage',
                                'Marriage',
                              ),
                            ),
                            _intentionChip(
                              'serious_relationship',
                              labels.text(
                                'profile.intention_serious',
                                'Serious relationship',
                              ),
                            ),
                            _intentionChip(
                              'casual_dating',
                              labels.text(
                                'profile.intention_casual',
                                'Casual dating',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_validation != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _validation!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: SoulColors.limeLight,
            foregroundColor: SoulColors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: Text(
            labels.text('common.save', 'Save'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLocationOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          void update(VoidCallback change) {
            setState(change);
            setSheetState(() {});
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.labels.text('profile.city', 'Location'),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  _SelectRow(
                    label: widget.labels.text('profile.city', 'Current city'),
                    selected: _locationMode == 'current',
                    onTap: () => update(() {
                      _locationMode = 'current';
                    }),
                  ),
                  if (_locationMode == 'current') ...[
                    SwitchListTile(
                      title: Text(
                        widget.labels.text(
                          'profile.country',
                          'Country of residence',
                        ),
                      ),
                      subtitle: const Text('Limit results to your country'),
                      value: _sameCountry,
                      onChanged: (value) =>
                          update(() => _sameCountry = value),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Distance',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DropdownButtonFormField<int?>(
                      initialValue: _radiusKm,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            widget.labels.text(
                              'discovery.anywhere',
                              'Anywhere',
                            ),
                          ),
                        ),
                        for (final distance
                            in const [10, 25, 40, 50, 100, 250, 500])
                          DropdownMenuItem<int?>(
                            value: distance,
                            child: Text('Up to $distance km away'),
                          ),
                      ],
                      onChanged: (value) => update(() => _radiusKm = value),
                    ),
                  ],
                  _SelectRow(
                    label: widget.labels.text('profile.country', 'Country'),
                    selected: _locationMode == 'selected',
                    onTap: () => update(() {
                      _locationMode = 'selected';
                      _sameCountry = false;
                    }),
                  ),
                  if (_locationMode == 'selected') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _country,
                      maxLength: 2,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: widget.labels.text(
                          'profile.country',
                          'Country',
                        ),
                        helperText: '2-letter country code',
                        counterText: '',
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _city,
                      decoration: InputDecoration(
                        labelText:
                            widget.labels.text('profile.city', 'Current city'),
                      ),
                      onChanged: (_) => setSheetState(() {}),
                    ),
                  ],
                  _SelectRow(
                    label: widget.labels.text(
                      'discovery.anywhere',
                      'Anywhere',
                    ),
                    selected: _locationMode == 'anywhere',
                    onTap: () => update(() {
                      _locationMode = 'anywhere';
                      _sameCountry = false;
                      _radiusKm = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: SoulColors.limeLight,
                      foregroundColor: SoulColors.ink,
                    ),
                    child: Text(widget.labels.text('common.done', 'Done')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _intentionChip(String value, String label) => FilterChip(
        label: Text(label),
        selectedColor: SoulColors.limeLight,
        checkmarkColor: SoulColors.ink,
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

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text(
          label,
          style: const TextStyle(
            color: SoulColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          selected
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
          color: selected ? SoulColors.lime : SoulColors.muted,
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Text(
          label,
          style: const TextStyle(
            color: SoulColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: SoulColors.line),
        ),
        child: Column(children: children),
      );
}

class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.label,
    required this.value,
    required this.trailing,
  });

  final String label;
  final String value;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
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
                  Text(
                    value,
                    style: const TextStyle(
                      color: SoulColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      );
}

class _TapField extends StatelessWidget {
  const _TapField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
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
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        color: SoulColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: SoulColors.muted,
              ),
            ],
          ),
        ),
      );
}
