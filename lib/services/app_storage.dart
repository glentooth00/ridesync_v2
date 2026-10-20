
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/motorcycle.dart';
import '../models/ride.dart';
import '../models/rider_profile.dart';

class AppStorage {
  static const _motorcyclesKey = 'ridesync_motorcycles_v1';
  static const _ridesKey = 'ridesync_rides_v1';
  static const _selectedMotorcycleKey =
      'ridesync_selected_motorcycle_v1';
  static const _riderProfileKey = 'ridesync_rider_profile_v1';

  // MOTORCYCLES

  static Future<List<Motorcycle>> loadMotorcycles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_motorcyclesKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Motorcycle.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveMotorcycles(
    List<Motorcycle> motorcycles,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _motorcyclesKey,
      jsonEncode(
        motorcycles.map((item) => item.toJson()).toList(),
      ),
    );
  }

  // RIDES

  static Future<List<RideRecord>> loadRides() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ridesKey);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(RideRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveRides(List<RideRecord> rides) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _ridesKey,
      jsonEncode(rides.map((item) => item.toJson()).toList()),
    );
  }

  // SELECTED MOTORCYCLE

  static Future<int> loadSelectedMotorcycleId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getInt(_selectedMotorcycleKey) ?? 0;
  }

  static Future<void> saveSelectedMotorcycleId(int id) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_selectedMotorcycleKey, id);
  }

  // RIDER PROFILE

  static Future<RiderProfile> loadRiderProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_riderProfileKey);

    if (raw == null || raw.isEmpty) {
      return const RiderProfile();
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return RiderProfile.fromJson(decoded);
      }

      return const RiderProfile();
    } catch (_) {
      return const RiderProfile();
    }
  }

  static Future<void> saveRiderProfile(
    RiderProfile profile,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _riderProfileKey,
      jsonEncode(profile.toJson()),
    );
  }

  static Future<void> clearRiderProfile() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_riderProfileKey);
  }

  // CLEAR ALL LOCAL DATA

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_motorcyclesKey);
    await prefs.remove(_ridesKey);
    await prefs.remove(_selectedMotorcycleKey);
    await prefs.remove(_riderProfileKey);
  }
}
