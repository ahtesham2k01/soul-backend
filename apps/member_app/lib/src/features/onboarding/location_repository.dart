import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';

class ResolvedMemberLocation {
  const ResolvedMemberLocation({
    required this.city,
    required this.countryCode,
    this.country,
    this.region,
    this.isApproximate = false,
  });

  final String city;
  final String countryCode;
  final String? country;
  final String? region;
  final bool isApproximate;

  factory ResolvedMemberLocation.fromJson(Map<String, dynamic> json) =>
      ResolvedMemberLocation(
        city: json['city']?.toString() ?? '',
        countryCode: json['country_code']?.toString().toUpperCase() ?? '',
        country: json['country']?.toString(),
        region: json['region']?.toString(),
        isApproximate: json['is_approximate'] == true,
      );
}

class LocationResolutionFailure implements Exception {
  const LocationResolutionFailure(this.code, this.message);

  final String code;
  final String message;
}

class OnboardingLocationRepository {
  OnboardingLocationRepository(this._api);

  final SoulApiClient _api;

  Future<ResolvedMemberLocation> resolveCurrent() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationResolutionFailure(
        'LOCATION_SERVICES_DISABLED',
        'Turn on location services or enter your city manually.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationResolutionFailure(
        'LOCATION_PERMISSION_DENIED',
        'Location permission was not granted. Enter your city manually.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationResolutionFailure(
        'LOCATION_PERMISSION_DENIED_FOREVER',
        'Location permission is blocked in system settings. Enter your city manually.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );

    final data = await _api.post(
      'location/resolve',
      data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy_meters': position.accuracy,
      },
    );

    final raw = data['location'];
    if (raw is! Map) {
      throw const LocationResolutionFailure(
        'LOCATION_UNAVAILABLE',
        'We could not resolve your city. Enter it manually to continue.',
      );
    }

    final location = ResolvedMemberLocation.fromJson(
      Map<String, dynamic>.from(raw),
    );
    if (location.city.trim().isEmpty ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(location.countryCode)) {
      throw const LocationResolutionFailure(
        'LOCATION_INVALID',
        'We could not resolve a valid city. Enter it manually to continue.',
      );
    }

    return location;
  }
}
