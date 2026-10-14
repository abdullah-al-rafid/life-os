import 'dart:convert';

import '../../records/domain/life_record.dart';

enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

extension PrayerNameLabel on PrayerName {
  String get label => switch (this) {
    PrayerName.fajr => 'Fajr',
    PrayerName.dhuhr => 'Dhuhr',
    PrayerName.asr => 'Asr',
    PrayerName.maghrib => 'Maghrib',
    PrayerName.isha => 'Isha',
  };
}

class PrayerTimes {
  const PrayerTimes({required this.azanMinute, required this.jamaatMinute});
  final int azanMinute;
  final int jamaatMinute;

  void validate() {
    if (azanMinute < 0 || azanMinute >= 1440) {
      throw const PrayerValidationFailure('Azan time must be within one day.');
    }
    if (jamaatMinute <= azanMinute || jamaatMinute >= 1440) {
      throw const PrayerValidationFailure(
        'Jamaat time must be later than Azan and within the same day.',
      );
    }
  }
}

class PrayerSchedule {
  PrayerSchedule({
    required this.timezoneId,
    required Map<PrayerName, PrayerTimes> slots,
    this.remindersEnabled = false,
  }) : slots = Map.unmodifiable(slots) {
    validate();
  }

  final String timezoneId;
  final Map<PrayerName, PrayerTimes> slots;
  final bool remindersEnabled;

  void validate() {
    if (!RegExp(
      r'^(?:UTC|GMT|[A-Za-z][A-Za-z0-9_+-]*(?:/[A-Za-z0-9_+-]+)+)$',
    ).hasMatch(timezoneId)) {
      throw const PrayerValidationFailure('Choose a valid device timezone.');
    }
    if (slots.length != PrayerName.values.length ||
        !slots.keys.toSet().containsAll(PrayerName.values)) {
      throw const PrayerValidationFailure('Configure all five daily prayers.');
    }
    for (final times in slots.values) {
      times.validate();
    }
  }

  Map<String, Object?> toJson() => {
    'recordType': 'prayerSchedule',
    'schemaVersion': 1,
    'timezoneId': timezoneId,
    'remindersEnabled': remindersEnabled,
    'slots': {
      for (final prayer in PrayerName.values)
        prayer.label: {
          'azanMinute': slots[prayer]!.azanMinute,
          'jamaatMinute': slots[prayer]!.jamaatMinute,
        },
    },
  };

  String encode() => jsonEncode(toJson());

  factory PrayerSchedule.fromJson(Map<String, dynamic> json) {
    try {
      if (json['recordType'] != 'prayerSchedule' ||
          json['schemaVersion'] != 1 ||
          (json.containsKey('remindersEnabled') &&
              json['remindersEnabled'] is! bool) ||
          json['slots'] is! Map<String, dynamic>) {
        throw const PrayerValidationFailure('Prayer schedule is malformed.');
      }
      final slotsJson = json['slots'] as Map<String, dynamic>;
      final slots = <PrayerName, PrayerTimes>{};
      for (final prayer in PrayerName.values) {
        final value = slotsJson[prayer.label];
        if (value is! Map<String, dynamic> ||
            value['azanMinute'] is! int ||
            value['jamaatMinute'] is! int) {
          throw const PrayerValidationFailure('Prayer schedule is malformed.');
        }
        slots[prayer] = PrayerTimes(
          azanMinute: value['azanMinute'] as int,
          jamaatMinute: value['jamaatMinute'] as int,
        );
      }
      return PrayerSchedule(
        timezoneId: json['timezoneId'] as String,
        slots: slots,
        remindersEnabled: json['remindersEnabled'] == true,
      );
    } on TypeError {
      throw const PrayerValidationFailure('Prayer schedule is malformed.');
    }
  }
}

enum PrayerCompletion { prayedOnTime, prayedLate, missed }

enum JamaatStatus { jamaat, individual, unknown }

class PrayerValidationFailure implements Exception {
  const PrayerValidationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class DeviceTimezoneFailure implements Exception {
  const DeviceTimezoneFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class PrayerRepositoryFailure implements Exception {
  const PrayerRepositoryFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

String formatPrayerMinute(int minute) {
  final hour = minute ~/ 60;
  final value = minute % 60;
  final suffix = hour < 12 ? 'AM' : 'PM';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$hour12:${value.toString().padLeft(2, '0')} $suffix';
}

int minuteFromTime(DateTime value) => value.hour * 60 + value.minute;

String prayerDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

RecordVisibility get defaultPrayerVisibility => RecordVisibility.private;
